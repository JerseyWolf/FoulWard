# PROMPT 37 — EconomyManager mission economy + HexGrid placement/sell/upgrade wiring

**Date:** 2026-03-29

## Summary

Wired **EconomyManager** into **HexGrid** placement (`get_gold_cost` / `get_material_cost`, `register_purchase` on paid place), **sell** (`get_refund` with `sell_refund_fraction` × `sell_refund_global_multiplier`), and **upgrade** (`get_upgrade_cost`, `record_upgrade_cost`, no `register_purchase`). **BuildingBase** tracks `paid_*` and `total_invested_*`. Mission passive income ticks in `_process`; `apply_mission_economy` sets multipliers, optional starting stock, and duplicate `k` override. **GameManager** TODO for loading `MissionEconomyData` when mission assets exist.

## Files touched

- `autoloads/economy_manager.gd` — mission state, duplicate scaling, `get_refund`, `apply_mission_economy`, `_process` passive
- `scenes/buildings/building_base.gd` — `paid_*`, `total_invested_*`, `record_*`, `get_sell_refund`, `get_upgrade_cost`
- `scenes/hex_grid/hex_grid.gd` — place/sell/upgrade flows
- `ui/build_menu.gd` — costs + sell preview
- `scripts/sim_bot.gd` — afford checks use effective costs
- `autoloads/game_manager.gd` — TODO hook
- `tests/unit/test_economy_mission_integration.gd` — **new**
- `tools/run_gdunit_quick.sh`, `tools/run_gdunit_unit.sh` — allowlist

## Tests

- `./Godot_v4.6.1-stable_linux.x86_64` GdUnit: `test_economy_mission_integration.gd` + `test_hex_grid.gd` + `test_economy_manager.gd` — pass
