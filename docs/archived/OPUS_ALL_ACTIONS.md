> ⚠️ **ARCHIVED:** foulward-rag references in this document treat RAG as mandatory. Current policy: RAG is optional. See `.cursor/skills/mcp-workflow/SKILL.md`.

# FOUL WARD — OPUS ALL ACTIONS (Consolidated)

**Generated:** 2026-03-28

This file consolidates (read-only snapshot): `IMPROVEMENTS_TO_BE_DONE.md`, `docs/AGENTS.md`, `docs/PROMPT_26_IMPLEMENTATION.md`, `docs/INDEX_SHORT.md`, and `docs/INDEX_FULL.md`. For day-to-day work, prefer the canonical files; update those first, then regenerate this consolidation if needed.

---

# Part 1 — Improvement Backlog (`IMPROVEMENTS_TO_BE_DONE.md`)

# FOUL WARD — Improvement Backlog
Generated: 2026-03-28 | Auditor: Opus 4.6 (Prompt 26) | Baseline: 525 cases, 0 failures, 17 orphans

## Summary
- Total issues: 78 | Critical: 3 | High: 18 | Medium: 32 | Low: 25
- Direct fixes applied: 4 (INDEX_SHORT.md updates, AGENTS.md rewrite, run_gdunit_visible.sh verified, PROMPT_26_IMPLEMENTATION.md)

## How to use this file
Work top to bottom. Every issue has file + line + suggested fix.
After each batch, run `./tools/run_gdunit_parallel.sh` (or `run_gdunit.sh`
until parallel runner is implemented).

---

## 1. Test Suite

### Current Metrics

| Runner | Suites | Cases | Failures | Orphans | Wall-clock |
|--------|--------|-------|----------|---------|------------|
| `run_gdunit.sh` (full) | 58 | 525 | 0 | 17 | 4m 22s |
| `run_gdunit_quick.sh` (quick) | 37 | 336 | 0 | 1 | 1m 44s |

### Three-Tier Test Structure Proposal

| Tier | Script | Contents | Target time |
|------|--------|----------|-------------|
| Unit | `run_gdunit_unit.sh` | Pure logic tests — no `await`, no scene instantiation, no timers | < 10 seconds |
| Integration | `run_gdunit_parallel.sh` | All other tests, 8 parallel headless processes | < 45 seconds |
| Visible | `run_gdunit_visible.sh` | Full suite, no `--headless`, for debugging | No time target |

### Per-File Unit/Integration Classification

| File | Classification | Reason |
|------|---------------|--------|
| test_economy_manager.gd | Unit | Pure autoload logic |
| test_damage_calculator.gd | Unit | Stateless function |
| test_health_component.gd | Unit | Component math |
| test_art_placeholders.gd | Unit | Resource loading only |
| test_ally_data.gd | Unit | Resource validation |
| test_faction_data.gd | Unit | Resource validation |
| test_boss_data.gd | Unit | Resource validation |
| test_territory_data.gd | Unit | Resource validation |
| test_campaign_manager.gd | Unit | Autoload state |
| test_endless_mode.gd | Unit | Autoload state |
| test_research_manager.gd | Unit | Tree state |
| test_shop_manager.gd | Unit | Purchase logic |
| test_consumables.gd | Unit | Effect application |
| test_enchantment_manager.gd | Unit | Slot state |
| test_territory_economy_bonuses.gd | Unit | Calculation |
| test_campaign_territory_mapping.gd | Unit | Data validation |
| test_campaign_territory_updates.gd | Unit | State mutation |
| test_mercenary_offers.gd | Unit | Offer generation |
| test_mercenary_purchase.gd | Unit | Purchase flow |
| test_campaign_ally_roster.gd | Unit | Roster APIs |
| test_mini_boss_defection.gd | Unit | Defection logic |
| test_simbot_mercenaries.gd | Unit | SimBot API |
| test_simbot_profiles.gd | Unit | Profile loading |
| test_simbot_handlers.gd | Unit | Handler state |
| test_simbot_logging.gd | Unit | CSV output |
| test_simbot_safety.gd | Unit | Reference scan |
| test_dialogue_manager.gd | Unit | Condition eval |
| test_relationship_manager.gd | Unit | Affinity state |
| test_florence.gd | Unit | Meta state |
| test_weapon_structural.gd | Unit | Data validation |
| test_building_specials.gd | Unit | Data validation |
| test_settings_manager.gd | Unit | Config I/O |
| test_save_manager.gd | Unit | Serialization |
| test_game_manager.gd | Integration | Complex state + signals + await |
| test_ally_combat.gd | Integration | Scene instantiation + physics |
| test_simbot_basic_run.gd | Integration | Full run with game state |
| test_spell_manager.gd | Integration | Physics process ticks |
| test_wave_manager.gd | Integration | Scene spawning + timers |
| test_hex_grid.gd | Integration | Scene + slot instances |
| test_building_base.gd | Integration | Scene + combat loop |
| test_projectile_system.gd | Integration | Scene + physics |
| test_arnulf_state_machine.gd | Integration | Scene + state machine |
| test_ally_base.gd | Integration | Scene + combat |
| test_ally_signals.gd | Integration | Scene + signal emission |
| test_ally_spawning.gd | Integration | Scene tree manipulation |
| test_boss_base.gd | Integration | Scene + combat |
| test_boss_waves.gd | Integration | Scene + spawning |
| test_final_boss_day.gd | Integration | Complex flow |
| test_boss_day_flow.gd | Integration | Complex flow |
| test_campaign_autoload_and_day_flow.gd | Integration | Autoload order check |
| test_enemy_pathfinding.gd | Integration | Scene + navigation |
| test_enemy_dot_system.gd | Integration | Scene + DoT effects |
| test_simulation_api.gd | Integration | Full API exercise |
| test_character_hub.gd | Integration | UI scene instances |
| test_tower_enchantments.gd | Integration | Scene + combat |
| test_weapon_upgrade_manager.gd | Integration | Manager + data |
| test_world_map_ui.gd | Integration | UI scene instances |
| test_simbot_determinism.gd | Integration | Full game run |

### Orphan Node Fixes (17 orphans in full suite)
- **Priority:** Medium. Orphans are leaked nodes from tests that don't `queue_free()` all scene instances in `after_test()`.
- **Suggested fix:** For each Integration test that instantiates scenes, add `queue_free()` calls in `after_test()` for all tracked scene references. Common culprits: `test_wave_manager.gd`, `test_hex_grid.gd`, `test_projectile_system.gd`, `test_building_base.gd`, `test_ally_base.gd`, `test_enemy_pathfinding.gd`.

### Coverage Gap Specifications

| System | Gap | Spec | Type |
|--------|-----|------|------|
| RelationshipManager | Tier boundary edge cases | Test affinity at exact tier thresholds (e.g. -100, -50, 0, 50, 100) and verify `get_tier()` returns correct tier name | Unit |
| RelationshipManager | Multi-event accumulation | Fire 3+ different SignalBus signals that affect the same character; verify cumulative affinity | Unit |
| SaveManager | Slot shifting | Save 5 times and verify oldest slot is rotated out; load each slot and confirm data integrity | Unit |
| SaveManager | Attempt isolation | Save in attempt_1, start new attempt, verify attempt_2 directory exists independently | Unit |
| SaveManager | Cross-autoload restore order | Save full game state, restore, verify CampaignManager→GameManager→RelationshipManager order does not corrupt state | Integration |
| SettingsManager | Keybind remap persistence | Remap `fire_primary` to a different key, save, reload, verify InputMap matches | Unit |
| SettingsManager | Graphics quality application | Call `set_graphics_quality("low")`, verify it persists in config file (rendering API wiring is POST-MVP) | Unit |
| Endless mode | Wave scaling past day 50 | Start endless mode, simulate 60+ waves, verify HP/damage multipliers continue scaling without overflow | Unit |
| Endless mode | Hub dialogue suppression | In endless mode, verify DialogueManager does not fire hub dialogue or that UIManager suppresses it | Integration |
| Consumables | Stacking edge cases | Apply mana_draught twice in same mission, verify second is no-op or correctly stacks | Unit |
| Consumables | Empty effect_tags | Create ShopItemData with empty effect_tags, purchase, verify no crash | Unit |
| AllyBase combat | DOWNED/RECOVERING under concurrent damage | Two enemies attack ally simultaneously during recovery timer; verify no double-downed state | Integration |
| SimBot difficulty | Multi-run convergence | Run 10+ batches with same profile, verify `compute_difficulty_fit()` converges toward target | Integration |

---

## 2. MCP & RAG Pipeline

### Tool Statuses

| Tool | Server | Status | Notes |
|------|--------|--------|-------|
| get_scene_tree | gdai-mcp-godot | Working | Returns full scene hierarchy accurately |
| get_godot_errors | gdai-mcp-godot | Working | Returns error/log output correctly |
| get_scene_file_content | gdai-mcp-godot | Working | Returns raw .tscn content |
| get_project_info | gdai-mcp-godot | Working | Project metadata |
| view_script | gdai-mcp-godot | Working | Script content viewer |
| sequential-thinking | sequential-thinking | Available | Single tool: sequentialthinking |
| godot-mcp-pro | godot-mcp-pro | Available | 163+ tools for editor integration |
| query_project_knowledge | foulward-rag | **NOT AVAILABLE** | Server not configured in `.cursor/mcp.json` |
| get_recent_simbot_summary | foulward-rag | **NOT AVAILABLE** | Server not configured |

### Accuracy Issues

| Query | Expected | Status | Diagnosis |
|-------|----------|--------|-----------|
| RAG: EconomyManager.spend_gold | Bool return, SignalBus.resource_changed | **NO_ANSWER** | foulward-rag server not configured; fix: add RAG MCP server to `.cursor/mcp.json` |
| RAG: FIRE damage vs UNDEAD | 2.0 | **NO_ANSWER** | Same — RAG unavailable |
| RAG: RelationshipManager tier lookup | threshold from .tres | **NO_ANSWER** | Same |
| RAG: SaveManager slots | 5-slot rolling | **NO_ANSWER** | Same |
| RAG: Mana draught effect_tags | ["mana_restore"] | **NO_ANSWER** | Same |
| RAG: SimBot summary | Run data | **NO_ANSWER** | Same |

### Concrete Fixes

1. **[Critical]** Configure foulward-rag MCP server in `.cursor/mcp.json` with `query_project_knowledge` and `get_recent_simbot_summary` tools. This requires the RAG pipeline from Prompt 18 (`~/LLM`) to be running.
2. **[Medium]** Document in AGENTS.md that RAG requires a running service and is not available by default — sessions must check for its availability before relying on it.

---

## 3. Code Quality

| File | Issue Type | Line(s) | Description | Severity | Suggested Fix |
|------|-----------|---------|-------------|----------|---------------|
| `scripts/wave_manager.gd` | Long function | 469–551 | `_spawn_wave` is 82 lines | Medium | Extract roster spawn loop (509–542) to `_spawn_enemies_for_roster(roster, wave_number, total)` |
| `scripts/sim_bot.gd` | Long function | 706–775 | `_choose_build_or_upgrade_action` is 69 lines | Low | Extract build-priority scan (722–753) to `_collect_weighted_build_entries()` |
| `scripts/input_manager.gd` | Long function | 37–100 | `_unhandled_input` is 63 lines | Medium | Extract `_handle_mouse_combat(mb)`, `_handle_spell_keybinds(event)`, `_handle_build_mode_keys()` |
| `scripts/input_manager.gd` | Bare get_node | 18–22 | Five `get_node("/root/Main/...")` without null guards | High | Replace with `get_node_or_null(...)` + null check before use |
| `ui/ui_manager.gd` | Bare get_node | 13–20 | Six `get_node("/root/Main/UI/...")` | High | Replace with `get_node_or_null(...)` + null check |
| `ui/build_menu.gd` | Bare get_node | 27 | `get_node("/root/Main/HexGrid")` | High | `get_node_or_null(...)` + guard |
| `ui/hud.gd` | Bare get_node | 26 | `get_node("/root/Main/Tower")` | Medium | `get_node_or_null(...)` — already has `is_instance_valid` elsewhere |
| `ui/ui_manager.gd` | Signal bypass | 57 | `DialogueManager.dialogue_line_finished.connect()` bypasses SignalBus | Medium | Add `dialogue_line_finished` to `signal_bus.gd`; emit from DialogueManager; connect UIManager via SignalBus |
| `autoloads/economy_manager.gd` | assert() in production | 39,45,56,62,73,79 | `assert(amount > 0)` in all economy mutators | High | Replace with `if amount <= 0: push_warning("..."); return false` |
| `autoloads/game_manager.gd` | assert() in production | 153,164–167 | `assert()` in `start_wave_countdown`, `enter_build_mode` | High | Replace with `if condition: push_warning("..."); return` |
| `scripts/wave_manager.gd` | assert() in production | 126–129,163–177,470–504 | Multiple asserts in spawn/countdown logic | High | Replace with `push_warning()` + early return |
| `scripts/shop_manager.gd` | assert() in production | 109,113–114 | assert in purchase flow | High | `push_warning()` + `return false` |
| `scripts/research_manager.gd` | assert() in production | 68 | assert in unlock flow | Medium | `push_warning()` + `return false` |
| `scenes/hex_grid/hex_grid.gd` | assert() in production | 82–84,190,192,280,282,292,357,402 | Multiple asserts in slot operations | High | `push_warning()` + early return pattern |
| `scenes/enemies/enemy_base.gd` | assert() in production | 50 | assert in initialize | Medium | `push_error()` + `return` |
| `scenes/bosses/boss_base.gd` | assert() in production | 12 | assert in init | Medium | `push_error()` + `return` |
| `autoloads/campaign_manager.gd` | Long function | 343–410 | `auto_select_best_allies` is 59 lines | Low | Extract sort + greedy fill into helpers |
| `autoloads/campaign_manager.gd` | assert() in production | 561,565–568 | assert in `validate_day_configs` | Medium | `push_warning()` + return |
| `autoloads/campaign_manager.gd` | Long function | 686–738 | `restore_from_save` is 52 lines | Low | Per-domain `_apply_*_from_dict()` helpers |
| `scenes/enemies/enemy_base.gd` | Long function | 230–285 | `_update_status_effects` is 55 lines | Low | One helper per effect: `_tick_slow()`, `_tick_dot()`, `_cleanup_expired()` |
| `scenes/tower/tower.gd` | Long function | 371–419 | `_apply_auto_aim` is 48 lines | Low | Extract cone search to `_find_assist_target(...)` |
| `scenes/hex_grid/hex_grid.gd` | Long function | 150–212 | `_try_place_building` is 58 lines | Low | Split validation vs instantiation |

---

## 4. Resource Files

| File | Issue | Classification | Fix |
|------|-------|---------------|-----|
| `resources/campaign_main_50days.tres` | All 50 DayConfig sub-resources have `faction_id = ""` | PLACEHOLDER_ACCEPTABLE | Set faction_id to `"DEFAULT_MIXED"` for days 1–10, appropriate faction IDs for later days when faction design is finalized |
| `resources/bossdata_final_boss.tres` | `associated_territory_id = ""`, `threat_icon_id = ""` | PLACEHOLDER_ACCEPTABLE | Set `associated_territory_id` when final boss territory is designed |
| `resources/bossdata_plague_cult_miniboss.tres` | `associated_territory_id = ""`, `threat_icon_id = ""` | PLACEHOLDER_ACCEPTABLE | Same |
| `resources/building_data/archer_barracks.tres` | `upgrade_gold_cost = 0` | PLACEHOLDER_ACCEPTABLE | Set to non-zero when Archer Barracks upgrade behavior is implemented (POST-MVP) |
| `resources/building_data/shield_generator.tres` | `upgrade_gold_cost = 0` | PLACEHOLDER_ACCEPTABLE | Same |
| `resources/building_data/*.tres` | Various `research_damage_boost_id = ""`, `research_range_boost_id = ""` | PLACEHOLDER_ACCEPTABLE | Populate when research boost system is implemented |
| `resources/building_data/*.tres` | `unlock_research_id = ""` for unlocked buildings | INTENTIONAL | Buildings without research gates intentionally have empty unlock IDs |
| `resources/character_data/*.tres` | All `icon_id = ""` | PLACEHOLDER_ACCEPTABLE | Populate when icon pipeline is complete |
| `resources/dialogue/**/*.tres` | Many `chain_next_id = ""` | INTENTIONAL | Non-chained dialogue entries intentionally have empty chain IDs |
| `resources/spell_data/slow_field.tres` | `damage = 0.0` | INTENTIONAL | Control spell with no direct damage |
| `resources/strategyprofiles/*.tres` | All `difficulty_target = 0.0` | PLACEHOLDER_ACCEPTABLE | Tuning deferred; value is in valid range [0.0, 1.0] |

