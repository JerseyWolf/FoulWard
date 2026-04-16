# test_endless_mode.gd — Endless Run (AUDIT 6 §3.4) headless-safe checks.
class_name TestEndlessMode
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	CampaignManager.is_endless_mode = false
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)


func after_test() -> void:
	CampaignManager.is_endless_mode = false
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	GameManager.start_new_game()
	await get_tree().process_frame


func test_start_endless_run_sets_flag() -> void:
	CampaignManager.is_endless_mode = false
	CampaignManager.start_endless_run()
	assert_bool(CampaignManager.is_endless_mode).is_true()


func test_endless_mission_won_does_not_complete_campaign() -> void:
	GameManager.reset_boss_campaign_state_for_test()
	CampaignManager.start_endless_run()
	GameManager.start_new_game()
	assert_int(CampaignManager.current_day).is_equal(1)
	for _i: int in range(60):
		SignalBus.mission_won.emit(CampaignManager.current_day)
		await get_tree().process_frame
	assert_bool(CampaignManager.campaign_completed).is_false()
	assert_int(CampaignManager.current_day).is_equal(61)


func test_endless_wave_scaling_continues_past_day_50() -> void:
	var m50: float = WaveManager.get_effective_enemy_hp_multiplier_for_day(50)
	var m60: float = WaveManager.get_effective_enemy_hp_multiplier_for_day(60)
	assert_float(m60).is_greater(m50)


func test_endless_skips_dialogue_calls() -> void:
	DialogueManager.reset_campaign_day_started_calls_for_test()
	CampaignManager.start_endless_run()
	GameManager.start_new_game()
	assert_int(DialogueManager.get_campaign_day_started_calls_for_test()).is_equal(0)
