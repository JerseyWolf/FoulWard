---
name: economy-system
description: >-
  Activate when working with resources, costs, or purchases in Foul Ward.
  Use when: gold, building material, research material, EconomyManager,
  afford, spend, refund, duplicate cost scaling, currency, purchase,
  resource_changed, wave reward, mission economy, sell refund fraction.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Economy System — Foul Ward

---

## Autoload: EconomyManager (Init #5)

File: `autoloads/economy_manager.gd`

ALL resource modifications go through EconomyManager's public methods.
Never access `gold`, `building_material`, or `research_material` directly.

---

## Constants

```gdscript
DEFAULT_GOLD = 1000
DEFAULT_BUILDING_MATERIAL = 50
DEFAULT_RESEARCH_MATERIAL = 0
DEFAULT_SELL_REFUND_FRACTION = 0.6
DEFAULT_DUPLICATE_COST_K = 0.08
```

*Verified against `autoloads/economy_manager.gd` (2026-03-31).*

---

## Duplicate Cost Scaling

Linear per `building_id`:
- Formula: `cost_multiplier = 1.0 + k * n`
- `k` = `DEFAULT_DUPLICATE_COST_K` (0.08)
- `n` = number of times that building_id has been purchased this mission

---

## Sell Refund

refund = sell_refund_fraction × sell_refund_global_multiplier × paid_cost

Default fraction: 0.6 (60% refund).

---

## Full API

```gdscript
# Resource modifications
EconomyManager.add_gold(amount: int) -> void
EconomyManager.spend_gold(amount: int) -> bool        # false if insufficient
EconomyManager.add_building_material(amount: int) -> void
EconomyManager.spend_building_material(amount: int) -> bool
EconomyManager.add_research_material(amount: int) -> void
EconomyManager.spend_research_material(amount: int) -> bool

# Affordability
EconomyManager.can_afford(gold_cost: int, material_cost: int) -> bool
EconomyManager.can_afford_building(building_data: BuildingData) -> bool

# Queries
EconomyManager.get_gold() -> int
EconomyManager.get_building_material() -> int
EconomyManager.get_research_material() -> int
EconomyManager.get_gold_cost(building_data: BuildingData) -> int
EconomyManager.get_material_cost(building_data: BuildingData) -> int
EconomyManager.get_cost_multiplier(building_data: BuildingData) -> float
EconomyManager.get_duplicate_count(building_id: String) -> int

# Transactions
EconomyManager.register_purchase(building_data: BuildingData) -> Dictionary
# Returns: {paid_gold, paid_material, duplicate_count_after} or {} on failure

EconomyManager.get_refund(building_data: BuildingData, paid_gold: int, paid_material: int) -> Dictionary
# Returns: {gold, material}

# Wave rewards
EconomyManager.grant_wave_clear_reward(wave: int, econ: MissionEconomyData) -> Vector2i
EconomyManager.get_wave_reward_gold(wave: int, econ: MissionEconomyData) -> int
EconomyManager.get_wave_reward_material(wave: int, econ: MissionEconomyData) -> int

# Mission / lifecycle
EconomyManager.reset_for_mission() -> void          # clears dup counts
EconomyManager.apply_mission_economy(econ: MissionEconomyData) -> void
EconomyManager.reset_to_defaults() -> void          # full reset for new game
EconomyManager.apply_save_snapshot(g: int, building_mat: int, research_mat: int) -> void
```

---

## Signal

```gdscript
SignalBus.resource_changed(resource_type: Types.ResourceType, new_amount: int)
# Emitted on EVERY modification — gold, building_material, or research_material
```

---

## Usage Patterns

```gdscript
# Check before purchase
if EconomyManager.can_afford_building(building_data):
    var result := EconomyManager.register_purchase(building_data)
    if result.is_empty():
        push_warning("Purchase failed")
        return
    # proceed with placement

# Manual refund on sell
var refund := EconomyManager.get_refund(building_data, paid_gold, paid_material)
EconomyManager.add_gold(refund.gold)
EconomyManager.add_building_material(refund.material)
```