**BUG count: 0** — All flagged resource issues are either PLACEHOLDER_ACCEPTABLE or INTENTIONAL.

---

## 5. Documentation & Files

### Unindexed Files (55 total from pre-pass)
All 55 files from `docs/PROMPT_26_PRE_INDEX_DIFF.txt` are legitimate files that need INDEX_SHORT.md entries. Key categories:
- **6 scripts:** `character_base_2d.gd`, `florence_data.gd`, `strategyprofileconfig.gd`, `test_strategyprofileconfig.gd`, `simbot_logger.gd`, `weapon_upgrade_manager.gd`
- **1 UI script:** `dialogue_ui.gd`
- **48 test files:** All test files listed in pre-pass

**Fix applied in Phase 7:** INDEX_SHORT.md updated to include all 55 files.

### Missing Files (0)
No files listed in INDEX_SHORT.md are missing from disk.

### Orphaned/Redundant Files

| File | Classification | Reason |
|------|---------------|--------|
| `scripts/resources/strategyprofileconfig.gd` | KEEP | Active resource class for SimBot config |
| `scripts/resources/test_strategyprofileconfig.gd` | KEEP | Test helper resource |
| `scripts/simbot_logger.gd` | KEEP | SimBot CSV logging utility |
| `ui/dialogue_ui.gd` / `ui/dialogueui.tscn` | MERGE | Legacy dialogue panel; code references exist in INDEX_SHORT.md noting "kept for reference"; consider removing when DialoguePanel is fully adopted |
| `scenes/hub/character_base_2d.gd` | KEEP | Active scene script for hub characters |

### Open TODOs from Prior Prompts

| Source | TODO | Status |
|--------|------|--------|
| P1 | Sell UX wiring | COMPLETED (P1 + subsequent) |
| P10 | Full test suite not run | COMPLETED (P26-PRE: 525 pass) |
| P13 | Placeholder dialogue text | OPEN — all DialogueEntry .tres still have `"TODO: placeholder dialogue line."` |
| P15 | Florence meta-state integration | PARTIALLY OPEN — flags exist but most dialogue conditions using them are stubs |
| P16 | Full test suite not run during session | COMPLETED (P26-PRE) |
| P19 | TODO(ART) annotations for GLB swap | OPEN — 12 files have `# TODO(ART)` markers awaiting production 3D assets |

---

## 6. Post-MVP Stubs

### Signals Never Emitted

| Signal | Classification | Spec |
|--------|---------------|------|
| `enemy_reached_tower` | BLOCKED | Requires EnemyBase attack refactor to emit on tower contact instead of direct `take_damage()` call |
| `ally_state_changed` | READY | Emit from `AllyBase._transition_state()` with `(ally_id, state_name)` when detailed ally tracking is needed |
| `wave_failed` | OBSOLETE | No game mechanic uses "wave failed" — waves either clear or tower falls. Remove or repurpose. |
| `wave_completed` | OBSOLETE | Duplicate of `wave_cleared`. Remove. |
| `building_destroyed` | BLOCKED | Requires building HP damage system (POST-MVP). Currently buildings are indestructible. |

### Functions with `pass` Body Only

| File | Function | Classification | Spec |
|------|----------|---------------|------|
| `dialogue_manager.gd` | `_on_resource_changed` | READY | Track resource changes for dialogue conditions like "gold_amount > 500". Impl: update internal `_current_gold` from EconomyManager and re-evaluate pending conditions. |
| `dialogue_manager.gd` | `_on_research_unlocked` | READY | Set internal flag for `research_unlocked_<id>` condition key. Impl: add `node_id` to `_unlocked_research_ids` set. |
| `dialogue_manager.gd` | `_on_shop_item_purchased` | READY | Track purchases for dialogue conditions. Impl: increment `_purchase_count` counter. |
| `dialogue_manager.gd` | `_on_arnulf_state_changed` | READY | Track Arnulf state for dialogue conditions like "arnulf_is_downed". Impl: store `_arnulf_current_state`. |
| `dialogue_manager.gd` | `_on_spell_cast` | READY | Track spell casts for conditions. Impl: increment `_spell_cast_count` and set `_last_spell_cast_id`. |
| `wave_manager.gd` | `_on_game_state_changed` | READY | React to state changes (e.g., pause wave countdown in BUILD_MODE). Impl: pause/resume countdown timer based on state. |

### Orphaned Enum Values

| Enum | Value | Classification |
|------|-------|---------------|
| `Types.AllyRole.TANK` | Only in types.gd, never used | OBSOLETE — remove or implement tank role in AllyBase targeting |

### Specific System Audits

| System | Finding | Status |
|--------|---------|--------|
| `SettingsManager.set_graphics_quality()` | Stores string in config, not wired to Godot rendering APIs | READY — add `RenderingServer` calls for shadow quality, MSAA, etc. based on quality string |
| `SimBot._on_wave_cleared()` difficulty exit | `compute_difficulty_fit()` returns 0.0 when batch log is empty; `is_equal_approx(..., 1.0)` is never true | BLOCKED — effectively unreachable in interactive SimBot flow; only meaningful after prior batch data |
| `SaveManager` save/load pipeline | Works via `_build_save_payload()` / `_apply_save_payload()` calling per-autoload `get_save_data()` / `restore_from_save()` | READY — missing `RelationshipManager` in save/load calls; add `RelationshipManager.get_save_data()` and `restore_from_save()` to the pipeline |
| Art icon PNGs | `res://art/icons/` directories exist but contain no actual PNG files | BLOCKED — requires `tools/generate_placeholder_icons.gd` to be run via Project menu or script |

---

## 7. Direct Fixes Applied

| Fix | File(s) | Description |
|-----|---------|-------------|
| 7a | `docs/INDEX_SHORT.md` | Added 55 unindexed files to the test files section |
| 7e | `tools/run_gdunit_visible.sh` | Verified exists and is correct (created by Sonnet pre-pass) |
| 7f | `docs/AGENTS.md` | Created authoritative standing orders document |
| Log | `docs/PROMPT_26_IMPLEMENTATION.md` | Session log with all audit findings |

---

## Appendix A: Orphaned / Redundant Files (DELETE / MERGE / KEEP)

| File | Decision | Reason |
|------|----------|--------|
| `ui/dialogueui.gd` + `ui/dialogueui.tscn` | MERGE/DELETE | Legacy placeholder; `DialoguePanel` is the active replacement. Remove after confirming no runtime references remain. |
| `scripts/resources/test_strategyprofileconfig.gd` | KEEP | Test helper resource class used by SimBot test suites |
| `scripts/resources/strategyprofileconfig.gd` | KEEP | Active resource wrapper for strategy profile loading |
| `scripts/simbot_logger.gd` | KEEP | SimBot CSV logging utility actively used by `sim_bot.gd` |
| `AUDIT_IMPLEMENTATION_AUDIT_6.md` | DELETE | Content merged into `docs/ALL_AUDITS.md` — root-level copy is redundant |
| `AUDIT_IMPLEMENTATION_UPDATE.md` | DELETE | Superseded by `docs/ALL_AUDITS.md` |
| `AUDIT_IMPLEMENTATION_TASK.md` | DELETE | Superseded by this file |
| `FUTURE_3D_MODELS_PLAN.md` | KEEP | Active production art roadmap referenced in INDEX_SHORT.md |

## Appendix B: Every TODO/FIXME/HACK (file, line, text, recommendation)

Full scan: 84 items found. See `docs/PROMPT_26_PRE_TODO_LIST.txt` for complete listing.

Key categories:
- **POST-MVP markers (68):** Deferred features with clear labels. No action needed until feature development.
- **TODO(ART) markers (7):** Awaiting production 3D assets. Blocked on art pipeline.
- **TODO: description / TODO: placeholder (9):** Placeholder text in CharacterData and DialogueEntry .tres files. Replace with final content during narrative pass.

## Appendix C: Test Coverage Gap Specifications (with Unit/Integration classification)

See Section 1 "Coverage Gap Specifications" table above.

## Appendix D: Audit 5 & 6 System Health

| System | From Audit | Status | Notes |
|--------|-----------|--------|-------|
| Multi-spell registry (A6) | SpellManager | Implemented | 4 spells: shockwave, slow_field, arcane_beam, tower_shield |
| Structural weapon upgrades (A6) | WeaponLevelData | Implemented | Data fields exist; behavioral effects (pierce, splash) are POST-MVP stubs |
| Archer Barracks special (A6) | BuildingBase | Stub | `fire_rate = 0`, `damage = 0` — no actual spawn behavior |
| Shield Generator special (A6) | BuildingBase | Stub | `fire_rate = 0`, `damage = 0` — no actual shield behavior |
| Territory aggregate bonuses (A6) | GameManager | Implemented | `get_current_territory_gold_modifiers()` aggregates flat + percent bonuses |
| DOWNED/RECOVERING allies (A5) | AllyBase | Implemented | `uses_downed_recovering` flag controls behavior; no .tres currently enables it |
| Save/Load (A6) | SaveManager | Implemented | Rolling autosave with slot management; missing RelationshipManager in pipeline |
| Relationship system (A5→P22) | RelationshipManager | Implemented | Affinity + tiers; dialogue conditions work |
| Settings persistence (A6→P24) | SettingsManager | Implemented | Audio works; graphics quality stores string only |

## Appendix E: Parallel Test Runner Implementation Spec

### `tools/run_gdunit_parallel.sh`

**Purpose:** Run integration tests across 8 parallel headless Godot processes to reduce wall-clock time from ~4m22s to <45s.

**Algorithm:**
1. Collect all test files from `res://tests/` into an array
2. Split into 8 groups by file count (round-robin assignment)
3. For each group, launch a headless Godot process:
   ```bash
   "$godot_bin" --headless --path "$repo_root" \
     -s "$repo_root/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
     --ignoreHeadlessMode \
     -a "res://tests/file1.gd" -a "res://tests/file2.gd" ...
   ```
4. Store each process PID
5. `wait` for all 8 PIDs
6. Merge exit codes: if any process exits non-zero (and not 101), the script exits non-zero
7. Print combined summary: total cases, total failures, wall-clock time

**Key considerations:**
- GdUnit4 writes XML reports to `reports/report_*/` — each parallel process gets a unique report directory (set via environment or temp dir)
- Autoloads are shared within a Godot process but isolated between processes — no state leakage
- Test files that modify global autoload state (EconomyManager, GameManager, etc.) must reset in `before_test()` — this is already the convention
- The parallel runner should be the default for CI after implementation

**Estimated implementation effort:** 2-3 hours for a future Cursor session.


---

# Part 2 — Agent Standing Orders (`docs/AGENTS.md`)

# FOUL WARD — Agent Standing Orders
Last updated: 2026-03-28 by Opus 4.6 (Prompt 26)

Read this file FIRST in every Cursor session, before opening any other file.

## 1. Orientation (do at the start of every session)
- Read: `docs/INDEX_SHORT.md`, `docs/CONVENTIONS.md`
- If task involves tests: read `tools/run_gdunit.sh` and the relevant test files
- If task involves resources: check `docs/PROMPT_26_PRE_RESOURCE_SCAN.txt` for known placeholder fields
- If task involves scene nodes: use Godot MCP `get_scene_tree` to read the scene tree — never assume node paths
- If task involves autoloads: check `project.godot` registration order before assuming load order
- If task involves balance or economy: read `IMPROVEMENTS_TO_BE_DONE.md` Section 6 for stub status

## 2. MCP Tool Rules (non-negotiable)
- ALWAYS use Godot MCP `get_scene_tree` to validate scene tree paths before writing any `get_node()` call
- ALWAYS use Godot MCP `get_godot_errors` after making changes to check for new errors
- If RAG is available (`query_project_knowledge`), call it before writing new code for an existing system
- If RAG is available (`get_recent_simbot_summary`), call it when your task touches balance, economy, or wave scaling
- If any MCP tool fails to respond: note it in your implementation log and continue
- RAG (`foulward-rag`) is NOT always available — it requires a running service from `~/LLM` (Prompt 18). Check for it but do not block on it.

## 3. File Change Rules (non-negotiable)
- EVERY new .gd file must be added to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- EVERY deleted or renamed file must be removed/updated in both index files
- EVERY session must log to `docs/PROMPT_[N]_IMPLEMENTATION.md` (use the next unused N)
- EVERY new autoload must be registered in `project.godot` in the correct load order:
  1. SignalBus (no dependencies)
  2. DamageCalculator (no dependencies)
  3. EconomyManager (depends on SignalBus)
  4. CampaignManager (depends on SignalBus — must load BEFORE GameManager)
  5. RelationshipManager (depends on SignalBus, after CampaignManager)
  6. SettingsManager (depends on SignalBus, after RelationshipManager)
  7. GameManager (depends on SignalBus, EconomyManager, CampaignManager)
  8. SaveManager (depends on CampaignManager, GameManager, EnchantmentManager)
  9. DialogueManager (depends on SignalBus, GameManager, ResearchManager)
  10. AutoTestDriver (depends on GameManager)
  11. EnchantmentManager (depends on SignalBus)
- EVERY new signal must be declared in `autoloads/signal_bus.gd`, named in past tense snake_case
- EVERY new .tres resource file must be referenced by at least one .gd file or other .tres

## 4. Test Rules (non-negotiable)
- Run `./tools/run_gdunit_quick.sh` after EVERY change. Fix failures before continuing.
- Run `./tools/run_gdunit.sh` before declaring any task complete.
- All new tests go in `res://tests/` as GdUnit4 suites
- All tests must be headless-safe: no UI nodes, no editor APIs, no `@tool`
- Tests that use `await` or timers are Integration tests — keep them out of `run_gdunit_unit.sh` (when implemented)
- New test files must be added to the allowlist in `run_gdunit_quick.sh` if they are lightweight
- GdUnit exit code 101 means warnings only (typically orphan nodes) — treat as pass when failure count is 0
- GdUnit exit code 100 with "0 failures" in the log means GodotGdErrorMonitor counted `push_warning` calls — treat as pass

## 5. Code Conventions (enforced)
1. **Static typing everywhere**: all function parameters, return types, and variable declarations must have explicit types
2. **Signals through SignalBus**: all cross-system events go through `SignalBus` — no direct `.connect()` between unrelated nodes
3. **Autoload access by name**: `EconomyManager.add_gold(50)`, never `var econ = EconomyManager`
4. **No magic numbers**: all gameplay tuning lives in `.tres` resource files or named constants in `types.gd`
5. **`get_node_or_null()` for runtime lookups**: never bare `get_node()` for paths that might not exist in headless/test contexts
6. **`is_instance_valid()` before accessing freed nodes**: enemies, projectiles, and allies can be freed mid-frame
7. **`push_warning()` not `assert()` in production**: `assert()` crashes headless builds; use `push_warning()` + early return
8. **snake_case signals, past tense for events**: `enemy_killed`, `wave_cleared`, `building_placed`
9. **`_physics_process` for game logic**: `_process` is for visual/UI only
10. **Scene instantiation via `initialize()`**: never set properties after `add_child()`; call `initialize()` before or immediately after

