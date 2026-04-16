# test_simbot_safety.gd
# GdUnit4 test suite for SimBot safety (no UI dependencies).

class_name TestSimBotSafety
extends GdUnitTestSuite

func test_simbot_has_no_ui_dependencies() -> void:
	# Arrange
	var simbot_script: Script = load("res://scripts/sim_bot.gd")
	var source_code: String = simbot_script.source_code

	# Act
	var uses_ui: bool = source_code.contains("res://ui/")

	# Assert
	assert_bool(uses_ui).is_false()

