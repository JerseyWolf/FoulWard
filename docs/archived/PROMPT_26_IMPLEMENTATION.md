# PROMPT_26_IMPLEMENTATION.md

**Session type:** Full Project Audit (Opus 4.6)
**Date:** 2026-03-28
**Session goal:** Complete 9-phase audit of the entire Foul Ward project.

---

## Phase 0 — Orientation

### MCP Status
- **GDAI MCP (gdai-mcp-godot):** Working. Scene tree, error console, script viewing all functional.
- **Godot MCP Pro:** Available. 163+ tools accessible.
- **Sequential Thinking:** Available.
- **foulward-rag:** NOT AVAILABLE. Server not configured in `.cursor/mcp.json`. RAG queries (`query_project_knowledge`, `get_recent_simbot_summary`) cannot be answered.

### Scene Tree Verification
Scene tree from `get_scene_tree` matches ARCHITECTURE.md and INDEX_SHORT.md. All 24 hex slots, 10 spawn points, 3 ally spawn points, all manager nodes, and all UI panels present and correctly typed.

### Error Console
Clean — "Session has no errors". Only MCP connection cycling logs visible (normal behavior).

### Autoload Order (from project.godot)
1. SignalBus → 2. DamageCalculator → 3. EconomyManager → 4. CampaignManager → 5. RelationshipManager → 6. SettingsManager → 7. GameManager → 8. SaveManager → 9. DialogueManager → 10. AutoTestDriver → 11. GDAIMCPRuntime → 12. EnchantmentManager → 13-15. MCP addon autoloads

---

## Phase 1 — Test Suite Audit

### Results
| Runner | Suites | Cases | Failures | Orphans | Time |
|--------|--------|-------|----------|---------|------|
| `run_gdunit.sh` | 58/58 | 525 | 0 | 17 | 4m 22s |
| `run_gdunit_quick.sh` | 37/37 | 336 | 0 | 1 | 1m 44s |

No changes from Sonnet pre-pass baseline.

### Test Classification
- 33 files classified as Unit (pure logic, no await/timers/scenes)
- 25 files classified as Integration (scene instantiation, physics, timers)
- Full classification table in IMPROVEMENTS_TO_BE_DONE.md §1

### Parallel Runner
Designed `run_gdunit_parallel.sh` spec — 8-process parallel runner. See IMPROVEMENTS_TO_BE_DONE.md Appendix E.

---

## Phase 2 — MCP & RAG Pipeline

RAG pipeline is not available (server not configured). All 6 test queries returned NO_ANSWER. GDAI MCP and Godot MCP Pro both functional. See IMPROVEMENTS_TO_BE_DONE.md §2.

---

## Phase 3 — Code Quality Audit

### Key Findings
- **24 functions** exceed 40 lines (largest: `WaveManager._spawn_wave` at 82 lines)
- **11 bare `get_node()` calls** in `input_manager.gd`, `ui_manager.gd`, `build_menu.gd`, `hud.gd`
- **1 SignalBus bypass**: `UIManager` connects directly to `DialogueManager.dialogue_line_finished`
- **30+ `assert()` calls** in production code across autoloads, scripts, and scenes
- **No autoload caching violations** found
- **Good `is_instance_valid()` coverage** — only `ally_base.gd` `_spawn_ally_projectile` is a minor hardening candidate

Full table in IMPROVEMENTS_TO_BE_DONE.md §3.

---

## Phase 4 — Resource File Audit

### Summary
- **0 BUGs** found in resource files
- 88 flagged items from pre-scan: all classified as PLACEHOLDER_ACCEPTABLE or INTENTIONAL
- Key intentional patterns: empty `faction_id` in 50-day campaign (falls back to DEFAULT_MIXED), `slow_field.tres` damage=0 (control spell), empty `chain_next_id` (non-chained dialogue)
- All `RelationshipEventData` signal_names are valid SignalBus signals
- All `CharacterRelationshipData` character_ids are referenced elsewhere
- All shop `effect_tags` are handled by `_apply_consumable_effect()`

Full table in IMPROVEMENTS_TO_BE_DONE.md §4.

---

## Phase 5 — Documentation & Index Audit

### INDEX_SHORT.md
- 55 unindexed files identified and added in Phase 7
- 0 missing files (all indexed files exist on disk)

### INDEX_FULL.md
- Spot-checked 15 entries including RelationshipManager, SaveManager, SettingsManager
- Method signatures, signals, and dependencies are accurate

### Open TODOs from Prior Prompts
- P13 placeholder dialogue text: OPEN
- P15 Florence meta-state integration: PARTIALLY OPEN
- P19 TODO(ART) annotations: OPEN (blocked on art pipeline)

---

## Phase 6 — Post-MVP Stub Inventory

### Never-Emitted Signals: 5
- `enemy_reached_tower` (POST-MVP)
- `ally_state_changed` (POST-MVP)
- `wave_failed` (OBSOLETE — remove)
- `wave_completed` (OBSOLETE — remove)
- `building_destroyed` (POST-MVP)

### Pass-Only Functions: 6
All in `dialogue_manager.gd` and `wave_manager.gd` — classified as READY for implementation.

### Orphaned Enum Values: 1
- `Types.AllyRole.TANK` — never used in any .tres or .gd file

---

## Phase 7 — Direct Fixes Applied

| # | Fix | Files Modified |
|---|-----|---------------|
| 7a | Added 55 unindexed files to INDEX_SHORT.md test section | `docs/INDEX_SHORT.md` |
| 7e | Verified `run_gdunit_visible.sh` exists and is correct | (no change needed) |
| 7f | Created authoritative AGENTS.md with standing orders | `docs/AGENTS.md` |

### Fixes NOT needed (confirmed clean):
- 7b: No Sonnet-added comments contradict code behavior
- 7c: All RelationshipEventData .tres signal_names are valid SignalBus signals
- 7d: No AllyData .tres has `uses_downed_recovering = true` with `recovery_time = 0`

---

## Phase 8 — Final Report

Assembled `IMPROVEMENTS_TO_BE_DONE.md` with all 8 sections + 5 appendices.

---

## Phase 9 — AGENTS.md

Created `docs/AGENTS.md` with 9 sections + 12 known gotchas.

---

## Files Created/Modified

| File | Action |
|------|--------|
| `IMPROVEMENTS_TO_BE_DONE.md` | Created — full improvement backlog |
| `docs/AGENTS.md` | Created — standing orders for all future sessions |
| `docs/PROMPT_26_IMPLEMENTATION.md` | Created — this log |
| `docs/INDEX_SHORT.md` | Modified — added 55 unindexed files |

---

## Final Test Results

Same as initial: 525 cases, 0 failures, 17 orphans. No code changes were made that could affect test outcomes.

---

## Follow-up — `docs/OPUS_ALL_ACTIONS.md`

Consolidated single-file snapshot created at `docs/OPUS_ALL_ACTIONS.md` containing: root `IMPROVEMENTS_TO_BE_DONE.md`, `docs/AGENTS.md` (first 108 lines, canonical standing orders), `docs/PROMPT_26_IMPLEMENTATION.md`, full `docs/INDEX_SHORT.md`, full `docs/INDEX_FULL.md`. `INDEX_SHORT.md` / `INDEX_FULL.md` headers updated to reference this file.
