## test_economy_manager.gd
## Exhaustive GdUnit4 tests for the EconomyManager autoload.
## Simulation API: all public methods callable without UI nodes present.

class_name TestEconomyManager
extends GdUnitTestSuite

func before_test() -> void:
	EconomyManager.reset_to_defaults()

# ════════════════════════════════════════════
# add_gold
# ════════════════════════════════════════════

func test_add_gold_positive_amount_increases_total() -> void:
	EconomyManager.add_gold(50)
	assert_int(EconomyManager.get_gold()).is_equal(1050)

func test_add_gold_accumulates_across_multiple_calls() -> void:
	EconomyManager.add_gold(10)
	EconomyManager.add_gold(20)
	assert_int(EconomyManager.get_gold()).is_equal(1030)

func test_add_gold_emits_resource_changed() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_gold(25)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.GOLD, 1025]
	)

func test_add_gold_emits_gold_resource_type() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_gold(10)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.GOLD, 1010]
	)

func test_add_gold_emits_correct_new_amount() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_gold(40)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.GOLD, 1040]
	)

# ════════════════════════════════════════════
# spend_gold
# ════════════════════════════════════════════

func test_spend_gold_sufficient_returns_true() -> void:
	var result: bool = EconomyManager.spend_gold(50)
	assert_bool(result).is_true()

func test_spend_gold_sufficient_deducts_correct_amount() -> void:
	EconomyManager.spend_gold(60)
	assert_int(EconomyManager.get_gold()).is_equal(940)

func test_spend_gold_insufficient_returns_false() -> void:
	var result: bool = EconomyManager.spend_gold(2000)
	assert_bool(result).is_false()

func test_spend_gold_insufficient_balance_unchanged() -> void:
	EconomyManager.spend_gold(2000)
	assert_int(EconomyManager.get_gold()).is_equal(1000)

func test_spend_gold_exact_amount_returns_true() -> void:
	var result: bool = EconomyManager.spend_gold(1000)
	assert_bool(result).is_true()

func test_spend_gold_exact_amount_results_in_zero_balance() -> void:
	EconomyManager.spend_gold(1000)
	assert_int(EconomyManager.get_gold()).is_equal(0)

func test_spend_gold_one_over_balance_returns_false() -> void:
	var result: bool = EconomyManager.spend_gold(1001)
	assert_bool(result).is_false()

func test_spend_gold_emits_resource_changed_on_success() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.spend_gold(10)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.GOLD, 990]
	)

func test_spend_gold_does_not_emit_resource_changed_on_failure() -> void:
	EconomyManager.spend_gold(1000)
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.spend_gold(1)
	assert_signal(monitor).is_not_emitted("resource_changed")

# ════════════════════════════════════════════
# add_building_material
# ════════════════════════════════════════════

func test_add_building_material_increases_total() -> void:
	EconomyManager.add_building_material(5)
	assert_int(EconomyManager.get_building_material()).is_equal(55)

func test_add_building_material_emits_resource_changed() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_building_material(3)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.BUILDING_MATERIAL, 53]
	)

func test_add_building_material_emits_correct_resource_type() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_building_material(1)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.BUILDING_MATERIAL, 51]
	)

# ════════════════════════════════════════════
# spend_building_material
# ════════════════════════════════════════════

func test_spend_building_material_sufficient_returns_true() -> void:
	var result: bool = EconomyManager.spend_building_material(5)
	assert_bool(result).is_true()

func test_spend_building_material_sufficient_deducts_amount() -> void:
	EconomyManager.spend_building_material(3)
	assert_int(EconomyManager.get_building_material()).is_equal(47)

func test_spend_building_material_insufficient_returns_false() -> void:
	var result: bool = EconomyManager.spend_building_material(51)
	assert_bool(result).is_false()

func test_spend_building_material_insufficient_balance_unchanged() -> void:
	EconomyManager.spend_building_material(100)
	assert_int(EconomyManager.get_building_material()).is_equal(50)

func test_spend_building_material_exact_results_in_zero() -> void:
	EconomyManager.spend_building_material(50)
	assert_int(EconomyManager.get_building_material()).is_equal(0)

func test_spend_building_material_emits_resource_changed_on_success() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.spend_building_material(2)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.BUILDING_MATERIAL, 48]
	)

func test_spend_building_material_does_not_emit_on_failure() -> void:
	EconomyManager.spend_building_material(50)
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.spend_building_material(1)
	assert_signal(monitor).is_not_emitted("resource_changed")

# ════════════════════════════════════════════
# add_research_material
# ════════════════════════════════════════════

func test_add_research_material_increases_from_zero() -> void:
	EconomyManager.add_research_material(4)
	assert_int(EconomyManager.get_research_material()).is_equal(4)

func test_add_research_material_emits_resource_changed() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_research_material(2)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.RESEARCH_MATERIAL, 2]
	)

