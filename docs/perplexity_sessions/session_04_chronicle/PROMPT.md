# Session 4: Chronicle Meta-Progression System

## Goal
Design the Chronicle of Foul Ward — a cross-run meta-progression system. The master doc confirms it is designed but not yet implemented. This session produces the complete implementation spec: resources, achievement triggers, perk effects, UI, and save integration.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `florence_data.gd` — FlorenceData resource; protagonist meta-state (run counters, boss attempts, unlock flags)
- `signal_bus.gd` — Central signal hub; lines 90-150 covering game state, campaign, and build mode signals
- `save_manager.gd` — SaveManager autoload; lines 1-60 covering save payload structure
- `types.gd` — Types.gd; lines 1-30 covering enum patterns

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
Produce an implementation spec for: the Chronicle meta-progression system.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

DESIGN DECISION: Chronicle perks should be cosmetic micro-buffs (not meaningful power advantages). Examples: +2% gold per kill (flavor), +5 starting mana, unique building skins unlocked.

REQUIREMENTS:
1. Define ChronicleData resource class: chronicle_id (String), entries (Array[ChronicleEntryData]), total_xp (int), current_rank (int).
2. Define ChronicleEntryData resource class: entry_id (String), display_name (String), description (String), trigger_signal (String — SignalBus signal name), trigger_condition (Dictionary — e.g., {"count": 10}), reward_type (String — "perk", "cosmetic", "title"), reward_id (String), is_completed (bool).
3. Define ChroniclePerkData resource class: perk_id (String), display_name (String), description (String), effect_type (String), effect_value (float), is_active (bool).
4. Design 15-20 achievements spanning: combat (kill N enemies), campaign (reach day 25, day 50), bosses (defeat each mini-boss), economy (earn N gold total), building (place N buildings), and meta (complete N runs).
5. Design 8-10 perks as rewards: starting gold +50, starting mana +5, sell refund +2%, research cost -5%, etc. All intentionally small.
6. Chronicle persists across runs in a separate save file: user://chronicle.json (not in the per-attempt save slots).
7. Design the UI: accessible from MAIN_MENU as a "Chronicle" button. Shows achievement list with progress bars and perk unlock status.
8. Integration: a new autoload ChronicleManager listens to SignalBus signals and tracks achievement progress. Perk effects are applied at mission start via existing manager APIs.
9. Define all SignalBus signal connections and the exact listener pattern.
10. Do NOT implement a full XP/leveling system — just achievement -> perk unlocks.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
