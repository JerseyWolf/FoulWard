# MASTER_PERPLEXITY_OUTPUT.txt — Audit Report

**Auditor:** Claude Opus 4.6 (Cursor)
**Date:** 2026-04-15
**Scope:** Factual accuracy, internal consistency, and fitness-for-purpose of all 10 Perplexity sessions in `MASTER_PERPLEXITY_OUTPUT.txt`
**Baseline codebase state verified against:** live repo as of 2026-04-15

---

## Executive Summary

The 10 sessions form a coherent expansion roadmap for Foul Ward, covering campaign content, new game systems, UI, art pipeline, economy, and settings. The research quality is high, with verifiable citations and well-reasoned design decisions. However, **each session was written against the same frozen baseline** (67 signals, 612 tests, 17 autoloads), creating cumulative conflicts in signal counts, autoload ordering, and enum values when the sessions are intended to be implemented sequentially. These are coordination issues, not design errors — they are fixable at implementation time with a single reconciliation pass.

**Verdict: Factually sound in isolation. Requires a sequencing reconciliation pass before serial implementation.**

---

## Per-Session Findings

### Session 01 — 50-Day Campaign Content Design

**Purpose:** Replace placeholder DayConfig data with a fully authored 50-day campaign table using mathematically grounded scaling curves.

**Factual accuracy:** GOOD
- Smoothstep formula `1.0 + 2.0 * t*t*(3-2t)` correctly produces the claimed range (1.0 at day 1 → 3.0 at day 50). Spot-checked day 10 (t=0.1837): `1.0 + 2.0 * 0.0888 = 1.1776` — matches table.
- Linear ramps for gold_reward and spawn_count are correctly computed.
- starting_gold formula `1000 + floor((day-1)*500/49)` yields 1000 at day 1 and 1500 at day 50 — correct.
- Wave count step progression (3→4→5) at days 1-10/11-30/31-50 is clean and standard.
- Faction rotation respects the "no run > 5" constraint — verified by visual inspection of the table.
- Mini-boss days at 10, 20, 30, 40 with boss IDs alternate correctly between orc_warlord and plague_cult_miniboss.

**Issues:**
1. **`starting_gold` field overlap:** DayConfig already has `mission_economy: MissionEconomyData` which may already handle starting gold. The spec acknowledges this with a TUNING comment ("if MissionEconomyData.starting_gold exists, prefer that and remove this") — reasonable hedge.
2. **`mission_index` field ignored:** The current DayConfig has a `mission_index` field separate from `day_index`. The spec's .tres samples omit it. The implementing agent would need to preserve or account for this.

---

### Session 02 — Sybil Passive System

**Purpose:** Implement the Sybil passive selection system (previously PLANNED, confirmed in AGENTS.md as "not in code yet; stubs only").

**Factual accuracy:** GOOD (with one convention error)

**Issues:**
1. **`class_name` convention error on SybilPassiveData:** Prompt 1 says "No class_name (convention: class_name only on non-autoloads per project)." This inverts the rule. The actual convention is: autoloads do NOT get `class_name`, but Resource classes DO. SybilPassiveData is a Resource and SHOULD get `class_name`. Session 4 correctly gives `class_name` to its Resources (ChronicleEntryData, ChroniclePerkData). This is a factual error in Session 2.
2. **Init 14 conflict with Session 4:** Both Session 2 (SybilPassiveManager) and Session 4 (ChronicleManager) claim Init #14 after SaveManager. First implementer gets the slot; the second must shift by +1.
3. **Signal count baseline:** Adds 2 signals (67→69), correct in isolation. Does not account for other sessions.
4. **`Array` without type specifier** in `prerequisite_ids: Array = []` — should ideally be `Array[String]` per static typing rules. Minor.

---

### Session 03 — Ring Rotation Pre-Battle UI

**Purpose:** Expand hex grid from 24 to 42 slots (6+12+24), add per-ring independent rotation, and create a pre-combat ring rotation UI with SubViewport preview.

**Factual accuracy:** GOOD

**Issues:**
1. **Signal count error:** States "Increment total from 67 to 68" (adding 1 signal: `ring_rotated`). If Session 2 is implemented first, the baseline would be 69, making the new total 70. The spec assumes the frozen 67 baseline.
2. **PASSIVE_SELECT dependency:** References `PASSIVE_SELECT = 11` from Session 2 when defining `RING_ROTATE = 12`, but signal counts don't reflect Session 2 being done. The GameState enum extension is correctly coordinated — the signal count is not.
3. **AGENTS.md says "24 slots across 3 rings"** — this would need updating. The doc sync prompt (Prompt 11) correctly identifies this.
4. **TOTAL_SLOTS from 24→42** is a significant structural change. The save migration approach (v1→v2, keeping slots 0-23 valid) is well-reasoned.
5. **`_ring_index_for_slot` comment says "boundaries change"** but then says "logic expression is unchanged." This is actually correct since Ring 2 still ends at index 17, and the change is only that Ring 3 now extends to index 41 instead of 23. The existing `else` branch catches it. Clear, if initially confusing.

