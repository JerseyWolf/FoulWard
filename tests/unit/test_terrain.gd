## TODO: add before_test() isolation — see testing SKILL
## tests/unit/test_terrain.gd
## Unit tests for TerrainZone, EnemyBase terrain speed, NavMeshManager, TerritoryData terrain_type.

class_name TestTerrain
extends GdUnitTestSuite

const _TerrainZoneScript: GDScript = preload("res://scripts/terrain_zone.gd")
const _CountingNavRegionScript: GDScript = preload("res://tests/support/counting_navigation_region.gd")


func after_test() -> void:
	NavMeshManager.register_region(null)
	NavMeshManager._baking = false
	NavMeshManager._queue_bake = false


func test_terrain_zone_slows_enemy() -> void:
	var zone: Node = _TerrainZoneScript.new()
	zone.set("speed_multiplier", 0.5)
	add_child(zone)
	var mock_enemy: CharacterBody3D = CharacterBody3D.new()
	mock_enemy.add_to_group("enemies")
	add_child(mock_enemy)
	var monitor := monitor_signals(SignalBus, false)
	zone.body_entered.emit(mock_enemy)
	await assert_signal(monitor).is_emitted("enemy_entered_terrain_zone", [mock_enemy, 0.5])
	mock_enemy.queue_free()
	zone.queue_free()


func test_enemy_speed_restored_on_exit() -> void:
	var zone: Node = _TerrainZoneScript.new()
	zone.set("speed_multiplier", 0.5)
	add_child(zone)
	var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	add_child(enemy)
	var ed: EnemyData = load("res://resources/enemy_data/orc_grunt.tres") as EnemyData
	enemy.initialize(ed)
	var mon_enter := monitor_signals(SignalBus, false)
	zone.body_entered.emit(enemy)
	await assert_signal(mon_enter).is_emitted("enemy_entered_terrain_zone", [enemy, 0.5])
	var mon_exit := monitor_signals(SignalBus, false)
	zone.body_exited.emit(enemy)
	await assert_signal(mon_exit).is_emitted("enemy_exited_terrain_zone", [enemy, 0.5])
	assert_float(enemy._active_terrain_speed_multiplier).is_equal(1.0)
	enemy.queue_free()
	zone.queue_free()


func test_overlapping_zones_take_minimum() -> void:
	var z1: Node = _TerrainZoneScript.new()
	z1.set("speed_multiplier", 0.7)
	var z2: Node = _TerrainZoneScript.new()
	z2.set("speed_multiplier", 0.4)
	add_child(z1)
	add_child(z2)
	var enemy_scene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	add_child(enemy)
	var ed: EnemyData = load("res://resources/enemy_data/orc_grunt.tres") as EnemyData
	enemy.initialize(ed)
	z1.body_entered.emit(enemy)
	z2.body_entered.emit(enemy)
	assert_float(enemy._active_terrain_speed_multiplier).is_equal(0.4)
	enemy.queue_free()
	z1.queue_free()
	z2.queue_free()


func test_navmeshmanager_queues_rebake() -> void:
	var mock: NavigationRegion3D = _CountingNavRegionScript.new() as NavigationRegion3D
	add_child(mock)
	NavMeshManager.register_region(mock)
	NavMeshManager._baking = true
	var calls_before: int = mock.bake_calls
	NavMeshManager.request_rebake()
	assert_bool(NavMeshManager._queue_bake).is_true()
	assert_int(mock.bake_calls).is_equal(calls_before)
	mock.queue_free()


func test_terrain_type_field_on_territory_data() -> void:
	var td: TerritoryData = TerritoryData.new()
	td.terrain_type = Types.TerrainType.SWAMP
	assert_int(td.terrain_type).is_equal(Types.TerrainType.SWAMP)
