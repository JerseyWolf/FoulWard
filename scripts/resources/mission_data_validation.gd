## mission_data_validation.gd
## Authoring validation for mission resources: non-destructive, returns human-readable issues.

class_name MissionDataValidation
extends RefCounted


static func is_non_empty_id(id: String) -> bool:
	return not id.strip_edges().is_empty()


static func validate_mission_waves(data: MissionWavesData) -> PackedStringArray:
	if data == null:
		return PackedStringArray(["MissionWavesData is null"])
	return data.collect_validation_warnings()


static func validate_mission_routing(data: MissionRoutingData) -> PackedStringArray:
	if data == null:
		return PackedStringArray(["MissionRoutingData is null"])
	return data.collect_validation_warnings()


static func validate_mission_economy(data: MissionEconomyData) -> PackedStringArray:
	if data == null:
		return PackedStringArray(["MissionEconomyData is null"])
	return data.collect_validation_warnings()


static func validate_spawn_entry(data: SpawnEntryData) -> PackedStringArray:
	if data == null:
		return PackedStringArray(["SpawnEntryData is null"])
	return data.collect_validation_warnings()


## Validates `MissionData` (routing + wave list). Does not mutate resources. Empty array = OK.
static func validate_mission(data: MissionData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if data == null:
		out.append("MissionData is null")
		return out
	if data.waves.is_empty():
		out.append("MissionData.waves is empty")
	out.append_array(validate_routing(data.routing))
	var seen_wave_numbers: Dictionary = {}
	var i: int = 0
	while i < data.waves.size():
		var w: WaveData = data.waves[i]
		if w == null:
			out.append("waves[%d]: entry is null" % i)
			i += 1
			continue
		var prefix: String = "waves[%d] (wave_number=%d)" % [i, w.wave_number]
		if seen_wave_numbers.has(w.wave_number):
			out.append(
					"%s: duplicate wave_number %d (also used at index %d)"
					% [prefix, w.wave_number, int(seen_wave_numbers[w.wave_number])]
			)
		else:
			seen_wave_numbers[w.wave_number] = i
		var wave_errs: PackedStringArray = validate_wave(w)
		var j: int = 0
		while j < wave_errs.size():
			out.append("%s: %s" % [prefix, wave_errs[j]])
			j += 1
		i += 1
	return out


## Full routing graph checks: ids, duplicates, lane → path references.
static func validate_routing(routing: MissionRoutingData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if routing == null:
		out.append("MissionRoutingData is null")
		return out
	var base: PackedStringArray = routing.collect_validation_warnings()
	var k: int = 0
	while k < base.size():
		out.append(base[k])
		k += 1

	var path_ids: Dictionary = {}
	var pi: int = 0
	while pi < routing.paths.size():
		var p: RoutePathData = routing.paths[pi]
		if p == null:
			out.append("paths[%d] is null" % pi)
			pi += 1
			continue
		var pid: String = p.id.strip_edges()
		if pid.is_empty():
			out.append("paths[%d]: RoutePathData.id is empty" % pi)
		elif path_ids.has(pid):
			out.append("duplicate RoutePathData id '%s' (paths[%d] and paths[%d])" % [pid, int(path_ids[pid]), pi])
		else:
			path_ids[pid] = pi
		pi += 1

	var lane_ids: Dictionary = {}
	var li: int = 0
	while li < routing.lanes.size():
		var lane: LaneData = routing.lanes[li]
		if lane == null:
			out.append("lanes[%d] is null" % li)
			li += 1
			continue
		var lid: String = lane.id.strip_edges()
		if lid.is_empty():
			out.append("lanes[%d]: LaneData.id is empty" % li)
		elif lane_ids.has(lid):
			out.append("duplicate LaneData id '%s' (lanes[%d] and lanes[%d])" % [lid, int(lane_ids[lid]), li])
		else:
			lane_ids[lid] = li

		var ap_idx: int = 0
		var allowed: PackedStringArray = lane.allowed_path_ids
		while ap_idx < allowed.size():
			var apid: String = str(allowed[ap_idx]).strip_edges()
			if apid.is_empty():
				out.append("lane '%s': allowed_path_ids contains an empty string" % lid)
			elif not path_ids.has(apid):
				out.append("lane '%s': allowed_path_ids references unknown path id '%s'" % [lid, apid])
			ap_idx += 1
		li += 1
	return out


## Validates a single wave (spawn entries, timing, enemy refs). Does not mutate.
static func validate_wave(wave: WaveData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if wave == null:
		out.append("WaveData is null")
		return out
	var base: PackedStringArray = wave.collect_validation_warnings()
	var i: int = 0
	while i < base.size():
		out.append(base[i])
		i += 1

	var ei: int = 0
	while ei < wave.spawn_entries.size():
		var e: SpawnEntryData = wave.spawn_entries[ei]
		var eprefix: String = "spawn_entries[%d]" % ei
		if e == null:
			out.append("%s is null" % eprefix)
			ei += 1
			continue
		if e.enemy_data == null:
			out.append("%s: enemy_data is null" % eprefix)
		else:
			var ed: EnemyData = e.enemy_data
			if ed.max_hp <= 0:
				out.append("%s: enemy_data.max_hp should be > 0" % eprefix)
		if e.interval_sec < 0.0:
			out.append("%s: interval_sec must be >= 0" % eprefix)
		if e.spawn_offset_variance_sec < 0.0:
			out.append("%s: spawn_offset_variance_sec must be >= 0" % eprefix)
		ei += 1

	if wave.pre_wave_delay_sec < 0.0:
		out.append("pre_wave_delay_sec is negative")
	if wave.post_wave_grace_sec < 0.0:
		out.append("post_wave_grace_sec is negative")
	return out
