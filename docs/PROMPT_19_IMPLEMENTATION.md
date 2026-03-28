# Prompt 19 — Art pipeline audit & placeholder GLB batch

**Date:** 2026-03-28

## Summary

- Verified **Blender 4.0.2** + **numpy** (user `pip install --user numpy --break-system-packages`) for glTF export.
- Added **`tools/generate_placeholder_glbs_blender.py`**: headless Rigify humanoids, static buildings/misc, bat as Empty+mesh; exports **`res://art/generated/{type}/{entity_id}.glb`** and **`art/generated/generation_log.json`**.
- **`tools/blender_rigify_test.py`**: optional Rigify smoke test.
- **Godot MCP Pro** `reload_project`: filesystem rescanned after batch.
- **`FUTURE_3D_MODELS_PLAN.md`**: roadmap, roster table from `generation_log.json`, scene audit appendix, ragdoll + animation wiring plans.
- **`# TODO(ART):`** comments only (no logic changes) in: `enemy_base`, `ally_base`, `arnulf`, `tower`, `building_base`, `boss_base`, `hub` (+ selected `.tscn` slot comments).

## Paths

- GLB output: `art/generated/**`
- Log: `art/generated/generation_log.json`
- Plan: `FUTURE_3D_MODELS_PLAN.md`
