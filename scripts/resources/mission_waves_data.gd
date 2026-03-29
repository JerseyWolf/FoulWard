## mission_waves_data.gd
## Bundles all waves for a mission plus starting resources / Florence HP.

class_name MissionWavesData
extends Resource

@export var mission_id: String = ""
@export var display_name: String = ""

@export var waves: Array[WaveData] = []

@export var starting_gold: int = 400
@export var starting_material: int = 20
@export var florence_starting_hp: int = 500

@export var mission_tags: PackedStringArray = PackedStringArray()
## Identifier for hex layout / slot preset (interpreted by mission loader).
@export var layout_preset: String = ""


func get_wave_by_number(wave_number: int) -> WaveData:
	var i: int = 0
	while i < waves.size():
		var w: WaveData = waves[i]
		if w != null and w.wave_number == wave_number:
			return w
		i += 1
	return null


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if mission_id.is_empty():
		out.append("mission_id is empty")
	if waves.is_empty():
		out.append("waves is empty")
	var seen: Dictionary = {}
	var i: int = 0
	while i < waves.size():
		var w: WaveData = waves[i]
		if w == null:
			out.append("waves[%d] is null" % i)
		else:
			if seen.has(w.wave_number):
				out.append(
						"duplicate wave_number %d (waves[%d] and waves[%d])"
						% [w.wave_number, int(seen[w.wave_number]), i]
				)
			else:
				seen[w.wave_number] = i
			out.append_array(w.collect_validation_warnings())
		i += 1
	return out
