## weapon_upgrade_manager.gd
## Manages weapon level progression for Florence's Tower weapons.
## Tracks current upgrade level per weapon slot (0 = base, 1-3 = upgraded).
## Provides effective stat accessors that compose base WeaponData values
## with additive incremental level bonuses from WeaponLevelData resources.
##
## Lives at: /root/Main/Managers/WeaponUpgradeManager
## NOT an autoload — scene-bound manager consistent with WaveManager, ShopManager, etc.
##
## Simulation API: all public methods callable without UI nodes present.
## Tower references this manager via get_node_or_null and falls back to raw
## WeaponData when manager is absent, preserving all existing Tower tests.
##
# SOURCE: Composition-based stat system pattern — https://www.reddit.com/r/godot/comments/1fu9gcc/stats_resources_for_a_compositionbased_weapon/ [S4]
# SOURCE: Scene-bound manager pattern — consistent with existing ResearchManager, ShopManager in this codebase

class_name WeaponUpgradeManager
extends Node

const MAX_LEVEL: int = 3

## Array of WeaponLevelData resources for the crossbow, one per upgrade level (3 entries).
## Index 0 = level 1 data, index 1 = level 2 data, index 2 = level 3 data.
@export var crossbow_levels: Array[WeaponLevelData] = []

## Array of WeaponLevelData resources for the rapid missile, one per upgrade level (3 entries).
## Index 0 = level 1 data, index 1 = level 2 data, index 2 = level 3 data.
@export var rapid_missile_levels: Array[WeaponLevelData] = []

## Base WeaponData resource for the crossbow. Used as the additive base for all stat lookups.
@export var crossbow_base_data: WeaponData = null

## Base WeaponData resource for the rapid missile. Used as the additive base for all stat lookups.
@export var rapid_missile_base_data: WeaponData = null

var _crossbow_current_level: int = 0
var _rapid_missile_current_level: int = 0

## Connects to game-state signal for future extension.
func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)


## Returns whether the game state change is relevant (reserved for future HUD reactivity).
func _on_game_state_changed(_old: Types.GameState, _new: Types.GameState) -> void:
	pass  # Reserved for future use


## Attempts to upgrade the specified weapon by one level.
## Returns true on success, false if already at max level or gold is insufficient.
## Spends gold via EconomyManager.spend_gold(). Emits SignalBus.weapon_upgraded on success.
func upgrade_weapon(weapon_slot: Types.WeaponSlot) -> bool:
	var current_level: int = get_current_level(weapon_slot)
	if current_level >= MAX_LEVEL:
		return false
	var level_data_array: Array[WeaponLevelData] = _get_level_array(weapon_slot)
	if current_level >= level_data_array.size():
		push_error("WeaponUpgradeManager.upgrade_weapon: missing level data for slot %d level %d" % [weapon_slot, current_level + 1])
		return false
	var level_data: WeaponLevelData = level_data_array[current_level]
	if level_data == null:
		push_error("WeaponUpgradeManager.upgrade_weapon: level_data is null for slot %d level %d" % [weapon_slot, current_level + 1])
		return false
	var eff_gold: int = int(
		ceilf(float(level_data.gold_cost) * GameManager.get_aggregate_weapon_upgrade_cost_multiplier())
	)
	if eff_gold < 0:
		eff_gold = 0
	if not EconomyManager.can_afford(eff_gold, level_data.material_cost):
		return false
	if eff_gold > 0:
		var spent_gold: bool = EconomyManager.spend_gold(eff_gold)
		if not spent_gold:
			push_warning("WeaponUpgradeManager: insufficient gold for upgrade")
			return false
	if level_data.material_cost > 0:
		var spent_material: bool = EconomyManager.spend_building_material(level_data.material_cost)
		if not spent_material:
			push_warning("WeaponUpgradeManager: insufficient building material for upgrade")
			return false
	_set_current_level(weapon_slot, current_level + 1)
	SignalBus.weapon_upgraded.emit(weapon_slot, get_current_level(weapon_slot))
	return true


## Returns the current upgrade level for the specified weapon slot (0 = base, 1-3 = upgraded).
func get_current_level(weapon_slot: Types.WeaponSlot) -> int:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			return _crossbow_current_level
		Types.WeaponSlot.RAPID_MISSILE:
			return _rapid_missile_current_level
	push_error("WeaponUpgradeManager.get_current_level: unknown weapon_slot %d" % weapon_slot)
	return 0


## Returns the maximum upgrade level constant (3).
func get_max_level() -> int:
	return MAX_LEVEL


## Returns the effective damage for the given weapon slot at its current level.
## Computed as base_data.damage + SUM of all damage_bonus values from levels 1..current_level.
## Falls back to base damage when level is 0 or base_data is null.
func get_effective_damage(weapon_slot: Types.WeaponSlot) -> float:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0.0
	return base.damage + _get_cumulative_bonus(weapon_slot, "damage_bonus")


