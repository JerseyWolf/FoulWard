PROMPT:

# Session 8: Star Difficulty System

## Goal
Design the Normal / Veteran / Nightmare difficulty system for per-territory replay. The master doc notes it is on the roadmap but not in code. The master doc TBD asks for exact multipliers.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `types.gd` — Types.gd; lines 1-50 covering GameState and enum patterns
- `day_config.gd` — DayConfig resource class; per-day tuning fields
- `game_manager.gd` — GameManager autoload; lines 1-60 covering state and constants
- `campaign_manager.gd` — CampaignManager autoload; lines 1-60 covering campaign state
- `territory_data.gd` — TerritoryData resource class; territory ownership and bonuses

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
Produce an implementation spec for: the star difficulty tier system.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

REQUIREMENTS:
1. Add enum Types.DifficultyTier: NORMAL = 0, VETERAN = 1, NIGHTMARE = 2. Add matching C# mirror entry.
2. Define multiplier tables:
   - NORMAL: all 1.0x (base values from DayConfig)
   - VETERAN: enemy_hp 1.5x, enemy_damage 1.3x, gold_reward 1.2x, spawn_count 1.25x
   - NIGHTMARE: enemy_hp 2.5x, enemy_damage 2.0x, gold_reward 1.5x, spawn_count 1.75x
3. Add TerritoryData fields: highest_cleared_tier (Types.DifficultyTier), star_count (int 0-3, one star per tier cleared).
4. Design the selection UI: on the world map, each territory shows 0-3 stars. Clicking a cleared territory offers tier selection. Nightmare requires Veteran cleared first.
5. DayConfig integration: GameManager applies tier multipliers ON TOP of the day's base multipliers when starting a mission. Add a helper: get_effective_multiplier(base: float, tier: Types.DifficultyTier) -> float.
6. Rewards: Veteran completion grants a territory-specific perk (cosmetic or micro-buff). Nightmare grants a title.
7. Save integration: TerritoryData.highest_cleared_tier persists in save payload.
8. SignalBus: territory_tier_cleared(territory_id: String, tier: Types.DifficultyTier).

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 8: Star Difficulty

## Campaign and Progression (§13)

### Day/Wave Structure
- 50 days main campaign, 5 days short.
- Each mission = 5 waves (WAVES_PER_MISSION).
- After Day 50 final boss: loop continues until player wins or tower destroyed.

### Star Difficulty System
DOES NOT EXIST IN CODE. ON ROADMAP. Normal / Veteran / Nightmare per-map.

## DayConfig Tuning Fields

DayConfig resource has these multiplier fields:
- enemy_hp_multiplier (float)
- enemy_damage_multiplier (float)
- gold_reward_multiplier (float)
- spawn_count_multiplier (float)
- starting_gold (int)
- base_wave_count (int)
- faction_id (String)
- territory_id (String)

## TerritoryData Fields

- territory_id (String)
- display_name (String)
- is_controlled (bool)
- bonus fields for economy modifiers

5 territories: heartland_plains, blackwood_forest, ashen_swamp, iron_ridge, outer_city.

## GameManager API (§3.9, relevant methods only)

| Signature | Returns | Usage |
|-----------|---------|-------|
| start_mission_for_day(day_index: int, day_config: DayConfig) -> void | void | Initializes mission |
| get_day_config_for_index(day_index: int) -> DayConfig | DayConfig | Lookup from campaign |
| apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void | void | Updates territory |
| get_territory_data(territory_id: String) -> TerritoryData | TerritoryData | Lookup |

Constants: TOTAL_MISSIONS = 5, WAVES_PER_MISSION = 5.

## CampaignManager API (§3.6, relevant methods only)

| Signature | Returns | Usage |
|-----------|---------|-------|
| get_current_day() -> int | int | Current day index (1-based) |
| get_current_day_config() -> DayConfig | DayConfig | DayConfig for active day |

## Open TBD — Star Difficulty (§33)
| Item | Question | Who Decides |
|------|----------|-------------|
| Star difficulty multipliers | Exact HP/damage/gold multipliers for Veteran and Nightmare | Designer/playtester |

Decisions for this session: VETERAN: enemy_hp 1.5x, enemy_damage 1.3x, gold_reward 1.2x, spawn_count 1.25x. NIGHTMARE: enemy_hp 2.5x, enemy_damage 2.0x, gold_reward 1.5x, spawn_count 1.75x.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- Signals: past tense for events

FILES:

# Files to Upload for Session 8: Star Difficulty

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_08_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/types.gd` — Types.gd; lines 1-50 covering GameState and enum patterns (~50 lines)
2. `scripts/resources/day_config.gd` — DayConfig resource class; all tunable fields per day (~54 lines)
3. `autoloads/game_manager.gd` — GameManager autoload; lines 1-60 covering state and constants (~60 lines)
4. `autoloads/campaign_manager.gd` — CampaignManager autoload; lines 1-60 covering campaign state (~60 lines)
5. `scripts/resources/territory_data.gd` — TerritoryData resource class; territory ownership/bonuses (~87 lines)

Total estimated token load: ~311 lines across 5 files

scripts/types.gd:
## types.gd
## Global enums and constants for FOUL WARD. Accessed via Types.GameState, Types.DamageType, etc.
## Simulation API: all public methods callable without UI nodes present.

class_name Types

enum GameState {
	MAIN_MENU,
	MISSION_BRIEFING,
	COMBAT,
	BUILD_MODE,
	WAVE_COUNTDOWN,
	BETWEEN_MISSIONS,
	MISSION_WON,
	MISSION_FAILED,
	GAME_WON,
	## Terminal failure / game over (SimBot, meta-flow); distinct from per-mission MISSION_FAILED.
	GAME_OVER,
	## Between-mission hub while in Endless Run (same UI as BETWEEN_MISSIONS; no campaign cap).
	ENDLESS,
}

enum DamageType {
	PHYSICAL,
	FIRE,
	MAGICAL,
	POISON,
	## Ignores armor flat / shield ordering in [method EnemyBase.receive_damage] (Prompt 49).
	TRUE,
}

enum ArmorType {
	UNARMORED,
	HEAVY_ARMOR,
	UNDEAD,
	FLYING,
}

enum BuildingType {
	ARROW_TOWER,
	FIRE_BRAZIER,
	MAGIC_OBELISK,
	POISON_VAT,
	BALLISTA,
	ARCHER_BARRACKS,
	ANTI_AIR_BOLT,
	SHIELD_GENERATOR,
	# ─── SMALL TOWERS (indices 8–19) ───
	SPIKE_SPITTER, # 8   SMALL, PHYSICAL, ground
	EMBER_VENT, # 9   SMALL, FIRE, ground, DoT
	FROST_PINGER, # 10  SMALL, MAGICAL, ground, slow
	NETGUN, # 11  SMALL, PHYSICAL, ground, stop-on-hit
	ACID_DRIPPER, # 12  SMALL, POISON, ground, DoT
	WOLFDEN, # 13  SMALL, SUMMONER, 2 wolf summons
	CROW_ROOST, # 14  SMALL, AA, flying
	ALARM_TOTEMS, # 15  SMALL, AURA, speed debuff aura on enemies
	CROSSFIRE_NEST, # 16  SMALL, PHYSICAL, targets air+ground
	BOLT_SHRINE, # 17  SMALL, MAGICAL, area pulse every 3s
	THORNWALL, # 18  SMALL, PHYSICAL, passive damage to melee attackers
	FIELD_MEDIC, # 19  SMALL, HEALER, heals allies in radius
	# ─── MEDIUM TOWERS (indices 20–29) ───
	GREATBOW_TURRET, # 20  MEDIUM, PHYSICAL, high range
	MOLTEN_CASTER, # 21  MEDIUM, FIRE, splash AoE
	ARCANE_LENS, # 22  MEDIUM, MAGICAL, chains to 2 targets
	PLAGUE_MORTAR, # 23  MEDIUM, POISON, lobs to random ground pos
	BEAR_DEN, # 24  MEDIUM, SUMMONER, 1 bear + 1 wolf
	GUST_CANNON, # 25  MEDIUM, PHYSICAL, AA + knockback
	WARDEN_SHRINE, # 26  MEDIUM, AURA, +15% damage to all buildings in radius
	IRON_CLERIC, # 27  MEDIUM, HEALER, repairs damaged buildings
	SIEGE_BALLISTA, # 28  MEDIUM, PHYSICAL, piercing (hits up to 3 enemies)
	CHAIN_LIGHTNING, # 29  MEDIUM, MAGICAL, priority FLYING
	# ─── LARGE TOWERS (indices 30–35) ───
	FORTRESS_CANNON, # 30  LARGE, PHYSICAL, highest single-hit damage
	DRAGON_FORGE, # 31  LARGE, FIRE, wide AoE splash
	VOID_OBELISK, # 32  LARGE, MAGICAL, debuffs enemy armor on hit
	PLAGUE_CAULDRON, # 33  LARGE, POISON, persistent AoE cloud
	BARRACKS_FORTRESS, # 34  LARGE, SUMMONER, 2 knights + 2 archers
	CITADEL_AURA, # 35  LARGE, AURA, +20% damage + +10% fire rate to all buildings
}

## Modular building kit: base piece under `res://art/generated/kit/*.glb` (see FUTURE_3D_MODELS_PLAN.md §4).
enum BuildingBaseMesh {
	STONE_ROUND,
	STONE_SQUARE,
	WOOD_ROUND,
	RUINS_BASE,
}

## Modular building kit: top piece under `res://art/generated/kit/*.glb` (see FUTURE_3D_MODELS_PLAN.md §4).
enum BuildingTopMesh {
	ROOF_CONE,
	ROOF_FLAT,
	GLASS_DOME,
	FIRE_BOWL,
	POISON_TANK,
	BALLISTA_FRAME,
	EMBRASURE,
}

enum ArnulfState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DOWNED,
	RECOVERING,
}

enum ResourceType {
	GOLD,
	BUILDING_MATERIAL,
	RESEARCH_MATERIAL,
}

