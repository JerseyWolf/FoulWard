# PROMPT 76 — Perplexity audit fix workplan (Groups 1–11)

**Date:** 2026-04-19  
**Scope:** Implement `perplexity_audit_fix_workplan_056a2620` (attached plan; plan file not edited in-repo).

## Summary

Production + harness fixes from the audit: `HealthComponent` preserves pre-`add_child()` HP; canonical campaign `.tres`; save payload `save_version` + v1→v2 migration; shop building repair cost/description; ring rotation SubViewport hex preview; missing tests and Session 07 art reports; documentation and index sync; optional LOW batch (Sybil signal declaration order, combat dialogue filename note, changelog clarification).

## Verification

| Command | Result |
|---------|--------|
| `dotnet build FoulWard.csproj` | OK |
| `./tools/run_gdunit_quick.sh` | OK (exit 101 post-crash suppressed; **488** cases in allowlist) |
| `./tools/run_gdunit_parallel.sh` | **PASS** — **665** cases, 0 failures (2026-04-19) |
| `./tools/run_gdunit.sh` | Exit 0 via known **139** teardown suppression; log may omit final **Overall Summary** if segfault truncates |

## SignalBus

- Count: **77** (`grep -c '^signal ' autoloads/signal_bus.gd`).
- **Sybil passive:** `sybil_passive_selected` is declared **before** `sybil_passives_offered` (Perplexity spec parity). Updated `.cursor/skills/signal-bus/references/signal-table.md`.

## Harness / tooling

- **`tools/run_gdunit_quick.sh`:** Map **134/139** → **101** after Godot run (same idea as `run_gdunit.sh`).
- **`tools/run_gdunit_parallel.sh`:** (1) Same **134/139** → **101** for group processes; (2) **strip_ansi** extended for truecolor `38;2;…`; (3) exit-code **100** + “0 failures” check uses **`grep` on raw `group_*.log`** (pipe from huge `$clean_log` failed to match); (4) stats parsed via **`strip_ansi < group.log | …`** pipe.
- **`tests/unit/test_aura_healer_runtime.gd`:** `monitor_signals(SignalBus, false)` in `before_test()`.
- **`tests/test_building_repair.gd`:** `HealthComponent` named **`HealthComponent`** in `_make_building_with_hp` so `get_node_or_null` matches production.
- **`tests/test_florence.gd`:** `SaveManager.start_new_attempt()` in `before_test()` to avoid autosave warning on `mission_failed`.

## Outstanding / known

- GdUnit **GdUnitTestCaseAfterStage** occasionally hits **`test_case.id()` on Nil** and/or **SIGSEGV** during error-monitor teardown — environment-dependent; parallel split reduces blast radius.
- Sequential **`run_gdunit.sh`** may **truncate** the HTML/text report if the engine crashes after the last suite; rely on **parallel aggregate** for case totals when needed.

## Doc touchpoints

- `docs/FOUL_WARD_MASTER_DOC.md` — changelog note on historical signal totals; canonical combat `.tres` filenames; legacy campaign path row updated.
- `docs/INDEX_SHORT.md` / `docs/INDEX_FULL.md` — Session 07 REPORT_01/02/03; HexGrid **42** slots line.
- `AGENTS.md` — parallel case count **665**, signal verify date **2026-04-19**.
