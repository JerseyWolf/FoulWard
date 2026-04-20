# PROMPT 89 — Documentation and file-tree state sync

**Date:** 2026-04-20  
**Scope:** Refresh **`docs/FOUL_WARD_MASTER_DOC.md`**, **`docs/INDEX_SHORT.md`**, **`docs/INDEX_FULL.md`**, and other “living snapshot” docs (`HOW_IT_WORKS.md`, `INTERVIEW_CHEATSHEET.md`, `AGENTS.md`, `docs/README.md`, `docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`, `docs/SUMMARY_VERIFICATION.md`, `docs/archived/prompts/README.md`, `.cursor/skills/signal-bus/SKILL.md`) so paths, gen3d layout, rolling `PROMPT_*` window, and verification metrics match the repository. **No gameplay logic changes.**

## Canonical paths / metrics updated

- **Gen3D:** Orchestration is **in-repo** under `res://tools/gen3d/` (not an off-repo `/home/.../gen3d/` tree). §22 of the master doc lists `art/gen3d_candidates/`, `art/gen3d_previews/`, and adds **`orc_berserker.glb`** to the generated-enemy examples.
- **`SignalBus`:** **77** signals — `grep -c '^signal ' autoloads/signal_bus.gd` (verification date **2026-04-20** in standing orders and related docs).
- **GdUnit4:** **665** test cases — parallel runner aggregate (`reports/gdunit_parallel_run.summary.txt`, **2026-04-19**); **88** test files; **749** lines matching `func test_` in `tests/` (differs from GdUnit case count).
- **`.tres`:** **262** under `resources/` (gameplay); **287** repo-wide including addons (`find . -name '*.tres' -not -path './.git/*'`).
- **Session logs:** **`PROMPT_*_IMPLEMENTATION.md`** → **90** files via  
  `find docs docs/archived/prompts -maxdepth 1 -name 'PROMPT_*_IMPLEMENTATION.md' | wc -l`  
  **`PROMPT_1_IMPLEMENTATION_v2.md`** is separate (not counted in that `find`). Rolling window under **`docs/`:** **`PROMPT_80`…`PROMPT_89`**.

## Rolling window

- Moved **`docs/PROMPT_79_IMPLEMENTATION.md`** → **`docs/archived/prompts/PROMPT_79_IMPLEMENTATION.md`** before adding this file.

## Tests

Not run — documentation only.