## 6. Architecture Rules (enforced)
- ALL cross-system events go through SignalBus — no direct method calls between autoloads for events
- ALL node path lookups use `get_node_or_null()` with a null guard — never bare `get_node()`
- ALL scene node access is gated: `if not is_instance_valid(node): return`
- Autoload singletons are accessed by name (`CampaignManager.x`), never cached in `var _cm = CampaignManager`
- `SaveManager.save_current_state()` is called automatically on `mission_won` and `mission_failed` — do not add extra save calls
- RelationshipManager events are driven by `RelationshipEventData` .tres resources — do not hardcode deltas in .gd files
- Manager node paths are contracted (see ARCHITECTURE.md §2 "Manager node path contracts"):
  - `/root/Main/Managers/WaveManager`
  - `/root/Main/Managers/ResearchManager`
  - `/root/Main/Managers/WeaponUpgradeManager`
  - `/root/Main/Managers/ShopManager`
  - `/root/Main/Managers/SpellManager`
  - `/root/Main/Managers/InputManager`

## 7. Prohibited Actions (never do these)
- Never add UI node references to SimBot, autoloads, or headless-capable scripts
- Never call DialogueManager or FlorenceManager inside `if CampaignManager.is_endless_mode`
- Never change the autoload registration order in `project.godot` without reading this document first
- Never use `assert()` in production code — use `push_warning()` or `push_error()`
- Never write a `get_save_data()` or `restore_from_save()` method without also wiring it into SaveManager's `_build_save_payload()` / `_apply_save_payload()`
- Never emit a SignalBus signal from a test using the real autoload without resetting state in `after_test()`
- Never add a `class_name` to `SaveManager` or `RelationshipManager` — they are autoload-only singletons (avoids GdUnit shadowing)
- Never `print()` to stdout in MCP bridge scripts (GDAI) — only JSON-RPC may use stdout; debug logs go to stderr

