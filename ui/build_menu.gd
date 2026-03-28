# ui/build_menu.gd
# BuildMenu — shown during BUILD_MODE when a hex slot is selected.
# Zero game logic. All decisions delegated to HexGrid and EconomyManager.
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — BuildMenu class responsibilities.

class_name BuildMenu
extends Control

const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

var _selected_slot: int = -1
var _is_sell_mode: bool = false

@onready var _slot_label: Label = $Panel/VBox/SlotLabel
@onready var _building_container: GridContainer = $Panel/VBox/BuildingContainer
@onready var _close_button: Button = $Panel/VBox/CloseButton
@onready var _sell_panel: VBoxContainer = $Panel/VBox/SellPanel
@onready var _sell_building_name: Label = $Panel/VBox/SellPanel/BuildingNameLabel
@onready var _sell_upgrade_status: Label = $Panel/VBox/SellPanel/UpgradeStatusLabel
@onready var _sell_refund: Label = $Panel/VBox/SellPanel/RefundLabel
@onready var _sell_button: Button = $Panel/VBox/SellPanel/Buttons/SellButton
@onready var _sell_cancel_button: Button = $Panel/VBox/SellPanel/Buttons/CancelButton

# ASSUMPTION: HexGrid path matches ARCHITECTURE.md §2.
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	print("[BuildMenu] _ready")
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.resource_changed.connect(_on_resource_changed)
	_close_button.pressed.connect(_on_close_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_sell_cancel_button.pressed.connect(_on_sell_cancel_pressed)


## Called by InputManager when player clicks a hex slot during BUILD_MODE.
func open_for_slot(slot_index: int) -> void:
	print("[BuildMenu] open_for_slot: slot=%d" % slot_index)
	_selected_slot = slot_index
	_is_sell_mode = false
	_slot_label.text = "Building on slot %d (yellow tile on ground)" % slot_index
	_hex_grid.set_build_slot_highlight(slot_index)
	_building_container.show()
	_sell_panel.hide()
	show()       # must come BEFORE _refresh() — the guard checks visibility
	_refresh()

func open_for_sell_slot(slot_index: int, slot_data: Dictionary) -> void:
	print("[BuildMenu] open_for_sell_slot: slot=%d" % slot_index)
	_selected_slot = slot_index
	_is_sell_mode = true
	_hex_grid.set_build_slot_highlight(slot_index)
	_slot_label.text = "Occupied slot %d" % slot_index
	_building_container.hide()
	_sell_panel.show()
	_refresh_sell_panel(slot_data)
	show()


func _refresh() -> void:
	# Deferred refresh can run after exit_build_mode — skip if menu is hidden or invalid.
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

	var count: int = 0
	for i: int in range(Types.BuildingType.size()):
		var bt: Types.BuildingType = i as Types.BuildingType
		var bd: BuildingData = _hex_grid.get_building_data(bt)
		if bd == null:
			print("[BuildMenu] _refresh: WARNING no BuildingData for type %d" % i)
			continue

		var btn: Button = Button.new()
		var is_unlocked: bool = _hex_grid.is_building_available(bt)
		var can_afford: bool = EconomyManager.can_afford(bd.gold_cost, bd.material_cost)

		btn.icon = ArtPlaceholderHelper.get_building_icon(bt)
		btn.expand_icon = true
		btn.text = "%s\n%dg %dm" % [bd.display_name, bd.gold_cost, bd.material_cost]
		btn.disabled = not is_unlocked or not can_afford
		btn.custom_minimum_size = Vector2(180, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		btn.pressed.connect(func() -> void: _on_building_selected(bt))
		_building_container.add_child(btn)
		count += 1

	print("[BuildMenu] _refresh: slot=%d  gold=%d mat=%d  showing %d buttons" % [
		_selected_slot, EconomyManager.get_gold(), EconomyManager.get_building_material(), count
	])


func _on_building_selected(building_type: Types.BuildingType) -> void:
	print("[BuildMenu] _on_building_selected: type=%d slot=%d" % [building_type, _selected_slot])
	if _selected_slot < 0:
		print("[BuildMenu] _on_building_selected: REJECTED — no slot selected")
		return
	var placed: bool = _hex_grid.place_building(_selected_slot, building_type)
	print("[BuildMenu] _on_building_selected: place_building returned %s" % placed)
	if placed:
		# Exit build mode entirely — this triggers _on_build_mode_exited → hide().
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

	var refund_gold: int = data.gold_cost + (data.upgrade_gold_cost if is_upgraded else 0)
	var refund_material: int = data.material_cost + (data.upgrade_material_cost if is_upgraded else 0)
	_sell_refund.text = "Refund: %d gold, %d material" % [refund_gold, refund_material]


func _on_build_mode_entered() -> void:
	print("[BuildMenu] build_mode_entered — waiting for slot click")
	_selected_slot = -1
	_is_sell_mode = false
	_building_container.show()
	_sell_panel.hide()
	hide()  # UIManager keeps BuildMenu hidden until HexGrid explicitly opens it.


func _on_resource_changed(_resource_type: Types.ResourceType, _new_amount: int) -> void:
	if not visible:
		return
	if GameManager.get_game_state() != Types.GameState.BUILD_MODE:
		return
	if _selected_slot < 0:
		return
	# Deferred so we never free a button node while it is mid-signal-dispatch.
	call_deferred("_refresh")


func _on_build_mode_exited() -> void:
	print("[BuildMenu] build_mode_exited — hiding")
	hide()
	_selected_slot = -1
	_is_sell_mode = false


func _on_close_pressed() -> void:
	print("[BuildMenu] close pressed")
	GameManager.exit_build_mode()


func _on_sell_pressed() -> void:
	if _selected_slot < 0:
		hide()
		return
	_hex_grid.sell_building(_selected_slot)
	hide()


func _on_sell_cancel_pressed() -> void:
	hide()
