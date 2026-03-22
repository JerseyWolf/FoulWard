# tests/test_research_manager.gd
# GdUnit4 test suite for ResearchManager.
# Tests unlock flow, prerequisite checking, material spending, and reset.

class_name TestResearchManager
extends GdUnitTestSuite

var _research_manager: ResearchManager = null


func _make_node(node_id: String, cost: int, prereqs: Array[String] = []) -> ResearchNodeData:
	var rnd: ResearchNodeData = ResearchNodeData.new()
	rnd.node_id = node_id
	rnd.display_name = node_id
	rnd.research_cost = cost
	rnd.prerequisite_ids = prereqs
	rnd.description = "Test node %s" % node_id
	return rnd


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_research_material(20)
	_research_manager = ResearchManager.new()
	_research_manager.research_nodes = [
		_make_node("unlock_ballista", 2, []),
		_make_node("unlock_advanced", 4, ["unlock_ballista"]),
	]
	add_child(_research_manager)


func after_test() -> void:
	if is_instance_valid(_research_manager):
		_research_manager.queue_free()
	EconomyManager.reset_to_defaults()
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# is_unlocked tests
# ---------------------------------------------------------------------------

func test_is_unlocked_returns_false_before_unlock() -> void:
	assert_bool(_research_manager.is_unlocked("unlock_ballista")).is_false()


func test_is_unlocked_returns_true_after_unlock() -> void:
	_research_manager.unlock_node("unlock_ballista")
	assert_bool(_research_manager.is_unlocked("unlock_ballista")).is_true()

# ---------------------------------------------------------------------------
# unlock_node tests
# ---------------------------------------------------------------------------

func test_unlock_node_spends_research_material() -> void:
	var mat_before: int = EconomyManager.get_research_material()
	_research_manager.unlock_node("unlock_ballista")
	assert_int(EconomyManager.get_research_material()).is_equal(mat_before - 2)


func test_unlock_node_emits_research_unlocked() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_research_manager.unlock_node("unlock_ballista")
	await assert_signal(monitor).is_emitted("research_unlocked", ["unlock_ballista"])


func test_unlock_node_fails_when_prereq_not_met() -> void:
	var result: bool = _research_manager.unlock_node("unlock_advanced")
	assert_bool(result).is_false()
	assert_bool(_research_manager.is_unlocked("unlock_advanced")).is_false()


func test_unlock_node_succeeds_when_prereq_met() -> void:
	_research_manager.unlock_node("unlock_ballista")
	var result: bool = _research_manager.unlock_node("unlock_advanced")
	assert_bool(result).is_true()


func test_unlock_node_fails_insufficient_material() -> void:
	EconomyManager.reset_to_defaults()
	var result: bool = _research_manager.unlock_node("unlock_ballista")
	assert_bool(result).is_false()
	assert_bool(_research_manager.is_unlocked("unlock_ballista")).is_false()


func test_unlock_node_fails_for_unknown_node_id() -> void:
	var result: bool = _research_manager.unlock_node("nonexistent_node")
	assert_bool(result).is_false()


func test_unlock_already_unlocked_node_fails() -> void:
	_research_manager.unlock_node("unlock_ballista")
	var mat_after_first: int = EconomyManager.get_research_material()
	var result: bool = _research_manager.unlock_node("unlock_ballista")
	assert_bool(result).is_false()
	assert_int(EconomyManager.get_research_material()).is_equal(mat_after_first)

# ---------------------------------------------------------------------------
# get_available_nodes tests
# ---------------------------------------------------------------------------

func test_get_available_nodes_returns_only_prereq_met() -> void:
	var available: Array[ResearchNodeData] = _research_manager.get_available_nodes()
	assert_int(available.size()).is_equal(1)
	assert_str(available[0].node_id).is_equal("unlock_ballista")


func test_get_available_nodes_excludes_already_unlocked() -> void:
	_research_manager.unlock_node("unlock_ballista")
	var available: Array[ResearchNodeData] = _research_manager.get_available_nodes()
	for node: ResearchNodeData in available:
		assert_str(node.node_id).is_not_equal("unlock_ballista")


func test_get_available_nodes_expands_after_unlock() -> void:
	_research_manager.unlock_node("unlock_ballista")
	var available: Array[ResearchNodeData] = _research_manager.get_available_nodes()
	var ids: Array[String] = []
	for node: ResearchNodeData in available:
		ids.append(node.node_id)
	assert_bool(ids.has("unlock_advanced")).is_true()

# ---------------------------------------------------------------------------
# reset_to_defaults tests
# ---------------------------------------------------------------------------

func test_reset_clears_all_unlocks() -> void:
	_research_manager.unlock_node("unlock_ballista")
	assert_bool(_research_manager.is_unlocked("unlock_ballista")).is_true()
	_research_manager.reset_to_defaults()
	assert_bool(_research_manager.is_unlocked("unlock_ballista")).is_false()


func test_reset_makes_nodes_available_again() -> void:
	EconomyManager.add_research_material(10)
	_research_manager.unlock_node("unlock_ballista")
	_research_manager.reset_to_defaults()
	var available: Array[ResearchNodeData] = _research_manager.get_available_nodes()
	assert_int(available.size()).is_equal(1)
	assert_str(available[0].node_id).is_equal("unlock_ballista")

