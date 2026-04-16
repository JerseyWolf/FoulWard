# DELIVERABLE A — Error/Fix List with Sonnet Prompts

Generated: 2026-04-14 | Auditor: Opus 4.6 (Prompt 1 Plan session)

---

## Summary of Findings

Cross-referencing `IMPROVEMENTS_TO_BE_DONE.md` (Prompt 26/28), `docs/COMPLIANCE_REPORT_MASTER.md` (H1–H5), and a full codebase scan against the repo as of 2026-04-14:

| Original Improvement Item | Status |
|---------------------------|--------|
| Assert-to-guard conversion (all production .gd) | **ALREADY FIXED** (Prompt 27) — zero `assert(` in production code |
| Bare `get_node()` → `get_node_or_null()` | **ALREADY FIXED** (Prompt 27) — zero bare `get_node(` in production code |
| `EconomyManager._process` → `_physics_process` | **ALREADY FIXED** — uses `_physics_process` at line 52 |
| `weapon_upgrade_manager` unchecked `spend_gold` | **ALREADY FIXED** — return value checked at lines 72–75 |
| `AutoTestDriver` `print()` → `printerr()` | **ALREADY FIXED** — no `print(` calls remain |
| Root-level AUDIT_IMPLEMENTATION_*.md files | **ALREADY DELETED** |
| `place_building_shop_free` skips build phase guard | **INTENTIONAL** — comment at lines 111–112 documents shop voucher bypass |
| WaveManager/HexGrid `add_child` before `initialize` | **INTENTIONAL** — AP-06 exception documented in comments at each site |

**Remaining issues: 5 batches with actionable work.**

- Batch 1: Signal routing + connect guards (~10 files)
- Batch 2: Test isolation + orphan node fixes (~38 test files)
- Batch 3: Documentation stale references (3 active docs)
- Batch 4: Housekeeping — dead files + orphaned enum (~8 files)
- Batch 5: Long function extraction (LOW priority, ~7 files)

---

## Batch 1 — Signal Routing & Connect Guards

### Issue Summary

1. `DialogueManager` declares `dialogue_line_finished` and `dialogue_line_started` as **local signals** (lines 40–41) and emits them directly (lines 213, 236). `UIManager` connects to `DialogueManager.dialogue_line_finished` directly (line 57) instead of via SignalBus. This violates the rule that ALL cross-system events go through SignalBus.

2. ~10 files call `.connect()` in `_ready()` or `_connect_signals()` without `is_connected` guards. The project convention (per `CombatStatsTracker` and `NavMeshManager`) is to guard every connect.

3. Five SignalBus signals are declared but never emitted anywhere in game code. They should have documentation comments marking them as POST-MVP stubs.

### Sonnet Prompt

