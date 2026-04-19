## test_dialogue_content.gd
## GdUnit4: hub dialogue .tres invariants (Group 9).
class_name TestDialogueContent
extends GdUnitTestSuite

const HUB_ENTRY_IDS: Array[String] = [
	"COMPANION_MELEE_INTRO_01", "COMPANION_MELEE_INTRO_02",
	"COMPANION_MELEE_RESEARCH_01", "COMPANION_MELEE_GENERIC_01", "COMPANION_MELEE_GENERIC_02",
	"SPELL_RESEARCHER_INTRO_01", "SPELL_RESEARCHER_INTRO_02",
	"SPELL_RESEARCHER_RESEARCH_01", "SPELL_RESEARCHER_GENERIC_01", "SPELL_RESEARCHER_GENERIC_02",
	"MERCHANT_INTRO_01", "MERCHANT_INTRO_02",
	"MERCHANT_RESEARCH_01", "MERCHANT_GENERIC_01", "MERCHANT_GENERIC_02",
	"WEAPONS_ENGINEER_INTRO_01", "WEAPONS_ENGINEER_INTRO_02",
	"WEAPONS_ENGINEER_RESEARCH_01", "WEAPONS_ENGINEER_GENERIC_01", "WEAPONS_ENGINEER_GENERIC_02",
	"ENCHANTER_INTRO_01", "ENCHANTER_INTRO_02",
	"ENCHANTER_RESEARCH_01", "ENCHANTER_GENERIC_01", "ENCHANTER_GENERIC_02",
	"MERCENARY_COMMANDER_INTRO_01", "MERCENARY_COMMANDER_INTRO_02",
	"MERCENARY_COMMANDER_RESEARCH_01", "MERCENARY_COMMANDER_GENERIC_01", "MERCENARY_COMMANDER_GENERIC_02",
]


func before_test() -> void:
	DialogueManager._load_all_dialogue_entries()


func test_all_30_hub_entries_load() -> void:
	for id: String in HUB_ENTRY_IDS:
		var entry: DialogueEntry = DialogueManager.get_entry_by_id(id)
		assert_object(entry).override_failure_message("Missing entry: %s" % id).is_not_null()


func test_all_entries_have_character_id() -> void:
	for id: String in HUB_ENTRY_IDS:
		var entry: DialogueEntry = DialogueManager.get_entry_by_id(id)
		if entry != null:
			assert_str(entry.character_id).override_failure_message("Empty character_id on %s" % id).is_not_empty()


func test_intro_entries_are_once_only() -> void:
	for id: String in HUB_ENTRY_IDS:
		if "INTRO" in id:
			var entry: DialogueEntry = DialogueManager.get_entry_by_id(id)
			if entry != null:
				assert_bool(entry.once_only).override_failure_message("INTRO not once_only: %s" % id).is_true()


func test_generic_entries_are_repeatable() -> void:
	for id: String in HUB_ENTRY_IDS:
		if "GENERIC" in id:
			var entry: DialogueEntry = DialogueManager.get_entry_by_id(id)
			if entry != null:
				assert_bool(entry.once_only).override_failure_message("GENERIC should not be once_only: %s" % id).is_false()


func test_chain_next_ids_valid() -> void:
	for id: String in HUB_ENTRY_IDS:
		var entry: DialogueEntry = DialogueManager.get_entry_by_id(id)
		if entry != null and not entry.chain_next_id.is_empty():
			var chained: DialogueEntry = DialogueManager.get_entry_by_id(entry.chain_next_id)
			assert_object(chained).override_failure_message("Broken chain from %s → %s" % [id, entry.chain_next_id]).is_not_null()


func test_combat_entries_have_is_combat_line() -> void:
	var combat_ids: Array[String] = [
		"COMBAT_FIRST_BLOOD", "COMBAT_WAVE_3", "COMBAT_BOSS_APPEARS",
		"COMBAT_FLORENCE_HIT", "COMBAT_KILL_50", "COMBAT_WAVE_5",
		"COMBAT_KILL_10", "COMBAT_BOSS_KILLED", "COMBAT_WAVE_2", "COMBAT_FLORENCE_HIT_2",
	]
	for id: String in combat_ids:
		var entry: DialogueEntry = DialogueManager.get_entry_by_id(id)
		if entry != null:
			assert_bool(entry.is_combat_line).override_failure_message("Not flagged combat: %s" % id).is_true()
