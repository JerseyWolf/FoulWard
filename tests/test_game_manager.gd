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

# ════════════════════════════════════════════
# start_next_mission
# ════════════════════════════════════════════

func test_start_next_mission_increments_mission_number() -> void:
	GameManager.current_mission = 2
	GameManager.start_next_mission()
	assert_int(GameManager.get_current_mission()).is_equal(3)

func test_start_next_mission_resets_wave_to_0() -> void:
	GameManager.current_wave = 10
	GameManager.start_next_mission()
	assert_int(GameManager.get_current_wave()).is_equal(0)

func test_start_next_mission_transitions_to_mission_briefing() -> void:
	GameManager.start_next_mission()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.MISSION_BRIEFING)

func test_start_next_mission_emits_mission_started_with_correct_number() -> void:
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
	GameManager.game_state = Types.GameState.COMBAT
	GameManager.current_mission = 5
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