enum EnemyType {
	ORC_GRUNT,
	ORC_BRUTE,
	GOBLIN_FIREBUG,
	PLAGUE_ZOMBIE,
	ORC_ARCHER,
	BAT_SWARM,
	# ─── TIER 1 FODDER (indices 6–9) ───
	ORC_SKIRMISHER, # 6   T1, fast melee, RUSH
	ORC_RATLING, # 7   T1, tiny, spawns from Brood Carrier death
	GOBLIN_RUNTS, # 8   T1, 3-pack spawn, very low HP
	HOUND, # 9   T1, fast, high-speed RUSH
	# ─── TIER 2 STANDARD (indices 10–15) ───
	ORC_RAIDER, # 10  T2, standard melee
	ORC_MARKSMAN, # 11  T2, ranged physical
	WAR_SHAMAN, # 12  T2, SUPPORT: buffs nearby orc damage +20%
	PLAGUE_SHAMAN, # 13  T2, SUPPORT: heals nearby orcs 5 HP/s
	TOTEM_CARRIER, # 14  T2, SUPPORT: HP regen aura
	HARPY_SCOUT, # 15  T2, FLYING, fast flyer
	# ─── TIER 3 ELITE (indices 16–21) ───
	ORC_SHIELDBEARER, # 16  T3, HEAVY, physical shield absorbs first 80 dmg
	ORC_BERSERKER, # 17  T3, RUSH, enrages below 50% HP (+50% speed)
	ORC_SABOTEUR, # 18  T3, disables a building for 4s on reach
	HEXBREAKER, # 19  T3, dispels one player aura on hit
	WYVERN_RIDER, # 20  T3, FLYING, ranged fire attack
	BROOD_CARRIER, # 21  T3, spawns 3 ORC_RATLING on death
	# ─── TIER 4 HEAVY (indices 22–26) ───
	TROLL, # 22  T4, HEAVY, HP regen 8/s, slow
	IRONCLAD_CRUSHER, # 23  T4, HEAVY, high armor
	ORC_OGRE, # 24  T4, HEAVY, AoE melee smash
	WAR_BOAR, # 25  T4, RUSH+HEAVY, charge dash on approach
	ORC_SKYTHROWER, # 26  T4, RANGED, anti-air javelin priority
	# ─── TIER 5 BOSS-TIER (indices 27–29) ───
	WARLORDS_GUARD, # 27  T5, mini-elite escort
	ORCISH_SPIRIT, # 28  T5, FLYING, magic immune
	PLAGUE_HERALD, # 29  T5, SUPPORT+HEAVY, combines shaman aura + troll HP
}

enum AllyClass {
	MELEE,
	RANGED,
	SUPPORT,
}

enum WeaponSlot {
	CROSSBOW,
	RAPID_MISSILE,
}

# Used by buildings and allies for target selection preferences.
# AllyBase: CLOSEST / LOWEST_HP / HIGHEST_HP / FLYING_FIRST (see AllyData.preferred_targeting).
enum TargetPriority {
	CLOSEST,
	HIGHEST_HP,
	FLYING_FIRST,
	LOWEST_HP,
}

# NEW enums for ally roles and SimBot strategy profiles (Prompt 12).
enum AllyRole {
	MELEE_FRONTLINE,
	RANGED_SUPPORT,
	ANTI_AIR,
	SPELL_SUPPORT,
}

## Combat role for [AllyData] tower-defense data (Prompt 42). Distinct from [enum AllyRole] (mercenary / SimBot legacy).
enum AllyCombatRole {
	MELEE,
	RANGED,
	HEALER,
	BOMBER,
	AURA,
}

enum StrategyProfile {
	BALANCED,
	ALLY_HEAVY_PHYSICAL,
	ANTI_AIR_FOCUS,
	SPELL_FOCUS,
	BUILDING_FOCUS,
}

## Battle terrain preset for CampaignManager terrain scene selection (see FUTURE_3D_MODELS_PLAN.md §5).
enum TerrainType {
	GRASSLAND,
	FOREST,
	SWAMP,
	RUINS,
	TUNDRA,
}

## Modifier kind for TerrainZone; IMPASSABLE is documented for NavigationObstacle3D, not Area3D zones.
enum TerrainEffect {
	NONE,
	SLOW,
	IMPASSABLE,
}

# ASSUMPTION: HubRole enum is appended to keep existing enum numeric ordering stable.
# POST-MVP: Extend with FLORENCE, CAMPAIGN_SPECIFIC, etc. narrative requires.
enum HubRole {
	SHOP,
	RESEARCH,
	ENCHANT,
	MERCENARY,
	ALLY,
	FLAVOR_ONLY,
}

# Meta-state timeline advance reasons for Florence and between-mission narratives.
# Higher priority means "more important" to keep within the same advance window.
enum DayAdvanceReason {
	MISSION_COMPLETED,
	ACHIEVEMENT_EARNED,
	MAJOR_STORY_EVENT,
}

# --- Tower defense / mission data (Prompt 34) — must appear before any methods. ---

## Footprint category for data-driven building placement (hex rings, multi-slot).
enum BuildingSizeClass {
	SINGLE_SLOT,
	DOUBLE_WIDE,
	TRIPLE_CLUSTER,
	## Ring footprint tiers (Prompt 42); orthogonal to SINGLE_SLOT / DOUBLE_WIDE slot geometry.
	SMALL,
	MEDIUM,
	LARGE,
}

## Rough unit footprint for allies / summons (balance + pathing hints).
enum UnitSize {
	SMALL,
	MEDIUM,
	LARGE,
	HUGE,
}

## High-level ally behaviour mode (runtime AI may map multiple modes to one state machine).
enum AllyAiMode {
	DEFAULT,
	HOLD_POSITION,
	AGGRESSIVE,
	ESCORT,
	FOLLOW_LEADER,
}

## Summoned unit lifetime category (buildings + allies; Prompt 42).
enum SummonLifetimeType {
	NONE,
	MORTAL,
	RECURRING,
	IMMORTAL,
}

## Aura stacking / modification style for support towers and allies (legacy / extended tuning).
enum AuraModifierKind {
	ADD_FLAT,
	ADD_PERCENT,
	MULTIPLY,
}

## Simplified aura math mode for data resources (Prompt 42): additive vs multiplicative.
enum AuraModifierOp {
	ADD,
	MULTIPLY,
}

## Broad aura channel for UI filtering and exclusive rules.
enum AuraCategory {
	OFFENSE,
	DEFENSE,
	UTILITY,
	CONTROL,
}

## Stat column modified by an aura (data-driven; gameplay interprets).
enum AuraStat {
	DAMAGE,
	FIRE_RATE,
	RANGE,
	ARMOR,
	MAGIC_RESIST,
	MOVE_SPEED,
}

## Enemy locomotion / pathing class (distinct from ArmorType). Append-only: preserve existing ordinals.
enum EnemyBodyType {
	GROUND,
	FLYING,
	HOVER,
	BOSS,
	STRUCTURE,
	LARGE_GROUND,
	SIEGE,
	ETHEREAL,
}

## Content pipeline status for mission JSON / exports.
enum MissionBalanceStatus {
	UNSET,
	DRAFT,
	REVIEW,
	SHIPPED,
}

# SOURCE: Day/week advancement priority table pattern from management/roguelite design.
# TUNING: Adjust priorities as needed.
static func get_day_advance_priority(reason: DayAdvanceReason) -> int:
	match reason:
		DayAdvanceReason.MISSION_COMPLETED:
			# Baseline: still advances time, but is superseded by higher narrative drivers.
			return 0
		DayAdvanceReason.ACHIEVEMENT_EARNED:
			return 1
		DayAdvanceReason.MAJOR_STORY_EVENT:
			return 2
		_:
			return 0

# ASSUMPTION: Types uses enums + static helpers as a shared registry across systems.


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

autoloads/game_manager.gd:
## game_manager.gd
## State machine for overall game flow: missions, waves, and build mode in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.
##
## Territory + day summary:
## - CampaignConfig on CampaignManager defines DayConfig entries (mission_index, territory_id, waves, etc.).
## - CampaignManager tracks current_day; GameManager maps day to current_mission via DayConfig.mission_index.
## - TerritoryMapData lists all TerritoryData; GameManager mutates ownership flags on mission win/loss
##   and aggregates end-of-mission gold bonuses for EconomyManager.
## - MVP: player cannot choose territories; CampaignConfig fixes day→territory mapping.
##   POST-MVP: multi-front choices, boss advance after final day, factions, and research/enchant/upgrade
##   modifiers from TerritoryData hook into this layer.

extends Node

const TOTAL_MISSIONS: int = 5
# Temporary dev/testing cap so we can reach "mission won" quickly.
const WAVES_PER_MISSION: int = 5

const FlorenceDataType = preload("res://scripts/florence_data.gd")

## Optional reference path for the main 50-day campaign asset (documentation / tools).
## ASSUMPTION: Runtime loads territory map from CampaignManager.campaign_config.territory_map_resource_path.
const MAIN_CAMPAIGN_CONFIG_PATH: String = "res://resources/campaign_main_50days.tres"

var _active_allies: Array = []
var _ally_base_scene: PackedScene = preload("res://scenes/allies/ally_base.tscn")

var current_mission: int = 1
var current_wave: int = 0
## ASSUMPTION: meta campaign day index, 1-based (independent from CampaignManager.current_day).
var current_day: int = 1
var game_state: Types.GameState = Types.GameState.MAIN_MENU

## SOURCE: Roguelike meta-state Resource pattern (data-only model state).
var florence_data: FlorenceDataType = null

const INVALID_DAY_ADVANCE_REASON: int = -1
var _pending_day_advance_reason: int = INVALID_DAY_ADVANCE_REASON

## Loaded from the active campaign's territory_map_resource_path when set; otherwise null.
var territory_map: TerritoryMapData = null

# --- Final boss / post–Day-50 loop (Prompt 10) --------------------------------
var final_boss_id: String = ""
var final_boss_day_index: int = 50
var final_boss_active: bool = false
var final_boss_defeated: bool = false
var current_boss_threat_territory_id: String = ""
## ASSUMPTION: populated from TerritoryMapData or tests; used for random boss strikes.
var held_territory_ids: Array[String] = []
## Runtime-only day config when current_day exceeds CampaignConfig.day_configs (boss repeat days).
var _synthetic_boss_attack_day: DayConfig = null

