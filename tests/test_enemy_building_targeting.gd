## test_enemy_building_targeting.gd
## GdUnit4 tests for EnemyBase building-targeting logic (prefer_building_targets flag).

class_name TestEnemyBuildingTargeting
extends GdUnitTestSuite

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_enemy_data(prefer: bool, radius: float = 50.0) -> EnemyData:
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.GOBLIN
	ed.display_name = "TestEnemy"
	ed.max_hp = 100
	ed.move_speed = 3.0
	ed.damage = 5
	ed.attack_range = 1.5
	ed.attack_cooldown = 1.0
	ed.prefer_building_targets = prefer
	ed.building_detection_radius = radius
	return ed


func _make_enemy(ed: EnemyData) -> EnemyBase:
	var e: EnemyBase = EnemyBase.new()
	e._enemy_data = ed
	e._attack_timer = 0.0
	e._is_attacking = false
	e._current_building_target = null
	return e


func _make_building_data(targeted: bool, max_hp: int = 100) -> BuildingData:
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
	bd.can_be_targeted_by_enemies = targeted
	return bd


## Creates a BuildingBase with a live HealthComponent child in the given group.
func _make_targetable_building(targeted: bool, max_hp: int = 100) -> BuildingBase:
	var b: BuildingBase = BuildingBase.new()
	b._building_data = _make_building_data(targeted, max_hp)
	if max_hp > 0:
		var hc: HealthComponent = HealthComponent.new()
		hc.max_hp = max_hp
		hc.current_hp = max_hp
		b.add_child(hc)
		b.health_component = hc
	b.add_to_group("buildings")
	return b


var _cleanup_nodes: Array[Node] = []


func after_test() -> void:
	for n: Node in _cleanup_nodes:
		if is_instance_valid(n):
			n.remove_from_group("buildings")
			n.queue_free()
	_cleanup_nodes.clear()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

func test_enemy_ignores_buildings_when_flag_false() -> void:
	var ed: EnemyData = _make_enemy_data(false)
	var enemy: EnemyBase = _make_enemy(ed)
	_cleanup_nodes.append(enemy)
	# _try_building_target_attack returns false immediately when flag is off
	var result: bool = enemy._try_building_target_attack(0.1)
	assert_bool(result).is_false()


func test_enemy_finds_building_when_flag_true() -> void:
	# Arrange: enemy in scene tree so get_tree() works; building nearby in "buildings" group
	var ed: EnemyData = _make_enemy_data(true, 100.0)
	var enemy: EnemyBase = _make_enemy(ed)
	add_child(enemy)
	_cleanup_nodes.append(enemy)

	var building: BuildingBase = _make_targetable_building(true, 100)
	add_child(building)
	_cleanup_nodes.append(building)

	var found: BuildingBase = enemy._find_building_target()
	assert_object(found).is_not_null()
	assert_object(found).is_equal(building)


func test_enemy_ignores_non_targetable_building() -> void:
	var ed: EnemyData = _make_enemy_data(true, 100.0)
	var enemy: EnemyBase = _make_enemy(ed)
	add_child(enemy)
	_cleanup_nodes.append(enemy)

	# Building with can_be_targeted_by_enemies = false
	var building: BuildingBase = _make_targetable_building(false, 100)
	add_child(building)
	_cleanup_nodes.append(building)

	var found: BuildingBase = enemy._find_building_target()
	assert_object(found).is_null()


func test_enemy_ignores_dead_building() -> void:
	var ed: EnemyData = _make_enemy_data(true, 100.0)
	var enemy: EnemyBase = _make_enemy(ed)
	add_child(enemy)
	_cleanup_nodes.append(enemy)

	var building: BuildingBase = _make_targetable_building(true, 100)
	add_child(building)
	_cleanup_nodes.append(building)

	# Kill the building's HC so is_alive() returns false
	var hc: HealthComponent = building.get_node_or_null("HealthComponent") as HealthComponent
	if hc != null:
		hc.take_damage(9999.0)

	var found: BuildingBase = enemy._find_building_target()
	assert_object(found).is_null()


func test_enemy_ignores_building_outside_radius() -> void:
	# Tiny detection radius — building at default position (0,0,0) is not within radius
	# if enemy is placed far away
	var ed: EnemyData = _make_enemy_data(true, 1.0)  # 1 unit radius
	var enemy: EnemyBase = _make_enemy(ed)
	enemy.position = Vector3(100.0, 0.0, 100.0)  # far from origin
	add_child(enemy)
	_cleanup_nodes.append(enemy)

	var building: BuildingBase = _make_targetable_building(true, 100)
	building.position = Vector3(0.0, 0.0, 0.0)
	add_child(building)
	_cleanup_nodes.append(building)

	var found: BuildingBase = enemy._find_building_target()
	assert_object(found).is_null()
