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

const BuildingScene: PackedScene = preload("res://scenes/buildings/building_base.tscn")

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Must have exactly 8 entries, one per Types.BuildingType enum value.
@export var building_data_registry: Array[BuildingData] = []

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

## Each Dictionary: { index: int, world_pos: Vector3,
##                    building: BuildingBase|null, is_occupied: bool }
var _slots: Array[Dictionary] = []

# ASSUMPTION: BuildingContainer at /root/Main/BuildingContainer per ARCHITECTURE.md §2.
@onready var _building_container: Node3D = get_node("/root/Main/BuildingContainer")

# ASSUMPTION: ResearchManager at /root/Main/Managers/ResearchManager.
# If null (unit test context), all buildings are treated as unlocked.
var _research_manager = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.research_unlocked.connect(_on_research_unlocked)

	# ASSUMPTION: ResearchManager may not be present in unit test scenes.
	_research_manager = get_node_or_null("/root/Main/Managers/ResearchManager")

	assert(building_data_registry.size() == 8,
		"HexGrid: building_data_registry must have exactly 8 entries, got %d"
		% building_data_registry.size())

	_initialize_slots()
	_set_slots_visible(false)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Places a building of building_type on the given slot.
## Returns true on success, false on any validation failure.
func place_building(slot_index: int, building_type: Types.BuildingType) -> bool:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.place_building: invalid slot_index %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if slot["is_occupied"]:
		push_warning("HexGrid.place_building: slot %d already occupied" % slot_index)
		return false

	var building_data: BuildingData = get_building_data(building_type)
	if building_data == null:
		push_error("HexGrid.place_building: no BuildingData for type %d" % building_type)
		return false

	if not is_building_unlocked(building_type):
		return false

	if not EconomyManager.can_afford(building_data.gold_cost, building_data.material_cost):
		return false

	# Spend resources.
	var gold_spent: bool = EconomyManager.spend_gold(building_data.gold_cost)
	assert(gold_spent, "HexGrid: spend_gold failed after can_afford returned true")
	var mat_spent: bool = EconomyManager.spend_building_material(building_data.material_cost)
	assert(mat_spent, "HexGrid: spend_building_material failed after can_afford returned true")

	var building: BuildingBase = BuildingScene.instantiate() as BuildingBase
	# Per CONVENTIONS.md §7.3 – call initialize() before add_child when possible.
	building.initialize(building_data)
	_building_container.add_child(building)
	building.global_position = slot["world_pos"]
	building.add_to_group("buildings")

	slot["building"] = building
	slot["is_occupied"] = true

	SignalBus.building_placed.emit(slot_index, building_type)
	return true


## Sells the building on the given slot. Full refund including upgrade costs if upgraded.
## Returns true on success, false if slot is empty or invalid.
func sell_building(slot_index: int) -> bool:
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

	# Full refund of base costs.
	EconomyManager.add_gold(building_data.gold_cost)
	EconomyManager.add_building_material(building_data.material_cost)

	# Also refund upgrade costs if the building was upgraded.
	if building.is_upgraded:
		EconomyManager.add_gold(building_data.upgrade_gold_cost)
		EconomyManager.add_building_material(building_data.upgrade_material_cost)

	building.remove_from_group("buildings")
	building.queue_free()

	slot["building"] = null
	slot["is_occupied"] = false

	SignalBus.building_sold.emit(slot_index, building_type)
	return true


## Upgrades the building on the given slot from Basic to Upgraded tier.
## Returns true on success, false on any validation failure.
func upgrade_building(slot_index: int) -> bool:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.upgrade_building: invalid slot_index %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if not slot["is_occupied"]:
		push_warning("HexGrid.upgrade_building: slot %d not occupied" % slot_index)
		return false

	var building: BuildingBase = slot["building"] as BuildingBase

	if building.is_upgraded:
		push_warning("HexGrid.upgrade_building: building on slot %d already upgraded" % slot_index)
		return false

	var building_data: BuildingData = building.get_building_data()

	if not EconomyManager.can_afford(building_data.upgrade_gold_cost, building_data.upgrade_material_cost):
		return false

	var gold_spent: bool = EconomyManager.spend_gold(building_data.upgrade_gold_cost)
	assert(gold_spent, "HexGrid: upgrade spend_gold failed after can_afford returned true")
	var mat_spent: bool = EconomyManager.spend_building_material(building_data.upgrade_material_cost)
	assert(mat_spent, "HexGrid: upgrade spend_building_material failed after can_afford returned true")

	building.upgrade()

	SignalBus.building_upgraded.emit(slot_index, building_data.building_type)
	return true


## Returns a shallow copy of the slot data Dictionary for the given index.
func get_slot_data(slot_index: int) -> Dictionary:
	assert(_is_valid_index(slot_index),
		"HexGrid.get_slot_data: invalid slot_index %d" % slot_index)
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
func is_building_unlocked(building_type: Types.BuildingType) -> bool:
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
	assert(_is_valid_index(slot_index),
		"HexGrid.get_slot_position: invalid slot_index %d" % slot_index)
	return _slots[slot_index]["world_pos"]

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

	assert(positions.size() == TOTAL_SLOTS,
		"HexGrid: expected %d positions, got %d" % [TOTAL_SLOTS, positions.size()])

	for i: int in range(TOTAL_SLOTS):
		var slot_data: Dictionary = {
			"index": i,
			"world_pos": positions[i],
			"building": null,
			"is_occupied": false,
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


func _set_slots_visible(visible: bool) -> void:
	for i: int in range(get_child_count()):
		var slot_node: Area3D = get_child(i) as Area3D
		if slot_node == null:
			continue
		var mesh: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
		if mesh != null:
			mesh.visible = visible

# ---------------------------------------------------------------------------
# Private – validation
# ---------------------------------------------------------------------------

func _is_valid_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < TOTAL_SLOTS

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_build_mode_entered() -> void:
	_set_slots_visible(true)


func _on_build_mode_exited() -> void:
	_set_slots_visible(false)


func _on_research_unlocked(_node_id: String) -> void:
	# No cache to invalidate – is_building_unlocked() checks live state each call.
	# Hook reserved for future UI refresh (e.g., glow newly unlocked slots).
	pass
