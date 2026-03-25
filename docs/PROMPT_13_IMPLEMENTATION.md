# Prompt 13 — Hub dialogue system (implementation log)

## Summary

**DialogueManager** (`res://autoloads/dialogue_manager.gd`) is a UI-agnostic autoload that:

- Recursively loads all `DialogueEntry` resources under `res://resources/dialogue/**/*.tres`.
- Tracks **priority** selection (highest wins; ties broken with a local RNG), **once-only** lines per run, **active chain** pointers (`chain_next_id` per `character_id`), and simple **AND** condition lists (`DialogueCondition`).
- Listens to **SignalBus** (`game_state_changed`, `mission_started`, `mission_won`, `mission_failed`, plus stubs for resource/research/shop/Arnulf/spell) and reads **EconomyManager** / **GameManager**-synced fields for condition keys.
- Resolves **ResearchManager** via `Main/Managers/ResearchManager` when present (headless tests without `Main` treat research-dependent conditions as false).

Signals: `dialogue_line_started(entry_id, character_id)`, `dialogue_line_finished(entry_id, character_id)`.

Public API: `request_entry_for_character(character_id, context = "")`, `mark_entry_played(entry_id)`, `notify_dialogue_finished(entry_id, character_id)`.

## Character pools (initial)

| Role ID | Folder | Notes |
|---------|--------|--------|
| `SPELL_RESEARCHER` | `resources/dialogue/spell_researcher/` | Sybil-biased: intro (once-only, mission ≥ 2 + hub state), post–spell-unlock hook (`sybil_research_unlocked_any`), generic filler. |
| `COMPANION_MELEE` | `resources/dialogue/companion_melee/` | Arnulf-biased: intro (once-only), `arnulf_research_unlocked_any`, generic. |
| `FLORENCE`, `MERCHANT`, `WEAPONS_ENGINEER`, `ENCHANTER`, `MERCENARY_COMMANDER`, `CAMPAIGN_CHARACTER_X` | respective folders | One placeholder `.tres` each (TODO text only). |
| `EXAMPLE_CHARACTER` | `resources/dialogue/example_character/` | Template: numeric condition, two-part chain. |

All `text` fields are explicit **TODO** placeholders — no story content.

## Condition keys (MVP)

Documented in code in `_resolve_state_value`: `current_mission_number`, `mission_won_count`, `mission_failed_count`, `current_gamestate` (string from `Types.GameState.keys()`), `gold_amount`, `building_material_amount`, `research_material_amount`, `sybil_research_unlocked_any`, `arnulf_research_unlocked_any`, `research_unlocked_<NODE_ID>`, `shop_item_purchased_<ITEM_ID>` (stub **false**).

**TUNING / ASSUMPTION:** `sybil_research_unlocked_any` is true if any `ResearchNodeData.node_id` contains substring `spell` (case-insensitive) and `is_unlocked`. The current shipped research tree may have **no** such IDs — add nodes with `spell` in `node_id` when content is ready. Similarly **`arnulf`** substring for Arnulf-related research; none exist in the default tree yet.

## UI integration

- `res://ui/dialogueui.tscn` + `dialogueui.gd` — minimal panel; **Continue** advances chains and calls `DialogueManager`.
- `UIManager.show_dialogue_for_character` instantiates the scene once, **queues** a second request if a line is already visible (so Sybil then Arnulf do not overwrite each other).
- `BetweenMissionScreen` calls both roles when entering `BETWEEN_MISSIONS`.

## Adding new lines (data-only)

1. Create a new `.tres` with `script = ExtResource(... dialogue_entry.gd)`, set `entry_id` (unique), `character_id`, `text` (TODO), `priority`, `once_only`, `chain_next_id`, and `conditions` (sub-resources using `dialogue_condition.gd`).
2. Place the file under `res://resources/dialogue/<role_folder>/` (any subfolder — loader scans recursively).
3. No code changes required unless you introduce a **new condition key** — then extend `_resolve_state_value` in `dialogue_manager.gd`.

## Tests

`res://tests/test_dialogue_manager.gd` — GdUnit4: conditions, priority, equal-priority bucket, once-only, chain preference, chain fallback when conditions fail, loaded data TODO check, folder load count.

## Verification

- Autoload: `DialogueManager` registered in `project.godot` after `GameManager`.
- Full suite: `./tools/run_gdunit.sh`; iteration: `./tools/run_gdunit_quick.sh` (includes `test_dialogue_manager.gd`).
