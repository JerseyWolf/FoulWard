PROMPT:

# Session 1: 50-Day Campaign Content Design

## Goal
Design the complete 50-day campaign for Foul Ward: faction assignments for each day, boss placement (mini-boss days, final boss day 50), territory rotation across the five territories, wave composition tuning per day (HP/damage/gold multipliers, spawn count scaling), and starting resources per mission. Currently all 50 DayConfigs have `faction_id = ""` and minimal tuning. This session produces a complete campaign specification.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `day_config.gd` — DayConfig resource class definition; shows all tunable fields per day
- `campaign_config.gd` — CampaignConfig resource class; holds an array of DayConfigs
- `faction_data.gd` — FactionData resource class; defines enemy mix weights per faction
- `boss_data.gd` — BossData resource class; defines boss stats and phase behavior
- `territory_data.gd` — TerritoryData resource class; territory ownership and bonuses
- `territory_map_data.gd` — TerritoryMapData; holds the array of all territories
- `campaign_main_50_days.tres` — Current 50-day campaign (first 100 lines; all faction_id empty)
- `faction_data_default_mixed.tres` — DEFAULT_MIXED faction: equal-weight six-type enemy mix
- `faction_data_orc_raiders.tres` — ORC_RAIDERS faction: orc-heavy with mini-boss
- `faction_data_plague_cult.tres` — PLAGUE_CULT faction: undead/fire/flyer with mini-boss
- `bossdata_final_boss.tres` — Day 50 final boss: 5000 HP, 80 dmg, 3 phases
- `bossdata_orc_warlord_miniboss.tres` — Orc warlord mini-boss: 400 HP, 32 dmg
- `bossdata_plague_cult_miniboss.tres` — Plague cult mini-boss: 450 HP, 35 dmg
- `main_campaign_territories.tres` — 5 territories with bonus definitions

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: designing and populating the complete 50-day campaign content.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

DESIGN REQUIREMENTS:
1. Assign faction_id to every day. Days 1-10 should use DEFAULT_MIXED. After day 10, rotate between ORC_RAIDERS and PLAGUE_CULT based on territory. Introduce faction variety so no faction appears more than 5 days in a row.
2. Place mini-boss encounters: at least 2 mini-boss days (one per faction) between days 15-40. Mark these with is_mini_boss_day = true and boss_id matching the .tres files.
3. Day 50 is the final boss (boss_id = "final_boss", is_final_boss = true).
4. Map each day to a territory_id. The campaign should progress through territories roughly in order (heartland_plains early, outer_city late) with some back-and-forth for variety.
5. Design wave tuning multipliers: enemy_hp_multiplier and enemy_damage_multiplier should scale from 1.0 (day 1) to approximately 3.0 (day 50). gold_reward_multiplier should scale from 1.0 to 1.5. spawn_count_multiplier from 1.0 to 2.5.
6. Set base_wave_count: days 1-10 = 3 waves, days 11-30 = 4 waves, days 31-50 = 5 waves.
7. Provide starting_gold values per day (start at 1000, increase to 1500 by day 50).

OUTPUT FORMAT: A table with columns: day_index (1-50), territory_id, faction_id, is_mini_boss_day, boss_id, base_wave_count, enemy_hp_multiplier, enemy_damage_multiplier, gold_reward_multiplier, spawn_count_multiplier, starting_gold. Then provide the exact .tres sub-resource format for 5 sample days (days 1, 10, 25, 40, 50) showing how to encode these values.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 1: Campaign Content

## EnemyType Enum (30 values)
| Name | Value | Tier |
|------|-------|------|
| ORC_GRUNT | 0 | Base |
| ORC_BRUTE | 1 | Base |
| GOBLIN_FIREBUG | 2 | Base |
| PLAGUE_ZOMBIE | 3 | Base |
| ORC_ARCHER | 4 | Base |
| BAT_SWARM | 5 | Base |
| ORC_SKIRMISHER | 6 | T1 |
| ORC_RATLING | 7 | T1 |
| GOBLIN_RUNTS | 8 | T1 |
| HOUND | 9 | T1 |
| ORC_RAIDER | 10 | T2 |
| ORC_MARKSMAN | 11 | T2 |
| WAR_SHAMAN | 12 | T2 |
| PLAGUE_SHAMAN | 13 | T2 |
| TOTEM_CARRIER | 14 | T2 |
| HARPY_SCOUT | 15 | T2 |
| ORC_SHIELDBEARER | 16 | T3 |
| ORC_BERSERKER | 17 | T3 |
| ORC_SABOTEUR | 18 | T3 |
| HEXBREAKER | 19 | T3 |
| WYVERN_RIDER | 20 | T3 |
| BROOD_CARRIER | 21 | T3 |
| TROLL | 22 | T4 |
| IRONCLAD_CRUSHER | 23 | T4 |
| ORC_OGRE | 24 | T4 |
| WAR_BOAR | 25 | T4 |
| ORC_SKYTHROWER | 26 | T4 |
| WARLORDS_GUARD | 27 | T5 |
| ORCISH_SPIRIT | 28 | T5 |
| PLAGUE_HERALD | 29 | T5 |

