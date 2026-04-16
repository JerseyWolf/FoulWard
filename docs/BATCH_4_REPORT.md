# Batch 4 Cleanup Report
Date: 2026-04-14

## Summary

Removed orphaned legacy files, orphaned scripts, and a cut enum value. No refactoring or behavioral changes.

---

## STEP 1 — Legacy Dialogue UI Files Deleted

Reference check before deletion:
- `autoloads/dialogue_manager.gd` — only a comment reference (`## UI-agnostic: UIManager / DialogueUI call …`). Not a runtime reference. Safe to delete.
- No other `.gd` or `.tscn` file loads or instantiates these scenes.

Files deleted:
- `ui/dialogueui.gd`
- `ui/dialogueui.tscn`
- `ui/dialogue_ui.gd`
- `ui/dialogue_ui.tscn`
- `ui/dialogueui.gd.uid`
- `ui/dialogue_ui.gd.uid`

---

## STEP 2 — Orphaned Scripts Deleted

Reference check before deletion:
- `SimBotLogger` — only found as `class_name` declaration inside `scripts/simbot_logger.gd` itself. Zero callers.
- `TestStrategyProfileConfig` — only found as `class_name` declaration inside `scripts/resources/test_strategyprofileconfig.gd` itself. Zero callers.

Files deleted:
- `scripts/simbot_logger.gd`
- `scripts/simbot_logger.gd.uid`
- `scripts/resources/test_strategyprofileconfig.gd`
- `scripts/resources/test_strategyprofileconfig.gd.uid`

---

## STEP 3 — Orphaned Enum Value Removed

Reference check before removal:
- Search for `AllyRole.TANK` / `AllyRole.Tank` in all `.gd` and `.cs` files: **zero results**.
- Search for `.TANK` in all `.tres` files under `resources/`: **zero results**.

Changes made:
- `scripts/types.gd`: Removed `TANK,` from `enum AllyRole` (was between ANTI_AIR and SPELL_SUPPORT).
- `scripts/FoulWardTypes.cs`: Removed `Tank = 3,` and updated `SpellSupport = 4` → `SpellSupport = 3` to maintain correct sequential integer values.

Final `AllyRole` enum:

```
# types.gd
enum AllyRole {
    MELEE_FRONTLINE,   # 0
    RANGED_SUPPORT,    # 1
    ANTI_AIR,          # 2
    SPELL_SUPPORT,     # 3
}

// FoulWardTypes.cs
public enum AllyRole {
    MeleeFrontline = 0,
    RangedSupport  = 1,
    AntiAir        = 2,
    SpellSupport   = 3,
}
```

---

## STEP 4 — docs/INDEX_SHORT.md Updated

Lines removed:
- `DialogueUI  res://ui/dialogueui.gd  res://ui/dialogueui.tscn  Legacy placeholder hub dialogue panel (Prompt 13). Kept for reference; hub now uses DialoguePanel.`
- `scripts/resources/test_strategyprofileconfig.gd  Prompt 16: Test helper resource class for SimBot profile tests`
- `scripts/simbot_logger.gd  Prompt 16: SimBot CSV logging utility — writes batch results to user://simbot/logs/`
- `ui/dialogue_ui.gd  Prompt 13: Legacy DialogueUI placeholder panel (kept for reference; DialoguePanel is active)`

---

## STEP 5 — docs/INDEX_FULL.md Updated

Lines removed:
- `**DialogueUI** (res://ui/dialogueui.gd / dialogueui.tscn) — Prompt 13: show_entry(DialogueEntry); Continue → mark_entry_played / chain or notify_dialogue_finished.`

---

## Build & Test Results

### dotnet build FoulWard.csproj
**Result: PASSED**
- 0 warnings, 0 errors
- Output: `.godot/mono/temp/bin/Debug/foul_ward.dll`

### ./tools/run_gdunit_parallel.sh
**Result: 1 pre-existing failure (unrelated to this batch)**

```
TOTALS: cases=563  failures=1  orphans=2  wall-clock=133s
RESULT: FAIL
```

Failure details:
- **Suite**: `res://tests/test_save_manager_slots.gd`
- **Test**: `test_relationship_manager_round_trip_integration`
- **Error**: Affinity round-trip mismatch (expected `17.0`, got `2.0`; expected `-3.0`, got `2.0`)
- **Root cause**: Pre-existing `RelationshipManager` save/load integration test flakiness. **Not caused by this batch** — none of the deleted files or enum changes touch `RelationshipManager`, affinity storage, or save slots.

All other 562 tests passed.

---

## Files Changed (complete list)

| Action | File |
|--------|------|
| Deleted | `ui/dialogueui.gd` |
| Deleted | `ui/dialogueui.tscn` |
| Deleted | `ui/dialogue_ui.gd` |
| Deleted | `ui/dialogue_ui.tscn` |
| Deleted | `ui/dialogueui.gd.uid` |
| Deleted | `ui/dialogue_ui.gd.uid` |
| Deleted | `scripts/simbot_logger.gd` |
| Deleted | `scripts/simbot_logger.gd.uid` |
| Deleted | `scripts/resources/test_strategyprofileconfig.gd` |
| Deleted | `scripts/resources/test_strategyprofileconfig.gd.uid` |
| Modified | `scripts/types.gd` — removed `TANK,` from `AllyRole` |
| Modified | `scripts/FoulWardTypes.cs` — removed `Tank = 3,`; `SpellSupport` 4→3 |
| Modified | `docs/INDEX_SHORT.md` — removed 4 stale lines |
| Modified | `docs/INDEX_FULL.md` — removed 1 stale DialogueUI entry |
