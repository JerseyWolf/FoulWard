## building_data.gd
## Data resource describing stats for a single building type in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name BuildingData
extends Resource

## Which building type this resource describes.
@export var building_type: Types.BuildingType
## Human-readable name shown in the build menu.
@export var display_name: String = ""
## Gold cost to place this building.
@export var gold_cost: int = 50
## Building material cost to place this building.
@export var material_cost: int = 2
## Gold cost to upgrade this building.
@export var upgrade_gold_cost: int = 75
## Building material cost to upgrade this building.
@export var upgrade_material_cost: int = 3
## Base damage per shot.
@export var damage: float = 20.0
## Damage per shot after upgrade.
@export var upgraded_damage: float = 35.0
## Shots per second.
@export var fire_rate: float = 1.0
## Attack range in world units (external specs use the word "range"; the GDScript keyword `range` cannot be a member name).
@export var attack_range: float = 15.0
## Attack range after upgrade.
@export var upgraded_range: float = 18.0
## Damage type this building's projectiles deal.
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
## True if this building's targeting includes flying enemies.
@export var targets_air: bool = false
## True if this building's targeting includes ground enemies.
@export var targets_ground: bool = true
## True if a research node must be unlocked before this building is placeable.
@export var is_locked: bool = false
## ID of the research node that unlocks this building. Empty string = always available.
@export var unlock_research_id: String = ""
## If set, unlocking this node grants upgraded_damage while the building is not upgraded.
@export var research_damage_boost_id: String = ""
## If set, unlocking this node grants upgraded_range while the building is not upgraded.
@export var research_range_boost_id: String = ""
## MVP cube color for this building type.
@export var color: Color = Color.GRAY
## Targeting strategy this building uses to select its next attack target.
@export var target_priority: Types.TargetPriority = Types.TargetPriority.CLOSEST
## Enables damage-over-time (DoT) application for this building's projectiles.
@export var dot_enabled: bool = false
## TUNING: total DoT damage over full duration.
@export var dot_total_damage: float = 0.0
## TUNING: seconds between DoT ticks.
@export var dot_tick_interval: float = 1.0
## TUNING: DoT duration in seconds.
@export var dot_duration: float = 0.0
## Effect identifier for DoT handling ("burn", "poison", etc.).
@export var dot_effect_type: String = ""
## Stable source identifier for stacking rules ("fire_brazier", "poison_vat", etc.).
@export var dot_source_id: String = ""
## TUNING: true = instant hit plus DoT, false = DoT only.
@export var dot_in_addition_to_hit: bool = true

## Archer Barracks / Shield Generator: seconds between special pulses.
@export var special_pulse_interval: float = 10.0
## Radius for barracks ally buff (world units).
@export var barracks_buff_radius: float = 22.0
## Flat damage added to the next ally strike while in radius (applied on pulse).
@export var barracks_ally_damage_bonus: float = 8.0
## Shield pulse: temporary absorb HP granted to the central tower.
@export var shield_hp_per_pulse: float = 28.0
## Duration for shield HP pool from generator (seconds).
@export var shield_pulse_duration: float = 8.0

## Modular kit: base GLB id (`res://art/generated/kit/<name>.glb`).
@export var base_mesh_id: Types.BuildingBaseMesh = Types.BuildingBaseMesh.STONE_ROUND
## Modular kit: top GLB id (`res://art/generated/kit/<name>.glb`).
@export var top_mesh_id: Types.BuildingTopMesh = Types.BuildingTopMesh.ROOF_CONE
## Faction accent applied to the top kit mesh surface 0 (see ArtPlaceholderHelper.get_building_kit_mesh).
@export var accent_color: Color = Color(0.7, 0.3, 0.1)

# ---------------------------------------------------------------------------
# Data-driven tower defense foundation (Prompt 34) — identity & presentation
# ---------------------------------------------------------------------------

## Stable string id for JSON / saves (optional; legacy content may leave empty).
@export var id: String = ""
## Longer description for tooltips / codex.
@export var description: String = ""
## `res://` path to icon texture (optional).
@export var icon: String = ""
## Optional PackedScene path for bespoke building root (empty = default BuildingBase).
@export var scene_path: String = ""

# ---------------------------------------------------------------------------
# Layout (future hex / multi-slot placement)
# ---------------------------------------------------------------------------

@export var size_class: Types.BuildingSizeClass = Types.BuildingSizeClass.SINGLE_SLOT
## Preferred ring for auto-layout presets (-1 = any ring).
@export var ring_index: int = -1

# ---------------------------------------------------------------------------
# Economy — canonical `cost_*` with legacy fallback (`gold_cost` / `material_cost`)
# ---------------------------------------------------------------------------

## When >= 0, overrides `gold_cost` for new pipelines. -1 = use `gold_cost`.
@export var cost_gold: int = -1
## When >= 0, overrides `material_cost`. -1 = use `material_cost`.
@export var cost_material: int = -1
## Fraction of placement + upgrade costs refunded on sell (1.0 = full refund; matches legacy behaviour).
@export var sell_refund_fraction: float = 1.0
## When true, duplicate placements apply global duplicate scaling from mission economy.
@export var apply_duplicate_scaling: bool = false

