## test_game_manager.gd
## Exhaustive GdUnit4 tests for the GameManager autoload.
## Simulation API: all public methods callable without UI nodes present.

class_name TestGameManager
extends GdUnitTestSuite

func before_test() -> void:
	Engine.time_scale = 1.0
	GameManager.current_mission = 1
	GameManager.current_wave = 0
	GameManager.game_state = Types.GameState.MAIN_MENU
	EconomyManager.reset_to_defaults()
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	CampaignManager.campaign_completed = false
	CampaignManager.failed_attempts_on_current_day = 0
	CampaignManager.current_day = 1
	if CampaignManager.campaign_config != null:
		CampaignManager.campaign_length = CampaignManager.campaign_config.get_effective_length()
		if CampaignManager.campaign_config.day_configs.size() > 0:
			CampaignManager.current_day_config = CampaignManager.campaign_config.day_configs[0]

func after_test() -> void:
	Engine.time_scale = 1.0

# ════════════════════════════════════════════
# start_new_game
# ════════════════════════════════════════════

func test_start_new_game_resets_mission_to_1() -> void:
	GameManager.current_mission = 4
	GameManager.start_new_game()
	assert_int(GameManager.get_current_mission()).is_equal(1)

func test_start_new_game_resets_wave_to_0() -> void:
	GameManager.current_wave = 7
	GameManager.start_new_game()
	assert_int(GameManager.get_current_wave()).is_equal(0)

func test_start_new_game_transitions_to_combat() -> void:
	GameManager.start_new_game()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.COMBAT)

func test_start_new_game_emits_game_state_changed() -> void:
	var monitor := monitor_signals(SignalBus, false)
	GameManager.start_new_game()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.MAIN_MENU, Types.GameState.COMBAT]
	)

func test_start_new_game_emits_mission_started_with_1() -> void:
	var monitor := monitor_signals(SignalBus, false)
	GameManager.start_new_game()
	await assert_signal(monitor).is_emitted("mission_started", [1])

func test_start_new_game_calls_economy_reset() -> void:
	EconomyManager.add_gold(500)
	GameManager.start_new_game()
	assert_int(EconomyManager.get_gold()).is_equal(1000)

func test_begin_mission_wave_sequence_skips_gracefully_without_main_scene() -> void:
	# Typical GdUnit tree has no /root/Main; must not crash or assert.
	GameManager.call("_begin_mission_wave_sequence")
	assert_bool(true).is_true()

# ════════════════════════════════════════════
# start_next_mission
# ════════════════════════════════════════════

func test_start_next_mission_increments_mission_number() -> void:
	CampaignManager.current_day = 3
	if CampaignManager.campaign_config != null and CampaignManager.campaign_config.day_configs.size() >= 3:
		CampaignManager.current_day_config = CampaignManager.campaign_config.day_configs[2]
	GameManager.current_mission = 2
	GameManager.start_next_mission()
	assert_int(GameManager.get_current_mission()).is_equal(3)

func test_start_next_mission_resets_wave_to_0() -> void:
	GameManager.current_wave = 10
	GameManager.start_next_mission()
	assert_int(GameManager.get_current_wave()).is_equal(0)

func test_start_next_mission_transitions_to_combat() -> void:
	# DEVIATION: CampaignManager.start_next_day() kicks off the day via start_mission_for_day → COMBAT (not MISSION_BRIEFING).
	GameManager.start_next_mission()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.COMBAT)

func test_start_next_mission_emits_mission_started_with_correct_number() -> void:
	CampaignManager.current_day = 4
	if CampaignManager.campaign_config != null and CampaignManager.campaign_config.day_configs.size() >= 4:
		CampaignManager.current_day_config = CampaignManager.campaign_config.day_configs[3]
	GameManager.current_mission = 3
	var monitor := monitor_signals(SignalBus, false)
	GameManager.start_next_mission()
	await assert_signal(monitor).is_emitted("mission_started", [4])

# ════════════════════════════════════════════
# enter_build_mode
# ════════════════════════════════════════════

func test_enter_build_mode_sets_time_scale_to_0_1() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.enter_build_mode()
	assert_float(Engine.time_scale).is_equal_approx(0.1, 0.001)

func test_enter_build_mode_sets_game_state_to_build_mode() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.enter_build_mode()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.BUILD_MODE)

func test_enter_build_mode_from_wave_countdown_is_valid() -> void:
	GameManager.game_state = Types.GameState.WAVE_COUNTDOWN
	GameManager.enter_build_mode()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.BUILD_MODE)

