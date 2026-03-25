# scripts/research_manager.gd
# ResearchManager – owns the research tree state (which nodes are unlocked).
# Loaded from base_structures_tree.tres via the @export array.
# All resource spending goes through EconomyManager.spend_research_material().
# Emits SignalBus.research_unlocked(node_id) on successful unlock.

class_name ResearchManager
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## All research nodes in the game. Populated via editor with base_structures_tree.tres.
@export var research_nodes: Array[ResearchNodeData] = []

# Dev toggle: in dev/test builds, make all towers immediately reachable by
# unlocking every research node when starting a new game.
@export var dev_unlock_all_research: bool = false

## Dev toggle: unlock only anti-air research so Anti-Air Bolt is buildable
## immediately (everything else remains locked behind its research).
## This is intended for faster manual playtesting of early wave survival.
@export var dev_unlock_anti_air_only: bool = false

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _unlocked_nodes: Array[String] = []

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Attempts to unlock the research node with the given node_id.
## Checks prerequisites, research material cost, then applies the unlock.
## Returns true on success, false on any validation failure.
func unlock_node(node_id: String) -> bool:
	var node_data: ResearchNodeData = _find_node(node_id)
	if node_data == null:
		push_warning("ResearchManager.unlock_node: node_id '%s' not found" % node_id)
		return false

	if is_unlocked(node_id):
		push_warning("ResearchManager.unlock_node: '%s' already unlocked" % node_id)
		return false

	# Check all prerequisites are satisfied.
	for prereq_id: String in node_data.prerequisite_ids:
		if not is_unlocked(prereq_id):
			push_warning("ResearchManager.unlock_node: prerequisite '%s' not met for '%s'"
				% [prereq_id, node_id])
			return false

	# Research costs research_material, not gold.
	if EconomyManager.get_research_material() < node_data.research_cost:
		return false

	var spent: bool = EconomyManager.spend_research_material(node_data.research_cost)
	assert(spent, "ResearchManager: spend_research_material failed after balance check")

	_unlocked_nodes.append(node_id)
	SignalBus.research_unlocked.emit(node_id)

	# Florence meta-state hook.
	# ASSUMPTION: GameManager owns FlorenceData and exposes get_florence_data().
	var florence_data := GameManager.get_florence_data()
	if florence_data != null and florence_data.has_unlocked_research == false:
		florence_data.has_unlocked_research = true
		SignalBus.florence_state_changed.emit()
	return true


## Returns true if the node with the given node_id has been unlocked.
func is_unlocked(node_id: String) -> bool:
	return _unlocked_nodes.has(node_id)


## Returns nodes whose prerequisites are all met and that are not yet unlocked.
func get_available_nodes() -> Array[ResearchNodeData]:
	var result: Array[ResearchNodeData] = []
	for node_data: ResearchNodeData in research_nodes:
		if is_unlocked(node_data.node_id):
			continue
		var prereqs_met: bool = true
		for prereq_id: String in node_data.prerequisite_ids:
			if not is_unlocked(prereq_id):
				prereqs_met = false
				break
		if prereqs_met:
			result.append(node_data)
	return result


## Clears all unlocked nodes. Called on new game.
func reset_to_defaults() -> void:
	_unlocked_nodes.clear()
	if dev_unlock_all_research:
		for node_data: ResearchNodeData in research_nodes:
			_unlocked_nodes.append(node_data.node_id)
	elif dev_unlock_anti_air_only:
		_unlocked_nodes.append("unlock_anti_air")

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _find_node(node_id: String) -> ResearchNodeData:
	for node_data: ResearchNodeData in research_nodes:
		if node_data.node_id == node_id:
			return node_data
	return null

