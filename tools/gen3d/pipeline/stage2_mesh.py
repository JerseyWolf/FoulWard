# SPDX-License-Identifier: MIT
"""Stage 2: TRELLIS.2 image → GLB (in-process; run with ``FOULWARD_PYTHON`` = trellis2 env).

Bypass TRELLIS::

    export FOULWARD_GEN3D_STAGE2_MODE=input_file
    export FOULWARD_GEN3D_STAGE2_INPUT_GLB=/path/to/existing.glb

Placeholder box (stages 3–5 smoke test)::

    export FOULWARD_GEN3D_STAGE2_MODE=placeholder

**Public rembg:** default ``FOULWARD_TRELLIS_PUBLIC_REMBG=1`` rewrites cached ``pipeline.json`` to
``ZhengPeng7/BiRefNet`` instead of gated ``briaai/RMBG-2.0`` (see module body).
"""

from __future__ import annotations

import json
import os
import struct
import sys
from pathlib import Path
from typing import Any

import shutil
import trimesh

# TRELLIS sweet spot: 770px input (trained at 518, 770 is community-verified best)
TRELLIS_INPUT_SIZE: int = 770
# Texture bake resolution: 2048 for production quality
TEXTURE_RESOLUTION: int = 2048
# Sampling steps: 500 gives best geometry without excessive time
SPARSE_STEPS: int = 500
def _trellis_repo_root() -> str:
    raw: str = os.environ.get("FOULWARD_TRELLIS_REPO", str(Path.home() / "TRELLIS.2"))
    return str(Path(raw).expanduser().resolve())


def _ensure_repo_on_path() -> None:
    root: str = _trellis_repo_root()
    if root not in sys.path:
        sys.path.insert(0, root)


def _stage2_mode() -> str:
    raw: str = os.environ.get("FOULWARD_GEN3D_STAGE2_MODE", "trellis").strip().lower()
    return raw if raw != "" else "trellis"


def _image_to_glb_from_input_file(out_p: Path) -> str:
    src: str = os.environ.get("FOULWARD_GEN3D_STAGE2_INPUT_GLB", "").strip()
    if src == "":
        raise ValueError(
            "FOULWARD_GEN3D_STAGE2_MODE=input_file requires FOULWARD_GEN3D_STAGE2_INPUT_GLB "
            "pointing to an existing .glb (e.g. a previous placeholder or manual mesh)."
        )
    src_p: Path = Path(src).expanduser().resolve()
    if not src_p.is_file():
        raise FileNotFoundError(f"FOULWARD_GEN3D_STAGE2_INPUT_GLB not found: {src_p}")
    shutil.copy2(src_p, out_p)
    return str(out_p)


def _image_to_glb_placeholder(out_p: Path) -> str:
    mesh: trimesh.Trimesh = trimesh.creation.box(extents=[0.6, 1.8, 0.4])
    mesh.export(str(out_p))
    return str(out_p)


def _trellis_public_rembg_enabled() -> bool:
    raw: str = os.environ.get("FOULWARD_TRELLIS_PUBLIC_REMBG", "1").strip().lower()
    return raw not in ("0", "false", "no", "off")


def _ensure_trellis_pipeline_json_and_public_rembg(model_id: str) -> None:
    """Prefetch ``pipeline.json`` and optionally swap gated RMBG for public BiRefNet."""
    if model_id != "microsoft/TRELLIS.2-4B":
        return
    try:
        from huggingface_hub import hf_hub_download

        hf_hub_download(repo_id=model_id, filename="pipeline.json")
    except Exception:
        pass

    if not _trellis_public_rembg_enabled():
        return

    hub_dir: Path = Path.home() / ".cache/huggingface/hub"
    pattern: str = "models--microsoft--TRELLIS.2-4B/snapshots/*/pipeline.json"
    for p in hub_dir.glob(pattern):
        try:
            text: str = p.read_text(encoding="utf-8")
            data: dict[str, Any] = json.loads(text)
            args: dict[str, Any] = data.get("args") or {}
            rembg_model: dict[str, Any] = args.get("rembg_model") or {}
            rargs: dict[str, Any] = rembg_model.get("args") or {}
            if rargs.get("model_name") != "briaai/RMBG-2.0":
                continue
            rargs["model_name"] = "ZhengPeng7/BiRefNet"
            p.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
        except (OSError, json.JSONDecodeError, TypeError, KeyError):
            continue


