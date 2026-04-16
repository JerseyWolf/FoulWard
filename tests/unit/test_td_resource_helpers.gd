# GdUnit4 — TD data resource helpers (identity, range alias, spawn/routing validation).
extends GdUnitTestSuite


func test_building_data_get_range_matches_attack_range() -> void:
	var bd: BuildingData = BuildingData.new()
	bd.building_type = Types.BuildingType.ARROW_TOWER
	bd.attack_range = 12.5
	assert_float(bd.get_range()).is_equal(12.5)


func test_ally_get_range_matches_attack_range() -> void:
	var ad: AllyData = AllyData.new()
	ad.attack_range = 7.25
	assert_float(ad.get_range()).is_equal(7.25)


func test_ally_get_identity_prefers_identity_field() -> void:
	var ad: AllyData = AllyData.new()
	ad.ally_id = "foo"
	ad.identity = "bar"
	assert_str(ad.get_identity()).is_equal("bar")


func test_ally_get_identity_falls_back_to_ally_id() -> void:
	var ad: AllyData = AllyData.new()
	ad.ally_id = "foo"
	assert_str(ad.get_identity()).is_equal("foo")


func test_ally_get_identity_prefers_id_field() -> void:
	var ad: AllyData = AllyData.new()
	ad.id = "catalog_x"
	ad.ally_id = "foo"
	ad.identity = "bar"
	assert_str(ad.get_identity()).is_equal("catalog_x")


func test_enemy_get_identity_prefers_id() -> void:
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.id = "orc_custom"
	assert_str(ed.get_identity()).is_equal("orc_custom")


func test_enemy_get_identity_falls_back_to_enum_name() -> void:
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.id = ""
	assert_that(ed.get_identity()).is_not_empty()


func test_enemy_matches_tower_filter_uses_body_type_when_is_flying_mismatched() -> void:
	var air_only: EnemyData = EnemyData.new()
	air_only.enemy_type = Types.EnemyType.BAT_SWARM
	air_only.body_type = Types.EnemyBodyType.FLYING
	air_only.is_flying = false
	assert_bool(air_only.matches_tower_air_ground_filter(true, false)).is_true()
	assert_bool(air_only.matches_tower_air_ground_filter(false, true)).is_false()


func test_enemy_matches_tower_filter_bat_default_data() -> void:
	var bat: EnemyData = load("res://resources/enemy_data/bat_swarm.tres") as EnemyData
	assert_object(bat).is_not_null()
	assert_bool(bat.matches_tower_air_ground_filter(true, false)).is_true()
	assert_bool(bat.matches_tower_air_ground_filter(false, true)).is_false()


func test_enemy_matches_tower_filter_ground_grunt() -> void:
	var orc: EnemyData = load("res://resources/enemy_data/orc_grunt.tres") as EnemyData
	assert_object(orc).is_not_null()
	assert_bool(orc.matches_tower_air_ground_filter(true, false)).is_false()
	assert_bool(orc.matches_tower_air_ground_filter(false, true)).is_true()


func test_spawn_entry_enemy_id_without_enemy_data_is_valid_for_authoring() -> void:
	var se: SpawnEntryData = SpawnEntryData.new()
	se.enemy_id = "catalog_orc"
	se.count = 1
	var w: PackedStringArray = se.collect_validation_warnings()
	assert_int(w.size()).is_equal(0)


func test_mission_routing_warns_when_path_lane_missing() -> void:
	var mr: MissionRoutingData = MissionRoutingData.new()
	mr.mission_id = "m1"
	var lane: LaneData = LaneData.new()
	lane.id = "L1"
	mr.lanes = [lane]
	var p: RoutePathData = RoutePathData.new()
	p.id = "P1"
	p.lane_id = "missing_lane"
	p.curve3d_path = NodePath("res://dummy.tres")
	mr.paths = [p]
	var warnings: PackedStringArray = mr.collect_validation_warnings()
	var found: bool = false
	var i: int = 0
	while i < warnings.size():
		if str(warnings[i]).find("not found in lanes") != -1:
			found = true
			break
		i += 1
	assert_bool(found).is_true()
