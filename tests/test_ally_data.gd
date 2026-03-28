# test_ally_data.gd — AllyData resource defaults and placeholder .tres loads.
# Credit: GdUnit4 — https://mikeschulze.github.io/gdUnit4/

class_name TestAllyData
extends GdUnitTestSuite

const ALLY_DATA_SCRIPT: GDScript = preload("res://scripts/resources/ally_data.gd")


func test_ally_data_defaults_are_valid() -> void:
	var data: Resource = ALLY_DATA_SCRIPT.new()
	assert_int(data.get("max_hp")).is_greater_equal(0)
	assert_float(float(data.get("move_speed"))).is_greater_equal(0.0)
	assert_float(float(data.get("basic_attack_damage"))).is_greater_equal(0.0)
	assert_float(float(data.get("attack_range"))).is_greater_equal(0.0)
	assert_float(float(data.get("attack_cooldown"))).is_greater(0.0)

	var valid_classes: Array = [
		Types.AllyClass.MELEE,
		Types.AllyClass.RANGED,
		Types.AllyClass.SUPPORT,
	]
	assert_bool(valid_classes.has(data.get("ally_class"))).is_true()

	var valid_pri: Array = [
		Types.TargetPriority.CLOSEST,
		Types.TargetPriority.HIGHEST_HP,
		Types.TargetPriority.FLYING_FIRST,
		Types.TargetPriority.LOWEST_HP,
	]
	assert_bool(valid_pri.has(data.get("preferred_targeting"))).is_true()


func test_ally_data_placeholder_resources_load() -> void:
	var dir: DirAccess = DirAccess.open("res://resources/ally_data/")
	assert_object(dir).is_not_null()
	var err: Error = dir.list_dir_begin()
	assert_int(err).is_equal(OK)
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: Resource = load("res://resources/ally_data/%s" % file_name)
			var data: Resource = res
			assert_object(data).is_not_null()
			assert_that(str(data.get("ally_id"))).is_not_empty()
			assert_int(int(data.get("max_hp"))).is_greater(0)
			assert_float(float(data.get("move_speed"))).is_greater(0.0)
			assert_float(float(data.get("basic_attack_damage"))).is_greater(0.0)
			assert_float(float(data.get("attack_cooldown"))).is_greater(0.0)
			var pri: Variant = data.get("preferred_targeting")
			var valid_pri2: Array = [
				Types.TargetPriority.CLOSEST,
				Types.TargetPriority.HIGHEST_HP,
				Types.TargetPriority.FLYING_FIRST,
				Types.TargetPriority.LOWEST_HP,
			]
			assert_bool(valid_pri2.has(pri)).is_true()
		file_name = dir.get_next()
	dir.list_dir_end()
