# FOUL WARD — SYSTEMS.md — Part 2 of 3
# Systems: Hex Grid & Build System | Projectile System | HealthComponent
# Reference: ARCHITECTURE.md + CONVENTIONS.md are canonical.
# Carries forward: damage_immunities: Array[Types.DamageType] decision from Part 1 §3.8.
# UI layer MUST NOT appear anywhere — systems communicate only via SignalBus.

---

# ═══════════════════════════════════════════════════════════════════
# SYSTEM 4 — HEALTH COMPONENT
# File: res://scripts/health_component.gd
# Attached to: Tower, Arnulf, BuildingBase, EnemyBase (as child Node)
# ═══════════════════════════════════════════════════════════════════

## 4.1 PURPOSE

HealthComponent is a reusable, self-contained HP tracker. It owns `current_hp` and
`max_hp`, exposes damage/heal/reset methods, and emits LOCAL signals (not on SignalBus).
The owning node connects to these local signals and decides what they mean:

- Tower connects `health_depleted` → emits `SignalBus.tower_destroyed()`
- Arnulf connects `health_depleted` → enters DOWNED state
- EnemyBase connects `health_depleted` → emits `SignalBus.enemy_killed()`, queue_free()
- BuildingBase connects `health_depleted` → enters DESTROYED state (post-MVP)

HealthComponent has ZERO knowledge of who owns it. It never references SignalBus,
EconomyManager, DamageCalculator, or any other system. Pure encapsulated HP logic.

**Important**: HealthComponent does NOT apply the damage matrix. The calling system
(EnemyBase, Tower, etc.) is responsible for calling `DamageCalculator.calculate_damage()`
and checking `damage_immunities` BEFORE passing the final value to HealthComponent.
HealthComponent receives a pre-calculated float and subtracts it from HP.

---

## 4.2 CLASS VARIABLES

```gdscript
class_name HealthComponent
extends Node

## Maximum hit points. Set by owning scene or via @export in the editor.
@export var max_hp: int = 100

## Current hit points. Initialized to max_hp in _ready().
var current_hp: int = 0

## Whether this entity is currently considered "alive" (HP > 0).
var _is_alive: bool = true
```

---

## 4.3 SIGNALS (LOCAL — not on SignalBus)

```gdscript
## Emitted whenever current_hp changes. Receivers use this for HP bars, effects.
signal health_changed(current_hp: int, max_hp: int)

## Emitted once when current_hp reaches 0. Only fires once per "life."
## Reset by calling reset_to_max() or heal() above 0.
signal health_depleted()
```

---

## 4.4 METHOD SIGNATURES

```gdscript
# === PUBLIC API ===

## Applies [amount] damage. Clamps current_hp to 0 minimum.
## If current_hp reaches 0 and was previously alive, emits health_depleted.
## amount must be >= 0.0. Fractional damage is floored to int.
func take_damage(amount: float) -> void

## Heals by [amount] HP. Clamps to max_hp. If was depleted and heal brings
## HP above 0, re-enables alive state (allows health_depleted to fire again).
func heal(amount: int) -> void

## Sets current_hp to max_hp and re-enables alive state.
func reset_to_max() -> void

## Returns current_hp.
func get_current_hp() -> int

## Returns max_hp.
func get_max_hp() -> int

## Returns true if current_hp > 0.
func is_alive() -> bool

## Returns current_hp as a float ratio (0.0 to 1.0) for progress bars.
func get_hp_ratio() -> float
```

---

## 4.5 PSEUDOCODE

### _ready()

```gdscript
func _ready() -> void:
    current_hp = max_hp
    _is_alive = true
```

### take_damage(amount)

```gdscript
func take_damage(amount: float) -> void:
    assert(amount >= 0.0, "take_damage called with negative amount: %f" % amount)

    if not _is_alive:
        return  # Already depleted — ignore further damage

    var int_damage: int = int(amount)
    if int_damage <= 0:
        return  # Fractional damage below 1.0 does nothing

    current_hp = max(current_hp - int_damage, 0)
    health_changed.emit(current_hp, max_hp)

    if current_hp <= 0 and _is_alive:
        _is_alive = false
        health_depleted.emit()
```

### heal(amount)

```gdscript
func heal(amount: int) -> void:
    assert(amount > 0, "heal called with non-positive amount: %d" % amount)

    var was_depleted: bool = not _is_alive

    current_hp = min(current_hp + amount, max_hp)

    # Re-enable alive state so health_depleted can fire again if HP drops to 0
    if current_hp > 0:
        _is_alive = true

    health_changed.emit(current_hp, max_hp)
```

### reset_to_max()

```gdscript
func reset_to_max() -> void:
    current_hp = max_hp
    _is_alive = true
    health_changed.emit(current_hp, max_hp)
```

### Getters

```gdscript
func get_current_hp() -> int:
    return current_hp

func get_max_hp() -> int:
    return max_hp

func is_alive() -> bool:
    return _is_alive

func get_hp_ratio() -> float:
    if max_hp <= 0:
        return 0.0
    return float(current_hp) / float(max_hp)
```

---

## 4.6 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **Damage after already depleted** | `_is_alive` guard returns immediately. `health_depleted` fires only once. |
| **Damage of exactly remaining HP** | `current_hp` becomes 0. `health_depleted` fires. |
| **Damage exceeding remaining HP (overkill)** | `current_hp` clamped to 0. No negative HP. |
| **Fractional damage < 1.0** | `int(0.7)` = 0 → no damage applied. Prevents micro-damage noise. |
| **Heal while at max HP** | `min()` clamp prevents exceeding `max_hp`. Signal still emits (for UI refresh). |
| **Heal from 0 HP (resurrection)** | `_is_alive` becomes true again. Arnulf uses this: `heal(max_hp / 2)` during recovery. `health_depleted` can fire again if HP drops to 0 a second time. |
| **Multiple take_damage calls same frame** | All process sequentially (single-threaded). Each reduces HP. `health_depleted` fires on the call that reaches 0, not on subsequent calls. |
| **max_hp of 0** | `get_hp_ratio()` returns 0.0 (division guard). Not a valid gameplay state — assert at scene-level if needed. |
| **reset_to_max after depletion** | Restores full HP and re-enables alive state. Used by Tower between missions. |
| **take_damage(0.0)** | Passes assert (>= 0.0) but `int(0.0) = 0`, so early return. No signal emitted. |
| **Negative heal amount** | Assert fires. |

---

## 4.7 GdUnit4 TEST SPECIFICATIONS

File: `res://tests/test_health_component.gd`

```gdscript
class_name TestHealthComponent
extends GdUnitTestSuite
```

### Test: Initialization

```
test_init_current_hp_equals_max_hp
    Arrange: Create HealthComponent with max_hp = 200.
    Act:     Call _ready() (or let scene tree initialize).
    Assert:  get_current_hp() == 200
             get_max_hp() == 200
             is_alive() == true

test_init_hp_ratio_is_1_0
    Arrange: Create HealthComponent with max_hp = 100.
    Assert:  get_hp_ratio() == 1.0

test_init_default_max_hp_is_100
    Arrange: Create HealthComponent with no @export override.
    Assert:  get_max_hp() == 100
```

### Test: take_damage

