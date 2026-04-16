## SettingsManager — user settings: audio buses, graphics quality, keybind mirror.
## Autoload singleton only (no class_name — avoids clashing with autoload name).
extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const SHADOW_RES_OFF: int = 0
const SHADOW_RES_MEDIUM: int = 2048
const SHADOW_RES_HIGH: int = 4096

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var graphics_quality: Types.GraphicsQuality = Types.GraphicsQuality.MEDIUM
## action_name -> InputEvent (single binding per action for persistence)
var keybinds: Dictionary = {}

var shadows_enabled: bool = true
var msaa_enabled: bool = false
var ssao_enabled: bool = false
var glow_enabled: bool = true


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
	cfg.set_value("graphics", "quality", int(graphics_quality))
	cfg.set_value("graphics", "shadows_enabled", shadows_enabled)
	cfg.set_value("graphics", "msaa_enabled", msaa_enabled)
	cfg.set_value("graphics", "ssao_enabled", ssao_enabled)
	cfg.set_value("graphics", "glow_enabled", glow_enabled)
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
	var quality_raw: Variant = cfg.get_value("graphics", "quality", int(graphics_quality))
	if quality_raw is int:
		graphics_quality = quality_raw as Types.GraphicsQuality
	elif quality_raw is String:
		match quality_raw:
			"Low":
				graphics_quality = Types.GraphicsQuality.LOW
			"High":
				graphics_quality = Types.GraphicsQuality.HIGH
			"Custom":
				graphics_quality = Types.GraphicsQuality.CUSTOM
			_:
				graphics_quality = Types.GraphicsQuality.MEDIUM
	shadows_enabled = bool(cfg.get_value("graphics", "shadows_enabled", shadows_enabled))
	msaa_enabled = bool(cfg.get_value("graphics", "msaa_enabled", msaa_enabled))
	ssao_enabled = bool(cfg.get_value("graphics", "ssao_enabled", ssao_enabled))
	glow_enabled = bool(cfg.get_value("graphics", "glow_enabled", glow_enabled))
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
	_apply_quality_preset(graphics_quality)


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


## Sets the graphics quality preset, applies rendering changes, and saves.
func set_graphics_quality(quality: Types.GraphicsQuality) -> void:
	graphics_quality = quality
	_apply_quality_preset(quality)
	SignalBus.graphics_quality_changed.emit(int(quality))
	save_settings()


## Replaces the first binding of the named input action and saves settings.
func remap_action(action_name: String, new_event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, new_event)
	keybinds[action_name] = new_event.duplicate()
	save_settings()


## THEORYCRAFT: WorldEnvironment placement unconfirmed.
## Assumed path: /root/Main/WorldEnvironment.
## No WorldEnvironment found in repo at time of S10.
## Adjust path once node is added to scene.
func _find_world_environment() -> WorldEnvironment:
	return get_node_or_null("/root/Main/WorldEnvironment") as WorldEnvironment


func _apply_quality_preset(quality: Types.GraphicsQuality) -> void:
	if get_viewport() == null or not is_inside_tree():
		return
	match quality:
		Types.GraphicsQuality.LOW:
			RenderingServer.directional_shadow_atlas_set_size(SHADOW_RES_OFF, false)
			get_viewport().positional_shadow_atlas_size = SHADOW_RES_OFF
			for light: Node in get_tree().get_nodes_in_group("directional_lights"):
				if light is DirectionalLight3D:
					(light as DirectionalLight3D).light_angular_distance = 0.0
			get_viewport().msaa_3d = Viewport.MSAA_DISABLED
			var we: WorldEnvironment = _find_world_environment()
			if we != null and we.environment != null:
				we.environment.ssao_enabled = false
				we.environment.sdfgi_enabled = false
				we.environment.glow_enabled = false
				we.environment.volumetric_fog_enabled = false
		Types.GraphicsQuality.MEDIUM:
			RenderingServer.directional_shadow_atlas_set_size(SHADOW_RES_MEDIUM, true)
			get_viewport().positional_shadow_atlas_size = SHADOW_RES_MEDIUM
			for light: Node in get_tree().get_nodes_in_group("directional_lights"):
				if light is DirectionalLight3D:
					(light as DirectionalLight3D).light_angular_distance = 0.5
			get_viewport().msaa_3d = Viewport.MSAA_2X
			var we: WorldEnvironment = _find_world_environment()
			if we != null and we.environment != null:
				we.environment.ssao_enabled = false
				we.environment.sdfgi_enabled = false
				we.environment.glow_enabled = true
				we.environment.volumetric_fog_enabled = false
		Types.GraphicsQuality.HIGH:
			RenderingServer.directional_shadow_atlas_set_size(SHADOW_RES_HIGH, true)
			get_viewport().positional_shadow_atlas_size = SHADOW_RES_HIGH
			for light: Node in get_tree().get_nodes_in_group("directional_lights"):
				if light is DirectionalLight3D:
					(light as DirectionalLight3D).light_angular_distance = 0.5
			get_viewport().msaa_3d = Viewport.MSAA_4X
			var we: WorldEnvironment = _find_world_environment()
			if we != null and we.environment != null:
				we.environment.ssao_enabled = true
				we.environment.sdfgi_enabled = false
				we.environment.glow_enabled = true
				we.environment.volumetric_fog_enabled = true
		Types.GraphicsQuality.CUSTOM:
			_apply_custom_toggles()


func _apply_custom_toggles() -> void:
	if get_viewport() == null or not is_inside_tree():
		return
	get_viewport().msaa_3d = Viewport.MSAA_2X if msaa_enabled else Viewport.MSAA_DISABLED
	var shadow_res: int = SHADOW_RES_MEDIUM if shadows_enabled else SHADOW_RES_OFF
	RenderingServer.directional_shadow_atlas_set_size(shadow_res, shadows_enabled)
	get_viewport().positional_shadow_atlas_size = shadow_res
	var we: WorldEnvironment = _find_world_environment()
	if we != null and we.environment != null:
		we.environment.ssao_enabled = ssao_enabled
		we.environment.glow_enabled = glow_enabled
