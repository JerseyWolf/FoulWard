# PROMPT 38 — Wave clear rewards + passive income (EconomyManager)

**Date:** 2026-03-29

## Summary

- **`EconomyManager`**: `get_wave_reward_gold(wave, econ)`, `get_wave_reward_material(wave, econ)` — read `MissionEconomyData.wave_clear_bonus_*` (flat per clear; `wave` must be ≥ 1; null `econ` → 0). `grant_wave_clear_reward(wave, econ)` adds gold/material and returns `Vector2i` granted amounts.
- **`SignalBus.wave_cleared`** → `_on_wave_cleared` → `grant_wave_clear_reward` using active `_mission_economy` (no payout when mission economy not applied).
- **Passive income**: unchanged — `_process` accrues `passive_gold_per_sec` / `passive_material_per_sec` from applied `MissionEconomyData`; `apply_mission_economy` toggles `set_process`.
- **`GameManager`**: TODO comment extended to mention wave_clear wiring.
- **`MissionEconomyData`**: doc comment on wave_clear bonus fields.

## Files

- `autoloads/economy_manager.gd`
- `autoloads/game_manager.gd` (comment)
- `scripts/resources/mission_economy_data.gd` (comment)
- `tests/unit/test_economy_mission_integration.gd`

## Tests

`res://tests/unit/test_economy_mission_integration.gd` — 6 cases, pass.
