# test_arnulf_state_machine.gd
# GdUnit4 test suite for Arnulf's AI state machine.
# Covers: state transitions, target selection, damage, recovery, signals.
#
# Credit: Foul Ward SYSTEMS_part3.md §7.8 (GdUnit4 test specifications)
# Credit: GdUnit4 documentation — https://mikeschulze.github.io/gdUnit4/ — MIT License

class_name TestArnulfStateMachine
extends GdUnitTestSuite

var _arnulf: Arnulf


func _create_arnulf() -> Arnulf:
	var scene: PackedScene = load("res://scenes/arnulf/arnulf.tscn")
	var arnulf: Arnulf = scene.instantiate() as Arnulf
	add_child(arnulf)
	return arnulf


func _make_enemy_data(is_flying: bool = false) -> EnemyData:
	var d: EnemyData = EnemyData.new()
	d.is_flying = is_flying
	d.max_hp = 50
	d.move_speed = 3.0
	d.damage = 5
	d.attack_range = 1.5
	d.attack_cooldown = 1.0
	d.armor_type = Types.ArmorType.UNARMORED
	d.gold_reward = 5
	d.enemy_type = Types.EnemyType.ORC_GRUNT
	d.damage_immunities = []
	return d


func _spawn_enemy(pos: Vector3, is_flying: bool = false) -> EnemyBase:
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	add_child(enemy)
	enemy.initialize(_make_enemy_data(is_flying))
	enemy.global_position = pos
	return enemy

# ---------------------------------------------------------------------------
# SETUP / TEARDOWN
# ---------------------------------------------------------------------------

func before_test() -> void:
	_arnulf = _create_arnulf()


func after_test() -> void:
	if is_instance_valid(_arnulf):
		_arnulf.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# TEST: Initial state
# ---------------------------------------------------------------------------

