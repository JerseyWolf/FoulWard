# SPDX-License-Identifier: MIT
"""Stage 2: TRELLIS.2 image → GLB via conda env `trellis2`.

Bypass gated Hugging Face deps (e.g. DINOv3) without TRELLIS::

    export FOULWARD_GEN3D_STAGE2_MODE=input_file
    export FOULWARD_GEN3D_STAGE2_INPUT_GLB=/path/to/existing.glb

Or a crude box mesh for pipeline smoke tests (stages 3–5)::

    export FOULWARD_GEN3D_STAGE2_MODE=placeholder

Default ``FOULWARD_GEN3D_STAGE2_MODE=trellis`` runs full TRELLIS.2 (needs HF access + GPU conda env).

**Gated HF deps:** ``facebook/dinov3-vitl16-pretrain-lvd1689m`` (image encoder) and, in the
upstream ``pipeline.json``, ``briaai/RMBG-2.0`` (foreground mask). If you lack access to
``briaai/RMBG-2.0``, leave ``FOULWARD_TRELLIS_PUBLIC_REMBG=1`` (default): we prefetch
``pipeline.json`` and rewrite the rembg checkpoint to public ``ZhengPeng7/BiRefNet`` (same
``BiRefNet`` class). Set ``FOULWARD_TRELLIS_PUBLIC_REMBG=0`` to keep Microsoft's RMBG-2.0
(after accepting its license on Hugging Face).
"""

from __future__ import annotations

import json
import os
from typing import Any
import shutil
import subprocess
from pathlib import Path


def _resolve_conda_exe() -> str:
    """Find `conda` when not on PATH (set CONDA_EXE to override)."""
    override: str = os.environ.get("CONDA_EXE", "").strip()
    if override != "" and Path(override).is_file():
        return override
    which_conda: str | None = shutil.which("conda")
    if which_conda is not None:
        return which_conda
    home: Path = Path.home()
    for candidate in (
        home / "miniconda3" / "bin" / "conda",
        home / "miniforge3" / "bin" / "conda",
        home / "anaconda3" / "bin" / "conda",
        home / "mambaforge" / "bin" / "conda",
    ):
        if candidate.is_file():
            return str(candidate.resolve())
    raise FileNotFoundError(
        "conda not found. Install Miniconda/Anaconda, add conda to PATH, or set CONDA_EXE "
        "to the full path of the conda executable (see docs/gen3d_workplan.md Part 1 Step 2)."
    )


def _trellis2_prefix() -> Path:
    """Conda env root for `trellis2` (override with FOULWARD_TRELLIS2_PREFIX)."""
    raw: str = os.environ.get("FOULWARD_TRELLIS2_PREFIX", str(Path.home() / "miniconda3/envs/trellis2"))
    return Path(raw).expanduser().resolve()


def _trellis_repo() -> Path:
    """TRELLIS.2 git clone (override with FOULWARD_TRELLIS_REPO)."""
    raw: str = os.environ.get("FOULWARD_TRELLIS_REPO", str(Path.home() / "TRELLIS.2"))
    return Path(raw).expanduser().resolve()


def _conda_run_env() -> dict[str, str]:
    """CUDA headers, nvcc, cicc, CUB/Thrust, and PYTHONPATH for TRELLIS imports."""
    prefix: Path = _trellis2_prefix()
    repo: Path = _trellis_repo()
    env: dict[str, str] = dict(os.environ)
    cuda_home: Path = prefix / "targets/x86_64-linux"
    bin_p: str = str(prefix / "bin")
    nvvm_bin: str = str(prefix / "nvvm/bin")
    env["CUDA_HOME"] = str(cuda_home)
    env["PATH"] = f"{bin_p}:{nvvm_bin}:{env.get('PATH', '')}"
    inc: str = str(prefix / "include")
    env["CPATH"] = f"{inc}:{env['CPATH']}" if env.get("CPATH") else inc
    env["CPLUS_INCLUDE_PATH"] = f"{inc}:{env['CPLUS_INCLUDE_PATH']}" if env.get("CPLUS_INCLUDE_PATH") else inc
    env["PYTHONPATH"] = str(repo)
    env["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
    # TRELLIS pulls gated HF deps (e.g. DINOv3); unauthenticated requests get 401.
    for _hf_key in ("HF_TOKEN", "HUGGING_FACE_HUB_TOKEN"):
        _val: str | None = os.environ.get(_hf_key)
        if _val is not None and _val.strip() != "":
            env[_hf_key] = _val.strip()
    return env


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
    """Minimal box GLB via trimesh — not game-quality; for testing downstream stages only."""
    import trimesh

    mesh: trimesh.Trimesh = trimesh.creation.box(extents=[0.6, 1.8, 0.4])
    mesh.export(str(out_p))
    return str(out_p)


def _trellis_public_rembg_enabled() -> bool:
    raw: str = os.environ.get("FOULWARD_TRELLIS_PUBLIC_REMBG", "1").strip().lower()
    return raw not in ("0", "false", "no", "off")


def _ensure_trellis_pipeline_json_and_public_rembg(model_id: str) -> None:
    """Prefetch ``pipeline.json`` for ``model_id`` and optionally swap gated RMBG for public BiRefNet."""
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


def image_to_glb(
    image_path: str,
    out_path: str,
    model_id: str = "microsoft/TRELLIS.2-4B",
    _tri_budget: int = 12000,
) -> str:
    """Mesh from image, or bypass TRELLIS when ``FOULWARD_GEN3D_STAGE2_MODE`` is set (see module docstring)."""
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

    img_p: Path = Path(image_path).resolve()
    img_s: str = str(img_p).replace("\\", "\\\\")
    out_s: str = str(out_p).replace("\\", "\\\\")
    # Match upstream export path; simplify + to_glb for PBR GLB.
    script: str = f"""
import os
os.environ["PYTORCH_CUDA_ALLOC_CONF"] = "expandable_segments:True"
from pathlib import Path
from PIL import Image
import o_voxel
from trellis2.pipelines import Trellis2ImageTo3DPipeline

out_path = Path(r"{out_s}")
out_path.parent.mkdir(parents=True, exist_ok=True)
pipeline = Trellis2ImageTo3DPipeline.from_pretrained("{model_id}")
pipeline.cuda()
img = Image.open(r"{img_s}")
mesh = pipeline.run(img)[0]
mesh.simplify(16777216)
glb = o_voxel.postprocess.to_glb(
    vertices=mesh.vertices,
    faces=mesh.faces,
    attr_volume=mesh.attrs,
    coords=mesh.coords,
    attr_layout=mesh.layout,
    voxel_size=mesh.voxel_size,
    aabb=[[-0.5, -0.5, -0.5], [0.5, 0.5, 0.5]],
    decimation_target=1000000,
    texture_size=4096,
    remesh=True,
    remesh_band=1,
    remesh_project=0,
    verbose=False,
)
glb.export(str(out_path), extension_webp=True)
print("TRELLIS_DONE")
"""
    conda_exe: str = _resolve_conda_exe()
    run_env: dict[str, str] = _conda_run_env()
    result: subprocess.CompletedProcess[str] = subprocess.run(
        [conda_exe, "run", "-n", "trellis2", "python", "-c", script],
        capture_output=True,
        text=True,
        timeout=7200,
        env=run_env,
    )
    if "TRELLIS_DONE" not in (result.stdout or ""):
        err: str = (result.stderr or "") + (result.stdout or "")
        raise RuntimeError(f"TRELLIS.2 failed:\n{err}")
    return str(out_p)
