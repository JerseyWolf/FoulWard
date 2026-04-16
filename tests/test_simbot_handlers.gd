# test_simbot_handlers.gd — SimBot AUDIT 6 §6.1–6.2 handler and difficulty-fit tests (headless-safe).

class_name TestSimBotHandlers
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()


func after_test() -> void:
	for child: Node in get_children():
		if is_instance_valid(child) and not child is Timer:
			child.queue_free()
	await get_tree().process_frame


func test_on_mission_started_resets_counters() -> void:
	var bot: SimBot = SimBot.new()
	add_child(bot)
	bot._current_run_waves_cleared = 7
	bot._current_run_enemies_killed = 42
	bot._current_run_spell_casts = 3
	bot._current_run_building_material_spent = 99
	bot._enemies_killed_wave_counter = 5
	bot._handler_waves_cleared = 2
	bot._on_mission_started(1)
	assert_int(bot._current_run_waves_cleared).is_equal(0)
	assert_int(bot._current_run_enemies_killed).is_equal(0)
	assert_int(bot._current_run_spell_casts).is_equal(0)
	assert_int(bot._current_run_building_material_spent).is_equal(0)
	assert_int(bot._enemies_killed_wave_counter).is_equal(0)
	assert_int(bot._handler_waves_cleared).is_equal(0)
	assert_bool(bot._in_combat).is_true()
	bot.queue_free()
	await get_tree().process_frame


func test_on_game_state_changed_loss_ends_run() -> void:
	var bot: SimBot = SimBot.new()
	add_child(bot)
	bot.activate(Types.StrategyProfile.BALANCED)
	assert_bool(bot.is_active).is_true()
	bot._on_game_state_changed(Types.GameState.COMBAT, Types.GameState.GAME_OVER)
	assert_bool(bot.is_active).is_false()
	bot.queue_free()
	await get_tree().process_frame


func test_compute_difficulty_fit_perfect_match() -> void:
	var bot: SimBot = SimBot.new()
	add_child(bot)
	var profile: StrategyProfile = load(
			"res://resources/strategyprofiles/strategy_balanced_default.tres"
	) as StrategyProfile
	assert_object(profile).is_not_null()
	profile.difficulty_target = 0.5
	var entries: Array[Dictionary] = [{"result": "WIN"}, {"result": "LOSS"}]
	bot._last_batch_entries = entries
	var fit: float = bot.compute_difficulty_fit(profile)
	assert_float(fit).is_equal(1.0)
	bot.queue_free()
	await get_tree().process_frame


func test_compute_difficulty_fit_empty_log_returns_zero() -> void:
	var bot: SimBot = SimBot.new()
	add_child(bot)
	var profile: StrategyProfile = load(
			"res://resources/strategyprofiles/strategy_balanced_default.tres"
	) as StrategyProfile
	assert_object(profile).is_not_null()
	bot._last_batch_entries = []
	assert_float(bot.compute_difficulty_fit(profile)).is_equal(0.0)
	bot.queue_free()
	await get_tree().process_frame
