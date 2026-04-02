## TODO: add before_test() isolation — see testing SKILL
# GdUnit4 — Summoner tower runtime (AllyManager squads, BuildingData paths).
class_name TestSummonerRuntime
extends GdUnitTestSuite


func test_spawn_squad_creates_correct_count() -> void:
	var bd: BuildingData = load("res://resources/building_data/wolfden.tres") as BuildingData
	assert_bool(bd.is_summoner).is_true()
	assert_int(bd.summon_squad_size).is_equal(2)
	var scene: PackedScene = load("res://scenes/buildings/building_base.tscn") as PackedScene
	var building: BuildingBase = scene.instantiate() as BuildingBase
	add_child(building)
	# Headless-safe: avoid full initialize() (EnchantmentManager / stat pipeline).
	building._building_data = bd
	building.placed_instance_id = "test_wolf_001"
	building.global_position = Vector3.ZERO
	AllyManager.spawn_squad(building)
	assert_bool(AllyManager._squads.has("test_wolf_001")).is_true()
	var squad: Array = AllyManager._squads["test_wolf_001"] as Array
	assert_int(squad.size()).is_equal(2)
	AllyManager.despawn_squad("test_wolf_001")
	building._building_data = null
	building.placed_instance_id = ""
	building.queue_free()


func test_respawn_type_mortal_only_fires_once() -> void:
	var bd: BuildingData = load("res://resources/building_data/wolfden.tres") as BuildingData
	assert_str(bd.summon_respawn_type).is_equal("mortal")


func test_barracks_fortress_recurring() -> void:
	var bd: BuildingData = load("res://resources/building_data/barracks_fortress.tres") as BuildingData
	assert_str(bd.summon_respawn_type).is_equal("recurring")


func test_all_summoner_buildings_have_valid_paths() -> void:
	var dir := DirAccess.open("res://resources/building_data/")
	assert_object(dir).is_not_null()
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not fname.begins_with(".") and fname.ends_with(".tres"):
			var res: Resource = load("res://resources/building_data/" + fname)
			var bd: BuildingData = res as BuildingData
			if bd != null and bd.is_summoner:
				if bd.summon_leader_data != null:
					continue
				var leader_path: String = bd.summon_leader_data_path.strip_edges()
				assert_bool(not leader_path.is_empty()).is_true()
				assert_bool(ResourceLoader.exists(leader_path)).is_true()
		fname = dir.get_next()
	dir.list_dir_end()
