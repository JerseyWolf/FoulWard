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
