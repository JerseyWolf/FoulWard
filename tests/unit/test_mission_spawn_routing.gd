# GdUnit4 — MissionSpawnRouting queue + deterministic path picks.
extends GdUnitTestSuite


func test_build_spawn_queue_respects_explicit_path_id() -> void:
	var routing: MissionRoutingData = MissionRoutingData.new()
	var path_a: RoutePathData = RoutePathData.new()
	path_a.id = "north"
	path_a.lane_id = "L0"
	path_a.body_types_allowed = 1
	routing.paths = [path_a]

	var wave: WaveData = WaveData.new()
	wave.wave_number = 1
	var se: SpawnEntryData = SpawnEntryData.new()
	se.enemy_data = _orc_grunt_data()
	se.count = 1
	se.start_time_sec = 0.0
	se.interval_sec = 0.0
	se.path_id = "north"
	wave.spawn_entries = [se]

	var registry: Array[EnemyData] = [_orc_grunt_data()]
	var rows: Array = MissionSpawnRouting.build_spawn_queue(wave, routing, registry, 42)
	assert_int(rows.size()).is_equal(1)
	var r0: Variant = rows[0]
	assert_str(r0.path_id).is_equal("north")


func test_lane_pick_is_deterministic_with_seed() -> void:
	var routing: MissionRoutingData = MissionRoutingData.new()
	var p1: RoutePathData = RoutePathData.new()
	p1.id = "a"
	p1.lane_id = "L1"
	p1.body_types_allowed = 0
	var p2: RoutePathData = RoutePathData.new()
	p2.id = "b"
	p2.lane_id = "L1"
	p2.body_types_allowed = 0
	routing.paths = [p1, p2]
	var lane: LaneData = LaneData.new()
	lane.id = "L1"
	lane.allowed_path_ids = PackedStringArray(["a", "b"])
	routing.lanes = [lane]

	var wave: WaveData = WaveData.new()
	wave.wave_number = 1
	var se: SpawnEntryData = SpawnEntryData.new()
	se.enemy_data = _orc_grunt_data()
	se.count = 3
	se.start_time_sec = 0.0
	se.interval_sec = 0.0
	se.lane_id = "L1"
	wave.spawn_entries = [se]

	var registry: Array[EnemyData] = [_orc_grunt_data()]
	var a: Array = MissionSpawnRouting.build_spawn_queue(wave, routing, registry, 999)
	var b: Array = MissionSpawnRouting.build_spawn_queue(wave, routing, registry, 999)
	assert_int(a.size()).is_equal(3)
	for i: int in range(3):
		assert_str(a[i].path_id).is_equal(b[i].path_id)


func test_path_rejects_wrong_body_type() -> void:
	var routing: MissionRoutingData = MissionRoutingData.new()
	var path_fly: RoutePathData = RoutePathData.new()
	path_fly.id = "air"
	path_fly.lane_id = "L1"
	path_fly.body_types_allowed = 1 << int(Types.EnemyBodyType.FLYING)
	routing.paths = [path_fly]
	var lane: LaneData = LaneData.new()
	lane.id = "L1"
	lane.allowed_path_ids = PackedStringArray(["air"])
	routing.lanes = [lane]

	var wave: WaveData = WaveData.new()
	wave.wave_number = 1
	var se: SpawnEntryData = SpawnEntryData.new()
	se.enemy_data = _orc_grunt_data()
	se.count = 1
	se.start_time_sec = 0.0
	se.interval_sec = 0.0
	se.lane_id = "L1"
	wave.spawn_entries = [se]

	var registry: Array[EnemyData] = [_orc_grunt_data()]
	var rows: Array = MissionSpawnRouting.build_spawn_queue(wave, routing, registry, 1)
	assert_str(rows[0].path_id).is_equal("")


func test_validate_mission() -> void:
	var m: MissionData = MissionData.new()
	m.routing = MissionRoutingData.new()
	var p: RoutePathData = RoutePathData.new()
	p.id = "p1"
	p.lane_id = "lane1"
	m.routing.paths = [p]
	var l: LaneData = LaneData.new()
	l.id = "l1"
	l.allowed_path_ids = PackedStringArray(["p1"])
	m.routing.lanes = [l]
	var w: WaveData = WaveData.new()
	w.wave_number = 1
	w.spawn_entries = []
	m.waves = [w]
	assert_bool(MissionSpawnRouting.validate_mission(m)).is_true()


func _orc_grunt_data() -> EnemyData:
	var d: EnemyData = EnemyData.new()
	d.enemy_type = Types.EnemyType.ORC_GRUNT
	d.body_type = Types.EnemyBodyType.GROUND
	d.max_hp = 10
	d.damage = 1
	d.gold_reward = 1
	return d
