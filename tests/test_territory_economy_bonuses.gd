## test_territory_economy_bonuses.gd
## Aggregated territory gold modifiers vs EconomyManager.

class_name TestTerritoryEconomyBonuses
extends GdUnitTestSuite

var _saved_territory_map: TerritoryMapData = null


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	_saved_territory_map = GameManager.territory_map


func after_test() -> void:
	GameManager.territory_map = _saved_territory_map
	GameManager.reload_territory_map_from_active_campaign()


func _load_main_map_and_heart() -> TerritoryData:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap
	var heart: TerritoryData = tmap.get_territory_by_id("heartland_plains")
	assert_object(heart).is_not_null()
	return heart


func _make_research_node(node_id: String, cost: int, prereqs: Array[String] = []) -> ResearchNodeData:
	var rnd: ResearchNodeData = ResearchNodeData.new()
	rnd.node_id = node_id
	rnd.display_name = node_id
	rnd.research_cost = cost
	rnd.prerequisite_ids = prereqs
	rnd.description = "Test node %s" % node_id
	return rnd


func _make_minimal_weapon_upgrade_manager() -> WeaponUpgradeManager:
	var mgr: WeaponUpgradeManager = WeaponUpgradeManager.new()
	var cb_data: WeaponData = WeaponData.new()
	cb_data.weapon_slot = Types.WeaponSlot.CROSSBOW
	cb_data.damage = 50.0
	cb_data.projectile_speed = 30.0
	cb_data.reload_time = 2.5
	cb_data.burst_count = 1
	cb_data.burst_interval = 0.0
	mgr.crossbow_base_data = cb_data
	var cb1: WeaponLevelData = WeaponLevelData.new()
	cb1.weapon_slot = Types.WeaponSlot.CROSSBOW
	cb1.level = 1
	cb1.damage_bonus = 10.0
	cb1.speed_bonus = 0.0
	cb1.reload_bonus = 0.0
	cb1.burst_count_bonus = 0
	cb1.gold_cost = 100
	mgr.crossbow_levels = [cb1]
	return mgr


func test_controlled_territory_increases_end_of_day_gold() -> void:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap

	var heart: TerritoryData = tmap.get_territory_by_id("heartland_plains")
	assert_object(heart).is_not_null()
	heart.is_controlled_by_player = true
	heart.is_permanently_lost = false
	heart.bonus_flat_gold_end_of_day = 25
	heart.bonus_percent_gold_end_of_day = 0.0

	var modifiers: Dictionary = GameManager.get_current_territory_gold_modifiers()
	assert_int(int(modifiers.get("flat_gold_end_of_day", -1))).is_equal(25)

	var base_gold: int = 100
	var flat_bonus: int = int(modifiers.get("flat_gold_end_of_day", 0))
	var total: int = base_gold + flat_bonus
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(total)
	assert_int(EconomyManager.get_gold()).is_equal(1000 + total)


func test_lost_territory_bonus_does_not_apply() -> void:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap

	var heart: TerritoryData = tmap.get_territory_by_id("heartland_plains")
	heart.is_controlled_by_player = false
	heart.is_permanently_lost = true
	heart.bonus_flat_gold_end_of_day = 99

	var modifiers: Dictionary = GameManager.get_current_territory_gold_modifiers()
	assert_int(int(modifiers.get("flat_gold_end_of_day", -1))).is_equal(0)


func test_flat_gold_per_kill_applied_when_territory_controlled() -> void:
	var heart: TerritoryData = _load_main_map_and_heart()
	heart.is_controlled_by_player = true
	heart.is_permanently_lost = false
	heart.is_secured = true
	heart.bonus_flat_gold_per_kill = 11
	assert_int(GameManager.get_aggregate_flat_gold_per_kill()).is_equal(11)

	heart.is_controlled_by_player = false
	assert_int(GameManager.get_aggregate_flat_gold_per_kill()).is_equal(0)


