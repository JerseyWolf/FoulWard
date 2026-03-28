## test_relationship_manager.gd — Affinity tiers, SignalBus deltas, dialogue tier conditions.
## (Class name avoids `TestRelationshipManager` — can shadow the `RelationshipManager` autoload in GdUnit.)
class_name TestRelationshipManagerGdUnit
extends GdUnitTestSuite

const _REL_EVENT_SCRIPT: GDScript = preload("res://scripts/resources/relationship_event_data.gd")
const _REL_MANAGER_SCRIPT: GDScript = preload("res://autoloads/relationship_manager.gd")


func before_test() -> void:
	RelationshipManager.reload_from_resources()


func after_test() -> void:
	RelationshipManager.reload_from_resources()


func test_starting_affinity_from_resource() -> void:
	var cr: Resource = load("res://resources/character_relationship/florence.tres") as Resource
	assert_object(cr).is_not_null()
	var starting: float = float(cr.get("starting_affinity"))
	RelationshipManager.reload_from_resources()
	assert_float(RelationshipManager.get_affinity("FLORENCE")).is_equal(starting)


func test_get_tier_returns_correct_tier() -> void:
	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 50.0)
	assert_str(RelationshipManager.get_tier("FLORENCE")).is_equal("Friendly")


func test_affinity_clamped_at_bounds() -> void:
	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 9999.0)
	assert_float(RelationshipManager.get_affinity("FLORENCE")).is_equal(100.0)


func test_mission_won_increases_affinity() -> void:
	RelationshipManager.reload_from_resources()
	var before: float = RelationshipManager.get_affinity("FLORENCE")
	SignalBus.mission_won.emit(1)
	var after: float = RelationshipManager.get_affinity("FLORENCE")
	assert_float(after).is_greater(before)


func test_unknown_signal_name_does_not_crash() -> void:
	var rm: Node = _REL_MANAGER_SCRIPT.new() as Node ## GDScript.new() on autoload script
	var bad: Resource = _REL_EVENT_SCRIPT.new() as Resource
	bad.set("signal_name", "nonexistent_signal")
	bad.set("character_deltas", {"FLORENCE": 1.0})
	rm.set("test_relationship_events_override", [bad])
	add_child(rm)
	await get_tree().process_frame
	remove_child(rm)
	rm.queue_free()


func test_dialogue_relationship_tier_condition() -> void:
	RelationshipManager.reload_from_resources()
	RelationshipManager.add_affinity("FLORENCE", 80.0)

	var cond_friendly := DialogueCondition.new()
	cond_friendly.condition_type = "relationship_tier"
	cond_friendly.character_id = "FLORENCE"
	cond_friendly.required_tier = "Friendly"
	assert_bool(DialogueManager._evaluate_relationship_tier_condition(cond_friendly)).is_true()

	var cond_allied := DialogueCondition.new()
	cond_allied.condition_type = "relationship_tier"
	cond_allied.character_id = "FLORENCE"
	cond_allied.required_tier = "Allied"
	assert_bool(DialogueManager._evaluate_relationship_tier_condition(cond_allied)).is_true()

	var cond_hostile := DialogueCondition.new()
	cond_hostile.condition_type = "relationship_tier"
	cond_hostile.character_id = "FLORENCE"
	cond_hostile.required_tier = "Hostile"
	assert_bool(DialogueManager._evaluate_relationship_tier_condition(cond_hostile)).is_false()
