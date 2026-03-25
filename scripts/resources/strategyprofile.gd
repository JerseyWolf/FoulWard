## strategyprofile.gd
## PRE_GENERATION_VERIFICATION: Mentally ran the required checklist for this file
## (Resource-only, no scene access, typed exported fields, no autoload impacts).
##
## StrategyProfile drives SimBot's build, upgrade, and spell decisions.
## POST-MVP: Extended for NEAT/ML tuning and endless-mode targets.
extends Resource
class_name StrategyProfile

## Unique ID for this profile, used for lookup and logging.
@export var profile_id: String = ""

## Human-readable description of the strategy.
## PLACEHOLDER: Fill with detailed design notes after tuning.
@export var description: String = ""

## Per-building weighted preferences.
## Each entry is a Dictionary with keys:
## - "building_type": Types.BuildingType (stored as int in .tres; cast in SimBot)
## - "weight": float
## - "min_wave": int (inclusive, default 1)
## - "max_wave": int (inclusive, default 10)
@export var build_priorities: Array[Dictionary] = []

## Placement preferences for new buildings.
## Keys:
## - "preferred_slots": Array[int] ordered list of slot indices to try first.
## - "fallback_strategy": String, "FIRST_EMPTY" or "RANDOM_EMPTY".
## - "ring_hint": String, e.g. "ANY", "INNER_FIRST", "OUTER_FIRST".
@export var placement_preferences: Dictionary = {
	"preferred_slots": [],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "ANY",
}

## Spell usage configuration for SimBot.
## MVP supports only "shockwave".
## Keys:
## - "enabled": bool
## - "spell_id": String
## - "min_enemies_in_wave": int
## - "min_mana": int
## - "cooldown_safety_margin": float
## - "evaluation_interval": float (seconds between checks)
## - "priority_vs_building": float (TUNING: used to break ties vs building actions)
@export var spell_usage: Dictionary = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 6,
	"min_mana": 50,
	"cooldown_safety_margin": 0.5,
	"evaluation_interval": 1.0,
	"priority_vs_building": 1.0,
}

## Upgrade behavior configuration.
## Keys:
## - "prefer_upgrades_until_build_count": int
## - "upgrade_weight": float
## - "min_gold_reserve": int
## - "max_upgrade_level": int (MVP buildings have 1 upgrade level)
@export var upgrade_behavior: Dictionary = {
	"prefer_upgrades_until_build_count": 6,
	"upgrade_weight": 1.0,
	"min_gold_reserve": 0,
	"max_upgrade_level": 1,
}

## Target difficulty score for future tuning.
## POST-MVP: used by optimization tools to compare desired vs actual difficulty.
@export var difficulty_target: float = 0.0

