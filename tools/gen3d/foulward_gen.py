#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
#
# NOTE: ComfyUI HTTP stage and local torch usage expect the same Python stack as your
# working ComfyUI install (torch+cu124). Do not use base miniconda Python 3.13 alone.
# Prefer: ``$FOULWARD_PYTHON foulward_gen.py ...`` (FOULWARD_PYTHON is set in ~/.bashrc).
#
"""
Foul Ward — automatic 3D asset generator (local tools).

Usage (``foulward_gen.py`` lives in ``tools/gen3d/``; repo root is two levels above this file):

  cd tools/gen3d
  # Optional: put export HF_TOKEN=hf_... and Mixamo vars in ~/.foulward_secrets (see launch.sh)
  $FOULWARD_PYTHON foulward_gen.py "orc grunt" orc_raiders enemy

Stages: 2D reference → 3D mesh → rig → animate → copy into Godot art/generated/.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

# Ensure sibling package `pipeline` resolves when run as a script
_GEN3D_ROOT: Path = Path(__file__).resolve().parent
# foulward_gen.py is at tools/gen3d/foulward_gen.py → repo root is parents[2]
_REPO_ROOT: Path = Path(__file__).resolve().parents[2]
if str(_GEN3D_ROOT) not in sys.path:
    sys.path.insert(0, str(_GEN3D_ROOT))

from pipeline.secrets_loader import load_foulward_secrets

load_foulward_secrets()

# --- CONFIG (Godot project = repository root; see docs/gen3d_workplan.md) ---
GODOT_ROOT: str = str(_REPO_ROOT)
GEN3D_ROOT: str = str(_GEN3D_ROOT)
COMFYUI_PORT: int = 8188
TRELLIS_MODEL: str = "microsoft/TRELLIS.2-4B"
MIXAMO_EMAIL: str = os.environ.get("MIXAMO_EMAIL", "")
MIXAMO_PASSWORD: str = os.environ.get("MIXAMO_PASSWORD", "")

STYLE_FOOTER: str = (
    "create a turnaround sheet of this character, "
    "front view, right side view, back view, "
    "evenly spaced on pure white background, no shadows, T-pose. "
    "Baroque Fantasy Realism. Caravaggio Baroque Style ca 1600. "
    "Art style: semi-realistic low-poly game character, "
    "slightly exaggerated proportions (large hands, broad shoulders, readable silhouette at small scale), "
    "dark humor fantasy tone (Warhammer Fantasy meets Terry Pratchett), "
    "warm desaturated earth tones, stylized PBR materials, baked ambient occlusion."
)

FACTION_ANCHORS: dict[str, str] = {
    "orc_raiders": (
        "Faction palette: dark green skin, rust iron armor, "
        "cracked leather, tribal bone trim, warm earth tones."
    ),
    "plague_cult": (
        "Faction palette: rot brown-grey flesh, tattered burial cloth, "
        "sickly yellow-green infection glow, rusted dark iron."
    ),
    "allies": (
        "Faction palette: worn practical armor, warm leather browns, "
        "tarnished iron, heroic but scruffy aesthetic."
    ),
    "buildings": (
        "Architecture style: dark stone, wood and iron construction, "
        "medieval fantasy, hex-tile footprint approximately 3x3m, geometric and readable."
    ),
}

ANIM_CLIPS_ENEMY: list[str] = ["idle", "walk", "attack", "hit_react", "death"]
ANIM_CLIPS_ALLY: list[str] = ["idle", "run", "attack_melee", "hit_react", "death", "downed", "recovering"]
ANIM_CLIPS_BUILDING: list[str] = ["idle", "active", "destroyed"]
ANIM_CLIPS_BOSS: list[str] = ["idle", "walk", "attack", "hit_react", "death"]

PERSONAL_NAMES: set[str] = {"arnulf", "florence", "sybil"}


def canonical_slug(unit_name: str) -> str:
    """Single-token slug for named heroes (e.g. 'Florence the ...' -> ``florence``)."""
    parts: list[str] = unit_name.lower().strip().split()
    if len(parts) == 0:
        return "unnamed"
    if parts[0] in PERSONAL_NAMES:
        return parts[0]
    return "_".join(parts)


def get_output_dir(unit_name: str, asset_type: str) -> str:
    """Flat layout: art/generated/<category>/<slug>.glb (matches generation_log / rigged_visual_wiring)."""
    slug: str = canonical_slug(unit_name)
    folder_map: dict[str, str] = {
        "enemy": f"{GODOT_ROOT}/art/generated/enemies",
        "ally": f"{GODOT_ROOT}/art/generated/allies",
        "building": f"{GODOT_ROOT}/art/generated/buildings",
        "boss": f"{GODOT_ROOT}/art/generated/bosses",
    }
    folder: str = folder_map.get(asset_type, f"{GODOT_ROOT}/art/generated/misc")
    os.makedirs(folder, exist_ok=True)
    return folder


def run_pipeline(unit_name: str, faction: str, asset_type: str = "enemy") -> None:
    from pipeline.stage1_image import generate_reference_sheet
    from pipeline.stage2_mesh import image_to_glb
    from pipeline.stage3_rig import rig_model
    from pipeline.stage4_anim import merge_animations
    from pipeline.stage5_drop import drop_to_godot
    from pipeline.unit_descriptions import get_unit_description

    faction_block: str = FACTION_ANCHORS.get(faction, "")
    anim_clips: list[str] = {
        "enemy": ANIM_CLIPS_ENEMY,
        "ally": ANIM_CLIPS_ALLY,
        "building": ANIM_CLIPS_BUILDING,
        "boss": ANIM_CLIPS_BOSS,
    }.get(asset_type, ANIM_CLIPS_ENEMY)

    output_dir: str = get_output_dir(unit_name, asset_type)
    slug: str = canonical_slug(unit_name)
    # Prefer the natural-language description from characters.md when available;
    # fall back to the bare slug so unknown units still generate something.
    description: str = get_unit_description(slug) or unit_name

    print(f"\n=== Foul Ward Gen3D: {unit_name} ({faction}, {asset_type}) ===\n")
    if description != unit_name:
        print(f"[desc] Using bank description for `{slug}` ({len(description)} chars)\n")

    # Stage 1 — 2D reference sheet
    img_path: str = generate_reference_sheet(
        description,
        faction_block,
        STYLE_FOOTER,
        out_path=f"/tmp/fw_{slug}_ref.png",
        port=COMFYUI_PORT,
        faction=faction,
    )
    print(f"[1/5] Reference sheet saved: {img_path}")

    # Stage 2 — image to 3D mesh
    glb_raw: str = image_to_glb(
        img_path,
        out_path=f"/tmp/fw_{slug}_raw.glb",
        model_id=TRELLIS_MODEL,
        tri_budget=12000,
    )
    print(f"[2/5] Raw GLB: {glb_raw}")

    # Stage 3 — rigging
    glb_rigged: str = rig_model(
        glb_raw,
        out_path=f"/tmp/fw_{slug}_rigged.glb",
        mixamo_email=MIXAMO_EMAIL,
        mixamo_password=MIXAMO_PASSWORD,
        asset_type=asset_type,
    )
    print(f"[3/5] Rigged GLB: {glb_rigged}")

    # Stage 4 — animation merge
    anim_library_dir: str = os.path.join(GEN3D_ROOT, "anim_library")
    glb_final: str = merge_animations(
        glb_rigged,
        clips=anim_clips,
        anim_library_dir=anim_library_dir,
        out_path=f"/tmp/fw_{slug}_final.glb",
    )
    print(f"[4/5] Animated GLB: {glb_final}")

    # Stage 5 — drop to Godot project
    drop_to_godot(glb_final, slug, output_dir)
    print(f"[5/5] Done — {unit_name} → {output_dir}/{slug}.glb")
    print("\nOpen Godot editor or Project → Reload Current Project to reimport the GLB.\n")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print('Usage: python foulward_gen.py "unit name" faction [enemy|ally|building|boss]')
        sys.exit(1)
    at: str = sys.argv[3] if len(sys.argv) > 3 else "enemy"
    run_pipeline(
        unit_name=sys.argv[1],
        faction=sys.argv[2],
        asset_type=at,
    )
