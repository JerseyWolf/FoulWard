# PROMPT 33 — Terrain System Implementation

**Date:** 2026-03-29

## Summary

Data-driven battlefield terrain: `Types.TerrainType` / `TerrainEffect`, `TerrainZone` (Area3D slow zones), `NavMeshManager` autoload (rebake queue), `CampaignManager._load_terrain()` driven by `TerritoryData.terrain_type`, grassland + swamp scenes under `res://scenes/terrain/`, `main.tscn` `TerrainContainer` (removed inline Ground/NavigationRegion3D), `EnemyBase` terrain speed multiplier (min of overlapping zones), SignalBus terrain + nav signals, GdUnit `tests/unit/test_terrain.gd`, `FUTURE_3D_MODELS_PLAN.md` §5.

## Files created

- `res://scripts/terrain_zone.gd` — `class_name TerrainZone`
- `res://scripts/terrain_navigation_region.gd` — builds `NavigationMesh` from sibling `GroundMesh`
- `res://scripts/nav_mesh_manager.gd` — autoload (no `class_name`; avoids GdUnit shadowing)
- `res://scenes/terrain/terrain_grassland.tscn`
- `res://scenes/terrain/terrain_swamp.tscn`
- `res://tests/unit/test_terrain.gd`
- `res://tests/support/counting_navigation_region.gd`

## Files modified

- `res://tests/test_enemy_pathfinding.gd` — `test_ground_enemy_position_changes_over_time_dense_layout`: max distance while valid (avoids freed enemy access under dense towers)
- `res://scripts/types.gd` — `TerrainType`, `TerrainEffect`
- `res://autoloads/signal_bus.gd` — terrain + nav signals
- `res://scenes/enemies/enemy_base.gd` — terrain multiplier, SignalBus handlers, velocity + `NavigationAgent3D.max_speed`
- `res://autoloads/campaign_manager.gd` — `_load_terrain`, preloads, call from `_start_current_day_internal`
- `res://scripts/resources/territory_data.gd` — `terrain_type: Types.TerrainType` (removed nested `TerritoryData.TerrainType`; legacy `.tres` ints 0–4 align with new enum order)
- `res://ui/world_map.gd` — `Types.TerrainType` display strings
- `res://scenes/main.tscn` — `TerrainContainer`, removed `Ground` subtree
- `res://project.godot` — `NavMeshManager` autoload after `SignalBus`
- `res://FUTURE_3D_MODELS_PLAN.md` — §5 Terrain System
- `res://docs/INDEX_SHORT.md`, `res://docs/INDEX_FULL.md`
- `res://tools/run_gdunit_quick.sh`, `res://tools/run_gdunit_unit.sh` — allowlist `test_terrain.gd`

## Tests

Run `./tools/run_gdunit.sh` for full suite; terrain suite: `tests/unit/test_terrain.gd` (5 cases).

## Notes

- `NavMeshManager` intentionally omits `class_name` (same rationale as `SaveManager` / `RelationshipManager` in AGENTS.md).
- `TerritoryData` previously used a nested terrain enum; migrated to global `Types.TerrainType` so campaign terrain maps align with scene preloads.