func test_initial_state_is_idle() -> void:
	assert_that(_arnulf.get_current_state()).is_equal(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# TEST: IDLE → CHASE via detection
# ---------------------------------------------------------------------------

func test_enemy_in_detection_area_triggers_chase() -> void:
	var enemy := _spawn_enemy(Vector3(3.0, 0.0, 0.0))

	_arnulf._on_detection_area_body_entered(enemy)

	assert_that(_arnulf.get_current_state()).is_equal(Types.ArnulfState.CHASE)
	assert_object(_arnulf._chase_target).is_not_null()

	enemy.queue_free()

# ---------------------------------------------------------------------------
# TEST: Target selection — closest to tower, not to Arnulf
# ---------------------------------------------------------------------------

func test_target_selection_picks_closest_to_tower_not_arnulf() -> void:
	_arnulf.global_position = Vector3(15.0, 0.0, 0.0)

	# Enemy A: dist 3 to tower, dist 12 to Arnulf → should be selected.
	var enemy_a := _spawn_enemy(Vector3(3.0, 0.0, 0.0))
	# Enemy B: dist 14 to tower, dist 1 to Arnulf → should NOT be selected.
	var enemy_b := _spawn_enemy(Vector3(14.0, 0.0, 0.0))

	_arnulf._on_detection_area_body_entered(enemy_a)

	assert_object(_arnulf._chase_target).is_equal(enemy_a)

	enemy_a.queue_free()
	enemy_b.queue_free()

# ---------------------------------------------------------------------------
# TEST: Flying enemies ignored by Arnulf
# ---------------------------------------------------------------------------

func test_flying_enemy_ignored_by_arnulf() -> void:
	var flying_enemy := _spawn_enemy(Vector3(5.0, 5.0, 0.0), true)

	_arnulf._on_detection_area_body_entered(flying_enemy)

	assert_that(_arnulf.get_current_state()).is_equal(Types.ArnulfState.IDLE)

	flying_enemy.queue_free()

# ---------------------------------------------------------------------------
# TEST: Attack deals correct damage via DamageCalculator
# ---------------------------------------------------------------------------

func test_attack_deals_correct_damage() -> void:
	# PHYSICAL vs UNARMORED = 1.0x → attack_damage = 25.0 → 25 damage.
	var enemy := _spawn_enemy(Vector3(1.5, 0.0, 0.0))
	var data: EnemyData = EnemyData.new()
	data.is_flying = false
	data.max_hp = 200
	data.move_speed = 1.0
	data.damage = 5
	data.attack_range = 1.5
	data.attack_cooldown = 1.0
	data.armor_type = Types.ArmorType.UNARMORED
	data.gold_reward = 5
	data.enemy_type = Types.EnemyType.ORC_GRUNT
	data.damage_immunities = []
	enemy.initialize(data)

	_arnulf._chase_target = enemy
	_arnulf._transition_to_state(Types.ArnulfState.ATTACK)

	# Timer starts at 0 on ATTACK entry — first hit fires on first call.
	_arnulf._process_attack(0.016)

	assert_that(enemy.health_component.get_current_hp()).is_equal(200 - 25)

	enemy.queue_free()

# ---------------------------------------------------------------------------
# TEST: Health depleted → DOWNED
# ---------------------------------------------------------------------------

func test_health_depleted_transitions_to_downed() -> void:
	var monitor := monitor_signals(SignalBus, false)

	_arnulf.health_component.take_damage(float(_arnulf.max_hp))

	assert_that(_arnulf.get_current_state()).is_equal(Types.ArnulfState.DOWNED)
	await assert_signal(SignalBus).is_emitted("arnulf_incapacitated")
	await assert_signal(SignalBus).is_emitted(
		"arnulf_state_changed", [Types.ArnulfState.DOWNED]
	)


func test_arnulf_incapacitated_signal_emitted_on_downed() -> void:
	var monitor := monitor_signals(SignalBus, false)

	_arnulf._transition_to_state(Types.ArnulfState.DOWNED)

	await assert_signal(SignalBus).is_emitted("arnulf_incapacitated")

# ---------------------------------------------------------------------------
# TEST: Recovery timer respects delta
# ---------------------------------------------------------------------------

func test_recovery_timer_uses_delta() -> void:
	_arnulf._transition_to_state(Types.ArnulfState.DOWNED)
	var initial_timer: float = _arnulf._recovery_timer
	assert_float(initial_timer).is_equal(_arnulf.recovery_time)

	_arnulf._process_downed(1.0)

	assert_float(_arnulf._recovery_timer).is_equal(initial_timer - 1.0)

	# Overshoot to trigger transition out of DOWNED.
	_arnulf._process_downed(_arnulf._recovery_timer + 0.1)

	assert_that(_arnulf.get_current_state()).is_not_equal(Types.ArnulfState.DOWNED)

# ---------------------------------------------------------------------------
# TEST: Recovering restores full HP (reset_to_max after downed)
# ---------------------------------------------------------------------------

func test_recovering_restores_full_hp() -> void:
	_arnulf.health_component.take_damage(float(_arnulf.max_hp))
	assert_that(_arnulf.get_current_state()).is_equal(Types.ArnulfState.DOWNED)

	_arnulf._transition_to_state(Types.ArnulfState.RECOVERING)
	_arnulf._process_recovering()

	assert_that(_arnulf.get_current_hp()).is_equal(_arnulf.max_hp)

# ---------------------------------------------------------------------------
# TEST: RECOVERING → IDLE
# ---------------------------------------------------------------------------

func test_recovering_transitions_to_idle() -> void:
	_arnulf._transition_to_state(Types.ArnulfState.DOWNED)
	_arnulf._transition_to_state(Types.ArnulfState.RECOVERING)
	_arnulf._process_recovering()

	assert_that(_arnulf.get_current_state()).is_equal(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# TEST: Kill counter
# ---------------------------------------------------------------------------

func test_kill_counter_increments_on_enemy_killed_signal() -> void:
	assert_that(_arnulf._kill_counter).is_equal(0)

	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
	SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)

	assert_that(_arnulf._kill_counter).is_equal(3)

# ---------------------------------------------------------------------------
# TEST: reset_for_new_mission
# ---------------------------------------------------------------------------

func test_reset_for_new_mission_restores_full_hp() -> void:
	_arnulf.health_component.take_damage(float(_arnulf.max_hp))
	_arnulf._kill_counter = 5

	_arnulf.reset_for_new_mission()

	assert_that(_arnulf.get_current_hp()).is_equal(_arnulf.max_hp)
	assert_that(_arnulf.get_current_state()).is_equal(Types.ArnulfState.IDLE)
	assert_that(_arnulf._kill_counter).is_equal(0)
	assert_that(_arnulf.global_position).is_equal(Arnulf.HOME_POSITION)

