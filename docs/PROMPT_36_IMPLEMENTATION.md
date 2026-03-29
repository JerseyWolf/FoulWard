# PROMPT 36 — Mission lane/path routing + spawn queue (WaveManager)

**Date:** 2026-03-29

## Summary

Integrated data-driven mission waves with `WaveManager`: `DayConfig.mission_data` → `MissionRoutingData` + `WaveData.spawn_entries` (`SpawnEntryData`), deterministic `build_spawn_queue` / `resolve_path_for_spawn`, seeded lane/path RNG, timed `_process_spawn_queue`, `spawn_enemy_on_path` + `EnemyBase.assigned_lane_id` / `assigned_path_id`. Renamed `PathData` → `RoutePathData` in `path_data.gd` to avoid Godot built-in `PathData` name clash. `MissionSpawnRouting` uses `RoutePathData.body_types_allowed` bitmask vs `EnemyData.body_type`.

## Files touched

- `scripts/mission_spawn_routing.gd` — queue build, validation, bitmask `_path_accepts_enemy`, dynamic `Resource` API for load order
- `scripts/wave_manager.gd` — `_MissionSpawnRouting` preload, mission queue spawn path, public API wrappers, `_place_enemy_for_path` optional `curve3d_path` load
- `scripts/resources/day_config.gd` — `@export var mission_data: Resource`
- `scripts/resources/path_data.gd` — `class_name RoutePathData` (+ clash comment)
- `scripts/resources/mission_routing_data.gd` — `Array[RoutePathData]` / return types
- `scenes/enemies/enemy_base.gd` — `assigned_lane_id`, `assigned_path_id`
- `resources/enemy_data/bat_swarm.tres`, `orc_brute.tres` — `body_type` for bitmask routing
- `tests/unit/test_mission_spawn_routing.gd` — **new**
- `tools/run_gdunit_quick.sh` — allowlist entry for unit suite

## Tests

- `./tools/run_gdunit_quick.sh` — pass (0 failures)

## TODO / follow-ups

- Optional jitter from `SpawnEntryData.spawn_offset_variance_sec` (seeded)
- PathFollow3D / curve sampling beyond first point + tower targeting hooks
- Authoring `.tres` `MissionData` samples on `DayConfig` for campaign days
