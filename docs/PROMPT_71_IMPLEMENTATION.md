# PROMPT_71_IMPLEMENTATION — Group 9 (S05): Hub dialogue content & combat lines

**Date:** 2026-04-18  
**Scope:** Per `docs/perplexity_sessions/IMPLEMENTATION_PROMPTS.md` Group 9 (lines 1906–2137).

## Summary

- **`DialogueEntry`:** `@export var is_combat_line: bool = false` in `scripts/resources/dialogue/dialogue_entry.gd`.
- **Hub content:** 30 new `.tres` files across `resources/dialogue/{companion_melee,spell_researcher,merchant,weapons_engineer,enchanter,mercenary_commander}/` (intro/research/generic per NPC). Removed obsolete placeholder `.tres` in those six folders.
- **Combat content:** 10 `.tres` under `resources/dialogue/combat/` with `is_combat_line = true` and combat condition keys.
- **`DialogueManager`:** Per-mission combat state; `_resolve_state_value` keys `first_blood`, `wave_number_gte`, `kills_this_mission_gte`, `boss_active`, `florence_damaged`; `peek_entry_for_character` (no `dialogue_line_started`); `request_combat_line` + `_seen_combat_lines`; hub path excludes `is_combat_line`; connects `enemy_killed`, `wave_started`, `florence_damaged`, `boss_spawned`; calls `request_combat_line()` from combat handlers; resets state on `mission_started`.
- **`SignalBus`:** `combat_dialogue_requested(entry: DialogueEntry)` — **77** `^signal ` lines (verified 2026-04-18).
- **UI:** `scripts/ui/combat_dialogue_banner.gd`, `scenes/ui/combat_dialogue_banner.tscn`; instance under `Main/UI/UIManager` in `scenes/main.tscn`.
- **Hub Talk button:** `scenes/hub/character_base_2d.tscn` + `character_base_2d.gd` — `TalkButton`, `_refresh_talk_button()` via `peek_entry_for_character`, `SignalBus.dialogue_line_finished` + `mission_started`.
- **Tests:** `tests/test_dialogue_content.gd`, `tests/test_combat_dialogue.gd` (+12 cases). `tests/test_dialogue_manager.gd` reset extended for combat vars; `test_get_line_for_character_returns_sybil_hub_line` replaces TODO placeholder assertion.
- **`tools/run_gdunit_quick.sh`:** allowlist includes `test_dialogue_content.gd`, `test_combat_dialogue.gd`.
- **Docs:** Signal count **77** in `AGENTS.md`, `.cursor/skills/signal-bus/SKILL.md`, `references/signal-table.md`, `docs/FOUL_WARD_MASTER_DOC.md`, `docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`, `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, `docs/AGENTS.md` (under `docs/`).

## Verification

- `./tools/run_gdunit_quick.sh` (includes new suites; full project run may hit known GdUnit/engine edge cases — use `./tools/run_gdunit.sh` before merge).
- Targeted: `GdUnitCmdTool.gd` with `-a res://tests/test_dialogue_content.gd` and `test_combat_dialogue.gd` — 12/12 passed.

## Files touched (representative)

| Area | Paths |
|------|--------|
| Resource | `dialogue_entry.gd`, 30 hub + 10 combat `.tres` |
| Autoload | `dialogue_manager.gd`, `signal_bus.gd` |
| Hub | `character_base_2d.gd`, `character_base_2d.tscn` |
| UI | `combat_dialogue_banner.gd`, `combat_dialogue_banner.tscn`, `main.tscn` |
| Tests | `test_dialogue_content.gd`, `test_combat_dialogue.gd`, `test_dialogue_manager.gd` |
| Tooling | `run_gdunit_quick.sh` |
