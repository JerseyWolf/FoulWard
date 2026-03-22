## test_health_component.gd
## Exhaustive GdUnit4 tests for HealthComponent.
## Simulation API: all public methods callable without UI nodes present.

class_name TestHealthComponent
extends GdUnitTestSuite

var _component: HealthComponent

func before_test() -> void:
	_component = HealthComponent.new()
	_component.max_hp = 100
	# add_child triggers _ready(), which sets current_hp = max_hp.
	add_child(_component)

func after_test() -> void:
	_component.queue_free()
	_component = null

# ════════════════════════════════════════════
# Initial state
# ════════════════════════════════════════════

func test_initial_hp_equals_max_hp() -> void:
	assert_int(_component.current_hp).is_equal(100)

func test_is_alive_true_on_init() -> void:
	assert_bool(_component.is_alive()).is_true()

# ════════════════════════════════════════════
# take_damage
# ════════════════════════════════════════════

func test_take_damage_reduces_current_hp() -> void:
	_component.take_damage(30.0)
	assert_int(_component.current_hp).is_equal(70)

func test_take_damage_clamps_to_zero_not_negative() -> void:
	_component.take_damage(150.0)
	assert_int(_component.current_hp).is_equal(0)

func test_take_damage_emits_health_changed() -> void:
	var monitor := monitor_signals(_component, false)
	_component.take_damage(10.0)
	await assert_signal(monitor).is_emitted("health_changed", [90, 100])

func test_take_damage_to_zero_emits_health_depleted() -> void:
	var monitor := monitor_signals(_component, false)
	_component.take_damage(100.0)
	await assert_signal(monitor).is_emitted("health_depleted")

func test_take_damage_to_zero_sets_is_alive_false() -> void:
	_component.take_damage(100.0)
	assert_bool(_component.is_alive()).is_false()

func test_take_damage_health_depleted_emitted_exactly_once_not_twice() -> void:
	var count: int = 0
	_component.health_depleted.connect(func() -> void: count += 1)
	_component.take_damage(100.0)
	_component.take_damage(100.0)
	assert_int(count).is_equal(1)

func test_take_damage_when_dead_does_not_emit_health_changed() -> void:
	_component.take_damage(100.0)
	var monitor := monitor_signals(_component, false)
	_component.take_damage(50.0)
	assert_signal(monitor).is_not_emitted("health_changed")

func test_take_damage_when_dead_hp_stays_at_zero() -> void:
	_component.take_damage(100.0)
	_component.take_damage(50.0)
	assert_int(_component.current_hp).is_equal(0)

func test_take_damage_partial_does_not_emit_health_depleted() -> void:
	var monitor := monitor_signals(_component, false)
	_component.take_damage(50.0)
	assert_signal(monitor).is_not_emitted("health_depleted")

func test_take_damage_float_fractional_part_truncated() -> void:
	# int(30.9) == 30, so current_hp should be 70 not 69.
	_component.take_damage(30.9)
	assert_int(_component.current_hp).is_equal(70)

func test_take_damage_exactly_one_hp_remaining_is_still_alive() -> void:
	_component.take_damage(99.0)
	assert_bool(_component.is_alive()).is_true()
	assert_int(_component.current_hp).is_equal(1)

func test_take_damage_sequential_calls_accumulate_correctly() -> void:
	_component.take_damage(30.0)
	_component.take_damage(30.0)
	assert_int(_component.current_hp).is_equal(40)

# ════════════════════════════════════════════
# heal
# ════════════════════════════════════════════

func test_heal_increases_current_hp() -> void:
	_component.take_damage(40.0)
	_component.heal(20)
	assert_int(_component.current_hp).is_equal(80)

func test_heal_clamps_to_max_hp() -> void:
	_component.take_damage(10.0)
	_component.heal(50)
	assert_int(_component.current_hp).is_equal(100)

func test_heal_at_full_hp_stays_at_max() -> void:
	_component.heal(99)
	assert_int(_component.current_hp).is_equal(100)

func test_heal_emits_health_changed() -> void:
	_component.take_damage(20.0)
	var monitor := monitor_signals(_component, false)
	_component.heal(10)
	await assert_signal(monitor).is_emitted("health_changed", [90, 100])

