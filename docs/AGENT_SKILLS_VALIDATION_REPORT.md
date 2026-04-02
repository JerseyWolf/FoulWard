# Agent Skills Validation Report

Date: 2026-03-31  
Sessions validated: 0, A, B, C, D, E (parallel implementation audit)

## Summary

The Agent Skills layout under `.cursor/skills/` is **largely complete**: all **20** expected Markdown paths exist and are non-empty, **`.cursorrules` → `AGENTS.md` (repo root)** is correct, **`docs/AGENTS.md` was a stale duplicate** and was **removed** after comparison, and **root `AGENTS.md` was repaired** so it no longer points at the removed path. **Session C** cleared all **`⚠️ VERIFY`** markers (current count **0**). **`./tools/run_gdunit_quick.sh`** reported **1 failed** test and **1 orphan** (exit **100**), consistent with prior logs — **not introduced by this validation session**. Remaining gaps: **indexes and several SKILL files still mention `docs/AGENTS.md`**, **INDEX lists 16 skill-related paths (AGENTS + 15 `SKILL.md`) not all 20 file paths**, and **Session D / Session E implementation logs are ambiguous or missing** (see Step 8).

---

## Step Results

### 0. AGENTS.md Deduplication and Content Check

**0a.** `docs/AGENTS.md` **existed** and **differed materially** from repo-root `AGENTS.md`: it was the **legacy long-form Prompt 27 document** (outdated autoload order, e.g. missing `NavMeshManager` in the numbered list, different structure). Root `AGENTS.md` matched the **FILE 1** lean template from `AGENT_SKILLS_STAGING.md`. **Action:** **Deleted `docs/AGENTS.md`** — no merge of legacy content into root (would reintroduce incorrect autoload order and duplicate `AGENTS.md`).

