## Prompt 14 — Between-mission hub framework (implementation log)

### 2026-03-25 (work so far)

Implemented the foundation of the data-driven hub system:

1. **Types**
   - Added `enum HubRole` to `res://scripts/types.gd`.

2. **Resources (data-driven hub cast)**
   - Added `CharacterData` and `CharacterCatalog` resource scripts:
     - `res://scripts/resources/character_data.gd`
     - `res://scripts/resources/character_catalog.gd`
   - Added initial hub cast resources:
     - `res://resources/character_data/merchant.tres`
     - `res://resources/character_data/researcher.tres`
     - `res://resources/character_data/enchantress.tres`
     - `res://resources/character_data/mercenary_captain.tres`
     - `res://resources/character_data/arnulf_hub.tres`
     - `res://resources/character_data/flavor_npc_01.tres`
   - Added catalog:
     - `res://resources/character_catalog.tres`

3. **Hub UI (2D)**
   - Added clickable hub character UI:
     - `res://scenes/hub/character_base_2d.tscn`
     - `res://scenes/hub/character_base_2d.gd`
     - Emits `character_interacted(character_id: String)`
   - Added 2D hub overlay manager:
     - `res://ui/hub.tscn`
     - `res://ui/hub.gd` (`class_name Hub2DHub`)
     - Public API: `open_hub()`, `close_hub()`, `focus_character(character_id)`, `set_between_mission_screen(screen)`, `_set_ui_manager(ui_manager)`

4. **DialoguePanel overlay**
   - Added global click-to-continue dialogue overlay:
     - `res://ui/dialogue_panel.tscn`
     - `res://ui/dialogue_panel.gd` (`class_name DialoguePanel`)
   - Updated `DialogueManager` with stable APIs needed by `DialoguePanel`:
     - `get_entry_by_id(entry_id: String)`
     - `request_entry_for_character(character_id: String, tags: Array[String] = [])`

5. **UI integration**
   - Updated `UIManager` (`res://ui/ui_manager.gd`) to:
     - wire hub references
     - show/close hub on `BETWEEN_MISSIONS` transitions
     - add hub/dialogue helpers: `show_dialogue(display_name, entry)` and `clear_dialogue()`
     - route existing `show_dialogue_for_character()` through `DialoguePanel`
   - Updated `BetweenMissionScreen` with panel helper methods:
     - `open_shop_panel()`, `open_research_panel()`, `open_enchant_panel()`, `open_mercenary_panel()`

6. **Scene wiring**
   - Updated `res://scenes/main.tscn`:
     - instanced `res://ui/hub.tscn` as `Main/UI/Hub`
     - instanced `res://ui/dialogue_panel.tscn` as `Main/UI/UIManager/DialoguePanel`

7. **Test/stub robustness (headless safety)**
   - Updated `res://ui/ui_manager.gd` to avoid stale `@onready` references in GdUnit stubs:
     - `_get_hub()` performs a safe re-fetch fallback (by path / name).
     - `_get_dialogue_panel()` re-fetches `DialoguePanel` dynamically before hiding/clearing.
   - This fixed `test_next_mission_closes_hub_and_clears_dialogue` in `res://tests/test_character_hub.gd`.

### Next steps

- Update `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md` to reflect the new enum, resources, scenes, methods/signals, and test suites.
- Run GdUnit quick/full to validate hub/resources/dialogue panel integration.

