# scripts/shop_manager.gd
# ShopManager – owns the shop catalog and handles item purchases.
# Effects: tower_repair / building_repair immediate; mana_draught + arrow_tower_placed
# pending flags consumed by apply_mission_start_consumables() from GameManager.
# All resource spending goes through EconomyManager.
# Emits SignalBus.shop_item_purchased(item_id) on success.

class_name ShopManager
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## All purchasable items. Populated via editor with shop_catalog.tres.
@export var shop_catalog: Array[ShopItemData] = []

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _mana_draught_pending: bool = false
var _arrow_tower_shop_pending: bool = false

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Purchases the item with the given item_id.
## Checks affordability, spends resources, applies effect, emits signal.
## Returns true on success, false on any failure.
func purchase_item(item_id: String) -> bool:
	var item: ShopItemData = _find_item(item_id)
	if item == null:
		push_warning("ShopManager.purchase_item: item_id '%s' not found" % item_id)
		return false

	if not EconomyManager.can_afford(item.gold_cost, item.material_cost):
		return false

	var gold_spent: bool = EconomyManager.spend_gold(item.gold_cost)
	assert(gold_spent, "ShopManager: spend_gold failed after can_afford returned true")

	if item.material_cost > 0:
		var mat_spent: bool = EconomyManager.spend_building_material(item.material_cost)
		assert(mat_spent, "ShopManager: spend_building_material failed after can_afford returned true")

	var effect_ok: bool = _apply_effect(item_id)
	if not effect_ok:
		_refund_item(item)
		return false

	SignalBus.shop_item_purchased.emit(item_id)
	return true


## Returns all items in the shop catalog (copy, not reference).
func get_available_items() -> Array[ShopItemData]:
	return shop_catalog.duplicate()


## Returns true if the item exists and the player can currently afford it.
func can_purchase(item_id: String) -> bool:
	var item: ShopItemData = _find_item(item_id)
	if item == null:
		return false
	if not EconomyManager.can_afford(item.gold_cost, item.material_cost):
		return false
	var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	match item_id:
		"building_repair":
			if hex == null:
				return false
			return hex.has_any_damaged_building()
		"arrow_tower_placed":
			if hex == null:
				return false
			return hex.has_empty_slot() and hex.is_building_unlocked(Types.BuildingType.ARROW_TOWER)
		_:
			return true


## Returns and clears the mana draught pending flag.
## Called by GameManager at the start of a new mission.
func consume_mana_draught_pending() -> bool:
	var was_pending: bool = _mana_draught_pending
	_mana_draught_pending = false
	return was_pending


func consume_arrow_tower_pending() -> bool:
	var was_pending: bool = _arrow_tower_shop_pending
	_arrow_tower_shop_pending = false
	return was_pending


## Called by GameManager when entering COMBAT for a mission (after mission_started).
func apply_mission_start_consumables() -> void:
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	if consume_mana_draught_pending() and spell != null:
		spell.set_mana_to_full()
		SignalBus.mana_draught_consumed.emit()
	var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	if consume_arrow_tower_pending() and hex != null:
		if not hex.place_building_shop_free(Types.BuildingType.ARROW_TOWER):
			push_warning(
				"ShopManager: arrow_tower_placed voucher could not place (no slot or locked)"
			)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _refund_item(item: ShopItemData) -> void:
	EconomyManager.add_gold(item.gold_cost)
	if item.material_cost > 0:
		EconomyManager.add_building_material(item.material_cost)


func _find_item(item_id: String) -> ShopItemData:
	for item: ShopItemData in shop_catalog:
		if item.item_id == item_id:
			return item
	return null


func _apply_effect(item_id: String) -> bool:
	match item_id:
		"tower_repair":
			var tower: Node = get_node_or_null("/root/Main/Tower")
			if tower != null and tower.has_method("repair_to_full"):
				tower.repair_to_full()
			else:
				push_error("ShopManager: 'tower_repair' effect failed – Tower not found or missing repair_to_full()")
			return true

		"building_repair":
			var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
			if hex == null:
				push_error("ShopManager: building_repair — HexGrid missing")
				return false
			if not hex.repair_first_damaged_building():
				push_error("ShopManager: building_repair — no damaged building (unexpected)")
				return false
			return true

		"mana_draught":
			_mana_draught_pending = true
			return true

		"arrow_tower_placed":
			_arrow_tower_shop_pending = true
			return true

		_:
			push_warning("ShopManager._apply_effect: unknown item_id '%s'" % item_id)
			return false

