## Headless tests for Archer Barracks pulse buff and Shield Generator tower shield (Audit 6 §1.3).
class_name TestBuildingSpecials
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	BuildPhaseManager.set_build_phase_active(true)


func after_test() -> void:
	for child: Node in get_children():
		if is_instance_valid(child) and not child is Timer:
			child.queue_free()
	await get_tree().process_frame


func test_archer_barracks_pulse_adds_strike_bonus() -> void:
	var bd: BuildingData = load("res://resources/building_data/archer_barracks.tres") as BuildingData
	var bscene: PackedScene = load("res://scenes/buildings/building_base.tscn")
	var building: BuildingBase = bscene.instantiate() as BuildingBase
	add_child(building)
	building.global_position = Vector3.ZERO
	building.initialize(bd)
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: AllyBase = ally_scene.instantiate() as AllyBase
	var ad: AllyData = load("res://resources/ally_data/ally_melee_generic.tres") as AllyData
	add_child(ally)
	ally.global_position = Vector3(5.0, 0.0, 0.0)
	ally.initialize_ally_data(ad)
	for _i: int in range(400):
		building._physics_process(0.016)
	assert_that(ally.get_barracks_strike_bonus()).is_greater(0.0)
	ally.queue_free()
	building.queue_free()
	await get_tree().process_frame


func test_shield_generator_pulses_tower_shield() -> void:
	var bd: BuildingData = load("res://resources/building_data/shield_generator.tres") as BuildingData
	var bscene: PackedScene = load("res://scenes/buildings/building_base.tscn")
	var building: BuildingBase = bscene.instantiate() as BuildingBase
	add_child(building)
	building.initialize(bd)
	var tower_scene: PackedScene = load("res://scenes/tower/tower.tscn")
	var tower: Tower = tower_scene.instantiate() as Tower
	add_child(tower)
	for _i: int in range(200):
		building._physics_process(0.016)
	assert_that(tower.get_spell_shield_hp()).is_greater(0.0)
	tower.queue_free()
	building.queue_free()
	await get_tree().process_frame
