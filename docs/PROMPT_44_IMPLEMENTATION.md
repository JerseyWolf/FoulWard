# Prompt 44 — Anti-air towers not shooting

## Summary

`BuildingBase._find_target()` filtered enemies using only `EnemyData.is_flying`. Air eligibility in this project is also expressed via `EnemyData.body_type` (FLYING, HOVER, ETHEREAL) in `get_target_flag_bits()`. Any enemy with `body_type == FLYING` but `is_flying == false` was treated as ground-only, so anti-air towers (`targets_ground == false`) skipped them and often had no valid target.

## Fix

- `EnemyData.matches_tower_air_ground_filter(targets_air, targets_ground)` — uses air/ground bits from `get_target_flag_bits()` when either is set; otherwise falls back to `is_flying` for legacy content (e.g. boss-only bits).
- `BuildingBase._find_target()` — null-guard `get_enemy_data()` and call `matches_tower_air_ground_filter` instead of duplicating `is_flying` logic.
- `tests/unit/test_td_resource_helpers.gd` — regression tests for mismatched `is_flying` vs `body_type`, plus bat/orc `.tres` checks.

## Files changed

- `scripts/resources/enemy_data.gd`
- `scenes/buildings/building_base.gd`
- `tests/unit/test_td_resource_helpers.gd`
- `docs/PROMPT_44_IMPLEMENTATION.md` (this file)
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`
