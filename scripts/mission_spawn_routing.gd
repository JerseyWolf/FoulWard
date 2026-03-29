## Path/lane resolution + spawn queue construction for data-driven waves.

class_name MissionSpawnRouting
extends RefCounted

const _SpawnQueueRowScript: Script = preload("res://scripts/spawn_queue_row.gd")


static func _path_accepts_enemy(path_data: Resource, enemy_data: EnemyData) -> bool:
	if path_data == null or enemy_data == null:
		return false
	var mask: int = int(path_data.body_types_allowed)
	if mask == 0:
		return true
	var bit: int = 1 << int(enemy_data.body_type)
	return (mask & bit) != 0


static func resolve_path_for_spawn(
		entry: Resource,
		routing: Resource,
		rng: RandomNumberGenerator,
		enemy_data: EnemyData
) -> String:
	if entry == null or enemy_data == null:
		return ""

	var explicit_path: String = str(entry.path_id).strip_edges()
	if not explicit_path.is_empty():
		if routing == null:
			return explicit_path
		var p_direct: Resource = routing.call("get_path_by_id", explicit_path) as Resource
		if p_direct == null:
			push_warning("MissionSpawnRouting: path_id '%s' not found in routing." % explicit_path)
			return ""
		if not _path_accepts_enemy(p_direct, enemy_data):
			push_warning(
					"MissionSpawnRouting: path '%s' rejects body_type %s"
					% [explicit_path, str(enemy_data.body_type)]
			)
			return ""
		return explicit_path

	var lane_key: String = str(entry.lane_id).strip_edges()
	if lane_key.is_empty() or routing == null:
		return ""

	var lane: Resource = routing.call("get_lane_by_id", lane_key) as Resource
	if lane == null:
		push_warning("MissionSpawnRouting: lane_id '%s' not found in routing." % lane_key)
		return ""

	var candidates: Array[String] = []
	var allowed_ids: PackedStringArray = lane.allowed_path_ids
	for i: int in range(allowed_ids.size()):
		var pid: String = str(allowed_ids[i])
		var p: Resource = routing.call("get_path_by_id", pid) as Resource
		if p == null:
			push_warning("MissionSpawnRouting: lane '%s' references unknown path '%s'." % [lane_key, pid])
			continue
		if _path_accepts_enemy(p, enemy_data):
			candidates.append(pid)

	if candidates.is_empty():
		push_warning(
				"MissionSpawnRouting: no valid path for lane '%s' and body_type %s."
				% [lane_key, str(enemy_data.body_type)]
		)
		return ""

	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func build_spawn_queue(
		wave: Resource,
		routing: Resource,
		_enemy_registry: Array[EnemyData],
		seed: int = 0
) -> Array:
	var out: Array = []
	if wave == null:
		return out

	if not validate_wave(wave):
		return out

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed as int

	var entries: Array = wave.spawn_entries as Array
	for entry_v: Variant in entries:
		var entry: Resource = entry_v as Resource
		if entry == null:
			continue
		var base_data: EnemyData = entry.enemy_data as EnemyData
		if base_data == null:
			push_warning("MissionSpawnRouting.build_spawn_queue: spawn entry missing enemy_data")
			continue
		var n: int = maxi(1, int(entry.count))
		for i: int in range(n):
			var row: Variant = _SpawnQueueRowScript.new()
			row.spawn_time_sec = float(entry.start_time_sec) + float(i) * float(entry.interval_sec)
			row.enemy_data = base_data
			row.lane_id = str(entry.lane_id).strip_edges()
			row.path_id = resolve_path_for_spawn(entry, routing, rng, base_data)
			out.append(row)

	out.sort_custom(func(a: Variant, b: Variant) -> bool:
		return float(a.spawn_time_sec) < float(b.spawn_time_sec)
	)
	return out


static func validate_routing(routing: Resource) -> bool:
	if routing == null:
		push_warning("MissionSpawnRouting.validate_routing: routing is null.")
		return false
	var seen_paths: Dictionary = {}
	var paths: Array = routing.paths as Array
	for p_v: Variant in paths:
		var p: Resource = p_v as Resource
		if p == null:
			push_warning("MissionSpawnRouting.validate_routing: null path in paths array.")
			return false
		var pid: String = str(p.id).strip_edges()
		if pid.is_empty():
			push_warning("MissionSpawnRouting.validate_routing: path with empty id.")
			return false
		if seen_paths.has(pid):
			push_warning("MissionSpawnRouting.validate_routing: duplicate path id '%s'." % pid)
			return false
		seen_paths[pid] = true

	var seen_lanes: Dictionary = {}
	var lanes: Array = routing.lanes as Array
	for l_v: Variant in lanes:
		var l: Resource = l_v as Resource
		if l == null:
			push_warning("MissionSpawnRouting.validate_routing: null lane in lanes array.")
			return false
		var lid: String = str(l.id).strip_edges()
		if lid.is_empty():
			push_warning("MissionSpawnRouting.validate_routing: lane with empty id.")
			return false
		if seen_lanes.has(lid):
			push_warning("MissionSpawnRouting.validate_routing: duplicate lane id '%s'." % lid)
			return false
		seen_lanes[lid] = true
		var allowed_ids: PackedStringArray = l.allowed_path_ids
		for i: int in range(allowed_ids.size()):
			var pid: String = str(allowed_ids[i])
			if not seen_paths.has(pid):
				push_warning(
						"MissionSpawnRouting.validate_routing: lane '%s' references unknown path '%s'."
						% [lid, pid]
				)
				return false

	return true


static func validate_wave(wave: Resource) -> bool:
	if wave == null:
		push_warning("MissionSpawnRouting.validate_wave: wave is null.")
		return false
	if int(wave.wave_number) < 1:
		push_warning("MissionSpawnRouting.validate_wave: wave_number must be >= 1.")
		return false
	var entries: Array = wave.spawn_entries as Array
	for e_v: Variant in entries:
		var e: Resource = e_v as Resource
		if e == null:
			push_warning("MissionSpawnRouting.validate_wave: null SpawnEntryData.")
			return false
		if int(e.count) < 1:
			push_warning("MissionSpawnRouting.validate_wave: count must be >= 1.")
			return false
		if float(e.start_time_sec) < 0.0:
			push_warning("MissionSpawnRouting.validate_wave: start_time_sec must be >= 0.")
			return false
		if float(e.interval_sec) < 0.0:
			push_warning("MissionSpawnRouting.validate_wave: interval_sec must be >= 0.")
			return false
	return true


static func validate_mission(data: Resource) -> bool:
	if data == null:
		push_warning("MissionSpawnRouting.validate_mission: mission data is null.")
		return false
	var routing: Resource = data.routing as Resource
	if routing == null:
		push_warning("MissionSpawnRouting.validate_mission: routing is null.")
		return false
	if not validate_routing(routing):
		return false
	var waves: Array = data.waves as Array
	for w_v: Variant in waves:
		var w: Resource = w_v as Resource
		if w == null:
			push_warning("MissionSpawnRouting.validate_mission: null WaveData in waves.")
			return false
		if not validate_wave(w):
			return false
	return true
