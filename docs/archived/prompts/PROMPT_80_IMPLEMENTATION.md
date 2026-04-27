# Prompt 80 — Default ComfyUI workflow = LoRAs

**Date:** 2026-04-19

- **`gen3d/workflows/turnaround_flux.json`** is now the **three-LoRA** graph (same content as the former `turnaround_flux_with_loras.json`).
- **`turnaround_flux_no_loras.json`** preserves the UNET + dual CLIP + VAE path without `LoraLoader` nodes.
- **`FOULWARD_GEN3D_WORKFLOW`** env var (in `pipeline/stage1_image.py`) selects an alternate filename under `workflows/` without renaming files.
- **`workflows/README_COMFYUI.md`** and **`.cursor/skills/gen3d/SKILL.md`** updated.
