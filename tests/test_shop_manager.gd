# tests/test_shop_manager.gd
# GdUnit4 test suite for ShopManager.
# Tests purchase flow, affordability, effects, and signal emission.

class_name TestShopManager
extends GdUnitTestSuite

var _shop_manager: ShopManager = null


func _make_item(item_id: String, gold: int, material: int = 0) -> ShopItemData:
	var item: ShopItemData = ShopItemData.new()
	item.item_id = item_id
	item.display_name = item_id
	item.gold_cost = gold
	item.material_cost = material
	item.description = "Test item %s" % item_id
	if item_id == "mana_draught":
		item.item_type = "consumable"
		item.effect_tags = ["mana_restore"]
	return item


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(500)
	EconomyManager.add_building_material(50)
	_shop_manager = ShopManager.new()
	_shop_manager.shop_catalog = [
		_make_item("tower_repair", 50, 0),
		_make_item("mana_draught", 20, 0),
	]
	add_child(_shop_manager)


func after_test() -> void:
	if is_instance_valid(_shop_manager):
		_shop_manager.queue_free()
	EconomyManager.reset_to_defaults()
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# purchase_item tests
# ---------------------------------------------------------------------------

func test_purchase_item_deducts_gold() -> void:
	var gold_before: int = EconomyManager.get_gold()
	_shop_manager.purchase_item("mana_draught")
	assert_int(EconomyManager.get_gold()).is_equal(gold_before - 20)


func test_purchase_item_insufficient_gold_fails() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.spend_gold(990)
	assert_int(EconomyManager.get_gold()).is_equal(10)
	var result: bool = _shop_manager.purchase_item("tower_repair")
	assert_bool(result).is_false()
	assert_int(EconomyManager.get_gold()).is_equal(10)


func test_purchase_item_returns_false_for_unknown_id() -> void:
	var result: bool = _shop_manager.purchase_item("does_not_exist")
	assert_bool(result).is_false()


func test_purchase_item_emits_shop_item_purchased() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_shop_manager.purchase_item("mana_draught")
	await assert_signal(monitor).is_emitted("shop_item_purchased", ["mana_draught"])


func test_purchase_item_emits_correct_item_id() -> void:
	var monitor := monitor_signals(SignalBus, false)
	_shop_manager.purchase_item("mana_draught")
	await assert_signal(monitor).is_emitted("shop_item_purchased", ["mana_draught"])

# ---------------------------------------------------------------------------
# can_purchase tests
# ---------------------------------------------------------------------------

func test_can_purchase_returns_true_when_affordable() -> void:
	assert_bool(_shop_manager.can_purchase("mana_draught")).is_true()


func test_can_purchase_returns_false_when_insufficient_gold() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.spend_gold(951)
	assert_bool(_shop_manager.can_purchase("tower_repair")).is_false()


func test_can_purchase_returns_false_for_unknown_id() -> void:
	assert_bool(_shop_manager.can_purchase("nonexistent")).is_false()

# ---------------------------------------------------------------------------
# Effect tests
# ---------------------------------------------------------------------------

func test_purchase_mana_draught_adds_stack() -> void:
	assert_int(_shop_manager.get_stack_count("mana_draught")).is_equal(0)
	_shop_manager.purchase_item("mana_draught")
	assert_int(_shop_manager.get_stack_count("mana_draught")).is_equal(1)


func test_mission_started_consumes_mana_draught_stack() -> void:
	_shop_manager.purchase_item("mana_draught")
	assert_int(_shop_manager.get_stack_count("mana_draught")).is_equal(1)
	SignalBus.mission_started.emit(1)
	assert_int(_shop_manager.get_stack_count("mana_draught")).is_equal(0)


func test_consume_empty_stack_returns_false() -> void:
	var result: bool = _shop_manager.consume("mana_draught")
	assert_bool(result).is_false()


func test_purchase_tower_repair_graceful_when_tower_absent() -> void:
	# Tower is absent in unit test scene; purchase_item must still return true
	# (cost is spent; push_error is logged but no crash).
	var result: bool = _shop_manager.purchase_item("tower_repair")
	assert_bool(result).is_true()


func test_purchase_tower_repair_deducts_50_gold() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(500)
	var gold_before: int = EconomyManager.get_gold()
	_shop_manager.purchase_item("tower_repair")
	assert_int(EconomyManager.get_gold()).is_equal(gold_before - 50)

# ---------------------------------------------------------------------------
# get_available_items tests
# ---------------------------------------------------------------------------

func test_get_available_items_returns_all_catalog_items() -> void:
	var items: Array[ShopItemData] = _shop_manager.get_available_items()
	assert_int(items.size()).is_equal(2)


func test_get_available_items_returns_copy_not_reference() -> void:
	var items: Array[ShopItemData] = _shop_manager.get_available_items()
	items.clear()
	assert_int(_shop_manager.get_available_items().size()).is_equal(2)

