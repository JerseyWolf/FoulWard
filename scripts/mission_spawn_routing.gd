## Path/lane resolution + spawn queue construction for data-driven waves.
## Design doc "PathData" maps to `RoutePathData` (`path_data.gd`) — avoids Godot built-in `PathData`.

class_name MissionSpawnRouting
extends RefCounted


static func _get_path_from_routing(routing: Resource, path_id: String) -> RoutePathData:
	if routing == null:
		return null
	if routing is MissionRoutingData:
		return (routing as MissionRoutingData).get_path_by_id(path_id)
	return routing.call("get_path_by_id", path_id) as RoutePathData


static func _get_lane_from_routing(routing: Resource, lane_id: String) -> LaneData:
	if routing == null:
		return null
	if routing is MissionRoutingData:
		return (routing as MissionRoutingData).get_lane_by_id(lane_id)
	return routing.call("get_lane_by_id", lane_id) as LaneData


## `RoutePathData.body_types_allowed` bitmask: ordinal of `enemy_data.body_type` must be allowed (mask 0 = all types). Ordinals follow [enum Types.EnemyBodyType] including [code]SIEGE[/code] / [code]ETHEREAL[/code].
static func _path_accepts_enemy(path: RoutePathData, enemy_data: EnemyData) -> bool:
	if path == null or enemy_data == null:
		return false
	var mask: int = int(path.body_types_allowed)
	if mask == 0:
		return true
	var bit: int = 1 << int(enemy_data.body_type)
	return (mask & bit) != 0


static func resolve_path_for_spawn(
		entry: SpawnEntryData,
		routing: MissionRoutingData,
		rng: RandomNumberGenerator,
		enemy_data: EnemyData
) -> RoutePathData:
	if entry == null or enemy_data == null:
		push_warning("MissionSpawnRouting.resolve_path_for_spawn: entry or enemy_data is null.")
		return null

	var explicit_path: String = str(entry.path_id).strip_edges()
	if not explicit_path.is_empty():
		if routing == null:
			push_warning("MissionSpawnRouting.resolve_path_for_spawn: path_id set but routing is null.")
			return null
		var p_direct: RoutePathData = _get_path_from_routing(routing, explicit_path)
		if p_direct == null:
			push_warning("MissionSpawnRouting: path_id '%s' not found in routing." % explicit_path)
			return null
		if not _path_accepts_enemy(p_direct, enemy_data):
			push_warning(
					"MissionSpawnRouting: path '%s' rejects body_type %s"
					% [explicit_path, str(enemy_data.body_type)]
			)
			return null
		return p_direct

	var lane_key: String = str(entry.lane_id).strip_edges()
	if lane_key.is_empty() or routing == null:
		push_warning("MissionSpawnRouting.resolve_path_for_spawn: lane_id empty or routing is null.")
		return null

	var lane: LaneData = _get_lane_from_routing(routing, lane_key)
	if lane == null:
		push_warning("MissionSpawnRouting: lane_id '%s' not found in routing." % lane_key)
		return null

	var candidates: Array[RoutePathData] = []
	var allowed_ids: PackedStringArray = lane.allowed_path_ids
	for i: int in range(allowed_ids.size()):
		var pid: String = str(allowed_ids[i]).strip_edges()
		if pid.is_empty():
			continue
		var p: RoutePathData = _get_path_from_routing(routing, pid)
		if p == null:
			push_warning("MissionSpawnRouting: lane '%s' references unknown path '%s'." % [lane_key, pid])
			continue
		if _path_accepts_enemy(p, enemy_data):
			candidates.append(p)

	if candidates.is_empty():
		push_warning(
				"MissionSpawnRouting: no valid path for lane '%s' and body_type %s."
				% [lane_key, str(enemy_data.body_type)]
		)
		return null

	return candidates[rng.randi_range(0, candidates.size() - 1)]