func _ready() -> void:
	print("[GameManager] _ready: initial state=%s" % Types.GameState.keys()[game_state])
	if not SignalBus.all_waves_cleared.is_connected(_on_all_waves_cleared):
		SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
	if not SignalBus.tower_destroyed.is_connected(_on_tower_destroyed):
		SignalBus.tower_destroyed.connect(_on_tower_destroyed)
	# Autoload order: CampaignManager before GameManager — connect second so day increments first on mission_won.
	_connect_mission_won_transition_to_hub()
	var shop: Node = get_node_or_null("/root/Main/Managers/ShopManager")
	var tower: Node = get_node_or_null("/root/Main/Tower")
	if shop != null and tower != null and shop.has_method("initialize_tower"):
		shop.initialize_tower(tower)
	print("[GameManager] _ready: ShopManager wired to Tower")
	reload_territory_map_from_active_campaign()
	if not SignalBus.boss_killed.is_connected(_on_boss_killed):
		SignalBus.boss_killed.connect(_on_boss_killed)
	_sync_held_territories_from_map()
	if SaveManager.has_method("save_current_state"):
		var save_cb: Callable = func(_mission_number: int) -> void:
			SaveManager.save_current_state()
		if not SignalBus.mission_won.is_connected(save_cb):
			SignalBus.mission_won.connect(save_cb)
		if not SignalBus.mission_failed.is_connected(save_cb):
			SignalBus.mission_failed.connect(save_cb)


func _connect_mission_won_transition_to_hub() -> void:
	if SignalBus.mission_won.is_connected(_on_mission_won_transition_to_hub):
		return
	SignalBus.mission_won.connect(_on_mission_won_transition_to_hub)


## Runs after CampaignManager._on_mission_won (autoload order: CampaignManager before GameManager). Also used when tests emit mission_won without waves.
func _on_mission_won_transition_to_hub(mission_number: int) -> void:
	if CampaignManager.is_endless_mode:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)
		return
	var campaign_len: int = CampaignManager.get_campaign_length()
	var completed_day_index: int = mission_number
	var is_final_day: bool = campaign_len > 0 and completed_day_index == campaign_len
	var should_game_won: bool = false

	if campaign_len == 0 and mission_number >= TOTAL_MISSIONS:
		should_game_won = true
	elif is_final_day or final_boss_defeated:
		should_game_won = true

	if should_game_won:
		# ASSUMPTION: run_count increments only on full campaign completion for now.
		if florence_data != null:
			florence_data.run_count += 1
			SignalBus.florence_state_changed.emit()
		_transition_to(Types.GameState.GAME_WON)
	else:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)

# ── Public API ─────────────────────────────────────────────────────────────────

## Resets all game state and starts a fresh campaign from day one.
func start_new_game() -> void:
	print("[GameManager] start_new_game: mission=1  gold=%d mat=%d" % [
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	if CampaignManager.is_endless_mode:
		game_state = Types.GameState.ENDLESS
	_cleanup_allies()
	_reset_final_boss_campaign_state()
	current_mission = 1
	current_wave = 0
	EconomyManager.reset_to_defaults()
	EnchantmentManager.reset_to_defaults()
	# Ensure research unlock state is reset for a new run.
	# In dev mode, ResearchManager can choose to unlock all nodes to make
	# content reachable for testing (e.g., tower availability).
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm != null:
		rm.reset_to_defaults()
	var weapon_upgrade_manager: Node = get_node_or_null("/root/Main/Managers/WeaponUpgradeManager")
	if weapon_upgrade_manager != null:
		weapon_upgrade_manager.reset_to_defaults()

	# Florence meta-state bootstrap.
	# ASSUMPTION: New game starts meta day index at 1.
	current_day = 1
	_pending_day_advance_reason = INVALID_DAY_ADVANCE_REASON
	if florence_data == null:
		florence_data = FlorenceDataType.new()
	florence_data.reset_for_new_run()
	florence_data.update_day_threshold_flags(current_day)
	SignalBus.florence_state_changed.emit()
	# DEVIATION: CampaignManager owns day/campaign state and mission kickoff.
	CampaignManager.start_new_campaign()
	reload_territory_map_from_active_campaign()
	_sync_held_territories_from_map()

## Delegates to CampaignManager to begin the next day in the campaign.
func start_next_mission() -> void:
	# DEVIATION: next day is now owned by CampaignManager.
	# BetweenMissionScreen routes directly through CampaignManager, this remains for compatibility.
	CampaignManager.start_next_day()

## Begins the countdown timer before the first wave spawns.
func start_wave_countdown() -> void:
	if game_state != Types.GameState.MISSION_BRIEFING:
		push_warning("start_wave_countdown called from invalid state: %s" % Types.GameState.keys()[game_state])
		return
	_transition_to(Types.GameState.COMBAT)
	BuildPhaseManager.set_build_phase_active(false)
	SignalBus.mission_started.emit(current_mission)
	_spawn_allies_for_current_mission()
	_apply_shop_mission_start_consumables()
	# Single source of truth for countdown duration: WaveManager emits wave_countdown_started.
	_begin_mission_wave_sequence()

## Transitions the game state to BUILD_MODE, pausing enemy movement.
func enter_build_mode() -> void:
	print("[GameManager] enter_build_mode: from=%s" % Types.GameState.keys()[game_state])
	if game_state != Types.GameState.COMBAT and game_state != Types.GameState.WAVE_COUNTDOWN:
		push_warning("enter_build_mode called from invalid state: %s" % Types.GameState.keys()[game_state])
		return
	Engine.time_scale = 0.1
	var old: Types.GameState = game_state
	game_state = Types.GameState.BUILD_MODE
	BuildPhaseManager.set_build_phase_active(true)
	SignalBus.build_mode_entered.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.BUILD_MODE)

## Transitions the game state back to COMBAT from BUILD_MODE.
func exit_build_mode() -> void:
	print("[GameManager] exit_build_mode")
	Engine.time_scale = 1.0
	var old: Types.GameState = game_state
	game_state = Types.GameState.COMBAT
	BuildPhaseManager.set_build_phase_active(false)
	SignalBus.build_mode_exited.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.COMBAT)

## Returns the current GameState enum value.
func get_game_state() -> Types.GameState:
	return game_state

## Returns the current mission number (1-indexed).
func get_current_mission() -> int:
	return current_mission

## Returns the current wave index within the active mission.
func get_current_wave() -> int:
	return current_wave

## Returns the FlorenceData resource tracking protagonist meta-state.
func get_florence_data() -> FlorenceDataType:
	return florence_data

## Increments Florence's day counter with the given advance reason.
func advance_day(reason: Types.DayAdvanceReason) -> void:
	# SOURCE: Day/week advancement priority pattern using Types as central registry.
	var reason_priority: int = Types.get_day_advance_priority(reason)

	# ASSUMPTION: The “pending reasons” window is typically a mission resolution
	# (from win/fail events through state transitions).
	if _pending_day_advance_reason == INVALID_DAY_ADVANCE_REASON:
		_pending_day_advance_reason = int(reason)
		return

	var pending_priority: int = _get_day_advance_priority_from_int(_pending_day_advance_reason)
	if reason_priority > pending_priority:
		_pending_day_advance_reason = int(reason)


func _get_day_advance_priority_from_int(reason_id: int) -> int:
	# Godot does not allow casting enums via `Types.DayAdvanceReason(reason_id)` syntax.
	# We map the stored int back to the enum values via match.
	match reason_id:
		int(Types.DayAdvanceReason.MISSION_COMPLETED):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.MISSION_COMPLETED)
		int(Types.DayAdvanceReason.ACHIEVEMENT_EARNED):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.ACHIEVEMENT_EARNED)
		int(Types.DayAdvanceReason.MAJOR_STORY_EVENT):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.MAJOR_STORY_EVENT)
		_:
			return 0


func _apply_pending_day_advance_if_any() -> void:
	if _pending_day_advance_reason == INVALID_DAY_ADVANCE_REASON:
		return

	current_day += 1
	if florence_data != null:
		florence_data.total_days_played += 1
		florence_data.update_day_threshold_flags(current_day)

	SignalBus.florence_state_changed.emit()
	_pending_day_advance_reason = INVALID_DAY_ADVANCE_REASON

## Linear day index within the active campaign (1-based). Delegates to CampaignManager.
func get_current_day_index() -> int:
	return CampaignManager.get_current_day()


## Alias for tests / Prompt 10 (syncs calendar via CampaignManager.force_set_day).
var current_day_index: int:
	get:
		return CampaignManager.get_current_day()
	set(value):
		CampaignManager.force_set_day(value)


## Campaign timeline resource (same as CampaignManager.campaign_config).
var campaign_config: CampaignConfig:
	get:
		return CampaignManager.campaign_config
	set(value):
		CampaignManager.set_active_campaign_config_for_test(value)


## Returns the DayConfig for the given day index from the active campaign.
func get_day_config_for_index(day_index: int) -> DayConfig:
	if CampaignManager.is_endless_mode:
		return _create_synthetic_endless_day_config(day_index)
	var cfg: CampaignConfig = CampaignManager.campaign_config
	if cfg == null:
		return null
	for d: DayConfig in cfg.day_configs:
		if d != null and d.day_index == day_index:
			return d
	if day_index >= 1 and day_index <= cfg.day_configs.size():
		return cfg.day_configs[day_index - 1]
	if _synthetic_boss_attack_day != null and _synthetic_boss_attack_day.day_index == day_index:
		return _synthetic_boss_attack_day
	return null


func _create_synthetic_endless_day_config(day_index: int) -> DayConfig:
	var d: DayConfig = DayConfig.new()
	d.day_index = day_index
	d.mission_index = mini(day_index, TOTAL_MISSIONS)
	d.display_name = "Endless"
	d.faction_id = "DEFAULT_MIXED"
	d.base_wave_count = WAVES_PER_MISSION
	d.enemy_hp_multiplier = WaveManager.get_effective_enemy_hp_multiplier_for_day(day_index)
	d.enemy_damage_multiplier = d.enemy_hp_multiplier
	d.gold_reward_multiplier = 1.0
	d.spawn_count_multiplier = WaveManager.get_effective_spawn_count_multiplier_for_day(day_index)
	return d


## Returns a synthetic DayConfig for a boss-attack day.
func get_synthetic_boss_day_config() -> DayConfig:
	return _synthetic_boss_attack_day


