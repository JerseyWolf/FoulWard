# PROMPT 09 — Enemy special behaviours (special_tags / special_values)

**Date:** 2026-03-30

## Summary

Runtime behaviours driven by `EnemyData.special_tags` and `EnemyData.special_values`: charge (enrage + optional war-boar dash), `ShieldComponent` absorption, war shaman / shaman auras via `AuraManager` enemy registry, on-death spawn (Brood Carrier), building disable (Orc Saboteur), anti-air priority for ranged (Orc Skythrower vs flying allies), regen + aura heal ticks. `SignalBus.enemy_spawned(enemy_type, position)` and `enemy_enraged(instance_id)` added. `WaveManager.spawn_enemy_at_position` + `get_enemy_data_by_type` support Brood Carrier spawns.

## Files touched

- `autoloads/signal_bus.gd` — `enemy_spawned(Types.EnemyType, Vector2)`, `enemy_enraged(String)`
- `autoloads/aura_manager.gd` — `_enemy_emitters`, `register_enemy_aura` / `deregister_enemy_aura`, `get_enemy_damage_bonus`, `get_enemy_heal_per_sec`, stale-emitter cleanup, `clear_all_emitters_for_tests`
- `autoloads/combat_stats_tracker.gd` — `_on_enemy_spawned` signature
- `scripts/wave_manager.gd` — spawn emits with type+XZ; `spawn_enemy_at_position`, `get_enemy_data_by_type`
- `scripts/components/shield_component.gd` — **new** `class_name ShieldComponent`
- `scenes/enemies/enemy_base.gd` — `_init_special_behaviours`, charge/dash/shield/auras/regen/saboteur/anti-air/on_death_spawn, `instance_id`, `enemy_data` getter, `_exit_tree` aura deregister
- `scenes/buildings/building_base.gd` — `set_disabled`, `_disabled` guard in `_combat_process`
- `tests/unit/test_damage_pipeline.gd` — shield test uses `special_tags`/`special_values`
- `tests/unit/test_combat_stats_tracker.gd` — `_on_enemy_spawned` args
- `tests/unit/test_enemy_specials.gd` — **new**
- `tools/run_gdunit_unit.sh` — allowlist `test_enemy_specials.gd`
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md` — index entries

## Tests

`./tools/run_gdunit_unit.sh` — pass (exit 101 warnings-only per project rules when failure count is 0).
