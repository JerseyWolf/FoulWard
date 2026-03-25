# test_mercenary_offers.gd — MercenaryCatalog + CampaignManager offer generation (Prompt 12).

class_name TestMercenaryOffers
extends GdUnitTestSuite

const CATALOG: MercenaryCatalog = preload("res://resources/mercenary_catalog.tres")


func before_test() -> void:
	GameManager.start_new_game()
	CampaignManager.mercenary_catalog = CATALOG


func test_offers_filtered_by_day_and_ownership() -> void:
	var owned: Array[String] = ["hired_archer"]
	var d2: Array = CATALOG.filter_offers_for_day(2, owned)
	var ids: Array[String] = []
	for o: Variant in d2:
		if o != null:
			ids.append(str(o.get("ally_id")))
	assert_bool(ids.has("anti_air_scout")).is_true()
	assert_bool(ids.has("hired_archer")).is_false()


func test_max_number_of_offers_per_day_enforced() -> void:
	var cat: MercenaryCatalog = MercenaryCatalog.new()
	for k: int in range(5):
		var mo: MercenaryOfferData = MercenaryOfferData.new()
		mo.ally_id = "z_%d" % k
		mo.min_day = 1
		mo.max_day = -1
		cat.offers.append(mo)
	cat.max_offers_per_day = 3
	var daily: Array = cat.get_daily_offers(1, [])
	assert_int(daily.size()).is_equal(3)


func test_generate_offers_for_day_populates_current_offers() -> void:
	CampaignManager.current_mercenary_offers.clear()
	CampaignManager.generate_offers_for_day(2)
	assert_int(CampaignManager.get_current_offers().size()).is_greater_equal(1)
