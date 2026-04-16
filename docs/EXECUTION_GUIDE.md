# EXECUTION GUIDE — Perplexity Sessions & Cursor Implementation

Generated: 2026-04-14

---

## Pre-requisites

1. All 5 Sonnet fix batches (BATCH_1 through BATCH_5) have been completed and verified.
2. Full test suite passes: **459 cases, 0 failures, 0 errors, 2 orphans** (known navmesh teardown).
3. See `docs/POST_BATCH_FIXES.md` for details on the resolved pre-existing test failure.
4. DELIVERABLE_B has been updated with post-batch corrections (file path fixes, enum changes, signal routing notes).

---

## Perplexity Session Execution Order

### Dependency Graph

```
Session 1 (Campaign Content) ──┬──> Session 4 (Chronicle)
                                ├──> Session 5 (Dialogue Content)
                                └──> Session 8 (Star Difficulty)

Session 2 (Sybil Passives) ────> Session 3 (Ring Rotation)

Session 6 (Shop Rotation)       Independent
Session 7 (Art Pipeline)        Independent
Session 9 (Building HP)         Independent
Session 10 (Settings Graphics)  Independent
```

### Recommended Execution Sequence

**If running sessions serially (one at a time):**

1. Session 1 (Campaign Content) -- foundational, others depend on it
2. Session 2 (Sybil Passives) -- adds GameState.PASSIVE_SELECT = 11
3. Session 6 (Shop Rotation) -- independent
4. Session 7 (Art Pipeline) -- independent
5. Session 9 (Building HP) -- independent
6. Session 10 (Settings Graphics) -- independent
7. Session 3 (Ring Rotation) -- depends on Session 2 (uses PASSIVE_SELECT = 11, adds RING_ROTATE = 12)
8. Session 4 (Chronicle) -- depends on Session 1
9. Session 5 (Dialogue Content) -- depends on Session 1
10. Session 8 (Star Difficulty) -- depends on Session 1

**If running two in parallel:**

- Wave 1: Session 1 + Session 2
- Wave 2: Session 6 + Session 7
- Wave 3: Session 9 + Session 10
- Wave 4: Session 3 + Session 4
- Wave 5: Session 5 + Session 8

---

## How to Run a Perplexity Session

For each session directory under `docs/perplexity_sessions/session_NN_<name>/`:

### Step 1: Upload Files to Perplexity

1. Open `FILES_TO_UPLOAD.md` to see the list of source files.
2. For each file listed, locate it in the Foul Ward repository.
3. If the file says "lines X-Y only", extract those lines before uploading.
4. Upload the files to Perplexity as attachments.
5. Also upload `CONTEXT_BRIEF.md` as an attachment.

### Step 2: Paste the Prompt

1. Open `PROMPT.md`.
2. Copy the entire contents.
3. Paste into the Perplexity chat.
4. Send the message.

### Step 3: Review the Output

Perplexity will produce an implementation spec. Review it for:
- Correct file paths (match the actual repo layout)
- Correct method signatures (static typing, correct parameter names)
- No references to cut features (Arnulf drunkenness, Time Stop, Hades hub)
- No conflicts with other sessions' outputs (especially GameState enum values)

---

## Post-Perplexity Workflow: Feeding Output to Cursor

For each Perplexity session's output, open a new Cursor agent session:

### Preamble (paste before the Perplexity output)

```
READ FIRST: AGENTS.md (repo root), then docs/CONVENTIONS.md.

You are implementing a feature spec produced by a Perplexity planning session.
The spec below is the COMPLETE implementation plan — follow it task-by-task.
Do NOT skip tasks, reorder them, or add unplanned features.
Static typing is mandatory. All cross-system events use SignalBus.
After implementation, run: ./tools/run_gdunit.sh
Fix any test failures before finishing.
Write a summary of all changes to docs/PROMPT_[N]_IMPLEMENTATION.md (use the next unused N).

=== BEGIN PERPLEXITY SPEC ===
```

