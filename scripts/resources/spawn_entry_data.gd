## spawn_entry_data.gd
## One spawn line inside a wave: enemy type, cadence, and routing hints.

class_name SpawnEntryData
extends Resource

@export var enemy_data: EnemyData = null
@export var count: int = 1
@export var start_time_sec: float = 0.0
@export var interval_sec: float = 0.5

@export var lane_id: String = ""
@export var path_id: String = ""
## Jitter applied to each spawn instant (±seconds).
@export var spawn_offset_variance_sec: float = 0.0

@export var tags: PackedStringArray = PackedStringArray()


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if enemy_data == null:
		out.append("enemy_data is null")
	if count < 1:
		out.append("count < 1")
	if interval_sec < 0.0:
		out.append("interval_sec is negative")
	if spawn_offset_variance_sec < 0.0:
		out.append("spawn_offset_variance_sec is negative")
	return out
