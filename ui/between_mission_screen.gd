# ui/between_mission_screen.gd
# BetweenMissionScreen — Shop, Research, Buildings tabs + Next Mission button.
# Zero game logic. All decisions delegated to ShopManager, ResearchManager,
# HexGrid, and GameManager.
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — BetweenMissionScreen class responsibilities.

class_name BetweenMissionScreen
extends Control

@onready var _next_mission_btn: Button = $NextMissionButton

@onready var _shop_list: VBoxContainer = $TabContainer/ShopTab/ShopList
@onready var _research_list: VBoxContainer = $TabContainer/ResearchTab/ResearchList
@onready var _buildings_list: VBoxContainer = $TabContainer/BuildingsTab/BuildingsList

@onready var _shop_manager: ShopManager = get_node(
	"/root/Main/Managers/ShopManager"
)
@onready var _research_manager: ResearchManager = get_node(
	"/root/Main/Managers/ResearchManager"
)
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	_next_mission_btn.pressed.connect(_on_next_mission_pressed)


func _on_game_state_changed(
		_old: Types.GameState,
		new_state: Types.GameState
) -> void:
	if new_state == Types.GameState.BETWEEN_MISSIONS:
		_refresh_all()


func _refresh_all() -> void:
	_refresh_shop()
	_refresh_research()
	_refresh_buildings()


func _refresh_shop() -> void:
	for child: Node in _shop_list.get_children():
		child.queue_free()

	var items: Array[ShopItemData] = _shop_manager.get_available_items()
	for item: ShopItemData in items:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		var price_text: String = "%s — %dg" % [item.display_name, item.gold_cost]
		if item.material_cost > 0:
			price_text = "%s — %dg + %dm" % [
				item.display_name, item.gold_cost, item.material_cost
			]
		lbl.text = price_text
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Buy"
		btn.disabled = not _shop_manager.can_purchase(item.item_id)
		var captured_id: String = item.item_id
		btn.pressed.connect(func() -> void: _on_shop_buy_pressed(captured_id))
		row.add_child(lbl)
		row.add_child(btn)
		_shop_list.add_child(row)


func _refresh_research() -> void:
	for child: Node in _research_list.get_children():
		child.queue_free()

	var nodes: Array[ResearchNodeData] = _research_manager.get_available_nodes()
	for node_data: ResearchNodeData in nodes:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s — %d res" % [node_data.display_name, node_data.research_cost]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Unlock"
		btn.disabled = (
			EconomyManager.get_research_material() < node_data.research_cost
		)
		var captured_id: String = node_data.node_id
		btn.pressed.connect(func() -> void: _on_research_unlock_pressed(captured_id))
		row.add_child(lbl)
		row.add_child(btn)
		_research_list.add_child(row)


func _refresh_buildings() -> void:
	for child: Node in _buildings_list.get_children():
		child.queue_free()

	var occupied: Array[int] = _hex_grid.get_all_occupied_slots()
	if occupied.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No buildings placed."
		_buildings_list.add_child(lbl)
		return

	for slot_index: int in occupied:
		var slot_data: Dictionary = _hex_grid.get_slot_data(slot_index)
		var building: BuildingBase = slot_data.get("building", null)
		if building == null:
			continue
		var bd: BuildingData = building.get_building_data()
		var lbl: Label = Label.new()
		lbl.text = "Slot %d: %s%s" % [
			slot_index,
			bd.display_name,
			" (Upgraded)" if building.is_upgraded else ""
		]
		_buildings_list.add_child(lbl)


func _on_shop_buy_pressed(item_id: String) -> void:
	_shop_manager.purchase_item(item_id)
	_refresh_shop()


func _on_research_unlock_pressed(node_id: String) -> void:
	_research_manager.unlock_node(node_id)
	_refresh_research()


func _on_next_mission_pressed() -> void:
	GameManager.start_next_mission()
