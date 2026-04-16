# Session 3: Ring Rotation Pre-Battle UI

## Goal
Design the pre-battle ring rotation screen where players can rotate the HexGrid's three rings before combat begins. The method HexGrid.rotate_ring(delta_steps: int) exists but has no UI or caller. This session designs the GameState, UI, and integration.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `hex_grid.gd` — HexGrid script; slot layout, rotate_ring, ring constants (lines 1-120)
- `build_phase_manager.gd` — BuildPhaseManager autoload; build phase state management
- `game_manager.gd` — GameManager autoload; state transitions (lines 55-120)
- `types.gd` — Types.gd; GameState enum (lines 1-50)

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: the ring rotation pre-battle UI and GameState integration.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

REQUIREMENTS:
1. Add GameState.RING_ROTATE (integer value 12) to Types.gd — append at end. PASSIVE_SELECT = 11 is added by Session 2; coordinate accordingly. Add matching C# mirror entry.
2. Design the state transition: PASSIVE_SELECT -> RING_ROTATE -> COMBAT (or skip RING_ROTATE if no buildings are placed yet — first mission).
3. Design the UI: show a top-down hex grid visualization with three rings highlighted. Each ring has left/right rotation arrows. Show building icons in their current slots. Include a "Confirm" button to proceed to COMBAT.
4. The rotation is FREE (no resource cost). Each ring rotates independently.
5. Define the scene structure: res://ui/ring_rotation_screen.tscn + ring_rotation_screen.gd.
6. Integration: GameManager transitions to RING_ROTATE after passive selection (or after MISSION_BRIEFING if passives are not yet implemented). HexGrid.rotate_ring() is called when arrows are clicked.
7. BuildPhaseManager should NOT be active during RING_ROTATE — this is a separate phase.
8. SignalBus signals: ring_rotated(ring_index: int, delta_steps: int).
9. Save: ring positions persist automatically since buildings are already saved by slot index.

Note: Batch 5 extracted hex_grid.gd's _try_place_building into _validate_placement() + _instantiate_and_place() helper methods. The ring rotation system does not interact with placement — it only calls rotate_ring().

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
