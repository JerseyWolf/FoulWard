# PROMPT 07 — Summoner tower runtime

**Date:** 2026-03-30

## Summary

Wired `BuildingData.is_summoner` into gameplay: `AllyManager` spawns `AllyBase` squads from leader/follower paths, patrol anchors, mortal/recurring respawn timers on `BuildingBase`, soft-blocker counts on `HexGrid`, `SignalBus` ally lifecycle signals (including extended `ally_spawned`), `CombatStatsTracker` `ally_deaths` in building CSV. `archer_barracks.tres`: `is_summoner` set to `false` (buff tower only; no summon leader path).

## Files touched

| File | Change |
|------|--------|
| `autoloads/signal_bus.gd` | `ally_spawned(ally_id, building_instance_id)`, `ally_died`, `ally_squad_wiped` |
| `autoloads/ally_manager.gd` | **New** — squad registry, `spawn_squad` / `despawn_squad` |
| `autoloads/combat_stats_tracker.gd` | `ally_died` → `ally_deaths`; building_summary CSV column |
| `project.godot` | Register `AllyManager` after `BuildPhaseManager` |
| `scenes/buildings/building_base.gd` | `_init_summoner`, respawn timer, `_exit_tree` cleanup |
| `scenes/hex_grid/hex_grid.gd` | `soft_blocker_count`, `world_to_hex`, register/unregister/has; sell → `despawn_squad` |
| `scenes/allies/ally_base.gd` | `patrol_anchor`, `owning_building_instance_id`, `ally_died`, soft-blocker register/unregister |
| `scenes/arnulf/arnulf.gd` | `ally_spawned` second arg `""` |
| `resources/building_data/archer_barracks.tres` | `is_summoner = false` |
| `tests/test_ally_signals.gd` | Expected `ally_spawned` args |
| `tests/unit/test_summoner_runtime.gd` | **New** |
| `tools/run_gdunit_unit.sh` | Allowlist new suite |
| `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md` | Index updates |

## TODO / follow-ups

- Enemy pathfinding: prefer tiles with `has_soft_blocker` (future prompt).
- `AllyManager`: optional batch reset between missions if tests need isolation.

## Verification

- `./tools/run_gdunit_unit.sh` — pass (exit 101 with 0 failures per project script rules).