```
test_take_damage_reduces_current_hp
    Arrange: HealthComponent max_hp = 100. current_hp = 100.
    Act:     take_damage(30.0)
    Assert:  get_current_hp() == 70

test_take_damage_emits_health_changed
    Arrange: HealthComponent max_hp = 100. Monitor health_changed signal.
    Act:     take_damage(25.0)
    Assert:  health_changed emitted with (75, 100)

test_take_damage_to_zero_emits_health_depleted
    Arrange: HealthComponent max_hp = 50. current_hp = 50.
             Monitor health_depleted signal.
    Act:     take_damage(50.0)
    Assert:  get_current_hp() == 0
             health_depleted emitted exactly once
             is_alive() == false

test_take_damage_overkill_clamps_to_zero
    Arrange: HealthComponent max_hp = 50. current_hp = 50.
    Act:     take_damage(999.0)
    Assert:  get_current_hp() == 0 (not negative)
             health_depleted emitted

test_take_damage_after_depleted_is_ignored
    Arrange: HealthComponent max_hp = 50. take_damage(50.0) → depleted.
             Clear signal monitors.
    Act:     take_damage(10.0)
    Assert:  get_current_hp() == 0 (unchanged)
             health_changed NOT emitted
             health_depleted NOT emitted again

test_take_damage_fractional_below_one_does_nothing
    Arrange: HealthComponent max_hp = 100. current_hp = 100.
             Monitor health_changed.
    Act:     take_damage(0.5)
    Assert:  get_current_hp() == 100
             health_changed NOT emitted

test_take_damage_fractional_above_one_floors
    Arrange: HealthComponent max_hp = 100.
    Act:     take_damage(1.9)
    Assert:  get_current_hp() == 99  # int(1.9) = 1

test_take_damage_zero_does_nothing
    Arrange: HealthComponent max_hp = 100. Monitor health_changed.
    Act:     take_damage(0.0)
    Assert:  get_current_hp() == 100
             health_changed NOT emitted

test_take_damage_negative_asserts
    Act:     take_damage(-10.0)
    Assert:  Assert fires.

test_take_damage_exact_remaining_hp
    Arrange: HealthComponent max_hp = 100. take_damage(60.0) → current_hp = 40.
    Act:     take_damage(40.0)
    Assert:  get_current_hp() == 0
             health_depleted emitted

test_take_damage_multiple_calls_accumulate
    Arrange: HealthComponent max_hp = 100.
    Act:     take_damage(20.0). take_damage(30.0). take_damage(10.0).
    Assert:  get_current_hp() == 40

test_take_damage_depleted_fires_only_once_across_multiple_hits
    Arrange: HealthComponent max_hp = 10.
             Monitor health_depleted. Count emissions.
    Act:     take_damage(5.0). take_damage(5.0). take_damage(5.0).
    Assert:  health_depleted emitted exactly 1 time (on second call).
```

### Test: heal

```
test_heal_increases_current_hp
    Arrange: HealthComponent max_hp = 100. take_damage(40.0) → current_hp = 60.
    Act:     heal(20)
    Assert:  get_current_hp() == 80

test_heal_clamps_to_max_hp
    Arrange: HealthComponent max_hp = 100. take_damage(10.0) → current_hp = 90.
    Act:     heal(50)
    Assert:  get_current_hp() == 100 (not 140)

test_heal_at_max_hp_stays_at_max
    Arrange: HealthComponent max_hp = 100. current_hp = 100.
    Act:     heal(10)
    Assert:  get_current_hp() == 100

test_heal_emits_health_changed
    Arrange: HealthComponent. take_damage(30.0). Monitor health_changed. Clear.
    Act:     heal(15)
    Assert:  health_changed emitted with (85, 100)

test_heal_from_zero_reenables_alive
    Arrange: HealthComponent max_hp = 100. take_damage(100.0) → depleted.
    Act:     heal(50)
    Assert:  get_current_hp() == 50
             is_alive() == true

test_heal_from_zero_allows_depleted_to_fire_again
    Arrange: HealthComponent max_hp = 100.
             take_damage(100.0) → depleted. heal(50) → alive again.
             Monitor health_depleted. Clear.
    Act:     take_damage(50.0)
    Assert:  health_depleted emitted (second time total, first since heal)

test_heal_negative_amount_asserts
    Act:     heal(-5)
    Assert:  Assert fires.

test_heal_zero_amount_asserts
    Act:     heal(0)
    Assert:  Assert fires.
```

### Test: reset_to_max

```
test_reset_to_max_restores_full_hp
    Arrange: HealthComponent max_hp = 200. take_damage(150.0).
    Act:     reset_to_max()
    Assert:  get_current_hp() == 200

test_reset_to_max_reenables_alive_after_depletion
    Arrange: HealthComponent max_hp = 50. take_damage(50.0) → depleted.
    Act:     reset_to_max()
    Assert:  is_alive() == true
             get_current_hp() == 50

test_reset_to_max_emits_health_changed
    Arrange: Monitor health_changed.
    Act:     reset_to_max()
    Assert:  health_changed emitted with (max_hp, max_hp).

test_reset_to_max_at_full_hp_is_idempotent
    Arrange: HealthComponent max_hp = 100. current_hp = 100.
    Act:     reset_to_max()
    Assert:  get_current_hp() == 100. is_alive() == true.
```

### Test: get_hp_ratio

```
test_hp_ratio_full_returns_1_0
    Assert:  get_hp_ratio() == 1.0

test_hp_ratio_half_returns_0_5
    Arrange: max_hp = 100. take_damage(50.0).
    Assert:  get_hp_ratio() == 0.5

test_hp_ratio_zero_returns_0_0
    Arrange: max_hp = 100. take_damage(100.0).
    Assert:  get_hp_ratio() == 0.0

test_hp_ratio_max_hp_zero_returns_0_0
    Arrange: Set max_hp = 0 directly (edge case).
    Assert:  get_hp_ratio() == 0.0 (not NaN or crash)
```

### Test: Arnulf Resurrection Cycle

```
test_arnulf_cycle_deplete_heal_deplete
    Arrange: HealthComponent max_hp = 200. Monitor health_depleted. Count emissions.
    Act:     take_damage(200.0) → depleted. heal(100) → alive.
             take_damage(100.0) → depleted again.
    Assert:  health_depleted emitted exactly 2 times.
             get_current_hp() == 0.

test_arnulf_cycle_heal_to_half_max
    Arrange: HealthComponent max_hp = 200. take_damage(200.0).
    Act:     heal(100)  # 50% of max_hp
    Assert:  get_current_hp() == 100
             is_alive() == true
```

---


# ═══════════════════════════════════════════════════════════════════
# SYSTEM 5 — HEX GRID & BUILD SYSTEM
# File: res://scenes/hex_grid/hex_grid.gd (on HexGrid Node3D)
# Also covers: res://scenes/buildings/building_base.gd (BuildingBase)
# ═══════════════════════════════════════════════════════════════════

## 5.1 PURPOSE

HexGrid manages 24 hex-shaped building slots arranged in concentric rings around the
tower. It handles placement, selling, upgrading, and between-mission persistence of
buildings. All resource cost transactions flow through EconomyManager. All lock checks
flow through ResearchManager (which lives on the Managers node — HexGrid has a typed
reference to it).

BuildingBase is the base class for all 8 building types. It is initialized with a
`BuildingData` resource, contains autonomous targeting and attack logic, and fires
projectiles at enemies within range. Special types (Archer Barracks, Shield Generator)
override the attack behavior.

HexGrid owns the data; BuildingBase owns the runtime combat behavior.

---

## 5.2 HEX GRID — CLASS VARIABLES

```gdscript
class_name HexGrid
extends Node3D

## Registry mapping BuildingType → BuildingData resource.
## Must have exactly 8 entries, one per Types.BuildingType.
@export var building_data_registry: Array[BuildingData] = []

# Preloaded scene
const BuildingScene: PackedScene = preload("res://scenes/buildings/building_base.tscn")

# Internal slot data — populated in _ready()
# Each entry: { "index": int, "world_pos": Vector3, "building": BuildingBase or null,
#               "is_occupied": bool }
var _slots: Array[Dictionary] = []

# Ring layout constants
const RING_1_COUNT: int = 6
const RING_1_RADIUS: float = 6.0
const RING_2_COUNT: int = 12
const RING_2_RADIUS: float = 12.0
const RING_3_COUNT: int = 6
const RING_3_RADIUS: float = 18.0
const TOTAL_SLOTS: int = 24   # RING_1 + RING_2 + RING_3

# Scene references
@onready var _building_container: Node3D = get_node("/root/Main/BuildingContainer")

# Reference to ResearchManager — needed for lock checks.
# Set via @export or _ready() traversal.
var _research_manager: Node = null  # Typed as Node; cast to ResearchManager at runtime
```

