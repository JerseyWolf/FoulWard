## Prompt 16 — SimBot Strategy Profiles and Balance Logging (implementation log)

### 2026-03-25 (work so far)

Implemented Prompt 16 Phase 2:

1. **StrategyProfile Resource + profiles**
   - Added `res://scripts/resources/strategyprofile.gd` (`class_name StrategyProfile`) with typed exported data only.
   - Added `.tres` instances under `res://resources/strategyprofiles/`:
     - `strategy_balanced_default.tres` (`profile_id=BALANCED_DEFAULT`)
     - `strategy_greedy_econ.tres` (`profile_id=GREEDY_ECON`)
     - `strategy_heavy_fire.tres` (`profile_id=HEAVY_FIRE`)

2. **SimBot strategy-driven headless runs**
   - Extended `res://scripts/sim_bot.gd` with:
     - `run_single(profile_id:String, run_index:int, seed_value:int) -> Dictionary`
     - `run_batch(profile_id:String, runs:int, base_seed:int=0, csv_path:String="") -> void`
   - SimBot loads `StrategyProfile` by `profile_id`, runs missions headlessly using public manager APIs only, and collects per-run metrics.
   - Added per-run CSV balance logging to `user://simbot_logs/simbot_balance_log.csv` (or caller-provided `csv_path`).

3. **AutoTestDriver CLI integration**
   - Updated `res://autoloads/auto_test_driver.gd` to support:
     - `--simbot_profile=<PROFILE_ID>`
     - `--simbot_runs=<N>` (defaults to `1` when missing or <= 0)
     - `--simbot_seed=<seed>` (defaults to `0`)

4. **GdUnit4 test coverage**
   - Added tests under `res://tests/`:
     - `test_simbot_profiles.gd` (StrategyProfile loading + structure)
     - `test_simbot_basic_run.gd` (headless `SimBot.run_single()` can place buildings)
     - `test_simbot_logging.gd` (`run_batch()` writes CSV header + rows)
     - `test_simbot_determinism.gd` (fixed seed determinism checks)
     - `test_simbot_safety.gd` (static “no UI paths” check)

### Follow-up fixes included
- Fixed CSV header creation in `SimBot.run_batch()` when callers pass an explicit `csv_path`.
- Corrected `test_simbot_profiles.gd` to use a valid GdUnit assertion helper.

### Verification notes
- Ran `./tools/run_gdunit_quick.sh`: `0 errors / 0 failures` in `Overall Summary`.
- Full GdUnit suite skipped intentionally (per task instruction); run `./tools/run_gdunit.sh` before final release.

