# SPDX-License-Identifier: MIT
"""Stage 4: Merge Mixamo FBX clips in Blender; export one GLB with embedded actions."""

from __future__ import annotations

import subprocess
from pathlib import Path

# Map Foul Ward clip names → Mixamo export filenames in anim_library/
ANIM_NAME_MAP: dict[str, str] = {
    "idle": "Idle.fbx",
    "walk": "Walking.fbx",
    "run": "Running.fbx",
    "attack": "Punching.fbx",
    "attack_melee": "Sword And Shield Slash.fbx",
    "hit_react": "Receiving Damage.fbx",
    "death": "Dying.fbx",
    "downed": "Falling Back Death.fbx",
    "recovering": "Getting Up.fbx",
    "active": "Idle.fbx",
    "destroyed": "Falling Back Death.fbx",
}


def merge_animations(
    rigged_glb: str,
    clips: list[str],
    anim_library_dir: str,
    out_path: str,
) -> str:
    """Import rigged GLB + FBX clips; export GLB with animations."""
    rig_p: Path = Path(rigged_glb).resolve()
    lib: Path = Path(anim_library_dir).resolve()
    out_p: Path = Path(out_path).resolve()
    out_p.parent.mkdir(parents=True, exist_ok=True)

    rig_s: str = str(rig_p).replace("\\", "/")
    out_s: str = str(out_p).replace("\\", "/")

    anim_imports: str = ""
    for clip_name in clips:
        fbx_file: str = ANIM_NAME_MAP.get(clip_name, "Idle.fbx")
        fbx_path: Path = lib / fbx_file
        if fbx_path.is_file():
            fp: str = str(fbx_path).replace("\\", "/")
            anim_imports += f"""
bpy.ops.import_scene.fbx(filepath=r"{fp}", use_anim=True)
if bpy.data.actions:
    bpy.data.actions[-1].name = "{clip_name}"
"""

    blend_script: str = f"""
import bpy
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=r"{rig_s}")
{anim_imports}
bpy.ops.export_scene.gltf(
    filepath=r"{out_s}",
    export_format='GLB',
    export_animations=True,
)
print("ANIM_DONE")
"""
    result: subprocess.CompletedProcess[str] = subprocess.run(
        ["blender", "--background", "--python-expr", blend_script],
        capture_output=True,
        text=True,
        timeout=3600,
    )
    if "ANIM_DONE" not in (result.stdout or ""):
        print(f"[stage4_anim] Warning: animation merge may have failed:\n{result.stderr[:800]}")
    return str(out_p)
