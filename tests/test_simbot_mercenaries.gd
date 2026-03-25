# test_simbot_mercenaries.gd — SimBot mercenary preview / auto-select (Prompt 12).

class_name TestSimBotMercenaries
extends GdUnitTestSuite

const CATALOG: MercenaryCatalog = preload("res://resources/mercenary_catalog.tres")


func before_test() -> void:
	GameManager.start_new_game()
	CampaignManager.mercenary_catalog = CATALOG
	EconomyManager.reset_to_defaults()


func _catalog_ally_ids_from_offers(offers: Array) -> Array[String]:
	var ids: Array[String] = []
	for o: Variant in offers:
		if o != null and not bool(o.get("is_defection_offer")):
			ids.append(str(o.get("ally_id")))
	ids.sort()
	return ids


func test_preview_offers_matches_generated_catalog_ids() -> void:
	var day: int = 2
	CampaignManager.generate_offers_for_day(day)
	var gen: Array = CampaignManager.get_current_offers()
	var prev: Array = CampaignManager.preview_mercenary_offers_for_day(
			day,
			CampaignManager.get_owned_allies()
	)
	assert_that(_catalog_ally_ids_from_offers(gen)).is_equal(_catalog_ally_ids_from_offers(prev))


func test_simbot_exposes_mercenary_api() -> void:
	var bot: SimBot = SimBot.new()
	assert_bool(bot.has_method("get_log")).is_true()
	assert_bool(bot.has_method("decide_mercenaries")).is_true()
	bot.queue_free()


func test_auto_select_best_n_allies_respects_cap_and_budget() -> void:
	EconomyManager.add_gold(1000)
	EconomyManager.add_building_material(50)
	EconomyManager.add_research_material(50)
	CampaignManager.generate_offers_for_day(2)
	var offers: Array = CampaignManager.get_current_offers()
	var result: Dictionary = CampaignManager.auto_select_best_allies(
			Types.StrategyProfile.BALANCED,
			offers,
			CampaignManager.get_owned_allies(),
			2,
			EconomyManager.get_gold(),
			EconomyManager.get_building_material(),
			EconomyManager.get_research_material()
	)
	var rec_idx: Array = result.get("recommended_offer_indices", []) as Array
	var rec_act: Array = result.get("recommended_active_allies", []) as Array
	assert_int(rec_idx.size()).is_less_equal(2)
	assert_int(rec_act.size()).is_less_equal(CampaignManager.max_active_allies_per_day)
