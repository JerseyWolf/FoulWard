extends GdUnitTestSuite
class_name TestSybilPassiveManager

var _offer_signal_hits: int = 0


func after_test() -> void:
	SybilPassiveManager.clear_passive()


func _on_passives_offered(_ids: Variant) -> void:
	_offer_signal_hits += 1


func test_load_all_passives_from_directory() -> void:
	assert_int(SybilPassiveManager._all_passives.size()).is_equal(8)


func test_get_offered_passives_returns_offer_count() -> void:
	var offered: Array = SybilPassiveManager.get_offered_passives()
	assert_int(offered.size()).is_equal(SybilPassiveManager.OFFER_COUNT)


func test_get_offered_passives_all_unlocked() -> void:
	var offered: Array = SybilPassiveManager.get_offered_passives()
	for v: Variant in offered:
		var res: Resource = v as Resource
		assert_bool(bool(res.get("is_unlocked"))).is_true()


func test_select_passive_sets_active() -> void:
	SybilPassiveManager.select_passive("passive_iron_vow")
	assert_object(SybilPassiveManager.get_active_passive()).is_not_null()


func test_select_passive_emits_signal() -> void:
	var monitor := monitor_signals(SignalBus, false)
	SybilPassiveManager.select_passive("passive_iron_vow")
	await assert_signal(SignalBus).is_emitted("sybil_passive_selected", ["passive_iron_vow"])


func test_get_modifier_returns_value_for_matching_type() -> void:
	SybilPassiveManager.select_passive("passive_iron_vow")
	assert_float(SybilPassiveManager.get_modifier("spell_damage_pct")).is_equal(0.15)


func test_get_modifier_returns_zero_for_non_matching() -> void:
	SybilPassiveManager.select_passive("passive_iron_vow")
	assert_float(SybilPassiveManager.get_modifier("mana_regen_pct")).is_equal(0.0)


func test_clear_passive_resets_state() -> void:
	SybilPassiveManager.select_passive("passive_iron_vow")
	SybilPassiveManager.clear_passive()
	assert_that(SybilPassiveManager.get_active_passive()).is_null()


func test_save_restore_preserves_selection() -> void:
	SybilPassiveManager.select_passive("passive_iron_vow")
	var data: Dictionary = SybilPassiveManager.get_save_data()
	SybilPassiveManager.clear_passive()
	assert_that(SybilPassiveManager.get_active_passive()).is_null()
	SybilPassiveManager.restore_from_save_data(data)
	var ap: Resource = SybilPassiveManager.get_active_passive()
	assert_object(ap).is_not_null()
	assert_str(str(ap.get("passive_id"))).is_equal("passive_iron_vow")


func test_save_restore_empty_data_no_crash() -> void:
	SybilPassiveManager.select_passive("passive_iron_vow")
	SybilPassiveManager.restore_from_save_data({})
	assert_that(SybilPassiveManager.get_active_passive()).is_null()


func test_offered_passives_signal_emitted() -> void:
	_offer_signal_hits = 0
	SignalBus.sybil_passives_offered.connect(_on_passives_offered)
	SybilPassiveManager.get_offered_passives()
	assert_int(_offer_signal_hits).is_equal(1)
	SignalBus.sybil_passives_offered.disconnect(_on_passives_offered)
