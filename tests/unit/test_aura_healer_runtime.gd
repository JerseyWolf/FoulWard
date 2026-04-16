# GdUnit4 — AuraManager + healer tower data (Prompt 08 / Prompt 50 fields).
extends GdUnitTestSuite

const _BuildingScene: PackedScene = preload("res://scenes/buildings/building_base.tscn")


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	AuraManager.clear_all_emitters_for_tests()


func after_test() -> void:
	for child: Node in get_children():
		if is_instance_valid(child) and not child is Timer:
			child.queue_free()
	AuraManager.clear_all_emitters_for_tests()


func test_warden_shrine_is_aura_damage_pct() -> void:
	var bd: BuildingData = load("res://resources/building_data/warden_shrine.tres") as BuildingData
	assert_object(bd).is_not_null()
	assert_bool(bd.is_aura).is_true()
	assert_str(bd.aura_effect_type).is_equal("damage_pct")
	assert_float(bd.aura_effect_value).is_equal(0.15)
	assert_float(bd.aura_radius).is_greater(0.0)


func test_alarm_totems_is_aura_speed_debuff() -> void:
	var bd: BuildingData = load("res://resources/building_data/alarm_totems.tres") as BuildingData
	assert_object(bd).is_not_null()
	assert_bool(bd.is_aura).is_true()
	assert_str(bd.aura_effect_type).is_equal("enemy_speed_pct")
	assert_float(bd.aura_effect_value).is_less(0.0)


func test_citadel_aura_is_largest_radius() -> void:
	var bd: BuildingData = load("res://resources/building_data/citadel_aura.tres") as BuildingData
	assert_object(bd).is_not_null()
	assert_float(bd.aura_radius).is_equal(18.0)


func test_field_medic_heals_allies() -> void:
	var bd: BuildingData = load("res://resources/building_data/field_medic.tres") as BuildingData
	assert_object(bd).is_not_null()
	assert_bool(bd.is_healer).is_true()
	assert_str(bd.heal_targets).is_equal("allies")
	assert_float(bd.heal_per_tick).is_greater(0.0)


func test_iron_cleric_heals_buildings() -> void:
	var bd: BuildingData = load("res://resources/building_data/iron_cleric.tres") as BuildingData
	assert_object(bd).is_not_null()
	assert_bool(bd.is_healer).is_true()
	assert_str(bd.heal_targets).is_equal("buildings")


func test_aura_manager_damage_pct_accumulates() -> void:
	var warden_data: BuildingData = load("res://resources/building_data/warden_shrine.tres") as BuildingData
	var arrow_data: BuildingData = load("res://resources/building_data/arrow_tower.tres") as BuildingData
	assert_object(warden_data).is_not_null()
	assert_object(arrow_data).is_not_null()

	var w1: BuildingBase = _BuildingScene.instantiate() as BuildingBase
	var w2: BuildingBase = _BuildingScene.instantiate() as BuildingBase
	var tower: BuildingBase = _BuildingScene.instantiate() as BuildingBase
	add_child(w1)
	add_child(w2)
	add_child(tower)

	w1.add_to_group("buildings")
	w2.add_to_group("buildings")
	tower.add_to_group("buildings")

	w1.global_position = Vector3(0.0, 0.0, 0.0)
	w2.global_position = Vector3(2.0, 0.0, 0.0)
	tower.global_position = Vector3(1.0, 0.0, 0.0)

	w1.initialize_with_economy(warden_data, 0, 0)
	w2.initialize_with_economy(warden_data, 1, 0)
	tower.initialize_with_economy(arrow_data, 2, 0)

	var bonus: float = AuraManager.get_damage_pct_bonus(tower)
	assert_float(bonus).is_equal(0.15)

	w1.queue_free()
	w2.queue_free()
	tower.queue_free()
