# test_campaign_autoload_and_day_flow.gd — Audit 5: campaign autoload + day flow (headless-safe).
class_name TestCampaignAutoloadAndDayFlow
extends GdUnitTestSuite


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
	cm.queue_free()


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
