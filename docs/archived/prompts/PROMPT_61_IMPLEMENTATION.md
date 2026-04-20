# PROMPT 61 — Godot C# (.NET) support scaffolding

## Phase 0: Godot C# support added

- `FoulWard.csproj` created at repo root (Godot.NET.Sdk/4.4.0, net8.0).
- `project.godot` patched with `[dotnet]` section: `enabled=true`.
- `.gitignore` updated with Godot C# build artifact paths.

**Verification note:** On the agent host, `dotnet` was not available (`dotnet --version` failed). Install the [.NET 8 SDK](https://dotnet.microsoft.com/download), then run `dotnet restore FoulWard.csproj`, `dotnet build FoulWard.csproj`, and `./tools/run_gdunit.sh` locally. If `dotnet restore` fails with a package source error, use `--source https://api.nuget.org/v3/index.json`. If Godot.NET.Sdk is missing until NuGet is configured, open the project once in the Godot .NET editor to register the SDK, then retry.

No `.cs` source files were added in this phase (per prompt).

## Phase 1B: FoulWardTypes.cs

Phase 1B complete: `FoulWardTypes.cs` created. No `.gd` files modified.

- `res://scripts/FoulWardTypes.cs` — C# mirror of every enum in `types.gd` as nested `public enum` types under `FoulWardTypes`; integer values match GDScript exactly; UPPER_SNAKE_CASE → PascalCase member names.
- `CREDITS.md` at repo root — row for FoulWardTypes.cs technique and references.
- `docs/INDEX_SHORT.md` — one-liner entry for FoulWardTypes.

**Verification (agent host):** `dotnet` was not available (`dotnet build` could not run). Install [.NET 8 SDK](https://dotnet.microsoft.com/download), then run `dotnet build FoulWard.csproj` locally. `./tools/run_gdunit.sh` was executed: **581** test cases reported (not 525); exit 100 with multiple failures/errors (e.g. `DamageCalculator` nil in headless tests). Failures appear unrelated to `FoulWardTypes.cs` (no GDScript references this file). Re-run `dotnet build` and the full GdUnit suite on a machine with .NET + Godot to confirm green.
