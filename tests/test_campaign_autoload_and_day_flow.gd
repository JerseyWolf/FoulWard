# test_campaign_autoload_and_day_flow.gd — Audit 5: campaign autoload + day flow (headless-safe).
class_name TestCampaignAutoloadAndDayFlow
extends GdUnitTestSuite


func after_test() -> void:
	CampaignManager.is_endless_mode = false
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	GameManager.start_new_game()
	await get_tree().process_frame


func test_autoload_order_campaign_before_game_manager() -> void:
	var cf: ConfigFile = ConfigFile.new()
	var err: Error = cf.load("res://project.godot")
	assert_int(int(err)).is_equal(OK)
	var keys: PackedStringArray = cf.get_section_keys("autoload")
	var found_campaign: int = -1
	var found_game: int = -1
	for i: int in range(keys.size()):
		var k: String = str(keys[i])
		if k == "CampaignManager":
			found_campaign = i
		elif k == "GameManager":
			found_game = i
	assert_bool(found_campaign >= 0).is_true()
	assert_bool(found_game >= 0).is_true()
	if found_campaign >= found_game:
		push_error(
			"CampaignManager must be registered before GameManager in project.godot"
		)
	assert_int(found_campaign).is_less(found_game)


func test_start_new_campaign_initializes_state() -> void:
	var cm_script: GDScript = load("res://autoloads/campaign_manager.gd") as GDScript
	var cm: Node = cm_script.new()
	var cfg: CampaignConfig = load("res://resources/campaigns/campaign_short_5_days.tres") as CampaignConfig
	assert_object(cfg).is_not_null()
	cm.active_campaign_config = cfg
	add_child(cm)
	await get_tree().process_frame
	cm.start_new_campaign()
	assert_int(cm.current_day).is_equal(1)
	assert_bool(cm.campaign_completed).is_false()
	assert_int(cm.campaign_length).is_equal(cfg.get_effective_length())
	cm.queue_free()


func test_mission_won_advances_day_when_campaign_active() -> void:
	GameManager.reset_boss_campaign_state_for_test()
	GameManager.start_new_game()
	assert_int(CampaignManager.current_day).is_equal(1)
	GameManager.current_mission = CampaignManager.get_current_day()
	# Headless runs may complete deferred waves and set final_boss_defeated; clear before manual emit.
	GameManager.final_boss_defeated = false
	SignalBus.mission_won.emit(CampaignManager.current_day)
	await get_tree().process_frame
	assert_int(CampaignManager.current_day).is_equal(2)
	assert_object(CampaignManager.current_day_config).is_not_null()
	assert_int(CampaignManager.current_day_config.day_index).is_equal(2)


func test_mission_won_does_not_progress_without_active_campaign() -> void:
	var cm_script: GDScript = load("res://autoloads/campaign_manager.gd") as GDScript
	var cm: Node = cm_script.new()
	add_child(cm)
	await get_tree().process_frame
	cm.current_day = 5
	SignalBus.mission_won.emit(5)
	await get_tree().process_frame
	assert_int(cm.current_day).is_equal(5)
	cm.queue_free()


func test_campaign_completes_on_last_day_two_day_config() -> void:
	var custom_config: CampaignConfig = CampaignConfig.new()
	custom_config.campaign_id = "audit5_two_day"
	custom_config.is_short_campaign = true
	custom_config.short_campaign_length = 2

	var d1: DayConfig = DayConfig.new()
	d1.day_index = 1
	d1.base_wave_count = 3
	d1.faction_id = "DEFAULT_MIXED"
	var d2: DayConfig = DayConfig.new()
	d2.day_index = 2
	d2.base_wave_count = 3
	d2.faction_id = "DEFAULT_MIXED"

	custom_config.day_configs = [d1, d2]

	CampaignManager.set_active_campaign_config_for_test(custom_config)
	GameManager.start_new_game()

	assert_int(CampaignManager.current_day).is_equal(1)
	assert_bool(CampaignManager.campaign_completed).is_false()

	GameManager.current_mission = CampaignManager.get_current_day()
	SignalBus.mission_won.emit(GameManager.get_current_mission())
	await get_tree().process_frame

	assert_int(CampaignManager.current_day).is_equal(2)
	assert_bool(CampaignManager.campaign_completed).is_false()

	GameManager.current_mission = CampaignManager.get_current_day()
	SignalBus.mission_won.emit(GameManager.get_current_mission())
	await get_tree().process_frame

	assert_bool(CampaignManager.campaign_completed).is_true()
	assert_int(CampaignManager.campaign_length).is_equal(2)
