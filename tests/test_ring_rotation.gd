# tests/test_ring_rotation.gd — Hex grid 42-slot layout, ring_rotated signal, RING_ROTATE state, save guards.

class_name TestRingRotation
extends GdUnitTestSuite

var _hex_grid: HexGrid = null


func _create_hex_grid() -> HexGrid:
	var grid: HexGrid = HexGrid.new()
	for i: int in range(HexGrid.TOTAL_SLOTS):
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


func _setup_hex_grid_test() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(1000)
	EconomyManager.add_building_material(100)
	BuildPhaseManager.set_build_phase_active(true)


func _teardown_hex_grid_test() -> void:
	EconomyManager.reset_to_defaults()
	BuildPhaseManager.set_build_phase_active(true)
	if is_instance_valid(_hex_grid):
		_hex_grid.queue_free()
	_hex_grid = null
	await get_tree().process_frame


func test_total_slots_42() -> void:
	assert_int(HexGrid.TOTAL_SLOTS).is_equal(42)


func test_ring1_slot_count() -> void:
	assert_int(HexGrid.RING1_COUNT).is_equal(6)


func test_ring2_slot_count() -> void:
	assert_int(HexGrid.RING2_COUNT).is_equal(12)


func test_ring3_slot_count() -> void:
	assert_int(HexGrid.RING3_COUNT).is_equal(24)


func test_rotate_ring_changes_offset() -> void:
	_setup_hex_grid_test()
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	_hex_grid.rotate_ring(0, PI / 6.0)
	assert_float(_hex_grid.get_ring_offset_radians(0)).is_equal_approx(PI / 6.0, 0.0001)
	await _teardown_hex_grid_test()


func test_rotate_ring_moves_building_positions() -> void:
	_setup_hex_grid_test()
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	assert_bool(_hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)).is_true()
	var pos_before: Vector3 = _hex_grid.get_slot_position(0)
	_hex_grid.rotate_ring(0, PI / 6.0)
	var pos_after: Vector3 = _hex_grid.get_slot_position(0)
	assert_float(pos_before.distance_to(pos_after)).is_greater(0.05)
	await _teardown_hex_grid_test()


func test_ring_rotated_signal_emitted() -> void:
	_setup_hex_grid_test()
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	var monitor := monitor_signals(SignalBus, false)
	var step: float = PI / 12.0
	_hex_grid.rotate_ring(1, step)
	await assert_signal(monitor).is_emitted("ring_rotated", [1, step])
	await _teardown_hex_grid_test()


func test_rotation_preserves_building_count() -> void:
	_setup_hex_grid_test()
	_hex_grid = _create_hex_grid()
	_hex_grid.building_data_registry = _make_building_data_registry()
	add_child(_hex_grid)
	await get_tree().process_frame
	assert_bool(_hex_grid.place_building(3, Types.BuildingType.ARROW_TOWER)).is_true()
	var n_before: int = _hex_grid.get_all_occupied_slots().size()
	_hex_grid.rotate_ring(0, PI / 9.0)
	var n_after: int = _hex_grid.get_all_occupied_slots().size()
	assert_int(n_after).is_equal(n_before)
	await _teardown_hex_grid_test()


func test_game_state_ring_rotate_value() -> void:
	assert_int(int(Types.GameState.RING_ROTATE)).is_equal(12)


func test_enter_ring_rotate_sets_state() -> void:
	var prev: Types.GameState = GameManager.get_game_state()
	GameManager.game_state = Types.GameState.PASSIVE_SELECT
	GameManager.enter_ring_rotate()
	assert_that(GameManager.get_game_state()).is_equal(Types.GameState.RING_ROTATE)
	GameManager.game_state = prev


func test_exit_ring_rotate_transitions_state() -> void:
	var prev: Types.GameState = GameManager.get_game_state()
	GameManager.game_state = Types.GameState.RING_ROTATE
	GameManager.exit_ring_rotate()
	assert_that(GameManager.get_game_state()).is_equal(Types.GameState.COMBAT)
	GameManager.game_state = prev


func test_save_migration_old_24_slots() -> void:
	SaveManager.clear_all_saves_for_test()
	SaveManager.current_attempt_id = ""
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	CampaignManager.is_endless_mode = false
	CampaignManager.campaign_completed = false
	var d: Dictionary = {
		"version": 1,
		"attempt_id": "mig_test",
		"campaign": {
			"current_day": 4,
			"campaign_completed": false,
			"is_endless_mode": false,
			"held_territory_ids": [] as Array,
			"owned_ally_ids": [] as Array,
			"active_ally_ids": [] as Array,
			"failed_attempts_on_current_day": 0,
			"campaign_config_resource_path": "",
		},
		"game": {
			"game_state": int(Types.GameState.BETWEEN_MISSIONS),
			"final_boss_defeated": false,
			"current_gold": 100,
			"current_building_material": 10,
			"current_research_material": 0,
			"current_mana": 0,
			"current_mission": 1,
			"current_wave": 0,
			"current_day": 4,
			"florence_data": {},
			"final_boss_id": "",
			"final_boss_day_index": 50,
			"final_boss_active": false,
			"current_boss_threat_territory_id": "",
		},
		"relationship": {},
		"research": {"unlocked_node_ids": [] as Array[String]},
		"shop": {},
		"enchantments": {},
		"sybil": {},
	}
	SaveManager._apply_save_payload(d)
	assert_int(CampaignManager.get_current_day()).is_equal(4)


func test_save_migration_guard_invalid_slot() -> void:
	assert_bool(SaveManager.is_hex_slot_index_in_save_range(41)).is_true()
	assert_bool(SaveManager.is_hex_slot_index_in_save_range(42)).is_false()
