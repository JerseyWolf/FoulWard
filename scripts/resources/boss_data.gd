## boss_data.gd
## Unified Resource for mini-bosses and the campaign final boss (Prompt 10).

class_name BossData
extends Resource

## Built-in boss .tres files loaded into WaveManager / GameManager registries.
## POST-MVP: directory scan or mod bundle.
const BUILTIN_BOSS_RESOURCE_PATHS: Array[String] = [
	"res://resources/bossdata_plague_cult_miniboss.tres",
	"res://resources/bossdata_orc_warlord_miniboss.tres",
	"res://resources/bossdata_final_boss.tres",
	"res://resources/bossdata_audit5_territory_miniboss.tres",
]

## Unique string identifier matching BossData.boss_id and FactionData.mini_boss_ids.
@export var boss_id: String = ""
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
## PLACEHOLDER narrative until writing pass.
@export var description: String = ""

## Faction this boss belongs to; used for escort unit theming.
@export var faction_id: String = ""
## POST-MVP: link mini-boss to a territory reward.
@export var associated_territory_id: String = ""
## POST-MVP UI hook for threat icons.
@export var threat_icon_id: String = ""

## Maximum hit points of this entity at base difficulty.
@export var max_hp: int = 100
## Movement speed in world units per second.
@export var move_speed: float = 3.0
## Base damage dealt per attack.
@export var damage: int = 10
## Range in world units at which this entity can initiate an attack.
@export var attack_range: float = 2.0
## Seconds between consecutive attacks.
@export var attack_cooldown: float = 1.0
## Armor class determining the damage multiplier matrix column.
@export var armor_type: Types.ArmorType = Types.ArmorType.UNARMORED
## Gold awarded to the player when this entity is killed.
@export var gold_reward: int = 100

## True if this ally attacks at range rather than closing to melee.
@export var is_ranged: bool = false
## True if this entity uses aerial pathing and can only be hit by anti-air weapons.
@export var is_flying: bool = false
## DamageType values for which this entity takes zero damage.
@export var damage_immunities: Array[Types.DamageType] = []

## Phase count for multi-phase encounters; MVP uses tracking only in BossBase.
@export var phase_count: int = 1

## Escort enemy IDs: string form of Types.EnemyType (e.g. "ORC_GRUNT").
@export var escort_unit_ids: Array[String] = []

## True if this boss is a mini-boss that can appear mid-campaign.
@export var is_mini_boss: bool = false
## True if this is the Day-50 campaign boss.
@export var is_final_boss: bool = false

## Optional per-boss scene; defaults to shared boss_base.tscn when unset in .tres.
@export var boss_scene: PackedScene


## Builds an EnemyData mirror so EnemyBase.initialize() can drive combat and rewards.
func build_placeholder_enemy_data() -> EnemyData:
	var e: EnemyData = EnemyData.new()
	# ASSUMPTION: ORC_GRUNT is a neutral stand-in for SignalBus.enemy_killed typing only.
	e.enemy_type = Types.EnemyType.ORC_GRUNT
	e.display_name = display_name
	e.max_hp = max_hp
	e.move_speed = move_speed
	e.damage = damage
	e.attack_range = attack_range
	e.attack_cooldown = attack_cooldown
	e.armor_type = armor_type
	e.gold_reward = gold_reward
	e.is_ranged = is_ranged
	e.is_flying = is_flying
	e.damage_immunities = damage_immunities.duplicate()
	e.color = Color(0.75, 0.2, 0.85)
	return e
