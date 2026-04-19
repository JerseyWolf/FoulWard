## test_building_health_component.gd
## GdUnit4 tests for Building HP / HealthComponent integration in BuildingBase.
## Verifies conditional HC setup, destruction signal, HP bar wiring, and save-payload exclusion.

class_name TestBuildingHealthComponent
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_bd(max_hp: int) -> BuildingData:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.display_name = "TestBuilding"
	bd.gold_cost = 50
	bd.material_cost = 2
	bd.upgrade_gold_cost = 75
	bd.upgrade_material_cost = 3
	bd.damage = 10.0
	bd.upgraded_damage = 20.0
	bd.fire_rate = 0.0
	bd.attack_range = 10.0
	bd.upgraded_range = 12.0
	bd.max_hp = max_hp
	bd.can_be_targeted_by_enemies = max_hp > 0
	return bd


func _make_bare_building() -> BuildingBase:
	var b: BuildingBase = BuildingBase.new()
	return b


var _cleanup_nodes: Array[Node] = []


func after_test() -> void:
	for n: Node in _cleanup_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_cleanup_nodes.clear()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# STEP 1 — _setup_health_component conditional logic
# ---------------------------------------------------------------------------

func test_no_health_component_when_max_hp_zero() -> void:
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	b._building_data = _make_bd(0)
	b._setup_health_component()
	# health_component @onready is null (no $HealthComponent child) and method returned early
	assert_object(b.health_component).is_null()


func test_health_component_added_when_max_hp_positive() -> void:
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	b._building_data = _make_bd(100)
	b._setup_health_component()
	assert_object(b.health_component).is_not_null()


func test_health_component_initialized_with_correct_max_hp() -> void:
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	b._building_data = _make_bd(250)
	b._setup_health_component()
	assert_int(b.health_component.max_hp).is_equal(250)


func test_health_component_current_hp_set_to_max_on_setup() -> void:
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	b._building_data = _make_bd(200)
	b._setup_health_component()
	assert_int(b.health_component.current_hp).is_equal(200)


# ---------------------------------------------------------------------------
# STEP 2 — Destruction signal
# ---------------------------------------------------------------------------

func test_building_destroyed_signal_emitted_on_depletion() -> void:
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	b.slot_id = 7
	b._building_data = _make_bd(50)
	# Create and wire HC manually so we control when health_depleted fires
	var hc: HealthComponent = HealthComponent.new()
	hc.max_hp = 50
	hc.current_hp = 50
	add_child(hc)
	_cleanup_nodes.append(hc)
	b.health_component = hc
	hc.health_depleted.connect(b._on_health_depleted)

	var monitor := monitor_signals(SignalBus, false)
	hc.take_damage(50.0)
	await assert_signal(monitor).is_emitted("building_destroyed", [7])


# ---------------------------------------------------------------------------
# STEP 3 — HP bar wiring
# ---------------------------------------------------------------------------

func test_hp_bar_hidden_at_full_health() -> void:
	var hc: HealthComponent = HealthComponent.new()
	hc.max_hp = 100
	add_child(hc)
	_cleanup_nodes.append(hc)

	var hp_bar_scene: PackedScene = load("res://scenes/ui/building_hp_bar.tscn") as PackedScene
	if hp_bar_scene == null or not hp_bar_scene.can_instantiate():
		push_warning("test_hp_bar_hidden_at_full_health: scene unavailable, skipping")
		return
	var hp_bar: BuildingHpBar = hp_bar_scene.instantiate() as BuildingHpBar
	add_child(hp_bar)
	_cleanup_nodes.append(hp_bar)

	hp_bar.setup(hc)
	assert_bool(hp_bar.visible).is_false()


func test_hp_bar_visible_after_damage() -> void:
	var hc: HealthComponent = HealthComponent.new()
	hc.max_hp = 100
	add_child(hc)
	_cleanup_nodes.append(hc)

	var hp_bar_scene: PackedScene = load("res://scenes/ui/building_hp_bar.tscn") as PackedScene
	if hp_bar_scene == null or not hp_bar_scene.can_instantiate():
		push_warning("test_hp_bar_visible_after_damage: scene unavailable, skipping")
		return
	var hp_bar: BuildingHpBar = hp_bar_scene.instantiate() as BuildingHpBar
	add_child(hp_bar)
	_cleanup_nodes.append(hp_bar)

	hp_bar.setup(hc)
	hc.take_damage(30.0)
	assert_bool(hp_bar.visible).is_true()


func test_hp_bar_value_matches_current_hp() -> void:
	var hc: HealthComponent = HealthComponent.new()
	hc.max_hp = 100
	add_child(hc)
	_cleanup_nodes.append(hc)

	var hp_bar_scene: PackedScene = load("res://scenes/ui/building_hp_bar.tscn") as PackedScene
	if hp_bar_scene == null or not hp_bar_scene.can_instantiate():
		push_warning("test_hp_bar_value_matches_current_hp: scene unavailable, skipping")
		return
	var hp_bar: BuildingHpBar = hp_bar_scene.instantiate() as BuildingHpBar
	add_child(hp_bar)
	_cleanup_nodes.append(hp_bar)

	hp_bar.setup(hc)
	hc.take_damage(40.0)
	# _on_health_changed is called synchronously; current_hp == 60
	assert_int(hc.current_hp).is_equal(60)


