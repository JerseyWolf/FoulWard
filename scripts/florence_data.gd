## florence_data.gd
## FlorenceData — data-only resource storing Florence meta-state for a single run.
## No Node references; safe to use in headless GdUnit tests.
##
## SOURCE: Roguelike meta-progression design pattern (Hades meta-state approach).
## Pattern: keep run/campaign meta-state in a dedicated Resource owned by managers.

class_name FlorenceData
extends Resource

## Technical label for the meta-state namespace used by dialogue conditions.
@export var florence_id: String = "florence"

## Display name for UI/placeholder debug text.
@export var display_name: String = "Florence"

## Total days advanced in the current run (meta progression, not world time).
## ASSUMPTION: This tracks days in the current run; cross-run tracking can be added later.
@export var total_days_played: int = 0

## Number of full campaign completions (run counter).
## ASSUMPTION: Increment on full campaign completion (`GAME_WON`), not on new game start.
@export var run_count: int = 0

## Total missions resolved (win or failure) in the current run.
## Increments once per mission resolution.
@export var total_missions_played: int = 0

## How many boss encounter attempts happened in the current run.
@export var boss_attempts: int = 0

## How many boss encounter victories happened in the current run.
@export var boss_victories: int = 0

## How many missions failed in the current run.
@export var mission_failures: int = 0

## Flags — technical progression toggles.
@export var has_unlocked_research: bool = false
## POST-MVP: Enchantments unlock hook.
@export var has_unlocked_enchantments: bool = false
## POST-MVP: Mercenary recruitment hook.
@export var has_recruited_any_mercenary: bool = false
## POST-MVP: Mini-boss seen hook.
@export var has_seen_any_mini_boss: bool = false
## POST-MVP: Mini-boss defeated hook.
@export var has_defeated_any_mini_boss: bool = false
## TUNING: Day 25 milestone.
@export var has_reached_day_25: bool = false
## TUNING: Day 50 milestone.
@export var has_reached_day_50: bool = false
## POST-MVP: First boss seen hook.
@export var has_seen_first_boss: bool = false

const TUNING_DAY_25: int = 25
const TUNING_DAY_50: int = 50

## Resets all per-run counters and flags to their initial values.
func reset_for_new_run() -> void:
	# FlorenceData represents run meta-state, so we reset run-scoped counters/flags.
	total_days_played = 0
	total_missions_played = 0
	boss_attempts = 0
	boss_victories = 0
	mission_failures = 0

	has_unlocked_research = false
	has_unlocked_enchantments = false
	has_recruited_any_mercenary = false
	has_seen_any_mini_boss = false
	has_defeated_any_mini_boss = false
	has_reached_day_25 = false
	has_reached_day_50 = false
	has_seen_first_boss = false
	# Note: run_count intentionally persists across runs (GameManager increments on GAME_WON).


## Updates day-threshold boolean flags (early/mid/late game) based on current_day.
func update_day_threshold_flags(current_day: int) -> void:
	# TUNING: Flags reflect whether the meta campaign timeline has reached milestones.
	has_reached_day_25 = current_day >= TUNING_DAY_25
	has_reached_day_50 = current_day >= TUNING_DAY_50

