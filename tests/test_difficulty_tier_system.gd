## test_difficulty_tier_system.gd
## GdUnit4 tests for the Star Difficulty Tier System.
## PREREQUISITE: Chat 4A must be fully implemented (Types.DifficultyTier enum,
##   DifficultyTierData resource, TerritoryData tier fields, GameManager tier logic,
##   and save integration). These tests define the expected contract.

class_name TestDifficultyTierSystem
extends GdUnitTestSuite


func before_test() -> void:
	CampaignManager.is_endless_mode = false
	GameManager.current_mission = 1
	GameManager.current_wave = 0
	GameManager.game_state = Types.GameState.MAIN_MENU
	GameManager.final_boss_defeated = false
	GameManager.final_boss_active = false
	GameManager.territory_map = null
	EconomyManager.reset_to_defaults()


func after_test() -> void:
	GameManager.territory_map = null


# ════════════════════════════════════════════
# Enum
# ════════════════════════════════════════════

func test_enum_values() -> void:
	assert_int(int(Types.DifficultyTier.NORMAL)).is_equal(0)
	assert_int(int(Types.DifficultyTier.VETERAN)).is_equal(1)
	assert_int(int(Types.DifficultyTier.NIGHTMARE)).is_equal(2)


# ════════════════════════════════════════════
# DifficultyTierData resources
# ════════════════════════════════════════════

func test_tier_data_normal_all_ones() -> void:
	var data: DifficultyTierData = load("res://resources/difficulty/tier_normal.tres") as DifficultyTierData
	assert_object(data).is_not_null()
	assert_float(data.enemy_hp_multiplier).is_equal(1.0)
	assert_float(data.enemy_damage_multiplier).is_equal(1.0)
	assert_float(data.gold_reward_multiplier).is_equal(1.0)
	assert_float(data.spawn_count_multiplier).is_equal(1.0)


func test_tier_data_veteran_multipliers() -> void:
	var data: DifficultyTierData = load("res://resources/difficulty/tier_veteran.tres") as DifficultyTierData
	assert_object(data).is_not_null()
	assert_float(data.enemy_hp_multiplier).is_equal(1.5)
	assert_float(data.enemy_damage_multiplier).is_equal(1.3)
	assert_float(data.gold_reward_multiplier).is_equal(1.2)
	assert_float(data.spawn_count_multiplier).is_equal(1.25)


func test_tier_data_nightmare_multipliers() -> void:
	var data: DifficultyTierData = load("res://resources/difficulty/tier_nightmare.tres") as DifficultyTierData
	assert_object(data).is_not_null()
	assert_float(data.enemy_hp_multiplier).is_equal(2.5)
	assert_float(data.enemy_damage_multiplier).is_equal(2.0)
	assert_float(data.gold_reward_multiplier).is_equal(1.5)
	assert_float(data.spawn_count_multiplier).is_equal(1.75)


# ════════════════════════════════════════════
# _apply_tier_to_day_config
# ════════════════════════════════════════════

func test_apply_tier_normal_does_not_mutate() -> void:
	GameManager.set_active_tier(Types.DifficultyTier.NORMAL)
	var source: DayConfig = DayConfig.new()
	source.enemy_hp_multiplier = 1.0
	source.enemy_damage_multiplier = 1.0
	source.gold_reward_multiplier = 1.0
	source.spawn_count_multiplier = 1.0
	var patched: DayConfig = GameManager.call("_apply_tier_to_day_config", source) as DayConfig
	# NORMAL returns source unchanged; both point to same object
	assert_float(patched.enemy_hp_multiplier).is_equal(1.0)
	assert_float(patched.enemy_damage_multiplier).is_equal(1.0)
	# Source must not have been mutated
	assert_float(source.enemy_hp_multiplier).is_equal(1.0)


func test_apply_tier_veteran_scales_correctly() -> void:
	GameManager.set_active_tier(Types.DifficultyTier.VETERAN)
	var source: DayConfig = DayConfig.new()
	source.enemy_hp_multiplier = 1.0
	source.enemy_damage_multiplier = 1.0
	source.gold_reward_multiplier = 1.0
	source.spawn_count_multiplier = 1.0
	var patched: DayConfig = GameManager.call("_apply_tier_to_day_config", source) as DayConfig
	assert_float(patched.enemy_hp_multiplier).is_equal_approx(1.5, 0.001)
	assert_float(patched.enemy_damage_multiplier).is_equal_approx(1.3, 0.001)
	assert_float(patched.gold_reward_multiplier).is_equal_approx(1.2, 0.001)
	assert_float(patched.spawn_count_multiplier).is_equal_approx(1.25, 0.001)


