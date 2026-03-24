## faction_data.gd
## Faction identity, weighted enemy roster, mini-boss hooks, and scaling hints for WaveManager.

class_name FactionData
extends Resource

## Preload so this script parses before `FactionRosterEntry` class_name is globally registered.
const FactionRosterEntryType = preload("res://scripts/resources/faction_roster_entry.gd")

## Built-in faction .tres files loaded by WaveManager and CampaignManager.
## POST-MVP: replace with directory scan or campaign bundle.
const BUILTIN_FACTION_RESOURCE_PATHS: Array[String] = [
	"res://resources/faction_data_default_mixed.tres",
	"res://resources/faction_data_orc_raiders.tres",
	"res://resources/faction_data_plague_cult.tres",
]

# Identity -------------------------------------------------------------

## Unique stable ID used by DayConfig and TerritoryData.
@export var faction_id: String = ""

## Human-readable name for UI and debug logs.
@export var display_name: String = ""

## Text description for codex / faction summary.
## PLACEHOLDER until narrative pass fills this in.
@export var description: String = ""

# Roster ---------------------------------------------------------------

## Roster entries for this faction. Defines which enemy types can spawn,
## how common they are, and in which wave index range they appear.
@export var roster: Array[FactionRosterEntryType] = []

# Mini-boss hooks ------------------------------------------------------

## IDs of mini-bosses associated with this faction.
## PLACEHOLDER mini-boss resources will be defined in a later prompt.
@export var mini_boss_ids: Array[String] = []

## Recommended wave indices for mini-boss appearances.
## POST-MVP: Used by future boss spawning logic.
@export var mini_boss_wave_hints: Array[int] = []

# Scaling hints --------------------------------------------------------

## Coarse difficulty tier knob for the faction. 1 easy, 2 mid, 3 late-game.
@export var roster_tier: int = 1

## Optional offset used by wave formulas to nudge difficulty up/down.
## TUNING: Values will be adjusted in future balance passes.
@export var difficulty_offset: float = 0.0

# Helper methods -------------------------------------------------------

## Returns roster entries valid for the given wave index based on min/max bounds.
func get_entries_for_wave(wave_index: int) -> Array[FactionRosterEntryType]:
	var result: Array[FactionRosterEntryType] = []
	for entry: FactionRosterEntryType in roster:
		if wave_index >= entry.min_wave_index and wave_index <= entry.max_wave_index:
			result.append(entry)
	return result


## Computes effective weight for a roster entry at a given wave.
## Early waves favor tier 1 units; tier >1 ramp up later.
func get_effective_weight_for_wave(entry: FactionRosterEntryType, wave_index: int) -> float:
	if entry.base_weight <= 0.0:
		return 0.0

	var weight: float = entry.base_weight

	# SOURCE: Weighted enemy roster scaling by wave and tier, common TD pattern.
	# Simple tier-based ramp: elites gain weight as wave index grows.
	if entry.tier > 1:
		var ramp: float = float(wave_index - entry.min_wave_index)
		if ramp < 0.0:
			ramp = 0.0
		weight *= (1.0 + ramp * 0.1) # TUNING

	# Optionally nudge with faction difficulty offset.
	if difficulty_offset != 0.0:
		weight *= maxf(0.1, 1.0 + difficulty_offset) # TUNING

	return maxf(weight, 0.0)
