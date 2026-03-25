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

func _ready() -> void:
	# In-editor previews and some tests may instantiate the scene without data.
	if character_data == null:
		return

	character_id = character_data.character_id
	role = character_data.role
	display_name = character_data.display_name

	if is_instance_valid(_name_label):
		_name_label.text = display_name


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			character_interacted.emit(character_id)

