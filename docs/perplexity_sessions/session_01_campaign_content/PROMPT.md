# Session 1: 50-Day Campaign Content Design

## Goal
Design the complete 50-day campaign for Foul Ward: faction assignments for each day, boss placement (mini-boss days, final boss day 50), territory rotation across the five territories, wave composition tuning per day (HP/damage/gold multipliers, spawn count scaling), and starting resources per mission. Currently all 50 DayConfigs have `faction_id = ""` and minimal tuning. This session produces a complete campaign specification.

## Uploaded Files
I have uploaded the following files from the Foul Ward codebase:
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
The attached CONTEXT_BRIEF.md contains the relevant sections of the project's master documentation. Read it fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See CONTEXT_BRIEF.md for full conventions

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
1. Assign faction_id to every day. Days 1-10 should use DEFAULT_MIXED. After day 10, rotate between ORC_RAIDERS and PLAGUE_CULT based on territory. Both factions appear on all days, but the ratio of orcs and plague cult 
2. Place mini-boss encounters: 4 total encounters on days 10, 20, 30, 40. Mark these with is_mini_boss_day = true and boss_id matching the .tres files.
3. Day 50 is the final boss (boss_id = "final_boss", is_final_boss = true).
4. Map each day to a territory_id. The campaign should progress through territories roughly in order (heartland_plains early, outer_city late) with some back-and-forth for variety.
5. Design wave tuning multipliers: enemy_hp_multiplier and enemy_damage_multiplier should scale from 1.0 (day 1) to approximately 3.0 (day 50). gold_reward_multiplier should scale from 1.0 to 1.5. spawn_count_multiplier from 1.0 to 2.5.
6. Set base_wave_count: days 1-10 = 3 waves, days 11-30 = 4 waves, days 31-50 = 5 waves.
7. Provide starting_gold values per day (start at 1000, increase to 1500 by day 50).

OUTPUT FORMAT: A table with columns: day_index (1-50), territory_id, faction_id, is_mini_boss_day, boss_id, base_wave_count, enemy_hp_multiplier, enemy_damage_multiplier, gold_reward_multiplier, spawn_count_multiplier, starting_gold. Then provide the exact .tres sub-resource format for 5 sample days (days 1, 10, 25, 40, 50) showing how to encode these values.

Format as a numbered task list that a developer can execute top-to-bottom in a single session. Each task should be one atomic change (one file, one method, one resource). Do not suggest alternatives or ask questions — make decisions and state them.