```
READ FIRST: autoloads/signal_bus.gd, autoloads/dialogue_manager.gd, ui/ui_manager.gd

TASK A — Route dialogue signals through SignalBus:

1. autoloads/signal_bus.gd: Add two new signal declarations between line 141 (campaign_completed) and line 143 (build mode section). Add a section header and the two signals:

   @warning_ignore("unused_signal")
   signal dialogue_line_started(entry_id: String, character_id: String)
   @warning_ignore("unused_signal")
   signal dialogue_line_finished(entry_id: String, character_id: String)

2. autoloads/dialogue_manager.gd:
   - Lines 40–41: Remove the local signal declarations (signal dialogue_line_started, signal dialogue_line_finished). Replace with comments pointing to SignalBus.
   - Line 213: Change `dialogue_line_started.emit(entry_id, entry.character_id)` → `SignalBus.dialogue_line_started.emit(entry_id, entry.character_id)`
   - Line 236: Change `dialogue_line_finished.emit(entry_id, character_id)` → `SignalBus.dialogue_line_finished.emit(entry_id, character_id)`

3. ui/ui_manager.gd:
   - Line 57: Change `DialogueManager.dialogue_line_finished.connect(_on_dialogue_line_finished)` → wrap with is_connected guard and route through SignalBus:
     if not SignalBus.dialogue_line_finished.is_connected(_on_dialogue_line_finished):
         SignalBus.dialogue_line_finished.connect(_on_dialogue_line_finished)

4. tests/test_character_hub.gd: Search for "dialogue_line_finished" — update signal monitor from `DialogueManager` to `SignalBus` if the test monitors DialogueManager directly.

TASK B — Add is_connected guards to all _ready() and _connect_signals() connect calls:

For EACH file below, wrap every bare .connect() inside _ready() or _connect_signals() with an is_connected guard. Use this exact pattern:

   if not SignalBus.<signal_name>.is_connected(<callback>):
       SignalBus.<signal_name>.connect(<callback>)

Files and lines to fix:

- autoloads/game_manager.gd lines 57, 58, 67
- autoloads/campaign_manager.gd lines 59, 60
- autoloads/economy_manager.gd lines 47, 48
- scripts/wave_manager.gd lines 158, 159
- autoloads/auto_test_driver.gd lines 66, 67, 68
- ui/ui_manager.gd line 56 (plus the new SignalBus connect from Task A)
- autoloads/dialogue_manager.gd lines 135, 136, 137, 138, 139, 140, 141, 142, 143

TASK C — Document orphaned SignalBus signals:

In autoloads/signal_bus.gd, add a comment above each of these signals explaining they are POST-MVP stubs not yet emitted:
- Line 44: ally_state_changed — add: ## POST-MVP: not yet emitted. Will be emitted from AllyBase._transition_state() when ally state tracking is implemented.
- Line 86: terrain_prop_destroyed — add: ## POST-MVP: not yet emitted. Reserved for destructible terrain props.
- Line 88: nav_mesh_rebake_requested — add: ## POST-MVP: connected in NavMeshManager but never emitted. Will be emitted from terrain/build flows.
- Line 102: florence_damaged — add: ## POST-MVP: connected in CombatStatsTracker but not yet emitted from game code. EnemyBase attack flow should emit this.
- Line 105: building_destroyed — add: ## POST-MVP: not yet emitted. Requires building HP/destruction system.

NO other changes. Do not refactor, rename, or reorganize anything.

Run: ./tools/run_gdunit_parallel.sh
Expected: All tests pass. If any fail, fix them before continuing.

Write summary to docs/BATCH_1_REPORT.md — list every file changed, every connect guarded, signal routing changes, test results.
```

---

## Batch 2 — Test Isolation & Orphan Node Fixes

### Issue Summary

38 test files lack `reset_to_defaults()` or `before_test()` cleanup. Integration tests that instantiate scenes don't always `queue_free()` in `after_test()`, causing orphan node leaks (17 orphans in full suite at last count, reduced to 2–6 after Prompt 27/28 fixes).

### Sonnet Prompt

