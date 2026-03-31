## wave_pattern_data.gd
## Per-campaign wave curve: point budgets, primary tags per wave, and optional modifiers.

class_name WavePatternData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var base_point_budget: int = 40
@export var budget_per_wave: int = 8
@export var max_waves: int = 30

## Each wave has a primary tag, e.g. "RUSH", "HEAVY", "AIRSTRIKE", "INVASION", "SUPPORT", or "MIXED".
@export var wave_primary_tags: Array[String] = []

## Optional per-wave modifiers per wave; each entry is an [Array] of strings (nested typed arrays are not supported in GDScript exports).
@export var wave_modifiers: Array = []
