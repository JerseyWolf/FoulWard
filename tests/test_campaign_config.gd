extends GdUnitTestSuite

const CAMPAIGN_PATH: String = "res://resources/campaigns/campaign_main_50_days.tres"
const TOTAL_DAYS: int = 50
const MINI_BOSS_DAYS: PackedInt32Array = [10, 20, 30, 40]
const EXPECTED_BOSSES: Dictionary = {
	10: "orc_warlord",
	20: "plague_cult_miniboss",
	30: "orc_warlord",
	40: "plague_cult_miniboss",
	50: "final_boss",
}
const MAX_CONSECUTIVE_FACTION_RUN: int = 5

var _campaign: CampaignConfig
var _days: Array[DayConfig]


func before() -> void:
	_campaign = load(CAMPAIGN_PATH) as CampaignConfig
	assert_object(_campaign).is_not_null()
	_days = _campaign.day_configs
	assert_int(_days.size()).is_equal(TOTAL_DAYS)


func test_all_days_have_faction_id() -> void:
	for dc: DayConfig in _days:
		assert_str(dc.faction_id).is_not_empty()


func test_all_days_have_territory_id() -> void:
	for dc: DayConfig in _days:
		assert_str(dc.territory_id).is_not_empty()


func test_mini_boss_days() -> void:
	for dc: DayConfig in _days:
		if dc.day_index in MINI_BOSS_DAYS:
			assert_bool(dc.is_mini_boss_day).is_true()
			assert_bool(dc.is_mini_boss).is_true()
		else:
			assert_bool(dc.is_mini_boss_day).is_false()


func test_boss_ids() -> void:
	for dc: DayConfig in _days:
		if dc.day_index in EXPECTED_BOSSES:
			assert_str(dc.boss_id).is_equal(EXPECTED_BOSSES[dc.day_index])
		else:
			assert_str(dc.boss_id).is_empty()


func test_final_boss() -> void:
	for dc: DayConfig in _days:
		if dc.day_index == TOTAL_DAYS:
			assert_bool(dc.is_final_boss).is_true()
		else:
			assert_bool(dc.is_final_boss).is_false()


func test_wave_counts() -> void:
	for dc: DayConfig in _days:
		var di: int = dc.day_index
		if di <= 10:
			assert_int(dc.base_wave_count).is_equal(3)
		elif di <= 30:
			assert_int(dc.base_wave_count).is_equal(4)
		else:
			assert_int(dc.base_wave_count).is_equal(5)


func test_multiplier_endpoints() -> void:
	var day1: DayConfig = _days[0]
	var day50: DayConfig = _days[49]
	assert_float(day1.enemy_hp_multiplier).is_equal_approx(1.0, 0.001)
	assert_float(day1.enemy_damage_multiplier).is_equal_approx(1.0, 0.001)
	assert_float(day1.gold_reward_multiplier).is_equal_approx(1.0, 0.001)
	assert_float(day1.spawn_count_multiplier).is_equal_approx(1.0, 0.001)
	assert_float(day50.enemy_hp_multiplier).is_equal_approx(3.0, 0.001)
	assert_float(day50.enemy_damage_multiplier).is_equal_approx(3.0, 0.001)
	assert_float(day50.gold_reward_multiplier).is_equal_approx(1.5, 0.001)
	assert_float(day50.spawn_count_multiplier).is_equal_approx(2.5, 0.001)


func test_starting_gold_range() -> void:
	var day1: DayConfig = _days[0]
	var day50: DayConfig = _days[49]
	assert_int(day1.starting_gold).is_equal(1000)
	assert_int(day50.starting_gold).is_equal(1500)


func test_starting_gold_monotonic() -> void:
	var prev: int = 0
	for dc: DayConfig in _days:
		assert_int(dc.starting_gold).is_greater_equal(prev)
		prev = dc.starting_gold


func test_no_faction_run_exceeds_5() -> void:
	var start_idx: int = 10
	var run_count: int = 1
	var max_run: int = 1
	for i: int in range(start_idx + 1, _days.size()):
		if _days[i].faction_id == _days[i - 1].faction_id:
			run_count += 1
			if run_count > max_run:
				max_run = run_count
		else:
			run_count = 1
	assert_int(max_run).is_less_equal(MAX_CONSECUTIVE_FACTION_RUN)
