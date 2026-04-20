# PROMPT 83 — gen3d e2e orc grunt + ComfyUI + TRELLIS fixes

**Date:** 2026-04-19

## Results

- **Step 2 (Comfy API smoke):** 2048×2048, **5.7%** black (first run) / **5.0%** black (verification) — STAGE 1 PASS. Used **CLIPTextEncodeFlux** `t5xxl` injection (nodes 7/8), not legacy `CLIPTextEncode` / `text`.
- **Full pipeline:** Success — `art/generated/enemies/orc_grunt.glb` **~40.29 MB**, `.import` present.
- **Step 5:** Not needed.

## Code fixes

1. **`stage2_mesh.py`:** `cfg_strength` → **`guidance_strength`** (TRELLIS.2 sampler API).
2. **`foulward_gen.py`:** After Stage 1, **`pkill -f "main.py.*--port 8188"`** by default so TRELLIS does not **CUDA OOM** while ComfyUI holds ~16GB. Opt out: `FOULWARD_GEN3D_KEEP_COMFYUI_AFTER_STAGE1=1`.

## Path note

- Godot drop is **`art/generated/enemies/<slug>.glb`**, not `art/enemies/<slug>/`.
