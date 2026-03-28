## ShopManager — Owns the shop catalog and handles item purchases; consumables apply on mission start.
# scripts/shop_manager.gd
# ShopManager – owns the shop catalog and handles item purchases.
# Effects: tower_repair / building_repair immediate; consumables stack (cap 20) and apply on mission_started.
# Arrow tower voucher uses a pending flag consumed by apply_mission_start_consumables() from GameManager.
# All resource spending goes through EconomyManager.
# Emits SignalBus.shop_item_purchased(item_id) on success.

class_name ShopManager
extends Node

const CONSUMABLE_STACK_CAP: int = 20

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## All purchasable items. Populated via editor with shop_catalog.tres.
@export var shop_catalog: Array[ShopItemData] = []

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _consumable_stacks: Dictionary = {} ## String -> int
var _arrow_tower_shop_pending: bool = false

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------

func _ready() -> void:
	if not SignalBus.mission_started.is_connected(_on_mission_started):
		SignalBus.mission_started.connect(_on_mission_started)


func _exit_tree() -> void:
	if SignalBus.mission_started.is_connected(_on_mission_started):
		SignalBus.mission_started.disconnect(_on_mission_started)


# ---------------------------------------------------------------------------
# Public API — consumable stacks
# ---------------------------------------------------------------------------

## Adds the given amount of the item_id consumable to the stack (capped at 20).
func add_consumable(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var cur: int = int(_consumable_stacks.get(item_id, 0))
	_consumable_stacks[item_id] = mini(cur + amount, CONSUMABLE_STACK_CAP)


## Decrements one unit of the item_id consumable; returns false if stack is empty.
func consume(item_id: String) -> bool:
	var cur: int = int(_consumable_stacks.get(item_id, 0))
	if cur <= 0:
		return false
	var next: int = cur - 1
	if next <= 0:
		_consumable_stacks.erase(item_id)
	else:
		_consumable_stacks[item_id] = next
	return true


## Returns the current stack count for the given item_id consumable.
func get_stack_count(item_id: String) -> int:
	return int(_consumable_stacks.get(item_id, 0))


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	return {"consumable_stacks": _consumable_stacks.duplicate(true)}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	_consumable_stacks.clear()
	var raw: Variant = data.get("consumable_stacks", {})
	if raw is Dictionary:
		var d: Dictionary = raw
		for k: Variant in d.keys():
			if k is String:
				var v: Variant = d[k]
				if v is int:
					var n: int = clampi(v, 0, CONSUMABLE_STACK_CAP)
					if n > 0:
						_consumable_stacks[k] = n


# ---------------------------------------------------------------------------
# Public API — shop
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
	if not gold_spent:
		push_warning("ShopManager: spend_gold failed after can_afford returned true")
		return false

	if item.material_cost > 0:
		var mat_spent: bool = EconomyManager.spend_building_material(item.material_cost)
		if not mat_spent:
			push_warning("ShopManager: spend_building_material failed after can_afford returned true")
			return false

	var effect_ok: bool = _apply_effect(item_id)
	if not effect_ok:
		_refund_item(item)
		return false

	# POST-MVP: Enchantments unlock hook into FlorenceData.
	# PLACEHOLDER: replace this item_id with the real enchantments unlock item.
	if item_id == "enchantments_unlock":
		var florence_data := GameManager.get_florence_data()
		if florence_data != null and florence_data.has_unlocked_enchantments == false:
			florence_data.has_unlocked_enchantments = true
			SignalBus.florence_state_changed.emit()

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
			return hex.has_empty_slot() and hex.is_building_available(Types.BuildingType.ARROW_TOWER)
		_:
			return true


## Consumes the pending arrow-tower voucher flag; returns true if it was set.
func consume_arrow_tower_pending() -> bool:
	var was_pending: bool = _arrow_tower_shop_pending
	_arrow_tower_shop_pending = false
	return was_pending


## Called by GameManager when entering COMBAT for a mission (after mission_started).
## Applies non-consumable mission-start effects (arrow tower voucher).
func apply_mission_start_consumables() -> void:
	var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	if consume_arrow_tower_pending() and hex != null:
		if not hex.place_building_shop_free(Types.BuildingType.ARROW_TOWER):
			push_warning(
				"ShopManager: arrow_tower_placed voucher could not place (no slot or locked)"
			)


# ---------------------------------------------------------------------------
# Mission start — consumables (stacked)
# ---------------------------------------------------------------------------

func _on_mission_started(_mission_number: int) -> void:
	var to_process: Array[String] = []
	for k: Variant in _consumable_stacks.keys():
		if k is String and int(_consumable_stacks[k]) > 0:
			to_process.append(k)
	for item_id: String in to_process:
		if get_stack_count(item_id) <= 0:
			continue
		_apply_consumable_effect(item_id)
		consume(item_id)


func _apply_consumable_effect(item_id: String) -> void:
	var item_data: ShopItemData = _find_item(item_id)
	if item_data == null:
		push_warning("ShopManager._apply_consumable_effect: no ShopItemData for '%s'" % item_id)
		return
	for tag: String in item_data.effect_tags:
		match tag:
			"mana_restore":
				var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
				if spell != null:
					spell.restore_mana(item_data.value)
					SignalBus.mana_draught_consumed.emit()
			"gold_bonus":
				EconomyManager.add_gold(item_data.value)
			"shield":
				var tower: Node = get_node_or_null("/root/Main/Tower")
				if tower != null and tower.has_method("add_spell_shield"):
					var dur: float = item_data.duration
					if dur <= 0.0:
						dur = 1.0
					tower.add_spell_shield(float(item_data.value), dur)
			_:
				push_warning("ShopManager._apply_consumable_effect: unknown effect tag '%s'" % tag)


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
			add_consumable("mana_draught", 1)
			var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
			if spell != null:
				spell.set_mana_to_full()
			return true

		"arrow_tower_placed":
			_arrow_tower_shop_pending = true
			return true

		_:
			push_warning("ShopManager._apply_effect: unknown item_id '%s'" % item_id)
			return false