# ---------------------------------------------------------------------------
# Combat — extended fields (legacy `attack_range` / DoT block remains authoritative for MVP)
# ---------------------------------------------------------------------------

@export_flags("ground", "air", "boss", "structure", "summoned") var target_flags: int = 0
## Optional projectile scene override (null = use BuildingBase default projectile).
@export var projectile_scene: PackedScene = null
## Splash radius in world units (0 = single-target impact only).
@export var splash_radius: float = 0.0
## DoT DPS; ticks may still use `dot_tick_interval` / `dot_duration` from legacy fields.
@export var dot_damage_per_second: float = 0.0

# ---------------------------------------------------------------------------
# Summoner / spawner buildings
# ---------------------------------------------------------------------------

@export var is_summoner: bool = false
@export var summon_leader_data: AllyData = null
@export var summon_follower_data: AllyData = null
@export var summon_follower_count: int = 0
@export var summon_type: Types.SummonLifetimeType = Types.SummonLifetimeType.NONE
@export var respawn_cooldown: float = 0.0
@export var summon_is_ground: bool = true
@export var summon_is_blocker: bool = false

# ---------------------------------------------------------------------------
# Aura / support buildings
# ---------------------------------------------------------------------------

@export var is_aura: bool = false
@export var aura_category: Types.AuraCategory = Types.AuraCategory.OFFENSE
@export var aura_radius: float = 0.0
@export_flags("allies", "buildings", "summons", "tower") var aura_targets: int = 0
@export var aura_stat: Types.AuraStat = Types.AuraStat.DAMAGE
@export var aura_modifier_type: Types.AuraModifierOp = Types.AuraModifierOp.ADD
@export var aura_modifier_value: float = 0.0
## When true, `aura_damage_type_filter` restricts which incoming damage types receive the aura.
@export var aura_limit_damage_type: bool = false
## Only read when `aura_limit_damage_type` is true.
@export var aura_damage_type_filter: Types.DamageType = Types.DamageType.PHYSICAL

# ---------------------------------------------------------------------------
# Healer buildings
# ---------------------------------------------------------------------------

@export var is_healer: bool = false
@export var heal_per_second: float = 0.0
@export var heal_radius: float = 0.0
@export_flags("allies", "tower", "buildings") var heal_targets: int = 0
@export var cleanse_on_heal: bool = false
@export var shield_on_heal: float = 0.0

# ---------------------------------------------------------------------------
# Upgrade chain (data-driven)
# ---------------------------------------------------------------------------

## When >= 0, overrides `upgrade_gold_cost`. -1 = use `upgrade_gold_cost`.
@export var upgrade_cost_gold: int = -1
## When >= 0, overrides `upgrade_material_cost`. -1 = use `upgrade_material_cost`.
@export var upgrade_cost_material: int = -1
## Next tier in an upgrade chain (null = terminal).
@export var upgrade_next: BuildingData = null
@export var upgrade_level: int = 0
@export var upgrade_label: String = ""

# ---------------------------------------------------------------------------
# Meta
# ---------------------------------------------------------------------------

@export var balance_status: Types.MissionBalanceStatus = Types.MissionBalanceStatus.UNSET
## Preferred research gate id for new content; falls back to `unlock_research_id` when empty.
@export var research_unlock_id: String = ""
## Campaign day index at which this blueprint appears (0 = no gate).
@export var campaign_unlock_day: int = 0
@export var tags: PackedStringArray = PackedStringArray()


## Attack range in world units (alias for authoring tools / external specs that refer to “range”).
func get_range() -> float:
	return attack_range


## Effective gold cost for placement (respects legacy `gold_cost` when override unset).
func get_effective_cost_gold() -> int:
	return gold_cost if cost_gold < 0 else cost_gold


## Effective material cost for placement.
func get_effective_cost_material() -> int:
	return material_cost if cost_material < 0 else cost_material


## Effective upgrade gold cost.
func get_effective_upgrade_cost_gold() -> int:
	return upgrade_gold_cost if upgrade_cost_gold < 0 else upgrade_cost_gold


## Effective upgrade material cost.
func get_effective_upgrade_cost_material() -> int:
	return upgrade_material_cost if upgrade_cost_material < 0 else upgrade_cost_material


## Single research gate: prefers `research_unlock_id`, then legacy `unlock_research_id`.
func get_research_gate_id() -> String:
	if not research_unlock_id.is_empty():
		return research_unlock_id
	return unlock_research_id


## Lightweight checks for authoring; returns human-readable issues (not exhaustive).
func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if get_effective_cost_gold() < 0:
		out.append("effective cost_gold is negative")
	if get_effective_cost_material() < 0:
		out.append("effective cost_material is negative")
	if sell_refund_fraction < 0.0 or sell_refund_fraction > 1.0:
		out.append("sell_refund_fraction should be in [0,1]")
	if is_summoner and summon_follower_count < 1:
		out.append("is_summoner but summon_follower_count < 1")
	if is_aura and aura_radius <= 0.0:
		out.append("is_aura but aura_radius <= 0")
	if is_healer and heal_per_second > 0.0 and heal_radius <= 0.0:
		out.append("healer with HPS but heal_radius <= 0")
	return out

