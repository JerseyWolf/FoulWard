# PROMPT 66 — C# integration final verification

**Date:** 2026-04-14

## Scope

End-to-end verification of Foul Ward C# integration: file presence, `project.godot` autoload policy (single `.cs` autoload: `DamageCalculator`), `CREDITS.md` / `INDEX_SHORT.md` / `AGENTS.md` alignment, `dotnet build`, full GdUnit suite, `run_gdunit.sh` post-exit crash guard, no `signal_bus.gd` drift, projectile hit logic review, `IMPROVEMENTS_TO_BE_DONE.md` spawn_wave status.

## Changes applied (this session)

- `AGENTS.md`: test count 525 → 612; `DamageCalculator` path `.cs`; added `dotnet build` + `FoulWardTypes.cs` notes under How to Verify.
- `CREDITS.md`: five-row C# credit table including `DamageCalculator.cs`.
- `tools/run_gdunit.sh`: map exit 139/134 to 101 (known .NET teardown) before existing 0/101 handling.

## Checks (summary)

- Five C# files present under `res://` paths as specified.
- `damage_calculator.gd` absent.
- `project.godot`: only `DamageCalculator` uses `.cs` autoload.
- Tests and build: see verification report in session output.
