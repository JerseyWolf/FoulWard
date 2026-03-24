# PROMPT_10_FIXES — WaveManager test harness + resource / assertion fixes

Updated: 2026-03-24.

This document records fixes that unblock GdUnit4 and align tests with headless environments. See also **`docs/PROMPT_10_IMPLEMENTATION.md`** for the main Prompt 10 feature work.

---

## 1. `WeaponLevelData` / `.tres` load (test scanner)

**Symptom:** `Cannot get class 'WeaponLevelData'`, broken `crossbow_level_*.tres`, `main.tscn` ext_resource failures.

**Cause:** Root `.tres` used `[gd_resource type="WeaponLevelData"]` instead of the project pattern `type="Resource" script_class="WeaponLevelData"`. Script order was normalized to `class_name` before `extends Resource`.

**Files:** `scripts/resources/weapon_level_data.gd`, `scripts/weapon_upgrade_manager.gd` (class order), all `resources/weapon_level_data/*.tres`.

---

## 2. `test_campaign_manager.gd` GdUnit assertions

**Symptom:** `assert_not_null()` not found on `GdUnitTestSuite`.

**Fix:** `assert_that(x).is_not_null()` (see **`docs/CONVENTIONS.md`** §12).

---

## 3. WaveManager `/root/Main/...` paths in GdUnit (this prompt)

**Symptoms:**

- `Node not found: "/root/Main/EnemyContainer"` when WaveManager runs under the test runner (root is not `Main`).
- `Condition "!is_inside_tree()" is true` at `test_wave_manager.gd` when setting `Marker3D.global_position` before `SpawnPoints` was in the scene tree.

**Part A — `scripts/wave_manager.gd`**

- `_enemy_container` / `_spawn_points` `@onready` paths use **`get_node_or_null("/root/Main/...")`** instead of `get_node(...)`.
- **`_spawn_wave`** and **`_spawn_boss_wave`** return early with a single `push_error` if either reference is null (tests must assign both after `add_child`).

**Part B — `tests/test_wave_manager.gd` and `tests/test_boss_waves.gd`**

- **`add_child(_spawn_points)`** before creating markers and assigning **`global_position`** (markers must be in-tree for valid transforms).
- Build **`WaveManager`**, **`add_child(wm)`**, then assign **`wm._enemy_container`** and **`wm._spawn_points`** (overrides null from `get_node_or_null` after `_ready`).

**Isolation:** Suites that disconnect **`GameManager._on_all_waves_cleared`** for WaveManager-only tests are unchanged (see **`PROMPT_10_IMPLEMENTATION.md`** optional noise reduction).

---

## 4. `GameManager._begin_mission_wave_sequence` — missing WaveManager is non-fatal

**Symptom:** `push_error` / logs like `WaveManager not found at /root/Main/Managers/WaveManager` when running GdUnit suites that call **`GameManager.start_new_game()`** or **`start_mission_for_day()`** without loading **`main.tscn`** (e.g. **`test_enchantment_manager.gd`** — enchantment reset only; waves irrelevant). GdUnit4’s **`GodotGdErrorMonitor`** treats **`push_error`** as a test failure even when the skip is intentional.

**Fix:** **`_begin_mission_wave_sequence()`** resolves **`Main` → `Managers` → `WaveManager`** with **`get_node_or_null`** at each step. If **`Main`**, **`Managers`**, or **`WaveManager`** is absent, **`push_warning`** once (with mission index) and **return** — no asserts, no duplicate prints; warnings still show in the editor/console but do not fail GdUnit. Suites without **`Main`** (e.g. **`test_enchantment_manager.gd`**) only log and skip waves; full runs that load **`main.tscn`** (e.g. **`test_enemy_pathfinding.gd`**) keep normal wave startup.

**Optional test:** **`test_game_manager.gd`** — **`test_begin_mission_wave_sequence_skips_gracefully_without_main_scene`** calls **`GameManager.call("_begin_mission_wave_sequence")`** on the headless tree to lock soft-skip behavior.

---

## 5. `mission_won` → hub state + autoload order + campaign test payload

**Symptoms**

- Tests that emit **`SignalBus.mission_won`** without going through **`all_waves_cleared`** stayed in **`COMBAT`**; GdUnit expected **`BETWEEN_MISSIONS`** (e.g. **`test_campaign_manager.gd`** `test_day_win_advances_day_and_shows_between_day_hub`).
- **`call_deferred`** connect for **`mission_won`** could run **after** first-frame tests, breaking **`test_game_manager.gd`** **`all_waves_cleared`** cases.
- **`test_day_fail_repeats_same_day`**: **`mission_failed.emit(GameManager.get_current_mission())`** could mismatch **`CampaignManager.current_day`** after a prior win, so **`_on_mission_failed`** no-oped and **`failed_attempts_on_current_day`** did not increment.

**Fix**

- **`res://autoloads/game_manager.gd`**: **`_on_mission_won_transition_to_hub(mission_number)`** applies **`GAME_WON`** / **`BETWEEN_MISSIONS`**; **`_on_all_waves_cleared`** emits **`mission_won`** only (no duplicate transition tail). **`_connect_mission_won_transition_to_hub()`** in **`_ready`**.
- **`res://project.godot`**: **`CampaignManager`** immediately before **`GameManager`** so **`CampaignManager._on_mission_won`** is registered **before** **`GameManager`**’s handler (day increments first on emit).
- **`res://tests/test_campaign_manager.gd`**: **`mission_failed.emit(CampaignManager.get_current_day())`** in **`test_day_fail_repeats_same_day`** (comment explains **`GameManager`** mission index lag).

**See also:** **`docs/PROBLEM_REPORT.md`** (verbatim errors and file list).

---

## Verification

- `./tools/run_gdunit.sh` — no `WeaponLevelData` / main.tscn parse errors; WaveManager tests run without `/root/Main` or `is_inside_tree` errors from this setup; enchantment / GameManager tests run without requiring **`/root/Main/Managers/WaveManager`**; campaign + mission hub tests align with **`mission_won`** / **`mission_failed`** payloads.
