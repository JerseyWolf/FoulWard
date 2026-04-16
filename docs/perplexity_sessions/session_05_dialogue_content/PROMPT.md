# Session 5: Dialogue Content & Mid-Battle Dialogue

## Goal
Replace all 15+ placeholder dialogue entries ("TODO: placeholder dialogue line.") with actual character dialogue, and design a mid-battle dialogue trigger system for contextual lines during combat (e.g., "First flying enemy!" or "Tower HP critically low!").

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `dialogue_manager.gd` — DialogueManager autoload; API, conditions, chain system (lines 1-100)
- `dialogue_entry.gd` — DialogueEntry resource class definition
- `dialogue_condition.gd` — DialogueCondition resource class definition
- `dialogue_companion_melee_arnulf_intro_01.tres` — Sample dialogue .tres structure (companion_melee)
- `dialogue_spell_researcher_sybil_intro_01.tres` — Sample dialogue .tres structure (spell_researcher)
- `arnulf_hub.tres` — Arnulf character data
- `researcher.tres` — Sybil/researcher character data

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- dialogue_line_started and dialogue_line_finished signals are now on SignalBus (moved from DialogueManager in batch 1)
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: dialogue content creation and mid-battle dialogue system.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

CHARACTERS:
- COMPANION_MELEE (Arnulf): Burly warrior with a shovel. Gruff, darkly humorous, loyal but unreliable. References his past drinking (drunkenness system was CUT — do NOT reference active drunkenness mechanics, only as character flavor). Speaks in short, blunt sentences.
- SPELL_RESEARCHER (Sybil): Scholarly, slightly condescending, obsessed with magical theory. Speaks formally with occasional dry wit.
- MERCHANT: Pragmatic trader. Friendly but always looking for profit. Speaks in merchant idiom.
- WEAPONS_ENGINEER: Tinkerer. Enthusiastic about weapon modifications. Speaks with technical jargon.
- ENCHANTER: Mystical enchantress. Speaks cryptically with poetic flourish.
- MERCENARY_COMMANDER: Battle-hardened captain. No-nonsense military speech.
- FLORENCE: The player character (plague doctor). Rarely speaks; when he does, it's terse and practical.

REQUIREMENTS:

Part A — Hub Dialogue Content:
1. Write 3-5 dialogue entries per character (COMPANION_MELEE, SPELL_RESEARCHER, MERCHANT, WEAPONS_ENGINEER, ENCHANTER, MERCENARY_COMMANDER). Each should be 1-3 sentences.
2. For each character, include: an intro line (priority 100, once_only = true, no conditions), a research-unlocked reaction (conditions: sybil_research_unlocked_any or arnulf_research_unlocked_any), 2-3 generic lines (priority 1, once_only = false) that cycle, and at least one chain (chain_next_id linking two entries).
3. Use the dark humor fantasy tone consistently.

Part B — Mid-Battle Dialogue System:
1. Design a lightweight mid-battle dialogue trigger system. Add new condition keys: "first_flying_enemy_this_mission" (bool), "tower_hp_below_50_percent" (bool), "wave_number_gte" (int comparison), "enemy_type_first_seen" (String).
2. Mid-battle lines are short (1 sentence max), appear briefly in a toast/banner (not the full DialoguePanel), and do not pause gameplay.
3. Write 8-10 mid-battle lines: first flying enemy warning (Sybil), tower damage alert (Arnulf), wave 3+ encouragement, boss spawn reaction, etc.
4. Define a new DialogueEntry field: is_combat_line (bool, default false). Combat lines use a different UI display path.
5. Design the UI: a small banner at the top of the screen showing character portrait placeholder + text, auto-dismisses after 3 seconds.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
