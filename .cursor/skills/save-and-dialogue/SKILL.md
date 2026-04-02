---
name: save-and-dialogue
description: >-
  Activate when working with save/load, autosave, dialogue, relationship
  affinity, or character conditions in Foul Ward. Use when: save, load,
  autosave, save slot, attempt, restore, dialogue, conversation, relationship,
  affinity, tier, DialogueManager, SaveManager, RelationshipManager,
  DialogueEntry, condition keys, character_id, once_only, chain_next_id.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Save and Dialogue — Foul Ward

---

## SaveManager (Autoload #13)

File: `autoloads/save_manager.gd`
**No `class_name`** — intentional, prevents GdUnit autoload shadowing. Do not add one.

Rolling autosaves to `user://saves/attempt_*/slot_*.json`. 5 slots.

```gdscript
SaveManager.start_new_attempt() -> void
SaveManager.save_current_state() -> void    # builds payload from all managers, writes slot 0
SaveManager.load_slot(slot_index: int) -> bool
SaveManager.get_available_slots() -> Array[int]
SaveManager.has_resumable_attempt() -> bool
SaveManager.clear_all_saves_for_test() -> void  # test helper only
```

**Save payload structure:**
```gdscript
{
    version: int,
    attempt_id: String,
    campaign: {},      # CampaignManager.get_save_data()
    game: {},          # GameManager.get_save_data()
    relationship: {},  # RelationshipManager.get_save_data()
    research: {},      # ResearchManager.get_save_data()
    shop: {},          # ShopManager.get_save_data()
    enchantments: {}   # EnchantmentManager.get_save_data()
}
```

**Critical:** `save_current_state()` is called automatically on `mission_won` and
`mission_failed`. Do NOT add extra save calls elsewhere.

**When adding a new saveable system:** wire both `get_save_data()` and
`restore_from_save()` into `SaveManager._build_save_payload()` and
`_apply_save_payload()` immediately — see anti-pattern AP-14.

---

## DialogueManager (Autoload #14)

File: `autoloads/dialogue_manager.gd`
Loads `DialogueEntry` .tres from `res://resources/dialogue/`.

```gdscript
DialogueManager.request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry
DialogueManager.get_entry_by_id(entry_id: String) -> DialogueEntry
DialogueManager.mark_entry_played(entry_id: String) -> void
DialogueManager.notify_dialogue_finished(entry_id: String, character_id: String) -> void
DialogueManager.on_campaign_day_started() -> void
DialogueManager.get_tracked_gold() -> int
DialogueManager.get_unlocked_research_ids_snapshot() -> Dictionary
DialogueManager.get_total_shop_purchases_tracked() -> int
DialogueManager.get_arnulf_state_tracked() -> Types.ArnulfState
DialogueManager.get_spell_cast_count_tracked() -> int
```

**Local signals** (NOT on SignalBus — known convention exception):
```gdscript
signal dialogue_line_started(entry_id: String, character_id: String)
signal dialogue_line_finished(entry_id: String, character_id: String)
```
UIManager connects to `dialogue_line_finished` directly on the DialogueManager node.

**Condition keys** for `DialogueEntry.conditions`:
`current_mission_number`, `mission_won_count`, `gold_amount`,
`sybil_research_unlocked_any`, `arnulf_research_unlocked_any`,
`research_unlocked_<id>`, `shop_item_purchased_<id>`,
`arnulf_is_downed`, `florence.*`, `campaign.*`

**7 character IDs:**
`FLORENCE`, `COMPANION_MELEE`, `SPELL_RESEARCHER`, `MERCHANT`,
`WEAPONS_ENGINEER`, `ENCHANTER`, `MERCENARY_COMMANDER`

**All 15 dialogue entries are TODO placeholders** as of Prompt 51.

---

## RelationshipManager (Autoload #7)

File: `autoloads/relationship_manager.gd`
**No `class_name`** — intentional. Do not add one.

Affinity range: −100..100 per `character_id`. Tiers from `relationship_tier_config.tres`.

```gdscript
RelationshipManager.get_affinity(character_id: String) -> float
RelationshipManager.get_tier(character_id: String) -> String        # e.g. "Hostile", "Neutral", "Friendly"
RelationshipManager.get_tier_rank_index(tier_name: String) -> int
RelationshipManager.add_affinity(character_id: String, delta: float) -> void
RelationshipManager.reload_from_resources() -> void
RelationshipManager.get_save_data() -> Dictionary                   # {affinities: {id: float}}
RelationshipManager.restore_from_save(data: Dictionary) -> void
```

Relationship events driven by `RelationshipEventData` .tres resources.
**Do not hardcode affinity delta values in .gd files** — always via resource.