## Returns the effective projectile speed for the given weapon slot at its current level.
## Computed as base_data.projectile_speed + SUM of speed_bonus values from levels 1..current_level.
func get_effective_speed(weapon_slot: Types.WeaponSlot) -> float:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0.0
	return base.projectile_speed + _get_cumulative_bonus(weapon_slot, "speed_bonus")


## Returns the effective reload time for the given weapon slot at its current level.
## Computed as base_data.reload_time + SUM of reload_bonus values from levels 1..current_level.
## Note: reload_bonus values are negative to improve (reduce) reload time.
## Clamped to a minimum of 0.1 seconds to prevent zero or negative reload.
func get_effective_reload_time(weapon_slot: Types.WeaponSlot) -> float:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0.1
	var result: float = base.reload_time + _get_cumulative_bonus(weapon_slot, "reload_bonus")
	return maxf(result, 0.1)


## Returns the effective burst count for the given weapon slot at its current level.
## Computed as base_data.burst_count + SUM of burst_count_bonus values from levels 1..current_level.
func get_effective_burst_count(weapon_slot: Types.WeaponSlot) -> int:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0
	return base.burst_count + int(_get_cumulative_bonus(weapon_slot, "burst_count_bonus"))


## Extra enemies a projectile may hit after the first (piercing).
func get_effective_pierce_count(weapon_slot: Types.WeaponSlot) -> int:
	return int(_get_cumulative_bonus(weapon_slot, "pierce_count_bonus"))


## Parallel projectiles per attack (minimum 1). Base is 1 + cumulative projectile_count_bonus.
func get_effective_projectile_count(weapon_slot: Types.WeaponSlot) -> int:
	var base: int = 1 + int(_get_cumulative_bonus(weapon_slot, "projectile_count_bonus"))
	return maxi(1, base)


## Total fan spread in degrees (split across projectile_count when count exceeds 1).
func get_effective_spread_angle_degrees(weapon_slot: Types.WeaponSlot) -> float:
	return maxf(0.0, _get_cumulative_bonus(weapon_slot, "spread_angle_degrees_bonus"))


## Splash radius from weapon levels (0 = off).
func get_effective_splash_radius(weapon_slot: Types.WeaponSlot) -> float:
	return maxf(0.0, _get_cumulative_bonus(weapon_slot, "splash_radius_bonus"))


## Returns the WeaponLevelData for the next upgrade level, or null if already at max level.
## Useful for UI preview of upcoming stat changes.
func get_next_level_data(weapon_slot: Types.WeaponSlot) -> WeaponLevelData:
	var current_level: int = get_current_level(weapon_slot)
	if current_level >= MAX_LEVEL:
		return null
	return get_level_data(weapon_slot, current_level + 1)


## Returns the WeaponLevelData for a specific level (1-3), or null if invalid.
## Level 0 has no WeaponLevelData (implicit base — returns null by design).
func get_level_data(weapon_slot: Types.WeaponSlot, level: int) -> WeaponLevelData:
	if level < 1 or level > MAX_LEVEL:
		return null
	var arr: Array[WeaponLevelData] = _get_level_array(weapon_slot)
	var index: int = level - 1
	if index >= arr.size():
		return null
	return arr[index]


## Resets both weapon levels to 0 (base stats). Called by GameManager.start_new_game().
## POST-MVP: Save/load weapon levels to disk for persistent campaign progress.
func reset_to_defaults() -> void:
	_crossbow_current_level = 0
	_rapid_missile_current_level = 0
	# POST-MVP: Campaign save/load for weapon levels


## Returns the configured base WeaponData for the slot.
func _get_base_data(weapon_slot: Types.WeaponSlot) -> WeaponData:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_base_data
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_base_data
	return null


## Returns the configured level data array for the slot.
func _get_level_array(weapon_slot: Types.WeaponSlot) -> Array[WeaponLevelData]:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_levels
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_levels
	return []


## Updates the current level for the specified slot.
func _set_current_level(weapon_slot: Types.WeaponSlot, new_level: int) -> void:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			_crossbow_current_level = new_level
		Types.WeaponSlot.RAPID_MISSILE:
			_rapid_missile_current_level = new_level


## Sums the named float field across all WeaponLevelData entries from level 1
## up to and including the weapon's current level. Returns 0.0 if level is 0.
## Uses get() for dynamic field access on Resource objects.
## burst_count_bonus is an int field but returned as float for uniform summation;
## callers cast back to int where needed.
# SOURCE: Dynamic property access via .get() on Resource — Godot 4 docs [S1]
func _get_cumulative_bonus(weapon_slot: Types.WeaponSlot, field: String) -> float:
	var current_level: int = get_current_level(weapon_slot)
	if current_level == 0:
		return 0.0
	var arr: Array[WeaponLevelData] = _get_level_array(weapon_slot)
	var total: float = 0.0
	for i: int in range(current_level):
		if i < arr.size() and arr[i] != null:
			total += float(arr[i].get(field))
	return total
