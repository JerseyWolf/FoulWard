## mission_routing_data.gd
## Lanes + paths for a single mission instance.

class_name MissionRoutingData
extends Resource

@export var mission_id: String = ""

@export var lanes: Array[LaneData] = []
@export var paths: Array[RoutePathData] = []


func get_lane_by_id(lane_id: String) -> LaneData:
	var i: int = 0
	while i < lanes.size():
		var l: LaneData = lanes[i]
		if l != null and l.id == lane_id:
			return l
		i += 1
	return null


func get_path_by_id(path_id: String) -> RoutePathData:
	var i: int = 0
	while i < paths.size():
		var p: RoutePathData = paths[i]
		if p != null and p.id == path_id:
			return p
		i += 1
	return null


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if mission_id.is_empty():
		out.append("mission_id is empty")
	if lanes.is_empty():
		out.append("lanes is empty")
	if paths.is_empty():
		out.append("paths is empty")
	var lane_id_set: Dictionary = {}
	var i: int = 0
	while i < lanes.size():
		var l: LaneData = lanes[i]
		if l == null:
			out.append("lanes[%d] is null" % i)
		else:
			out.append_array(l.collect_validation_warnings())
			var lid: String = l.id.strip_edges()
			if not lid.is_empty():
				lane_id_set[lid] = true
		i += 1
	var j: int = 0
	while j < paths.size():
		var p: RoutePathData = paths[j]
		if p == null:
			out.append("paths[%d] is null" % j)
		else:
			out.append_array(p.collect_validation_warnings())
			var plid: String = p.lane_id.strip_edges()
			if not plid.is_empty() and not lane_id_set.has(plid):
				out.append("paths[%d]: lane_id '%s' not found in lanes" % [j, plid])
		j += 1
	return out
