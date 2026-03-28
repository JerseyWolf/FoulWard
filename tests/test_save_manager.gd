# tests/test_save_manager.gd
# SaveManager rolling slots, load/restore, and resume detection.

class_name TestSaveManager
extends GdUnitTestSuite


func _slot0_path() -> String:
	return "user://saves/attempt_%s/slot_0.json" % SaveManager.current_attempt_id


func _slot_path(i: int) -> String:
	return "user://saves/attempt_%s/slot_%d.json" % [SaveManager.current_attempt_id, i]


func _read_campaign_day(path: String) -> int:
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


func before_test() -> void:
	SaveManager.clear_all_saves_for_test()
	SaveManager.current_attempt_id = ""
	EconomyManager.reset_to_defaults()
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	CampaignManager.is_endless_mode = false
	CampaignManager.campaign_completed = false
	GameManager.game_state = Types.GameState.BETWEEN_MISSIONS


func test_save_creates_slot_0_file() -> void:
	SaveManager.start_new_attempt()
	SaveManager.save_current_state()
	assert_bool(FileAccess.file_exists(_slot0_path())).is_true()


func test_slots_shift_on_second_save() -> void:
	SaveManager.start_new_attempt()
	CampaignManager.current_day = 10
	SaveManager.save_current_state()
	CampaignManager.current_day = 20
	SaveManager.save_current_state()
	assert_int(_read_campaign_day(_slot_path(1))).is_equal(10)
	assert_int(_read_campaign_day(_slot_path(0))).is_equal(20)


func test_load_slot_restores_current_day() -> void:
	SaveManager.start_new_attempt()
	CampaignManager.current_day = 3
	SaveManager.save_current_state()
	CampaignManager.current_day = 7
	var ok: bool = SaveManager.load_slot(0)
	assert_bool(ok).is_true()
	assert_int(CampaignManager.current_day).is_equal(3)


func test_load_slot_discards_newer_slots() -> void:
	SaveManager.start_new_attempt()
	CampaignManager.current_day = 1
	SaveManager.save_current_state()
	CampaignManager.current_day = 2
	SaveManager.save_current_state()
	CampaignManager.current_day = 3
	SaveManager.save_current_state()
	assert_bool(FileAccess.file_exists(_slot_path(0))).is_true()
	assert_bool(FileAccess.file_exists(_slot_path(1))).is_true()
	assert_bool(FileAccess.file_exists(_slot_path(2))).is_true()
	var ok2: bool = SaveManager.load_slot(2)
	assert_bool(ok2).is_true()
	assert_bool(FileAccess.file_exists(_slot_path(0))).is_false()
	assert_bool(FileAccess.file_exists(_slot_path(1))).is_false()
	assert_bool(FileAccess.file_exists(_slot_path(2))).is_true()


func test_has_resumable_returns_false_when_no_saves() -> void:
	SaveManager.clear_all_saves_for_test()
	SaveManager.current_attempt_id = ""
	assert_bool(SaveManager.has_resumable_attempt()).is_false()
