## TODO: add before_test() isolation — see testing SKILL
# test_wave_composer.gd — WaveComposer budgets, tags, and tier caps.

class_name TestWaveComposer
extends GdUnitTestSuite

const WaveComposerType = preload("res://scripts/wave_composer.gd")


func test_compose_first_wave_uses_only_tier1() -> void:
	var registry: Array[EnemyData] = _load_all_enemy_data()
	var pattern: Resource = load("res://resources/wave_patterns/default_campaign_pattern.tres")
	var composer: RefCounted = WaveComposerType.new(registry, pattern)
	var wave0: Array[EnemyData] = composer.compose_wave(0)
	assert_bool(wave0.size() > 0).is_true()
	for ed: EnemyData in wave0:
		assert_int(ed.tier).is_less_equal(1)


func test_compose_mid_wave_allows_up_to_tier3() -> void:
	var registry: Array[EnemyData] = _load_all_enemy_data()
	var pattern: Resource = load("res://resources/wave_patterns/default_campaign_pattern.tres")
	var composer: RefCounted = WaveComposerType.new(registry, pattern)
	var wave10: Array[EnemyData] = composer.compose_wave(10)
	assert_bool(wave10.size() > 0).is_true()
	var max_t: int = 0
	for ed: EnemyData in wave10:
		max_t = maxi(max_t, ed.tier)
	assert_int(max_t).is_less_equal(3)


func test_compose_late_wave_can_include_tier4_and_tier5() -> void:
	var registry: Array[EnemyData] = _load_all_enemy_data()
	var pattern: Resource = load("res://resources/wave_patterns/default_campaign_pattern.tres")
	var composer: RefCounted = WaveComposerType.new(registry, pattern)
	var found_high: bool = false
	for s: int in range(256):
		seed(s)
		var wave25: Array[EnemyData] = composer.compose_wave(25)
		assert_bool(wave25.size() > 0).is_true()
		var max_t: int = 0
		for ed: EnemyData in wave25:
			max_t = maxi(max_t, ed.tier)
		if max_t >= 4:
			found_high = true
			break
	assert_bool(found_high).is_true()


func test_wave_budget_is_respected() -> void:
	var registry: Array[EnemyData] = _load_all_enemy_data()
	var pattern: Resource = load("res://resources/wave_patterns/default_campaign_pattern.tres")
	var composer: RefCounted = WaveComposerType.new(registry, pattern)
	var wave5: Array[EnemyData] = composer.compose_wave(5)
	var budget: int = composer._compute_budget_for_wave(5)
	var cost_total: int = 0
	for ed: EnemyData in wave5:
		cost_total += ed.point_cost
	assert_int(cost_total).is_less_equal(budget * 12 / 10)


func _load_all_enemy_data() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	var dir: DirAccess = DirAccess.open("res://resources/enemy_data/")
	if dir == null:
		return result
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var ed: EnemyData = load("res://resources/enemy_data/" + fname) as EnemyData
			if ed != null:
				result.append(ed)
		fname = dir.get_next()
	dir.list_dir_end()
	return result
