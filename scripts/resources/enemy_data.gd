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

# ---------------------------------------------------------------------------
# Data-driven tower defense foundation (Prompt 34)
# ---------------------------------------------------------------------------

## Stable string id for JSON / catalog (optional when `enemy_type` suffices).
@export var id: String = ""
## Longer description for UI / tooling.
@export var description: String = ""
## Optional icon path.
@export var icon: String = ""
## Optional PackedScene root for this enemy (empty = spawner default / enum scene).
@export var scene_path: String = ""

## Flat mitigation layered with `armor_type` matrix (designer-tunable).
@export var armor_flat: float = 0.0
@export var magic_resist: float = 0.0
## Multiplier on status effect application chance/duration (1.0 = normal).
@export var status_resist_multiplier: float = 1.0

## Locomotion / path eligibility (lanes, blockers). Distinct from `armor_type`.
@export var body_type: Types.EnemyBodyType = Types.EnemyBodyType.GROUND
@export var collision_radius: float = 1.0
@export var is_blockable: bool = true
@export var ignores_blockers: bool = false

## Damage applied when this unit reaches Florence / the core (parallel to legacy tower leak damage).
@export var contact_damage_to_florence: int = 0
@export var attack_damage_vs_blockers: int = 0
@export var attack_rate_vs_blockers: float = 1.0

@export var can_be_slowed: bool = true
@export var can_be_stunned: bool = true
@export var can_be_silenced: bool = true
@export var can_be_disarmed: bool = true
@export var can_be_knocked_back: bool = true

## Bounty when >= 0 overrides `gold_reward`; material is new for TD economy.
@export var bounty_gold: int = -1
@export var bounty_material: int = 0

@export var threat_value: int = 1
@export var tags: PackedStringArray = PackedStringArray()

## When true, enemy scans for targetable buildings in detection radius before pathing to tower.
@export var prefer_building_targets: bool = false
## Scan radius for targetable buildings (separate from attack_range).
@export var building_detection_radius: float = 8.0

# ─── WAVE GENERATION & CONTENT AUTHORING (Prompt 50) ───

@export var point_cost: int = 5
## Valid values: "RUSH", "HEAVY", "AIRSTRIKE", "ARTILLERY", "INVASION", "SUPPORT"
@export var wave_tags: Array[String] = []
@export var tier: int = 1
## Valid values: "charge", "shield", "aura_buff", "aura_heal", "on_death_spawn", "ranged_long", "disable_building", "anti_air", "regen"
@export var special_tags: Array[String] = []
@export var special_values: Dictionary = {}
## UNTESTED, BASELINE, OVERTUNED, UNDERTUNED, CUT_CAMPAIGN_1
@export var balance_status: String = "UNTESTED"

## Bitmask aligned with `BuildingData.target_flags` (@export_flags order: ground, air, boss, structure, summoned).
const TARGET_FLAG_GROUND: int = 1 << 0
const TARGET_FLAG_AIR: int = 1 << 1
const TARGET_FLAG_BOSS: int = 1 << 2
const TARGET_FLAG_STRUCTURE: int = 1 << 3
const TARGET_FLAG_SUMMONED: int = 1 << 4


func get_effective_bounty_gold() -> int:
	return gold_reward if bounty_gold < 0 else bounty_gold


## Stable identity for catalog and mission tooling (prefers `id`, then enum name).
func get_identity() -> String:
	var s: String = id.strip_edges()
	if not s.is_empty():
		return s
	return str(enemy_type)


## Leak damage to Florence when > 0; otherwise callers may use legacy `damage`.
func get_effective_contact_damage_to_florence() -> int:
	return damage if contact_damage_to_florence <= 0 else contact_damage_to_florence


## Bits describing this unit for tower `target_flags` matching (OR semantics vs building mask).
func get_target_flag_bits() -> int:
	var bits: int = 0
	if (
			body_type == Types.EnemyBodyType.GROUND
			or body_type == Types.EnemyBodyType.LARGE_GROUND
			or body_type == Types.EnemyBodyType.SIEGE
	):
		bits |= TARGET_FLAG_GROUND
	if (
			is_flying
			or body_type == Types.EnemyBodyType.FLYING
			or body_type == Types.EnemyBodyType.HOVER
			or body_type == Types.EnemyBodyType.ETHEREAL
	):
		bits |= TARGET_FLAG_AIR
	if body_type == Types.EnemyBodyType.BOSS:
		bits |= TARGET_FLAG_BOSS
	if body_type == Types.EnemyBodyType.STRUCTURE:
		bits |= TARGET_FLAG_STRUCTURE
	if _has_tag("summoned"):
		bits |= TARGET_FLAG_SUMMONED
	return bits


## Returns true if this unit is eligible when the tower mask is `flags` (0 = unrestricted).
func matches_target_flags(flags: int) -> bool:
	if flags == 0:
		return true
	var eb: int = get_target_flag_bits()
	return (eb & flags) != 0


## Used by [BuildingBase] with legacy [member BuildingData.targets_air] / [member BuildingData.targets_ground].
## Uses [method get_target_flag_bits] so [member body_type] (e.g. FLYING) matches [member is_flying]; if neither air nor ground locomotion bits are set, falls back to [member is_flying] only.
func matches_tower_air_ground_filter(targets_air: bool, targets_ground: bool) -> bool:
	var eb: int = get_target_flag_bits()
	var has_air: bool = (eb & TARGET_FLAG_AIR) != 0
	var has_ground: bool = (eb & TARGET_FLAG_GROUND) != 0
	if has_air or has_ground:
		return (has_air and targets_air) or (has_ground and targets_ground)
	return (is_flying and targets_air) or ((not is_flying) and targets_ground)


func _has_tag(tag: String) -> bool:
	var want: String = tag.strip_edges()
	if want.is_empty():
		return false
	var i: int = 0
	while i < tags.size():
		if str(tags[i]).strip_edges() == want:
			return true
		i += 1
	return false


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if max_hp <= 0:
		out.append("max_hp should be > 0")
	if move_speed < 0.0:
		out.append("move_speed is negative")
	if status_resist_multiplier < 0.0:
		out.append("status_resist_multiplier is negative")
	return out

