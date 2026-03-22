# ui/build_menu.gd
# BuildMenu — shown during BUILD_MODE when a hex slot is selected.
# Zero game logic. All decisions delegated to HexGrid and EconomyManager.
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — BuildMenu class responsibilities.

class_name BuildMenu
extends Control

var _selected_slot: int = -1

@onready var _slot_label: Label = $Panel/VBox/SlotLabel
@onready var _building_container: GridContainer = $Panel/VBox/BuildingContainer
@onready var _close_button: Button = $Panel/VBox/CloseButton

# ASSUMPTION: HexGrid path matches ARCHITECTURE.md §2.
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	_close_button.pressed.connect(_on_close_pressed)


## Called by InputManager or HexGrid input handler when player
## clicks a hex slot during BUILD_MODE.
func open_for_slot(slot_index: int) -> void:
	_selected_slot = slot_index
	_slot_label.text = "Slot %d — Choose Building:" % slot_index
	_refresh()
	show()


func _refresh() -> void:
	for child: Node in _building_container.get_children():
		child.queue_free()

	for building_type: int in Types.BuildingType.values():
		var bt: Types.BuildingType = building_type as Types.BuildingType
		var bd: BuildingData = _hex_grid.get_building_data(bt)
		if bd == null:
			continue

		var btn: Button = Button.new()
		var is_unlocked: bool = _hex_grid.is_building_unlocked(bt)
		var can_afford: bool = EconomyManager.can_afford(bd.gold_cost, bd.material_cost)

		btn.text = "%s\n%dg %dm" % [bd.display_name, bd.gold_cost, bd.material_cost]
		btn.disabled = not is_unlocked or not can_afford
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Capture bt in lambda via bound parameter.
		btn.pressed.connect(func() -> void: _on_building_selected(bt))
		_building_container.add_child(btn)


func _on_building_selected(building_type: Types.BuildingType) -> void:
	if _selected_slot < 0:
		return
	var placed: bool = _hex_grid.place_building(_selected_slot, building_type)
	if placed:
		hide()
		_selected_slot = -1


func _on_build_mode_entered() -> void:
	_selected_slot = -1


func _on_build_mode_exited() -> void:
	hide()
	_selected_slot = -1


func _on_close_pressed() -> void:
	GameManager.exit_build_mode()

