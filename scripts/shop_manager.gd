# scripts/shop_manager.gd
# ShopManager – owns the shop catalog and handles item purchases.
# Effects are applied immediately: tower_repair calls Tower.repair_to_full(),
# mana_draught sets a pending flag consumed by GameManager at mission start.
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

## POST-MVP: GameManager should read this flag at mission start and call
## SpellManager.set_mana_to_full(). Currently a simple flag on this node.
var _mana_draught_pending: bool = false

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

	_apply_effect(item_id)

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
	return EconomyManager.can_afford(item.gold_cost, item.material_cost)


## Returns and clears the mana draught pending flag.
## Called by GameManager at the start of a new mission.
func consume_mana_draught_pending() -> bool:
	var was_pending: bool = _mana_draught_pending
	_mana_draught_pending = false
	return was_pending

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _find_item(item_id: String) -> ShopItemData:
	for item: ShopItemData in shop_catalog:
		if item.item_id == item_id:
			return item
	return null


func _apply_effect(item_id: String) -> void:
	match item_id:
		"tower_repair":
			# ASSUMPTION: Tower node at /root/Main/Tower with public repair_to_full().
			var tower: Node = get_node_or_null("/root/Main/Tower")
			if tower != null and tower.has_method("repair_to_full"):
				tower.repair_to_full()
			else:
				push_error("ShopManager: 'tower_repair' effect failed – Tower not found or missing repair_to_full()")

		"mana_draught":
			# POST-MVP: cleaner approach would use a direct signal.
			_mana_draught_pending = true

		_:
			push_warning("ShopManager._apply_effect: unknown item_id '%s'" % item_id)

