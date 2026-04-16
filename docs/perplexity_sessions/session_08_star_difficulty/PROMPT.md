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
