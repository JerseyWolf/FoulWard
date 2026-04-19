# Prompt 81 — Arnulf gen3d wiring + TRELLIS/BiRefNet workaround

**Date:** 2026-04-19

## Summary

- **`scenes/arnulf/arnulf.gd`:** Placeholder cube fallback only when `ArnulfVisual` is empty after `mount_glb_scene()`. Previously, missing `AnimationPlayer` (no clips in `anim_library/`) caused `clear_visual_slot()` and replaced the rigged GLB with a cube.
- **`tools/gen3d/pipeline/stage2_mesh.py`:** After `pipeline.cuda()`, force `pipeline.rembg_model.model.float()` when present — fixes `RuntimeError: Input type (float) and bias type (c10::Half)` with public **`ZhengPeng7/BiRefNet`** rembg (HF Half weights vs torchvision float32 input).
- **Gen3D run:** Full TRELLIS path failed after BiRefNet fix because ComfyUI reference PNGs were **all black** (mean/std 0) — rembg then produced an empty foreground bbox (`ValueError: zero-size array`). `turnaround_flux_no_loras.json` also produced black output (workflow/prompt wiring needs separate investigation).
- **Completed pipeline** using **`FOULWARD_GEN3D_STAGE2_MODE=input_file`** and **`FOULWARD_GEN3D_STAGE2_INPUT_GLB`** pointing at existing `art/generated/allies/arnulf.glb` so stages 3–5 ran; log: `/tmp/fw_arnulf_run.log`. Mixamo automation unavailable locally (`MixamoBot not available`); stage 3 copied unrigged GLB; `anim_library/` still empty → **0 animations** in GLB.
- **Output GLB path:** `res://art/generated/allies/arnulf.glb` (workspace: `art/generated/allies/arnulf.glb`, ~272 KiB, Blender export, roots `metarig` + `rig.005`, 1 mesh, 2 skins, 0 animations).

## Verification

- `./tools/run_gdunit_quick.sh` — pass (includes `test_arnulf_scene_ready_sets_arnulf_mesh_non_null`).
- ComfyUI LoRAs visible at `http://127.0.0.1:8188/object_info/LoraLoader`: `turnaround_sheet`, `baroque_fantasy_realism`, `velvet_mythic_flux` (no restart required in this session).

## Follow-ups (not done here)

- Fix ComfyUI stage-1 black images (FLUX graph / positive prompt injection order vs `CLIPTextEncodeFlux` nodes).
- Re-run full TRELLIS after reference images are valid; or populate `tools/gen3d/anim_library/` with Mixamo FBX aligned to `stage4_anim.py` `ANIM_NAME_MAP` for clips + `AnimationPlayer` in Godot.
