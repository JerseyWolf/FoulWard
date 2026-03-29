## Legacy row shape for `spawn_time_sec`, `enemy_data`, `lane_id`, `path_id`.
## `MissionSpawnRouting.build_spawn_queue` now returns `Array[Dictionary]` with the same keys.

class_name SpawnQueueRow
extends RefCounted

var spawn_time_sec: float = 0.0
var enemy_data: EnemyData = null
var lane_id: String = ""
var path_id: String = ""
