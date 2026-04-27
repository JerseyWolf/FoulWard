PROMPT:

# Session 3: Ring Rotation Pre-Battle UI

## Goal
Design the pre-battle ring rotation screen where players can rotate the HexGrid's three rings before combat begins. The method HexGrid.rotate_ring(delta_steps: int) exists but has no UI or caller. This session designs the GameState, UI, and integration.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `hex_grid.gd` — HexGrid script; slot layout, rotate_ring, ring constants (lines 1-120)
- `build_phase_manager.gd` — BuildPhaseManager autoload; build phase state management
- `game_manager.gd` — GameManager autoload; state transitions (lines 55-120)
- `types.gd` — Types.gd; GameState enum (lines 1-50)

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: the ring rotation pre-battle UI and GameState integration.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

REQUIREMENTS:
1. Add GameState.RING_ROTATE (integer value 12) to Types.gd — append at end. PASSIVE_SELECT = 11 is added by Session 2; coordinate accordingly. Add matching C# mirror entry.
2. Design the state transition: PASSIVE_SELECT -> RING_ROTATE -> COMBAT (or skip RING_ROTATE if no buildings are placed yet — first mission).
3. Design the UI: show a top-down hex grid visualization with three rings highlighted. Each ring has left/right rotation arrows. Show building icons in their current slots. Include a "Confirm" button to proceed to COMBAT.
4. The rotation is FREE (no resource cost). Each ring rotates independently.
5. Define the scene structure: res://ui/ring_rotation_screen.tscn + ring_rotation_screen.gd.
6. Integration: GameManager transitions to RING_ROTATE after passive selection (or after MISSION_BRIEFING if passives are not yet implemented). HexGrid.rotate_ring() is called when arrows are clicked.
7. BuildPhaseManager should NOT be active during RING_ROTATE — this is a separate phase.
8. SignalBus signals: ring_rotated(ring_index: int, delta_steps: int).
9. Save: ring positions persist automatically since buildings are already saved by slot index.

Note: Batch 5 extracted hex_grid.gd's _try_place_building into _validate_placement() + _instantiate_and_place() helper methods. The ring rotation system does not interact with placement — it only calls rotate_ring().

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 3: Ring Rotation

## Game States (§6)

Defined in res://scripts/types.gd as Types.GameState.

Transition graph: MAIN_MENU -> MISSION_BRIEFING -> COMBAT <-> BUILD_MODE -> WAVE_COUNTDOWN -> (COMBAT loop) -> MISSION_WON/MISSION_FAILED -> BETWEEN_MISSIONS -> MISSION_BRIEFING...

PLANNED states: RING_ROTATE (pre-battle ring rotation), PASSIVE_SELECT (Sybil passives).

### GameState Enum (current values + Session 2 addition)
| Name | Value |
|------|-------|
| MAIN_MENU | 0 |
| MISSION_BRIEFING | 1 |
| COMBAT | 2 |
| BUILD_MODE | 3 |
| WAVE_COUNTDOWN | 4 |
| BETWEEN_MISSIONS | 5 |
| MISSION_WON | 6 |
| MISSION_FAILED | 7 |
| GAME_WON | 8 |
| GAME_OVER | 9 |
| ENDLESS | 10 |
| PASSIVE_SELECT | 11 (added by Session 2) |

## Buildings — Ring Rotation (§8)

EXISTS: rotate_ring() in BuildPhaseManager / HexGrid.
PLANNED: Pre-battle ring rotation UI.

HexGrid has TOTAL_SLOTS = 24 across 3 concentric rings around the tower. rotate_ring(delta_steps: int) shifts buildings within a ring.

Note: Batch 5 extracted _try_place_building into _validate_placement() + _instantiate_and_place() helpers. Ring rotation does not interact with placement — only calls rotate_ring().

## Scene Tree — HexGrid and Managers (§25)

```
/root/Main (Node3D)
├── HexGrid (Node3D) [hex_grid.tscn]
│   └── HexSlot00..HexSlot23 (Area3D x24)
├── Managers (Node)
│   ├── WaveManager (Node)
│   ├── SpellManager (Node)
│   ├── ResearchManager (Node)
│   ├── ShopManager (Node)
│   ├── WeaponUpgradeManager (Node)
│   └── InputManager (Node)
└── UI (CanvasLayer)
    ├── UIManager (Control)
    ├── HUD [hud.tscn]
    ├── BuildMenu [build_menu.tscn]
    ├── BetweenMissionScreen [between_mission_screen.tscn]
    ├── MainMenu [main_menu.tscn]
    ├── MissionBriefing (Control)
    └── EndScreen (Control)
```

## Full Mission Cycle — Steps 1-3 (§27.1)

1. MAIN_MENU -> User clicks "Start"
2. GameManager.start_new_game() resets all managers, starts campaign
3. COMBAT (waves loop) -> wave_started, enemies spawn, wave_cleared, next wave...

The ring rotation phase inserts between PASSIVE_SELECT and COMBAT.

## BuildPhaseManager API (§3.10)

| Signature | Returns | Usage |
|-----------|---------|-------|
| set_build_phase_active(active: bool) -> void | void | Enables/disables build phase |
| is_build_phase_active() -> bool | bool | Current state |
| assert_build_phase(caller: String) -> bool | bool | Guard for build-only operations |

BuildPhaseManager should NOT be active during RING_ROTATE.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- _physics_process for game logic — _process for visual/UI only
- get_node_or_null() for runtime lookups with null guard
- Scene instantiation: call initialize() before or immediately after add_child()

FILES:

# Files to Upload for Session 3: Ring Rotation

Upload these files from the Foul Ward repository to Perplexity:

1. `scenes/hex_grid/hex_grid.gd` — HexGrid script; lines 1-120 covering slot layout, rotate_ring, ring constants (~120 lines)
2. `autoloads/build_phase_manager.gd` — BuildPhaseManager autoload; full file (~50 lines)
3. `autoloads/game_manager.gd` — GameManager autoload; lines 55-120 covering state transitions (~65 lines)
4. `scripts/types.gd` — Types.gd; lines 1-50 covering GameState enum (~50 lines)

Total estimated token load: ~285 lines across 4 files

scenes/hex_grid/hex_grid.gd:
## HexGrid — Manages 24 hex-shaped building slots; handles placement, selling, upgrading, and between-mission persistence.
# scenes/hex_grid/hex_grid.gd
# HexGrid – manages 24 hex-shaped building slots in three concentric rings.
# Handles placement, selling, upgrading, and between-mission persistence.
# All resource transactions flow through EconomyManager.
# All lock checks flow through ResearchManager (nullable for unit tests).
#
# Credit: Ring position formula (TAU / N * i + offset_rad) derived from:
#   Godot 4 official docs – built-in math constants (TAU = 2*PI, no import needed)
#   https://docs.godotengine.org/en/4.4/tutorials/physics/ray-casting.html
#   Adapted by the Foul Ward team.
#
# Credit: get_node_or_null pattern for optional scene references:
#   CONVENTIONS.md §6 – "Node reference patterns"
#   Foul Ward project document.

class_name HexGrid
extends Node3D

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const RING1_COUNT: int = 6
const RING1_RADIUS: float = 6.0
const RING2_COUNT: int = 12
const RING2_RADIUS: float = 12.0
const RING3_COUNT: int = 6
const RING3_RADIUS: float = 18.0
const TOTAL_SLOTS: int = 24

## Max horizontal distance from a click (XZ) to a slot center to count as "that slot".
const SLOT_PICK_MAX_DISTANCE: float = 4.0

const BuildingScene: PackedScene = preload("res://scenes/buildings/building_base.tscn")

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Must have exactly 36 entries, one per Types.BuildingType enum value.
@export var building_data_registry: Array[BuildingData] = []

## Which hex is targeted for the next build (driven by BuildMenu). -1 = none.
var _build_highlight_slot: int = -1

## Visual ring rotation (build phase only); does not change slot indices.
var rotation_offset_degrees: float = 0.0
const ROTATION_STEP_DEG: float = 15.0

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

## Each Dictionary: { index: int, world_pos: Vector3,
##                    building: BuildingBase|null, is_occupied: bool,
##                    soft_blocker_count: int }
var _slots: Array[Dictionary] = []

# ASSUMPTION: BuildingContainer at /root/Main/BuildingContainer per ARCHITECTURE.md §2.
# In GdUnit/headless tests there is no Main scene — create a child container so placement still works.
var _building_container: Node3D = null

# ASSUMPTION: ResearchManager at /root/Main/Managers/ResearchManager.
# If null (unit test context), all buildings are treated as unlocked.
var _research_manager = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group("hex_grid")
	_building_container = get_node_or_null("/root/Main/BuildingContainer") as Node3D
	if _building_container == null:
		var c: Node3D = Node3D.new()
		c.name = "BuildingContainer"
		# AP-06 exception: Node3D placeholder has no initialize() — name set above only
		add_child(c)
		_building_container = c
	print("[HexGrid] _ready: building_data_registry size=%d" % building_data_registry.size())
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.research_unlocked.connect(_on_research_unlocked)

	_research_manager = get_node_or_null("/root/Main/Managers/ResearchManager")
	print("[HexGrid] _ready: ResearchManager found=%s" % (str(_research_manager != null)))

	if building_data_registry.size() != 36:
		push_error("HexGrid: building_data_registry must have exactly 36 entries, got %d" % building_data_registry.size())
		return

	_initialize_slots()
	_set_slots_visible(false)
	print("[HexGrid] _ready: %d slots initialized" % _slots.size())

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Places a building of building_type on the given slot (charges gold + material).
## Returns true on success, false on any validation failure.
func place_building(slot_index: int, building_type: Types.BuildingType) -> bool:
	if not BuildPhaseManager.assert_build_phase("place_building"):
		return false
	return _try_place_building(slot_index, building_type, true)


