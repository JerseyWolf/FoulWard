# test_boss_waves.gd
# GdUnit4: WaveManager boss + escort spawning (Prompt 10).

class_name TestBossWaves
extends GdUnitTestSuite

var _wave_manager: WaveManager
var _enemy_container: Node3D
var _spawn_points: Node3D
## Boss wave tests can emit `all_waves_cleared` on the final wave; pause GameManager's handler for isolation.
var _gm_all_waves_handler_paused: bool = false


func _build_wave_manager() -> WaveManager:
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

	wm._enemy_container = _enemy_container
	wm._spawn_points = _spawn_points
	return wm


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


func _flush_composed_spawns() -> void:
	var max_iter: int = 10000
	while _wave_manager.has_pending_composed_spawns() and max_iter > 0:
		_wave_manager._physics_process(0.5)
		max_iter -= 1


func test_wave_manager_spawns_one_mini_boss_and_escorts_on_mini_boss_day() -> void:
	var day: DayConfig = DayConfig.new()
	day.day_index = 1
	day.base_wave_count = 10
	day.is_mini_boss = true
	day.faction_id = "DEFAULT_MIXED"

	var faction: FactionData = FactionData.new()
	faction.faction_id = "TEST"
	faction.mini_boss_ids = ["miniboss_test"]
	var roster_entry: FactionRosterEntry = FactionRosterEntry.new()
	roster_entry.enemy_type = Types.EnemyType.ORC_GRUNT
	roster_entry.base_weight = 1.0
	roster_entry.min_wave_index = 1
	roster_entry.max_wave_index = 10
	roster_entry.tier = 1
	faction.roster = [roster_entry]

	var boss_data: BossData = BossData.new()
	boss_data.boss_id = "miniboss_test"
	boss_data.display_name = "Mini"
	boss_data.boss_scene = preload("res://scenes/bosses/boss_base.tscn")
	boss_data.escort_unit_ids = ["ORC_GRUNT", "ORC_BRUTE"]

	_wave_manager.ensure_boss_registry_loaded()
	_wave_manager.boss_registry["miniboss_test"] = boss_data
	_wave_manager.set_day_context(day, faction)
	_wave_manager.force_spawn_wave(_wave_manager.max_waves)
	_flush_composed_spawns()

	var boss_count: int = 0
	var escort_count: int = 0
	for child: Node in _enemy_container.get_children():
		if child is BossBase:
			boss_count += 1
		elif child is EnemyBase:
			escort_count += 1
	assert_int(boss_count).is_equal(1)
	assert_int(escort_count).is_greater_equal(boss_data.escort_unit_ids.size())


func test_mini_boss_wave_only_completes_when_boss_and_escorts_dead() -> void:
	var day: DayConfig = DayConfig.new()
	day.day_index = 1
	day.base_wave_count = 10
	day.is_mini_boss = true

	var faction: FactionData = FactionData.new()
	faction.faction_id = "TEST"
	faction.mini_boss_ids = ["miniboss_test"]
	var roster_entry2: FactionRosterEntry = FactionRosterEntry.new()
	roster_entry2.enemy_type = Types.EnemyType.ORC_GRUNT
	roster_entry2.base_weight = 1.0
	roster_entry2.min_wave_index = 1
	roster_entry2.max_wave_index = 10
	roster_entry2.tier = 1
	faction.roster = [roster_entry2]

	var boss_data: BossData = BossData.new()
	boss_data.boss_id = "miniboss_test"
	boss_data.display_name = "Mini"
	boss_data.boss_scene = preload("res://scenes/bosses/boss_base.tscn")
	boss_data.escort_unit_ids = ["ORC_GRUNT"]

	_wave_manager.ensure_boss_registry_loaded()
	_wave_manager.boss_registry["miniboss_test"] = boss_data
	_wave_manager.set_day_context(day, faction)

	_wave_manager.force_spawn_wave(_wave_manager.max_waves)
	_flush_composed_spawns()

	for child: Node in _enemy_container.get_children():
		if child is EnemyBase and not (child is BossBase):
			(child as EnemyBase).take_damage(50000.0, Types.DamageType.PHYSICAL)

	await get_tree().process_frame
	await get_tree().process_frame
	await assert_signal(SignalBus).is_not_emitted("wave_cleared")

	for child: Node in _enemy_container.get_children():
		if child is BossBase:
			(child as BossBase).take_damage(50000.0, Types.DamageType.PHYSICAL)

	await get_tree().process_frame
	await get_tree().process_frame
	await assert_signal(SignalBus).is_emitted("wave_cleared", [_wave_manager.max_waves])
