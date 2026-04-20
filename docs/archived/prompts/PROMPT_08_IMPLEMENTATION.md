# PROMPT 08 — Aura + healer tower runtime

**Date:** 2026-03-30

## Summary

Implemented runtime behaviour for `BuildingData.is_aura` and `is_healer` (Prompt 50 fields): `AuraManager` autoload registers aura towers and applies `damage_pct` bonuses to nearby buildings and `enemy_speed_pct` debuffs to enemies; healer towers run a `Timer` and heal allies and/or other buildings via `receive_heal` on `AllyBase` / `BuildingBase` (`HealthComponent`).

## Files created

- `autoloads/aura_manager.gd` — registry, `get_damage_pct_bonus`, `get_enemy_speed_modifier`, building recomputation on register/deregister
- `tests/unit/test_aura_healer_runtime.gd` — resource assertions + overlapping warden shrines → single-category bonus 0.15
- `docs/PROMPT_08_IMPLEMENTATION.md` — this log

## Files modified

- `project.godot` — `AuraManager` autoload after `DamageCalculator`
- `scenes/hex_grid/hex_grid.gd` — `add_to_group("buildings")` before `initialize_with_economy` so aura/healer registration sees the full building set
- `scenes/buildings/building_base.gd` — `AuraManager` damage multiplier in `recompute_all_stats`, `_setup_aura_and_healer_runtime`, healer tick helpers, `receive_heal`, `NOTIFICATION_PREDELETE` cleanup
- `scenes/enemies/enemy_base.gd` — tower aura applied to move speed (floor 20% of base), periodic check every 0.25s
- `scenes/allies/ally_base.gd` — `receive_heal`
- `docs/AGENTS.md` — autoload order list (+ AuraManager, renumbered)
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`
- `tools/run_gdunit_unit.sh`, `tools/run_gdunit_quick.sh` — include `test_aura_healer_runtime.gd`

## Design notes

- **Autoload naming:** No `class_name` on `aura_manager.gd` — a `class_name AuraManager` would shadow the `/root/AuraManager` autoload and break `AuraManager.*` calls in GdUnit/headless (same pattern as `SaveManager`).
- **Damage bonus:** Strongest value per `aura_category` among in-range `damage_pct` emitters; values from different categories are summed, then applied as `damage * (1 + bonus)` after existing stat layers (`incoming_auras`, status effects).
- **Enemy slow:** `min` of `aura_effect_value` (negative = slow) among in-range `enemy_speed_pct` auras; applied as `move_speed * (1 + modifier)` with a floor at 20% of `EnemyData.move_speed`.
- **Signals:** No new `SignalBus` signals; registration is driven from placement (`initialize_with_economy`) and teardown (`NOTIFICATION_PREDELETE`).

## Verification

- `./tools/run_gdunit_unit.sh` — expected 0 failures
