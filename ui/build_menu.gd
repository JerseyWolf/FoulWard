## BuildMenu — Radial building placement panel shown during BUILD_MODE; delegates all decisions to HexGrid and EconomyManager.
# ui/build_menu.gd
# BuildMenu — shown during BUILD_MODE when a hex slot is selected.
# Prompt 11: full [member HexGrid.building_data_registry] roster + research-locked towers.

class_name BuildMenu
extends Control

const BuildMenuButtonScene: PackedScene = preload("res://ui/build_menu_button.tscn")

var _selected_slot: int = -1
var _is_sell_mode: bool = false
var _buttons: Array[Node] = []

@onready var _slot_label: Label = $Panel/VBox/SlotLabel
@onready var _building_scroll: ScrollContainer = $Panel/VBox/BuildingScroll
@onready var _building_container: GridContainer = $Panel/VBox/BuildingScroll/BuildingContainer
@onready var _close_button: Button = $Panel/VBox/CloseButton
@onready var _sell_panel: VBoxContainer = $Panel/VBox/SellPanel
@onready var _sell_building_name: Label = $Panel/VBox/SellPanel/BuildingNameLabel
@onready var _sell_upgrade_status: Label = $Panel/VBox/SellPanel/UpgradeStatusLabel
@onready var _sell_refund: Label = $Panel/VBox/SellPanel/RefundLabel
@onready var _sell_button: Button = $Panel/VBox/SellPanel/Buttons/SellButton
@onready var _sell_cancel_button: Button = $Panel/VBox/SellPanel/Buttons/CancelButton

@onready var _hex_grid: HexGrid = get_node_or_null("/root/Main/HexGrid")


func _ready() -> void:
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.resource_changed.connect(_on_resource_changed)
	SignalBus.research_unlocked.connect(_on_research_unlocked)
	SignalBus.research_node_unlocked.connect(_on_research_unlocked)
	BuildPhaseManager.combat_phase_started.connect(_on_combat_phase_started)
	_close_button.pressed.connect(_on_close_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_sell_cancel_button.pressed.connect(_on_sell_cancel_pressed)
	hide()


func _on_combat_phase_started() -> void:
	hide()


## Called by InputManager when player clicks a hex slot during BUILD_MODE.
func open_for_slot(slot_index: int) -> void:
	if not is_instance_valid(_hex_grid):
		push_warning("BuildMenu: HexGrid not found")
		return
	_selected_slot = slot_index
	_is_sell_mode = false
	_slot_label.text = "Building on slot %d (yellow tile on ground)" % slot_index
	_hex_grid.set_build_slot_highlight(slot_index)
	_building_scroll.show()
	_sell_panel.hide()
	show()
	_refresh()


func open_for_sell_slot(slot_index: int, slot_data: Dictionary) -> void:
	if not is_instance_valid(_hex_grid):
		push_warning("BuildMenu: HexGrid not found")
		return
	_selected_slot = slot_index
	_is_sell_mode = true
	_hex_grid.set_build_slot_highlight(slot_index)
	_slot_label.text = "Occupied slot %d" % slot_index
	_building_scroll.hide()
	_sell_panel.show()
	_refresh_sell_panel(slot_data)
	show()


func _refresh() -> void:
	if not visible:
		return
	if _selected_slot < 0:
		return
	if GameManager.get_game_state() != Types.GameState.BUILD_MODE:
		return
	if _is_sell_mode:
		return

	while _building_container.get_child_count() > 0:
		_building_container.get_child(0).free()
	_buttons.clear()

	if not is_instance_valid(_hex_grid):
		return

	var registry: Array[BuildingData] = []
	for bd: BuildingData in _hex_grid.building_data_registry:
		if bd != null:
			registry.append(bd)

	registry.sort_custom(func(a: BuildingData, b: BuildingData) -> bool:
		var order: Dictionary = {"SMALL": 0, "MEDIUM": 1, "LARGE": 2}
		var sa: String = a.size_class.strip_edges().to_upper()
		var sb: String = b.size_class.strip_edges().to_upper()
		var oa: int = int(order.get(sa, 99))
		var ob: int = int(order.get(sb, 99))
		if oa == ob:
			return a.display_name < b.display_name
		return oa < ob
	)

	for bd: BuildingData in registry:
		var btn: BuildMenuButton = BuildMenuButtonScene.instantiate() as BuildMenuButton
		_building_container.add_child(btn)
		_buttons.append(btn)
		btn.set_building(bd)
		btn.building_clicked.connect(_on_building_data_selected)


func _on_building_data_selected(bd: BuildingData) -> void:
	if bd == null:
		return
	if _selected_slot < 0:
		return
	var placed: bool = _hex_grid.place_building(_selected_slot, bd.building_type)
	if placed:
		GameManager.exit_build_mode()


func _refresh_sell_panel(slot_data: Dictionary) -> void:
	var building: BuildingBase = slot_data.get("building", null) as BuildingBase
	if building == null:
		open_for_slot(_selected_slot)
		return

	var data: BuildingData = building.get_building_data()
	if data == null:
		_sell_building_name.text = "Unknown Building"
		_sell_upgrade_status.text = "Status: Unknown"
		_sell_refund.text = "Refund: N/A"
		return

	var is_upgraded: bool = building.is_upgraded
	_sell_building_name.text = data.display_name
	_sell_upgrade_status.text = "Status: %s" % ("Upgraded" if is_upgraded else "Basic")

	var refund: Dictionary = EconomyManager.get_refund(
			data,
			building.total_invested_gold,
			building.total_invested_material
	)
	_sell_refund.text = "Refund: %d gold, %d material" % [
			int(refund.get("gold", 0)),
			int(refund.get("material", 0))
	]


func _on_build_mode_entered() -> void:
	_selected_slot = -1
	_is_sell_mode = false
	_building_scroll.show()
	_sell_panel.hide()
	hide()


func _on_resource_changed(_resource_type: Types.ResourceType, _new_amount: int) -> void:
	if not visible:
		return
	if GameManager.get_game_state() != Types.GameState.BUILD_MODE:
		return
	if _selected_slot < 0:
		return
	call_deferred("_refresh")


func _on_research_unlocked(_unused_node_id: String) -> void:
	if not visible:
		return
	if GameManager.get_game_state() != Types.GameState.BUILD_MODE:
		return
	if _selected_slot < 0:
		return
	if _is_sell_mode:
		return
	call_deferred("_refresh")


func _on_build_mode_exited() -> void:
	hide()
	_selected_slot = -1
	_is_sell_mode = false


func _on_close_pressed() -> void:
	GameManager.exit_build_mode()


func _on_sell_pressed() -> void:
	if _selected_slot < 0:
		hide()
		return
	_hex_grid.sell_building(_selected_slot)
	hide()


func _on_sell_cancel_pressed() -> void:
	hide()
