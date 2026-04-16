# BATCH_1_REPORT — Signal Routing, Connect Guards, Orphan Documentation
Date: 2026-04-14

---

## Summary

Three tasks completed across 8 files:
- **Task A**: `dialogue_line_started` / `dialogue_line_finished` moved from DialogueManager locals to SignalBus.
- **Task B**: All bare `.connect()` calls in `_ready()` / `_connect_signals()` wrapped with `is_connected` guards.
- **Task C**: Five orphaned SignalBus signals annotated with POST-MVP stub comments.

---

## Task A — Dialogue Signals Routed Through SignalBus

### Files changed

**`autoloads/signal_bus.gd`**
- Added `# === DIALOGUE ===` section after `campaign_completed` (line 141).
- Declared `dialogue_line_started(entry_id: String, character_id: String)` on SignalBus.
- Declared `dialogue_line_finished(entry_id: String, character_id: String)` on SignalBus.
- Both carry `@warning_ignore("unused_signal")`.

**`autoloads/dialogue_manager.gd`**
- Removed local `signal dialogue_line_started` and `signal dialogue_line_finished` declarations (lines 40–41).
- Replaced with: `# dialogue_line_started and dialogue_line_finished are declared on SignalBus.`
- `_emit_started()`: changed `dialogue_line_started.emit(...)` → `SignalBus.dialogue_line_started.emit(...)`
- `notify_dialogue_finished()`: changed `dialogue_line_finished.emit(...)` → `SignalBus.dialogue_line_finished.emit(...)`

**`ui/ui_manager.gd`**
- `_ready()`: replaced `DialogueManager.dialogue_line_finished.connect(_on_dialogue_line_finished)` with `SignalBus` route wrapped in `is_connected` guard.

**`tests/test_character_hub.gd`**
- Line 317: changed `monitor_signals(DialogueManager, false)` → `monitor_signals(SignalBus, false)` so the signal assertion targets the correct source after the routing change.

---

## Task B — is_connected Guards Added

All bare `.connect()` calls in `_ready()` / `_connect_signals()` wrapped. Pattern used:
```gdscript
if not SignalBus.<signal_name>.is_connected(<callback>):
    SignalBus.<signal_name>.connect(<callback>)
```

### Per-file

**`autoloads/game_manager.gd`** (original lines 57, 58, 67)
- `SignalBus.all_waves_cleared` → `_on_all_waves_cleared`
- `SignalBus.tower_destroyed` → `_on_tower_destroyed`
- `SignalBus.boss_killed` → `_on_boss_killed`

**`autoloads/campaign_manager.gd`** (original lines 59, 60)
- `SignalBus.mission_won` → `_on_mission_won`
- `SignalBus.mission_failed` → `_on_mission_failed`

**`autoloads/economy_manager.gd`** (original lines 47, 48)
- `SignalBus.enemy_killed` → `_on_enemy_killed`
- `SignalBus.wave_cleared` → `_on_wave_cleared`

**`scripts/wave_manager.gd`** (original lines 158, 159)
- `SignalBus.enemy_killed` → `_on_enemy_killed`
- `SignalBus.game_state_changed` → `_on_game_state_changed`

**`autoloads/auto_test_driver.gd`** (original lines 66, 67, 68)
- `SignalBus.enemy_killed` → `_on_enemy_killed`
- `SignalBus.wave_cleared` → `_on_wave_cleared`
- `SignalBus.wave_started` → `_on_wave_started`

**`ui/ui_manager.gd`** (original line 56 + new dialogue connect from Task A)
- `SignalBus.game_state_changed` → `_on_game_state_changed`
- `SignalBus.dialogue_line_finished` → `_on_dialogue_line_finished`

**`autoloads/dialogue_manager.gd`** — `_connect_signals()` (original lines 135–143)
- `SignalBus.game_state_changed` → `_on_game_state_changed`
- `SignalBus.mission_started` → `_on_mission_started`
- `SignalBus.mission_won` → `_on_mission_won`
- `SignalBus.mission_failed` → `_on_mission_failed`
- `SignalBus.resource_changed` → `_on_resource_changed`
- `SignalBus.research_unlocked` → `_on_research_unlocked`
- `SignalBus.shop_item_purchased` → `_on_shop_item_purchased`
- `SignalBus.arnulf_state_changed` → `_on_arnulf_state_changed`
- `SignalBus.spell_cast` → `_on_spell_cast`

Total guards added: **16**

---

## Task C — Orphaned Signal Documentation

All comments added to `autoloads/signal_bus.gd`:

| Signal | Comment added |
|---|---|
| `ally_state_changed` (line 44) | POST-MVP: not yet emitted. Will be emitted from AllyBase._transition_state() when ally state tracking is implemented. |
| `terrain_prop_destroyed` (line 86) | POST-MVP: not yet emitted. Reserved for destructible terrain props. |
| `nav_mesh_rebake_requested` (line 88) | POST-MVP: connected in NavMeshManager but never emitted. Will be emitted from terrain/build flows. |
| `florence_damaged` (line 102) | POST-MVP: connected in CombatStatsTracker but not yet emitted from game code. EnemyBase attack flow should emit this. |
| `building_destroyed` (line 105) | POST-MVP: not yet emitted. Requires building HP/destruction system. |

---

## Test Results

```
./tools/run_gdunit_parallel.sh
Wall-clock: 133s  |  Processes: 8  |  Test files: 74
TOTALS: cases=612  failures=1  orphans=3
```

**1 failure**: `test_save_manager_slots.gd::test_relationship_manager_round_trip_integration`
- Pre-existing: the baseline (git stash) run crashed Godot with signal 11 on the same test file.
- Root cause: affinity value mismatch (expected 17.0, got 2.0) — unrelated to this batch's changes.
- No new failures introduced.

**3 orphans**: Pre-existing across groups 2, 3, 5 — unchanged from baseline.

---

## Files Changed in This Batch

| File | Change type |
|---|---|
| `autoloads/signal_bus.gd` | New signals + POST-MVP comments |
| `autoloads/dialogue_manager.gd` | Remove local signals, route to SignalBus, add guards |
| `autoloads/game_manager.gd` | is_connected guards |
| `autoloads/campaign_manager.gd` | is_connected guards |
| `autoloads/economy_manager.gd` | is_connected guards |
| `autoloads/auto_test_driver.gd` | is_connected guards |
| `scripts/wave_manager.gd` | is_connected guards |
| `ui/ui_manager.gd` | Route to SignalBus + is_connected guards |
| `tests/test_character_hub.gd` | Update signal monitor to SignalBus |
