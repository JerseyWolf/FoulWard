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
