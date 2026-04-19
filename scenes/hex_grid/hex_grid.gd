## HexGrid — Manages 42 hex-shaped building slots; handles placement, selling, upgrading, and between-mission persistence.
# scenes/hex_grid/hex_grid.gd
# HexGrid – manages 42 hex-shaped building slots in three concentric rings.
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
const RING3_COUNT: int = 24
const RING3_RADIUS: float = 24.0
const TOTAL_SLOTS: int = 42

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

## Per-ring visual rotation (radians); does not change slot indices. Indices 0..2 = rings 1..3.
var _ring_offsets: Array[float] = [0.0, 0.0, 0.0]

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
		var hc: HealthComponent = building.health_component as HealthComponent
		if hc == null:
			hc = building.get_node_or_null("HealthComponent") as HealthComponent
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
		var hc: HealthComponent = building.health_component as HealthComponent
		if hc == null:
			hc = building.get_node_or_null("HealthComponent") as HealthComponent
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


# Ring position formula adapted from Red Blob Games (redblobgames.com/grids/hexagons/)
# via romlok/godot-gdhexgrid (github.com/romlok/godot-gdhexgrid)
func rotate_ring(ring_index: int, angle_rad: float) -> void:
	var state: Types.GameState = GameManager.get_game_state()
	var allow_rotate: bool = (
			BuildPhaseManager.is_build_phase
			or state == Types.GameState.RING_ROTATE
	)
	if not allow_rotate:
		push_warning("HexGrid.rotate_ring: attempted outside build phase / ring rotate screen")
		return
	if ring_index < 0 or ring_index >= 3:
		push_warning("HexGrid.rotate_ring: invalid ring_index %d" % ring_index)
		return
	_ring_offsets[ring_index] += angle_rad
	_rebuild_slot_positions()
	SignalBus.ring_rotated.emit(ring_index, _ring_offsets[ring_index])


## Applies ring rotation geometry only (no SignalBus). Used by ring rotation SubViewport preview.
func apply_ring_rotation_silent(ring_index: int, angle_rad: float) -> void:
	if ring_index < 0 or ring_index >= 3:
		return
	_ring_offsets[ring_index] += angle_rad
	_rebuild_slot_positions()


func get_ring_offset_radians(ring_index: int) -> float:
	if ring_index < 0 or ring_index >= _ring_offsets.size():
		return 0.0
	return _ring_offsets[ring_index]


func _rebuild_slot_positions() -> void:
	var new_positions: Array[Vector3] = []
	new_positions.append_array(
			_compute_ring_positions(RING1_COUNT, RING1_RADIUS, rad_to_deg(_ring_offsets[0]))
	)
	new_positions.append_array(
			_compute_ring_positions(RING2_COUNT, RING2_RADIUS, rad_to_deg(_ring_offsets[1]))
	)
	new_positions.append_array(
			_compute_ring_positions(
					RING3_COUNT,
					RING3_RADIUS,
					30.0 + rad_to_deg(_ring_offsets[2])
			)
	)
	if new_positions.size() != TOTAL_SLOTS:
		push_error("HexGrid._rebuild_slot_positions: position count mismatch")
		return
	for i: int in TOTAL_SLOTS:
		_slots[i]["world_pos"] = new_positions[i]
		var node: Area3D = get_node_or_null("HexSlot_%02d" % i) as Area3D
		if node != null:
			node.global_position = new_positions[i]
		var slot: Dictionary = _slots[i]
		if bool(slot.get("is_occupied", false)):
			var building: BuildingBase = slot.get("building") as BuildingBase
			if is_instance_valid(building):
				building.global_position = new_positions[i]


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


## Called by BuildingBase on health_depleted. Clears slot data and frees building node.
func clear_slot_on_destruction(slot_index: int) -> void:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.clear_slot_on_destruction: invalid index %d" % slot_index)
		return
	var slot: Dictionary = _slots[slot_index]
	if not slot["is_occupied"]:
		push_warning("HexGrid.clear_slot_on_destruction: slot %d not occupied" % slot_index)
		return
	var building: BuildingBase = slot["building"] as BuildingBase
	if is_instance_valid(building):
		building.remove_from_group("buildings")
		_disable_building_obstacle(building)
		building.queue_free()
	slot["building"] = null
	slot["is_occupied"] = false


func _disable_building_obstacle(building: BuildingBase) -> void:
	if not is_instance_valid(building):
		return
	var obs: NavigationObstacle3D = building.get_node_or_null("NavigationObstacle") as NavigationObstacle3D
	if obs != null:
		obs.set_deferred("enabled", false)
	var col: CollisionShape3D = building.get_node_or_null("BuildingCollision/CollisionShape3D") as CollisionShape3D
	if col != null:
		col.set_deferred("disabled", true)


## Returns building with lowest HP percentage among alive buildings with HealthComponent.
## Returns null if none found or all at full HP.
func get_lowest_hp_pct_building() -> BuildingBase:
	var best: BuildingBase = null
	var best_pct: float = 1.0
	for slot: Dictionary in _slots:
		if not slot["is_occupied"]:
			continue
		var b: BuildingBase = slot["building"] as BuildingBase
		if not is_instance_valid(b):
			continue
		var hc: HealthComponent = b.health_component as HealthComponent
		if hc == null:
			hc = b.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null or not hc.is_alive():
			continue
		var pct: float = float(hc.current_hp) / float(hc.max_hp)
		if pct < best_pct:
			best_pct = pct
			best = b
	return best


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


## Maps a world position to a logical hex key; [member Vector2i.x] is the slot index (0..41), [member Vector2i.y] is unused (0).
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


## Ring index 0 = inner (6 slots), 1 = middle (12), 2 = outer (24).
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
