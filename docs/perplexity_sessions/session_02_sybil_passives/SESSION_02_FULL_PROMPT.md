PROMPT:

# Session 2: Sybil Passive Selection System

## Goal
Design the Sybil passive selection system: a set of mission-start passive buffs the player chooses from (e.g., +10% mana regen, +15% spell damage, reduced cooldowns). Includes a new GameState PASSIVE_SELECT, the selection UI, passive data resources, SpellManager integration, and SignalBus signals.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `types.gd` — All enum definitions including GameState (11 values currently); shows enum patterns
- `spell_manager.gd` — Scene-bound spell manager; mana, cooldowns, 4 registered spells
- `game_manager.gd` — Autoload; game state machine, mission start, state transitions (lines 55-120)
- `signal_bus.gd` — Central signal hub; **67** typed `signal` declarations as of **2026-04-14** (see top of `signal_bus.gd` for patterns; if you add signals, update the project's SignalBus signal-count parity everywhere it is tracked — consult **FOUL_WARD_MASTER_DOC** only if you need the maintenance checklist)
- `spell_data.gd` — SpellData resource class; spell_id, mana_cost, cooldown, damage fields

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
Produce an implementation spec for: the Sybil passive selection system.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

DESIGN DECISION (already made): Choose "single pick before mission" — the player selects ONE passive from a list of 3-4 randomly offered options each mission.

REQUIREMENTS:
1. Define a new resource class SybilPassiveData (extends Resource) with fields: passive_id (String), display_name (String), description (String), icon_id (String), category (String — "offense", "defense", "utility"), effect_type (String), effect_value (float), is_unlocked (bool).
2. Define 8 passives covering offense (spell damage +15%, mana regen +20%), defense (tower shield duration +30%, spell cooldown -15%), and utility (mana cost -10%, spell ready notification, etc.).
3. Add GameState.PASSIVE_SELECT (integer value 11) to the Types.gd enum — append at end, never reorder existing values. Add matching C# mirror entry.
4. Design the state transition: MISSION_BRIEFING -> PASSIVE_SELECT -> COMBAT. The selection screen shows 3-4 randomly offered passives from the unlocked pool.
5. Define SignalBus signals: sybil_passive_selected(passive_id: String), sybil_passives_offered(passive_ids: Array[String]).
6. Design SpellManager integration: how the selected passive modifies spell behavior (e.g., multiplied mana_regen_rate, modified cooldown values).
7. Design the UI: a simple panel showing 3-4 passive cards with name, description, icon placeholder, and a Select button.
8. Define save/load integration: selected passive persists in save payload under a new "sybil" key.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 2: Sybil Passives

## AI Companions — Sybil (§2.2)

STATUS: EXISTS IN CODE (spell management); PASSIVE SYSTEM PLANNED

- Role: Spell researcher / spell support.
- Manages the spell system via SpellManager.
- PLANNED — Sybil Passive Selection System (not yet in code).

## Game States (§6)

Defined in res://scripts/types.gd as Types.GameState.

Transition graph: MAIN_MENU -> MISSION_BRIEFING -> COMBAT <-> BUILD_MODE -> WAVE_COUNTDOWN -> (COMBAT loop) -> MISSION_WON/MISSION_FAILED -> BETWEEN_MISSIONS -> MISSION_BRIEFING...

PLANNED states: RING_ROTATE (pre-battle ring rotation), PASSIVE_SELECT (Sybil passives).

### GameState Enum (current values)
| Name | Value |
|------|-------|
| MAIN_MENU | 0 |
| MISSION_BRIEFING | 1 |
| COMBAT | 2 |
| BUILD_MODE | 3 |
| WAVE_COUNTDOWN | 4 |
| BETWEEN_MISSIONS | 5 |
| MISSION_WON | 6 |
| MISSION_FAILED | 7 |
| GAME_WON | 8 |
| GAME_OVER | 9 |
| ENDLESS | 10 |

## Spells (§7)

Manager: SpellManager (scene node under /root/Main/Managers/) — max_mana: 100, mana_regen_rate: 5.0/sec.

Four registered spells:
| .tres File | Display Name | Mana | Cooldown |
|-----------|-------------|------|----------|
| shockwave.tres | Shockwave | 50 | 60s |
| slow_field.tres | Slow Field | — | — |
| arcane_beam.tres | Arcane Beam | — | — |
| tower_shield.tres | Aegis Pulse | — | — |

slow_field.tres has damage = 0.0 intentionally (control spell).

## SpellManager API (§4.2)

| Signature | Returns | Usage |
|-----------|---------|-------|
| cast_spell(spell_id: String) -> bool | bool | Casts if mana/cooldown OK |
| get_available_spells() -> Array[SpellData] | Array | All registered spells |
| get_current_mana() -> int | int | Current mana |
| get_max_mana() -> int | int | Max mana |
| get_mana_regen_rate() -> float | float | Mana per second |
| is_spell_ready(spell_id: String) -> bool | bool | Cooldown + mana check |

## Full Mission Cycle — Mission Start Flow (§27.1, steps 1-2)

1. MAIN_MENU -> User clicks "Start"
2. GameManager.start_new_game()
   -> EconomyManager.reset_to_defaults()
   -> EnchantmentManager.reset_to_defaults()
   -> ResearchManager.reset_to_defaults()
   -> WeaponUpgradeManager.reset_to_defaults()
   -> FlorenceData.reset_for_new_run()
   -> CampaignManager.start_new_campaign()
     -> _bootstrap_starter_allies()
     -> _start_current_day_internal()
       -> SignalBus.day_started.emit(1)
       -> CampaignManager._load_terrain(territory)
       -> GameManager.start_mission_for_day(1, day_config)
         -> _transition_to(COMBAT)
         -> BuildPhaseManager.set_build_phase_active(false)
         -> SignalBus.mission_started.emit(1)

## Formally Cut Features (§31)
| Feature | Status |
|---------|--------|
| Arnulf drunkenness system | FORMALLY CUT |
| Time Stop spell | FORMALLY CUT |
| Hades-style 3D navigable hub | FORMALLY CUT |

Note: Sybil passive selection is PLANNED, not cut.

## Open TBD — Sybil (§33)
| Item | Question | Who Decides |
|------|----------|-------------|
| Sybil passive selection | Single pick before mission OR all passives always active? | Designer |

Decision for this session: Single pick before mission.

## Signal Declaration Patterns

Signals are declared in autoloads/signal_bus.gd with typed parameters:
```
signal sybil_passive_selected(passive_id: String)
```
Past tense for events, present for requests. All signals carry @warning_ignore("unused_signal").

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- _physics_process for game logic — _process for visual/UI only
- Scene instantiation: call initialize() before or immediately after add_child()
- get_node_or_null() for runtime lookups with null guard
- AllyRole enum: MELEE_FRONTLINE=0, RANGED_SUPPORT=1, ANTI_AIR=2, SPELL_SUPPORT=3 (TANK was removed)
- dialogue_line_started and dialogue_line_finished are now on SignalBus (not locally in DialogueManager)

FILES:

# Files to Upload for Session 2: Sybil Passives

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_02_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/types.gd` — Enum definitions; lines 1-100 covering GameState, DamageType, and existing enum patterns (~100 lines)
2. `scripts/spell_manager.gd` — Scene-bound spell manager; full file (~320 lines)
3. `autoloads/game_manager.gd` — Autoload game state machine; lines 55-120 covering _ready, state transitions, mission start (~65 lines)
4. `autoloads/signal_bus.gd` — Central signal hub; lines 1-50 showing signal declaration patterns (~50 lines)
5. `scripts/resources/spell_data.gd` — SpellData resource class definition (~34 lines)

Total estimated token load: ~569 lines across 5 files

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


scripts/spell_manager.gd:
## SpellManager — Owns Sybil's mana pool and spell cooldowns; manages the multi-spell registry and shockwave AoE.
# spell_manager.gd
# SpellManager owns Sybil's mana pool and spell cooldowns for FOUL WARD.
# MVP: one spell — Shockwave (ground AoE, MAGICAL damage).
# Mana regenerates in _physics_process, respecting Engine.time_scale.
#
# Scene placement: /root/Main/Managers/SpellManager (Node)
#
# Credit: Foul Ward SYSTEMS_part3.md §9 (SpellManager spec) — Foul Ward team.
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
#   License: CC BY 3.0 | Adapted: delta-based regen auto-scales with time_scale.
# Credit: Godot Engine Documentation — SceneTree.get_nodes_in_group()
#   https://docs.godotengine.org/en/stable/classes/class_scenetree.html
#   License: CC BY 3.0 | Adapted: group iteration + is_instance_valid guard.

class_name SpellManager
extends Node

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

## Maximum mana capacity for Sybil's spell pool.
@export var max_mana: int = 100
## Mana regenerated per second during combat.
@export var mana_regen_rate: float = 5.0

## Array of SpellData resources. One entry per spell.
@export var spell_registry: Array[SpellData] = []

# ---------------------------------------------------------------------------
# INTERNAL STATE
# ---------------------------------------------------------------------------

## Index into spell_registry for cast_selected_spell() / input hotkeys.
var _selected_spell_index: int = 0

# Float accumulator for smooth sub-integer regen per frame.
# Separate integer snapshot drives signals to avoid emitting 60×/sec.
var _current_mana_float: float = 0.0
var _current_mana: int = 0

# Per-spell cooldown tracking. Key: spell_id (String). Value: seconds remaining.
# A spell is OFF cooldown when its key is absent from this dictionary.
var _cooldown_remaining: Dictionary = {}

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	pass  # Cooldown dict is populated lazily on cast.

# ---------------------------------------------------------------------------
# PHYSICS PROCESS — Mana regen + cooldown tick
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_tick_mana_regen(delta)
	_tick_cooldowns(delta)


func _tick_mana_regen(delta: float) -> void:
	# Pattern: snapshot old int → apply regen → compare new int → emit only on change.
	# Avoids emitting mana_changed 60×/sec when regen is sub-integer per frame.
	if _current_mana_float >= float(max_mana):
		return

	_current_mana_float = minf(
		_current_mana_float + mana_regen_rate * delta,
		float(max_mana)
	)

	var new_int: int = int(_current_mana_float)
	if new_int != _current_mana:
		_current_mana = new_int
		SignalBus.mana_changed.emit(_current_mana, max_mana)


func _tick_cooldowns(delta: float) -> void:
	# Iterate over a copy of keys to allow safe erasure during iteration.
	for spell_id: String in _cooldown_remaining.keys():
		_cooldown_remaining[spell_id] -= delta
		if _cooldown_remaining[spell_id] <= 0.0:
			_cooldown_remaining.erase(spell_id)
			SignalBus.spell_ready.emit(spell_id)

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Attempts to cast a spell. Returns true on success, false on failure.
## Failure conditions: unknown spell_id, insufficient mana, on cooldown.
func cast_spell(spell_id: String) -> bool:
	var spell_data: SpellData = _get_spell_data(spell_id)
	if spell_data == null:
		push_warning("SpellManager: cast_spell() unknown spell_id '%s'." % spell_id)
		return false

	if _current_mana < spell_data.mana_cost:
		return false

	if _cooldown_remaining.has(spell_id):
		return false

	# Deduct mana — sync float accumulator to prevent regen overshooting.
	_current_mana -= spell_data.mana_cost
	_current_mana_float = float(_current_mana)

	_cooldown_remaining[spell_id] = spell_data.cooldown

	_apply_spell_effect(spell_data)

	SignalBus.spell_cast.emit(spell_id)
	SignalBus.mana_changed.emit(_current_mana, max_mana)
	return true


## Returns the current mana as a floored integer.
func get_current_mana() -> int:
	return _current_mana

## Returns the maximum mana capacity.
func get_max_mana() -> int:
	return max_mana

## Returns remaining cooldown seconds (0.0 if ready or unknown).
func get_cooldown_remaining(spell_id: String) -> float:
	return _cooldown_remaining.get(spell_id, 0.0)

## Returns true if the spell is known, mana is sufficient, and cooldown is zero.
func is_spell_ready(spell_id: String) -> bool:
	var spell_data: SpellData = _get_spell_data(spell_id)
	if spell_data == null:
		return false
	return _current_mana >= spell_data.mana_cost \
		and not _cooldown_remaining.has(spell_id)

## Sets mana to full (used by Mana Draught shop item).
func set_mana_to_full() -> void:
	_current_mana = max_mana
	_current_mana_float = float(max_mana)
	SignalBus.mana_changed.emit(_current_mana, max_mana)


## Adds mana, capped at max. If amount <= 0, restores to full (consumable full-restore semantics).
func restore_mana(amount: int) -> void:
	if amount <= 0:
		set_mana_to_full()
		return
	var new_int: int = mini(_current_mana + amount, max_mana)
	_current_mana = new_int
	_current_mana_float = float(new_int)
	SignalBus.mana_changed.emit(_current_mana, max_mana)

## Resets mana to 0 and clears all cooldowns.
func reset_to_defaults() -> void:
	_current_mana = 0
	_current_mana_float = 0.0
	_cooldown_remaining.clear()
	SignalBus.mana_changed.emit(0, max_mana)


## Save/load: set mana without triggering mission-start logic.
func set_mana_for_save_restore(mana: int) -> void:
	var clamped: int = clampi(mana, 0, max_mana)
	_current_mana = clamped
	_current_mana_float = float(clamped)
	SignalBus.mana_changed.emit(_current_mana, max_mana)

# ---------------------------------------------------------------------------
# PRIVATE — SPELL LOOKUP & EFFECTS
# ---------------------------------------------------------------------------

func _get_spell_data(spell_id: String) -> SpellData:
	for spell_data: SpellData in spell_registry:
		if spell_data.spell_id == spell_id:
			return spell_data
	return null


func _apply_spell_effect(spell_data: SpellData) -> void:
	match spell_data.spell_id:
		"shockwave":
			_apply_shockwave(spell_data)
		"slow_field":
			_apply_slow_field(spell_data)
		"arcane_beam":
			_apply_arcane_beam(spell_data)
		"tower_shield":
			_apply_tower_shield(spell_data)
		_:
			push_warning(
				"SpellManager: _apply_spell_effect() unknown spell '%s'."
				% spell_data.spell_id
			)


## Applies Shockwave AoE — hits all ground enemies on the battlefield.
## Battlefield-wide (radius = 100.0 covers full map).
func _apply_shockwave(spell_data: SpellData) -> void:
	# Credit: Foul Ward SYSTEMS_part3.md §9.6 (_apply_shockwave)
	# get_nodes_in_group() returns a snapshot — safe to iterate even if enemies
	# are freed mid-loop. is_instance_valid() guards against chain-kills.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue

		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue

		# hits_flying = false on shockwave.tres — skip Bat Swarm.
		if not spell_data.hits_flying and enemy.get_enemy_data().is_flying:
			continue

		# Single path: EnemyBase.take_damage applies immunities + armor matrix.
		enemy.take_damage(spell_data.damage, spell_data.damage_type)


func _apply_slow_field(spell_data: SpellData) -> void:
	var tower: Tower = get_tree().get_first_node_in_group("tower") as Tower
	var origin: Vector3 = Vector3.ZERO if tower == null else tower.global_position
	var radius_sq: float = spell_data.radius * spell_data.radius
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue
		if not spell_data.hits_flying and enemy.get_enemy_data().is_flying:
			continue
		var p: Vector3 = enemy.global_position
		var dx: float = p.x - origin.x
		var dz: float = p.z - origin.z
		if dx * dx + dz * dz > radius_sq:
			continue
		enemy.apply_slow_effect(
			spell_data.slow_speed_multiplier,
			spell_data.slow_duration_seconds,
			"slow_field"
		)


func _apply_arcane_beam(spell_data: SpellData) -> void:
	var tower: Tower = get_tree().get_first_node_in_group("tower") as Tower
	var start: Vector3 = Vector3.ZERO if tower == null else tower.global_position
	# Beam runs along +Z from the tower on the ground plane.
	var beam_dir: Vector3 = Vector3(0.0, 0.0, 1.0)
	var beam_length: float = maxf(0.1, spell_data.radius)
	var end: Vector3 = start + beam_dir * beam_length
	var half_w: float = maxf(0.1, spell_data.beam_lateral_half_width)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue
		if not spell_data.hits_flying and enemy.get_enemy_data().is_flying:
			continue
		var p: Vector3 = enemy.global_position
		var dist_sq: float = _distance_point_to_segment_squared(p, start, end)
		if dist_sq > half_w * half_w:
			continue
		enemy.take_damage(spell_data.damage, spell_data.damage_type)


func _distance_point_to_segment_squared(p: Vector3, a: Vector3, b: Vector3) -> float:
	var ab: Vector3 = b - a
	var ap: Vector3 = p - a
	var ab_len_sq: float = ab.length_squared()
	if ab_len_sq < 0.000001:
		return ap.length_squared()
	var t: float = clampf(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
	var closest: Vector3 = a + ab * t
	return p.distance_squared_to(closest)


func _apply_tower_shield(spell_data: SpellData) -> void:
	var tower: Tower = get_tree().get_first_node_in_group("tower") as Tower
	if tower == null:
		push_warning("SpellManager: tower_shield — no Tower in scene.")
		return
	tower.add_spell_shield(spell_data.damage, spell_data.shield_duration_seconds)


## Casts the currently selected spell from the registry (by index).
func cast_selected_spell() -> bool:
	var sid: String = get_selected_spell_id()
	if sid.is_empty():
		return false
	return cast_spell(sid)


## Returns the index of the currently selected spell in the registry.
func get_selected_spell_index() -> int:
	return _selected_spell_index


## Sets the selected spell index, clamped to the valid registry range.
func set_selected_spell_index(index: int) -> void:
	if spell_registry.is_empty():
		return
	var n: int = spell_registry.size()
	_selected_spell_index = posmod(index, n)


## Cycles the selected spell index by delta, wrapping around the registry.
func cycle_selected_spell(delta: int) -> void:
	set_selected_spell_index(_selected_spell_index + delta)


## Empty string if registry is empty.
func get_selected_spell_id() -> String:
	if spell_registry.is_empty():
		return ""
	var i: int = posmod(_selected_spell_index, spell_registry.size())
	return spell_registry[i].spell_id


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

autoloads/signal_bus.gd:
## signal_bus.gd
## Central signal registry for all cross-system communication in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# === COMBAT ===
@warning_ignore("unused_signal")
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
## Emitted once per enemy the first time it deals damage to the central tower (leak / reach metric).
@warning_ignore("unused_signal")
signal enemy_reached_tower(enemy_type: Types.EnemyType, damage: int)
@warning_ignore("unused_signal")
signal tower_damaged(current_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal tower_destroyed()
@warning_ignore("unused_signal")
signal projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)
@warning_ignore("unused_signal")
signal arnulf_state_changed(new_state: Types.ArnulfState)
@warning_ignore("unused_signal")
signal arnulf_incapacitated()
@warning_ignore("unused_signal")
signal arnulf_recovered()

# === ALLIES ===
## Second arg is empty for roster allies (e.g. Arnulf); set for summoner-tower allies.
@warning_ignore("unused_signal")
signal ally_spawned(ally_id: String, building_instance_id: String)
## Emitted when a summoner ally dies (permanent death, not downed).
@warning_ignore("unused_signal")
signal ally_died(ally_id: String, building_instance_id: String)
## Emitted when the last living ally for a summoner building is removed.
@warning_ignore("unused_signal")
signal ally_squad_wiped(building_instance_id: String)
@warning_ignore("unused_signal")
signal ally_downed(ally_id: String)
@warning_ignore("unused_signal")
signal ally_recovered(ally_id: String)
@warning_ignore("unused_signal")
signal ally_killed(ally_id: String)
## POST-MVP: not yet emitted. Will be emitted from AllyBase._transition_state() when ally state tracking is implemented.
@warning_ignore("unused_signal")
signal ally_state_changed(ally_id: String, new_state: String)

# === BOSSES (Prompt 10) ===
@warning_ignore("unused_signal")
signal boss_spawned(boss_id: String)
@warning_ignore("unused_signal")
signal boss_killed(boss_id: String)
@warning_ignore("unused_signal")
signal campaign_boss_attempted(day_index: int, success: bool)

# === WAVES ===
@warning_ignore("unused_signal")
signal wave_countdown_started(wave_number: int, seconds_remaining: float)
@warning_ignore("unused_signal")
signal wave_started(wave_number: int, enemy_count: int)
## Emitted once per enemy spawned into the mission (Prompt 49 / WaveManager; Prompt 9: type + XZ position).
@warning_ignore("unused_signal")
signal enemy_spawned(enemy_type: Types.EnemyType, position: Vector2)
## Emitted when an enemy with [code]charge[/code] special first crosses its enrage HP threshold.
@warning_ignore("unused_signal")
signal enemy_enraged(enemy_instance_id: String)
@warning_ignore("unused_signal")
signal wave_cleared(wave_number: int)
@warning_ignore("unused_signal")
signal all_waves_cleared()

# === ECONOMY ===
@warning_ignore("unused_signal")
signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

# === TERRITORIES / WORLD MAP ===
@warning_ignore("unused_signal")
signal territory_state_changed(territory_id: String)
@warning_ignore("unused_signal")
signal world_map_updated()

# === TERRAIN (battlefield zones, navmesh) ===
@warning_ignore("unused_signal")
signal enemy_entered_terrain_zone(enemy: Node, speed_multiplier: float)
@warning_ignore("unused_signal")
signal enemy_exited_terrain_zone(enemy: Node, speed_multiplier: float)
## POST-MVP: not yet emitted. Reserved for destructible terrain props.
@warning_ignore("unused_signal")
signal terrain_prop_destroyed(prop: Node, world_position: Vector3)
## POST-MVP: connected in NavMeshManager but never emitted. Will be emitted from terrain/build flows.
@warning_ignore("unused_signal")
signal nav_mesh_rebake_requested()

# === BUILDINGS ===
@warning_ignore("unused_signal")
signal building_placed(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_sold(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
## Building projectile / aura attribution for CombatStatsTracker (placed_instance_id string).
@warning_ignore("unused_signal")
signal building_dealt_damage(instance_id: String, damage: float, enemy_id: String)
## POST-MVP: connected in CombatStatsTracker but not yet emitted from game code. EnemyBase attack flow should emit this.
@warning_ignore("unused_signal")
signal florence_damaged(amount: int, source_enemy_id: String)
## POST-MVP: not yet emitted. Requires building HP/destruction system.
@warning_ignore("unused_signal")
signal building_destroyed(slot_index: int)

# === SPELLS ===
@warning_ignore("unused_signal")
signal spell_cast(spell_id: String)
@warning_ignore("unused_signal")
signal spell_ready(spell_id: String)
@warning_ignore("unused_signal")
signal mana_changed(current_mana: int, max_mana: int)

# === GAME STATE ===
@warning_ignore("unused_signal")
signal game_state_changed(old_state: Types.GameState, new_state: Types.GameState)
@warning_ignore("unused_signal")
signal mission_started(mission_number: int)
@warning_ignore("unused_signal")
signal mission_won(mission_number: int)
@warning_ignore("unused_signal")
signal mission_failed(mission_number: int)

# Florence / campaign meta-state.
@warning_ignore("unused_signal")
signal florence_state_changed()

# Campaign / day-level signals.
# mission_* signals remain mission-level; in the current short campaign they
# correspond 1:1 to days (one mission per day). CampaignManager wraps them.
@warning_ignore("unused_signal")
signal campaign_started(campaign_id: String)
@warning_ignore("unused_signal")
signal day_started(day_index: int)
@warning_ignore("unused_signal")
signal day_won(day_index: int)
@warning_ignore("unused_signal")
signal day_failed(day_index: int)
@warning_ignore("unused_signal")
signal campaign_completed(campaign_id: String)

# === DIALOGUE ===
@warning_ignore("unused_signal")
signal dialogue_line_started(entry_id: String, character_id: String)
@warning_ignore("unused_signal")
signal dialogue_line_finished(entry_id: String, character_id: String)

# === BUILD MODE ===
@warning_ignore("unused_signal")
signal build_mode_entered()
@warning_ignore("unused_signal")
signal build_mode_exited()
## Emitted when [member BuildPhaseManager.is_build_phase] becomes true (mission build phase / build mode).
@warning_ignore("unused_signal")
signal build_phase_started()
## Emitted when [member BuildPhaseManager.is_build_phase] becomes false (combat / waves).
@warning_ignore("unused_signal")
signal combat_phase_started()

# === RESEARCH ===
@warning_ignore("unused_signal")
signal research_unlocked(node_id: String)
## Prompt 11: alias event for research UI; mirrors [signal research_unlocked].
@warning_ignore("unused_signal")
signal research_node_unlocked(node_id: String)
## Prompt 11: current research material (RP) for in-mission research panel.
@warning_ignore("unused_signal")
signal research_points_changed(points: int)

# === SHOP ===
@warning_ignore("unused_signal")
signal shop_item_purchased(item_id: String)
## Emitted by ShopManager when a mana draught has been consumed by GameManager at mission start.
@warning_ignore("unused_signal")
signal mana_draught_consumed()

# === WEAPONS ===
@warning_ignore("unused_signal")
signal weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)

# === ENCHANTMENTS ===
@warning_ignore("unused_signal")
signal enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)
@warning_ignore("unused_signal")
signal enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)

# === CAMPAIGN / ALLY ROSTER (Prompt 12) ===
@warning_ignore("unused_signal")
signal mercenary_offer_generated(ally_id: String)
@warning_ignore("unused_signal")
signal mercenary_recruited(ally_id: String)
@warning_ignore("unused_signal")
signal ally_roster_changed()

scripts/resources/spell_data.gd:
## spell_data.gd
## Data resource describing stats for a single castable spell in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name SpellData
extends Resource

## Unique string identifier for this spell. Matches spell_cast signal payload.
@export var spell_id: String = "shockwave"
## Human-readable name shown in the spell panel UI.
@export var display_name: String = "Shockwave"
## Mana consumed on cast.
@export var mana_cost: int = 50
## Seconds before this spell can be cast again.
@export var cooldown: float = 60.0
## Damage dealt to each enemy hit.
@export var damage: float = 30.0
## Effective radius in world units. Set to 100.0 for battlefield-wide shockwave.
@export var radius: float = 100.0
## Damage type applied to all targets hit.
@export var damage_type: Types.DamageType = Types.DamageType.MAGICAL
## True if this spell can affect flying enemies. Shockwave is ground-AoE so false.
@export var hits_flying: bool = false

## Slow field: movement speed multiplier applied (e.g. 0.5 = half speed).
@export var slow_speed_multiplier: float = 0.5
## Slow field: duration in seconds.
@export var slow_duration_seconds: float = 4.0
## Beam: lateral half-width in world units (enemies within this distance of the beam segment are hit).
@export var beam_lateral_half_width: float = 3.0
## Shield: duration in seconds (HP pool from `damage` is removed when duration expires).
@export var shield_duration_seconds: float = 8.0


