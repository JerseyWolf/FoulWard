## ally_data.gd
## Data backbone for generic allies, mercenary UI, and future defected mini-boss allies.
## ASSUMPTION: A future BossData resource will share basic fields (HP, movement speed, damage, range)
## so conversion BossData → AllyData is straightforward.

extends Resource
class_name AllyData

@export var ally_id: String = ""
@export var display_name: String = ""
@export var description: String = "" ## PLACEHOLDER: narrative text to be filled later.

@export var ally_class: Types.AllyClass = Types.AllyClass.MELEE

## Combat role tag for SimBot scoring and future AI preferences.
@export var role: Types.AllyRole = Types.AllyRole.MELEE_FRONTLINE
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
## When true, ally AI may prefer flying targets (POST-MVP targeting).
@export var can_target_flying: bool = false

@export var max_hp: int = 100
@export var move_speed: float = 5.0
## Legacy stat name; used when `attack_damage` is zero.
@export var basic_attack_damage: float = 10.0
## Primary attack damage; if zero, `basic_attack_damage` is used at runtime.
@export var attack_damage: float = 0.0 # TUNING
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
## Idle/patrol radius for tower-centric allies (POST-MVP full use in AllyBase).
@export var patrol_radius: float = 12.0 # TUNING
## 0 = permanent death on HP depletion; >0 = downed/recover loop (POST-MVP in AllyBase).
@export var recovery_time: float = 0.0 # TUNING

# Uses existing TargetPriority enum; MVP only implements CLOSEST behavior.
@export var preferred_targeting: Types.TargetPriority = Types.TargetPriority.CLOSEST

# True for named characters (Arnulf, defected mini-bosses); false for generic mercs.
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
@export var starting_level: int = 1 # POST-MVP
@export var level_scaling_factor: float = 1.0 # POST-MVP
@export var uses_downed_recovering: bool = false # POST-MVP (for Arnulf-like behavior)
