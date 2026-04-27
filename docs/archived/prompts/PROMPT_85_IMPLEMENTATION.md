# PROMPT 85 — Gen3D validation batch (5 enemies)

**Date:** 2026-04-20

## Summary

Ran full pre-flight dependency checks for `tools/gen3d/`, fixed ComfyUI availability, and generated assets for five enemy units: `orc_grunt`, `orc_brute`, `goblin_firebug`, `plague_zombie`, `orc_berserker`.

## Pipeline

- Interpreter: `/home/jerzy-wolf/miniconda3/envs/trellis2/bin/python3` (`FOULWARD_PYTHON`).
- Stages 1–5 executed for all units (TRELLIS.2 mesh, Blender rig/anim passthrough where applicable).
- `foulward_gen.py` stops ComfyUI on port 8188 after Stage 1; **ComfyUI must be restarted before each subsequent run** unless `FOULWARD_GEN3D_KEEP_COMFYUI_AFTER_STAGE1=1` (risk of Stage 2 OOM).
- **Do not use** `pkill -f "main.py.*8188"` from a Cursor/bash one-liner that embeds `main.py` in the command string — it can match the wrapper and kill the shell. Prefer `pkill -f '/ComfyUI/main.py'` or kill by PID file.

## Outputs

- Reference PNGs: `/tmp/fw_<slug>_ref.png` (copied to `art/gen3d_previews/`).
- Final GLBs: `art/generated/enemies/<slug>.glb`.

## Issues

- **orc_brute (first attempt):** Connection refused to ComfyUI — ComfyUI had been stopped by the previous run’s Stage 1 shutdown. Resolved by restarting ComfyUI before the run.
- **orc berserker (first attempt):** `TimeoutError: ComfyUI did not finish within 1 hour` in Stage 1 — ComfyUI likely wedged or overloaded. Resolved by restarting ComfyUI and re-running (completed Stage 1–5 in ~26 min).
- **Stage 3:** Mixamo automation unavailable (`MixamoBot not available — install Mixamo automation package.`); pipeline fell back to unrigged GLB copy (expected).
- **Stage 4:** `anim_library/` has 0 `.fbx` files — Blender export ran but no clips merged.

## Dependency snapshot (session)

- Python packages (trellis2): trimesh, Pillow, requests, numpy, huggingface_hub — OK.
- ComfyUI: started as needed; FLUX weights present under `~/ComfyUI/models/{unet,clip,vae}/` (`flux1-dev.safetensors`, etc.).
- Blender: 4.0.2.
- trellis2 conda env: present.