func test_apply_tier_nightmare_scales_correctly() -> void:
	GameManager.set_active_tier(Types.DifficultyTier.NIGHTMARE)
	var source: DayConfig = DayConfig.new()
	source.enemy_hp_multiplier = 1.0
	source.enemy_damage_multiplier = 1.0
	source.gold_reward_multiplier = 1.0
	source.spawn_count_multiplier = 1.0
	var patched: DayConfig = GameManager.call("_apply_tier_to_day_config", source) as DayConfig
	assert_float(patched.enemy_hp_multiplier).is_equal_approx(2.5, 0.001)
	assert_float(patched.enemy_damage_multiplier).is_equal_approx(2.0, 0.001)
	assert_float(patched.gold_reward_multiplier).is_equal_approx(1.5, 0.001)
	assert_float(patched.spawn_count_multiplier).is_equal_approx(1.75, 0.001)


func test_apply_tier_stacks_on_nonunit_base() -> void:
	# DayConfig with hp=2.0, VETERAN multiplier 1.5 → result 3.0
	GameManager.set_active_tier(Types.DifficultyTier.VETERAN)
	var source: DayConfig = DayConfig.new()
	source.enemy_hp_multiplier = 2.0
	source.enemy_damage_multiplier = 1.0
	source.gold_reward_multiplier = 1.0
	source.spawn_count_multiplier = 1.0
	var patched: DayConfig = GameManager.call("_apply_tier_to_day_config", source) as DayConfig
	assert_float(patched.enemy_hp_multiplier).is_equal_approx(3.0, 0.001)
	# Source must not have been mutated
	assert_float(source.enemy_hp_multiplier).is_equal_approx(2.0, 0.001)


# ════════════════════════════════════════════
# _handle_tier_cleared
# ════════════════════════════════════════════

func _make_test_territory(territory_id: String, tier: int, stars: int) -> TerritoryData:
	var territory: TerritoryData = TerritoryData.new()
	territory.territory_id = territory_id
	territory.highest_cleared_tier = tier
	territory.star_count = stars
	territory.is_controlled_by_player = true
	return territory


func _make_map_with_territory(territory: TerritoryData) -> TerritoryMapData:
	var map: TerritoryMapData = TerritoryMapData.new()
	map.territories.append(territory)
	map.invalidate_cache()
	return map


func test_handle_tier_cleared_upgrades_star_count() -> void:
	var territory: TerritoryData = _make_test_territory(
		"test_t", int(Types.DifficultyTier.NORMAL), 1
	)
	GameManager.territory_map = _make_map_with_territory(territory)
	GameManager.set_active_tier(Types.DifficultyTier.VETERAN)
	var day_config: DayConfig = DayConfig.new()
	day_config.territory_id = "test_t"
	GameManager.call("_handle_tier_cleared", day_config)
	assert_int(territory.star_count).is_equal(2)
	assert_int(int(territory.highest_cleared_tier)).is_equal(int(Types.DifficultyTier.VETERAN))


func test_handle_tier_cleared_no_downgrade() -> void:
	var territory: TerritoryData = _make_test_territory(
		"test_t", int(Types.DifficultyTier.NIGHTMARE), 3
	)
	GameManager.territory_map = _make_map_with_territory(territory)
	GameManager.set_active_tier(Types.DifficultyTier.NORMAL)
	var day_config: DayConfig = DayConfig.new()
	day_config.territory_id = "test_t"
	GameManager.call("_handle_tier_cleared", day_config)
	# Replaying on NORMAL must not downgrade NIGHTMARE clear
	assert_int(int(territory.highest_cleared_tier)).is_equal(int(Types.DifficultyTier.NIGHTMARE))
	assert_int(territory.star_count).is_equal(3)


# ════════════════════════════════════════════
# Nightmare gate
# ════════════════════════════════════════════

