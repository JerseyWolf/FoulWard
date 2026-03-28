## test_dialogue_manager.gd
## GdUnit4 tests for DialogueManager selection, conditions, chains, and once-only.
# SOURCE: GdUnit autoload patterns from test_game_manager.gd / test_research_manager.gd

class_name TestDialogueManager
extends GdUnitTestSuite


func before_test() -> void:
	_reset_dialogue_manager_runtime_state()


func after_test() -> void:
	_reset_dialogue_manager_runtime_state()


func _reset_dialogue_manager_runtime_state() -> void:
	DialogueManager._load_all_dialogue_entries()
	DialogueManager.played_once_only.clear()
	DialogueManager.active_chains_by_character.clear()
	DialogueManager.mission_won_count = 0
	DialogueManager.mission_failed_count = 0
	DialogueManager.current_mission_number = 1
	DialogueManager.current_gamestate = Types.GameState.MAIN_MENU


func _register_entries(entries: Array[DialogueEntry]) -> void:
	DialogueManager.entries_by_id.clear()
	DialogueManager.entries_by_character.clear()
	for e: DialogueEntry in entries:
		DialogueManager.entries_by_id[e.entry_id] = e
		if not DialogueManager.entries_by_character.has(e.character_id):
			DialogueManager.entries_by_character[e.character_id] = []
		(DialogueManager.entries_by_character[e.character_id] as Array).append(e)


func test_conditions_matching_state_mark_entry_eligible() -> void:
	var entry := DialogueEntry.new()
	entry.entry_id = "TEST_ENTRY_COND_OK"
	entry.character_id = "EXAMPLE_CHARACTER"

	var cond := DialogueCondition.new()
	cond.key = "mission_failed_count"
	cond.comparison = ">"
	cond.value = 0
	entry.conditions = [cond]

	DialogueManager.mission_failed_count = 1
	assert_bool(DialogueManager._evaluate_conditions(entry)).is_true()


func test_conditions_not_matching_state_exclude_entry() -> void:
	var entry := DialogueEntry.new()
	entry.entry_id = "TEST_ENTRY_COND_FAIL"
	entry.character_id = "EXAMPLE_CHARACTER"

	var cond := DialogueCondition.new()
	cond.key = "mission_failed_count"
	cond.comparison = ">"
	cond.value = 5
	entry.conditions = [cond]

	DialogueManager.mission_failed_count = 1
	assert_bool(DialogueManager._evaluate_conditions(entry)).is_false()


func test_selects_entry_with_highest_priority() -> void:
	var a := DialogueEntry.new()
	a.entry_id = "A"
	a.character_id = "EXAMPLE_CHARACTER"
	a.priority = 10

	var b := DialogueEntry.new()
	b.entry_id = "B"
	b.character_id = "EXAMPLE_CHARACTER"
	b.priority = 100

	_register_entries([a, b])

	var picked: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
	assert_str(picked.entry_id).is_equal("B")


func test_entries_with_equal_priority_never_return_lower_priority() -> void:
	var high1 := DialogueEntry.new()
	high1.entry_id = "HIGH1"
	high1.character_id = "EXAMPLE_CHARACTER"
	high1.priority = 50

	var high2 := DialogueEntry.new()
	high2.entry_id = "HIGH2"
	high2.character_id = "EXAMPLE_CHARACTER"
	high2.priority = 50

	var low := DialogueEntry.new()
	low.entry_id = "LOW"
	low.character_id = "EXAMPLE_CHARACTER"
	low.priority = 10

	_register_entries([high1, high2, low])

	for _i in range(0, 20):
		var picked: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
		assert_int(picked.priority).is_equal(50)


func test_once_only_entry_not_returned_twice() -> void:
	var once := DialogueEntry.new()
	once.entry_id = "ONCE"
	once.character_id = "EXAMPLE_CHARACTER"
	once.priority = 100
	once.once_only = true

	var repeat := DialogueEntry.new()
	repeat.entry_id = "REPEAT"
	repeat.character_id = "EXAMPLE_CHARACTER"
	repeat.priority = 50

	_register_entries([once, repeat])

	var first: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
	DialogueManager.mark_entry_played(first.entry_id)
	var second: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")

	assert_str(first.entry_id).is_equal("ONCE")
	assert_str(second.entry_id).is_equal("REPEAT")


func test_chain_next_entry_preferred_after_first_part() -> void:
	var part1 := DialogueEntry.new()
	part1.entry_id = "CHAIN1"
	part1.character_id = "EXAMPLE_CHARACTER"
	part1.priority = 100
	part1.chain_next_id = "CHAIN2"

	var part2 := DialogueEntry.new()
	part2.entry_id = "CHAIN2"
	part2.character_id = "EXAMPLE_CHARACTER"
	part2.priority = 10

	var generic := DialogueEntry.new()
	generic.entry_id = "GENERIC"
	generic.character_id = "EXAMPLE_CHARACTER"
	generic.priority = 5

	_register_entries([part1, part2, generic])

	var first: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
	DialogueManager.mark_entry_played(first.entry_id)

	var second: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
	assert_str(second.entry_id).is_equal("CHAIN2")


