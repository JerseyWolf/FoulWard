# tests/test_building_base.gd
# GdUnit4 test suite for BuildingBase.
# Tests initialization, targeting, combat process, upgrade, and effective stats.

class_name TestBuildingBase
extends GdUnitTestSuite


func _make_building_data(
		building_type: Types.BuildingType = Types.BuildingType.ARROW_TOWER,
		damage: float = 20.0,
		upgraded_damage: float = 35.0,
		fire_rate: float = 1.0,
		attack_range: float = 15.0,
		upgraded_range: float = 18.0,
		targets_air: bool = false,
		targets_ground: bool = true,
		is_locked: bool = false) -> BuildingData:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = building_type
	bd.display_name = "Test Building"
	bd.gold_cost = 50
	bd.material_cost = 2
	bd.upgrade_gold_cost = 75
	bd.upgrade_material_cost = 3
	bd.damage = damage
	bd.upgraded_damage = upgraded_damage
	bd.fire_rate = fire_rate
	bd.attack_range = attack_range
	bd.upgraded_range = upgraded_range
	bd.damage_type = Types.DamageType.PHYSICAL
	bd.targets_air = targets_air
	bd.targets_ground = targets_ground
	bd.is_locked = is_locked
	bd.color = Color.GRAY
	return bd


func _make_bare_building(bd: BuildingData) -> BuildingBase:
	var building: BuildingBase = BuildingBase.new()
	building._building_data = bd
	building._is_upgraded = false
	building._attack_timer = 0.0
	building._current_target = null
	return building


func after_test() -> void:
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# Initialize tests
# ---------------------------------------------------------------------------

func test_initialize_sets_data() -> void:
	var bd: BuildingData = _make_building_data()
	var building: BuildingBase = _make_bare_building(bd)
	assert_object(building.get_building_data()).is_equal(bd)
	assert_bool(building.is_upgraded).is_false()


func test_initialize_sets_is_upgraded_false() -> void:
	var bd: BuildingData = _make_building_data()
	var building: BuildingBase = _make_bare_building(bd)
	assert_bool(building.is_upgraded).is_false()

# ---------------------------------------------------------------------------
# Effective stats tests
# ---------------------------------------------------------------------------

func test_get_effective_damage_returns_base_when_not_upgraded() -> void:
	var bd: BuildingData = _make_building_data(Types.BuildingType.ARROW_TOWER, 20.0, 35.0)
	var building: BuildingBase = _make_bare_building(bd)
	assert_float(building.get_effective_damage()).is_equal(20.0)


func test_get_effective_damage_returns_upgraded_when_upgraded() -> void:
	var bd: BuildingData = _make_building_data(Types.BuildingType.ARROW_TOWER, 20.0, 35.0)
	var building: BuildingBase = _make_bare_building(bd)
	building.upgrade()
	assert_float(building.get_effective_damage()).is_equal(35.0)


func test_get_effective_range_returns_base_when_not_upgraded() -> void:
	var bd: BuildingData = _make_building_data(
		Types.BuildingType.ARROW_TOWER, 20.0, 35.0, 1.0, 15.0, 18.0)
	var building: BuildingBase = _make_bare_building(bd)
	assert_float(building.get_effective_range()).is_equal(15.0)


func test_get_effective_range_returns_upgraded_when_upgraded() -> void:
	var bd: BuildingData = _make_building_data(
		Types.BuildingType.ARROW_TOWER, 20.0, 35.0, 1.0, 15.0, 18.0)
	var building: BuildingBase = _make_bare_building(bd)
	building.upgrade()
	assert_float(building.get_effective_range()).is_equal(18.0)

# ---------------------------------------------------------------------------
# Upgrade tests
# ---------------------------------------------------------------------------

func test_upgrade_sets_is_upgraded_true() -> void:
	var bd: BuildingData = _make_building_data()
	var building: BuildingBase = _make_bare_building(bd)
	building.upgrade()
	assert_bool(building.is_upgraded).is_true()

# ---------------------------------------------------------------------------
# Combat process guard tests
# ---------------------------------------------------------------------------

func test_combat_process_skips_when_fire_rate_zero() -> void:
	var bd: BuildingData = _make_building_data(
		Types.BuildingType.SHIELD_GENERATOR, 0.0, 0.0, 0.0, 0.0, 0.0)
	var building: BuildingBase = _make_bare_building(bd)
	building._combat_process(0.016)
	assert_bool(building._current_target == null).is_true()


func test_combat_process_skips_when_building_data_null() -> void:
	var building: BuildingBase = BuildingBase.new()
	building._building_data = null
	building._combat_process(0.016)
	assert_bool(building._current_target == null).is_true()

# ---------------------------------------------------------------------------
# _find_target tests
# ---------------------------------------------------------------------------

func test_find_target_returns_null_when_no_enemies() -> void:
	var bd: BuildingData = _make_building_data()
	var building: BuildingBase = BuildingBase.new()
	building._building_data = bd
	add_child(building)
	await get_tree().process_frame
	var target: EnemyBase = building._find_target()
	assert_object(target).is_null()
	building.queue_free()


func test_find_target_returns_null_no_flying_for_ground_building() -> void:
	var bd: BuildingData = _make_building_data(
		Types.BuildingType.ARROW_TOWER, 20.0, 35.0, 1.0, 15.0, 18.0,
		false, true)
	var building: BuildingBase = BuildingBase.new()
	building._building_data = bd
	add_child(building)
	await get_tree().process_frame
	var target: EnemyBase = building._find_target()
	assert_object(target).is_null()
	building.queue_free()


func test_anti_air_bolt_find_target_returns_null_no_flying() -> void:
	var bd: BuildingData = _make_building_data(
		Types.BuildingType.ANTI_AIR_BOLT, 30.0, 50.0, 1.2, 20.0, 24.0,
		true, false)
	var building: BuildingBase = BuildingBase.new()
	building._building_data = bd
	add_child(building)
	await get_tree().process_frame
	var target: EnemyBase = building._find_target()
	assert_object(target).is_null()
	building.queue_free()

# ---------------------------------------------------------------------------
# Attack timer tests
# ---------------------------------------------------------------------------

func test_combat_process_decrements_attack_timer() -> void:
	var bd: BuildingData = _make_building_data(
		Types.BuildingType.ARROW_TOWER, 20.0, 35.0, 1.0, 15.0, 18.0)
	var building: BuildingBase = _make_bare_building(bd)
	building._attack_timer = 0.5
	building._combat_process(0.3)
	assert_float(building._attack_timer).is_equal_approx(0.2, 0.001)


func test_building_scene_has_collision_and_navigation_obstacle() -> void:
	var scene: PackedScene = load("res://scenes/buildings/building_base.tscn") as PackedScene
	var building: BuildingBase = scene.instantiate() as BuildingBase
	add_child(building)
	await get_tree().process_frame
	var collision_body: StaticBody3D = building.get_node("BuildingCollision") as StaticBody3D
	var obstacle: NavigationObstacle3D = building.get_node("NavigationObstacle") as NavigationObstacle3D
	assert_object(collision_body).is_not_null()
	assert_object(obstacle).is_not_null()
	assert_int(collision_body.collision_layer).is_equal(8)
	assert_int(collision_body.collision_mask).is_equal(2)
	building.queue_free()

