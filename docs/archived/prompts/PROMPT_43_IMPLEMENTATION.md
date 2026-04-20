# PROMPT 43 — Lane/path spawn queue API alignment

**Date:** 2026-03-29

## Summary

Aligned data-driven wave spawning with explicit APIs: sorted spawn queue as `Array[Dictionary]`, path resolution returning `RoutePathData` (design “PathData”; engine name avoids Godot’s built-in `PathData`), and validation helpers returning `Array[String]` instead of `bool`.

## Files changed

- `scripts/mission_spawn_routing.gd` — `build_spawn_queue`, `resolve_path_for_spawn`, `_path_accepts_enemy`, `validate_routing`, `validate_wave`, `validate_mission`
- `scripts/wave_manager.gd` — queue type, `build_spawn_queue` / `resolve_path_for_spawn` / `validate_*` / `spawn_enemy_on_path` / `_spawn_enemy_from_queue_row` / `_process_spawn_queue`
- `scripts/spawn_queue_row.gd` — comment: legacy row; primary queue is `Dictionary`
- `tests/unit/test_mission_spawn_routing.gd` — assertions use dictionary keys
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md` — session note

## Assumptions

- `RoutePathData.body_types_allowed` remains a bitmask over `Types.EnemyBodyType`; “body type in allowed set” is implemented as `(1 << body_type) & mask`, with mask `0` meaning all types allowed.
- Enemies still move via `NavigationAgent3D` toward the tower; `RoutePathData.curve3d_path` is used only for initial placement (`_place_enemy_for_path`), not `PathFollow3D` (none in `EnemyBase`).
- `MissionSpawnRouting.validate_wave` requires non-null `enemy_data` on each entry (stricter than catalog-only `enemy_id` authoring in `MissionDataValidation`).

## TODOs

- Optional: wire enemies to follow `Curve3D` tangents or dedicated `Path3D` if design adds spline movement later.
- Optional: merge duplicate validation between `MissionSpawnRouting` and `MissionDataValidation` if a single `PackedStringArray` pipeline is desired.
