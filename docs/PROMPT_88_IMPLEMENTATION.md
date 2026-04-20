# PROMPT 88 — Repository documentation cleanup (no gameplay code)

**Date:** 2026-04-20  
**Scope:** Remove stale LLM dumps and scratch planning artefacts; consolidate session logs under `docs/archived/prompts/` with a **10-file rolling window** in `docs/`; refresh indexes, `AGENTS.md`, `HOW_IT_WORKS.md`, `INTERVIEW_CHEATSHEET.md`, `FOUL_WARD_MASTER_DOC.md`, `.cursor/skills/*`, and `docs/README.md`. **No** changes to game logic (`.tscn`/`.tres`/gameplay `.gd` paths), except **comment-only** path updates for `docs/FUTURE_3D_MODELS_PLAN.md` and one C# header comment.

## Deleted (git rm)

- **Repo root:** `REPO_DUMP_*.md`, `ALL_AUDITS.md` (duplicate), `test_output.md`, `PROMPT_[12]_OPUS_*.md`, `IMPROVEMENTS_TO_BE_DONE.md`
- **`docs/`:** Perplexity batch files (`BATCH_*`, `COMPLIANCE_*`, `DELIVERABLE_*`, `SESSION_07_*`, `perplexity_sessions/`, etc.), `docs/AGENTS.md`, `gen3d_workplan.md`, `POST_MVP_SUMMARY.odt`, `FOUL WARD 3D ART PIPELINE.txt`, …
- **`docs/archived/`:** Pre-audit dumps, `OPUS_ALL_ACTIONS`, `PROBLEM_REPORT`, autonomous session logs, `INDEX_MACHINE`/`INDEX_TASKS`, duplicate `ALL_AUDITS`, etc. (prompt logs **moved**, not deleted)

## Moved

- **`FUTURE_3D_MODELS_PLAN.md`** → `docs/FUTURE_3D_MODELS_PLAN.md`
- **Session logs:** `docs/PROMPT_0`…`PROMPT_77` and all former `docs/archived/PROMPT_*` → `docs/archived/prompts/`; **`PROMPT_1_IMPLEMENTATION_v2.md`** kept alongside the original `PROMPT_1_IMPLEMENTATION.md` (distinct content).
- **Rolling window:** `docs/` retains **`PROMPT_79`…`PROMPT_88`** (10 files); `PROMPT_78_IMPLEMENTATION.md` moved to `docs/archived/prompts/` to enforce the cap before adding this file.

## Added / updated

- **`README.md`** (repo root) — already present; cross-links unchanged in this session beyond doc hygiene elsewhere.
- **`docs/archived/prompts/README.md`**, **`docs/archived/README.md`** — policy and pointers.
- **`.gitignore`:** `simbot_runs/`

## Verification

- `grep -RIl 'REPO_DUMP_AFTER_MVP' --include='*.md' .` → should be empty at repo root docs (spot-check).
- Session count: `find docs docs/archived/prompts -maxdepth 1 -name 'PROMPT_*_IMPLEMENTATION.md' | wc -l` → **90** files including `PROMPT_1_IMPLEMENTATION_v2.md`.

## Tests

Not run — documentation and file moves only.
