# GdUnit4 — Parametric content validation for BuildingData / EnemyData .tres (Prompt 50).
extends GdUnitTestSuite


func test_all_building_data_invariants() -> void:
	var dir := DirAccess.open("res://resources/building_data/")
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	var checked: int = 0
	while fname != "":
		if fname.ends_with(".tres"):
			var res: Resource = load("res://resources/building_data/" + fname)
			assert_object(res).is_not_null()
			var bd: BuildingData = res as BuildingData
			assert_object(bd).is_not_null()
			assert_str(bd.display_name).is_not_empty()
			assert_int(bd.gold_cost).is_greater(0)
			assert_bool(["SMALL", "MEDIUM", "LARGE"].has(bd.size_class)).is_true()
			assert_bool(
					[
						"UNTESTED",
						"BASELINE",
						"OVERTUNED",
						"UNDERTUNED",
						"CUT_CAMPAIGN_1",
					].has(bd.balance_status)
			).is_true()
			if bd.is_summoner:
				assert_int(bd.summon_squad_size).is_greater(0)
			if bd.is_aura:
				assert_float(bd.aura_radius).is_greater(0.0)
			if bd.is_healer:
				assert_float(bd.heal_radius).is_greater(0.0)
			checked += 1
		fname = dir.get_next()
	assert_int(checked).is_equal(36)


func test_all_enemy_data_invariants() -> void:
	var dir := DirAccess.open("res://resources/enemy_data/")
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	var checked: int = 0
	while fname != "":
		if fname.ends_with(".tres"):
			var res: Resource = load("res://resources/enemy_data/" + fname)
			assert_object(res).is_not_null()
			var ed: EnemyData = res as EnemyData
			assert_object(ed).is_not_null()
			assert_str(ed.display_name).is_not_empty()
			assert_int(ed.max_hp).is_greater(0)
			assert_float(ed.move_speed).is_greater(0.0)
			assert_int(ed.tier).is_between(1, 5)
			assert_int(ed.point_cost).is_greater(0)
			assert_bool(ed.wave_tags.size() > 0).is_true()
			assert_bool(
					[
						"UNTESTED",
						"BASELINE",
						"OVERTUNED",
						"UNDERTUNED",
						"CUT_CAMPAIGN_1",
					].has(ed.balance_status)
			).is_true()
			checked += 1
		fname = dir.get_next()
	assert_int(checked).is_equal(30)


func test_building_type_enum_coverage() -> void:
	var all_types: Array = Types.BuildingType.values()
	assert_int(all_types.size()).is_equal(36)


func test_enemy_type_enum_coverage() -> void:
	var all_types: Array = Types.EnemyType.values()
	assert_int(all_types.size()).is_equal(30)