**ASSUMPTION**: `_building_container` path matches ARCHITECTURE.md scene tree.
**ASSUMPTION**: ResearchManager is accessible. HexGrid gets a reference during `_ready()`
via `get_node("/root/Main/Managers/ResearchManager")`. If ResearchManager is null
(e.g., during unit tests), lock checks are skipped (all buildings available).

---

## 5.3 HEX GRID — SIGNALS EMITTED (via SignalBus)

| Signal              | Payload                                        | When                 |
|---------------------|------------------------------------------------|----------------------|
| `building_placed`   | `slot_index: int, building_type: Types.BuildingType` | After successful placement |
| `building_sold`     | `slot_index: int, building_type: Types.BuildingType` | After successful sell |
| `building_upgraded` | `slot_index: int, building_type: Types.BuildingType` | After successful upgrade |

## 5.4 HEX GRID — SIGNALS CONSUMED (from SignalBus)

| Signal              | Handler                         | Action                                |
|---------------------|---------------------------------|---------------------------------------|
| `build_mode_entered`| `_on_build_mode_entered()`      | Show slot meshes                      |
| `build_mode_exited` | `_on_build_mode_exited()`       | Hide slot meshes                      |
| `research_unlocked` | `_on_research_unlocked(node_id)`| Update building lock state cache      |

---

## 5.5 HEX GRID — METHOD SIGNATURES

```gdscript
# === PUBLIC API (Bot-callable) ===

## Places a building of [building_type] on slot [slot_index].
## Checks: slot valid, not occupied, research unlocked, can afford.
## Spends resources, instantiates building, emits building_placed.
## Returns true on success, false on any validation failure.
func place_building(slot_index: int, building_type: Types.BuildingType) -> bool

## Sells the building on slot [slot_index].
## Refunds full gold + material cost. Frees the building node.
## Returns true on success, false if slot empty or invalid.
func sell_building(slot_index: int) -> bool

## Upgrades the building on slot [slot_index] from Basic to Upgraded.
## Checks: slot occupied, not already upgraded, can afford upgrade costs.
## Returns true on success, false on any validation failure.
func upgrade_building(slot_index: int) -> bool

## Returns a copy of the slot data dictionary for [slot_index].
## Keys: "index", "world_pos", "building" (or null), "is_occupied".
func get_slot_data(slot_index: int) -> Dictionary

## Returns array of slot indices that have buildings.
func get_all_occupied_slots() -> Array[int]

## Returns array of slot indices that are empty.
func get_empty_slots() -> Array[int]

## Frees all buildings and resets all slots. Called on new game.
func clear_all_buildings() -> void

## Returns the BuildingData for a given BuildingType from the registry.
func get_building_data(building_type: Types.BuildingType) -> BuildingData

## Returns whether a building type is currently unlocked.
func is_building_unlocked(building_type: Types.BuildingType) -> bool

## Returns the world position of a slot.
func get_slot_position(slot_index: int) -> Vector3


# === PRIVATE METHODS ===

## Builds the _slots array and positions the 24 Area3D slot nodes.
func _initialize_slots() -> void

## Computes world positions for a ring of N slots at a given radius.
func _compute_ring_positions(count: int, radius: float, angle_offset: float) -> Array[Vector3]

## Shows/hides hex slot visual meshes.
func _set_slots_visible(visible: bool) -> void
```

---

## 5.6 HEX GRID — PSEUDOCODE

### _ready()

```gdscript
func _ready() -> void:
    SignalBus.build_mode_entered.connect(_on_build_mode_entered)
    SignalBus.build_mode_exited.connect(_on_build_mode_exited)
    SignalBus.research_unlocked.connect(_on_research_unlocked)

    # Get ResearchManager reference (nullable for tests)
    _research_manager = get_node_or_null("/root/Main/Managers/ResearchManager")

    assert(building_data_registry.size() == 8,
        "building_data_registry must have 8 entries, got %d" % building_data_registry.size())

    _initialize_slots()
    _set_slots_visible(false)  # Hidden by default
```

### _initialize_slots()

```gdscript
func _initialize_slots() -> void:
    _slots.clear()
    var positions: Array[Vector3] = []

    # Ring 1: 6 inner slots, 60° apart
    positions.append_array(_compute_ring_positions(RING_1_COUNT, RING_1_RADIUS, 0.0))
    # Ring 2: 12 middle slots, 30° apart
    positions.append_array(_compute_ring_positions(RING_2_COUNT, RING_2_RADIUS, 0.0))
    # Ring 3: 6 outer slots, 60° apart, offset by 30°
    positions.append_array(_compute_ring_positions(RING_3_COUNT, RING_3_RADIUS, 30.0))

    assert(positions.size() == TOTAL_SLOTS,
        "Expected %d positions, got %d" % [TOTAL_SLOTS, positions.size()])

    for i: int in range(TOTAL_SLOTS):
        var slot_data: Dictionary = {
            "index": i,
            "world_pos": positions[i],
            "building": null,
            "is_occupied": false,
        }
        _slots.append(slot_data)

        # Position the corresponding HexSlot Area3D child
        var slot_node: Area3D = get_child(i) as Area3D
        if slot_node != null:
            slot_node.global_position = positions[i]
```

### _compute_ring_positions(count, radius, angle_offset)

```gdscript
func _compute_ring_positions(
    count: int,
    radius: float,
    angle_offset_degrees: float
) -> Array[Vector3]:
    var positions: Array[Vector3] = []
    var angle_step: float = TAU / float(count)  # TAU = 2 * PI
    var offset_rad: float = deg_to_rad(angle_offset_degrees)

    for i: int in range(count):
        var angle: float = (float(i) * angle_step) + offset_rad
        var x: float = radius * cos(angle)
        var z: float = radius * sin(angle)
        positions.append(Vector3(x, 0.0, z))

    return positions
```

### place_building(slot_index, building_type)

```gdscript
func place_building(slot_index: int, building_type: Types.BuildingType) -> bool:
    # Validate slot index
    if slot_index < 0 or slot_index >= TOTAL_SLOTS:
        push_warning("place_building: invalid slot_index %d" % slot_index)
        return false

    var slot: Dictionary = _slots[slot_index]

    # Check not occupied
    if slot["is_occupied"]:
        push_warning("place_building: slot %d already occupied" % slot_index)
        return false

    # Get BuildingData
    var building_data: BuildingData = get_building_data(building_type)
    if building_data == null:
        push_error("place_building: no BuildingData for type %d" % building_type)
        return false

    # Check research unlock
    if not is_building_unlocked(building_type):
        return false

    # Check affordability
    if not EconomyManager.can_afford(building_data.gold_cost, building_data.material_cost):
        return false

    # Spend resources — both must succeed
    var gold_spent: bool = EconomyManager.spend_gold(building_data.gold_cost)
    assert(gold_spent, "spend_gold failed after can_afford returned true")
    var mat_spent: bool = EconomyManager.spend_building_material(building_data.material_cost)
    assert(mat_spent, "spend_building_material failed after can_afford returned true")

    # Instantiate building
    var building: BuildingBase = BuildingScene.instantiate() as BuildingBase
    building.initialize(building_data)
    building.global_position = slot["world_pos"]
    _building_container.add_child(building)
    building.add_to_group("buildings")

    # Update slot
    slot["building"] = building
    slot["is_occupied"] = true

    SignalBus.building_placed.emit(slot_index, building_type)
    return true
```