---

### Session 04 — Chronicle Meta-Progression System

**Purpose:** Cross-run achievement/perk system with persistent `user://chronicle.json`, 18 achievements, and 8 micro-buff perks.

**Factual accuracy:** GOOD

**Issues:**
1. **Init 14 conflict (duplicate):** Claims Init 14 — same slot as Session 2's SybilPassiveManager.
2. **Signal count baseline:** Says "Current count is 67" and adds 3 → 70. Doesn't account for Sessions 2 or 3.
3. **`entry_campaign_day_50` and `entry_meta_first_run`** both trigger on `campaign_completed` with `{"count": 1}` and both reward `"title_survivor"`. The `entry_campaign_day_50` actually triggers on campaign_completed (reaching day 50), while `entry_meta_first_run` also triggers on `campaign_completed` with count 1. These are functionally identical — the "first run" IS completing a campaign. One of them is redundant unless "first run" means something different (e.g., mission_failed also counts as a "run"). Design intent is ambiguous.
4. **Many perk effects are explicitly stubbed** (SELL_REFUND_PCT, RESEARCH_COST_PCT, GOLD_PER_KILL_PCT, WAVE_REWARD_GOLD_FLAT). This is intentional and well-documented as TODO items in §33. Honest and practical.
5. **`boss_killed` signal assumed but not verified** — the spec notes boss IDs are placeholders and says to check `Types.EnemyType` T5 entries. Good self-awareness.
6. **Gold tracking via `enemy_killed.gold_reward`** — explicitly acknowledges undercounting from shop refunds, wave bonuses, territory bonuses. Good design note.

---

### Session 05 — Dialogue Content & Combat Lines

**Purpose:** Write hub dialogue for 6 NPC characters, add combat dialogue banner system, and create mid-battle trigger conditions.

**Factual accuracy:** GOOD

**Issues:**
1. **Optional CombatDialogueManager autoload** — the spec wisely says "This autoload may NOT be necessary" and leaves the decision to the implementing agent. Good engineering judgment.
2. **`enemy_spawned` signal assumed but says "TODO: confirm exact signature"** — honest about uncertainty. The signal may not exist or may have different parameters.
3. **`florence_damaged` signal** — same concern. The spec says "confirm how to read Florence current HP." Good.
4. **Dialogue writing quality** — the character voices are distinct and consistent: Arnulf (gruff, blunt), Sybil (condescending, formal), Merchant (pragmatic), Weapons Engineer (enthusiastic tinkerer), Enchanter (mystical), Mercenary Commander (military). All respect the medieval plague-doctor tone.
5. **Respects cut features:** No mention of Arnulf drunkenness in dialogue content. Arnulf's "Used to drink to forget. Now I just forget. Cheaper." references his past as flavor only — correctly handled.
6. **`sybil_research_unlocked_any` condition key** — not verified against existing condition keys in DialogueManager. The implementing agent would need to check or add this.

---

### Session 06 — Shop Rotation & Economy Tuning

**Purpose:** Add deterministic shop rotation with seeded RNG, expand shop catalog with 11 new items, and tune SimBot strategy profiles.

**Factual accuracy:** GOOD

**Issues:**
1. **`item_type` → `category` rename** is a breaking change for existing .tres files. The spec correctly identifies this (Step A: "Remove field item_type → Add field category") and lists all 4 existing items to update.
2. **`rand_weighted()` API** — Godot 4.4 `RandomNumberGenerator.rand_weighted()` accepts `PackedFloat32Array` and returns an index. This is correct per Godot 4.4 docs.
3. **Seed determinism:** Using `rng.seed = day_index` directly means day 0 and day 1 produce different results but the seed space is small. For a 50-day campaign this is fine. The spec correctly notes isolated RNG stream per system.
4. **New shop items reference methods that don't exist yet** (`Tower.add_max_hp_bonus`, `WaveManager.reveal_next_wave_composition`, `CampaignManager.set_next_mercenary_discount`). Prompt 5 creates these as stubs — correct sequencing.
5. **SimBot difficulty_target values** (0.5, 0.3, 0.7) — pure tuning. The claim that current values are 0.0 would need verification.

---

### Session 07 — Art Pipeline Integration

