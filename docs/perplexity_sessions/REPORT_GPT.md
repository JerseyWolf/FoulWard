# MASTER_PERPLEXITY_OUTPUT.txt — GPT Audit Report

**Auditor:** GPT-5.4  
**Date:** 2026-04-15  
**Scope:** Audit `docs/perplexity_sessions/MASTER_PERPLEXITY_OUTPUT.txt` against:
- `docs/DELIVERABLE_A_ERROR_FIX_PLAN.md`
- `docs/DELIVERABLE_B_FEATURE_WORKPLAN.md`
- `PROMPT_1_OPUS_PLAN.md`
- `PROMPT_2_OPUS_POST_FIX_AND_PERPLEXITY_PREP.md`
- live repo state on 2026-04-15
- `docs/perplexity_sessions/REPORT.md`

---

## Executive Summary

`MASTER_PERPLEXITY_OUTPUT.txt` is broadly useful and mostly factually grounded. Most sessions understand the live codebase, respect the project rules, and produce implementable planning material. The strongest parts are Sessions 2, 4, 5, 8, 9, and 10, which mostly do what the original workplan asked and fit the game's broader roadmap.

The main problems are **not** outright hallucinations. They are:

1. **Frozen-baseline coordination issues** across sessions written as if signal count, autoload order, and enum state had not changed.
2. **Scope drift** in a few sessions, where the master output changes what the original Perplexity session was supposed to deliver.
3. **Packaging inconsistency**, especially Session 7, which stops being a single implementation spec and becomes a multi-chat execution program.

**Verdict:** Mostly sound as a planning artifact, but not fully faithful to the originally defined session briefs. Safe to use if treated as a curated design bundle rather than a literal one-to-one execution of `DELIVERABLE_B`.

---

## Highest-Value Findings

### 1. Session 7 drifts furthest from the assigned format

`DELIVERABLE_B_FEATURE_WORKPLAN.md` defines Session 7 as one Perplexity planning session that should return a single implementation spec with exact file-by-file changes. In `MASTER_PERPLEXITY_OUTPUT.txt`, Session 7 becomes a **task program**:

- each task runs in a separate Cursor chat
- early tasks are explicitly `REPORT only`
- later tasks depend on prior report files

This is useful operationally, but it is **not the same deliverable**. It no longer matches the original "one session, one implementation spec" goal.

**Assessment:** Good material, wrong package shape.

### 2. Session 3 expands scope beyond the original brief

The original Session 3 brief in `DELIVERABLE_B_FEATURE_WORKPLAN.md` is about adding a **pre-battle ring-rotation UI** around the existing three-ring, 24-slot system. In the master output, Session 3 also redesigns the underlying board:

- `24 -> 42` total slots
- ring layout becomes `6 + 12 + 24`
- save migration is introduced
- several systems must be updated for new slot indexing

This can make sense if it was a deliberate product decision, but it is a **strategic redesign**, not just UI wiring. It should be understood as a change in scope, not just a fuller implementation.

**Assessment:** Plausible design direction, but materially larger than what Session 3 was originally supposed to do.

### 3. Session 6 intentionally drops a requested field

The original Session 6 brief explicitly requested new `ShopItemData` fields:

- `category`
- `max_stack`
- `rarity_weight`

The master output explicitly chooses:

- `category` replaces `item_type`
- `rarity_weight` is added
- `max_stack` is **not** added; existing `CONSUMABLE_STACK_CAP` is reused

That is a reasonable simplification, but it means the output is **not a faithful execution of the stated session brief**.

**Assessment:** Sensible deviation, but still a deviation.

### 4. Session 1 rewrites one original requirement

The original Session 1 brief asked for at least two mini-boss days between days 15-40. The master output explicitly says that was an "authoring error" and locks mini-boss days to **10, 20, 30, 40**.

This is not internally absurd. Day 10 as an act-end mini-boss is perfectly defensible. But it is still a deliberate rewrite of the earlier assignment and should be recognized as such.

**Assessment:** Design-valid, but not faithful to the literal original brief.

---

## Session-by-Session Assessment

### Session 1 — 50-Day Campaign Content

Mostly sound. The formulas, ramp logic, and authored table are coherent. The biggest real repo-fit concern is that `DayConfig` already has:

- `mission_index`
- `mission_economy`

So the proposed `starting_gold` field overlaps existing structure and the sample blocks omit `mission_index`. That matches the concern noted in `REPORT.md`.

**Verdict:** Good campaign-authoring spec, but it quietly changes one requirement and under-specifies existing `DayConfig` fields.

### Session 2 — Sybil Passive System

Strong overall and fits the game plan. The major factual problem remains the same one identified in `REPORT.md`: it says the new Resource script should have **no `class_name`**, but the live repo uses `class_name` extensively on Resource scripts. That guidance is wrong by project convention.

The autoload placement and signal-count math are fine in isolation, but conflict sequentially with later sessions.

**Verdict:** Good plan with one real convention error.

### Session 3 — Ring Rotation

The research and integration logic are sensible, but this session is really a **hex-grid redesign session plus UI session**. That is the key thing to understand when deciding whether it "makes sense": yes, if the broader plan is to deepen board tactics; no, if the intention was only to expose existing rotation functionality.

**Verdict:** Coherent, but broader than assigned.

### Session 4 — Chronicle

One of the stronger sessions. The static-resource vs runtime-progress split is solid and fits Godot well. I agree with `REPORT.md` that:

- the autoload slot conflicts with Session 2
- the signal baseline is frozen
- `entry_campaign_day_50` vs `entry_meta_first_run` looks redundant or at least under-defined

**Verdict:** Strong system design with one ambiguous achievement pair.

