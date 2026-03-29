# PROMPT 41 — Economy duplicate scaling, upgrade chain, projectile guards

**Date:** 2026-03-29

## Summary

- **EconomyManager:** Duplicate placement cost uses **linear** multiplier `1.0 + k * n` with default `k = 0.08`. Counts are per **building** identity: `BuildingData.id` when non-empty, else `building_type:%d`. `apply_mission_economy` (any call) and `reset_to_defaults` clear duplicate counts. Added `get_duplicate_count`, `get_cost_multiplier`, `can_afford_building`. Existing `can_afford(int, int)` unchanged for shop and generic checks. Mission overrides: `duplicate_cost_k_override`, `sell_refund_global_multiplier` (unchanged).
- **HexGrid:** Records `ring_index`, `placed_instance_id` on place; `upgrade_building` uses `BuildingBase.can_upgrade()`, applies `BuildingData.upgrade_next` via `apply_upgrade` when set, else legacy `upgrade()`.
- **BuildingBase:** Public `slot_id`, `ring_index`, `placed_instance_id`; `can_upgrade` / `apply_upgrade`; `get_effective_damage` / `get_effective_range` branch for **chain** rows (`upgrade_next` or `upgrade_level > 0`) vs legacy two-tier. **Projectiles:** `_resolve_projectile_packed_scene()` validates path, `PackedScene`, `instantiate()`, `ProjectileBase`, `initialize_from_building`; warnings/errors instead of hard crash.
- **SimBot:** Upgrade candidate filter uses `can_upgrade()` instead of `!is_upgraded`.
- **Tests:** `tests/unit/test_economy_mission_integration.gd` updated for linear scaling + new helpers.

## Files touched

- `autoloads/economy_manager.gd`
- `scenes/buildings/building_base.gd`
- `scenes/hex_grid/hex_grid.gd`
- `scripts/sim_bot.gd`
- `ui/build_menu.gd`
- `tests/unit/test_economy_mission_integration.gd`
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, `docs/PROMPT_41_IMPLEMENTATION.md`

## Verification

- `./tools/run_gdunit_unit.sh` — pass
- `./tools/run_gdunit.sh` — 564 cases, 0 failures

## Assumptions / TODOs

- **Chain authoring:** Each tier `BuildingData` should set `damage` / `attack_range` for that tier; `upgrade_next` links to the next resource. Legacy `.tres` without `upgrade_next` keep the old two-tier `upgrade()` / `upgraded_damage` path.
- **`get_duplicate_count`:** Query keys match `_duplicate_key`: explicit `id` or `building_type:%d` for enum fallback.
- **Upgrades:** Upgrade costs do not call `register_purchase`; duplicate scaling applies only to new placements with `apply_duplicate_scaling`.
- **TODO:** Persist `slot_id` / `ring_index` / `placed_instance_id` in save payloads if analytics need them across loads (not wired in this change).
