## test_combat_dialogue.gd
## GdUnit4: combat dialogue selection and SignalBus hook (Group 9).
class_name TestCombatDialogue
extends GdUnitTestSuite


func before_test() -> void:
	DialogueManager._load_all_dialogue_entries()
	DialogueManager._combat_kills_this_mission = 0
	DialogueManager._combat_wave_number = 0
	DialogueManager._combat_boss_seen = false
	DialogueManager._combat_first_blood = false
	DialogueManager._combat_florence_damaged = false
	DialogueManager._seen_combat_lines.clear()


func after_test() -> void:
	before_test()


func test_request_combat_line_returns_null_initially() -> void:
	var result: DialogueEntry = DialogueManager.request_combat_line()
	assert_object(result).is_null()


func test_first_blood_triggers_line() -> void:
	DialogueManager._combat_first_blood = true
	var result: DialogueEntry = DialogueManager.request_combat_line()
	assert_object(result).is_not_null()


func test_wave_number_condition() -> void:
	DialogueManager._combat_wave_number = 3
	var result: DialogueEntry = DialogueManager.request_combat_line()
	assert_object(result).is_not_null()


func test_seen_lines_not_repeated() -> void:
	DialogueManager._combat_first_blood = true
	var first: DialogueEntry = DialogueManager.request_combat_line()
	assert_object(first).is_not_null()
	DialogueManager._seen_combat_lines.clear()
	DialogueManager._seen_combat_lines[first.entry_id] = true
	var second: DialogueEntry = DialogueManager.request_combat_line()
	if second != null:
		assert_str(second.entry_id).is_not_equal(first.entry_id)


func test_mission_reset_clears_seen() -> void:
	DialogueManager._combat_first_blood = true
	var first: DialogueEntry = DialogueManager.request_combat_line()
	assert_object(first).is_not_null()
	DialogueManager._seen_combat_lines[first.entry_id] = true
	SignalBus.mission_started.emit(1)
	DialogueManager._combat_first_blood = true
	var second: DialogueEntry = DialogueManager.request_combat_line()
	assert_object(second).is_not_null()


func test_combat_banner_no_crash_headless() -> void:
	var dummy_entry := DialogueEntry.new()
	dummy_entry.entry_id = "HEADLESS_TEST"
	dummy_entry.is_combat_line = true
	dummy_entry.text = "test"
	SignalBus.combat_dialogue_requested.emit(dummy_entry)
	assert_bool(true).is_true()
