# test_boss_base.gd
# GdUnit4: BossBase damage, death signals, and movement vs tower (Prompt 10).

class_name TestBossBase
extends GdUnitTestSuite

const BOSS_SCENE: PackedScene = preload("res://scenes/bosses/boss_base.tscn")


func test_boss_base_initializes_combat_stats_like_enemy_base() -> void:
	var boss: BossBase = BOSS_SCENE.instantiate() as BossBase
	add_child(boss)
	var data: BossData = BossData.new()
	data.boss_id = "stat_boss"
	data.display_name = "Stat Boss"
	data.max_hp = 99
	data.move_speed = 2.5
	data.damage = 7
	data.attack_range = 2.1
	data.attack_cooldown = 1.0
	data.gold_reward = 3
	data.boss_scene = BOSS_SCENE
	boss.initialize_boss_data(data)
	assert_int(boss.health_component.current_hp).is_equal(99)
	assert_float(boss.get_enemy_data().move_speed).is_equal(2.5)
	assert_that(boss is EnemyBase).is_true()
	boss.queue_free()


func test_boss_base_takes_damage_and_dies() -> void:
	var boss: BossBase = BOSS_SCENE.instantiate() as BossBase
	add_child(boss)
	var data: BossData = BossData.new()
	data.boss_id = "test_boss"
	data.display_name = "Test Boss"
	data.max_hp = 10
	data.damage = 1
	data.move_speed = 3.0
	data.attack_range = 2.0
	data.attack_cooldown = 1.0
	data.gold_reward = 1
	data.boss_scene = BOSS_SCENE

	var monitor := monitor_signals(SignalBus, false)
	boss.initialize_boss_data(data)
	boss.take_damage(20.0, Types.DamageType.PHYSICAL)
	await assert_signal(monitor).is_emitted("boss_killed", ["test_boss"])
	await get_tree().process_frame
	assert_bool(is_instance_valid(boss)).is_false()


func test_boss_base_has_navigation_agent_like_enemy_base() -> void:
	# SOURCE: NavigationAgent3D on CharacterBody3D enemies (Godot docs — Using NavigationAgents)
	var boss: BossBase = BOSS_SCENE.instantiate() as BossBase
	add_child(boss)
	var data: BossData = BossData.new()
	data.boss_id = "nav_boss"
	data.display_name = "Nav Boss"
	data.max_hp = 100
	data.move_speed = 3.0
	data.boss_scene = BOSS_SCENE
	boss.initialize_boss_data(data)
	var nav: NavigationAgent3D = boss.get_node("NavigationAgent3D") as NavigationAgent3D
	assert_object(nav).is_not_null()
	boss.queue_free()
