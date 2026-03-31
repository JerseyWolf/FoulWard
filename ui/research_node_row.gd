## One row in the in-mission research panel (Prompt 11).
class_name ResearchNodeRow
extends HBoxContainer

var _node: ResearchNodeData = null

@onready var _name_label: Label = $NameLabel
@onready var _cost_label: Label = $CostLabel
@onready var _desc_label: Label = $DescLabel
@onready var _button: Button = $UnlockButton


func _ready() -> void:
	pass


func set_node(node: ResearchNodeData) -> void:
	_node = node
	if node == null:
		return
	_name_label.text = node.display_name
	_cost_label.text = "%d RP" % node.research_cost
	_desc_label.text = node.description
	if not _button.pressed.is_connected(_on_pressed):
		_button.pressed.connect(_on_pressed)
	refresh_state()


func get_node_id() -> String:
	if _node == null:
		return ""
	return _node.node_id


func refresh_state() -> void:
	if _node == null:
		return
	var rm: ResearchManager = _get_rm()
	if rm == null:
		_button.disabled = true
		return
	var unlocked: bool = rm.is_unlocked(_node.node_id)
	if unlocked:
		_button.disabled = true
		_button.text = "Unlocked"
		_name_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	else:
		_button.disabled = not rm.can_unlock(_node.node_id)
		_button.text = "Unlock"
		_name_label.remove_theme_color_override("font_color")


func _get_rm() -> ResearchManager:
	return get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager


func _on_pressed() -> void:
	if _node == null:
		return
	var rm: ResearchManager = _get_rm()
	if rm == null:
		return
	rm.unlock_node(_node.node_id)
