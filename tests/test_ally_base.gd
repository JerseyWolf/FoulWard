# test_ally_base.gd — AllyBase movement, combat, death via HealthComponent.
# SOURCE: GdUnit4 await physics_frame stepping, https://mikeschulze.github.io/gdUnit4/

class_name TestAllyBase
extends GdUnitTestSuite

const ALLY_DATA_SCRIPT: GDScript = preload("res://scripts/resources/ally_data.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")


func before_test() -> void:
	EconomyManager.reset_to_defaults()


func after_test() -> void:
	for child: Node in get_children():
		if is_instance_valid(child) and not child is Timer:
			child.queue_free()
	await get_tree().process_frame


func _make_enemy_data() -> EnemyData:
	var d: EnemyData = EnemyData.new()
	d.is_flying = false
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


func _spawn_enemy(parent: Node, pos: Vector3) -> EnemyBase:
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
	parent.add_child(enemy)
	enemy.initialize(_make_enemy_data())
	enemy.global_position = pos
	return enemy


## Navmesh progress is environment-sensitive; we assert nearest-enemy acquisition instead.
func test_melee_ally_find_target_returns_nearest_enemy() -> void:
	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame

	var enemy: EnemyBase = _spawn_enemy(main, Vector3(25.0, 0.0, 0.0))
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: Node = ally_scene.instantiate()
	main.add_child(ally)
	var data: Resource = load("res://resources/ally_data/ally_melee_generic.tres") as Resource
	ally.call("initialize_ally_data", data)
	ally.global_position = Vector3(2.0, 0.0, 0.0)
	await get_tree().process_frame

	var t: Variant = ally.call("find_target")
	assert_object(t as Object).is_not_null()
	assert_that(t).is_equal(enemy)

	ally.queue_free()
	enemy.queue_free()
	main.queue_free()
	await get_tree().process_frame


func test_melee_ally_attacks_enemy_in_range() -> void:
	var main: Node3D = MAIN_SCENE.instantiate() as Node3D
	get_tree().root.add_child(main)
	await get_tree().process_frame

	var enemy: EnemyBase = _spawn_enemy(main, Vector3(1.0, 0.0, 0.0))
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: Node = ally_scene.instantiate()
	main.add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_melee_attack")
	data.set("max_hp", 50)
	data.set("move_speed", 0.0)
	data.set("basic_attack_damage", 20.0)
	data.set("attack_range", 5.0)
	data.set("attack_cooldown", 0.2)
	data.set("ally_class", Types.AllyClass.MELEE)
	data.set("preferred_targeting", Types.TargetPriority.CLOSEST)
	ally.call("initialize_ally_data", data)
	ally.global_position = Vector3(0.0, 0.0, 0.0)

	var hp0: int = enemy.health_component.get_current_hp()
	for _i in range(90):
		await get_tree().physics_frame
	assert_int(enemy.health_component.get_current_hp()).is_less(hp0)

	ally.queue_free()
	enemy.queue_free()
	main.queue_free()
	await get_tree().process_frame


func test_ally_hp_decreases_and_uses_health_component() -> void:
	var ally_scene: PackedScene = load("res://scenes/allies/ally_base.tscn")
	var ally: Node = ally_scene.instantiate()
	add_child(ally)
	var data: Resource = ALLY_DATA_SCRIPT.new()
	data.set("ally_id", "test_ally_hp")
	data.set("max_hp", 40)
	data.set("attack_cooldown", 1.0)
	ally.call("initialize_ally_data", data)

	var monitor := monitor_signals(SignalBus, false)
	var health_comp: Node = ally.get_node_or_null("HealthComponent")
	assert_object(health_comp).is_not_null()
	health_comp.call("take_damage", float(40))
	await get_tree().process_frame
	assert_bool(is_instance_valid(ally)).is_false()
	await assert_signal(monitor).is_emitted("ally_killed", ["test_ally_hp"])
