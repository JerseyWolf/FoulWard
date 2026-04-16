extends GdUnitTestSuite


func after_test() -> void:
	SettingsManager.graphics_quality = Types.GraphicsQuality.MEDIUM
	SettingsManager.shadows_enabled = true
	SettingsManager.msaa_enabled = false
	SettingsManager.ssao_enabled = false
	SettingsManager.glow_enabled = true


func test_enum_low_value() -> void:
	assert_int(Types.GraphicsQuality.LOW).is_equal(0)


func test_enum_medium_value() -> void:
	assert_int(Types.GraphicsQuality.MEDIUM).is_equal(1)


func test_enum_high_value() -> void:
	assert_int(Types.GraphicsQuality.HIGH).is_equal(2)


func test_enum_custom_value() -> void:
	assert_int(Types.GraphicsQuality.CUSTOM).is_equal(3)


func test_set_graphics_quality_stores_enum() -> void:
	SettingsManager.set_graphics_quality(Types.GraphicsQuality.LOW)
	assert_int(int(SettingsManager.graphics_quality)).is_equal(int(Types.GraphicsQuality.LOW))


func test_set_graphics_quality_emits_signal() -> void:
	var received: Array[int] = [-1]
	var on_changed: Callable = func(quality: int) -> void: received[0] = quality
	SignalBus.graphics_quality_changed.connect(on_changed)
	SettingsManager.set_graphics_quality(Types.GraphicsQuality.HIGH)
	assert_int(received[0]).is_equal(int(Types.GraphicsQuality.HIGH))
	SignalBus.graphics_quality_changed.disconnect(on_changed)


func test_load_settings_applies_preset_headless() -> void:
	SettingsManager.graphics_quality = Types.GraphicsQuality.HIGH
	SettingsManager.save_settings()
	SettingsManager.graphics_quality = Types.GraphicsQuality.LOW
	SettingsManager.load_settings()
	assert_int(int(SettingsManager.graphics_quality)).is_equal(int(Types.GraphicsQuality.HIGH))


func test_custom_preset_preserves_toggles() -> void:
	SettingsManager.shadows_enabled = false
	SettingsManager.msaa_enabled = true
	SettingsManager.ssao_enabled = false
	SettingsManager.glow_enabled = false
	SettingsManager.save_settings()
	SettingsManager.shadows_enabled = true
	SettingsManager.load_settings()
	assert_bool(SettingsManager.shadows_enabled).is_false()
	assert_bool(SettingsManager.msaa_enabled).is_true()
	assert_bool(SettingsManager.glow_enabled).is_false()


func test_apply_quality_preset_headless_no_crash() -> void:
	SettingsManager._apply_quality_preset(Types.GraphicsQuality.LOW)
	SettingsManager._apply_quality_preset(Types.GraphicsQuality.MEDIUM)
	SettingsManager._apply_quality_preset(Types.GraphicsQuality.HIGH)
	SettingsManager._apply_quality_preset(Types.GraphicsQuality.CUSTOM)
	assert_bool(true).is_true()
