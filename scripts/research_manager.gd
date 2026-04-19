## ResearchManager — Owns the research tree state and gates locked buildings; spending flows through EconomyManager.
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
## Dev flag: unlocks all research nodes at startup; must be false for release builds.
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
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	SignalBus.resource_changed.connect(_on_resource_changed)
	SignalBus.research_points_changed.emit(EconomyManager.get_research_material())


func _on_resource_changed(resource_type: Types.ResourceType, new_amount: int) -> void:
	if resource_type == Types.ResourceType.RESEARCH_MATERIAL:
		SignalBus.research_points_changed.emit(new_amount)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Prompt 11: current research material available for unlocks (same wallet as meta).
func get_research_points() -> int:
	return EconomyManager.get_research_material()


## Prompt 11: awards research material and emits [signal SignalBus.research_points_changed] via EconomyManager.
func add_research_points(amount: int) -> void:
	if amount <= 0:
		push_warning("ResearchManager.add_research_points: non-positive amount %d" % amount)
		return
	EconomyManager.add_research_material(amount)


## True if this node could be unlocked right now (material, prereqs, not already unlocked).
func can_unlock(node_id: String) -> bool:
	var node_data: ResearchNodeData = _find_node(node_id)
	if node_data == null:
		return false
	if is_unlocked(node_id):
		return false
	for prereq_id: String in node_data.prerequisite_ids:
		if not is_unlocked(prereq_id):
			return false
	var eff_cost: int = _effective_research_cost(node_data)
	return EconomyManager.get_research_material() >= eff_cost


## Prompt 11 alias for [method unlock_node].
func unlock(node_id: String) -> void:
	unlock_node(node_id)


## Opens the in-mission research panel and scrolls to the given node when possible.
func show_research_panel_for(node_id: String) -> void:
	if not is_inside_tree():
		return
	var panel: Node = get_tree().get_first_node_in_group("research_panel")
	if panel == null:
		return
	if panel.has_method("show_panel"):
		panel.call("show_panel")
	if node_id.strip_edges() != "" and panel.has_method("scroll_to_node"):
		panel.call_deferred("scroll_to_node", node_id)


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

	var eff_cost: int = _effective_research_cost(node_data)
	if EconomyManager.get_research_material() < eff_cost:
		return false

	var spent: bool = EconomyManager.spend_research_material(eff_cost)
	if not spent:
		push_warning("ResearchManager: spend_research_material failed after balance check")
		return false

	_unlocked_nodes.append(node_id)
	SignalBus.research_unlocked.emit(node_id)
	SignalBus.research_node_unlocked.emit(node_id)
	_unlock_building_for_node(node_id)

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


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	return {"unlocked_node_ids": _unlocked_nodes.duplicate()}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	_unlocked_nodes.clear()
	var arr: Variant = data.get("unlocked_node_ids", [])
	if arr is Array:
		for x: Variant in arr as Array:
			if x is String:
				_unlocked_nodes.append(x as String)


# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _find_node(node_id: String) -> ResearchNodeData:
	for node_data: ResearchNodeData in research_nodes:
		if node_data.node_id == node_id:
			return node_data
	return null


func _effective_research_cost(node_data: ResearchNodeData) -> int:
	var eff_cost: int = int(
		ceilf(
			float(node_data.research_cost)
			* GameManager.get_aggregate_research_cost_multiplier()
			* ChronicleManager.get_chronicle_research_cost_multiplier()
		)
	)
	if eff_cost < 1:
		eff_cost = 1
	return eff_cost


func _unlock_building_for_node(node_id: String) -> void:
	if node_id.strip_edges() == "":
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var hg: Node = tree.get_first_node_in_group("hex_grid")
	if hg is HexGrid:
		for bd: BuildingData in (hg as HexGrid).building_data_registry:
			if bd != null and bd.unlock_research_id == node_id:
				bd.is_locked = false

