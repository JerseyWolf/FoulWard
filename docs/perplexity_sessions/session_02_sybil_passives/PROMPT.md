# Session 2: Sybil Passive Selection System

## Goal
Design the Sybil passive selection system: a set of mission-start passive buffs the player chooses from (e.g., +10% mana regen, +15% spell damage, reduced cooldowns). Includes a new GameState PASSIVE_SELECT, the selection UI, passive data resources, SpellManager integration, and SignalBus signals.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `types.gd` — All enum definitions including GameState (11 values currently); shows enum patterns
- `spell_manager.gd` — Scene-bound spell manager; mana, cooldowns, 4 registered spells
- `game_manager.gd` — Autoload; game state machine, mission start, state transitions (lines 55-120)
- `signal_bus.gd` — Central signal hub; **67** typed `signal` declarations as of **2026-04-14** (see top of `signal_bus.gd` for patterns; if you add signals, update the project's SignalBus signal-count parity everywhere it is tracked — consult **FOUL_WARD_MASTER_DOC** only if you need the maintenance checklist)
- `spell_data.gd` — SpellData resource class; spell_id, mana_cost, cooldown, damage fields

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
Produce an implementation spec for: the Sybil passive selection system.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

DESIGN DECISION (already made): Choose "single pick before mission" — the player selects ONE passive from a list of 3-4 randomly offered options each mission.

REQUIREMENTS:
1. Define a new resource class SybilPassiveData (extends Resource) with fields: passive_id (String), display_name (String), description (String), icon_id (String), category (String — "offense", "defense", "utility"), effect_type (String), effect_value (float), is_unlocked (bool).
2. Define 8 passives covering offense (spell damage +15%, mana regen +20%), defense (tower shield duration +30%, spell cooldown -15%), and utility (mana cost -10%, spell ready notification, etc.).
3. Add GameState.PASSIVE_SELECT (integer value 11) to the Types.gd enum — append at end, never reorder existing values. Add matching C# mirror entry.
4. Design the state transition: MISSION_BRIEFING -> PASSIVE_SELECT -> COMBAT. The selection screen shows 3-4 randomly offered passives from the unlocked pool.
5. Define SignalBus signals: sybil_passive_selected(passive_id: String), sybil_passives_offered(passive_ids: Array[String]).
6. Design SpellManager integration: how the selected passive modifies spell behavior (e.g., multiplied mana_regen_rate, modified cooldown values).
7. Design the UI: a simple panel showing 3-4 passive cards with name, description, icon placeholder, and a Select button.
8. Define save/load integration: selected passive persists in save payload under a new "sybil" key.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
