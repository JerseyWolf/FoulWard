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

VRAM handoff (24 GB cards, FLUX.1-dev + TRELLIS.2-4B):
    ComfyUI holds ~16+ GB after Stage 1; TRELLIS needs ~14–18 GB. The pipeline always stops
    ComfyUI after Stage 1 and polls ``nvidia-smi`` until VRAM drops before Stage 2.
    Set ``SKIP_COMFYUI_SHUTDOWN=1`` only if you use a small text-to-image model (e.g. FLUX.1-schnell
    fp8, ~6 GB) so ComfyUI and TRELLIS can share VRAM; do not use with FLUX.1-dev on 24 GB.
"""

from __future__ import annotations

import os
import subprocess
import sys
import time
from pathlib import Path

# Ensure sibling package `pipeline` resolves when run as a script
_GEN3D_ROOT: Path = Path(__file__).resolve().parent
# foulward_gen.py is at tools/gen3d/foulward_gen.py → repo root is parents[2]
_REPO_ROOT: Path = Path(__file__).resolve().parents[2]
if str(_GEN3D_ROOT) not in sys.path:
    sys.path.insert(0, str(_GEN3D_ROOT))

from pipeline.secrets_loader import load_foulward_secrets

load_foulward_secrets()


def wait_for_vram_free(threshold_gb: float = 12.0, timeout_s: int = 120, poll_interval_s: int = 3) -> bool:
    """
    Poll nvidia-smi until GPU VRAM in use drops below threshold_gb.
    Returns True if threshold is reached within timeout_s seconds.
    Returns False (and prints a warning) if timeout is exceeded.
    Used to confirm ComfyUI has fully released VRAM before TRELLIS starts.
    """
    deadline: float = time.time() + float(timeout_s)
    while time.time() < deadline:
        result: subprocess.CompletedProcess[str] = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            first_line: str = result.stdout.strip().split("\n")[0].strip()
            used_mb: int = int(first_line)
            used_gb: float = used_mb / 1024.0
            print(f"[VRAM] {used_gb:.1f} GB used (waiting for < {threshold_gb} GB)...")
            if used_gb < threshold_gb:
                print(f"[VRAM] Threshold reached ({used_gb:.1f} GB). Proceeding.")
                return True
        time.sleep(float(poll_interval_s))
    print(
        f"[VRAM WARNING] Timeout after {timeout_s}s — VRAM did not drop below {threshold_gb} GB. Proceeding anyway."
    )
    return False


# --- CONFIG (Godot project = repository root; see docs/gen3d_workplan.md) ---
GODOT_ROOT: str = str(_REPO_ROOT)
GEN3D_ROOT: str = str(_GEN3D_ROOT)
COMFYUI_PORT: int = 8188
TRELLIS_MODEL: str = "microsoft/TRELLIS.2-4B"

# TRELLIS_INPUT_FORMAT — determined by A/B test on 2026-04-20 (TRELLIS.2-4B, seed=42).
# Winner: front panel only (left third of 3-view Comfy hires sheet), rembg + hard alpha,
#         then square prep resize to 768 px, RGB to the sampler (see prepare_trellis_input).
# v3b dec non-manifold edges @10k faces: 9310 (matched to_glb: texture 512, predec 50k) vs v4 9472, v5 9874.
# Full-sheet v1/v2 ~9791–9840 at default to_glb; still risks multi-body reconstruction visually.
# Square prep size matches ``FOULWARD_TRELLIS_INPUT_EDGE`` (default 768 in stage2_mesh).
_trellis_edge: int = int(os.environ.get("FOULWARD_TRELLIS_INPUT_EDGE", "768"))
TRELLIS_INPUT_SIZE: tuple[int, int] = (_trellis_edge, _trellis_edge)
TRELLIS_INPUT_MODE: str = "RGB"  # tensor fed to TRELLIS after prepare_trellis_input
TRELLIS_CROP_TO_FRONT: bool = True  # crop_front_view: left third of turnaround sheet

MIXAMO_EMAIL: str = os.environ.get("MIXAMO_EMAIL", "")
MIXAMO_PASSWORD: str = os.environ.get("MIXAMO_PASSWORD", "")

# STYLE_FOOTER — optimised for TRELLIS 3D reconstruction quality.
# Key principles: simple silhouette, flat color regions, no surface engravings,
# strong shape readability. Detailed surface texture is baked in post; TRELLIS
# needs clean geometry input.
STYLE_FOOTER: str = (
    "Game character concept art. Clean simple silhouette. "
    "Flat color regions with minimal surface detail. "
    "No engravings, no surface patterns, no fine texture. "
    "Strong readable shape from a distance. "
    "White background. Front view only, full body, T-pose, "
    "arms slightly extended from body. No cast shadows. "
    "Style: simplified Warhammer Fantasy, chunky proportions, "
    "dark humor tone. Matte colors. "
    "DO NOT show multiple views. Single front-facing character only."
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

# Character slug → weapon scene ids and Mixamo-style attach bones (for post-import wiring).
WEAPON_ASSIGNMENTS: dict[str, list[tuple[str, str]]] = {
    "arnulf": [("weapon_iron_shovel", "RightHand")],
    "florence": [("weapon_crossbow", "RightHand")],
    "sybil": [("weapon_stone_staff", "RightHand")],
    "orc_grunt": [("weapon_iron_cleaver", "RightHand")],
    "orc_brute": [("weapon_iron_maul", "RightHand")],
    "orc_archer": [("weapon_bone_recurve_bow", "RightHand")],
    "orc_berserker": [
        ("weapon_dual_axes", "RightHand"),
        ("weapon_dual_axes", "LeftHand"),
    ],
    "orc_shaman_boar_rider": [("weapon_skull_staff", "RightHand")],
    "herald_of_worms": [("weapon_skull_staff", "RightHand")],
}


def canonical_slug(unit_name: str) -> str:
    """Single-token slug for named heroes (e.g. 'Florence the ...' -> ``florence``)."""
    parts: list[str] = unit_name.lower().strip().split()
    if len(parts) == 0:
        return "unnamed"
    if parts[0] in PERSONAL_NAMES:
        return parts[0]
    return "_".join(parts)


def stop_comfyui_and_wait_for_vram() -> None:
    """
    Kill ComfyUI on port 8188 and wait for VRAM to be released.
    Always called after Stage 1 on this machine (FLUX.1-dev + TRELLIS
    cannot coexist on 24 GB). If you switch to FLUX.1-schnell fp8
    (~6 GB), you can skip this by setting SKIP_COMFYUI_SHUTDOWN=1.
    """
    if os.environ.get("SKIP_COMFYUI_SHUTDOWN", "0") == "1":
        print("[1/5] SKIP_COMFYUI_SHUTDOWN=1 — leaving ComfyUI running (only safe with small model)")
        return

    print("[1/5] Stopping ComfyUI to free VRAM for TRELLIS...")
    subprocess.run(
        ["pkill", "-f", "main.py.*8188"],
        capture_output=True,
    )
    time.sleep(3)
    try:
        import requests as _req

        _req.post("http://127.0.0.1:8188/api/quit", timeout=3)
    except Exception:
        pass
    time.sleep(2)
    wait_for_vram_free(threshold_gb=12.0, timeout_s=120)
    print("[1/5] VRAM released. Ready for TRELLIS.")


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


def select_candidate(
    candidates: list[str],
    slug: str,
    project_root: str,
    auto: bool = False,
) -> tuple[str, int]:
    """
    Present the N candidate GLBs to the user and let them pick one.
    Writes ``selected.glb`` into ``art/gen3d_candidates/{slug}/`` and returns
    ``(selected_path, chosen_index_1based)``.

    In auto mode (``auto=True``, used by ``generate_all.sh``) silently picks
    candidate 1 without prompting.

    Args:
        candidates:    List of decimated candidate GLB paths (from generate_mesh_variants).
        slug:          Asset slug (e.g. "orc_grunt").
        project_root:  Godot project root path.
        auto:          If True, skip the prompt and select candidate 1.

    Returns:
        (selected_path, chosen_index) — path to the selected GLB and its 1-based index.
    """
    import shutil

    dest_dir: str = os.path.join(project_root, "art", "gen3d_candidates", slug)
    os.makedirs(dest_dir, exist_ok=True)

    print(f"\n{'=' * 60}")
    print(f"  {len(candidates)} mesh variants generated for: {slug}")
    for i, p in enumerate(candidates, 1):
        dst: str = os.path.join(dest_dir, f"candidate_{i}_decimated.glb")
        # Candidates were already copied during generate_mesh_variants; skip if present.
        if not os.path.exists(dst):
            shutil.copy2(p, dst)
        print(f"    [{i}] {dst}")
    print(f"{'=' * 60}")

    chosen: int
    if auto:
        chosen = 1
        print(f"[AUTO] Selecting candidate 1")
    else:
        while True:
            try:
                raw: str = input(f"  Select variant [1–{len(candidates)}]: ").strip()
                chosen = int(raw)
                if 1 <= chosen <= len(candidates):
                    break
                print(f"  Enter a number between 1 and {len(candidates)}.")
            except (ValueError, EOFError):
                chosen = 1
                print("  Invalid input. Defaulting to 1.")
                break

    src: str = os.path.join(dest_dir, f"candidate_{chosen}_decimated.glb")
    dst_selected: str = os.path.join(dest_dir, "selected.glb")
    shutil.copy2(src, dst_selected)
    print(f"\n  → Selected variant {chosen}: {dst_selected}")
    return dst_selected, chosen


def run_pipeline(unit_name: str, faction: str, asset_type: str = "enemy") -> None:
    from pipeline.stage1_image import clean_alpha_for_trellis, crop_front_view, generate_reference_sheet
    from pipeline.stage2_mesh import generate_mesh_variants, remove_background
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

    decimate_targets: dict[str, int] = {
        "enemy": 10000,
        "ally": 10000,
        "building": 8000,
        "boss": 20000,
    }
    target_faces: int = decimate_targets.get(asset_type, 10000)

    # ── Skip-stage env vars (used by promote_candidate.py to re-run 3-5 only) ──
    skip_stage1: bool = os.environ.get("SKIP_STAGE1", "0") == "1"
    skip_stage2: bool = os.environ.get("SKIP_STAGE2", "0") == "1"
    selected_glb_env: str = os.environ.get("SELECTED_GLB", "").strip()

    # ── Stage 1 — 2D reference sheet ────────────────────────────────────────
    nobg_path: str = f"/tmp/fw_{slug}_front_nobg.png"
    clean_path: str = f"/tmp/fw_{slug}_front_clean.png"
    mesh_image_path: str = nobg_path

    if skip_stage1:
        print("[1/5] SKIP_STAGE1=1 — skipping ComfyUI image generation")
    else:
        img_path: str = generate_reference_sheet(
            description,
            faction_block,
            STYLE_FOOTER,
            out_path=f"/tmp/fw_{slug}_ref.png",
            port=COMFYUI_PORT,
            faction=faction,
        )
        print(f"[1/5] Reference sheet saved: {img_path}")

        front_path: str = f"/tmp/fw_{slug}_front.png"
        crop_front_view(img_path, front_path)
        print(f"[1b]  Front view cropped: {front_path}")

        remove_background(front_path, nobg_path)
        print(f"[1c]  Background removed: {nobg_path}")

        # Stage 1d — binarise alpha to remove semi-transparent fringe pixels
        clean_alpha_for_trellis(nobg_path, clean_path)
        mesh_image_path = clean_path
        print(f"[1d]  Alpha cleaned: {clean_path}")

        stop_comfyui_and_wait_for_vram()

    # ── Stage 2 — N-variant mesh generation + selection ─────────────────────
    if skip_stage2 and selected_glb_env:
        selected_glb: str = selected_glb_env
        print(f"[2/5] SKIP_STAGE2=1 — using SELECTED_GLB: {selected_glb}")
    else:
        n_variants: int = int(os.environ.get("N_MESH_VARIANTS", "5"))
        auto_select: bool = os.environ.get("AUTO_SELECT_CANDIDATE", "0") == "1"
        candidates_dir: str = f"/tmp/fw_{slug}_candidates"

        candidate_paths: list[str] = generate_mesh_variants(
            mesh_image_path,
            out_dir=candidates_dir,
            model_id=TRELLIS_MODEL,
            tri_budget=target_faces,
            n_variants=n_variants,
            slug=slug,
            project_root=GODOT_ROOT,
        )
        print(f"[2/5] {len(candidate_paths)} variants ready in {candidates_dir}")

        selected_glb, chosen_idx = select_candidate(
            candidate_paths,
            slug=slug,
            project_root=GODOT_ROOT,
            auto=auto_select,
        )
        print(f"[2b]  Selected variant {chosen_idx}: {selected_glb}")

        # Sidecar metadata alongside the candidates
        import json as _json

        meta: dict[str, object] = {
            "slug": slug,
            "unit_name": unit_name,
            "faction": faction,
            "asset_type": asset_type,
            "n_variants": n_variants,
            "selected": chosen_idx,
        }
        meta_path: str = os.path.join(
            GODOT_ROOT, "art", "gen3d_candidates", slug, "meta.json"
        )
        with open(meta_path, "w", encoding="utf-8") as _f:
            _json.dump(meta, _f, indent=2)
        print(f"[2c]  Metadata: {meta_path}")

    # ── Stage 3 — rigging (selected variant only) ────────────────────────────
    glb_rigged: str = rig_model(
        selected_glb,
        out_path=f"/tmp/fw_{slug}_rigged.glb",
        mixamo_email=MIXAMO_EMAIL,
        mixamo_password=MIXAMO_PASSWORD,
        asset_type=asset_type,
    )
    print(f"[3/5] Rigged GLB: {glb_rigged}")

    # ── Stage 4 — animation merge ────────────────────────────────────────────
    anim_library_dir: str = os.path.join(GEN3D_ROOT, "anim_library")
    glb_final: str = merge_animations(
        glb_rigged,
        clips=anim_clips,
        anim_library_dir=anim_library_dir,
        out_path=f"/tmp/fw_{slug}_final.glb",
    )
    print(f"[4/5] Animated GLB: {glb_final}")

    # ── Stage 5 — drop to Godot project ─────────────────────────────────────
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
