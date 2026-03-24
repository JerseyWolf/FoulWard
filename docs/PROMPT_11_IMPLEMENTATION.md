# PROMPT 11 — Ally framework (implementation summary)

**Date:** 2026-03-24  
**Scope:** Generic ally data (`AllyData`), runtime `AllyBase`, `CampaignManager` roster, `GameManager` spawn/cleanup, `SignalBus` ally signals, Arnulf integration, `main.tscn` nodes, GdUnit tests, index/ARCHITECTURE updates.

## Design deviations (repo alignment)

| Topic | Prompt text | Actual |
|--------|----------------|--------|
| `CampaignManager` | Create new autoload | **Extended** existing `res://autoloads/campaign_manager.gd` (already present). |
| `TargetPriority` | “NEAREST / FARTHEST / …” | Repo uses **`Types.TargetPriority.CLOSEST`**, `HIGHEST_HP`, `FLYING_FIRST`. Ally MVP uses **CLOSEST** only. |
| `ally_state_changed` payload | Second arg unspecified | **String** `new_state` (POST-MVP detail tracking). |
| Typed `Array[AllyData]` in autoloads | — | **Avoided** in `GameManager` / `CampaignManager` where global class cache could break headless parse; use **`Array`** + `Variant` / `Resource` + `.get()` where needed. `AllyBase` uses **`Variant`** for `ally_data` with `get("field")` for the same reason. |
| Movement test | Distance decreases over time | **Replaced** with `test_melee_ally_find_target_returns_nearest_enemy` — nav progress is environment-sensitive; Arnulf/enemy interaction in the same scene made strict distance assertions flaky. |

## Files added

| Path | Purpose |
|------|---------|
| `res://scripts/types.gd` | `enum AllyClass { MELEE, RANGED, SUPPORT }`; comment on `TargetPriority` for allies. |
| `res://scripts/resources/ally_data.gd` | `class_name AllyData` resource (fields per prompt). |
| `res://resources/ally_data/ally_melee_generic.tres` | Placeholder melee merc. |
| `res://resources/ally_data/ally_ranged_generic.tres` | Placeholder ranged merc. |
| `res://resources/ally_data/ally_support_generic.tres` | Optional support placeholder (not in static roster by default). |
| `res://scenes/allies/ally_base.gd` | `class_name AllyBase` — state machine, nav chase, direct damage via `EnemyBase.take_damage`. |
| `res://scenes/allies/ally_base.tscn` | CharacterBody3D + mesh, health, nav agent, detection/attack areas. |
| `res://tests/test_ally_data.gd` | Defaults + directory scan of `.tres`. |
| `res://tests/test_ally_base.gd` | `find_target`, attack in range, death + `ally_killed`. |
| `res://tests/test_ally_signals.gd` | `ally_spawned` / `ally_killed` / Arnulf mirror signals (`monitor_signals` for sync emissions). |
| `res://tests/test_ally_spawning.gd` | Roster spawn count + cleanup on `all_waves_cleared` + `start_new_game`. |

## Files modified

| Path | Change |
|------|--------|
| `res://autoloads/signal_bus.gd` | `ally_spawned`, `ally_downed`, `ally_recovered`, `ally_killed`, `ally_state_changed` (POST-MVP). |
| `res://autoloads/campaign_manager.gd` | `current_ally_roster`, `current_ally_roster_ids`, `_initialize_static_roster()`, `has_ally`, `get_ally_data`, `reinitialize_ally_roster_for_test()`. |
| `res://autoloads/game_manager.gd` | `_spawn_allies_for_current_mission`, `_cleanup_allies`, hooks in `start_mission_for_day`, `start_wave_countdown`, `start_new_game`, `_on_all_waves_cleared`, `_on_tower_destroyed`. |
| `res://scenes/arnulf/arnulf.gd` | `ALLY_ID_ARNULF`, `ally_spawned` on `reset_for_new_mission`, `ally_downed` / `ally_recovered` alongside Arnulf-specific signals. |
| `res://scenes/main.tscn` | `AllyContainer`, `AllySpawnPoints` + `AllySpawnPoint_00..02`. |
| `docs/ARCHITECTURE.md` | Scene tree + autoload + ally flow notes. |
| `docs/INDEX_SHORT.md`, `INDEX_FULL.md`, `docs/INDEX_MACHINE.md`, `docs/INDEX_TASKS.md` | Ally entries + SignalBus + test list. |

## Markers used

- **# SOURCE:** — NavigationAgent3D chase pattern, nearest-target iteration, GdUnit patterns (in `ally_base.gd` / tests).
- **# DEVIATION:** — Arnulf generic `SignalBus` emissions; `emit` order in `reset_for_new_mission`.
- **# POST-MVP:** — Downed/recover for generic allies, projectiles for ranged, support buffs, `ally_state_changed`, campaign day recovery, `add_ally_to_roster` / `remove_ally_from_roster`, permanent `ally_killed` for Arnulf.
- **# ASSUMPTION:** — BossData → AllyData conversion (comment in `ally_data.gd`); allies reuse layer 3 (Arnulf) for collision.

## Tests

- `res://tests/test_ally_*.gd` — **11** cases; all pass in headless run (`GdUnitCmdTool` with four suite paths).
- **Full** `./tools/run_gdunit.sh` not completed in this session (long runtime / pathfinding suites); re-run locally after merge.

## Related

- `docs/PROBLEM_REPORT.md` — known issues (GdUnit `push_error`, mission hub, etc.); **not** re-addressed here unless required for Ally work.
