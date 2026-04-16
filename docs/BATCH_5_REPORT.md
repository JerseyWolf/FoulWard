# Batch 5 — Helper-Function Extraction Report

**Date:** 2026-04-14  
**Scope:** Pure structural refactoring — no logic changes, no behavior changes.  
**Test run:** `./tools/run_gdunit.sh` — **all suites PASSED (0 failures)**

---

## Summary

Seven long methods were split into smaller private helpers. Every extraction is a pure
refactoring: identical runtime behavior, identical signal flow, identical output. No constants,
resources, or test files were modified.

---

## Extractions

### 1. `scripts/sim_bot.gd` — `_choose_build_or_upgrade_action`

| | Lines |
|---|---|
| Before (original method) | ~69 |
| After — `_choose_build_or_upgrade_action` (caller) | ~28 |
| After — `_collect_weighted_build_entries` (new helper) | ~48 |

**Extracted function:**

```
func _collect_weighted_build_entries() -> Array[Dictionary]
```

Scans `_profile.build_priorities` and returns the tied-for-best-weight entries that pass
wave-range, availability, and affordability checks. The caller picks one entry (random tie-break
via `_rng`) and assembles the final action Dictionary.

---

### 2. `scripts/input_manager.gd` — `_unhandled_input`

| | Lines |
|---|---|
| Before (original method) | ~67 |
| After — `_unhandled_input` (dispatcher) | ~10 |
| After — `_handle_mouse_combat` (new helper) | ~25 |
| After — `_handle_spell_keybinds` (new helper) | ~16 |
| After — `_handle_build_mode_keys` (new helper) | ~12 |

**Extracted functions:**

```
func _handle_mouse_combat(event: InputEventMouseButton) -> void
func _handle_spell_keybinds(event: InputEvent) -> void
func _handle_build_mode_keys(event: InputEvent) -> void
```

`_handle_mouse_combat` handles crossbow/missile left/right clicks and build-mode left click.
`_handle_spell_keybinds` dispatches cast/cycle/slot actions (requires valid `_spell_manager`).
`_handle_build_mode_keys` dispatches `toggle_build_mode` and `cancel` actions.

Original guard: `if not is_instance_valid(_spell_manager): return` still lives in
`_unhandled_input` before both key helpers, preserving the original gating behavior where
build-mode keys are also skipped when `_spell_manager` is absent.

---

### 3. `autoloads/campaign_manager.gd` — `auto_select_best_allies`

| | Lines |
|---|---|
| Before (original method) | ~66 |
| After — `auto_select_best_allies` (orchestrator) | ~22 |
| After — `_sort_offers_by_value` (new helper) | ~40 |
| After — `_greedy_fill_roster` (new helper) | ~26 |

**Extracted functions:**

```
func _sort_offers_by_value(
        offers: Array,
        current_roster: Array[String],
        budget_gold: int,
        budget_material: int,
        budget_research: int,
        strategy_profile: Types.StrategyProfile
) -> Array
```
Filters affordable, non-roster offers and returns them sorted descending by score.

```
func _greedy_fill_roster(
        sorted_offers: Array,
        budget: Dictionary,
        max_count: int,
        starting_roster: Array[String]
) -> Dictionary
```
Greedily selects offers within budget; returns `{"recommended_indices": [...], "sim_roster": [...]}`.

---

### 4. `autoloads/campaign_manager.gd` — `restore_from_save`

| | Lines |
|---|---|
| Before (original method) | ~54 |
| After — `restore_from_save` (orchestrator) | ~4 |
| After — `_apply_campaign_from_dict` (new helper) | ~7 |
| After — `_apply_roster_from_dict` (new helper) | ~16 |
| After — `_apply_offers_from_dict` (new helper) | ~30 |

**Extracted functions:**

```
func _apply_campaign_from_dict(data: Dictionary) -> void
```
Restores `current_day`, `campaign_completed`, `is_endless_mode`, `failed_attempts_on_current_day`.

```
func _apply_roster_from_dict(data: Dictionary) -> void
```
Restores `owned_allies`, `active_allies_for_next_day`, calls `_sync_current_ally_roster_for_spawn`.

```
func _apply_offers_from_dict(data: Dictionary) -> void
```
Restores campaign config, sets `_has_active_campaign_run`, applies held territories, regenerates day
offers, emits `ally_roster_changed`. Must be called after `_apply_campaign_from_dict` (reads
`is_endless_mode`).

---

### 5. `scenes/enemies/enemy_base.gd` — `_update_status_effects`

| | Lines |
|---|---|
| Before (original method) | ~58 |
| After — `_update_status_effects` (orchestrator) | ~5 |
| After — `_tick_dot_effects` (new helper) | ~38 |
| After — `_cleanup_expired_effects` (new helper) | ~9 |

**Extracted functions:**

```
func _tick_dot_effects(delta: float) -> void
```
Advances timers and fires damage ticks for all `active_status_effects` entries. Does **not**
remove expired effects — uses a forward `for i in range(...)` pass so no index-shift issues arise.

```
func _cleanup_expired_effects() -> void
```
Removes effects with `remaining_time <= 0.0` using a backward pass (`while i >= 0`), avoiding
index-shift when calling `remove_at`. Effects with a `stack_key` are skipped by both helpers
(they are managed by `_tick_stat_layer_effects`).

**Equivalence note:** The original single-pass loop advanced timers and removed expired entries
inline. The two-pass approach is equivalent because `receive_damage()` (called during tick) does
not modify `active_status_effects`, so no cross-iteration side-effects exist.

---

### 6. `scenes/tower/tower.gd` — `_apply_auto_aim`

| | Lines |
|---|---|
| Before (original method) | ~47 |
| After — `_apply_auto_aim` (caller) | ~14 |
| After — `_find_assist_target` (new helper) | ~36 |

**Extracted function:**

```
func _find_assist_target(origin: Vector3, direction: Vector3, weapon_data: WeaponData) -> Node3D
```
Iterates the `"enemies"` group and returns the nearest living `EnemyBase` within the assist cone
defined by `weapon_data.assist_angle_degrees` and `weapon_data.assist_max_distance`. Returns `null`
when no target qualifies. The caller casts the result to `EnemyBase` to read `global_position`.

---

### 7. `scenes/hex_grid/hex_grid.gd` — `_try_place_building`

| | Lines |
|---|---|
| Before (original method) | ~89 |
| After — `_try_place_building` (dispatcher) | ~7 |
| After — `_validate_placement` (new helper) | ~18 |
| After — `_instantiate_and_place` (new helper) | ~67 |

**Extracted functions:**

```
func _validate_placement(slot_index: int, building_type: Types.BuildingType) -> bool
```
Checks: valid index, slot unoccupied, `BuildingData` found, building unlocked. Does **not** check
affordability (that is charge-economy territory, handled in `_instantiate_and_place`).

```
func _instantiate_and_place(
        slot_index: int,
        building_type: Types.BuildingType,
        charge_economy: bool
) -> bool
```
When `charge_economy` is `true`: checks affordability, calls `EconomyManager.register_purchase`,
instantiates `BuildingBase`, records costs, activates obstacle, emits `building_placed`.
When `charge_economy` is `false` (shop voucher): skips economy entirely, calls
`record_initial_purchase(0, 0)`. Both paths log success and register with `CombatStatsTracker`.

---

## Test Results

```
./tools/run_gdunit.sh
```

All test suites: **PASSED — 0 errors, 0 failures, 0 flaky**

Known post-run segfault (Godot .NET teardown — exit 101) is suppressed by the test harness
and does not indicate a test failure. This is pre-existing behavior, not introduced by this batch.
