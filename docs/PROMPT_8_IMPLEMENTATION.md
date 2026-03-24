# PROMPT 8 IMPLEMENTATION

Date: 2026-03-24

## Implemented

### Data / resources

- `res://scripts/resources/territory_data.gd` (`TerritoryData`)
  - Terrain enum, ownership flags, end-of-mission gold bonuses, POST-MVP hooks (`bonus_research_*`, enchant/upgrade cost multipliers).
  - Helpers: `is_active_for_bonuses()`, `get_effective_end_of_day_gold_flat()`, `get_effective_end_of_day_gold_percent()`.

- `res://scripts/resources/territory_map_data.gd` (`TerritoryMapData`)
  - `territories: Array[TerritoryData]`, ID cache, `invalidate_cache()` for tests.

- `res://scripts/resources/day_config.gd`
  - Added `mission_index: int` (days 1–5 map 1:1 to missions 1–5; later days may reuse mission 5 — `# PLACEHOLDER` / `# TUNING`).

- `res://scripts/resources/campaign_config.gd`
  - Added `territory_map_resource_path: String` (optional; short MVP may leave empty).

- `res://resources/territories/main_campaign_territories.tres` — five placeholder territories (`heartland_plains` held at start, etc.).

- `res://resources/campaign_main_50days.tres` — 50 `DayConfig` entries, territory bands days 1–10 … 41–50, `mission_index` 1–5 then 5 for days 6–50 (`# ASSUMPTION` / `# PLACEHOLDER`).

- `res://resources/campaigns/campaign_short_5_days.tres` — each day includes `mission_index` 1..5.

### Autoloads / flow

- `res://autoloads/signal_bus.gd`
  - `territory_state_changed(territory_id: String)`
  - `world_map_updated()`

- `res://autoloads/campaign_manager.gd`
  - `_set_campaign_config()` calls `GameManager.reload_territory_map_from_active_campaign()` when the active campaign changes.

- `res://autoloads/game_manager.gd`
  - `territory_map: TerritoryMapData`, `MAIN_CAMPAIGN_CONFIG_PATH` (documentation path for main 50-day asset).
  - Loads territory map from `CampaignManager.campaign_config.territory_map_resource_path` when non-empty.
  - `start_mission_for_day` sets `current_mission` from `DayConfig.mission_index` (clamped 1..`TOTAL_MISSIONS`).
  - Post-mission gold: base `50 * current_mission` + aggregated flat + percent from **all** active territories (`get_current_territory_gold_modifiers()`).
  - `apply_day_result_to_territory(day_config, was_won)` mutates `TerritoryData` on the loaded map; emits territory + world map signals.
  - **Win condition:** snapshot `completed_day_index == campaign_len` **before** `mission_won` (CampaignManager increments `current_day` on `mission_won`, so order matters).
  - Legacy fallback: `campaign_len == 0` and `current_mission >= TOTAL_MISSIONS` → `GAME_WON`.
  - Public accessors: `get_current_day_index()`, `get_day_config_for_index()`, `get_current_day_config()`, `get_current_day_territory_id()`, `get_territory_data()`, `get_current_day_territory()`, `get_all_territories()`, `reload_territory_map_from_active_campaign()`, `get_current_territory_gold_modifiers()`, `apply_day_result_to_territory()`.

### UI

- `res://ui/world_map.gd` + `res://ui/world_map.tscn` (`WorldMap`) — territory list + detail labels; listens to `territory_state_changed`, `world_map_updated`, `game_state_changed`.

- `res://ui/between_mission_screen.tscn` — first `TabContainer` child `MapTab` instances `WorldMap` (`res://ui/world_map.tscn`).

### Tests (GdUnit4)

- `res://tests/test_territory_data.gd`
- `res://tests/test_campaign_territory_mapping.gd`
- `res://tests/test_campaign_territory_updates.gd`
- `res://tests/test_territory_economy_bonuses.gd`
- `res://tests/test_world_map_ui.gd`
- `res://tests/test_game_manager.gd` — campaign reset, final-day win, `start_next_mission` → `COMBAT`, dayconfig wave test skips WaveManager when `/root/Main` absent (headless).

## DEVIATIONS / notes

- **CampaignManager** remains the day/campaign driver (Prompt 7); territory **state** and **map** live on **GameManager** per spec, loaded from the active `CampaignConfig.territory_map_resource_path`.
- **`day_configs`** naming kept (not renamed to `days`) to avoid breaking `CampaignConfig` API.
- Duplicate campaign asset: `res://resources/campaigns/campaign_main_50_days.tres` may exist from Prompt 7; canonical 50-day data for this prompt is `res://resources/campaign_main_50days.tres` (referenced by `GameManager.MAIN_CAMPAIGN_CONFIG_PATH` and tests).
- **GdUnit CLI:** use the real Godot binary (not a shell alias that adds `-e` / editor); e.g. `./Godot_v4.6.1-stable_linux.x86_64 --headless --path <project> -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -c -a res://tests`
- Full suite last run: **342** cases, **0** failures; exit code **101** may still appear from orphan-node warnings (known GdUnit noise).

## Manual QA (World Map)

1. New game → win day 1 → Between Mission → **World Map** tab: Heartland shows **(Held)** after win.
2. New run → lose a mission: that day’s territory shows **(Lost)**; gold bonuses from lost territories do not apply on next cleared mission.
3. Optional: assign `CampaignManager` active config to `campaign_main_50days.tres` in editor for multi-day band checks.

## Source prompt summary

Territory + world map data model, 50-day linear `CampaignConfig`, territory ownership and end-of-mission gold aggregation on `GameManager`, SignalBus territory signals, `WorldMap` in between-mission UI, GdUnit coverage, and index updates — as specified in the user’s Prompt 8 brief.
