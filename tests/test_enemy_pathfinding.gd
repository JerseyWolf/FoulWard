class_name TestEnemyPathfinding
extends GdUnitTestSuite

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const INNER_RING_SLOT_COUNT: int = 6
const TEST_MAX_STEPS: int = 1800 # 30s at 60 physics ticks/s
const FLYING_STEPS: int = 1200 # 20s at 60 physics ticks/s

var _main: Node3D = null
var _hex_grid: HexGrid = null
var _wave_manager: WaveManager = null
var _tower: Tower = null
var _enemy_container: Node3D = null

func before_test() -> void:
	_main = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(_main)
	_hex_grid = _main.get_node("HexGrid") as HexGrid
	_wave_manager = _main.get_node("Managers/WaveManager") as WaveManager
	_tower = _main.get_node("Tower") as Tower
	_enemy_container = _main.get_node("EnemyContainer") as Node3D
	GameManager.start_new_game()
	EconomyManager.add_gold(20000)
	EconomyManager.add_building_material(2000)
	await get_tree().process_frame


func after_test() -> void:
	if is_instance_valid(_main):
		_main.queue_free()
	await get_tree().process_frame


func test_ground_enemy_paths_around_buildings_reaches_tower() -> void:
	for i: int in range(INNER_RING_SLOT_COUNT):
		assert_bool(_hex_grid.place_building(i, Types.BuildingType.ARROW_TOWER)).is_true()
	var hp_before: int = _tower.get_current_hp()
	_wave_manager.force_spawn_wave(1)
	await _run_steps(TEST_MAX_STEPS)
	assert_int(_tower.get_current_hp()).is_less(hp_before)


func test_ground_enemy_paths_to_tower_without_buildings_unchanged() -> void:
	_hex_grid.clear_all_buildings()
	var hp_before: int = _tower.get_current_hp()
	_wave_manager.force_spawn_wave(1)
	await _run_steps(TEST_MAX_STEPS)
	assert_int(_tower.get_current_hp()).is_less(hp_before)


func test_flying_enemy_ignores_building_obstacles() -> void:
	for i: int in range(INNER_RING_SLOT_COUNT):
		assert_bool(_hex_grid.place_building(i, Types.BuildingType.ARROW_TOWER)).is_true()
	var hp_before: int = _tower.get_current_hp()
	_wave_manager.force_spawn_wave(1)
	var flying_enemy: EnemyBase = await _wait_for_flying_enemy(300)
	assert_object(flying_enemy).is_not_null()
	var xz_before: Vector2 = Vector2(flying_enemy.global_position.x, flying_enemy.global_position.z)
	await _run_steps(FLYING_STEPS)
	var xz_after: Vector2 = Vector2(flying_enemy.global_position.x, flying_enemy.global_position.z)
	var radial_before: float = xz_before.length()
	var radial_after: float = xz_after.length()
	assert_float(radial_after).is_less(radial_before)
	assert_int(_tower.get_current_hp()).is_less(hp_before)


func test_enemy_paths_through_area_after_selling_building() -> void:
	assert_bool(_hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)).is_true()
	assert_bool(_hex_grid.place_building(1, Types.BuildingType.ARROW_TOWER)).is_true()
	assert_bool(_hex_grid.place_building(2, Types.BuildingType.ARROW_TOWER)).is_true()
	_wave_manager.force_spawn_wave(1)
	var constrained_enemy: EnemyBase = await _wait_for_ground_enemy(300)
	assert_object(constrained_enemy).is_not_null()
	await _run_steps(300)
	var constrained_distance: float = constrained_enemy.global_position.distance_to(Vector3.ZERO)

	assert_bool(_hex_grid.sell_building(1)).is_true()
	_hex_grid.clear_all_buildings()
	_wave_manager.force_spawn_wave(1)
	var open_enemy: EnemyBase = await _wait_for_ground_enemy(300)
	assert_object(open_enemy).is_not_null()
	await _run_steps(300)
	var open_distance: float = open_enemy.global_position.distance_to(Vector3.ZERO)
	assert_float(open_distance).is_less_equal(constrained_distance)


func test_enemy_stuck_near_building_eventually_reaches_tower() -> void:
	assert_bool(_hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)).is_true()
	assert_bool(_hex_grid.place_building(2, Types.BuildingType.ARROW_TOWER)).is_true()
	assert_bool(_hex_grid.place_building(4, Types.BuildingType.ARROW_TOWER)).is_true()
	var hp_before: int = _tower.get_current_hp()
	_wave_manager.force_spawn_wave(1)
	await _run_steps(1500)
	assert_int(_tower.get_current_hp()).is_less(hp_before)


func _run_steps(steps: int) -> void:
	for _i: int in range(steps):
		await get_tree().physics_frame


func _wait_for_ground_enemy(max_steps: int) -> EnemyBase:
	for _i: int in range(max_steps):
		await get_tree().physics_frame
		for child: Node in _enemy_container.get_children():
			var enemy: EnemyBase = child as EnemyBase
			if enemy != null and not enemy.get_enemy_data().is_flying:
				return enemy
	return null


func _wait_for_flying_enemy(max_steps: int) -> EnemyBase:
	for _i: int in range(max_steps):
		await get_tree().physics_frame
		for child: Node in _enemy_container.get_children():
			var enemy: EnemyBase = child as EnemyBase
			if enemy != null and enemy.get_enemy_data().is_flying:
				return enemy
	return null


func test_ground_enemy_position_changes_over_time_dense_layout() -> void:
	for i: int in range(INNER_RING_SLOT_COUNT):
		assert_bool(_hex_grid.place_building(i, Types.BuildingType.ARROW_TOWER)).is_true()
	_wave_manager.force_spawn_wave(1)
	var enemy: EnemyBase = await _wait_for_ground_enemy(400)
	assert_object(enemy).is_not_null()
	var p0: Vector3 = enemy.global_position
	await _run_steps(600)
	var p1: Vector3 = enemy.global_position
	assert_float(p0.distance_to(p1)).is_greater(0.05)

