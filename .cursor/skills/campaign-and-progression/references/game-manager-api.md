# GameManager Full API — Foul Ward

Source: FOUL_WARD_MASTER_DOC.md §3.9
File: `autoloads/game_manager.gd` — Autoload Init #9

---

## Full Method Table

| Signature | Returns | Usage |
|---|---|---|
| `start_new_game() -> void` | void | Full reset; calls CampaignManager.start_new_campaign() |
| `start_next_mission() -> void` | void | Delegates to CampaignManager.start_next_day() |
| `start_wave_countdown() -> void` | void | Begins combat from MISSION_BRIEFING |
| `enter_build_mode() -> void` | void | COMBAT → BUILD_MODE (time_scale 0.1) |
| `exit_build_mode() -> void` | void | BUILD_MODE → COMBAT (time_scale 1.0) |
| `get_game_state() -> Types.GameState` | GameState | Current state |
| `get_current_mission() -> int` | int | Mission number (1-indexed) |
| `get_current_wave() -> int` | int | Wave index in active mission |
| `get_florence_data() -> FlorenceData` | FlorenceData | Protagonist meta-state resource |
| `advance_day(reason: Types.DayAdvanceReason) -> void` | void | Increments Florence day counter |
| `get_current_day_index() -> int` | int | Delegates to CampaignManager |
| `get_day_config_for_index(day_index: int) -> DayConfig` | DayConfig | Looks up from campaign or creates synthetic |
| `start_mission_for_day(day_index: int, day_config: DayConfig) -> void` | void | Initializes mission and begins waves |
| `advance_to_next_day() -> void` | void | Advances calendar; assigns boss attack if needed |
| `get_territory_data(territory_id: String) -> TerritoryData` | TerritoryData | Lookup from territory map |
| `get_current_day_territory() -> TerritoryData` | TerritoryData | Territory for current day |
| `get_all_territories() -> Array[TerritoryData]` | Array | All territories |
| `reload_territory_map_from_active_campaign() -> void` | void | Reloads territory map resource |
| `apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void` | void | Updates territory ownership |
| `get_current_territory_gold_modifiers() -> Dictionary` | Dict | `{flat_gold_end_of_day, percent_gold_end_of_day}` |
| `get_aggregate_flat_gold_per_kill() -> int` | int | Sum of kill bonuses from held territories |
| `get_aggregate_research_cost_multiplier() -> float` | float | Product of research cost mults |
| `get_aggregate_enchanting_cost_multiplier() -> float` | float | Product of enchanting cost mults |
| `get_aggregate_weapon_upgrade_cost_multiplier() -> float` | float | Product of weapon upgrade cost mults |
| `get_aggregate_bonus_research_per_day() -> int` | int | Sum of bonus research per mission |
| `get_save_data() -> Dictionary` | Dict | Save snapshot |
| `restore_from_save(data: Dictionary) -> void` | void | Restore from save |

## Constants

```gdscript
TOTAL_MISSIONS = 5
WAVES_PER_MISSION = 5
```

*Verified against `autoloads/game_manager.gd` (2026-03-31).*