## Advances calendar by one day; after a failed final boss, assigns a random threatened territory.
func advance_to_next_day() -> void:
	CampaignManager.force_set_day(CampaignManager.get_current_day() + 1)
	var day: DayConfig = get_day_config_for_index(CampaignManager.get_current_day())
	if final_boss_active and not final_boss_defeated:
		if day == null:
			day = _ensure_synthetic_boss_attack_day_config()
		_assign_boss_attack_to_day(day)


## Returns the DayConfig for the currently active day.
func get_current_day_config() -> DayConfig:
	return CampaignManager.get_current_day_config()


## Returns the territory_id for the current day's mission.
func get_current_day_territory_id() -> String:
	var day_config: DayConfig = get_current_day_config()
	if day_config == null:
		return ""
	return day_config.territory_id


## Returns the TerritoryData resource for the given territory_id.
func get_territory_data(territory_id: String) -> TerritoryData:
	if territory_map == null:
		return null
	return territory_map.get_territory_by_id(territory_id)


## Returns the TerritoryData for the territory of the current day.
func get_current_day_territory() -> TerritoryData:
	var id: String = get_current_day_territory_id()
	if id == "":
		return null
	return get_territory_data(id)


## Returns all TerritoryData entries in this map.
func get_all_territories() -> Array[TerritoryData]:
	if territory_map == null:
		return []
	return territory_map.get_all_territories()


## Reloads TerritoryMapData from CampaignManager.campaign_config.territory_map_resource_path.
func reload_territory_map_from_active_campaign() -> void:
	territory_map = null
	var cfg: CampaignConfig = CampaignManager.campaign_config
	if cfg == null:
		return
	if cfg.territory_map_resource_path == "":
		return
	var res: Resource = load(cfg.territory_map_resource_path)
	if res == null:
		push_error(
			"GameManager: Failed to load TerritoryMapData from %s"
			% cfg.territory_map_resource_path
		)
		return
	territory_map = res as TerritoryMapData
	if territory_map == null:
		push_error(
			"GameManager: Resource at %s is not a TerritoryMapData"
			% cfg.territory_map_resource_path
		)
		return
	territory_map.invalidate_cache()
	SignalBus.world_map_updated.emit()
	_sync_held_territories_from_map()


## Updates territory ownership and threat flags based on the day win/loss result.
func apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void:
	if territory_map == null or day_config == null:
		return
	if day_config.territory_id == "":
		return

	var territory: TerritoryData = territory_map.get_territory_by_id(day_config.territory_id)
	if territory == null:
		push_error(
			"GameManager: DayConfig references unknown territory_id '%s'."
			% day_config.territory_id
		)
		return

	# Prompt 10 MVP: failing a final boss encounter does not permanently conquer territory.
	if (
			not was_won
			and day_config.boss_id != ""
			and (day_config.is_final_boss or day_config.is_boss_attack_day)
	):
		return

	if was_won:
		territory.is_controlled_by_player = true
		# TUNING: MVP does not change is_permanently_lost on win; future campaigns
		# may allow recovery clearing this flag.
	else:
		territory.is_controlled_by_player = false
		territory.is_permanently_lost = true

	SignalBus.territory_state_changed.emit(territory.territory_id)
	SignalBus.world_map_updated.emit()


## Aggregates end-of-mission gold modifiers from all controlled territories.
## Keys: flat_gold_end_of_day (int), percent_gold_end_of_day (float additive fractions).
func get_current_territory_gold_modifiers() -> Dictionary:
	var result: Dictionary = {
		"flat_gold_end_of_day": 0,
		"percent_gold_end_of_day": 0.0,
	}
	if territory_map == null:
		return result

	for t: TerritoryData in territory_map.get_all_territories():
		if t == null:
			continue
		if not t.is_active_for_bonuses():
			continue
		result["flat_gold_end_of_day"] += t.get_effective_end_of_day_gold_flat()
		result["percent_gold_end_of_day"] += t.get_effective_end_of_day_gold_percent()
	return result


## Sum of bonus_flat_gold_per_kill from all territories that pass is_active_for_bonuses().
func get_aggregate_flat_gold_per_kill() -> int:
	var s: int = 0
	if territory_map == null:
		return 0
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		s += t.bonus_flat_gold_per_kill
	return s


## Product of bonus_research_cost_multiplier across active territories (empty map = 1.0).
func get_aggregate_research_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_research_cost_multiplier > 0.0:
			p *= t.bonus_research_cost_multiplier
	return p


## Returns the aggregated enchanting cost multiplier from all held territories.
func get_aggregate_enchanting_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_enchanting_cost_multiplier > 0.0:
			p *= t.bonus_enchanting_cost_multiplier
	return p


## Returns the aggregated weapon upgrade cost multiplier from all held territories.
func get_aggregate_weapon_upgrade_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_weapon_upgrade_cost_multiplier > 0.0:
			p *= t.bonus_weapon_upgrade_cost_multiplier
	return p


## Extra research material granted at end of a successful mission wave clear (not per-kill).
func get_aggregate_bonus_research_per_day() -> int:
	var s: int = 0
	if territory_map == null:
		return 0
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		s += t.bonus_research_per_day
	return s


## When DayConfig.faction_id is empty, use territory default_faction_id.
func get_effective_faction_id_for_territory(territory_id: String) -> String:
	if territory_id.strip_edges() == "" or territory_map == null:
		return ""
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return ""
	return t.default_faction_id.strip_edges()


## Initializes the mission for the given day index and DayConfig, then begins combat.
func start_mission_for_day(day_index: int, day_config: DayConfig) -> void:
	var mission_from_config: int = day_index
	if day_config != null:
		mission_from_config = day_config.mission_index
	current_mission = clampi(mission_from_config, 1, TOTAL_MISSIONS)
	current_wave = 0

	_transition_to(Types.GameState.COMBAT)
	BuildPhaseManager.set_build_phase_active(false)
	SignalBus.mission_started.emit(current_mission)
	_spawn_allies_for_current_mission()
	_apply_shop_mission_start_consumables()
	_begin_mission_wave_sequence()

# ── Private helpers ────────────────────────────────────────────────────────────

func _apply_shop_mission_start_consumables() -> void:
	var shop: ShopManager = get_node_or_null("/root/Main/Managers/ShopManager") as ShopManager
	if shop == null:
		return
	shop.apply_mission_start_consumables()


func _spawn_allies_for_current_mission() -> void:
	var main: Node = get_node_or_null("/root/Main")
	if main == null:
		push_warning(
			"GameManager: Main scene not found at /root/Main; skipping ally spawn (mission %d)."
			% current_mission
		)
		return

	var ally_container: Node3D = main.get_node_or_null("AllyContainer") as Node3D
	var spawn_points_root: Node3D = main.get_node_or_null("AllySpawnPoints") as Node3D
	if ally_container == null or spawn_points_root == null:
		push_warning(
			"GameManager: AllyContainer or AllySpawnPoints missing under Main; skipping ally spawn (mission %d)."
			% current_mission
		)
		return

	_cleanup_allies()

	var ally_datas: Array = CampaignManager.current_ally_roster
	var spawn_points: Array[Node3D] = []
	for child: Node in spawn_points_root.get_children():
		if child is Node3D:
			spawn_points.append(child as Node3D)

	if ally_datas.is_empty() or spawn_points.is_empty():
		return

	var index: int = 0
	for data: Variant in ally_datas:
		if data == null:
			continue
		var ally: Node = _ally_base_scene.instantiate()
		if ally == null:
			continue

		ally_container.add_child(ally)
		var spawn_point: Node3D = spawn_points[index % spawn_points.size()] as Node3D
		ally.global_position = spawn_point.global_position

		if ally.has_method("initialize_ally_data"):
			ally.call("initialize_ally_data", data)
		_active_allies.append(ally)

		index += 1


func _cleanup_allies() -> void:
	for ally: Variant in _active_allies:
		if ally != null and is_instance_valid(ally):
			(ally as Node).queue_free()
	_active_allies.clear()


