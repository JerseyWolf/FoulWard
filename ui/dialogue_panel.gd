## dialogue_panel.gd
## Global hub dialogue overlay (click-to-continue).

extends Control
class_name DialoguePanel

var current_entry: DialogueEntry = null
var current_speaker_name: String = ""

@onready var _speaker_label: Label = $SpeakerLabel # ASSUMPTION: scene has SpeakerLabel node.
@onready var _text_label: Label = $TextLabel # ASSUMPTION: scene has TextLabel node.

func _ready() -> void:
	visible = false
	# SOURCE: Godot Control gui_input signal for click handling.
	gui_input.connect(_on_gui_input)


func show_entry(display_name: String, entry: DialogueEntry) -> void:
	current_entry = entry
	current_speaker_name = display_name

	if is_instance_valid(_speaker_label):
		_speaker_label.text = display_name

	if is_instance_valid(_text_label) and entry != null:
		_text_label.text = entry.text

	visible = true


func clear_dialogue() -> void:
	current_entry = null
	current_speaker_name = ""
	visible = false


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_advance_or_close()


func _advance_or_close() -> void:
	if current_entry == null:
		clear_dialogue()
		return

	# Mark the entry as played to respect once_only and chain behavior.
	DialogueManager.mark_entry_played(current_entry.entry_id)

	var chain_id: String = current_entry.chain_next_id
	if not chain_id.is_empty():
		var next_entry: DialogueEntry = DialogueManager.get_entry_by_id(chain_id)
		if next_entry != null:
			show_entry(current_speaker_name, next_entry)
			return

	# Chain exhausted or missing next entry.
	DialogueManager.notify_dialogue_finished(
		current_entry.entry_id,
		current_entry.character_id
	)
	clear_dialogue()

