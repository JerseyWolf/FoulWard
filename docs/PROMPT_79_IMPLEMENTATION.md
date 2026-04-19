# Prompt 79 — ComfyUI FLUX workflow + symlinks (gen3d Stage 1)

**Date:** 2026-04-19

## Problem

- `workflows/turnaround_flux.json` was `{}`; Stage 1 raised “no CLIPTextEncode node”.
- `CheckpointLoaderSimple` + `flux1-dev.safetensors` produced **CLIP = None** for FLUX.
- Deprecated `DiffusersLoader` expected an `unet/` subfolder; HF FLUX layout uses **`transformer/`**.

## Fix

1. **`stage1_image.py`** — For `CLIPTextEncodeFlux`, inject **`clip_l`** and **`t5xxl`** (not `text`).
2. **Symlinks** under `~/ComfyUI/models/`:
   - `unet/` → FLUX transformer shards + index
   - `clip/` → `flux_clip_l.safetensors`, `flux_t5_1/2.safetensors`
   - `vae/` → `flux_ae.safetensors`
   - `diffusers/flux1-dev` → checkpoint tree (optional)
3. **API workflows:**
   - `turnaround_flux.json` — `UNETLoader` + `DualCLIPLoader` + `VAELoader` + `CLIPTextEncodeFlux` + `KSampler` + `SaveImage` (verified: PNG output in ~21s).
   - `turnaround_flux_with_loras.json` — same + 3× `LoraLoader` (use after LoRA files exist).
4. **`gen3d/setup_comfyui_flux_symlinks.sh`** — idempotent script for the layout above.
5. **`workflows/README_COMFYUI.md`** — updated for shipped workflows + symlink step.
6. **`SKILL.md` (gen3d)** — points to symlink script; LoRA workflow optional.

## CivitAI LoRAs

Still manual or flaky via API; default workflow runs **without** LoRAs.