## Shop voucher: places first available [param building_type] without spending resources.
## Uses lowest empty slot index. Returns false if no slot or validation fails.
# Intentional: shop voucher placement bypasses build-phase guard by design.
# See docs/FOUL_WARD_MASTER_DOC.md §ShopManager for voucher rules.
func place_building_shop_free(building_type: Types.BuildingType) -> bool:
	var empty: Array[int] = get_empty_slots()
	if empty.is_empty():
		return false
	empty.sort()
	return _try_place_building(empty[0], building_type, false)


## Returns true if any placed building has less than max HP (alive).
func has_any_damaged_building() -> bool:
	for slot: Dictionary in _slots:
		if not slot["is_occupied"]:
			continue
		var building: BuildingBase = slot["building"] as BuildingBase
		if not is_instance_valid(building):
			continue
		var hc: HealthComponent = building.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null:
			continue
		if not hc.is_alive():
			continue
		if hc.current_hp < hc.max_hp:
			return true
	return false


## Restores the first damaged building (lowest slot index) to full HP. Returns true if one was repaired.
func repair_first_damaged_building() -> bool:
	for i: int in range(TOTAL_SLOTS):
		var slot: Dictionary = _slots[i]
		if not slot["is_occupied"]:
			continue
		var building: BuildingBase = slot["building"] as BuildingBase
		if not is_instance_valid(building):
			continue
		var hc: HealthComponent = building.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null:
			continue
		if not hc.is_alive():
			continue
		if hc.current_hp >= hc.max_hp:
			continue
		hc.reset_to_max()
		print("[HexGrid] repair_first_damaged_building: slot %d repaired to full HP" % i)
		return true
	return false