### Session 5 — Dialogue Content and Combat Dialogue

This session is mostly good. The written voices fit the game's tone and the system respects SignalBus discipline. The spec is honest where signal/API details need confirmation.

The main design risk is not factual error but architectural sprawl: a separate `CombatDialogueManager` may be overkill when `DialogueManager` could likely absorb the work.

**Verdict:** Good content pass and reasonable system design, with one implementation-architecture choice that should be decided cautiously.

### Session 6 — Shop Rotation

Grounded in the repo and generally useful. The clearest drift is the dropped `max_stack` field. I also agree with `REPORT.md` that several item effects rely on methods/hooks that do not exist yet, so the eventual implementing agent would still need to create those integration points.

**Verdict:** Good system spec, but not fully faithful to the original requirements.

### Session 7 — Art Pipeline

This is the biggest format drift in the file. The content itself is thoughtful and respects the cut-feature rule around `drunk_idle`, but it is no longer really a single Perplexity session output. It becomes a staged operating procedure for multiple Cursor chats, with report handoffs between them.

That may still be useful in practice, but it does **not** match the original "produce one implementation spec Perplexity session" plan.

**Verdict:** Valuable work breakdown, poor fidelity to the original session contract.

### Session 8 — Star Difficulty

Mostly strong. The multipliers, persistence strategy, and tier gating fit the game plan. I agree with `REPORT.md` that the helper `get_effective_multiplier` appears to be a no-op in the spec while the real logic lives elsewhere. The second extra signal (`territory_selected_for_replay`) is also an expansion beyond the original brief, which only explicitly required `territory_tier_cleared`.

**Verdict:** Good design with one helper bug and one scope expansion.

### Session 9 — Building HP and Destruction

This session is one of the cleanest. It uses existing project patterns sensibly, activates an already-declared signal, and makes backward-compatible choices (`max_hp = 0` meaning indestructible).

**Verdict:** Strong and well aligned with the roadmap.

### Session 10 — Graphics Quality

Also strong. It correctly sees that the current repo stores a string only, and it responsibly marks the `WorldEnvironment` integration as theorycraft because no such node currently exists in project scenes. Promoting graphics quality from string to enum is a deliberate enhancement over the original brief, but a good one.

**Verdict:** Good session, with sensible scope improvement rather than problematic drift.

---

## Cross-Session Issues

### 1. Frozen baseline problem

This matches `REPORT.md` and I agree with it. Multiple sessions assume the same starting baseline:

- 67 signals
- current autoload order
- pre-expansion enum state

So the sessions are valid individually but do not compose cleanly without reconciliation.

### 2. Autoload slot conflict

Also matches `REPORT.md`. Session 2 and Session 4 both want the same insertion point after `SaveManager`.

### 3. Output format inconsistency

This is the biggest gap not emphasized enough in `REPORT.md`.

Across the 10 sessions, the master file is not one consistent kind of artifact:

- some sessions are implementation specs
- some are prompt packages
- Session 7 is effectively an execution program

That inconsistency matters because downstream users will assume each session can be handed to an implementation agent the same way.

### 4. Mixed relationship to the original briefs

Several sessions are best understood as **post-discussion revised briefs**, not direct executions of `DELIVERABLE_B`:

- Session 1 changes mini-boss timing
- Session 3 expands from UI to board redesign
- Session 6 drops `max_stack`
- Session 8 adds an extra signal/UI event path
- Session 10 upgrades strings to enums

This is acceptable if those were deliberate human decisions, but the bundle should be treated as "revised canon" rather than "strictly followed original plan."

---

## Comparison With `REPORT.md`

### Where I agree with `REPORT.md`

- The master file is broadly high quality and useful.
- The biggest structural issue is cross-session coordination, not rampant factual hallucination.
- Session 2's `class_name` guidance is wrong.
- Session 4 has an autoload-order conflict and an ambiguous achievement pair.
- Session 8 has a helper-level logic problem.
- Sessions 9 and 10 are among the cleaner, more grounded sessions.

### What I think `REPORT.md` underweights

1. **Session 7 package drift**
   `REPORT.md` treats Session 7 as basically clean. I think that is too charitable. Its content is fine, but it no longer delivers the type of artifact the original plan asked Perplexity to produce.

2. **Session 6 requirement drift**
   `REPORT.md` does not call out that the original brief requested `max_stack`, and the master output explicitly declines to add it.

3. **Session 1 requirement rewrite**
   `REPORT.md` accepts the mini-boss schedule at face value. I think it should be called out as an intentional rewrite of the original session brief.

4. **Session 3 scope expansion**
   `REPORT.md` notes the 24→42 slot change is significant, but it does not emphasize that this changes the session from "UI around an existing feature" into a broader strategic redesign.

### Overall comparison

`REPORT.md` is directionally correct and catches the most obvious factual/convention issues. My audit is stricter on **brief fidelity** and **artifact shape**, not just factual plausibility. On that axis, `MASTER_PERPLEXITY_OUTPUT.txt` is weaker than `REPORT.md` suggests.

---

## Final Judgment

If the question is "does `MASTER_PERPLEXITY_OUTPUT.txt` mostly make factual sense for Foul Ward?" the answer is **yes**.

If the question is "does it consistently do exactly what the original Perplexity session briefs said it should do?" the answer is **no, not always**.

Best interpretation:

- use it as a **revised design bundle**
- do **one reconciliation pass** before implementation
- treat Sessions **3, 6, and 7** as the places where human intent should be re-confirmed before any coding starts

Those are the sessions most likely to cause downstream confusion, not because they are nonsensical, but because they changed the assignment shape or scope.
