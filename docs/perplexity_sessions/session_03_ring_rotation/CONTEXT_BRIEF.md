# Context Brief — Session 3: Ring Rotation

## Game States (§6)

Defined in res://scripts/types.gd as Types.GameState.

Transition graph: MAIN_MENU -> MISSION_BRIEFING -> COMBAT <-> BUILD_MODE -> WAVE_COUNTDOWN -> (COMBAT loop) -> MISSION_WON/MISSION_FAILED -> BETWEEN_MISSIONS -> MISSION_BRIEFING...

PLANNED states: RING_ROTATE (pre-battle ring rotation), PASSIVE_SELECT (Sybil passives).

### GameState Enum (current values + Session 2 addition)
| Name | Value |
|------|-------|
| MAIN_MENU | 0 |
| MISSION_BRIEFING | 1 |
| COMBAT | 2 |
| BUILD_MODE | 3 |
| WAVE_COUNTDOWN | 4 |
| BETWEEN_MISSIONS | 5 |
| MISSION_WON | 6 |
| MISSION_FAILED | 7 |
| GAME_WON | 8 |
| GAME_OVER | 9 |
| ENDLESS | 10 |
| PASSIVE_SELECT | 11 (added by Session 2) |

## Buildings — Ring Rotation (§8)

EXISTS: rotate_ring() in BuildPhaseManager / HexGrid.
PLANNED: Pre-battle ring rotation UI.

HexGrid has TOTAL_SLOTS = 24 across 3 concentric rings around the tower. rotate_ring(delta_steps: int) shifts buildings within a ring.

Note: Batch 5 extracted _try_place_building into _validate_placement() + _instantiate_and_place() helpers. Ring rotation does not interact with placement — only calls rotate_ring().

## Scene Tree — HexGrid and Managers (§25)

```
/root/Main (Node3D)
├── HexGrid (Node3D) [hex_grid.tscn]
│   └── HexSlot00..HexSlot23 (Area3D x24)
├── Managers (Node)
│   ├── WaveManager (Node)
│   ├── SpellManager (Node)
│   ├── ResearchManager (Node)
│   ├── ShopManager (Node)
│   ├── WeaponUpgradeManager (Node)
│   └── InputManager (Node)
└── UI (CanvasLayer)
    ├── UIManager (Control)
    ├── HUD [hud.tscn]
    ├── BuildMenu [build_menu.tscn]
    ├── BetweenMissionScreen [between_mission_screen.tscn]
    ├── MainMenu [main_menu.tscn]
    ├── MissionBriefing (Control)
    └── EndScreen (Control)
```

## Full Mission Cycle — Steps 1-3 (§27.1)

1. MAIN_MENU -> User clicks "Start"
2. GameManager.start_new_game() resets all managers, starts campaign
3. COMBAT (waves loop) -> wave_started, enemies spawn, wave_cleared, next wave...

The ring rotation phase inserts between PASSIVE_SELECT and COMBAT.

## BuildPhaseManager API (§3.10)

| Signature | Returns | Usage |
|-----------|---------|-------|
| set_build_phase_active(active: bool) -> void | void | Enables/disables build phase |
| is_build_phase_active() -> bool | bool | Current state |
| assert_build_phase(caller: String) -> bool | bool | Guard for build-only operations |

BuildPhaseManager should NOT be active during RING_ROTATE.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- _physics_process for game logic — _process for visual/UI only
- get_node_or_null() for runtime lookups with null guard
- Scene instantiation: call initialize() before or immediately after add_child()
