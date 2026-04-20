# PROMPT 63 — Phase 2A (SavePayload.cs)

Phase 2A complete: `res://autoloads/SavePayload.cs` added (C# `RefCounted` + `FromGodotDict` / `ToGodotDict` + `System.Text.Json` `Serialize` / `Deserialize`). `save_manager.gd` unchanged.

Verification:

- `dotnet build FoulWard.csproj` — success.
- `test_save_manager.gd` + `test_save_manager_slots.gd` — 8/8 cases passed (GdUnit headless).

Full `./tools/run_gdunit.sh` requires **Godot 4.6.1 .NET (mono)** at repo root as `Godot_v4.6.1-stable_mono_linux.x86_64` or `GODOT_BIN` pointing at a .NET build — C# autoloads (`DamageCalculator.cs`, etc.) do not load on the standard (non-mono) export; with only `Godot_v4.6.1-stable_linux.x86_64`, suites that call `DamageCalculator` fail with `calculate_damage` on `Nil` (environment / Phase 1A toolchain), not due to `SavePayload.cs`.
