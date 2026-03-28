## AUITONOMOUS SESSION 4 — CONTEXT HANDOFF (Mission-Win -> Shop/Research + Build-Mode Clickability)

### What I understand the game flow is (from docs)

1. **Core loop (MVP)**
   - Main menu → `GameManager.start_new_game()` → `COMBAT`
   - `WaveManager` runs: countdown → spawn → track → clear → repeat
   - Winning a mission happens when **all waves are cleared**; `GameManager` then awards post-mission resources and emits `SignalBus.mission_won(mission_number)`
   - `GameManager` transitions to `BETWEEN_MISSIONS`
   - `UIManager` reacts to the state change by hiding combat HUD and showing `BetweenMissionScreen`
   - `BetweenMissionScreen` (tabs):
     - **Shop tab** calls `ShopManager.purchase_item(item_id)`
     - **Research tab** calls `ResearchManager.unlock_node(node_id)`
     - **Buildings tab** is view-only
   - **NEXT MISSION** button calls `GameManager.start_next_mission()`

2. **Build mode loop (docs)**
   - Build mode state is driven by `GameManager`
   - `SignalBus.game_state_changed(_, BUILD_MODE)` drives UI visibility/routing
   - `BuildMenu` is a **pure UI**: it shows 8 options and delegates placement logic to `HexGrid`
   - `HexGrid` is responsible for validating/placing/selling/locking logic; it also listens for build-mode entry to make slot meshes visible

### Session 3 state (carry-over summary from your log)

The project already had targeted fixes in this area:

- **Between-mission shop crash**
  - `HexGrid.has_empty_slot()` was added because `ShopManager.can_purchase()` was crashing during shop refresh.

- **Build-menu click obstruction**
  - `ui/ui_manager.gd`: removed automatic showing of `BuildMenu` on entering `BUILD_MODE`.
  - `ui/build_menu.gd`: menu opens only via `BuildMenu.open_for_slot(slot_index)` invoked from a hex click handler.
  - `ui/build_menu.tscn`: positioned the build panel so it covers less of the grid.

- **Mission timing dev mode**
  - `scripts/wave_manager.gd`: inter-wave countdown set to 10s (wave 1 remains 3s).
  - `autoloads/game_manager.gd`: capped waves per mission to 3 for faster “mission won → between mission” testing.

- **Debug unlocks for testing**
  - `scripts/research_manager.gd`: added `dev_unlock_all_research` + `dev_unlock_anti_air_only`.
  - `scenes/main.tscn`: enabled `dev_unlock_anti_air_only = true`.
  - `autoloads/game_manager.gd`: resets research unlock state on `start_new_game()` so the toggle applies each run.

### The specific runtime bug we’re targeting next

You reported: after mission victory, I currently see:
- Victory screen appears,
- then the flow breaks (between-mission shop/research missing),
- and errors appear in the debugger (with a crash risk during `BETWEEN_MISSIONS` UI refresh).

The architecture path we will trace is:
- `WaveManager` → `SignalBus.all_waves_cleared` →
- `GameManager._on_all_waves_cleared()` →
- `SignalBus.mission_won(current_mission)` →
- `GameManager` transitions to `BETWEEN_MISSIONS` →
- `UIManager` updates UI visibility →
- `BetweenMissionScreen` becomes visible →
- Shop/Research panels refresh:
  - shop refresh likely involves `ShopManager.can_purchase()` (which previously required a `HexGrid` API).

### Constraints I’m assuming for Session 4

- Keep the resolution/stretch/menu layout behavior changes you already made; do not undo them right now.
- Prefer small, targeted fixes.
- After any code change, re-run `GdUnit` to keep test failures at zero.

### What I will do first in the next iteration

1. Reproduce the current runtime errors after mission victory and capture the exact stack trace.
2. Trace the transition and UI refresh chain through:
   - `autoloads/game_manager.gd`
   - `ui/ui_manager.gd`
   - `ui/between_mission_screen.gd`
   - `scripts/shop_manager.gd`
3. Re-verify the known shop precondition:
   - `HexGrid.has_empty_slot()` exists and matches what `ShopManager.can_purchase()` expects.
4. Verify build-mode clickability:
   - `BUILD_MODE` should not cover the grid
   - after placing a tower, `BuildMenu` hides again
   - placement still routes through `HexGrid` correctly

