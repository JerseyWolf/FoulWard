# PROMPT 23 — Endless Run mode (AUDIT 6 §3.4)

**Date:** 2026-03-28

## Summary

- **Types:** `GameState.ENDLESS` for between-mission hub during Endless Run (parallel to hub UX).
- **CampaignManager:** `is_endless_mode`, `start_endless_run()` (stub `CampaignConfig`, empty `day_configs`, `campaign_started("endless")`), `_on_mission_won` endless branch (no `campaign_completed`, day increments forever), `_start_current_day_internal` skips `DialogueManager.on_campaign_day_started` when endless.
- **GameManager:** Synthetic endless `DayConfig` via `get_day_config_for_index` + `WaveManager` scaling helpers; hub transition skips `GAME_WON` for endless; Florence updates gated in mission win/fail; `mission_won` / `mission_failed` emit `CampaignManager.get_current_day()`; `_transition_to(BETWEEN_MISSIONS)` maps to `ENDLESS` when `is_endless_mode`.
- **WaveManager:** `get_effective_enemy_hp_multiplier_for_day` / `get_effective_spawn_count_multiplier_for_day` (unbounded per-day formula); `spawn_count_multiplier` on `DayConfig` applied in `_compute_total_enemies_for_wave`.
- **UI:** Main menu "New Campaign" clears endless + `start_new_game`; "Endless Run" → `start_endless_run` + `start_new_game`. Hub / BetweenMissionScreen / UIManager / WorldMap treat `ENDLESS` like between-mission; dialogue + Florence debug gated.
- **Tests:** `res://tests/test_endless_mode.gd` (4 cases). `tools/run_gdunit_quick.sh` includes this suite.

## Verification

- `./tools/run_gdunit_quick.sh` — pass (326 cases, 0 failures).
- `./tools/run_gdunit.sh` — pass (515 cases, 0 failures).
