## Single tower entry in the build menu (Prompt 11).
class_name BuildMenuButton
extends Button

signal building_clicked(building_data: BuildingData)

var _bd: BuildingData = null

@onready var _cost_label: Label = $Margin/VBox/CostLabel
@onready var _role_label: Label = $Margin/VBox/RoleLabel
@onready var _lock_overlay: ColorRect = $LockOverlay


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func set_building(bd: BuildingData) -> void:
	_bd = bd
	if bd == null:
		return
	text = bd.display_name
	var gc: int = EconomyManager.get_gold_cost(bd)
	var mc: int = EconomyManager.get_material_cost(bd)
	_cost_label.text = "%d gold · %d mat" % [gc, mc]
	var tags: PackedStringArray = bd.role_tags
	if tags.is_empty():
		_role_label.text = ""
	else:
		_role_label.text = ", ".join(tags)
	_refresh_state()


func refresh_state() -> void:
	_refresh_state()


func _refresh_state() -> void:
	if _bd == null:
		disabled = true
		return
	var locked: bool = _is_research_locked()
	_lock_overlay.visible = locked
	# Research-locked towers must stay enabled so [signal pressed] opens the research panel.
	if locked:
		disabled = false
	else:
		disabled = not EconomyManager.can_afford_building(_bd)


func _is_research_locked() -> bool:
	if _bd == null:
		return true
	if not _bd.is_locked:
		return false
	var uid: String = _bd.unlock_research_id.strip_edges()
	if uid == "":
		return true
	var rm: ResearchManager = _get_research_manager()
	if rm == null:
		return false
	return not rm.is_unlocked(uid)


func _get_research_manager() -> ResearchManager:
	return get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager


func _on_pressed() -> void:
	if _bd == null:
		return
	if _is_research_locked():
		var rm: ResearchManager = _get_research_manager()
		if rm != null:
			rm.show_research_panel_for(_bd.unlock_research_id.strip_edges())
		return
	emit_signal("building_clicked", _bd)
