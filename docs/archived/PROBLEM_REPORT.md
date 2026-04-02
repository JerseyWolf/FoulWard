# Problem report — GdUnit / GameManager / headless tests (2026-03-24)

This document is for handoff: **files involved**, **symptoms**, and **verbatim or near-verbatim messages** seen in logs or GdUnit HTML reports. Run `./tools/run_gdunit.sh` locally to reproduce; exit code **100** means failures unless your wrapper maps warnings.

---

## 1. GdUnit `GodotGdErrorMonitor` vs intentional `push_error`

**Involved files**

- `res://autoloads/game_manager.gd` — `_begin_mission_wave_sequence()`

**Problem**

GdUnit4 records **`push_error()`** during a test as a failure via **`GodotGdErrorMonitor`**, even when the code path is an expected “soft skip” (no `main.tscn`, no `WaveManager`).

**Typical log / monitor behavior**

- Message text (before fix):  
  `GameManager: WaveManager not found at /root/Main/Managers/WaveManager`
- Stack often includes:  
  `_begin_mission_wave_sequence` ← `start_mission_for_day` / `start_new_game` / tests such as `test_enchantment_manager.gd`

**Resolution (in repo)**

Use **`push_warning()`** for missing **`Main` / `Managers` / `WaveManager`** in `_begin_mission_wave_sequence` so the skip stays visible in the console but does not trip the error monitor.

---

## 2. `mission_won` hub transition and signal order

**Involved files**

- `res://autoloads/game_manager.gd` — `_connect_mission_won_transition_to_hub`, `_on_mission_won_transition_to_hub`, `_on_all_waves_cleared`
- `res://project.godot` — autoload order: **`CampaignManager` before `GameManager`**

**Problem**

Post–mission UI state (**`Types.GameState.BETWEEN_MISSIONS`** / **`GAME_WON`**) was only applied at the end of **`_on_all_waves_cleared`**. Tests and flows that emit **`SignalBus.mission_won`** directly (without clearing all waves) never transitioned out of **`COMBAT`**.

A **deferred** connect for `mission_won` was also unsafe: first-frame tests could run **`all_waves_cleared`** before the handler existed.

**Typical GdUnit failure (HTML report)**

- Suite: `res://tests/test_campaign_manager.gd` — `test_day_win_advances_day_and_shows_between_day_hub`  
  - Example assertion: expected **`Types.GameState.BETWEEN_MISSIONS`** (enum value **5**), got **`COMBAT`** (**2**).

- Suite: `res://tests/test_game_manager.gd` — e.g. `test_all_waves_cleared_mission_1_transitions_to_between_missions` or related, if transition did not run.

**Resolution (in repo)**

- **`project.godot`**: register **`CampaignManager`** before **`GameManager`** so **`CampaignManager._on_mission_won`** subscribes to **`mission_won`** first; **`GameManager`** connects second in **`_ready`**.
- **`GameManager`**: subscribe to **`mission_won`** in **`_connect_mission_won_transition_to_hub()`**; move hub **`_transition_to`** logic into **`_on_mission_won_transition_to_hub`** (no duplicate tail after emit inside **`_on_all_waves_cleared`**).

---

## 3. `test_campaign_manager.gd` — `mission_failed` payload vs `current_day`

**Involved file**

- `res://tests/test_campaign_manager.gd` — `test_day_fail_repeats_same_day`

**Problem**

After a synthetic **`mission_won`**, **`CampaignManager.current_day`** advances, but **`GameManager.get_current_mission()`** may still reflect the previous mission until the next day starts. Emitting **`mission_failed.emit(GameManager.get_current_mission())`** can send **`1`** while **`CampaignManager.current_day`** is **`2`**, so **`CampaignManager._on_mission_failed`** returns early (**`mission_number != current_day`**).

**Typical GdUnit failure (HTML report)**

- Example: line ~27 — expected **`prev_fails + 1`** (e.g. **1**), got **0** (failed attempts did not increment).

**Resolution (in repo)**

Emit with **`SignalBus.mission_failed.emit(CampaignManager.get_current_day())`** (see comment in test).

---

## 4. Tooling / engine noise (not always test logic)

**Symptoms seen at end of Godot runs**

```
ERROR: Capture not registered: 'gdaimcp'.
   at: unregister_message_capture (core/debugger/engine_debugger.cpp:62)
WARNING: ObjectDB instances leaked at exit (run with --verbose for details).
ERROR: N resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:810)
```

**Involved context**

- Editor / MCP / debugger integration; may appear when running headless tests depending on enabled plugins and capture registration.

**Note**

Treat as **environment noise** unless you are debugging MCP or shutdown leaks; separate from assertion failures in section 1–3.

---

## 5. CI / agent environment

**Symptom**

Shell or agent may report **`Error: Command failed to spawn: Aborted`** when running `./tools/run_gdunit.sh`, so a **full suite pass** is not always obtainable in automation.

**Reference**

See **`docs/PROMPT_10_IMPLEMENTATION.md`** (“What went wrong”).

---

## Related docs

- **`docs/PROMPT_10_FIXES.md`** — detailed fixes (sections 4–5).
- **`docs/PROMPT_10_IMPLEMENTATION.md`** — implementation status and verification.
- **`docs/INDEX_SHORT.md`**, **`INDEX_FULL.md`**, **`INDEX_TASKS.md`**, **`INDEX_MACHINE.md`** — condensed API and changelog notes.
