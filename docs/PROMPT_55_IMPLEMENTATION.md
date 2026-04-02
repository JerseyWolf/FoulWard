# PROMPT 55 — Docs AGENTS path cleanup + skill reference index entries

**Date:** 2026-03-31  
**Session:** G — targeted cleanup after Agent Skills validation report.

## Task 1 — INDEX files (`docs/AGENTS.md` → repo-root `AGENTS.md` + semantics)

| File | Changes |
|------|---------|
| `docs/INDEX_SHORT.md` | **Line 10:** Removed stale pointer to deleted `docs/AGENTS.md`; now ends with “deep systems reference in `docs/FOUL_WARD_MASTER_DOC.md`” (canonical encyclopedia). **Lines 26–29:** New one-liners for four `references/*.md` files (Task 3). |
| `docs/INDEX_FULL.md` | **`docs/AGENTS.md` → `AGENTS.md`:** 2× global replace — **line 7** (header history paragraph, Prompt 26 clause) and **line 35** (pre-edit) affected. **Line 35 (after edits):** `**Covers:**` bullet rewritten to drop redundant “full sections” pointer; now points encyclopedia detail to `docs/FOUL_WARD_MASTER_DOC.md` only. **Lines 97–113:** New subsection “Skill reference tables” (Task 3). |

## Task 2 — SKILL files

| File | Line(s) updated |
|------|-----------------|
| `.cursor/skills/scene-tree-and-physics/SKILL.md` | **63** — `docs/AGENTS.md` → `AGENTS.md` (repo root) |
| `.cursor/skills/godot-conventions/SKILL.md` | **22, 30, 150** — `docs/AGENTS.md` → `AGENTS.md` |
| `.cursor/skills/mcp-workflow/SKILL.md` | **72, 76, 82** — `docs/AGENTS.md` → `AGENTS.md` |

## Task 3 — INDEX entries for `references/*.md`

All four paths were **missing** from both `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`; entries added:

- `.cursor/skills/signal-bus/references/signal-table.md`
- `.cursor/skills/enemy-system/references/enemy-types.md`
- `.cursor/skills/building-system/references/building-types.md`
- `.cursor/skills/campaign-and-progression/references/game-manager-api.md`

## Task 4 — Remaining `docs/AGENTS.md` string hits (not auto-fixed)

Repo-wide `grep -rn "docs/AGENTS.md" .` outside **`docs/archived/`**:

| Location | Note |
|----------|------|
| `docs/AGENT_SKILLS_VALIDATION_REPORT.md` | Historical validation narrative (documents that `docs/AGENTS.md` was removed). Update only if you want the report to reflect post-migration wording. |
| `AGENT_SKILLS_STAGING.md` | Staging / template still lists legacy `docs/AGENTS.md` in several blocks — **Action:** align staging with repo-root `AGENTS.md` when editing staging next. |

**`docs/archived/**`:** Left unchanged per instructions.

## Task 5 — Tests

**Command:** `./tools/run_gdunit_quick.sh`  
**Exit code:** **100**  
**Summary:** **389** test cases, **0** errors, **1** failure, **1** orphan.

| Item | Detail |
|------|--------|
| Failure | `res://tests/test_simbot_basic_run.gd` → `test_simbot_can_run_and_place_buildings` — report: line 26 expected `true` got `false`; backtrace includes `assert_build_phase` → `place_building` during SimBot combat tick. |
| Orphan | `res://tests/test_florence.gd` → `test_first_research_unlock_sets_has_unlocked_research_flag` — GdUnit orphan-node warning (line 99 of report). |

Failures/orphans match pre-existing project baseline referenced in validation; **not introduced by this documentation-only session.**
