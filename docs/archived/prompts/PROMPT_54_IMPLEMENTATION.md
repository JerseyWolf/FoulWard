# PROMPT 54 — CONVENTIONS.md refresh (2026-03-31)

## Summary

Aligned `docs/CONVENTIONS.md` with `docs/FOUL_WARD_MASTER_DOC.md` (§2 Core Architecture, §3 Autoloads, §5 Types.gd, §24 Signal Bus via grouped tables, §29–30 agent rules, §32 field name discipline). The previous MVP-era document was archived as `docs/archived/CONVENTIONS_MVP.md`.

## Changes

- **Changelog** at top of `CONVENTIONS.md` with date and pointer to archive + master doc.
- **§1** File tree: 17 gameplay autoload scripts, `NavMeshManager` under `scripts/`, `tests/unit/`, scene-bound managers under `/root/Main/Managers/`.
- **§3** Economy defaults `1000` / `50` / `0`; `GameManager` `WAVES_PER_MISSION = 5`, waves `1..5`; `DamageCalculator` note for `TRUE`; **§3.5** full core `Types` enums (36 `BuildingType`, 30 `EnemyType`, `DamageType.TRUE`, `GameState` includes `GAME_OVER`, `ENDLESS`, `TargetPriority.LOWEST_HP`).
- **§4** Pointer to master doc §32 for field names (resource templates kept).
- **§5** Grouped SignalBus tables (58+ signals) aligned with `signal_bus.gd` / master §24 — removed duplicate `building_destroyed` stub line and MVP-only caveats where superseded.
- **§6** Note on `get_node_or_null` for runtime lookups.
- **§8** Full autoload registration table (17 scripts + `GDAIMCPRuntime` row).
- **§9.1** Prefer `push_warning` over `assert()` for production/headless (§30.4).
- **§12** Tests under `res://tests/unit/`; example assert `1050` for default gold 1000.
- **§19** Seventeen-step init order matching `AGENTS.md` / master §3.
- **§2.2** Signal example payload: `enemy_type: Types.EnemyType` (matches `SignalBus`).

## Test alignment (verification)

- `tests/test_game_manager.gd`: `test_waves_per_mission_constant_is_3` was stale (`GameManager.WAVES_PER_MISSION` is **5**). Updated to `test_waves_per_mission_constant_is_5`.

## Verification

- `./tools/run_gdunit_quick.sh` — **exit code 100** on this run: one failure in `tests/test_simbot_basic_run.gd` (`test_simbot_can_run_and_place_buildings` — build-phase / SimBot; not caused by `CONVENTIONS.md`). Log summary: 389 cases, 1 failure, 1 orphan.

## Files touched

- `docs/CONVENTIONS.md`
- `docs/archived/CONVENTIONS_MVP.md` (copy of pre-refresh `CONVENTIONS.md`)
- `tests/test_game_manager.gd` (waves-per-mission assertion)
- `docs/PROMPT_54_IMPLEMENTATION.md` (this log)