func _try_place_building(
		slot_index: int,
		building_type: Types.BuildingType,
		charge_resources: bool
) -> bool:
	print("[HexGrid] place_building: slot=%d type=%d charge=%s  gold=%d mat=%d" % [
		slot_index, building_type, str(charge_resources),
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	if not _validate_placement(slot_index, building_type):
		return false
	return _instantiate_and_place(slot_index, building_type, charge_resources)


## Validates that slot_index is in range, unoccupied, has a BuildingData entry, and is unlocked.
## Does not check affordability (handled by _instantiate_and_place when charge_economy is true).
func _validate_placement(slot_index: int, building_type: Types.BuildingType) -> bool:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.place_building: invalid slot_index %d" % slot_index)
		print("[HexGrid] place_building FAILED: invalid slot %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]
	if slot["is_occupied"]:
		push_warning("HexGrid.place_building: slot %d already occupied" % slot_index)
		print("[HexGrid] place_building FAILED: slot %d already occupied" % slot_index)
		return false

	var building_data: BuildingData = get_building_data(building_type)
	if building_data == null:
		push_error("HexGrid.place_building: no BuildingData for type %d" % building_type)
		print("[HexGrid] place_building FAILED: no BuildingData for type %d" % building_type)
		return false

	if not is_building_available(building_type):
		print("[HexGrid] place_building FAILED: building type %d is locked" % building_type)
		return false

	return true


## Instantiates and places a building on slot_index.
## When charge_economy is true, checks affordability, registers the purchase, and records costs.
## When charge_economy is false (shop voucher), skips economy checks entirely.
## Assumes _validate_placement(slot_index, building_type) has already returned true.
func _instantiate_and_place(
		slot_index: int,
		building_type: Types.BuildingType,
		charge_economy: bool
) -> bool:
	var slot: Dictionary = _slots[slot_index]
	var building_data: BuildingData = get_building_data(building_type)

	if charge_economy:
		if not EconomyManager.can_afford_building(building_data):
			print("[HexGrid] place_building FAILED: cannot afford scaled cost  have=%dg %dm" % [
				EconomyManager.get_gold(), EconomyManager.get_building_material()
			])
			return false

		var receipt: Dictionary = EconomyManager.register_purchase(building_data)
		if receipt.is_empty():
			push_warning("HexGrid: register_purchase failed after can_afford_building returned true")
			return false

		var building: BuildingBase = BuildingScene.instantiate() as BuildingBase
		# AP-06 exception: add_child before initialize_with_economy — BuildingBase.initialize()
		# expects the node in the tree (see docstring); slot world_pos is applied immediately
		# after add_child, then init. (Swapping init before add_child broke nav/path tests.)
		_building_container.add_child(building)
		building.global_position = slot["world_pos"]
		building.add_to_group("buildings")
		building.initialize_with_economy(building_data, slot_index, _ring_index_for_slot(slot_index))
		building.paid_gold = int(receipt.get("paid_gold", 0))
		building.paid_material = int(receipt.get("paid_material", 0))
		building.total_invested_gold = building.paid_gold
		building.total_invested_material = building.paid_material
		_activate_building_obstacle(building)

		slot["building"] = building
		slot["is_occupied"] = true

		print("[HexGrid] place_building SUCCESS: slot=%d type=%d at pos=(%.1f,%.1f,%.1f)  remaining gold=%d mat=%d" % [
			slot_index, building_type,
			slot["world_pos"].x, slot["world_pos"].y, slot["world_pos"].z,
			EconomyManager.get_gold(), EconomyManager.get_building_material()
		])
		_register_combat_stats_building(building, building_data)
		SignalBus.building_placed.emit(slot_index, building_type)
		return true

	var building_free: BuildingBase = BuildingScene.instantiate() as BuildingBase
	# Same AP-06 exception as paid placement (add_child → pose → initialize_with_economy).
	_building_container.add_child(building_free)
	building_free.global_position = slot["world_pos"]
	building_free.add_to_group("buildings")
	building_free.initialize_with_economy(building_data, slot_index, _ring_index_for_slot(slot_index))
	building_free.record_initial_purchase(0, 0)
	_activate_building_obstacle(building_free)

	slot["building"] = building_free
	slot["is_occupied"] = true

	print("[HexGrid] place_building SUCCESS: slot=%d type=%d at pos=(%.1f,%.1f,%.1f)  remaining gold=%d mat=%d" % [
		slot_index, building_type,
		slot["world_pos"].x, slot["world_pos"].y, slot["world_pos"].z,
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	_register_combat_stats_building(building_free, building_data)
	SignalBus.building_placed.emit(slot_index, building_type)
	return true


func _register_combat_stats_building(building: BuildingBase, building_data: BuildingData) -> void:
	if building == null or building_data == null:
		return
	var bid: String = building_data.building_id.strip_edges()
	if bid.is_empty():
		bid = "building_type:%d" % int(building_data.building_type)
	var sc: String = building_data.size_class.strip_edges()
	if sc.is_empty():
		sc = "MEDIUM"
	CombatStatsTracker.register_building(
			building.placed_instance_id,
			bid,
			sc,
			building.ring_index,
			building.slot_id,
			building.paid_gold,
			0
	)


func rotate_ring(delta_steps: int) -> void:
	if not BuildPhaseManager.is_build_phase:
		push_warning("HexGrid.rotate_ring: attempted outside build phase")
		return
	rotation_offset_degrees += float(delta_steps) * ROTATION_STEP_DEG
	rotation_offset_degrees = fposmod(rotation_offset_degrees, 360.0)
	_rebuild_slot_positions()


func _rebuild_slot_positions() -> void:
	var new_positions: Array[Vector3] = []
	new_positions.append_array(_compute_ring_positions(RING1_COUNT, RING1_RADIUS, rotation_offset_degrees))
	new_positions.append_array(_compute_ring_positions(RING2_COUNT, RING2_RADIUS, rotation_offset_degrees))
	new_positions.append_array(_compute_ring_positions(RING3_COUNT, RING3_RADIUS, 30.0 + rotation_offset_degrees))
	if new_positions.size() != TOTAL_SLOTS:
		push_error("HexGrid._rebuild_slot_positions: position count mismatch")
		return
	for i: int in TOTAL_SLOTS:
		_slots[i]["world_pos"] = new_positions[i]
		var node: Area3D = get_node_or_null("HexSlot_%02d" % i) as Area3D
		if node != null:
			node.global_position = new_positions[i]


func _activate_building_obstacle(building: BuildingBase) -> void:
	# ASSUMPTION: BuildingBase self-configures collision + obstacle in _ready().
	if building == null:
		return


## Sells the building on the given slot. Full refund including upgrade costs if upgraded.
## Returns true on success, false if slot is empty or invalid.
func sell_building(slot_index: int) -> bool:
	if not BuildPhaseManager.assert_build_phase("sell_building"):
		return false
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.sell_building: invalid slot_index %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if not slot["is_occupied"]:
		push_warning("HexGrid.sell_building: slot %d is not occupied" % slot_index)
		return false

	var building: BuildingBase = slot["building"] as BuildingBase
	var building_data: BuildingData = building.get_building_data()
	var building_type: Types.BuildingType = building_data.building_type

	var refund: Dictionary = building.get_sell_refund()
	var rg: int = int(refund.get("gold", 0))
	var rmat: int = int(refund.get("material", 0))
	if rg > 0:
		EconomyManager.add_gold(rg)
	if rmat > 0:
		EconomyManager.add_building_material(rmat)

	AllyManager.despawn_squad(building.placed_instance_id)

	building.remove_from_group("buildings")
	building.queue_free()

	slot["building"] = null
	slot["is_occupied"] = false

	SignalBus.building_sold.emit(slot_index, building_type)
	return true


## Upgrades the building on the given slot from Basic to Upgraded tier.
## Returns true on success, false on any validation failure.
func upgrade_building(slot_index: int) -> bool:
	if not BuildPhaseManager.assert_build_phase("upgrade_building"):
		return false
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.upgrade_building: invalid slot_index %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if not slot["is_occupied"]:
		push_warning("HexGrid.upgrade_building: slot %d not occupied" % slot_index)
		return false

	var building: BuildingBase = slot["building"] as BuildingBase

	if not building.can_upgrade():
		push_warning("HexGrid.upgrade_building: building on slot %d cannot upgrade" % slot_index)
		return false

	var building_data: BuildingData = building.get_building_data()
	var cost: Dictionary = building.get_upgrade_cost()
	var ug: int = int(cost.get("gold", 0))
	var um: int = int(cost.get("material", 0))

	if not EconomyManager.can_afford(ug, um):
		return false

	var gold_spent: bool = EconomyManager.spend_gold(ug)
	if not gold_spent:
		push_warning("HexGrid: upgrade spend_gold failed after can_afford returned true")
		return false
	var mat_spent: bool = EconomyManager.spend_building_material(um)
	if not mat_spent:
		push_warning("HexGrid: upgrade spend_building_material failed after can_afford returned true")
		EconomyManager.add_gold(ug)
		return false

	var next_chain: BuildingData = building_data.upgrade_next
	if next_chain != null:
		building.apply_upgrade(next_chain)
	else:
		building.record_upgrade_cost(ug, um)
		building.upgrade()

	var upgraded_type: Types.BuildingType = building.get_building_data().building_type
	SignalBus.building_upgraded.emit(slot_index, upgraded_type)
	return true


## Returns a shallow copy of the slot data Dictionary for the given index.
func get_slot_data(slot_index: int) -> Dictionary:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.get_slot_data: invalid slot_index %d" % slot_index)
		return {}
	return _slots[slot_index].duplicate()


## Returns an array of slot indices that currently have buildings.
func get_all_occupied_slots() -> Array[int]:
	var result: Array[int] = []
	for slot: Dictionary in _slots:
		if slot["is_occupied"]:
			result.append(slot["index"])
	return result


## Returns an array of slot indices that are currently empty.
func get_empty_slots() -> Array[int]:
	var result: Array[int] = []
	for slot: Dictionary in _slots:
		if not slot["is_occupied"]:
			result.append(slot["index"])
	return result

## Returns true if at least one slot is currently empty.
func has_empty_slot() -> bool:
	for slot: Dictionary in _slots:
		if not slot["is_occupied"]:
			return true
	return false


## Frees all buildings and resets all slots. Called on new game only.
func clear_all_buildings() -> void:
	for slot: Dictionary in _slots:
		if slot["is_occupied"]:
			var building: BuildingBase = slot["building"] as BuildingBase
			if is_instance_valid(building):
				building.remove_from_group("buildings")
				building.queue_free()
			slot["building"] = null
			slot["is_occupied"] = false


## Returns the BuildingData resource for the given BuildingType, or null if not found.
func get_building_data(building_type: Types.BuildingType) -> BuildingData:
	for data: BuildingData in building_data_registry:
		if data.building_type == building_type:
			return data
	return null


## Returns whether the given building type is currently available to place.
func is_building_available(building_type: Types.BuildingType) -> bool:
	var building_data: BuildingData = get_building_data(building_type)
	if building_data == null:
		return false
	if not building_data.is_locked:
		return true
	# ASSUMPTION: if ResearchManager is null (unit test), treat all as unlocked.
	if _research_manager == null:
		return true
	return _research_manager.is_unlocked(building_data.unlock_research_id)


## Returns the world-space Vector3 position of the given slot.
func get_slot_position(slot_index: int) -> Vector3:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.get_slot_position: invalid slot_index %d" % slot_index)
		return Vector3.ZERO
	return _slots[slot_index]["world_pos"]


## Returns the slot index whose center is nearest to [param world_pos] on XZ, or -1 if too far.
## Used when UI blocks Area3D picking — InputManager resolves the slot from a ground click.
func get_nearest_slot_index(world_pos: Vector3) -> int:
	var best_i: int = -1
	var best_d2: float = INF
	for i: int in range(TOTAL_SLOTS):
		var wp: Vector3 = _slots[i]["world_pos"]
		var dx: float = wp.x - world_pos.x
		var dz: float = wp.z - world_pos.z
		var d2: float = dx * dx + dz * dz
		if d2 < best_d2:
			best_d2 = d2
			best_i = i
	var max_d: float = SLOT_PICK_MAX_DISTANCE
	if best_d2 <= max_d * max_d:
		return best_i
	return -1


## Maps a world position to a logical hex key; [member Vector2i.x] is the slot index (0..23), [member Vector2i.y] is unused (0).
func world_to_hex(world_pos: Vector3) -> Vector2i:
	var best_i: int = -1
	var best_d: float = INF
	for i: int in range(TOTAL_SLOTS):
		var wp: Vector3 = _slots[i]["world_pos"] as Vector3
		var d: float = Vector2(wp.x, wp.z).distance_to(Vector2(world_pos.x, world_pos.z))
		if d < best_d:
			best_d = d
			best_i = i
	if best_i < 0:
		return Vector2i(-1, -1)
	return Vector2i(best_i, 0)


## Pathfinding hint: allies patrolling a slot count as soft obstacles (enemies may path around later).
func register_soft_blocker(hex_coord: Vector2i) -> void:
	var idx: int = hex_coord.x
	if not _is_valid_index(idx):
		return
	var slot: Dictionary = _slots[idx]
	var n: int = int(slot.get("soft_blocker_count", 0))
	slot["soft_blocker_count"] = n + 1


func unregister_soft_blocker(hex_coord: Vector2i) -> void:
	var idx: int = hex_coord.x
	if not _is_valid_index(idx):
		return
	var slot: Dictionary = _slots[idx]
	var n: int = int(slot.get("soft_blocker_count", 0))
	slot["soft_blocker_count"] = maxi(0, n - 1)


func has_soft_blocker(hex_coord: Vector2i) -> bool:
	var idx: int = hex_coord.x
	if not _is_valid_index(idx):
		return false
	return int(_slots[idx].get("soft_blocker_count", 0)) > 0


## Updates the highlighted ring tile for build mode (each slot has its own material instance).
func set_build_slot_highlight(slot_index: int) -> void:
	if not _is_valid_index(slot_index):
		return
	_build_highlight_slot = slot_index
	_apply_build_slot_highlights()


# ---------------------------------------------------------------------------
# Private – slot initialisation
# ---------------------------------------------------------------------------

func _initialize_slots() -> void:
	_slots.clear()

	var positions: Array[Vector3] = []
	positions.append_array(_compute_ring_positions(RING1_COUNT, RING1_RADIUS, 0.0))
	positions.append_array(_compute_ring_positions(RING2_COUNT, RING2_RADIUS, 0.0))
	# Ring 3 is offset 30° so its slots sit between ring-2 slots visually.
	positions.append_array(_compute_ring_positions(RING3_COUNT, RING3_RADIUS, 30.0))

	if positions.size() != TOTAL_SLOTS:
		push_error("HexGrid: expected %d positions, got %d" % [TOTAL_SLOTS, positions.size()])
		return

	for i: int in range(TOTAL_SLOTS):
		var slot_data: Dictionary = {
			"index": i,
			"world_pos": positions[i],
			"building": null,
			"is_occupied": false,
			"soft_blocker_count": 0,
		}
		_slots.append(slot_data)

		# Name-based lookup is more robust than get_child(i) — immune to editor
		# child-order shuffling. Source: CONVENTIONS.md §6.2.
		var slot_node: Area3D = get_node_or_null("HexSlot_%02d" % i) as Area3D
		if slot_node != null:
			slot_node.global_position = positions[i]
			slot_node.collision_layer = 0
			slot_node.set_collision_layer_value(7, true)
			slot_node.collision_mask = 0
			# input_ray_pickable must be true for Area3D.input_event signal to fire.
			# Source: Godot Forum – "Input Event Help" (2024-08-30)
			#   https://forum.godotengine.org/t/input-event-help/80348
			slot_node.input_ray_pickable = true
			slot_node.monitoring = false
			slot_node.monitorable = false
			slot_node.input_event.connect(_on_hex_slot_input.bind(i))
			# Scene file shares one material across all SlotMesh — duplicate per slot for highlights.
			var mesh_inst: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
			if mesh_inst != null:
				var shared: Material = mesh_inst.material_override
				if shared == null and mesh_inst.mesh != null and mesh_inst.mesh.get_surface_count() > 0:
					shared = mesh_inst.get_surface_override_material(0)
				if shared != null:
					mesh_inst.material_override = shared.duplicate() as Material


## Computes world positions for a ring of count slots at radius, offset by angle_offset_degrees.
## All positions are at Y = 0 (ground plane).
func _compute_ring_positions(count: int, radius: float, angle_offset_degrees: float) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var angle_step: float = TAU / float(count)
	var offset_rad: float = deg_to_rad(angle_offset_degrees)
	for i: int in range(count):
		var angle: float = float(i) * angle_step + offset_rad
		positions.append(Vector3(
			radius * cos(angle),
			0.0,
			radius * sin(angle)
		))
	return positions


func _set_slots_visible(slots_visible: bool) -> void:
	for i: int in range(get_child_count()):
		var slot_node: Area3D = get_child(i) as Area3D
		if slot_node == null:
			continue
		var mesh: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
		if mesh != null:
			mesh.visible = slots_visible
	if slots_visible:
		_apply_build_slot_highlights()


func _apply_build_slot_highlights() -> void:
	for i: int in range(TOTAL_SLOTS):
		var slot_node: Area3D = get_node_or_null("HexSlot_%02d" % i) as Area3D
		if slot_node == null:
			continue
		var mesh: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
		if mesh == null:
			continue
		var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mesh.material_override = mat
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var is_selected: bool = i == _build_highlight_slot
		if is_selected:
			mat.albedo_color = Color(1.0, 0.92, 0.15, 0.92)
			mat.emission_enabled = true
			mat.emission = Color(0.4, 0.35, 0.05)
		else:
			mat.albedo_color = Color(0.12, 0.55, 1.0, 0.82)
			mat.emission_enabled = true
			mat.emission = Color(0.08, 0.2, 0.35)

# ---------------------------------------------------------------------------
# Private – validation
# ---------------------------------------------------------------------------

func _is_valid_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < TOTAL_SLOTS


## Ring index 0 = inner (6 slots), 1 = middle (12), 2 = outer (6).
func _ring_index_for_slot(slot_index: int) -> int:
	if slot_index < RING1_COUNT:
		return 0
	if slot_index < RING1_COUNT + RING2_COUNT:
		return 1
	return 2

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_build_mode_entered() -> void:
	print("[HexGrid] build_mode_entered: showing %d slot tiles" % TOTAL_SLOTS)
	_build_highlight_slot = 0
	_set_slots_visible(true)


func _on_build_mode_exited() -> void:
	print("[HexGrid] build_mode_exited: hiding slot tiles")
	_build_highlight_slot = -1
	_set_slots_visible(false)


func _on_research_unlocked(_node_id: String) -> void:
	# No cache to invalidate – is_building_available() checks live state each call.
	# Hook reserved for future UI refresh (e.g., glow newly unlocked slots).
	pass


## Bound slot index is last: Godot passes signal args first, then Callable.bind() args.
func _on_hex_slot_input(
		_camera: Node,
		event: InputEvent,
		_event_position: Vector3,
		_normal: Vector3,
		_shape_idx: int,
		slot_index: int
) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var state: Types.GameState = GameManager.get_game_state()
	print("[HexGrid] hex slot %d clicked  game_state=%s" % [slot_index, Types.GameState.keys()[state]])
	if state != Types.GameState.BUILD_MODE:
		return
	# InputManager now owns BUILD_MODE slot click routing (place vs sell menu mode).
	# Keep this callback for highlight feedback only.
	set_build_slot_highlight(slot_index)

autoloads/build_phase_manager.gd:
## build_phase_manager.gd
## Headless-safe guard for hex placement during the build phase (Prompt 49).
## Prompt 11: signals for HUD build menu / research panel visibility.

extends Node

## When false, [method HexGrid.place_building] / sell / upgrade return early with a warning.
## GameManager sets this false when combat starts and true in [method GameManager.enter_build_mode].
## Default true matches headless tests that place buildings without toggling mission state.
var is_build_phase: bool = true


func assert_build_phase(context: String) -> bool:
	if is_build_phase:
		return true
	push_warning("BuildPhaseManager: blocked %s — not in build phase" % context)
	return false


func confirm_build_phase() -> void:
	# Reserved for HUD "Begin wave" wiring; gameplay may toggle [member is_build_phase] via GameManager.
	pass


## Toggles [member is_build_phase] and emits the matching signal (no-op if unchanged).
func set_build_phase_active(active: bool) -> void:
	if is_build_phase == active:
		return
	is_build_phase = active
	if active:
		SignalBus.build_phase_started.emit()
	else:
		SignalBus.combat_phase_started.emit()

autoloads/game_manager.gd:
## game_manager.gd
## State machine for overall game flow: missions, waves, and build mode in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.
##
## Territory + day summary:
## - CampaignConfig on CampaignManager defines DayConfig entries (mission_index, territory_id, waves, etc.).
## - CampaignManager tracks current_day; GameManager maps day to current_mission via DayConfig.mission_index.
## - TerritoryMapData lists all TerritoryData; GameManager mutates ownership flags on mission win/loss
##   and aggregates end-of-mission gold bonuses for EconomyManager.
## - MVP: player cannot choose territories; CampaignConfig fixes day→territory mapping.
##   POST-MVP: multi-front choices, boss advance after final day, factions, and research/enchant/upgrade
##   modifiers from TerritoryData hook into this layer.

extends Node

const TOTAL_MISSIONS: int = 5
# Temporary dev/testing cap so we can reach "mission won" quickly.
const WAVES_PER_MISSION: int = 5

const FlorenceDataType = preload("res://scripts/florence_data.gd")

## Optional reference path for the main 50-day campaign asset (documentation / tools).
## ASSUMPTION: Runtime loads territory map from CampaignManager.campaign_config.territory_map_resource_path.
const MAIN_CAMPAIGN_CONFIG_PATH: String = "res://resources/campaign_main_50days.tres"

var _active_allies: Array = []
var _ally_base_scene: PackedScene = preload("res://scenes/allies/ally_base.tscn")

var current_mission: int = 1
var current_wave: int = 0
## ASSUMPTION: meta campaign day index, 1-based (independent from CampaignManager.current_day).
var current_day: int = 1
var game_state: Types.GameState = Types.GameState.MAIN_MENU

## SOURCE: Roguelike meta-state Resource pattern (data-only model state).
var florence_data: FlorenceDataType = null

const INVALID_DAY_ADVANCE_REASON: int = -1
var _pending_day_advance_reason: int = INVALID_DAY_ADVANCE_REASON

## Loaded from the active campaign's territory_map_resource_path when set; otherwise null.
var territory_map: TerritoryMapData = null

# --- Final boss / post–Day-50 loop (Prompt 10) --------------------------------
var final_boss_id: String = ""
var final_boss_day_index: int = 50
var final_boss_active: bool = false
var final_boss_defeated: bool = false
var current_boss_threat_territory_id: String = ""
## ASSUMPTION: populated from TerritoryMapData or tests; used for random boss strikes.
var held_territory_ids: Array[String] = []
## Runtime-only day config when current_day exceeds CampaignConfig.day_configs (boss repeat days).
var _synthetic_boss_attack_day: DayConfig = null

func _ready() -> void:
	print("[GameManager] _ready: initial state=%s" % Types.GameState.keys()[game_state])
	if not SignalBus.all_waves_cleared.is_connected(_on_all_waves_cleared):
		SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
	if not SignalBus.tower_destroyed.is_connected(_on_tower_destroyed):
		SignalBus.tower_destroyed.connect(_on_tower_destroyed)
	# Autoload order: CampaignManager before GameManager — connect second so day increments first on mission_won.
	_connect_mission_won_transition_to_hub()
	var shop: Node = get_node_or_null("/root/Main/Managers/ShopManager")
	var tower: Node = get_node_or_null("/root/Main/Tower")
	if shop != null and tower != null and shop.has_method("initialize_tower"):
		shop.initialize_tower(tower)
	print("[GameManager] _ready: ShopManager wired to Tower")
	reload_territory_map_from_active_campaign()
	if not SignalBus.boss_killed.is_connected(_on_boss_killed):
		SignalBus.boss_killed.connect(_on_boss_killed)
	_sync_held_territories_from_map()
	if SaveManager.has_method("save_current_state"):
		var save_cb: Callable = func(_mission_number: int) -> void:
			SaveManager.save_current_state()
		if not SignalBus.mission_won.is_connected(save_cb):
			SignalBus.mission_won.connect(save_cb)
		if not SignalBus.mission_failed.is_connected(save_cb):
			SignalBus.mission_failed.connect(save_cb)


func _connect_mission_won_transition_to_hub() -> void:
	if SignalBus.mission_won.is_connected(_on_mission_won_transition_to_hub):
		return
	SignalBus.mission_won.connect(_on_mission_won_transition_to_hub)


## Runs after CampaignManager._on_mission_won (autoload order: CampaignManager before GameManager). Also used when tests emit mission_won without waves.
func _on_mission_won_transition_to_hub(mission_number: int) -> void:
	if CampaignManager.is_endless_mode:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)
		return
	var campaign_len: int = CampaignManager.get_campaign_length()
	var completed_day_index: int = mission_number
	var is_final_day: bool = campaign_len > 0 and completed_day_index == campaign_len
	var should_game_won: bool = false

	if campaign_len == 0 and mission_number >= TOTAL_MISSIONS:
		should_game_won = true
	elif is_final_day or final_boss_defeated:
		should_game_won = true

	if should_game_won:
		# ASSUMPTION: run_count increments only on full campaign completion for now.
		if florence_data != null:
			florence_data.run_count += 1
			SignalBus.florence_state_changed.emit()
		_transition_to(Types.GameState.GAME_WON)
	else:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)

# ── Public API ─────────────────────────────────────────────────────────────────

## Resets all game state and starts a fresh campaign from day one.
func start_new_game() -> void:
	print("[GameManager] start_new_game: mission=1  gold=%d mat=%d" % [
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	if CampaignManager.is_endless_mode:
		game_state = Types.GameState.ENDLESS
	_cleanup_allies()
	_reset_final_boss_campaign_state()
	current_mission = 1
	current_wave = 0
	EconomyManager.reset_to_defaults()
	EnchantmentManager.reset_to_defaults()
	# Ensure research unlock state is reset for a new run.
	# In dev mode, ResearchManager can choose to unlock all nodes to make
	# content reachable for testing (e.g., tower availability).
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm != null:
		rm.reset_to_defaults()
	var weapon_upgrade_manager: Node = get_node_or_null("/root/Main/Managers/WeaponUpgradeManager")
	if weapon_upgrade_manager != null:
		weapon_upgrade_manager.reset_to_defaults()

	# Florence meta-state bootstrap.
	# ASSUMPTION: New game starts meta day index at 1.
	current_day = 1
	_pending_day_advance_reason = INVALID_DAY_ADVANCE_REASON
	if florence_data == null:
		florence_data = FlorenceDataType.new()
	florence_data.reset_for_new_run()
	florence_data.update_day_threshold_flags(current_day)
	SignalBus.florence_state_changed.emit()
	# DEVIATION: CampaignManager owns day/campaign state and mission kickoff.
	CampaignManager.start_new_campaign()
	reload_territory_map_from_active_campaign()
	_sync_held_territories_from_map()

## Delegates to CampaignManager to begin the next day in the campaign.
func start_next_mission() -> void:
	# DEVIATION: next day is now owned by CampaignManager.
	# BetweenMissionScreen routes directly through CampaignManager, this remains for compatibility.
	CampaignManager.start_next_day()

## Begins the countdown timer before the first wave spawns.
func start_wave_countdown() -> void:
	if game_state != Types.GameState.MISSION_BRIEFING:
		push_warning("start_wave_countdown called from invalid state: %s" % Types.GameState.keys()[game_state])
		return
	_transition_to(Types.GameState.COMBAT)
	BuildPhaseManager.set_build_phase_active(false)
	SignalBus.mission_started.emit(current_mission)
	_spawn_allies_for_current_mission()
	_apply_shop_mission_start_consumables()
	# Single source of truth for countdown duration: WaveManager emits wave_countdown_started.
	_begin_mission_wave_sequence()

## Transitions the game state to BUILD_MODE, pausing enemy movement.
func enter_build_mode() -> void:
	print("[GameManager] enter_build_mode: from=%s" % Types.GameState.keys()[game_state])
	if game_state != Types.GameState.COMBAT and game_state != Types.GameState.WAVE_COUNTDOWN:
		push_warning("enter_build_mode called from invalid state: %s" % Types.GameState.keys()[game_state])
		return
	Engine.time_scale = 0.1
	var old: Types.GameState = game_state
	game_state = Types.GameState.BUILD_MODE
	BuildPhaseManager.set_build_phase_active(true)
	SignalBus.build_mode_entered.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.BUILD_MODE)

## Transitions the game state back to COMBAT from BUILD_MODE.
func exit_build_mode() -> void:
	print("[GameManager] exit_build_mode")
	Engine.time_scale = 1.0
	var old: Types.GameState = game_state
	game_state = Types.GameState.COMBAT
	BuildPhaseManager.set_build_phase_active(false)
	SignalBus.build_mode_exited.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.COMBAT)

## Returns the current GameState enum value.
func get_game_state() -> Types.GameState:
	return game_state

## Returns the current mission number (1-indexed).
func get_current_mission() -> int:
	return current_mission

## Returns the current wave index within the active mission.
func get_current_wave() -> int:
	return current_wave

## Returns the FlorenceData resource tracking protagonist meta-state.
func get_florence_data() -> FlorenceDataType:
	return florence_data

## Increments Florence's day counter with the given advance reason.
func advance_day(reason: Types.DayAdvanceReason) -> void:
	# SOURCE: Day/week advancement priority pattern using Types as central registry.
	var reason_priority: int = Types.get_day_advance_priority(reason)

	# ASSUMPTION: The “pending reasons” window is typically a mission resolution
	# (from win/fail events through state transitions).
	if _pending_day_advance_reason == INVALID_DAY_ADVANCE_REASON:
		_pending_day_advance_reason = int(reason)
		return

	var pending_priority: int = _get_day_advance_priority_from_int(_pending_day_advance_reason)
	if reason_priority > pending_priority:
		_pending_day_advance_reason = int(reason)


func _get_day_advance_priority_from_int(reason_id: int) -> int:
	# Godot does not allow casting enums via `Types.DayAdvanceReason(reason_id)` syntax.
	# We map the stored int back to the enum values via match.
	match reason_id:
		int(Types.DayAdvanceReason.MISSION_COMPLETED):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.MISSION_COMPLETED)
		int(Types.DayAdvanceReason.ACHIEVEMENT_EARNED):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.ACHIEVEMENT_EARNED)
		int(Types.DayAdvanceReason.MAJOR_STORY_EVENT):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.MAJOR_STORY_EVENT)
		_:
			return 0


