# test_boss_day_flow.gd — Audit 5: boss / territory / campaign completion flows (headless-safe).
class_name TestBossDayFlow
extends GdUnitTestSuite

var _saved_territory_map: TerritoryMapData = null
var _gm_all_waves_handler_paused: bool = false


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	_saved_territory_map = GameManager.territory_map
	GameManager.reset_boss_campaign_state_for_test()
	_gm_all_waves_handler_paused = false
	if SignalBus.all_waves_cleared.is_connected(GameManager._on_all_waves_cleared):
		SignalBus.all_waves_cleared.disconnect(GameManager._on_all_waves_cleared)
		_gm_all_waves_handler_paused = true


func after_test() -> void:
	if _gm_all_waves_handler_paused:
		if not SignalBus.all_waves_cleared.is_connected(GameManager._on_all_waves_cleared):
			SignalBus.all_waves_cleared.connect(GameManager._on_all_waves_cleared)
		_gm_all_waves_handler_paused = false
	GameManager.territory_map = _saved_territory_map
	if GameManager.territory_map != null:
		GameManager.territory_map.invalidate_cache()
	GameManager.reload_territory_map_from_active_campaign()
	CampaignManager.set_active_campaign_config_for_test(CampaignManager.DEFAULT_SHORT_CAMPAIGN)
	GameManager.start_new_game()
	for child: Node in get_children():
		if is_instance_valid(child) and not child is Timer:
			child.queue_free()
	await get_tree().process_frame


func test_mini_boss_kill_secures_territory_and_clears_threat() -> void:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap
	var territory: TerritoryData = tmap.get_territory_by_id("blackwood_forest")
	assert_object(territory).is_not_null()
	territory.is_secured = false
	territory.has_boss_threat = true

	SignalBus.boss_killed.emit("audit5_territory_mini")
	assert_bool(territory.is_secured).is_true()
	assert_bool(territory.has_boss_threat).is_false()


func test_mini_boss_defection_adds_ally_to_roster() -> void:
	GameManager.start_new_game()
	CampaignManager.notify_mini_boss_defeated("orc_captain")
	var idx: int = -1
	var offers: Array = CampaignManager.get_current_offers()
	for i: int in range(offers.size()):
		var o: Variant = offers[i]
		if o != null and str(o.get("ally_id")) == "defected_orc_captain":
			idx = i
			break
	assert_int(idx).is_greater_equal(0)
	assert_bool(CampaignManager.purchase_mercenary_offer(idx)).is_true()
	assert_bool(CampaignManager.owned_allies.has("defected_orc_captain")).is_true()
	assert_bool(CampaignManager.current_ally_roster_ids.has("defected_orc_captain")).is_true()


func test_final_boss_day_marks_defeated_and_completes_campaign() -> void:
	var d50: DayConfig = DayConfig.new()
	d50.day_index = 50
	d50.mission_index = 50
	d50.is_final_boss = true
	d50.boss_id = "final_boss_audit5"
	d50.faction_id = "DEFAULT_MIXED"

	var cfg: CampaignConfig = CampaignConfig.new()
	cfg.campaign_id = "audit5_final_boss"
	cfg.day_configs = [d50]
	CampaignManager.set_active_campaign_config_for_test(cfg)
	CampaignManager.start_new_campaign()
	CampaignManager.campaign_length = 1
	CampaignManager.current_day = 50
	CampaignManager.current_day_config = d50
	CampaignManager.campaign_completed = false

	GameManager.current_mission = 50
	GameManager.final_boss_id = "final_boss_audit5"
	GameManager.final_boss_day_index = 50
	GameManager.final_boss_active = false
	GameManager.final_boss_defeated = false

	var monitor := monitor_signals(SignalBus, false)
	GameManager._on_all_waves_cleared()
	await assert_signal(monitor).is_emitted("campaign_boss_attempted", [50, true])
	assert_bool(GameManager.final_boss_defeated).is_true()
	assert_bool(CampaignManager.campaign_completed).is_true()


func test_wave_manager_falls_back_when_faction_id_missing() -> void:
	var wm: WaveManager = _make_isolated_wave_manager()
	var day: DayConfig = DayConfig.new()
	day.day_index = 1
	day.base_wave_count = 10
	day.faction_id = "NONEXISTENT_FACTION_XYZ"
	wm.configure_for_day(day)
	assert_object(wm.current_faction_data).is_not_null()
	assert_str(wm.current_faction_data.faction_id).is_equal("DEFAULT_MIXED")
	wm.queue_free()


func test_boss_wave_one_boss_and_escorts_matches_boss_data() -> void:
	var wm: WaveManager = _make_isolated_wave_manager()
	var day: DayConfig = DayConfig.new()
	day.day_index = 1
	day.base_wave_count = 1
	day.is_mini_boss = true
	day.faction_id = "DEFAULT_MIXED"

	var faction: FactionData = FactionData.new()
	faction.faction_id = "TEST"
	faction.mini_boss_ids = ["audit5_territory_mini"]
	# Empty roster so this wave only spawns the mini-boss + BossData escorts (no N×6 roster grunts).
	faction.roster = []

	var boss_data: BossData = load(
		"res://resources/bossdata_audit5_territory_miniboss.tres"
	) as BossData
	wm.max_waves = 1
	wm.ensure_boss_registry_loaded()
	wm.boss_registry["audit5_territory_mini"] = boss_data
	wm.set_day_context(day, faction)
	wm.force_spawn_wave(1)

	var boss_count: int = 0
	var escort_grunt: int = 0
	for child: Node in wm._enemy_container.get_children():
		if child is BossBase:
			boss_count += 1
		elif child is EnemyBase:
			var eb: EnemyBase = child as EnemyBase
			var ed: EnemyData = eb.get_enemy_data()
			if ed != null and ed.enemy_type == Types.EnemyType.ORC_GRUNT:
				escort_grunt += 1

	assert_int(boss_count).is_equal(1)
	assert_int(escort_grunt).is_equal(1)
	wm.queue_free()


func _make_isolated_wave_manager() -> WaveManager:
	var enemy_container: Node3D = Node3D.new()
	var spawn_points: Node3D = Node3D.new()
	for i: int in range(10):
		var marker: Marker3D = Marker3D.new()
		marker.global_position = Vector3(float(i) * 4.0, 0.0, 0.0)
		spawn_points.add_child(marker)
	add_child(enemy_container)
	add_child(spawn_points)

	var wm: WaveManager = WaveManager.new()
	wm.wave_countdown_duration = 10.0
	wm.max_waves = 10
	wm.enemy_data_registry = _build_full_enemy_data()
	add_child(wm)
	wm._enemy_container = enemy_container
	wm._spawn_points = spawn_points
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
		d.wave_tags = ["INVASION"]
		d.tier = 1
		d.balance_status = "UNTESTED"
		registry.append(d)
	return registry
