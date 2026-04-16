# Files to Upload for Session 6: Shop Rotation

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_06_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/shop_manager.gd` — ShopManager scene-bound manager; current shop logic (full file, ~150 lines estimated)
2. `scripts/resources/shop_item_data.gd` — ShopItemData resource class definition (~30 lines estimated)
3. `autoloads/economy_manager.gd` — EconomyManager autoload; lines 1-50 covering constants and currency fields (~50 lines)
4. `resources/shop_data/shop_catalog.tres` — Current static shop catalog with 4 items (~40 lines estimated)
5. `resources/strategyprofiles/strategy_balanced_default.tres` — Balanced SimBot profile (~20 lines)
6. `resources/strategyprofiles/strategy_greedy_econ.tres` — Greedy economy SimBot profile (~20 lines)
7. `resources/strategyprofiles/strategy_heavy_fire.tres` — Heavy fire SimBot profile (~20 lines)
8. `scripts/resources/strategyprofile.gd` — StrategyProfile resource class definition (~30 lines estimated)

Total estimated token load: ~360 lines across 8 files
