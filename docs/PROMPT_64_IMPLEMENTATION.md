# PROMPT 64 — Phase 2B (WaveCompositionHelper.cs)

Phase 2B complete: `res://scripts/WaveCompositionHelper.cs` created. `wave_manager.gd` `spawn_wave()` calls `build_roster()` before the composed-wave path. Full GdUnit suite passes (612 test cases; exit 101 orphan warnings only — `run_gdunit.sh` treats as pass).

Notes:

- `wave_manager.gd` preloads `WaveCompositionHelper.cs` as `CSharpScript` (`WaveCompositionHelperScript`) so the helper instantiates without relying on `.godot/global_script_class_cache.cfg` (gitignored). `helper.build_roster(...)` uses the explicit C# `build_roster` wrapper (same pattern as `DamageCalculator.calculate_damage`).
- `BuildRoster` takes a `Resource` (`FactionData` from GDScript); it calls `get_entries_for_wave` / `get_effective_weight_for_wave` on that resource and mirrors legacy Prompt 9 largest-remainder allocation.

Verification:

- `dotnet build FoulWard.csproj` — success.
- `./tools/run_gdunit.sh` — 612 cases, 0 failures.
