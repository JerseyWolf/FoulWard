# test_simbot_logging.gd
# GdUnit4 test suite for SimBot CSV batch logging (Phase 2).

class_name TestSimBotLogging
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	CampaignManager.current_day = 1
	GameManager.game_state = Types.GameState.MAIN_MENU


func test_simbot_writes_csv_log_for_batch() -> void:
	# Arrange
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	get_tree().root.add_child(main)

	var simbot: SimBot = SimBot.new()
	get_tree().root.add_child(simbot)

	var csv_path: String = "user://simbot_logs/test_simbot_balance_log_%d.csv" % Time.get_ticks_msec()

	# Act
	await simbot.run_batch("BALANCED_DEFAULT", 2, 123, csv_path)

	# Assert
	assert_bool(FileAccess.file_exists(csv_path)).is_true()
	var file: FileAccess = FileAccess.open(csv_path, FileAccess.READ)
	assert_object(file).is_not_null()

	var lines: Array[String] = []
	while file != null and not file.eof_reached():
		lines.append(file.get_line())
	file.close()

	assert_int(lines.size()).is_greater_equal(3)

	main.queue_free()
	simbot.queue_free()
	await get_tree().process_frame


func test_csv_rows_deterministic_for_same_seed() -> void:
	RelationshipManager.reload_from_resources()
	# Unique path avoids stale rows from interrupted full-suite runs touching a fixed filename.
	var csv_path: String = "user://simbot/logs/audit5_determinism_%d.csv" % Time.get_ticks_msec()
	var log_dir: DirAccess = DirAccess.open("user://simbot/logs/")
	if log_dir != null and log_dir.file_exists(csv_path.get_file()):
		log_dir.remove(csv_path.get_file())

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	get_tree().root.add_child(main)
	var simbot: SimBot = SimBot.new()
	get_tree().root.add_child(simbot)

	await simbot.run_batch("BALANCED_DEFAULT", 2, 4242, csv_path)
	await simbot.run_batch("BALANCED_DEFAULT", 2, 4242, csv_path)

	assert_bool(FileAccess.file_exists(csv_path)).is_true()
	var f: FileAccess = FileAccess.open(csv_path, FileAccess.READ)
	assert_object(f).is_not_null()
	var lines: Array[String] = []
	while not f.eof_reached():
		lines.append(f.get_line())
	f.close()
	assert_int(lines.size()).is_greater_equal(5)
	var header: PackedStringArray = lines[0].split(",")
	var seed_col: int = header.find("seed_value")
	assert_int(seed_col).is_greater_equal(0)
	var row_a: PackedStringArray = lines[1].split(",")
	var row_b: PackedStringArray = lines[3].split(",")
	assert_int(row_a.size()).is_greater(seed_col)
	assert_int(row_b.size()).is_greater(seed_col)
	assert_str(row_a[seed_col]).is_equal(row_b[seed_col])
	assert_str(row_a[seed_col]).is_equal("4242")

	main.queue_free()
	simbot.queue_free()
	await get_tree().process_frame

