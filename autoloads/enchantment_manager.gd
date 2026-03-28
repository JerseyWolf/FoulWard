## enchantment_manager.gd
## Tracks equipped enchantments per Florence weapon and affinity stubs.
## Provides a clean API for Tower and BetweenMissionScreen to query and change state.
## SOURCE: Resources-as-stats pattern, https://forum.godotengine.org/t/resources-as-stats/107326

extends Node

# Mapping: weapon_slot (Types.WeaponSlot) -> Dictionary[String, String]
# Keys in inner dictionary: "elemental", "power"
var _equipped_enchantments: Dictionary = {}

# POST-MVP affinity tracking: weapon_slot -> affinity level / xp.
var _affinity_level: Dictionary = {}
var _affinity_xp: Dictionary = {}


func _ready() -> void:
	_reset_to_defaults_internal()


func _reset_to_defaults_internal() -> void:
	_equipped_enchantments.clear()
	_affinity_level.clear()
	_affinity_xp.clear()

	for weapon_slot_value: int in Types.WeaponSlot.values():
		var weapon_slot: Types.WeaponSlot = weapon_slot_value as Types.WeaponSlot
		_equipped_enchantments[weapon_slot] = {
			"elemental": "",
			"power": "",
		}
		_affinity_level[weapon_slot] = 0  # POST-MVP
		_affinity_xp[weapon_slot] = 0.0  # POST-MVP


## Resets all state to default values, clearing any runtime data.
func reset_to_defaults() -> void:
	# Called from GameManager.start_new_game to clear campaign-state.
	_reset_to_defaults_internal()


## Returns the enchantment ID in the given weapon slot and slot type, or empty string if none.
func get_equipped_enchantment_id(weapon_slot: Types.WeaponSlot, slot_type: String) -> String:
	if not _equipped_enchantments.has(weapon_slot):
		return ""
	var slots: Dictionary = _equipped_enchantments[weapon_slot]
	if not slots.has(slot_type):
		return ""
	return slots[slot_type] as String


## Returns the EnchantmentData resource in the given weapon/slot pair, or null if none.
func get_equipped_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> EnchantmentData:
	var enchantment_id: String = get_equipped_enchantment_id(weapon_slot, slot_type)
	if enchantment_id == "":
		return null

	# ASSUMPTION: Enchantment resources live under res://resources/enchantments/.
	var path: String = "res://resources/enchantments/%s.tres" % enchantment_id
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = ResourceLoader.load(path)
	if not (resource is EnchantmentData):
		return null
	return resource as EnchantmentData


## Returns a Dictionary of slot_type → EnchantmentData for all equipped enchantments on a weapon.
func get_all_equipped_enchantments_for_weapon(weapon_slot: Types.WeaponSlot) -> Dictionary:
	if not _equipped_enchantments.has(weapon_slot):
		return {}
	return (_equipped_enchantments[weapon_slot] as Dictionary).duplicate(true)


## Attempts to equip an enchantment; spends gold via EconomyManager and emits enchantment_applied.
func try_apply_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String, gold_cost: int) -> bool:
	var eff_gold: int = gold_cost
	if gold_cost > 0:
		eff_gold = int(
			ceilf(float(gold_cost) * GameManager.get_aggregate_enchanting_cost_multiplier())
		)
		if eff_gold < 1:
			eff_gold = 1
		if not EconomyManager.can_afford(eff_gold, 0):
			return false
		var spent: bool = EconomyManager.spend_gold(eff_gold)
		if not spent:
			return false

	if not _equipped_enchantments.has(weapon_slot):
		_equipped_enchantments[weapon_slot] = {
			"elemental": "",
			"power": "",
		}

	var slots: Dictionary = _equipped_enchantments[weapon_slot]
	slots[slot_type] = enchantment_id
	_equipped_enchantments[weapon_slot] = slots

	SignalBus.enchantment_applied.emit(weapon_slot, slot_type, enchantment_id)
	return true


## Removes the enchantment from the given weapon/slot pair and emits enchantment_removed.
func remove_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> void:
	if not _equipped_enchantments.has(weapon_slot):
		return

	var slots: Dictionary = _equipped_enchantments[weapon_slot]
	if not slots.has(slot_type):
		return
	if (slots[slot_type] as String) == "":
		return

	slots[slot_type] = ""
	_equipped_enchantments[weapon_slot] = slots
	SignalBus.enchantment_removed.emit(weapon_slot, slot_type)


## Returns the current affinity level (inert XP tier) for the given weapon slot.
func get_affinity_level(weapon_slot: Types.WeaponSlot) -> int:
	if not _affinity_level.has(weapon_slot):
		return 0
	return _affinity_level[weapon_slot] as int


## Returns the raw accumulated affinity XP for the given weapon slot.
func get_affinity_xp(weapon_slot: Types.WeaponSlot) -> float:
	if not _affinity_xp.has(weapon_slot):
		return 0.0
	return _affinity_xp[weapon_slot] as float


## Adds affinity XP to the given weapon slot (inert; no gameplay effect yet).
func gain_affinity_xp(weapon_slot: Types.WeaponSlot, amount: float) -> void:
	# POST-MVP: Currently inert except for tracking numbers.
	if amount <= 0.0:
		return
	if not _affinity_xp.has(weapon_slot):
		_affinity_xp[weapon_slot] = 0.0
	_affinity_xp[weapon_slot] = (_affinity_xp[weapon_slot] as float) + amount


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	var flat: Dictionary = {}
	for weapon_slot_value: int in Types.WeaponSlot.values():
		var weapon_slot: Types.WeaponSlot = weapon_slot_value as Types.WeaponSlot
		var slots: Dictionary = _equipped_enchantments.get(weapon_slot, {
			"elemental": "",
			"power": "",
		})
		for st: String in ["elemental", "power"]:
			var key: String = "%d_%s" % [int(weapon_slot), st]
			flat[key] = str(slots.get(st, ""))
	return {"enchantments_by_slot": flat}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	_reset_to_defaults_internal()
	var raw: Variant = data.get("enchantments_by_slot", {})
	if raw is not Dictionary:
		return
	var flat: Dictionary = raw as Dictionary
	for k: Variant in flat.keys():
		var ks: String = str(k)
		var sep: int = ks.find("_")
		if sep < 1:
			continue
		var slot_num: int = int(ks.left(sep))
		var st: String = ks.substr(sep + 1)
		var slot_enum: Types.WeaponSlot = slot_num as Types.WeaponSlot
		if not _equipped_enchantments.has(slot_enum):
			continue
		var slots: Dictionary = _equipped_enchantments[slot_enum]
		slots[st] = str(flat[k])
		_equipped_enchantments[slot_enum] = slots