### sell_building(slot_index)

```gdscript
func sell_building(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= TOTAL_SLOTS:
        return false

    var slot: Dictionary = _slots[slot_index]
    if not slot["is_occupied"]:
        return false

    var building: BuildingBase = slot["building"] as BuildingBase
    var building_data: BuildingData = building.get_building_data()
    var building_type: Types.BuildingType = building_data.building_type

    # Full refund — base cost always, upgrade cost only if upgraded
    EconomyManager.add_gold(building_data.gold_cost)
    EconomyManager.add_building_material(building_data.material_cost)

    if building.is_upgraded:
        EconomyManager.add_gold(building_data.upgrade_gold_cost)
        EconomyManager.add_building_material(building_data.upgrade_material_cost)

    building.remove_from_group("buildings")
    building.queue_free()

    slot["building"] = null
    slot["is_occupied"] = false

    SignalBus.building_sold.emit(slot_index, building_type)
    return true
```

### upgrade_building(slot_index)

```gdscript
func upgrade_building(slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= TOTAL_SLOTS:
        return false

    var slot: Dictionary = _slots[slot_index]
    if not slot["is_occupied"]:
        return false

    var building: BuildingBase = slot["building"] as BuildingBase
    if building.is_upgraded:
        return false  # Already upgraded

    var building_data: BuildingData = building.get_building_data()

    if not EconomyManager.can_afford(
        building_data.upgrade_gold_cost,
        building_data.upgrade_material_cost
    ):
        return false

    EconomyManager.spend_gold(building_data.upgrade_gold_cost)
    EconomyManager.spend_building_material(building_data.upgrade_material_cost)

    building.upgrade()

    SignalBus.building_upgraded.emit(slot_index, building_data.building_type)
    return true
```

### clear_all_buildings()

```gdscript
func clear_all_buildings() -> void:
    for slot: Dictionary in _slots:
        if slot["is_occupied"]:
            var building: BuildingBase = slot["building"] as BuildingBase
            if is_instance_valid(building):
                building.remove_from_group("buildings")
                building.queue_free()
            slot["building"] = null
            slot["is_occupied"] = false
```

### is_building_unlocked(building_type)

```gdscript
func is_building_unlocked(building_type: Types.BuildingType) -> bool:
    var building_data: BuildingData = get_building_data(building_type)
    if building_data == null:
        return false

    # If building is not locked, always available
    if not building_data.is_locked:
        return true

    # If no ResearchManager (unit test context), treat all as unlocked
    if _research_manager == null:
        return true

    return _research_manager.is_unlocked(building_data.unlock_research_id)
```

### get_building_data(building_type)

```gdscript
func get_building_data(building_type: Types.BuildingType) -> BuildingData:
    for data: BuildingData in building_data_registry:
        if data.building_type == building_type:
            return data
    return null
```

### Visibility and signal handlers

```gdscript
func _on_build_mode_entered() -> void:
    _set_slots_visible(true)

func _on_build_mode_exited() -> void:
    _set_slots_visible(false)

func _on_research_unlocked(_node_id: String) -> void:
    # No cache to update — is_building_unlocked() checks live state.
    # This handler exists for future UI refresh (e.g., glow newly unlocked slots).
    pass

func _set_slots_visible(visible: bool) -> void:
    for i: int in range(get_child_count()):
        var slot_node: Area3D = get_child(i) as Area3D
        if slot_node == null:
            continue
        var mesh: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
        if mesh != null:
            mesh.visible = visible

func get_slot_data(slot_index: int) -> Dictionary:
    assert(slot_index >= 0 and slot_index < TOTAL_SLOTS,
        "Invalid slot_index: %d" % slot_index)
    return _slots[slot_index].duplicate()

func get_all_occupied_slots() -> Array[int]:
    var result: Array[int] = []
    for slot: Dictionary in _slots:
        if slot["is_occupied"]:
            result.append(slot["index"])
    return result

func get_empty_slots() -> Array[int]:
    var result: Array[int] = []
    for slot: Dictionary in _slots:
        if not slot["is_occupied"]:
            result.append(slot["index"])
    return result

func get_slot_position(slot_index: int) -> Vector3:
    assert(slot_index >= 0 and slot_index < TOTAL_SLOTS)
    return _slots[slot_index]["world_pos"]
```

---

## 5.7 BUILDING BASE — CLASS VARIABLES

```gdscript
class_name BuildingBase
extends Node3D

# Data
var _building_data: BuildingData = null
var is_upgraded: bool = false

# Combat state
var _attack_timer: float = 0.0
var _current_target: Node3D = null  # EnemyBase reference

# Preloaded scene
const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")

# Children (set in _ready of the scene)
@onready var _mesh: MeshInstance3D = $BuildingMesh
@onready var _label: Label3D = $BuildingLabel
@onready var health_component: HealthComponent = $HealthComponent

# Scene reference for projectile container
@onready var _projectile_container: Node3D = get_node("/root/Main/ProjectileContainer")
```

---

## 5.8 BUILDING BASE — METHOD SIGNATURES

```gdscript
# === PUBLIC ===

## Called immediately after instantiation, before add_child.
## Configures the building from its data resource.
func initialize(data: BuildingData) -> void

## Upgrades the building from Basic to Upgraded tier.
## Applies upgraded stats from BuildingData.
func upgrade() -> void

## Returns the BuildingData resource this building was initialized with.
func get_building_data() -> BuildingData

## Returns the current effective damage (base or upgraded).
func get_effective_damage() -> float

## Returns the current effective range (base or upgraded).
func get_effective_range() -> float


# === PRIVATE ===

## Finds the best target within range based on targeting priority.
func _find_target() -> EnemyBase

## Fires a projectile at the current target.
func _fire_at_target() -> void

## Per-frame combat logic: find target, manage attack timer, fire.
func _combat_process(delta: float) -> void
```

---

## 5.9 BUILDING BASE — PSEUDOCODE

### initialize(data)

```gdscript
func initialize(data: BuildingData) -> void:
    _building_data = data
    is_upgraded = false

    # Visual setup (MVP: colored cube + label)
    if _mesh != null:
        var mat: StandardMaterial3D = StandardMaterial3D.new()
        mat.albedo_color = data.color
        _mesh.material_override = mat
    if _label != null:
        _label.text = data.display_name
```

### _physics_process(delta)

```gdscript
func _physics_process(delta: float) -> void:
    _combat_process(delta)
```

### _combat_process(delta)

```gdscript
func _combat_process(delta: float) -> void:
    if _building_data == null:
        return

    # Tick attack timer
    _attack_timer -= delta

    # Find or validate target
    if _current_target == null or not is_instance_valid(_current_target):
        _current_target = _find_target()

    if _current_target == null:
        return  # No valid targets in range

    # Check range (target may have moved since last frame)
    var distance: float = global_position.distance_to(_current_target.global_position)
    if distance > get_effective_range():
        _current_target = _find_target()
        if _current_target == null:
            return

    # Fire if ready
    if _attack_timer <= 0.0:
        _fire_at_target()
        _attack_timer = 1.0 / _building_data.fire_rate
```

### _find_target()

```gdscript
func _find_target() -> EnemyBase:
    var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
    var best_target: EnemyBase = null
    var best_distance: float = INF
    var effective_range: float = get_effective_range()

    for node: Node in enemies:
        var enemy: EnemyBase = node as EnemyBase
        if enemy == null or not is_instance_valid(enemy):
            continue
        if not enemy.health_component.is_alive():
            continue

        # Air targeting rules
        var enemy_data: EnemyData = enemy.get_enemy_data()
        if enemy_data.is_flying and not _building_data.targets_air:
            continue
        if not enemy_data.is_flying and not _building_data.targets_ground:
            continue

        var distance: float = global_position.distance_to(enemy.global_position)
        if distance > effective_range:
            continue

        # Default targeting: closest to building
        if distance < best_distance:
            best_distance = distance
            best_target = enemy

    return best_target
```

