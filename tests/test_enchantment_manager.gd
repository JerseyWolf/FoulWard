extends GdUnitTestSuite
class_name TestEnchantmentManager


func before_test() -> void:
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()


func test_apply_enchantment_stores_and_replaces_previous() -> void:
	var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.CROSSBOW
	var slot_type: String = "elemental"
	var first_id: String = "scorching_bolts"
	var second_id: String = "toxic_payload"
	var gold_cost: int = 0

	var first_result: bool = EnchantmentManager.try_apply_enchantment(weapon_slot, slot_type, first_id, gold_cost)
	var stored_first: String = EnchantmentManager.get_equipped_enchantment_id(weapon_slot, slot_type)

	var second_result: bool = EnchantmentManager.try_apply_enchantment(weapon_slot, slot_type, second_id, gold_cost)
	var stored_second: String = EnchantmentManager.get_equipped_enchantment_id(weapon_slot, slot_type)

	assert_bool(first_result).is_true()
	assert_str(stored_first).is_equal(first_id)
	assert_bool(second_result).is_true()
	assert_str(stored_second).is_equal(second_id)


func test_apply_enchantment_fails_when_insufficient_gold() -> void:
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()

	var current_gold: int = EconomyManager.get_gold()
	if current_gold > 0:
		EconomyManager.spend_gold(current_gold)

	var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.CROSSBOW
	var slot_type: String = "power"
	var enchantment_id: String = "sharpened_mechanism"
	var gold_cost: int = 10

	var monitor := monitor_signals(SignalBus, false)
	var result: bool = EnchantmentManager.try_apply_enchantment(weapon_slot, slot_type, enchantment_id, gold_cost)
	var stored: String = EnchantmentManager.get_equipped_enchantment_id(weapon_slot, slot_type)

	assert_bool(result).is_false()
	assert_str(stored).is_equal("")
	await assert_signal(monitor).is_not_emitted("enchantment_applied")


func test_enchantment_state_resets_on_start_new_game() -> void:
	EconomyManager.reset_to_defaults()
	EnchantmentManager.reset_to_defaults()
	var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.RAPID_MISSILE
	var slot_type: String = "elemental"
	var enchantment_id: String = "scorching_bolts"
	var gold_cost: int = 0
	var applied: bool = EnchantmentManager.try_apply_enchantment(weapon_slot, slot_type, enchantment_id, gold_cost)
	assert_bool(applied).is_true()

	GameManager.start_new_game()
	var stored_after: String = EnchantmentManager.get_equipped_enchantment_id(weapon_slot, slot_type)
	assert_str(stored_after).is_equal("")


func test_get_all_equipped_enchantments_for_weapon_returns_both_slots() -> void:
	EnchantmentManager.reset_to_defaults()
	EconomyManager.reset_to_defaults()

	var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.CROSSBOW
	var elemental_id: String = "scorching_bolts"
	var power_id: String = "sharpened_mechanism"

	EnchantmentManager.try_apply_enchantment(weapon_slot, "elemental", elemental_id, 0)
	EnchantmentManager.try_apply_enchantment(weapon_slot, "power", power_id, 0)

	var slots: Dictionary = EnchantmentManager.get_all_equipped_enchantments_for_weapon(weapon_slot)

	assert_dict(slots).contains_keys(["elemental", "power"])
	assert_str(slots["elemental"] as String).is_equal(elemental_id)
	assert_str(slots["power"] as String).is_equal(power_id)
