## test_damage_calculator.gd
## Exhaustive GdUnit4 tests for the DamageCalculator autoload — all 16 matrix cells.
## Simulation API: all public methods callable without UI nodes present.

class_name TestDamageCalculator
extends GdUnitTestSuite

# ════════════════════════════════════════════
# UNARMORED — all multipliers 1.0
# ════════════════════════════════════════════

func test_physical_vs_unarmored_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.PHYSICAL, Types.ArmorType.UNARMORED)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_fire_vs_unarmored_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.FIRE, Types.ArmorType.UNARMORED)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_magical_vs_unarmored_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.MAGICAL, Types.ArmorType.UNARMORED)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_poison_vs_unarmored_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.POISON, Types.ArmorType.UNARMORED)
	assert_float(result).is_equal_approx(100.0, 0.001)

# ════════════════════════════════════════════
# HEAVY_ARMOR — physical 0.5, magical 2.0, fire/poison 1.0
# ════════════════════════════════════════════

func test_physical_vs_heavy_armor_equals_half_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.PHYSICAL, Types.ArmorType.HEAVY_ARMOR)
	assert_float(result).is_equal_approx(50.0, 0.001)

func test_fire_vs_heavy_armor_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.FIRE, Types.ArmorType.HEAVY_ARMOR)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_magical_vs_heavy_armor_equals_double_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.MAGICAL, Types.ArmorType.HEAVY_ARMOR)
	assert_float(result).is_equal_approx(200.0, 0.001)

func test_poison_vs_heavy_armor_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.POISON, Types.ArmorType.HEAVY_ARMOR)
	assert_float(result).is_equal_approx(100.0, 0.001)

# ════════════════════════════════════════════
# UNDEAD — fire 2.0, poison 0.0 (immune), physical/magical 1.0
# ════════════════════════════════════════════

func test_physical_vs_undead_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.PHYSICAL, Types.ArmorType.UNDEAD)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_fire_vs_undead_equals_double_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.FIRE, Types.ArmorType.UNDEAD)
	assert_float(result).is_equal_approx(200.0, 0.001)

func test_magical_vs_undead_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.MAGICAL, Types.ArmorType.UNDEAD)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_poison_vs_undead_equals_zero_full_immunity() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.POISON, Types.ArmorType.UNDEAD)
	assert_float(result).is_equal_approx(0.0, 0.001)

# ════════════════════════════════════════════
# FLYING — all multipliers 1.0
# ════════════════════════════════════════════

func test_physical_vs_flying_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.PHYSICAL, Types.ArmorType.FLYING)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_fire_vs_flying_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.FIRE, Types.ArmorType.FLYING)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_magical_vs_flying_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.MAGICAL, Types.ArmorType.FLYING)
	assert_float(result).is_equal_approx(100.0, 0.001)

func test_poison_vs_flying_equals_base_damage() -> void:
	var result: float = DamageCalculator.calculate_damage(
		100.0, Types.DamageType.POISON, Types.ArmorType.FLYING)
	assert_float(result).is_equal_approx(100.0, 0.001)

# ════════════════════════════════════════════
# Edge cases
# ════════════════════════════════════════════

func test_zero_base_damage_always_returns_zero_regardless_of_types() -> void:
	var result: float = DamageCalculator.calculate_damage(
		0.0, Types.DamageType.MAGICAL, Types.ArmorType.HEAVY_ARMOR)
	assert_float(result).is_equal_approx(0.0, 0.001)

func test_small_base_damage_half_multiplier_rounds_correctly() -> void:
	var result: float = DamageCalculator.calculate_damage(
		10.0, Types.DamageType.PHYSICAL, Types.ArmorType.HEAVY_ARMOR)
	assert_float(result).is_equal_approx(5.0, 0.001)

func test_large_base_damage_double_multiplier_scales_correctly() -> void:
	var result: float = DamageCalculator.calculate_damage(
		1000.0, Types.DamageType.MAGICAL, Types.ArmorType.HEAVY_ARMOR)
	assert_float(result).is_equal_approx(2000.0, 0.001)

func test_poison_immunity_on_undead_with_large_damage_still_zero() -> void:
	var result: float = DamageCalculator.calculate_damage(
		9999.0, Types.DamageType.POISON, Types.ArmorType.UNDEAD)
	assert_float(result).is_equal_approx(0.0, 0.001)

func test_fractional_base_damage_preserved_in_output() -> void:
	var result: float = DamageCalculator.calculate_damage(
		33.3, Types.DamageType.FIRE, Types.ArmorType.UNDEAD)
	assert_float(result).is_equal_approx(66.6, 0.01)


func test_calculate_dot_tick_simple_case() -> void:
	var dot_total_damage: float = 100.0
	var tick_interval: float = 0.5
	var duration: float = 5.0
	var per_tick: float = DamageCalculator.calculate_dot_tick(
		dot_total_damage,
		tick_interval,
		duration,
		Types.DamageType.FIRE,
		Types.ArmorType.UNARMORED
	)
	assert_float(per_tick).is_equal_approx(10.0, 0.001)


func test_calculate_dot_tick_poison_undead_returns_zero() -> void:
	var per_tick: float = DamageCalculator.calculate_dot_tick(
		100.0,
		0.5,
		5.0,
		Types.DamageType.POISON,
		Types.ArmorType.UNDEAD
	)
	assert_float(per_tick).is_equal(0.0)

