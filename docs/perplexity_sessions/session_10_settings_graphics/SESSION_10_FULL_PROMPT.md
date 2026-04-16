PROMPT:

# Session 10: Settings Graphics & Polish

## Goal
Wire SettingsManager.set_graphics_quality() to actual Godot RenderingServer APIs. Currently it stores a string but does not apply any rendering changes.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `settings_manager.gd` — SettingsManager autoload; full file
- `settings_screen.gd` — SettingsScreen UI script; full file
- `settings_screen.tscn` — SettingsScreen scene (or node structure description if binary)

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: wiring graphics quality presets to Godot's rendering APIs.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

REQUIREMENTS:
1. Define quality presets:
   - "low": shadows off, MSAA disabled, SSAO off, SDFGI off, glow off, motion blur off
   - "medium": shadows on (soft, 2048px), MSAA 2x, SSAO off, glow on
   - "high": shadows on (soft, 4096px), MSAA 4x, SSAO on, glow on, volumetric fog on

2. Implement _apply_quality_preset(quality: String) in SettingsManager that calls:
   - RenderingServer.directional_shadow_atlas_set_size() for shadow resolution
   - Viewport.msaa_3d for MSAA
   - Environment resource modifications for SSAO, glow, volumetric fog
   - get_viewport().set_* calls where applicable

3. Call _apply_quality_preset at startup (load_settings) and whenever set_graphics_quality is called.

4. Add a "Custom" quality option that preserves individual toggle states when the user changes specific settings.

5. SettingsScreen additions: individual toggles for shadows, MSAA, SSAO, glow (visible only when "Custom" quality is selected).

6. Handle the case where the game runs headless (no viewport available) — skip all rendering calls with a guard.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 10: Settings Graphics

## SettingsManager API (§3.8)

user://settings.cfg — volumes, graphics quality, keybind mirror.

| Signature | Returns | Usage |
|-----------|---------|-------|
| save_settings() -> void | void | Persists to user://settings.cfg |
| load_settings() -> void | void | Loads from config file |
| set_volume(bus_name: String, value: float) -> void | void | Sets "Master", "Music", or "SFX" (0.0-1.0) |
| set_graphics_quality(quality: String) -> void | void | Stores string; no RenderingServer calls (MVP) |
| remap_action(action_name: String, new_event: InputEvent) -> void | void | Replaces first binding and saves |

Current state: set_graphics_quality stores "low", "medium", or "high" as a string in the config file. No actual rendering changes are applied.

## Headless Considerations

The game supports headless execution (SimBot, GdUnit4 tests, AutoTestDriver). Any rendering code must guard against:
- No viewport available (get_viewport() returns null in some headless contexts)
- No WorldEnvironment node present
- RenderingServer calls that crash in headless mode

Pattern: `if not Engine.is_editor_hint() and get_viewport() != null:`

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- get_node_or_null() for runtime lookups with null guard
- push_warning() not assert() in production

FILES:

# Files to Upload for Session 10: Settings Graphics

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_10_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `autoloads/settings_manager.gd` — SettingsManager autoload; full file (~100 lines estimated)
2. `scripts/ui/settings_screen.gd` — SettingsScreen UI script; full file (~80 lines estimated)
3. `scenes/ui/settings_screen.tscn` — SettingsScreen scene; if binary/unreadable, describe the node structure instead (dropdown for quality, sliders for volume)

Total estimated token load: ~180 lines across 2-3 files

Note: If settings_screen.tscn is binary and unreadable, describe the current node tree in a comment at the top of the settings_screen.gd upload instead.

autoloads/settings_manager.gd:
## SettingsManager — user settings: audio buses, graphics quality string, keybind mirror.
## Autoload singleton only (no class_name — avoids clashing with autoload name).
extends Node

const SETTINGS_PATH: String = "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var graphics_quality: String = "Medium"
## action_name -> InputEvent (single binding per action for persistence)
var keybinds: Dictionary = {}


func _ready() -> void:
	_ensure_audio_buses()
	if FileAccess.file_exists(SETTINGS_PATH):
		load_settings()
	else:
		_mirror_keybinds_from_input_map()
		_apply_volumes_to_audio_server()
		save_settings()


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") < 0:
		AudioServer.add_bus()
		var idx_m: int = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx_m, "Music")
		AudioServer.set_bus_send(idx_m, "Master")
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		var idx_s: int = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx_s, "SFX")
		AudioServer.set_bus_send(idx_s, "Master")


func _mirror_keybinds_from_input_map() -> void:
	keybinds.clear()
	for action: String in InputMap.get_actions():
		if _is_skipped_builtin_action(action):
			continue
		var evs: Array[InputEvent] = InputMap.action_get_events(action)
		if evs.is_empty():
			continue
		keybinds[action] = evs[0].duplicate()


func _is_skipped_builtin_action(action: String) -> bool:
	return action.begins_with("ui_")


