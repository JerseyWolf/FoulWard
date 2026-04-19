---
name: building-system
description: >-
  Activate when working with buildings in Foul Ward: placement, selling,
  HexGrid, BuildingBase, BuildingData, aura buildings, summoner buildings,
  build phase, ring rotation. Use when: building, BuildingBase, BuildingData,
  HexGrid, hex grid, placement, sell, upgrade, ring, slot, build mode,
  build phase, aura, summoner, turret, BuildingType, BuildingSizeClass,
  BuildPhaseManager, AuraManager, AllyManager.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Building System — Foul Ward

---

## Key Classes

| Class | File/Path | Role |
|---|---|---|
| `HexGrid` | `scenes/hex_grid/hex_grid.gd` | 24-slot grid management |
| `BuildingBase` | `scenes/buildings/building_base.gd` | Building logic base |
| `BuildingData` | `resources/building_data/*.tres` | Resource: all building stats |
| `BuildPhaseManager` | Autoload #10 | Headless-safe build-phase guard |
| `AuraManager` | Autoload #4 | Registers aura towers, queries bonuses |
| `AllyManager` | Autoload #11 | Summoner building squads |

---

## Field Name Discipline (BuildingData)

| ❌ Wrong | ✅ Correct |
|---|---|
| `build_gold_cost` | `gold_cost` |
| `targeting_priority` | `target_priority` |
| `build_material_cost` | `material_cost` |

---

## Building Placement Flow (§27.2)

1. Player clicks hex slot → `BuildPhaseManager.assert_build_phase("placement")` must return `true`
2. `EconomyManager.can_afford_building(building_data)` — abort if false
3. `EconomyManager.register_purchase(building_data)` — charges scaled cost, increments dup count
4. `BuildingBase.initialize(building_data, slot_index)` called BEFORE `add_child()`
5. `HexGrid` places building node; emits `SignalBus.building_placed(slot_index, building_type)`

### Sell Flow
1. `EconomyManager.get_refund(building_data, paid_gold, paid_material)` → refund dict
2. `EconomyManager.add_gold(refund.gold)` + `add_building_material(refund.material)`
3. `HexGrid` frees building node; emits `SignalBus.building_sold(slot_index, building_type)`

---

## How to Add a New Building (9 steps)

1. Add `BUILDING_NAME` to `Types.BuildingType` enum in `scripts/types.gd`
2. Create `resources/building_data/building_name.tres` with all required fields
3. Set `building_id` = `"building_name"` (matches file name, no .tres extension)
4. Set `gold_cost`, `material_cost`, `damage`, `damage_type`, `target_priority`, `building_size_class`
5. If aura building: set `is_aura = true`, `aura_effect_type`, `aura_modifier_value`
6. If summoner building: set `is_summoner = true`, `squad_ally_ids`
7. If research-locked: set `is_locked = true`, `unlock_research_id`
8. Add to `BuildMenu` scene — register the .tres in the build menu catalog
9. Write test: at minimum `test_building_name_can_be_placed_and_sold()`

---

## Ring Structure

- 42 slots across 3 rings
- Ring 1 (inner): slots 0–5
- Ring 2 (middle): slots 6–13
- Ring 3 (outer): slots 14–23
- `ring_rotation` exists on HexGrid
- Pre-battle ring rotation UI: **PLANNED, not yet implemented**

---

## BuildPhaseManager

```gdscript
# Autoload #10 — headless-safe
BuildPhaseManager.assert_build_phase("context_string") -> bool
# Returns true if in build phase. Default: true (headless tests).

BuildPhaseManager.set_build_phase_active(active: bool) -> void
# Emits SignalBus.build_phase_started() or SignalBus.combat_phase_started()
```

Always call `assert_build_phase()` before any placement operation.

---

## Aura Buildings

```gdscript
# Registration
AuraManager.register_aura(building: BuildingBase) -> void
AuraManager.deregister_aura(building_instance_id: String) -> void

# Query
AuraManager.get_damage_pct_bonus(building: BuildingBase) -> float
AuraManager.get_enemy_speed_modifier(world_pos: Vector3) -> float
```

Aura effect types: `damage_pct`, `enemy_speed_pct`.

---

## Summoner Buildings

```gdscript
# Spawn/despawn squads keyed by placed_instance_id
AllyManager.spawn_squad(building: BuildingBase) -> void
AllyManager.despawn_squad(building_instance_id: String) -> void
```

---

## Full Type Tables

Read `references/building-types.md` when:
- Looking up the integer value of a BuildingType enum
- Checking the size class of a building
- Verifying all 36 building IDs

---

**36 types:** `scripts/types.gd` enum `BuildingType` and `resources/building_data/` align with `references/building-types.md` (verified 2026-03-31).