func test_chain_next_not_used_when_conditions_fail() -> void:
	var part1 := DialogueEntry.new()
	part1.entry_id = "CHAIN1_FAIL"
	part1.character_id = "EXAMPLE_CHARACTER"
	part1.priority = 10
	part1.once_only = true
	part1.chain_next_id = "CHAIN2_FAIL"

	var part2 := DialogueEntry.new()
	part2.entry_id = "CHAIN2_FAIL"
	part2.character_id = "EXAMPLE_CHARACTER"
	part2.priority = 10
	var cond := DialogueCondition.new()
	cond.key = "mission_failed_count"
	cond.comparison = ">"
	cond.value = 10
	part2.conditions = [cond]

	var generic := DialogueEntry.new()
	generic.entry_id = "GENERIC2"
	generic.character_id = "EXAMPLE_CHARACTER"
	generic.priority = 5

	_register_entries([part1, part2, generic])

	DialogueManager.mission_failed_count = 0

	var first: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
	DialogueManager.mark_entry_played(first.entry_id)

	var second: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
	assert_str(second.entry_id).is_equal("GENERIC2")


func test_get_line_for_character_returns_placeholder_todo_text() -> void:
	_reset_dialogue_manager_runtime_state()
	DialogueManager.current_mission_number = 2
	DialogueManager.current_gamestate = Types.GameState.BETWEEN_MISSIONS
	var entry: DialogueEntry = DialogueManager.request_entry_for_character("SPELL_RESEARCHER")
	if entry != null:
		assert_str(entry.text).contains("TODO")


func test_dialoguemanager_loads_entries_from_dialogue_resources_folder() -> void:
	_reset_dialogue_manager_runtime_state()
	DialogueManager._load_all_dialogue_entries()
	assert_int(DialogueManager.entries_by_id.size()).is_greater(0)


func test_get_entry_by_id_returns_registered_entry() -> void:
	var entry := DialogueEntry.new()
	entry.entry_id = "TEST_GET_ENTRY_BY_ID_01"
	entry.character_id = "EXAMPLE_CHARACTER"
	entry.text = "Hello"
	entry.priority = 10
	entry.once_only = false
	entry.chain_next_id = ""
	entry.conditions = []

	_register_entries([entry])

	var fetched: DialogueEntry = DialogueManager.get_entry_by_id("TEST_GET_ENTRY_BY_ID_01")
	assert_object(fetched).is_not_null()
	assert_str(fetched.entry_id).is_equal("TEST_GET_ENTRY_BY_ID_01")


func test_request_entry_for_character_with_tags_keeps_priority_selection() -> void:
	var high := DialogueEntry.new()
	high.entry_id = "TEST_TAGS_HIGH"
	high.character_id = "EXAMPLE_CHARACTER"
	high.priority = 99
	high.once_only = false
	high.chain_next_id = ""
	high.text = "High"
	high.conditions = []

	var low := DialogueEntry.new()
	low.entry_id = "TEST_TAGS_LOW"
	low.character_id = "EXAMPLE_CHARACTER"
	low.priority = 1
	low.once_only = false
	low.chain_next_id = ""
	low.text = "Low"
	low.conditions = []

	_register_entries([high, low])

	var picked: DialogueEntry = DialogueManager.request_entry_for_character(
		"EXAMPLE_CHARACTER",
		["hub", "shop"]
	)
	assert_str(picked.entry_id).is_equal("TEST_TAGS_HIGH")


func test_research_unlocked_condition_unknown_node_evaluates_false() -> void:
	var entry := DialogueEntry.new()
	entry.entry_id = "AUDIT5_RESEARCH"
	entry.character_id = "EXAMPLE_CHARACTER"
	entry.priority = 100
	entry.text = "X"
	var cond := DialogueCondition.new()
	cond.key = "research_unlocked_nonexistent_node_id_abc123"
	cond.comparison = "=="
	cond.value = true
	entry.conditions = [cond]
	_register_entries([entry])
	var picked2: DialogueEntry = DialogueManager.request_entry_for_character("EXAMPLE_CHARACTER")
	assert_object(picked2).is_null()


func test_invalid_chain_next_id_does_not_crash() -> void:
	var first := DialogueEntry.new()
	first.entry_id = "AUDIT5_CHAIN_A"
	first.character_id = "EXAMPLE_CHARACTER"
	first.priority = 50
	first.text = "A"
	first.chain_next_id = "does_not_exist_999"
	first.conditions = []
	_register_entries([first])
	DialogueManager.mark_entry_played("AUDIT5_CHAIN_A")
	assert_bool(true).is_true()
