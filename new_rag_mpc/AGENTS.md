# AGENTS.md — Foul Ward AI Assistant Standing Orders

> **Place this file in the Foul Ward project root (`~/FoulWard/AGENTS.md`).**
> Cursor reads this automatically at the start of every session.

---

## MANDATORY PRE-FLIGHT (Do these BEFORE any work)

### 1. Orient yourself on the current project state

Before making ANY changes, call the `query_project_knowledge` MCP tool:

```
query_project_knowledge(
    question="What is the current state of the project? What systems exist, what was last implemented, and what are the known issues?",
    domain="all"
)
```

Read the response fully. If the answer is incomplete, make follow-up queries targeting specific domains (`code`, `architecture`, `resources`).

### 2. Check SimBot data before balance work

Before ANY task related to game balance, enemy stats, building tuning, economy numbers, wave scaling, or difficulty progression, call:

```
get_recent_simbot_summary(n_runs=3)
```

Ground all balance suggestions in actual simulation data. Never invent numbers.

### 3. Check INDEX_SHORT.md before creating new files

Before creating any new `.gd`, `.tscn`, `.tres`, or test file:

```
query_project_knowledge(
    question="What files exist in the project? Show me INDEX_SHORT.md",
    domain="architecture"
)
```

- Verify the file doesn't already exist.
- Verify the name follows the project naming conventions.
- Verify the directory placement matches the established structure.

### 4. Check CONVENTIONS.md before writing any code

If you haven't already reviewed it this session:

```
query_project_knowledge(
    question="What are the coding conventions for this project?",
    domain="architecture"
)
```

Follow ALL rules in CONVENTIONS.md without exception:
- `snake_case` for files, variables, functions
- `PascalCase` for `class_name` and scene tree nodes
- `UPPER_SNAKE_CASE` for constants and enum values
- All signals through `SignalBus` only
- Explicit types on every parameter and return value
- No magic numbers — everything in `.tres` or named constants
- Test naming: `test_{what}_{condition}_{expected}`

---

## MANDATORY POST-FLIGHT (Do these AFTER completing work)

### 5. Create/update the implementation log

After completing any task, create or update:

```
docs/PROMPT_[N]_IMPLEMENTATION.md
```

Where `[N]` is the next prompt number in sequence. This file must contain:
- What was requested
- What was implemented (every file created or modified)
- What tests were added and their pass/fail status
- Any deviations from the spec (with `# DEVIATION:` explanations)
- Known issues or follow-up items

### 6. Update INDEX files

After ANY file creation or modification:
- Update `INDEX_SHORT.md` with the new file entry (path, class_name, one-sentence description)
- Update `INDEX_FULL.md` with full public API documentation (methods, signals, exports, dependencies)

---

## LOOKUP PATTERNS

Use these queries to find specific information quickly:

| What you need | Query |
|---|---|
| How a system works | `query_project_knowledge("How does [system] work?", "architecture")` |
| A specific function signature | `query_project_knowledge("[function_name] signature parameters", "code")` |
| Resource file values | `query_project_knowledge("[resource_name] stats values", "resources")` |
| Signal flow | `query_project_knowledge("What signals does [system] emit and consume?", "architecture")` |
| Enemy/building stats | `query_project_knowledge("[entity_name] damage hp stats", "resources")` |
| Recent balance data | `get_recent_simbot_summary(n_runs=5)` |
| What was last implemented | `query_project_knowledge("What was implemented in the most recent prompt?", "architecture")` |
| Test patterns | `query_project_knowledge("test conventions GdUnit4", "architecture")` |

---

## DOMAIN GUIDE

When calling `query_project_knowledge`, set the `domain` parameter for better results:

| Domain | Contents | Use when... |
|---|---|---|
| `all` | Everything | General orientation, cross-cutting questions |
| `architecture` | .md docs (CONVENTIONS, ARCHITECTURE, INDEX files, PROMPT logs) | Understanding project structure, conventions, decisions |
| `code` | .gd scripts | Looking up function implementations, class APIs |
| `resources` | .tres files | Checking stat values, resource definitions |
| `simbot_logs` | .json/.csv logs | Analyzing simulation results, balance data |
| `balance` | resources + logs together | Balance analysis needing both data and sim results |

---

## ABSOLUTE RULES (Never violate these)

1. **NEVER hardcode gameplay values in scripts.** All numbers go in `.tres` resource files.
2. **NEVER emit cross-system signals directly.** Everything goes through `SignalBus`.
3. **NEVER create a scene-instantiated node without an `initialize()` method.**
4. **NEVER skip writing tests.** Every new system gets at least one GdUnit4 test file.
5. **NEVER use `get_node()` with string paths for cross-scene references.** Use autoloads, signals, or typed `@onready`.
6. **ALWAYS use `is_instance_valid()` before accessing enemies, projectiles, or allies** that may be freed mid-frame.
7. **ALWAYS use `get_node_or_null()` with `push_warning()` (not `assert`)** for runtime node lookups that may fail in headless/test mode.
8. **ALWAYS run the test suite** before marking any task complete.
