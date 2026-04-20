#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""One-shot TRELLIS.2 run for input-format A/B tests (subprocess-friendly).

Usage:
  trellis2_input_ab_variant.py <variant_id> <image_path> <seed:int> <out_raw.glb>
      <out_decimated.glb> <out_report.json> <edge:int>

Pads to square on white, resizes to edge×edge, RGB, then runs Trellis2ImageTo3DPipeline
with the same sampler settings as pipeline.stage2_mesh (env overrides respected).

Environment:
  ``FOULWARD_AB_TEXTURE_SIZE`` — optional lower ``texture_size`` for ``to_glb`` when
  CuMesh simplify OOMs on some inputs (default: ``TEXTURE_RESOLUTION`` from stage2).
  ``FOULWARD_TRELLIS_PREDECIMATE`` — passed through as ``decimation_target`` (default 100000).
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path


def _pad_square_rgba(img, fill: tuple[int, int, int, int] = (255, 255, 255, 255)):
    from PIL import Image

    w, h = img.size
    size = max(w, h)
    padded = Image.new("RGBA", (size, size), fill)
    padded.paste(img, ((size - w) // 2, (size - h) // 2))
    return padded


def main() -> None:
    if len(sys.argv) < 8:
        print(
            "Usage: trellis2_input_ab_variant.py VARIANT IMAGE SEED OUT_RAW "
            "OUT_DECIMATED OUT_REPORT EDGE",
            file=sys.stderr,
        )
        sys.exit(2)

    variant_id: str = sys.argv[1]
    image_path: str = sys.argv[2]
    seed: int = int(sys.argv[3])
    out_raw: str = sys.argv[4]
    out_decimated: str = sys.argv[5]
    out_report: str = sys.argv[6]
    edge: int = int(sys.argv[7])

    gen3d: Path = Path(__file__).resolve().parents[1]
    sys.path.insert(0, str(gen3d))

    from PIL import Image

    from pipeline.stage2_mesh import (
        TRELLIS_SAMPLER_STEPS,
        TRELLIS_SLAT_GUIDANCE,
        TRELLIS_SPARSE_GUIDANCE,
        TEXTURE_RESOLUTION,
        decimate_glb,
    )

    trellis_root: str = os.environ.get("FOULWARD_TRELLIS_REPO", str(Path.home() / "TRELLIS.2"))
    if trellis_root not in sys.path:
        sys.path.insert(0, trellis_root)

    import torch
    from trellis2.pipelines import Trellis2ImageTo3DPipeline
    import o_voxel

    import trimesh

    img_rgba: Image.Image = Image.open(image_path).convert("RGBA")
    padded: Image.Image = _pad_square_rgba(img_rgba)
    resized: Image.Image = padded.resize((edge, edge), Image.LANCZOS)
    front_rgb: Image.Image = resized.convert("RGB")

    model_id: str = os.environ.get("FOULWARD_TRELLIS_MODEL", "microsoft/TRELLIS.2-4B")
    predecimate: int = int(os.environ.get("FOULWARD_TRELLIS_PREDECIMATE", "100000"))

    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)

    print(f"[{variant_id}] Loading TRELLIS.2 ({model_id}) edge={edge}...")
    pipeline = Trellis2ImageTo3DPipeline.from_pretrained(model_id)
    pipeline.cuda()

    if pipeline.rembg_model is not None and hasattr(pipeline.rembg_model, "model"):
        try:
            pipeline.rembg_model.model.float()
        except Exception:
            pass

    print(
        f"[{variant_id}] run seed={seed} steps={TRELLIS_SAMPLER_STEPS} "
        f"sparse={TRELLIS_SPARSE_GUIDANCE} slat={TRELLIS_SLAT_GUIDANCE}"
    )
    with torch.no_grad():
        result = pipeline.run(
            front_rgb,
            seed=seed,
            sparse_structure_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SPARSE_GUIDANCE,
            },
            shape_slat_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SLAT_GUIDANCE,
            },
            tex_slat_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SLAT_GUIDANCE,
            },
        )

    mesh = result[0]
    mesh.simplify(16777216)
    # A/B runs can OOM in CuMesh simplify when VRAM is fragmented; allow lower bake res.
    texture_size: int = int(
        os.environ.get("FOULWARD_AB_TEXTURE_SIZE", str(TEXTURE_RESOLUTION))
    )
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
        torch.cuda.synchronize()

    glb_obj = o_voxel.postprocess.to_glb(
        vertices=mesh.vertices,
        faces=mesh.faces,
        attr_volume=mesh.attrs,
        coords=mesh.coords,
        attr_layout=mesh.layout,
        voxel_size=mesh.voxel_size,
        aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]],
        decimation_target=predecimate,
        texture_size=texture_size,
        remesh=True,
        remesh_band=1,
        remesh_project=0,
        verbose=False,
    )
    Path(out_raw).parent.mkdir(parents=True, exist_ok=True)
    glb_obj.export(out_raw, extension_webp=True)
    print(f"[{variant_id}] Raw GLB: {out_raw}")

    decimate_glb(out_raw, out_decimated, target_faces=10000)

    def count_nonmanifold(mesh: trimesh.Trimesh) -> int:
        edge_faces: dict[tuple[int, int], int] = {}
        for face in mesh.faces:
            for j in range(3):
                a: int = int(face[j])
                b: int = int(face[(j + 1) % 3])
                edge: tuple[int, int] = (a, b) if a < b else (b, a)
                edge_faces[edge] = edge_faces.get(edge, 0) + 1
        return sum(1 for v in edge_faces.values() if v != 2)

    dec_scene = trimesh.load(out_decimated, process=False, force="scene")
    if isinstance(dec_scene, trimesh.Scene):
        geoms = [g for g in dec_scene.geometry.values() if isinstance(g, trimesh.Trimesh)]
        dec_combined: trimesh.Trimesh = (
            trimesh.util.concatenate(geoms) if len(geoms) > 1 else geoms[0]
        )
    else:
        dec_combined = dec_scene  # type: ignore[assignment]

    raw_scene = trimesh.load(out_raw, process=False, force="scene")
    if isinstance(raw_scene, trimesh.Scene):
        rgeoms = [g for g in raw_scene.geometry.values() if isinstance(g, trimesh.Trimesh)]
        raw_combined: trimesh.Trimesh = (
            trimesh.util.concatenate(rgeoms) if len(rgeoms) > 1 else rgeoms[0]
        )
    else:
        raw_combined = raw_scene  # type: ignore[assignment]

    raw_nm: int = count_nonmanifold(raw_combined)
    dec_nm: int = count_nonmanifold(dec_combined)
    has_uv: bool = (
        isinstance(dec_combined.visual, trimesh.visual.TextureVisuals)
        and dec_combined.visual.uv is not None
        and len(dec_combined.visual.uv) > 0
    )
    report: dict[str, object] = {
        "variant": variant_id,
        "image_path": image_path,
        "prep_edge": edge,
        "image_size": list(img_rgba.size),
        "image_mode": img_rgba.mode,
        "raw_verts": int(len(raw_combined.vertices)),
        "raw_faces": int(len(raw_combined.faces)),
        "raw_nonmanifold_edges": int(raw_nm),
        "dec_verts": int(len(dec_combined.vertices)),
        "dec_faces": int(len(dec_combined.faces)),
        "dec_nonmanifold_edges": int(dec_nm),
        "dec_has_uv": bool(has_uv),
        "dec_watertight": bool(dec_combined.is_watertight),
    }
    Path(out_report).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"[{variant_id}] Report: {json.dumps(report, indent=2)}")


if __name__ == "__main__":
    main()
