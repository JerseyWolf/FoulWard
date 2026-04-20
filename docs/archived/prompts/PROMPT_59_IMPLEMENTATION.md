# PROMPT 59 — Session I-B: AP-06 placement init order (WaveManager + HexGrid)

**Date:** 2026-03-31

## Goal

Audit **AP-06** (`add_child` before `initialize` / `initialize_with_economy` / `initialize_boss_data`) in `scripts/wave_manager.gd` and `scenes/hex_grid/hex_grid.gd`.

## Result: documented exceptions (no unsafe reorder)

### `scripts/wave_manager.gd`

Swapping to **initialize → add_child** was **reverted** after failures:

- `EnemyBase.initialize` uses **`@onready` `health_component`** (nil before entering the tree) and **`global_position.distance_to(...)`** (requires `is_inside_tree()`).

**Resolution:** Restored **add_child → … → initialize** for all enemy and boss spawns. Added **AP-06 exception** comments on each site (`spawn_enemy_on_path`, `spawn_enemy_at_position`, boss wave block, escorts, `_spawn_enemy_from_composed_data`).

### `scenes/hex_grid/hex_grid.gd`

Swapping to **initialize_with_economy → add_child** broke **pathfinding**: `BuildingBase._ready()` enables **NavigationObstacle**; if `_ready` runs before **slot `global_position`** is applied, obstacles register at the wrong pose.

**Resolution:** Restored **add_child → global_position → initialize_with_economy** (paid and shop-free paths). Added **AP-06 exception** comments referencing obstacle pose and `BuildingBase.initialize()` docstring.

Headless **BuildingContainer** placeholder: **AP-06 exception** comment for plain `Node3D` (no `initialize()`).

### `place_building_shop_free`

Confirmed **intentional** bypass of `BuildPhaseManager.assert_build_phase` for shop vouchers; existing comments already document this.

## Tests (`tests/test_hex_grid.gd`, `tests/test_enemy_pathfinding.gd`)

- **Sell refund:** Assertions now use **`EconomyManager.get_refund(...)`** so they match **`DEFAULT_SELL_REFUND_FRACTION` (0.6)** instead of assuming full `gold_cost` / `material_cost` refund (`test_sell_building_empties_slot_and_refunds_base_cost`, `test_sell_upgraded_building_refunds_base_and_upgrade_costs`).
- **Pathfinding:** With **Arnulf** in `main.tscn`, ally + **arrow towers** cleared waves before enemies reached the tower. Added **`_disable_building_combat_on_main()`** (keeps nav obstacles, disables **`BuildingBase` physics**) where placement tests need enemies to survive for path assertions; **Arnulf** disabled in **`before_test`**. **Flying test** spawns **HARPY_SCOUT** via **`spawn_enemy_at_position`** because **wave 1 can be ground-only**.

## Verification

- `./tools/run_gdunit_quick.sh` — pass (warnings only, exit 101 treated as pass).
- `./tools/run_gdunit.sh` — **612** cases, **0 failures** (warnings / orphans only).

## Takeaway

AP-06 is the default when init does not depend on the tree. **`EnemyBase`**, **`BossBase`**, and **`BuildingBase`** in this project require **`add_child`** (and for buildings, **world pose**) before init so **`@onready`**, **`global_position`**, and **`_ready()` obstacle setup** are correct — document as **AP-06 exceptions** rather than forcing the generic pattern.
