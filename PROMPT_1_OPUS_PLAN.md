# OPUS PLAN MODE — Full Audit + Workplan Generation

## YOUR ROLE
You are the lead architect for the Foul Ward project. This is a PLAN session — you will read everything, analyze, and produce two written deliverables. You will NOT modify any code in this session.

## STEP 1 — READ THESE FILES IN ORDER (mandatory, do all before writing anything)

1. `AGENTS.md` (repo root)
2. `docs/CONVENTIONS.md`
3. `docs/FOUL_WARD_MASTER_DOC.md` (or wherever the master doc lives — find it)
4. `docs/IMPROVEMENTS_TO_BE_DONE.md`
5. `docs/INDEX_SHORT.md`
6. `docs/INDEX_FULL.md` (skim — use for API cross-referencing)
7. `FOUL_WARD_3D_ART_PIPELINE.txt` (or `.md` — find it)
8. `docs/SUMMARY_VERIFICATION.md`
9. `.cursorrules`
10. `.cursor/rules/mcp-godot-workflow.mdc`

After reading docs, walk the actual file tree:
- `ls` the top-level directory
- `ls` key directories: `autoloads/`, `scripts/`, `scenes/`, `ui/`, `resources/`, `tests/`, `tools/`, `docs/`, `docs/archived/`
- Open and read any file where you suspect a discrepancy between docs and reality

## STEP 2 — PRODUCE DELIVERABLE A: Error/Fix List with Sonnet Prompts

Cross-reference IMPROVEMENTS_TO_BE_DONE.md against the actual codebase. For every issue listed there:
- Verify if it is STILL PRESENT or ALREADY FIXED since Prompt 28
- If still present, confirm the exact file, line range, and severity

Then scan for issues NOT in the improvements file:
- Master doc says a signal/API/field exists but code differs
- Master doc says something is PLANNED but code already partially implements it (or vice versa)
- Orphaned files, dead imports, signals declared but never emitted/connected
- Any `.tres` resource referencing a path or ID that doesn't exist
- Anything in AGENTS.md or CONVENTIONS.md that the code violates

Group all surviving issues into these batches (reorder or re-group if you find a better split based on the actual codebase — these are suggestions, not constraints):

**Batch 1 — Assert-to-guard conversion** (all assert() calls that should be push_warning + early return)
**Batch 2 — Bare get_node fixes** (replace with get_node_or_null + null guard)
**Batch 3 — Signal routing** (dialogue_line_finished bypass and any other signal bus violations)
**Batch 4 — Long function extraction** (LOW priority refactors — only include if you judge them worth doing now)
**Batch 5 — Test cleanup** (orphan node fixes + parallel runner implementation)
**Batch 6 — Housekeeping** (delete redundant files, remove orphaned enum values, merge legacy UI files)
**Batch 7+ — Any additional batches you identify**

For EACH batch, write a complete, self-contained Cursor prompt for a Sonnet agent session. These prompts must:
- Use terse, imperative language (caveman mode — no pleasantries, no "please", no "could you")
- List every file to touch and exactly what to change
- Include the test command to run after (`./tools/run_gdunit_parallel.sh` or `./tools/run_gdunit.sh`)
- End with: "Write a summary of all changes to `docs/BATCH_[N]_REPORT.md`"
- Be fully self-contained — the Sonnet session will NOT have access to MASTER_DOC or IMPROVEMENTS file, only the codebase

Sonnet prompts should look like this (example only — adapt to real findings):

```
READ FIRST: autoloads/economy_manager.gd

TASK: Replace all assert() calls with defensive guards.

Line 39: assert(amount > 0) → if amount <= 0: push_warning("EconomyManager.add_gold: invalid amount %d" % amount); return
Line 45: assert(amount > 0) → if amount <= 0: push_warning("EconomyManager.spend_gold: invalid amount %d" % amount); return false
[... every instance explicitly listed ...]

NO other changes. Do not refactor, rename, or reorganize anything.

Run: ./tools/run_gdunit.sh
Expected: All tests pass. If any fail, fix them before continuing.

Write summary to docs/BATCH_1_REPORT.md — list every file changed, every assert replaced, test results.
```

## STEP 3 — PRODUCE DELIVERABLE B: Feature Workplan with Perplexity Session Specs

Collect every non-error work item:
- Every PLANNED / NOT YET IMPLEMENTED item from the master doc
- Every PLACEHOLDER_ACCEPTABLE resource issue from improvements file
- Every open TBD from master doc §33
- Every POST-MVP stub from improvements §6
- The 3D art pipeline integration points (from FOUL_WARD_3D_ART_PIPELINE)
- Any TODO(ART) markers in the codebase
- Dialogue placeholder text (all "TODO: placeholder dialogue line." entries)

Organize these into Perplexity planning sessions. Each session should be:
- Scoped tightly enough that Perplexity can plan it in one conversation
- Self-contained — no session should depend on another session's output being available at planning time
- Focused on one subsystem or closely related subsystems

For EACH Perplexity session, produce:

### Session N: [Title]
**Goal:** [One paragraph — what this session designs]
**Upload these files to Perplexity:**
- [exact file path 1]
- [exact file path 2]
- [etc — be specific, list actual paths from the repo]

**Include these master doc sections** (copy the section numbers and titles):
- §X — [title]
- §Y — [title]

**Trimmed context note:** [If the full master doc sections are too large, specify which sub-sections to extract. E.g., "From §3, include only §3.6 CampaignManager and §3.9 GameManager APIs"]

**Dependencies:** [Other sessions that should complete first, or "None"]

**Prompt for Perplexity:**
```
[Write the actual prompt here. It must:
- State the goal
- Reference the uploaded files explicitly
- Ask for an IMPLEMENTATION SPEC, not a discussion
- Specify the output format: file-by-file changes, new files to create, resource schemas, exact method signatures
- Include: "Output must be detailed enough that a Cursor agent can implement it in a single session without further questions."
- Include: "Do not suggest alternatives or ask clarifying questions. Make design decisions and justify them briefly."]
```

Suggest an execution order for all sessions, noting which can run in parallel.

## STEP 4 — SAVE DELIVERABLES

Save Deliverable A to: `docs/DELIVERABLE_A_ERROR_FIX_PLAN.md`
Save Deliverable B to: `docs/DELIVERABLE_B_FEATURE_WORKPLAN.md`

## IMPORTANT NOTES

- An external advisor (Claude Opus on claude.ai) reviewed the master doc, improvements file, and 3D art pipeline doc and suggested the batch groupings and Perplexity session topics listed above. Use them as a starting point but override with better groupings if the actual codebase suggests it. You have access to everything — they only had the docs.
- The advisor flagged these dependency constraints: Sessions adding new GameStates (Sybil passives, ring rotation) should be sequenced, not parallel. Campaign content (50-day design) should precede dialogue content. Assert-to-guard fixes (Batch 1) should complete before feature work since those files are touched by many features.
- For Deliverable B, the master doc sections per session should be TRIMMED extracts, not "include all of §3" — Perplexity's context is smaller than yours. Aim for 300-500 lines of master doc content per session max, plus the source files.
- If you find that the 3D art pipeline doc describes integration points that conflict with how ArtPlaceholderHelper.gd actually works, flag it clearly in Deliverable B.
