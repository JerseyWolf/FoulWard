/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/foulward_gen.py
========================

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

========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/stage1_image.py
========================

# SPDX-License-Identifier: MIT
"""Stage 1: ComfyUI HTTP API — FLUX.1 dev reference sheet with optional LoRA strengths."""

from __future__ import annotations

import json
import os
import random
import shutil
import time
from pathlib import Path
from typing import Any

import numpy as np
import requests
from PIL import Image, ImageFilter

# Per-faction ceilings (validated); build_workflow_with_loras caps workflow JSON to these maxima.
LORA_STRENGTHS: dict[str, dict[str, float]] = {
    "orc_raiders": {"turnaround": 0.4, "baroque": 0.5, "velvet": 0.4},
    "plague_cult": {"turnaround": 0.4, "baroque": 0.5, "velvet": 0.3},
    "allies": {"turnaround": 0.4, "baroque": 0.3, "velvet": 0.4},
    "buildings": {"turnaround": 0.3, "baroque": 0.4, "velvet": 0.2},
}


def _workflow_nodes(workflow: dict[str, Any]) -> dict[str, Any]:
    """Normalize: ComfyUI API JSON is a flat map of node_id -> {class_type, inputs}."""
    return workflow


def _iter_clip_text_encode_nodes(workflow: dict[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    out: list[tuple[str, dict[str, Any]]] = []
    for node_id, node in _workflow_nodes(workflow).items():
        if not isinstance(node, dict):
            continue
        ct: str = str(node.get("class_type", ""))
        if "CLIPTextEncode" in ct or ct == "CLIPTextEncode":
            out.append((node_id, node))
    return out


def _iter_lora_loader_nodes(workflow: dict[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    out: list[tuple[str, dict[str, Any]]] = []
    for node_id, node in _workflow_nodes(workflow).items():
        if not isinstance(node, dict):
            continue
        ct: str = str(node.get("class_type", ""))
        if "LoraLoader" in ct or ct == "LoraLoader":
            out.append((node_id, node))
    # Stable order: numeric sort when possible
    def sort_key(t: tuple[str, dict[str, Any]]) -> tuple[int, str]:
        try:
            return (int(t[0]), t[0])
        except ValueError:
            return (999999, t[0])

    out.sort(key=sort_key)
    return out


def build_workflow_with_loras(
    workflow: dict[str, Any],
    prompt: str,
    faction: str,
) -> dict[str, Any]:
    """Inject prompt text, random seed, and per-faction LoRA strengths."""
    strengths: dict[str, float] = LORA_STRENGTHS.get(faction, LORA_STRENGTHS["orc_raiders"])
    keys: tuple[str, str, str] = ("turnaround", "baroque", "velvet")

    clip_nodes: list[tuple[str, dict[str, Any]]] = _iter_clip_text_encode_nodes(workflow)
    if not clip_nodes:
        raise RuntimeError(
            "ComfyUI workflow has no CLIPTextEncode node. Export API JSON from ComfyUI "
            "and save as workflows/turnaround_flux.json (see workflows/README_COMFYUI.md)."
        )
    # Positive prompt: FLUX turnaround workflow uses node "7" (CLIPTextEncodeFlux).
    n7: Any = workflow.get("7")
    if isinstance(n7, dict) and str(n7.get("class_type", "")) == "CLIPTextEncodeFlux":
        ins7: dict[str, Any] = n7.setdefault("inputs", {})
        ins7["clip_l"] = prompt
        ins7["t5xxl"] = prompt
    else:
        # First positive prompt node (JSON key order: first CLIP encode = positive)
        _nid, first_clip = clip_nodes[0]
        inputs: dict[str, Any] = first_clip.setdefault("inputs", {})
        ct_first: str = str(first_clip.get("class_type", ""))
        if ct_first == "CLIPTextEncodeFlux" or ct_first.endswith("CLIPTextEncodeFlux"):
            inputs["clip_l"] = prompt
            inputs["t5xxl"] = prompt
        else:
            inputs["text"] = prompt

    # Randomize seeds across any node that exposes one (KSampler `seed`,
    # FLUX `RandomNoise` `noise_seed`, etc.).
    new_seed: int = random.randint(0, 2**32 - 1)
    for node in _workflow_nodes(workflow).values():
        if not isinstance(node, dict):
            continue
        nin: dict[str, Any] | None = node.get("inputs")
        if not isinstance(nin, dict):
            continue
        if "seed" in nin and isinstance(nin["seed"], (int, float)):
            nin["seed"] = new_seed
        if "noise_seed" in nin and isinstance(nin["noise_seed"], (int, float)):
            nin["noise_seed"] = new_seed

    loras: list[tuple[str, dict[str, Any]]] = _iter_lora_loader_nodes(workflow)
    # When workflow JSON pins all three LoRAs to 0.0 (NaN / black-PNG isolation), do not
    # apply per-faction strengths — would undo the workaround in turnaround_flux.json.
    all_lora_zero: bool = True
    for _lid, lnode in loras[:3]:
        lin0: dict[str, Any] = lnode.get("inputs", {})
        if not isinstance(lin0, dict):
            all_lora_zero = False
            break
        sm0: float = float(lin0.get("strength_model", -1.0))
        sc0: float = float(lin0.get("strength_clip", -1.0))
        if sm0 != 0.0 or sc0 != 0.0:
            all_lora_zero = False
            break
    if not all_lora_zero:
        for i, (_lid, lnode) in enumerate(loras[:3]):
            if i >= len(keys):
                break
            lin: dict[str, Any] = lnode.setdefault("inputs", {})
            s = strengths[keys[i]]
            if "strength_model" not in lin and "strength_clip" not in lin:
                continue
            cur_m: float = float(lin.get("strength_model", 0.0))
            cur_c: float = float(lin.get("strength_clip", 0.0))
            if cur_m == 0.0 and cur_c == 0.0:
                continue
            # Cap at faction maximum (validated); never exceed LORA_STRENGTHS for this slot.
            lin["strength_model"] = min(cur_m, s)
            lin["strength_clip"] = min(cur_c, s)

    return workflow


def _first_output_image_path(history_entry: dict[str, Any]) -> tuple[str, str] | None:
    """Return (node_id, filename) for ComfyUI history outputs.

    Prefer node 101 (upscaled 2048x2048 ``foulward_turnaround_hires_*``) when present.
    """
    outputs: dict[str, Any] = history_entry.get("outputs", {})
    preferred_id: str = "101"
    if preferred_id in outputs:
        out101: Any = outputs[preferred_id]
        if isinstance(out101, dict):
            images101: list[Any] | None = out101.get("images")
            if images101 and isinstance(images101, list) and len(images101) > 0:
                img0: Any = images101[0]
                if isinstance(img0, dict) and "filename" in img0:
                    return (preferred_id, str(img0["filename"]))
    for node_id, out in outputs.items():
        if not isinstance(out, dict):
            continue
        images: list[Any] | None = out.get("images")
        if images and isinstance(images, list) and len(images) > 0:
            img1: Any = images[0]
            if isinstance(img1, dict) and "filename" in img1:
                return (str(node_id), str(img1["filename"]))
    return None


def generate_reference_sheet(
    unit_name: str,
    faction_block: str,
    style_footer: str,
    out_path: str,
    port: int = 8188,
    faction: str = "orc_raiders",
    comfyui_output_dir: Path | None = None,
) -> str:
    """POST workflow to ComfyUI, poll history, copy PNG to out_path."""
    gen3d_root: Path = Path(__file__).resolve().parent.parent
    workflow_name: str = os.environ.get("FOULWARD_GEN3D_WORKFLOW", "turnaround_flux.json")
    workflow_path: Path = gen3d_root / "workflows" / workflow_name
    if not workflow_path.is_file():
        raise FileNotFoundError(
            f"Missing {workflow_path}. Build a FLUX + LoRA graph in ComfyUI, "
            "then Save (API Format) and replace this file. See workflows/README_COMFYUI.md."
        )

    with workflow_path.open("r", encoding="utf-8") as f:
        workflow: dict[str, Any] = json.load(f)

    full_prompt: str = (
        f"Character design turnaround sheet, front view, right side view, back view, "
        f"isolated on white background.\n{unit_name}.\n{faction_block}\n{style_footer}"
    )
    workflow = build_workflow_with_loras(workflow, full_prompt, faction)

    base: str = f"http://127.0.0.1:{port}"
    r: requests.Response = requests.post(
        f"{base}/prompt",
        json={"prompt": workflow},
        timeout=60,
    )
    r.raise_for_status()
    data: dict[str, Any] = r.json()
    prompt_id: str | None = data.get("prompt_id")
    if not prompt_id:
        raise RuntimeError(f"ComfyUI /prompt unexpected response: {data}")

    out_file: Path = Path(out_path)
    out_file.parent.mkdir(parents=True, exist_ok=True)

    if comfyui_output_dir is None:
        comfyui_output_dir = Path.home() / "ComfyUI" / "output"

    deadline: float = time.time() + 3600.0
    while time.time() < deadline:
        hr: requests.Response = requests.get(f"{base}/history/{prompt_id}", timeout=30)
        hr.raise_for_status()
        hist: dict[str, Any] = hr.json()
        if prompt_id not in hist:
            time.sleep(2.0)
            continue
        entry: dict[str, Any] = hist[prompt_id]
        found: tuple[str, str] | None = _first_output_image_path(entry)
        if not found:
            time.sleep(2.0)
            continue
        _node_id, filename = found
        src: Path = comfyui_output_dir / filename
        if not src.is_file():
            # Subfolder in output
            for p in comfyui_output_dir.rglob(filename):
                if p.is_file():
                    src = p
                    break
        if not src.is_file():
            raise FileNotFoundError(f"ComfyUI reported output {filename} but file not found under {comfyui_output_dir}")
        shutil.copy2(src, out_file)
        img = Image.open(out_file).convert("RGB")
        arr: np.ndarray = np.array(img)
        black_ratio: float = float((arr < 10).all(axis=2).mean())
        if black_ratio > 0.95:
            raise RuntimeError(
                f"Stage 1 produced a {black_ratio * 100:.0f}% black image. "
                f"Likely NaN from VAEDecode. Check ComfyUI log for 'invalid value encountered in cast'. "
                f"Current workaround: LoRAs are disabled — check workflow node 4/5/6 strengths."
            )
        return str(out_file.resolve())

    raise TimeoutError("ComfyUI did not finish within 1 hour.")


def crop_front_view(sheet_path: str, out_path: str) -> str:
    """
    Crop the leftmost third of a front/side/back turnaround sheet.

    ComfyUI / FLUX workflow produces a hires sheet (typically 2048² after upscale)
    with three views laid out
    horizontally left-to-right (front, side, back), each panel
    approximately one third of the sheet width (e.g. ~682 px at 2048²).
    This function extracts only the front view for TRELLIS input; see
    ``docs/PROMPT_87_IMPLEMENTATION.md`` for the 2026-04-20 input-format A/B.

    Args:
        sheet_path: Path to the full turnaround sheet PNG.
        out_path:   Where to save the cropped front-view PNG.

    Returns:
        out_path after saving.
    """
    img = Image.open(sheet_path)
    w, h = img.size
    # Front view is the leftmost third of the sheet
    front = img.crop((0, 0, w // 3, h))
    front.save(out_path)
    return out_path


def clean_alpha_for_trellis(image_path: str, out_path: str, threshold: int = 128) -> str:
    """
    Binarise the alpha channel of an RGBA image so every pixel is either
    fully opaque (alpha=255) or fully transparent (alpha=0).
    Semi-transparent fringe pixels from rembg cause TRELLIS to hallucinate
    thin geometry sheets which explode into razor shards after decimation.

    Args:
        image_path: Path to RGBA PNG (rembg output).
        out_path:   Where to save the cleaned RGBA PNG.
        threshold:  Pixels with alpha >= threshold → 255, else → 0. Default 128.

    Returns:
        out_path after saving.
    """
    img: Image.Image = Image.open(image_path).convert("RGBA")
    arr: np.ndarray = np.array(img, dtype=np.uint8)

    # Hard alpha threshold
    arr[:, :, 3] = np.where(arr[:, :, 3] >= threshold, 255, 0)

    # Erode the mask by 1px (3x3 min filter) to reduce fringe artifacts at silhouette edges
    mask: Image.Image = Image.fromarray(arr[:, :, 3], mode="L")
    mask_eroded: Image.Image = mask.filter(ImageFilter.MinFilter(size=3))
    arr[:, :, 3] = np.array(mask_eroded, dtype=np.uint8)

    Image.fromarray(arr).save(out_path)
    return out_path

========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/stage2_mesh.py
========================

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


def remove_background(image_path: str, out_path: str) -> str:
    """
    Remove the background from a character image using rembg, producing
    an RGBA PNG with a transparent background. TRELLIS performs significantly
    better on transparent-background RGBA images than white-background RGB —
    it cannot misinterpret the white background as geometry.

    Uses ``rembg`` from the **current** Python interpreter (run foulward_gen
    with ``conda run -n trellis2`` or ``$FOULWARD_PYTHON`` pointing at trellis2).
    Nested ``conda run`` subprocesses are avoided because they fail when the
    pipeline itself is already launched via ``conda run``.

    Args:
        image_path: Path to the input image (white background PNG).
        out_path:   Where to save the output RGBA PNG.

    Returns:
        out_path after saving.
    """
    from rembg import remove

    with open(image_path, "rb") as f:
        data: bytes = f.read()
    out_bytes: bytes = remove(data)
    with open(out_path, "wb") as f:
        f.write(out_bytes)
    return out_path


def clean_mesh_before_decimation(mesh: trimesh.Trimesh) -> trimesh.Trimesh:
    """
    Apply trimesh cleaning operations to remove degenerate geometry
    before decimation. This reduces the chance that the decimator collapses
    legitimate faces into degenerate ones, which can produce razor-shard
    artifacts on noisy TRELLIS output.

    Operations applied in order:
    1. merge_vertices — weld duplicate/near-duplicate vertices
    2. remove degenerate faces (zero-area)
    3. remove duplicate faces (overlapping copies)
    4. fix_winding / fix_normals — consistent winding order
    5. remove_unreferenced_vertices
    """
    from trimesh import repair

    original_faces: int = int(len(mesh.faces))

    mesh.merge_vertices(merge_tex=False, merge_norm=False)

    mesh.update_faces(mesh.nondegenerate_faces())
    mesh.update_faces(mesh.unique_faces())

    repair.fix_winding(mesh)
    repair.fix_normals(mesh)

    mesh.remove_unreferenced_vertices()

    cleaned_faces: int = int(len(mesh.faces))
    removed: int = original_faces - cleaned_faces
    print(
        f"[clean] Removed {removed} degenerate/duplicate faces "
        f"({original_faces} → {cleaned_faces})"
    )

    if original_faces > 0 and removed > original_faces * 0.3:
        print("[clean] WARNING: >30% faces removed — input mesh was very noisy")

    return mesh


def _load_combined_mesh(input_path: str) -> trimesh.Trimesh:
    """Load a GLB and return a single combined Trimesh, preserving visual data."""
    scene: Any = trimesh.load(input_path, process=False, force="scene")
    if isinstance(scene, trimesh.Scene):
        meshes: list[trimesh.Trimesh] = [
            g for g in scene.geometry.values() if isinstance(g, trimesh.Trimesh)
        ]
        if not meshes:
            raise ValueError(f"No triangle meshes found in {input_path}")
        if len(meshes) == 1:
            return meshes[0]
        return trimesh.util.concatenate(meshes)
    return scene  # type: ignore[return-value]


def _decimate_o3d(
    vertices: Any,
    faces: Any,
    target_faces: int,
) -> tuple[Any, Any, Any]:
    """
    Decimate geometry with Open3D quadric decimation.

    Returns (verts_out, faces_out, normals_out) as numpy arrays.
    Open3D correctly reaches the target face count even on non-manifold TRELLIS
    meshes. Visual data is intentionally NOT passed in; callers preserve it via
    nearest-vertex re-projection after this call.
    """
    import numpy as np
    import open3d as o3d

    o3d_mesh: o3d.geometry.TriangleMesh = o3d.geometry.TriangleMesh()
    o3d_mesh.vertices = o3d.utility.Vector3dVector(
        np.asarray(vertices, dtype=np.float64).copy()
    )
    o3d_mesh.triangles = o3d.utility.Vector3iVector(
        np.asarray(faces, dtype=np.int32).copy()
    )
    decimated: o3d.geometry.TriangleMesh = o3d_mesh.simplify_quadric_decimation(
        target_number_of_triangles=int(target_faces)
    )
    decimated.compute_vertex_normals()
    verts_out: Any = np.asarray(decimated.vertices, dtype=np.float64)
    faces_out: Any = np.asarray(decimated.triangles, dtype=np.int64)
    normals_out: Any = np.asarray(decimated.vertex_normals, dtype=np.float64)
    return verts_out, faces_out, normals_out


def decimate_glb(input_path: str, out_path: str, target_faces: int = 10000) -> str:
    """
    Decimate a GLB mesh to approximately target_faces triangles while
    preserving UV maps, vertex colors, and PBR materials.

    Strategy:
      1. Load with trimesh (preserves full visual/material data).
      2. Decimate geometry with Open3D's simplify_quadric_decimation.
         Open3D reliably reaches the target face count even on the
         non-manifold TRELLIS meshes (fast_simplification plateaus at
         ~38k faces due to seam-vertex topology on these meshes).
      3. Re-project visual data from the original high-res mesh onto
         decimated vertices via scipy cKDTree nearest-vertex lookup.
         For TextureVisuals: re-project UV + reattach PBRMaterial.
         For ColorVisuals: re-project per-vertex RGBA colors.
         For geometry-only meshes: export normals only (no change).
      4. Export as GLB with textures/materials fully embedded.

    Args:
        input_path:   Path to raw GLB from TRELLIS.
        out_path:     Where to save the decimated GLB.
        target_faces: Target triangle count. Default 10000 for standard units.

    Returns:
        out_path after saving.
    """
    import numpy as np
    from scipy.spatial import cKDTree

    combined: trimesh.Trimesh = _load_combined_mesh(input_path)
    print(
        f"[decimate] Input: {len(combined.vertices)} verts, {len(combined.faces)} faces"
        f"  visual={type(combined.visual).__name__}"
    )

    combined = clean_mesh_before_decimation(combined)

    has_uv: bool = (
        isinstance(combined.visual, trimesh.visual.TextureVisuals)
        and combined.visual.uv is not None
        and len(combined.visual.uv) > 0
    )
    has_vc: bool = isinstance(combined.visual, trimesh.visual.ColorVisuals)
    print(f"[decimate] has_uv={has_uv}, has_vertex_colors={has_vc}")

    # Capture original visual data before geometry decimation
    original_uvs: Any = combined.visual.uv.copy() if has_uv else None
    original_material: Any = combined.visual.material if has_uv else None
    original_vc: Any = None
    if has_vc:
        try:
            original_vc = combined.visual.vertex_colors.copy()
        except Exception:
            original_vc = None

    # Geometry decimation via Open3D
    verts_out, faces_out, normals_out = _decimate_o3d(
        combined.vertices, combined.faces, target_faces
    )
    print(f"[decimate] Output: {len(verts_out)} verts, {len(faces_out)} faces")

    # Nearest-vertex UV/color re-projection from original high-res mesh
    tree: cKDTree = cKDTree(combined.vertices)
    _, idx = tree.query(verts_out, k=1)

    if has_uv and original_uvs is not None and original_material is not None:
        new_uvs: Any = original_uvs[idx]
        print(f"[decimate] UV reprojected: {new_uvs.shape}  material={type(original_material).__name__}")
        decimated_mesh: trimesh.Trimesh = trimesh.Trimesh(
            vertices=verts_out,
            faces=faces_out,
            vertex_normals=normals_out,
            process=False,
        )
        decimated_mesh.visual = trimesh.visual.TextureVisuals(
            uv=new_uvs,
            material=original_material,
        )
    elif has_vc and original_vc is not None:
        new_vc: Any = original_vc[idx]
        unique_colors: int = len(np.unique(new_vc, axis=0))
        print(f"[decimate] Vertex colors reprojected: {unique_colors} unique")
        decimated_mesh = trimesh.Trimesh(
            vertices=verts_out,
            faces=faces_out,
            vertex_normals=normals_out,
            vertex_colors=new_vc,
            process=False,
        )
    else:
        print("[decimate] No UV/color data — geometry-only output")
        decimated_mesh = trimesh.Trimesh(
            vertices=verts_out,
            faces=faces_out,
            vertex_normals=normals_out,
            process=False,
        )

    export_scene: trimesh.Scene = trimesh.scene.scene.Scene(
        geometry={"geometry_0": decimated_mesh}
    )
    export_scene.export(out_path, file_type="glb")
    return out_path


# TRELLIS input square edge after pad (see tools/gen3d/scripts/trellis2_input_ab_variant.py A/B 2026-04-20).
# Community often uses ~770; front-only + 768 beat 770 and full-sheet configs on decimated NM proxy.
TRELLIS_INPUT_SIZE: int = int(os.environ.get("FOULWARD_TRELLIS_INPUT_EDGE", "768"))
# Texture bake resolution: 2048 for production quality
TEXTURE_RESOLUTION: int = 2048
# TRELLIS sparse / slat sampler steps — lower reduces internal-structure hallucination.
TRELLIS_SAMPLER_STEPS: int = int(os.environ.get("FOULWARD_TRELLIS_SAMPLER_STEPS", "8"))
TRELLIS_SPARSE_GUIDANCE: float = float(os.environ.get("FOULWARD_TRELLIS_SPARSE_GUIDANCE", "5.0"))
TRELLIS_SLAT_GUIDANCE: float = float(os.environ.get("FOULWARD_TRELLIS_SLAT_GUIDANCE", "2.0"))
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


def prepare_trellis_input(image_path: str, out_path: str) -> str:
    from PIL import Image, ImageOps

    img = Image.open(image_path).convert("RGBA")
    # Pad to square using white background, keep subject centered
    w, h = img.size
    size = max(w, h)
    padded = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    padded.paste(img, ((size - w) // 2, (size - h) // 2))
    edge: int = int(TRELLIS_INPUT_SIZE)
    padded = padded.resize((edge, edge), Image.LANCZOS)
    padded.convert("RGB").save(out_path)
    return out_path


def image_to_glb(
    image_path: str,
    out_path: str,
    model_id: str = "microsoft/TRELLIS.2-4B",
    tri_budget: int = 12000,
    seed: int | None = None,
) -> str:
    """
    Mesh from image, or bypass TRELLIS when ``FOULWARD_GEN3D_STAGE2_MODE`` is set.

    Args:
        image_path: Path to the front-view RGBA PNG (background-removed).
        out_path:   Where to save the raw textured GLB.
        model_id:   HuggingFace model ID for TRELLIS.2.
        tri_budget: Reserved for future use (TRELLIS pre-decimation handled via
                    ``FOULWARD_TRELLIS_PREDECIMATE`` env var; see below).
        seed:       Random seed for TRELLIS generation. ``None`` → random 32-bit seed.
                    Different seeds produce shape variants from the same image.

    Returns:
        out_path after saving.

    Environment variables:
        FOULWARD_TRELLIS_PREDECIMATE: Pre-decimation target inside TRELLIS's
            ``o_voxel.postprocess.to_glb``. Default 100000. Reduces raw GLB from
            ~38 MB to ~4 MB. Our ``decimate_glb`` step further reduces to target_faces.
            Set to a higher value (e.g. 1000000) for maximum source detail.
    """
    import random as _random

    _ = tri_budget  # reserved
    out_p: Path = Path(out_path).resolve()
    out_p.parent.mkdir(parents=True, exist_ok=True)

    if seed is None:
        seed = _random.randint(0, 2**32 - 1)
    print(f"[stage2] seed={seed}")

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

    # Set seeds before generation for reproducibility
    import torch as _torch
    _torch.manual_seed(seed)
    if _torch.cuda.is_available():
        _torch.cuda.manual_seed_all(seed)

    trellis_input_path: str = prepare_trellis_input(
        image_path, image_path.replace(".png", "_trellis_input.png")
    )
    front_resized = Image.open(trellis_input_path).convert("RGB")
    print(f"[stage2] TRELLIS input: {trellis_input_path}")

    # TRELLIS pre-decimation target: default 100000 (from ~38MB raw → ~4MB).
    # Our decimate_glb step further reduces to the game-ready target (8k–20k).
    predecimate: int = int(os.environ.get("FOULWARD_TRELLIS_PREDECIMATE", "100000"))

    print(
        f"[stage2] Generating mesh"
        f" (sampler_steps={TRELLIS_SAMPLER_STEPS}, sparse_guidance={TRELLIS_SPARSE_GUIDANCE},"
        f" slat_guidance={TRELLIS_SLAT_GUIDANCE}, texture_size={TEXTURE_RESOLUTION},"
        f" predecimate={predecimate})..."
    )
    with _torch.no_grad():
        result = pipeline.run(
            front_resized,
            seed=seed,
            sparse_structure_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SPARSE_GUIDANCE,
            },
            shape_slat_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SLAT_GUIDANCE,
            },
            tex_slat_sampler_params={
                "steps": TRELLIS_SAMPLER_STEPS,
                "guidance_strength": TRELLIS_SLAT_GUIDANCE,
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


def _check_glb_has_texture(path: str) -> bool:
    """
    Return True if the GLB at *path* contains UV map or multi-color vertex data.
    Used as a post-generation diagnostic: a white mesh (all-white vertex colors,
    no UV) indicates TRELLIS did not produce texture for this seed.
    """
    import numpy as np

    try:
        scene: Any = trimesh.load(path, process=False)
        meshes: list[trimesh.Trimesh] = (
            list(scene.geometry.values())
            if isinstance(scene, trimesh.Scene)
            else [scene]
        )
        for m in meshes:
            if (
                isinstance(m.visual, trimesh.visual.TextureVisuals)
                and m.visual.uv is not None
                and len(m.visual.uv) > 0
            ):
                return True
            if isinstance(m.visual, trimesh.visual.ColorVisuals):
                try:
                    vc: Any = m.visual.vertex_colors
                    if vc is not None and len(np.unique(vc, axis=0)) > 1:
                        return True
                except Exception:
                    pass
    except Exception:
        pass
    return False


def generate_mesh_variants(
    image_path: str,
    out_dir: str,
    model_id: str = "microsoft/TRELLIS.2-4B",
    tri_budget: int = 10000,
    n_variants: int = 5,
    slug: str = "unit",
    project_root: str = "",
) -> list[str]:
    """
    Run TRELLIS N times on the same input image with different random seeds,
    producing N candidate GLBs. Each variant is immediately decimated and
    copied to two locations:

      - ``out_dir/candidate_{i}_decimated.glb``   (ephemeral working dir in /tmp)
      - ``{project_root}/art/gen3d_candidates/{slug}/candidate_{i}_decimated.glb``
        (permanent project storage — kept across reboots for post-run review)

    Raw per-variant GLBs are deleted after decimation to save disk space.

    Args:
        image_path:    Path to the front-view RGBA PNG (background removed).
        out_dir:       Working directory for raw + decimated candidates (e.g. /tmp/fw_slug_candidates).
        model_id:      HuggingFace model ID for TRELLIS.2.
        tri_budget:    Target triangle count for each decimated candidate.
        n_variants:    Number of mesh variants to generate. Default 5.
        slug:          Asset slug (e.g. "orc_grunt") used for the permanent storage path.
        project_root:  Godot project root path. If empty, permanent copy is skipped.

    Returns:
        List of ``n_variants`` paths to decimated candidate GLBs in *out_dir*.
    """
    import os
    import random
    import shutil

    os.makedirs(out_dir, exist_ok=True)

    # Set up permanent storage dir alongside ephemeral /tmp working dir
    permanent_dir: str = ""
    if project_root:
        permanent_dir = os.path.join(project_root, "art", "gen3d_candidates", slug)
        os.makedirs(permanent_dir, exist_ok=True)

    candidates: list[str] = []
    for i in range(1, n_variants + 1):
        print(f"\n[Stage 2] ── Variant {i}/{n_variants} ──")
        seed: int = random.randint(0, 2**32 - 1)
        raw: str = os.path.join(out_dir, f"candidate_{i}_raw.glb")
        decimated: str = os.path.join(out_dir, f"candidate_{i}_decimated.glb")

        print(f"[Stage 2] Generating mesh (seed={seed})...")
        image_to_glb(image_path, raw, model_id=model_id, tri_budget=None, seed=seed)

        if not _check_glb_has_texture(raw):
            print(
                f"[Stage 2] WARNING: candidate {i} raw GLB has no UV/color data"
                f" (seed={seed}) — output will be white mesh."
            )
        else:
            print(f"[Stage 2] Texture confirmed in candidate {i} raw GLB ✓")

        print(f"[Stage 2] Decimating candidate {i} → {tri_budget} faces...")
        decimate_glb(raw, decimated, target_faces=tri_budget)

        try:
            os.remove(raw)
        except OSError:
            pass

        # Permanent project copy — write immediately so it survives a /tmp wipe
        if permanent_dir:
            perm_path: str = os.path.join(permanent_dir, f"candidate_{i}_decimated.glb")
            shutil.copy2(decimated, perm_path)
            print(f"[Stage 2] Candidate {i} saved: {decimated}")
            print(f"[Stage 2]   permanent copy:   {perm_path}")
        else:
            print(f"[Stage 2] Candidate {i} ready: {decimated}")

        candidates.append(decimated)

    return candidates

========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/stage3_rig.py
========================

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

========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/stage4_anim.py
========================

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

========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/stage5_drop.py
========================

# SPDX-License-Identifier: MIT
"""Stage 5: Copy final GLB into Foul Ward art/generated (flat paths)."""

from __future__ import annotations

import shutil
from pathlib import Path


def drop_to_godot(glb_path: str, unit_slug: str, output_dir: str) -> str:
    """Copy GLB to output_dir/{unit_slug}.glb. Godot creates .import on next editor scan."""
    src: Path = Path(glb_path).resolve()
    out_dir: Path = Path(output_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    dest: Path = out_dir / f"{unit_slug}.glb"
    shutil.copy2(src, dest)
    print(f"[stage5_drop] Dropped to {dest}")
    return str(dest)

========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/generate_all.sh
========================

#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Batch driver for foulward_gen.py — run from repo anywhere:
#   bash tools/gen3d/generate_all.sh
# Or: cd tools/gen3d && ./generate_all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

: "${FOULWARD_PYTHON:=python3}"
# Default 0: foulward_gen stops ComfyUI after Stage 1 and waits for VRAM before TRELLIS.
# Set SKIP_COMFYUI_SHUTDOWN=1 only with a small Comfy model (e.g. FLUX schnell fp8), not FLUX.1-dev on 24 GB.
: "${SKIP_COMFYUI_SHUTDOWN:=0}"
export SKIP_COMFYUI_SHUTDOWN

# Batch runs cannot prompt for variant selection — auto-select candidate 1.
# Override either variable on the command line before calling this script.
: "${AUTO_SELECT_CANDIDATE:=1}"
: "${N_MESH_VARIANTS:=5}"
export AUTO_SELECT_CANDIDATE N_MESH_VARIANTS

ensure_comfyui() {
    if curl -sSf "http://127.0.0.1:8188/system_stats" >/dev/null 2>&1; then
        return 0
    fi
    echo "Starting ComfyUI (--lowvram) on 127.0.0.1:8188..."
    nohup "$FOULWARD_PYTHON" "$HOME/ComfyUI/main.py" --listen 127.0.0.1 --port 8188 --lowvram >/tmp/comfyui.log 2>&1 &
    sleep 15
    curl -s "http://127.0.0.1:8188/system_stats" | python3 -c "import sys, json; json.load(sys.stdin); print('ComfyUI ready')" || {
        echo "ComfyUI failed to start"
        exit 1
    }
}

run() {
    local unit_name="$1"
    local faction="$2"
    local asset_type="$3"
    # Each pipeline run kills ComfyUI after Stage 1; ensure it is up before the next asset.
    curl -sSf "http://127.0.0.1:8188/system_stats" >/dev/null 2>&1 || ensure_comfyui
    echo "=== gen3d: $unit_name | $faction | $asset_type ==="
    "$FOULWARD_PYTHON" "$SCRIPT_DIR/foulward_gen.py" "$unit_name" "$faction" "$asset_type"
}

# ── Weapons (building type = no rig, geometry only) ──────────────────────
run "weapon_iron_shovel" buildings building
run "weapon_crossbow" buildings building
run "weapon_stone_staff" buildings building
run "weapon_iron_cleaver" buildings building
run "weapon_iron_maul" buildings building
run "weapon_skull_staff" buildings building
run "weapon_bone_recurve_bow" buildings building
run "weapon_dual_axes" buildings building

========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/workflows/turnaround_flux.json
========================

{
  "1": {
    "class_type": "UNETLoader",
    "inputs": {
      "unet_name": "flux1-dev.safetensors",
      "weight_dtype": "default"
    }
  },
  "2": {
    "class_type": "DualCLIPLoader",
    "inputs": {
      "clip_name1": "clip_l.safetensors",
      "clip_name2": "t5xxl_fp8_e4m3fn.safetensors",
      "type": "flux"
    }
  },
  "3": {
    "class_type": "VAELoader",
    "inputs": {
      "vae_name": "flux_ae.safetensors"
    }
  },
  "4": {
    "class_type": "LoraLoader",
    "inputs": {
      "model": [
        "1",
        0
      ],
      "clip": [
        "2",
        0
      ],
      "lora_name": "turnaround_sheet.safetensors",
      "strength_model": 0.4,
      "strength_clip": 0.4
    }
  },
  "5": {
    "class_type": "LoraLoader",
    "inputs": {
      "model": [
        "4",
        0
      ],
      "clip": [
        "4",
        1
      ],
      "lora_name": "baroque_fantasy_realism.safetensors",
      "strength_model": 0.5,
      "strength_clip": 0.5
    }
  },
  "6": {
    "class_type": "LoraLoader",
    "inputs": {
      "model": [
        "5",
        0
      ],
      "clip": [
        "5",
        1
      ],
      "lora_name": "velvet_mythic_flux.safetensors",
      "strength_model": 0.4,
      "strength_clip": 0.4
    }
  },
  "7": {
    "class_type": "CLIPTextEncodeFlux",
    "inputs": {
      "clip": [
        "6",
        1
      ],
      "clip_l": "",
      "t5xxl": "",
      "guidance": 3.5
    }
  },
  "8": {
    "class_type": "CLIPTextEncodeFlux",
    "inputs": {
      "clip": [
        "6",
        1
      ],
      "clip_l": "multiple views, turnaround sheet, side view, back view, detailed engravings, surface patterns, fine texture, photorealistic, subsurface scattering, specular highlights, complex shading, busy background",
      "t5xxl": "multiple views, turnaround sheet, side view, back view, detailed engravings, surface patterns, fine texture, photorealistic, subsurface scattering, specular highlights, complex shading, busy background",
      "guidance": 3.5
    }
  },
  "9": {
    "class_type": "EmptyLatentImage",
    "inputs": {
      "width": 1024,
      "height": 1024,
      "batch_size": 1
    }
  },
  "10": {
    "class_type": "KSampler",
    "inputs": {
      "model": [
        "6",
        0
      ],
      "seed": 0,
      "steps": 28,
      "cfg": 3.5,
      "sampler_name": "euler",
      "scheduler": "beta",
      "denoise": 1.0,
      "positive": [
        "7",
        0
      ],
      "negative": [
        "8",
        0
      ],
      "latent_image": [
        "9",
        0
      ]
    }
  },
  "11": {
    "class_type": "VAEDecode",
    "inputs": {
      "samples": [
        "10",
        0
      ],
      "vae": [
        "3",
        0
      ]
    }
  },
  "12": {
    "class_type": "SaveImage",
    "inputs": {
      "filename_prefix": "foulward_turnaround",
      "images": [
        "11",
        0
      ]
    }
  },
  "98": {
    "class_type": "UpscaleModelLoader",
    "inputs": {
      "model_name": "4x_NMKD-Superscale-SP_178000_G.pth"
    }
  },
  "99": {
    "class_type": "ImageUpscaleWithModel",
    "inputs": {
      "upscale_model": [
        "98",
        0
      ],
      "image": [
        "11",
        0
      ]
    }
  },
  "100": {
    "class_type": "ImageScale",
    "inputs": {
      "image": [
        "99",
        0
      ],
      "upscale_method": "lanczos",
      "width": 2048,
      "height": 2048,
      "crop": "disabled"
    }
  },
  "101": {
    "class_type": "SaveImage",
    "inputs": {
      "images": [
        "100",
        0
      ],
      "filename_prefix": "foulward_turnaround_hires"
    }
  }
}
========================

/home/jerzy-wolf/workspace/foul-ward/FoulWard/.cursor/skills/gen3d/SKILL.md
========================

# SKILL: gen3d — Automatic 3D asset generation (local pipeline)

## Stage 1 Environment (Resolved — do not change)

- ComfyUI: v0.19.3 at http://127.0.0.1:8188
- Start command: `nohup $FOULWARD_PYTHON ~/ComfyUI/main.py --listen 127.0.0.1 --port 8188 > /tmp/comfyui.log 2>&1 &`
- `FOULWARD_PYTHON`: `/home/jerzy-wolf/miniconda3/envs/trellis2/bin/python3`
- UNET: `~/ComfyUI/models/unet/flux1-dev.safetensors` (23.80GB, `weight_dtype`: default)
- CLIP: `~/ComfyUI/models/clip/clip_l.safetensors` (~246MB)
- T5: `~/ComfyUI/models/clip/t5xxl_fp8_e4m3fn.safetensors` (~4.6GB)
- VAE: `~/ComfyUI/models/vae/flux_ae.safetensors`
- LoRA strengths validated: turnaround=0.4, baroque=0.5, velvet=0.4
- Minimal test baseline: mean RGB (228.6, 201.9, 197.3), 0.0% black

## Pinned dependency versions (Stage 2 / `trellis2` conda — do not upgrade without testing)

- **transformers: 4.56.0** — `transformers` **5.5.x** breaks TRELLIS.2’s DINOv3 path: `AttributeError: 'DINOv3ViTModel' object has no attribute 'layer'`. **`transformers==4.46.3` is not usable** here: that release has no `DINOv3ViTModel` (`ImportError` on import). **4.56.0** matches the working downgrade in [microsoft/TRELLIS.2#147](https://github.com/microsoft/TRELLIS.2/issues/147). Install with full dependency resolution, e.g. `pip install "transformers==4.56.0" --force-reinstall` (avoid `--no-deps` unless you also align `tokenizers` / `huggingface-hub`).
- **torch: 2.6.0+cu124**
- **torchaudio: 2.6.0+cu124**
- **timm: 1.0.26** (do not change without re-testing Stage 2)
- **Python: 3.10** (`trellis2` conda env)

### DINOv3 / transformers quick reference

| Symptom | Fix |
|--------|-----|
| `'DINOv3ViTModel' object has no attribute 'layer'` | Pin **transformers 4.56.0** (you are likely on 5.5.x). |
| `cannot import name 'DINOv3ViTModel' from 'transformers'` | Transformers too old; use **4.56.0**, not **4.46.3**. |

Further discussion: [microsoft/TRELLIS.2#147](https://github.com/microsoft/TRELLIS.2/issues/147), [visualbruno/ComfyUI-Trellis2#144](https://github.com/visualbruno/ComfyUI-Trellis2/issues/144).

## Stage 1 Image Generation Settings (validated)

- Resolution: 1024×1024 (FLUX sharpness sweet spot — do NOT go higher, FLUX blurs above 1MP)
- Steps: 28, cfg: 3.5, sampler: euler, scheduler: beta
- LoRA strengths: turnaround=0.4, baroque=0.5 (orc)/0.3 (allies), velvet=0.4/0.3 (buildings)
- Upscale pass: 4× NMKD-Superscale → lanczos down to 2048×2048 for reference sheet
- Output node: 101 (`foulward_turnaround_hires_*.png` at 2048×2048)

## Stage 2 TRELLIS Settings (validated)

- **VRAM:** After Stage 1, `foulward_gen.py` **always** stops ComfyUI (`pkill` + optional `/api/quit`) and **polls `nvidia-smi`** until used VRAM &lt; 12 GB (or timeout) before loading TRELLIS — FLUX.1-dev (~16+ GB resident) and TRELLIS.2-4B cannot coexist on 24 GB. To skip shutdown (only safe with a **small** image model, e.g. FLUX.1-schnell fp8): `export SKIP_COMFYUI_SHUTDOWN=1`.
- **Stage 2 (multi-variant):** `generate_mesh_variants(n_variants=N)` runs TRELLIS N times with different random seeds and decimates each. Default `N_MESH_VARIANTS=5`. The user is prompted to pick one; batch runs auto-select candidate 1 (`AUTO_SELECT_CANDIDATE=1`). Candidates are stored in both `/tmp/fw_{slug}_candidates/` (ephemeral) and `art/gen3d_candidates/{slug}/` (permanent). `meta.json` sidecar tracks the selection.
- **Stage 2b (decimation):** `decimate_glb` preserves UV/PBR textures. Strategy: Open3D QEM decimation (correctly targets face count even on non-manifold TRELLIS meshes), then scipy `cKDTree` nearest-vertex UV re-projection from the original high-res mesh. Output includes `TextureVisuals` + embedded `PBRMaterial` baseColorTexture. **Do NOT revert to plain Open3D decimation** — it stripped all UV data.
- **Pre-decimation:** `o_voxel.postprocess.to_glb` runs with `decimation_target=100000` (env: `FOULWARD_TRELLIS_PREDECIMATE`, default 100000). This reduces the raw TRELLIS GLB from ~38 MB to ~4 MB before the `decimate_glb` step. Increase to 1000000 for maximum source detail.
- **Seed:** `image_to_glb` accepts `seed: int | None`. `None` → random 32-bit seed. Seed is passed to TRELLIS and logged (`[TRELLIS] seed=...`). Same image + same seed → same geometry.
- Input: crop left-third of turnaround sheet (front view) → pad square on white → resize to **768** px edge (A/B 2026-04-20; env ``FOULWARD_TRELLIS_INPUT_EDGE`` overrides default 768).
- Prefer **single front panel** for clean humanoids; full multi-view sheets can score similar on edge-count proxies but often hallucinate extra bodies in the mesh.
- Model is trained around ~518 px; 768 is the project default after A/B (was 770 community sweet spot).
- sparse_structure steps: 500, **guidance_strength** 7.5 (TRELLIS.2 sampler API — not `cfg_strength`)
- slat steps: 500, **guidance_strength** 3.0
- texture_resolution: 2048 (``o_voxel.postprocess.to_glb`` → ``texture_size``)
- nviews: 120 (community default for multiview texture quality; bake path is fixed in ``o_voxel``)
- Expected GLB size after decimation: ~10–20 MB (includes embedded 2048px WebP/PNG baseColorTexture); triangle count ~8k–12k (enemies/allies), 8k (buildings), ~20k (bosses)

### Variant selection env vars

| Variable | Default | Meaning |
|---|---|---|
| `N_MESH_VARIANTS` | `5` | Number of TRELLIS runs per asset |
| `AUTO_SELECT_CANDIDATE` | `0` (interactive) | `1` = auto-select candidate 1 without prompt (set by `generate_all.sh`) |
| `FOULWARD_TRELLIS_PREDECIMATE` | `100000` | Pre-decimation target inside `o_voxel.to_glb` |

### Re-selecting a variant after a batch run

```bash
cd tools/gen3d
# Re-promote candidate 3 for orc_grunt and re-run stages 3–5:
$FOULWARD_PYTHON promote_candidate.py orc_grunt 3
```

Candidates live at `art/gen3d_candidates/{slug}/candidate_{N}_decimated.glb`.
`selected.glb` in the same dir is what stages 3–5 consume.

### Skip-stage env vars (for promote_candidate.py / CI)

| Variable | Meaning |
|---|---|
| `SKIP_STAGE1=1` | Skip ComfyUI image generation (use existing `/tmp/fw_{slug}_front_nobg.png`) |
| `SKIP_STAGE2=1` | Skip TRELLIS mesh generation; requires `SELECTED_GLB=<path>` |
| `SELECTED_GLB=<path>` | Absolute path to the already-decimated GLB to feed into stage 3 |

Invoke gen3d with: `$FOULWARD_PYTHON tools/gen3d/foulward_gen.py "Unit Name" faction asset_type`

## Previously broken (fixed — do not revert)

- Old `flux_t5_1` / `flux_t5_2` were sharded HF diffusers T5 (only shard 1 of 2 loaded) → "Long clip missing" → NaN → black PNG. Fixed by downloading `comfyanonymous/flux_text_encoders` `t5xxl_fp8_e4m3fn.safetensors`.
- Old UNETLoader pointed at `diffusion_pytorch_model-00001-of-00003.safetensors` (shard 1 of 3) → NaN. Fixed by downloading single-file `flux1-dev.safetensors`.
- ComfyUI must be started with **trellis2** conda env Python, not base miniconda Python 3.13.

## Purpose

Load this skill when generating **placeholder or batch 3D assets** for Foul Ward: enemies, allies, bosses, buildings. The Python orchestrator lives in **`tools/gen3d/`** in this repo; it drives local tools on the developer machine (ComfyUI + FLUX.1 dev, TRELLIS.2, Blender, optional Mixamo automation). Output is **`.glb`** under `res://art/generated/...` with the same **flat naming** as existing placeholders (`rigged_visual_wiring.gd`, `docs/FUTURE_3D_MODELS_PLAN.md`).

## When to use

- "Create a 3D model for [unit]" / "Generate a GLB for [enemy/building]"
- "Run the gen3d pipeline" / "Batch placeholder meshes"
- "Add a new character to Foul Ward and generate its model"
- Anything involving **local** ComfyUI → mesh → rig → animation → Godot drop

## Canonical paths (this workspace)

| Item | Absolute path |
|------|-----------------|
| **Install / workflows** | `tools/gen3d/workflows/README_COMFYUI.md` (ComfyUI + FLUX); this SKILL § Pipeline + How to run |
| **Scripts (in-repo)** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/` |
| **Per-unit description bank** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/unit_descriptions.py` |
| **Character manifest (source of descriptions)** | `/home/jerzy-wolf/.cursor/plans/characters.md` |
| **Godot project** | `/home/jerzy-wolf/workspace/foul-ward/FoulWard` |
| **Godot path resolver (per `entity_id`)** | `scripts/art/rigged_visual_wiring.gd` |
| **Roster doc** | `docs/FUTURE_3D_MODELS_PLAN.md` |

## Pipeline (5 stages)

1. **2D reference** — ComfyUI + **FLUX.1 [dev]** + three CivitAI LoRAs.  
   Prompt is built from: `description (from unit_descriptions.py or unit_name)` + `FACTION_ANCHORS[faction]` + `STYLE_FOOTER` (LoRA triggers baked in).
2. **Image → mesh** — TRELLIS.2 (`conda` env `trellis2`).
3. **Rig** — Blender GLB↔FBX; humanoids via **Mixamo** automation when `MIXAMO_EMAIL`/`MIXAMO_PASSWORD` env vars are set; buildings skip rig; falls back to unrigged GLB silently if Mixamo fails.
4. **Animation** — Blender merges FBX clips from `anim_library/`; see `ANIM_NAME_MAP` in `stage4_anim.py`.
5. **Drop** — Copy `{slug}.glb` to `art/generated/{enemies|allies|buildings|bosses}/`.

## How to run (single unit)

```bash
cd /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d
# Optional: ~/.foulward_secrets with export MIXAMO_* and export HF_TOKEN=hf_... (see tools/gen3d/workflows/README_COMFYUI.md)
python foulward_gen.py "UNIT NAME" FACTION ASSET_TYPE
```

`foulward_gen.py` loads **`~/.foulward_secrets`** automatically (same as `launch.sh`); **`HF_TOKEN`** is forwarded into the TRELLIS `conda run` step for Hugging Face downloads (DINOv3 + other weights). **Default `FOULWARD_TRELLIS_PUBLIC_REMBG=1`** rewrites the cached TRELLIS `pipeline.json` to use public **`ZhengPeng7/BiRefNet`** instead of gated **`briaai/RMBG-2.0`** (see `tools/gen3d/workflows/README_COMFYUI.md`).

**Without TRELLIS (skip mesh gen):** set **`FOULWARD_GEN3D_STAGE2_MODE=input_file`** and **`FOULWARD_GEN3D_STAGE2_INPUT_GLB=/path/to/file.glb`**, or **`FOULWARD_GEN3D_STAGE2_MODE=placeholder`** for a box mesh — see `tools/gen3d/workflows/README_COMFYUI.md` (Stage 2 bypass).

- **FACTION:** `orc_raiders` | `plague_cult` | `allies` | `buildings`
- **ASSET_TYPE:** `enemy` | `ally` | `building` | `boss`
- **UNIT NAME:** matches a slug in `unit_descriptions.py` (preferred) or any free text. Lowercase + `_` for spaces.

Examples (slugs already in `unit_descriptions.py`):

```bash
python foulward_gen.py "arnulf" allies ally
python foulward_gen.py "florence" allies ally
python foulward_gen.py "sybil" allies ally
python foulward_gen.py "orc_grunt" orc_raiders enemy
python foulward_gen.py "herald_of_worms" plague_cult enemy
python foulward_gen.py "arrow_tower" buildings building
```

Start **ComfyUI** first (`~/ComfyUI`, port **8188**). After downloading **FLUX.1-dev** into `~/ComfyUI/models/checkpoints/flux1-dev/`, run **`tools/gen3d/setup_comfyui_flux_symlinks.sh`** once so UNET/CLIP/VAE paths resolve (see `tools/gen3d/workflows/README_COMFYUI.md`). **Default** `turnaround_flux.json` includes **three LoRAs** under `~/ComfyUI/models/loras/` with fixed filenames (`turnaround_sheet`, `baroque_fantasy_realism`, `velvet_mythic_flux`). **Source links, API URLs, optional Hugging Face mirror for LoRA 1, and `~/Downloads` copy examples:** `tools/gen3d/workflows/README_COMFYUI.md`. **`STYLE_FOOTER` in `foulward_gen.py` must stay aligned with those LoRAs’ trigger words.** If LoRAs are not installed yet, run with `export FOULWARD_GEN3D_WORKFLOW=turnaround_flux_no_loras.json` or use that file as `turnaround_flux.json`.

## Adding a new character — exact step-by-step

### Step 1 — Decide the slug, faction, and asset type

Pick a **lowercase slug with underscores**: e.g. `frost_wolf`. Pick a `FACTION` and `ASSET_TYPE` from the lists above. Bosses can use `enemy` (drops to `art/generated/enemies/`) or `boss` (drops to `art/generated/bosses/`); match what `scripts/art/rigged_visual_wiring.gd` expects for that ID.

### Step 2 — Write the description and add it to the bank

Edit `/home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/unit_descriptions.py` and add an entry following the existing pattern (one paragraph, T-pose, silhouette/proportions, palette, weapon, telling detail). Keep `FACTION_ANCHORS` alone — it auto-appends. Do not edit `STYLE_FOOTER` here (global LoRA triggers in `foulward_gen.py`).

```python
UNIT_DESCRIPTIONS["frost_wolf"] = (
    "Frost wolf beast unit, 1.4m at shoulder, ..."
)
```

### Step 3 — Make sure the GLB will be found by the game

If the new unit needs to render in-game, add the `entity_id → res://art/generated/.../<slug>.glb` mapping in `scripts/art/rigged_visual_wiring.gd` and (where relevant) the corresponding `*.tres` in `res://resources/{enemy_data,ally_data,building_data,boss_data}/`. See `add-new-entity` skill for the full data-side checklist (`SignalBus`, `Types`, indexes).

### Step 4 — Run the pipeline

```bash
cd /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d
python foulward_gen.py "frost_wolf" plague_cult enemy
```

Output lands at `FoulWard/art/generated/enemies/frost_wolf.glb`. The Godot editor will reimport on next focus / `Project → Reload Current Project`.

### Step 5 — Verify

- `ls -lh /home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/enemies/frost_wolf.glb`
- Open the scene that uses it (or the .glb directly) in Godot and check `Skeleton3D` + `AnimationPlayer` clip names against `ANIM_NAME_MAP` if it's a humanoid.
- Update `FUTURE_3D_MODELS_PLAN.md` roster table.

## How to prompt Cursor's agent to generate a new character

Paste a prompt of this shape into chat (Cursor will read this skill automatically when it sees terms like "3D model", "gen3d", "GLB"):

```
Generate a new Foul Ward 3D placeholder for a unit named "<SLUG>".
Faction: <orc_raiders|plague_cult|allies|buildings>
Asset type: <enemy|ally|building|boss>
Description (paste in or describe):
<one paragraph: silhouette, height, proportions, palette, weapon,
T-pose, one telling detail>

Steps:
1. Add an entry to /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d/pipeline/unit_descriptions.py
   following the existing format.
2. If this unit needs to render in-game, also add the GLB path mapping in
   FoulWard/scripts/art/rigged_visual_wiring.gd and the matching *.tres under
   FoulWard/resources/<category>_data/. Use the add-new-entity skill.
3. Confirm ComfyUI is up at http://127.0.0.1:8188; if not, start it and wait.
4. Run:
     cd /home/jerzy-wolf/workspace/foul-ward/FoulWard/tools/gen3d
     python foulward_gen.py "<SLUG>" <FACTION> <ASSET_TYPE>
5. Show me the resulting paths under FoulWard/art/generated/.
```

Minimal prompt for an existing slug already in `unit_descriptions.py`:

```
Run gen3d for "arnulf" allies ally and report the output GLB path.
```

Batch-all-existing prompt (uses `characters.md` as the source of truth):

```
Run the full gen3d batch from characters.md (allies, orc_raiders, plague_cult,
buildings sections — leave SECTION 5–9 future factions commented out). Stop on
the first error and print the failing unit's stage and stderr.
```

## Output layout (Godot)

Flat files (matches `rigged_visual_wiring.gd` and `generation_log.json`):

- `res://art/generated/enemies/{slug}.glb`
- `res://art/generated/allies/{slug}.glb`
- `res://art/generated/buildings/{slug}.glb`
- `res://art/generated/bosses/{slug}.glb`

After export, **reload the Godot project** so `.import` updates.

## Animation clip names

Set per asset type in `foulward_gen.py`:

- enemies: `idle, walk, attack, hit_react, death`
- allies: `idle, run, attack_melee, hit_react, death, downed, recovering`
- buildings: `idle, active, destroyed`
- bosses: `idle, walk, attack, hit_react, death`

Align Mixamo filenames in `tools/gen3d/anim_library/` with `ANIM_NAME_MAP` in `stage4_anim.py`.

## Troubleshooting

| Issue | Check |
|--------|--------|
| ComfyUI dead | `curl http://127.0.0.1:8188/system_stats` |
| Empty workflow error | Export API JSON to `turnaround_flux.json` (see `workflows/README_COMFYUI.md`) |
| TRELLIS fails (DINOv3 / HF) | `HF_TOKEN` set; accept **DINOv3** on Hugging Face. Pin **`transformers==4.56.0`** in `trellis2` if you see **`DINOv3ViTModel` / `.layer`** errors (see **Pinned dependency versions** above). If **RMBG-2.0** is 403, keep **`FOULWARD_TRELLIS_PUBLIC_REMBG=1`** (default) so stage 2 uses public BiRefNet — see `tools/gen3d/workflows/README_COMFYUI.md`. |
| Stage 2 **`cfg_strength`** / sampler API | Current TRELLIS expects **`guidance_strength`** in sampler params (not `cfg_strength`). |
| Stage 2 **CUDA OOM** with ComfyUI up | Default: `foulward_gen.py` stops ComfyUI after Stage 1 to free VRAM; or stop ComfyUI manually before TRELLIS. |
| **White mesh / untextured GLB** | Root cause was Open3D stripping UV on rebuild. Fixed (Prompt 86): `decimate_glb` now uses Open3D + cKDTree UV re-projection. If it recurs, run `_check_glb_has_texture(raw_glb)` on the TRELLIS output first. |
| Decimated GLB white but raw is textured | Verify `pipeline/stage2_mesh.py` `decimate_glb` exports via `trimesh.Scene(geometry={...}).export(out, file_type="glb")` — not `mesh.export(out)` which loses materials. |
| Mixamo fails (UI change / login) | Env vars set; bot may break — pipeline silently writes the unrigged GLB so the run still completes |
| No animations | Populate `anim_library/` with Mixamo FBX files using the names in `ANIM_NAME_MAP` |
| Godot doesn't pick up the GLB | `Project → Reload Current Project` or focus editor; ensure `rigged_visual_wiring.gd` maps the `entity_id` to the new path |
| Humanoid arms look mangled | Add `T-pose, arms extended horizontally` to the description in `unit_descriptions.py` and re-run |

## Quality

**Placeholder-grade** for gameplay iteration. Production art follows the manual steps in `docs/FUTURE_3D_MODELS_PLAN.md`.

## Related docs (in repo)

- [docs/FUTURE_3D_MODELS_PLAN.md](../../../docs/FUTURE_3D_MODELS_PLAN.md) — roster, `res://` paths, rig wiring
- `add-new-entity` skill — data-side checklist (`Types`, `SignalBus`, `*.tres`, indexes)

========================