func _begin_mission_wave_sequence() -> void:
	var main: Node = get_tree().root.get_node_or_null("Main")
	if main == null:
		push_warning(
			"GameManager: Main scene not found at /root/Main; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	var managers: Node = main.get_node_or_null("Managers")
	if managers == null:
		push_warning(
			"GameManager: Managers node not found at /root/Main/Managers; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	var wave_manager: WaveManager = managers.get_node_or_null("WaveManager") as WaveManager
	if wave_manager == null:
		push_warning(
			"GameManager: WaveManager not found at /root/Main/Managers/WaveManager; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	print("[GameManager] _begin_mission_wave_sequence: mission=%d" % current_mission)
	wave_manager.ensure_boss_registry_loaded()
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	if day_cfg != null and day_cfg.mission_economy != null:
		EconomyManager.apply_mission_economy(day_cfg.mission_economy)
	else:
		EconomyManager.reset_for_mission()
	_update_final_boss_tracking_from_day(day_cfg)
	wave_manager.reset_for_new_mission()
	# Apply day config after reset — reset clears per-day tuning (waves, faction, multipliers).
	wave_manager.configure_for_day(day_cfg)
	wave_manager.call_deferred("start_wave_sequence")

func _transition_to(new_state: Types.GameState) -> void:
	var resolved: Types.GameState = new_state
	if new_state == Types.GameState.BETWEEN_MISSIONS and CampaignManager.is_endless_mode:
		resolved = Types.GameState.ENDLESS
	if game_state == resolved:
		return
	var old_name: String = Types.GameState.keys()[game_state]
	var new_name: String = Types.GameState.keys()[resolved]
	print("[GameManager] state: %s → %s" % [old_name, new_name])
	var old: Types.GameState = game_state
	game_state = resolved
	SignalBus.game_state_changed.emit(old, resolved)

func _on_all_waves_cleared() -> void:
	_cleanup_allies()
	print("[GameManager] all_waves_cleared: awarding mission=%d resources" % current_mission)
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	apply_day_result_to_territory(day_cfg, true)

	var base_gold_reward: int = 50 * current_mission
	var modifiers: Dictionary = get_current_territory_gold_modifiers()
	var flat_bonus: int = int(modifiers.get("flat_gold_end_of_day", 0))
	var percent_bonus: float = float(modifiers.get("percent_gold_end_of_day", 0.0))
	var total_gold: int = base_gold_reward + flat_bonus
	if percent_bonus != 0.0:
		total_gold = int(round(float(total_gold) * (1.0 + percent_bonus)))

	EconomyManager.add_gold(total_gold)
	EconomyManager.add_building_material(3)
	var extra_rm: int = get_aggregate_bonus_research_per_day()
	EconomyManager.add_research_material(2 + extra_rm)
	# Snapshot before mission_won: CampaignManager may increment current_day on mission_won.
	var completed_day_index: int = CampaignManager.get_current_day()

	if (
			day_cfg != null
			and day_cfg.boss_id != ""
			and (day_cfg.is_final_boss or day_cfg.is_boss_attack_day)
	):
		final_boss_id = day_cfg.boss_id
		final_boss_defeated = true
		final_boss_active = false
		_synthetic_boss_attack_day = null
		SignalBus.campaign_boss_attempted.emit(completed_day_index, true)

	# Florence meta-state updates (run meta-progression).
	if florence_data != null and not CampaignManager.is_endless_mode:
		florence_data.total_missions_played += 1
		advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
		_apply_pending_day_advance_if_any()

	SignalBus.mission_won.emit(CampaignManager.get_current_day())

func _on_tower_destroyed() -> void:
	_cleanup_allies()
	print("[GameManager] tower_destroyed → MISSION_FAILED")
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	var completed_day_index: int = CampaignManager.get_current_day()

	# Florence meta-state updates (counts mission attempts).
	if florence_data != null and not CampaignManager.is_endless_mode:
		florence_data.total_missions_played += 1
		florence_data.mission_failures += 1
		advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
		_apply_pending_day_advance_if_any()
	if (
			day_cfg != null
			and day_cfg.boss_id != ""
			and (day_cfg.is_final_boss or day_cfg.is_boss_attack_day)
			and not final_boss_defeated
	):
		final_boss_id = day_cfg.boss_id
		final_boss_active = true
		SignalBus.campaign_boss_attempted.emit(completed_day_index, false)
	else:
		apply_day_result_to_territory(day_cfg, false)
	_transition_to(Types.GameState.MISSION_FAILED)
	# Snapshot from entry — advance_day above may have incremented CampaignManager.current_day.
	SignalBus.mission_failed.emit(completed_day_index)


## Pre-loads the next day's DayConfig into WaveManager if not already prepared.
func prepare_next_campaign_day_if_needed() -> void:
	if not final_boss_active or final_boss_defeated:
		return
	advance_to_next_day()


## TEST-ONLY: resets Prompt 10 boss campaign fields without starting a new game.
func reset_boss_campaign_state_for_test() -> void:
	_reset_final_boss_campaign_state()


func _reset_final_boss_campaign_state() -> void:
	final_boss_id = ""
	final_boss_day_index = 50
	final_boss_active = false
	final_boss_defeated = false
	current_boss_threat_territory_id = ""
	held_territory_ids.clear()
	_synthetic_boss_attack_day = null


func _sync_held_territories_from_map() -> void:
	held_territory_ids.clear()
	if territory_map == null:
		return
	for t: TerritoryData in territory_map.get_all_territories():
		if t != null and t.is_controlled_by_player:
			held_territory_ids.append(t.territory_id)


func _update_final_boss_tracking_from_day(day_cfg: DayConfig) -> void:
	if day_cfg == null:
		return
	if day_cfg.boss_id != "":
		final_boss_id = day_cfg.boss_id
	if day_cfg.is_final_boss:
		final_boss_day_index = day_cfg.day_index


func _ensure_synthetic_boss_attack_day_config() -> DayConfig:
	var syn: DayConfig = DayConfig.new()
	syn.day_index = CampaignManager.current_day
	syn.mission_index = 5
	syn.display_name = "Boss strike"
	syn.description = "PLACEHOLDER: The campaign boss strikes again."
	syn.faction_id = "PLAGUE_CULT"
	syn.base_wave_count = 5
	syn.enemy_hp_multiplier = 1.0
	syn.enemy_damage_multiplier = 1.0
	syn.gold_reward_multiplier = 1.0
	syn.is_mini_boss_day = false
	syn.is_mini_boss = false
	syn.is_final_boss = true
	syn.is_boss_attack_day = true
	syn.boss_id = final_boss_id
	_synthetic_boss_attack_day = syn
	return syn


func _assign_boss_attack_to_day(day_config: DayConfig) -> void:
	if day_config == null:
		return
	if held_territory_ids.is_empty():
		_sync_held_territories_from_map()
	if held_territory_ids.is_empty():
		return
	var idx: int = randi() % held_territory_ids.size()
	current_boss_threat_territory_id = held_territory_ids[idx]
	day_config.territory_id = current_boss_threat_territory_id
	day_config.is_boss_attack_day = true
	day_config.is_final_boss = true
	day_config.boss_id = final_boss_id
	_mark_territory_boss_threat(current_boss_threat_territory_id, true)


func _mark_territory_boss_threat(territory_id: String, threatened: bool) -> void:
	if territory_map == null or territory_id == "":
		return
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return
	t.has_boss_threat = threatened
	SignalBus.territory_state_changed.emit(territory_id)


func _on_boss_killed(boss_id: String) -> void:
	CampaignManager.notify_mini_boss_defeated(boss_id)
	var data: BossData = _get_boss_data(boss_id)
	if data != null and data.is_mini_boss and data.associated_territory_id != "":
		_mark_territory_secured(data.associated_territory_id)


func _get_boss_data(boss_id: String) -> BossData:
	for path: String in BossData.BUILTIN_BOSS_RESOURCE_PATHS:
		var res: Resource = load(path)
		if res is BossData:
			var b: BossData = res as BossData
			if b.boss_id == boss_id:
				return b
	return null


func _mark_territory_secured(territory_id: String) -> void:
	if territory_map == null or territory_id == "":
		return
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return
	t.is_secured = true
	t.has_boss_threat = false
	SignalBus.territory_state_changed.emit(territory_id)


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	var mana: int = 0
	if spell != null:
		mana = spell.get_current_mana()
	var florence_dict: Dictionary = {}
	if florence_data != null:
		florence_dict = {
			"total_days_played": florence_data.total_days_played,
			"run_count": florence_data.run_count,
			"total_missions_played": florence_data.total_missions_played,
			"boss_attempts": florence_data.boss_attempts,
			"boss_victories": florence_data.boss_victories,
			"mission_failures": florence_data.mission_failures,
			"has_unlocked_research": florence_data.has_unlocked_research,
			"has_unlocked_enchantments": florence_data.has_unlocked_enchantments,
			"has_recruited_any_mercenary": florence_data.has_recruited_any_mercenary,
			"has_seen_any_mini_boss": florence_data.has_seen_any_mini_boss,
			"has_defeated_any_mini_boss": florence_data.has_defeated_any_mini_boss,
			"has_reached_day_25": florence_data.has_reached_day_25,
			"has_reached_day_50": florence_data.has_reached_day_50,
			"has_seen_first_boss": florence_data.has_seen_first_boss,
		}
	return {
		"game_state": int(game_state),
		"final_boss_defeated": final_boss_defeated,
		"current_gold": EconomyManager.get_gold(),
		"current_building_material": EconomyManager.get_building_material(),
		"current_research_material": EconomyManager.get_research_material(),
		"current_mana": mana,
		"current_mission": current_mission,
		"current_wave": current_wave,
		"current_day": CampaignManager.get_current_day(),
		"florence_data": florence_dict,
		"final_boss_id": final_boss_id,
		"final_boss_day_index": final_boss_day_index,
		"final_boss_active": final_boss_active,
		"current_boss_threat_territory_id": current_boss_threat_territory_id,
	}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	var gs: int = int(data.get("game_state", int(Types.GameState.MAIN_MENU)))
	game_state = gs as Types.GameState
	final_boss_defeated = bool(data.get("final_boss_defeated", false))
	current_mission = int(data.get("current_mission", 1))
	current_wave = int(data.get("current_wave", 0))
	current_day = int(data.get("current_day", 1))
	final_boss_id = str(data.get("final_boss_id", ""))
	final_boss_day_index = int(data.get("final_boss_day_index", 50))
	final_boss_active = bool(data.get("final_boss_active", false))
	current_boss_threat_territory_id = str(data.get("current_boss_threat_territory_id", ""))
	EconomyManager.apply_save_snapshot(
		int(data.get("current_gold", EconomyManager.get_gold())),
		int(data.get("current_building_material", EconomyManager.get_building_material())),
		int(data.get("current_research_material", EconomyManager.get_research_material()))
	)
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	if spell != null:
		spell.set_mana_for_save_restore(int(data.get("current_mana", 0)))
	if florence_data == null:
		florence_data = FlorenceDataType.new()
	var fd: Variant = data.get("florence_data", {})
	if fd is Dictionary:
		var fdd: Dictionary = fd as Dictionary
		florence_data.total_days_played = int(fdd.get("total_days_played", florence_data.total_days_played))
		florence_data.run_count = int(fdd.get("run_count", florence_data.run_count))
		florence_data.total_missions_played = int(fdd.get("total_missions_played", florence_data.total_missions_played))
		florence_data.boss_attempts = int(fdd.get("boss_attempts", florence_data.boss_attempts))
		florence_data.boss_victories = int(fdd.get("boss_victories", florence_data.boss_victories))
		florence_data.mission_failures = int(fdd.get("mission_failures", florence_data.mission_failures))
		florence_data.has_unlocked_research = bool(fdd.get("has_unlocked_research", florence_data.has_unlocked_research))
		florence_data.has_unlocked_enchantments = bool(fdd.get("has_unlocked_enchantments", florence_data.has_unlocked_enchantments))
		florence_data.has_recruited_any_mercenary = bool(fdd.get("has_recruited_any_mercenary", florence_data.has_recruited_any_mercenary))
		florence_data.has_seen_any_mini_boss = bool(fdd.get("has_seen_any_mini_boss", florence_data.has_seen_any_mini_boss))
		florence_data.has_defeated_any_mini_boss = bool(fdd.get("has_defeated_any_mini_boss", florence_data.has_defeated_any_mini_boss))
		florence_data.has_reached_day_25 = bool(fdd.get("has_reached_day_25", florence_data.has_reached_day_25))
		florence_data.has_reached_day_50 = bool(fdd.get("has_reached_day_50", florence_data.has_reached_day_50))
		florence_data.has_seen_first_boss = bool(fdd.get("has_seen_first_boss", florence_data.has_seen_first_boss))
		florence_data.update_day_threshold_flags(current_day)
	SignalBus.florence_state_changed.emit()


## Restores the set of held territory IDs from a saved snapshot.
func apply_save_held_territory_ids(ids: Array[String]) -> void:
	held_territory_ids = ids.duplicate()
	if territory_map == null:
		return
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null:
			continue
		t.is_controlled_by_player = held_territory_ids.has(t.territory_id)
	SignalBus.world_map_updated.emit()

autoloads/campaign_manager.gd:
## campaign_manager.gd
## Campaign/day-level state controller above GameManager mission flow.
## Owns campaign progress, DayConfig lookup, ally roster, mercenary offers, and mini-boss defection.
## DEVIATION: Mercenary/MiniBoss resource types are referenced as Resource/Variant here so this autoload
## parses before global `class_name` registration (same pattern as Prompt 11 ally roster).

extends Node

const DEFAULT_SHORT_CAMPAIGN: CampaignConfig = preload("res://resources/campaigns/campaign_short_5_days.tres")
const FactionDataType = preload("res://scripts/resources/faction_data.gd")
const DEFAULT_MERCENARY_CATALOG_PATH: String = "res://resources/mercenary_catalog.tres"
const _MERCENARY_OFFER_DATA_GD: GDScript = preload("res://scripts/resources/mercenary_offer_data.gd")
const _TERRAIN_GRASSLAND_SCENE: PackedScene = preload("res://scenes/terrain/terrain_grassland.tscn")
const _TERRAIN_SWAMP_SCENE: PackedScene = preload("res://scenes/terrain/terrain_swamp.tscn")

var current_day: int = 1
var campaign_length: int = 0
var campaign_id: String = ""
var campaign_completed: bool = false
## Endless Run from main menu: no campaign cap, no narrative/dialogue hooks from day start.
var is_endless_mode: bool = false
## When false, day progression handlers ignore `mission_won` / `mission_failed` (no `start_new_campaign()` yet).
var _has_active_campaign_run: bool = false
var failed_attempts_on_current_day: int = 0
var current_day_config: DayConfig = null
var campaign_config: CampaignConfig = null

## Loaded from FactionData.BUILTIN_FACTION_RESOURCE_PATHS (String -> FactionData).
var faction_registry: Dictionary = {}

# ASSUMPTION: all ally `.tres` files live under `res://resources/ally_data/`.
var _ally_registry: Dictionary = {}

## Loaded from `res://resources/miniboss_data/*.tres` (boss_id -> Resource).
var _mini_boss_registry: Dictionary = {}

## MercenaryCatalog resource supplying the pool of recruitable mercenary offers.
@export var mercenary_catalog: Resource = null

var owned_allies: Array[String] = []
var active_allies_for_next_day: Array[String] = []
var max_active_allies_per_day: int = 2 # TUNING

var current_mercenary_offers: Array = []
var _defeated_defectable_bosses: Array[String] = []

var current_ally_roster: Array = []
var current_ally_roster_ids: Array[String] = []

## The currently active CampaignConfig resource driving day/faction progression.
@export var active_campaign_config: CampaignConfig


func _ready() -> void:
	_load_faction_registry()
	_load_ally_registry()
	_load_mini_boss_registry()
	_ensure_default_mercenary_catalog()
	if not SignalBus.mission_won.is_connected(_on_mission_won):
		SignalBus.mission_won.connect(_on_mission_won)
	if not SignalBus.mission_failed.is_connected(_on_mission_failed):
		SignalBus.mission_failed.connect(_on_mission_failed)
	if active_campaign_config == null:
		active_campaign_config = DEFAULT_SHORT_CAMPAIGN
	if active_campaign_config != null:
		_set_campaign_config(active_campaign_config)


func _ensure_default_mercenary_catalog() -> void:
	if mercenary_catalog != null:
		return
	var res: Resource = load(DEFAULT_MERCENARY_CATALOG_PATH) as Resource
	if res != null and res.has_method("get_daily_offers"):
		mercenary_catalog = res


func _load_ally_registry() -> void:
	_ally_registry.clear()
	var dir: DirAccess = DirAccess.open("res://resources/ally_data/")
	if dir == null:
		return
	dir.list_dir_begin()
	var fn: String = dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var loaded: Resource = load("res://resources/ally_data/%s" % fn) as Resource
			var ad_reg: AllyData = loaded as AllyData
			if ad_reg != null and ad_reg.ally_id != "":
				_ally_registry[ad_reg.ally_id] = loaded
		fn = dir.get_next()
	dir.list_dir_end()


func _load_mini_boss_registry() -> void:
	_mini_boss_registry.clear()
	var dir: DirAccess = DirAccess.open("res://resources/miniboss_data/")
	if dir == null:
		return
	dir.list_dir_begin()
	var fn: String = dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var loaded: Resource = load("res://resources/miniboss_data/%s" % fn) as Resource
			if loaded != null and str(loaded.get("boss_id")) != "":
				_mini_boss_registry[str(loaded.get("boss_id"))] = loaded
		fn = dir.get_next()
	dir.list_dir_end()


## Loads the default short campaign and initializes the day/faction/roster state.
func start_new_campaign() -> void:
	_has_active_campaign_run = true
	if not is_endless_mode:
		if active_campaign_config != null and campaign_config != active_campaign_config:
			_set_campaign_config(active_campaign_config)

	current_day = 1
	failed_attempts_on_current_day = 0
	campaign_completed = false
	current_mercenary_offers.clear()
	_defeated_defectable_bosses.clear()
	_load_ally_registry()
	_load_mini_boss_registry()
	_ensure_default_mercenary_catalog()
	_bootstrap_starter_allies()

	if campaign_config != null:
		campaign_length = campaign_config.get_effective_length()

	if not is_endless_mode:
		SignalBus.campaign_started.emit(campaign_id)
	_start_current_day_internal()


## Initializes the campaign for endless mode with synthetic day scaling.
func start_endless_run() -> void:
	is_endless_mode = true
	campaign_completed = false
	current_day = 1
	var stub: CampaignConfig = CampaignConfig.new()
	stub.campaign_id = "endless"
	stub.day_configs = []
	active_campaign_config = stub
	_set_campaign_config(stub)
	SignalBus.campaign_started.emit("endless")


func _bootstrap_starter_allies() -> void:
	owned_allies.clear()
	active_allies_for_next_day.clear()
	for ally_id: String in _ally_registry.keys():
		var d: Resource = _ally_registry[ally_id] as Resource
		var ad_boot: AllyData = d as AllyData
		if ad_boot != null and ad_boot.is_starter_ally:
			if not owned_allies.has(ally_id):
				owned_allies.append(ally_id)
	_apply_default_active_selection()
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


func _load_terrain(territory: TerritoryData) -> void:
	# TODO(TERRAIN): FOREST, RUINS, TUNDRA scenes pending — see FUTURE_3D_MODELS_PLAN.md §5.
	var terrain_map: Dictionary = {
		Types.TerrainType.GRASSLAND: _TERRAIN_GRASSLAND_SCENE,
		Types.TerrainType.SWAMP: _TERRAIN_SWAMP_SCENE,
	}
	var packed: PackedScene = terrain_map.get(
			territory.terrain_type,
			terrain_map[Types.TerrainType.GRASSLAND]
	) as PackedScene
	var main: Node = get_tree().root.get_node_or_null("Main")
	if main == null:
		push_warning("CampaignManager._load_terrain: /root/Main not in tree; skipping terrain load.")
		return
	var container: Node = main.get_node_or_null("TerrainContainer")
	if container == null:
		push_warning("CampaignManager._load_terrain: Main/TerrainContainer missing; skipping terrain load.")
		return
	for child: Node in container.get_children():
		child.queue_free()
	var terrain_instance: Node = packed.instantiate()
	container.add_child(terrain_instance)
	var nav_region: NavigationRegion3D = terrain_instance.find_child("NavRegion", true, false) as NavigationRegion3D
	if nav_region != null:
		NavMeshManager.register_region(nav_region)
	# TODO(TERRAIN): Add remaining TerrainType entries to terrain_map as
	# terrain_forest, terrain_ruins, terrain_tundra scenes are created.


## Returns true if the ally with the given ally_id is in the owned roster.
func is_ally_owned(ally_id: String) -> bool:
	return owned_allies.has(ally_id)


## Returns the Array of ally_ids currently owned (recruited) by the player.
func get_owned_allies() -> Array[String]:
	return owned_allies.duplicate()


## Returns the Array of ally_ids selected to participate in the next mission.
func get_active_allies() -> Array[String]:
	return active_allies_for_next_day.duplicate()


## Returns the AllyData resource for the given ally_id, or null if not owned.
func get_ally_data(ally_id: String) -> Resource:
	var r: Variant = _ally_registry.get(ally_id, null)
	return r as Resource


## Adds the given ally_id to owned roster and emits ally_roster_changed.
func add_ally_to_roster(ally_id: String) -> void:
	if ally_id.is_empty():
		return
	if owned_allies.has(ally_id):
		return
	owned_allies.append(ally_id)
	SignalBus.ally_roster_changed.emit()


## Removes the given ally_id from owned and active rosters and emits ally_roster_changed.
func remove_ally_from_roster(ally_id: String) -> void:
	var i: int = owned_allies.find(ally_id)
	if i >= 0:
		owned_allies.remove_at(i)
	var j: int = active_allies_for_next_day.find(ally_id)
	if j >= 0:
		active_allies_for_next_day.remove_at(j)
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


## Toggles whether the given ally_id is in the active-for-next-mission set.
func toggle_ally_active(ally_id: String) -> bool:
	if not is_ally_owned(ally_id):
		return false
	var idx: int = active_allies_for_next_day.find(ally_id)
	if idx >= 0:
		active_allies_for_next_day.remove_at(idx)
		_sync_current_ally_roster_for_spawn()
		SignalBus.ally_roster_changed.emit()
		return true
	if active_allies_for_next_day.size() >= max_active_allies_per_day:
		return false
	active_allies_for_next_day.append(ally_id)
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()
	return true


## Replaces the active ally list with the provided Array of ally_ids.
func set_active_allies_from_list(ally_ids: Array[String]) -> void:
	active_allies_for_next_day.clear()
	for aid: String in ally_ids:
		if not is_ally_owned(aid):
			continue
		if active_allies_for_next_day.size() >= max_active_allies_per_day:
			break
		if not active_allies_for_next_day.has(aid):
			active_allies_for_next_day.append(aid)
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


## Returns the ally_ids that should spawn at the start of the next mission.
func get_allies_for_mission_start() -> Array[String]:
	if active_allies_for_next_day.is_empty() and not owned_allies.is_empty():
		_apply_default_active_selection()
		_sync_current_ally_roster_for_spawn()
	return active_allies_for_next_day.duplicate()


## Generates mercenary offers for the given day from the mercenary catalog.
func generate_offers_for_day(day: int) -> void:
	var defection_offers: Array = []
	for o: Variant in current_mercenary_offers:
		if o != null and bool(o.get("is_defection_offer")):
			defection_offers.append(o)
	current_mercenary_offers.clear()
	for o: Variant in defection_offers:
		current_mercenary_offers.append(o)
	if mercenary_catalog == null or not mercenary_catalog.has_method("get_daily_offers"):
		for o2: Variant in current_mercenary_offers:
			if o2 != null:
				SignalBus.mercenary_offer_generated.emit(str(o2.get("ally_id")))
		return
	var catalog_offers: Variant = mercenary_catalog.call("get_daily_offers", day, owned_allies)
	if catalog_offers is Array:
		for o3: Variant in catalog_offers as Array:
			current_mercenary_offers.append(o3)
	for o4: Variant in current_mercenary_offers:
		if o4 != null:
			SignalBus.mercenary_offer_generated.emit(str(o4.get("ally_id")))


## Returns what offers would be available given a hypothetical owned ally list.
func preview_mercenary_offers_for_day(day: int, hypothetical_owned: Array[String]) -> Array:
	if mercenary_catalog == null or not mercenary_catalog.has_method("get_daily_offers"):
		return []
	var arr: Variant = mercenary_catalog.call("get_daily_offers", day, hypothetical_owned)
	return arr as Array if arr is Array else []


## Returns the current Array of mercenary offers generated for this day.
func get_current_offers() -> Array:
	return current_mercenary_offers.duplicate()


## Attempts to purchase the offer at the given index; spends resources and adds the ally.
func purchase_mercenary_offer(index: int) -> bool:
	if index < 0 or index >= current_mercenary_offers.size():
		return false
	var offer: Variant = current_mercenary_offers[index]
	if offer == null:
		return false
	if not _can_afford_offer(offer):
		return false
	var cg: int = int(offer.get("cost_gold"))
	var cb: int = int(offer.get("cost_building_material"))
	var cr: int = int(offer.get("cost_research_material"))
	if cg > 0 and not EconomyManager.spend_gold(cg):
		return false
	if cb > 0 and not EconomyManager.spend_building_material(cb):
		return false
	if cr > 0 and not EconomyManager.spend_research_material(cr):
		return false
	var new_id: String = str(offer.get("ally_id"))
	if not owned_allies.has(new_id):
		owned_allies.append(new_id)
	if active_allies_for_next_day.size() < max_active_allies_per_day:
		if not active_allies_for_next_day.has(new_id):
			active_allies_for_next_day.append(new_id)
	_sync_current_ally_roster_for_spawn()
	current_mercenary_offers.remove_at(index)
	SignalBus.mercenary_recruited.emit(new_id)
	SignalBus.ally_roster_changed.emit()
	return true


## Handles a mini-boss defeat: may add defection ally offer to the catalog.
func notify_mini_boss_defeated(boss_id: String) -> void:
	if boss_id.is_empty() or _defeated_defectable_bosses.has(boss_id):
		return
	var mb: Variant = _mini_boss_registry.get(boss_id, null)
	if mb == null or not bool(mb.get("can_defect_to_ally")):
		return
	_defeated_defectable_bosses.append(boss_id)
	if int(mb.get("defection_day_offset")) == 0:
		_inject_defection_offer(mb as Resource)


## Registers a BossData resource in the mini-boss registry for potential defection.
func register_mini_boss(boss_data: Resource) -> void:
	if boss_data == null:
		return
	var bid: String = str(boss_data.get("boss_id"))
	if bid.is_empty():
		return
	_mini_boss_registry[bid] = boss_data


func _inject_defection_offer(boss_data: Resource) -> void:
	var offer: Resource = _MERCENARY_OFFER_DATA_GD.new() as Resource
	offer.set("ally_id", str(boss_data.get("defected_ally_id")))
	offer.set("cost_gold", int(boss_data.get("defection_cost_gold")))
	offer.set("cost_building_material", 0)
	offer.set("cost_research_material", 0)
	offer.set("is_defection_offer", true)
	offer.set("min_day", current_day)
	offer.set("max_day", -1)
	current_mercenary_offers.append(offer)
	SignalBus.mercenary_offer_generated.emit(str(offer.get("ally_id")))


# SOURCE: Simple deterministic soldier/officer scoring (XCOM-style talks); weighted role + cost + diversity.
## Selects the best subset of owned allies up to the given max count.
func auto_select_best_allies(
		strategy_profile: Types.StrategyProfile,
		available_offers: Array,
		current_roster: Array[String],
		max_purchases: int,
		budget_gold: int,
		budget_material: int,
		budget_research: int
) -> Dictionary:
	var scored: Array = _sort_offers_by_value(
			available_offers,
			current_roster,
			budget_gold,
			budget_material,
			budget_research,
			strategy_profile
	)
	var budget: Dictionary = {
		"gold": budget_gold,
		"material": budget_material,
		"research": budget_research,
	}
	var fill: Dictionary = _greedy_fill_roster(scored, budget, max_purchases, current_roster)
	var raw_indices: Variant = fill.get("recommended_indices", [])
	var recommended_indices: Array[int] = []
	if raw_indices is Array:
		for v: Variant in raw_indices as Array:
			recommended_indices.append(int(v))
	var raw_roster: Variant = fill.get("sim_roster", [])
	var sim_roster: Array[String] = []
	if raw_roster is Array:
		for s2: Variant in raw_roster as Array:
			sim_roster.append(str(s2))
	var recommended_active: Array[String] = _pick_best_active(sim_roster, strategy_profile)
	return {
		"recommended_offer_indices": recommended_indices,
		"recommended_active_allies": recommended_active,
	}


## Builds a scored and sorted array of affordable, non-roster offers.
## Each element is a Dictionary with keys: i (original index), score (float), offer (Variant).
func _sort_offers_by_value(
		offers: Array,
		current_roster: Array[String],
		budget_gold: int,
		budget_material: int,
		budget_research: int,
		strategy_profile: Types.StrategyProfile
) -> Array:
	var scored: Array[Dictionary] = []
	var idx: int = 0
	for offer: Variant in offers:
		if offer == null:
			idx += 1
			continue
		var aid: String = str(offer.get("ally_id"))
		if current_roster.has(aid):
			idx += 1
			continue
		var og: int = int(offer.get("cost_gold"))
		var ob: int = int(offer.get("cost_building_material"))
		var orr: int = int(offer.get("cost_research_material"))
		if og > budget_gold or ob > budget_material or orr > budget_research:
			idx += 1
			continue
		var ad: Resource = get_ally_data(aid)
		if ad == null:
			idx += 1
			continue
		var s: float = _score_offer(offer, ad, strategy_profile, current_roster)
		scored.append({"i": idx, "score": s, "offer": offer})
		idx += 1
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) > float(b["score"])
	)
	return scored


## Greedily selects offers from the sorted list within the given budget.
## Returns a Dictionary with keys: recommended_indices (Array[int]), sim_roster (Array[String]).
func _greedy_fill_roster(
		sorted_offers: Array,
		budget: Dictionary,
		max_count: int,
		starting_roster: Array[String]
) -> Dictionary:
	var bg: int = int(budget.get("gold", 0))
	var bm: int = int(budget.get("material", 0))
	var br: int = int(budget.get("research", 0))
	var recommended_indices: Array[int] = []
	var sim_roster: Array[String] = starting_roster.duplicate()
	for entry: Dictionary in sorted_offers:
		if recommended_indices.size() >= max_count:
			break
		var off: Variant = entry.get("offer", null)
		if off == null:
			continue
		var g2: int = int(off.get("cost_gold"))
		var b2: int = int(off.get("cost_building_material"))
		var r2: int = int(off.get("cost_research_material"))
		if g2 > bg or b2 > bm or r2 > br:
			continue
		bg -= g2
		bm -= b2
		br -= r2
		recommended_indices.append(int(entry["i"]))
		var oid: String = str(off.get("ally_id"))
		if not sim_roster.has(oid):
			sim_roster.append(oid)
	return {"recommended_indices": recommended_indices, "sim_roster": sim_roster}


func _pick_best_active(simulated_roster: Array[String], strategy_profile: Types.StrategyProfile) -> Array[String]:
	var scored_ids: Array[Dictionary] = []
	for aid2: String in simulated_roster:
		var d: Resource = get_ally_data(aid2)
		var ad_pick: AllyData = d as AllyData
		if ad_pick == null:
			continue
		var role_i: int = int(ad_pick.role)
		var sc: float = _role_alignment_score(role_i, strategy_profile)
		scored_ids.append({"id": aid2, "score": sc})
	scored_ids.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["score"]) == float(b["score"]):
			return str(a["id"]) < str(b["id"])
		return float(a["score"]) > float(b["score"])
	)
	var out: Array[String] = []
	for e: Dictionary in scored_ids:
		if out.size() >= max_active_allies_per_day:
			break
		out.append(str(e["id"]))
	return out


