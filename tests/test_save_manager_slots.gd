## test_save_manager_slots.gd — Rolling slots, attempt isolation, relationship restore.
## Unit tests + one integration test (uses SaveManager.load_slot).

class_name SaveManagerSlotTest
extends GdUnitTestSuite


func _read_campaign_day_from_path(path: String) -> int:
	assert_bool(FileAccess.file_exists(path)).is_true()
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_that(f).is_not_null()
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	assert_that(typeof(parsed)).is_equal(TYPE_DICTIONARY)
	var d: Dictionary = parsed as Dictionary
	var camp: Variant = d.get("campaign", {})
	assert_that(camp is Dictionary).is_true()
	return int((camp as Dictionary).get("current_day", -1))


func _read_florence_affinity(path: String) -> float:
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_that(f).is_not_null()
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	var d: Dictionary = parsed as Dictionary
	var rel: Dictionary = d.get("relationship", {}) as Dictionary
	var aff: Variant = (rel.get("affinities", {}) as Dictionary).get("FLORENCE", 0.0)
	return float(aff)


func before_test() -> void:
	SaveManager.clear_all_saves_for_test()
	SaveManager.current_attempt_id = ""
	EconomyManager.reset_to_defaults()
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	CampaignManager.is_endless_mode = false
	CampaignManager.campaign_completed = false
	GameManager.game_state = Types.GameState.BETWEEN_MISSIONS
	RelationshipManager.reload_from_resources()


func after_test() -> void:
	SaveManager.clear_all_saves_for_test()
	SaveManager.current_attempt_id = ""
	RelationshipManager.reload_from_resources()


func test_slot_rotation_after_max_saves() -> void:
	SaveManager.start_new_attempt()
	for day: int in range(1, 7):
		CampaignManager.current_day = day
		SaveManager.save_current_state()
	var attempt_dir: String = SaveManager._attempt_dir_path()
	var path_slot4: String = "%s/slot_4.json" % attempt_dir
	assert_int(_read_campaign_day_from_path(path_slot4)).is_equal(2)


func test_attempt_directory_isolation() -> void:
	SaveManager.start_new_attempt()
	var path_first_attempt: String = SaveManager._attempt_dir_path()
	CampaignManager.current_day = 42
	SaveManager.save_current_state()

	# start_new_attempt() uses second-level timestamps; ensure a distinct attempt id.
	await Engine.get_main_loop().create_timer(1.2).timeout
	SaveManager.start_new_attempt()
	CampaignManager.current_day = 99
	SaveManager.save_current_state()

	assert_bool(DirAccess.dir_exists_absolute(path_first_attempt)).is_true()
	var slot0_first: String = "%s/slot_0.json" % path_first_attempt
	assert_int(_read_campaign_day_from_path(slot0_first)).is_equal(42)


func test_relationship_manager_round_trip_integration() -> void:
	SaveManager.clear_all_saves_for_test()
	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 17.0)
	RelationshipManager.add_affinity("MERCHANT", -3.0)

	SaveManager.start_new_attempt()
	var attempt_a: String = SaveManager.current_attempt_id
	CampaignManager.current_day = 5
	SaveManager.save_current_state()

	var path_a_slot0: String = "user://saves/attempt_%s/slot_0.json" % attempt_a
	var aff_flo_saved: float = _read_florence_affinity(path_a_slot0)

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", -100.0)

	await Engine.get_main_loop().create_timer(1.2).timeout
	SaveManager.start_new_attempt()
	assert_str(SaveManager.current_attempt_id).is_not_equal(attempt_a)

	SaveManager.current_attempt_id = attempt_a
	var ok: bool = SaveManager.load_slot(0)
	assert_bool(ok).is_true()
	assert_float(RelationshipManager.get_affinity("FLORENCE")).is_equal(aff_flo_saved)
	assert_float(RelationshipManager.get_affinity("MERCHANT")).is_equal(-3.0)