## Enemies and Bosses (§12)

30 EnemyData .tres files exist.

### Bosses
| File | boss_id | Notes |
|------|---------|-------|
| bossdata_final_boss.tres | final_boss | Day 50. 5000 HP, 80 dmg, phase 3. |
| bossdata_orc_warlord_miniboss.tres | orc_warlord | 400 HP, 32 dmg. |
| bossdata_plague_cult_miniboss.tres | plague_cult_miniboss | 450 HP, 35 dmg. |
| bossdata_audit5_territory_miniboss.tres | — | Territory mini-boss. |

### Factions
| File | faction_id | Notes |
|------|-----------|-------|
| faction_data_default_mixed.tres | DEFAULT_MIXED | Equal-weight six-type MVP mix |
| faction_data_orc_raiders.tres | ORC_RAIDERS | Orc-heavy + mini-boss |
| faction_data_plague_cult.tres | PLAGUE_CULT | Undead/fire/flyer + mini-boss |

## Campaign and Progression (§13)

### Day/Wave Structure
- 50 days main campaign (campaign_main_50_days.tres), 5 days short (campaign_short_5days.tres).
- Each mission = 5 waves (WAVES_PER_MISSION).
- After Day 50 final boss: loop continues until player wins or tower destroyed.

### Endless Mode
PARTIALLY EXISTS: CampaignManager.is_endless_mode, start_endless_run(), synthetic day scaling.

### Star Difficulty System
DOES NOT EXIST IN CODE. ON ROADMAP. Normal / Veteran / Nightmare per-map.

## Wave System (§20)

WaveComposer + WavePatternData + point budgets. Staggered spawn in _physics_process. enemy_data_registry.size() == 30 enforced.

## Territories

5 territories: heartland_plains, blackwood_forest, ashen_swamp, iron_ridge, outer_city.

## CampaignManager Key API (§3.6)

| Signature | Returns | Usage |
|-----------|---------|-------|
| start_new_campaign() -> void | void | Resets everything, starts day 1 |
| get_current_day() -> int | int | Current day index (1-based) |
| get_current_day_config() -> DayConfig | DayConfig | DayConfig for active day |
| validate_day_configs(day_configs: Array[DayConfig]) -> void | void | Warns on unknown faction/boss IDs |

Key state: current_day, campaign_length, is_endless_mode, faction_registry.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- Signals: past tense for events (enemy_killed), present for requests (build_requested)

FILES:

# Files to Upload for Session 1: Campaign Content

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_01_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/resources/day_config.gd` — DayConfig resource class; all tunable fields per day (~54 lines)
2. `scripts/resources/campaign_config.gd` — CampaignConfig resource class; holds array of DayConfigs (~30 lines)
3. `scripts/resources/faction_data.gd` — FactionData resource class; enemy mix weights per faction (~87 lines)
4. `scripts/resources/boss_data.gd` — BossData resource class; boss stats and phase behavior (~84 lines)
5. `scripts/resources/territory_data.gd` — TerritoryData resource class; territory ownership/bonuses (~87 lines)
6. `scripts/resources/territory_map_data.gd` — TerritoryMapData; holds array of all territories (~63 lines)
7. `resources/campaigns/campaign_main_50_days.tres` — Current 50-day campaign; upload first 100 lines only (showing structure + first few days)
8. `resources/faction_data_default_mixed.tres` — DEFAULT_MIXED faction definition (~63 lines)
9. `resources/faction_data_orc_raiders.tres` — ORC_RAIDERS faction definition (~47 lines)
10. `resources/faction_data_plague_cult.tres` — PLAGUE_CULT faction definition (~39 lines)
11. `resources/bossdata_final_boss.tres` — Final boss data (~26 lines)
12. `resources/bossdata_orc_warlord_miniboss.tres` — Orc warlord mini-boss (~21 lines)
13. `resources/bossdata_plague_cult_miniboss.tres` — Plague cult mini-boss (~26 lines)
14. `resources/territories/main_campaign_territories.tres` — 5 territory definitions (~111 lines)

Total estimated token load: ~838 lines across 14 files

scripts/resources/day_config.gd:
## day_config.gd
## Single-day campaign configuration resource.
## Owned by CampaignConfig; read by CampaignManager and WaveManager.
## POST-MVP: extend with territory/world-map fields.

class_name DayConfig
extends Resource

## 1-based day index inside the campaign.
@export var day_index: int = 1

## Mission index used by MVP systems (1–5). Short campaign: days 1–5 map 1:1 to missions 1–5.
## Days beyond 5 may reuse mission 5 as placeholder content (# ASSUMPTION / # PLACEHOLDER / # TUNING).
@export var mission_index: int = 1

## Human-friendly day name for UI.
@export var display_name: String = ""
## Day description shown in hub/briefing.
@export var description: String = ""

## Active faction for this day. Must match a FactionData.faction_id in the registry.
@export var faction_id: String = "DEFAULT_MIXED"
## POST-MVP: world map / territory UI.
@export var territory_id: String = ""

## Marks this day as eligible for mini-boss schedule queries (WaveManager hook).
@export var is_mini_boss_day: bool = false
## Alias for data-driven mini-boss days (Prompt 10); WaveManager treats this like is_mini_boss_day.
@export var is_mini_boss: bool = false
## TUNING: mark final day boss.
@export var is_final_boss: bool = false
## BossData.boss_id for final boss or repeat boss-attack days.
@export var boss_id: String = ""
## True when this day is a post–Day-50 boss strike on a held territory (Prompt 10).
@export var is_boss_attack_day: bool = false

## TUNING: desired wave count for this day.
@export var base_wave_count: int = 5

## TUNING: per-day multipliers.
@export var enemy_hp_multiplier: float = 1.0
## Multiplier applied to all enemy damage values for this day.
@export var enemy_damage_multiplier: float = 1.0
## Multiplier applied to all gold rewards earned this day.
@export var gold_reward_multiplier: float = 1.0
## Scales total wave spawn count (WaveManager: applied to N×6 base). Default 1.0 = unchanged.
@export var spawn_count_multiplier: float = 1.0

## Optional data-driven waves + routing; when set, WaveManager uses per-wave SpawnEntryData queues.
@export var mission_data: Resource = null

## Optional per-mission economy (starting resources, duplicate k, sell refund, wave bonuses). When null, GameManager does not call [method EconomyManager.apply_mission_economy].
@export var mission_economy: MissionEconomyData = null

scripts/resources/campaign_config.gd:
## campaign_config.gd
## Campaign-level configuration resource containing ordered DayConfig entries.

class_name CampaignConfig
extends Resource

## Stable campaign identifier.
@export var campaign_id: String = ""
## Human-friendly campaign name.
@export var display_name: String = ""
## Ordered day configurations (index 0 => day 1).
@export var day_configs: Array[DayConfig] = []
## Optional campaign start territory IDs (world map / tooling). ASSUMPTION: may mirror TerritoryMapData.
@export var starting_territory_ids: Array[String] = []

## Optional path to TerritoryMapData for this campaign. Empty = no territory layer (short MVP).
## ASSUMPTION: GameManager loads this at runtime when set.
@export var territory_map_resource_path: String = ""

## If true, uses short_campaign_length when > 0.
@export var is_short_campaign: bool = false
## Overrides day_configs size when short mode is enabled.
@export var short_campaign_length: int = 0

## Returns the usable campaign length for CampaignManager.
func get_effective_length() -> int:
	if is_short_campaign and short_campaign_length > 0:
		return short_campaign_length
	return day_configs.size()

scripts/resources/faction_data.gd:
## faction_data.gd
## Faction identity, weighted enemy roster, mini-boss hooks, and scaling hints for WaveManager.

class_name FactionData
extends Resource

## Preload so this script parses before `FactionRosterEntry` class_name is globally registered.
const FactionRosterEntryType = preload("res://scripts/resources/faction_roster_entry.gd")

## Built-in faction .tres files loaded by WaveManager and CampaignManager.
## POST-MVP: replace with directory scan or campaign bundle.
const BUILTIN_FACTION_RESOURCE_PATHS: Array[String] = [
	"res://resources/faction_data_default_mixed.tres",
	"res://resources/faction_data_orc_raiders.tres",
	"res://resources/faction_data_plague_cult.tres",
]

# Identity -------------------------------------------------------------

## Unique stable ID used by DayConfig and TerritoryData.
@export var faction_id: String = ""

## Human-readable name for UI and debug logs.
@export var display_name: String = ""

## Text description for codex / faction summary.
## PLACEHOLDER until narrative pass fills this in.
@export var description: String = ""

# Roster ---------------------------------------------------------------

## Roster entries for this faction. Defines which enemy types can spawn,
## how common they are, and in which wave index range they appear.
@export var roster: Array[FactionRosterEntryType] = []

# Mini-boss hooks ------------------------------------------------------

## IDs of mini-bosses associated with this faction.
## PLACEHOLDER mini-boss resources will be defined in a later prompt.
@export var mini_boss_ids: Array[String] = []

## Recommended wave indices for mini-boss appearances.
## POST-MVP: Used by future boss spawning logic.
@export var mini_boss_wave_hints: Array[int] = []

# Scaling hints --------------------------------------------------------

## Coarse difficulty tier knob for the faction. 1 easy, 2 mid, 3 late-game.
@export var roster_tier: int = 1

## Optional offset used by wave formulas to nudge difficulty up/down.
## TUNING: Values will be adjusted in future balance passes.
@export var difficulty_offset: float = 0.0

# Helper methods -------------------------------------------------------

## Returns roster entries valid for the given wave index based on min/max bounds.
func get_entries_for_wave(wave_index: int) -> Array[FactionRosterEntryType]:
	var result: Array[FactionRosterEntryType] = []
	for entry: FactionRosterEntryType in roster:
		if wave_index >= entry.min_wave_index and wave_index <= entry.max_wave_index:
			result.append(entry)
	return result


## Computes effective weight for a roster entry at a given wave.
## Early waves favor tier 1 units; tier >1 ramp up later.
func get_effective_weight_for_wave(entry: FactionRosterEntryType, wave_index: int) -> float:
	if entry.base_weight <= 0.0:
		return 0.0

	var weight: float = entry.base_weight

	# SOURCE: Weighted enemy roster scaling by wave and tier, common TD pattern.
	# Simple tier-based ramp: elites gain weight as wave index grows.
	if entry.tier > 1:
		var ramp: float = float(wave_index - entry.min_wave_index)
		if ramp < 0.0:
			ramp = 0.0
		weight *= (1.0 + ramp * 0.1) # TUNING

	# Optionally nudge with faction difficulty offset.
	if difficulty_offset != 0.0:
		weight *= maxf(0.1, 1.0 + difficulty_offset) # TUNING

	return maxf(weight, 0.0)

scripts/resources/boss_data.gd:
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

scripts/resources/territory_data.gd:
## territory_data.gd
## Per-territory data: ownership, terrain, and economic bonuses for campaign/world map.
## SOURCE: FOUL WARD Prompt 8 spec — territory ownership hooks for 50-day campaign.

class_name TerritoryData
extends Resource

## Unique ID for this territory, used by DayConfig. Must be unique within a campaign.
@export var territory_id: String = ""

## Display name shown in UI.
@export var display_name: String = ""

## Long-form description for world map and briefing.
## PLACEHOLDER until narrative pass fills this in.
@export var description: String = ""

## Default faction controlling this territory.
## POST-MVP: Used when DayConfig does not set a faction explicitly.
@export var default_faction_id: String = ""

## For now just a string; later can map to real icons.
@export var icon_id: String = ""

## Base color tint for UI elements representing this territory.
@export var color: Color = Color.WHITE

## Terrain preset for battlefield terrain scene selection (Types.TerrainType).
## Former TerritoryData.TerrainType values map 1:1 to Types: PLAINS→GRASSLAND, MOUNTAIN→RUINS, CITY→TUNDRA.
@export var terrain_type: Types.TerrainType = Types.TerrainType.GRASSLAND

## Whether the player currently holds this territory.
@export var is_controlled_by_player: bool = false
## Set when a mini-boss guarding this territory is defeated (Prompt 10 hook).
@export var is_secured: bool = false
## True while the campaign boss threatens this territory (Prompt 10 MVP UI hook).
@export var has_boss_threat: bool = false

## If true, territory is lost for the campaign (MVP: set on mission fail).
@export var is_permanently_lost: bool = false

## Narrative/tuning hook for threat display.
@export var threat_level: int = 0

## Whether the territory is under attack (POST-MVP UI).
@export var is_under_attack: bool = false

## Flat gold added at end of mission/day reward when active.
@export var bonus_flat_gold_end_of_day: int = 0

## Additive fraction applied to gold after flat (e.g. 0.1 = +10%).
@export var bonus_percent_gold_end_of_day: float = 0.0

## POST-MVP: per-kill flat bonus from holding this territory.
@export var bonus_flat_gold_per_kill: int = 0

## POST-MVP: extra research material per day while held.
@export var bonus_research_per_day: int = 0

## POST-MVP: multiplier on research costs (1.0 = no change).
@export var bonus_research_cost_multiplier: float = 1.0

## POST-MVP: multiplier on enchanting gold costs.
@export var bonus_enchanting_cost_multiplier: float = 1.0

## POST-MVP: multiplier on weapon upgrade gold costs.
@export var bonus_weapon_upgrade_cost_multiplier: float = 1.0


## Returns true if this territory should currently contribute bonuses.
## MVP: controlled and not permanently lost.
func is_active_for_bonuses() -> bool:
	return is_controlled_by_player and not is_permanently_lost


## Returns the effective flat gold bonus per kill after any territory modifiers.
func get_effective_end_of_day_gold_flat() -> int:
	if not is_active_for_bonuses():
		return 0
	return bonus_flat_gold_end_of_day


## Returns the effective percent gold bonus per day after any territory modifiers.
func get_effective_end_of_day_gold_percent() -> float:
	if not is_active_for_bonuses():
		return 0.0
	return bonus_percent_gold_end_of_day

scripts/resources/territory_map_data.gd:
## territory_map_data.gd
## Campaign territory list with O(1) lookup by territory_id.
## SOURCE: FOUL WARD Prompt 8 spec.

class_name TerritoryMapData
extends Resource

## All territories in this map (order is display order; IDs must be unique).
@export var territories: Array[TerritoryData] = []

var _id_to_territory: Dictionary = {}
var _id_to_index: Dictionary = {}
var _cache_built: bool = false


func _ensure_cache_built() -> void:
	if _cache_built:
		return
	_id_to_territory.clear()
	_id_to_index.clear()
	for i: int in territories.size():
		var territory: TerritoryData = territories[i]
		if territory == null:
			continue
		if territory.territory_id == "":
			continue
		# ASSUMPTION: IDs unique within the campaign. Ignore duplicates after first.
		if not _id_to_territory.has(territory.territory_id):
			_id_to_territory[territory.territory_id] = territory
			_id_to_index[territory.territory_id] = i
	_cache_built = true


## Clears lookup cache after external edits to the territories array (e.g. tests).
func invalidate_cache() -> void:
	_cache_built = false


## Returns the TerritoryData with the matching territory_id, or null if not found.
func get_territory_by_id(id: String) -> TerritoryData:
	_ensure_cache_built()
	if not _id_to_territory.has(id):
		return null
	return _id_to_territory[id] as TerritoryData


## Returns true if a territory with the given id exists in the map.
func has_territory(id: String) -> bool:
	_ensure_cache_built()
	return _id_to_territory.has(id)


## Returns all TerritoryData entries in this map.
func get_all_territories() -> Array[TerritoryData]:
	return territories.duplicate()


## Returns the array index of the territory with the given id, or -1 if not found.
func get_index_by_id(id: String) -> int:
	_ensure_cache_built()
	if not _id_to_index.has(id):
		return -1
	return int(_id_to_index[id])

resources/campaigns/campaign_main_50_days.tres:
[gd_resource type="Resource" script_class="CampaignConfig" format=3]
; campaign_main_50_days.tres — 50-day main campaign (Prompt 7).
; # PLACEHOLDER: display_name "Day N", description "Placeholder briefing." on every day until narrative pass.
; # TUNING (per day i = day_index): base_wave_count follows clamp(5 + floor((i-1)/5), 5, 10) — PLACEHOLDER linear ramp.
; # TUNING: enemy_hp_multiplier = 1.0 + (i-1)*0.02 — PLACEHOLDER +2% per day from day 1.
; # TUNING: enemy_damage_multiplier = 1.0 + (i-1)*0.015 — PLACEHOLDER +1.5% per day.
; # TUNING: gold_reward_multiplier = 1.0 + (i-1)*0.01 — PLACEHOLDER +1% per day.
; # TUNING: is_mini_boss_day true on days 10,20,30,40; is_final_boss true on day 50 only.


[ext_resource type="Script" path="res://scripts/resources/campaign_config.gd" id="1_campaignconfig"]
[ext_resource type="Script" path="res://scripts/resources/day_config.gd" id="2_dayconfig"]

[sub_resource type="Resource" id="DayConfig_1"]
script = ExtResource("2_dayconfig")
day_index = 1
display_name = "Day 1"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.0
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.0
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.0
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_2"]
script = ExtResource("2_dayconfig")
day_index = 2
display_name = "Day 2"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.02
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.015
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.01
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_3"]
script = ExtResource("2_dayconfig")
day_index = 3
display_name = "Day 3"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.04
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.03
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.02
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_4"]
script = ExtResource("2_dayconfig")
day_index = 4
display_name = "Day 4"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.06
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.045
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.03
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_5"]
script = ExtResource("2_dayconfig")
day_index = 5
display_name = "Day 5"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.08
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.06
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.04
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_6"]
script = ExtResource("2_dayconfig")
day_index = 6
display_name = "Day 6"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.1
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.075
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.05
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_7"]
script = ExtResource("2_dayconfig")
day_index = 7
display_name = "Day 7"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.12
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.09
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.06
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_8"]
script = ExtResource("2_dayconfig")
day_index = 8
display_name = "Day 8"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.14
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.105
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.07
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_9"]
script = ExtResource("2_dayconfig")
day_index = 9
display_name = "Day 9"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.16
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.12
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.08
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_10"]
script = ExtResource("2_dayconfig")
day_index = 10
display_name = "Day 10"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.18
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.135
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.09
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_11"]
script = ExtResource("2_dayconfig")
day_index = 11
display_name = "Day 11"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.2
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.15
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.1
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_12"]
script = ExtResource("2_dayconfig")
day_index = 12
display_name = "Day 12"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.22
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.165
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.11
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_13"]
script = ExtResource("2_dayconfig")
day_index = 13
display_name = "Day 13"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.24
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.18
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.12
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_14"]
script = ExtResource("2_dayconfig")
day_index = 14
display_name = "Day 14"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.26
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.195
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.13
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_15"]
script = ExtResource("2_dayconfig")
day_index = 15
display_name = "Day 15"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.28
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.21
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.14
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_16"]
script = ExtResource("2_dayconfig")
day_index = 16
display_name = "Day 16"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.3
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.225
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.15
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_17"]
script = ExtResource("2_dayconfig")
day_index = 17
display_name = "Day 17"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.32
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.24
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.16
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_18"]
script = ExtResource("2_dayconfig")
day_index = 18
display_name = "Day 18"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.34
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.255
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.17
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_19"]
script = ExtResource("2_dayconfig")
day_index = 19
display_name = "Day 19"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.36
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.27
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.18
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_20"]
script = ExtResource("2_dayconfig")
day_index = 20
display_name = "Day 20"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.38
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.285
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.19
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_21"]
script = ExtResource("2_dayconfig")
day_index = 21
display_name = "Day 21"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.4
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.3
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.2
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_22"]
script = ExtResource("2_dayconfig")
day_index = 22
display_name = "Day 22"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.42
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.315
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.21
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_23"]
script = ExtResource("2_dayconfig")
day_index = 23
display_name = "Day 23"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.44
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.33
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.22
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_24"]
script = ExtResource("2_dayconfig")
day_index = 24
display_name = "Day 24"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.46
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.345
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.23
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_25"]
script = ExtResource("2_dayconfig")
day_index = 25
display_name = "Day 25"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.48
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.36
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.24
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_26"]
script = ExtResource("2_dayconfig")
day_index = 26
display_name = "Day 26"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.5
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.375
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.25
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_27"]
script = ExtResource("2_dayconfig")
day_index = 27
display_name = "Day 27"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.52
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.39
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.26
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_28"]
script = ExtResource("2_dayconfig")
day_index = 28
display_name = "Day 28"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.54
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.405
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.27
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_29"]
script = ExtResource("2_dayconfig")
day_index = 29
display_name = "Day 29"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.56
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.42
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.28
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_30"]
script = ExtResource("2_dayconfig")
day_index = 30
display_name = "Day 30"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.58
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.435
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.29
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_31"]
script = ExtResource("2_dayconfig")
day_index = 31
display_name = "Day 31"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.6
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.45
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.3
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_32"]
script = ExtResource("2_dayconfig")
day_index = 32
display_name = "Day 32"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.62
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.465
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.31
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_33"]
script = ExtResource("2_dayconfig")
day_index = 33
display_name = "Day 33"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.64
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.48
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.32
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_34"]
script = ExtResource("2_dayconfig")
day_index = 34
display_name = "Day 34"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.66
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.495
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.33
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_35"]
script = ExtResource("2_dayconfig")
day_index = 35
display_name = "Day 35"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.68
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.51
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.34
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_36"]
script = ExtResource("2_dayconfig")
day_index = 36
display_name = "Day 36"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.7
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.525
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.35
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_37"]
script = ExtResource("2_dayconfig")
day_index = 37
display_name = "Day 37"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.72
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.54
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.36
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_38"]
script = ExtResource("2_dayconfig")
day_index = 38
display_name = "Day 38"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.74
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.555
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.37
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_39"]
script = ExtResource("2_dayconfig")
day_index = 39
display_name = "Day 39"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.76
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.57
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.38
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_40"]
script = ExtResource("2_dayconfig")
day_index = 40
display_name = "Day 40"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.78
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.585
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.39
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_41"]
script = ExtResource("2_dayconfig")
day_index = 41
display_name = "Day 41"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.8
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.6
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.4
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_42"]
script = ExtResource("2_dayconfig")
day_index = 42
display_name = "Day 42"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.82
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.615
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.41
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_43"]
script = ExtResource("2_dayconfig")
day_index = 43
display_name = "Day 43"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.84
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.63
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.42
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_44"]
script = ExtResource("2_dayconfig")
day_index = 44
display_name = "Day 44"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.86
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.645
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.43
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_45"]
script = ExtResource("2_dayconfig")
day_index = 45
display_name = "Day 45"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.88
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.66
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.44
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_46"]
script = ExtResource("2_dayconfig")
day_index = 46
display_name = "Day 46"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.9
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.675
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.45
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_47"]
script = ExtResource("2_dayconfig")
day_index = 47
display_name = "Day 47"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.92
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.69
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.46
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_48"]
script = ExtResource("2_dayconfig")
day_index = 48
display_name = "Day 48"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.94
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.705
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.47
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_49"]
script = ExtResource("2_dayconfig")
day_index = 49
display_name = "Day 49"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.96
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.72
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.48
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_50"]
script = ExtResource("2_dayconfig")
day_index = 50
mission_index = 5
faction_id = "PLAGUE_CULT"
boss_id = "final_boss"
display_name = "Day 50"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.98
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.735
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.49
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = true
; # TUNING: final campaign boss

[resource]
script = ExtResource("1_campaignconfig")
campaign_id = "main_50_day_campaign"
display_name = "The Foul Ward - Main Campaign"
day_configs = [SubResource("DayConfig_1"), SubResource("DayConfig_2"), SubResource("DayConfig_3"), SubResource("DayConfig_4"), SubResource("DayConfig_5"), SubResource("DayConfig_6"), SubResource("DayConfig_7"), SubResource("DayConfig_8"), SubResource("DayConfig_9"), SubResource("DayConfig_10"), SubResource("DayConfig_11"), SubResource("DayConfig_12"), SubResource("DayConfig_13"), SubResource("DayConfig_14"), SubResource("DayConfig_15"), SubResource("DayConfig_16"), SubResource("DayConfig_17"), SubResource("DayConfig_18"), SubResource("DayConfig_19"), SubResource("DayConfig_20"), SubResource("DayConfig_21"), SubResource("DayConfig_22"), SubResource("DayConfig_23"), SubResource("DayConfig_24"), SubResource("DayConfig_25"), SubResource("DayConfig_26"), SubResource("DayConfig_27"), SubResource("DayConfig_28"), SubResource("DayConfig_29"), SubResource("DayConfig_30"), SubResource("DayConfig_31"), SubResource("DayConfig_32"), SubResource("DayConfig_33"), SubResource("DayConfig_34"), SubResource("DayConfig_35"), SubResource("DayConfig_36"), SubResource("DayConfig_37"), SubResource("DayConfig_38"), SubResource("DayConfig_39"), SubResource("DayConfig_40"), SubResource("DayConfig_41"), SubResource("DayConfig_42"), SubResource("DayConfig_43"), SubResource("DayConfig_44"), SubResource("DayConfig_45"), SubResource("DayConfig_46"), SubResource("DayConfig_47"), SubResource("DayConfig_48"), SubResource("DayConfig_49"), SubResource("DayConfig_50")]
is_short_campaign = false
short_campaign_length = 0

resources/faction_data_default_mixed.tres:
[gd_resource type="Resource" script_class="FactionData" load_steps=9 format=3]

[ext_resource type="Script" path="res://scripts/resources/faction_data.gd" id="1_faction"]
[ext_resource type="Script" path="res://scripts/resources/faction_roster_entry.gd" id="2_roster"]

[sub_resource type="Resource" id="Roster_0"]
script = ExtResource("2_roster")
enemy_type = 0
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_1"]
script = ExtResource("2_roster")
enemy_type = 1
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_2"]
script = ExtResource("2_roster")
enemy_type = 2
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_3"]
script = ExtResource("2_roster")
enemy_type = 3
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_4"]
script = ExtResource("2_roster")
enemy_type = 4
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_5"]
script = ExtResource("2_roster")
enemy_type = 5
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[resource]
script = ExtResource("1_faction")
faction_id = "DEFAULT_MIXED"
display_name = "Default Mixed"
description = "PLACEHOLDER: MVP-style mixed enemy roster."
roster = [SubResource("Roster_0"), SubResource("Roster_1"), SubResource("Roster_2"), SubResource("Roster_3"), SubResource("Roster_4"), SubResource("Roster_5")]
mini_boss_ids = []
mini_boss_wave_hints = []
roster_tier = 1
difficulty_offset = 0.0

resources/faction_data_orc_raiders.tres:
[gd_resource type="Resource" script_class="FactionData" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/resources/faction_data.gd" id="1_faction"]
[ext_resource type="Script" path="res://scripts/resources/faction_roster_entry.gd" id="2_roster"]

[sub_resource type="Resource" id="Roster_grunt"]
script = ExtResource("2_roster")
enemy_type = 0
base_weight = 4.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_archer"]
script = ExtResource("2_roster")
enemy_type = 4
base_weight = 3.0
min_wave_index = 2
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_brute"]
script = ExtResource("2_roster")
enemy_type = 1
base_weight = 2.0
min_wave_index = 3
max_wave_index = 10
tier = 2

[sub_resource type="Resource" id="Roster_bats"]
script = ExtResource("2_roster")
enemy_type = 5
base_weight = 1.0
min_wave_index = 4
max_wave_index = 10
tier = 2

[resource]
script = ExtResource("1_faction")
faction_id = "ORC_RAIDERS"
display_name = "Orc Raiders"
description = "PLACEHOLDER: Orc warbands and supporting beasts."
roster = [SubResource("Roster_grunt"), SubResource("Roster_archer"), SubResource("Roster_brute"), SubResource("Roster_bats")]
mini_boss_ids = Array[String](["orc_warlord"])
mini_boss_wave_hints = Array[int]([5, 10])
roster_tier = 2
difficulty_offset = 0.0

resources/faction_data_plague_cult.tres:
[gd_resource type="Resource" script_class="FactionData" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/resources/faction_data.gd" id="1_faction"]
[ext_resource type="Script" path="res://scripts/resources/faction_roster_entry.gd" id="2_roster"]

[sub_resource type="Resource" id="Roster_zombie"]
script = ExtResource("2_roster")
enemy_type = 3
base_weight = 4.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_firebug"]
script = ExtResource("2_roster")
enemy_type = 2
base_weight = 3.0
min_wave_index = 2
max_wave_index = 10
tier = 2

[sub_resource type="Resource" id="Roster_bats"]
script = ExtResource("2_roster")
enemy_type = 5
base_weight = 2.0
min_wave_index = 3
max_wave_index = 10
tier = 2

[resource]
script = ExtResource("1_faction")
faction_id = "PLAGUE_CULT"
display_name = "Plague Cult"
description = "PLACEHOLDER: Rotting hordes and fire-obsessed fanatics."
roster = [SubResource("Roster_zombie"), SubResource("Roster_firebug"), SubResource("Roster_bats")]
mini_boss_ids = Array[String](["plague_cult_miniboss"])
mini_boss_wave_hints = Array[int]([4, 9])
roster_tier = 2
difficulty_offset = 0.0

resources/bossdata_final_boss.tres:
[gd_resource type="Resource" script_class="BossData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/boss_data.gd" id="1_boss"]
[ext_resource type="PackedScene" path="res://scenes/bosses/boss_base.tscn" id="2_scene"]

[resource]
script = ExtResource("1_boss")
boss_id = "final_boss"
display_name = "Archrot Incarnate"
description = "PLACEHOLDER: Campaign-ending threat for Day 50."
faction_id = "PLAGUE_CULT"
associated_territory_id = ""
threat_icon_id = ""
max_hp = 5000
move_speed = 2.2
damage = 80
attack_range = 2.5
attack_cooldown = 0.85
gold_reward = 2000
is_ranged = false
is_flying = false
phase_count = 3
escort_unit_ids = Array[String](["ORC_BRUTE", "PLAGUE_ZOMBIE", "BAT_SWARM"])
is_mini_boss = false
is_final_boss = true
boss_scene = ExtResource("2_scene")

resources/bossdata_orc_warlord_miniboss.tres:
[gd_resource type="Resource" script_class="BossData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/boss_data.gd" id="1_boss"]
[ext_resource type="PackedScene" path="res://scenes/bosses/boss_base.tscn" id="2_scene"]

[resource]
script = ExtResource("1_boss")
boss_id = "orc_warlord"
display_name = "Gorefang Warlord"
description = "PLACEHOLDER: Orc Raiders mini-boss."
faction_id = "ORC_RAIDERS"
max_hp = 400
move_speed = 3.2
damage = 32
attack_range = 2.0
attack_cooldown = 1.0
gold_reward = 110
escort_unit_ids = Array[String](["ORC_GRUNT", "ORC_ARCHER"])
is_mini_boss = true
is_final_boss = false
boss_scene = ExtResource("2_scene")

resources/bossdata_plague_cult_miniboss.tres:
[gd_resource type="Resource" script_class="BossData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/boss_data.gd" id="1_boss"]
[ext_resource type="PackedScene" path="res://scenes/bosses/boss_base.tscn" id="2_scene"]

[resource]
script = ExtResource("1_boss")
boss_id = "plague_cult_miniboss"
display_name = "Herald of Worms"
description = "PLACEHOLDER: Plague Cult mini-boss."
faction_id = "PLAGUE_CULT"
associated_territory_id = ""
threat_icon_id = ""
max_hp = 450
move_speed = 2.8
damage = 35
attack_range = 2.2
attack_cooldown = 1.1
gold_reward = 120
is_ranged = false
is_flying = false
phase_count = 1
escort_unit_ids = Array[String](["ORC_GRUNT", "ORC_BRUTE"])
is_mini_boss = true
is_final_boss = false
boss_scene = ExtResource("2_scene")

resources/territories/main_campaign_territories.tres:
; main_campaign_territories.tres — TerritoryMapData for main 50-day campaign.
; # PLACEHOLDER / # TUNING: names, bonuses, descriptions.

[gd_resource type="Resource" script_class="TerritoryMapData" load_steps=8 format=3 uid="uid://bwmcterrmap01"]

[ext_resource type="Script" path="res://scripts/resources/territory_map_data.gd" id="1_tmap"]
[ext_resource type="Script" path="res://scripts/resources/territory_data.gd" id="2_terr"]

[sub_resource type="Resource" id="Territory_heartland"]
script = ExtResource("2_terr")
territory_id = "heartland_plains"
display_name = "Heartland Plains"
description = "Central breadbasket region. # PLACEHOLDER # TUNING"
icon_id = "plains_icon"
color = Color(0.75, 0.85, 0.55, 1)
terrain_type = 0
is_controlled_by_player = true
is_permanently_lost = false
threat_level = 0
is_under_attack = false
bonus_flat_gold_end_of_day = 5
bonus_percent_gold_end_of_day = 0.0
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_blackwood"]
script = ExtResource("2_terr")
territory_id = "blackwood_forest"
display_name = "Blackwood Forest"
description = "Dense woods. # PLACEHOLDER # TUNING"
icon_id = "forest_icon"
color = Color(0.2, 0.45, 0.22, 1)
terrain_type = 1
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 1
is_under_attack = false
bonus_flat_gold_end_of_day = 3
bonus_percent_gold_end_of_day = 0.05
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_ashen"]
script = ExtResource("2_terr")
territory_id = "ashen_swamp"
display_name = "Ashen Swamp"
description = "Miasmic wetlands. # PLACEHOLDER # TUNING"
icon_id = "swamp_icon"
color = Color(0.35, 0.4, 0.38, 1)
terrain_type = 2
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 2
is_under_attack = false
bonus_flat_gold_end_of_day = 0
bonus_percent_gold_end_of_day = 0.12
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_iron"]
script = ExtResource("2_terr")
territory_id = "iron_ridge"
display_name = "Iron Ridge"
description = "Highland mines. # PLACEHOLDER # TUNING"
icon_id = "mountain_icon"
color = Color(0.55, 0.5, 0.48, 1)
terrain_type = 3
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 2
is_under_attack = false
bonus_flat_gold_end_of_day = 15
bonus_percent_gold_end_of_day = 0.0
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_outer"]
script = ExtResource("2_terr")
territory_id = "outer_city"
display_name = "Outer City"
description = "Walled outskirts. # PLACEHOLDER # TUNING"
icon_id = "city_icon"
color = Color(0.65, 0.62, 0.7, 1)
terrain_type = 4
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 3
is_under_attack = false
bonus_flat_gold_end_of_day = 12
bonus_percent_gold_end_of_day = 0.0
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[resource]
script = ExtResource("1_tmap")
territories = [SubResource("Territory_heartland"), SubResource("Territory_blackwood"), SubResource("Territory_ashen"), SubResource("Territory_iron"), SubResource("Territory_outer")]