func _score_offer(
		offer: Variant,
		ally_data: Resource,
		strategy_profile: Types.StrategyProfile,
		current_roster: Array[String]
) -> float:
	var og: int = int(offer.get("cost_gold"))
	var ob: int = int(offer.get("cost_building_material"))
	var orr: int = int(offer.get("cost_research_material"))
	var total_cost: float = float(og + 2 * ob + 3 * orr)
	var cost_eff: float = maxf(0.0, 1.0 - total_cost / 300.0)
	var ad_score: AllyData = ally_data as AllyData
	if ad_score == null:
		return 0.0
	var my_role: int = int(ad_score.role)
	var role_part: float = _role_alignment_score(my_role, strategy_profile)
	var diversity: float = 0.0
	var has_same_role: bool = false
	for oid: String in current_roster:
		var od: Resource = get_ally_data(oid)
		var ad_od: AllyData = od as AllyData
		if ad_od != null and int(ad_od.role) == my_role:
			has_same_role = true
			break
	if not has_same_role:
		diversity = 0.5
	return role_part + cost_eff + diversity


func _role_alignment_score(role: int, strategy: Types.StrategyProfile) -> float:
	match strategy:
		Types.StrategyProfile.ALLY_HEAVY_PHYSICAL:
			if role == int(Types.AllyCombatRole.MELEE):
				return 2.0
			if role == int(Types.AllyCombatRole.RANGED):
				return 1.5
			return 0.0
		Types.StrategyProfile.ANTI_AIR_FOCUS:
			if role == int(Types.AllyCombatRole.RANGED):
				return 2.0
			if role == int(Types.AllyCombatRole.HEALER):
				return 0.5
			return 0.0
		Types.StrategyProfile.SPELL_FOCUS:
			if (
					role == int(Types.AllyCombatRole.HEALER)
					or role == int(Types.AllyCombatRole.BOMBER)
					or role == int(Types.AllyCombatRole.AURA)
			):
				return 2.0
			return 0.0
		Types.StrategyProfile.BUILDING_FOCUS:
			return 0.0
		Types.StrategyProfile.BALANCED:
			return 0.3
	return 0.0


