# test_faction_data.gd
# GdUnit4: FactionData .tres integrity and campaign day → faction validation.

class_name TestFactionData
extends GdUnitTestSuite


func before_test() -> void:
	EconomyManager.reset_to_defaults()


func test_faction_data_roster_enemy_types_are_valid() -> void:
	var faction_paths: Array[String] = [
		"res://resources/faction_data_default_mixed.tres",
		"res://resources/faction_data_orc_raiders.tres",
		"res://resources/faction_data_plague_cult.tres",
	]

	for path: String in faction_paths:
		var faction: FactionData = load(path) as FactionData
		assert_that(faction).is_not_null()
		for entry: FactionRosterEntry in faction.roster:
			var data: EnemyData = _find_enemy_data_for_type(entry.enemy_type)
			assert_that(data).is_not_null()


func test_campaign_manager_validate_day_configs_accepts_short_campaign() -> void:
	var cfg: CampaignConfig = load("res://resources/campaigns/campaign_short_5_days.tres") as CampaignConfig
	assert_that(cfg).is_not_null()
	CampaignManager.validate_day_configs(cfg.day_configs)


func _find_enemy_data_for_type(enemy_type: Types.EnemyType) -> EnemyData:
	var paths: Array[String] = [
		"res://resources/enemy_data/orc_grunt.tres",
		"res://resources/enemy_data/orc_brute.tres",
		"res://resources/enemy_data/goblin_firebug.tres",
		"res://resources/enemy_data/plague_zombie.tres",
		"res://resources/enemy_data/orc_archer.tres",
		"res://resources/enemy_data/bat_swarm.tres",
	]
	for path: String in paths:
		var data: EnemyData = load(path) as EnemyData
		if data != null and data.enemy_type == enemy_type:
			return data
	return null


func test_empty_faction_roster_configures_without_crash() -> void:
	var wm: WaveManager = WaveManager.new()
	var enemy_container: Node3D = Node3D.new()
	var spawn_points: Node3D = Node3D.new()
	for i: int in range(4):
		var marker: Marker3D = Marker3D.new()
		marker.global_position = Vector3(float(i) * 4.0, 0.0, 0.0)
		spawn_points.add_child(marker)
	add_child(enemy_container)
	add_child(spawn_points)
	wm.wave_countdown_duration = 5.0
	wm.max_waves = 3
	wm.enemy_data_registry = _audit5_full_enemy_data()
	add_child(wm)
	wm._enemy_container = enemy_container
	wm._spawn_points = spawn_points

	var faction: FactionData = FactionData.new()
	faction.faction_id = "EMPTY_ROSTER_AUDIT5"
	faction.roster = []

	var day: DayConfig = DayConfig.new()
	day.day_index = 1
	day.base_wave_count = 3
	day.faction_id = "EMPTY_ROSTER_AUDIT5"
	wm.set_day_context(day, faction)
	wm.force_spawn_wave(1)
	await get_tree().process_frame
	assert_int(enemy_container.get_child_count()).is_equal(0)
	wm.queue_free()
	enemy_container.queue_free()
	spawn_points.queue_free()


func _audit5_full_enemy_data() -> Array[EnemyData]:
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