func test_heal_does_not_revive_dead_entity() -> void:
	_component.take_damage(100.0)
	_component.heal(50)
	# is_alive must remain false — heal() does not reset _is_alive
	assert_bool(_component.is_alive()).is_false()

func test_heal_on_dead_entity_hp_still_clamps_to_max() -> void:
	_component.take_damage(100.0)
	_component.heal(50)
	# current_hp increases via heal() but entity is still considered dead.
	# This is intentional — only reset_to_max() revives.
	assert_int(_component.current_hp).is_equal(50)

# ════════════════════════════════════════════
# reset_to_max
# ════════════════════════════════════════════

func test_reset_to_max_restores_full_hp() -> void:
	_component.take_damage(60.0)
	_component.reset_to_max()
	assert_int(_component.current_hp).is_equal(100)

func test_reset_to_max_sets_is_alive_true_after_death() -> void:
	_component.take_damage(100.0)
	_component.reset_to_max()
	assert_bool(_component.is_alive()).is_true()

func test_reset_to_max_emits_health_changed() -> void:
	_component.take_damage(50.0)
	var monitor := monitor_signals(_component, false)
	_component.reset_to_max()
	await assert_signal(monitor).is_emitted("health_changed", [100, 100])

func test_reset_to_max_allows_health_depleted_to_fire_again() -> void:
	_component.take_damage(100.0)
	_component.reset_to_max()
	var count: int = 0
	_component.health_depleted.connect(func() -> void: count += 1)
	_component.take_damage(100.0)
	assert_int(count).is_equal(1)

func test_reset_to_max_on_full_hp_still_emits_health_changed() -> void:
	var monitor := monitor_signals(_component, false)
	_component.reset_to_max()
	await assert_signal(monitor).is_emitted("health_changed", [100, 100])

func test_reset_to_max_full_cycle_damage_reset_damage() -> void:
	_component.take_damage(100.0)
	_component.reset_to_max()
	_component.take_damage(40.0)
	assert_int(_component.current_hp).is_equal(60)
	assert_bool(_component.is_alive()).is_true()

# ════════════════════════════════════════════
# is_alive
# ════════════════════════════════════════════

func test_is_alive_true_when_hp_above_zero() -> void:
	_component.take_damage(50.0)
	assert_bool(_component.is_alive()).is_true()

func test_is_alive_false_after_lethal_damage() -> void:
	_component.take_damage(100.0)
	assert_bool(_component.is_alive()).is_false()

func test_is_alive_true_after_reset_to_max() -> void:
	_component.take_damage(100.0)
	_component.reset_to_max()
	assert_bool(_component.is_alive()).is_true()

# ════════════════════════════════════════════
# health_changed signal payload
# ════════════════════════════════════════════

func test_health_changed_payload_current_hp_correct_after_damage() -> void:
	var received_hp: int = -1
	_component.health_changed.connect(
		func(cur: int, _max: int) -> void: received_hp = cur,
		CONNECT_ONE_SHOT
	)
	_component.take_damage(25.0)
	assert_int(received_hp).is_equal(75)

func test_health_changed_payload_max_hp_correct() -> void:
	var received_max: int = -1
	_component.health_changed.connect(
		func(_cur: int, mx: int) -> void: received_max = mx,
		CONNECT_ONE_SHOT
	)
	_component.take_damage(10.0)
	assert_int(received_max).is_equal(100)

func test_health_changed_payload_after_heal_correct() -> void:
	_component.take_damage(50.0)
	var received_hp: int = -1
	_component.health_changed.connect(
		func(cur: int, _max: int) -> void: received_hp = cur,
		CONNECT_ONE_SHOT
	)
	_component.heal(20)
	assert_int(received_hp).is_equal(70)

# ════════════════════════════════════════════
# max_hp export integration
# ════════════════════════════════════════════

func test_different_max_hp_export_uses_correct_starting_hp() -> void:
	var comp2: HealthComponent = HealthComponent.new()
	comp2.max_hp = 250
	add_child(comp2)
	assert_int(comp2.current_hp).is_equal(250)
	comp2.queue_free()

func test_take_damage_on_custom_max_hp_clamps_correctly() -> void:
	var comp2: HealthComponent = HealthComponent.new()
	comp2.max_hp = 50
	add_child(comp2)
	comp2.take_damage(30.0)
	assert_int(comp2.current_hp).is_equal(20)
	comp2.queue_free()

