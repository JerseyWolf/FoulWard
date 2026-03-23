# ui/build_menu.gd
# BuildMenu — shown during BUILD_MODE when a hex slot is selected.
# Zero game logic. All decisions delegated to HexGrid and EconomyManager.
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — BuildMenu class responsibilities.

class_name BuildMenu
extends Control

var _selected_slot: int = -1

@onready var _slot_label: Label = $Panel/VBox/SlotLabel
@onready var _help_label: Label = $Panel/VBox/HelpScroll/HelpLabel
@onready var _building_container: GridContainer = $Panel/VBox/BuildingContainer
@onready var _close_button: Button = $Panel/VBox/CloseButton

# ASSUMPTION: HexGrid path matches ARCHITECTURE.md §2.
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	print("[BuildMenu] _ready")
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.resource_changed.connect(_on_resource_changed)
	_close_button.pressed.connect(_on_close_pressed)


## Called by HexGrid input handler when player clicks a hex slot during BUILD_MODE.
func open_for_slot(slot_index: int) -> void:
	print("[BuildMenu] open_for_slot: slot=%d" % slot_index)
	_selected_slot = slot_index
	_slot_label.text = "Building on slot %d (yellow tile on ground)" % slot_index
	_hex_grid.set_build_slot_highlight(slot_index)
	show()       # must come BEFORE _refresh() — the guard checks visibility
	_refresh()


func _refresh() -> void:
	# Deferred refresh can run after exit_build_mode — skip if menu is hidden or invalid.
	if not visible:
		return
	if _selected_slot < 0:
		return
	if GameManager.get_game_state() != Types.GameState.BUILD_MODE:
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


func _on_build_mode_entered() -> void:
	print("[BuildMenu] build_mode_entered — opening slot 0")
	open_for_slot(0)


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


func _on_close_pressed() -> void:
	print("[BuildMenu] close pressed")
	GameManager.exit_build_mode()
