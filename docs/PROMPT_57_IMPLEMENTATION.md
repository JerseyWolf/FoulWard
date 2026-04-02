# PROMPT 57 — Mechanical sweep: assert/print + test isolation (Session I-A)

**Date:** 2026-03-31

## Summary

Mechanical compliance sweep across SimBot, AutoTestDriver, and tests: replace production `assert()` and `print()`, add campaign test isolation, document remaining isolation gaps, fix bare `get_node()` in tests, and rename two short GdUnit test functions.

## Task 1 — `scripts/sim_bot.gd`

- Replaced three `assert()` calls in `_activate_for_run` with null/`is_instance_valid` checks and `push_warning()` messages for WaveManager, SpellManager, and HexGrid.
- Resolved scene nodes **before** `CombatStatsTracker.begin_mission` so a missing scene tree does not start a tracker run.
- `_activate_for_run` now returns `bool`; on failure, `run_single` returns a minimal `ERROR` result dictionary and still logs via `_store_run_single_batch_log`.

## Task 2 — `autoloads/auto_test_driver.gd`

- Replaced all `print(` calls: routine autotest / SimBot trace → `printerr()`; FATAL, INFO (Anti-Air skip), FAIL, TIMEOUT → `push_warning()`.
- Updated file header comment to describe stderr logging instead of stdout.

## Task 3 — Test isolation

- **`tests/test_campaign_autoload_and_day_flow.gd`:** Added `before_test()` aligning with `test_game_manager.gd` (Engine time scale, `GameManager.reset_boss_campaign_state_for_test`, `EconomyManager.reset_to_defaults`, `CampaignManager` day/campaign fields).
- **33 other test `.gd` files** that had neither `before_test` nor `reset_to_defaults`: inserted top-of-file comment  
  `## TODO: add before_test() isolation — see testing SKILL`  
  (skipped `tests/support/counting_navigation_region.gd` — not a test suite).

## Task 4 — Bare `get_node()` in tests

Replaced with `get_node_or_null()` plus `assert_object(...).is_not_null()` (or existing asserts) in:

- `tests/test_enemy_pathfinding.gd`
- `tests/test_ally_base.gd`
- `tests/test_building_base.gd`
- `tests/test_florence.gd`
- `tests/test_art_placeholders.gd`
- `tests/test_ally_spawning.gd`
- `tests/test_character_hub.gd`
- `tests/test_ally_signals.gd`
- `tests/test_boss_base.gd`

## Task 5 — Test function names

- `tests/unit/test_combat_stats_tracker.gd`: `test_wave_lifecycle` → `test_wave_lifecycle_records_spawns_and_leak_rate`
- `tests/unit/test_mission_spawn_routing.gd`: `test_validate_mission` → `test_validate_mission_valid_routing_returns_true`

## Verification

```bash
./tools/run_gdunit_quick.sh
```

Result: **0 failures** (GdUnit exit 100 with warnings only; script treats as pass per project convention).

## References

- `.cursor/skills/anti-patterns/SKILL.md` — AP-03 (`assert` in production), AP-08 (stdout / MCP)
- `.cursor/skills/testing/SKILL.md` — isolation, naming
