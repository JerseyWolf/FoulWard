# test_final_boss_day.gd
# GdUnit4: GameManager final boss victory / failure and advance_to_next_day (Prompt 10).

class_name TestFinalBossDay
extends GdUnitTestSuite


func before_test() -> void:
	Engine.time_scale = 1.0
	GameManager.reset_boss_campaign_state_for_test()


func after_test() -> void:
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	GameManager.reset_boss_campaign_state_for_test()


func test_final_boss_victory_triggers_campaign_completed() -> void:
	var d50: DayConfig = DayConfig.new()
	d50.day_index = 50
	d50.mission_index = 5
	d50.is_final_boss = true
	d50.boss_id = "final_boss_test"

	var cfg: CampaignConfig = CampaignConfig.new()
	cfg.campaign_id = "test_boss_campaign"
	cfg.day_configs = [d50]
	CampaignManager.set_active_campaign_config_for_test(cfg)
	CampaignManager.campaign_length = 1
	CampaignManager.current_day = 50
	CampaignManager.current_day_config = d50

	GameManager.final_boss_id = "final_boss_test"
	GameManager.final_boss_day_index = 50
	GameManager.final_boss_active = false
	GameManager.final_boss_defeated = false

	var monitor := monitor_signals(SignalBus, false)
	GameManager._on_all_waves_cleared()
	await assert_signal(monitor).is_emitted("campaign_boss_attempted", [50, true])
	assert_bool(GameManager.final_boss_defeated).is_true()
	assert_bool(GameManager.final_boss_active).is_false()


func test_final_boss_failure_marks_boss_as_active_threat_and_attacks_random_territory_next_day() -> void:
	var d50: DayConfig = DayConfig.new()
	d50.day_index = 50
	d50.mission_index = 5
	d50.is_final_boss = true
	d50.boss_id = "final_boss_test"

	var d51: DayConfig = DayConfig.new()
	d51.day_index = 51
	d51.mission_index = 5
	d51.is_final_boss = false
	d51.is_boss_attack_day = false

	var cfg: CampaignConfig = CampaignConfig.new()
	cfg.campaign_id = "test_boss_campaign2"
	cfg.day_configs = [d50, d51]
	CampaignManager.set_active_campaign_config_for_test(cfg)
	CampaignManager.campaign_length = 51
	CampaignManager.current_day = 50
	CampaignManager.current_day_config = d50

	GameManager.final_boss_id = "final_boss_test"
	GameManager.final_boss_day_index = 50
	GameManager.final_boss_active = false
	GameManager.final_boss_defeated = false
	GameManager.held_territory_ids = ["territory_a", "territory_b", "territory_c"]

	var monitor := monitor_signals(SignalBus, false)
	GameManager._on_tower_destroyed()
	await assert_signal(monitor).is_emitted("campaign_boss_attempted", [50, false])
	assert_bool(GameManager.final_boss_active).is_true()
	assert_bool(GameManager.final_boss_defeated).is_false()

	GameManager.advance_to_next_day()
	assert_int(GameManager.current_day_index).is_equal(51)
	assert_that(GameManager.current_boss_threat_territory_id).is_not_empty()
	assert_bool(GameManager.held_territory_ids.has(GameManager.current_boss_threat_territory_id)).is_true()

	var day51: DayConfig = GameManager.get_day_config_for_index(51)
	assert_object(day51).is_not_null()
	assert_bool(day51.is_boss_attack_day).is_true()
	assert_bool(day51.is_final_boss).is_true()
	assert_that(day51.boss_id).is_equal("final_boss_test")
