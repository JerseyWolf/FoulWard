#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""One-off Phase D: TRELLIS batch with single pipeline load (orc grunt clean test)."""
from __future__ import annotations

import os
import sys
from pathlib import Path

_SCRIPT_DIR: Path = Path(__file__).resolve().parent
_GEN3D_ROOT: Path = _SCRIPT_DIR.parent
sys.path.insert(0, str(_GEN3D_ROOT))

os.environ.setdefault("FOULWARD_TRELLIS_SAMPLER_STEPS", "8")
os.environ.setdefault("FOULWARD_TRELLIS_SPARSE_GUIDANCE", "5.0")
os.environ.setdefault("FOULWARD_TRELLIS_SLAT_GUIDANCE", "2.0")
os.environ.setdefault("FOULWARD_TRELLIS_PREDECIMATE", "100000")

import pipeline.stage2_mesh as s2  # noqa: E402

s2._ensure_repo_on_path()

import o_voxel  # noqa: E402
import torch  # noqa: E402
import trimesh  # noqa: E402
from PIL import Image  # noqa: E402
from trellis2.pipelines import Trellis2ImageTo3DPipeline  # noqa: E402

MODEL_ID: str = "microsoft/TRELLIS.2-4B"

RUNS: list[tuple[str, str, int, int]] = [
    ("/tmp/fw_d/inputs/A_512.png", "/tmp/fw_d/raw/A_512_seed42.glb", 42, 512),
    ("/tmp/fw_d/inputs/A_512.png", "/tmp/fw_d/raw/A_512_seed256.glb", 256, 512),
    ("/tmp/fw_d/inputs/A_512.png", "/tmp/fw_d/raw/A_512_seed512.glb", 512, 512),
    ("/tmp/fw_d/inputs/A_768.png", "/tmp/fw_d/raw/A_768_seed42.glb", 42, 768),
    ("/tmp/fw_d/inputs/A_768.png", "/tmp/fw_d/raw/A_768_seed256.glb", 256, 768),
    ("/tmp/fw_d/inputs/A_768.png", "/tmp/fw_d/raw/A_768_seed512.glb", 512, 768),
    ("/tmp/fw_d/inputs/B_512.png", "/tmp/fw_d/raw/B_512_seed42.glb", 42, 512),
    ("/tmp/fw_d/inputs/B_512.png", "/tmp/fw_d/raw/B_512_seed256.glb", 256, 512),
    ("/tmp/fw_d/inputs/B_512.png", "/tmp/fw_d/raw/B_512_seed512.glb", 512, 512),
    ("/tmp/fw_d/inputs/B_768.png", "/tmp/fw_d/raw/B_768_seed42.glb", 42, 768),
    ("/tmp/fw_d/inputs/B_768.png", "/tmp/fw_d/raw/B_768_seed256.glb", 256, 768),
    ("/tmp/fw_d/inputs/B_768.png", "/tmp/fw_d/raw/B_768_seed512.glb", 512, 768),
]


def main() -> None:
    Path("/tmp/fw_d/raw").mkdir(parents=True, exist_ok=True)
    s2._ensure_trellis_pipeline_json_and_public_rembg(MODEL_ID)
    s2._ensure_repo_on_path()

    print(f"[phase_d] Loading {MODEL_ID} (once)...")
    pipeline: Trellis2ImageTo3DPipeline = Trellis2ImageTo3DPipeline.from_pretrained(MODEL_ID)
    pipeline.cuda()

    if pipeline.rembg_model is not None and hasattr(pipeline.rembg_model, "model"):
        try:
            pipeline.rembg_model.model.float()
        except Exception:
            pass

    predecimate: int = int(os.environ.get("FOULWARD_TRELLIS_PREDECIMATE", "100000"))

    for image_path, out_path, seed, edge in RUNS:
        inp_p: Path = Path(image_path)
        out_p: Path = Path(out_path)
        if not inp_p.is_file():
            print(f"[SKIP] missing input {inp_p}")
            continue

        s2.TRELLIS_INPUT_SIZE = edge
        print(f"\n[phase_d] {out_p.name} seed={seed} edge={edge}")

        torch.manual_seed(seed)
        if torch.cuda.is_available():
            torch.cuda.manual_seed_all(seed)

        trellis_input_path: str = s2.prepare_trellis_input(
            str(inp_p), str(inp_p).replace(".png", "_trellis_input.png")
        )
        front_resized = Image.open(trellis_input_path).convert("RGB")
        print(f"[phase_d] TRELLIS input: {trellis_input_path}")

        with torch.no_grad():
            result = pipeline.run(
                front_resized,
                seed=seed,
                sparse_structure_sampler_params={
                    "steps": s2.TRELLIS_SAMPLER_STEPS,
                    "guidance_strength": s2.TRELLIS_SPARSE_GUIDANCE,
                },
                shape_slat_sampler_params={
                    "steps": s2.TRELLIS_SAMPLER_STEPS,
                    "guidance_strength": s2.TRELLIS_SLAT_GUIDANCE,
                },
                tex_slat_sampler_params={
                    "steps": s2.TRELLIS_SAMPLER_STEPS,
                    "guidance_strength": s2.TRELLIS_SLAT_GUIDANCE,
                },
            )

        mesh = result[0]
        mesh.simplify(16777216)
        glb_obj = o_voxel.postprocess.to_glb(
            vertices=mesh.vertices,
            faces=mesh.faces,
            attr_volume=mesh.attrs,
            coords=mesh.coords,
            attr_layout=mesh.layout,
            voxel_size=mesh.voxel_size,
            aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]],
            decimation_target=predecimate,
            texture_size=s2.TEXTURE_RESOLUTION,
            remesh=True,
            remesh_band=1,
            remesh_project=0,
            verbose=False,
        )
        out_p.parent.mkdir(parents=True, exist_ok=True)
        glb_obj.export(str(out_p), extension_webp=True)

        kb: float = os.path.getsize(out_p) / 1024.0
        print(f"[phase_d] GLB: {out_p} ({kb:.1f} KB)")

        scene = trimesh.load(str(out_p), process=False, force="scene")
        if isinstance(scene, trimesh.Scene):
            meshes = [g for g in scene.geometry.values() if isinstance(g, trimesh.Trimesh)]
            fc = sum(len(m.faces) for m in meshes)
        else:
            fc = len(scene.faces)  # type: ignore[attr-defined]
        print(f"[phase_d] face_count={fc} status=ok")


if __name__ == "__main__":
    main()
