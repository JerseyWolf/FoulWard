# test_mini_boss_defection.gd — Mini-boss defection mercenary offers (Prompt 12).

class_name TestMiniBossDefection
extends GdUnitTestSuite


func before_test() -> void:
	GameManager.start_new_game()


func test_defeated_defectable_miniboss_creates_corresponding_offer() -> void:
	CampaignManager.notify_mini_boss_defeated("orc_captain")
	var found: bool = false
	for o: Variant in CampaignManager.get_current_offers():
		if o != null and bool(o.get("is_defection_offer")) and str(o.get("ally_id")) == "defected_orc_captain":
			found = true
			break
	assert_bool(found).is_true()


func test_purchasing_defected_miniboss_adds_to_roster() -> void:
	CampaignManager.notify_mini_boss_defeated("orc_captain")
	var idx: int = -1
	var offers: Array = CampaignManager.get_current_offers()
	for i: int in range(offers.size()):
		var o: Variant = offers[i]
		if o != null and str(o.get("ally_id")) == "defected_orc_captain":
			idx = i
			break
	assert_int(idx).is_greater_equal(0)
	var ok: bool = CampaignManager.purchase_mercenary_offer(idx)
	assert_bool(ok).is_true()
	assert_bool(CampaignManager.is_ally_owned("defected_orc_captain")).is_true()