```
READ FIRST: .cursor/skills/testing/SKILL.md

TASK: Add test isolation boilerplate to all test files that lack it.

RULE: Every test file that touches autoload state MUST have a before_test() or before() method that calls reset_to_defaults() on every autoload it uses. Every test file that instantiates scenes MUST have an after_test() or after() method that calls queue_free() on tracked scene references.

STEP 1 — Audit every test file under tests/ and tests/unit/ for:
  a) Missing before_test() / before() with reset_to_defaults() calls
  b) Missing after_test() / after() with queue_free() calls for scene instances
  c) Scene instances stored in class-level vars that are not freed

For each file, determine which autoloads it touches. Common patterns:
  - EconomyManager → EconomyManager.reset_to_defaults()
  - GameManager → GameManager.reset_to_defaults() if it has one; otherwise reset relevant state
  - CampaignManager → CampaignManager.reset_to_defaults() if it has one
  - EnchantmentManager → EnchantmentManager.reset_to_defaults()
  - BuildPhaseManager → BuildPhaseManager.set_build_phase_active(true) (test default)

STEP 2 — For each file that needs fixes:
  - Add before_test() calling the relevant reset methods
  - Add after_test() freeing any scene instances
  - If the file already has before_test() but is missing some resets, add them
  - Do NOT change test logic, only add isolation boilerplate

STEP 3 — Focus on these known orphan-leak culprits first:
  - tests/test_wave_manager.gd
  - tests/test_hex_grid.gd
  - tests/test_projectile_system.gd
  - tests/test_building_base.gd
  - tests/test_ally_base.gd
  - tests/test_enemy_pathfinding.gd
  - tests/test_ally_combat.gd
  - tests/test_ally_signals.gd
  - tests/test_ally_spawning.gd
  - tests/test_boss_base.gd
  - tests/test_boss_waves.gd
  - tests/test_arnulf_state_machine.gd

For each, ensure all instantiated scene nodes (enemies, buildings, allies, projectiles, hex grid, tower, arnulf) are freed in after_test().

NO other changes. Do not refactor test logic, rename tests, or add new test cases.

Run: ./tools/run_gdunit.sh (full sequential — baseline for orphan count)
Expected: All tests pass. Orphan count should be 0 or near 0. If any fail, fix them.

Write summary to docs/BATCH_2_REPORT.md — list every file changed, what was added (before_test/after_test), orphan count before and after, test results.
```

---

## Batch 3 — Documentation: Stale References

### Issue Summary

`DamageCalculator` was migrated from GDScript (`damage_calculator.gd`) to C# (`DamageCalculator.cs`) but several active documentation files still reference the old `.gd` path. Archived docs are snapshots and should not be changed.

### Sonnet Prompt

```
READ FIRST: docs/CONVENTIONS.md, docs/ARCHITECTURE.md, docs/INDEX_FULL.md

TASK: Fix stale DamageCalculator path references in active documentation files.

The autoload DamageCalculator is now implemented in C# at res://autoloads/DamageCalculator.cs (not the old res://autoloads/damage_calculator.gd which no longer exists).

Fix these specific locations:

1. docs/CONVENTIONS.md line 692:
   Change: | `res://autoloads/damage_calculator.gd` | `DamageCalculator` |
   To:     | `res://autoloads/DamageCalculator.cs` | `DamageCalculator` |