Then paste the full Perplexity output below the preamble.

### Which Agent Model to Use

| Session | Recommended Model | Rationale |
|---------|-------------------|-----------|
| Session 1 (Campaign Content) | Sonnet | Mechanical: populate .tres fields from a table |
| Session 2 (Sybil Passives) | Opus | Complex: new GameState, state machine changes, new resource class, UI |
| Session 3 (Ring Rotation) | Opus | Complex: new GameState, new UI scene, HexGrid integration |
| Session 4 (Chronicle) | Opus | Complex: new autoload, cross-run persistence, achievement system |
| Session 5 (Dialogue Content) | Sonnet | Mechanical: write .tres dialogue entries + small system addition |
| Session 6 (Shop Rotation) | Sonnet | Mechanical: new .tres items + rotation algorithm |
| Session 7 (Art Pipeline) | Sonnet | Mechanical: validation script + documentation tables |
| Session 8 (Star Difficulty) | Opus | Complex: new enum, multiplier system, world map UI changes |
| Session 9 (Building HP) | Opus | Complex: HealthComponent wiring, enemy targeting changes, slot clearing |
| Session 10 (Settings Graphics) | Sonnet | Mechanical: wire RenderingServer APIs to existing settings |

### Post-Implementation Checklist

After each Cursor session:
1. Run `./tools/run_gdunit.sh` — all tests must pass
2. If .cs files were changed: run `dotnet build FoulWard.csproj` first
3. Verify no new orphan nodes in test output
4. Check that `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md` were updated for new files
5. Check that `docs/PROMPT_[N]_IMPLEMENTATION.md` was written

---

## 3D Art Pipeline Parallel Track

The 3D art pipeline runs independently of code implementation. It can start at any time.

### Reference: `docs/FOUL WARD 3D ART PIPELINE.txt`

The pipeline has 5 stages:
1. Reference sheets (character turnarounds, orthographic views)
2. Rodin AI 3D generation
3. Rigging (Mixamo or manual)
4. Animation (clip creation per entity type)
5. Godot import (drop .glb into correct res://art/ path)

### Priority Order for Art Generation

1. **Florence** (player character) — highest visibility
2. **Arnulf** (always present) — second highest visibility
3. **Enemies** (ORC_GRUNT, ORC_BRUTE, PLAGUE_ZOMBIE first) — most common on screen
4. **Buildings** (ARROW_TOWER, FIRE_BRAZIER, MAGIC_OBELISK first) — starter buildings
5. **Bosses** (final_boss, orc_warlord, plague_cult_miniboss) — dramatic moments
6. **Hub characters** (Sybil, Merchant, etc.) — 2D portraits, lower priority

### Integration Point

Art integration is a file-drop operation:
- Place production `.glb` files at the paths defined in `RiggedVisualWiring`
- `ArtPlaceholderHelper` auto-detects production files and uses them instead of placeholders
- No code changes needed for individual art drops

### Known Conflict

The pipeline doc (`docs/FOUL WARD 3D ART PIPELINE.txt`, line 319) lists `drunk_idle` as a required Arnulf animation. The Arnulf drunkenness system is **FORMALLY CUT**. Session 7 (Art Pipeline) addresses this by removing `drunk_idle` from requirements.

### When to Start

Start reference sheet generation for Florence and Arnulf immediately. It has no code dependencies. The validation script from Session 7 should be implemented before the first batch of GLB files is ready for import.

---

## Session Package Location

All session packages are at:

```
docs/perplexity_sessions/
  session_01_campaign_content/
  session_02_sybil_passives/
  session_03_ring_rotation/
  session_04_chronicle/
  session_05_dialogue_content/
  session_06_shop_rotation/
  session_07_art_pipeline/
  session_08_star_difficulty/
  session_09_building_hp/
  session_10_settings_graphics/
```

Each contains: `PROMPT.md`, `CONTEXT_BRIEF.md`, `FILES_TO_UPLOAD.md`.
