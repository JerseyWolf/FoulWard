## test_florence.gd
## GdUnit4 tests for FlorenceData meta-state integration.
##
## SOURCE: Uses existing Arrange–Act–Assert pattern from other suites.

class_name TestFlorence
extends GdUnitTestSuite

func before_test() -> void:
	Engine.time_scale = 1.0
	GameManager.game_state = Types.GameState.MAIN_MENU
	GameManager.current_mission = 1
	GameManager.current_wave = 0
	GameManager.final_boss_defeated = false
	GameManager.final_boss_active = false
	GameManager.current_day = 1

	EconomyManager.reset_to_defaults()
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	CampaignManager.campaign_completed = false
	CampaignManager.failed_attempts_on_current_day = 0
	CampaignManager.current_day = 1
	if CampaignManager.campaign_config != null:
		CampaignManager.campaign_length = CampaignManager.campaign_config.get_effective_length()
		if CampaignManager.campaign_config.day_configs.size() > 0:
			CampaignManager.current_day_config = CampaignManager.campaign_config.day_configs[0]

	# Test isolation: run_count persists across runs in FlorenceData, so reset it.
	var fd := GameManager.get_florence_data()
	if fd != null:
		fd.run_count = 0


func test_start_new_game_initializes_florence_data_and_counters() -> void:
	GameManager.start_new_game()

	var florence := GameManager.get_florence_data()
	assert_object(florence).is_not_null()

	assert_int(florence.total_days_played).is_equal(0)
	assert_int(florence.total_missions_played).is_equal(0)
	assert_int(florence.mission_failures).is_equal(0)
	assert_int(florence.boss_attempts).is_equal(0)

	assert_int(GameManager.current_day).is_equal(1)
	assert_bool(florence.has_unlocked_research).is_false()
	assert_bool(florence.has_recruited_any_mercenary).is_false()


func test_mission_win_increments_total_missions_played_and_advances_day() -> void:
	GameManager.start_new_game()
	var florence := GameManager.get_florence_data()
	var starting_day: int = GameManager.current_day

	SignalBus.all_waves_cleared.emit()

	assert_int(florence.total_missions_played).is_equal(1)
	assert_int(florence.total_days_played).is_equal(1)
	assert_int(GameManager.current_day).is_equal(starting_day + 1)


func test_mission_failure_increments_mission_failures_and_advances_day() -> void:
	GameManager.start_new_game()
	var florence := GameManager.get_florence_data()
	var starting_day: int = GameManager.current_day

	SignalBus.tower_destroyed.emit()

	assert_int(florence.mission_failures).is_equal(1)
	assert_int(florence.total_missions_played).is_equal(1)
	assert_int(florence.total_days_played).is_equal(1)
	assert_int(GameManager.current_day).is_equal(starting_day + 1)


func test_day_advances_once_for_multiple_reasons() -> void:
	GameManager.start_new_game()
	var florence := GameManager.get_florence_data()
	var starting_day: int = GameManager.current_day

	GameManager.advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
	GameManager.advance_day(Types.DayAdvanceReason.ACHIEVEMENT_EARNED)
	GameManager._apply_pending_day_advance_if_any()

	assert_int(GameManager.current_day).is_equal(starting_day + 1)
	assert_int(florence.total_days_played).is_equal(1)


func test_higher_priority_day_reason_from_types_wins() -> void:
	GameManager.start_new_game()

	GameManager.advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
	GameManager.advance_day(Types.DayAdvanceReason.MAJOR_STORY_EVENT)

	assert_int(GameManager._pending_day_advance_reason).is_equal(
		int(Types.DayAdvanceReason.MAJOR_STORY_EVENT)
	)


func test_first_research_unlock_sets_has_unlocked_research_flag() -> void:
	GameManager.start_new_game()
	var florence := GameManager.get_florence_data()
	assert_bool(florence.has_unlocked_research).is_false()

	var rm: ResearchManager = ResearchManager.new()
	var rnd: ResearchNodeData = ResearchNodeData.new()
	rnd.node_id = "unlock_ballista"
	rnd.display_name = "Ballista"
	rnd.research_cost = 2
	rnd.prerequisite_ids = []
	rm.research_nodes = [rnd]

	EconomyManager.add_research_material(10)
	var ok: bool = rm.unlock_node("unlock_ballista")
	assert_bool(ok).is_true()

	assert_bool(florence.has_unlocked_research).is_true()


func test_dialogue_condition_resolves_florence_mission_failures() -> void:
	GameManager.start_new_game()
	var florence := GameManager.get_florence_data()
	florence.mission_failures = 3

	var value: Variant = DialogueManager._resolve_state_value("florence.mission_failures")
	assert_int(int(value)).is_equal(3)


func test_dialogue_condition_resolves_campaign_current_day() -> void:
	GameManager.start_new_game()
	GameManager.current_day = 10

	var value: Variant = DialogueManager._resolve_state_value("campaign.current_day")
	assert_int(int(value)).is_equal(10)


func test_hub_florence_panel_updates_on_florence_state_changed_signal() -> void:
	var scene := load("res://ui/between_mission_screen.tscn")
	var screen := scene.instantiate() as BetweenMissionScreen
	add_child(screen)
	await get_tree().process_frame

	GameManager.start_new_game()
	await get_tree().process_frame

	var florence := GameManager.get_florence_data()
	florence.mission_failures = 5
	SignalBus.florence_state_changed.emit()
	await get_tree().process_frame

	var label: Label = screen.get_node("FlorenceDebugLabel") as Label
	assert_str(label.text).contains("Failures 5")