## 8. Before Declaring a Task Complete
- [ ] All new/modified files are in `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- [ ] `docs/PROMPT_[N]_IMPLEMENTATION.md` exists and lists all files created/modified
- [ ] `./tools/run_gdunit.sh` (or parallel equivalent) passes with 0 failures
- [ ] Godot MCP `get_godot_errors` shows no new errors introduced by this session
- [ ] Any new .tres resources have all required fields populated (no empty IDs, no zero costs where non-zero is required)
- [ ] AGENTS.md updated if any new standing order was established this session

## 9. Known Gotchas
1. **AllyData is a Resource** — do not call `.get(key, default)` with two arguments; use typed field access instead (e.g., `ally_data.ally_id`, not `ally_data.get("ally_id", "")`)
2. **`run_gdunit_quick.sh` exits 101 for orphan/warning noise** — treat as pass when failure count is 0. The script already handles this.
3. **SaveManager has no `class_name`** — this is intentional to avoid shadowing the autoload singleton in GdUnit tests. Same for RelationshipManager. Do not add `class_name` to either.
4. **CampaignManager MUST load before GameManager in `project.godot`** — `mission_won` signal listeners run in autoload registration order; CampaignManager's day increment must fire before GameManager's hub transition.
5. **EnchantmentManager loads AFTER GameManager in `project.godot`** — `GameManager.start_new_game()` calls `EnchantmentManager.reset_enchantments()`; this works because both are in the tree by `_ready()` time, but registration order means EnchantmentManager's `_ready()` runs after GameManager's.
6. **WaveManager is a scene node, not an autoload** — it lives at `/root/Main/Managers/WaveManager`. GameManager resolves it via `get_node_or_null()` and silently skips wave spawning if absent (allows headless testing without `main.tscn`).
7. **`DialogueManager.dialogue_line_finished` bypasses SignalBus** — UIManager connects directly to this signal on the DialogueManager autoload. This is a known convention violation; future work should add this signal to SignalBus.
8. **GdUnit exit code 100 vs 101** — 100 means GodotGdErrorMonitor counted errors (often from expected `push_warning()` calls); 101 means orphan nodes detected. Both are treated as pass by `run_gdunit_quick.sh` when the log shows 0 test failures.
9. **`slow_field.tres` has `damage = 0.0`** — this is intentional (control spell). Do not "fix" it.
10. **`SettingsManager.set_graphics_quality()` stores a string but does not call RenderingServer** — graphics quality is persistence-only in MVP; actual rendering API calls are POST-MVP.
11. **50-day campaign DayConfigs all have empty `faction_id`** — this is placeholder; WaveManager falls back to `DEFAULT_MIXED` faction when `faction_id` is empty.
12. **SimBot's `compute_difficulty_fit()` difficulty-based early exit is effectively unreachable** — it requires prior batch log data that is empty during interactive `activate()` runs. Mission completion still ends runs via `all_waves_cleared`.


---

# Part 3 — Prompt 26 Implementation Log (`docs/PROMPT_26_IMPLEMENTATION.md`)

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


---

# Part 4 — INDEX_SHORT (`docs/INDEX_SHORT.md`)

INDEX_SHORT.md
==============

FOUL WARD — INDEX_SHORT.md

Compact repository reference. One-liner per file. **Doc layout:** `docs/README.md`. **Consolidated snapshot (Prompt 26+):** `docs/OPUS_ALL_ACTIONS.md` — single file merging improvement backlog, AGENTS standing orders, PROMPT_26 log, INDEX_SHORT, INDEX_FULL (regenerate after editing sources). Updated: 2026-03-28 (**Prompt 26:** Full project audit — 55 unindexed files added, AGENTS.md standing orders, IMPROVEMENTS_TO_BE_DONE.md backlog, test classification — `docs/PROMPT_26_IMPLEMENTATION.md`). **Prompt 24:** programmatic PNG icons (`tools/generate_placeholder_icons.gd`, `addons/fw_placeholder_icons`), `ArtPlaceholderHelper` icon textures, `SettingsManager` + `scenes/ui/settings_screen`, UI wiring — `docs/PROMPT_24_IMPLEMENTATION.md`. **Prompt 23:** Endless Run — `Types.GameState.ENDLESS`, `CampaignManager.is_endless_mode` / `start_endless_run`, synthetic day scaling, main menu — `docs/PROMPT_23_IMPLEMENTATION.md`. **Prompt 22:** relationship tiers + affinity autoload, dialogue `relationship_tier` conditions — `docs/PROMPT_22_IMPLEMENTATION.md`. Prompt 19: Blender batch GLBs under `res://art/generated/**`, `generation_log.json`, `FUTURE_3D_MODELS_PLAN.md`, `# TODO(ART)` in combat/hub scenes; see `docs/PROMPT_19_IMPLEMENTATION.md`. **Prompt 18:** local RAG + MCP pipeline under `~/LLM` — `docs/PROMPT_18_IMPLEMENTATION.md`. **Audit 6:** `AUDIT_IMPLEMENTATION_AUDIT_6.md` (multi-spell, structural weapon upgrades, barracks/shield specials, territory aggregates). **Prompt 20:** `docs/obsolete/` archive + INDEX autoload alignment; `docs/PROMPT_20_IMPLEMENTATION.md`.
Source of truth: REPO_DUMP_AFTER_MVP.md; **re-run** `./tools/run_gdunit.sh` after Prompt 12/13 (use `./tools/run_gdunit_quick.sh` for iteration). **Handoff:** `docs/PROBLEM_REPORT.md` lists files and log snippets for GdUnit / `mission_won` / `push_warning` work.
AUTOLOADS (registered in project.godot, in init order)
Autoload Name	Path	What it does
SignalBus	res://autoloads/signal_bus.gd	Central hub for ALL cross-system typed signals. Prompt 10: boss_spawned, boss_killed, campaign_boss_attempted. Prompt 11: ally_spawned, ally_downed, ally_recovered, ally_killed, ally_state_changed (POST-MVP). Prompt 12: mercenary_offer_generated, mercenary_recruited, ally_roster_changed. No logic, no state.
DamageCalculator	res://autoloads/damage_calculator.gd	Stateless 4×4 damage-type × armor-type matrix. Pure function singleton.
EconomyManager	res://autoloads/economy_manager.gd	Owns gold, building_material, research_material. Emits resource_changed.
CampaignManager	res://autoloads/campaign_manager.gd	Day/campaign progress; faction_registry + validate_day_configs; **owned_allies / active_allies_for_next_day**, mercenary catalog + offers, purchase + defection + `auto_select_best_allies` (Prompt 12); **current_ally_roster** sync for spawn (Prompt 11). **Init order:** must load **before** GameManager in `project.godot` so `SignalBus.mission_won` runs `_on_mission_won` (day increment) before GameManager hub transition.
RelationshipManager	res://autoloads/relationship_manager.gd	Prompt 22: affinity −100..100 per `character_id`, tiers from `relationship_tier_config.tres`; loads `character_relationship/*.tres` + `relationship_events/*.tres`, applies deltas on SignalBus; `get_tier` / `get_save_data` / `restore_from_save`. **Init order:** after CampaignManager, before GameManager.
SettingsManager	res://autoloads/settings_manager.gd	Prompt 24: `user://settings.cfg` — master/music/SFX linear volumes, graphics quality string, keybind mirror; `AudioServer` Music+SFX buses; `load_settings`/`save_settings`/`set_volume`/`remap_action`. **Init order:** after RelationshipManager, before GameManager.
GameManager	res://autoloads/game_manager.gd	Owns game state, mission index, wave index, territory map runtime; mission rewards + territory bonuses. Prompt 10: final boss state, synthetic boss-attack days, held_territory_ids, prepare_next_campaign_day_if_needed / advance_to_next_day / get_day_config_for_index. Prompt 11: `_spawn_allies_for_current_mission` / `_cleanup_allies` (Main/AllyContainer, AllySpawnPoints). Prompt 12: `notify_mini_boss_defeated` → CampaignManager; `_transition_to` skips duplicate same-state transitions. `_begin_mission_wave_sequence`: Main→Managers→WaveManager via get_node_or_null; `push_warning` if absent (not `push_error` — GdUnit). Subscribes to `mission_won` for BETWEEN_MISSIONS / GAME_WON after CampaignManager (see `PROBLEM_REPORT.md`).
SaveManager	res://autoloads/save_manager.gd	Audit 6: rolling autosaves `user://saves/attempt_*/slot_*.json`; autoload singleton only (no `class_name`).
DialogueManager	res://autoloads/dialogue_manager.gd	Prompt 13: loads `DialogueEntry` `.tres` under `res://resources/dialogue/**`; priority, AND conditions, once-only, chain_next_id; signals `dialogue_line_started` / `dialogue_line_finished`; ResearchManager heuristics for `sybil_research_unlocked_any` (`spell` in node_id) and `arnulf_research_unlocked_any` (`arnulf` in node_id). See `docs/PROMPT_13_IMPLEMENTATION.md`.
AutoTestDriver	res://autoloads/auto_test_driver.gd	Headless smoke-test driver. Active only when --autotest flag is present.
GDAIMCPRuntime	(uid plugin autoload in project.godot)	GDAI MCP GDExtension bridge — editor HTTP API for MCP when `addons/gdai-mcp-plugin-godot` is enabled.
EnchantmentManager	res://autoloads/enchantment_manager.gd	Phase 4: per-weapon enchantment slots (elemental/power); Tower + BetweenMissionScreen integration.
SCRIPTS (attached to Manager nodes in main.tscn under /root/Main/Managers/)
Class Name	Path	What it does
Types	res://scripts/types.gd	All enums and shared constants. Prompt 11: `AllyClass` (MELEE/RANGED/SUPPORT); `TargetPriority` shared with allies (MVP: CLOSEST). Prompt 14: `HubRole` marks between-mission hub character categories. Not an autoload; referenced as Types.XXX.
HealthComponent	res://scripts/health_component.gd	Reusable HP tracker. Emits local signals health_depleted, health_changed.
WaveManager	res://scripts/wave_manager.gd	Spawns enemies per wave from FactionData-weighted roster (total N×6), countdown, wave signals. `_enemy_container` / `_spawn_points` via get_node_or_null(/root/Main/...); null-safe spawn. Prompt 10: boss_registry, ensure_boss_registry_loaded, set_day_context, boss wave on configured index + escorts.
SpellManager	res://scripts/spell_manager.gd	Owns mana pool, spell cooldowns. Multi-spell registry + `cast_selected_spell` / hotkeys (Audit 6); effects include shockwave, slow_field, arcane_beam, tower_shield.
ResearchManager	res://scripts/research_manager.gd	Tracks unlocked research nodes. Gates locked buildings.
ShopManager	res://scripts/shop_manager.gd	Processes shop purchases. Applies mission-start consumable effects.
InputManager	res://scripts/input_manager.gd	Translates mouse/keyboard input into public method calls on managers.
SimBot	res://scripts/sim_bot.gd (+ alias `res://scripts/simbot.gd`)	Headless automated simulation bot. Audit 4: `get_log()` → Dictionary; `run_single` / `run_batch` CSV under `user://simbot/logs/`. Prompt 16 Phase 2: `StrategyProfile` resources.
ArtPlaceholderHelper	res://scripts/art/art_placeholder_helper.gd	Stateless utility resolving placeholder meshes, materials, and icons from res://art based on Types enums and string IDs. Handles caching, fallbacks, and generated-asset priority.
PlaceholderIconGenerator	res://tools/generate_placeholder_icons.gd	Prompt 24: `class_name PlaceholderIconGenerator` — 64×64 PNG placeholders (editor Project menu or `run_generate_placeholder_icons.gd`).
fw_placeholder_icons	res://addons/fw_placeholder_icons/plugin.cfg	Prompt 24: EditorPlugin — Project → Generate Placeholder Icons.
tools/generate_placeholder_glbs_blender.py	res://tools/generate_placeholder_glbs_blender.py	Blender 4.x headless: Rigify/blockout GLBs → `res://art/generated/{enemies,allies,buildings,bosses,misc}/`; writes `art/generated/generation_log.json`. Requires system numpy for glTF exporter.
art/generated/generation_log.json	res://art/generated/generation_log.json	Batch export inventory (entity_id, paths, animation_count, has_rig); optional `godot_mcp.reload_project` metadata.
FUTURE_3D_MODELS_PLAN.md	res://FUTURE_3D_MODELS_PLAN.md	Production 3D + hub portrait roadmap; placeholder table; scene art audit appendix; PhysicalBone3D + AnimationPlayer wiring notes.
MainRoot	res://scripts/main_root.gd	Applies root window content scale at startup (stretch fix for Godot 4.4+).
SCENES (runtime instantiated or statically placed)
Class Name	Script Path	Scene Path	What it does
Tower	res://scenes/tower/tower.gd	res://scenes/tower/tower.tscn	Player's stationary avatar. Fires crossbow + rapid missile.
Arnulf	res://scenes/arnulf/arnulf.gd	res://scenes/arnulf/arnulf.tscn	AI melee companion. State machine: IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING. Prompt 11: emits generic `ally_*` with id `arnulf` + `ALLY_ID_ARNULF`.
AllyBase	res://scenes/allies/ally_base.gd	res://scenes/allies/ally_base.tscn	Prompt 11 + Audit 6: DOWNED/RECOVERING when `uses_downed_recovering`; `can_target_flying` / `preferred_targeting` (CLOSEST, LOWEST_HP, …); ally_spawned / ally_downed / ally_recovered / ally_killed.
HexGrid	res://scenes/hex_grid/hex_grid.gd	res://scenes/hex_grid/hex_grid.tscn	24-slot ring grid. Manages building placement, sell, upgrade.
BuildingBase	res://scenes/buildings/building_base.gd	res://scenes/buildings/building_base.tscn	Base class for all 8 building types. Auto-targets and fires.
EnemyBase	res://scenes/enemies/enemy_base.gd	res://scenes/enemies/enemy_base.tscn	Base class for all 6 enemy types. Nav, attack, die, reward.
BossBase	res://scenes/bosses/boss_base.gd	res://scenes/bosses/boss_base.tscn	Prompt 10: extends EnemyBase; initialize_boss_data(BossData); emits boss_spawned / boss_killed.
ProjectileBase	res://scenes/projectiles/projectile_base.gd	res://scenes/projectiles/projectile_base.tscn	Physics-driven projectile. Hits first valid enemy, self-destructs.
UI SCRIPTS & SCENES
Class Name	Script Path	Scene Path	What it does
UIManager	res://ui/ui_manager.gd	(Control node in main.tscn)	Lightweight state router + hub dialogue router. Shows/hides UI panels on game_state_changed and wires `Hub2DHub` + `DialoguePanel`. Prompt 14: `show_dialogue(display_name, entry)` + `clear_dialogue()`; still supports `show_dialogue_for_character` with queue.
Hub2DHub	res://ui/hub.gd	res://ui/hub.tscn	2D between-mission hub overlay. Instantiates clickable characters from `CharacterCatalog` and routes focus to `BetweenMissionScreen` + dialogue.
DialoguePanel	res://ui/dialogue_panel.gd	res://ui/dialogue_panel.tscn	Global click-to-continue dialogue overlay (SpeakerLabel + TextLabel). Chains via `DialogueEntry.chain_next_id`.
DialogueUI	res://ui/dialogueui.gd	res://ui/dialogueui.tscn	Legacy placeholder hub dialogue panel (Prompt 13). Kept for reference; hub now uses DialoguePanel.
HUD	res://ui/hud.gd	res://ui/hud.tscn	Combat overlay: resources, wave counter, HP bar, spells.
BuildMenu	res://ui/build_menu.gd	res://ui/build_menu.tscn	Radial building placement panel. Opens on hex slot click in BUILDMODE.
BetweenMissionScreen	res://ui/between_mission_screen.gd	res://ui/between_mission_screen.tscn	Post-mission tabs: World Map, Shop, Research, Buildings, Weapons, Mercenaries (Prompt 12). NEXT DAY. Prompt 13: on `BETWEEN_MISSIONS`, `_show_hub_dialogue()` → UIManager for SPELL_RESEARCHER then COMPANION_MELEE (queued).
WorldMap	res://ui/world_map.gd	res://ui/world_map.tscn	Territory list + details (read-only; GameManager state).
MainMenu	res://ui/main_menu.gd	res://ui/main_menu.tscn	Title screen. Start, Settings → `settings_screen.tscn` overlay, Quit.
SettingsScreen	res://scripts/ui/settings_screen.gd	res://scenes/ui/settings_screen.tscn	Prompt 24: audio sliders, graphics quality, keybind remap, Back.
MissionBriefing	res://ui/mission_briefing.gd	(Control node in main.tscn)	Shows mission number. BEGIN button → GameManager.start_wave_countdown.
EndScreen	res://ui/end_screen.gd	(Control node in main.tscn)	Final screen for win/lose. Restart and Quit buttons.
CUSTOM RESOURCE TYPES (script classes, not .tres files)
Class Name	Script Path	Fields summary
EnemyData	res://scripts/resources/enemy_data.gd	enemy_type, display_name, max_hp, move_speed, damage, attack_range, attack_cooldown, armor_type, gold_reward, is_ranged, is_flying, color, damage_immunities[]
BuildingData	res://scripts/resources/building_data.gd	building_type, display_name, gold_cost, material_cost, upgrade_gold_cost, upgrade_material_cost, damage, upgraded_damage, fire_rate, attack_range, upgraded_range, damage_type, targets_air, targets_ground, is_locked, unlock_research_id, color, dot_enabled, dot_total_damage, dot_tick_interval, dot_duration, dot_effect_type, dot_source_id, dot_in_addition_to_hit
WeaponData	res://scripts/resources/weapon_data.gd	weapon_slot, display_name, damage, projectile_speed, reload_time, burst_count, burst_interval, can_target_flying, assist_angle_degrees, assist_max_distance, base_miss_chance, max_miss_angle_degrees
SpellData	res://scripts/resources/spell_data.gd	spell_id, display_name, mana_cost, cooldown, damage, radius, damage_type, hits_flying
ResearchNodeData	res://scripts/resources/research_node_data.gd	node_id, display_name, research_cost, prerequisite_ids[], description
ShopItemData	res://scripts/resources/shop_item_data.gd	item_id, display_name, gold_cost, material_cost, description
TerritoryData	res://scripts/resources/territory_data.gd	territory_id, terrain_type, ownership, default_faction_id (POST-MVP), is_secured, has_boss_threat, bonus_flat_gold_end_of_day, bonus_percent_gold_end_of_day, POST-MVP bonus hooks
TerritoryMapData	res://scripts/resources/territory_map_data.gd	territories: Array[TerritoryData], get_territory_by_id, has_territory
FactionRosterEntry	res://scripts/resources/faction_roster_entry.gd	enemy_type, base_weight, min_wave_index, max_wave_index, tier
FactionData	res://scripts/resources/faction_data.gd	faction_id, display_name, description, roster[], mini_boss_ids (BossData.boss_id strings), mini_boss_wave_hints, roster_tier, difficulty_offset; get_entries_for_wave, get_effective_weight_for_wave; BUILTIN_FACTION_RESOURCE_PATHS
BossData	res://scripts/resources/boss_data.gd	boss_id, stats, escort_unit_ids, phase_count, is_mini_boss / is_final_boss, boss_scene; build_placeholder_enemy_data(); BUILTIN_BOSS_RESOURCE_PATHS
DayConfig	res://scripts/resources/day_config.gd	day_index, mission_index, territory_id, faction_id (default DEFAULT_MIXED), is_mini_boss_day, is_mini_boss (alias), is_final_boss, boss_id, is_boss_attack_day, display_name, wave/tuning multipliers
CampaignConfig	res://scripts/resources/campaign_config.gd	campaign_id, display_name, day_configs, starting_territory_ids, territory_map_resource_path, short-campaign flags
StrategyProfile	res://scripts/resources/strategyprofile.gd	profile_id, description, build_priorities, placement_preferences, spell_usage, upgrade_behavior, difficulty_target
AllyData	res://scripts/resources/ally_data.gd	Prompt 11: ally_id, ally_class, stats, preferred_targeting (CLOSEST MVP), is_unique. Prompt 12: role, damage_type, attack_damage / patrol / recovery, scene_path, is_starter_ally, is_defected_ally, debug_color; POST-MVP progression fields.
MercenaryOfferData	res://scripts/resources/mercenary_offer_data.gd	Prompt 12: ally_id, costs, day range, is_defection_offer.
MercenaryCatalog	res://scripts/resources/mercenary_catalog.gd	Prompt 12: offers pool, max_offers_per_day, get_daily_offers.
MiniBossData	res://scripts/resources/mini_boss_data.gd	Prompt 12: defection metadata (defected_ally_id, costs).
DialogueCondition	res://scripts/resources/dialogue/dialogue_condition.gd	key, comparison (==, !=, >, >=, <, <=), value (Variant); optional `condition_type` **relationship_tier** + `character_id` / `required_tier` (Prompt 22); AND only; evaluated by DialogueManager
RelationshipTierConfig	res://scripts/resources/relationship_tier_config.gd	Prompt 22: `tiers` Array[Dictionary] `{ name, min_affinity }` ascending; shared tier names for `RelationshipManager.get_tier`.
CharacterRelationshipData	res://scripts/resources/character_relationship_data.gd	Prompt 22: `character_id`, `starting_affinity`, `display_name` — one `.tres` per character under `res://resources/character_relationship/`.
RelationshipEventData	res://scripts/resources/relationship_event_data.gd	Prompt 22: `signal_name` (SignalBus), `character_deltas` Dictionary id → float.
DialogueEntry	res://scripts/resources/dialogue/dialogue_entry.gd	entry_id, character_id, text, priority, once_only, chain_next_id, conditions[]
CharacterData	res://scripts/resources/character_data.gd	data resource for a single between-mission hub character (id, display_name, HubRole, dialogue tags, 2D placement).
CharacterCatalog	res://scripts/resources/character_catalog.gd	resource holding the hub character set loaded by `Hub2DHub`.
RESOURCE FILES (.tres — actual data)
Ally data (Prompt 11)
File	ally_id	Notes
res://resources/ally_data/ally_melee_generic.tres	ally_melee_generic	Placeholder melee merc
res://resources/ally_data/ally_ranged_generic.tres	ally_ranged_generic	Placeholder ranged merc
res://resources/ally_data/ally_support_generic.tres	ally_support_generic	Optional; not in static roster by default
Mercenary data (Prompt 12)
File	Notes
res://resources/mercenary_catalog.tres	Default offer pool; referenced by CampaignManager
res://resources/mercenary_offers/*.tres	Per-offer rows (subset; catalog may embed sub-resources)
res://resources/miniboss_data/*.tres	Mini-boss defection metadata
Dialogue pools (Prompt 13)
Folder	Notes
res://resources/dialogue/florence/	FLORENCE lines (placeholder TODO)
res://resources/dialogue/companion_melee/	COMPANION_MELEE (Arnulf) — intro, arnulf research hook, generic
res://resources/dialogue/spell_researcher/	SPELL_RESEARCHER (Sybil) — intro, spell-unlock hook, generic
res://resources/dialogue/weapons_engineer/	WEAPONS_ENGINEER placeholder pool
res://resources/dialogue/enchanter/	ENCHANTER placeholder pool
res://resources/dialogue/merchant/	MERCHANT placeholder pool
res://resources/dialogue/mercenary_commander/	MERCENARY_COMMANDER placeholder pool
res://resources/dialogue/campaign_character_template/	CAMPAIGN_CHARACTER_X template pool
res://resources/dialogue/example_character/	EXAMPLE_CHARACTER — conditional + chain demo entries
Character hub cast (Prompt 14)
File	Notes
res://resources/character_data/merchant.tres	MERCHANT (HubRole.SHOP)
res://resources/character_data/researcher.tres	SPELL_RESEARCHER (HubRole.RESEARCH)
res://resources/character_data/enchantress.tres	ENCHANTER (HubRole.ENCHANT)
res://resources/character_data/mercenary_captain.tres	MERCENARY_COMMANDER (HubRole.MERCENARY)
res://resources/character_data/arnulf_hub.tres	COMPANION_MELEE (HubRole.ALLY)
res://resources/character_data/flavor_npc_01.tres	EXAMPLE_CHARACTER (HubRole.FLAVOR_ONLY)
res://resources/character_catalog.tres	CharacterCatalog containing all hub cast entries.
Enemy Data
File	enemy_type	armor_type	Notes
res://resources/enemy_data/orc_grunt.tres	ORCGRUNT	UNARMORED	Basic melee runner
res://resources/enemy_data/orc_brute.tres	ORCBRUTE	HEAVYARMOR	Slow, high HP, melee
res://resources/enemy_data/goblin_firebug.tres	GOBLINFIREBUG	UNARMORED	Fast melee, fire immune
res://resources/enemy_data/plague_zombie.tres	PLAGUEZOMBIE	UNARMORED	Slow tank, poison immune
res://resources/enemy_data/orc_archer.tres	ORCARCHER	UNARMORED	Stops at range, fires
res://resources/enemy_data/bat_swarm.tres	BATSWARM	FLYING	Flying, anti-air only
Building Data
File	building_type	is_locked	unlock_research_id
res://resources/building_data/arrow_tower.tres	ARROWTOWER	false	—
res://resources/building_data/fire_brazier.tres	FIREBRAZIER	false	—
res://resources/building_data/magic_obelisk.tres	MAGICOBELISK	false	—
res://resources/building_data/poison_vat.tres	POISONVAT	false	—
res://resources/building_data/ballista.tres	BALLISTA	true	unlock_ballista
res://resources/building_data/archer_barracks.tres	ARCHERBARRACKS	true	(POST-MVP stub)
res://resources/building_data/anti_air_bolt.tres	ANTIAIRBOLT	false	—
res://resources/building_data/shield_generator.tres	SHIELDGENERATOR	true	(POST-MVP stub)
Weapon Data
File	weapon_slot	burst_count
res://resources/weapon_data/crossbow.tres	CROSSBOW	1
res://resources/weapon_data/rapid_missile.tres	RAPIDMISSILE	10
Spell / Research / Shop Data
File	Class	Notes
res://resources/spell_data/shockwave.tres	SpellData	Shockwave AoE, 50 mana, 60s cooldown
res://resources/research_data/base_structures_tree.tres	ResearchNodeData	6 nodes: unlock_ballista, unlock_antiair, arrow_tower_dmg, unlock_shield_gen, fire_brazier_range, unlock_archer_barracks
res://resources/shop_data/shop_catalog.tres	ShopItemData[]	4 items: tower_repair, building_repair, arrow_tower (voucher), mana_draught
res://resources/territories/main_campaign_territories.tres	TerritoryMapData	Five placeholder territories for main campaign
res://resources/campaign_main_50days.tres	CampaignConfig	50 linear days + territory_map_resource_path (Prompt 8 canonical)
res://resources/campaigns/campaign_short_5_days.tres	CampaignConfig	Default MVP 5-day short campaign (mission_index 1–5)
Faction data
File	faction_id	Notes
res://resources/faction_data_default_mixed.tres	DEFAULT_MIXED	Equal-weight six-type MVP mix
res://resources/faction_data_orc_raiders.tres	ORC_RAIDERS	Orc-heavy roster + placeholder mini-boss id
res://resources/faction_data_plague_cult.tres	PLAGUE_CULT	Undead/fire/flyer mix + mini-boss id (BossData)
Boss data (Prompt 10)
File	boss_id	Notes
res://resources/bossdata_plague_cult_miniboss.tres	plague_cult_miniboss	Shared boss_base.tscn
res://resources/bossdata_orc_warlord_miniboss.tres	orc_warlord	Shared boss_base.tscn
res://resources/bossdata_final_boss.tres	final_boss	Day 50 / campaign boss
SimBot strategy profiles (Prompt 16 Phase 2)
File	profile_id	Notes
res://resources/strategyprofiles/strategy_balanced_default.tres	BALANCED_DEFAULT	Balanced profile: mix of tower types + moderate shockwave
res://resources/strategyprofiles/strategy_greedy_econ.tres	GREEDY_ECON	Greedy econ: prioritize cheap/early towers, fewer upgrades/spells
res://resources/strategyprofiles/strategy_heavy_fire.tres	HEAVY_FIRE	Heavy fire/DPS: FireBrazier/Ballista/MagicObelisk bias + aggressive shockwave
Art resources
Art root: res://art/
- Meshes: res://art/meshes/{buildings,enemies,allies,misc}/ — primitive Mesh .tres, named by convention
- Materials: res://art/materials/{factions,types}/ — StandardMaterial3D .tres, named by convention
- Icons: res://art/icons/{buildings,enemies,allies}/ — Texture2D .png/.tres, POST-MVP
- Generated: res://art/generated/{meshes,icons}/ — drop zone for Blender/AI outputs, takes priority over placeholders
TEST FILES (res://tests/, GdUnit4 framework; full run see PROMPT_9_IMPLEMENTATION.md / PROMPT_10_IMPLEMENTATION.md / PROMPT_12_IMPLEMENTATION.md / PROMPT_13_IMPLEMENTATION.md)
File	What it covers
testmercenaryoffers.gd	Prompt 12: offer generation / preview
testmercenarypurchase.gd	Prompt 12: purchase + economy
testcampaignallyroster.gd	Prompt 12: owned/active roster APIs
testminibossdefection.gd	Prompt 12: defection offer injection
testsimbotmercenaries.gd	Prompt 12: SimBot mercenary API
test_simbot_profiles.gd	Prompt 16 Phase 2: `StrategyProfile` `.tres` loading + basic structure validation
test_simbot_basic_run.gd	Prompt 16 Phase 2: headless `SimBot.run_single()` places buildings without UI dependencies
test_simbot_logging.gd	Prompt 16 Phase 2: `run_batch()` CSV header + append behavior
test_simbot_determinism.gd	Prompt 16 Phase 2: determinism for a fixed seed
test_simbot_safety.gd	Prompt 16 Phase 2: safety check (no `res://ui/` references)
test_dialogue_manager.gd	Prompt 13: DialogueManager conditions, priority, once-only, chain fallback, resource load
test_art_placeholders.gd	Prompt 17: ArtPlaceholderHelper placeholder mesh/material resolution, generated-asset priority, scene wiring, and cache/fallback behavior
test_character_hub.gd	Prompt 14: CharacterData/Catalog loading, Hub click focus behavior, DialoguePanel display + chaining, and UIManager hub open/close integration.
testeconomymanager.gd	gold/material add/spend/reset, signal emission, transactions
testdamagecalculator.gd	Full 4×4 matrix, boundary values, DoT stub
testwavemanager.gd	Wave scaling, countdown, spawn count, faction-weighted composition, mini-boss hook, Prompt 10: regular day spawns no bosses
testbossdata.gd	BossData load, BUILTIN paths, placeholder EnemyData build
testbossbase.gd	BossBase init, nav present, kill → boss_killed
testbosswaves.gd	Boss wave index + escorts + wave_cleared to max
testfinalbossday.gd	Final-boss day / GameManager campaign hooks (see test file)
testfactiondata.gd	Faction .tres load + roster→EnemyData; validate_day_configs on short campaign
testspellmanager.gd	Mana regen, deduct, cooldown, shockwave AoE damage
testarnulfstatemachine.gd	All state transitions, downed/recover cycle
testallydata.gd	AllyData defaults + all res://resources/ally_data/*.tres loads
testallybase.gd	AllyBase find_target, attack in range, ally_killed on HP depletion
testallycombat.gd	Downed→recover timer; skip flying when `can_target_flying` false; LOWEST_HP targeting
testallysignals.gd	ally_spawned, ally_killed, Arnulf generic ally_* + reset ally_spawned
testallyspawning.gd	Campaign roster count under AllyContainer; cleanup on waves cleared / new game
testhealthcomponent.gd	take_damage, heal, reset, health_depleted signal
testresearchmanager.gd	unlock, prereq gating, insufficient material, reset
testshopmanager.gd	purchase flow, affordability, effect application, signal
testgamemanager.gd	State transitions, mission progression, win/fail paths, campaign/territory integration
testterritorydata.gd	Main territory map load and IDs
testcampaignterritorymapping.gd	50-day DayConfig → territory_id validity
testcampaignterritoryupdates.gd	apply_day_result_to_territory + SignalBus
testterritoryeconomybonuses.gd	Gold modifier aggregation
testworldmapui.gd	WorldMap button labels on territory_state_changed
testhexgrid.gd	24 slots, place/sell/upgrade, resource deduction, signals
testbuildingbase.gd	Combat loop, targeting, fire rate, upgrade stats
testprojectilesystem.gd	Init paths, travel, collision, damage matrix, immunity, miss
testsimulationapi.gd	All manager public methods callable without UI
testenemypathfinding.gd	EnemyBase nav, attack, health_depleted → gold signal
test_boss_day_flow.gd	Prompt 21: Boss day progression, territory secure on mini-boss kill
test_campaign_autoload_and_day_flow.gd	Prompt 21: Autoload registration order, campaign start/day progression
test_consumables.gd	Prompt 25: Consumable stacking, effect_tags handling, mission-start application
test_endless_mode.gd	Prompt 23: Endless run start, wave scaling past day 50, hub suppression
test_enemy_dot_system.gd	Prompt 6: DoT burn/poison stacking, tick damage, duration, cleanup
test_florence.gd	Prompt 15: Florence meta-state counters, day advance priority, dialogue conditions
test_relationship_manager.gd	Prompt 22: Affinity add/get, tier lookup, save/restore, event-driven deltas
test_save_manager.gd	Prompt 25: Save/load round-trip, slot management, payload structure
test_settings_manager.gd	Prompt 24: Volume set/get, keybind remap, config file persistence
test_simbot_handlers.gd	Prompt 25: SimBot signal handlers, wave/mission counters, metrics
test_tower_enchantments.gd	Prompt 4: Tower enchantment composition, projectile damage/type override
test_weapon_structural.gd	Audit 6: WeaponLevelData structural fields validation
test_building_specials.gd	Audit 6: Archer Barracks/Shield Generator special behavior validation
test_weapon_upgrade_manager.gd	Prompt 3: Weapon level progression, cost checks, stat lookup, reset
ADDITIONAL SCRIPTS (not previously indexed)
File	What it does
scenes/hub/character_base_2d.gd	Prompt 14: Clickable hub character node — exports CharacterData, emits character_interacted
scripts/florence_data.gd	Prompt 15: FlorenceData resource class — run meta-state (counters, unlock flags)
scripts/resources/strategyprofileconfig.gd	Prompt 16: StrategyProfileConfig wrapper for SimBot profile loading
scripts/resources/test_strategyprofileconfig.gd	Prompt 16: Test helper resource class for SimBot profile tests
scripts/simbot_logger.gd	Prompt 16: SimBot CSV logging utility — writes batch results to user://simbot/logs/
scripts/weapon_upgrade_manager.gd	Prompt 3: WeaponUpgradeManager — per-weapon level tracking, upgrade cost, stat lookup
scripts/ui/settings_screen.gd	Prompt 24: SettingsScreen — audio sliders, graphics quality, keybind remap, Back button
ui/dialogue_ui.gd	Prompt 13: Legacy DialogueUI placeholder panel (kept for reference; DialoguePanel is active)
KNOWN OPEN ISSUES (as of Autonomous Session 3)

    Sell UX is now wired in build mode: InputManager routes slot clicks to BuildMenu placement/sell mode.

    Phase 6 playtest rows 5 (sell), 6 (Sybil shockwave full verify), 7 (Arnulf full verify), 10 (between-mission full loop) not fully confirmed.

    WAVES_PER_MISSION = 3 in GameManager (dev cap; final value is 10).

    dev_unlock_all_research = true in main.tscn (dev flag; must be set false for release).

    SimBot: strategy `activate`, `decide_mercenaries`, `get_log` (Prompt 12); building/spell/wave bot_* helpers remain.

    Windows headless main.tscn run may SIGSEGV; use editor F5 for full loop on Windows.

    `GDAIMCPRuntime` is registered in `project.godot` for the GDAI MCP plugin; requires the plugin enabled in the editor for full behavior.

PHYSICS LAYERS
Layer	Assigned to
1	Tower (StaticBody3D)
2	Enemies
5	Projectiles
7	HexGrid slots (Area3D)
INPUT ACTIONS (defined in project.godot Input Map)
Action Name	Default Binding	Purpose
fire_primary	Left Mouse	Florence crossbow
fire_secondary	Right Mouse	Florence rapid missile
cast_shockwave	Space	Sybil's Shockwave spell
toggle_build_mode	B or Tab	Enter/exit build mode
cancel	Escape	Exit build mode / close menu
SCENE TREE OVERVIEW (main.tscn)

/root/Main (Node3D)
├── Camera3D
├── WorldEnvironment
├── Tower (StaticBody3D) [tower.tscn]
│ ├── TowerMesh (MeshInstance3D)
│ ├── TowerCollision (CollisionShape3D)
│ ├── HealthComponent (Node)
│ └── TowerLabel (Label3D)
├── HexGrid (Node3D) [hex_grid.tscn]
│ └── HexSlot00..HexSlot23 (Area3D ×24)
├── Arnulf (CharacterBody3D) [arnulf.tscn]
├── BuildingContainer (Node3D)
├── ProjectileContainer (Node3D)
├── EnemyContainer (Node3D)
├── Managers (Node)
│ ├── WaveManager (Node)
│ ├── SpellManager (Node)
│ ├── ResearchManager (Node)
│ ├── ShopManager (Node)
│ └── InputManager (Node)
└── UI (CanvasLayer)
  ├── UIManager (Control)
  ├── HUD [hud.tscn]
  ├── BuildMenu [build_menu.tscn]
  ├── BetweenMissionScreen [between_mission_screen.tscn]
  ├── MainMenu [main_menu.tscn]
  ├── MissionBriefing (Control)
  └── EndScreen (Control)

LATEST CHANGES (2026-03-25)

    - Prompt 15 Florence meta-state: `FlorenceData` resource, `Types.DayAdvanceReason`, `SignalBus.florence_state_changed`, `GameManager` day/counter wiring, hub debug label, dialogue condition keys, and `tests/test_florence.gd` (parse-safety fixes: enum cast + type inference).

    - Prompt 13 hub dialogue (`docs/PROMPT_13_IMPLEMENTATION.md`): `DialogueManager` autoload; `DialogueEntry` / `DialogueCondition`; `res://resources/dialogue/**` pools; `dialogue_ui.tscn`; `UIManager.show_dialogue_for_character` + queue; `BetweenMissionScreen` hub lines for Sybil + Arnulf; `test_dialogue_manager.gd` + `run_gdunit_quick.sh` allowlist.

    - Prompt 12 mercenary roster + offers (`docs/PROMPT_12_IMPLEMENTATION.md`): `MercenaryOfferData`, `MercenaryCatalog`, `MiniBossData`, `res://resources/mercenary_catalog.tres` + offers; `CampaignManager` purchase/preview/defection/auto-select; `SignalBus` mercenary + roster signals; `BetweenMissionScreen` Mercenaries tab; `SimBot` strategy + `decide_mercenaries`; GdUnit suites in `run_gdunit_quick.sh` allowlist; `GameManager._transition_to` idempotent for same state.

LATEST CHANGES (2026-03-24)

    - Prompt 10 fixes (`docs/PROMPT_10_FIXES.md`): WaveManager `get_node_or_null` for EnemyContainer/SpawnPoints; `test_wave_manager` / `test_boss_waves` add SpawnPoints to tree before Marker3D `global_position`; `WeaponLevelData` `.tres` `script_class` header; `test_campaign_manager` GdUnit `assert_that().is_not_null()`; `GameManager` `push_warning` + `mission_won` hub (`project.godot` CampaignManager before GameManager); `docs/PROBLEM_REPORT.md` for errors/snippets.
- Prompt 10 mini-boss + campaign boss (`docs/PROMPT_10_IMPLEMENTATION.md`):
  - `BossData` (`res://scripts/resources/boss_data.gd`), `.tres` bosses under `res://resources/bossdata_*.tres`.
  - `BossBase` (`res://scenes/bosses/boss_base.{gd,tscn}`).
  - `SignalBus`: `boss_spawned`, `boss_killed`, `campaign_boss_attempted`.
  - `GameManager` / `CampaignManager`: Day 50 + synthetic boss-attack day flow; `get_day_config_for_index`; territory secure on mini-boss kill.
  - `WaveManager`: `boss_registry`, `set_day_context`, `ensure_boss_registry_loaded`, boss wave + escorts (`Types.EnemyType.keys()` string match).
  - `DayConfig`: `boss_id`, `is_mini_boss`, `is_boss_attack_day`; `CampaignConfig.starting_territory_ids`; `TerritoryData.is_secured`, `has_boss_threat`.
  - Tests: `test_boss_data.gd`, `test_boss_base.gd`, `test_boss_waves.gd`, `test_final_boss_day.gd`; additions in `test_wave_manager.gd`.

- Prompt 7 campaign/day layer added:
  - New autoload: `CampaignManager` (`res://autoloads/campaign_manager.gd`).
  - New resource classes:
    - `CampaignConfig` (`res://scripts/resources/campaign_config.gd`)
    - `DayConfig` (`res://scripts/resources/day_config.gd`)
  - New campaign resources:
    - `res://resources/campaigns/campaign_short_5_days.tres`
    - `res://resources/campaigns/campaign_main_50_days.tres`
  - `SignalBus` added campaign/day lifecycle signals:
    - `campaign_started`, `day_started`, `day_won`, `day_failed`, `campaign_completed`
  - `GameManager` now exposes `start_mission_for_day(day_index, day_config)` and delegates day progression to `CampaignManager`.
  - `WaveManager` now supports day config fields:
    - `configured_max_waves`, `enemy_hp_multiplier`, `enemy_damage_multiplier`, `gold_reward_multiplier`
  - `BetweenMissionScreen` now displays day info and routes next progression via `CampaignManager.start_next_day()`.
  - Added tests:
    - `res://tests/test_campaign_manager.gd`
    - Prompt 7 additions in `res://tests/test_wave_manager.gd`
    - Prompt 7 additions in `res://tests/test_game_manager.gd`

- Prompt 9 factions + weighted waves (`docs/PROMPT_9_IMPLEMENTATION.md`):
  - `FactionData`, `FactionRosterEntry`; `.tres` factions `DEFAULT_MIXED`, `ORC_RAIDERS`, `PLAGUE_CULT`.
  - `WaveManager` roster-weighted spawns (total `N×6`), `set_faction_data_override`, `get_mini_boss_info_for_wave`, `faction_registry`.
  - `CampaignManager.faction_registry`, `validate_day_configs`.
  - `DayConfig.faction_id` default `DEFAULT_MIXED`; `is_mini_boss_day`; `TerritoryData.default_faction_id`.
  - `GameManager` applies `WaveManager.configure_for_day` after `reset_for_new_mission`.
  - Tests: `res://tests/test_faction_data.gd`, Prompt 9 cases in `res://tests/test_wave_manager.gd`.

- InputManager build-mode click now raycasts hex slots on layer 7 and routes menu mode by occupancy.
- BuildMenu now supports `open_for_sell_slot(slot_index, slot_data)` and a sell panel with Sell/Cancel actions.
- HexGrid slot click callback now only updates highlight in build mode (menu opening is centralized in InputManager).
- Added concrete HexGrid sell-flow tests for slot clearing, refund correctness, and `building_sold` signal emission.
- Implementation notes recorded in `docs/PROMPT_1_IMPLEMENTATION.md`.
- Phase 2 firing changes added:
  - `WeaponData` now includes assist/miss tuning fields (all default to `0.0`).
  - `Tower` manual shots now pass through private aim helper for cone assist + miss perturbation.
  - `crossbow.tres` has initial tuning defaults (`7.5`, `0.05`, `2.0`), `rapid_missile.tres` remains `0.0`.
  - Added simulation API tests covering assist, miss, and autofire bypass behavior.
- Implementation notes recorded in `docs/PROMPT_2_IMPLEMENTATION.md`.
- Phase 3 weapon-upgrade system added:
  - `WeaponLevelData` resource class (`res://scripts/resources/weapon_level_data.gd`)
  - `WeaponUpgradeManager` scene-bound manager (`/root/Main/Managers/WeaponUpgradeManager`)
  - New level resources in `res://resources/weapon_level_data/` (crossbow + rapid missile, levels 1-3)
  - `SignalBus.weapon_upgraded(weapon_slot, new_level)`
  - `BetweenMissionScreen` now includes a Weapons tab with upgrade controls
  - `Tower` now resolves effective damage/speed/reload/burst via manager with null-guard fallback
  - `docs/PROMPT_3_IMPLEMENTATION.md` records implementation details
- Phase 4 two-slot enchantment system added:
  - New autoload: `EnchantmentManager` (`res://autoloads/enchantment_manager.gd`)
  - New resource class: `EnchantmentData` (`res://scripts/resources/enchantment_data.gd`)
  - New resources: `res://resources/enchantments/{scorching_bolts,sharpened_mechanism,toxic_payload,arcane_focus}.tres`
  - New SignalBus signals: `enchantment_applied(...)`, `enchantment_removed(...)`
  - `Tower` now composes projectile damage + damage type using `"elemental"` and `"power"` enchantment slots
  - `ProjectileBase.initialize_from_weapon(...)` now supports optional custom damage and damage type
  - `GameManager.start_new_game()` resets enchantment state
  - `BetweenMissionScreen` now includes enchantment apply/remove controls in Weapons tab
  - Added tests: `res://tests/test_enchantment_manager.gd`, `res://tests/test_tower_enchantments.gd`
  - Added projectile regression: `test_initialize_from_weapon_without_custom_values_uses_physical`
- Phase 5 DoT system added:
  - `DamageCalculator.calculate_dot_tick(...)` now returns live per-tick DoT values (no stub).
  - `EnemyBase` now stores `active_status_effects` and exposes `apply_dot_effect(effect_data: Dictionary)`.
  - Burn: one stack per source with duration refresh + max total damage retention.
  - Poison: additive stacks capped by `MAX_POISON_STACKS`.
  - `ProjectileBase.initialize_from_building(...)` now accepts DoT fields and applies DoT on hit for fire/poison.
  - Fire Brazier / Poison Vat `.tres` now include conservative DoT defaults.
  - Added tests: `res://tests/test_enemy_dot_system.gd`; DoT integration coverage in `res://tests/test_projectile_system.gd`.
- Phase 6 solid-building navigation added:
  - `BuildingBase` scene now includes `BuildingCollision` (`StaticBody3D`) + `NavigationObstacle3D`.
  - `BuildingBase` script now centralizes footprint/obstacle tuning constants and setup.
  - `EnemyBase` ground pathing now tracks progress and applies stuck recovery retargeting.
  - `EnemyBase` flying pathing remains direct steering and ignores ground obstacles.
  - `HexGrid` placement now calls `_activate_building_obstacle(...)` hook.
  - Added pathing integration scenarios in `res://tests/test_enemy_pathfinding.gd`.
  - Added building collision/obstacle scene assertion in `res://tests/test_building_base.gd`.


---

# Part 5 — INDEX_FULL (`docs/INDEX_FULL.md`)

INDEX_FULL.md
=============

FOUL WARD — INDEX_FULL.md

Full public API reference for every script, resource type, and system.
Source of truth: REPO_DUMP_AFTER_MVP.md. **Doc layout:** `docs/README.md`. **Consolidated snapshot:** `docs/OPUS_ALL_ACTIONS.md` merges backlog + AGENTS + Prompt 26 log + both indexes. Updated: 2026-03-28 (**Prompt 26:** Full project audit — 55 unindexed files indexed, `docs/AGENTS.md` standing orders, `IMPROVEMENTS_TO_BE_DONE.md` backlog with 78 issues, test Unit/Integration classification, parallel runner spec — `docs/PROMPT_26_IMPLEMENTATION.md`). **Prompt 24:** `PlaceholderIconGenerator` `tools/generate_placeholder_icons.gd` + editor plugin `addons/fw_placeholder_icons`; `ArtPlaceholderHelper` icon PNGs; `SettingsManager` autoload `user://settings.cfg`; `scenes/ui/settings_screen`; UI wiring `build_menu` / `between_mission_screen` / `world_map` / `main_menu`; `tests/test_settings_manager.gd` — `docs/PROMPT_24_IMPLEMENTATION.md`). **Prompt 22:** `RelationshipManager` autoload, `relationship_tier` dialogue conditions, resources under `res://resources/relationship_*` / `character_relationship/` — `docs/PROMPT_22_IMPLEMENTATION.md`. Prompt 19: Blender batch GLBs `res://art/generated/**`, `generation_log.json`, `FUTURE_3D_MODELS_PLAN.md`, `docs/PROMPT_19_IMPLEMENTATION.md`; `# TODO(ART)` in enemy/ally/arnulf/tower/building/boss/hub scripts. Prompt 18: RAG + MCP — `docs/PROMPT_18_IMPLEMENTATION.md`. Audit 6 delta: `AUDIT_IMPLEMENTATION_AUDIT_6.md` — SpellManager multi-spell; WeaponLevelData structural fields; BuildingBase archer barracks / shield generator; GameManager territory aggregates; tests `test_weapon_structural.gd`, `test_building_specials.gd`. Prompt 20: `docs/obsolete/` + INDEX header/autoload alignment — `docs/PROMPT_20_IMPLEMENTATION.md`.
Use INDEX_SHORT.md for fast orientation, INDEX_FULL.md for exact method signatures, signals, and dependencies.
CONVENTIONS SUMMARY (see CONVENTIONS.md for full rules)

    Files: snake_case.gd / .tscn / .tres

    Classes: PascalCase (classname keyword)

    Variables & functions: snake_case

    Constants: UPPER_SNAKE_CASE

    Private members: prefix with underscore _

    Signals: past tense for events (enemy_killed), present tense for requests (build_requested)

    All cross-system signals: through SignalBus ONLY — never direct node-to-node for cross-system events

    Autoloads: access by name directly (EconomyManager.add_gold()), never cache in a variable

    Node references: typed onready var — never string paths

    Tests: GdUnit4. File named test_{module}.gd. Function named test_{what}{condition}{expected}

