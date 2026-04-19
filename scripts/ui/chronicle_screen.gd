## Chronicle — meta-progression achievement list overlay.
extends Panel

const _ROW_SCENE: PackedScene = preload("res://scenes/ui/achievement_row_entry.tscn")

@onready var _entry_list: VBoxContainer = $Margin/VBox/Scroll/EntryList
@onready var _back_button: Button = $Margin/VBox/Header/BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	if not SignalBus.chronicle_progress_updated.is_connected(_on_chronicle_progress_updated):
		SignalBus.chronicle_progress_updated.connect(_on_chronicle_progress_updated)
	if not SignalBus.chronicle_entry_completed.is_connected(_on_chronicle_entry_completed):
		SignalBus.chronicle_entry_completed.connect(_on_chronicle_entry_completed)
	visibility_changed.connect(_on_visibility_changed)
	if visible:
		_refresh_rows()


func _on_visibility_changed() -> void:
	if visible:
		_refresh_rows()


func _on_chronicle_progress_updated(_entry_id: String, _current: int, _target: int) -> void:
	if visible:
		_refresh_rows()


func _on_chronicle_entry_completed(_entry_id: String) -> void:
	if visible:
		_refresh_rows()


func _refresh_rows() -> void:
	for c: Node in _entry_list.get_children():
		c.queue_free()
	var ids: PackedStringArray = ChronicleManager.get_entry_ids_sorted()
	for entry_id: String in ids:
		var st: Dictionary = ChronicleManager.get_entry_state(entry_id)
		var data: Resource = st.get("data") as Resource
		if data == null:
			continue
		var prog: int = int(st.get("progress", 0))
		var done: bool = bool(st.get("completed", false))
		var row: Node = _ROW_SCENE.instantiate()
		_entry_list.add_child(row)
		if row.has_method("setup"):
			row.call("setup", data, prog, done)


func _on_back_pressed() -> void:
	queue_free()