func _apply_pending_day_advance_if_any() -> void:
	if _pending_day_advance_reason == INVALID_DAY_ADVANCE_REASON:
		return

	current_day += 1
	if florence_data != null:
		florence_data.total_days_played += 1
		florence_data.update_day_threshold_flags(current_day)

	SignalBus.florence_state_changed.emit()
	_pending_day_advance_reason = INVALID_DAY_ADVANCE_REASON

## Linear day index within the active campaign (1-based). Delegates to CampaignManager.
func get_current_day_index() -> int:
	return CampaignManager.get_current_day()


## Alias for tests / Prompt 10 (syncs calendar via CampaignManager.force_set_day).
var current_day_index: int:
	get:
		return CampaignManager.get_current_day()
	set(value):
		CampaignManager.force_set_day(value)


## Campaign timeline resource (same as CampaignManager.campaign_config).
var campaign_config: CampaignConfig:
	get:
		return CampaignManager.campaign_config
	set(value):
		CampaignManager.set_active_campaign_config_for_test(value)


## Returns the DayConfig for the given day index from the active campaign.
func get_day_config_for_index(day_index: int) -> DayConfig:
	if CampaignManager.is_endless_mode:
		return _create_synthetic_endless_day_config(day_index)
	var cfg: CampaignConfig = CampaignManager.campaign_config
	if cfg == null:
		return null
	for d: DayConfig in cfg.day_configs:
		if d != null and d.day_index == day_index:
			return d
	if day_index >= 1 and day_index <= cfg.day_configs.size():
		return cfg.day_configs[day_index - 1]
	if _synthetic_boss_attack_day != null and _synthetic_boss_attack_day.day_index == day_index:
		return _synthetic_boss_attack_day
	return null


