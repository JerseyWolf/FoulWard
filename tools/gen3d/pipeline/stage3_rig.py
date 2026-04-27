# SPDX-License-Identifier: MIT
"""Stage 3: GLB → rigged GLB via UniRig (primary) or Mixamo (fallback) or unrigged copy."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path


# ---------------------------------------------------------------------------
# UniRig
# ---------------------------------------------------------------------------

def rig_with_unirig(glb_path: Path, out_path: Path) -> bool:
    """
    Rig a GLB using the local UniRig inference pipeline.

    UniRig is a 3-step shell script pipeline run from UNIRIG_REPO as the
    working directory:
      1. generate_skeleton.sh  — predicts bone positions
      2. generate_skin.sh      — predicts skinning weights
      3. merge.sh              — merges skeleton + skin back onto the source GLB

    All three steps run via ``conda run -n trellis2 bash ...`` so that the
    correct PyTorch + CUDA environment is active.

    Args:
        glb_path:  Absolute path to the source (unrigged) GLB.
        out_path:  Where to write the final rigged GLB.

    Returns:
        True if out_path exists and has non-zero size after all three steps.
        False on any failure — never raises, so the caller can fall through
        to the next backend.
    """
    unirig_repo_raw: str = os.environ.get("UNIRIG_REPO", "").strip()
    if not unirig_repo_raw:
        print("[stage3_rig] UNIRIG_REPO env var not set — skipping UniRig")
        return False

    unirig_repo: Path = Path(unirig_repo_raw).expanduser().resolve()
    if not unirig_repo.is_dir():
        print(f"[stage3_rig] UNIRIG_REPO directory not found: {unirig_repo}")
        return False

    # UniRig extract.sh respects BLENDER_BIN (same default as many Linux installs).
    os.environ.setdefault("BLENDER_BIN", "/usr/bin/blender")

    glb_s: str = str(glb_path)
    out_s: str = str(out_path)

    try:
        with tempfile.TemporaryDirectory(prefix="fw_unirig_") as tmp:
            tmp_path: Path = Path(tmp)
            skeleton_fbx: str = str(tmp_path / "skeleton.fbx")
            skin_fbx: str = str(tmp_path / "skin.fbx")

            # Step 1 — skeleton prediction
            print("[stage3_rig] UniRig step 1/3: generate_skeleton")
            r1: subprocess.CompletedProcess[str] = subprocess.run(
                [
                    "conda", "run", "-n", "trellis2", "bash",
                    "launch/inference/generate_skeleton.sh",
                    "--input", glb_s,
                    "--output", skeleton_fbx,
                ],
                cwd=str(unirig_repo),
                capture_output=True,
                text=True,
                timeout=600,
            )
            if r1.returncode != 0:
                print(f"[stage3_rig] UniRig skeleton failed (rc={r1.returncode}):\n{r1.stderr[-1200:]}")
                return False
            sk_path: Path = Path(skeleton_fbx)
            if not sk_path.is_file() or sk_path.stat().st_size == 0:
                print(
                    "[stage3_rig] UniRig skeleton output missing or empty after step 1 "
                    "(generate_skeleton.sh may have returned 0 on error)"
                )
                out_tail: str = (r1.stdout or "")[-3000:]
                err_tail: str = (r1.stderr or "")[-3000:]
                if out_tail.strip():
                    print(f"[stage3_rig] generate_skeleton stdout (tail):\n{out_tail}")
                if err_tail.strip():
                    print(f"[stage3_rig] generate_skeleton stderr (tail):\n{err_tail}")
                return False

            # Step 2 — skin prediction
            print("[stage3_rig] UniRig step 2/3: generate_skin")
            r2: subprocess.CompletedProcess[str] = subprocess.run(
                [
                    "conda", "run", "-n", "trellis2", "bash",
                    "launch/inference/generate_skin.sh",
                    "--input", skeleton_fbx,
                    "--output", skin_fbx,
                ],
                cwd=str(unirig_repo),
                capture_output=True,
                text=True,
                timeout=600,
            )
            if r2.returncode != 0:
                print(f"[stage3_rig] UniRig skin failed (rc={r2.returncode}):\n{r2.stderr[-600:]}")
                return False
            skin_path: Path = Path(skin_fbx)
            if not skin_path.is_file() or skin_path.stat().st_size == 0:
                print(
                    "[stage3_rig] UniRig skin output missing or empty after step 2 "
                    "(generate_skin.sh may have returned 0 on error)"
                )
                out_tail2: str = (r2.stdout or "")[-3000:]
                err_tail2: str = (r2.stderr or "")[-3000:]
                if out_tail2.strip():
                    print(f"[stage3_rig] generate_skin stdout (tail):\n{out_tail2}")
                if err_tail2.strip():
                    print(f"[stage3_rig] generate_skin stderr (tail):\n{err_tail2}")
                return False

            # Step 3 — merge skeleton + skin back onto original GLB
            print("[stage3_rig] UniRig step 3/3: merge")
            r3: subprocess.CompletedProcess[str] = subprocess.run(
                [
                    "conda", "run", "-n", "trellis2", "bash",
                    "launch/inference/merge.sh",
                    "--source", skin_fbx,
                    "--target", glb_s,
                    "--output", out_s,
                ],
                cwd=str(unirig_repo),
                capture_output=True,
                text=True,
                timeout=600,
            )
            if r3.returncode != 0:
                print(f"[stage3_rig] UniRig merge failed (rc={r3.returncode}):\n{r3.stderr[-600:]}")
                return False
            if not Path(out_s).is_file() or Path(out_s).stat().st_size == 0:
                print(
                    "[stage3_rig] UniRig merge output missing or empty after step 3 "
                    "(merge may have returned 0 on error)"
                )
                out_tail3: str = (r3.stdout or "")[-3000:]
                err_tail3: str = (r3.stderr or "")[-3000:]
                if out_tail3.strip():
                    print(f"[stage3_rig] merge stdout (tail):\n{out_tail3}")
                if err_tail3.strip():
                    print(f"[stage3_rig] merge stderr (tail):\n{err_tail3}")
                return False

    except subprocess.TimeoutExpired:
        print("[stage3_rig] UniRig step timed out (600s)")
        return False
    except Exception as exc:
        print(f"[stage3_rig] UniRig unexpected error: {exc}")
        return False

    if out_path.exists() and out_path.stat().st_size > 0:
        print(f"[stage3_rig] UniRig succeeded: {out_path}")
        return True

    print(f"[stage3_rig] UniRig merge produced no output at {out_path}")
    return False


# ---------------------------------------------------------------------------
# Mixamo (secondary / legacy)
# ---------------------------------------------------------------------------

def _load_mixamo_credentials() -> tuple[str, str]:
    """
    Load Mixamo credentials from ``~/.foulward_secrets`` or environment variables.

    Priority: environment variable → secrets file.
    ``secrets_loader.load_foulward_secrets()`` is called at foulward_gen.py import
    time and already populates ``os.environ``, so this is a belt-and-suspenders
    guard that makes ``stage3_rig`` safe to use standalone.

    Returns:
        (email, password) — may be empty strings if not configured.

    Raises:
        RuntimeError: if neither environment variables nor the secrets file
            provide both MIXAMO_EMAIL and MIXAMO_PASSWORD.
    """
    email: str = os.environ.get("MIXAMO_EMAIL", "").strip()
    password: str = os.environ.get("MIXAMO_PASSWORD", "").strip()

    if not email or not password:
        secrets_path: Path = Path(
            os.environ.get("FOULWARD_SECRETS_FILE", "~/.foulward_secrets")
        ).expanduser().resolve()
        if secrets_path.is_file():
            for line in secrets_path.read_text(encoding="utf-8").splitlines():
                stripped: str = line.strip()
                if stripped.startswith("export "):
                    stripped = stripped[7:].lstrip()
                if "=" not in stripped or stripped.startswith("#"):
                    continue
                key, _, value = stripped.partition("=")
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key == "MIXAMO_EMAIL" and not email:
                    email = value
                elif key == "MIXAMO_PASSWORD" and not password:
                    password = value

    if not email or not password:
        raise RuntimeError(
            "Mixamo credentials not found. Add MIXAMO_EMAIL= and MIXAMO_PASSWORD= "
            "to ~/.foulward_secrets or export them as environment variables."
        )
    print(f"[stage3_rig] Mixamo credentials loaded for: {email}")
    return email, password


def _blender_glb_to_fbx(glb_path: Path, fbx_path: Path) -> None:
    glb_s: str = str(glb_path).replace("\\", "/")
    fbx_s: str = str(fbx_path).replace("\\", "/")
    blend_script: str = f"""
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"{glb_s}")
bpy.ops.export_scene.fbx(
    filepath=r"{fbx_s}",
    use_selection=False,
    add_leaf_bones=False,
    primary_bone_axis='Y',
    secondary_bone_axis='X',
)
"""
    subprocess.run(
        ["blender", "--background", "--python-expr", blend_script],
        check=True,
        capture_output=True,
        text=True,
        timeout=600,
    )


def _blender_fbx_to_glb(fbx_path: Path, glb_path: Path) -> None:
    fbx_s: str = str(fbx_path).replace("\\", "/")
    glb_s: str = str(glb_path).replace("\\", "/")
    blend_script: str = f"""
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=r"{fbx_s}", use_anim=True)
bpy.ops.export_scene.gltf(
    filepath=r"{glb_s}",
    export_format='GLB',
    export_animations=True,
)
"""
    subprocess.run(
        ["blender", "--background", "--python-expr", blend_script],
        check=True,
        capture_output=True,
        text=True,
        timeout=600,
    )


def _rig_with_mixamo(src: Path, dst: Path, email: str, password: str) -> bool:
    """
    Attempt Mixamo Selenium rig. Returns True on success, False on any failure.
    """
    with tempfile.TemporaryDirectory(prefix="fw_mixamo_") as tmp:
        tmp_path: Path = Path(tmp)
        fbx_raw: Path = tmp_path / "mesh_raw.fbx"
        _blender_glb_to_fbx(src, fbx_raw)

        rigged_fbx: Path = tmp_path / "mesh_rigged.fbx"
        try:
            bot = None  # type: ignore[var-annotated]
            try:
                from calapy.mixamo import MixamoBot  # type: ignore[import-not-found]
                bot = MixamoBot(email=email, password=password)
            except ImportError:
                try:
                    from mixamo_bot import MixamoBot  # type: ignore[import-not-found]
                    bot = MixamoBot(email=email, password=password)
                except ImportError:
                    bot = None
            if bot is not None and hasattr(bot, "upload_and_rig"):
                bot.upload_and_rig(str(fbx_raw), str(rigged_fbx))  # type: ignore[misc]
            else:
                raise RuntimeError("MixamoBot not available — install Mixamo automation package.")
        except Exception as exc:
            print(f"[stage3_rig] Mixamo automation failed ({exc})")
            return False

        if rigged_fbx.is_file():
            _blender_fbx_to_glb(rigged_fbx, dst)
            return dst.is_file() and dst.stat().st_size > 0

    return False


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

def rig_model(
    glb_path: str,
    out_path: str,
    mixamo_email: str = "",
    mixamo_password: str = "",
    asset_type: str = "enemy",
) -> str:
    """
    Rig a GLB using the configured backend priority order.

    Backend selection (via ``FOULWARD_RIG_BACKEND`` env var):
      - ``unirig``  — force UniRig only; skip Mixamo even if creds are set
      - ``mixamo``  — force Mixamo only; skip UniRig
      - unset / any other value — default priority:
          1. UniRig (always attempted first)
          2. Mixamo (only if UniRig returns False AND credentials are available)
          3. Unrigged GLB copy (always last resort)

    Buildings skip rigging and are always copied unchanged.
    """
    src: Path = Path(glb_path).resolve()
    dst: Path = Path(out_path).resolve()
    dst.parent.mkdir(parents=True, exist_ok=True)

    if asset_type == "building":
        shutil.copy2(src, dst)
        return str(dst)

    backend: str = os.environ.get("FOULWARD_RIG_BACKEND", "").strip().lower()

    # ── UniRig attempt ───────────────────────────────────────────────────────
    if backend != "mixamo":
        if rig_with_unirig(src, dst):
            return str(dst)
        if backend == "unirig":
            print("[stage3_rig] UniRig failed and FOULWARD_RIG_BACKEND=unirig — no fallback.")
            shutil.copy2(src, dst)
            return str(dst)
        print("[stage3_rig] UniRig failed; trying Mixamo fallback...")

    # ── Mixamo attempt ───────────────────────────────────────────────────────
    if backend != "unirig":
        # Resolve credentials: caller args take precedence, then secrets file.
        email: str = mixamo_email
        pw: str = mixamo_password
        if not email or not pw:
            try:
                email, pw = _load_mixamo_credentials()
            except RuntimeError as exc:
                print(f"[stage3_rig] {exc}")
                email, pw = "", ""

        if email and pw:
            if _rig_with_mixamo(src, dst, email, pw):
                return str(dst)
            print("[stage3_rig] Mixamo failed; falling back to unrigged copy.")
        else:
            print("[stage3_rig] Mixamo credentials not set; skipping Mixamo.")

    # ── Last resort: unrigged copy ───────────────────────────────────────────
    print("[stage3_rig] Copying unrigged GLB as final fallback.")
    shutil.copy2(src, dst)
    return str(dst)