func test_add_research_material_emits_correct_resource_type() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_research_material(1)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.RESEARCH_MATERIAL, 1]
	)

# ════════════════════════════════════════════
# spend_research_material
# ════════════════════════════════════════════

func test_spend_research_material_sufficient_returns_true() -> void:
	EconomyManager.add_research_material(5)
	var result: bool = EconomyManager.spend_research_material(3)
	assert_bool(result).is_true()

func test_spend_research_material_sufficient_deducts_amount() -> void:
	EconomyManager.add_research_material(5)
	EconomyManager.spend_research_material(3)
	assert_int(EconomyManager.get_research_material()).is_equal(2)

func test_spend_research_material_zero_starting_returns_false() -> void:
	var result: bool = EconomyManager.spend_research_material(1)
	assert_bool(result).is_false()

func test_spend_research_material_insufficient_balance_unchanged() -> void:
	EconomyManager.spend_research_material(1)
	assert_int(EconomyManager.get_research_material()).is_equal(0)

func test_spend_research_material_emits_resource_changed_on_success() -> void:
	EconomyManager.add_research_material(3)
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.spend_research_material(1)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.RESEARCH_MATERIAL, 2]
	)

# ════════════════════════════════════════════
# can_afford
# ════════════════════════════════════════════

func test_can_afford_exact_gold_and_material_returns_true() -> void:
	assert_bool(EconomyManager.can_afford(100, 10)).is_true()

func test_can_afford_one_gold_under_returns_false() -> void:
	assert_bool(EconomyManager.can_afford(1001, 0)).is_false()

func test_can_afford_one_material_under_returns_false() -> void:
	assert_bool(EconomyManager.can_afford(0, 51)).is_false()

func test_can_afford_zero_costs_always_returns_true() -> void:
	assert_bool(EconomyManager.can_afford(0, 0)).is_true()

func test_can_afford_both_insufficient_returns_false() -> void:
	assert_bool(EconomyManager.can_afford(2000, 60)).is_false()

func test_can_afford_gold_ok_material_insufficient_returns_false() -> void:
	assert_bool(EconomyManager.can_afford(50, 51)).is_false()

func test_can_afford_gold_insufficient_material_ok_returns_false() -> void:
	assert_bool(EconomyManager.can_afford(2000, 5)).is_false()

func test_can_afford_after_spending_reflects_new_balance() -> void:
	EconomyManager.spend_gold(990)
	assert_bool(EconomyManager.can_afford(11, 0)).is_false()
	assert_bool(EconomyManager.can_afford(10, 0)).is_true()

# ════════════════════════════════════════════
# reset_to_defaults
# ════════════════════════════════════════════

func test_reset_to_defaults_restores_gold_to_default() -> void:
	EconomyManager.add_gold(999)
	EconomyManager.reset_to_defaults()
	assert_int(EconomyManager.get_gold()).is_equal(1000)

func test_reset_to_defaults_restores_building_material_to_default() -> void:
	EconomyManager.add_building_material(99)
	EconomyManager.reset_to_defaults()
	assert_int(EconomyManager.get_building_material()).is_equal(50)

func test_reset_to_defaults_restores_research_material_to_0() -> void:
	EconomyManager.add_research_material(7)
	EconomyManager.reset_to_defaults()
	assert_int(EconomyManager.get_research_material()).is_equal(0)

func test_reset_to_defaults_emits_resource_changed() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.reset_to_defaults()
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.GOLD, 1000]
	)

func test_reset_to_defaults_after_spending_gold_restores_correctly() -> void:
	EconomyManager.spend_gold(100)
	EconomyManager.reset_to_defaults()
	assert_int(EconomyManager.get_gold()).is_equal(1000)

# ════════════════════════════════════════════
# enemy_killed signal integration
# ════════════════════════════════════════════

func test_enemy_killed_signal_awards_gold_reward() -> void:
	ChronicleManager.reset_for_test()
	EconomyManager.reset_to_defaults()
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 15)
	assert_int(EconomyManager.get_gold()).is_equal(1015)

func test_enemy_killed_signal_awards_exact_gold_amount() -> void:
	ChronicleManager.reset_for_test()
	EconomyManager.reset_to_defaults()
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_BRUTE, Vector3.ZERO, 30)
	assert_int(EconomyManager.get_gold()).is_equal(1030)

func test_enemy_killed_signal_accumulates_across_multiple_kills() -> void:
	ChronicleManager.reset_for_test()
	EconomyManager.reset_to_defaults()
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	SignalBus.enemy_killed.emit(Types.EnemyType.BAT_SWARM, Vector3.ZERO, 5)
	assert_int(EconomyManager.get_gold()).is_equal(1015)

func test_enemy_killed_emits_resource_changed() -> void:
	ChronicleManager.reset_for_test()
	EconomyManager.reset_to_defaults()
	var monitor := monitor_signals(SignalBus, false)
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.GOLD, 1010]
	)

