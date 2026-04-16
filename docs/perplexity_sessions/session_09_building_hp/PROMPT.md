# Session 9: Building HP & Destruction System

## Goal
Design the building HP and destruction system. Currently buildings are indestructible. The building_destroyed signal exists on SignalBus but is never emitted. This session adds building HP, damage reception, destruction effects, and signal activation.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `building_base.gd` — BuildingBase scene script; initialization, combat, key methods (lines 1-80)
- `building_data.gd` — BuildingData resource class; all exported fields (lines 1-60)
- `health_component.gd` — HealthComponent script; HP management, damage, heal, signals
- `signal_bus.gd` — SignalBus; lines 100-110 covering building signals
- `hex_grid.gd` — HexGrid script; lines 1-50 covering slot data structure

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
Produce an implementation spec for: building HP, destruction, enemy targeting of buildings, and HP bar UI.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

REQUIREMENTS:
1. Add BuildingData fields: max_hp (int, default 0 — 0 means indestructible for backward compat), can_be_targeted_by_enemies (bool, default false).
2. Add a HealthComponent child to BuildingBase when max_hp > 0. Initialize with max_hp from BuildingData.
3. When HealthComponent.health_depleted fires on a building:
   - Emit SignalBus.building_destroyed(slot_index)
   - If summoner: AllyManager.despawn_squad(instance_id)
   - If aura: AuraManager.deregister_aura(instance_id)
   - Play a destruction visual (placeholder: scale to 0 over 0.5s, then queue_free)
   - HexGrid clears the slot
4. Which enemies attack buildings: only enemies with a new EnemyData field prefer_building_targets (bool, default false). When true AND a building with can_be_targeted_by_enemies is in range, the enemy attacks the building instead of pathing to the tower.
5. Set max_hp > 0 on MEDIUM and LARGE buildings only. SMALL buildings remain indestructible. Suggested values: MEDIUM = 200-400 HP, LARGE = 500-800 HP.
6. Repair mechanic: the existing tower_repair shop item repairs the tower. Add building_repair shop item behavior: restores 50% HP to the lowest-HP building.
7. Building HP bar: show a small HP bar above buildings with HP. Use the same visual pattern as enemy HP bars.
8. Save: building HP should persist within a mission but resets between missions (buildings are fresh each day).

Note: Batch 5 extracted hex_grid.gd's _try_place_building into _validate_placement() + _instantiate_and_place(). The destruction system interacts with slot clearing, not placement.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