### _fire_at_target()

```gdscript
func _fire_at_target() -> void:
    if _current_target == null or not is_instance_valid(_current_target):
        return

    var projectile: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
    projectile.initialize_from_building(
        get_effective_damage(),
        _building_data.damage_type,
        _building_data.fire_rate,
        global_position,
        _current_target.global_position,
        _building_data.targets_air  # Determines collision mask
    )
    _projectile_container.add_child(projectile)
    projectile.add_to_group("projectiles")
```

### upgrade()

```gdscript
func upgrade() -> void:
    is_upgraded = true
    # Visual feedback (MVP: brighten color slightly)
    if _mesh != null:
        var mat: StandardMaterial3D = _mesh.material_override as StandardMaterial3D
        if mat != null:
            mat.albedo_color = _building_data.color.lightened(0.3)
    if _label != null:
        _label.text = _building_data.display_name + " +"
```

### Getters

```gdscript
func get_building_data() -> BuildingData:
    return _building_data

func get_effective_damage() -> float:
    if is_upgraded:
        return _building_data.upgraded_damage
    return _building_data.damage

func get_effective_range() -> float:
    if is_upgraded:
        return _building_data.upgraded_range
    return _building_data.attack_range
```

---

## 5.10 EDGE CASES (Hex Grid + BuildingBase)

| Edge Case | Handling |
|-----------|----------|
| **Place on occupied slot** | Returns false. No resources spent. |
| **Place locked building without research** | `is_building_unlocked()` returns false. Returns false. |
| **Place when cannot afford** | `can_afford()` returns false. Returns false. No partial spend. |
| **Sell empty slot** | Returns false. |
| **Sell refunds full cost including upgrade** | If upgraded, refunds base cost + upgrade cost. |
| **Upgrade already-upgraded building** | Returns false. |
| **Upgrade when cannot afford** | Returns false. |
| **Invalid slot_index (negative or >= 24)** | `place_building` returns false with push_warning. `get_slot_data` asserts. |
| **BuildingData registry missing an entry** | `get_building_data()` returns null → place_building returns false. |
| **Building target dies mid-attack-timer** | `is_instance_valid()` check in _combat_process. Finds new target. |
| **Anti-Air Bolt targeting ground enemy** | `targets_air = true, targets_ground = false` → _find_target skips non-flying. |
| **Poison Vat targeting flying enemy** | `targets_air = false` → _find_target skips flying. |
| **Shield Generator (no attack)** | BuildingData.damage = 0, fire_rate = 0. _combat_process: `1.0 / 0.0` would crash → GUARD: if fire_rate <= 0.0, skip combat entirely. Shield Generator overrides _combat_process to buff adjacent buildings instead. |
| **Archer Barracks (spawner)** | Overrides _fire_at_target to spawn archer units instead of projectiles. Post-MVP detail — MVP stub spawns nothing but occupies the slot. |
| **Buildings persist between missions** | HexGrid.clear_all_buildings() is only called on new game, NOT between missions. |
| **No enemies on map** | _find_target returns null. Building idles. |
| **ResearchManager null (unit test)** | is_building_unlocked returns true for all. |

---

## 5.11 GdUnit4 TEST SPECIFICATIONS

### File: `res://tests/test_hex_grid.gd`

```gdscript
class_name TestHexGrid
extends GdUnitTestSuite
```

### Test: Slot Initialization

```
test_initialize_creates_24_slots
    Arrange: Create HexGrid with 24 child Area3D nodes.
    Act:     Call _ready() / _initialize_slots().
    Assert:  _slots.size() == 24.

test_all_slots_start_unoccupied
    Arrange: Initialize HexGrid.
    Assert:  For all 24 slots: slot["is_occupied"] == false.

test_slot_positions_ring_1_at_correct_radius
    Arrange: Initialize HexGrid.
    Assert:  Slots 0-5: distance from Vector3.ZERO ≈ 6.0 (within tolerance).

test_slot_positions_ring_2_at_correct_radius
    Assert:  Slots 6-17: distance from Vector3.ZERO ≈ 12.0.

test_slot_positions_ring_3_at_correct_radius
    Assert:  Slots 18-23: distance from Vector3.ZERO ≈ 18.0.

test_slot_positions_all_at_y_zero
    Assert:  All 24 slots have world_pos.y == 0.0.

test_ring_1_slots_evenly_spaced
    Assert:  Angular separation between consecutive Ring 1 slots ≈ 60°.

test_get_empty_slots_returns_all_24_initially
    Assert:  get_empty_slots().size() == 24.

test_get_all_occupied_slots_returns_empty_initially
    Assert:  get_all_occupied_slots().size() == 0.
```

### Test: Building Placement

```
test_place_building_on_empty_slot_succeeds
    Arrange: HexGrid initialized. EconomyManager has enough gold + material.
    Act:     place_building(0, Types.BuildingType.ARROW_TOWER)
    Assert:  Returns true.
             get_slot_data(0)["is_occupied"] == true.
             get_all_occupied_slots() == [0].

test_place_building_deducts_resources
    Arrange: EconomyManager: gold=100, material=10.
             Arrow Tower costs 50 gold + 2 material.
    Act:     place_building(0, ARROW_TOWER)
    Assert:  EconomyManager.get_gold() == 50.
             EconomyManager.get_building_material() == 8.

test_place_building_emits_building_placed_signal
    Arrange: Monitor SignalBus.building_placed.
    Act:     place_building(0, ARROW_TOWER)
    Assert:  building_placed emitted with (0, ARROW_TOWER).

test_place_building_on_occupied_slot_fails
    Arrange: place_building(0, ARROW_TOWER) → success.
    Act:     place_building(0, FIRE_BRAZIER)
    Assert:  Returns false. Slot still has arrow tower.
             Resources unchanged from second attempt.

test_place_building_insufficient_gold_fails
    Arrange: EconomyManager: gold=10. Arrow Tower costs 50.
    Act:     place_building(0, ARROW_TOWER)
    Assert:  Returns false. Slot empty. Gold unchanged.

test_place_building_insufficient_material_fails
    Arrange: EconomyManager: gold=100, material=0. Arrow Tower needs 2 material.
    Act:     place_building(0, ARROW_TOWER)
    Assert:  Returns false.

test_place_locked_building_without_research_fails
    Arrange: Ballista is_locked = true. ResearchManager has NOT unlocked it.
    Act:     place_building(0, BALLISTA)
    Assert:  Returns false.

test_place_locked_building_after_research_succeeds
    Arrange: Unlock Ballista via ResearchManager. Enough resources.
    Act:     place_building(0, BALLISTA)
    Assert:  Returns true.

test_place_unlocked_building_always_available
    Arrange: Arrow Tower is_locked = false.
    Act:     place_building(0, ARROW_TOWER) — no research needed.
    Assert:  Returns true.

test_place_building_invalid_slot_negative_fails
    Act:     place_building(-1, ARROW_TOWER)
    Assert:  Returns false.

test_place_building_invalid_slot_24_fails
    Act:     place_building(24, ARROW_TOWER)
    Assert:  Returns false.

test_place_building_adds_to_building_group
    Act:     place_building(0, ARROW_TOWER)
    Assert:  get_tree().get_nodes_in_group("buildings").size() == 1.

test_place_building_node_positioned_at_slot
    Act:     place_building(5, ARROW_TOWER)
    Assert:  The BuildingBase node's global_position matches _slots[5]["world_pos"].
```

