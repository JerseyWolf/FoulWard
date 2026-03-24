## faction_roster_entry.gd
## One row in a FactionData roster. Kept as its own Resource so .tres files can embed entries.
## DEVIATION: Prompt 9 sketched a nested class inside FactionData; Godot sub-resources need a script path.

class_name FactionRosterEntry
extends Resource

## Enemy type enum for this roster entry.
@export var enemy_type: Types.EnemyType = Types.EnemyType.ORC_GRUNT
## Baseline spawn weight for this enemy within its wave range.
@export var base_weight: float = 1.0
## Earliest wave index where this enemy can appear (inclusive).
@export var min_wave_index: int = 1
## Last wave index where this enemy can appear (inclusive).
@export var max_wave_index: int = 10
## Optional tier marker: 1 basic, 2 elite, 3 special.
@export var tier: int = 1
