## world_map.gd
## Read-only world map panel: lists territories and shows details from GameManager state.
## No campaign rules here — presenter only.

class_name WorldMap
extends Control

@onready var territory_buttons_container: VBoxContainer = %TerritoryButtons
@onready var day_label: Label = %DayLabel
@onready var territory_name_label: Label = %TerritoryNameLabel
@onready var territory_description_label: Label = %TerritoryDescriptionLabel
@onready var terrain_label: Label = %TerrainLabel
@onready var ownership_label: Label = %OwnershipLabel
@onready var bonuses_label: Label = %BonusesLabel


func _ready() -> void:
	_build_territory_buttons()
	_update_day_and_current_territory()
	_connect_signals()


func _connect_signals() -> void:
	SignalBus.territory_state_changed.connect(_on_territory_state_changed)
	SignalBus.world_map_updated.connect(_on_world_map_updated)
	SignalBus.game_state_changed.connect(_on_game_state_changed)


func _clear_buttons() -> void:
	for child: Node in territory_buttons_container.get_children():
		child.queue_free()


func _build_territory_buttons() -> void:
	_clear_buttons()
	var territories: Array[TerritoryData] = GameManager.get_all_territories()
	for territory: TerritoryData in territories:
		if territory == null:
			continue
		var button: Button = Button.new()
		button.text = _get_button_text_for_territory(territory)
		button.modulate = territory.color
		button.pressed.connect(_on_territory_button_pressed.bind(territory.territory_id))
		territory_buttons_container.add_child(button)

	var current: TerritoryData = GameManager.get_current_day_territory()
	if current != null:
		_update_details_for_territory(current)


func _get_button_text_for_territory(territory: TerritoryData) -> String:
	var label: String = territory.display_name
	if territory.is_permanently_lost:
		label += " (Lost)"
	elif territory.is_controlled_by_player:
		label += " (Held)"
	return label


func _update_day_and_current_territory() -> void:
	var day_index: int = GameManager.get_current_day_index()
	day_label.text = "Day: %d" % day_index
	var current: TerritoryData = GameManager.get_current_day_territory()
	if current == null:
		territory_name_label.text = "Territory: -"
		territory_description_label.text = "Description: -"
		terrain_label.text = "Terrain: -"
		ownership_label.text = "Ownership: -"
		bonuses_label.text = "Bonuses: -"
	else:
		_update_details_for_territory(current)


func _update_details_for_territory(territory: TerritoryData) -> void:
	territory_name_label.text = "Territory: %s" % territory.display_name
	territory_description_label.text = "Description: %s" % territory.description
	terrain_label.text = "Terrain: %s" % _terrain_type_to_string(territory.terrain_type)
	var ownership: String = "Neutral"
	if territory.is_permanently_lost:
		ownership = "Lost"
	elif territory.is_controlled_by_player:
		ownership = "Held"
	ownership_label.text = "Ownership: %s" % ownership

	var parts: Array[String] = []
	if territory.bonus_flat_gold_end_of_day != 0:
		parts.append("Flat gold/day: %d" % territory.bonus_flat_gold_end_of_day)
	if territory.bonus_percent_gold_end_of_day != 0.0:
		parts.append("Gold %%/day: %.0f%%" % (territory.bonus_percent_gold_end_of_day * 100.0))
	if parts.is_empty():
		bonuses_label.text = "Bonuses: None"
	else:
		bonuses_label.text = "Bonuses: %s" % ", ".join(parts)


func _terrain_type_to_string(terrain_type: int) -> String:
	match terrain_type:
		TerritoryData.TerrainType.PLAINS:
			return "Plains"
		TerritoryData.TerrainType.FOREST:
			return "Forest"
		TerritoryData.TerrainType.SWAMP:
			return "Swamp"
		TerritoryData.TerrainType.MOUNTAIN:
			return "Mountain"
		TerritoryData.TerrainType.CITY:
			return "City"
		_:
			return "Other"


func _on_territory_button_pressed(territory_id: String) -> void:
	var territory: TerritoryData = GameManager.get_territory_data(territory_id)
	if territory != null:
		_update_details_for_territory(territory)


func _on_territory_state_changed(_territory_id: String) -> void:
	_build_territory_buttons()


func _on_world_map_updated() -> void:
	_build_territory_buttons()
	_update_day_and_current_territory()


func _on_game_state_changed(_old_state: Types.GameState, new_state: Types.GameState) -> void:
	if new_state == Types.GameState.BETWEEN_MISSIONS:
		_update_day_and_current_territory()
