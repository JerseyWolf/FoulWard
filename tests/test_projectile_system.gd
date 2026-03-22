## test_projectile_system.gd
## GdUnit4 tests for ProjectileBase initialization, travel, collision, and damage application.

# Credit (test names / semantics):
#   FOUL WARD SYSTEMS_part2.md §6.7 GdUnit4 Test Specifications — Projectile system.

class_name TestProjectileSystem
extends GdUnitTestSuite

const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")

func _create_enemy_at(pos: Vector3, armor: Types.ArmorType = Types.ArmorType.UNARMORED) -> EnemyBase:
	var data := EnemyData.new()
	data.max_hp = 100
	data.armor_type = armor
	data.damage_immunities = []
	data.move_speed = 0.0
	data.attack_range = 1.5
	data.attack_cooldown = 1.0
	data.damage = 5
	data.gold_reward = 5
	data.enemy_type = Types.EnemyType.ORC_GRUNT
	var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
	add_child(enemy)
	enemy.global_position = pos
	enemy.initialize(data)
	return enemy

func _create_projectile() -> ProjectileBase:
	var proj: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	add_child(proj)
	return proj

# --- initialize_from_weapon ----------------------------------------

func test_initialize_from_weapon_sets_correct_damage() -> void:
	var weapon := WeaponData.new()
	weapon.damage = 50.0
	weapon.projectile_speed = 30.0
	weapon.burst_count = 1
	weapon.burst_interval = 0.0

	var proj := _create_projectile()
	proj.initialize_from_weapon(weapon, Vector3.ZERO, Vector3(10, 0, 0))
	assert_float(proj._damage).is_equal_approx(50.0, 0.001)
	proj.queue_free()

func test_initialize_from_weapon_sets_correct_speed() -> void:
	var weapon := WeaponData.new()
	weapon.damage = 10.0
	weapon.projectile_speed = 42.0
	weapon.burst_count = 1
	weapon.burst_interval = 0.0

	var proj := _create_projectile()
	proj.initialize_from_weapon(weapon, Vector3.ZERO, Vector3(5, 0, 0))
	assert_float(proj._speed).is_equal_approx(42.0, 0.001)
	proj.queue_free()

func test_initialize_from_weapon_computes_direction() -> void:
	var weapon := WeaponData.new()
	weapon.damage = 10.0
	weapon.projectile_speed = 20.0
	weapon.burst_count = 1
	weapon.burst_interval = 0.0

	var proj := _create_projectile()
	proj.initialize_from_weapon(weapon, Vector3.ZERO, Vector3(10, 0, 0))
	assert_vector(proj._direction).is_equal_approx(
		Vector3(1, 0, 0), Vector3(0.001, 0.001, 0.001)
	)
	proj.queue_free()

# --- initialize_from_building --------------------------------------

func test_initialize_from_building_sets_damage_type() -> void:
	var proj := _create_projectile()
	proj.initialize_from_building(
		20.0,
		Types.DamageType.FIRE,
		25.0,
		Vector3.ZERO,
		Vector3(0, 0, 5),
		false
	)
	assert_int(int(proj._damage_type)).is_equal(int(Types.DamageType.FIRE))
	proj.queue_free()

# --- travel / miss / lifetime --------------------------------------

func test_projectile_freed_on_miss() -> void:
	var proj := _create_projectile()
	proj.initialize_from_building(
		10.0,
		Types.DamageType.PHYSICAL,
		5.0,
		Vector3.ZERO,
		Vector3(1, 0, 0),
		false
	)
	for i in range(200):
		proj._physics_process(0.016)
	await await_idle_frame()
	assert_bool(is_instance_valid(proj)).is_false()

func test_projectile_freed_on_lifetime_exceeded() -> void:
	var proj := _create_projectile()
	proj.initialize_from_building(
		0.0,
		Types.DamageType.PHYSICAL,
		0.1,
		Vector3.ZERO,
		Vector3(1000, 0, 0),
		false
	)
	for i in range(400):
		proj._physics_process(0.016)
	await await_idle_frame()
	assert_bool(is_instance_valid(proj)).is_false()

# --- collision + damage matrix ------------------------------------

func test_projectile_skips_dead_enemy() -> void:
	var enemy := _create_enemy_at(Vector3(2, 0, 0))
	# Kill enemy before projectile hits.
	enemy.health_component.take_damage(9999.0)

	var proj := _create_projectile()
	proj.initialize_from_building(
		50.0,
		Types.DamageType.PHYSICAL,
		20.0,
		Vector3.ZERO,
		enemy.global_position,
		false
	)
	for i in range(60):
		proj._physics_process(0.016)

	await await_idle_frame()
	# Should not crash — test passes if we reach this line without error.
	assert_bool(true).is_true()

func test_projectile_respects_fire_immunity() -> void:
	var enemy := _create_enemy_at(Vector3(2, 0, 0))
	# Override immunity on the data copy.
	enemy.get_enemy_data().damage_immunities = [Types.DamageType.FIRE]

	var proj := _create_projectile()
	proj.initialize_from_building(
		50.0,
		Types.DamageType.FIRE,
		20.0,
		Vector3.ZERO,
		enemy.global_position,
		false
	)
	for i in range(60):
		proj._physics_process(0.016)

	assert_int(enemy.health_component.current_hp).is_equal(100)
	enemy.queue_free()

func test_projectile_deals_double_damage_magical_vs_heavy_armor() -> void:
	var enemy := _create_enemy_at(Vector3(2, 0, 0), Types.ArmorType.HEAVY_ARMOR)

	var proj := _create_projectile()
	proj.initialize_from_building(
		30.0,
		Types.DamageType.MAGICAL,
		20.0,
		Vector3.ZERO,
		enemy.global_position,
		false
	)
	for i in range(60):
		proj._physics_process(0.016)

	# DAMAGE_MATRIX: MAGICAL vs HEAVY_ARMOR = 2.0 → 60 damage → 40 hp remaining.
	assert_int(enemy.health_component.current_hp).is_equal(40)
	enemy.queue_free()