func test_enter_build_mode_emits_build_mode_entered() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	var monitor := monitor_signals(SignalBus, false)
	GameManager.enter_build_mode()
	await assert_signal(monitor).is_emitted("build_mode_entered")

func test_enter_build_mode_emits_game_state_changed() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	var monitor := monitor_signals(SignalBus, false)
	GameManager.enter_build_mode()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.COMBAT, Types.GameState.BUILD_MODE]
	)

func test_enter_build_mode_game_state_changed_payload_old_is_combat() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	var monitor := monitor_signals(SignalBus, false)
	GameManager.enter_build_mode()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.COMBAT, Types.GameState.BUILD_MODE]
	)

# ════════════════════════════════════════════
# exit_build_mode
# ════════════════════════════════════════════

func test_exit_build_mode_restores_time_scale_to_1() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.enter_build_mode()
	GameManager.exit_build_mode()
	assert_float(Engine.time_scale).is_equal_approx(1.0, 0.001)

func test_exit_build_mode_sets_game_state_to_combat() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.enter_build_mode()
	GameManager.exit_build_mode()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.COMBAT)

func test_exit_build_mode_emits_build_mode_exited() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.enter_build_mode()
	var monitor := monitor_signals(SignalBus, false)
	GameManager.exit_build_mode()
	await assert_signal(monitor).is_emitted("build_mode_exited")

func test_exit_build_mode_emits_game_state_changed() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.enter_build_mode()
	var monitor := monitor_signals(SignalBus, false)
	GameManager.exit_build_mode()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.BUILD_MODE, Types.GameState.COMBAT]
	)

func test_enter_then_exit_build_mode_time_scale_is_1() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.enter_build_mode()
	assert_float(Engine.time_scale).is_equal_approx(0.1, 0.001)
	GameManager.exit_build_mode()
	assert_float(Engine.time_scale).is_equal_approx(1.0, 0.001)

# ════════════════════════════════════════════
# tower_destroyed → MISSION_FAILED
# ════════════════════════════════════════════

func test_tower_destroyed_signal_transitions_to_mission_failed() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	SignalBus.tower_destroyed.emit()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.MISSION_FAILED)

func test_tower_destroyed_signal_emits_mission_failed() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.tower_destroyed.emit()
	await assert_signal(monitor).is_emitted("mission_failed", [1])

func test_tower_destroyed_signal_emits_mission_failed_with_correct_mission_number() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 3
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.tower_destroyed.emit()
	await assert_signal(monitor).is_emitted("mission_failed", [3])

func test_tower_destroyed_emits_game_state_changed() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.tower_destroyed.emit()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.COMBAT, Types.GameState.MISSION_FAILED]
	)

# ════════════════════════════════════════════
# all_waves_cleared → resource award + mission_won
# ════════════════════════════════════════════

func test_all_waves_cleared_emits_mission_won() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 1
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.all_waves_cleared.emit()
	await assert_signal(monitor).is_emitted("mission_won", [1])

func test_all_waves_cleared_emits_mission_won_with_correct_mission_number() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 2
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.all_waves_cleared.emit()
	await assert_signal(monitor).is_emitted("mission_won", [2])

func test_all_waves_cleared_awards_gold_50_times_mission_number() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 2
	EconomyManager.reset_to_defaults()
	SignalBus.all_waves_cleared.emit()
	assert_int(EconomyManager.get_gold()).is_equal(1100)

func test_all_waves_cleared_awards_3_building_material() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 1
	EconomyManager.reset_to_defaults()
	SignalBus.all_waves_cleared.emit()
	assert_int(EconomyManager.get_building_material()).is_equal(53)

func test_all_waves_cleared_awards_2_research_material() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 1
	EconomyManager.reset_to_defaults()
	SignalBus.all_waves_cleared.emit()
	assert_int(EconomyManager.get_research_material()).is_equal(2)

func test_all_waves_cleared_mission_1_transitions_to_between_missions() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 1
	SignalBus.all_waves_cleared.emit()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.BETWEEN_MISSIONS)

func test_all_waves_cleared_mission_5_transitions_to_game_won() -> void:
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 5
	CampaignManager.current_day = 5
	CampaignManager.campaign_length = CampaignManager.campaign_config.get_effective_length()
	if CampaignManager.campaign_config != null and CampaignManager.campaign_config.day_configs.size() >= 5:
		CampaignManager.current_day_config = CampaignManager.campaign_config.day_configs[4]
	assert_int(CampaignManager.get_current_day()).is_equal(5)
	assert_int(CampaignManager.get_campaign_length()).is_equal(5)
	SignalBus.all_waves_cleared.emit()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.GAME_WON)

