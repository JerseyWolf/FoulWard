# test_faction_data.gd
# GdUnit4: FactionData .tres integrity and campaign day → faction validation.

class_name TestFactionData
extends GdUnitTestSuite


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
