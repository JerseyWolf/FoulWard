# test_wave_manager.gd
# GdUnit4 test suite for WaveManager.
# Covers: countdown, wave scaling formula, spawn behavior, signals, clear/reset.
#
# Credit: Foul Ward SYSTEMS_part1.md §1.8 (GdUnit4 test specifications)
# Credit: GdUnit4 documentation — https://mikeschulze.github.io/gdUnit4/ — MIT License

class_name TestWaveManager
extends GdUnitTestSuite

var _wave_manager: WaveManager
var _enemy_container: Node3D
var _spawn_points: Node3D


func _build_wave_manager() -> WaveManager:
	_enemy_container = Node3D.new()
	_enemy_container.name = "EnemyContainer"
	add_child(_enemy_container)

	_spawn_points = Node3D.new()
	_spawn_points.name = "SpawnPoints"
	for i: int in range(10):
		var marker: Marker3D = Marker3D.new()
		marker.global_position = Vector3(float(i) * 4.0, 0.0, 0.0)
		_spawn_points.add_child(marker)
	add_child(_spawn_points)

	var wm: WaveManager = WaveManager.new()
	wm.wave_countdown_duration = 30.0
	wm.max_waves = 10
	wm.enemy_data_registry = _build_six_enemy_data()
	add_child(wm)

	# Inject mocks directly — bypasses @onready absolute path lookup.
	wm._enemy_container = _enemy_container
	wm._spawn_points = _spawn_points

	return wm


func _build_six_enemy_data() -> Array[EnemyData]:
	var registry: Array[EnemyData] = []
	var types: Array = [
		Types.EnemyType.ORC_GRUNT,
		Types.EnemyType.ORC_BRUTE,
		Types.EnemyType.GOBLIN_FIREBUG,
		Types.EnemyType.PLAGUE_ZOMBIE,
		Types.EnemyType.ORC_ARCHER,
		Types.EnemyType.BAT_SWARM
	]
	for t: Types.EnemyType in types:
		var d: EnemyData = EnemyData.new()
		d.enemy_type = t
		d.max_hp = 50
		d.move_speed = 3.0
		d.damage = 5
		d.attack_range = 1.5
		d.attack_cooldown = 1.0
		d.armor_type = Types.ArmorType.UNARMORED
		d.gold_reward = 5
		d.is_flying = (t == Types.EnemyType.BAT_SWARM)
		d.is_ranged = (t == Types.EnemyType.ORC_ARCHER)
		d.damage_immunities = []
		registry.append(d)
	return registry

# ---------------------------------------------------------------------------
# SETUP / TEARDOWN
# ---------------------------------------------------------------------------

func before_test() -> void:
	_wave_manager = _build_wave_manager()


func after_test() -> void:
	if is_instance_valid(_wave_manager):
		_wave_manager.clear_all_enemies()
		_wave_manager.queue_free()
	if is_instance_valid(_enemy_container):
		_enemy_container.queue_free()
	if is_instance_valid(_spawn_points):
		_spawn_points.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# TEST: Countdown
# ---------------------------------------------------------------------------

func test_start_wave_sequence_triggers_countdown() -> void:
	var monitor := monitor_signals(SignalBus, false)

	_wave_manager.start_wave_sequence()

	assert_that(_wave_manager.is_counting_down()).is_true()
	# Wave 1 uses first_wave_countdown_seconds (default 3) so "Start Game" reaches combat quickly.
	assert_float(_wave_manager.get_countdown_remaining()).is_equal(3.0)
	assert_that(_wave_manager.get_current_wave_number()).is_equal(1)
	await assert_signal(SignalBus).is_emitted("wave_countdown_started", [1, 3.0])


func test_countdown_decrements_with_delta() -> void:
	_wave_manager.start_wave_sequence()
	var initial: float = _wave_manager.get_countdown_remaining()

	_wave_manager._process_countdown(2.0)

	assert_float(_wave_manager.get_countdown_remaining()).is_equal(initial - 2.0)

# ---------------------------------------------------------------------------
# TEST: Wave scaling formula
# ---------------------------------------------------------------------------

func test_wave_1_spawns_6_enemies() -> void:
	_wave_manager.force_spawn_wave(1)
	await get_tree().process_frame
	assert_that(_wave_manager.get_living_enemy_count()).is_equal(6)


func test_wave_5_spawns_30_enemies() -> void:
	_wave_manager.force_spawn_wave(5)
	await get_tree().process_frame
	assert_that(_wave_manager.get_living_enemy_count()).is_equal(30)


func test_wave_10_spawns_60_enemies() -> void:
	_wave_manager.force_spawn_wave(10)
	await get_tree().process_frame
	assert_that(_wave_manager.get_living_enemy_count()).is_equal(60)

# ---------------------------------------------------------------------------
# TEST: force_spawn_wave skips countdown
# ---------------------------------------------------------------------------

func test_force_spawn_wave_skips_countdown() -> void:
	_wave_manager.start_wave_sequence()
	assert_that(_wave_manager.is_counting_down()).is_true()

	_wave_manager.force_spawn_wave(3)
	await get_tree().process_frame

	assert_that(_wave_manager.is_counting_down()).is_false()
	assert_that(_wave_manager.is_wave_active()).is_true()
	assert_that(_wave_manager.get_current_wave_number()).is_equal(3)

# ---------------------------------------------------------------------------
# TEST: all_waves_cleared emitted after wave 10
# ---------------------------------------------------------------------------

func test_all_waves_cleared_emitted_after_wave_10() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_wave_manager.force_spawn_wave(10)
	await get_tree().process_frame

	_wave_manager.clear_all_enemies()
	_wave_manager._check_wave_cleared()
	await get_tree().process_frame

	await assert_signal(SignalBus).is_emitted("wave_cleared", [10])
	await assert_signal(SignalBus).is_emitted("all_waves_cleared")
	assert_that(_wave_manager.is_wave_active()).is_false()

# ---------------------------------------------------------------------------
# TEST: clear_all_enemies
# ---------------------------------------------------------------------------

func test_clear_all_enemies_removes_from_group() -> void:
	_wave_manager.force_spawn_wave(2)
	await get_tree().process_frame
	assert_that(_wave_manager.get_living_enemy_count()).is_equal(12)

	_wave_manager.clear_all_enemies()
	await get_tree().process_frame

	assert_that(_wave_manager.get_living_enemy_count()).is_equal(0)


func test_living_enemy_count_zero_after_clear() -> void:
	_wave_manager.force_spawn_wave(3)
	await get_tree().process_frame
	assert_that(_wave_manager.get_living_enemy_count()).is_equal(18)

	_wave_manager.clear_all_enemies()
	await get_tree().process_frame

	assert_that(_wave_manager.get_living_enemy_count()).is_equal(0)

# ---------------------------------------------------------------------------
# TEST: call_deferred — wave not cleared until last kill
# ---------------------------------------------------------------------------

func test_check_wave_cleared_uses_call_deferred() -> void:
	_wave_manager.force_spawn_wave(1)
	await get_tree().process_frame

	var monitor := monitor_signals(SignalBus, false)

	# Emit 5 of 6 kills — enemies still in group, wave must NOT clear yet.
	for i: int in range(5):
		SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 5)
	await get_tree().process_frame

	await assert_signal(SignalBus).is_not_emitted("wave_cleared")