### Test: Selling

```
test_sell_building_returns_true
    Arrange: place_building(0, ARROW_TOWER).
    Act:     sell_building(0)
    Assert:  Returns true. Slot is now empty.

test_sell_building_full_refund
    Arrange: EconomyManager: gold=50, material=8 (after placing arrow tower).
    Act:     sell_building(0)
    Assert:  gold = 50 + 50 = 100 (original). material = 8 + 2 = 10.

test_sell_upgraded_building_refunds_both_costs
    Arrange: place_building(0, ARROW_TOWER). upgrade_building(0).
             Record resources.
    Act:     sell_building(0)
    Assert:  Gold refunded = base gold_cost + upgrade_gold_cost.
             Material refunded = base material_cost + upgrade_material_cost.

test_sell_empty_slot_fails
    Act:     sell_building(0) — no building placed.
    Assert:  Returns false.

test_sell_emits_building_sold_signal
    Arrange: place_building(0, FIRE_BRAZIER). Monitor SignalBus.building_sold.
    Act:     sell_building(0)
    Assert:  building_sold emitted with (0, FIRE_BRAZIER).

test_sell_removes_from_building_group
    Arrange: place_building(0, ARROW_TOWER).
    Act:     sell_building(0). Wait one frame.
    Assert:  get_tree().get_nodes_in_group("buildings").size() == 0.

test_sell_building_invalid_slot_fails
    Act:     sell_building(-1)
    Assert:  Returns false.
```

### Test: Upgrading

```
test_upgrade_building_succeeds
    Arrange: place_building(0, ARROW_TOWER). Enough resources for upgrade.
    Act:     upgrade_building(0)
    Assert:  Returns true.
             Building.is_upgraded == true.

test_upgrade_deducts_upgrade_costs
    Arrange: Place + record resources. Upgrade costs 75 gold + 3 material.
    Act:     upgrade_building(0)
    Assert:  Gold decreased by 75. Material decreased by 3.

test_upgrade_already_upgraded_fails
    Arrange: Place + upgrade arrow tower.
    Act:     upgrade_building(0) — second time.
    Assert:  Returns false.

test_upgrade_empty_slot_fails
    Act:     upgrade_building(0) — no building.
    Assert:  Returns false.

test_upgrade_insufficient_funds_fails
    Arrange: place_building(0, ARROW_TOWER). Set gold = 0.
    Act:     upgrade_building(0)
    Assert:  Returns false. is_upgraded still false.

test_upgrade_emits_building_upgraded_signal
    Arrange: place + monitor.
    Act:     upgrade_building(0)
    Assert:  building_upgraded emitted with (0, ARROW_TOWER).

test_upgraded_building_uses_upgraded_stats
    Arrange: Place arrow tower. upgrade.
    Assert:  building.get_effective_damage() == BuildingData.upgraded_damage.
             building.get_effective_range() == BuildingData.upgraded_range.
```

### Test: clear_all_buildings

```
test_clear_all_buildings_empties_all_slots
    Arrange: Place buildings on slots 0, 5, 10.
    Act:     clear_all_buildings(). Wait one frame.
    Assert:  get_all_occupied_slots().size() == 0.
             get_empty_slots().size() == 24.

test_clear_all_buildings_frees_nodes
    Arrange: Place 3 buildings.
    Act:     clear_all_buildings(). Wait one frame.
    Assert:  _building_container.get_child_count() == 0.

test_clear_all_buildings_on_empty_grid_is_noop
    Act:     clear_all_buildings()
    Assert:  No errors. All slots remain empty.
```

### Test: Persistence

```
test_buildings_persist_between_missions
    Arrange: Place building on slot 3. Simulate mission complete
             (GameManager transitions to BETWEEN_MISSIONS then back to COMBAT).
    Assert:  get_slot_data(3)["is_occupied"] == true.
             Building node still valid.

test_buildings_cleared_on_new_game
    Arrange: Place buildings. Call clear_all_buildings() (as GameManager would).
    Assert:  All slots empty.
```

### File: `res://tests/test_building_base.gd`

```gdscript
class_name TestBuildingBase
extends GdUnitTestSuite
```

### Test: BuildingBase Combat

```
test_building_fires_at_enemy_in_range
    Arrange: Create BuildingBase (Arrow Tower, range=15). Place enemy at distance 10.
    Act:     Simulate physics frames until attack timer fires.
    Assert:  Projectile spawned in ProjectileContainer.

test_building_does_not_fire_at_enemy_out_of_range
    Arrange: BuildingBase range=15. Enemy at distance 20.
    Act:     Simulate physics frames.
    Assert:  No projectile spawned.

test_building_does_not_target_flying_if_targets_air_false
    Arrange: Arrow Tower (targets_air=false). Only enemy is Bat Swarm (flying).
    Act:     Simulate frames.
    Assert:  No projectile. _current_target == null.

test_anti_air_bolt_only_targets_flying
    Arrange: Anti-Air Bolt (targets_air=true, targets_ground=false).
             One ground enemy, one flying enemy.
    Act:     Simulate frames.
    Assert:  Projectile aimed at flying enemy only.

test_building_retargets_when_target_dies
    Arrange: BuildingBase. Two enemies in range. Target the first.
    Act:     Kill first enemy (queue_free). Simulate next frame.
    Assert:  _current_target switches to second enemy.

test_building_idles_with_no_enemies
    Arrange: BuildingBase. No enemies in scene.
    Act:     Simulate 100 frames.
    Assert:  No projectiles spawned. No errors.

test_upgraded_building_uses_upgraded_damage
    Arrange: Initialize with BuildingData (damage=20, upgraded_damage=35).
    Act:     upgrade(). get_effective_damage().
    Assert:  35.0.

test_upgraded_building_uses_upgraded_range
    Arrange: Initialize with BuildingData (range=15, upgraded_range=18).
    Act:     upgrade(). get_effective_range().
    Assert:  18.0.

test_shield_generator_does_not_fire_projectiles
    Arrange: Shield Generator (damage=0, fire_rate=0).
    Act:     Simulate frames with enemies in range.
    Assert:  No projectiles spawned.
    Note:    fire_rate=0 guard prevents division by zero.
```

---


# ═══════════════════════════════════════════════════════════════════
# SYSTEM 6 — PROJECTILE SYSTEM
# File: res://scenes/projectiles/projectile_base.gd (on projectile_base.tscn)
# ═══════════════════════════════════════════════════════════════════

## 6.1 PURPOSE

ProjectileBase is a physics-driven projectile that travels in a straight line from an
origin to a target position. On contact with an enemy (via Area3D collision), it applies
damage through the DamageCalculator matrix and the per-enemy damage_immunities check,
then self-destructs. On reaching its target position without collision, it self-destructs
(miss). A maximum lifetime prevents orphaned projectiles.

ProjectileBase handles TWO initialization paths:
1. `initialize_from_weapon()` — Florence's crossbow and rapid missile (WeaponData)
2. `initialize_from_building()` — Building turret shots (BuildingData-derived values)

Both paths produce the same runtime behavior; only the data source differs.

---

## 6.2 CLASS VARIABLES

```gdscript
class_name ProjectileBase
extends Area3D

# Configured at initialization
var _damage: float = 0.0
var _damage_type: Types.DamageType = Types.DamageType.PHYSICAL
var _speed: float = 20.0
var _direction: Vector3 = Vector3.ZERO
var _origin: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _max_travel_distance: float = 0.0
var _distance_traveled: float = 0.0
var _targets_air_only: bool = false

## Safety timeout — projectile self-destructs after this many seconds.
const MAX_LIFETIME: float = 5.0
var _lifetime: float = 0.0

## How close to target_position counts as "arrived" (miss).
const ARRIVAL_TOLERANCE: float = 1.0

# Children
@onready var _mesh: MeshInstance3D = $ProjectileMesh
@onready var _collision: CollisionShape3D = $ProjectileCollision
```

