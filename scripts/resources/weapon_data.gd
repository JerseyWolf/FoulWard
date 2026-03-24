## weapon_data.gd
## Data resource describing stats for one of Florence's two weapons in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name WeaponData
extends Resource

## Which weapon slot this resource configures.
@export var weapon_slot: Types.WeaponSlot
## Human-readable name shown in the weapon panel UI.
@export var display_name: String = ""
## Damage dealt per projectile.
@export var damage: float = 50.0
## Projectile travel speed in units per second.
@export var projectile_speed: float = 30.0
## Seconds between shots (for crossbow) or between bursts (for rapid missile).
@export var reload_time: float = 2.5
## Projectiles fired per trigger pull. 1 for crossbow, 10 for rapid missile.
@export var burst_count: int = 1
## Seconds between individual shots within a burst. 0.0 for single-shot weapons.
@export var burst_interval: float = 0.0
## True if this weapon can target flying enemies. Always false for Florence in MVP.
@export var can_target_flying: bool = false
# ASSUMPTION: These fields are designer-tunable; setting them to 0.0 disables assist/miss
# and restores MVP-accurate behavior. Balance changes should be done via .tres resources, not code.
@export var assist_angle_degrees: float = 0.0
@export var assist_max_distance: float = 0.0
@export var base_miss_chance: float = 0.0
@export var max_miss_angle_degrees: float = 0.0

