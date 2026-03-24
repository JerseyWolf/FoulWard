class_name TestCampaignManager
extends GdUnitTestSuite

func before_test() -> void:
	GameManager.start_new_game()

func test_start_new_game_initializes_day_one_for_short_campaign() -> void:
	assert_int(CampaignManager.current_day).is_equal(1)
	assert_bool(CampaignManager.campaign_completed).is_false()
	assert_that(CampaignManager.current_day_config).is_not_null()
	assert_int(CampaignManager.current_day_config.day_index).is_equal(1)
	assert_str(CampaignManager.campaign_id).is_equal("short_campaign_5_days")

func test_day_win_advances_day_and_shows_between_day_hub() -> void:
	assert_int(CampaignManager.current_day).is_equal(1)
	SignalBus.mission_won.emit(GameManager.get_current_mission())
	assert_int(CampaignManager.current_day).is_equal(2)
	assert_bool(CampaignManager.campaign_completed).is_false()
	assert_int(GameManager.get_game_state()).is_equal(Types.GameState.BETWEEN_MISSIONS)

func test_day_fail_repeats_same_day() -> void:
	SignalBus.mission_won.emit(GameManager.get_current_mission())
	assert_int(CampaignManager.current_day).is_equal(2)
	var prev_fails: int = CampaignManager.failed_attempts_on_current_day
	# Payload must match CampaignManager.current_day (GameManager mission index may lag until the next day starts).
	SignalBus.mission_failed.emit(CampaignManager.get_current_day())
	assert_int(CampaignManager.current_day).is_equal(2)
	assert_int(CampaignManager.failed_attempts_on_current_day).is_equal(prev_fails + 1)

func test_failed_attempts_reset_on_day_win() -> void:
	SignalBus.mission_failed.emit(GameManager.get_current_mission())
	SignalBus.mission_failed.emit(GameManager.get_current_mission())
	assert_int(CampaignManager.failed_attempts_on_current_day).is_equal(2)
	SignalBus.mission_won.emit(GameManager.get_current_mission())
	assert_int(CampaignManager.failed_attempts_on_current_day).is_equal(0)

func test_campaign_completed_after_last_short_day_win() -> void:
	while CampaignManager.current_day < CampaignManager.campaign_length:
		SignalBus.mission_won.emit(GameManager.get_current_mission())
	assert_int(CampaignManager.current_day).is_equal(CampaignManager.campaign_length)
	assert_bool(CampaignManager.campaign_completed).is_false()
	SignalBus.mission_won.emit(GameManager.get_current_mission())
	assert_bool(CampaignManager.campaign_completed).is_true()

func test_campaign_length_matches_short_config() -> void:
	assert_int(CampaignManager.campaign_length).is_equal(5)

func test_day_config_injected_via_test_helper() -> void:
	var custom_config: CampaignConfig = CampaignConfig.new()
	custom_config.campaign_id = "test_only_2_days"
	custom_config.is_short_campaign = true
	custom_config.short_campaign_length = 2

	var d1: DayConfig = DayConfig.new()
	d1.day_index = 1
	d1.base_wave_count = 3
	var d2: DayConfig = DayConfig.new()
	d2.day_index = 2
	d2.base_wave_count = 4
	custom_config.day_configs = [d1, d2]

	CampaignManager.set_active_campaign_config_for_test(custom_config)
	GameManager.start_new_game()

	assert_int(CampaignManager.campaign_length).is_equal(2)
	assert_int(CampaignManager.current_day).is_equal(1)
	assert_str(CampaignManager.campaign_id).is_equal("test_only_2_days")
