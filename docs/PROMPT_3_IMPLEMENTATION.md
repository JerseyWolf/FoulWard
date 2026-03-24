# PROMPT 3 IMPLEMENTATION

Date: 2026-03-24

## Implemented

- Added weapon-upgrade progression resources and manager:
  - `res://scripts/resources/weapon_level_data.gd`
  - `res://scripts/weapon_upgrade_manager.gd`
  - `res://resources/weapon_level_data/crossbow_level_1.tres`
  - `res://resources/weapon_level_data/crossbow_level_2.tres`
  - `res://resources/weapon_level_data/crossbow_level_3.tres`
  - `res://resources/weapon_level_data/rapid_missile_level_1.tres`
  - `res://resources/weapon_level_data/rapid_missile_level_2.tres`
  - `res://resources/weapon_level_data/rapid_missile_level_3.tres`

- Added new cross-system signal in `res://autoloads/signal_bus.gd`:
  - `weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)`

- Wired manager reset into new-game flow in `res://autoloads/game_manager.gd`:
  - `start_new_game()` now calls `WeaponUpgradeManager.reset_to_defaults()` when node exists.

- Integrated effective-weapon-stat composition into `res://scenes/tower/tower.gd`:
  - Runtime manager lookup via `/root/Main/Managers/WeaponUpgradeManager`.
  - Null-guard fallback preserves existing behavior when manager is absent.
  - Added effective stat helpers for damage/speed/reload/burst.
  - Added per-shot `WeaponData.duplicate()` override path to keep base `.tres` immutable.
  - Reload/burst totals now resolve through effective stat helpers.

- Added manager node and resource wiring in `res://scenes/main.tscn`:
  - New child `Managers/WeaponUpgradeManager`.
  - Bound level-data resources and existing tower base weapon resources.

- Added Weapons tab UI and logic:
  - `res://ui/between_mission_screen.tscn`: new `WeaponsTab` with `CrossbowPanel` and `RapidMissilePanel`.
  - `res://ui/between_mission_screen.gd`: tab refresh, preview text, affordability state, upgrade button handling.

- Added tests:
  - `res://tests/test_weapon_upgrade_manager.gd` (new manager suite).
  - Regression test in `res://tests/test_simulation_api.gd`:
    - `test_tower_fires_with_base_stats_when_no_upgrade_manager`

## Notes

- # POST-MVP: Save/load persistence for weapon levels is not implemented.
- # ASSUMPTION: Existing `BetweenMissionScreen` uses `TabContainer`; Weapons tab follows that structure.
- # SOURCE: Godot Resource patterns, dynamic Resource `.get()`, and per-instance `duplicate()` usage are cited inline in new scripts.
- Safe cleanup performed:
  - Restored unintended `project.godot` autoload removals caused by headless tooling run.
  - Re-added:
    - `MCPScreenshot="*res://addons/godot_mcp/mcp_screenshot_service.gd"`
    - `MCPInputService="*res://addons/godot_mcp/mcp_input_service.gd"`
    - `MCPGameInspector="*res://addons/godot_mcp/mcp_game_inspector_service.gd"`
  - No gameplay/system behavior was changed by this cleanup.