func _apply_default_active_selection() -> void:
	active_allies_for_next_day.clear()
	var sorted_ids: Array[String] = owned_allies.duplicate()
	sorted_ids.sort()
	for aid: String in sorted_ids:
		if active_allies_for_next_day.size() >= max_active_allies_per_day:
			break
		active_allies_for_next_day.append(aid)
	_sync_current_ally_roster_for_spawn()


func _can_afford_offer(offer: Variant) -> bool:
	if offer == null:
		return false
	return (
			EconomyManager.get_gold() >= int(offer.get("cost_gold"))
			and EconomyManager.get_building_material() >= int(offer.get("cost_building_material"))
			and EconomyManager.get_research_material() >= int(offer.get("cost_research_material"))
	)


func _sync_current_ally_roster_for_spawn() -> void:
	current_ally_roster.clear()
	current_ally_roster_ids.clear()
	for aid: String in active_allies_for_next_day:
		if aid == "arnulf":
			continue
		var data: Resource = get_ally_data(aid)
		var ad_sync: AllyData = data as AllyData
		if ad_sync == null:
			continue
		if ad_sync.scene_path.strip_edges().is_empty():
			continue
		current_ally_roster.append(data)
		current_ally_roster_ids.append(aid)


## Returns true if the ally with the given ally_id is currently owned.
func has_ally(ally_id: String) -> bool:
	return is_ally_owned(ally_id)


