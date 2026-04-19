# tests/test_consumables.gd
# GdUnit4 — consumable stack caps, mission_start application, effect dispatch.

class_name TestConsumables
extends GdUnitTestSuite

var _shop: ShopManager


func _make_mana_item() -> ShopItemData:
	var item: ShopItemData = ShopItemData.new()
	item.item_id = "mana_draught"
	item.display_name = "Mana Draught"
	item.gold_cost = 20
	item.category = "consumable"
	item.effect_tags = ["mana_restore"]
	item.value = 0
	return item


func _attach_spell_under_main(spell: SpellManager) -> Node:
	var root: Window = get_tree().root
	var stale: Node = root.get_node_or_null("Main")
	if stale != null:
		root.remove_child(stale)
		stale.free()
	var main: Node = Node3D.new()
	main.name = "Main"
	root.add_child(main)
	var mgr: Node = main.get_node_or_null("Managers")
	if mgr == null:
		mgr = Node.new()
		mgr.name = "Managers"
		main.add_child(mgr)
	var old: Node = mgr.get_node_or_null("SpellManager")
	if old != null:
		old.queue_free()
	mgr.add_child(spell)
	spell.name = "SpellManager"
	return main


func before_test() -> void:
	_shop = ShopManager.new()
	_shop.shop_catalog = [_make_mana_item()]
	add_child(_shop)


func after_test() -> void:
	if is_instance_valid(_shop):
		_shop.queue_free()
	await get_tree().process_frame


func test_stack_capped_at_20() -> void:
	_shop.add_consumable("mana_draught", 25)
	assert_int(_shop.get_stack_count("mana_draught")).is_equal(20)


func test_consume_decrements_stack() -> void:
	_shop.add_consumable("mana_draught", 3)
	var ok: bool = _shop.consume("mana_draught")
	assert_bool(ok).is_true()
	assert_int(_shop.get_stack_count("mana_draught")).is_equal(2)


func test_consume_empty_returns_false() -> void:
	var ok: bool = _shop.consume("mana_draught")
	assert_bool(ok).is_false()


func test_mana_draught_effect_restores_mana() -> void:
	var spell: SpellManager = SpellManager.new()
	spell.max_mana = 100
	var main: Node = _attach_spell_under_main(spell)
	spell.reset_to_defaults()
	assert_int(spell.get_current_mana()).is_equal(0)
	_shop.add_consumable("mana_draught", 1)
	SignalBus.mission_started.emit(1)
	assert_int(spell.get_current_mana()).is_greater(0)
	main.queue_free()
	await get_tree().process_frame


func test_unknown_effect_tag_does_not_crash() -> void:
	var unknown: ShopItemData = ShopItemData.new()
	unknown.item_id = "unknown_consumable_test"
	unknown.effect_tags = ["totally_unknown"]
	_shop.shop_catalog = [_make_mana_item(), unknown]
	_shop._apply_consumable_effect("unknown_consumable_test")
	assert_bool(true).is_true()
