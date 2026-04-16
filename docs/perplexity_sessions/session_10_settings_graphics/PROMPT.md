# Session 10: Settings Graphics & Polish

## Goal
Wire SettingsManager.set_graphics_quality() to actual Godot RenderingServer APIs. Currently it stores a string but does not apply any rendering changes.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `settings_manager.gd` — SettingsManager autoload; full file
- `settings_screen.gd` — SettingsScreen UI script; full file
- `settings_screen.tscn` — SettingsScreen scene (or node structure description if binary)

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
Produce an implementation spec for: wiring graphics quality presets to Godot's rendering APIs.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

REQUIREMENTS:
1. Define quality presets:
   - "low": shadows off, MSAA disabled, SSAO off, SDFGI off, glow off, motion blur off
   - "medium": shadows on (soft, 2048px), MSAA 2x, SSAO off, glow on
   - "high": shadows on (soft, 4096px), MSAA 4x, SSAO on, glow on, volumetric fog on

2. Implement _apply_quality_preset(quality: String) in SettingsManager that calls:
   - RenderingServer.directional_shadow_atlas_set_size() for shadow resolution
   - Viewport.msaa_3d for MSAA
   - Environment resource modifications for SSAO, glow, volumetric fog
   - get_viewport().set_* calls where applicable

3. Call _apply_quality_preset at startup (load_settings) and whenever set_graphics_quality is called.

4. Add a "Custom" quality option that preserves individual toggle states when the user changes specific settings.

5. SettingsScreen additions: individual toggles for shadows, MSAA, SSAO, glow (visible only when "Custom" quality is selected).

6. Handle the case where the game runs headless (no viewport available) — skip all rendering calls with a guard.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
