## territory_node_ui.gd
## World-map control for a single territory: displays star tier count and lock state.
## Emits territory_selected_for_replay when the player activates a controlled territory.
## Requires: TerritoryData.star_count / highest_cleared_tier (Chat 4A step 3),
##           SignalBus.territory_selected_for_replay (Chat 4A step 4).

extends Control

@export var territory_id: String = ""

@onready var _star_label: Label = get_node_or_null("StarLabel") as Label
@onready var _lock_overlay: Control = get_node_or_null("LockOverlay") as Control
@onready var _select_button: Button = get_node_or_null("SelectButton") as Button


func _ready() -> void:
	if not SignalBus.territory_state_changed.is_connected(_on_territory_state_changed):
		SignalBus.territory_state_changed.connect(_on_territory_state_changed)
	if not SignalBus.world_map_updated.is_connected(_refresh):
		SignalBus.world_map_updated.connect(_refresh)
	if _select_button != null:
		_select_button.pressed.connect(_on_select_button_pressed)
	_refresh()


func _on_territory_state_changed(changed_id: String) -> void:
	if changed_id == territory_id:
		_refresh()


func _refresh() -> void:
	var territory: TerritoryData = GameManager.get_territory_data(territory_id)
	if territory == null:
		return
	var stars: int = territory.star_count
	if _star_label != null:
		_star_label.text = "*".repeat(stars)
	var locked: bool = not territory.is_controlled_by_player
	if _lock_overlay != null:
		_lock_overlay.visible = locked
	if _select_button != null:
		_select_button.disabled = locked


func _on_select_button_pressed() -> void:
	var territory: TerritoryData = GameManager.get_territory_data(territory_id)
	if territory == null:
		return
	if territory.is_controlled_by_player:
		SignalBus.territory_selected_for_replay.emit(territory_id)
