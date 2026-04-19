#!/usr/bin/env bash
# complete_comfyui_assets.sh — finish what the one-time ComfyUI install cannot do
# without your Hugging Face / CivitAI credentials.
#
# Prerequisites (already done by gen3d_workplan.md Part 1 Step 1):
#   ~/ComfyUI with .venv and pip install -r requirements.txt
#
# This script downloads:
#   • FLUX.1 [dev] weights (requires HF access — see below)
#   • CivitAI LoRAs (optional; URLs may need manual refresh if CivitAI returns 404)
#
# Usage:
#   export HF_TOKEN=hf_...        # from https://huggingface.co/settings/tokens
#   # Accept the FLUX license at https://huggingface.co/black-forest-labs/FLUX.1-dev
#   ./tools/complete_comfyui_assets.sh
#
# Optional:
#   FOULWARD_COMFYUI_HOME  (default: $HOME/ComfyUI)
#   CIVITAI_TOKEN          if CivitAI API returns 403 (see civitai.com account settings)

set -euo pipefail

SECRETS_FILE="${FOULWARD_SECRETS_FILE:-${HOME}/.foulward_secrets}"
if [[ -r "${SECRETS_FILE}" ]]; then
  # shellcheck disable=SC1090
  set -a
  # shellcheck disable=SC1090
  source "${SECRETS_FILE}"
  set +a
fi

COMFYUI_HOME="${FOULWARD_COMFYUI_HOME:-${HOME}/ComfyUI}"
FLUX_DIR="${COMFYUI_HOME}/models/checkpoints/flux1-dev"
LORA_DIR="${COMFYUI_HOME}/models/loras"

die() { echo "error: $*" >&2; exit 1; }

[[ -f "${COMFYUI_HOME}/main.py" ]] || die "ComfyUI not found at ${COMFYUI_HOME}"

if [[ -z "${HF_TOKEN:-}" ]]; then
  die "Set HF_TOKEN to a Hugging Face token with access to black-forest-labs/FLUX.1-dev " \
      "(create at https://huggingface.co/settings/tokens and accept the model license first)."
fi

VENV_ACTIVATE=""
if [[ -f "${COMFYUI_HOME}/.venv/bin/activate" ]]; then
  VENV_ACTIVATE="${COMFYUI_HOME}/.venv/bin/activate"
elif [[ -f "${COMFYUI_HOME}/venv/bin/activate" ]]; then
  VENV_ACTIVATE="${COMFYUI_HOME}/venv/bin/activate"
else
  die "No Python venv at ${COMFYUI_HOME}/.venv or ${COMFYUI_HOME}/venv"
fi

# shellcheck disable=SC1090
source "${VENV_ACTIVATE}"

command -v hf >/dev/null 2>&1 || die "Run: pip install 'huggingface_hub[cli]' inside ComfyUI's venv"

mkdir -p "${FLUX_DIR}" "${LORA_DIR}"

echo "==> Downloading FLUX.1-dev into ${FLUX_DIR} (this is large)…"
export HF_TOKEN
hf download black-forest-labs/FLUX.1-dev --local-dir "${FLUX_DIR}"

download_lora() {
  local name="$1"
  local url="$2"
  local dest="${LORA_DIR}/${name}"
  if [[ -s "${dest}" ]] && file "${dest}" | grep -q 'safetensors\|data'; then
    echo "==> ${name} already present ($(du -h "${dest}" | cut -f1)), skipping"
    return
  fi
  echo "==> Downloading ${name}…"
  rm -f "${dest}"
  if [[ -n "${CIVITAI_TOKEN:-}" ]]; then
    curl -fL --retry 3 --max-time 3600 \
      -H "Authorization: Bearer ${CIVITAI_TOKEN}" \
      -A "Mozilla/5.0 (X11; Linux x86_64)" \
      -o "${dest}" "${url}" || echo "warning: ${name} download failed (check URL or token)" >&2
  else
    curl -fL --retry 3 --max-time 3600 \
      -A "Mozilla/5.0 (X11; Linux x86_64)" \
      -o "${dest}" "${url}" || echo "warning: ${name} download failed — try setting CIVITAI_TOKEN or download manually from CivitAI" >&2
  fi
  if [[ ! -s "${dest}" ]] || [[ $(stat -c%s "${dest}" 2>/dev/null || echo 0) -lt 1000 ]]; then
    echo "warning: ${name} looks invalid (tiny file). Remove ${dest} and download from CivitAI manually." >&2
  fi
}

# LoRA sources: gen3d/workflows/README_COMFYUI.md (turnaround: 1753109; baroque: 1604716;
# third slot filename velvet_mythic_flux = Caravaggio 2256567). If CivitAI returns errors, use browser or HF for LoRA1.
download_lora "turnaround_sheet.safetensors" "https://civitai.com/api/download/models/1753109"
download_lora "baroque_fantasy_realism.safetensors" "https://civitai.com/api/download/models/1604716"
download_lora "velvet_mythic_flux.safetensors" "https://civitai.com/api/download/models/2256567"

echo
echo "Done. Verify:"
echo "  ls -lh ${FLUX_DIR}"
echo "  ls -lh ${LORA_DIR}/*.safetensors"
echo "Then start ComfyUI:  cd ${COMFYUI_HOME} && source .venv/bin/activate && python main.py --listen 127.0.0.1 --port 8188"
