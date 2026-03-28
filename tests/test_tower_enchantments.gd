extends GdUnitTestSuite
class_name TestTowerEnchantments

const TOWER_SCENE: PackedScene = preload("res://scenes/tower/tower.tscn")

var _root: Node3D
var _tower: Tower
var _projectile_container: Node3D


func before_test() -> void:
	_root = Node3D.new()
	_root.name = "Main"
	get_tree().root.add_child(_root)

	_projectile_container = Node3D.new()
	_projectile_container.name = "ProjectileContainer"
	_root.add_child(_projectile_container)

	_tower = TOWER_SCENE.instantiate() as Tower
	_tower.name = "Tower"
	_root.add_child(_tower)

	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()


func after_test() -> void:
	if is_instance_valid(_root):
		_root.queue_free()
	await get_tree().process_frame


func _get_single_projectile() -> ProjectileBase:
	for child: Node in _projectile_container.get_children():
		if child is ProjectileBase:
			return child as ProjectileBase
	return null


func test_tower_projectile_uses_physical_when_no_enchantment() -> void:
	var target_pos: Vector3 = _tower.global_position + Vector3(10.0, 0.0, 0.0)

	_tower.fire_crossbow(target_pos)
	await get_tree().process_frame

	var projectile: ProjectileBase = _get_single_projectile()
	assert_object(projectile).is_not_null()
	var damage_type: int = projectile.get("_damage_type") as int
	assert_int(damage_type).is_equal(Types.DamageType.PHYSICAL)


func test_tower_projectile_uses_enchantment_damage_type_when_active() -> void:
	var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.CROSSBOW
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()
	EnchantmentManager.try_apply_enchantment(weapon_slot, "elemental", "scorching_bolts", 0)

	var target_pos: Vector3 = _tower.global_position + Vector3(10.0, 0.0, 0.0)

	_tower.fire_crossbow(target_pos)
	await get_tree().process_frame

	var projectile: ProjectileBase = _get_single_projectile()
	assert_object(projectile).is_not_null()
	var damage_type: int = projectile.get("_damage_type") as int
	assert_int(damage_type).is_equal(Types.DamageType.FIRE)


func test_tower_projectile_damage_scaled_by_both_slots() -> void:
	var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.CROSSBOW
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()

	EnchantmentManager.try_apply_enchantment(weapon_slot, "elemental", "scorching_bolts", 0)
	EnchantmentManager.try_apply_enchantment(weapon_slot, "power", "sharpened_mechanism", 0)

	var base_damage: float = _tower.crossbow_data.damage
	var expected_damage: float = base_damage * 1.2 * 1.3
	var target_pos: Vector3 = _tower.global_position + Vector3(10.0, 0.0, 0.0)

	_tower.fire_crossbow(target_pos)
	await get_tree().process_frame

	var projectile: ProjectileBase = _get_single_projectile()
	assert_object(projectile).is_not_null()
	var actual_damage: float = projectile.get("_damage") as float
	assert_float(actual_damage).is_equal_approx(expected_damage, 0.001)


func test_remove_enchantment_subsequent_shot_uses_physical_damage_type() -> void:
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()
	EnchantmentManager.try_apply_enchantment(
		Types.WeaponSlot.CROSSBOW, "elemental", "scorching_bolts", 0
	)
	var target_pos: Vector3 = _tower.global_position + Vector3(10.0, 0.0, 0.0)
	_tower.fire_crossbow(target_pos)
	await get_tree().process_frame
	var first: ProjectileBase = _get_single_projectile()
	assert_int(first.get("_damage_type") as int).is_equal(Types.DamageType.FIRE)

	EnchantmentManager.remove_enchantment(Types.WeaponSlot.CROSSBOW, "elemental")
	for c: Node in _projectile_container.get_children():
		c.queue_free()
	await get_tree().process_frame

	_tower._crossbow_reload_remaining = 0.0
	_tower.fire_crossbow(target_pos)
	await get_tree().process_frame
	var second: ProjectileBase = _get_single_projectile()
	assert_object(second).is_not_null()
	assert_int(second.get("_damage_type") as int).is_equal(Types.DamageType.PHYSICAL)


func test_swap_enchantment_elemental_changes_second_shot_damage_type() -> void:
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()
	EnchantmentManager.try_apply_enchantment(
		Types.WeaponSlot.CROSSBOW, "elemental", "scorching_bolts", 0
	)
	_tower.fire_crossbow(_tower.global_position + Vector3(10.0, 0.0, 0.0))
	await get_tree().process_frame
	for c: Node in _projectile_container.get_children():
		c.queue_free()
	await get_tree().process_frame

	EnchantmentManager.remove_enchantment(Types.WeaponSlot.CROSSBOW, "elemental")
	EnchantmentManager.try_apply_enchantment(
		Types.WeaponSlot.CROSSBOW, "elemental", "toxic_payload", 0
	)
	_tower._crossbow_reload_remaining = 0.0
	_tower.fire_crossbow(_tower.global_position + Vector3(10.0, 0.0, 0.0))
	await get_tree().process_frame
	var p: ProjectileBase = _get_single_projectile()
	assert_int(p.get("_damage_type") as int).is_equal(Types.DamageType.POISON)
