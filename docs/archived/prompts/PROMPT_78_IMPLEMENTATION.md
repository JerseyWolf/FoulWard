# Prompt 78 — ComfyUI install (gen3d workplan Step 1)

**Date:** 2026-04-19

## Done

- Cloned `https://github.com/comfyanonymous/ComfyUI` to `~/ComfyUI`.
- Created `~/ComfyUI/.venv`, installed `requirements.txt` and `huggingface_hub[cli]`.
- Smoke test: `python main.py` responds on HTTP with valid `system_stats` JSON (CUDA / RTX 4090).
- Updated `launch.sh` to activate `~/ComfyUI/.venv` (workplan naming) with fallback to `venv`.
- Added `tools/complete_comfyui_assets.sh` — downloads FLUX.1-dev and LoRAs when `HF_TOKEN` (and optionally `CIVITAI_TOKEN`) are set.
- Updated gen3d install docs (`tools/gen3d/workflows/README_COMFYUI.md` / `.cursor/skills/gen3d/SKILL.md`) Step 1: replaced deprecated `huggingface-cli download` with `hf download` + `HF_TOKEN` / license note.

## Blocked without user credentials

- **FLUX.1-dev** is gated on Hugging Face (`Access denied` without token + license acceptance). No checkpoint weights were downloaded.
- **CivitAI LoRA** direct API URLs returned `File not found` (14-byte response) from this environment; user may need browser download or a CivitAI API token. Script documents retries.

## Next for operator

1. Accept license at https://huggingface.co/black-forest-labs/FLUX.1-dev  
2. `export HF_TOKEN=hf_...`  
3. Run `./tools/complete_comfyui_assets.sh` from repo root (or run `hf download` / manual LoRA copies per `tools/gen3d/workflows/README_COMFYUI.md`).  
4. Export `turnaround_flux.json` from ComfyUI (see `gen3d/workflows/README_COMFYUI.md`).
