## Mission-level spawn + routing. Optional on DayConfig; WaveManager consumes when set.

class_name MissionData
extends Resource

@export var routing: MissionRoutingData = null
@export var waves: Array[WaveData] = []


func get_wave(wave_number: int) -> WaveData:
	for w: WaveData in waves:
		if w != null and w.wave_number == wave_number:
			return w
	return null


func has_wave_entries(wave_number: int) -> bool:
	var w: WaveData = get_wave(wave_number)
	return w != null and not w.spawn_entries.is_empty()
