# PROMPT 25 — SaveManager rolling autosaves (AUDIT 6 §3.5)

## Scope

Rolling disk saves per campaign/endless **attempt**, autosave after combat resolution, main-menu resume, and serialization across core autoloads/managers.

## Done

1. **`res://autoloads/save_manager.gd`** — Autoload singleton **without** `class_name` (avoids clashing with the autoload name). `user://saves/attempt_{attempt_id}/slot_{0..4}.json` (slot 0 = newest; shift on save; load discards newer slots than the loaded index). `start_new_attempt()`, `has_resumable_attempt()`, `get_available_slots()`, `load_slot()`, `save_current_state()`, `clear_all_saves_for_test()` for GdUnit.

2. **`project.godot`** — `SaveManager` registered immediately after `GameManager`.

3. **Serialization** — `get_save_data()` / `restore_from_save()` on **CampaignManager**, **GameManager**, **ResearchManager**, **ShopManager** (existing consumable dict), **EnchantmentManager**. **EconomyManager** `apply_save_snapshot()`; **SpellManager** `set_mana_for_save_restore()`. **GameManager** `apply_save_held_territory_ids()`; save blob uses `CampaignManager.get_current_day()` for `current_day` alignment.

4. **Autosave** — End of **`GameManager._ready()`**: `SignalBus.mission_won` and `mission_failed` → `SaveManager.save_current_state` (connected after other setup in that function).

5. **Main menu** — `ResumeButton` when `has_resumable()`; resume = `load_slot(0)` + `game_state_changed`. New Campaign / Endless: `SaveManager.start_new_attempt()` before `GameManager.start_new_game()`.

6. **Tests** — `res://tests/test_save_manager.gd` (slot file, shift, restore day, discard newer, no-saves). Listed in `tools/run_gdunit_quick.sh`.

## Note

Full `./tools/run_gdunit.sh` may be run locally before merge; quick suite used during implementation.
