## mini_boss_data.gd
## Campaign metadata for mini-bosses and optional defection into the ally roster.
# SOURCE: “Guest joins after boss fight” pattern (FFT-like).

extends Resource
class_name MiniBossData

@export var boss_id: String = ""
@export var display_name: String = ""
@export var appears_on_day: int = 1

@export var max_hp: int = 500 # TUNING
@export var gold_reward: int = 100 # TUNING

@export var can_defect_to_ally: bool = false
@export var defected_ally_id: String = ""
@export var defection_cost_gold: int = 0
## POST-MVP: 0 = offer injected immediately; >0 = delayed offer (not implemented).
@export var defection_day_offset: int = 0
