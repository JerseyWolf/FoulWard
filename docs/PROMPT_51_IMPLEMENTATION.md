# PROMPT 51 — SimBot balance sweep + CSV reports + BuildingData.balance_status

**Date:** 2026-03-30

## Summary

Automated balance pass wiring: `SimBot.run_balance_sweep()` runs scripted mission × loadout combinations, `CombatStatsTracker` tags each run with `mission_id` + `run_label` in CSVs, a Python tool aggregates `building_summary.csv` files into a markdown report and status CSV, and an editor script can apply statuses back to `.tres` files.

## Files touched

| Area | Files |
|------|--------|
| Loadouts | `scripts/simbot/simbot_loadouts.gd` (`SimBotLoadouts`) |
| SimBot | `scripts/sim_bot.gd` — `run_balance_sweep`, `_run_single_balance_run`, `_place_loadout`, `_balance_resolve_mission`, research unlocks |
| Combat stats | `autoloads/combat_stats_tracker.gd` — `begin_run`, `end_run`, `run_label` + `display_name`/`role_tags` columns in CSVs |
| CLI | `autoloads/auto_test_driver.gd` — `--simbot_balance_sweep` |
| Tools | `tools/simbot_balance_report.py`, `tools/apply_balance_status.gd` (`BalanceStatusApplier`) |
| Tests | `tests/unit/test_simbot_balance_integration.gd`, `tools/run_gdunit_unit.sh` |
| Docs | `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, this file |

## How to run a SimBot sweep (headless)

From the project root (Godot binary on `PATH` or `GODOT_BIN`):

```bash
godot --path . --headless -- --simbot_balance_sweep
```

Requires `main.tscn` (AutoTestDriver creates `SimBot` under `/root`). CSV output: `user://simbot/runs/{mission_id}_{loadout}_{timestamp}/` (Godot user data dir).

Copy or symlink that tree to `./simbot_runs` for the Python tool (or pass `--root`).

## Python report

```bash
python3 tools/simbot_balance_report.py --root simbot_runs
```

Outputs:

- `tools/output/simbot_balance_report.md` — table sorted by damage/gold
- `tools/output/simbot_balance_status.csv` — `building_id,status`

**Classification:** Towers with **total gold spent ≥ 200** (aggregated `cost_gold_paid`) enter the median pool. Median is taken over per-building `damage_per_gold` (total_damage / total_gold). Then:

- `OVERTUNED`: ≥ median × **1.35**
- `UNDERTUNED`: ≤ median × **0.65**
- `BASELINE`: between
- `UNTESTED`: gold below 200 or no qualifying data

## Apply status to resources (editor)

Open the project in the Godot editor, select `tools/apply_balance_status.gd`, use **File → Run** (or run as EditorScript from Project Tools). It reads `res://tools/output/simbot_balance_status.csv` and updates `balance_status` on matching `res://resources/building_data/*.tres`.

## Tests

```bash
./tools/run_gdunit_unit.sh
```
