---
name: testing
description: >-
  Activate when writing, running, or debugging tests for Foul Ward. Covers
  GdUnit4 conventions, test file naming, test isolation, signal testing,
  SimBot, headless simulation, AutoTestDriver, CombatStatsTracker, test run
  commands. Use when: test, GdUnit4, unit test, integration test, SimBot,
  headless, assert, test file, run tests, balance sweep, test isolation,
  test naming, after_test, reset_to_defaults.
compatibility: Godot 4.4 GDScript, GdUnit4. Foul Ward project only.
---

# Testing — Foul Ward

Current passing tests: **525** (as of Prompt 51).

---

## Test Run Commands

```bash
./tools/run_gdunit_quick.sh        # After every change — fast subset
./tools/run_gdunit_unit.sh         # Unit tests only, 33 files, ~65s
./tools/run_gdunit_parallel.sh     # All 58 files, 8 parallel, ~2m45s
./tools/run_gdunit.sh              # Sequential baseline — run before declaring done
```

**Exit codes:**
- `101` = warnings only (orphan nodes) — treat as PASS when failure count is 0
- `100` with "0 failures" = `push_warning()` calls counted — treat as PASS

---

## File and Class Naming

test_<module_name>.gd # e.g. test_economy_manager.gd
class_name Test<ModuleName> # e.g. class_name TestEconomyManager
extends GdUnitTestSuite


All test files go in `res://tests/unit/`.

---

## Function Naming

test_<method><condition><expected>


Examples:
```gdscript
func test_add_gold_positive_amount_increases_total() -> void:
func test_spend_gold_insufficient_funds_returns_false() -> void:
func test_arnulf_downed_state_recovers_after_three_seconds() -> void:
```

---

## Arrange-Act-Assert Structure

```gdscript
func test_spend_gold_sufficient_funds_returns_true() -> void:
    # Arrange
    EconomyManager.reset_to_defaults()
    EconomyManager.add_gold(200)

    # Act
    var result: bool = EconomyManager.spend_gold(150)

    # Assert
    assert_bool(result).is_true()
    assert_int(EconomyManager.get_gold()).is_equal(850)  # 1000 default + 200 - 150
```

---

## Test Isolation

- Call `reset_to_defaults()` at the start of every test (or in `before_test()`)
- Tests MUST NOT depend on execution order
- Never emit SignalBus signals from tests using the real autoload without resetting in `after_test()`
- No UI nodes, no editor APIs, no `@tool` in test files

---

## Signal Testing

```gdscript
func test_add_gold_emits_resource_changed() -> void:
    EconomyManager.reset_to_defaults()
    var monitor := monitor_signals(SignalBus)
    EconomyManager.add_gold(50)
    await assert_signal(monitor).is_emitted("resource_changed")
```

---

## Integration Tests (await / timers)

Tests using `await` or timers are Integration tests.
Keep them OUT of `run_gdunit_unit.sh`.
Add lightweight tests to the allowlist in `run_gdunit_quick.sh`.

---

## SimBot / AutoTestDriver

Activated by CLI args:
- `--autotest` → headless smoke test
- `--simbot_profile=<name>` → run strategy profile
- `--simbot_balance_sweep` → run all profiles

Strategy profiles: `balanced`, `summoner_heavy`, `artillery_air`

`CombatStatsTracker` outputs:
- `user://simbot/runs/wave_summary.csv`
- `user://simbot/runs/building_summary.csv`
- `user://simbot/runs/event_log.csv` (when verbose enabled)

SimBot `compute_difficulty_fit()` early exit is effectively unreachable during
interactive runs (requires prior batch log data). Mission completion ends runs
via `all_waves_cleared`.

---

## Headless Safety Rules

All tests must be headless-safe:
- No UI node references in autoloads or SimBot scripts
- `get_node_or_null()` with null guard for scene nodes (WaveManager etc.)
- `BuildPhaseManager` defaults `is_build_phase = true` in headless contexts
- WaveManager absent → GameManager silently skips wave spawning (by design)
