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
	## Sybil passive selection screen, shown once per mission before combat.
	PASSIVE_SELECT,
	## Ring rotation pre-combat screen; entered after PASSIVE_SELECT, exits to COMBAT.
	RING_ROTATE,
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

## Modular building kit: base piece under `res://art/generated/kit/*.glb` (see docs/FUTURE_3D_MODELS_PLAN.md §4).
enum BuildingBaseMesh {
	STONE_ROUND,
	STONE_SQUARE,
	WOOD_ROUND,
	RUINS_BASE,
}

## Modular building kit: top piece under `res://art/generated/kit/*.glb` (see docs/FUTURE_3D_MODELS_PLAN.md §4).
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

## Battle terrain preset for CampaignManager terrain scene selection (see docs/FUTURE_3D_MODELS_PLAN.md §5).
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

## Rendering quality preset for SettingsManager.
enum GraphicsQuality {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
	CUSTOM = 3,
}

## Reward category for a Chronicle entry completion.
enum ChronicleRewardType { PERK = 0, COSMETIC = 1, TITLE = 2 }

## Effect applied by an unlocked Chronicle perk (meta-progression).
enum ChroniclePerkEffectType {
	STARTING_GOLD = 0,
	STARTING_MANA = 1,
	SELL_REFUND_PCT = 2,
	RESEARCH_COST_PCT = 3,
	GOLD_PER_KILL_PCT = 4,
	BUILDING_MATERIAL_START = 5,
	ENCHANTING_COST_PCT = 6,
	WAVE_REWARD_GOLD = 7,
	XP_GAIN_PCT = 8,
	COSMETIC_SKIN = 9,
}

## Replay difficulty tier for per-territory star system.
enum DifficultyTier {
	NORMAL = 0,
	VETERAN = 1,
	NIGHTMARE = 2,
}

# ASSUMPTION: Types uses enums + static helpers as a shared registry across systems.

