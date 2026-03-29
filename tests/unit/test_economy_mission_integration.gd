# GdUnit4 — EconomyManager mission economy + building cost/refund math (deterministic).
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()


func test_get_refund_applies_fraction_and_global_multiplier() -> void:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.sell_refund_fraction = 0.5
	var me: MissionEconomyData = MissionEconomyData.new()
	me.sell_refund_global_multiplier = 0.8
	EconomyManager.apply_mission_economy(me)
	var r: Vector2i = EconomyManager.get_refund(bd, 100, 10)
	assert_int(r.x).is_equal(40)
	assert_int(r.y).is_equal(4)


func test_get_gold_cost_duplicate_scaling_uses_k_pow_n() -> void:
	EconomyManager.reset_to_defaults()
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.gold_cost = 100
	bd.apply_duplicate_scaling = true
	assert_int(EconomyManager.get_gold_cost(bd)).is_equal(100)
	EconomyManager.register_purchase(bd)
	assert_int(EconomyManager.get_gold_cost(bd)).is_equal(int(round(100.0 * 1.15)))
	EconomyManager.register_purchase(bd)
	assert_int(EconomyManager.get_gold_cost(bd)).is_equal(int(round(100.0 * pow(1.15, 2.0))))


func test_passive_income_accumulates_deterministically() -> void:
	EconomyManager.reset_to_defaults()
	var me: MissionEconomyData = MissionEconomyData.new()
	me.passive_gold_per_sec = 10.0
	me.passive_material_per_sec = 0.0
	EconomyManager.apply_mission_economy(me)
	var g0: int = EconomyManager.get_gold()
	EconomyManager.call("_process", 0.5)
	assert_int(EconomyManager.get_gold() - g0).is_equal(5)


func test_get_wave_reward_queries_are_pure_and_flat() -> void:
	var me: MissionEconomyData = MissionEconomyData.new()
	me.wave_clear_bonus_gold = 40
	me.wave_clear_bonus_material = 7
	assert_int(EconomyManager.get_wave_reward_gold(0, me)).is_equal(0)
	assert_int(EconomyManager.get_wave_reward_gold(1, me)).is_equal(40)
	assert_int(EconomyManager.get_wave_reward_gold(3, me)).is_equal(40)
	assert_int(EconomyManager.get_wave_reward_material(2, me)).is_equal(7)
	assert_int(EconomyManager.get_wave_reward_gold(1, null)).is_equal(0)


func test_grant_wave_clear_reward_adds_currency() -> void:
	EconomyManager.reset_to_defaults()
	var me: MissionEconomyData = MissionEconomyData.new()
	me.wave_clear_bonus_gold = 10
	me.wave_clear_bonus_material = 2
	var g0: int = EconomyManager.get_gold()
	var m0: int = EconomyManager.get_building_material()
	var granted: Vector2i = EconomyManager.grant_wave_clear_reward(1, me)
	assert_int(granted.x).is_equal(10)
	assert_int(granted.y).is_equal(2)
	assert_int(EconomyManager.get_gold()).is_equal(g0 + 10)
	assert_int(EconomyManager.get_building_material()).is_equal(m0 + 2)


func test_wave_cleared_autogrants_when_mission_economy_applied() -> void:
	EconomyManager.reset_to_defaults()
	var me: MissionEconomyData = MissionEconomyData.new()
	me.starting_gold = 0
	me.starting_material = 0
	me.wave_clear_bonus_gold = 5
	me.wave_clear_bonus_material = 1
	EconomyManager.apply_mission_economy(me)
	var g0: int = EconomyManager.get_gold()
	var m0: int = EconomyManager.get_building_material()
	SignalBus.wave_cleared.emit(2)
	assert_int(EconomyManager.get_gold()).is_equal(g0 + 5)
	assert_int(EconomyManager.get_building_material()).is_equal(m0 + 1)
