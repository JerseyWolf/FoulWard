## wave_data.gd
## Authoring block for a single combat wave.

class_name WaveData
extends Resource

@export var wave_number: int = 1
@export var display_name: String = ""
@export var description: String = ""

@export var spawn_entries: Array[SpawnEntryData] = []

@export var pre_wave_delay_sec: float = 0.0
@export var post_wave_grace_sec: float = 0.0

@export var reward_gold_override: int = -1
@export var reward_material_override: int = -1

@export var recommended_tags: PackedStringArray = PackedStringArray()
@export var simbot_label: String = ""


## Sum of `count` across non-null spawn entries (ignores null entries).
func get_total_enemy_count() -> int:
	var total: int = 0
	var i: int = 0
	while i < spawn_entries.size():
		var e: SpawnEntryData = spawn_entries[i]
		if e != null:
			total += maxi(0, e.count)
		i += 1
	return total


## Total gold bounty if every spawned enemy is killed (uses `EnemyData.get_effective_bounty_gold()`).
func get_total_bounty_gold() -> int:
	var total: int = 0
	var i: int = 0
	while i < spawn_entries.size():
		var e: SpawnEntryData = spawn_entries[i]
		if e != null and e.enemy_data != null:
			var per: int = e.enemy_data.get_effective_bounty_gold()
			total += maxi(0, e.count) * maxi(0, per)
		i += 1
	return total


## Counts tag strings from each spawn row and from referenced `enemy_data.tags`, multiplied by spawn `count`.
func get_enemy_tag_histogram() -> Dictionary:
	var hist: Dictionary = {}
	var i: int = 0
	while i < spawn_entries.size():
		var e: SpawnEntryData = spawn_entries[i]
		if e == null:
			i += 1
			continue
		var n: int = maxi(0, e.count)
		var ti: int = 0
		while ti < e.tags.size():
			var t: String = str(e.tags[ti]).strip_edges()
			if not t.is_empty():
				hist[t] = int(hist.get(t, 0)) + n
			ti += 1
		if e.enemy_data != null:
			var ei: int = 0
			while ei < e.enemy_data.tags.size():
				var et: String = str(e.enemy_data.tags[ei]).strip_edges()
				if not et.is_empty():
					hist[et] = int(hist.get(et, 0)) + n
				ei += 1
		i += 1
	return hist


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if wave_number < 1:
		out.append("wave_number should be >= 1")
	if spawn_entries.is_empty():
		out.append("spawn_entries is empty (no enemies will spawn)")
	var i: int = 0
	while i < spawn_entries.size():
		var e: SpawnEntryData = spawn_entries[i]
		if e == null:
			out.append("spawn_entries[%d] is null" % i)
		else:
			out.append_array(e.collect_validation_warnings())
		i += 1
	return out
