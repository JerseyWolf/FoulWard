## Prompt 15 — Florence meta-state + day progression (implementation log)

### 2026-03-25 (work so far)

Implemented the Florence meta-state scaffold and its technical hooks:

1. **FlorenceData Resource**
   - Added `res://scripts/florence_data.gd` (`class_name FlorenceData`).
   - Run-scoped counters/flags + day milestone flags (`has_reached_day_25`, `has_reached_day_50`).
   - Added `reset_for_new_run()` and `update_day_threshold_flags(current_day)`.

2. **Central day-advance reasons**
   - Updated `res://scripts/types.gd`:
     - Added `enum DayAdvanceReason`.
     - Added `Types.get_day_advance_priority(reason)` priority helper.

3. **SignalBus + GameManager integration**
   - Updated `res://autoloads/signal_bus.gd`:
     - Added `SignalBus.florence_state_changed()`.
   - Updated `res://autoloads/game_manager.gd`:
     - Added `GameManager.current_day` (meta day index) and `GameManager.florence_data`.
     - Added `advance_day()` + `_apply_pending_day_advance_if_any()` using `Types.DayAdvanceReason`.
     - Updated mission win/fail handlers to increment Florence counters and advance meta day.
     - Added `GameManager.get_florence_data()`.
     - Incremented `florence_data.run_count` on full `GAME_WON` transition.

4. **Dialogue condition hooks**
   - Updated `res://autoloads/dialogue_manager.gd`:
     - Extended `_resolve_state_value()` to resolve namespaced keys:
       - `florence.*`
       - `campaign.current_day`
       - `campaign.current_mission`

5. **Between-mission debug UI**
   - Updated `res://ui/between_mission_screen.tscn` + `res://ui/between_mission_screen.gd`:
     - Added `FlorenceDebugLabel`.
     - Connected to `SignalBus.florence_state_changed`.
     - Implemented `_refresh_florence_debug()` placeholder text.

6. **Research/Shop technical hooks**
   - Updated `res://scripts/research_manager.gd`:
     - On first `unlock_node()` success sets `florence.has_unlocked_research`.
   - Updated `res://scripts/shop_manager.gd`:
     - Added placeholder enchantments unlock hook (`item_id == "enchantments_unlock"`).

7. **Tests**
   - Added `res://tests/test_florence.gd`.
   - Added `test_florence.gd` to `./tools/run_gdunit_quick.sh` allowlist.

### Verification notes

- Used `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, and `docs/PRE_GENERATION_VERIFICATION.md` as required.
- The next step is running `./tools/run_gdunit_quick.sh` and addressing any GdUnit failures.

### 2026-03-25 (follow-up fixes)

- `GameManager.advance_day()` no longer attempts to cast an int back to `Types.DayAdvanceReason` using `Types.DayAdvanceReason(reason_id)` (Godot parse error); it now maps the stored int via a `match` helper for priority comparisons.
- `tests/test_florence.gd` and `ui/between_mission_screen.gd` avoid `: FlorenceData` type annotations in local variables (prevents parse-time "type not found" / autoload init ordering issues).
- `./tools/run_gdunit_quick.sh` passes (`0 errors / 0 failures`) after these parse-safety changes.

