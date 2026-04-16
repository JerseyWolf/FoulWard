# OPUS POST-FIX REVIEW + PERPLEXITY SESSION PREPARATION

## CONTEXT
Sonnet agent sessions have completed the error-fix batches from DELIVERABLE_A_ERROR_FIX_PLAN.md. Each session wrote a report to `docs/BATCH_[N]_REPORT.md`. You now need to:
1. Verify the fixes
2. Finalize and produce the Perplexity planning session packages

## STEP 1 — READ ALL BATCH REPORTS

Read every `docs/BATCH_*_REPORT.md` file. For each:
- Confirm the reported changes match what's actually in the code (spot-check 2-3 files per batch)
- Note any tests that failed and were fixed — verify the fixes are sound
- Note any issues the Sonnet session flagged but couldn't resolve
- Check if any batch introduced regressions into files that other batches also touched

Run the full test suite: `./tools/run_gdunit.sh`
Record result: total cases, failures, orphans.

If there are failures:
- Diagnose and fix them directly (this is an agent session, you can edit code)
- Document what you fixed in `docs/POST_BATCH_FIXES.md`

Run tests again after any fixes. Do not proceed to Step 2 until all tests pass.

## STEP 2 — UPDATE DELIVERABLE B IF NEEDED

Read `docs/DELIVERABLE_B_FEATURE_WORKPLAN.md` (your prior output).

Check if any Sonnet batch changes affect the Perplexity session specs:
- Did a batch rename a method or signal that a Perplexity session references?
- Did a batch delete a file that was listed for upload?
- Did a batch fix something that was also listed as a Perplexity session task?

Update DELIVERABLE_B if needed. Save changes in place.

## STEP 3 — PRODUCE PERPLEXITY SESSION PACKAGES

For EACH Perplexity session defined in DELIVERABLE_B, create a self-contained directory:

```
docs/perplexity_sessions/
  session_01_[short_name]/
    PROMPT.md          — The exact prompt to paste into Perplexity
    CONTEXT_BRIEF.md   — Trimmed master doc sections (300-500 lines max)
    FILES_TO_UPLOAD.md — List of file paths with brief description of each
  session_02_[short_name]/
    ...
```

### PROMPT.md format:

```markdown
# [Session Title]

## Goal
[One paragraph]

## Uploaded Files
I have uploaded the following files from the Foul Ward codebase:
- `[filename]` — [one-line description of what it is and why it's relevant]
- [...]

## Context Brief
The attached CONTEXT_BRIEF.md contains the relevant sections of the project's master documentation. Read it fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See CONTEXT_BRIEF.md for full conventions

## Task
Produce an implementation spec for: [specific task description]

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

Format as a numbered task list that a developer can execute top-to-bottom in a single session. Each task should be one atomic change (one file, one method, one resource). Do not suggest alternatives or ask questions — make decisions and state them.
```

### CONTEXT_BRIEF.md format:

Extract ONLY the relevant master doc sections. Strip the full API tables down to just the methods the session needs. Include:
- The relevant system description
- ONLY the API methods that will be called or modified
- The relevant Types.gd enum values
- Any anti-patterns or conventions that apply to this specific work
- The relevant signal bus signals

Do NOT include unrelated systems, unrelated API methods, or general project overview sections.

### FILES_TO_UPLOAD.md format:

```markdown
# Files to Upload for Session N

Upload these files from the Foul Ward repository to Perplexity:

1. `autoloads/signal_bus.gd` — Central signal hub; needed to see existing signals and add new ones
2. `scripts/types.gd` — Enum definitions; needed to add new enum values
3. [...]

Total estimated token load: ~[X] lines across [N] files
```

For each session, keep the total upload under 2,000 lines of source code. If a file is large, note which sections to extract (e.g., "lines 1-150 only — the rest is unrelated building data").

## STEP 4 — PRODUCE EXECUTION GUIDE

Create `docs/EXECUTION_GUIDE.md` with:

1. **Pre-requisite:** All Sonnet fix batches completed and verified (Step 1 above)
2. **Perplexity session execution order** — which sessions to run first, which can run in parallel, which depend on others
3. **Post-Perplexity workflow** — for each session's output, how to feed it to a Cursor agent:
   - "Take the output from Perplexity Session N"
   - "Open a new Cursor agent session (Sonnet for mechanical implementation, Opus for complex architecture)"
   - "Paste the Perplexity output as context"
   - "Add this preamble: [preamble that sets up the Cursor agent with AGENTS.md and CONVENTIONS.md]"
   - "Run tests after"
4. **3D art pipeline parallel track** — when to start generating reference sheets, which characters to do first (per the priority order in FOUL_WARD_3D_ART_PIPELINE), and the single integration point (dropping .glb files into res://art/ subfolders)

Save to `docs/EXECUTION_GUIDE.md`.

## STEP 5 — FINAL SUMMARY

Print to chat:
- Total test results after all fixes
- Number of Perplexity sessions produced
- Recommended execution order (short version)
- Any issues or decisions you made that I should review before proceeding
- Any items from DELIVERABLE_B that you chose to CUT or DEFER and why

## IMPORTANT NOTES

- You have full agent access — edit code if needed during Step 1 to fix regressions
- The Perplexity sessions will use Sonnet 4.6, not Opus — keep prompts explicit and concrete
- Each CONTEXT_BRIEF must be genuinely trimmed — do not just paste entire master doc sections. Perplexity's context is limited. If a section has 40 API methods but the session only needs 5, include only those 5.
- The person running these sessions will upload CONTEXT_BRIEF.md and the listed source files to Perplexity manually, then paste PROMPT.md into the chat. Make this workflow as frictionless as possible.
