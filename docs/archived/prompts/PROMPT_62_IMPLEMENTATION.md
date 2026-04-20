# PROMPT 62 — Phase 1A (DamageCalculator C#)

Phase 1A complete: `autoloads/DamageCalculator.cs` added, `damage_calculator.gd` removed, full GdUnit suite passes (612 test cases with current discovery; 0 failures).

Notes for maintainers:

- **`FoulWard.csproj`** must set `<AssemblyName>foul_ward</AssemblyName>` so the built DLL matches Godot’s `Path.get_csharp_project_name()` (from `project.godot` `application/config/name`, i.e. `foul_ward` → `foul_ward.dll`). Without this, Linux builds emit `FoulWard.dll` and the engine looks for `foul_ward.dll`, so `.NET: Failed to load project assembly` occurs.
- **Godot .NET editor** is required to run the project and tests (`Godot_*_mono_linux.x86_64`). The `tools/run_gdunit*.sh` scripts prefer `Godot_v4.6.1-stable_mono_linux.x86_64` at the repo root when executable; otherwise set `GODOT_BIN`. Plain non-.NET Godot cannot load `.cs` autoloads.
- **GDScript** calls `calculate_damage` / `calculate_dot_tick` (snake_case). Explicit public wrappers forward to `CalculateDamage` / `CalculateDotTick` because automatic snake_case mapping was not resolving on autoload in practice.
