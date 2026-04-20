# PROMPT 74 — Group 10: Shop Rotation & Economy Tuning

**Date:** 2026-04-18  
**Scope:** Shop catalog schema (`category`, `rarity_weight`), `ShopManager.get_daily_items()` with day-seeded RNG, 15 shop items (`resources/shop_data/` + `shop_catalog.tres`), effect dispatch for new item IDs and consumable tags, stubs on Tower / WaveManager / CampaignManager / WeaponUpgradeManager, SimBot strategy profile `difficulty_target` tuning, `tests/test_shop_rotation.gd` (8 tests), `run_gdunit_quick.sh` allowlist entry.

**Files touched (high level):**

- `scripts/resources/shop_item_data.gd` — `item_type` → `category`, `rarity_weight`
- `scripts/shop_manager.gd` — rotation, `_pick_weighted`, new `_apply_effect` / `_apply_consumable_effect` branches, `can_purchase` for `arrow_tower_voucher_2`
- `resources/shop_data/*` — 15 items total (aggregate `shop_catalog.tres` + per-item `.tres`; `main.tscn` lists 15 `ExtResource` entries)
- `scenes/tower/tower.gd` — `add_max_hp_bonus`, `heal_percent_max_hp` (stub)
- `scripts/wave_manager.gd` — `reveal_next_wave_composition` (stub)
- `autoloads/campaign_manager.gd` — `set_next_mercenary_discount` (stub)
- `scripts/weapon_upgrade_manager.gd` — `add_fire_oil_charges` (stub)
- `resources/strategyprofiles/strategy_*.tres` — `difficulty_target` 0.5 / 0.3 / 0.7
- `tests/test_shop_rotation.gd`, `tests/test_shop_manager.gd`, `tests/test_consumables.gd`
- `tools/run_gdunit_quick.sh` — added `test_shop_rotation.gd`
- `AGENTS.md` / `.cursorrules` — test count 678
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`

**Verification:** `./Godot_v4.6.2-stable_mono_linux.x86_64 --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a res://tests/test_shop_rotation.gd` — 8/8 passed. Full `run_gdunit_quick.sh` reported 472 cases, 0 failures; runner may segfault after exit (engine/GdUnit teardown; not treated as test failure).
