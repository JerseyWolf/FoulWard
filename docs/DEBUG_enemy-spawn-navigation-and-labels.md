# DEBUG — Enemy spawn stall + tiny world labels

**Date:** 2026-03-29  
**Symptoms:** Some ground enemies did not move toward the tower, blocking wave/mission progress; `Label3D` text above enemies, tower, and buildings was hard to read at normal camera distance.

## Findings

1. **`NavigationAgent3D.max_speed` was `0.0` in `enemy_base.tscn`.**  
   In Godot 4.x the agent’s `max_speed` defaults to `10.0` for a reason: internal avoidance / path logic uses it. A value of `0` can produce poor or no usable path velocity hints when combined with manual `CharacterBody3D` movement. **`initialize()` now sets `max_speed` from `EnemyData.move_speed`** (minimum `0.25`), and the scene default was raised to `10.0` as a safe fallback before init runs.

2. **No fallback when the nav agent returns a zero direction.**  
   If the navigation map is empty, not yet synced, or `get_next_path_position()` equals the agent position, the previous code set `velocity = Vector3.ZERO` indefinitely (until stuck logic, which still assumed nav retargeting helped). **Ground movement now falls back to direct XZ steering toward the tower** when the nav vector is zero but the enemy is still out of range.

3. **Hardcoded `Vector3.ZERO` tower target.**  
   The tower sits at the origin in `main.tscn`, so this matched, but it was fragile. **Movement and distance checks now use `/root/Main/Tower`’s global XZ** when the node exists, with `Vector3.ZERO` as fallback for odd test setups.

4. **Label readability.**  
   Enemy `Label3D` had no `font_size` / `pixel_size` in the scene (defaults read very small at gameplay scale). Tower used `font_size` 64 with `pixel_size` 0.01. **Enemy, tower, and building labels were aligned to `font_size` 72, `pixel_size` 0.02`, billboard enabled where missing.**

## Files changed

- `scenes/enemies/enemy_base.gd` — tower XZ target helpers, `max_speed` in `initialize`, direct-steer fallback  
- `scenes/enemies/enemy_base.tscn` — `max_speed`, `EnemyLabel` sizing/billboard  
- `scenes/tower/tower.tscn` — `TowerLabel` sizing  
- `scenes/buildings/building_base.tscn` — `BuildingLabel` sizing + billboard  

## Verification

- `./tools/run_gdunit_quick.sh` run before and after edits (expect exit `0` with script treating GdUnit warning exit codes as pass per project rules).
