#!/usr/bin/env bash
# After `hf download black-forest-labs/FLUX.1-dev --local-dir ~/ComfyUI/models/checkpoints/flux1-dev`,
# ComfyUI expects UNET / CLIP / VAE under models/{unet,clip,vae}. This script adds symlinks
# so `workflows/turnaround_flux.json` (UNETLoader + DualCLIPLoader + VAELoader) resolves paths.
#
# Usage:  ./setup_comfyui_flux_symlinks.sh
# Optional: FOULWARD_COMFYUI_HOME=/path/to/ComfyUI

set -euo pipefail

ROOT="${FOULWARD_COMFYUI_HOME:-${HOME}/ComfyUI}"
CKPT="${ROOT}/models/checkpoints/flux1-dev"

[[ -d "${CKPT}/transformer" ]] || {
  echo "error: missing ${CKPT}/transformer — download FLUX.1-dev first." >&2
  exit 1
}

mkdir -p "${ROOT}/models/unet" "${ROOT}/models/clip" "${ROOT}/models/vae" "${ROOT}/models/diffusers"

cd "${ROOT}/models/unet"
ln -sf "../checkpoints/flux1-dev/transformer/diffusion_pytorch_model-00001-of-00003.safetensors" .
ln -sf "../checkpoints/flux1-dev/transformer/diffusion_pytorch_model-00002-of-00003.safetensors" .
ln -sf "../checkpoints/flux1-dev/transformer/diffusion_pytorch_model-00003-of-00003.safetensors" .
ln -sf "../checkpoints/flux1-dev/transformer/diffusion_pytorch_model.safetensors.index.json" .

cd "${ROOT}/models/clip"
ln -sf "../checkpoints/flux1-dev/text_encoder/model.safetensors" flux_clip_l.safetensors
ln -sf "../checkpoints/flux1-dev/text_encoder_2/model-00001-of-00002.safetensors" flux_t5_1.safetensors
ln -sf "../checkpoints/flux1-dev/text_encoder_2/model-00002-of-00002.safetensors" flux_t5_2.safetensors

cd "${ROOT}/models/vae"
ln -sf "../checkpoints/flux1-dev/ae.safetensors" flux_ae.safetensors

ln -sfn "${CKPT}" "${ROOT}/models/diffusers/flux1-dev"

echo "OK: symlinks under ${ROOT}/models/{unet,clip,vae,diffusers}. Restart ComfyUI if it was already running."
