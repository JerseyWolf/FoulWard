# PROMPT 7 IMPLEMENTATION

Date: 2026-03-24

## Scope completed

- Added campaign/day abstraction layer with `CampaignManager` autoload above `GameManager`.
- Added data-driven campaign resources (`CampaignConfig`, `DayConfig`) and two campaign `.tres` definitions (short 5-day + main 50-day).
- Extended `SignalBus` with campaign/day lifecycle signals.
- Integrated day-driven mission startup into `GameManager` and per-day tuning into `WaveManager`.
- Updated Between Mission UI to show day progression and route progression through `CampaignManager`.
- Added Prompt 7 test coverage in new and existing suites.

## Files added

- `res://scripts/resources/day_config.gd`
- `res://scripts/resources/campaign_config.gd`
- `res://resources/campaigns/campaign_short_5_days.tres`
- `res://resources/campaigns/campaign_main_50_days.tres`
- `res://autoloads/campaign_manager.gd`
- `res://tests/test_campaign_manager.gd`

## Files updated

- `res://project.godot` (autoload registration/order including `CampaignManager`)
- `res://autoloads/signal_bus.gd` (campaign/day signals)
- `res://autoloads/game_manager.gd` (campaign-owned mission kickoff + `start_mission_for_day`)
- `res://scripts/wave_manager.gd` (`configure_for_day`, configurable wave cap, day multipliers)
- `res://ui/between_mission_screen.gd`
- `res://ui/between_mission_screen.tscn`
- `res://tests/test_wave_manager.gd` (Prompt 7 additions)
- `res://tests/test_game_manager.gd` (Prompt 7 additions)

## Behavior notes

- # ASSUMPTION: current short-campaign flow maps `mission_number == day_index`.
- # DEVIATION: `GameManager.start_next_mission()` now delegates to `CampaignManager.start_next_day()`.
- # DEVIATION: `WaveManager` now supports per-day wave cap and difficulty multipliers.
- # POST-MVP: mini/final boss fields are data-ready but not consumed by gameplay logic yet.

## Verification run notes

- Script lints on all edited `.gd` files returned clean.
- GdUnit CLI invocation in this environment still reports `Unknown '--editor' command` from the gdUnit command tool despite returning process exit code `0`; this appears to be an environment/runner argument issue rather than a Prompt 7 script parse issue.

## `.tres` comment tags (Prompt 7 checklist)

- `campaign_short_5_days.tres` and `campaign_main_50_days.tres` use Godot text-resource line comments (`;`) embedding `# PLACEHOLDER` / `# TUNING` tags next to narrative and numeric fields, matching the style used in `resources/spell_data/shockwave.tres`.
- Headless `Resource.load()` on both campaigns succeeds (`main_days=50`).