func _create_synthetic_endless_day_config(day_index: int) -> DayConfig:
	var d: DayConfig = DayConfig.new()
	d.day_index = day_index
	d.mission_index = mini(day_index, TOTAL_MISSIONS)
	d.display_name = "Endless"
	d.faction_id = "DEFAULT_MIXED"
	d.base_wave_count = WAVES_PER_MISSION
	d.enemy_hp_multiplier = WaveManager.get_effective_enemy_hp_multiplier_for_day(day_index)
	d.enemy_damage_multiplier = d.enemy_hp_multiplier
	d.gold_reward_multiplier = 1.0
	d.spawn_count_multiplier = WaveManager.get_effective_spawn_count_multiplier_for_day(day_index)
	return d


## Returns a synthetic DayConfig for a boss-attack day.
func get_synthetic_boss_day_config() -> DayConfig:
	return _synthetic_boss_attack_day


## Advances calendar by one day; after a failed final boss, assigns a random threatened territory.
func advance_to_next_day() -> void:
	CampaignManager.force_set_day(CampaignManager.get_current_day() + 1)
	var day: DayConfig = get_day_config_for_index(CampaignManager.get_current_day())
	if final_boss_active and not final_boss_defeated:
		if day == null:
			day = _ensure_synthetic_boss_attack_day_config()
		_assign_boss_attack_to_day(day)


## Returns the DayConfig for the currently active day.
func get_current_day_config() -> DayConfig:
	return CampaignManager.get_current_day_config()


## Returns the territory_id for the current day's mission.
func get_current_day_territory_id() -> String:
	var day_config: DayConfig = get_current_day_config()
	if day_config == null:
		return ""
	return day_config.territory_id


## Returns the TerritoryData resource for the given territory_id.
func get_territory_data(territory_id: String) -> TerritoryData:
	if territory_map == null:
		return null
	return territory_map.get_territory_by_id(territory_id)


## Returns the TerritoryData for the territory of the current day.
func get_current_day_territory() -> TerritoryData:
	var id: String = get_current_day_territory_id()
	if id == "":
		return null
	return get_territory_data(id)


## Returns all TerritoryData entries in this map.
func get_all_territories() -> Array[TerritoryData]:
	if territory_map == null:
		return []
	return territory_map.get_all_territories()


## Reloads TerritoryMapData from CampaignManager.campaign_config.territory_map_resource_path.
func reload_territory_map_from_active_campaign() -> void:
	territory_map = null
	var cfg: CampaignConfig = CampaignManager.campaign_config
	if cfg == null:
		return
	if cfg.territory_map_resource_path == "":
		return
	var res: Resource = load(cfg.territory_map_resource_path)
	if res == null:
		push_error(
			"GameManager: Failed to load TerritoryMapData from %s"
			% cfg.territory_map_resource_path
		)
		return
	territory_map = res as TerritoryMapData
	if territory_map == null:
		push_error(
			"GameManager: Resource at %s is not a TerritoryMapData"
			% cfg.territory_map_resource_path
		)
		return
	territory_map.invalidate_cache()
	SignalBus.world_map_updated.emit()
	_sync_held_territories_from_map()


## Updates territory ownership and threat flags based on the day win/loss result.
func apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void:
	if territory_map == null or day_config == null:
		return
	if day_config.territory_id == "":
		return

	var territory: TerritoryData = territory_map.get_territory_by_id(day_config.territory_id)
	if territory == null:
		push_error(
			"GameManager: DayConfig references unknown territory_id '%s'."
			% day_config.territory_id
		)
		return

	# Prompt 10 MVP: failing a final boss encounter does not permanently conquer territory.
	if (
			not was_won
			and day_config.boss_id != ""
			and (day_config.is_final_boss or day_config.is_boss_attack_day)
	):
		return

	if was_won:
		territory.is_controlled_by_player = true
		# TUNING: MVP does not change is_permanently_lost on win; future campaigns
		# may allow recovery clearing this flag.
	else:
		territory.is_controlled_by_player = false
		territory.is_permanently_lost = true

	SignalBus.territory_state_changed.emit(territory.territory_id)
	SignalBus.world_map_updated.emit()


## Aggregates end-of-mission gold modifiers from all controlled territories.
## Keys: flat_gold_end_of_day (int), percent_gold_end_of_day (float additive fractions).
func get_current_territory_gold_modifiers() -> Dictionary:
	var result: Dictionary = {
		"flat_gold_end_of_day": 0,
		"percent_gold_end_of_day": 0.0,
	}
	if territory_map == null:
		return result

	for t: TerritoryData in territory_map.get_all_territories():
		if t == null:
			continue
		if not t.is_active_for_bonuses():
			continue
		result["flat_gold_end_of_day"] += t.get_effective_end_of_day_gold_flat()
		result["percent_gold_end_of_day"] += t.get_effective_end_of_day_gold_percent()
	return result


## Sum of bonus_flat_gold_per_kill from all territories that pass is_active_for_bonuses().
func get_aggregate_flat_gold_per_kill() -> int:
	var s: int = 0
	if territory_map == null:
		return 0
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		s += t.bonus_flat_gold_per_kill
	return s


