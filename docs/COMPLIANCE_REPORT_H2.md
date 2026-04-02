# Compliance Report H2 — Enemy System, Building System, Economy System

Date: 2026-03-31

## Skill: enemy-system

- **CHECK A (EnemyData field names — `max_hp` only):** PASS — 0 violations.  
  `grep` over `resources/enemy_data/` and `scenes/enemies/` for `\.hp\b`, `\.health\b`, `\bhp:`, `\bhealth:` found no matches.

- **CHECK B (`is_instance_valid` before enemy access):** N/A re-run — **no `COMPLIANCE_REPORT_H1.md` (or other H1 report) in this repository**; per instructions this check references H1 AP-02. Not independently verified in H2.

- **CHECK C (DamageCalculator usage / signature):** PASS — 0 violations.  
  All production `DamageCalculator.calculate_damage(...)` and `calculate_dot_tick(...)` call sites reviewed (`scenes/projectiles/projectile_base.gd`, `scenes/enemies/enemy_base.gd`, `scenes/arnulf/arnulf.gd`) match  
  `calculate_damage(base_damage: float, damage_type: Types.DamageType, armor_type: Types.ArmorType)` and the documented `calculate_dot_tick` parameter order.

- **CHECK D (Flying enemies and NavigationAgent3D):** PASS — 0 skill violations for *usage*.  
  `scenes/enemies/enemy_base.gd` branches `_physics_process` to `_physics_process_flying` when `is_flying`; ground path uses `navigation_agent` for navigation. Flying path steers directly to a Y-offset target and does not read nav path positions. The scene still *includes* a `NavigationAgent3D` node (`enemy_base.tscn`), but flying logic does not drive it.

- **CHECK E (EnemyType enum completeness):** PASS — noted from `docs/AGENT_SKILLS_VALIDATION_REPORT.md` Step **10C**: **30** `EnemyType` values (indices 0–29); result **PASS**.

- **CHECK F (Brood Carrier on-death spawn → `WaveManager.spawn_enemy_at_position`):** PASS — 0 violations.  
  `scenes/enemies/enemy_base.gd` `_handle_on_death_spawn()` resolves `WaveManager` and calls `wm.spawn_enemy_at_position(spawn_data, global_position + off)` (e.g. line 503).

---

## Skill: building-system

- **CHECK A (BuildingData wrong field names in `.tres` / `building_base.gd`):** PASS — 0 violations.  
  No matches for `build_gold_cost`, `targeting_priority`, or `build_material_cost` under `resources/building_data/`, `scenes/buildings/`, or `building_base.gd`.

- **CHECK B (`initialize()` before `add_child()`):** **1 convention mismatch** (H1 not in repo; AP-06 not re-attested).  
  - `scenes/hex_grid/hex_grid.gd` **~201–205**: `_building_container.add_child(building)` occurs **before** `building.initialize_with_economy(...)`.  
  - `scenes/buildings/building_base.gd` **~177** documents the opposite: *“Call after the node is in the scene tree (add_child) so child paths resolve.”*  
  **Rule broken vs skill:** `building-system` SKILL “Building Placement Flow” step 4 (*initialize before add_child*). Codebase intentionally defers initialization until after `add_child`.

- **CHECK C (`BuildPhaseManager.assert_build_phase()` before placement):** **1 violation.**  
  - `scenes/hex_grid/hex_grid.gd` **`place_building_shop_free`** (~110–115) calls `_try_place_building(..., false)` **without** calling `assert_build_phase()`.  
  - `place_building()` (~102–105) correctly guards with `assert_build_phase("place_building")` first.  
  **Rule broken:** SKILL — *“Always call `assert_build_phase()` before any placement operation.”*  
  **Consumer:** `scripts/shop_manager.gd` (~174) calls `hex.place_building_shop_free(...)`.

- **CHECK D (`can_afford_building` / `can_afford` before `register_purchase`):** PASS — 0 violations.  
  Only gameplay `register_purchase` usage is `scenes/hex_grid/hex_grid.gd` (~196–199), after `EconomyManager.can_afford_building(building_data)` when `charge_resources` is true.

- **CHECK E (Aura `register_aura` / `deregister_aura` on place/sell):** PASS — 0 violations found.  
  `scenes/buildings/building_base.gd`: `_setup_aura_and_healer_runtime()` (~278–282) calls `AuraManager.register_aura(self)` when `is_aura`; `NOTIFICATION_PREDELETE` (~676–679) calls `AuraManager.deregister_aura(placed_instance_id)`.

