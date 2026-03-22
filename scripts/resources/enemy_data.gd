## enemy_data.gd
## Data resource describing stats for a single enemy type in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name EnemyData
extends Resource

## Which enemy type this resource describes.
@export var enemy_type: Types.EnemyType
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
## Maximum hit points.
@export var max_hp: int = 100
## Movement speed in units per second.
@export var move_speed: float = 3.0
## Damage dealt per attack.
@export var damage: int = 10
## Melee engagement range for melee types; projectile fire range for ranged types.
@export var attack_range: float = 1.5
## Seconds between attacks.
@export var attack_cooldown: float = 1.0
## Armor type used for damage matrix lookups in DamageCalculator.
@export var armor_type: Types.ArmorType = Types.ArmorType.UNARMORED
## Gold awarded to the player on kill; passed directly in enemy_killed signal.
@export var gold_reward: int = 10
## True if this enemy fires projectiles rather than melee-attacking.
@export var is_ranged: bool = false
## True if this enemy flies (ignores ground-only buildings; Y offset applied).
@export var is_flying: bool = false
## MVP cube color for this enemy type.
@export var color: Color = Color.GREEN
## Per-enemy damage-type immunities checked before the matrix lookup.
## Per SYSTEMS_part1 §3.8: these override the DAMAGE_MATRIX result.
@export var damage_immunities: Array[Types.DamageType] = []