func test_research_cost_multiplier_applied_when_territory_controlled() -> void:
	ChronicleManager.reset_for_test()
	var heart: TerritoryData = _load_main_map_and_heart()
	heart.is_controlled_by_player = true
	heart.is_permanently_lost = false
	heart.is_secured = true
	heart.bonus_research_cost_multiplier = 0.5

	EconomyManager.reset_to_defaults()
	EconomyManager.add_research_material(100)
	var rm: ResearchManager = ResearchManager.new()
	rm.research_nodes = [_make_research_node("t_rm_ballista", 10, [])]
	add_child(rm)
	await get_tree().process_frame
	var ok: bool = rm.unlock_node("t_rm_ballista")
	assert_bool(ok).is_true()
	assert_int(EconomyManager.get_research_material()).is_equal(95)

	rm.queue_free()
	await get_tree().process_frame

	heart.is_controlled_by_player = false
	EconomyManager.reset_to_defaults()
	EconomyManager.add_research_material(100)
	var rm2: ResearchManager = ResearchManager.new()
	rm2.research_nodes = [_make_research_node("t_rm_ballista_b", 10, [])]
	add_child(rm2)
	await get_tree().process_frame
	var ok2: bool = rm2.unlock_node("t_rm_ballista_b")
	assert_bool(ok2).is_true()
	assert_int(EconomyManager.get_research_material()).is_equal(90)

	rm2.queue_free()
	await get_tree().process_frame


func test_enchanting_cost_multiplier_applied_when_territory_controlled() -> void:
	ChronicleManager.reset_for_test()
	var heart: TerritoryData = _load_main_map_and_heart()
	heart.is_controlled_by_player = true
	heart.is_permanently_lost = false
	heart.is_secured = true
	heart.bonus_enchanting_cost_multiplier = 0.5

	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()
	var applied: bool = EnchantmentManager.try_apply_enchantment(
		Types.WeaponSlot.CROSSBOW, "elemental", "scorching_bolts", 100
	)
	assert_bool(applied).is_true()
	assert_int(EconomyManager.get_gold()).is_equal(950)

	heart.is_controlled_by_player = false
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()
	var applied2: bool = EnchantmentManager.try_apply_enchantment(
		Types.WeaponSlot.CROSSBOW, "elemental", "scorching_bolts", 100
	)
	assert_bool(applied2).is_true()
	assert_int(EconomyManager.get_gold()).is_equal(900)


func test_weapon_upgrade_cost_multiplier_applied_when_territory_controlled() -> void:
	var heart: TerritoryData = _load_main_map_and_heart()
	heart.is_controlled_by_player = true
	heart.is_permanently_lost = false
	heart.is_secured = true
	heart.bonus_weapon_upgrade_cost_multiplier = 0.5

	EconomyManager.reset_to_defaults()
	var wum: WeaponUpgradeManager = _make_minimal_weapon_upgrade_manager()
	add_child(wum)
	await get_tree().process_frame
	var up_ok: bool = wum.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_bool(up_ok).is_true()
	assert_int(EconomyManager.get_gold()).is_equal(950)

	wum.queue_free()
	await get_tree().process_frame

	heart.is_controlled_by_player = false
	EconomyManager.reset_to_defaults()
	var wum2: WeaponUpgradeManager = _make_minimal_weapon_upgrade_manager()
	add_child(wum2)
	await get_tree().process_frame
	var up_ok2: bool = wum2.upgrade_weapon(Types.WeaponSlot.CROSSBOW)
	assert_bool(up_ok2).is_true()
	assert_int(EconomyManager.get_gold()).is_equal(900)

	wum2.queue_free()
	await get_tree().process_frame


func test_bonus_research_per_day_applied_when_territory_controlled() -> void:
	var heart: TerritoryData = _load_main_map_and_heart()
	heart.is_controlled_by_player = true
	heart.is_permanently_lost = false
	heart.is_secured = true
	heart.bonus_research_per_day = 6
	assert_int(GameManager.get_aggregate_bonus_research_per_day()).is_equal(6)

	heart.is_controlled_by_player = false
	assert_int(GameManager.get_aggregate_bonus_research_per_day()).is_equal(0)
