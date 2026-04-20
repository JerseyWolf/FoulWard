# Prompt 31 — Rigged GLB instances in combat scenes

**Date:** 2026-03-29

## Summary

- Added **`RiggedVisualWiring`** (`res://scripts/art/rigged_visual_wiring.gd`): paths aligned with `art/generated/generation_log.json` (`has_rig: true`), `mount_glb_scene`, placeholder mesh fallbacks (bat swarm, unknown `boss_id`), `AnimationPlayer` discovery, `idle`/`walk` locomotion blending.
- **`enemy_base.tscn` / `enemy_base.gd`:** `EnemyMesh` → **`EnemyVisual`** (`Node3D`); `initialize()` mounts rigged GLB per `EnemyType` or bat placeholder; `_physics_process` ends with `_sync_locomotion_animation()`. **`preload`** of `rigged_visual_wiring.gd` ensures `class_name` resolves on cold `.godot` (BossBase inherits — no duplicate const).
- **`boss_base.tscn` / `boss_base.gd`:** `BossMesh` → **`BossVisual`**; `_configure_visuals()` mounts GLB when `boss_id` matches built-in bosses (1.5× scale), else placeholder box; **`assign_locomotion_animation_player()`** on `EnemyBase` wires shared locomotion driver.
- **`arnulf.tscn` / `arnulf.gd`:** `ArnulfMesh` → **`ArnulfVisual`**; `_ready` mounts `allies/arnulf.glb`; `_sync_arnulf_locomotion_animation()` after state dispatch (DOWNED/RECOVERING → idle).
- **Death clip:** not played before `queue_free()` (would delay removal / break GdUnit timing); only **idle/walk** per `FUTURE_3D_MODELS_PLAN.md` §8 locomotion row.
- **`tests/test_art_placeholders.gd`:** resolve first `MeshInstance3D` under visual slot (GLB subtree).

## Godot MCP

- `open_scene` `res://scenes/enemies/enemy_base.tscn` → `get_scene_tree`: root shows **`EnemyVisual`** (`Node3D`) plus collision/nav/label. Runtime `initialize()` adds imported GLB subtree (**`Skeleton3D` + `AnimationPlayer`** inside instanced scene).

## Tests

- `./tools/run_gdunit.sh` — **535** cases, **0 failures** (exit **100**, 1 monitored engine error — baseline per `docs/AGENTS.md` §4).

## Files touched

- `scripts/art/rigged_visual_wiring.gd` (new)
- `scenes/enemies/enemy_base.{gd,tscn}`
- `scenes/bosses/boss_base.{gd,tscn}`
- `scenes/arnulf/arnulf.{gd,tscn}`
- `tests/test_art_placeholders.gd`
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`
- `docs/PROMPT_31_IMPLEMENTATION.md` (this file)
