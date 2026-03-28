## tests/test_settings_manager.gd — SettingsManager persistence + ArtPlaceholderHelper icons.

class_name TestSettingsManager
extends GdUnitTestSuite

const SettingsManagerScript: GDScript = preload("res://autoloads/settings_manager.gd")
const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

var _saved_fire_primary_events: Array[InputEvent] = []


func before_test() -> void:
	_saved_fire_primary_events = InputMap.action_get_events("fire_primary").duplicate()
	ArtPlaceholderHelper.clear_cache()


func after_test() -> void:
	InputMap.action_erase_events("fire_primary")
	for ev: InputEvent in _saved_fire_primary_events:
		InputMap.action_add_event("fire_primary", ev)
	ArtPlaceholderHelper.clear_cache()


func test_save_and_load_preserves_volume() -> void:
	var sm1: Node = SettingsManagerScript.new()
	add_child(sm1)
	sm1.master_volume = 0.4
	sm1.save_settings()
	remove_child(sm1)
	sm1.free()

	var sm2: Node = SettingsManagerScript.new()
	add_child(sm2)
	sm2.load_settings()
	assert_float(sm2.master_volume).is_equal(0.4)
	remove_child(sm2)
	sm2.free()


func test_set_volume_clamped() -> void:
	SettingsManager.set_volume("Master", 1.5)
	assert_float(SettingsManager.master_volume).is_equal(1.0)


func test_remap_action_updates_input_map() -> void:
	var new_ev: InputEventKey = InputEventKey.new()
	new_ev.physical_keycode = KEY_Q
	new_ev.keycode = KEY_Q
	SettingsManager.remap_action("fire_primary", new_ev)
	var evs: Array[InputEvent] = InputMap.action_get_events("fire_primary")
	assert_int(evs.size()).is_equal(1)
	var ev: InputEvent = evs[0]
	assert_bool(ev is InputEventKey).is_true()
	assert_int((ev as InputEventKey).physical_keycode).is_equal(KEY_Q)


func test_get_building_icon_returns_texture() -> void:
	var tex: Texture2D = ArtPlaceholderHelper.get_building_icon(Types.BuildingType.ARROW_TOWER)
	assert_object(tex).is_not_null()


func test_get_icon_missing_file_returns_fallback() -> void:
	var bogus: Types.BuildingType = 999
	var tex: Texture2D = ArtPlaceholderHelper.get_building_icon(bogus)
	assert_object(tex).is_not_null()
