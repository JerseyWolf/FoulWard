# test_campaign_ally_roster.gd — CampaignManager owned/active roster (Prompt 12).

class_name TestCampaignAllyRoster
extends GdUnitTestSuite


func before_test() -> void:
	GameManager.start_new_game()
	CampaignManager.max_active_allies_per_day = 2


func test_start_new_campaign_resets_recruited_allies() -> void:
	CampaignManager.add_ally_to_roster("hired_archer")
	GameManager.start_new_game()
	assert_bool(CampaignManager.is_ally_owned("hired_archer")).is_false()
	assert_bool(CampaignManager.is_ally_owned("arnulf")).is_true()


func test_start_new_campaign_adds_starter_allies() -> void:
	assert_bool(CampaignManager.is_ally_owned("arnulf")).is_true()
	assert_int(CampaignManager.get_owned_allies().size()).is_greater_equal(1)


func test_add_ally_to_roster_makes_ally_owned() -> void:
	CampaignManager.add_ally_to_roster("hired_archer")
	assert_bool(CampaignManager.is_ally_owned("hired_archer")).is_true()


func test_add_ally_to_roster_does_not_duplicate() -> void:
	var n0: int = CampaignManager.get_owned_allies().size()
	CampaignManager.add_ally_to_roster("hired_archer")
	CampaignManager.add_ally_to_roster("hired_archer")
	assert_int(CampaignManager.get_owned_allies().size()).is_equal(n0 + 1)


func test_add_ally_emits_roster_changed() -> void:
	var monitor := monitor_signals(SignalBus, false)
	CampaignManager.add_ally_to_roster("hired_archer")
	await assert_signal(monitor).is_emitted("ally_roster_changed")


func test_toggle_ally_active_respects_cap() -> void:
	CampaignManager.add_ally_to_roster("hired_archer")
	CampaignManager.add_ally_to_roster("anti_air_scout")
	CampaignManager.max_active_allies_per_day = 1
	CampaignManager.set_active_allies_from_list(["arnulf"])
	assert_bool(CampaignManager.toggle_ally_active("hired_archer")).is_false()
	CampaignManager.max_active_allies_per_day = 2


func test_toggle_ally_active_deactivates_when_already_active() -> void:
	CampaignManager.max_active_allies_per_day = 2
	CampaignManager.add_ally_to_roster("hired_archer")
	CampaignManager.set_active_allies_from_list(["arnulf", "hired_archer"])
	assert_bool(CampaignManager.get_active_allies().has("hired_archer")).is_true()
	assert_bool(CampaignManager.toggle_ally_active("hired_archer")).is_true()
	assert_bool(CampaignManager.get_active_allies().has("hired_archer")).is_false()


func test_toggle_unowned_ally_returns_false() -> void:
	assert_bool(CampaignManager.toggle_ally_active("not_a_real_ally")).is_false()


func test_set_active_allies_enforces_cap() -> void:
	CampaignManager.add_ally_to_roster("hired_archer")
	CampaignManager.max_active_allies_per_day = 1
	CampaignManager.set_active_allies_from_list(["arnulf", "hired_archer", "anti_air_scout"])
	assert_int(CampaignManager.get_active_allies().size()).is_equal(1)
	CampaignManager.max_active_allies_per_day = 2


func test_set_active_allies_drops_unowned() -> void:
	CampaignManager.set_active_allies_from_list(["arnulf", "totally_fake_id"])
	assert_bool(CampaignManager.get_active_allies().has("totally_fake_id")).is_false()
