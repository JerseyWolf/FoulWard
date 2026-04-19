# tests/test_shop_rotation.gd
# GdUnit4 — ShopManager.get_daily_items rotation, determinism, and SimBot profile tuning.

class_name TestShopRotation
extends GdUnitTestSuite

var _shop: ShopManager = null


func _item(item_id: String, category: String, weight: float = 1.0) -> ShopItemData:
	var i: ShopItemData = ShopItemData.new()
	i.item_id = item_id
	i.category = category
	i.rarity_weight = weight
	return i


func _catalog_ten_mixed() -> Array[ShopItemData]:
	return [
		_item("c0", "consumable"),
		_item("c1", "consumable"),
		_item("c2", "consumable"),
		_item("c3", "consumable"),
		_item("e0", "equipment"),
		_item("e1", "equipment"),
		_item("e2", "equipment"),
		_item("e3", "equipment"),
		_item("v0", "voucher"),
		_item("v1", "voucher"),
	]


func _ids_sequence(items: Array[ShopItemData]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for it: ShopItemData in items:
		out.append(it.item_id)
	return out


func after_test() -> void:
	if is_instance_valid(_shop):
		_shop.queue_free()
		_shop = null


func test_get_daily_items_count_in_range() -> void:
	_shop = ShopManager.new()
	_shop.shop_catalog = _catalog_ten_mixed()
	add_child(_shop)
	var got: Array[ShopItemData] = _shop.get_daily_items(0)
	assert_int(got.size()).is_greater_equal(4)
	assert_int(got.size()).is_less_equal(6)


func test_get_daily_items_deterministic() -> void:
	_shop = ShopManager.new()
	_shop.shop_catalog = _catalog_ten_mixed()
	add_child(_shop)
	var a: Array[ShopItemData] = _shop.get_daily_items(5)
	var b: Array[ShopItemData] = _shop.get_daily_items(5)
	assert_that(_ids_sequence(a)).is_equal(_ids_sequence(b))


func test_get_daily_items_different_days_differ() -> void:
	_shop = ShopManager.new()
	_shop.shop_catalog = _catalog_ten_mixed()
	add_child(_shop)
	var a: PackedStringArray = _ids_sequence(_shop.get_daily_items(1))
	var b: PackedStringArray = _ids_sequence(_shop.get_daily_items(99))
	assert_bool(a != b).is_true()


func test_get_daily_items_always_has_consumable() -> void:
	_shop = ShopManager.new()
	_shop.shop_catalog = _catalog_ten_mixed()
	add_child(_shop)
	for day: int in range(10):
		var got: Array[ShopItemData] = _shop.get_daily_items(day)
		var has_consumable: bool = false
		for it: ShopItemData in got:
			if it.category == "consumable":
				has_consumable = true
				break
		assert_bool(has_consumable).is_true()


func test_get_daily_items_always_has_equipment() -> void:
	_shop = ShopManager.new()
	_shop.shop_catalog = _catalog_ten_mixed()
	add_child(_shop)
	for day: int in range(10):
		var got: Array[ShopItemData] = _shop.get_daily_items(day)
		var has_equipment: bool = false
		for it: ShopItemData in got:
			if it.category == "equipment":
				has_equipment = true
				break
		assert_bool(has_equipment).is_true()


func test_get_daily_items_excludes_capped_consumables() -> void:
	_shop = ShopManager.new()
	var cat: Array[ShopItemData] = [
		_item("test_consumable", "consumable"),
		_item("e0", "equipment"),
		_item("e1", "equipment"),
		_item("e2", "equipment"),
	]
	_shop.shop_catalog = cat
	add_child(_shop)
	_shop.add_consumable("test_consumable", 20)
	var got: Array[ShopItemData] = _shop.get_daily_items(0)
	for it: ShopItemData in got:
		assert_that(it.item_id).is_not_equal("test_consumable")


func test_get_daily_items_returns_empty_when_no_consumable() -> void:
	_shop = ShopManager.new()
	_shop.shop_catalog = [_item("e0", "equipment"), _item("e1", "equipment"), _item("e2", "equipment")]
	add_child(_shop)
	var got: Array[ShopItemData] = _shop.get_daily_items(0)
	assert_int(got.size()).is_equal(0)


func test_simbot_difficulty_targets() -> void:
	var balanced: StrategyProfile = (
		load("res://resources/strategyprofiles/strategy_balanced_default.tres") as StrategyProfile
	)
	var greedy: StrategyProfile = (
		load("res://resources/strategyprofiles/strategy_greedy_econ.tres") as StrategyProfile
	)
	var heavy: StrategyProfile = (
		load("res://resources/strategyprofiles/strategy_heavy_fire.tres") as StrategyProfile
	)
	assert_object(balanced).is_not_null()
	assert_object(greedy).is_not_null()
	assert_object(heavy).is_not_null()
	assert_float(balanced.difficulty_target).is_equal(0.5)
	assert_float(greedy.difficulty_target).is_equal(0.3)
	assert_float(heavy.difficulty_target).is_equal(0.7)
