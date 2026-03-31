## ally_manager.gd
## Tracks summoner-building squads and spawns AllyBase instances from BuildingData paths.

extends Node

const ALLY_SCENE_PATH: String = "res://scenes/allies/ally_base.tscn"

# building_instance_id (placed_instance_id) -> Array of AllyBase node refs
var _squads: Dictionary = {}


func spawn_squad(building: BuildingBase) -> void:
	if building == null or not is_instance_valid(building):
		return
	var bd: BuildingData = building.get_building_data()
	if bd == null or not bd.is_summoner:
		return

	var leader_data: AllyData = _resolve_summon_leader_data(bd)
	if leader_data == null:
		push_warning("AllyManager.spawn_squad: no leader AllyData for building '%s'" % bd.building_id)
		return

	var follower_data: AllyData = _resolve_summon_follower_data(bd)
	var squad: Array = []

	var leader: AllyBase = _spawn_ally(leader_data, building)
	if leader == null:
		return
	squad.append(leader)

	var extra: int = maxi(0, bd.summon_squad_size - 1)
	for _i in range(extra):
		var fdata: AllyData = follower_data if follower_data != null else leader_data
		var follower: AllyBase = _spawn_ally(fdata, building)
		if follower != null:
			squad.append(follower)

	_squads[building.placed_instance_id] = squad


func _resolve_summon_leader_data(bd: BuildingData) -> AllyData:
	if bd.summon_leader_data != null:
		return bd.summon_leader_data
	var p: String = bd.summon_leader_data_path.strip_edges()
	if p.is_empty() or not ResourceLoader.exists(p):
		return null
	var res: Resource = load(p)
	return res as AllyData


func _resolve_summon_follower_data(bd: BuildingData) -> AllyData:
	if bd.summon_follower_data != null:
		return bd.summon_follower_data
	var p: String = bd.summon_follower_data_path.strip_edges()
	if p.is_empty() or not ResourceLoader.exists(p):
		return null
	var res: Resource = load(p)
	return res as AllyData


func _spawn_ally(data: AllyData, building: BuildingBase) -> AllyBase:
	var scene: PackedScene = load(ALLY_SCENE_PATH) as PackedScene
	var ally: AllyBase = scene.instantiate() as AllyBase
	if ally == null:
		push_error("AllyManager._spawn_ally: ally_base.tscn root is not AllyBase")
		return null

	ally.patrol_anchor = building.global_position
	ally.owning_building_instance_id = building.placed_instance_id

	var parent: Node = get_tree().root.get_node_or_null("Main/AllyContainer")
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		parent = get_tree().root

	parent.add_child(ally)

	var ox: float = randf_range(-2.0, 2.0)
	var oz: float = randf_range(-2.0, 2.0)
	ally.global_position = building.global_position + Vector3(ox, 0.0, oz)

	var ally_id_str: String = data.ally_id.strip_edges() if data != null else ""
	ally.ally_died.connect(_on_ally_died.bind(building.placed_instance_id, ally_id_str, ally))
	ally.initialize_ally_data(data)
	return ally


func despawn_squad(building_instance_id: String) -> void:
	if building_instance_id.strip_edges().is_empty():
		return
	if not _squads.has(building_instance_id):
		return
	var squad_copy: Array = _squads[building_instance_id]
	_squads.erase(building_instance_id)
	for node: Variant in squad_copy:
		var ally: AllyBase = node as AllyBase
		if ally != null and is_instance_valid(ally):
			ally.queue_free()


func _on_ally_died(building_instance_id: String, ally_id_str: String, dead_ally: AllyBase) -> void:
	if not _squads.has(building_instance_id):
		return

	var squad: Array = _squads[building_instance_id]
	var new_squad: Array = []
	for node: Variant in squad:
		var a: AllyBase = node as AllyBase
		if a == null:
			continue
		if a == dead_ally:
			continue
		if is_instance_valid(a) and not a.is_queued_for_deletion():
			new_squad.append(a)

	_squads[building_instance_id] = new_squad

	var aid: String = ally_id_str
	if aid.is_empty() and dead_ally != null and is_instance_valid(dead_ally):
		var ad: AllyData = dead_ally.ally_data as AllyData
		if ad != null:
			aid = ad.ally_id.strip_edges()

	SignalBus.ally_died.emit(aid, building_instance_id)

	if new_squad.is_empty():
		_squads.erase(building_instance_id)
		SignalBus.ally_squad_wiped.emit(building_instance_id)
