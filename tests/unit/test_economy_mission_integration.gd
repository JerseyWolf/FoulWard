# GdUnit4 — EconomyManager mission economy + building cost/refund math (deterministic).
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()


func test_get_refund_applies_fraction_and_global_multiplier() -> void:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	var me: MissionEconomyData = MissionEconomyData.new()
	me.sell_refund_fraction = 0.5
	me.sell_refund_global_multiplier = 0.8
	me.starting_gold = 0
	me.starting_material = 0
	EconomyManager.apply_mission_economy(me)
	var r: Dictionary = EconomyManager.get_refund(bd, 100, 10)
	assert_int(int(r.get("gold", 0))).is_equal(40)
	assert_int(int(r.get("material", 0))).is_equal(4)


func test_get_gold_cost_duplicate_scaling_linear_k() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.gold = 10000
	EconomyManager.building_material = 1000
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.gold_cost = 100
	bd.apply_duplicate_scaling = true
	var k: float = 0.08
	assert_int(EconomyManager.get_gold_cost(bd)).is_equal(100)
	assert_float(EconomyManager.get_cost_multiplier(bd)).is_equal(1.0)
	var r1: Dictionary = EconomyManager.register_purchase(bd)
	assert_bool(not r1.is_empty()).is_true()
	assert_float(EconomyManager.get_cost_multiplier(bd)).is_equal(1.0 + k * 1.0)
	assert_int(EconomyManager.get_gold_cost(bd)).is_equal(ceili(100.0 * (1.0 + k * 1.0)))
	var r2: Dictionary = EconomyManager.register_purchase(bd)
	assert_bool(not r2.is_empty()).is_true()
	assert_int(EconomyManager.get_gold_cost(bd)).is_equal(ceili(100.0 * (1.0 + k * 2.0)))


func test_apply_mission_economy_resets_duplicate_counts() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.gold = 10000
	EconomyManager.building_material = 1000
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.id = "test_tower_dup"
	bd.apply_duplicate_scaling = true
	var rp: Dictionary = EconomyManager.register_purchase(bd)
	assert_bool(not rp.is_empty()).is_true()
	assert_int(EconomyManager.get_duplicate_count("test_tower_dup")).is_equal(1)
	var me: MissionEconomyData = MissionEconomyData.new()
	me.starting_gold = 0
	me.starting_material = 0
	EconomyManager.apply_mission_economy(me)
	assert_int(EconomyManager.get_duplicate_count("test_tower_dup")).is_equal(0)


func test_can_afford_building_uses_scaled_costs() -> void:
	EconomyManager.reset_to_defaults()
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.BALLISTA
	bd.gold_cost = 50
	bd.material_cost = 2
	bd.apply_duplicate_scaling = true
	assert_bool(EconomyManager.can_afford_building(bd)).is_true()
	EconomyManager.gold = 49
	assert_bool(EconomyManager.can_afford_building(bd)).is_false()


func test_passive_income_accumulates_deterministically() -> void:
	EconomyManager.reset_to_defaults()
	var me: MissionEconomyData = MissionEconomyData.new()
	me.passive_gold_per_sec = 10.0
	me.passive_material_per_sec = 0.0
	me.starting_gold = 0
	me.starting_material = 0
	EconomyManager.apply_mission_economy(me)
	var g0: int = EconomyManager.get_gold()
	EconomyManager.call("_physics_process", 0.5)
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
	ChronicleManager.reset_for_test()
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


func test_sell_refund_fraction_zero_sentinel() -> void:
	EconomyManager.reset_to_defaults()
	var default_frac: float = EconomyManager.sell_refund_fraction
	var me: MissionEconomyData = MissionEconomyData.new()
	me.sell_refund_fraction = -1.0
	me.starting_gold = 0
	me.starting_material = 0
	EconomyManager.apply_mission_economy(me)
	assert_float(EconomyManager.sell_refund_fraction).is_equal(default_frac)


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
