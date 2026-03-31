# test_wave_manager.gd
# GdUnit4 test suite for WaveManager.
# Covers: countdown, wave scaling formula, spawn behavior, signals, clear/reset.
#
# Credit: Foul Ward SYSTEMS_part1.md §1.8 (GdUnit4 test specifications)
# Credit: GdUnit4 documentation — https://mikeschulze.github.io/gdUnit4/ — MIT License

class_name TestWaveManager
extends GdUnitTestSuite

const WaveComposerType = preload("res://scripts/wave_composer.gd")

var _wave_manager: WaveManager
var _enemy_container: Node3D
var _spawn_points: Node3D
## Isolated WaveManager tests emit `all_waves_cleared`; pause GameManager's handler to avoid log noise + economy/mission side effects.
var _gm_all_waves_handler_paused: bool = false


func _build_wave_manager() -> WaveManager:
	# SpawnPoints must be in the tree before Marker3D children use global_position (valid global_transform).
	_enemy_container = Node3D.new()
	_enemy_container.name = "EnemyContainer"
	add_child(_enemy_container)

	_spawn_points = Node3D.new()
	_spawn_points.name = "SpawnPoints"
	add_child(_spawn_points)
	for i: int in range(10):
		var marker: Marker3D = Marker3D.new()
		_spawn_points.add_child(marker)
		marker.global_position = Vector3(float(i) * 4.0, 0.0, 0.0)

	var wm: WaveManager = WaveManager.new()
	wm.wave_countdown_duration = 10.0
	wm.max_waves = 10
	wm.enemy_data_registry = _build_full_enemy_data()
	add_child(wm)

	# _ready used get_node_or_null → null without /root/Main; inject test nodes after wm enters tree.
	wm._enemy_container = _enemy_container
	wm._spawn_points = _spawn_points

	return wm


func _flush_composed_spawns() -> void:
	var max_iter: int = 10000
	while _wave_manager.has_pending_composed_spawns() and max_iter > 0:
		_wave_manager._physics_process(0.5)
		max_iter -= 1


func _expected_composed_count(wave_number: int) -> int:
	var pattern: Resource = load("res://resources/wave_patterns/default_campaign_pattern.tres")
	seed(_wave_manager.mission_spawn_seed + wave_number * 7919 + 17)
	return WaveComposerType.new(_wave_manager.enemy_data_registry, pattern).compose_wave(wave_number - 1).size()


func _build_full_enemy_data() -> Array[EnemyData]:
	var registry: Array[EnemyData] = []
	for t: Types.EnemyType in Types.EnemyType.values():
		var d: EnemyData = EnemyData.new()
		d.enemy_type = t
		d.max_hp = 50
		d.move_speed = 3.0
		d.damage = 5
		d.attack_range = 1.5
		d.attack_cooldown = 1.0
		d.armor_type = Types.ArmorType.UNARMORED
		d.gold_reward = 5
		d.is_flying = (
				t == Types.EnemyType.BAT_SWARM
				or t == Types.EnemyType.HARPY_SCOUT
				or t == Types.EnemyType.WYVERN_RIDER
				or t == Types.EnemyType.ORCISH_SPIRIT
		)
		d.is_ranged = (
				t == Types.EnemyType.ORC_ARCHER
				or t == Types.EnemyType.ORC_MARKSMAN
				or t == Types.EnemyType.WYVERN_RIDER
				or t == Types.EnemyType.ORC_SKYTHROWER
		)
		d.damage_immunities = []
		d.point_cost = 5
		d.wave_tags = ["RUSH", "INVASION", "HEAVY", "AIRSTRIKE", "SUPPORT", "MIXED", "ARTILLERY"]
		d.tier = 1
		d.balance_status = "UNTESTED"
		registry.append(d)
	return registry

# ---------------------------------------------------------------------------
# SETUP / TEARDOWN
# ---------------------------------------------------------------------------

func before_test() -> void:
	_gm_all_waves_handler_paused = false
	if SignalBus.all_waves_cleared.is_connected(GameManager._on_all_waves_cleared):
		SignalBus.all_waves_cleared.disconnect(GameManager._on_all_waves_cleared)
		_gm_all_waves_handler_paused = true
	_wave_manager = _build_wave_manager()