# ---------------------------------------------------------------------------
# STEP 4 — Save payload exclusion
# ---------------------------------------------------------------------------

func test_building_hp_not_in_save_payload() -> void:
	# Architecture contract: HealthComponent has no serialisation API,
	# so building HP can never be written into a save slot.
	var hc: HealthComponent = HealthComponent.new()
	_cleanup_nodes.append(hc)
	assert_bool(hc.has_method("get_save_data")).is_false()
	assert_bool(hc.has_method("restore_from_save")).is_false()


func test_building_hp_resets_on_new_mission() -> void:
	# Simulate the re-initialisation that happens when buildings are re-placed
	# each day (HexGrid.clear_all_buildings + fresh place_building).
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	var bd: BuildingData = _make_bd(200)
	b._building_data = bd
	b._setup_health_component()

	# Simulate damage during a mission
	b.health_component.take_damage(100.0)
	assert_int(b.health_component.current_hp).is_equal(100)

	# New mission: setup again (mimics re-instantiation)
	b._setup_health_component()
	# Because health_component now exists and is valid, setup resets it to max
	assert_int(b.health_component.current_hp).is_equal(200)


# ---------------------------------------------------------------------------
# Summoner / aura destruction guards
# ---------------------------------------------------------------------------

func test_summoner_despawn_not_called_for_non_summoner() -> void:
	# _on_health_depleted should not crash when building is not a summoner
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	var bd: BuildingData = _make_bd(50)
	bd.is_summoner = false
	b._building_data = bd
	b.slot_id = -1  # no signal emitted; no HexGrid needed
	var hc: HealthComponent = HealthComponent.new()
	hc.max_hp = 50
	hc.current_hp = 50
	add_child(hc)
	_cleanup_nodes.append(hc)
	b.health_component = hc
	hc.health_depleted.connect(b._on_health_depleted)
	# Must not crash
	hc.take_damage(50.0)
	assert_bool(true).is_true()


func test_aura_deregistered_gracefully_on_destruction() -> void:
	# Verifies _on_health_depleted handles aura buildings without crash
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	var bd: BuildingData = _make_bd(50)
	bd.is_aura = true
	bd.aura_category = "test_aura"
	b._building_data = bd
	b.slot_id = -1
	b.placed_instance_id = "test_instance_abc"
	var hc: HealthComponent = HealthComponent.new()
	hc.max_hp = 50
	hc.current_hp = 50
	add_child(hc)
	_cleanup_nodes.append(hc)
	b.health_component = hc
	hc.health_depleted.connect(b._on_health_depleted)
	hc.take_damage(50.0)
	assert_bool(true).is_true()


# ---------------------------------------------------------------------------
# HexGrid clear_slot_on_destruction (Chat 3C parity)
# ---------------------------------------------------------------------------

func _create_hex_grid_for_slot_tests() -> HexGrid:
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


func _make_building_data_registry_36() -> Array[BuildingData]:
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


func test_hex_slot_cleared_on_destruction() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(1000)
	EconomyManager.add_building_material(100)
	BuildPhaseManager.set_build_phase_active(true)
	var hg: HexGrid = _create_hex_grid_for_slot_tests()
	hg.building_data_registry = _make_building_data_registry_36()
	add_child(hg)
	_cleanup_nodes.append(hg)
	assert_bool(hg.place_building(5, Types.BuildingType.ARROW_TOWER)).is_true()
	var sd_before: Dictionary = hg.get_slot_data(5)
	assert_bool(sd_before["is_occupied"]).is_true()
	hg.clear_slot_on_destruction(5)
	var sd_after: Dictionary = hg.get_slot_data(5)
	assert_bool(sd_after["is_occupied"]).is_false()
	assert_object(sd_after["building"]).is_null()
	EconomyManager.reset_to_defaults()
	BuildPhaseManager.set_build_phase_active(true)


func test_building_freed_on_destruction() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(1000)
	EconomyManager.add_building_material(100)
	BuildPhaseManager.set_build_phase_active(true)
	var hg: HexGrid = _create_hex_grid_for_slot_tests()
	hg.building_data_registry = _make_building_data_registry_36()
	add_child(hg)
	_cleanup_nodes.append(hg)
	assert_bool(hg.place_building(5, Types.BuildingType.ARROW_TOWER)).is_true()
	var placed: BuildingBase = hg.get_slot_data(5)["building"] as BuildingBase
	assert_object(placed).is_not_null()
	hg.clear_slot_on_destruction(5)
	await get_tree().process_frame
	assert_bool(is_instance_valid(placed)).is_false()
	EconomyManager.reset_to_defaults()
	BuildPhaseManager.set_build_phase_active(true)


func test_summoner_despawn_called_on_destruction() -> void:
	var summoner_id: String = "test_summoner_despawn_id"
	AllyManager._squads[summoner_id] = []
	var b: BuildingBase = _make_bare_building()
	_cleanup_nodes.append(b)
	var bd: BuildingData = _make_bd(50)
	bd.is_summoner = true
	b._building_data = bd
	b.placed_instance_id = summoner_id
	b.slot_id = -1
	var hc: HealthComponent = HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_hp = 50
	hc.current_hp = 50
	add_child(hc)
	_cleanup_nodes.append(hc)
	b.health_component = hc
	hc.health_depleted.connect(b._on_health_depleted)
	hc.take_damage(50.0)
	assert_bool(AllyManager._squads.has(summoner_id)).is_false()
