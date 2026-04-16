# test_simbot_profiles.gd
# GdUnit4 test suite for StrategyProfile resources (Phase 2).
# PRE_GENERATION_VERIFICATION: ran mentally for this file after CSV fix.

class_name TestSimBotProfiles
extends GdUnitTestSuite

func test_profiles_load_and_have_weights() -> void:
	# Arrange
	var paths: Array[String] = [
		"res://resources/strategyprofiles/strategy_balanced_default.tres",
		"res://resources/strategyprofiles/strategy_greedy_econ.tres",
		"res://resources/strategyprofiles/strategy_heavy_fire.tres",
	]

	# Act & Assert
	for path: String in paths:
		var res: Resource = load(path)
		assert_object(res).is_not_null()

		var profile: StrategyProfile = res as StrategyProfile
		assert_object(profile).is_not_null()

		assert_that(profile.profile_id).is_not_empty()
		assert_int(profile.build_priorities.size()).is_greater_equal(1)
		assert_bool(profile.placement_preferences.has("preferred_slots")).is_true()

