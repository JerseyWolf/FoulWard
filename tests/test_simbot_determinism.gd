## TODO: add before_test() isolation — see testing SKILL
# test_simbot_determinism.gd
# GdUnit4 test suite for SimBot determinism (Phase 2).

class_name TestSimBotDeterminism
extends GdUnitTestSuite

func test_simbot_is_deterministic_for_fixed_seed() -> void:
	# Arrange
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var seed_value: int = 999

	# Act (run #1)
	var main1: Node = main_scene.instantiate()
	get_tree().root.add_child(main1)

	var simbot1: SimBot = SimBot.new()
	get_tree().root.add_child(simbot1)

	var tower1: Tower = main1.get_node_or_null("Tower") as Tower
	if tower1 != null:
		# Stabilize tower shot patterns that include local RNG perturbations.
		tower1._shot_rng.seed = seed_value

	var result1: Dictionary = await simbot1.run_single("BALANCED_DEFAULT", 0, seed_value)

	main1.queue_free()
	simbot1.queue_free()
	await get_tree().process_frame

	# Act (run #2)
	var main2: Node = main_scene.instantiate()
	get_tree().root.add_child(main2)

	var simbot2: SimBot = SimBot.new()
	get_tree().root.add_child(simbot2)

	var tower2: Tower = main2.get_node_or_null("Tower") as Tower
	if tower2 != null:
		tower2._shot_rng.seed = seed_value

	var result2: Dictionary = await simbot2.run_single("BALANCED_DEFAULT", 0, seed_value)

	# Assert
	assert_int(int(result1.get("waves_cleared", 0))).is_equal(int(result2.get("waves_cleared", 0)))
	assert_int(int(result1.get("enemies_killed", 0))).is_equal(
		int(result2.get("enemies_killed", 0))
	)

	main2.queue_free()
	simbot2.queue_free()
	await get_tree().process_frame