func after_test() -> void:
	if is_instance_valid(_wave_manager):
		_wave_manager.clear_all_enemies()
		_wave_manager.set_faction_data_override(null)
		_wave_manager.queue_free()
	if is_instance_valid(_enemy_container):
		_enemy_container.queue_free()
	if is_instance_valid(_spawn_points):
		_spawn_points.queue_free()
	if _gm_all_waves_handler_paused:
		if not SignalBus.all_waves_cleared.is_connected(GameManager._on_all_waves_cleared):
			SignalBus.all_waves_cleared.connect(GameManager._on_all_waves_cleared)
		_gm_all_waves_handler_paused = false
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

func test_wave_1_spawns_composed_enemies() -> void:
	var expected: int = _expected_composed_count(1)
	_wave_manager.force_spawn_wave(1)
	_flush_composed_spawns()
	assert_int(_wave_manager.get_living_enemy_count()).is_equal(expected)


func test_wave_5_spawns_composed_enemies() -> void:
	var expected: int = _expected_composed_count(5)
	_wave_manager.force_spawn_wave(5)
	_flush_composed_spawns()
	assert_int(_wave_manager.get_living_enemy_count()).is_equal(expected)


func test_wave_10_spawns_composed_enemies() -> void:
	var expected: int = _expected_composed_count(10)
	_wave_manager.force_spawn_wave(10)
	_flush_composed_spawns()
	assert_int(_wave_manager.get_living_enemy_count()).is_equal(expected)

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
	var expected: int = _expected_composed_count(2)
	_wave_manager.force_spawn_wave(2)
	_flush_composed_spawns()
	assert_int(_wave_manager.get_living_enemy_count()).is_equal(expected)

	_wave_manager.clear_all_enemies()
	await get_tree().process_frame

	assert_that(_wave_manager.get_living_enemy_count()).is_equal(0)


func test_living_enemy_count_zero_after_clear() -> void:
	var expected: int = _expected_composed_count(3)
	_wave_manager.force_spawn_wave(3)
	_flush_composed_spawns()
	assert_int(_wave_manager.get_living_enemy_count()).is_equal(expected)

	_wave_manager.clear_all_enemies()
	await get_tree().process_frame

	assert_that(_wave_manager.get_living_enemy_count()).is_equal(0)

# ---------------------------------------------------------------------------
# TEST: call_deferred — wave not cleared until last kill
# ---------------------------------------------------------------------------

func test_check_wave_cleared_uses_call_deferred() -> void:
	_wave_manager.force_spawn_wave(1)
	_flush_composed_spawns()

	var monitor := monitor_signals(SignalBus, false)

	var n: int = _wave_manager.get_living_enemy_count()
	if n < 2:
		return
	var kills: int = mini(5, n - 1)
	for i: int in range(kills):
		SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 5)
	await get_tree().process_frame

	await assert_signal(SignalBus).is_not_emitted("wave_cleared")

func test_dayconfig_wave_count_configures_wavemanager() -> void:
	var day_config: DayConfig = DayConfig.new()
	day_config.base_wave_count = 7

	var default_max: int = _wave_manager.max_waves
	_wave_manager.configure_for_day(day_config)

	var expected: int = mini(7, default_max)
	assert_int(_wave_manager.configured_max_waves).is_equal(expected)

func test_dayconfig_wave_count_clamps_to_maxwaves() -> void:
	var day_config: DayConfig = DayConfig.new()
	day_config.base_wave_count = 9999
	_wave_manager.configure_for_day(day_config)
	assert_int(_wave_manager.configured_max_waves).is_less_equal(_wave_manager.max_waves)

