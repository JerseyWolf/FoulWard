## test_enemy_pathfinding.gd
## GdUnit4 tests for EnemyBase initialization, damage application, and basic path/attack behavior.

# Credit (test names and behaviors):
#   FOUL WARD SYSTEMS_part3.md §8.8 GdUnit4 Test Specifications for EnemyBase.

class_name TestEnemyPathfinding
extends GdUnitTestSuite

const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")

func _create_enemy(data: EnemyData) -> EnemyBase:
	var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
	add_child(enemy)
	enemy.initialize(data)
	return enemy

# --- initialize -----------------------------------------------------

func test_initialize_sets_stats_from_enemy_data() -> void:
	var data := EnemyData.new()
	data.max_hp = 123
	data.display_name = "Test Enemy"
	data.color = Color(0.2, 0.3, 0.4)
	var enemy := _create_enemy(data)

	assert_int(enemy.health_component.max_hp).is_equal(123)
	assert_str(enemy.get_enemy_data().display_name).is_equal("Test Enemy")
	enemy.queue_free()

# --- damage + matrix + immunities ----------------------------------

func test_take_damage_physical_vs_unarmored_full_damage() -> void:
	var data := EnemyData.new()
	data.max_hp = 100
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = []
	var enemy := _create_enemy(data)

	enemy.take_damage(50.0, Types.DamageType.PHYSICAL)
	assert_int(enemy.health_component.current_hp).is_equal(50)
	enemy.queue_free()

func test_take_damage_physical_vs_heavy_armor_half_damage() -> void:
	var data := EnemyData.new()
	data.max_hp = 100
	data.armor_type = Types.ArmorType.HEAVY_ARMOR
	data.damage_immunities = []
	var enemy := _create_enemy(data)

	enemy.take_damage(50.0, Types.DamageType.PHYSICAL)
	# 50 * 0.5 = 25 damage -> 75 hp remaining
	assert_int(enemy.health_component.current_hp).is_equal(75)
	enemy.queue_free()

func test_take_damage_fire_immunity_goblin_no_damage() -> void:
	var data := EnemyData.new()
	data.max_hp = 60
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = [Types.DamageType.FIRE]
	var enemy := _create_enemy(data)

	enemy.take_damage(999.0, Types.DamageType.FIRE)
	assert_int(enemy.health_component.current_hp).is_equal(60)
	enemy.queue_free()

func test_take_damage_poison_immunity_zombie_no_damage() -> void:
	var data := EnemyData.new()
	data.max_hp = 120
	data.armor_type = Types.ArmorType.UNDEAD
	data.damage_immunities = [Types.DamageType.POISON]
	var enemy := _create_enemy(data)

	enemy.take_damage(999.0, Types.DamageType.POISON)
	assert_int(enemy.health_component.current_hp).is_equal(120)
	enemy.queue_free()

func test_take_damage_triggers_health_depleted_at_zero() -> void:
	var data := EnemyData.new()
	data.max_hp = 50
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = []
	var enemy := _create_enemy(data)

	var monitor := monitor_signals(enemy.health_component, false)
	enemy.take_damage(50.0, Types.DamageType.PHYSICAL)
	await get_tree().process_frame
	await assert_signal(monitor).is_emitted("health_depleted")

# --- on_health_depleted effects ------------------------------------

func test_on_health_depleted_emits_enemy_killed_signal() -> void:
	var data := EnemyData.new()
	data.enemy_type = Types.EnemyType.ORC_GRUNT
	data.max_hp = 10
	data.gold_reward = 10
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = []
	var enemy := _create_enemy(data)

	var monitor := monitor_signals(SignalBus, false)
	enemy.take_damage(999.0, Types.DamageType.PHYSICAL)
	await assert_signal(monitor).is_emitted(
		"enemy_killed", [Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10]
	)

func test_on_health_depleted_removes_from_enemies_group() -> void:
	var data := EnemyData.new()
	data.max_hp = 10
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = []
	var enemy := _create_enemy(data)

	assert_bool(enemy.is_in_group("enemies")).is_true()
	enemy.take_damage(999.0, Types.DamageType.PHYSICAL)
	await await_idle_frame()
	assert_bool(enemy.is_in_group("enemies")).is_false()

func test_on_health_depleted_calls_queue_free() -> void:
	var data := EnemyData.new()
	data.max_hp = 10
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = []
	var enemy := _create_enemy(data)

	enemy.take_damage(999.0, Types.DamageType.PHYSICAL)
	await await_idle_frame()
	assert_bool(is_instance_valid(enemy)).is_false()