static func build_spawn_queue(
		wave: WaveData,
		routing: MissionRoutingData,
		seed: int = 0
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if wave == null:
		return out

	var wave_issues: Array[String] = validate_wave(wave)
	if not wave_issues.is_empty():
		for msg: String in wave_issues:
			push_warning("MissionSpawnRouting.build_spawn_queue: %s" % msg)
		return out

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed as int

	var w: WaveData = wave
	var entries: Array[SpawnEntryData] = w.spawn_entries
	for entry: SpawnEntryData in entries:
		if entry == null:
			continue
		var base_data: EnemyData = entry.enemy_data as EnemyData
		if base_data == null:
			push_warning("MissionSpawnRouting.build_spawn_queue: spawn entry missing enemy_data")
			continue
		var n: int = maxi(1, int(entry.count))
		var variance: float = maxf(0.0, float(entry.spawn_offset_variance_sec))
		for i: int in range(n):
			var t: float = float(entry.start_time_sec) + float(i) * float(entry.interval_sec)
			if variance > 0.0:
				t += rng.randf_range(-variance, variance)
			var path_res: RoutePathData = resolve_path_for_spawn(entry, routing, rng, base_data)
			var path_id_str: String = path_res.id if path_res != null else ""
			var row: Dictionary = {
				"spawn_time_sec": t,
				"enemy_data": base_data,
				"lane_id": str(entry.lane_id).strip_edges(),
				"path_id": path_id_str,
			}
			out.append(row)

	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["spawn_time_sec"]) < float(b["spawn_time_sec"])
	)
	return out


static func validate_routing(routing: MissionRoutingData) -> Array[String]:
	var out: Array[String] = []
	if routing == null:
		out.append("routing is null")
		return out
	var seen_paths: Dictionary = {}
	var paths: Array = routing.paths as Array
	for p_v: Variant in paths:
		var p: RoutePathData = p_v as RoutePathData
		if p == null:
			out.append("null path in paths array")
			continue
		var pid: String = str(p.id).strip_edges()
		if pid.is_empty():
			out.append("path with empty id")
			continue
		if seen_paths.has(pid):
			out.append("duplicate path id '%s'" % pid)
			continue
		seen_paths[pid] = true

	var seen_lanes: Dictionary = {}
	var lanes: Array = routing.lanes as Array
	for l_v: Variant in lanes:
		var l: LaneData = l_v as LaneData
		if l == null:
			out.append("null lane in lanes array")
			continue
		var lid: String = str(l.id).strip_edges()
		if lid.is_empty():
			out.append("lane with empty id")
			continue
		if seen_lanes.has(lid):
			out.append("duplicate lane id '%s'" % lid)
			continue
		seen_lanes[lid] = true
		var allowed_ids: PackedStringArray = l.allowed_path_ids
		for i: int in range(allowed_ids.size()):
			var apid: String = str(allowed_ids[i]).strip_edges()
			if apid.is_empty():
				out.append("lane '%s': allowed_path_ids contains an empty entry" % lid)
				continue
			if not seen_paths.has(apid):
				out.append("lane '%s' references unknown path '%s'" % [lid, apid])

	return out


static func validate_wave(wave: WaveData) -> Array[String]:
	var out: Array[String] = []
	if wave == null:
		out.append("wave is null")
		return out
	if int(wave.wave_number) < 1:
		out.append("wave_number must be >= 1")
	var entries: Array[SpawnEntryData] = wave.spawn_entries
	for e: SpawnEntryData in entries:
		if e == null:
			out.append("null SpawnEntryData in spawn_entries")
			continue
		if e.enemy_data == null:
			out.append("spawn entry missing enemy_data")
		if int(e.count) < 1:
			out.append("count must be >= 1")
		if float(e.start_time_sec) < 0.0:
			out.append("start_time_sec must be >= 0")
		if float(e.interval_sec) < 0.0:
			out.append("interval_sec must be >= 0 (invalid interval)")
		if float(e.spawn_offset_variance_sec) < 0.0:
			out.append("spawn_offset_variance_sec must be >= 0")
	return out


static func validate_mission(data: Resource) -> bool:
	if data == null:
		push_warning("MissionSpawnRouting.validate_mission: mission data is null.")
		return false
	var routing: MissionRoutingData = data.routing as MissionRoutingData
	if routing == null:
		push_warning("MissionSpawnRouting.validate_mission: routing is null.")
		return false
	if not validate_routing(routing).is_empty():
		return false
	var waves: Array = data.waves as Array
	for w_v: Variant in waves:
		var w: WaveData = w_v as WaveData
		if w == null:
			push_warning("MissionSpawnRouting.validate_mission: null WaveData in waves.")
			return false
		if not validate_wave(w).is_empty():
			return false
	return true
