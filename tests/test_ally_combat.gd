## TODO: add before_test() isolation — see testing SKILL
# test_ally_combat.gd — Downed/recovery, flying skip, preferred targeting (GdUnit4).
class_name TestAllyCombat
extends GdUnitTestSuite

const ALLY_DATA_SCRIPT: GDScript = preload("res://scripts/resources/ally_data.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func _make_enemy_data(p_is_flying: bool) -> EnemyData:
	var d: EnemyData = EnemyData.new()
	d.is_flying = p_is_flying
	d.max_hp = 200
	d.move_speed = 0.0
	d.damage = 5
	d.attack_range = 1.5
	d.attack_cooldown = 1.0
	d.armor_type = Types.ArmorType.UNARMORED
	d.gold_reward = 5
	d.enemy_type = Types.EnemyType.ORC_GRUNT
	d.damage_immunities = []
	return d


func _spawn_enemy(parent: Node, pos: Vector3, p_is_flying: bool) -> EnemyBase:
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	parent.add_child(enemy)
	enemy.initialize(_make_enemy_data(p_is_flying))
	enemy.global_position = pos
	return enemy


func test_downed_ally_recovers_after_recovery_time() -> void:
	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame

	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: AllyBase = ally_scene.instantiate() as AllyBase
	main.add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_downed_recover")
	data.set("max_hp", 40)
	data.set("uses_downed_recovering", true)
	data.set("recovery_time", 0.12)
	data.set("attack_cooldown", 1.0)
	ally.initialize_ally_data(data)
	ally.global_position = Vector3(1.0, 0.0, 0.0)

	var monitor := monitor_signals(SignalBus, false)
	ally.health_component.take_damage(float(40))
	await get_tree().process_frame

	assert_signal(monitor).is_emitted("ally_downed", ["test_downed_recover"])
	assert_int(ally.get_current_state()).is_equal(AllyBase.AllyState.DOWNED)

	for _i in range(80):
		await get_tree().physics_frame

	assert_signal(monitor).is_emitted("ally_recovered", ["test_downed_recover"])
	assert_int(ally.get_current_hp()).is_equal(40)
	assert_int(ally.get_current_state()).is_equal(AllyBase.AllyState.IDLE)

	ally.queue_free()
	main.queue_free()
	await get_tree().process_frame


func test_ally_does_not_target_flying_when_flag_false() -> void:
	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame

	var flying: EnemyBase = _spawn_enemy(main, Vector3(3.0, 0.0, 0.0), true)
	var ground: EnemyBase = _spawn_enemy(main, Vector3(10.0, 0.0, 0.0), false)

	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: AllyBase = ally_scene.instantiate() as AllyBase
	main.add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_no_fly_target")
	data.set("max_hp", 50)
	data.set("can_target_flying", false)
	data.set("preferred_targeting", Types.TargetPriority.CLOSEST)
	data.set("attack_cooldown", 1.0)
	ally.initialize_ally_data(data)
	ally.global_position = Vector3.ZERO
	await get_tree().process_frame

	var t: Variant = ally.find_target()
	assert_object(t as Object).is_not_null()
	assert_that(t).is_equal(ground)

	ally.queue_free()
	flying.queue_free()
	ground.queue_free()
	main.queue_free()
	await get_tree().process_frame


func test_ally_targets_lowest_hp_when_preferred_targeting_set() -> void:
	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame

	var high_hp: EnemyBase = _spawn_enemy(main, Vector3(5.0, 0.0, 0.0), false)
	var low_hp: EnemyBase = _spawn_enemy(main, Vector3(5.0, 0.0, 2.0), false)
	low_hp.health_component.take_damage(150.0)

	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: AllyBase = ally_scene.instantiate() as AllyBase
	main.add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_lowest_hp")
	data.set("max_hp", 50)
	data.set("preferred_targeting", Types.TargetPriority.LOWEST_HP)
	data.set("attack_cooldown", 1.0)
	ally.initialize_ally_data(data)
	ally.global_position = Vector3.ZERO
	await get_tree().process_frame

	var t: Variant = ally.find_target()
	assert_object(t as Object).is_not_null()
	assert_that(t).is_equal(low_hp)

	ally.queue_free()
	high_hp.queue_free()
	low_hp.queue_free()
	main.queue_free()
	await get_tree().process_frame


func test_ranged_ally_applies_damage_headless() -> void:
	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame
	var pc: Node = main.get_node_or_null("ProjectileContainer")
	assert_object(pc).is_not_null()
	pc.queue_free()
	await get_tree().process_frame

	var enemy: EnemyBase = _spawn_enemy(main, Vector3(4.0, 0.0, 0.0), false)
	var hp_before: int = enemy.health_component.get_current_hp()

	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: AllyBase = ally_scene.instantiate() as AllyBase
	main.add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_ranged_headless")
	data.set("max_hp", 50)
	data.set("base_hp", 50)
	data.set("base_damage", 10)
	data.set("ally_base_damage", 15)
	data.set("is_ranged", true)
	data.set("attack_range", 8.0)
	data.set("attack_cooldown", 0.05)
	data.set("move_speed", 0.0)
	ally.initialize_ally_data(data)
	ally.global_position = Vector3.ZERO
	await get_tree().process_frame

	for _i in range(120):
		await get_tree().physics_frame

	if is_instance_valid(enemy):
		assert_int(enemy.health_component.get_current_hp()).is_less(hp_before)
	else:
		assert_bool(hp_before > 0).is_true()

	if is_instance_valid(ally):
		ally.queue_free()
	if is_instance_valid(enemy):
		enemy.queue_free()
	main.queue_free()
	await get_tree().process_frame


func test_ally_level_scaling_damage_increases_with_level() -> void:
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: AllyBase = ally_scene.instantiate() as AllyBase
	get_tree().root.add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_level_scale")
	data.set("max_hp", 50)
	data.set("base_damage", 10)
	data.set("level_scaling_factor", 1.0)
	data.set("starting_level", 1)
	ally.initialize_ally_data(data)
	assert_int(ally.get_effective_damage()).is_equal(10)
	ally.current_level = 3
	assert_int(ally.get_effective_damage()).is_equal(30)
	ally.queue_free()
	await get_tree().process_frame


func test_ally_starting_level_applied_on_ready() -> void:
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: AllyBase = ally_scene.instantiate() as AllyBase
	get_tree().root.add_child(ally)
	await get_tree().process_frame
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_start_level")
	data.set("max_hp", 80)
	data.set("base_hp", 40)
	data.set("base_damage", 10)
	data.set("level_scaling_factor", 0.5)
	data.set("starting_level", 4)
	ally.initialize_ally_data(data)
	assert_int(ally.current_level).is_equal(4)
	var expected_hp: int = 40 + int(floor(40.0 * 0.5 * 3.0))
	assert_int(ally.health_component.max_hp).is_equal(expected_hp)
	ally.queue_free()
	await get_tree().process_frame
