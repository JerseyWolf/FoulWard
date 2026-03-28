## Settings UI — audio, graphics quality, keybind remapping. Delegates to SettingsManager.
class_name SettingsScreen
extends Control

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _quality_option: OptionButton = %QualityOption
@onready var _keybind_rows: VBoxContainer = %KeybindRows
@onready var _back_button: Button = %BackButton

var _listening_action: String = ""
var _listening_button: Button = null


func _ready() -> void:
	_populate_from_settings()
	_master_slider.value_changed.connect(func(v: float) -> void: SettingsManager.set_volume("Master", v))
	_music_slider.value_changed.connect(func(v: float) -> void: SettingsManager.set_volume("Music", v))
	_sfx_slider.value_changed.connect(func(v: float) -> void: SettingsManager.set_volume("SFX", v))
	_quality_option.item_selected.connect(_on_quality_selected)
	_back_button.pressed.connect(_on_back_pressed)
	_build_keybind_rows()


func _populate_from_settings() -> void:
	_master_slider.set_value_no_signal(SettingsManager.master_volume)
	_music_slider.set_value_no_signal(SettingsManager.music_volume)
	_sfx_slider.set_value_no_signal(SettingsManager.sfx_volume)
	if _quality_option.item_count == 0:
		_quality_option.add_item("Low")
		_quality_option.add_item("Medium")
		_quality_option.add_item("High")
	var q: String = SettingsManager.graphics_quality
	var qi: int = 1
	match q:
		"Low":
			qi = 0
		"High":
			qi = 2
		_:
			qi = 1
	_quality_option.select(qi)


func _build_keybind_rows() -> void:
	for child: Node in _keybind_rows.get_children():
		child.queue_free()
	for action: String in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl: Label = Label.new()
		name_lbl.text = action
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.custom_minimum_size = Vector2(180, 0)
		var key_btn: Button = Button.new()
		key_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_btn.text = _format_action_events(action)
		var captured_action: String = action
		key_btn.pressed.connect(func() -> void: _start_listen(captured_action, key_btn))
		row.add_child(name_lbl)
		row.add_child(key_btn)
		_keybind_rows.add_child(row)


func _format_action_events(action: String) -> String:
	var evs: Array[InputEvent] = InputMap.action_get_events(action)
	if evs.is_empty():
		return "(unbound)"
	return evs[0].as_text()


func _start_listen(action: String, btn: Button) -> void:
	_listening_action = action
	_listening_button = btn
	btn.text = "Press a key…"
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if _listening_action.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var ev: InputEventKey = InputEventKey.new()
		ev.physical_keycode = event.physical_keycode
		ev.keycode = event.keycode
		ev.shift_pressed = event.shift_pressed
		ev.ctrl_pressed = event.ctrl_pressed
		ev.alt_pressed = event.alt_pressed
		ev.meta_pressed = event.meta_pressed
		SettingsManager.remap_action(_listening_action, ev)
		if _listening_button != null:
			_listening_button.text = ev.as_text()
		_listening_action = ""
		_listening_button = null
		set_process_unhandled_input(false)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = InputEventMouseButton.new()
		mb.button_index = event.button_index
		mb.pressed = true
		SettingsManager.remap_action(_listening_action, mb)
		if _listening_button != null:
			_listening_button.text = mb.as_text()
		_listening_action = ""
		_listening_button = null
		set_process_unhandled_input(false)
		get_viewport().set_input_as_handled()


func _on_quality_selected(index: int) -> void:
	var labels: PackedStringArray = ["Low", "Medium", "High"]
	if index >= 0 and index < labels.size():
		SettingsManager.set_graphics_quality(labels[index])


func _on_back_pressed() -> void:
	var ui: CanvasLayer = get_parent() as CanvasLayer
	if ui != null:
		var mm: Control = ui.get_node_or_null("MainMenu") as Control
		if mm != null:
			mm.show()
	queue_free()