## Persists current settings to user://settings.cfg.
func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)
	cfg.set_value("graphics", "quality", graphics_quality)
	for action: String in keybinds.keys():
		var ev: Variant = keybinds[action]
		if ev is InputEvent:
			cfg.set_value("keybinds", action, var_to_str(ev))
	cfg.save(SETTINGS_PATH)


## Loads settings from user://settings.cfg, applying defaults for missing keys.
func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		_mirror_keybinds_from_input_map()
		return
	master_volume = float(cfg.get_value("audio", "master_volume", master_volume))
	music_volume = float(cfg.get_value("audio", "music_volume", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx_volume", sfx_volume))
	graphics_quality = str(cfg.get_value("graphics", "quality", graphics_quality))
	keybinds.clear()
	if cfg.has_section("keybinds"):
		for action: String in cfg.get_section_keys("keybinds"):
			var raw: String = str(cfg.get_value("keybinds", action, ""))
			if raw.is_empty():
				continue
			var ev: Variant = str_to_var(raw)
			if ev is InputEvent:
				keybinds[action] = ev
	if keybinds.is_empty():
		_mirror_keybinds_from_input_map()
	_apply_volumes_to_audio_server()
	_apply_keybinds_to_input_map()


func _apply_volumes_to_audio_server() -> void:
	_set_bus_volume_linear_by_name("Master", master_volume)
	_set_bus_volume_linear_by_name("Music", music_volume)
	_set_bus_volume_linear_by_name("SFX", sfx_volume)


func _set_bus_volume_linear_by_name(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_linear(idx, clampf(linear, 0.0, 1.0))


func _apply_keybinds_to_input_map() -> void:
	for action: String in keybinds.keys():
		var ev: Variant = keybinds[action]
		if ev is InputEvent:
			InputMap.action_erase_events(action)
			InputMap.action_add_event(action, ev as InputEvent)


## Sets the linear volume for the named AudioServer bus and saves settings.
func set_volume(bus_name: String, value: float) -> void:
	var v: float = clampf(value, 0.0, 1.0)
	match bus_name:
		"Master":
			master_volume = v
		"Music":
			music_volume = v
		"SFX":
			sfx_volume = v
		_:
			push_warning("SettingsManager.set_volume: unknown bus '%s'" % bus_name)
			return
	_set_bus_volume_linear_by_name(bus_name, v)
	save_settings()


## Sets the graphics quality preset string and saves settings.
func set_graphics_quality(quality: String) -> void:
	graphics_quality = quality
	save_settings()


## Replaces the first binding of the named input action and saves settings.
func remap_action(action_name: String, new_event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, new_event)
	keybinds[action_name] = new_event.duplicate()
	save_settings()

scripts/ui/settings_screen.gd:
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


scenes/ui/settings_screen.tscn:
[gd_scene load_steps=2 format=3 uid="uid://settings_screen_fw"]

[ext_resource type="Script" path="res://scripts/ui/settings_screen.gd" id="1_ss"]

[node name="SettingsScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_ss")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.08, 0.08, 0.12, 1)

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 40.0
offset_top = 40.0
offset_right = -40.0
offset_bottom = -40.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 16

[node name="Title" type="Label" parent="VBox"]
layout_mode = 2
text = "Settings"
theme_override_font_sizes/font_size = 36

[node name="AudioLabel" type="Label" parent="VBox"]
layout_mode = 2
text = "Audio"

[node name="MasterRow" type="HBoxContainer" parent="VBox"]
layout_mode = 2

[node name="Label" type="Label" parent="VBox/MasterRow"]
layout_mode = 2
custom_minimum_size = Vector2(120, 0)
text = "Master"

[node name="MasterSlider" type="HSlider" parent="VBox/MasterRow"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
min_value = 0.0
max_value = 1.0
step = 0.01
value = 1.0

[node name="MusicRow" type="HBoxContainer" parent="VBox"]
layout_mode = 2

[node name="Label" type="Label" parent="VBox/MusicRow"]
layout_mode = 2
custom_minimum_size = Vector2(120, 0)
text = "Music"

[node name="MusicSlider" type="HSlider" parent="VBox/MusicRow"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
min_value = 0.0
max_value = 1.0
step = 0.01
value = 0.8

[node name="SfxRow" type="HBoxContainer" parent="VBox"]
layout_mode = 2

[node name="Label" type="Label" parent="VBox/SfxRow"]
layout_mode = 2
custom_minimum_size = Vector2(120, 0)
text = "SFX"

[node name="SfxSlider" type="HSlider" parent="VBox/SfxRow"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
min_value = 0.0
max_value = 1.0
step = 0.01
value = 1.0

[node name="GraphicsLabel" type="Label" parent="VBox"]
layout_mode = 2
text = "Graphics Quality"

[node name="QualityOption" type="OptionButton" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 0

[node name="KeybindsLabel" type="Label" parent="VBox"]
layout_mode = 2
text = "Keybinds"

[node name="KeybindScroll" type="ScrollContainer" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3
custom_minimum_size = Vector2(0, 200)

[node name="KeybindRows" type="VBoxContainer" parent="VBox/KeybindScroll"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 6

[node name="BackButton" type="Button" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
text = "Back"