## Advances the campaign to the next day and triggers mission initialization.
func start_next_day() -> void:
	GameManager.prepare_next_campaign_day_if_needed()
	_start_current_day_internal()


## Sets current_day directly — use only from GameManager edge-case paths.
## Normal day advancement happens via _on_mission_won signal handler.
func force_set_day(day: int) -> void:
	current_day = day


## Returns the current day index (0-based) within the active campaign.
func get_current_day() -> int:
	return current_day


## Returns the total number of days in the active campaign.
func get_campaign_length() -> int:
	return campaign_length


## Returns the DayConfig for the currently active day.
func get_current_day_config() -> DayConfig:
	return current_day_config


func _load_faction_registry() -> void:
	faction_registry.clear()
	for path: String in FactionDataType.BUILTIN_FACTION_RESOURCE_PATHS:
		var data: FactionDataType = load(path) as FactionDataType
		if data == null:
			push_error("CampaignManager: Failed to load FactionData at %s" % path)
			continue
		if data.faction_id == "":
			push_error("CampaignManager: FactionData at %s has empty faction_id" % path)
			continue
		faction_registry[data.faction_id] = data


## Validates that all DayConfig entries reference known faction and boss IDs.
func validate_day_configs(day_configs: Array[DayConfig]) -> void:
	for dc: DayConfig in day_configs:
		if dc == null:
			push_warning("CampaignManager.validate_day_configs: null DayConfig in array.")
			continue
		var fid: String = dc.faction_id.strip_edges()
		if fid.is_empty():
			fid = "DEFAULT_MIXED"
		if fid.is_empty():
			push_warning("CampaignManager.validate_day_configs: resolved faction_id empty.")
			continue
		if not faction_registry.has(fid):
			push_warning("CampaignManager.validate_day_configs: unknown faction_id '%s'." % fid)


func _set_campaign_config(config: CampaignConfig) -> void:
	campaign_config = config
	if campaign_config != null:
		campaign_length = campaign_config.get_effective_length()
		campaign_id = campaign_config.campaign_id
	else:
		campaign_length = 0
		campaign_id = ""
	if GameManager != null:
		GameManager.reload_territory_map_from_active_campaign()


func _start_current_day_internal() -> void:
	if campaign_config == null:
		return
	if current_day < 1:
		return

	current_day_config = GameManager.get_day_config_for_index(current_day)
	if current_day_config == null:
		push_error("CampaignManager: no DayConfig for day %d" % current_day)
		return

	if not is_endless_mode:
		DialogueManager.on_campaign_day_started()

	SignalBus.day_started.emit(current_day)
	var territory: TerritoryData = GameManager.get_current_day_territory()
	if territory != null:
		_load_terrain(territory)
	else:
		var fallback: TerritoryData = TerritoryData.new()
		fallback.terrain_type = Types.TerrainType.GRASSLAND
		_load_terrain(fallback)
	GameManager.start_mission_for_day(current_day, current_day_config)


func _on_mission_won(mission_number: int) -> void:
	if not _has_active_campaign_run:
		return
	if mission_number != current_day:
		return

	failed_attempts_on_current_day = 0
	SignalBus.day_won.emit(current_day)
	if is_endless_mode:
		current_day += 1
		current_day_config = GameManager.get_day_config_for_index(current_day)
		generate_offers_for_day(current_day)
		return

	if GameManager.final_boss_defeated:
		campaign_completed = true
		SignalBus.campaign_completed.emit(campaign_id)
		return

	current_day += 1
	if current_day > campaign_length and campaign_length > 0:
		campaign_completed = true
		SignalBus.campaign_completed.emit(campaign_id)
		return

	current_day_config = GameManager.get_day_config_for_index(current_day)
	generate_offers_for_day(current_day)


func _on_mission_failed(mission_number: int) -> void:
	if not _has_active_campaign_run:
		return
	if mission_number != current_day:
		return

	failed_attempts_on_current_day += 1
	SignalBus.day_failed.emit(current_day)


## Test helper: replaces the active CampaignConfig without triggering signals.
func set_active_campaign_config_for_test(config: CampaignConfig) -> void:
	active_campaign_config = config
	_set_campaign_config(config)


## Test helper: clears all owned and active allies from the roster.
func remove_all_allies() -> void:
	owned_allies.clear()
	active_allies_for_next_day.clear()
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


## Test helper: reloads starter allies from ally_data resources.
func reinitialize_ally_roster_for_test() -> void:
	_load_ally_registry()
	owned_allies.clear()
	active_allies_for_next_day.clear()
	for legacy_id: String in ["ally_melee_generic", "ally_ranged_generic"]:
		if _ally_registry.has(legacy_id):
			owned_allies.append(legacy_id)
	_apply_default_active_selection()
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	var cfg_path: String = ""
	if active_campaign_config != null:
		cfg_path = active_campaign_config.resource_path
	return {
		"current_day": current_day,
		"campaign_completed": campaign_completed,
		"is_endless_mode": is_endless_mode,
		"held_territory_ids": GameManager.held_territory_ids.duplicate(),
		"owned_ally_ids": owned_allies.duplicate(),
		"active_ally_ids": active_allies_for_next_day.duplicate(),
		"failed_attempts_on_current_day": failed_attempts_on_current_day,
		"campaign_config_resource_path": cfg_path,
	}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	_apply_campaign_from_dict(data)
	_apply_roster_from_dict(data)
	_apply_offers_from_dict(data)


## Restores scalar campaign fields (day, completion flags) from a save Dictionary.
func _apply_campaign_from_dict(data: Dictionary) -> void:
	current_day = int(data.get("current_day", 1))
	campaign_completed = bool(data.get("campaign_completed", false))
	is_endless_mode = bool(data.get("is_endless_mode", false))
	failed_attempts_on_current_day = int(data.get("failed_attempts_on_current_day", 0))


## Restores owned and active ally lists from a save Dictionary.
func _apply_roster_from_dict(data: Dictionary) -> void:
	owned_allies.clear()
	var owned: Variant = data.get("owned_ally_ids", [])
	if owned is Array:
		for x: Variant in owned as Array:
			if x is String:
				owned_allies.append(x as String)

	active_allies_for_next_day.clear()
	var active: Variant = data.get("active_ally_ids", [])
	if active is Array:
		for x2: Variant in active as Array:
			if x2 is String:
				active_allies_for_next_day.append(x2 as String)

	_sync_current_ally_roster_for_spawn()


## Restores campaign config, held territories, and regenerates day offers from a save Dictionary.
## Must be called after _apply_campaign_from_dict (reads is_endless_mode).
func _apply_offers_from_dict(data: Dictionary) -> void:
	var cfg_path: String = str(data.get("campaign_config_resource_path", ""))
	if is_endless_mode:
		var stub: CampaignConfig = CampaignConfig.new()
		stub.campaign_id = "endless"
		stub.day_configs = []
		active_campaign_config = stub
		_set_campaign_config(stub)
	elif cfg_path != "" and ResourceLoader.exists(cfg_path):
		var lr: Resource = load(cfg_path)
		if lr is CampaignConfig:
			active_campaign_config = lr as CampaignConfig
			_set_campaign_config(active_campaign_config)
	else:
		if active_campaign_config == null:
			active_campaign_config = DEFAULT_SHORT_CAMPAIGN
		_set_campaign_config(active_campaign_config)

	_has_active_campaign_run = true

	var held: Array[String] = []
	var held_raw: Variant = data.get("held_territory_ids", [])
	if held_raw is Array:
		for h: Variant in held_raw as Array:
			if h is String:
				held.append(h as String)

	current_day_config = GameManager.get_day_config_for_index(current_day)
	GameManager.apply_save_held_territory_ids(held)
	if not is_endless_mode:
		generate_offers_for_day(current_day)
	SignalBus.ally_roster_changed.emit()

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

