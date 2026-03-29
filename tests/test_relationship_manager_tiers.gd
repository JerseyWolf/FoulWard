## test_relationship_manager_tiers.gd — Tier boundaries, multi-signal affinity, clamping.
## Classification: Unit (autoload state only).

class_name RelationshipManagerTierTest
extends GdUnitTestSuite


func before_test() -> void:
	RelationshipManager.reload_from_resources()


func after_test() -> void:
	RelationshipManager.reload_from_resources()


func test_affinity_at_exact_tier_boundaries() -> void:
	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", -100.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Hostile")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", -75.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Hostile")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", -51.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Hostile")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", -50.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Cold")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", -49.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Cold")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 0.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Neutral")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 30.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Neutral")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 31.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Friendly")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 70.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Friendly")

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 71.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Allied")


func test_multi_event_accumulation() -> void:
	RelationshipManager.reload_from_resources()
	SaveManager.start_new_attempt()
	var start: float = RelationshipManager.get_affinity("FLORENCE")
	SignalBus.mission_won.emit(1)
	var after_won: float = RelationshipManager.get_affinity("FLORENCE")
	SignalBus.mission_failed.emit(1)
	var after_fail: float = RelationshipManager.get_affinity("FLORENCE")
	SignalBus.boss_killed.emit("test_boss")
	var after_boss: float = RelationshipManager.get_affinity("FLORENCE")
	var d_won: float = after_won - start
	var d_fail: float = after_fail - after_won
	var d_boss: float = after_boss - after_fail
	assert_float(after_boss).is_equal(start + d_won + d_fail + d_boss)


func test_affinity_clamped_at_limits() -> void:
	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 1.0e9)
	assert_float(RelationshipManager.get_affinity("FLORENCE")).is_equal(100.0)

	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", -1.0e9)
	assert_float(RelationshipManager.get_affinity("FLORENCE")).is_equal(-100.0)
