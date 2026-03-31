# tests/test_simulation_api.gd
# The most important test file in the project.
# Proves the entire public API is callable and returns correct types
# with NO UI nodes, NO CanvasLayer, NO InputManager in the scene tree.
#
# Credit: GdUnit4 framework by Mike Schulze — https://github.com/MikeSchulze/gdUnit4
# License: MIT
# Used: GdUnitTestSuite lifecycle, monitor_signals, assert_signal,
#   await process_frame, before_test/after_test isolation.

class_name TestSimulationApi
extends GdUnitTestSuite

const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")

# ── Headless scene nodes ──────────────────────────────────────────────────
var _tower: Tower = null
var _wave_manager: WaveManager = null
var _spell_manager: SpellManager = null
var _research_manager: ResearchManager = null
var _shop_manager: ShopManager = null
var _hex_grid: HexGrid = null

var _enemy_container: Node3D = null
var _spawn_points: Node3D = null
var _building_container: Node3D = null

# ─────────────────────────────────────────────────────────────────────────

func before_test() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(1000)
	EconomyManager.add_building_material(50)
	EconomyManager.add_research_material(20)

	# ── Minimal headless scene ────────────────────────────────────────────
	_enemy_container = Node3D.new()
	_enemy_container.name = "EnemyContainer"
	add_child(_enemy_container)

	_spawn_points = Node3D.new()
	_spawn_points.name = "SpawnPoints"
	add_child(_spawn_points)
	for i: int in range(10):
		var marker: Marker3D = Marker3D.new()
		_spawn_points.add_child(marker)
		marker.position = Vector3(float(i) * 4.0, 0.0, 0.0)

	_building_container = Node3D.new()
	_building_container.name = "BuildingContainer"
	add_child(_building_container)

	# ── Tower ─────────────────────────────────────────────────────────────
	var tower_scene: PackedScene = load("res://scenes/tower/tower.tscn")
	_tower = tower_scene.instantiate() as Tower
	add_child(_tower)

	# ── WaveManager ───────────────────────────────────────────────────────
	_wave_manager = WaveManager.new()
	_wave_manager.wave_countdown_duration = 10.0
	_wave_manager.max_waves = 10
	_wave_manager.enemy_data_registry = _build_full_enemy_data()
	add_child(_wave_manager)
	_wave_manager._enemy_container = _enemy_container
	_wave_manager._spawn_points = _spawn_points

	# ── SpellManager ──────────────────────────────────────────────────────
	_spell_manager = SpellManager.new()
	_spell_manager.max_mana = 100
	_spell_manager.mana_regen_rate = 5.0
	_spell_manager.spell_registry = [_build_shockwave_data()]
	add_child(_spell_manager)

	# ── ResearchManager ───────────────────────────────────────────────────
	_research_manager = ResearchManager.new()
	var rnd: ResearchNodeData = ResearchNodeData.new()
	rnd.node_id = "unlock_ballista"
	rnd.display_name = "Ballista"
	rnd.research_cost = 2
	rnd.prerequisite_ids = []
	_research_manager.research_nodes = [rnd]
	add_child(_research_manager)

	# ── ShopManager ───────────────────────────────────────────────────────
	_shop_manager = ShopManager.new()
	_shop_manager.shop_catalog = _build_shop_catalog()
	add_child(_shop_manager)

	# ── HexGrid ───────────────────────────────────────────────────────────
	var hex_scene: PackedScene = load("res://scenes/hex_grid/hex_grid.tscn")
	_hex_grid = hex_scene.instantiate() as HexGrid
	_hex_grid.building_data_registry = _build_eight_building_data()
	add_child(_hex_grid)

	await get_tree().process_frame


func after_test() -> void:
	if is_instance_valid(_tower): _tower.queue_free()
	if is_instance_valid(_wave_manager): _wave_manager.queue_free()
	if is_instance_valid(_spell_manager): _spell_manager.queue_free()
	if is_instance_valid(_research_manager): _research_manager.queue_free()
	if is_instance_valid(_shop_manager): _shop_manager.queue_free()
	if is_instance_valid(_hex_grid): _hex_grid.queue_free()
	if is_instance_valid(_enemy_container): _enemy_container.queue_free()
	if is_instance_valid(_spawn_points): _spawn_points.queue_free()
	if is_instance_valid(_building_container): _building_container.queue_free()
	await get_tree().process_frame

# ── Helper builders ───────────────────────────────────────────────────────

