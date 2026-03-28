## ally_data.gd
## Data backbone for generic allies, mercenary UI, and future defected mini-boss allies.
## ASSUMPTION: A future BossData resource will share basic fields (HP, movement speed, damage, range)
## so conversion BossData → AllyData is straightforward.

extends Resource
class_name AllyData

## Unique string identifier for this ally, matching mercenary catalog entries.
@export var ally_id: String = ""
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
## Human-readable description of the enchantment's effect shown in UI.
@export var description: String = "" ## PLACEHOLDER: narrative text to be filled later.

## Combat class (MELEE/RANGED/SUPPORT) used by AllyBase for AI behaviour.
@export var ally_class: Types.AllyClass = Types.AllyClass.MELEE

## Combat role tag for SimBot scoring and future AI preferences.
@export var role: Types.AllyRole = Types.AllyRole.MELEE_FRONTLINE
## Damage type this ally's attacks deal, used by the damage matrix.
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
## When true, ally AI may prefer flying targets (POST-MVP targeting).
@export var can_target_flying: bool = false

## Maximum hit points of this entity at base difficulty.
@export var max_hp: int = 100
## Movement speed in world units per second.
@export var move_speed: float = 5.0
## Legacy stat name; used when `attack_damage` is zero.
@export var basic_attack_damage: float = 10.0
## Primary attack damage; if zero, `basic_attack_damage` is used at runtime.
@export var attack_damage: float = 0.0 # TUNING
## Range in world units at which this entity can initiate an attack.
@export var attack_range: float = 2.0
## Seconds between consecutive attacks.
@export var attack_cooldown: float = 1.0
## Idle/patrol radius for tower-centric allies (POST-MVP full use in AllyBase).
@export var patrol_radius: float = 12.0 # TUNING
## 0 = permanent death on HP depletion; >0 = downed/recover loop (POST-MVP in AllyBase).
@export var recovery_time: float = 0.0 # TUNING

# CLOSEST = nearest; LOWEST_HP = lowest current HP (tie: nearer); see AllyBase.find_target().
## Target selection priority (CLOSEST, LOWEST_HP, …) for this ally.
@export var preferred_targeting: Types.TargetPriority = Types.TargetPriority.CLOSEST

# True for named characters (Arnulf, defected mini-bosses); false for generic mercs.
## True if only one instance of this ally can be in the roster at a time.
@export var is_unique: bool = false

## Scene to spawn for this ally (empty = not spawnable as AllyBase instance).
@export var scene_path: String = ""
## Present in `owned_allies` when a new campaign starts (e.g. Arnulf roster entry).
@export var is_starter_ally: bool = false
## Unlocked via mini-boss defection offer rather than catalog alone.
@export var is_defected_ally: bool = false
## Tints placeholder mesh on generic allies.
@export var debug_color: Color = Color(0.2, 0.45, 0.95, 1.0)

# POST-MVP: campaign progression hooks (levels, scaling, gear).
## Starting level for progression (POST-MVP).
@export var starting_level: int = 1 # POST-MVP
## Per-level stat scaling coefficient (POST-MVP).
@export var level_scaling_factor: float = 1.0 # POST-MVP
## Enables the DOWNED/RECOVERING cycle rather than permanent death (POST-MVP).
@export var uses_downed_recovering: bool = false # POST-MVP (for Arnulf-like behavior)

## Base melee/ranged hit damage at level 1 (see AllyBase.get_effective_damage()).
@export var base_damage: int = 10
## Base max HP at level 1 (see AllyBase.get_effective_max_hp()). If 0, AllyBase falls back to `max_hp`.
@export var base_hp: int = 0
## Base projectile damage at level 1 for ranged allies; if 0, AllyBase uses `base_damage` for scaling.
@export var ally_base_damage: int = 0
## True if this ally attacks at range rather than closing to melee.
@export var is_ranged: bool = false