func test_dayconfig_difficulty_multipliers_stored_in_wavemanager() -> void:
	var day_config: DayConfig = DayConfig.new()
	day_config.enemy_hp_multiplier = 1.5
	day_config.enemy_damage_multiplier = 2.0
	day_config.gold_reward_multiplier = 0.75
	_wave_manager.configure_for_day(day_config)
	assert_float(_wave_manager.enemy_hp_multiplier).is_equal(1.5)
	assert_float(_wave_manager.enemy_damage_multiplier).is_equal(2.0)
	assert_float(_wave_manager.gold_reward_multiplier).is_equal(0.75)

func test_null_dayconfig_does_not_crash_wavemanager() -> void:
	_wave_manager.configure_for_day(null)
	assert_int(_wave_manager.configured_max_waves).is_greater_equal(0)

func test_resetfornewmission_clears_day_config_values() -> void:
	var day_config: DayConfig = DayConfig.new()
	day_config.base_wave_count = 7
	day_config.enemy_hp_multiplier = 2.0
	_wave_manager.configure_for_day(day_config)
	_wave_manager.reset_for_new_mission()
	assert_int(_wave_manager.configured_max_waves).is_equal(0)
	assert_float(_wave_manager.enemy_hp_multiplier).is_equal(1.0)


# ---------------------------------------------------------------------------
# Prompt 9 — faction-weighted waves (# DEVIATION: per-type counts approximate)
# ---------------------------------------------------------------------------

func _collect_spawned_enemy_types() -> Array[Types.EnemyType]:
	var result: Array[Types.EnemyType] = []
	for node: Node in _enemy_container.get_children():
		if node is EnemyBase:
			var enemy: EnemyBase = node as EnemyBase
			var data: EnemyData = enemy.get_enemy_data()
			if data != null:
				result.append(data.enemy_type)
	return result


func _count_types_in_enemy_container() -> Dictionary:
	var counts: Dictionary = {}
	for node: Node in _enemy_container.get_children():
		if node is EnemyBase:
			var enemy: EnemyBase = node as EnemyBase
			var data: EnemyData = enemy.get_enemy_data()
			if data == null:
				continue
			var t: Types.EnemyType = data.enemy_type
			counts[t] = counts.get(t, 0) + 1
	return counts


func _total_count(counts: Dictionary) -> int:
	var total: int = 0
	for v: Variant in counts.values():
		total += int(v)
	return total


func _clear_enemies_in_container() -> void:
	for node: Node in _enemy_container.get_children():
		if node is EnemyBase:
			(node as EnemyBase).queue_free()


func test_composed_wave_spawns_registry_enemy_types() -> void:
	_wave_manager.force_spawn_wave(2)
	_flush_composed_spawns()
	for t: Types.EnemyType in _collect_spawned_enemy_types():
		assert_object(_wave_manager.get_enemy_data_by_type(int(t))).is_not_null()

	_clear_enemies_in_container()
	await get_tree().process_frame

	_wave_manager.force_spawn_wave(7)
	_flush_composed_spawns()
	for t2: Types.EnemyType in _collect_spawned_enemy_types():
		assert_object(_wave_manager.get_enemy_data_by_type(int(t2))).is_not_null()


func test_wave_pattern_budget_increases_per_wave() -> void:
	var pattern: Resource = load("res://resources/wave_patterns/default_campaign_pattern.tres")
	var composer: RefCounted = WaveComposerType.new(_wave_manager.enemy_data_registry, pattern)
	assert_int(composer._compute_budget_for_wave(8)).is_greater(composer._compute_budget_for_wave(7))


func test_wave_manager_total_enemies_matches_composer() -> void:
	for wave: int in [1, 5, 10]:
		_clear_enemies_in_container()
		await get_tree().process_frame
		var expected: int = _expected_composed_count(wave)
		_wave_manager.force_spawn_wave(wave)
		_flush_composed_spawns()
		var counts: Dictionary = _count_types_in_enemy_container()
		var total: int = _total_count(counts)
		assert_int(total).is_equal(expected)