func _build_full_enemy_data() -> Array[EnemyData]:
	var registry: Array[EnemyData] = []
	for t: Types.EnemyType in Types.EnemyType.values():
		var d: EnemyData = EnemyData.new()
		d.enemy_type = t
		d.max_hp = 50
		d.move_speed = 3.0
		d.damage = 5
		d.attack_range = 1.5
		d.attack_cooldown = 1.0
		d.armor_type = Types.ArmorType.UNARMORED
		d.gold_reward = 5
		d.is_flying = (
				t == Types.EnemyType.BAT_SWARM
				or t == Types.EnemyType.HARPY_SCOUT
				or t == Types.EnemyType.WYVERN_RIDER
				or t == Types.EnemyType.ORCISH_SPIRIT
		)
		d.is_ranged = (
				t == Types.EnemyType.ORC_ARCHER
				or t == Types.EnemyType.ORC_MARKSMAN
				or t == Types.EnemyType.WYVERN_RIDER
				or t == Types.EnemyType.ORC_SKYTHROWER
		)
		d.damage_immunities = []
		d.point_cost = 5
		d.wave_tags = ["INVASION"]
		d.tier = 1
		d.balance_status = "UNTESTED"
		registry.append(d)
	return registry


func _build_shockwave_data() -> SpellData:
	var sd: SpellData = SpellData.new()
	sd.spell_id = "shockwave"
	sd.display_name = "Shockwave"
	sd.mana_cost = 50
	sd.cooldown = 60.0
	sd.damage = 30.0
	sd.radius = 100.0
	sd.damage_type = Types.DamageType.MAGICAL
	sd.hits_flying = false
	return sd


func _create_enemy_at(pos: Vector3, is_flying: bool = false) -> EnemyBase:
	var data: EnemyData = EnemyData.new()
	data.display_name = "Aim Test Enemy"
	data.enemy_type = Types.EnemyType.ORC_GRUNT
	data.max_hp = 100
	data.move_speed = 0.0
	data.damage = 1
	data.attack_range = 1.5
	data.attack_cooldown = 1.0
	data.armor_type = Types.ArmorType.UNARMORED
	data.gold_reward = 1
	data.is_ranged = false
	data.is_flying = is_flying
	data.damage_immunities = []
	var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
	_enemy_container.add_child(enemy)
	enemy.global_position = pos
	enemy.initialize(data)
	return enemy


func _build_shop_catalog() -> Array[ShopItemData]:
	var catalog: Array[ShopItemData] = []
	var repair: ShopItemData = ShopItemData.new()
	repair.item_id = "tower_repair"
	repair.display_name = "Tower Repair Kit"
	repair.gold_cost = 50
	repair.material_cost = 0
	catalog.append(repair)
	var mana: ShopItemData = ShopItemData.new()
	mana.item_id = "mana_draught"
	mana.display_name = "Mana Draught"
	mana.gold_cost = 20
	mana.material_cost = 0
	catalog.append(mana)
	return catalog


func _build_eight_building_data() -> Array[BuildingData]:
	var registry: Array[BuildingData] = []
	var types: Array = Types.BuildingType.values()
	for bt in types:
		var bd: BuildingData = BuildingData.new()
		bd.building_type = bt
		bd.display_name = "Test Building %d" % bt
		bd.gold_cost = 50
		bd.material_cost = 2
		bd.upgrade_gold_cost = 75
		bd.upgrade_material_cost = 3
		bd.damage = 20.0
		bd.upgraded_damage = 35.0
		bd.fire_rate = 1.0
		bd.attack_range = 15.0
		bd.upgraded_range = 18.0
		bd.damage_type = Types.DamageType.PHYSICAL
		bd.targets_air = false
		bd.targets_ground = true
		bd.is_locked = false
		bd.color = Color.GRAY
		registry.append(bd)
	return registry

# ═════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: Full game loop without UI (15 tests)
# ═════════════════════════════════════════════════════════════════════════

func test_economy_manager_add_gold_returns_correct_amount() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(150)
	assert_int(EconomyManager.get_gold()).is_equal(1150)


func test_economy_manager_spend_gold_deducts_amount() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(200)
	EconomyManager.spend_gold(75)
	assert_int(EconomyManager.get_gold()).is_equal(1125)


func test_economy_manager_can_afford_returns_bool() -> void:
	var result: Variant = EconomyManager.can_afford(50, 2)
	assert_bool(result is bool).is_true()


func test_wave_manager_get_living_enemy_count_callable() -> void:
	var result: Variant = _wave_manager.get_living_enemy_count()
	assert_bool(result is int).is_true()
	assert_int(result).is_equal(0)


