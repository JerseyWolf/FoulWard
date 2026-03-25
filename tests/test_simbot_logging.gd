# test_simbot_logging.gd
# GdUnit4 test suite for SimBot CSV batch logging (Phase 2).

class_name TestSimBotLogging
extends GdUnitTestSuite

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

