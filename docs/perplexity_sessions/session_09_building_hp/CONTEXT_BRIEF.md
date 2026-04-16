# Context Brief — Session 9: Building HP

## Buildings (§8)

STATUS: EXISTS IN CODE

36 BuildingData .tres files under res://resources/building_data/.

Key field names (use exact names):
- gold_cost (not build_gold_cost), target_priority, damage_type, building_id

### BuildingSizeClass Enum
| Name | Value |
|------|-------|
| SINGLE_SLOT | 0 |
| DOUBLE_WIDE | 1 |
| TRIPLE_CLUSTER | 2 |
| SMALL | 3 |
| MEDIUM | 4 |
| LARGE | 5 |

### Ring Rotation
EXISTS: rotate_ring() in BuildPhaseManager / HexGrid.

## Signal Bus — Building Signals (§24)

| Signal | Parameters |
|--------|-----------|
| building_placed | slot_index: int, building_type: Types.BuildingType |
| building_sold | slot_index: int, building_type: Types.BuildingType |
| building_upgraded | slot_index: int, building_type: Types.BuildingType |
| building_destroyed | slot_index: int |

Note: building_destroyed is declared but never emitted (POST-MVP stub). This session activates it.

## Building Placement Flow (§27.2)

1. Player enters BUILD_MODE (B key or Tab)
2. Player clicks a HexGrid slot -> InputManager raycasts
3. Player selects building -> BuildMenu checks EconomyManager.can_afford_building
4. HexGrid.place_building(slot_index, building_type):
   - BuildPhaseManager.assert_build_phase("place_building")
   - EconomyManager.register_purchase(building_data)
   - building.initialize_with_economy(building_data, paid_gold, paid_material)
   - If building_data.is_aura: AuraManager.register_aura(building)
   - If building_data.is_summoner: AllyManager.spawn_squad(building)
   - SignalBus.building_placed.emit(slot_index, building_type)
5. Selling:
   - If summoner: AllyManager.despawn_squad(instance_id)
   - If aura: AuraManager.deregister_aura(instance_id)
   - building.queue_free()
   - SignalBus.building_sold.emit(slot_index, building_type)

Note: Batch 5 extracted _try_place_building into _validate_placement() + _instantiate_and_place().

## HealthComponent Pattern

HealthComponent is used by Tower and EnemyBase. Key signals:
- health_changed(current_hp: int, max_hp: int)
- health_depleted()

Methods: take_damage(amount: int), heal(amount: int), reset_to_max().

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- is_instance_valid() before accessing enemies, projectiles, or allies (freed mid-frame)
- push_warning() not assert() in production
- _physics_process for game logic — _process for visual/UI only
