## wave_composer.gd
## Builds per-wave enemy lists from [EnemyData] point_cost, wave_tags, and tier.

class_name WaveComposer
extends RefCounted

var enemy_data_registry: Array[EnemyData] = []
## [WavePatternData] resource instance (untyped so script exports are visible at runtime in headless runs).
var pattern: Variant = null


func _init(registry: Array[EnemyData], pattern_res: Resource) -> void:
	enemy_data_registry = registry
	pattern = pattern_res


func compose_wave(wave_index: int, budget_scale: float = 1.0) -> Array[EnemyData]:
	var budget: int = maxi(1, int(floor(float(_compute_budget_for_wave(wave_index)) * maxf(0.01, budget_scale))))
	var primary_tag: String = _get_primary_tag(wave_index)
	var modifiers: Array[String] = _get_modifiers(wave_index)
	var pool: Array[EnemyData] = _build_candidate_pool(primary_tag, modifiers, wave_index)
	if pool.is_empty():
		push_warning(
				"WaveComposer: empty candidate pool for wave %d (tag=%s)" % [wave_index, primary_tag]
		)
		return []

	var result: Array[EnemyData] = []
	var safety: int = 256

	while budget > 0 and safety > 0:
		safety -= 1
		var candidate: EnemyData = _pick_enemy_for_wave(pool, wave_index)
		if candidate == null:
			break
		if candidate.point_cost > budget and result.size() > 0:
			break
		if candidate.point_cost > budget and result.size() == 0:
			result.append(candidate)
			break

		result.append(candidate)
		budget -= candidate.point_cost

	return result


func _compute_budget_for_wave(wave_index: int) -> int:
	var p: Object = pattern as Object
	var base_v: Variant = p.get("base_point_budget")
	var per_v: Variant = p.get("budget_per_wave")
	var base_budget: int = floori(float(base_v)) if base_v != null else 40
	var per_wave: int = floori(float(per_v)) if per_v != null else 8
	var wave_number: int = wave_index + 1
	return base_budget + per_wave * wave_number


func _get_primary_tag(wave_index: int) -> String:
	var p: Object = pattern as Object
	var tags_v: Variant = p.get("wave_primary_tags")
	if tags_v == null or not (tags_v is Array):
		return "INVASION"
	var tags: Array = tags_v as Array
	if tags.is_empty():
		return "INVASION"
	if wave_index >= tags.size():
		return str(tags.back())
	return str(tags[wave_index])


func _get_modifiers(wave_index: int) -> Array[String]:
	var p: Object = pattern as Object
	var mods_v: Variant = p.get("wave_modifiers")
	if mods_v == null or not (mods_v is Array):
		return []
	var mods_outer: Array = mods_v as Array
	if mods_outer.is_empty():
		return []
	var row: Variant
	if wave_index >= mods_outer.size():
		row = mods_outer.back()
	else:
		row = mods_outer[wave_index]
	if row == null or not (row is Array):
		return []
	var inner: Array = row as Array
	var out: Array[String] = []
	for item: Variant in inner:
		out.append(str(item))
	return out


func _build_candidate_pool(
		primary_tag: String,
		modifiers: Array[String],
		wave_index: int
) -> Array[EnemyData]:
	var pool: Array[EnemyData] = []
	for ed: EnemyData in enemy_data_registry:
		if not _enemy_matches_primary_tag(ed, primary_tag):
			continue
		if not _enemy_passes_modifiers(ed, modifiers, wave_index):
			continue
		pool.append(ed)
	if pool.is_empty():
		for ed2: EnemyData in enemy_data_registry:
			if primary_tag in ed2.wave_tags:
				pool.append(ed2)
	return pool


func _enemy_matches_primary_tag(ed: EnemyData, primary_tag: String) -> bool:
	if primary_tag == "MIXED":
		return true
	return primary_tag in ed.wave_tags


func _enemy_passes_modifiers(ed: EnemyData, modifiers: Array[String], _wave_index: int) -> bool:
	var t: int = ed.tier
	if "NO_TIER_3" in modifiers and t == 3:
		return false
	if "NO_TIER_4" in modifiers and t == 4:
		return false
	if "NO_TIER_5" in modifiers and t == 5:
		return false
	if "HEAVY_ONLY" in modifiers and not ("HEAVY" in ed.wave_tags):
		return false
	if "NO_FLYING" in modifiers and ed.is_flying:
		return false
	return true


func _pick_enemy_for_wave(pool: Array[EnemyData], wave_index: int) -> EnemyData:
	if pool.is_empty():
		return null
	var max_tier_allowed: int = _max_tier_for_wave(wave_index)
	var filtered: Array[EnemyData] = []
	for ed: EnemyData in pool:
		if ed.tier <= max_tier_allowed:
			filtered.append(ed)
	if filtered.is_empty():
		filtered = pool.duplicate()

	var weights: Array[float] = []
	var total_weight: float = 0.0
	for ed2: EnemyData in filtered:
		var w: float = 1.0 / float(ed2.tier)
		weights.append(w)
		total_weight += w
	var r: float = randf() * total_weight
	var acc: float = 0.0
	for i: int in range(filtered.size()):
		acc += weights[i]
		if r <= acc:
			return filtered[i]
	return filtered.back()


func _max_tier_for_wave(wave_index: int) -> int:
	var wave_number: int = wave_index + 1
	if wave_number <= 3:
		return 1
	if wave_number <= 7:
		return 2
	if wave_number <= 15:
		return 3
	if wave_number <= 23:
		return 4
	return 5
