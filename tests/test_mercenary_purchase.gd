# test_mercenary_purchase.gd — EconomyManager + mercenary purchase path (Prompt 12).

class_name TestMercenaryPurchase
extends GdUnitTestSuite

const CATALOG: MercenaryCatalog = preload("res://resources/mercenary_catalog.tres")


func before_test() -> void:
	GameManager.start_new_game()
	CampaignManager.mercenary_catalog = CATALOG
	EconomyManager.reset_to_defaults()


func test_purchase_mercenary_deducts_resources_and_adds_to_roster() -> void:
	EconomyManager.add_gold(500)
	EconomyManager.add_research_material(20)
	CampaignManager.generate_offers_for_day(2)
	var offers: Array = CampaignManager.get_current_offers()
	var idx: int = -1
	for i: int in range(offers.size()):
		var o: Variant = offers[i]
		if o != null and str(o.get("ally_id")) == "anti_air_scout":
			idx = i
			break
	assert_int(idx).is_greater_equal(0)
	var offer: Variant = offers[idx]
	var g_before: int = EconomyManager.get_gold()
	var r_before: int = EconomyManager.get_research_material()
	var ok: bool = CampaignManager.purchase_mercenary_offer(idx)
	assert_bool(ok).is_true()
	assert_bool(CampaignManager.is_ally_owned("anti_air_scout")).is_true()
	assert_int(EconomyManager.get_gold()).is_equal(g_before - int(offer.get("cost_gold")))
	assert_int(EconomyManager.get_research_material()).is_equal(r_before - int(offer.get("cost_research_material")))


func test_purchase_mercenary_fails_with_insufficient_resources() -> void:
	CampaignManager.generate_offers_for_day(2)
	var offers: Array = CampaignManager.get_current_offers()
	var idx: int = -1
	for i: int in range(offers.size()):
		var o: Variant = offers[i]
		if o != null and str(o.get("ally_id")) == "anti_air_scout":
			idx = i
			break
	if idx < 0:
		return
	EconomyManager.reset_to_defaults()
	var ok: bool = CampaignManager.purchase_mercenary_offer(idx)
	assert_bool(ok).is_false()