---

## 6.3 SIGNALS

ProjectileBase emits NO cross-system signals. Damage application is a direct method
call on the enemy's HealthComponent. The enemy itself emits `enemy_killed` via SignalBus
when its HP reaches 0.

SignalBus.projectile_fired is emitted by the CALLER (Tower or BuildingBase), not by
the projectile itself. This is because the caller knows the weapon_slot context.

---

## 6.4 METHOD SIGNATURES

```gdscript
# === PUBLIC ===

## Initialize for Florence's weapons. Sets damage, speed, direction from WeaponData.
func initialize_from_weapon(
    weapon_data: WeaponData,
    origin: Vector3,
    target_position: Vector3
) -> void

## Initialize for building turret shots. Sets damage, speed, direction from args.
func initialize_from_building(
    damage: float,
    damage_type: Types.DamageType,
    projectile_speed: float,
    origin: Vector3,
    target_position: Vector3,
    targets_air_only: bool
) -> void


# === PRIVATE ===

## Moves the projectile each physics frame. Checks arrival + lifetime.
func _physics_process(delta: float) -> void

## Handles collision with an enemy body.
func _on_body_entered(body: Node3D) -> void

## Applies damage to the enemy, respecting immunities and the damage matrix.
func _apply_damage_to_enemy(enemy: EnemyBase) -> void

## Configures collision layers/masks based on targeting mode.
func _configure_collision(targets_air_only: bool) -> void

## Visual setup based on projectile type (size, color).
func _configure_visuals(is_rapid_missile: bool) -> void
```

---

## 6.5 PSEUDOCODE

### initialize_from_weapon(weapon_data, origin, target_position)

```gdscript
func initialize_from_weapon(
    weapon_data: WeaponData,
    origin: Vector3,
    target_position: Vector3
) -> void:
    _damage = weapon_data.damage
    _damage_type = Types.DamageType.PHYSICAL  # Florence weapons are physical in MVP
    _speed = weapon_data.projectile_speed
    _origin = origin
    _target_position = target_position
    _direction = (target_position - origin).normalized()
    _max_travel_distance = origin.distance_to(target_position) + 5.0  # Overshoot buffer
    _distance_traveled = 0.0
    _lifetime = 0.0
    _targets_air_only = false

    global_position = origin

    # Florence cannot target flying — collision mask excludes flying layer
    _configure_collision(false)
    _configure_visuals(weapon_data.burst_count > 1)  # Rapid missile = burst > 1
```

### initialize_from_building(damage, damage_type, speed, origin, target, air_only)

```gdscript
func initialize_from_building(
    damage: float,
    damage_type: Types.DamageType,
    projectile_speed: float,
    origin: Vector3,
    target_position: Vector3,
    targets_air_only: bool
) -> void:
    _damage = damage
    _damage_type = damage_type
    _speed = projectile_speed
    _origin = origin
    _target_position = target_position
    _direction = (target_position - origin).normalized()
    _max_travel_distance = origin.distance_to(target_position) + 5.0
    _distance_traveled = 0.0
    _lifetime = 0.0
    _targets_air_only = targets_air_only

    global_position = origin

    _configure_collision(targets_air_only)
    _configure_visuals(false)
```

### _ready()

```gdscript
func _ready() -> void:
    # Connect Area3D body_entered signal for collision detection
    body_entered.connect(_on_body_entered)
```

### _physics_process(delta)

```gdscript
func _physics_process(delta: float) -> void:
    # Move along direction
    var movement: Vector3 = _direction * _speed * delta
    global_position += movement
    _distance_traveled += movement.length()
    _lifetime += delta

    # Check: passed target position (miss)
    var to_target: float = global_position.distance_to(_target_position)
    if to_target < ARRIVAL_TOLERANCE or _distance_traveled >= _max_travel_distance:
        queue_free()
        return

    # Check: lifetime exceeded (safety net)
    if _lifetime >= MAX_LIFETIME:
        queue_free()
        return
```

### _on_body_entered(body)

```gdscript
func _on_body_entered(body: Node3D) -> void:
    # Only process enemies (layer 2)
    var enemy: EnemyBase = body as EnemyBase
    if enemy == null:
        return

    if not enemy.health_component.is_alive():
        return  # Already dead — don't double-hit

    _apply_damage_to_enemy(enemy)
    queue_free()
```

### _apply_damage_to_enemy(enemy)

```gdscript
func _apply_damage_to_enemy(enemy: EnemyBase) -> void:
    var enemy_data: EnemyData = enemy.get_enemy_data()

    # Per-enemy immunity check (from Part 1 §3.8 decision)
    if _damage_type in enemy_data.damage_immunities:
        # Immune — projectile still consumed (it hit, just did no damage)
        return

    # Apply damage matrix
    var final_damage: float = DamageCalculator.calculate_damage(
        _damage, _damage_type, enemy_data.armor_type
    )

    enemy.health_component.take_damage(final_damage)
```

### _configure_collision(targets_air_only)

```gdscript
func _configure_collision(targets_air_only: bool) -> void:
    # Projectile is on layer 5 (Projectiles)
    collision_layer = 0
    set_collision_layer_value(5, true)

    # Mask: only detect enemies (layer 2)
    collision_mask = 0
    set_collision_mask_value(2, true)

    # Note: Filtering of flying vs ground enemies is handled by
    # the TARGETING system (_find_target), not by physics layers.
    # The projectile hits whatever it collides with on layer 2.
    # Anti-air buildings only TARGET flying enemies, so their projectiles
    # only ever fly toward flying enemies.
    # Florence's weapons only TARGET ground enemies (via InputManager
    # or targeting logic), so projectiles only fly toward ground enemies.
    _targets_air_only = targets_air_only
```

### _configure_visuals(is_rapid_missile)

```gdscript
func _configure_visuals(is_rapid_missile: bool) -> void:
    if _mesh == null:
        return

    var mat: StandardMaterial3D = StandardMaterial3D.new()

    if is_rapid_missile:
        # Small, fast, blue
        _mesh.scale = Vector3(0.15, 0.15, 0.15)
        mat.albedo_color = Color.CYAN
    else:
        # Larger, slower, brown (crossbow bolt) or damage-type colored
        _mesh.scale = Vector3(0.3, 0.3, 0.3)
        match _damage_type:
            Types.DamageType.PHYSICAL:
                mat.albedo_color = Color.SADDLE_BROWN
            Types.DamageType.FIRE:
                mat.albedo_color = Color.ORANGE_RED
            Types.DamageType.MAGICAL:
                mat.albedo_color = Color.MEDIUM_PURPLE
            Types.DamageType.POISON:
                mat.albedo_color = Color.GREEN_YELLOW
            _:
                mat.albedo_color = Color.WHITE

    _mesh.material_override = mat
```

---