func test_mini_boss_hook_reports_expected_wave_when_configured() -> void:
	var faction: FactionData = FactionData.new()
	faction.faction_id = "TEST_MINIBOSS"
	faction.mini_boss_ids = ["MINI_TEST"]
	faction.mini_boss_wave_hints = [4]
	var e: FactionRosterEntry = FactionRosterEntry.new()
	e.enemy_type = Types.EnemyType.ORC_GRUNT
	e.base_weight = 1.0
	e.min_wave_index = 1
	e.max_wave_index = 10
	e.tier = 1
	faction.roster = [e]

	_wave_manager.set_faction_data_override(faction)

	var info3: Dictionary = _wave_manager.get_mini_boss_info_for_wave(3)
	var info4: Dictionary = _wave_manager.get_mini_boss_info_for_wave(4)

	assert_that(info3).is_equal({})
	assert_str(info4.get("mini_boss_id", "")).is_equal("MINI_TEST")
	assert_int(info4.get("wave_index", -1)).is_equal(4)
	assert_str(info4.get("faction_id", "")).is_equal("TEST_MINIBOSS")


func test_default_faction_preserves_mixed_composition_trend() -> void:
	var faction: FactionData = load("res://resources/faction_data_default_mixed.tres") as FactionData
	assert_that(faction).is_not_null()
	_wave_manager.set_faction_data_override(faction)

	var observed_types: Dictionary = {}

	for wave: int in [1, 3, 5, 7, 10]:
		_clear_enemies_in_container()
		await get_tree().process_frame
		var expected: int = _expected_composed_count(wave)
		_wave_manager.force_spawn_wave(wave)
		_flush_composed_spawns()
		var counts: Dictionary = _count_types_in_enemy_container()
		var total: int = _total_count(counts)
		assert_int(total).is_equal(expected)
		for k: Variant in counts.keys():
			observed_types[k] = true

	# Composer draws from the full registry; ensure we saw a mix across waves.
	assert_int(observed_types.size()).is_greater_equal(2)


func test_regular_day_spawns_no_bosses() -> void:
	var day: DayConfig = DayConfig.new()
	day.day_index = 1
	day.base_wave_count = 10
	day.is_mini_boss_day = false
	day.is_mini_boss = false
	day.is_final_boss = false
	day.faction_id = "DEFAULT_MIXED"
	_wave_manager.configure_for_day(day)
	_wave_manager.force_spawn_wave(_wave_manager.max_waves)
	await get_tree().process_frame
	for child: Node in _enemy_container.get_children():
		assert_bool(child is BossBase).is_false()


func test_configure_for_day_unknown_faction_falls_back_safely() -> void:
	var day: DayConfig = DayConfig.new()
	day.day_index = 1
	day.base_wave_count = 5
	day.faction_id = "NO_SUCH_FACTION_AUDIT5"
	_wave_manager.configure_for_day(day)
	assert_object(_wave_manager.current_faction_data).is_not_null()
	assert_str(_wave_manager.current_faction_data.faction_id).is_equal("DEFAULT_MIXED")


func test_countdown_pauses_in_build_mode() -> void:
	_wave_manager.start_wave_sequence()
	assert_bool(_wave_manager.is_counting_down()).is_true()
	assert_bool(_wave_manager.is_wave_countdown_paused()).is_false()
	var t0: float = _wave_manager.get_countdown_remaining()
	SignalBus.game_state_changed.emit(Types.GameState.COMBAT, Types.GameState.BUILD_MODE)
	assert_bool(_wave_manager.is_wave_countdown_paused()).is_true()
	_wave_manager._physics_process(0.5)
	assert_float(_wave_manager.get_countdown_remaining()).is_equal(t0)


func test_countdown_resumes_on_combat_state() -> void:
	_wave_manager.start_wave_sequence()
	SignalBus.game_state_changed.emit(Types.GameState.COMBAT, Types.GameState.BUILD_MODE)
	assert_bool(_wave_manager.is_wave_countdown_paused()).is_true()
	var t0: float = _wave_manager.get_countdown_remaining()
	SignalBus.game_state_changed.emit(Types.GameState.BUILD_MODE, Types.GameState.COMBAT)
	assert_bool(_wave_manager.is_wave_countdown_paused()).is_false()
	_wave_manager._physics_process(1.0)
	assert_bool(_wave_manager.get_countdown_remaining() < t0).is_true()

