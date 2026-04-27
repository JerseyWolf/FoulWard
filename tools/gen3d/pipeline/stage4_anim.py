# SPDX-License-Identifier: MIT
"""Stage 4: Merge Mixamo FBX clips in Blender; export one GLB with embedded actions."""

from __future__ import annotations

import re
import shutil
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


def _scan_anim_library(
    clips: list[str],
    anim_library_dir: str,
) -> tuple[list[tuple[str, Path]], list[str]]:
    """
    Scan anim_library/ for each requested clip.

    Returns:
        found: list of (clip_name, fbx_path) for clips that exist on disk.
        missing_names: list of clip names whose FBX file was not found.
    """
    lib: Path = Path(anim_library_dir).resolve()
    found: list[tuple[str, Path]] = []
    missing_names: list[str] = []
    for clip_name in clips:
        fbx_file: str = ANIM_NAME_MAP.get(clip_name, "Idle.fbx")
        fbx_path: Path = lib / fbx_file
        if fbx_path.is_file():
            found.append((clip_name, fbx_path))
        else:
            missing_names.append(f"{clip_name} ({fbx_file})")
    return found, missing_names


def merge_animations(
    rigged_glb: str,
    clips: list[str],
    anim_library_dir: str,
    out_path: str,
) -> str:
    """Import rigged GLB + FBX clips; export GLB with animations.

    Pre-flight scan:
    - Prints found/missing clip counts before launching Blender.
    - If zero clips are found on disk, copies the rigged GLB to out_path
      unchanged and prints instructions to populate anim_library/.

    Blender output token: ``ANIMDONE:{n}`` where n = number of exported actions.
    """
    rig_p: Path = Path(rigged_glb).resolve()
    out_p: Path = Path(out_path).resolve()
    out_p.parent.mkdir(parents=True, exist_ok=True)

    # ── Pre-flight: scan anim_library/ ──────────────────────────────────────
    found_clips: list[tuple[str, Path]]
    missing_names: list[str]
    found_clips, missing_names = _scan_anim_library(clips, anim_library_dir)

    print(f"[stage4_anim] Clip scan: {len(found_clips)} found, {len(missing_names)} missing")
    if missing_names:
        print(f"[stage4_anim] Missing clips: {', '.join(missing_names)}")

    if not found_clips:
        print(
            "[stage4_anim] No animation clips found in anim_library/ — skipping Blender."
        )
        print(
            "[stage4_anim] To add animations, download Mixamo FBX files (FBX for Unity, "
            "T-pose, 30fps) into tools/gen3d/anim_library/ using these filenames:"
        )
        for clip_name in clips:
            fbx_file: str = ANIM_NAME_MAP.get(clip_name, "Idle.fbx")
            print(f"[stage4_anim]   {fbx_file}  →  clip '{clip_name}'")
        shutil.copy2(rig_p, out_p)
        print(f"[stage4_anim] Rigged GLB copied unchanged to {out_p}")
        return str(out_p)

    # ── Build Blender import script ──────────────────────────────────────────
    rig_s: str = str(rig_p).replace("\\", "/")
    out_s: str = str(out_p).replace("\\", "/")

    anim_imports: str = ""
    for clip_name, fbx_path in found_clips:
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
action_count = len(bpy.data.actions)
print(f"ANIMDONE:{{action_count}}")
if action_count == 0:
    print("ANIMWARN: 0 actions exported")
"""
    result: subprocess.CompletedProcess[str] = subprocess.run(
        ["blender", "--background", "--python-expr", blend_script],
        capture_output=True,
        text=True,
        timeout=3600,
    )

    stdout: str = result.stdout or ""
    m: re.Match[str] | None = re.search(r"ANIMDONE:(\d+)", stdout)
    if not m:
        print(f"[stage4_anim] Warning: animation merge may have failed:\n{result.stderr[:800]}")
    else:
        n_actions: int = int(m.group(1))
        if n_actions == 0:
            print("[stage4_anim] Warning: Blender exported 0 actions")
        else:
            print(f"[stage4_anim] Blender exported {n_actions} action(s)")

    return str(out_p)
