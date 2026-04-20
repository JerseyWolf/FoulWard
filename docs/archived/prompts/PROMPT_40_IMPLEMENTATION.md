# PROMPT 40 — Mission routing + spawn queue (incremental)

## Scope

Hardened existing **Prompt 35–36** systems: `MissionSpawnRouting`, `WaveManager`, `SpawnQueueRow`, `MissionRoutingData` / `LaneData` / `RoutePathData` (design docs may say “PathData”; engine type is `RoutePathData` in `path_data.gd`).

## Changes

- **`scripts/mission_spawn_routing.gd`**
  - Typed `MissionRoutingData` fast path for `get_path_by_id` / `get_lane_by_id` (fallback `Resource.call` for non-typed routing).
  - `resolve_path_for_spawn(entry: SpawnEntryData, …)` for clearer API.
  - `build_spawn_queue`: requires `WaveData`; applies **`spawn_offset_variance_sec`** per spawn with the same seeded `RandomNumberGenerator` (deterministic).
  - `validate_wave`: requires `WaveData`; spawn entry must have **`enemy_data` or `enemy_id`**; validates **`spawn_offset_variance_sec >= 0`**.
  - `validate_routing`: uses `get("id")` / `get("allowed_path_ids")` for duck-typed lane/path resources.
- **`scripts/wave_manager.gd`**
  - `resolve_path_for_spawn`: casts to `SpawnEntryData`, returns `""` if `enemy_data` missing (matches queue build rules).
- **`tests/unit/test_mission_spawn_routing.gd`**
  - `test_spawn_offset_variance_is_deterministic`.

## Files touched

- `scripts/mission_spawn_routing.gd`
- `scripts/wave_manager.gd`
- `tests/unit/test_mission_spawn_routing.gd`
- `docs/PROMPT_40_IMPLEMENTATION.md`
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`

## Tests

- `GdUnitCmdTool` on `res://tests/unit/test_mission_spawn_routing.gd` (5 cases).
- `res://tests/test_wave_manager.gd` (24 cases).

## TODO / follow-ups

- Runtime follow **Curve3D** along `assigned_path_id` in `EnemyBase` (currently placement uses curve start in `WaveManager._place_enemy_for_path`; navigation remains tower-focused).
- Resolve `enemy_id` → `EnemyData` at mission load if tooling authors rows without inline `enemy_data`.