**0b.** Compared root `AGENTS.md` to staging **FILE 1** (between the first ` ```markdown ` block in `AGENT_SKILLS_STAGING.md`). **Before repair:** body matched staging except the user-mandated migration was incomplete (staging still says `docs/AGENTS.md` in several places). **Repairs applied to `AGENTS.md`:** (1) autoload-order heading now references **`AGENTS.md` + `docs/FOUL_WARD_MASTER_DOC.md` §3** instead of `docs/AGENTS.md`; (2) Key Documents table row for standing orders now **`AGENTS.md` (repo root, this file)**; (3) Known Gotchas pointer now **`docs/FOUL_WARD_MASTER_DOC.md`** instead of `docs/AGENTS.md §9`. **Result:** **AGENTS.md content VERIFIED** against staging with **approved migration fixes** (not regressions).

**0c.** **`.cursorrules`:** `ls -la` → symlink **`AGENTS.md`** (9 bytes). **PASS** (no change needed).

**0d.** **`grep -r "docs/AGENTS.md" .cursor/skills/ docs/`** — hits to record for follow-up (do not auto-fix):

| File | Notes |
|------|--------|
| `.cursor/skills/godot-conventions/SKILL.md` | Lines 22, 30, 150 — read `docs/AGENTS.md` |
| `.cursor/skills/mcp-workflow/SKILL.md` | Lines 72, 76, 82 — paths and checklist |
| `.cursor/skills/scene-tree-and-physics/SKILL.md` | Line 63 — contract paths + `docs/AGENTS.md` |
| `docs/INDEX_SHORT.md` | Line 10 — pointer to full `docs/AGENTS.md` |
| `docs/INDEX_FULL.md` | Line 35 — `docs/AGENTS.md` for “full sections” |
| `AGENT_SKILLS_STAGING.md` | Staging source still contains old paths (expected for archive/reference) |
| `docs/archived/*` | Historical references — optional cleanup only |

---

### 1. File Existence

Commands: `find .cursor/skills -name "*.md" | sort` → **19** files under `.cursor/skills/`; plus **`AGENTS.md`** at repo root → **20** expected paths total.

| File | Status | Line count |
|------|--------|------------|
| `AGENTS.md` | PRESENT | 162 |
| `.cursor/skills/godot-conventions/SKILL.md` | PRESENT | 233 |
| `.cursor/skills/anti-patterns/SKILL.md` | PRESENT | 234 |
| `.cursor/skills/signal-bus/SKILL.md` | PRESENT | 91 |
| `.cursor/skills/signal-bus/references/signal-table.md` | PRESENT | 151 |
| `.cursor/skills/enemy-system/SKILL.md` | PRESENT | 139 |
| `.cursor/skills/enemy-system/references/enemy-types.md` | PRESENT | 82 |
| `.cursor/skills/building-system/SKILL.md` | PRESENT | 130 |
| `.cursor/skills/building-system/references/building-types.md` | PRESENT | 61 |
| `.cursor/skills/economy-system/SKILL.md` | PRESENT | 124 |
| `.cursor/skills/campaign-and-progression/SKILL.md` | PRESENT | 118 |
| `.cursor/skills/campaign-and-progression/references/game-manager-api.md` | PRESENT | 47 |
| `.cursor/skills/testing/SKILL.md` | PRESENT | 132 |
| `.cursor/skills/add-new-entity/SKILL.md` | PRESENT | 116 |
| `.cursor/skills/mcp-workflow/SKILL.md` | PRESENT | 87 |
| `.cursor/skills/scene-tree-and-physics/SKILL.md` | PRESENT | 136 |
| `.cursor/skills/spell-and-research-system/SKILL.md` | PRESENT | 122 |
| `.cursor/skills/ally-and-mercenary-system/SKILL.md` | PRESENT | 123 |
| `.cursor/skills/lifecycle-flows/SKILL.md` | PRESENT | 118 |
| `.cursor/skills/save-and-dialogue/SKILL.md` | PRESENT | 112 |
| `docs/AGENTS.md` | **REMOVED** (was duplicate; must stay absent) | — |

---

### 2. `.cursorrules` Symlink

- **`ls -la .cursorrules`:** `lrwxrwxrwx … .cursorrules -> AGENTS.md`  
- **`head -5`:** First line **`# Foul Ward — Agent Standing Orders`**  
**PASS**

---

### 3. Archived Files

| Expected | Status |
|----------|--------|
| `docs/archived/CONVENTIONS_MVP.md` | **PRESENT** |
| `docs/archived/ARCHITECTURE_pre_prompt*.md` | **PRESENT** as `ARCHITECTURE_pre_prompt53.md` |
| `docs/AGENTS.md` in `docs/archived/` | **ABSENT** (correct — duplicate was deleted, not archived) |

---

### 4. `docs/CONVENTIONS.md` Updates (Session A)

| Check | Result | Found |
|-------|--------|--------|
| Autoload count **17** (not 4) | **PASS** | §1 tree + note: **17 gameplay-related autoloads** (+ `GDAIMCPRuntime` / §19 order) |
| `BuildingType` **36** entries | **PASS** | Full enum block `ARROW_TOWER` … `CITADEL_AURA` (36 values) |
| `EnemyType` **30** entries | **PASS** | Full enum block through `PLAGUE_HERALD` (30 values) |
| `DamageType` includes **TRUE** | **PASS** | `TRUE` in enum block; `Types.DamageType.TRUE` note §3.3 |
| `WAVES_PER_MISSION = 5` | **PASS** | §3.2 `const WAVES_PER_MISSION: int = 5` |
| `DEFAULT_GOLD = 1000` | **PASS** | §3.1 `gold: int = 1000` / `# DEFAULT_GOLD` |
| Signal list **58+** | **PASS** | §5: **58+** typed declarations |
| Changelog at top | **PASS** | `## Changelog` → `### 2026-03-31` |

Overall: **PASS**

---

### 5. `docs/ARCHITECTURE.md` Updates (Session B)

| Check | Result |
|-------|--------|
| Manager paths `/root/Main/Managers/{WaveManager,SpellManager,ResearchManager,ShopManager,WeaponUpgradeManager,InputManager}` | **PASS** (§2 tree + “Manager node path contracts”) |
| **17** autoloads listed | **PARTIAL** — §1 table lists **20** `project.godot` rows (17 core + `GDAIMCPRuntime` + 3 Godot MCP addon helpers); prose in §3.1 clarifies “17 core game singletons + …” |
| No Arnulf **drunkenness** / **Time Stop** | **PASS** (no matches) |
| No **`docs/AGENTS.md`** | **PASS** (no matches) |

---

### 6. Remaining `⚠️ VERIFY` Comments

- **`grep -r "⚠️ VERIFY" .cursor/skills/`** → **0** lines (no matches).  
- **`grep -r "VERIFY" .cursor/skills/`** → no standalone VERIFY tasks found.  
**Session C** (`docs/PROMPT_1_IMPLEMENTATION.md`) documents removal of all markers after cross-check. **Total VERIFY count: 0.** **Unresolved: none.**

---

### 7. INDEX Files (Session E)

- **Skill entries vs 20 paths:** `docs/INDEX_SHORT.md` lists **`AGENTS.md` + 15 × `.cursor/skills/*/SKILL.md`** = **16** lines — **four reference files** (`signal-table.md`, `enemy-types.md`, `building-types.md`, `game-manager-api.md`) are **not** one-liners in `INDEX_SHORT`.  
- **`docs/INDEX_FULL.md`:** Structured entries exist for **AGENTS.md + 15 skills**; **reference `.md` files are not given the same standalone entries** as the 20-path checklist.  
- **Root `AGENTS.md`:** Listed and described correctly as repo root.  
- **`docs/AGENTS.md`:** Still mentioned in **`INDEX_FULL.md` line 35** and **`INDEX_SHORT.md` line 10** — **FAIL** for path correctness (file removed).  

**Count:** **16** indexed skill-related paths vs **20** expected file paths → **PARTIAL** coverage.

---

### 8. Implementation Logs

| Session | Mapped log | Date / content | Status |
|---------|------------|----------------|--------|
| **0** | `docs/PROMPT_0_IMPLEMENTATION.md` | 2026-03-31; staging → files | **PRESENT** |
| **A** | `docs/PROMPT_54_IMPLEMENTATION.md` | CONVENTIONS refresh + archive | **PRESENT** |
| **B** | `docs/PROMPT_53_IMPLEMENTATION.md` | ARCHITECTURE audit | **PRESENT** |
| **C** | `docs/PROMPT_1_IMPLEMENTATION.md` | Skills VERIFY (uses **PROMPT_1** filename) | **PRESENT** |
| **D** | — | No dedicated `PROMPT_*` file clearly scoped as “Session D” | **MISSING / unclear** |
| **E** | — | INDEX updates appear in **`INDEX_*` headers** (“Prompt 54” blurbs) but **`PROMPT_54_IMPLEMENTATION.md` documents CONVENTIONS only** — index work **not** in that log body | **PARTIAL / ambiguous** |

No log in this set states **“nothing done.”**

---

### 9. Test Suite (`./tools/run_gdunit_quick.sh`)

| Metric | Value |
|--------|--------|
| Exit code | **100** |
| Failures | **1** (`test_simbot_can_run_and_place_buildings` in `tests/test_simbot_basic_run.gd`) |
| Orphans | **1** |
| Cases | **389** (per summary) |

**New failures this session:** **None** (validation did not change game code; failure matches known SimBot/build-phase issue from prior logs).

---

### 10. Cross-Reference Spot Checks

| Check | Expected | Actual | Result |
|-------|----------|--------|--------|
| **A** — `signal_bus.gd` signal count | ≥ 58 | **63** `^signal ` lines | **PASS** |
| **B** — `BuildingType` enum size | 36 | **36** (indices 0–35) | **PASS** |
| **C** — `EnemyType` enum size | 30 | **30** (indices 0–29) | **PASS** |
| **D** — `WAVES_PER_MISSION` | 5 | **5** | **PASS** |
| **E** — `DEFAULT_GOLD` | 1000 | **1000** | **PASS** |

---

## Action Items

1. **BLOCKER — path migration:** Update remaining **`docs/AGENTS.md`** string references to **`AGENTS.md`** (repo root) and/or **`docs/FOUL_WARD_MASTER_DOC.md`** in: `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, `.cursor/skills/godot-conventions/SKILL.md`, `.cursor/skills/mcp-workflow/SKILL.md`, `.cursor/skills/scene-tree-and-physics/SKILL.md` — **Session follow-up (docs + skills)**.

2. **BLOCKER — index completeness:** Add **`INDEX_SHORT` / `INDEX_FULL` entries** for the **four** skill **reference** Markdown files (or document explicitly that only `SKILL.md` files are indexed) — **Session E / indexing**.

3. **NICE-TO-FIX — implementation logs:** Add or rename a log so **Session D** and **Session E** (INDEX-only) are **traceable** (avoid **PROMPT_1** vs Session C ambiguity; reconcile **PROMPT_54** title with INDEX header “Prompt 54” skills wording) — **docs hygiene**.

4. **NICE-TO-FIX — tests:** Fix **`test_simbot_can_run_and_place_buildings`** (and orphan) or document as known baseline — **testing / SimBot** (not Agent Skills per se).

5. **NICE-TO-FIX — staging:** Optionally refresh **`AGENT_SKILLS_STAGING.md` FILE 1** to match migrated **`AGENTS.md`** so future diffs are clean — **optional**.

---

## What Worked Well

- **Single lean `AGENTS.md` + `.cursorrules` symlink** matches the intended Cursor workflow; **duplicate `docs/AGENTS.md` removal** eliminates conflicting standing orders.  
- **All 20 skill-related Markdown files** are present with substantial content; **Session C** left **zero VERIFY debt** in `.cursor/skills/`.  
- **`docs/CONVENTIONS.md`** changelog and enum/signal/economy constants align with **`docs/FOUL_WARD_MASTER_DOC.md`** and the codebase.  
- **`docs/ARCHITECTURE.md`** manager path contracts and scene tree match **`AGENTS.md`** and contracted paths.
