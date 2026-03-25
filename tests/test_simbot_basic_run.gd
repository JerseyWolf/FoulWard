# test_simbot_basic_run.gd
# GdUnit4 test suite for a basic SimBot headless run (Phase 2).

class_name TestSimBotBasicRun
extends GdUnitTestSuite

func test_simbot_can_run_and_place_buildings() -> void:
	# Arrange
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	get_tree().root.add_child(main)

	var simbot: SimBot = SimBot.new()
	get_tree().root.add_child(simbot)

	# Act
	var result: Dictionary = await simbot.run_single("BALANCED_DEFAULT", 0, 123)

	# Assert
	var any_built: bool = false
	for btype: Types.BuildingType in Types.BuildingType.values():
		var key: String = "buildings_built_%s" % str(btype)
		if result.has(key) and int(result[key]) > 0:
			any_built = true
			break
	assert_bool(any_built).is_true()

	assert_int(int(result.get("total_enemies_killed", 0))).is_greater_equal(0)

	main.queue_free()
	simbot.queue_free()
	await get_tree().process_frame

