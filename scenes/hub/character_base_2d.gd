## character_base_2d.gd
## Clickable between-mission hub character UI base. Emits interaction signal only.

extends Control
class_name HubCharacterBase2D

signal character_interacted(character_id: String)

## Data resource that describes this hub character.
@export var character_data: CharacterData

var character_id: String = ""
var role: Types.HubRole = Types.HubRole.FLAVOR_ONLY
var display_name: String = ""

@onready var _name_label: Label = (get_node_or_null("NameLabel") as Label) # Optional in tests / stubs.
@onready var talk_button: Button = (get_node_or_null("TalkButton") as Button)


func _ready() -> void:
	# In-editor previews and some tests may instantiate the scene without data.
	if character_data == null:
		return

	character_id = character_data.character_id
	role = character_data.role
	display_name = character_data.display_name

	if is_instance_valid(_name_label):
		_name_label.text = display_name

	if is_instance_valid(talk_button):
		if not talk_button.pressed.is_connected(_on_talk_button_pressed):
			talk_button.pressed.connect(_on_talk_button_pressed)
		_refresh_talk_button()

	if not SignalBus.dialogue_line_finished.is_connected(_on_dialogue_line_finished_for_talk_refresh):
		SignalBus.dialogue_line_finished.connect(_on_dialogue_line_finished_for_talk_refresh)
	if not SignalBus.mission_started.is_connected(_on_mission_started_for_talk_refresh):
		SignalBus.mission_started.connect(_on_mission_started_for_talk_refresh)


func _refresh_talk_button() -> void:
	if not is_instance_valid(talk_button):
		return
	if character_id.is_empty():
		talk_button.visible = false
		return
	var entry: DialogueEntry = DialogueManager.peek_entry_for_character(character_id)
	talk_button.visible = (entry != null)


func _on_talk_button_pressed() -> void:
	if not character_id.is_empty():
		character_interacted.emit(character_id)


func _on_dialogue_line_finished_for_talk_refresh(_entry_id: String, _character_id: String) -> void:
	_refresh_talk_button()


func _on_mission_started_for_talk_refresh(_mission_number: int) -> void:
	_refresh_talk_button()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			character_interacted.emit(character_id)

