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

@export var max_hp: int = 100
@export var move_speed: float = 5.0
@export var basic_attack_damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0

# Uses existing TargetPriority enum; MVP only implements CLOSEST behavior.
@export var preferred_targeting: Types.TargetPriority = Types.TargetPriority.CLOSEST

# True for named characters (Arnulf, defected mini-bosses); false for generic mercs.
@export var is_unique: bool = false

# POST-MVP: campaign progression hooks (levels, scaling, gear).
@export var starting_level: int = 1 # POST-MVP
@export var level_scaling_factor: float = 1.0 # POST-MVP
@export var uses_downed_recovering: bool = false # POST-MVP (for Arnulf-like behavior)
