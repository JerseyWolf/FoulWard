# Compliance Report H5 — MCP Workflow, Add New Entity, Save and Dialogue

Date: 2026-03-31

Scope: Audited per Agent Skills `mcp-workflow`, `add-new-entity`, and `save-and-dialogue`. Report only — no code fixes applied.

---

## Skill: mcp-workflow

### CHECK A — stdout in GDAI bridge scripts

**By reference — H1 anti-patterns CHECK F.**

`docs/COMPLIANCE_REPORT_H1.md` reports **34 `print()` statements** in `autoloads/auto_test_driver.gd` (not GDAI bridge scripts). No additional GDAI bridge `print` sweep in H5.

### CHECK B — foulward-rag optional (not blocking)

**PASS** in active config and skills:

- `.cursor/skills/mcp-workflow/SKILL.md` marks `foulward-rag` as **Optional** and states agents must NOT block if down.
- `docs/FOUL_WARD_MASTER_DOC.md` and `docs/INDEX_FULL.md` reference optional RAG.

**FLAG — 1 doc treats RAG as mandatory:**

- `docs/archived/OPUS_ALL_ACTIONS.md` — e.g. “**[Critical]** Configure foulward-rag MCP server…” (instruction reads as required, not optional).

### CHECK C — AGENTS.md MCP session checklist

**PASS.** `AGENTS.md` lines 68–70 list:

- `get_scene_tree` — validate node paths before any `get_node()` call  
- `get_godot_errors` — check for new errors after changes  

### CHECK D — “No Tools Recovery” in mcp-workflow skill

**PASS.** `.cursor/skills/mcp-workflow/SKILL.md` §“No Tools” Recovery Procedure lists five numbered fallback steps (log, filesystem-workspace, contracted paths, read `.tscn`, do not block).

---

## Skill: add-new-entity

### CHECK A — BuildingType enum append-only (git history)

**PASS (no re-numbering of existing `BuildingType` members).**

`git log --oneline scripts/types.gd | head -10` shows recent work; `git show 28d3f23` expands `BuildingType` by **appending** new members after `SHIELD_GENERATOR` without reordering prior enum names.

*Note:* Same commit inserts `DamageType.TRUE` mid-`DamageType` enum (after `POISON`), which renumbers later `DamageType` values — **out of scope** for BuildingType-only check; flag only if serialized `DamageType` ints must stay stable.

### CHECK B — `building_id` matches `.tres` filename

**PASS — 0 mismatches** across `resources/building_data/*.tres` (each `building_id = "<stem>"` matches `FILE: .../<stem>.tres`).

### CHECK C — ResearchNodeData uses `node_id`, not bare `id`

**PASS.** `grep` over `resources/research_data/` for `"id":`, `^id =`, `^id=` returned **no matches**.

### CHECK D — `.gd` files listed in `docs/INDEX_SHORT.md`

**PASS (≥80%).**

- `find autoloads/ scripts/ scenes/ -name "*.gd"` → **88** files.  
- Naive `grep -f` full paths vs `INDEX_SHORT.md` can over-count (95); **basename** match: **88/88 (100%)**.

### CHECK E — Cross-system signals only on SignalBus

**By reference — H1 signal-bus CHECK A.**

`docs/COMPLIANCE_REPORT_H1.md`: **2** findings (`build_phase_manager.gd` phase signals; informational `ally_base` local signal).

---

## Skill: save-and-dialogue

### CHECK A — SaveManager has no `class_name`

**PASS.** Only comment line references “no class_name” (`grep class_name` → comment only).

### CHECK B — RelationshipManager has no `class_name`

**PASS.** Same pattern — comment only.

### CHECK C — Save payload keys and `get_save_data()` wiring

**PASS.**

`_build_save_payload()` includes: `campaign`, `game`, `relationship`, `research`, `shop`, `enchantments`.  
`_apply_save_payload()` restores each.  

Project `func get_save_data()` implementations exist only on: `CampaignManager`, `GameManager`, `RelationshipManager`, `ResearchManager`, `ShopManager`, `EnchantmentManager` — all wired.

### CHECK D — Extra save calls

**By reference — H2 economy CHECK E.**

`docs/COMPLIANCE_REPORT_H2.md`: `GameManager` connects `mission_won` / `mission_failed` to call `SaveManager.save_current_state()`; strict reading expected listeners **inside** `SaveManager` — **policy mismatch** (not extra ad-hoc saves elsewhere).

### CHECK E — Affinity deltas not hardcoded (RelationshipEventData)

**Production: PASS.** `RelationshipManager.add_affinity` from events uses `event.character_deltas` (resource-driven) at `autoloads/relationship_manager.gd` (~187).

**Tests: informational.** `tests/test_relationship_manager*.gd`, `tests/test_save_manager_slots.gd` use literal deltas for tier boundaries — acceptable test fixtures; strict skill text would still count them as literals.

### CHECK F — Dialogue `character_id` literals vs seven canonical IDs

**Canonical set:** `FLORENCE`, `COMPANION_MELEE`, `SPELL_RESEARCHER`, `MERCHANT`, `WEAPONS_ENGINEER`, `ENCHANTER`, `MERCENARY_COMMANDER`.

**Production UI — 2 extra literal IDs in `match` (not in the seven):**

| File | Literals |
|------|----------|
| `ui/ui_manager.gd` | `CAMPAIGN_CHARACTER_X`, `EXAMPLE_CHARACTER` |
| `ui/dialogue_ui.gd` | `CAMPAIGN_CHARACTER_X`, `EXAMPLE_CHARACTER` |

**Tests** use `EXAMPLE_CHARACTER`, `TEST_CHAR`, `CHAR_A`, etc. — fixture/stub IDs (expected for tests).

---

## H5 Priority Violations (this session)

1. **Archived doc** — `docs/archived/OPUS_ALL_ACTIONS.md` frames foulward-rag setup as **Critical/mandatory** (mcp-workflow CHECK B).
2. **Dialogue display names** — `CAMPAIGN_CHARACTER_X` / `EXAMPLE_CHARACTER` in production UI match arms vs strict seven-ID list (save-and-dialogue CHECK F).

---

## H5 Totals

| Skill | Violations (H5-only) |
|------|------------------------:|
| mcp-workflow | 1 (archived doc) |
| add-new-entity | 0 |
| save-and-dialogue | 2 (production character_id extras) |
| **H5 numeric** | **3** |

*End of Compliance Report H5.*
