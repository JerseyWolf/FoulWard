# PROMPT 58 — Economy + building single-method fixes (Session I-C, was I3 + I7)

**Date:** 2026-03-31

## Task 1 — `scripts/weapon_upgrade_manager.gd`

- After `can_afford`, `spend_gold` / `spend_building_material` return values are checked.
- On failure: `push_warning` with a clear message and `return false` (no level bump or signal).

## Task 2 — `autoloads/economy_manager.gd`

- Passive gold / building-material accrual moved from `_process` to `_physics_process`.
- `set_process` / `set_physics_process` toggles updated everywhere passive accrual is enabled or cleared (`_ready`, `apply_mission_economy`, `reset_to_defaults`).
- Comment at top of accrual body: gameplay logic belongs in `_physics_process` (godot-conventions §14).
- Doc comment for `apply_mission_economy` updated to reference `_physics_process`.

## Task 3 — `scenes/hex_grid/hex_grid.gd`

- `place_building_shop_free()`: documented as **intentional** bypass of build-phase guard for shop vouchers; pointer to `docs/FOUL_WARD_MASTER_DOC.md` ShopManager / voucher behavior.

## Follow-up — tests (aligned with Task 2 and build-phase guards)

| File | Change |
|------|--------|
| `tests/unit/test_economy_mission_integration.gd` | `call("_process", …)` → `call("_physics_process", …)` for passive-income deterministic test. |
| `tests/test_hex_grid.gd` | `before_test`: `BuildPhaseManager.set_build_phase_active(true)`. `after_test`: reset economy + build phase after each case (isolation for suites that leave low gold). |
| `tests/test_simulation_api.gd` | `before_test`: `BuildPhaseManager.set_build_phase_active(true)`. |
| `tests/test_enemy_pathfinding.gd` | After `GameManager.start_new_game()`, `BuildPhaseManager.set_build_phase_active(true)` so `place_building` in tests is not blocked by combat. |

## Verification

- Per project workflow: `./tools/run_gdunit_quick.sh` after touching each area; `./tools/run_gdunit.sh` before declaring complete.
- **This session:** full sequential GdUnit run **not** executed (user request). Re-run `./tools/run_gdunit_quick.sh` and `./tools/run_gdunit.sh` locally when convenient.

## Files touched

- `scripts/weapon_upgrade_manager.gd`
- `autoloads/economy_manager.gd`
- `scenes/hex_grid/hex_grid.gd`
- `tests/unit/test_economy_mission_integration.gd`
- `tests/test_hex_grid.gd`
- `tests/test_simulation_api.gd`
- `tests/test_enemy_pathfinding.gd`
- `docs/PROMPT_58_IMPLEMENTATION.md` (this file)