- **CHECK F (BuildingType enum completeness):** PASS — noted from `docs/AGENT_SKILLS_VALIDATION_REPORT.md` Step **10B**: **36** `BuildingType` values (indices 0–35); result **PASS**.

---

## Skill: economy-system

- **CHECK A (Direct resource mutation outside EconomyManager):** PASS — 0 violations under **autoloads/**, **scripts/**, **scenes/** per instructed `grep` (excluding `EconomyManager`’s own file).  
  Note: `scripts/sim_bot.gd` lines touching `_handler_prev_building_material` matched a naive substring; those are **not** mutations of `EconomyManager.building_material`.  
  *Out of grep scope:* `tests/unit/test_economy_mission_integration.gd` assigns `EconomyManager.gold` / `building_material` directly for test setup — flag if tests must follow the same rule as production.

- **CHECK B (`spend_*` return value ignored):** **1 violation (two calls).**  
  - `scripts/weapon_upgrade_manager.gd` **`upgrade_weapon`** (~71–74): after `can_afford`, calls `EconomyManager.spend_gold(eff_gold)` and `EconomyManager.spend_building_material(level_data.material_cost)` **without** checking the `bool` return. If a spend failed after a successful afford check, weapon level could still increment incorrectly.  
  **Contrast:** `autoloads/enchantment_manager.gd` (~86–88) checks `spent`; `scenes/hex_grid/hex_grid.gd` upgrade path checks spend bools.

- **CHECK C (`register_purchase` return not checked):** PASS — 0 violations in gameplay code.  
  `scenes/hex_grid/hex_grid.gd` (~197–199) uses `receipt.is_empty()` before proceeding.

- **CHECK D (Wave reward API):** PASS — 0 violations in **autoloads/scripts/scenes**.  
  `EconomyManager._on_wave_cleared` (~80–81) calls `grant_wave_clear_reward(wave_number, _mission_economy)` with types consistent with `grant_wave_clear_reward(wave: int, econ: MissionEconomyData)`.

- **CHECK E (Extra `save_current_state` / `SaveManager.save`):** **1 policy violation** vs stated expectation.  
  - `autoloads/game_manager.gd` **~69–75**: connects `SignalBus.mission_won` and `mission_failed` to a callable that invokes **`SaveManager.save_current_state()`** from **GameManager**, not from inside `SaveManager`.  
  **Rule broken (strict reading of H2 brief):** *“Expected: only called by the signal listeners on mission_won and mission_failed inside SaveManager itself.”*  
  `autoloads/save_manager.gd` does not register those listeners in `_ready()`.  
  *Tests* under `tests/` also call `save_current_state()` (expected for tests).

- **CHECK F (DEFAULT_GOLD / DEFAULT_BUILDING_MATERIAL):** PASS — noted from validation report Step **10E**: **DEFAULT_GOLD** = **1000**; **PASS**.

---

## Priority Violations

1. **`scripts/weapon_upgrade_manager.gd` — unchecked `spend_gold` / `spend_building_material` returns:** Risk of **desync** between weapon upgrade level and actual currency if spend fails unexpectedly (economy-system CHECK B).

2. **`HexGrid.place_building_shop_free` — no `assert_build_phase`:** Shop voucher placement can bypass the same build-phase guard as normal placement (building-system CHECK C).

3. **Placement order vs skill:** **`add_child` before `initialize_with_economy`** contradicts `building-system` SKILL §27.2 step 4; codebase documents a deliberate “after `add_child`” rule in `building_base.gd` (building-system CHECK B).

4. **Mission save wiring in `GameManager`:** Autosave on `mission_won` / `mission_failed` is **not** implemented as listeners inside `SaveManager` (economy-system CHECK E / standing-orders expectation).

5. *(Optional follow-up)* **Tests mutating `EconomyManager.gold` / `building_material` directly** — acceptable for isolation but outside “all modifications through public API” if interpreted literally for tests.

---

## Total Violation Count

| Skill           | Check outcomes | Violations / findings counted |
|-----------------|----------------|------------------------------|
| enemy-system    | A–D, F PASS; B/E by reference | **0** |
| building-system | A, D–F PASS | **2** (C: shop free placement guard; B: init/`add_child` order vs skill) |
| economy-system  | A, C–D, F PASS | **2** (B: weapon upgrade spend returns; E: save call site location) |
| **Grand total** |                | **4** substantive production issues in the table above (plus optional test note) |
