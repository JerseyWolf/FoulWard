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
