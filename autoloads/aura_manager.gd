## AuraManager — registers aura towers and resolves damage/speed bonuses from BuildingData (Prompt 50).
## Autoload singleton only (no `class_name` — avoids shadowing the `/root/AuraManager` node in GdUnit).
extends Node

# Registered aura emitters: placed_instance_id -> {building: BuildingBase, data: BuildingData}
var _emitters: Dictionary = {}

# enemy_instance_id -> {enemy: EnemyBase, tag: String, params: Dictionary}
var _enemy_emitters: Dictionary = {}


func register_aura(building: BuildingBase) -> void:
	var bd: BuildingData = building.get_building_data()
	if bd == null or not bd.is_aura:
		return
	var key: String = building.placed_instance_id
	if key.is_empty():
		push_warning("AuraManager.register_aura: empty placed_instance_id")
		return
	_emitters[key] = {
		"building": building,
		"data": bd,
	}
	_apply_aura(building)


func deregister_aura(building_instance_id: String) -> void:
	if building_instance_id.is_empty():
		return
	if not _emitters.has(building_instance_id):
		return
	var entry: Dictionary = _emitters[building_instance_id] as Dictionary
	var b: BuildingBase = entry.get("building") as BuildingBase
	_emitters.erase(building_instance_id)
	if is_instance_valid(b):
		_remove_aura(b)


## Combined fractional damage bonus from [code]damage_pct[/code] auras covering this building (strongest per [member BuildingData.aura_category], then summed).
func get_damage_pct_bonus(building: BuildingBase) -> float:
	if building == null:
		return 0.0
	var by_category: Dictionary = {}
	for id in _emitters:
		var entry: Dictionary = _emitters[id] as Dictionary
		var emitter: BuildingBase = entry.get("building") as BuildingBase
		var bd: BuildingData = entry.get("data") as BuildingData
		if not is_instance_valid(emitter) or bd == null:
			continue
		if bd.aura_effect_type != "damage_pct":
			continue
		var dist: float = emitter.global_position.distance_to(building.global_position)
		if dist > bd.aura_radius:
			continue
		var cat: String = bd.aura_category.strip_edges()
		if cat.is_empty():
			cat = "default"
		var val: float = bd.aura_effect_value
		if not by_category.has(cat) or val > float(by_category[cat]):
			by_category[cat] = val
	var total: float = 0.0
	for _c: Variant in by_category.values():
		total += float(_c)
	return total


## Worst (most negative) [code]enemy_speed_pct[/code] modifier at [param world_pos] (XZ plane vs emitters).
func get_enemy_speed_modifier(world_pos: Vector3) -> float:
	var worst: float = 0.0
	for id in _emitters:
		var entry: Dictionary = _emitters[id] as Dictionary
		var emitter: BuildingBase = entry.get("building") as BuildingBase
		var bd: BuildingData = entry.get("data") as BuildingData
		if not is_instance_valid(emitter) or bd == null:
			continue
		if bd.aura_effect_type != "enemy_speed_pct":
			continue
		var dist: float = emitter.global_position.distance_to(world_pos)
		if dist <= bd.aura_radius:
			worst = minf(worst, bd.aura_effect_value)
	return worst


func _apply_aura(building: BuildingBase) -> void:
	var bd: BuildingData = building.get_building_data()
	if bd == null:
		return
	if bd.aura_effect_type == "damage_pct":
		for b: BuildingBase in _get_all_buildings():
			if not is_instance_valid(b):
				continue
			var dist: float = building.global_position.distance_to(b.global_position)
			if dist <= bd.aura_radius:
				b.recompute_all_stats()


func _remove_aura(building: BuildingBase) -> void:
	var bd: BuildingData = building.get_building_data()
	if bd == null:
		return
	if bd.aura_effect_type == "damage_pct":
		for b: BuildingBase in _get_all_buildings():
			if not is_instance_valid(b):
				continue
			var dist: float = building.global_position.distance_to(b.global_position)
			if dist <= bd.aura_radius:
				b.recompute_all_stats()


func _get_all_buildings() -> Array[BuildingBase]:
	var out: Array[BuildingBase] = []
	var root: SceneTree = get_tree()
	if root == null:
		return out
	for n: Node in root.get_nodes_in_group("buildings"):
		var b: BuildingBase = n as BuildingBase
		if b != null and is_instance_valid(b):
			out.append(b)
	return out


## Test helper: clears registry (call from [method GdUnitTestSuite.after_test] when using real autoload).
func clear_all_emitters_for_tests() -> void:
	_emitters.clear()
	_enemy_emitters.clear()


func register_enemy_aura(enemy: EnemyBase, tag: String) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var ed: EnemyData = enemy.get_enemy_data()
	if ed == null:
		return
	var params: Dictionary = ed.special_values.get(tag, {}) as Dictionary
	_enemy_emitters[enemy.instance_id] = {
		"enemy": enemy,
		"tag": tag,
		"params": params,
	}


func deregister_enemy_aura(enemy_instance_id: String) -> void:
	if enemy_instance_id.is_empty():
		return
	_enemy_emitters.erase(enemy_instance_id)


## Fractional damage bonus from nearby war_shamans ([code]aura_buff[/code]) at [param world_pos] (XZ vs emitters).
func get_enemy_damage_bonus(world_pos: Vector2) -> float:
	var total: float = 0.0
	var stale: Array[String] = []
	for id in _enemy_emitters:
		var e: Dictionary = _enemy_emitters[id] as Dictionary
		if str(e.get("tag", "")) != "aura_buff":
			continue
		var emitter_raw: Variant = e.get("enemy")
		if typeof(emitter_raw) != TYPE_OBJECT or not is_instance_valid(emitter_raw as Object):
			stale.append(str(id))
			continue
		var emitter: EnemyBase = emitter_raw as EnemyBase
		var params: Dictionary = e.get("params", {}) as Dictionary
		var radius: float = float(params.get("radius", 8.0))
		var ep: Vector2 = Vector2(emitter.global_position.x, emitter.global_position.z)
		if ep.distance_to(world_pos) <= radius:
			total = maxf(total, float(params.get("damage_pct", 0.0)))
	for sid: String in stale:
		_enemy_emitters.erase(sid)
	return total


## Heal-per-second from plague_shamans / totem_carriers ([code]aura_heal[/code]) at [param world_pos].
func get_enemy_heal_per_sec(world_pos: Vector2) -> float:
	var total: float = 0.0
	var stale: Array[String] = []
	for id in _enemy_emitters:
		var e: Dictionary = _enemy_emitters[id] as Dictionary
		if str(e.get("tag", "")) != "aura_heal":
			continue
		var emitter_raw: Variant = e.get("enemy")
		if typeof(emitter_raw) != TYPE_OBJECT or not is_instance_valid(emitter_raw as Object):
			stale.append(str(id))
			continue
		var emitter: EnemyBase = emitter_raw as EnemyBase
		var params: Dictionary = e.get("params", {}) as Dictionary
		var radius: float = float(params.get("radius", 8.0))
		var ep: Vector2 = Vector2(emitter.global_position.x, emitter.global_position.z)
		if ep.distance_to(world_pos) <= radius:
			total += float(params.get("heal_per_sec", 0.0))
	for sid2: String in stale:
		_enemy_emitters.erase(sid2)
	return total
