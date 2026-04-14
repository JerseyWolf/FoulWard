## In-mission research overlay (Prompt 11).
class_name ResearchPanel
extends Control

const RowScene: PackedScene = preload("res://ui/research_node_row.tscn")

@onready var _panel: PanelContainer = $Panel
@onready var _points_label: Label = $Panel/Margin/VBox/HeaderRow/PointsLabel
@onready var _nodes_container: VBoxContainer = $Panel/Margin/VBox/Scroll/NodesVBox
@onready var _scroll: ScrollContainer = $Panel/Margin/VBox/Scroll
@onready var _close_button: Button = $Panel/Margin/VBox/HeaderRow/CloseButton


func _ready() -> void:
	add_to_group("research_panel")
	SignalBus.research_points_changed.connect(_on_points_changed)
	SignalBus.research_unlocked.connect(_on_research_unlocked)
	if not SignalBus.combat_phase_started.is_connected(_on_combat_phase_started):
		SignalBus.combat_phase_started.connect(_on_combat_phase_started)
	_close_button.pressed.connect(hide_panel)
	_build_nodes()
	_on_points_changed(EconomyManager.get_research_material())
	visible = false


func _on_combat_phase_started() -> void:
	visible = false


func _build_nodes() -> void:
	for child: Node in _nodes_container.get_children():
		child.queue_free()
	var rm: ResearchManager = _get_rm()
	if rm == null:
		return
	var nodes: Array[ResearchNodeData] = []
	for n: ResearchNodeData in rm.research_nodes:
		nodes.append(n)
	nodes.sort_custom(func(a: ResearchNodeData, b: ResearchNodeData) -> bool:
		return a.display_name < b.display_name
	)
	for n: ResearchNodeData in nodes:
		var row: Node = RowScene.instantiate()
		_nodes_container.add_child(row)
		if row.has_method("set_node"):
			row.call("set_node", n)


func _on_points_changed(points: int) -> void:
	_points_label.text = "%d RP" % points


func _on_research_unlocked(_node_id: String) -> void:
	for row: Node in _nodes_container.get_children():
		if row.has_method("refresh_state"):
			row.call("refresh_state")


func show_panel() -> void:
	visible = true
	_on_points_changed(EconomyManager.get_research_material())
	for row: Node in _nodes_container.get_children():
		if row.has_method("refresh_state"):
			row.call("refresh_state")


func hide_panel() -> void:
	visible = false


func scroll_to_node(node_id: String) -> void:
	if node_id.strip_edges() == "":
		return
	await get_tree().process_frame
	var target: Control = null
	for row: Node in _nodes_container.get_children():
		if row.has_method("get_node_id") and row.call("get_node_id") == node_id:
			target = row as Control
			break
	if target == null:
		return
	_scroll.ensure_control_visible(target)


func _get_rm() -> ResearchManager:
	return get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
