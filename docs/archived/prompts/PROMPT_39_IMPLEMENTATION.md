# Prompt 39 — TD data resource foundation (polish + alignment)

## Context

Prompt 35–38 already introduced the tower-defense data `Resource` scripts (`BuildingData`, `AllyData`, `EnemyData`, wave/spawn/mission bundles, routing, economy). This session aligns them with the consolidated field/spec checklist, adds small authoring helpers, and documents the engine-safe path resource naming.

## Files touched

| File | Change |
|------|--------|
| `scripts/resources/building_data.gd` | `get_range()` returns `attack_range` (specs use the word “range”; `range` is a GDScript keyword). |
| `scripts/resources/ally_data.gd` | `identity`, `max_lifetime_sec`, `get_identity()`. |
| `scripts/resources/enemy_data.gd` | `get_identity()`. |
| `scripts/resources/spawn_entry_data.gd` | `enemy_id` for rows resolved later; validation requires `enemy_data` **or** non-empty `enemy_id`. |
| `scripts/resources/mission_routing_data.gd` | Warn when a path’s `lane_id` is not present in `lanes`. |
| `scripts/resources/path_data.gd` | Clarify that design docs’ “PathData” is implemented as `RoutePathData`. |
| `scripts/resources/mission_economy_data.gd` | Grouping comments + note on overlapping `starting_*` with `MissionWavesData`. |
| `scripts/resources/mission_data_validation.gd` | `validate_wave` matches spawn entry rules for `enemy_id`-only rows. |
| `tests/unit/test_td_resource_helpers.gd` | New unit tests for the above. |
| `tools/run_gdunit_quick.sh` | Allowlist new suite. |
| `tools/run_gdunit_unit.sh` | Allowlist new suite (37 file count). |
| `docs/INDEX_SHORT.md` | Prompt 39 header + resource/test rows. |
| `docs/INDEX_FULL.md` | Prompt 39 header. |

## Assumptions

- Runtime spawn queues (`MissionSpawnRouting.build_spawn_queue`) still require concrete `EnemyData` on each row; `enemy_id`-only rows are for authoring/catalog resolution **before** gameplay wiring.
- `RoutePathData` remains the registered `class_name` in `path_data.gd` to avoid clashing with Godot’s built-in `PathData` type.

## TODOs (follow-up, not this prompt)

- Resolve `enemy_id` → `EnemyData` in a single mission load pipeline when catalog-driven waves land.
- Optionally deduplicate `starting_gold` / `starting_material` between `MissionWavesData` and `MissionEconomyData` via one loader policy in `GameManager` / `EconomyManager`.
