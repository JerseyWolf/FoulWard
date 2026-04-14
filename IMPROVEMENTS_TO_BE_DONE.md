# FOUL WARD — Improvement Backlog
Generated: 2026-03-28 | Auditor: Opus 4.6 (Prompt 26) | Prompt 28 refresh: 535 cases, 0 failures, 2 orphans (full), 1 orphan (quick)

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
| `run_gdunit.sh` (full) | 59 | 535 | 0 | 2 | ~4m 23s |
| `run_gdunit_quick.sh` (quick) | 39 | 347 | 0 | 1 | ~1m 49s |

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
| test_relationship_manager_tiers.gd | Unit | Tier boundaries + signal deltas |
| test_save_manager_slots.gd | Unit | Slot ring + attempt isolation + RM JSON |
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
| `scripts/wave_manager.gd` | Long function | 469–551 | `_spawn_wave` is 82 lines — **Status: FIXED** — extracted to `WaveCompositionHelper.cs` (Phase 2B) | Medium (resolved) | Extract roster spawn loop (509–542) to `_spawn_enemies_for_roster(roster, wave_number, total)` |
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
All 55 files from `docs/archived/PROMPT_26_PRE_INDEX_DIFF.txt` are legitimate files that need INDEX_SHORT.md entries. Key categories:
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
| P10 | Full test suite not run | COMPLETED (Prompt 28: 535 pass, `./tools/run_gdunit.sh`) |
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
| `dialogue_manager.gd` | `_on_resource_changed` … `_on_spell_cast` | **DONE (Prompt 28)** | Internal tracking + getters; covered by `tests/test_dialogue_manager.gd`. |
| `wave_manager.gd` | `_on_game_state_changed` | **DONE (Prompt 28)** | Pauses inter-wave countdown in `BUILD_MODE`; `tests/test_wave_manager.gd`. |

### Orphaned Enum Values

| Enum | Value | Classification |
|------|-------|---------------|
| `Types.AllyRole.TANK` | Only in types.gd, never used | OBSOLETE — remove or implement tank role in AllyBase targeting |

### Specific System Audits

| System | Finding | Status |
|--------|---------|--------|
| `SettingsManager.set_graphics_quality()` | Stores string in config, not wired to Godot rendering APIs | READY — add `RenderingServer` calls for shadow quality, MSAA, etc. based on quality string |
| `SimBot._on_wave_cleared()` difficulty exit | `compute_difficulty_fit()` returns 0.0 when batch log is empty; `is_equal_approx(..., 1.0)` is never true | BLOCKED — effectively unreachable in interactive SimBot flow; only meaningful after prior batch data |
| `SaveManager` save/load pipeline | Works via `_build_save_payload()` / `_apply_save_payload()` calling per-autoload `get_save_data()` / `restore_from_save()` | **RelationshipManager wired** (Prompt 22+); rolling slots + attempt dirs — `tests/test_save_manager_slots.gd` |
| Art icon PNGs | `res://art/icons/` directories exist but contain no actual PNG files | BLOCKED — requires `tools/generate_placeholder_icons.gd` to be run via Project menu or script |

---

## 7. Direct Fixes Applied

| Fix | File(s) | Description |
|-----|---------|-------------|
| 7a | `docs/INDEX_SHORT.md` | Added 55 unindexed files to the test files section |
| 7e | `tools/run_gdunit_visible.sh` | Verified exists and is correct (created by Sonnet pre-pass) |
| 7f | `AGENTS.md` (repo root) | Created authoritative standing orders document |
| Log | `docs/archived/PROMPT_26_IMPLEMENTATION.md` | Session log with all audit findings |
| Prompt 28 | `docs/archived/PROMPT_28_IMPLEMENTATION.md` | Tier/slots tests, DialogueManager/WaveManager stubs, test harness fixes; INDEX + metrics refresh |

---

## Appendix A: Orphaned / Redundant Files (DELETE / MERGE / KEEP)

| File | Decision | Reason |
|------|----------|--------|
| `ui/dialogueui.gd` + `ui/dialogueui.tscn` | MERGE/DELETE | Legacy placeholder; `DialoguePanel` is the active replacement. Remove after confirming no runtime references remain. |
| `scripts/resources/test_strategyprofileconfig.gd` | KEEP | Test helper resource class used by SimBot test suites |
| `scripts/resources/strategyprofileconfig.gd` | KEEP | Active resource wrapper for strategy profile loading |
| `scripts/simbot_logger.gd` | KEEP | SimBot CSV logging utility actively used by `sim_bot.gd` |
| `AUDIT_IMPLEMENTATION_AUDIT_6.md` | DELETE | Content merged into `docs/archived/ALL_AUDITS.md` — root-level copy is redundant |
| `AUDIT_IMPLEMENTATION_UPDATE.md` | DELETE | Superseded by `docs/archived/ALL_AUDITS.md` |
| `AUDIT_IMPLEMENTATION_TASK.md` | DELETE | Superseded by this file |
| `FUTURE_3D_MODELS_PLAN.md` | KEEP | Active production art roadmap referenced in INDEX_SHORT.md |

## Appendix B: Every TODO/FIXME/HACK (file, line, text, recommendation)

Full scan: 84 items found. See `docs/archived/PROMPT_26_PRE_TODO_LIST.txt` for complete listing.

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
| Save/Load (A6) | SaveManager | Implemented | Rolling autosave with slot management; `RelationshipManager` in payload (Prompt 22+) |
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
