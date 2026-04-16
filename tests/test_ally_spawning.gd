# test_ally_spawning.gd — GameManager spawns allies from CampaignManager roster at mission start.

class_name TestAllySpawning
extends GdUnitTestSuite

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


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
	CampaignManager.reinitialize_ally_roster_for_test()
	if CampaignManager.campaign_config != null:
		CampaignManager.campaign_length = CampaignManager.campaign_config.get_effective_length()
		if CampaignManager.campaign_config.day_configs.size() > 0:
			CampaignManager.current_day_config = CampaignManager.campaign_config.day_configs[0]


func after_test() -> void:
	EconomyManager.reset_to_defaults()
	GameManager.game_state = Types.GameState.MAIN_MENU
	await get_tree().process_frame


func _is_ally_node(n: Node) -> bool:
	return n.has_method("initialize_ally_data")


func test_allies_spawn_at_mission_start_from_campaign_roster() -> void:
	assert_bool(CampaignManager.current_ally_roster.size() >= 1).is_true()

	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame

	GameManager.start_new_game()
	await get_tree().process_frame

	var ally_container: Node = main.get_node_or_null("AllyContainer")
	assert_object(ally_container).is_not_null()
	var count: int = 0
	for c: Node in ally_container.get_children():
		if _is_ally_node(c):
			count += 1

	assert_int(count).is_equal(CampaignManager.current_ally_roster.size())

	main.queue_free()
	await get_tree().process_frame


func test_allies_cleaned_up_on_mission_end_and_new_game() -> void:
	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame

	GameManager.start_new_game()
	await get_tree().process_frame

	SignalBus.all_waves_cleared.emit()
	await get_tree().process_frame

	var ally_container: Node = main.get_node_or_null("AllyContainer")
	assert_object(ally_container).is_not_null()
	var after_win: int = 0
	for c: Node in ally_container.get_children():
		if _is_ally_node(c):
			after_win += 1
	assert_int(after_win).is_equal(0)

	GameManager.start_new_game()
	await get_tree().process_frame
	var after_restart: int = 0
	for c: Node in ally_container.get_children():
		if _is_ally_node(c):
			after_restart += 1
	assert_int(after_restart).is_equal(CampaignManager.current_ally_roster.size())

	main.queue_free()
	await get_tree().process_frame