AUTOLOADS
SignalBus

Path: res://autoloads/signal_bus.gd
Purpose: Central signal registry. All cross-system signals are declared here and only here. No logic, no state. Every module that emits or receives a cross-system signal does so through this singleton.
Dependencies: None.
Complete Signal Registry

COMBAT

    enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)

    enemy_reached_tower(enemy_type: Types.EnemyType, damage: int) — POST-MVP stub, not emitted in MVP.

    tower_damaged(current_hp: int, max_hp: int)

    tower_destroyed()

    projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)

    arnulf_state_changed(new_state: Types.ArnulfState)

    arnulf_incapacitated()

    arnulf_recovered()

ALLIES (Prompt 11)

    ally_spawned(ally_id: String) — emitted when `AllyBase.initialize_ally_data` runs or Arnulf `reset_for_new_mission` (id `arnulf`).

    ally_downed(ally_id: String) — emitted when a generic ally enters downed path (POST-MVP) or Arnulf enters DOWNED.

    ally_recovered(ally_id: String) — emitted when Arnulf completes RECOVERING (generic mirror).

    ally_killed(ally_id: String) — emitted when a generic ally’s HP hits zero (mission removal); Arnulf has no kill path in MVP (POST-MVP).

    ally_state_changed(ally_id: String, new_state: String) — POST-MVP detailed tracking.

