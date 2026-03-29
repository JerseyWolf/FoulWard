# PROMPT 35 — Tower defense data resource foundation

**Date:** 2026-03-29

## Summary

Extended existing `BuildingData`, `AllyData`, and `EnemyData` with typed `@export` fields for data-driven towers, allies, enemies, summoning, auras, healers, routing hints, and mission economy knobs. Added mission wave/routing resource types and `MissionDataValidation` helpers. Registered supporting enums on `Types` (before any `static func`, per GDScript rules).

## Files touched

- `scripts/types.gd` — `BuildingSizeClass`, `UnitSize`, `AllyAiMode`, `SummonSpawnType`, `AuraModifierKind`, `AuraCategory`, `AuraStat`, `EnemyBodyType`, `MissionBalanceStatus`
- `scripts/resources/building_data.gd` — identity, layout, economy overrides, combat extensions, summoner/aura/healer, upgrade chain, meta + `get_effective_*` / `collect_validation_warnings`
- `scripts/resources/ally_data.gd` — unit_size, vitals/combat extensions, aura/healer optionals, lifecycle, `get_effective_fire_rate`, validation
- `scripts/resources/enemy_data.gd` — defense/offense/leak/bounty/threat/tags + effective getters
- `scripts/resources/spawn_entry_data.gd` — **new**
- `scripts/resources/wave_data.gd` — **new**
- `scripts/resources/mission_waves_data.gd` — **new**
- `scripts/resources/lane_data.gd` — **new**
- `scripts/resources/path_data.gd` — **new** (aligned with `EnemyBodyType` bitmask bits)
- `scripts/resources/mission_routing_data.gd` — **new**
- `scripts/resources/mission_economy_data.gd` — **new**
- `scripts/resources/mission_data_validation.gd` — **new**
- `scripts/resources/mission_data.gd` — aligned with `wave_number` / `spawn_entries`
- `scripts/mission_spawn_routing.gd` — uses `PathData.id` / `LaneData.id`, `spawn_entries`, `SpawnEntryData.enemy_data` + bitmask path acceptance; keeps legacy `entries` + `enemy_type` path for older rows

## Tests

- `./tools/run_gdunit_quick.sh` — pass (0 failures; exit 100 treated as pass when failure count 0)

## Follow-up (Prompt 35+ validation & examples)

- `MissionDataValidation.validate_mission` / `validate_routing` / `validate_wave` — full string errors (non-destructive); duplicate wave numbers; lane → path id cross-refs
- `WaveData`: `get_total_enemy_count`, `get_total_bounty_gold`, `get_enemy_tag_histogram`; `MissionWavesData.get_wave_by_number`
- `EnemyData`: `get_target_flag_bits`, `matches_target_flags` (aligned with `BuildingData.target_flags` bitmask)
- Example `.tres` under `res://resources/examples/prompt35/`; `ExampleMissionResources` const paths
- Tweaked editor defaults: `MissionWavesData` / `MissionEconomyData` starting resources, `SpawnEntryData.interval_sec`

## Follow-ups (not in this task)

- Wire `HexGrid` / `EconomyManager` to `get_effective_cost_gold()` when mission duplicate scaling is active
- Load `MissionWavesData` / `MissionEconomyData` from `GameManager` / `DayConfig` when replacing hardcoded starts
- Consider renaming legacy `gold_cost` → `cost_gold` project-wide after migration window