func test_spell_manager_get_current_mana_returns_int() -> void:
	var result: Variant = _spell_manager.get_current_mana()
	assert_bool(result is int).is_true()


func test_spell_manager_cast_spell_returns_bool() -> void:
	_spell_manager.set_mana_to_full()
	var result: Variant = _spell_manager.cast_spell("shockwave")
	assert_bool(result is bool).is_true()


func test_spell_manager_cast_spell_insufficient_mana_returns_false() -> void:
	var result: bool = _spell_manager.cast_spell("shockwave")
	assert_bool(result).is_false()


func test_hex_grid_get_empty_slots_returns_array() -> void:
	var result: Variant = _hex_grid.get_empty_slots()
	assert_bool(result is Array).is_true()
	assert_int((result as Array).size()).is_equal(24)


func test_hex_grid_place_building_returns_bool() -> void:
	var result: Variant = _hex_grid.place_building(
		0, Types.BuildingType.ARROW_TOWER
	)
	assert_bool(result is bool).is_true()


func test_hex_grid_place_building_occupies_slot() -> void:
	_hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)
	await get_tree().process_frame
	var occupied: Array[int] = _hex_grid.get_all_occupied_slots()
	assert_bool(occupied.has(0)).is_true()


func test_research_manager_is_unlocked_returns_bool() -> void:
	var result: Variant = _research_manager.is_unlocked("unlock_ballista")
	assert_bool(result is bool).is_true()
	assert_bool(result).is_false()


func test_shop_manager_can_purchase_returns_bool() -> void:
	var result: Variant = _shop_manager.can_purchase("tower_repair")
	assert_bool(result is bool).is_true()


func test_tower_get_current_hp_returns_int() -> void:
	var result: Variant = _tower.get_current_hp()
	assert_bool(result is int).is_true()
	assert_int(result).is_equal(500)


func test_tower_is_weapon_ready_returns_bool() -> void:
	var result: Variant = _tower.is_weapon_ready(Types.WeaponSlot.CROSSBOW)
	assert_bool(result is bool).is_true()
	assert_bool(result).is_true()

# ═════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: Tower unit tests (7 tests)
# ═════════════════════════════════════════════════════════════════════════

func test_take_damage_reduces_hp() -> void:
	_tower.take_damage(100)
	assert_int(_tower.get_current_hp()).is_equal(400)


func test_take_damage_full_depletes_emits_tower_destroyed() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_tower.take_damage(500)
	await assert_signal(monitor).is_emitted("tower_destroyed")


func test_repair_to_full_restores_hp() -> void:
	_tower.take_damage(300)
	assert_int(_tower.get_current_hp()).is_equal(200)
	_tower.repair_to_full()
	assert_int(_tower.get_current_hp()).is_equal(500)


func test_fire_crossbow_starts_reload_timer() -> void:
	_tower.fire_crossbow(Vector3(10.0, 0.0, 0.0))
	assert_bool(_tower.is_weapon_ready(Types.WeaponSlot.CROSSBOW)).is_false()


func test_tower_fires_with_base_stats_when_no_upgrade_manager() -> void:
	assert_bool(_tower.is_weapon_ready(Types.WeaponSlot.CROSSBOW)).is_true()
	_tower.fire_crossbow(Vector3(10.0, 0.0, 0.0))
	assert_bool(_tower.is_weapon_ready(Types.WeaponSlot.CROSSBOW)).is_false()


func test_fire_crossbow_on_cooldown_does_nothing() -> void:
	_tower.fire_crossbow(Vector3(10.0, 0.0, 0.0))
	_tower.fire_crossbow(Vector3(10.0, 0.0, 0.0))
	assert_bool(_tower.is_weapon_ready(Types.WeaponSlot.CROSSBOW)).is_false()


func test_is_weapon_ready_true_when_not_reloading() -> void:
	assert_bool(_tower.is_weapon_ready(Types.WeaponSlot.CROSSBOW)).is_true()
	assert_bool(_tower.is_weapon_ready(Types.WeaponSlot.RAPID_MISSILE)).is_true()


func test_is_weapon_ready_false_during_reload() -> void:
	_tower.fire_crossbow(Vector3(10.0, 0.0, 0.0))
	assert_bool(_tower.is_weapon_ready(Types.WeaponSlot.CROSSBOW)).is_false()


func test_tower_damaged_signal_emitted_on_take_damage() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_tower.take_damage(50)
	await assert_signal(monitor).is_emitted("tower_damaged", [450, 500])


