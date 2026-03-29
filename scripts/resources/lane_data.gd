## lane_data.gd
## Logical lane from map edge toward Florence (threat weighting, allowed paths).

class_name LaneData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""

## Tag used when an enemy reaches Florence through this lane (analytics / VFX hooks).
@export var florence_entry_tag: String = ""

@export var threat_weight: float = 1.0
@export var allowed_path_ids: PackedStringArray = PackedStringArray()

@export var tags: PackedStringArray = PackedStringArray()


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if id.is_empty():
		out.append("lane id is empty")
	if threat_weight < 0.0:
		out.append("threat_weight is negative")
	return out
