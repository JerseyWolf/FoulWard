# Batch 3 Report — DamageCalculator Path Fix

Date: 2026-04-14

## Objective

Replace all stale `res://autoloads/damage_calculator.gd` (GDScript) references in active
documentation with the correct C# path `res://autoloads/DamageCalculator.cs`.

Archived files and REPO_DUMP_*.md files were not touched.

---

## Files Changed

### 1. `docs/CONVENTIONS.md`

| Line | Change |
|------|--------|
| 692  | `res://autoloads/damage_calculator.gd` → `res://autoloads/DamageCalculator.cs` (autoload path table) |

### 2. `docs/ARCHITECTURE.md`

| Line | Change |
|------|--------|
| 15   | Table row path `res://autoloads/damage_calculator.gd` → `res://autoloads/DamageCalculator.cs`; description updated to include `(C#)` |
| 152  | Prose heading ``**DamageCalculator** (`damage_calculator.gd`)`` → ``**DamageCalculator** (`DamageCalculator.cs`)`` |
| 641  | Inline prose reference ``see `damage_calculator.gd` for source of truth`` → ``see `DamageCalculator.cs` for source of truth`` |

### 3. `docs/INDEX_FULL.md`

| Line | Change |
|------|--------|
| 264  | `Path: res://autoloads/damage_calculator.gd` → `Path: res://autoloads/DamageCalculator.cs` |
| 265  | Purpose line updated: added `(C# implementation)` to note the implementation language |

---

## Verification

Command run after all edits:

```
grep -rn "damage_calculator\.gd" docs/CONVENTIONS.md docs/ARCHITECTURE.md docs/INDEX_FULL.md
```

Result: **0 matches** (exit code 1 — no output, as expected).

---

## Notes

- 4 occurrences were found across 3 files (task spec anticipated 3; one additional in ARCHITECTURE.md was also fixed).
- No files under `docs/archived/` were modified.
- No `REPO_DUMP_*.md` files were modified.
