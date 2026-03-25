## dialogue_ui.gd
## Minimal placeholder panel for hub dialogue lines. # PLACEHOLDER styling.

class_name DialogueUI
extends Control

var _current_entry_id: String = ""
var _current_character_id: String = ""

@onready var _name_label: Label = $Panel/VBox/NameLabel
@onready var _text_label: Label = $Panel/VBox/TextLabel
@onready var _advance_button: Button = $Panel/VBox/AdvanceButton


func _ready() -> void:
	visible = false
	_advance_button.pressed.connect(_on_advance_pressed)


func show_entry(entry: DialogueEntry) -> void:
	if entry == null:
		hide()
		return

	_current_entry_id = entry.entry_id
	_current_character_id = entry.character_id

	_name_label.text = _get_display_name(entry.character_id)
	_text_label.text = entry.text
	visible = true


func _get_display_name(character_id: String) -> String:
	match character_id:
		"FLORENCE":
			return "Florence"
		"COMPANION_MELEE":
			return "Arnulf"
		"SPELL_RESEARCHER":
			return "Sybil"
		"WEAPONS_ENGINEER":
			return "Weapons Engineer"
		"ENCHANTER":
			return "Enchanter"
		"MERCHANT":
			return "Merchant"
		"MERCENARY_COMMANDER":
			return "Commander"
		"CAMPAIGN_CHARACTER_X":
			return "Campaign Ally"
		"EXAMPLE_CHARACTER":
			return "Example"
		_:
			return character_id


func _on_advance_pressed() -> void:
	if _current_entry_id.is_empty():
		hide()
		return

	DialogueManager.mark_entry_played(_current_entry_id)

	var next_entry: DialogueEntry = null
	if DialogueManager.entries_by_id.has(_current_entry_id):
		var entry: DialogueEntry = DialogueManager.entries_by_id[_current_entry_id] as DialogueEntry
		if not entry.chain_next_id.is_empty():
			if DialogueManager.entries_by_id.has(entry.chain_next_id):
				next_entry = DialogueManager.entries_by_id[entry.chain_next_id] as DialogueEntry

	if next_entry != null:
		show_entry(next_entry)
	else:
		DialogueManager.notify_dialogue_finished(_current_entry_id, _current_character_id)
		_current_entry_id = ""
		_current_character_id = ""
		hide()
