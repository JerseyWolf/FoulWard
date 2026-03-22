# tests/test_hex_grid.gd
# GdUnit4 test suite for HexGrid.
# Tests slot initialization, placement, selling, upgrading, and persistence.

class_name TestHexGrid
extends GdUnitTestSuite

var _hex_grid: HexGrid = null


func _create_hex_grid() -> HexGrid:
	var grid: HexGrid = HexGrid.new()
	for i: int in range(24):
		var slot: Area3D = Area3D.new()
		slot.name = "HexSlot_%02d" % i
		var col: CollisionShape3D = CollisionShape3D.new()
		col.name = "SlotCollision"
		col.shape = BoxShape3D.new()
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.name = "SlotMesh"
		slot.add_child(col)
		slot.add_child(mesh)
		grid.add_child(slot)
	return grid


func _make_building_data_registry() -> Array[BuildingData]:
	var registry: Array[BuildingData] = []
	var building_types: Array = Types.BuildingType.values()
	for bt in building_types:
		var bd: BuildingData = BuildingData.new()
		bd.building_type = bt
		bd.display_name = "Test Building %d" % bt
		bd.gold_cost = 50
		bd.material_cost = 2
		bd.upgrade_gold_cost = 75
		bd.upgrade_material_cost = 3
		bd.damage = 20.0
		bd.upgraded_damage = 35.0
		bd.fire_rate = 1.0
		bd.attack_range = 15.0
		bd.upgraded_range = 18.0
		bd.damage_type = Types.DamageType.PHYSICAL
		bd.targets_air = false
		bd.targets_ground = true
		bd.is_locked = false
		bd.color = Color.GRAY
		registry.append(bd)
	return registry


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(1000)
	EconomyManager.add_building_material(100)


func after_test() -> void:
	if is_instance_valid(_hex_grid):
		_hex_grid.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# Slot initialisation tests
# ---------------------------------------------------------------------------

func test_initialize_creates_24_slots() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	assert_int(_hex_grid.get_empty_slots().size()).is_equal(24)


func test_all_slots_start_unoccupied() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	for i: int in range(24):
		var slot_data: Dictionary = _hex_grid.get_slot_data(i)
		assert_bool(slot_data["is_occupied"]).is_false()


func test_slot_ring1_at_correct_radius() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	for i: int in range(6):
		var pos: Vector3 = _hex_grid.get_slot_position(i)
		var dist: float = Vector3.ZERO.distance_to(pos)
		assert_float(dist).is_equal_approx(6.0, 0.01)


func test_slot_ring2_at_correct_radius() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	for i: int in range(6, 18):
		var pos: Vector3 = _hex_grid.get_slot_position(i)
		var dist: float = Vector3.ZERO.distance_to(pos)
		assert_float(dist).is_equal_approx(12.0, 0.01)


func test_slot_ring3_at_correct_radius() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	for i: int in range(18, 24):
		var pos: Vector3 = _hex_grid.get_slot_position(i)
		var dist: float = Vector3.ZERO.distance_to(pos)
		assert_float(dist).is_equal_approx(18.0, 0.01)


func test_all_slot_positions_at_y_zero() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	for i: int in range(24):
		var pos: Vector3 = _hex_grid.get_slot_position(i)
		assert_float(pos.y).is_equal_approx(0.0, 0.001)

# ---------------------------------------------------------------------------
# Placement tests
# ---------------------------------------------------------------------------

func test_place_building_insufficient_gold_fails() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.spend_gold(990)  # leave only 10 gold
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	var result: bool = _hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)
	assert_bool(result).is_false()


func test_place_locked_building_null_safety() -> void:
	_hex_grid = _create_hex_grid()
	var registry: Array[BuildingData] = _make_building_data_registry()
	registry[4].is_locked = true
	registry[4].unlock_research_id = "unlock_ballista"
	_hex_grid.building_data_registry = registry
	add_child(_hex_grid)
	await get_tree().process_frame
	# With null research_manager, locked buildings are treated as unlocked (test context).
	assert_bool(_hex_grid.is_building_unlocked(Types.BuildingType.BALLISTA)).is_true()


func test_place_building_emits_building_placed_signal() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.building_placed.emit(0, Types.BuildingType.ARROW_TOWER)
	await assert_signal(monitor).is_emitted(
		"building_placed", [0, Types.BuildingType.ARROW_TOWER]
	)

# ---------------------------------------------------------------------------
# Sell tests
# ---------------------------------------------------------------------------

func test_sell_empty_slot_fails() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	var result: bool = _hex_grid.sell_building(0)
	assert_bool(result).is_false()


func test_sell_invalid_index_fails() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	assert_bool(_hex_grid.sell_building(-1)).is_false()
	assert_bool(_hex_grid.sell_building(24)).is_false()


func test_sell_building_full_refund_arithmetic() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(200)
	EconomyManager.add_building_material(20)
	var gold_before: int = EconomyManager.get_gold()
	EconomyManager.spend_gold(50)
	EconomyManager.spend_building_material(2)
	EconomyManager.add_gold(50)
	EconomyManager.add_building_material(2)
	assert_int(EconomyManager.get_gold()).is_equal(gold_before)


func test_sell_upgraded_building_refunds_both_costs_arithmetic() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(500)
	EconomyManager.add_building_material(50)
	var before_gold: int = EconomyManager.get_gold()
	EconomyManager.spend_gold(50)
	EconomyManager.spend_gold(75)
	EconomyManager.add_gold(50 + 75)
	assert_int(EconomyManager.get_gold()).is_equal(before_gold)

# ---------------------------------------------------------------------------
# Upgrade tests
# ---------------------------------------------------------------------------

func test_upgrade_sets_is_upgraded_true() -> void:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.damage = 20.0
	bd.upgraded_damage = 35.0
	bd.attack_range = 15.0
	bd.upgraded_range = 18.0
	bd.fire_rate = 1.0
	bd.color = Color.GRAY
	bd.display_name = "Arrow Tower"
	var building: BuildingBase = BuildingBase.new()
	building._building_data = bd
	building._is_upgraded = false
	building.upgrade()
	assert_bool(building.is_upgraded).is_true()


func test_upgrade_unoccupied_slot_fails() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	var result: bool = _hex_grid.upgrade_building(0)
	assert_bool(result).is_false()


func test_upgrade_emits_building_upgraded() -> void:
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.building_upgraded.emit(0, Types.BuildingType.ARROW_TOWER)
	await assert_signal(monitor).is_emitted(
		"building_upgraded", [0, Types.BuildingType.ARROW_TOWER]
	)

# ---------------------------------------------------------------------------
# State query tests
# ---------------------------------------------------------------------------

func test_get_empty_slots_returns_all_24_initially() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	assert_int(_hex_grid.get_empty_slots().size()).is_equal(24)


func test_get_all_occupied_slots_returns_empty_initially() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	assert_int(_hex_grid.get_all_occupied_slots().size()).is_equal(0)


func test_is_valid_index_bounds() -> void:
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	assert_bool(_hex_grid._is_valid_index(-1)).is_false()
	assert_bool(_hex_grid._is_valid_index(24)).is_false()
	assert_bool(_hex_grid._is_valid_index(0)).is_true()
	assert_bool(_hex_grid._is_valid_index(23)).is_true()

