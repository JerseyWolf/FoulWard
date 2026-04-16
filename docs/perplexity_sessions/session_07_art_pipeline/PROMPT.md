# Session 7: 3D Art Pipeline Integration & Wiring

## Goal
Finalize the integration between the 3D art pipeline (reference sheet -> Rodin -> rig -> animate -> Godot import) and the existing ArtPlaceholderHelper / RiggedVisualWiring code. Standardize AnimationPlayer clip names, document the exact GLB drop zones, and resolve conflicts between the pipeline doc and cut features.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `art_placeholder_helper.gd` — Runtime mesh/material resolver; production GLBs auto-override placeholders
- `rigged_visual_wiring.gd` — GLB mount + animation mapping; maps entity types to GLB paths
- `FUTURE_3D_MODELS_PLAN.md` — Production 3D art roadmap (complete file under **FILES:** below)
- `FOUL WARD 3D ART PIPELINE.txt` — Full 5-stage art pipeline strategy document (complete file under **FILES:** below)
- `enemy_base.gd` — EnemyBase script; lines 1-50 covering visual slot setup
- `arnulf.gd` — Arnulf script; lines 130-140 covering ArnulfVisual
- `boss_base.gd` — BossBase script; lines 40-50 covering BossVisual

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
Produce an implementation spec for: 3D art pipeline integration, animation standardization, and validation tooling.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

CONFLICT: The pipeline doc lists "drunk_idle (swaying variation) — Arnulf only" as a required animation. The Arnulf drunkenness system is FORMALLY CUT. Remove drunk_idle from the animation requirements.

REQUIREMENTS:
1. Produce a definitive animation clip name table for every entity type:
   - Enemies (all 30 types): idle, walk, attack, hit_react, death, spawn (optional)
   - Allies (Arnulf + mercenaries): idle, run, attack_melee, hit_react, death, downed, recovering
   - Florence/Sybil (Tower): idle, shoot, hit_react, cast_spell, victory, defeat
   - Buildings: idle, active, destroyed
   - Bosses: idle, walk, attack, death, phase_transition (optional)

2. Document the exact GLB drop zone paths for each entity category:
   - res://art/generated/enemies/{enemy_type_lowercase}.glb
   - res://art/generated/allies/{ally_id}.glb
   - res://art/generated/bosses/{boss_id}.glb
   - res://art/generated/buildings/{building_type_lowercase}.glb
   - res://art/characters/{character_name}/{character_name}.glb

3. Design a validation script (tools/validate_art_assets.gd) that scans all GLB files under res://art/, checks required animation clips exist, reports missing clips/wrong names/unexpected files.

4. For each TODO(ART) marker, specify what production art replaces:
   - ally_base.gd:206 — GLB from RiggedVisualWiring for ally_id
   - arnulf.gd:134 — res://art/generated/allies/arnulf.glb
   - tower.gd:82 — res://art/characters/florence/florence.glb
   - boss_base.gd:46 — GLB from RiggedVisualWiring for boss_id
   - hub.gd:35 — 2D character portraits from res://art/icons/characters/

5. Update the 3D art pipeline doc: remove drunk_idle from Arnulf's animation list.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
