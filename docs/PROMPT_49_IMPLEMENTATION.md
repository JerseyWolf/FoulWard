# PROMPT 49 — CombatStatsTracker + Runtime Stat / Aura / Status Foundation

## Summary

Implemented Prompt 5 / 49 scope: `CombatStatsTracker` alignment with String `placed_instance_id` rows, `SignalBus` combat signals (`building_dealt_damage`, `florence_damaged`, `enemy_spawned`), `ProjectileBase` + `BuildingBase` attribution, `BuildingBase` stat layer + summon cleanup, `EnemyBase` `receive_damage` pipeline + stat/aura helpers + `stat_layer_effects`, `HexGrid` `CombatStatsTracker.register_building` + ring rotation + `BuildPhaseManager` guards, `WaveManager` `enemy_spawned`, `SimBot` `run_batch` `debug_batch`, `Types.DamageType.TRUE` + `DamageCalculator` handling, `anti_air_bolt.tres` `projectile_scene`, unit tests.

## Pre-work findings (inspection)

- **SignalBus:** `enemy_killed`, `wave_cleared`, `building_placed`, `building_upgraded` present; `wave_started(wave_number, enemy_count)` already existed (not replaced with Florence HP — tracker reads Tower HP in adapter).
- **BuildingBase:** `placed_instance_id`, `slot_id`, `ring_index`, `_building_data`, `initialize_with_economy()` confirmed.
- **EnemyBase:** `active_status_effects` + `apply_dot_effect()` (legacy DoT/slow); extended with `stat_layer_effects` + `receive_damage()`.
- **EconomyManager `register_purchase`:** returns `{ paid_gold, paid_material, duplicate_count_after }`.
- **Autoloads:** `CombatStatsTracker`, `BuildPhaseManager` (new) in `project.godot` after `GameManager`.
- **SimBot `run_single` / `run_batch`:** returns per-run `Dictionary` from `_build_audit_run_result()`; batch writes CSV under `user://simbot/logs/`; now also toggles `CombatStatsTracker.debug_mode` when `run_batch(..., debug_batch := true)`.

## WaveManager start

- Wave spawn entry: `_spawn_wave` / mission queue path emits `SignalBus.wave_started.emit(wave_number, total_spawned)` (see `scripts/wave_manager.gd`).

## Anti-air root cause

- **Issue:** `resources/building_data/anti_air_bolt.tres` had no `projectile_scene` — `_resolve_projectile_packed_scene()` could fall back to default only if preload valid; explicit `PackedScene` ensures anti-air uses the same projectile pipeline as other towers.
- **Fix:** Added `ExtResource` to `res://scenes/projectiles/projectile_base.tscn` and `projectile_scene = ExtResource("2_projectile")`.

## Assumptions

- `CombatStatsTracker` mission begin remains driven by `SignalBus.mission_started` → `begin_mission` (SimBot pre-seeds via `set_session_seed` before `start_new_game`).
- `building_dealt_damage` updates building rows only via `record_projectile_damage` to avoid double-counting; the signal is still emitted for external listeners.
- `EnemyBase` legacy DoT/slow stays in `active_status_effects`; Prompt 49 stat stacking uses `stat_layer_effects`.
- Ring rotation updates slot **positions** only (`_rebuild_slot_positions`), not slot index semantics.

## TODOs

- Wire HUD “Begin wave” to `BuildPhaseManager.confirm_build_phase()` when that API should flip `is_build_phase` / sync with `GameManager` state (see `autoloads/build_phase_manager.gd`).
- Optional: emit `SignalBus.florence_damaged` from `Tower` when central damage is attributed to a specific enemy.

## Tests

- **Before / after (unit suite):** `run_gdunit_unit.sh` overall summary reported **318** test cases after this work (0 failures; exit 101 warnings/orphans as per project script).

## Files touched (representative)

- `autoloads/combat_stats_tracker.gd` — CSV API, `register_building`, `flush_to_disk`, projectile hook, `enemy_spawned` / wave counters.
- `autoloads/signal_bus.gd` — deduped signals; `building_dealt_damage`, `florence_damaged`, `enemy_spawned`.
- `autoloads/build_phase_manager.gd` — new autoload; `is_build_phase`, `assert_build_phase`, `confirm_build_phase` stub.
- `autoloads/damage_calculator.gd` — `TRUE` bypass; matrix safety.
- `project.godot` — `BuildPhaseManager` autoload.
- `scenes/buildings/building_base.gd` — stat layer, summons, projectile `placed_instance_id` arg.
- `scenes/enemies/enemy_base.gd` — `receive_damage`, shield, stat/aura helpers, movement uses effective speed/range.
- `scenes/hex_grid/hex_grid.gd` — `CombatStatsTracker.register_building`, rotation, build-phase guards.
- `scenes/projectiles/projectile_base.gd` — String id + signal emit; `TRUE` material color.
- `scripts/wave_manager.gd` — `enemy_spawned.emit()` on spawns.
- `scripts/sim_bot.gd` — `run_batch` `debug_batch` → `CombatStatsTracker.debug_mode`.
- `scripts/types.gd` — `DamageType.TRUE`.
- `resources/building_data/anti_air_bolt.tres` — `projectile_scene`.
- `tests/unit/test_combat_stats_tracker.gd`, `tests/unit/test_damage_pipeline.gd`, `tests/unit/test_economy_mission_integration.gd` — new/extended tests.
- `tools/run_gdunit_unit.sh` — new suites in allowlist.

[ALL TASKS COMPLETE]
