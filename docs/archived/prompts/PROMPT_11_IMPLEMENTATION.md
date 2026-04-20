# PROMPT 11 — HUD build menu + in-mission research UI

**Date:** 2026-03-30

## Summary

- **Build menu** lists all towers from `HexGrid.building_data_registry`, sorted by `size_class` (SMALL → MEDIUM → LARGE) then `display_name`, using `ui/build_menu_button.tscn` rows (name, gold/material cost, `role_tags`, lock overlay).
- **Research** uses existing `EconomyManager` research material as “RP”; `SignalBus.research_points_changed` mirrors balance for UI; `research_node_unlocked` duplicates the unlock event for consumers that listen only to the new name.
- **ResearchManager** (`scripts/research_manager.gd`): `can_unlock`, `get_research_points`, `add_research_points`, `unlock`/`unlock_node`, `show_research_panel_for`, `_unlock_building_for_node` (finds `HexGrid` via `hex_grid` group and clears `BuildingData.is_locked` when a node unlocks).
- **BuildPhaseManager**: `build_phase_started` / `combat_phase_started`, `set_build_phase_active`; **GameManager** toggles it on mission start, wave countdown, and enter/exit build mode.
- **Research panel** (`ui/research_panel.tscn`) in `main.tscn` under `UI`, group `research_panel`; `HUD` Research button opens it in **BUILD_MODE** only.
- **Tests:** `tests/unit/test_research_and_build_menu.gd` (allowlist: `tools/run_gdunit_unit.sh`).

## Files touched

| Area | Files |
|------|--------|
| UI | `ui/build_menu.gd`, `ui/build_menu.tscn`, `ui/build_menu_button.gd`, `ui/build_menu_button.tscn`, `ui/research_panel.gd`, `ui/research_panel.tscn`, `ui/research_node_row.gd`, `ui/research_node_row.tscn`, `ui/hud.gd`, `ui/hud.tscn` |
| Logic | `scripts/research_manager.gd`, `autoloads/signal_bus.gd`, `autoloads/build_phase_manager.gd`, `autoloads/game_manager.gd`, `scenes/hex_grid/hex_grid.gd` |
| Main | `scenes/main.tscn` (`ResearchPanel` instance, `dev_unlock_anti_air_only = false`) |
| Tests | `tests/unit/test_research_and_build_menu.gd`, `tools/run_gdunit_unit.sh` |
| Docs | `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, this file |

## Verification

- `./tools/run_gdunit_unit.sh` — expect 0 failures (exit 100 may still appear from Godot GD error monitor when other suites log script errors; 0 test failures is the target).