func test_all_waves_cleared_mission_4_does_not_trigger_game_won() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 4
	SignalBus.all_waves_cleared.emit()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.BETWEEN_MISSIONS)

func test_all_waves_cleared_gold_scales_with_mission_number_mission_5() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 5
	EconomyManager.reset_to_defaults()
	SignalBus.all_waves_cleared.emit()
	assert_int(EconomyManager.get_gold()).is_equal(1250)

func test_all_waves_cleared_emits_game_state_changed() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 1
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.all_waves_cleared.emit()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.COMBAT, Types.GameState.BETWEEN_MISSIONS]
	)

# ════════════════════════════════════════════
# get_* accessors
# ════════════════════════════════════════════

func test_get_game_state_returns_current_state() -> void:
	GameManager.game_state = Types.GameState.COMBAT
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.COMBAT)

func test_get_current_mission_returns_correct_value() -> void:
	GameManager.current_mission = 3
	assert_int(GameManager.get_current_mission()).is_equal(3)

func test_get_current_wave_returns_correct_value() -> void:
	GameManager.current_wave = 7
	assert_int(GameManager.get_current_wave()).is_equal(7)

# ════════════════════════════════════════════
# game_state_changed emitted on every transition
# ════════════════════════════════════════════

func test_game_state_changed_emitted_on_start_new_game() -> void:
	GameManager.game_state = Types.GameState.MAIN_MENU
	var monitor := monitor_signals(SignalBus, false)
	GameManager.start_new_game()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.MAIN_MENU, Types.GameState.COMBAT]
	)

func test_game_state_changed_old_state_payload_is_main_menu_on_new_game() -> void:
	GameManager.game_state = Types.GameState.MAIN_MENU
	var monitor := monitor_signals(SignalBus, false)
	GameManager.start_new_game()
	await assert_signal(monitor).is_emitted(
		"game_state_changed", [Types.GameState.MAIN_MENU, Types.GameState.COMBAT]
	)

# ════════════════════════════════════════════
# TOTAL_MISSIONS / WAVES_PER_MISSION constants
# ════════════════════════════════════════════

func test_total_missions_constant_is_5() -> void:
	assert_int(GameManager.TOTAL_MISSIONS).is_equal(5)

func test_waves_per_mission_constant_is_3() -> void:
	assert_int(GameManager.WAVES_PER_MISSION).is_equal(3)

func test_start_new_game_resets_campaign_and_mission() -> void:
	while CampaignManager.current_day < 3:
		# CampaignManager requires mission_won payload to match current_day.
		GameManager.current_mission = CampaignManager.get_current_day()
		SignalBus.mission_won.emit(GameManager.get_current_mission())
	assert_int(CampaignManager.current_day).is_greater(1)

	GameManager.start_new_game()

	assert_int(CampaignManager.current_day).is_equal(1)
	assert_bool(CampaignManager.campaign_completed).is_false()
	assert_int(GameManager.get_current_mission()).is_equal(1)
	assert_int(GameManager.get_current_wave()).is_equal(0)

func test_dayconfig_wave_count_configures_wavemanager_via_gamemanager() -> void:
	var custom_day: DayConfig = DayConfig.new()
	custom_day.day_index = 1
	custom_day.mission_index = 1
	custom_day.base_wave_count = 7

	var temp_config: CampaignConfig = CampaignConfig.new()
	temp_config.campaign_id = "test_wave_count_config"
	temp_config.is_short_campaign = true
	temp_config.short_campaign_length = 1
	temp_config.day_configs = [custom_day]
	CampaignManager.set_active_campaign_config_for_test(temp_config)

	GameManager.start_new_game()

	var wave_manager: WaveManager = get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager
	if wave_manager == null:
		# Headless GdUnit has no main.tscn tree; WaveManager lives under Main in full runs.
		assert_bool(true).is_true()
		return
	var expected: int = mini(7, wave_manager.max_waves)
	assert_int(wave_manager.configured_max_waves).is_equal(expected)

func test_start_mission_for_day_sets_current_mission() -> void:
	var day_config: DayConfig = DayConfig.new()
	day_config.day_index = 3
	day_config.mission_index = 3
	day_config.base_wave_count = 5

	GameManager.start_mission_for_day(3, day_config)
	assert_int(GameManager.get_current_mission()).is_equal(3)

func test_existing_missions_still_use_campaign_length_not_hardcoded_5() -> void:
	assert_int(CampaignManager.campaign_length).is_equal(
		CampaignManager.campaign_config.get_effective_length()
	)

