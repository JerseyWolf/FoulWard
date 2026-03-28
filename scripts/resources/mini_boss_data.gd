## mini_boss_data.gd
## Campaign metadata for mini-bosses and optional defection into the ally roster.
# SOURCE: “Guest joins after boss fight” pattern (FFT-like).

extends Resource
class_name MiniBossData

## Unique string identifier matching BossData.boss_id and FactionData.mini_boss_ids.
@export var boss_id: String = ""
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
## Earliest campaign day on which this mini-boss can be encountered.
@export var appears_on_day: int = 1

## Maximum hit points of this entity at base difficulty.
@export var max_hp: int = 500 # TUNING
## Gold awarded to the player when this entity is killed.
@export var gold_reward: int = 100 # TUNING

## True if defeating this mini-boss can trigger a defection offer.
@export var can_defect_to_ally: bool = false
## The ally_id added to the roster if the player recruits this mini-boss after defeat.
@export var defected_ally_id: String = ""
## Gold required to recruit this mini-boss as an ally via defection.
@export var defection_cost_gold: int = 0
## POST-MVP: 0 = offer injected immediately; >0 = delayed offer (not implemented).
@export var defection_day_offset: int = 0