func test_weapon_data_new_assist_and_miss_defaults_are_zero() -> void:
	var weapon: WeaponData = WeaponData.new()
	assert_float(weapon.assist_angle_degrees).is_equal(0.0)
	assert_float(weapon.assist_max_distance).is_equal(0.0)
	assert_float(weapon.base_miss_chance).is_equal(0.0)
	assert_float(weapon.max_miss_angle_degrees).is_equal(0.0)


func test_crossbow_tres_loads_expected_phase2_defaults() -> void:
	var crossbow: WeaponData = load("res://resources/weapon_data/crossbow.tres") as WeaponData
	assert_object(crossbow).is_not_null()
	assert_float(crossbow.assist_angle_degrees).is_equal_approx(7.5, 0.001)
	assert_float(crossbow.assist_max_distance).is_equal(0.0)
	assert_float(crossbow.base_miss_chance).is_equal_approx(0.05, 0.001)
	assert_float(crossbow.max_miss_angle_degrees).is_equal_approx(2.0, 0.001)


func test_fire_crossbow_with_zero_assist_keeps_raw_target() -> void:
	_tower.crossbow_data.assist_angle_degrees = 0.0
	_tower.crossbow_data.assist_max_distance = 0.0
	_tower.crossbow_data.base_miss_chance = 0.0
	_tower.crossbow_data.max_miss_angle_degrees = 0.0
	_create_enemy_at(Vector3(10.0, 0.0, 0.0), false)

	var raw_target: Vector3 = Vector3(8.0, 0.0, 0.5)
	var monitor := monitor_signals(SignalBus, false)
	_tower.fire_crossbow(raw_target)
	await assert_signal(monitor).is_emitted(
		"projectile_fired",
		[Types.WeaponSlot.CROSSBOW, _tower.global_position, raw_target]
	)


func test_fire_crossbow_assist_snaps_to_nearest_enemy_inside_cone() -> void:
	_tower.crossbow_data.assist_angle_degrees = 10.0
	_tower.crossbow_data.assist_max_distance = 0.0
	_tower.crossbow_data.base_miss_chance = 0.0
	_tower.crossbow_data.max_miss_angle_degrees = 0.0
	var near_enemy: EnemyBase = _create_enemy_at(Vector3(9.0, 0.0, 0.4), false)
	_create_enemy_at(Vector3(18.0, 0.0, 0.8), false)

	var monitor := monitor_signals(SignalBus, false)
	_tower.fire_crossbow(Vector3(10.0, 0.0, 0.0))
	await assert_signal(monitor).is_emitted(
		"projectile_fired",
		[Types.WeaponSlot.CROSSBOW, _tower.global_position, near_enemy.global_position]
	)


func test_fire_crossbow_miss_chance_one_perturbs_direction() -> void:
	_tower.crossbow_data.assist_angle_degrees = 0.0
	_tower.crossbow_data.assist_max_distance = 0.0
	_tower.crossbow_data.base_miss_chance = 1.0
	_tower.crossbow_data.max_miss_angle_degrees = 5.0
	_tower._shot_rng.seed = 12345

	var raw_target: Vector3 = Vector3(10.0, 0.0, 0.0)
	var helper_target: Vector3 = _tower._resolve_manual_aim_target(_tower.crossbow_data, raw_target)
	assert_bool(helper_target != raw_target).is_true()


func test_fire_crossbow_auto_fire_enabled_ignores_assist_and_miss() -> void:
	_tower.auto_fire_enabled = true
	_tower.crossbow_data.assist_angle_degrees = 45.0
	_tower.crossbow_data.assist_max_distance = 0.0
	_tower.crossbow_data.base_miss_chance = 1.0
	_tower.crossbow_data.max_miss_angle_degrees = 15.0
	_create_enemy_at(Vector3(10.0, 0.0, 0.0), false)

	var raw_target: Vector3 = Vector3(7.0, 0.0, 2.0)
	var monitor := monitor_signals(SignalBus, false)
	_tower.fire_crossbow(raw_target)
	await assert_signal(monitor).is_emitted(
		"projectile_fired",
		[Types.WeaponSlot.CROSSBOW, _tower.global_position, raw_target]
	)
	_tower.auto_fire_enabled = false

# ═════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: SimBot activates without UI (2 tests)
# ═════════════════════════════════════════════════════════════════════════

