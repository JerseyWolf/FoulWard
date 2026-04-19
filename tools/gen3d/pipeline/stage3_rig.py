# SPDX-License-Identifier: MIT
"""Stage 3: GLB → FBX (Blender) → Mixamo rig (optional) → GLB."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path


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
    mixamo_email: str,
    mixamo_password: str,
    asset_type: str = "enemy",
) -> str:
    """Rig humanoids via Mixamo when credentials set; buildings copy GLB unchanged."""
    src: Path = Path(glb_path).resolve()
    dst: Path = Path(out_path).resolve()
    dst.parent.mkdir(parents=True, exist_ok=True)

    if asset_type == "building":
        shutil.copy2(src, dst)
        return str(dst)

    if not mixamo_email or not mixamo_password:
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
