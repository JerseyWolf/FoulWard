extends GdUnitTestSuite
class_name TestWeaponUpgradeManager

var _manager: WeaponUpgradeManager

func before_test() -> void:
	EconomyManager.reset_to_defaults()
	_manager = WeaponUpgradeManager.new()

	var cb_data: WeaponData = WeaponData.new()
	cb_data.weapon_slot = Types.WeaponSlot.CROSSBOW
	cb_data.damage = 50.0
	cb_data.projectile_speed = 30.0
	cb_data.reload_time = 2.5
	cb_data.burst_count = 1
	cb_data.burst_interval = 0.0
	_manager.crossbow_base_data = cb_data

	var rm_data: WeaponData = WeaponData.new()
	rm_data.weapon_slot = Types.WeaponSlot.RAPID_MISSILE
	rm_data.damage = 15.0
	rm_data.projectile_speed = 50.0
	rm_data.reload_time = 3.0
	rm_data.burst_count = 10
	rm_data.burst_interval = 0.05
	_manager.rapid_missile_base_data = rm_data

	var cb1: WeaponLevelData = WeaponLevelData.new()
	cb1.weapon_slot = Types.WeaponSlot.CROSSBOW
	cb1.level = 1
	cb1.damage_bonus = 10.0
	cb1.speed_bonus = 5.0
	cb1.reload_bonus = -0.2
	cb1.burst_count_bonus = 0
	cb1.gold_cost = 100

	var cb2: WeaponLevelData = WeaponLevelData.new()
	cb2.weapon_slot = Types.WeaponSlot.CROSSBOW
	cb2.level = 2
	cb2.damage_bonus = 15.0
	cb2.speed_bonus = 5.0
	cb2.reload_bonus = -0.2
	cb2.burst_count_bonus = 0
	cb2.gold_cost = 200

	var cb3: WeaponLevelData = WeaponLevelData.new()
	cb3.weapon_slot = Types.WeaponSlot.CROSSBOW
	cb3.level = 3
	cb3.damage_bonus = 20.0
	cb3.speed_bonus = 5.0
	cb3.reload_bonus = -0.2
	cb3.burst_count_bonus = 0
	cb3.gold_cost = 350
	_manager.crossbow_levels = [cb1, cb2, cb3]

	var rm1: WeaponLevelData = WeaponLevelData.new()
	rm1.weapon_slot = Types.WeaponSlot.RAPID_MISSILE
	rm1.level = 1
	rm1.damage_bonus = 3.0
	rm1.speed_bonus = 5.0
	rm1.reload_bonus = -0.2
	rm1.burst_count_bonus = 2
	rm1.gold_cost = 80

	var rm2: WeaponLevelData = WeaponLevelData.new()
	rm2.weapon_slot = Types.WeaponSlot.RAPID_MISSILE
	rm2.level = 2
	rm2.damage_bonus = 4.0
	rm2.speed_bonus = 5.0
	rm2.reload_bonus = -0.2
	rm2.burst_count_bonus = 2
	rm2.gold_cost = 160

	var rm3: WeaponLevelData = WeaponLevelData.new()
	rm3.weapon_slot = Types.WeaponSlot.RAPID_MISSILE
	rm3.level = 3
	rm3.damage_bonus = 5.0
	rm3.speed_bonus = 5.0
	rm3.reload_bonus = -0.2
	rm3.burst_count_bonus = 2
	rm3.gold_cost = 300
	_manager.rapid_missile_levels = [rm1, rm2, rm3]

	add_child(_manager)
	await get_tree().process_frame


func after_test() -> void:
	if is_instance_valid(_manager):
		_manager.queue_free()
	await get_tree().process_frame


func test_initial_level_is_zero_for_crossbow() -> void:
	assert_int(_manager.get_current_level(Types.WeaponSlot.CROSSBOW)).is_equal(0)


func test_initial_level_is_zero_for_rapid_missile() -> void:
	assert_int(_manager.get_current_level(Types.WeaponSlot.RAPID_MISSILE)).is_equal(0)


func test_get_max_level_returns_3() -> void:
	assert_int(_manager.get_max_level()).is_equal(3)


func test_upgrade_crossbow_level_1_succeeds() -> void:
	EconomyManager.add_gold(500)
	var result: bool = _manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_bool(result).is_true()
	assert_int(_manager.get_current_level(Types.WeaponSlot.CROSSBOW)).is_equal(1)


func test_upgrade_crossbow_deducts_gold() -> void:
	EconomyManager.add_gold(500)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_int(EconomyManager.get_gold()).is_equal(1400)


func test_upgrade_crossbow_insufficient_gold_returns_false() -> void:
	EconomyManager.spend_gold(950)
	var result: bool = _manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_bool(result).is_false()
	assert_int(_manager.get_current_level(Types.WeaponSlot.CROSSBOW)).is_equal(0)


func test_upgrade_beyond_max_level_returns_false() -> void:
	EconomyManager.add_gold(9999)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	var result: bool = _manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_bool(result).is_false()
	assert_int(_manager.get_current_level(Types.WeaponSlot.CROSSBOW)).is_equal(3)


func test_upgrade_crossbow_emits_weapon_upgraded() -> void:
	EconomyManager.add_gold(500)
	var monitor = monitor_signals(SignalBus, false)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	await assert_signal(monitor).is_emitted("weapon_upgraded", [Types.WeaponSlot.CROSSBOW, 1])


func test_get_effective_damage_at_level_0_equals_base() -> void:
	assert_float(_manager.get_effective_damage(Types.WeaponSlot.CROSSBOW)).is_equal(50.0)


func test_get_effective_damage_at_level_3_cumulative() -> void:
	EconomyManager.add_gold(9999)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_float(_manager.get_effective_damage(Types.WeaponSlot.CROSSBOW)).is_equal(95.0)


func test_get_effective_reload_time_clamped_to_minimum() -> void:
	EconomyManager.add_gold(9999)
	for i: int in range(3):
		_manager.crossbow_levels[i].reload_bonus = -9999.0
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_float(_manager.get_effective_reload_time(Types.WeaponSlot.CROSSBOW)).is_greater_equal(0.1)


func test_get_effective_burst_count_rapid_missile_increases() -> void:
	EconomyManager.add_gold(500)
	_manager.upgrade_weapon(Types.WeaponSlot.RAPID_MISSILE)
	assert_int(_manager.get_effective_burst_count(Types.WeaponSlot.RAPID_MISSILE)).is_equal(12)


func test_get_next_level_data_at_max_level_returns_null() -> void:
	EconomyManager.add_gold(9999)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_object(_manager.get_next_level_data(Types.WeaponSlot.CROSSBOW)).is_null()


func test_reset_to_defaults_sets_levels_to_zero() -> void:
	EconomyManager.add_gold(9999)
	_manager.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	_manager.upgrade_weapon(Types.WeaponSlot.RAPID_MISSILE)
	_manager.reset_to_defaults()
	assert_int(_manager.get_current_level(Types.WeaponSlot.CROSSBOW)).is_equal(0)
	assert_int(_manager.get_current_level(Types.WeaponSlot.RAPID_MISSILE)).is_equal(0)