## 6.6 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **Projectile misses (no collision)** | Arrival check: when distance to target < ARRIVAL_TOLERANCE or distance_traveled exceeds max, queue_free. |
| **Projectile hits dead enemy** | `is_alive()` check in `_on_body_entered`. Skips dead enemies. Projectile continues (does NOT queue_free on dead hit). |
| **Enemy dies between fire and hit** | `is_instance_valid` is implicitly handled by Godot's signal system — `body_entered` won't fire for freed nodes. If enemy freed same frame, collision callback may not fire. Projectile eventually self-destructs via arrival/lifetime. |
| **Projectile orphaned (never collides, never arrives)** | MAX_LIFETIME = 5.0 seconds. queue_free after timeout. |
| **Fire projectile hits fire-immune Goblin Firebug** | `damage_immunities` check in `_apply_damage_to_enemy()` returns early. Projectile still consumed (queue_free). Visual feedback: no damage number. |
| **Poison projectile hits undead** | DamageCalculator returns 0.0 (matrix multiplier). take_damage(0.0) → int(0.0) = 0 → HealthComponent early return. No damage applied. |
| **Zero-damage projectile** | _damage = 0.0 → calculate_damage returns 0.0 → take_damage(0.0) is no-op. Valid edge case (e.g., placeholder building). |
| **Projectile created with same origin and target** | Direction = (target - origin).normalized() → zero vector normalized → (0,0,0). Projectile won't move. Arrival tolerance check fires immediately → queue_free. |
| **Multiple enemies overlapping** | body_entered fires for the FIRST collision. Projectile queue_frees immediately. Second enemy is not hit. This is correct — projectiles don't pierce. |
| **Build mode time_scale 0.1** | _physics_process delta is already scaled. Projectile crawls at 10% speed. This is by design — player can observe projectile trajectories during build mode. |

---

## 6.7 GdUnit4 TEST SPECIFICATIONS

File: `res://tests/test_projectile_system.gd`

```gdscript
class_name TestProjectileSystem
extends GdUnitTestSuite
```

### Test: Initialization

```
test_initialize_from_weapon_sets_correct_damage
    Arrange: WeaponData with damage = 50.0.
    Act:     initialize_from_weapon(weapon_data, origin, target)
    Assert:  _damage == 50.0

test_initialize_from_weapon_sets_correct_speed
    Arrange: WeaponData with projectile_speed = 30.0.
    Act:     initialize_from_weapon(weapon_data, origin, target)
    Assert:  _speed == 30.0

test_initialize_from_weapon_computes_direction
    Arrange: origin = Vector3(0, 0, 0). target = Vector3(10, 0, 0).
    Act:     initialize_from_weapon(...)
    Assert:  _direction ≈ Vector3(1, 0, 0)

test_initialize_from_building_sets_damage_type
    Act:     initialize_from_building(20.0, FIRE, 15.0, origin, target, false)
    Assert:  _damage_type == Types.DamageType.FIRE

test_initialize_sets_position_to_origin
    Arrange: origin = Vector3(5, 2, 3).
    Act:     initialize_from_weapon(...)
    Assert:  global_position == Vector3(5, 2, 3)

test_initialize_from_building_air_only_flag
    Act:     initialize_from_building(10.0, PHYSICAL, 20.0, o, t, true)
    Assert:  _targets_air_only == true

test_rapid_missile_visual_is_small
    Arrange: WeaponData with burst_count = 10 (rapid missile).
    Act:     initialize_from_weapon(...)
    Assert:  _mesh.scale == Vector3(0.15, 0.15, 0.15)

test_crossbow_bolt_visual_is_large
    Arrange: WeaponData with burst_count = 1 (crossbow).
    Act:     initialize_from_weapon(...)
    Assert:  _mesh.scale == Vector3(0.3, 0.3, 0.3)
```

### Test: Movement

```
test_projectile_moves_along_direction
    Arrange: Initialize with origin (0,0,0), target (100,0,0), speed=10.
    Act:     Simulate 1 physics frame at delta=1.0.
    Assert:  global_position ≈ Vector3(10, 0, 0)

test_projectile_moves_correct_distance_per_frame
    Arrange: speed=20. delta=0.5.
    Act:     One physics frame.
    Assert:  Movement distance ≈ 10.0 units.

test_projectile_tracks_distance_traveled
    Arrange: speed=10.
    Act:     3 frames at delta=1.0.
    Assert:  _distance_traveled ≈ 30.0.

test_projectile_frees_on_arrival
    Arrange: origin (0,0,0), target (5,0,0), speed=10.
    Act:     Simulate frames until arrival.
    Assert:  Projectile calls queue_free (is_queued_for_deletion == true).

test_projectile_frees_on_max_lifetime
    Arrange: origin (0,0,0), target (10000,0,0), speed=1. MAX_LIFETIME=5.0.
    Act:     Simulate 6 seconds of frames.
    Assert:  Projectile freed after 5 seconds despite not arriving.

test_projectile_frees_on_max_distance_overshoot
    Arrange: origin (0,0,0), target (10,0,0). max_travel = 15.0. speed=20.
    Act:     Simulate frames.
    Assert:  Freed when distance_traveled >= 15.0.
```

### Test: Collision and Damage

```
test_projectile_deals_damage_on_enemy_collision
    Arrange: Projectile (damage=50, PHYSICAL). Enemy (Unarmored, HP=100).
    Act:     Simulate collision (body_entered with enemy).
    Assert:  Enemy HP = 50. (50 * 1.0 multiplier = 50 damage)

test_projectile_applies_damage_matrix
    Arrange: Projectile (damage=50, PHYSICAL). Enemy (Heavy Armor, HP=100).
    Act:     Collision.
    Assert:  Enemy HP = 75. (50 * 0.5 = 25 damage)

test_projectile_respects_immunity_override
    Arrange: Projectile (damage=50, FIRE). Enemy (Goblin Firebug,
             damage_immunities=[FIRE], HP=100).
    Act:     Collision.
    Assert:  Enemy HP = 100 (unchanged — immune).
             Projectile still freed.

test_projectile_poison_vs_undead_zero_damage
    Arrange: Projectile (damage=50, POISON). Enemy (Undead, HP=100).
    Act:     Collision.
    Assert:  Enemy HP = 100 (0.0 multiplier). Projectile freed.

test_projectile_freed_after_hit
    Arrange: Projectile + enemy in collision range.
    Act:     Collision fires.
    Assert:  Projectile is_queued_for_deletion.

test_projectile_skips_dead_enemy
    Arrange: Enemy with HP = 0 (already depleted).
    Act:     body_entered fires with dead enemy.
    Assert:  No damage applied. Projectile NOT freed (continues flying).

test_projectile_does_not_hit_same_enemy_twice
    Note:    queue_free prevents this — projectile is removed on first hit.
    Arrange: Projectile + enemy.
    Act:     First collision → damage + queue_free.
    Assert:  Only one damage event.

test_high_damage_projectile_kills_enemy
    Arrange: Projectile (damage=999, PHYSICAL). Enemy (Unarmored, HP=100).
    Act:     Collision.
    Assert:  Enemy HP = 0. health_depleted fired.

test_magical_vs_heavy_armor_double_damage
    Arrange: Projectile (damage=30, MAGICAL). Enemy (Heavy Armor, HP=100).
    Act:     Collision.
    Assert:  Enemy HP = 40. (30 * 2.0 = 60 damage)
```

### Test: Same-Origin-And-Target Edge Case

```
test_zero_distance_projectile_frees_immediately
    Arrange: origin = target = Vector3(5, 0, 5).
    Act:     Initialize + one physics frame.
    Assert:  Projectile freed (arrival tolerance met immediately).
```

### Test: Visual Configuration

```
test_fire_projectile_colored_orange_red
    Act:     initialize_from_building(10, FIRE, 15, o, t, false)
    Assert:  _mesh.material_override.albedo_color == Color.ORANGE_RED

test_magical_projectile_colored_purple
    Act:     initialize_from_building(10, MAGICAL, 15, o, t, false)
    Assert:  _mesh.material_override.albedo_color == Color.MEDIUM_PURPLE

test_poison_projectile_colored_green
    Act:     initialize_from_building(10, POISON, 15, o, t, false)
    Assert:  _mesh.material_override.albedo_color == Color.GREEN_YELLOW

test_physical_projectile_colored_brown
    Act:     initialize_from_building(10, PHYSICAL, 15, o, t, false)
    Assert:  _mesh.material_override.albedo_color == Color.SADDLE_BROWN
```

---

# END OF SYSTEMS.md — Part 2 of 3
