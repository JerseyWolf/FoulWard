# SPDX-License-Identifier: MIT
"""Stage 3: GLB → FBX (Blender) → Mixamo rig (optional) → GLB."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
from pathlib import Path


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


def rig_model(
    glb_path: str,
    out_path: str,
    mixamo_email: str = "",
    mixamo_password: str = "",
    asset_type: str = "enemy",
) -> str:
    """
    Rig humanoids via Mixamo when credentials are available; buildings copy GLB unchanged.

    Credentials are loaded from ``~/.foulward_secrets`` or environment variables via
    ``_load_mixamo_credentials()`` if the caller does not pass them. The caller-supplied
    ``mixamo_email`` / ``mixamo_password`` args take precedence (backwards compatible).
    """
    src: Path = Path(glb_path).resolve()
    dst: Path = Path(out_path).resolve()
    dst.parent.mkdir(parents=True, exist_ok=True)

    if asset_type == "building":
        shutil.copy2(src, dst)
        return str(dst)

    # Caller may pass empty strings when foulward_gen reads from module-level vars
    # before secrets_loader runs; fall back to _load_mixamo_credentials() silently.
    if not mixamo_email or not mixamo_password:
        try:
            mixamo_email, mixamo_password = _load_mixamo_credentials()
        except RuntimeError as exc:
            print(f"[stage3_rig] {exc}")
            print("[stage3_rig] Skipping Mixamo rig — copying unrigged GLB.")
            shutil.copy2(src, dst)
            return str(dst)

    with tempfile.TemporaryDirectory(prefix="fw_mixamo_") as tmp:
        tmp_path: Path = Path(tmp)
        fbx_raw: Path = tmp_path / "mesh_raw.fbx"
        _blender_glb_to_fbx(src, fbx_raw)

        rigged_fbx: Path = tmp_path / "mesh_rigged.fbx"
        try:
            # Package layout varies; try common entry points
            bot = None  # type: ignore[var-annotated]
            try:
                from calapy.mixamo import MixamoBot  # type: ignore[import-not-found]

                bot = MixamoBot(email=mixamo_email, password=mixamo_password)
            except ImportError:
                try:
                    from mixamo_bot import MixamoBot  # type: ignore[import-not-found]

                    bot = MixamoBot(email=mixamo_email, password=mixamo_password)
                except ImportError:
                    bot = None
            if bot is not None and hasattr(bot, "upload_and_rig"):
                bot.upload_and_rig(str(fbx_raw), str(rigged_fbx))  # type: ignore[misc]
            else:
                raise RuntimeError("MixamoBot not available — install Mixamo automation package.")
        except Exception as exc:
            print(f"[stage3_rig] Mixamo automation failed ({exc}); copying unrigged GLB.")
            shutil.copy2(src, dst)
            return str(dst)

        if rigged_fbx.is_file():
            _blender_fbx_to_glb(rigged_fbx, dst)
            return str(dst)

        shutil.copy2(src, dst)
        return str(dst)
