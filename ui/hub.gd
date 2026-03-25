## hub.gd
## Between-mission hub overlay (2D). Instantiates clickable hub characters from CharacterCatalog.

extends Control
class_name Hub2DHub

signal hub_opened()
signal hub_closed()
signal hub_character_interacted(character_id: String)

## Data-driven list of hub characters.
@export var character_catalog: CharacterCatalog

@onready var _characters_container: Container = $CharactersContainer # ASSUMPTION: scene has CharactersContainer node.

var _characters_by_id: Dictionary = {} # character_id -> HubCharacterBase2D
var _between_mission_screen: Node = null
var _ui_manager: Node = null

var _character_scene: PackedScene = preload("res://scenes/hub/character_base_2d.tscn")

func _ready() -> void:
	_initialize_characters()


func set_between_mission_screen(screen: Node) -> void:
	_between_mission_screen = screen


func _set_ui_manager(ui_manager: Node) -> void:
	_ui_manager = ui_manager


func _initialize_characters() -> void:
	if _characters_container == null:
		return

	for child: Node in _characters_container.get_children():
		child.queue_free()

	_characters_by_id.clear()

	if character_catalog == null:
		return

	for char_data: CharacterData in character_catalog.characters:
		if char_data == null:
			continue
		var char_node: HubCharacterBase2D = _character_scene.instantiate() as HubCharacterBase2D
		char_node.character_data = char_data
		_characters_container.add_child(char_node)
		_characters_by_id[char_data.character_id] = char_node
		char_node.character_interacted.connect(_on_character_interacted)


func open_hub() -> void:
	visible = true
	hub_opened.emit()


func close_hub() -> void:
	visible = false
	hub_closed.emit()


func _on_character_interacted(character_id: String) -> void:
	hub_character_interacted.emit(character_id)
	_handle_character_focus(character_id)


func focus_character(character_id: String) -> void:
	_on_character_interacted(character_id)


func _handle_character_focus(character_id: String) -> void:
	if character_catalog == null:
		return

	var char_node: HubCharacterBase2D = _characters_by_id.get(character_id, null) as HubCharacterBase2D
	if char_node == null or char_node.character_data == null:
		return

	var char_data: CharacterData = char_node.character_data

	# Switch BetweenMissionScreen tab based on hub role.
	if _between_mission_screen != null:
		match char_data.role:
			Types.HubRole.SHOP:
				_between_mission_screen.open_shop_panel()
			Types.HubRole.RESEARCH:
				_between_mission_screen.open_research_panel()
			Types.HubRole.ENCHANT:
				_between_mission_screen.open_enchant_panel()
			Types.HubRole.MERCENARY:
				_between_mission_screen.open_mercenary_panel()
			Types.HubRole.ALLY, Types.HubRole.FLAVOR_ONLY:
				pass
			_:
				pass

	# Request dialogue from DialogueManager and display it via UIManager.
	if _ui_manager != null and _ui_manager.has_method("show_dialogue"):
		var entry: DialogueEntry = DialogueManager.request_entry_for_character(
			char_data.character_id,
			char_data.default_dialogue_tags
		)
		if entry != null:
			_ui_manager.show_dialogue(char_data.display_name, entry)