## Product of bonus_research_cost_multiplier across active territories (empty map = 1.0).
func get_aggregate_research_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_research_cost_multiplier > 0.0:
			p *= t.bonus_research_cost_multiplier
	return p


## Returns the aggregated enchanting cost multiplier from all held territories.
func get_aggregate_enchanting_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_enchanting_cost_multiplier > 0.0:
			p *= t.bonus_enchanting_cost_multiplier
	return p


## Returns the aggregated weapon upgrade cost multiplier from all held territories.
func get_aggregate_weapon_upgrade_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_weapon_upgrade_cost_multiplier > 0.0:
			p *= t.bonus_weapon_upgrade_cost_multiplier
	return p


## Extra research material granted at end of a successful mission wave clear (not per-kill).
func get_aggregate_bonus_research_per_day() -> int:
	var s: int = 0
	if territory_map == null:
		return 0
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		s += t.bonus_research_per_day
	return s


## When DayConfig.faction_id is empty, use territory default_faction_id.
func get_effective_faction_id_for_territory(territory_id: String) -> String:
	if territory_id.strip_edges() == "" or territory_map == null:
		return ""
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return ""
	return t.default_faction_id.strip_edges()


## Initializes the mission for the given day index and DayConfig, then begins combat.
func start_mission_for_day(day_index: int, day_config: DayConfig) -> void:
	var mission_from_config: int = day_index
	if day_config != null:
		mission_from_config = day_config.mission_index
	current_mission = clampi(mission_from_config, 1, TOTAL_MISSIONS)
	current_wave = 0

	_transition_to(Types.GameState.COMBAT)
	BuildPhaseManager.set_build_phase_active(false)
	SignalBus.mission_started.emit(current_mission)
	_spawn_allies_for_current_mission()
	_apply_shop_mission_start_consumables()
	_begin_mission_wave_sequence()

# ── Private helpers ────────────────────────────────────────────────────────────

func _apply_shop_mission_start_consumables() -> void:
	var shop: ShopManager = get_node_or_null("/root/Main/Managers/ShopManager") as ShopManager
	if shop == null:
		return
	shop.apply_mission_start_consumables()


func _spawn_allies_for_current_mission() -> void:
	var main: Node = get_node_or_null("/root/Main")
	if main == null:
		push_warning(
			"GameManager: Main scene not found at /root/Main; skipping ally spawn (mission %d)."
			% current_mission
		)
		return

	var ally_container: Node3D = main.get_node_or_null("AllyContainer") as Node3D
	var spawn_points_root: Node3D = main.get_node_or_null("AllySpawnPoints") as Node3D
	if ally_container == null or spawn_points_root == null:
		push_warning(
			"GameManager: AllyContainer or AllySpawnPoints missing under Main; skipping ally spawn (mission %d)."
			% current_mission
		)
		return

	_cleanup_allies()

	var ally_datas: Array = CampaignManager.current_ally_roster
	var spawn_points: Array[Node3D] = []
	for child: Node in spawn_points_root.get_children():
		if child is Node3D:
			spawn_points.append(child as Node3D)

	if ally_datas.is_empty() or spawn_points.is_empty():
		return

	var index: int = 0
	for data: Variant in ally_datas:
		if data == null:
			continue
		var ally: Node = _ally_base_scene.instantiate()
		if ally == null:
			continue

		ally_container.add_child(ally)
		var spawn_point: Node3D = spawn_points[index % spawn_points.size()] as Node3D
		ally.global_position = spawn_point.global_position

		if ally.has_method("initialize_ally_data"):
			ally.call("initialize_ally_data", data)
		_active_allies.append(ally)

		index += 1


func _cleanup_allies() -> void:
	for ally: Variant in _active_allies:
		if ally != null and is_instance_valid(ally):
			(ally as Node).queue_free()
	_active_allies.clear()


