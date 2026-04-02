## TODO: add before_test() isolation — see testing SKILL
class_name TestEnemyDotSystem
extends GdUnitTestSuite

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")

func _spawn_enemy(data: EnemyData) -> EnemyBase:
	var enemy: EnemyBase = ENEMY_SCENE.instantiate() as EnemyBase
	add_child(enemy)
	enemy.initialize(data)
	return enemy


func _make_unarmored_enemy_data() -> EnemyData:
	var data: EnemyData = EnemyData.new()
	data.max_hp = 500
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = []
	data.enemy_type = Types.EnemyType.ORC_GRUNT
	data.gold_reward = 0
	return data


func _load_plague_zombie_data() -> EnemyData:
	return load("res://resources/enemy_data/plague_zombie.tres") as EnemyData


func test_dot_reduces_enemy_hp_over_time() -> void:
	var enemy: EnemyBase = _spawn_enemy(_make_unarmored_enemy_data())
	var max_hp: int = enemy.health_component.max_hp
	var effect: Dictionary = {
		"effect_type": "burn",
		"damage_type": Types.DamageType.FIRE,
		"dot_total_damage": 100.0,
		"tick_interval": 1.0,
		"duration": 5.0,
		"remaining_time": 5.0,
		"time_since_last_tick": 0.0,
		"source_id": "test_burn",
	}
	enemy.apply_dot_effect(effect)

	for _i: int in range(5):
		enemy._physics_process(1.0)

	var current_hp: int = enemy.health_component.current_hp
	assert_float(float(max_hp - current_hp)).is_equal_approx(100.0, 1.0)


func test_dot_on_immune_enemy_does_not_change_hp() -> void:
	var enemy: EnemyBase = _spawn_enemy(_load_plague_zombie_data())
	var max_hp: int = enemy.health_component.max_hp
	var effect: Dictionary = {
		"effect_type": "poison",
		"damage_type": Types.DamageType.POISON,
		"dot_total_damage": 100.0,
		"tick_interval": 1.0,
		"duration": 5.0,
		"remaining_time": 5.0,
		"time_since_last_tick": 0.0,
		"source_id": "test_poison",
	}
	enemy.apply_dot_effect(effect)

	for _i: int in range(5):
		enemy._physics_process(1.0)

	assert_int(enemy.health_component.current_hp).is_equal(max_hp)


func test_burn_reapplication_refreshes_and_keeps_max_total_damage() -> void:
	var enemy: EnemyBase = _spawn_enemy(_make_unarmored_enemy_data())
	enemy.apply_dot_effect({
		"effect_type": "burn",
		"damage_type": Types.DamageType.FIRE,
		"dot_total_damage": 30.0,
		"tick_interval": 1.0,
		"duration": 3.0,
		"source_id": "fire_brazier",
	})
	enemy.apply_dot_effect({
		"effect_type": "burn",
		"damage_type": Types.DamageType.FIRE,
		"dot_total_damage": 50.0,
		"tick_interval": 1.0,
		"duration": 4.0,
		"source_id": "fire_brazier",
	})

	assert_int(enemy.active_status_effects.size()).is_equal(1)
	var burn: Dictionary = enemy.active_status_effects[0]
	assert_float(float(burn.get("remaining_time", 0.0))).is_equal_approx(4.0, 0.001)
	assert_float(float(burn.get("dot_total_damage", 0.0))).is_equal_approx(50.0, 0.001)


func test_poison_stacking_respects_cap_and_increases_damage() -> void:
	var enemy_single: EnemyBase = _spawn_enemy(_make_unarmored_enemy_data())
	enemy_single.apply_dot_effect({
		"effect_type": "poison",
		"damage_type": Types.DamageType.POISON,
		"dot_total_damage": 50.0,
		"tick_interval": 1.0,
		"duration": 5.0,
		"source_id": "single_stack",
	})
	for _i: int in range(3):
		enemy_single._physics_process(1.0)
	var single_loss: int = enemy_single.health_component.max_hp - enemy_single.health_component.current_hp

	var enemy_stacked: EnemyBase = _spawn_enemy(_make_unarmored_enemy_data())
	for i: int in range(7):
		enemy_stacked.apply_dot_effect({
			"effect_type": "poison",
			"damage_type": Types.DamageType.POISON,
			"dot_total_damage": 50.0,
			"tick_interval": 1.0,
			"duration": 5.0,
			"source_id": "poison_stack_%d" % i,
		})
	assert_int(enemy_stacked.active_status_effects.size()).is_equal(enemy_stacked.MAX_POISON_STACKS)
	for _j: int in range(3):
		enemy_stacked._physics_process(1.0)
	var stacked_loss: int = enemy_stacked.health_component.max_hp - enemy_stacked.health_component.current_hp
	assert_int(stacked_loss).is_greater(single_loss)
