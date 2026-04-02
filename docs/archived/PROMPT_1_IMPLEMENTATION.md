# PROMPT 1 IMPLEMENTATION

Date: 2026-03-24

## Implemented

- `res://scripts/input_manager.gd`
  - Added build-mode left-click routing that raycasts hex slots on collision layer 7.
  - Added occupancy-aware menu open flow:
    - empty slot -> `BuildMenu.open_for_slot(slot_index)`
    - occupied slot -> `BuildMenu.open_for_sell_slot(slot_index, slot_data)`
  - Kept `InputManager` as a pure input router (no economy/build mutation logic).

- `res://ui/build_menu.gd`
  - Added sell-mode support with:
    - `open_for_sell_slot(slot_index: int, slot_data: Dictionary) -> void`
    - sell info refresh for building name, upgrade state, and display-only refund text.
  - Added button handlers:
    - Sell -> calls `HexGrid.sell_building(_selected_slot)` then closes menu.
    - Cancel -> closes menu.
  - Preserved placement-mode behavior in `open_for_slot`.

- `res://ui/build_menu.tscn`
  - Added `SellPanel` UI under `Panel/VBox`:
    - `BuildingNameLabel`
    - `UpgradeStatusLabel`
    - `RefundLabel`
    - `Buttons/SellButton`
    - `Buttons/CancelButton`
  - `SellPanel` starts hidden.

- `res://scenes/hex_grid/hex_grid.gd`
  - Updated `_on_hex_slot_input(...)` to highlight slot only in `BUILD_MODE`.
  - Removed direct BuildMenu open from `HexGrid` so input routing stays centralized in `InputManager`.

- `res://tests/test_hex_grid.gd`
  - Added sell-flow tests:
    - `test_sell_building_empties_slot_and_refunds_base_cost`
    - `test_sell_upgraded_building_refunds_base_and_upgrade_costs`
    - `test_sell_building_emits_building_sold_signal`

## Notes

- No behavior change was made to `HexGrid.sell_building()` logic.
- No additional game logic was added to `InputManager` or `BuildMenu`; both only route/call into existing systems.
- Continuation note: follow-up firing assist/miss implementation details are documented in `docs/PROMPT_2_IMPLEMENTATION.md`.

## Second-pass audit (2026-03-24)

- Verified each checklist item above against actual files.
- Fixed one comment drift in `res://ui/build_menu.gd` (`open_for_slot` caller now documented as `InputManager`).
- Hardened `res://scenes/hex_grid/hex_grid.gd` test-safety path:
  - guarded `get_surface_override_material(0)` behind a mesh/surface-count check.
  - prevents headless test noise from empty `MeshInstance3D` surfaces in test doubles.
- Improved `res://tests/test_hex_grid.gd` headless stability:
  - added a minimal `/root/Main/ProjectileContainer` test stub in setup to avoid runtime node-path errors when instantiating `BuildingBase` during sell-flow tests.
- Re-ran `test_hex_grid.gd`: all 22 tests pass, 0 failures.

## Source prompt summary

The source prompt requested two primary outcomes for FOUL WARD:

1. Wire the already-implemented `HexGrid.sell_building()` flow into player-facing UX in build mode.
2. Complete remaining Phase 6 verification gaps through tests and/or clearly documented manual checks.

Key requirements from the source prompt:

- Preserve existing behavior; do not break current systems.
- Do not add autoloads.
- Avoid public API signature changes unless absolutely necessary (`# DEVIATION` if needed).
- Follow `CONVENTIONS.md` strictly.
- Read architecture/index/project files first; do not invent signatures.
- Keep `InputManager` as input routing only.
- Keep UI scripts as presentation + delegation only (no game logic).

Requested implementation direction:

- In build mode, left-clicking a hex slot should branch by occupancy:
  - empty slot -> placement mode menu
  - occupied slot -> sell mode menu
- Build menu sell mode should display building context and expose Sell/Cancel actions.
- Sell action should call `HexGrid.sell_building(slot_index)` and close.
- `HexGrid.sell_building()` behavior itself should remain unchanged.
- Optional between-mission sell UX was explicitly allowed to remain `# POST-MVP` if non-trivial.

Requested testing direction:

- Strengthen sell coverage (`sell_building` slot state/refunds/signals/empty-slot behavior).
- Validate Phase 6 items for:
  - Shockwave (ground/flying behavior + mana/cooldown/signals)
  - Arnulf state machine transitions and recovery cycle
  - Mission win/fail and between-mission progression
  - Simulation-loop stability
- If some flows are impractical to fully automate, document clear manual verification steps.

Requested deliverables:

- Code changes in gameplay/UI/test files as needed.
- Updated project indexes when API/surface changes are introduced.
- A dedicated `CURSOR_INSTRUCTIONS_1.md` checklist describing final verification execution steps for Cursor.
