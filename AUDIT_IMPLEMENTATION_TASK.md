# AUDIT_IMPLEMENTATION_TASK.md

Progress log for audit groups A–J (FOUL WARD), session 2026-03-28.

## Summary: already applied at start

- **A** Node path ShopManager — `game_manager.gd` used `var shop: Node = ShopManager`; `ShopManager` is **not** a project autoload (only `class_name` + scene node), so that form could not work as written.
- **B** `_MERCENARY_OFFER_DATA_GD` — already present in `campaign_manager.gd`.
- **C** SignalBus snake_case — already satisfied in `signal_bus.gd`.
- **D** Old camelCase `SignalBus.*` references — none in `.gd` sources.

## Summary: changes made this session

- **A** Resolved `ShopManager` wiring with `get_node_or_null("/root/Main/Managers/ShopManager")` (matches Audit 3 manager path table; no `/root/ShopManager` string).
- **E** SimBot (`scripts/sim_bot.gd`): Audit 4 API — `activate(strategy: Types.StrategyProfile)` (required arg), `get_log() -> Dictionary` (`entries`, `profile_id`, `runs`, `base_seed`, `csv_path`), `run_single` returns audit schema + merged legacy `_metrics` keys, `run_batch` CSV columns + default `user://simbot/logs/`, batch log state after runs. Added `scripts/simbot.gd` as thin `extends` alias for the requested path.
- **F** SimBot tests: `enemies_killed` key; safety test loads `sim_bot.gd` source; `test_simulation_api.gd` passes `Types.StrategyProfile.BALANCED` to `activate()`.
- **G** `auto_test_driver.gd`: `--simbot_profile` path uses `run_single` when `--simbot_runs=1`, else `run_batch` + `get_log()` summary line.
- **H** `docs/ARCHITECTURE.md`: inserted **Manager node path contracts (FOUL WARD)** after the Main scene tree block.
- **I** `docs/AUDIT_CONTEXT_SUMMARY.md`: appended ShopManager + SpellManager rows; API path notes `simbot.gd`; related lines updated to `simbot.gd` where applicable.
- **J** `tests/test_campaign_autoload_and_day_flow.gd`; `campaign_manager.gd`: `_has_active_campaign_run` set in `start_new_campaign()`, checked in `_on_mission_won` / `_on_mission_failed`.
- **INDEX** `docs/INDEX_SHORT.md`: SimBot row updated for alias + CSV path.

## Verification

Sanity greps (project `.gd` trees used as `res://` equivalents):

- Old camelCase `SignalBus.*` list from prompt: **0 matches**
- `/root/ShopManager`: **0 matches** in `.gd`
- `_MercenaryOfferDataGd`: **0 matches** in `.gd`

Test runs:

- `./tools/run_gdunit_quick.sh` — **pass** (exit 0)
- `./tools/run_gdunit.sh` — **pass** (exit 0): **443** test cases, **0** errors, **0** failures

## Note on Group A vs prompt text

The prompt asked for `var shop: Node = ShopManager`. This project does **not** register `ShopManager` as an autoload in `project.godot`; `ShopManager` names the script class. The implemented fix uses the documented scene path under `Main/Managers` (see Audit 3 / ARCHITECTURE).

[ALL TASKS COMPLETE]