MERCENARIES / ROSTER (Prompt 12)

    mercenary_offer_generated(ally_id: String) — when a catalog or defection offer is added to the current pool.

    mercenary_recruited(ally_id: String) — after a successful `purchase_mercenary_offer`.

    ally_roster_changed() — owned/active roster or offer list changed (UI refresh).

BOSSES (Prompt 10)

    boss_spawned(boss_id: String) — emitted when `BossBase` finishes `initialize_boss_data`.

    boss_killed(boss_id: String) — emitted when a boss’s `HealthComponent` depletes.

    campaign_boss_attempted(day_index: int, success: bool) — emitted by `GameManager` on final-boss attempt outcome.

WAVES

    wave_countdown_started(wave_number: int, seconds_remaining: float)

    wave_started(wave_number: int, enemy_count: int)

    wave_cleared(wave_number: int)

    all_waves_cleared()

ECONOMY

    resource_changed(resource_type: Types.ResourceType, new_amount: int)

TERRITORIES / WORLD MAP

    territory_state_changed(territory_id: String)

    world_map_updated()

BUILDINGS

    building_placed(slot_index: int, building_type: Types.BuildingType)

    building_sold(slot_index: int, building_type: Types.BuildingType)

    building_upgraded(slot_index: int, building_type: Types.BuildingType)

    building_destroyed(slot_index: int) — POST-MVP stub.

SPELLS

    spell_cast(spell_id: String)

    spell_ready(spell_id: String)

    mana_changed(current_mana: int, max_mana: int)

GAME STATE

    game_state_changed(old_state: Types.GameState, new_state: Types.GameState)

    mission_started(mission_number: int)

    mission_won(mission_number: int)

    mission_failed(mission_number: int)

BUILD MODE

    build_mode_entered()

    build_mode_exited()

RESEARCH

    research_unlocked(node_id: String)

SHOP

    shop_item_purchased(item_id: String)

DamageCalculator

Path: res://autoloads/damage_calculator.gd
Purpose: Stateless pure-function singleton. Resolves final damage by applying the 4×4 damage_type × armor_type multiplier matrix. All damage in the game routes through this.
Dependencies: None. No signals.

Damage matrix:
	PHYSICAL	FIRE	MAGICAL	POISON
UNARMORED	1.0	1.0	1.0	1.0
HEAVY_ARMOR	0.5	1.0	2.0	1.0
UNDEAD	1.0	2.0	1.0	0.0
FLYING	1.0	1.0	1.0	1.0

