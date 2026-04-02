# PROMPT 47 — Economy + Upgrade-Chain Foundation (AGENTS Prompt 3)

Session: 2026-03-30.

## Summary

Aligned the codebase with the **Prompt 3 (Economy + Upgrade-Chain Foundation)** spec: atomic placement purchases, mission-level sell refund tuning, duplicate-cost keys preferring `building_id`, Dictionary-based refunds and upgrade costs, `initialize_with_economy` on `BuildingBase`, optional `DayConfig.mission_economy` wired from `GameManager._begin_mission_wave_sequence`, and `MissionEconomyData` extensions (`sell_refund_fraction` override, `passive_gold_per_wave`).

## Files touched

| File | Change |
|------|--------|
| `autoloads/economy_manager.gd` | `duplicate_cost_k`, `_built_counts`, `sell_refund_fraction` (default 0.6), public `sell_refund_global_multiplier`, `reset_for_mission`, `can_afford_building(building_data)` (internal wallet), `register_purchase` spends + receipt `Dictionary`, `get_refund` → `Dictionary` with `ceili`, `apply_mission_economy` sets starting resources + optional overrides, `grant_wave_clear_reward` adds `passive_gold_per_wave` |
| `scripts/resources/building_data.gd` | `building_id`, `upgrade_next_gold_cost` / `upgrade_next_material_cost`, `apply_duplicate_scaling` default `true` |
| `scripts/resources/mission_economy_data.gd` | `passive_gold_per_wave`, `sell_refund_fraction` (≥0 overrides; default -1 = no override), validation |
| `scripts/resources/day_config.gd` | `mission_economy: MissionEconomyData` |
| `scenes/buildings/building_base.gd` | `placed_instance_id: String`, `initialize_with_economy`, `_apply_data_stats`, `get_upgrade_cost` / `get_sell_refund` → Dictionary, `apply_upgrade` rolls invested totals + refresh stats |
| `scenes/hex_grid/hex_grid.gd` | Paid placement: `register_purchase` only; `initialize_with_economy` + receipt; sell via `get_sell_refund`; upgrade Dictionary costs + rollback on material fail |
| `ui/build_menu.gd` | `can_afford_building(bd)`; refund Dictionary |
| `scripts/sim_bot.gd` | `can_afford_building`; upgrade cost Dictionary |
| `autoloads/game_manager.gd` | `apply_mission_economy(day_cfg.mission_economy)` or `reset_for_mission()` |
| `tests/unit/test_economy_mission_integration.gd` | Updated for new APIs and `register_purchase` spending |
| `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md` | Prompt 47 entries + EconomyManager API lines |

## TODOs (follow-up)

- Add `building_id` to existing `.tres` `BuildingData` resources where authors want stable duplicate keys (fallback remains `id` then `building_type:%d`).
- Author `upgrade_next` chains and non-zero `upgrade_next_*` costs per tier.
- Campaign `DayConfig` assets can assign `mission_economy` when per-day tuning is ready; days without it only reset duplicate counts at mission start.

## Tests

`./tools/run_gdunit_unit.sh` — pass (0 failures).