**Purpose:** Establish canonical animation clip tables, GLB drop zone paths, extend RiggedVisualWiring, create art validation script, and resolve TODO(ART) markers.

**Factual accuracy:** GOOD

**Issues:**
1. **Correctly removes `drunk_idle`** from all animation tables and pipeline docs — respects the formally cut Arnulf drunkenness system.
2. **30 enemy types and 36 building types** — these numbers match the AGENTS.md statement ("30 enemy types. 36 building types").
3. **`GLTFDocument.generate_scene()` gotcha** — the warning about `remove_immutable_tracks` defaulting true in scripted loads is well-researched and the recommended workaround (use `ResourceLoader.load()` instead) is correct.
4. **Report-only validation script** — good design principle. No mutation, safe to run at any time.
5. **No signal or enum changes** — clean session that only touches art pipeline infrastructure. No coordination conflicts with other sessions.
6. **Mercenary placeholders** (archer, knight, swordsman, barbarian) are clearly marked as scaffolding entries only.

---

### Session 08 — Star Difficulty Tier System

**Purpose:** Add NORMAL/VETERAN/NIGHTMARE difficulty tiers with per-territory star progression and multiplier-based scaling.

**Factual accuracy:** GOOD

**Issues:**
1. **Signal count:** Adds 2 signals (`territory_tier_cleared`, `territory_selected_for_replay`), claiming 67→69. Same frozen-baseline issue.
2. **`_apply_tier_to_day_config` returns a duplicate** — correct; it doesn't mutate the source DayConfig resource. Important for resource safety.
3. **Reward stubs are explicitly POST-MVP** — `veteran_perk_id` and `nightmare_title_id` on TerritoryData are forward-compatible hooks with no implementation. Honest scoping.
4. **`@export var highest_cleared_tier` with no `_init()` assignment** — correctly avoids the Godot exported-enum-returns-zero bug. Well-researched.
5. **Save backward compatibility** via `.get(key, default)` — standard pattern, correctly applied.
6. **UI paths marked as "PROPOSED — subject to change"** — honest acknowledgment of uncertainty.
7. **The `get_effective_multiplier` method has a bug in the spec:** it says `return base  # caller passes the specific multiplier field; see below` which returns `base` unconditionally. The actual multiplier logic is in `_apply_tier_to_day_config`. The standalone helper method as written is a no-op. The implementing agent should note this.

---

### Session 09 — Building HP & Destruction System

**Purpose:** Add health components to buildings, enemy building-targeting, destruction effects, world-space HP bars, and building repair shop item.

**Factual accuracy:** GOOD

**Issues:**
1. **`max_hp = 0` means indestructible** — clean backward-compatible default. All existing .tres files remain functional.
2. **Conditional `HealthComponent` via `add_child` in `_ready`** — idiomatic Godot pattern.
3. **Enemy retargeting** with separate `building_detection_radius` — well-separated from attack range. The "fully stop pathing to tower while building alive" design is clear.
4. **`DestructionEffect` under `/root/Main/FX`** — correctly avoids the Godot tween-killed-on-parent-free issue by using a stable container.
5. **Building repair targets lowest HP percentage, not absolute** — correct design choice. The HP% comparison formula `float(hc.current_hp) / float(hc.max_hp)` handles different max_hp values fairly.
6. **No new signals needed** — `building_destroyed(slot_index)` already exists on SignalBus. This session activates it.
7. **Medium buildings at 300 HP, large at 650 HP** — reasonable starting values with "tune per balancing" notes. Small buildings left indestructible (max_hp=0) — intentional.

---

### Session 10 — Graphics Quality Wiring

**Purpose:** Wire `SettingsManager.set_graphics_quality()` to actual Godot rendering APIs, promote string quality to enum, add Custom preset with per-toggle controls.

**Factual accuracy:** GOOD

