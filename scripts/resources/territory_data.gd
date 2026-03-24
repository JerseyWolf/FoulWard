## territory_data.gd
## Per-territory data: ownership, terrain, and economic bonuses for campaign/world map.
## SOURCE: FOUL WARD Prompt 8 spec — territory ownership hooks for 50-day campaign.

class_name TerritoryData
extends Resource

## Unique ID for this territory, used by DayConfig. Must be unique within a campaign.
@export var territory_id: String = ""

## Display name shown in UI.
@export var display_name: String = ""

## Long-form description for world map and briefing.
@export var description: String = ""

## For now just a string; later can map to real icons.
@export var icon_id: String = ""

## Base color tint for UI elements representing this territory.
@export var color: Color = Color.WHITE

## Terrain categories for territories (CONVENTIONS: enum type PascalCase, members UPPER_SNAKE_CASE).
enum TerrainType {
	PLAINS,
	FOREST,
	SWAMP,
	MOUNTAIN,
	CITY,
	OTHER,
}

## Terrain category for this territory.
@export var terrain_type: int = TerrainType.PLAINS

## Whether the player currently holds this territory.
@export var is_controlled_by_player: bool = false

## If true, territory is lost for the campaign (MVP: set on mission fail).
@export var is_permanently_lost: bool = false

## Narrative/tuning hook for threat display.
@export var threat_level: int = 0

## Whether the territory is under attack (POST-MVP UI).
@export var is_under_attack: bool = false

## Flat gold added at end of mission/day reward when active.
@export var bonus_flat_gold_end_of_day: int = 0

## Additive fraction applied to gold after flat (e.g. 0.1 = +10%).
@export var bonus_percent_gold_end_of_day: float = 0.0

## POST-MVP: per-kill flat bonus from holding this territory.
@export var bonus_flat_gold_per_kill: int = 0

## POST-MVP: extra research material per day while held.
@export var bonus_research_per_day: int = 0

## POST-MVP: multiplier on research costs (1.0 = no change).
@export var bonus_research_cost_multiplier: float = 1.0

## POST-MVP: multiplier on enchanting gold costs.
@export var bonus_enchanting_cost_multiplier: float = 1.0

## POST-MVP: multiplier on weapon upgrade gold costs.
@export var bonus_weapon_upgrade_cost_multiplier: float = 1.0


## Returns true if this territory should currently contribute bonuses.
## MVP: controlled and not permanently lost.
func is_active_for_bonuses() -> bool:
	return is_controlled_by_player and not is_permanently_lost


func get_effective_end_of_day_gold_flat() -> int:
	if not is_active_for_bonuses():
		return 0
	return bonus_flat_gold_end_of_day


func get_effective_end_of_day_gold_percent() -> float:
	if not is_active_for_bonuses():
		return 0.0
	return bonus_percent_gold_end_of_day
