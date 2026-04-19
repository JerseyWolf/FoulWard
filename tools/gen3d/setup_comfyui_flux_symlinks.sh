#!/usr/bin/env bash
# After `hf download black-forest-labs/FLUX.1-dev --local-dir ~/ComfyUI/models/checkpoints/flux1-dev`,
# ComfyUI expects UNET / VAE under models/{unet,vae}. DualCLIPLoader must use **single-file**
# text encoders (not diffusers shards). Download into models/clip/:
#   hf download comfyanonymous/flux_text_encoders clip_l.safetensors t5xxl_fp8_e4m3fn.safetensors --local-dir ~/ComfyUI/models/clip/
# Workflows reference clip_l.safetensors + t5xxl_fp8_e4m3fn.safetensors.
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

# Do not symlink split T5 shards from flux1-dev/checkpoints — ComfyUI needs full encoders (see header).
mkdir -p "${ROOT}/models/clip"

cd "${ROOT}/models/vae"
ln -sf "../checkpoints/flux1-dev/ae.safetensors" flux_ae.safetensors

ln -sfn "${CKPT}" "${ROOT}/models/diffusers/flux1-dev"

echo "OK: symlinks under ${ROOT}/models/{unet,clip,vae,diffusers}. Restart ComfyUI if it was already running."