**Issues:**
1. **WorldEnvironment doesn't exist in the repo** — the spec correctly identifies this as THEORYCRAFT and places appropriate null guards and comments. Good engineering.
2. **Shadow disable quirk** (Godot Proposals #6612) — well-researched. The workaround (set atlas size to 0 AND iterate directional lights to set `light_angular_distance = 0.0`) is the community-recommended approach.
3. **Signal count:** Adds 1 signal (`graphics_quality_changed`), claiming 67→68. Same frozen-baseline issue.
4. **`graphics_quality_changed(quality: int)`** uses `int` parameter type rather than the enum type. This is intentional for C# interop (Godot signals with enum types can be problematic across the GDScript/C# boundary). Acceptable.
5. **Per-toggle flat keys** in settings.cfg (`graphics/shadows_enabled`, etc.) — simple, readable, alternatives noted.

---

## Cross-Session Coordination Issues

These are the most important findings. None are design flaws — they are sequencing conflicts from parallel authoring.

### 1. Signal Count Accumulation

| Session | Signals Added | Claims Total | Correct Total (Sequential) |
|---------|--------------|-------------|---------------------------|
| Baseline | — | 67 | 67 |
| S01 | 0 | 67 | 67 |
| S02 | 2 | 69 | 69 |
| S03 | 1 | 68 (wrong) | 70 |
| S04 | 3 | 70 (wrong) | 73 |
| S05 | 1-2 (agent decides) | ~69 (wrong) | 74-75 |
| S06 | 0 | — | 74-75 |
| S07 | 0 | — | 74-75 |
| S08 | 2 | 69 (wrong) | 76-77 |
| S09 | 0 | — | 76-77 |
| S10 | 1 | 68 (wrong) | 77-78 |

**Fix:** After implementing all sessions, do a single `grep -c "^signal " autoloads/signal_bus.gd` and update all doc locations once.

### 2. Autoload Init #14 Conflict

Both Session 2 (SybilPassiveManager) and Session 4 (ChronicleManager) claim Init #14 (after SaveManager at Init #13). Whichever is implemented second must take Init #15 and shift subsequent autoloads.

**Fix:** Determine implementation order, assign slots sequentially.

### 3. GameState Enum Value Coordination

| Value | Session | Enum Name |
|-------|---------|-----------|
| 0-10 | existing | MAIN_MENU through ENDLESS |
| 11 | S02 | PASSIVE_SELECT |
| 12 | S03 | RING_ROTATE |

Session 3 correctly depends on Session 2's PASSIVE_SELECT = 11 to place RING_ROTATE = 12. This dependency chain is sound if sessions are implemented in order.

### 4. Types.gd Enum Additions Across Sessions

| Session | Enum Added |
|---------|------------|
| S02 | GameState.PASSIVE_SELECT = 11 |
| S03 | GameState.RING_ROTATE = 12 |
| S04 | ChronicleRewardType (3 values), ChroniclePerkEffectType (10 values) |
| S08 | DifficultyTier (3 values) |
| S10 | GraphicsQuality (4 values) |

No integer value conflicts — each enum is independent. FoulWardTypes.cs mirrors required after each.

---

## What Works Well

1. **Research depth** — every design decision is backed by verifiable sources (Godot docs, community forums, academic papers, open-source repos). Attribution is thorough.
2. **Convention compliance** — all 10 sessions respect the project's static typing rules, SignalBus-only communication, no magic numbers, `push_warning` not `assert`, `get_node_or_null` with guards, and resource-driven data patterns.
3. **Cut feature discipline** — Arnulf drunkenness is explicitly removed in Session 7 and never referenced in dialogue (Session 5). No Time Stop, no Hades hub.
4. **Honest scoping** — POST-MVP stubs, TODO markers, "THEORYCRAFT" labels, and "agent decides" decision points show mature engineering judgment rather than over-promising.
5. **Test coverage** — every session includes GdUnit4 test plans with specific method names and assertion targets.
6. **Backward compatibility** — save migration (Session 3), `.get(key, default)` patterns (Session 8), and `max_hp = 0` defaults (Session 9) all protect existing data.
7. **"Caveman prompting" style** — dense, imperative, no filler. Maximizes signal-to-noise for an implementing agent.

---

## Recommendations

1. **Create a sequencing reconciliation document** before serial implementation. It should track: cumulative signal count, autoload init order, GameState enum values, and test count after each session.
2. **Fix Session 2's `class_name` guidance** for SybilPassiveData — it should have `class_name` since it's a Resource, not an autoload.
3. **Resolve the `entry_campaign_day_50` / `entry_meta_first_run` redundancy** in Session 4 — clarify if "first run" means something distinct from "complete a full campaign."
4. **Note the `get_effective_multiplier` no-op** in Session 8 Prompt 3 — the method body returns `base` unconditionally. The implementing agent should either fix this or remove it in favor of `_apply_tier_to_day_config` which does the actual work.
5. **Run `dotnet build` after all C# enum additions**, not just after individual sessions. The FoulWardTypes.cs file will accumulate 5 new enum blocks.

---

## Conclusion

The Perplexity output is a high-quality design and implementation planning artifact. The research is rigorous, the architectural decisions are well-motivated, and the prompts are clear enough for an implementing agent to follow. The main gap is cross-session coordination — a natural consequence of authoring 10 sessions against a frozen baseline. This is easily resolved with a reconciliation pass at implementation time. None of the identified issues are blockers.
