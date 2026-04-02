# Prompt 46 — Revert testing tweaks (autotest, waves, flying spawns)

## Summary

Reverted session-only changes: **AutoTestDriver** and `tools/run_autotest_visible.sh` removed; faction rosters and boss escorts restored from git (bats spawn again). Mission wave count set to **5** for ongoing testing: `WAVES_PER_MISSION`, `DayConfig.base_wave_count` default, `WaveManager.max_waves`, synthetic boss-attack day, and all `base_wave_count` entries in `campaign_short_5_days.tres`, `campaign_main_50days.tres`, `campaigns/campaign_main_50_days.tres`.

Deleted `docs/PROMPT_45_IMPLEMENTATION.md` (superseded).

**Not reverted:** Prompt 44 anti-air targeting (`EnemyData.matches_tower_air_ground_filter`, `BuildingBase._find_target`).

## Files

- Restored from `HEAD`: `autoloads/auto_test_driver.gd`, faction `*.tres`, `bossdata_final_boss.tres`, campaign `*.tres` (then wave-count sed applied)
- Removed: `tools/run_autotest_visible.sh`, `docs/PROMPT_45_IMPLEMENTATION.md`
- Edited: `autoloads/game_manager.gd`, `scripts/wave_manager.gd`, `scripts/resources/day_config.gd`, campaign `.tres` (all days `base_wave_count = 5`), `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, this file
