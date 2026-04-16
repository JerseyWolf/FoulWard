# Foul Ward — Agent notes (`docs/`)

Canonical standing orders live in **`AGENTS.md`** (repo root; symlinked as `.cursorrules`). This file adds orientation and rules specific to documentation and C#.

---

## Orientation

- **`.cs` files:** run `dotnet build FoulWard.csproj` **before** GdUnit when C# sources change. C# compile errors prevent correct autoload registration and cause GdUnit autoload failures.
- **MCP (paid bridges):** `godot-mcp-pro` and `gdai-mcp-godot` live outside the repo at `../foulward-mcp-servers/<name>` (not version-controlled). Paths and habits: root **`AGENTS.md`**, **`docs/FOUL_WARD_MASTER_DOC.md`** §1.1, **`.cursor/skills/mcp-workflow/SKILL.md`**.

---

## File change rules

- **New `.cs` file:** add a one-liner to **`docs/INDEX_SHORT.md`** (and `docs/INDEX_FULL.md` when that file documents the API).
- **Replacing a GDScript autoload with C#:** update **`project.godot`** autoload path to the new `.cs` resource.

---

## Code conventions

- **C#:** **PascalCase** methods and public API; GDScript callers see **snake_case** via the marshaller — **do not** add hand-written wrapper scripts for naming alone.
- **Interop:** signals stay centralized in **`autoloads/signal_bus.gd`**. Dialogue line events (`dialogue_line_started` / `dialogue_line_finished`) are declared there, not on DialogueManager — see root **`AGENTS.md`** Known Gotchas #8. **Signal count:** **67** typed declarations as of **2026-04-14**; when you add or remove a `signal`, update every file listed in `.cursor/skills/signal-bus/SKILL.md` § *Signal count in documentation*.

---

## Architecture rules

- **`FoulWardTypes.cs`** is the C# enum mirror of **`scripts/types.gd`**. Only **`.cs`** imports `FoulWardTypes`; **`.gd`** never does.