func test_nightmare_locked_until_veteran_cleared() -> void:
	var territory: TerritoryData = _make_test_territory(
		"test_t", int(Types.DifficultyTier.NORMAL), 1
	)
	# Gate: highest_cleared_tier must be >= VETERAN before nightmare is available
	assert_bool(
		territory.highest_cleared_tier < Types.DifficultyTier.VETERAN
	).is_true()


func test_nightmare_unlocked_after_veteran_cleared() -> void:
	var territory: TerritoryData = _make_test_territory(
		"test_t", int(Types.DifficultyTier.VETERAN), 2
	)
	assert_bool(
		territory.highest_cleared_tier >= Types.DifficultyTier.VETERAN
	).is_true()


# ════════════════════════════════════════════
# Save / restore
# ════════════════════════════════════════════

func test_save_restore_highest_cleared_tier() -> void:
	var territory: TerritoryData = _make_test_territory(
		"save_t", int(Types.DifficultyTier.VETERAN), 2
	)
	territory.veteran_perk_id = "veteran_perk_a"
	territory.nightmare_title_id = ""
	GameManager.territory_map = _make_map_with_territory(territory)

	var saved: Dictionary = GameManager.get_save_data()
	assert_bool(saved.has("territories")).is_true()

	var territories_dict: Dictionary = saved.get("territories", {}) as Dictionary
	assert_bool(territories_dict.has("save_t")).is_true()

	var t_saved: Dictionary = territories_dict.get("save_t", {}) as Dictionary
	assert_int(int(t_saved.get("highest_cleared_tier", 0))).is_equal(
		int(Types.DifficultyTier.VETERAN)
	)
	assert_int(int(t_saved.get("star_count", 0))).is_equal(2)


func test_save_restore_backward_compat_missing_keys() -> void:
	# Old save dict without "territories" key must not crash restore
	var territory: TerritoryData = _make_test_territory(
		"compat_t", int(Types.DifficultyTier.NORMAL), 0
	)
	GameManager.territory_map = _make_map_with_territory(territory)
	var old_save: Dictionary = {
		"game_state": int(Types.GameState.MAIN_MENU),
		"current_mission": 1,
		"current_wave": 0,
		"current_day": 1,
		"final_boss_defeated": false,
		"final_boss_active": false,
		"final_boss_id": "",
		"final_boss_day_index": 50,
		"current_boss_threat_territory_id": "",
		"current_gold": 1000,
		"current_building_material": 10,
		"current_research_material": 0,
		"current_mana": 0,
		"florence_data": {},
	}
	GameManager.restore_from_save(old_save)
	# Territory defaults to NORMAL (0) when save has no "territories" key
	assert_int(int(territory.highest_cleared_tier)).is_equal(int(Types.DifficultyTier.NORMAL))
	assert_int(territory.star_count).is_equal(0)


# ════════════════════════════════════════════
# Signal
# ════════════════════════════════════════════

func test_territory_tier_cleared_signal_emitted() -> void:
	var territory: TerritoryData = _make_test_territory(
		"signal_t", int(Types.DifficultyTier.NORMAL), 1
	)
	GameManager.territory_map = _make_map_with_territory(territory)
	GameManager.set_active_tier(Types.DifficultyTier.VETERAN)
	var day_config: DayConfig = DayConfig.new()
	day_config.territory_id = "signal_t"
	var monitor := monitor_signals(SignalBus, false)
	GameManager.call("_handle_tier_cleared", day_config)
	await assert_signal(monitor).is_emitted(
			"territory_tier_cleared", ["signal_t", int(Types.DifficultyTier.VETERAN)]
	)


# ════════════════════════════════════════════
# Active tier lifecycle
# ════════════════════════════════════════════

func test_active_tier_reset_on_new_game() -> void:
	GameManager.set_active_tier(Types.DifficultyTier.NIGHTMARE)
	assert_int(int(GameManager.get_active_tier())).is_equal(int(Types.DifficultyTier.NIGHTMARE))
	GameManager.start_new_game()
	assert_int(int(GameManager.get_active_tier())).is_equal(int(Types.DifficultyTier.NORMAL))


# ════════════════════════════════════════════
# Removed no-op method guard
# ════════════════════════════════════════════

func test_get_effective_multiplier_does_not_exist() -> void:
	# The Perplexity spec included get_effective_multiplier as a no-op. It was removed.
	assert_bool(GameManager.has_method("get_effective_multiplier")).is_false()
