## spell_data.gd
## Data resource describing stats for a single castable spell in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name SpellData
extends Resource

## Unique string identifier for this spell. Matches spell_cast signal payload.
@export var spell_id: String = "shockwave"
## Human-readable name shown in the spell panel UI.
@export var display_name: String = "Shockwave"
## Mana consumed on cast.
@export var mana_cost: int = 50
## Seconds before this spell can be cast again.
@export var cooldown: float = 60.0
## Damage dealt to each enemy hit.
@export var damage: float = 30.0
## Effective radius in world units. Set to 100.0 for battlefield-wide shockwave.
@export var radius: float = 100.0
## Damage type applied to all targets hit.
@export var damage_type: Types.DamageType = Types.DamageType.MAGICAL
## True if this spell can affect flying enemies. Shockwave is ground-AoE so false.
@export var hits_flying: bool = false

## Slow field: movement speed multiplier applied (e.g. 0.5 = half speed).
@export var slow_speed_multiplier: float = 0.5
## Slow field: duration in seconds.
@export var slow_duration_seconds: float = 4.0
## Beam: lateral half-width in world units (enemies within this distance of the beam segment are hit).
@export var beam_lateral_half_width: float = 3.0
## Shield: duration in seconds (HP pool from `damage` is removed when duration expires).
@export var shield_duration_seconds: float = 8.0

