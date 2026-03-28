## Deterministic tests for pierce, multi-shot fan, spread, and splash (Audit 6 §1.2).
class_name TestWeaponStructural
extends GdUnitTestSuite

const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")
const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")


func _enemy_at(pos: Vector3) -> EnemyBase:
	var data := EnemyData.new()
	data.max_hp = 200
	data.armor_type = Types.ArmorType.UNARMORED
	data.damage_immunities = []
	data.move_speed = 0.0
	data.attack_range = 1.5
	data.attack_cooldown = 1.0
	data.damage = 5
	data.gold_reward = 5
	data.enemy_type = Types.EnemyType.ORC_GRUNT
	data.is_flying = false
	var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
	add_child(enemy)
	enemy.global_position = pos
	enemy.initialize(data)
	return enemy


func test_pierce_hits_second_enemy_in_line() -> void:
	var e1: EnemyBase = _enemy_at(Vector3(2.0, 0.0, 0.0))
	var e2: EnemyBase = _enemy_at(Vector3(5.0, 0.0, 0.0))
	var w := WeaponData.new()
	w.damage = 40.0
	w.projectile_speed = 80.0
	w.burst_count = 1
	w.burst_interval = 0.0
	var proj: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	add_child(proj)
	proj.initialize_from_weapon(
		w, Vector3(0.0, 0.0, 0.0), Vector3(200.0, 0.0, 0.0), -1.0,
		Types.DamageType.PHYSICAL, 1, 0.0
	)
	await get_tree().process_frame
	for _i: int in range(200):
		proj._physics_process(0.016)
		if not is_instance_valid(proj):
			break
	assert_that(e1.health_component.get_current_hp()).is_equal(160)
	assert_that(e2.health_component.get_current_hp()).is_equal(160)


func test_splash_damages_nearby_enemy() -> void:
	# Line-shot first; second enemy along +X within splash disk (same z).
	var primary: EnemyBase = _enemy_at(Vector3(4.0, 0.0, 0.0))
	var splash_target: EnemyBase = _enemy_at(Vector3(7.0, 0.0, 0.0))
	var w := WeaponData.new()
	w.damage = 40.0
	w.projectile_speed = 12.0
	w.burst_count = 1
	var proj: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	add_child(proj)
	proj.initialize_from_weapon(
		w, Vector3(0.0, 0.0, 0.0), Vector3(80.0, 0.0, 0.0), -1.0,
		Types.DamageType.PHYSICAL, 0, 3.0
	)
	for _i: int in range(400):
		proj._physics_process(0.016)
		if not is_instance_valid(proj):
			break
	assert_that(primary.health_component.get_current_hp()).is_equal(160)
	assert_that(splash_target.health_component.get_current_hp()).is_less(200)


func test_weapon_upgrade_manager_structural_bonuses() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(5000)
	var mgr: WeaponUpgradeManager = WeaponUpgradeManager.new()
	var cb: WeaponData = WeaponData.new()
	cb.weapon_slot = Types.WeaponSlot.CROSSBOW
	cb.damage = 10.0
	cb.projectile_speed = 20.0
	cb.reload_time = 2.0
	cb.burst_count = 1
	mgr.crossbow_base_data = cb
	var lv: WeaponLevelData = WeaponLevelData.new()
	lv.weapon_slot = Types.WeaponSlot.CROSSBOW
	lv.level = 1
	lv.pierce_count_bonus = 2
	lv.projectile_count_bonus = 2
	lv.spread_angle_degrees_bonus = 12.0
	lv.splash_radius_bonus = 4.0
	lv.gold_cost = 1
	mgr.crossbow_levels = [lv]
	add_child(mgr)
	await get_tree().process_frame
	var upgraded: bool = mgr.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_bool(upgraded).is_true()
	assert_int(mgr.get_effective_pierce_count(Types.WeaponSlot.CROSSBOW)).is_equal(2)
	assert_int(mgr.get_effective_projectile_count(Types.WeaponSlot.CROSSBOW)).is_equal(3)
	assert_float(mgr.get_effective_spread_angle_degrees(Types.WeaponSlot.CROSSBOW)).is_equal(12.0)
	assert_float(mgr.get_effective_splash_radius(Types.WeaponSlot.CROSSBOW)).is_equal(4.0)
	mgr.queue_free()
	await get_tree().process_frame


func test_tower_fan_aim_three_projectiles_distinct() -> void:
	var tower_scene: PackedScene = load("res://scenes/tower/tower.tscn")
	var tower: Tower = tower_scene.instantiate() as Tower
	add_child(tower)
	await get_tree().process_frame
	var origin: Vector3 = Vector3(0.0, 0.0, 0.0)
	var aim: Vector3 = Vector3(0.0, 0.0, 30.0)
	var pts: Array[Vector3] = tower.fan_aim_points(origin, aim, 3, 30.0)
	assert_int(pts.size()).is_equal(3)
	assert_that(pts[0].distance_squared_to(pts[1])).is_greater(0.0001)
	assert_that(pts[1].distance_squared_to(pts[2])).is_greater(0.0001)
	tower.queue_free()
	await get_tree().process_frame
