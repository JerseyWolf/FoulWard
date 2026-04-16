# GdUnit4 — EnemyBase.receive_damage mitigation + shield + DoT (Prompt 49).
extends GdUnitTestSuite

const _EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")


func before_test() -> void:
	EconomyManager.reset_to_defaults()


func after_test() -> void:
	for child: Node in get_children():
		if is_instance_valid(child) and not child is Timer:
			child.queue_free()
	await get_tree().process_frame


func test_physical_mitigation_positive_armor() -> void:
	var e: EnemyBase = _EnemyScene.instantiate() as EnemyBase
	add_child(e)
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.max_hp = 200
	ed.armor_flat = 100.0
	ed.armor_type = Types.ArmorType.UNARMORED
	e.initialize(ed)
	var r: Dictionary = e.receive_damage({
		"raw_damage": 100.0,
		"damage_type": Types.DamageType.PHYSICAL,
		"is_dot": false,
	})
	assert_float(float(r.get("post_mitigation_damage", 0.0))).is_equal(50.0)


func test_physical_mitigation_negative_armor() -> void:
	var e: EnemyBase = _EnemyScene.instantiate() as EnemyBase
	add_child(e)
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.max_hp = 500
	ed.armor_flat = -50.0
	ed.armor_type = Types.ArmorType.UNARMORED
	e.initialize(ed)
	var r: Dictionary = e.receive_damage({
		"raw_damage": 100.0,
		"damage_type": Types.DamageType.PHYSICAL,
		"is_dot": false,
	})
	assert_float(float(r.get("post_mitigation_damage", 0.0))).is_equal(150.0)


func test_true_damage_bypasses_armor_flat() -> void:
	var e: EnemyBase = _EnemyScene.instantiate() as EnemyBase
	add_child(e)
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.max_hp = 200
	ed.armor_flat = 1000.0
	ed.armor_type = Types.ArmorType.HEAVY_ARMOR
	e.initialize(ed)
	var r: Dictionary = e.receive_damage({
		"raw_damage": 50.0,
		"damage_type": Types.DamageType.TRUE,
		"is_dot": false,
	})
	assert_float(float(r.get("hp_damage", 0.0))).is_equal(50.0)


func test_shield_absorbs_first() -> void:
	var e: EnemyBase = _EnemyScene.instantiate() as EnemyBase
	add_child(e)
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.max_hp = 200
	ed.armor_type = Types.ArmorType.UNARMORED
	ed.special_tags = ["shield"]
	ed.special_values = {"shield": {"shield_hp": 30}}
	e.initialize(ed)
	var r: Dictionary = e.receive_damage({
		"raw_damage": 100.0,
		"damage_type": Types.DamageType.TRUE,
		"is_dot": false,
	})
	assert_float(float(r.get("shield_absorbed", 0.0))).is_equal(30.0)
	assert_float(float(r.get("hp_damage", 0.0))).is_equal(70.0)


func test_dot_floor_is_zero_fraction() -> void:
	var e: EnemyBase = _EnemyScene.instantiate() as EnemyBase
	add_child(e)
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.max_hp = 200
	ed.armor_flat = 0.0
	ed.armor_type = Types.ArmorType.UNARMORED
	e.initialize(ed)
	var r: Dictionary = e.receive_damage({
		"raw_damage": 0.5,
		"damage_type": Types.DamageType.PHYSICAL,
		"is_dot": true,
	})
	assert_float(float(r.get("hp_damage", 0.0))).is_equal(0.5)


func test_take_damage_wrapper_compatible() -> void:
	var e: EnemyBase = _EnemyScene.instantiate() as EnemyBase
	add_child(e)
	var ed: EnemyData = EnemyData.new()
	ed.enemy_type = Types.EnemyType.ORC_GRUNT
	ed.max_hp = 200
	ed.armor_type = Types.ArmorType.UNARMORED
	e.initialize(ed)
	var hp0: int = e.health_component.current_hp
	e.take_damage(50.0, Types.DamageType.PHYSICAL)
	assert_int(hp0 - e.health_component.current_hp).is_equal(50)


func test_build_phase_guard_blocks_placement() -> void:
	var prev: bool = BuildPhaseManager.is_build_phase
	BuildPhaseManager.is_build_phase = false
	var hg: HexGrid = load("res://scenes/hex_grid/hex_grid.tscn").instantiate() as HexGrid
	add_child(hg)
	# Scene may warn if registry not configured — we only need the guard to return false early.
	var ok: bool = hg.place_building(0, Types.BuildingType.ARROW_TOWER)
	assert_bool(ok).is_false()
	BuildPhaseManager.is_build_phase = prev
