## TODO: add before_test() isolation — see testing SKILL
# GdUnit4 — SimBot balance sweep + CombatStatsTracker run labels (Prompt 51).
extends GdUnitTestSuite


func test_combat_stats_tracker_begin_end_run() -> void:
	CombatStatsTracker.begin_run("mission_01", "balanced")
	CombatStatsTracker.register_building(
			"inst_balance_test",
			"arrow_tower",
			"SMALL",
			1,
			0,
			50,
			0
	)
	CombatStatsTracker.end_run()
	var run_id: String = CombatStatsTracker._run_id
	var path: String = "user://simbot/runs/%s/building_summary.csv" % run_id
	assert_bool(FileAccess.file_exists(path)).is_true()


func test_all_buildings_have_balance_status_string() -> void:
	var dir := DirAccess.open("res://resources/building_data/")
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var bd: BuildingData = load("res://resources/building_data/%s" % fname) as BuildingData
			if bd != null:
				assert_str(bd.balance_status).is_not_empty()
		fname = dir.get_next()
	dir.list_dir_end()