func _begin_mission_wave_sequence() -> void:
	var main: Node = get_tree().root.get_node_or_null("Main")
	if main == null:
		push_warning(
			"GameManager: Main scene not found at /root/Main; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	var managers: Node = main.get_node_or_null("Managers")
	if managers == null:
		push_warning(
			"GameManager: Managers node not found at /root/Main/Managers; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	var wave_manager: WaveManager = managers.get_node_or_null("WaveManager") as WaveManager
	if wave_manager == null:
		push_warning(
			"GameManager: WaveManager not found at /root/Main/Managers/WaveManager; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	print("[GameManager] _begin_mission_wave_sequence: mission=%d" % current_mission)
	wave_manager.ensure_boss_registry_loaded()
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	if day_cfg != null and day_cfg.mission_economy != null:
		EconomyManager.apply_mission_economy(day_cfg.mission_economy)
	else:
		EconomyManager.reset_for_mission()
	_update_final_boss_tracking_from_day(day_cfg)
	wave_manager.reset_for_new_mission()
	# Apply day config after reset — reset clears per-day tuning (waves, faction, multipliers).
	wave_manager.configure_for_day(day_cfg)
	wave_manager.call_deferred("start_wave_sequence")

func _transition_to(new_state: Types.GameState) -> void:
	var resolved: Types.GameState = new_state
	if new_state == Types.GameState.BETWEEN_MISSIONS and CampaignManager.is_endless_mode:
		resolved = Types.GameState.ENDLESS
	if game_state == resolved:
		return
	var old_name: String = Types.GameState.keys()[game_state]
	var new_name: String = Types.GameState.keys()[resolved]
	print("[GameManager] state: %s → %s" % [old_name, new_name])
	var old: Types.GameState = game_state
	game_state = resolved
	SignalBus.game_state_changed.emit(old, resolved)

func _on_all_waves_cleared() -> void:
	_cleanup_allies()
	print("[GameManager] all_waves_cleared: awarding mission=%d resources" % current_mission)
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	apply_day_result_to_territory(day_cfg, true)

	var base_gold_reward: int = 50 * current_mission
	var modifiers: Dictionary = get_current_territory_gold_modifiers()
	var flat_bonus: int = int(modifiers.get("flat_gold_end_of_day", 0))
	var percent_bonus: float = float(modifiers.get("percent_gold_end_of_day", 0.0))
	var total_gold: int = base_gold_reward + flat_bonus
	if percent_bonus != 0.0:
		total_gold = int(round(float(total_gold) * (1.0 + percent_bonus)))

	EconomyManager.add_gold(total_gold)
	EconomyManager.add_building_material(3)
	var extra_rm: int = get_aggregate_bonus_research_per_day()
	EconomyManager.add_research_material(2 + extra_rm)
	# Snapshot before mission_won: CampaignManager may increment current_day on mission_won.
	var completed_day_index: int = CampaignManager.get_current_day()

	if (
			day_cfg != null
			and day_cfg.boss_id != ""
			and (day_cfg.is_final_boss or day_cfg.is_boss_attack_day)
	):
		final_boss_id = day_cfg.boss_id
		final_boss_defeated = true
		final_boss_active = false
		_synthetic_boss_attack_day = null
		SignalBus.campaign_boss_attempted.emit(completed_day_index, true)

	# Florence meta-state updates (run meta-progression).
	if florence_data != null and not CampaignManager.is_endless_mode:
		florence_data.total_missions_played += 1
		advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
		_apply_pending_day_advance_if_any()

	SignalBus.mission_won.emit(CampaignManager.get_current_day())

func _on_tower_destroyed() -> void:
	_cleanup_allies()
	print("[GameManager] tower_destroyed → MISSION_FAILED")
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	var completed_day_index: int = CampaignManager.get_current_day()

	# Florence meta-state updates (counts mission attempts).
	if florence_data != null and not CampaignManager.is_endless_mode:
		florence_data.total_missions_played += 1
		florence_data.mission_failures += 1
		advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
		_apply_pending_day_advance_if_any()
	if (
			day_cfg != null
			and day_cfg.boss_id != ""
			and (day_cfg.is_final_boss or day_cfg.is_boss_attack_day)
			and not final_boss_defeated
	):
		final_boss_id = day_cfg.boss_id
		final_boss_active = true
		SignalBus.campaign_boss_attempted.emit(completed_day_index, false)
	else:
		apply_day_result_to_territory(day_cfg, false)
	_transition_to(Types.GameState.MISSION_FAILED)
	# Snapshot from entry — advance_day above may have incremented CampaignManager.current_day.
	SignalBus.mission_failed.emit(completed_day_index)


## Pre-loads the next day's DayConfig into WaveManager if not already prepared.
func prepare_next_campaign_day_if_needed() -> void:
	if not final_boss_active or final_boss_defeated:
		return
	advance_to_next_day()


## TEST-ONLY: resets Prompt 10 boss campaign fields without starting a new game.
func reset_boss_campaign_state_for_test() -> void:
	_reset_final_boss_campaign_state()


func _reset_final_boss_campaign_state() -> void:
	final_boss_id = ""
	final_boss_day_index = 50
	final_boss_active = false
	final_boss_defeated = false
	current_boss_threat_territory_id = ""
	held_territory_ids.clear()
	_synthetic_boss_attack_day = null


func _sync_held_territories_from_map() -> void:
	held_territory_ids.clear()
	if territory_map == null:
		return
	for t: TerritoryData in territory_map.get_all_territories():
		if t != null and t.is_controlled_by_player:
			held_territory_ids.append(t.territory_id)


func _update_final_boss_tracking_from_day(day_cfg: DayConfig) -> void:
	if day_cfg == null:
		return
	if day_cfg.boss_id != "":
		final_boss_id = day_cfg.boss_id
	if day_cfg.is_final_boss:
		final_boss_day_index = day_cfg.day_index


func _ensure_synthetic_boss_attack_day_config() -> DayConfig:
	var syn: DayConfig = DayConfig.new()
	syn.day_index = CampaignManager.current_day
	syn.mission_index = 5
	syn.display_name = "Boss strike"
	syn.description = "PLACEHOLDER: The campaign boss strikes again."
	syn.faction_id = "PLAGUE_CULT"
	syn.base_wave_count = 5
	syn.enemy_hp_multiplier = 1.0
	syn.enemy_damage_multiplier = 1.0
	syn.gold_reward_multiplier = 1.0
	syn.is_mini_boss_day = false
	syn.is_mini_boss = false
	syn.is_final_boss = true
	syn.is_boss_attack_day = true
	syn.boss_id = final_boss_id
	_synthetic_boss_attack_day = syn
	return syn


func _assign_boss_attack_to_day(day_config: DayConfig) -> void:
	if day_config == null:
		return
	if held_territory_ids.is_empty():
		_sync_held_territories_from_map()
	if held_territory_ids.is_empty():
		return
	var idx: int = randi() % held_territory_ids.size()
	current_boss_threat_territory_id = held_territory_ids[idx]
	day_config.territory_id = current_boss_threat_territory_id
	day_config.is_boss_attack_day = true
	day_config.is_final_boss = true
	day_config.boss_id = final_boss_id
	_mark_territory_boss_threat(current_boss_threat_territory_id, true)


func _mark_territory_boss_threat(territory_id: String, threatened: bool) -> void:
	if territory_map == null or territory_id == "":
		return
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return
	t.has_boss_threat = threatened
	SignalBus.territory_state_changed.emit(territory_id)


func _on_boss_killed(boss_id: String) -> void:
	CampaignManager.notify_mini_boss_defeated(boss_id)
	var data: BossData = _get_boss_data(boss_id)
	if data != null and data.is_mini_boss and data.associated_territory_id != "":
		_mark_territory_secured(data.associated_territory_id)


func _get_boss_data(boss_id: String) -> BossData:
	for path: String in BossData.BUILTIN_BOSS_RESOURCE_PATHS:
		var res: Resource = load(path)
		if res is BossData:
			var b: BossData = res as BossData
			if b.boss_id == boss_id:
				return b
	return null


func _mark_territory_secured(territory_id: String) -> void:
	if territory_map == null or territory_id == "":
		return
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return
	t.is_secured = true
	t.has_boss_threat = false
	SignalBus.territory_state_changed.emit(territory_id)


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	var mana: int = 0
	if spell != null:
		mana = spell.get_current_mana()
	var florence_dict: Dictionary = {}
	if florence_data != null:
		florence_dict = {
			"total_days_played": florence_data.total_days_played,
			"run_count": florence_data.run_count,
			"total_missions_played": florence_data.total_missions_played,
			"boss_attempts": florence_data.boss_attempts,
			"boss_victories": florence_data.boss_victories,
			"mission_failures": florence_data.mission_failures,
			"has_unlocked_research": florence_data.has_unlocked_research,
			"has_unlocked_enchantments": florence_data.has_unlocked_enchantments,
			"has_recruited_any_mercenary": florence_data.has_recruited_any_mercenary,
			"has_seen_any_mini_boss": florence_data.has_seen_any_mini_boss,
			"has_defeated_any_mini_boss": florence_data.has_defeated_any_mini_boss,
			"has_reached_day_25": florence_data.has_reached_day_25,
			"has_reached_day_50": florence_data.has_reached_day_50,
			"has_seen_first_boss": florence_data.has_seen_first_boss,
		}
	return {
		"game_state": int(game_state),
		"final_boss_defeated": final_boss_defeated,
		"current_gold": EconomyManager.get_gold(),
		"current_building_material": EconomyManager.get_building_material(),
		"current_research_material": EconomyManager.get_research_material(),
		"current_mana": mana,
		"current_mission": current_mission,
		"current_wave": current_wave,
		"current_day": CampaignManager.get_current_day(),
		"florence_data": florence_dict,
		"final_boss_id": final_boss_id,
		"final_boss_day_index": final_boss_day_index,
		"final_boss_active": final_boss_active,
		"current_boss_threat_territory_id": current_boss_threat_territory_id,
	}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	var gs: int = int(data.get("game_state", int(Types.GameState.MAIN_MENU)))
	game_state = gs as Types.GameState
	final_boss_defeated = bool(data.get("final_boss_defeated", false))
	current_mission = int(data.get("current_mission", 1))
	current_wave = int(data.get("current_wave", 0))
	current_day = int(data.get("current_day", 1))
	final_boss_id = str(data.get("final_boss_id", ""))
	final_boss_day_index = int(data.get("final_boss_day_index", 50))
	final_boss_active = bool(data.get("final_boss_active", false))
	current_boss_threat_territory_id = str(data.get("current_boss_threat_territory_id", ""))
	EconomyManager.apply_save_snapshot(
		int(data.get("current_gold", EconomyManager.get_gold())),
		int(data.get("current_building_material", EconomyManager.get_building_material())),
		int(data.get("current_research_material", EconomyManager.get_research_material()))
	)
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	if spell != null:
		spell.set_mana_for_save_restore(int(data.get("current_mana", 0)))
	if florence_data == null:
		florence_data = FlorenceDataType.new()
	var fd: Variant = data.get("florence_data", {})
	if fd is Dictionary:
		var fdd: Dictionary = fd as Dictionary
		florence_data.total_days_played = int(fdd.get("total_days_played", florence_data.total_days_played))
		florence_data.run_count = int(fdd.get("run_count", florence_data.run_count))
		florence_data.total_missions_played = int(fdd.get("total_missions_played", florence_data.total_missions_played))
		florence_data.boss_attempts = int(fdd.get("boss_attempts", florence_data.boss_attempts))
		florence_data.boss_victories = int(fdd.get("boss_victories", florence_data.boss_victories))
		florence_data.mission_failures = int(fdd.get("mission_failures", florence_data.mission_failures))
		florence_data.has_unlocked_research = bool(fdd.get("has_unlocked_research", florence_data.has_unlocked_research))
		florence_data.has_unlocked_enchantments = bool(fdd.get("has_unlocked_enchantments", florence_data.has_unlocked_enchantments))
		florence_data.has_recruited_any_mercenary = bool(fdd.get("has_recruited_any_mercenary", florence_data.has_recruited_any_mercenary))
		florence_data.has_seen_any_mini_boss = bool(fdd.get("has_seen_any_mini_boss", florence_data.has_seen_any_mini_boss))
		florence_data.has_defeated_any_mini_boss = bool(fdd.get("has_defeated_any_mini_boss", florence_data.has_defeated_any_mini_boss))
		florence_data.has_reached_day_25 = bool(fdd.get("has_reached_day_25", florence_data.has_reached_day_25))
		florence_data.has_reached_day_50 = bool(fdd.get("has_reached_day_50", florence_data.has_reached_day_50))
		florence_data.has_seen_first_boss = bool(fdd.get("has_seen_first_boss", florence_data.has_seen_first_boss))
		florence_data.update_day_threshold_flags(current_day)
	SignalBus.florence_state_changed.emit()


## Restores the set of held territory IDs from a saved snapshot.
func apply_save_held_territory_ids(ids: Array[String]) -> void:
	held_territory_ids = ids.duplicate()
	if territory_map == null:
		return
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null:
			continue
		t.is_controlled_by_player = held_territory_ids.has(t.territory_id)
	SignalBus.world_map_updated.emit()

scripts/types.gd:
## types.gd
## Global enums and constants for FOUL WARD. Accessed via Types.GameState, Types.DamageType, etc.
## Simulation API: all public methods callable without UI nodes present.

class_name Types

enum GameState {
	MAIN_MENU,
	MISSION_BRIEFING,
	COMBAT,
	BUILD_MODE,
	WAVE_COUNTDOWN,
	BETWEEN_MISSIONS,
	MISSION_WON,
	MISSION_FAILED,
	GAME_WON,
	## Terminal failure / game over (SimBot, meta-flow); distinct from per-mission MISSION_FAILED.
	GAME_OVER,
	## Between-mission hub while in Endless Run (same UI as BETWEEN_MISSIONS; no campaign cap).
	ENDLESS,
}

enum DamageType {
	PHYSICAL,
	FIRE,
	MAGICAL,
	POISON,
	## Ignores armor flat / shield ordering in [method EnemyBase.receive_damage] (Prompt 49).
	TRUE,
}

enum ArmorType {
	UNARMORED,
	HEAVY_ARMOR,
	UNDEAD,
	FLYING,
}

enum BuildingType {
	ARROW_TOWER,
	FIRE_BRAZIER,
	MAGIC_OBELISK,
	POISON_VAT,
	BALLISTA,
	ARCHER_BARRACKS,
	ANTI_AIR_BOLT,
	SHIELD_GENERATOR,
	# ─── SMALL TOWERS (indices 8–19) ───
	SPIKE_SPITTER, # 8   SMALL, PHYSICAL, ground
	EMBER_VENT, # 9   SMALL, FIRE, ground, DoT
	FROST_PINGER, # 10  SMALL, MAGICAL, ground, slow
	NETGUN, # 11  SMALL, PHYSICAL, ground, stop-on-hit
	ACID_DRIPPER, # 12  SMALL, POISON, ground, DoT
	WOLFDEN, # 13  SMALL, SUMMONER, 2 wolf summons
	CROW_ROOST, # 14  SMALL, AA, flying
	ALARM_TOTEMS, # 15  SMALL, AURA, speed debuff aura on enemies
	CROSSFIRE_NEST, # 16  SMALL, PHYSICAL, targets air+ground
	BOLT_SHRINE, # 17  SMALL, MAGICAL, area pulse every 3s
	THORNWALL, # 18  SMALL, PHYSICAL, passive damage to melee attackers
	FIELD_MEDIC, # 19  SMALL, HEALER, heals allies in radius
	# ─── MEDIUM TOWERS (indices 20–29) ───
	GREATBOW_TURRET, # 20  MEDIUM, PHYSICAL, high range
	MOLTEN_CASTER, # 21  MEDIUM, FIRE, splash AoE
	ARCANE_LENS, # 22  MEDIUM, MAGICAL, chains to 2 targets
	PLAGUE_MORTAR, # 23  MEDIUM, POISON, lobs to random ground pos
	BEAR_DEN, # 24  MEDIUM, SUMMONER, 1 bear + 1 wolf
	GUST_CANNON, # 25  MEDIUM, PHYSICAL, AA + knockback
	WARDEN_SHRINE, # 26  MEDIUM, AURA, +15% damage to all buildings in radius
	IRON_CLERIC, # 27  MEDIUM, HEALER, repairs damaged buildings
	SIEGE_BALLISTA, # 28  MEDIUM, PHYSICAL, piercing (hits up to 3 enemies)
	CHAIN_LIGHTNING, # 29  MEDIUM, MAGICAL, priority FLYING
	# ─── LARGE TOWERS (indices 30–35) ───
	FORTRESS_CANNON, # 30  LARGE, PHYSICAL, highest single-hit damage
	DRAGON_FORGE, # 31  LARGE, FIRE, wide AoE splash
	VOID_OBELISK, # 32  LARGE, MAGICAL, debuffs enemy armor on hit
	PLAGUE_CAULDRON, # 33  LARGE, POISON, persistent AoE cloud
	BARRACKS_FORTRESS, # 34  LARGE, SUMMONER, 2 knights + 2 archers
	CITADEL_AURA, # 35  LARGE, AURA, +20% damage + +10% fire rate to all buildings
}

## Modular building kit: base piece under `res://art/generated/kit/*.glb` (see FUTURE_3D_MODELS_PLAN.md §4).
enum BuildingBaseMesh {
	STONE_ROUND,
	STONE_SQUARE,
	WOOD_ROUND,
	RUINS_BASE,
}

## Modular building kit: top piece under `res://art/generated/kit/*.glb` (see FUTURE_3D_MODELS_PLAN.md §4).
enum BuildingTopMesh {
	ROOF_CONE,
	ROOF_FLAT,
	GLASS_DOME,
	FIRE_BOWL,
	POISON_TANK,
	BALLISTA_FRAME,
	EMBRASURE,
}

enum ArnulfState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DOWNED,
	RECOVERING,
}

enum ResourceType {
	GOLD,
	BUILDING_MATERIAL,
	RESEARCH_MATERIAL,
}

enum EnemyType {
	ORC_GRUNT,
	ORC_BRUTE,
	GOBLIN_FIREBUG,
	PLAGUE_ZOMBIE,
	ORC_ARCHER,
	BAT_SWARM,
	# ─── TIER 1 FODDER (indices 6–9) ───
	ORC_SKIRMISHER, # 6   T1, fast melee, RUSH
	ORC_RATLING, # 7   T1, tiny, spawns from Brood Carrier death
	GOBLIN_RUNTS, # 8   T1, 3-pack spawn, very low HP
	HOUND, # 9   T1, fast, high-speed RUSH
	# ─── TIER 2 STANDARD (indices 10–15) ───
	ORC_RAIDER, # 10  T2, standard melee
	ORC_MARKSMAN, # 11  T2, ranged physical
	WAR_SHAMAN, # 12  T2, SUPPORT: buffs nearby orc damage +20%
	PLAGUE_SHAMAN, # 13  T2, SUPPORT: heals nearby orcs 5 HP/s
	TOTEM_CARRIER, # 14  T2, SUPPORT: HP regen aura
	HARPY_SCOUT, # 15  T2, FLYING, fast flyer
	# ─── TIER 3 ELITE (indices 16–21) ───
	ORC_SHIELDBEARER, # 16  T3, HEAVY, physical shield absorbs first 80 dmg
	ORC_BERSERKER, # 17  T3, RUSH, enrages below 50% HP (+50% speed)
	ORC_SABOTEUR, # 18  T3, disables a building for 4s on reach
	HEXBREAKER, # 19  T3, dispels one player aura on hit
	WYVERN_RIDER, # 20  T3, FLYING, ranged fire attack
	BROOD_CARRIER, # 21  T3, spawns 3 ORC_RATLING on death
	# ─── TIER 4 HEAVY (indices 22–26) ───
	TROLL, # 22  T4, HEAVY, HP regen 8/s, slow
	IRONCLAD_CRUSHER, # 23  T4, HEAVY, high armor
	ORC_OGRE, # 24  T4, HEAVY, AoE melee smash
	WAR_BOAR, # 25  T4, RUSH+HEAVY, charge dash on approach
	ORC_SKYTHROWER, # 26  T4, RANGED, anti-air javelin priority
	# ─── TIER 5 BOSS-TIER (indices 27–29) ───
	WARLORDS_GUARD, # 27  T5, mini-elite escort
	ORCISH_SPIRIT, # 28  T5, FLYING, magic immune
	PLAGUE_HERALD, # 29  T5, SUPPORT+HEAVY, combines shaman aura + troll HP
}

enum AllyClass {
	MELEE,
	RANGED,
	SUPPORT,
}

enum WeaponSlot {
	CROSSBOW,
	RAPID_MISSILE,
}

# Used by buildings and allies for target selection preferences.
# AllyBase: CLOSEST / LOWEST_HP / HIGHEST_HP / FLYING_FIRST (see AllyData.preferred_targeting).
enum TargetPriority {
	CLOSEST,
	HIGHEST_HP,
	FLYING_FIRST,
	LOWEST_HP,
}

# NEW enums for ally roles and SimBot strategy profiles (Prompt 12).
enum AllyRole {
	MELEE_FRONTLINE,
	RANGED_SUPPORT,
	ANTI_AIR,
	SPELL_SUPPORT,
}

## Combat role for [AllyData] tower-defense data (Prompt 42). Distinct from [enum AllyRole] (mercenary / SimBot legacy).
enum AllyCombatRole {
	MELEE,
	RANGED,
	HEALER,
	BOMBER,
	AURA,
}

enum StrategyProfile {
	BALANCED,
	ALLY_HEAVY_PHYSICAL,
	ANTI_AIR_FOCUS,
	SPELL_FOCUS,
	BUILDING_FOCUS,
}

## Battle terrain preset for CampaignManager terrain scene selection (see FUTURE_3D_MODELS_PLAN.md §5).
enum TerrainType {
	GRASSLAND,
	FOREST,
	SWAMP,
	RUINS,
	TUNDRA,
}

## Modifier kind for TerrainZone; IMPASSABLE is documented for NavigationObstacle3D, not Area3D zones.
enum TerrainEffect {
	NONE,
	SLOW,
	IMPASSABLE,
}

# ASSUMPTION: HubRole enum is appended to keep existing enum numeric ordering stable.
# POST-MVP: Extend with FLORENCE, CAMPAIGN_SPECIFIC, etc. narrative requires.
enum HubRole {
	SHOP,
	RESEARCH,
	ENCHANT,
	MERCENARY,
	ALLY,
	FLAVOR_ONLY,
}

# Meta-state timeline advance reasons for Florence and between-mission narratives.
# Higher priority means "more important" to keep within the same advance window.
enum DayAdvanceReason {
	MISSION_COMPLETED,
	ACHIEVEMENT_EARNED,
	MAJOR_STORY_EVENT,
}

# --- Tower defense / mission data (Prompt 34) — must appear before any methods. ---

## Footprint category for data-driven building placement (hex rings, multi-slot).
enum BuildingSizeClass {
	SINGLE_SLOT,
	DOUBLE_WIDE,
	TRIPLE_CLUSTER,
	## Ring footprint tiers (Prompt 42); orthogonal to SINGLE_SLOT / DOUBLE_WIDE slot geometry.
	SMALL,
	MEDIUM,
	LARGE,
}

## Rough unit footprint for allies / summons (balance + pathing hints).
enum UnitSize {
	SMALL,
	MEDIUM,
	LARGE,
	HUGE,
}

## High-level ally behaviour mode (runtime AI may map multiple modes to one state machine).
enum AllyAiMode {
	DEFAULT,
	HOLD_POSITION,
	AGGRESSIVE,
	ESCORT,
	FOLLOW_LEADER,
}

## Summoned unit lifetime category (buildings + allies; Prompt 42).
enum SummonLifetimeType {
	NONE,
	MORTAL,
	RECURRING,
	IMMORTAL,
}

## Aura stacking / modification style for support towers and allies (legacy / extended tuning).
enum AuraModifierKind {
	ADD_FLAT,
	ADD_PERCENT,
	MULTIPLY,
}

## Simplified aura math mode for data resources (Prompt 42): additive vs multiplicative.
enum AuraModifierOp {
	ADD,
	MULTIPLY,
}

## Broad aura channel for UI filtering and exclusive rules.
enum AuraCategory {
	OFFENSE,
	DEFENSE,
	UTILITY,
	CONTROL,
}

## Stat column modified by an aura (data-driven; gameplay interprets).
enum AuraStat {
	DAMAGE,
	FIRE_RATE,
	RANGE,
	ARMOR,
	MAGIC_RESIST,
	MOVE_SPEED,
}

## Enemy locomotion / pathing class (distinct from ArmorType). Append-only: preserve existing ordinals.
enum EnemyBodyType {
	GROUND,
	FLYING,
	HOVER,
	BOSS,
	STRUCTURE,
	LARGE_GROUND,
	SIEGE,
	ETHEREAL,
}

## Content pipeline status for mission JSON / exports.
enum MissionBalanceStatus {
	UNSET,
	DRAFT,
	REVIEW,
	SHIPPED,
}

# SOURCE: Day/week advancement priority table pattern from management/roguelite design.
# TUNING: Adjust priorities as needed.
static func get_day_advance_priority(reason: DayAdvanceReason) -> int:
	match reason:
		DayAdvanceReason.MISSION_COMPLETED:
			# Baseline: still advances time, but is superseded by higher narrative drivers.
			return 0
		DayAdvanceReason.ACHIEVEMENT_EARNED:
			return 1
		DayAdvanceReason.MAJOR_STORY_EVENT:
			return 2
		_:
			return 0

# ASSUMPTION: Types uses enums + static helpers as a shared registry across systems.