func test_sim_bot_activate_does_not_crash() -> void:
	var sim_bot: SimBot = SimBot.new()
	add_child(sim_bot)
	sim_bot.activate(Types.StrategyProfile.BALANCED)
	await get_tree().process_frame
	sim_bot.deactivate()
	sim_bot.queue_free()


func test_sim_bot_has_all_public_methods() -> void:
	var sim_bot: SimBot = SimBot.new()
	assert_bool(sim_bot.has_method("activate")).is_true()
	assert_bool(sim_bot.has_method("deactivate")).is_true()
	assert_bool(sim_bot.has_method("bot_enter_build_mode")).is_true()
	assert_bool(sim_bot.has_method("bot_exit_build_mode")).is_true()
	assert_bool(sim_bot.has_method("bot_place_building")).is_true()
	assert_bool(sim_bot.has_method("bot_cast_spell")).is_true()
	assert_bool(sim_bot.has_method("bot_fire_crossbow")).is_true()
	assert_bool(sim_bot.has_method("bot_advance_wave")).is_true()

# ═════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: SignalBus observable without UI (4 tests)
# ═════════════════════════════════════════════════════════════════════════

func test_resource_changed_emitted_after_add_gold() -> void:
	var monitor := monitor_signals(SignalBus, false)
	EconomyManager.add_gold(10)
	await assert_signal(monitor).is_emitted(
		"resource_changed", [Types.ResourceType.GOLD, 2010]
	)


func test_tower_damaged_emitted_after_take_damage() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_tower.take_damage(10)
	await assert_signal(monitor).is_emitted("tower_damaged", [490, 500])


func test_research_unlocked_emitted_after_unlock_node() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_research_manager.unlock_node("unlock_ballista")
	await assert_signal(monitor).is_emitted("research_unlocked", ["unlock_ballista"])


func test_shop_item_purchased_emitted_after_purchase() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_shop_manager.purchase_item("mana_draught")
	await assert_signal(monitor).is_emitted("shop_item_purchased", ["mana_draught"])


# ═════════════════════════════════════════════════════════════════════════
# Audit 5 — Firing assist / miss perturbation
# ═════════════════════════════════════════════════════════════════════════


func test_assist_not_applied_when_enemy_beyond_assist_max_distance() -> void:
	_tower.crossbow_data.assist_angle_degrees = 45.0
	_tower.crossbow_data.assist_max_distance = 10.0
	_tower.crossbow_data.base_miss_chance = 0.0
	_tower.crossbow_data.max_miss_angle_degrees = 0.0
	_create_enemy_at(Vector3(30.0, 0.0, 0.0), false)
	var raw_target: Vector3 = Vector3(10.0, 0.0, 0.0)
	var resolved: Vector3 = _tower._resolve_manual_aim_target(_tower.crossbow_data, raw_target)
	assert_float(resolved.distance_to(raw_target)).is_less(0.001)


func test_miss_perturbation_respects_max_miss_angle_degrees() -> void:
	_tower.crossbow_data.assist_angle_degrees = 0.0
	_tower.crossbow_data.assist_max_distance = 0.0
	_tower.crossbow_data.base_miss_chance = 1.0
	_tower.crossbow_data.max_miss_angle_degrees = 2.0
	_tower._shot_rng.seed = 99999
	var aim: Vector3 = Vector3(15.0, 0.0, 0.0)
	for _i in range(20):
		var out: Vector3 = _tower._resolve_manual_aim_target(_tower.crossbow_data, aim)
		var dir_a: Vector3 = (aim - _tower.global_position).normalized()
		var dir_b: Vector3 = (out - _tower.global_position).normalized()
		var ang: float = rad_to_deg(dir_a.angle_to(dir_b))
		assert_float(ang).is_less_equal(2.01)


func test_auto_fire_autofire_path_matches_raw_target_with_assist_enabled() -> void:
	_tower.auto_fire_enabled = true
	_tower.crossbow_data.assist_angle_degrees = 45.0
	_tower.crossbow_data.assist_max_distance = 0.0
	_tower.crossbow_data.base_miss_chance = 1.0
	_tower.crossbow_data.max_miss_angle_degrees = 15.0
	_create_enemy_at(Vector3(10.0, 0.0, 0.0), false)
	var raw_target: Vector3 = Vector3(7.0, 0.0, 2.0)
	var monitor := monitor_signals(SignalBus, false)
	_tower.fire_crossbow(raw_target)
	await assert_signal(monitor).is_emitted(
		"projectile_fired",
		[Types.WeaponSlot.CROSSBOW, _tower.global_position, raw_target]
	)
	_tower.auto_fire_enabled = false