Public methods:

    calculate_damage(base_damage: float, damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float

    get_multiplier(damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float

    is_immune(damage_type: Types.DamageType, armor_type: Types.ArmorType) -> bool

    calculate_dot_tick(dot_total_damage: float, tick_interval: float, duration: float, damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float (returns matrix-adjusted per-tick DoT damage)

Notes: per-enemy immunities via EnemyData.damage_immunities[] are applied before calling DamageCalculator.
EconomyManager

Path: res://autoloads/economy_manager.gd
Purpose: Single source of truth for gold, building_material, research_material. Emits resource_changed on every modification.
Dependencies: SignalBus.

Public variables (conceptual):

    gold: int = 100

    building_material: int = 10

    research_material: int = 0

Public methods (summarized):

    add_gold(amount: int) -> void

    spend_gold(amount: int) -> bool

    add_building_material(amount: int) -> void

    spend_building_material(amount: int) -> bool

    add_research_material(amount: int) -> void

    spend_research_material(amount: int) -> bool

    can_afford(gold_cost: int, material_cost: int) -> bool

    can_afford_research(research_cost: int) -> bool

    award_post_mission_rewards() -> void

    reset_to_defaults() -> void

    get_gold(), get_building_material(), get_research_material() -> int

Consumes: SignalBus.enemy_killed (adds gold_reward).
RelationshipManager

Path: res://autoloads/relationship_manager.gd
Purpose: Data-driven per-character affinity [−100, 100] and named tiers from `res://resources/relationship_tier_config.tres`. Loads `res://resources/character_relationship/*.tres` and `res://resources/relationship_events/*.tres`; connects to SignalBus signals listed in each `RelationshipEventData` (skips unknown signal names with `push_warning`). No `class_name` — autoload singleton name only (avoids shadowing in GdUnit).
Dependencies: SignalBus.

Public methods (summarized):

    get_affinity(character_id: String) -> float

    get_tier(character_id: String) -> String

    get_tier_rank_index(tier_name: String) -> int

    add_affinity(character_id: String, delta: float) -> void

    get_save_data() -> Dictionary

    restore_from_save(data: Dictionary) -> void

    reload_from_resources() -> void

    test_relationship_events_override: Array — tests only; if non-empty, replaces directory scan for event `.tres` files.

DialogueManager (delta): `DialogueCondition` may set `condition_type` to `relationship_tier` with `character_id` and `required_tier`; evaluated via `RelationshipManager` (see `dialogue_manager.gd`).

Tests: `res://tests/test_relationship_manager.gd`.
GameManager

Path: res://autoloads/game_manager.gd
Purpose: Session state machine: missions, waves, game state transitions, mission rewards, optional territory map + end-of-mission gold modifiers.
Dependencies: SignalBus, EconomyManager, WaveManager, ResearchManager, ShopManager, CampaignManager.

Constants:

    TOTAL_MISSIONS: int = 5

    WAVES_PER_MISSION: int = 3 (DEV CAP; final 10)

    MAIN_CAMPAIGN_CONFIG_PATH: String — documents canonical 50-day `CampaignConfig` path (`res://resources/campaign_main_50days.tres`).

Public variables:

    current_mission: int = 1

    current_wave: int = 0

    game_state: Types.GameState = MAIN_MENU

    territory_map: TerritoryMapData — null when active campaign has no `territory_map_resource_path`.

Key methods:

    start_new_game() -> void

    start_next_mission() -> void

    start_wave_countdown() -> void

    enter_build_mode() / exit_build_mode() -> void

    get_game_state(), get_current_mission(), get_current_wave() -> …

    start_mission_for_day(day_index: int, day_config: DayConfig) -> void

    Private `_begin_mission_wave_sequence()` — resolves `/root/Main/Managers/WaveManager` via `get_tree().root.get_node_or_null("Main")` then `Managers` / `WaveManager`; if any step is null, `push_warning` with mission index and return (no wave start; supports headless tests without `main.tscn`; warnings avoid GdUnit `GodotGdErrorMonitor` false failures).

    Private `_on_mission_won_transition_to_hub(mission_number: int)` — after `CampaignManager` handles `mission_won`, sets `GAME_WON` or `BETWEEN_MISSIONS`. Requires `project.godot` autoload order: `CampaignManager` before `GameManager`.

    reload_territory_map_from_active_campaign() -> void

    get_current_day_index() -> int

    get_day_config_for_index(day_index: int) -> DayConfig

    get_current_day_config() -> DayConfig

    get_current_day_territory_id() -> String

    get_territory_data(territory_id: String) -> TerritoryData

    get_current_day_territory() -> TerritoryData

    get_all_territories() -> Array[TerritoryData]

    get_current_territory_gold_modifiers() -> Dictionary — keys `flat_gold_end_of_day` (int), `percent_gold_end_of_day` (float).

    apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void

    prepare_next_campaign_day_if_needed() -> void — boss-attack / synthetic day prep when advancing past authored `day_configs`.

    advance_to_next_day() -> void — increments campaign day for boss-repeat loop paths.

    get_synthetic_boss_day_config() -> DayConfig — runtime-only config for post-length boss strike days (`_synthetic_boss_attack_day`).

    reset_boss_campaign_state_for_test() -> void — clears Prompt 10 boss campaign flags (tests).

Prompt 10 public state (selected): `final_boss_id`, `final_boss_defeated`, `final_boss_active`, `current_boss_threat_territory_id`, `held_territory_ids`.

Consumes: all_waves_cleared, tower_destroyed, boss_killed; subscribes to mission_won (hub transition). See `docs/PROBLEM_REPORT.md`.
DialogueManager

Path: res://autoloads/dialogue_manager.gd
Purpose: Data-driven between-mission hub dialogue: loads `DialogueEntry` resources from `res://resources/dialogue/**`, applies priority selection, AND conditions, once-only tracking, and chain pointers (`active_chains_by_character`). UI-agnostic; `DialogueUI` + `UIManager` call into it.

Dependencies: SignalBus, GameManager (sync), EconomyManager, ResearchManager (via `Main/Managers/ResearchManager` when present).

Public variables (selected): `entries_by_id`, `entries_by_character`, `played_once_only`, `active_chains_by_character`, `mission_won_count`, `mission_failed_count`, `current_mission_number`, `current_gamestate`.

Signals: `dialogue_line_started(entry_id: String, character_id: String)`, `dialogue_line_finished(entry_id: String, character_id: String)`.

Key methods:

    request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry

    mark_entry_played(entry_id: String) -> void

    get_entry_by_id(entry_id: String) -> DialogueEntry

    notify_dialogue_finished(entry_id: String, character_id: String) -> void

    _load_all_dialogue_entries() -> void — rescans folder (used by tests after mutation).

Internal: `_evaluate_conditions`, `_resolve_state_value`, `_compare`, `_sybil_research_unlocked_any`, `_arnulf_research_unlocked_any`, `_get_research_manager()` — see `docs/PROMPT_13_IMPLEMENTATION.md` for condition keys.

Consumes: SignalBus.game_state_changed, mission_started, mission_won, mission_failed, resource_changed, research_unlocked, shop_item_purchased, arnulf_state_changed, spell_cast (stubs where no logic yet).
AutoTestDriver

Path: res://autoloads/auto_test_driver.gd
Purpose: Headless integration smoke tester, active only with --autotest CLI flag.

ArtPlaceholderHelper

class path: res://scripts/art/art_placeholder_helper.gd
class_name: ArtPlaceholderHelper
purpose: Stateless utility. Resolves Mesh, Material, and Texture2D resources from res://art using convention-based path derivation keyed by Types.EnemyType, Types.BuildingType, ally ID strings, and faction ID strings. Caches loaded resources. Prefers res://art/generated/ assets over placeholders. Falls back to unknown_mesh/neutral material on missing resources — never crashes.
public methods:
  get_enemy_mesh(enemy_type: Types.EnemyType) -> Mesh
  get_building_mesh(building_type: Types.BuildingType) -> Mesh
  get_ally_mesh(ally_id: StringName) -> Mesh
  get_tower_mesh() -> Mesh
  get_unknown_mesh() -> Mesh
  get_faction_material(faction_id: StringName) -> Material
  get_enemy_material(enemy_type: Types.EnemyType) -> Material
  get_building_material(building_type: Types.BuildingType) -> Material
  get_enemy_icon(enemy_type: Types.EnemyType) -> Texture2D  [POST-MVP stub]
  get_building_icon(building_type: Types.BuildingType) -> Texture2D  [POST-MVP stub]
  get_ally_icon(ally_id: StringName) -> Texture2D  [POST-MVP stub]
  clear_cache() -> void
exported variables: none
signals emitted: none
dependencies: Types, ResourceLoader (built-in)

Placeholder GLB batch (Prompt 19)

Path: res://tools/generate_placeholder_glbs_blender.py  
Purpose: Run with `blender --background --python tools/generate_placeholder_glbs_blender.py`. Generates Rigify-based low-poly humanoid/boss GLBs, static buildings/misc, bat swarm with Empty-driven animation; writes `res://art/generated/generation_log.json`. Requires numpy available to Blender’s Python for glTF export.

Path: res://FUTURE_3D_MODELS_PLAN.md  
Purpose: authoritative transition plan from placeholders to production assets (Hyper3D/Rodin, Mixamo, Blender combine, Godot validation); includes `generation_log` table, scene audit appendix, PhysicalBone3D ragdoll plan, AnimationPlayer wiring, hub portrait TODOs.

`# TODO(ART)` annotations (2026-03-28): `scenes/enemies/enemy_base.gd`, `enemy_base.tscn`, `scenes/allies/ally_base.gd`, `ally_base.tscn`, `scenes/arnulf/arnulf.gd`, `arnulf.tscn`, `scenes/tower/tower.gd`, `tower.tscn`, `scenes/buildings/building_base.gd`, `scenes/bosses/boss_base.gd`, `ui/hub.gd`, `ui/hub.tscn`.

SCENE SCRIPTS (Tower, Arnulf, HexGrid, BuildingBase, EnemyBase, ProjectileBase)

(Details are as previously summarized in INDEX_SHORT.md, expanded with method behavior and signals.)

## 2026-03-24 Prompt 6 delta

- `res://scenes/buildings/building_base.tscn`
  - Added `BuildingCollision` (`StaticBody3D`, layer 4 bit, enemy-only mask) and `NavigationObstacle3D`.
- `res://scenes/buildings/building_base.gd`
  - Added footprint/obstacle constants and `_configure_base_area()` setup helpers.
- `res://scenes/enemies/enemy_base.tscn`
  - Updated `NavigationAgent3D` defaults and enemy collision mask to include buildings/arnulf/tower.
- `res://scenes/enemies/enemy_base.gd`
  - Added split physics loops for ground vs flying and stuck-prevention progress tracking.
- `res://scenes/hex_grid/hex_grid.gd`
  - Placement now includes `_activate_building_obstacle(building: BuildingBase)` integration hook.
- Tests
  - `res://tests/test_enemy_pathfinding.gd` now validates solid-ring routing, flying bypass, sell/clear route reopening, and stuck recovery.
  - `res://tests/test_building_base.gd` now validates presence/configuration of collision + obstacle nodes.
## 2026-03-24 Prompt 7 delta

- Added campaign/day resource classes:
  - `res://scripts/resources/day_config.gd` (`DayConfig`)
    - fields: `day_index`, `display_name`, `description`, `faction_id`, `territory_id`,
      `is_mini_boss_day`, `is_final_boss`, `base_wave_count`, `enemy_hp_multiplier`,
      `enemy_damage_multiplier`, `gold_reward_multiplier`.
  - `res://scripts/resources/campaign_config.gd` (`CampaignConfig`)
    - fields: `campaign_id`, `display_name`, `day_configs:Array[DayConfig]`,
      `is_short_campaign`, `short_campaign_length`.
    - method: `get_effective_length() -> int`.
- Added campaign resources:
  - `res://resources/campaigns/campaign_short_5_days.tres`
  - `res://resources/campaigns/campaign_main_50_days.tres`
    - placeholder day ramp pattern for wave count + hp/damage/reward multipliers.
- Added autoload:
  - `CampaignManager` at `res://autoloads/campaign_manager.gd`.
  - Public API:
    - `start_new_campaign() -> void`
    - `start_next_day() -> void`
    - `get_current_day() -> int`
    - `get_campaign_length() -> int`
    - `get_current_day_config() -> DayConfig`
    - `set_active_campaign_config_for_test(config: CampaignConfig) -> void` (test-only).
  - State:
    - `current_day`, `campaign_length`, `campaign_id`, `campaign_completed`,
      `failed_attempts_on_current_day`, `current_day_config`, `campaign_config`,
      `active_campaign_config`.
- SignalBus additions (declared in `res://autoloads/signal_bus.gd`):
  - `campaign_started(campaign_id: String)` emitted by `CampaignManager.start_new_campaign()`.
  - `day_started(day_index: int)` emitted by `CampaignManager` when day starts.
  - `day_won(day_index: int)` emitted by `CampaignManager` on mission-day win.
  - `day_failed(day_index: int)` emitted by `CampaignManager` on mission-day fail.
  - `campaign_completed(campaign_id: String)` emitted by `CampaignManager` on final day completion.
- GameManager updates:
  - `start_new_game()` now delegates mission kickoff to `CampaignManager.start_new_campaign()`.
  - `start_next_mission()` now delegates to `CampaignManager.start_next_day()`.
  - Added `start_mission_for_day(day_index: int, day_config: DayConfig) -> void`.
- WaveManager updates:
  - Added day-config fields:
    - `configured_max_waves: int`
    - `enemy_hp_multiplier: float`
    - `enemy_damage_multiplier: float`
    - `gold_reward_multiplier: float`
  - Added `configure_for_day(day_config: DayConfig) -> void`.
  - End-of-wave completion now uses `configured_max_waves` fallback to `max_waves`.
  - Spawn path now applies per-day multipliers via duplicated `EnemyData` before enemy initialization.
- BetweenMissionScreen updates:
  - Added day labels and refresh logic:
    - `DayProgressLabel` ("Day X / Y")
    - `DayNameLabel` ("Day X - <name>")
  - Next button flow now routes to `CampaignManager.start_next_day()`.
- Tests added/expanded:
  - New file: `res://tests/test_campaign_manager.gd` (campaign/day lifecycle + test helper).
  - Added Prompt 7 cases to `res://tests/test_wave_manager.gd`.
  - Added Prompt 7 cases to `res://tests/test_game_manager.gd`.
## 2026-03-24 Prompt 9 delta

- **Faction resources**
  - `res://scripts/resources/faction_roster_entry.gd` (`FactionRosterEntry`): per-roster-row `enemy_type`, `base_weight`, `min_wave_index`, `max_wave_index`, `tier`.
  - `res://scripts/resources/faction_data.gd` (`FactionData`): identity, `roster[]`, mini-boss hooks, scaling fields; `get_entries_for_wave`, `get_effective_weight_for_wave`; `BUILTIN_FACTION_RESOURCE_PATHS`.
  - Data: `res://resources/faction_data_default_mixed.tres`, `faction_data_orc_raiders.tres`, `faction_data_plague_cult.tres`.
- **DayConfig** (`res://scripts/resources/day_config.gd`): `faction_id` default `DEFAULT_MIXED`; `is_mini_boss` renamed **`is_mini_boss_day`** (campaign `.tres` migrated).
- **TerritoryData**: `default_faction_id` (POST-MVP).
- **CampaignManager** (`res://autoloads/campaign_manager.gd`):
  - `faction_registry: Dictionary` (String → FactionData), `_load_faction_registry()` in `_ready`.
  - `validate_day_configs(day_configs: Array[DayConfig]) -> void`.
- **WaveManager** (`res://scripts/wave_manager.gd`):
  - Faction-driven spawning: weighted roster allocation, total enemies **`wave_number × 6`** (scaled only if `difficulty_offset != 0`).
  - `faction_registry`, `set_faction_data_override(faction_data: FactionData) -> void`, `resolve_current_faction() -> void`, `get_mini_boss_info_for_wave(wave_index: int) -> Dictionary`.
  - Mini-boss hook respects `DayConfig.is_mini_boss_day` unless a test **faction override** is set.
  - Uses `preload` aliases (`FactionDataType`) where needed for autoload parse order (**DEVIATION** vs bare `class_name` types).
- **GameManager**: `configure_for_day` on WaveManager is invoked **after** `reset_for_new_mission()` in `_begin_mission_wave_sequence()` so day tuning persists.
- **Tests**: `res://tests/test_faction_data.gd`; Prompt 9 cases in `res://tests/test_wave_manager.gd`.
- **Notes**: `docs/PROMPT_9_IMPLEMENTATION.md`.
MANAGERS (WaveManager, SpellManager, ResearchManager, ShopManager, InputManager, SimBot)

(Full descriptions of exports, methods, signals, dependencies as summarized earlier.)
CUSTOM RESOURCE TYPES

Full field tables for EnemyData, BuildingData, WeaponData, SpellData, ResearchNodeData, ShopItemData as previously spelled out.

**FactionRosterEntry** (`res://scripts/resources/faction_roster_entry.gd`)

| Field | Type | Purpose |
|-------|------|---------|
| `enemy_type` | `Types.EnemyType` | Which enemy type this roster row spawns |
| `base_weight` | `float` | Relative weight within the wave’s allocation |
| `min_wave_index` | `int` | First wave (inclusive) where this row is active |
| `max_wave_index` | `int` | Last wave (inclusive) where this row is active |
| `tier` | `int` | 1 basic, 2 elite, 3 special — feeds `get_effective_weight_for_wave` ramp |

**FactionData** (`res://scripts/resources/faction_data.gd`)

| Field / member | Type | Purpose |
|----------------|------|---------|
| `faction_id` | `String` | Stable ID; must match `DayConfig.faction_id` and registry keys |
| `display_name` | `String` | UI / logs |
| `description` | `String` | Codex / summary copy |
| `roster` | `Array[FactionRosterEntry]` | Weighted spawn table (entries are sub-resources in `.tres`) |
| `mini_boss_ids` | `Array[String]` | `BossData.boss_id` values; used with `mini_boss_wave_hints` for `get_mini_boss_info_for_wave` |
| `mini_boss_wave_hints` | `Array[int]` | Waves where `get_mini_boss_info_for_wave` may return data |
| `roster_tier` | `int` | Coarse faction difficulty tier (1–3) |
| `difficulty_offset` | `float` | Scales total enemy count when non-zero (`WaveManager` formula) |
| `BUILTIN_FACTION_RESOURCE_PATHS` | `const Array[String]` | Paths to shipped faction `.tres` files |

Public methods: `get_entries_for_wave(wave_index: int) -> Array[FactionRosterEntry]`, `get_effective_weight_for_wave(entry: FactionRosterEntry, wave_index: int) -> float`.

**BossData** (`res://scripts/resources/boss_data.gd`)

| Field / member | Type | Purpose |
|----------------|------|---------|
| `boss_id` | `String` | Stable id; matches `DayConfig.boss_id`, faction `mini_boss_ids`, registry keys |
| `display_name`, `description` | `String` | UI / codex |
| `faction_id` | `String` | Which faction context loads this boss |
| `associated_territory_id` | `String` | Optional territory link (mini-boss secure hook) |
| `max_hp` … `gold_reward` | various | Combat stats mirrored into `build_placeholder_enemy_data()` |
| `escort_unit_ids` | `Array[String]` | Enum **key** strings, e.g. `"ORC_GRUNT"` — `WaveManager` resolves via `Types.EnemyType.keys()` |
| `phase_count` | `int` | Multi-phase hook (`BossBase.advance_phase`) |
| `is_mini_boss` / `is_final_boss` | `bool` | Encounter classification |
| `boss_scene` | `PackedScene` | Spawn scene; defaults to `boss_base.tscn` in shipped `.tres` |
| `BUILTIN_BOSS_RESOURCE_PATHS` | `const Array[String]` | Shipped boss `.tres` paths |

Public methods: `build_placeholder_enemy_data() -> EnemyData`.

**BossBase** (`res://scenes/bosses/boss_base.gd`): extends `EnemyBase`; `initialize_boss_data(data: BossData) -> void`, `advance_phase() -> void`; emits `boss_spawned` / `boss_killed`.

**AllyData** (`res://scripts/resources/ally_data.gd`) — Prompt 11

| Field | Type | Purpose |
|-------|------|---------|
| `ally_id` | `String` | Stable id (matches SignalBus payloads, roster lookup) |
| `display_name`, `description` | `String` | UI / placeholder narrative |
| `ally_class` | `Types.AllyClass` | MELEE / RANGED / SUPPORT |
| `max_hp`, `move_speed`, `basic_attack_damage`, `attack_range`, `attack_cooldown` | various | Combat/movement tuning (data-driven) |
| `preferred_targeting` | `Types.TargetPriority` | MVP: **CLOSEST** only |
| `is_unique` | `bool` | Named vs generic merc |
| `starting_level`, `level_scaling_factor`, `uses_downed_recovering` | POST-MVP | Campaign / Arnulf-like recovery |
| `role` | `Types.AllyRole` | SimBot / auto-select scoring |
| `damage_type`, `can_target_flying` | `Types.DamageType`, `bool` | Combat tagging |
| `attack_damage`, `patrol_radius`, `recovery_time` | `float` | Primary damage (fallback to `basic_attack_damage` if zero), patrol, downed loop |
| `scene_path` | `String` | Spawn scene for `AllyBase` |
| `is_starter_ally`, `is_defected_ally` | `bool` | Campaign start vs mini-boss defection |
| `debug_color` | `Color` | Placeholder mesh tint |

**MercenaryOfferData** (`res://scripts/resources/mercenary_offer_data.gd`) — Prompt 12: `ally_id`, resource costs, `min_day` / `max_day`, `is_defection_offer`, `is_available_on_day`, `get_cost_summary`.

**MercenaryCatalog** (`res://scripts/resources/mercenary_catalog.gd`) — Prompt 12: `offers` (untyped `Array`), `max_offers_per_day`, `get_daily_offers`.

**MiniBossData** (`res://scripts/resources/mini_boss_data.gd`) — Prompt 12: `can_defect_to_ally`, `defected_ally_id`, defection cost fields.

**DialogueCondition** (`res://scripts/resources/dialogue/dialogue_condition.gd`) — Prompt 13

| Field | Type | Purpose |
|-------|------|---------|
| `key` | `String` | Condition key for DialogueManager (`current_mission_number`, `gold_amount`, `sybil_research_unlocked_any`, `research_unlocked_<id>`, …) |
| `comparison` | `String` | `==`, `!=`, `>`, `>=`, `<`, `<=` |
| `value` | `Variant` | Expected value (int, bool, or string for game-state name) |

**DialogueEntry** (`res://scripts/resources/dialogue/dialogue_entry.gd`) — Prompt 13

| Field | Type | Purpose |
|-------|------|---------|
| `entry_id` | `String` | Unique id (warnings on duplicate) |
| `character_id` | `String` | Role bucket (`SPELL_RESEARCHER`, `COMPANION_MELEE`, …) |
| `text` | `String` | Multiline line (placeholder TODO in MVP) |
| `priority` | `int` | Higher = more likely when conditions pass |
| `once_only` | `bool` | Suppress after `mark_entry_played` for this run |
| `chain_next_id` | `String` | Optional next `entry_id` after current line plays |
| `conditions` | `Array[DialogueCondition]` | All must pass (AND) |

**CharacterData** (`res://scripts/resources/character_data.gd`) — Prompt 14

| Field | Type | Purpose |
|-------|------|---------|
| `character_id` | `String` | Stable ID passed into `DialogueManager.request_entry_for_character()` |
| `display_name` | `String` | Speaker/name shown by hub character UI and `DialoguePanel` |
| `description` | `String` | Placeholder copy for future tooltips/codex |
| `role` | `Types.HubRole` | Drives which `BetweenMissionScreen` panel to open |
| `portrait_id` | `String` | Visual identifier for future portrait rendering |
| `icon_id` | `String` | Optional sprite/icon identifier for future UI |
| `hub_position_2d` | `Vector2` | Intended 2D placement for the hub overlay |
| `hub_marker_name_3d` | `String` | Marker reference for a future 3D hub implementation |
| `default_dialogue_tags` | `Array[String]` | Tags passed into `DialogueManager` when requesting dialogue (MVP ignores tags) |

**CharacterCatalog** (`res://scripts/resources/character_catalog.gd`) — Prompt 14

| Field | Type | Purpose |
|-------|------|---------|
| `characters` | `Array[CharacterData]` | Full hub character set instantiated by `Hub2DHub` |

**DialogueUI** (`res://ui/dialogueui.gd` / `dialogueui.tscn`) — Prompt 13: `show_entry(DialogueEntry)`; **Continue** → `mark_entry_played` / chain or `notify_dialogue_finished`.

**DialoguePanel** (`res://ui/dialogue_panel.gd` / `dialogue_panel.tscn`) — Prompt 14
- `show_entry(display_name: String, entry: DialogueEntry) -> void`: sets SpeakerLabel + TextLabel and makes the overlay visible.
- `clear_dialogue() -> void`: hides the panel and resets the current entry.
- Click-to-continue: left mouse advances. On chain end it calls `DialogueManager.notify_dialogue_finished`.

**HubCharacterBase2D** (`res://scenes/hub/character_base_2d.gd` / `character_base_2d.tscn`) — Prompt 14
- Export: `character_data: CharacterData`.
- Signal: `character_interacted(character_id: String)` emitted on left mouse click.

**Hub2DHub** (`res://ui/hub.gd` / `ui/hub.tscn`) — Prompt 14
- Export: `character_catalog: CharacterCatalog`.
- Signals: `hub_opened()`, `hub_closed()`, `hub_character_interacted(character_id: String)`.
- Public API:
  - `open_hub() -> void`
  - `close_hub() -> void`
  - `focus_character(character_id: String) -> void` (same behavior as a user click)
  - `set_between_mission_screen(screen: Node) -> void`
  - `_set_ui_manager(ui_manager: Node) -> void`

**BetweenMissionScreen** (`res://ui/between_mission_screen.gd`) — Prompt 14
- Panel helpers used by hub focus routing:
  - `open_shop_panel() -> void`
  - `open_research_panel() -> void`
  - `open_enchant_panel() -> void` (routes to ResearchTab in MVP)
  - `open_mercenary_panel() -> void` (routes to MercenariesTab in current MVP scene)

**UIManager** (`res://ui/ui_manager.gd`) — Prompt 14
- New dialogue helpers:
  - `show_dialogue(display_name: String, entry: DialogueEntry) -> void` (routes to DialoguePanel)
  - `clear_dialogue() -> void` (hides DialoguePanel)
- Hub integration:
  - Shows `Hub2DHub` when entering `Types.GameState.BETWEEN_MISSIONS`
  - Closes Hub + clears dialogue when leaving `BETWEEN_MISSIONS`

**AllyBase** (`res://scenes/allies/ally_base.gd` / `ally_base.tscn`) — Prompt 11 + Audit 6 Group 4

- `initialize_ally_data(p_ally_data: Variant) -> void` — HP reset, shapes from `attack_range`, emits `ally_spawned`.
- `find_target() -> EnemyBase` — filters by `can_target_flying`; scores by `preferred_targeting` (`Types.TargetPriority`: CLOSEST, LOWEST_HP, HIGHEST_HP, FLYING_FIRST).
- `_perform_attack_on_target` — `EnemyBase.take_damage` (direct damage; POST-MVP projectiles).
- Death: if `uses_downed_recovering`, DOWNED for `recovery_time` → RECOVERING (full heal) → IDLE with `ally_downed` / `ally_recovered`; else `ally_killed` + `queue_free()`.

**CampaignManager** — Prompt 11 roster arrays + **Prompt 12**: `owned_allies` / `active_allies_for_next_day` / `max_active_allies_per_day`; `mercenary_catalog` export; `is_ally_owned`, `get_owned_allies`, `get_active_allies`, `add_ally_to_roster`, `remove_ally_from_roster`, `toggle_ally_active`, `set_active_allies_from_list`, `get_allies_for_mission_start`; `generate_offers_for_day`, `preview_mercenary_offers_for_day`, `get_current_offers`, `purchase_mercenary_offer`; `notify_mini_boss_defeated`, `register_mini_boss`, `auto_select_best_allies`; legacy `current_ally_roster` sync for spawn; `has_ally`, `get_ally_data`, `reinitialize_ally_roster_for_test()`.

**SimBot** — Prompt 12: `activate(strategy: Types.StrategyProfile)`, `decide_mercenaries()`, `get_log()`.

- WeaponData Phase 2 additions:
  - `assist_angle_degrees: float`
  - `assist_max_distance: float`
  - `base_miss_chance: float`
  - `max_miss_angle_degrees: float`
  - All default to `0.0` (MVP behavior preserved until tuned in `.tres` data).
TYPES ENUMS (res://scripts/types.gd)

GameState, DamageType, ArmorType, BuildingType, ArnulfState, ResourceType, EnemyType, **AllyClass**, **HubRole**, WeaponSlot, TargetPriority (buildings + allies; includes **LOWEST_HP** for ally pick-lowest-HP mode).
GAME FLOW, SIGNAL FLOW, POST-MVP STUB INVENTORY

These sections describe the complete main-menu → mission → between-mission → end-screen loop, the major signal chains (enemy dies, tower dies, wave clears, research unlock, build mode, etc.), and which hooks exist but are not yet used (building_destroyed, DoT, SimBot profiles, etc.).

(Full text omitted here for brevity since you already have it above; content is identical to what I wrote into the index file.)

2026-03-24 UPDATE NOTE

- `InputManager` build-mode left click now does a physics raycast against hex-slot layer (7) and routes to `BuildMenu` placement/sell entrypoints based on `HexGrid.get_slot_data(slot_index).is_occupied`.
- `BuildMenu` public API now includes:
  - `open_for_slot(slot_index: int) -> void`
  - `open_for_sell_slot(slot_index: int, slot_data: Dictionary) -> void`
- `BuildMenu` scene now contains a dedicated sell panel (`BuildingNameLabel`, `UpgradeStatusLabel`, `RefundLabel`, `SellButton`, `CancelButton`).
- `HexGrid._on_hex_slot_input(...)` no longer opens BuildMenu directly; it only updates slot highlight while in build mode.
- `test_hex_grid.gd` includes direct sell-flow coverage for refund amounts, slot-empty postcondition, and `building_sold` emission.
- See `docs/PROMPT_1_IMPLEMENTATION.md` for implementation-specific details.
- Added manual-shot firing assist/miss logic in `Tower` private helper path without public API signature changes.
- `crossbow.tres` now carries initial Phase 2 tuning defaults; `rapid_missile.tres` remains deterministic (`0.0` assist/miss values).
- Added simulation API tests for assist disabled path, cone snapping, guaranteed miss perturbation, autofire bypass, and crossbow defaults loading.
- See `docs/PROMPT_2_IMPLEMENTATION.md` for full Phase 2 implementation and test notes.
- Added deterministic weapon-upgrade station Phase 3:
  - New resource class: `res://scripts/resources/weapon_level_data.gd`
  - New scene manager: `res://scripts/weapon_upgrade_manager.gd` under `/root/Main/Managers/WeaponUpgradeManager`
  - New resource set: `res://resources/weapon_level_data/{crossbow,rapid_missile}_level_{1..3}.tres`
  - New SignalBus signal: `weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)`
  - `Tower` now composes effective weapon stats from WeaponUpgradeManager with null fallback to raw WeaponData
  - `BetweenMissionScreen` now has a Weapons tab and upgrade UI refresh logic
  - Added tests in `res://tests/test_weapon_upgrade_manager.gd` and a tower fallback regression in `res://tests/test_simulation_api.gd`
  - See `docs/PROMPT_3_IMPLEMENTATION.md` for full implementation notes.
- Added two-slot enchantment system Phase 4:
  - New autoload `EnchantmentManager` at `res://autoloads/enchantment_manager.gd`
  - New resource class `EnchantmentData` at `res://scripts/resources/enchantment_data.gd`
  - New resources in `res://resources/enchantments/`
  - New SignalBus events:
    - `enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)`
    - `enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)`
  - `Tower` now layers enchantment multipliers/overrides from `"elemental"` + `"power"` slots before spawning projectiles.
  - `ProjectileBase.initialize_from_weapon(...)` accepts optional custom damage + damage type while preserving old call behavior.
  - `GameManager.start_new_game()` now resets enchantments.
  - `BetweenMissionScreen` Weapons tab now includes enchantment apply/remove UI controls.
  - Added tests:
    - `res://tests/test_enchantment_manager.gd`
    - `res://tests/test_tower_enchantments.gd`
    - projectile regression in `res://tests/test_projectile_system.gd`
- Added Phase 5 DoT system:
  - `EnemyBase` now exposes `apply_dot_effect(effect_data: Dictionary) -> void`.
  - Enemy-local `active_status_effects` tracks burn/poison status with stack-aware rules.
  - `BuildingData` exports now include:
    - `dot_enabled`, `dot_total_damage`, `dot_tick_interval`, `dot_duration`
    - `dot_effect_type`, `dot_source_id`, `dot_in_addition_to_hit`
  - `ProjectileBase.initialize_from_building(...)` now accepts DoT parameters and applies status effects on hit.
  - Tuned resources:
    - `res://resources/building_data/fire_brazier.tres`
    - `res://resources/building_data/poison_vat.tres`
  - Added tests:
    - `res://tests/test_enemy_dot_system.gd`
    - DoT integration assertions in `res://tests/test_projectile_system.gd`

## 2026-03-24 Prompt 8 delta (territory + world map + 50-day data)

- Resource classes:
  - `res://scripts/resources/territory_data.gd` (`TerritoryData`) — territory_id, display, terrain enum, ownership, end-of-day gold bonuses, POST-MVP hooks.
  - `res://scripts/resources/territory_map_data.gd` (`TerritoryMapData`) — `territories[]`, lookups by id, `invalidate_cache()`.
- `DayConfig`: added `mission_index` (maps day → MVP mission 1–5).
- `CampaignConfig`: added `territory_map_resource_path` (optional).
- Data instances:
  - `res://resources/territories/main_campaign_territories.tres`
  - `res://resources/campaign_main_50days.tres` (50 linear days; canonical path for Prompt 8 tests and `GameManager.MAIN_CAMPAIGN_CONFIG_PATH`).
- `SignalBus` (`res://autoloads/signal_bus.gd`):
  - `territory_state_changed(territory_id: String)`
  - `world_map_updated()`
- `GameManager` (`res://autoloads/game_manager.gd`):
  - `territory_map: TerritoryMapData`, `reload_territory_map_from_active_campaign()`, territory helpers (`get_current_day_index`, `get_day_config_for_index`, `get_*_territory*`, `get_all_territories`, `get_current_territory_gold_modifiers`, `apply_day_result_to_territory`).
  - End-of-mission gold applies territory flat + percent bonuses (all active territories).
  - Campaign win: last day uses `completed_day_index == campaign_len` **before** `mission_won` emission (CampaignManager advances day on `mission_won`).
- `CampaignManager._set_campaign_config` triggers `GameManager.reload_territory_map_from_active_campaign()`.
- UI: `res://ui/world_map.gd`, `res://ui/world_map.tscn` (`WorldMap`); embedded in `res://ui/between_mission_screen.tscn` as first `TabContainer` tab (`MapTab`).
- Tests: `test_territory_data.gd`, `test_campaign_territory_mapping.gd`, `test_campaign_territory_updates.gd`, `test_territory_economy_bonuses.gd`, `test_world_map_ui.gd`; plus `test_game_manager.gd` updates for campaign/day flow.
- See `docs/PROMPT_8_IMPLEMENTATION.md`.

## 2026-03-24 Prompt 10 delta (mini-boss + campaign boss)

- **Implementation notes**: `docs/PROMPT_10_IMPLEMENTATION.md`.
- **Resources**: `BossData`; `res://resources/bossdata_plague_cult_miniboss.tres`, `bossdata_orc_warlord_miniboss.tres`, `bossdata_final_boss.tres`; scene `res://scenes/bosses/boss_base.tscn`.
- **DayConfig** (`res://scripts/resources/day_config.gd`): `is_mini_boss`, `boss_id`, `is_boss_attack_day` (plus existing `is_mini_boss_day`, `is_final_boss`).
- **CampaignConfig**: `starting_territory_ids`.
- **TerritoryData**: `is_secured`, `has_boss_threat`.
- **SignalBus**: `boss_spawned`, `boss_killed`, `campaign_boss_attempted`.
- **WaveManager**: `boss_registry`, `set_day_context(day_config, faction_data)`, `ensure_boss_registry_loaded()`; `_spawn_boss_wave` on configured wave index; escort resolution uses enum key strings.
- **GameManager**: final-boss tracking, `get_day_config_for_index` (match `day_index` then fallback index, synthetic day), `prepare_next_campaign_day_if_needed`, `advance_to_next_day`, mini-boss kill → territory `is_secured` hook, final-boss fail skips permanent territory loss (MVP).
- **CampaignManager**: `start_next_day` calls `GameManager.prepare_next_campaign_day_if_needed()`; win path respects `GameManager.final_boss_defeated`.
- **Tests**: `res://tests/test_boss_data.gd`, `test_boss_base.gd`, `test_boss_waves.gd`, `test_final_boss_day.gd`; `test_wave_manager.gd` (`test_regular_day_spawns_no_bosses`). **Confirm** full suite with `./tools/run_gdunit.sh`.

## 2026-03-24 Prompt 10 fixes delta (GdUnit / WaveManager harness)

- See **`docs/PROMPT_10_FIXES.md`**.
- **`WaveManager`** (`res://scripts/wave_manager.gd`): `_enemy_container` and `_spawn_points` use **`get_node_or_null("/root/Main/...")`**; **`_spawn_wave`** / **`_spawn_boss_wave`** return if either is null.
- **`test_wave_manager.gd`**, **`test_boss_waves.gd`**: add **`SpawnPoints`** to the test tree before **`Marker3D`** children and **`global_position`**; assign **`wm._enemy_container`** / **`wm._spawn_points`** after **`add_child(wm)`**.
- **`GameManager`** (`res://autoloads/game_manager.gd`): **`_begin_mission_wave_sequence()`** walks **`Main` → `Managers` → `WaveManager`** with **`get_node_or_null`**; missing **`Main`**, **`Managers`**, or **`WaveManager`** → **`push_warning`** + return (no asserts; GdUnit-safe). Full **`main.tscn`** loads unchanged; **`test_game_manager.gd`** includes **`test_begin_mission_wave_sequence_skips_gracefully_without_main_scene`**.
- **`project.godot`**: **`CampaignManager`** autoload **before** **`GameManager`** so **`mission_won`** listeners run day increment before hub transition.
- **`test_campaign_manager.gd`**: **`test_day_fail_repeats_same_day`** uses **`mission_failed.emit(CampaignManager.get_current_day())`** when **`GameManager.get_current_mission()`** can lag **`current_day`**.
- **`docs/PROBLEM_REPORT.md`**: file paths + log/GdUnit snippets for the above.

## 2026-03-25 Prompt 15 delta (Florence meta-state + day progression)

- Added `res://scripts/florence_data.gd` (`class_name FlorenceData`) to store run meta-state.
- Updated `res://scripts/types.gd`:
  - Added `enum DayAdvanceReason`
  - Added `Types.get_day_advance_priority(reason)` helper.
- Updated `res://autoloads/signal_bus.gd`: added `SignalBus.florence_state_changed()`.
- Updated `res://autoloads/game_manager.gd`:
  - Added Florence ownership (`florence_data`) + meta day counter (`current_day`).
  - Added `advance_day()` and `_apply_pending_day_advance_if_any()`.
  - Mission win/fail hooks increment Florence counters.
  - Incremented `florence_data.run_count` on final `GAME_WON`.
  - Added `get_florence_data()`.
- Updated `res://scripts/research_manager.gd` and `res://scripts/shop_manager.gd` with Florence unlock hooks.
- Updated `res://ui/between_mission_screen.tscn` and `res://ui/between_mission_screen.gd`:
  - Added `FlorenceDebugLabel`
  - Refreshes on `SignalBus.florence_state_changed`.
- Updated `res://autoloads/dialogue_manager.gd`:
  - Resolves `florence.*` and `campaign.*` condition keys.
- Added `res://tests/test_florence.gd` and included it in `./tools/run_gdunit_quick.sh`.
- Follow-up parse-safety fixes: removed invalid enum cast in `GameManager.advance_day()` and avoided `: FlorenceData` local type annotations in tests/UI.
