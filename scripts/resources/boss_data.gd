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
]

@export var boss_id: String = ""
@export var display_name: String = ""
## PLACEHOLDER narrative until writing pass.
@export var description: String = ""

@export var faction_id: String = ""
## POST-MVP: link mini-boss to a territory reward.
@export var associated_territory_id: String = ""
## POST-MVP UI hook for threat icons.
@export var threat_icon_id: String = ""

@export var max_hp: int = 100
@export var move_speed: float = 3.0
@export var damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var armor_type: Types.ArmorType = Types.ArmorType.UNARMORED
@export var gold_reward: int = 100

@export var is_ranged: bool = false
@export var is_flying: bool = false
@export var damage_immunities: Array[Types.DamageType] = []

## Phase count for multi-phase encounters; MVP uses tracking only in BossBase.
@export var phase_count: int = 1

## Escort enemy IDs: string form of Types.EnemyType (e.g. "ORC_GRUNT").
@export var escort_unit_ids: Array[String] = []

@export var is_mini_boss: bool = false
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
