# PROMPT 48 — CombatStatsTracker + Runtime Stat / Aura / Status Foundation

**Date:** 2026-03-30

## Summary

- **`autoloads/combat_stats_tracker.gd`**: Rewrote around `begin_mission` / `register_building` / `flush_to_disk`, `user://simbot/runs/{mission_id}_{timestamp}/`, wave/building CSV schemas per spec, `debug_mode` + structured `event_log`, SignalBus wiring (including `building_dealt_damage`, `florence_damaged`, `enemy_spawned`). Kept helpers `set_session_seed`, `set_layout_rotation_deg`, `set_verbose_logging`, `record_projectile_damage` (string `placed_instance_id`), `slot_index_to_ring`.
- **`autoloads/signal_bus.gd`**: Added `building_dealt_damage`, `florence_damaged`, `enemy_spawned`.
- **`scenes/projectiles/projectile_base.gd`**: Building attribution uses `source_placed_instance_id` + `source_slot_index`; emits `building_dealt_damage` when applicable.
- **`scenes/buildings/building_base.gd`**: Stat layer (`base_stats`/`final_stats`/auras/status), `_rebuild_base_stats`, `recompute_all_stats`, stack modes, `_tick_status_effects` (stack_key-only), summons + `NOTIFICATION_PREDELETE`; passes `placed_instance_id` to projectiles.
- **`scenes/enemies/enemy_base.gd`**: Stat layer + `stat_layer_effects` (stack_key stat mods) vs legacy DoT/slow in `active_status_effects`; `recompute_all_stats` / nav sync; movement/attack use effective stats where wired.
- **`scenes/hex_grid/hex_grid.gd`**: `_register_combat_stats_building` + fixed free-placement `building_free` slot/obstacle assignment.
- **`scripts/wave_manager.gd`**: `SignalBus.enemy_spawned.emit()` on spawn (deduped per enemy).
- **`scripts/sim_bot.gd`**: `CombatStatsTracker.begin_mission` in `_activate_for_run`; `flush_to_disk` in `_finalize_metrics`; `run_batch(..., debug_batch)`.
- **`tests/unit/test_combat_stats_tracker.gd`**: Four tests (register/flush, wave lifecycle, REFRESH stack, aura strongest).
- **`tools/run_gdunit_unit.sh`**: Suite entry for `test_combat_stats_tracker.gd` (if not already present).

## Pre-work findings (inspection)

- **SignalBus** (`autoloads/signal_bus.gd`): `enemy_killed`, `wave_cleared`, `building_placed`, `building_upgraded`, `building_sold` present; `wave_started(wave_number, enemy_count)` — not `(florence_hp)`; adapted CombatStatsTracker via Tower HP read + existing signals.
- **EconomyManager.register_purchase** returns `{paid_gold, paid_material, duplicate_count_after}`.
- **Autoloads** (project.godot): SignalBus, NavMeshManager, DamageCalculator, EconomyManager, … CombatStatsTracker, … (no separate “analytics” autoload beyond CombatStatsTracker).
- **SimBot** (`scripts/sim_bot.gd`): `run_single` returns per-run metrics dict; `run_batch` aggregates rows + CSV; `get_log()` returns batch metadata.

## Tests

- Full unit allowlist (`./tools/run_gdunit_unit.sh`): **320** test cases, **0 failures** (exit 101 acceptable for warnings per script).
- Isolated `test_combat_stats_tracker.gd`: **4** cases, **0 failures**.

## TODOs / follow-ups

- Emit `florence_damaged` from `Tower` when desired (currently optional; `tower_damaged` still drives wave Florence damage in tracker).
- Killer/building attribution on `enemy_killed` remains coarse (`enemy_killed` has no instance ids).
