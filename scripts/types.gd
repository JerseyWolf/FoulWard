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
	TANK,
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

