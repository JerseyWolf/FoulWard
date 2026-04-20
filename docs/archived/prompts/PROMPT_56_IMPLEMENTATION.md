# PROMPT 56 — Master compliance rollup, SimBot test fix, staging archive

**Date:** 2026-03-31

## CHECK 7 — `docs/COMPLIANCE_REPORT_MASTER.md`

**Created:** `docs/COMPLIANCE_REPORT_MASTER.md` (rollup from `COMPLIANCE_REPORT_H1.md` … `H4.md`).

**H5 skills** (`mcp-workflow`, `add-new-entity`, `save-and-dialogue`) marked **NOT AUDITED — H5 missing** in the violation table per instructions.

---

## CHECK 6 — `test_simbot_can_run_and_place_buildings` (`tests/test_simbot_basic_run.gd`)

### Failure analysis

1. **`./tools/run_gdunit_quick.sh`** reported `Expecting: 'true' but is 'false'` on `assert_bool(any_built)` (line 26).

2. **Log root cause:** `BuildPhaseManager: blocked place_building — not in build phase` during `_perform_build_action` → `HexGrid.place_building`. SimBot runs its decision loop in **COMBAT** / **WAVE_COUNTDOWN**; `HexGrid.place_building` requires `BuildPhaseManager.assert_build_phase` (true after `GameManager.enter_build_mode()`).

3. **Secondary issue:** `strategy_balanced_default.tres` uses `spell_usage.priority_vs_building = 1.0` and build weights up to `1.0`. `_process_combat_tick` used `if spell_priority >= best_build_score` → spell always won on ties, so no placements even if phase were fixed.

### Classification

** (a) Genuine bug** — SimBot did not enter build mode before placement; spell/build tie-break was wrong for “balanced” profile. Not headless-missing-node flakiness.

### Code changes (`scripts/sim_bot.gd`)

| Change | Purpose |
|--------|---------|
| `_perform_build_action`: if state is `COMBAT` or `WAVE_COUNTDOWN`, call `GameManager.enter_build_mode()` before place/upgrade, then `GameManager.exit_build_mode()` after. | Satisfies `BuildPhaseManager` for `place_building` / `upgrade_building`. |
| `spell_priority >= best_build_score` → `spell_priority > best_build_score` | Equal priority prefers **building**; avoids spell starving placement. |

### Verification

**Command:** `./tools/run_gdunit_quick.sh`

| Metric | Result |
|--------|--------|
| Exit | **101** (wrapper treats as pass with warnings) |
| Failures | **0** |
| Cases | 390 |
| Orphans | 1 (known engine/GdUnit noise) |

---

## CHECK 10 — `AGENT_SKILLS_STAGING.md`

**Moved:** `AGENT_SKILLS_STAGING.md` → `docs/archived/AGENT_SKILLS_STAGING_original.md`

Resolves root staging file presence; removes that path from default `docs/AGENTS.md` grep scope when excluding `archived/`.

---

## CHECK 1 / 5 note

- **Skill markdown count:** **19** (15× `SKILL.md` + 4× `references/*.md`) — canonical expectation.
- **Stale `docs/AGENTS.md`:** documentation-only hits remain acceptable per checklist; optional grep excludes documented in user note.

---

## Files touched this session

| File | Action |
|------|--------|
| `docs/COMPLIANCE_REPORT_MASTER.md` | Created |
| `docs/PROMPT_56_IMPLEMENTATION.md` | Created (this file) |
| `scripts/sim_bot.gd` | Build-mode wrap + spell/build tie-break |
| `AGENT_SKILLS_STAGING.md` | Moved to `docs/archived/AGENT_SKILLS_STAGING_original.md` |

---

## Next steps

Use **`docs/COMPLIANCE_REPORT_MASTER.md` → Top 10 Priority Violations** and **Recommended Fix Sessions (I1–I8)** for follow-up Cursor work; run **H5** when ready to audit the three remaining skills.