def _write_placeholder_glb(out_path: str) -> str:
    json_chunk: bytes = b'{"asset":{"version":"2.0"}}'
    pad: int = (4 - len(json_chunk) % 4) % 4
    json_chunk += b" " * pad
    total_len: int = 12 + 8 + len(json_chunk)
    with open(out_path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total_len))
        f.write(struct.pack("<II", len(json_chunk), 0x4E4F534A))
        f.write(json_chunk)
    print(f"[stage2] Placeholder GLB written: {out_path}")
    return out_path


def image_to_glb(
    image_path: str,
    out_path: str,
    model_id: str = "microsoft/TRELLIS.2-4B",
    tri_budget: int = 12000,
) -> str:
    """Mesh from image, or bypass TRELLIS when ``FOULWARD_GEN3D_STAGE2_MODE`` is set."""
    _ = tri_budget  # reserved for future decimation / simplify tuning
    out_p: Path = Path(out_path).resolve()
    out_p.parent.mkdir(parents=True, exist_ok=True)

    mode: str = _stage2_mode()
    if mode == "input_file":
        return _image_to_glb_from_input_file(out_p)
    if mode == "placeholder":
        return _image_to_glb_placeholder(out_p)
    if mode != "trellis":
        raise ValueError(
            f"Unknown FOULWARD_GEN3D_STAGE2_MODE={mode!r}. Use trellis, input_file, or placeholder."
        )

    _ensure_trellis_pipeline_json_and_public_rembg(model_id)
    _ensure_repo_on_path()

    try:
        import o_voxel
        import torch
        from PIL import Image
        from trellis2.pipelines import Trellis2ImageTo3DPipeline
    except ImportError as e:
        print(f"[stage2] TRELLIS import failed: {e}")
        print("[stage2] Run: cd ~/TRELLIS.2 && pip install -e .")
        return _write_placeholder_glb(str(out_p))

    print(f"[stage2] Loading TRELLIS.2 ({model_id})...")
    pipeline = Trellis2ImageTo3DPipeline.from_pretrained(model_id)
    pipeline.cuda()

    if pipeline.rembg_model is not None and hasattr(pipeline.rembg_model, "model"):
        try:
            pipeline.rembg_model.model.float()
        except Exception:
            pass

    img = Image.open(image_path).convert("RGB")
    w, h = img.size
    front_view = img.crop((0, 0, w // 3, h))

    fw, fh = front_view.size
    scale: float = TRELLIS_INPUT_SIZE / float(max(fw, fh))
    new_w: int = int(fw * scale)
    new_h: int = int(fh * scale)
    front_resized = front_view.resize((new_w, new_h), Image.LANCZOS)
    print(f"[stage2] Front view: {fw}x{fh} -> {new_w}x{new_h} (TRELLIS input)")

    print(f"[stage2] Generating mesh (steps={SPARSE_STEPS}, texture_size={TEXTURE_RESOLUTION})...")
    with torch.no_grad():
        result = pipeline.run(
            front_resized,
            seed=42,
            sparse_structure_sampler_params={
                "steps": SPARSE_STEPS,
                "guidance_strength": 7.5,
            },
            shape_slat_sampler_params={
                "steps": SPARSE_STEPS,
                "guidance_strength": 3.0,
            },
            tex_slat_sampler_params={
                "steps": SPARSE_STEPS,
                "guidance_strength": 3.0,
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
        decimation_target=1000000,
        texture_size=TEXTURE_RESOLUTION,
        remesh=True,
        remesh_band=1,
        remesh_project=0,
        verbose=False,
    )
    glb_obj.export(str(out_p), extension_webp=True)

    size_mb: float = os.path.getsize(out_p) / 1e6
    print(f"[stage2] GLB exported: {out_p} ({size_mb:.1f}MB)")
    return str(out_p)
