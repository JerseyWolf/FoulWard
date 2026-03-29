## ally_data.gd
## Data backbone for generic allies, mercenary UI, and future defected mini-boss allies.
## ASSUMPTION: A future BossData resource will share basic fields (HP, movement speed, damage, range)
## so conversion BossData → AllyData is straightforward.

extends Resource
class_name AllyData

## Optional stable id for catalogs / missions; when empty, tooling uses [member ally_id].
@export var id: String = ""
## Unique string identifier for this ally, matching mercenary catalog entries.
@export var ally_id: String = ""
## Optional display/catalog identity override; when empty, get_identity() uses ally_id.
@export var identity: String = ""
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
## Human-readable description of the enchantment's effect shown in UI.
@export var description: String = "" ## PLACEHOLDER: narrative text to be filled later.

## Combat class (MELEE/RANGED/SUPPORT) used by AllyBase for AI behaviour.
@export var ally_class: Types.AllyClass = Types.AllyClass.MELEE

## Combat role for TD data and roster scoring (see [enum Types.AllyCombatRole]).
@export var role: Types.AllyCombatRole = Types.AllyCombatRole.MELEE
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
## Data-driven hit/shot damage (Prompt 42); when >0, preferred over legacy attack fields for new pipelines.
@export var damage: float = 0.0
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

# ---------------------------------------------------------------------------
# Data-driven tower defense / roster foundation (Prompt 34)
# ---------------------------------------------------------------------------

## Optional icon (`res://` texture path).
@export var icon: String = ""
## Rough footprint / formation weight.
@export var unit_size: Types.UnitSize = Types.UnitSize.SMALL

## Flat armor and MR (post-MVP combat pipeline; parallel to future armor_type matrix).
@export var armor_flat: float = 0.0
@export var magic_resist: float = 0.0

## Shots per second; when <= 0, runtime may derive from `attack_cooldown`.
@export var fire_rate: float = 0.0
## Splash radius for ranged/AoE allies (world units).
@export var splash_radius: float = 0.0
@export var dot_duration: float = 0.0
@export var dot_damage_per_second: float = 0.0

@export_flags("ground", "air", "boss", "structure", "summoned") var target_flags: int = 0

## Blocker / body footprint for navigation and tower interactions.
@export var is_blocker: bool = false
@export var collision_radius: float = 1.0
## Max distance from anchor before leash pulls (parallel to `patrol_radius`; prefer explicit leash for TD).
@export var leash_radius: float = 0.0

@export var ai_mode: Types.AllyAiMode = Types.AllyAiMode.DEFAULT
## Free-form tag string for preferred targets (e.g. `"flying"`, `"boss"`).
@export var preferred_target_tag: String = ""

## Optional support package (mirrors BuildingData subset for aura/healer allies).
@export var is_aura: bool = false
@export var aura_category: Types.AuraCategory = Types.AuraCategory.OFFENSE
@export var aura_radius: float = 0.0
@export_flags("allies", "self", "tower") var aura_targets: int = 0
@export var aura_stat: Types.AuraStat = Types.AuraStat.DAMAGE
@export var aura_modifier_type: Types.AuraModifierOp = Types.AuraModifierOp.ADD
@export var aura_modifier_value: float = 0.0
@export var aura_limit_damage_type: bool = false
@export var aura_damage_type_filter: Types.DamageType = Types.DamageType.PHYSICAL

@export var is_healer: bool = false
@export var heal_per_second: float = 0.0
@export var heal_radius: float = 0.0
@export_flags("allies", "tower", "self") var heal_targets: int = 0
@export var cleanse_on_heal: bool = false
@export var shield_on_heal: float = 0.0

@export var summon_type: Types.SummonLifetimeType = Types.SummonLifetimeType.NONE
@export var respawn_cooldown: float = 0.0
@export var despawn_at_wave_end: bool = false
## Lifetime cap for summons / temporary allies (0 = no automatic expiry).
@export var max_lifetime_sec: float = 0.0

@export var tags: PackedStringArray = PackedStringArray()


## Stable identity string for saves, UI, and wave tooling (prefers `id`, then `identity`, then `ally_id`).
func get_identity() -> String:
	var sid: String = id.strip_edges()
	if not sid.is_empty():
		return sid
	var s: String = identity.strip_edges()
	if not s.is_empty():
		return s
	return ally_id.strip_edges()


## Weapon range in world units (spec alias for [member attack_range]).
func get_range() -> float:
	return attack_range


## Effective fire rate (Hz); uses `attack_cooldown` when `fire_rate` is unset.
func get_effective_fire_rate() -> float:
	if fire_rate > 0.0:
		return fire_rate
	if attack_cooldown > 0.0:
		return 1.0 / attack_cooldown
	return 0.0


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if max_hp < 0:
		out.append("max_hp is negative")
	if (ally_class == Types.AllyClass.MELEE or ally_class == Types.AllyClass.RANGED) and get_effective_fire_rate() <= 0.0:
		out.append("no positive fire_rate or attack_cooldown for combat ally")
	if is_aura and aura_radius <= 0.0:
		out.append("is_aura but aura_radius <= 0")
	if is_healer and heal_per_second > 0.0 and heal_radius <= 0.0:
		out.append("healer with HPS but heal_radius <= 0")
	return out

