# PROMPT 73 — Group 8 Chronicle Meta-Progression (2026-04-18)

## Summary

- **Resources:** `ChronicleData`, `ChronicleEntryData`, `ChroniclePerkData` under `scripts/resources/`.
- **Types:** `Types.ChronicleRewardType`, `Types.ChroniclePerkEffectType`; C# mirror in `scripts/FoulWardTypes.cs`.
- **SignalBus:** `chronicle_entry_completed`, `chronicle_perk_activated`, `chronicle_progress_updated` (total signals **76**).
- **Autoload:** `ChronicleManager` at Init **#15** (after `SybilPassiveManager`, before `DialogueManager`).
- **Data:** `resources/chronicle/entries/*.tres` (16 entries), `resources/chronicle/perks/*.tres` (8 perks). No `entry_meta_first_run` (merged into `entry_campaign_day_50`).
- **Integration:** `GameManager._begin_mission_wave_sequence()` calls `ChronicleManager.apply_perks_at_mission_start()` after mission economy; `EconomyManager` / `ResearchManager` / `EnchantmentManager` consume chronicle multipliers.
- **UI:** `scenes/ui/chronicle_screen.tscn`, `achievement_row_entry.tscn`; main menu **Chronicle** button (`ui/main_menu.*`).
- **Tests:** `tests/test_chronicle_manager.gd` (11 cases). `tools/run_gdunit_quick.sh` includes this suite.
- **Fix:** `scripts/ui/ring_rotation_screen.gd` — corrected `@onready` paths to `Panel/VBoxContainer/...` (buttons were null; SimBot/integration errors).

## Verification

- `dotnet build FoulWard.csproj`
- `./tools/run_gdunit_quick.sh` — 0 test failures in summary (engine may still exit 139 on teardown in some environments).