2. docs/ARCHITECTURE.md line 15:
   Change: | 3  | `res://autoloads/damage_calculator.gd`   | `DamageCalculator` | Stateless damage multiplier lookups      |
   To:     | 3  | `res://autoloads/DamageCalculator.cs`     | `DamageCalculator` | Stateless damage multiplier lookups (C#) |

3. docs/INDEX_FULL.md line 264:
   Change: Path: res://autoloads/damage_calculator.gd
   To:     Path: res://autoloads/DamageCalculator.cs

   Also update the description at that location to note it is a C# implementation.

DO NOT change any files under docs/archived/ — those are historical snapshots.
DO NOT change REPO_DUMP_*.md files — those are historical dumps.

Run: grep -rn "damage_calculator\.gd" docs/CONVENTIONS.md docs/ARCHITECTURE.md docs/INDEX_FULL.md
Expected: 0 matches. If any remain, fix them.

Write summary to docs/BATCH_3_REPORT.md — list every file changed, every line updated, verification results.
```

---

## Batch 4 — Housekeeping: Dead Files & Orphaned Enums

### Issue Summary

1. Four legacy dialogue UI files exist but are never loaded at runtime (DialoguePanel replaced them). Safe to delete after removing doc references.
2. `scripts/simbot_logger.gd` defines `SimBotLogger` class — never referenced anywhere. `sim_bot.gd` has its own inline CSV helpers.
3. `scripts/resources/test_strategyprofileconfig.gd` defines `TestStrategyProfileConfig` — never referenced anywhere.
4. `Types.AllyRole.TANK` (line 177 in types.gd, line 196 in FoulWardTypes.cs) — never used in any code.

### Sonnet Prompt

```
READ FIRST: scripts/types.gd (lines 174-180), ui/dialogueui.gd, ui/dialogue_ui.gd

TASK: Remove orphaned files and enum values.

STEP 1 — Delete legacy dialogue UI files:
  - ui/dialogueui.gd
  - ui/dialogueui.tscn
  - ui/dialogue_ui.gd
  - ui/dialogue_ui.tscn

  Before deleting, verify zero runtime references:
  - Search all .gd and .tscn files for "dialogueui" and "dialogue_ui" (case-insensitive)
  - Exclude docs/ and .md files from this search
  - If any runtime .gd or .tscn file loads or references these, do NOT delete and report the reference instead

  After deleting, remove corresponding .uid files if they exist:
  - ui/dialogueui.gd.uid
  - ui/dialogue_ui.gd.uid

STEP 2 — Delete orphaned scripts:
  - scripts/simbot_logger.gd (and scripts/simbot_logger.gd.uid if exists)
  - scripts/resources/test_strategyprofileconfig.gd (and .uid if exists)

  Before deleting each, verify no .gd file references the class_name:
  - Search for "SimBotLogger" in all .gd files
  - Search for "TestStrategyProfileConfig" in all .gd files
  - If any references found, do NOT delete and report instead

STEP 3 — Remove orphaned enum value:
  - scripts/types.gd line 177: Remove the `TANK,` line from the AllyRole enum
  - scripts/FoulWardTypes.cs line 196: Remove the `Tank = 3,` line from the AllyRole enum
  - After removing TANK, update the integer values in FoulWardTypes.cs so SPELL_SUPPORT becomes 3 (was 4)

  Before removing, verify TANK is not referenced:
  - Search for "AllyRole.TANK" and "AllyRole.Tank" in all .gd and .cs files
  - Search for ".TANK" in all .tres files under resources/
  - If any references found, do NOT remove and report instead

STEP 4 — Update docs/INDEX_SHORT.md:
  - Remove the line referencing "DialogueUI res://ui/dialogueui.gd" or "dialogue_ui.gd" (Legacy placeholder hub dialogue panel)
  - Remove any line referencing simbot_logger.gd
  - Remove any line referencing test_strategyprofileconfig.gd

STEP 5 — Update docs/INDEX_FULL.md:
  - Remove entries for the deleted files (dialogueui.gd, dialogue_ui.gd, simbot_logger.gd, test_strategyprofileconfig.gd)

NO other changes. Do not refactor, rename, or reorganize anything else.

Run: dotnet build FoulWard.csproj && ./tools/run_gdunit_parallel.sh
Expected: C# build succeeds. All tests pass. If any fail due to removed files, fix references.

Write summary to docs/BATCH_4_REPORT.md — list every file deleted, every enum value removed, every doc updated, test results.
```

---

## Batch 5 — Long Function Extraction (LOW priority)

### Issue Summary

Seven long functions (48–69 lines) identified across the codebase. These are functional but harder to maintain. Extract helpers only if doing so improves readability without changing behavior.

**Only execute this batch if all prior batches are complete and passing.**

### Sonnet Prompt

```
READ FIRST: scripts/sim_bot.gd, scripts/input_manager.gd, autoloads/campaign_manager.gd, scenes/enemies/enemy_base.gd, scenes/tower/tower.gd, scenes/hex_grid/hex_grid.gd

TASK: Extract helper functions from long methods. Each extraction must be pure refactoring — identical behavior, no logic changes.

1. scripts/sim_bot.gd — _choose_build_or_upgrade_action (~69 lines):
   Extract the build-priority scan loop into a new private method:
   func _collect_weighted_build_entries() -> Array[Dictionary]
   The main function calls the helper and iterates the result.

2. scripts/input_manager.gd — _unhandled_input (~63 lines):
   Extract three helpers:
   func _handle_mouse_combat(event: InputEventMouseButton) -> void
   func _handle_spell_keybinds(event: InputEvent) -> void
   func _handle_build_mode_keys(event: InputEvent) -> void
   The main function dispatches to helpers based on event type and game state.

3. autoloads/campaign_manager.gd — auto_select_best_allies (~66 lines):
   Extract the sort comparator and greedy fill loop:
   func _sort_offers_by_value(offers: Array) -> Array
   func _greedy_fill_roster(sorted_offers: Array, budget: Dictionary, max_count: int) -> Dictionary

4. autoloads/campaign_manager.gd — restore_from_save (~54 lines):
   Extract per-domain restore helpers:
   func _apply_campaign_from_dict(data: Dictionary) -> void
   func _apply_roster_from_dict(data: Dictionary) -> void
   func _apply_offers_from_dict(data: Dictionary) -> void

5. scenes/enemies/enemy_base.gd — _update_status_effects (~55 lines):
   Extract:
   func _tick_dot_effects(delta: float) -> void
   func _cleanup_expired_effects() -> void

6. scenes/tower/tower.gd — _apply_auto_aim (~48 lines):
   Extract the cone search:
   func _find_assist_target(origin: Vector3, direction: Vector3, weapon_data: WeaponData) -> Node3D

7. scenes/hex_grid/hex_grid.gd — _try_place_building (~58 lines):
   Split into validation and instantiation:
   func _validate_placement(slot_index: int, building_type: Types.BuildingType) -> bool
   func _instantiate_and_place(slot_index: int, building_type: Types.BuildingType, charge_economy: bool) -> bool

For ALL extractions:
- Use static typing on all parameters and returns
- Preserve all existing comments
- Do not change any behavior — pure structural refactoring
- Run tests after each file is modified to catch regressions immediately

Run: ./tools/run_gdunit.sh
Expected: All tests pass with identical results to before.

Write summary to docs/BATCH_5_REPORT.md — list every function extracted, before/after line counts, test results.
```

---

## Execution Order

1. **Batch 1** (Signal routing) — do first, touches SignalBus which many tests depend on
2. **Batch 3** (Documentation) — independent, can run parallel with Batch 1
3. **Batch 4** (Housekeeping) — independent, can run parallel with Batch 1
4. **Batch 2** (Test isolation) — do after Batch 1 since signal changes may affect test monitors
5. **Batch 5** (Long functions) — do last, lowest priority, only if time permits

**Dependency constraint:** Batch 1 must complete before Batch 2 because the `dialogue_line_finished` signal routing change in Batch 1 affects `test_character_hub.gd` signal monitors.

---

## Appendix: Issues Confirmed Already Fixed

| Issue | Fixed In | Evidence |
|-------|----------|----------|
| `assert()` in production .gd files | Prompt 27 | Full codebase scan: 0 matches outside addons/ and tests/ |
| Bare `get_node()` in production .gd | Prompt 27 | Full codebase scan: 0 matches outside addons/ |
| `EconomyManager._process` → `_physics_process` | Pre-existing | Line 52: `func _physics_process(delta: float) -> void:` |
| `weapon_upgrade_manager` spend check | Pre-existing | Lines 72–75: return value checked with `if not spent_gold` guard |
| `AutoTestDriver` print → printerr | Pre-existing | 0 `print(` calls in file |
| Root-level AUDIT_IMPLEMENTATION_*.md | Pre-existing | 0 files found |
| `place_building_shop_free` build phase | By-design | Comment at lines 111–112: shop voucher intentionally bypasses guard |
| WaveManager/HexGrid init ordering | By-design | AP-06 exception comments at each `add_child` site |
| `CampaignManager.current_day` direct mutation | Prompt I-E | `force_set_day()` method; AGENTS.md gotcha 7 documents mitigation |
| AllyData `.get()` dictionary access | Prompt I-E | Typed field access in campaign_manager.gd |
