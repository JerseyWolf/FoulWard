# Context Brief — Session 5: Dialogue Content

## AI Companions (§2.2)

### Arnulf
- Role: Melee frontline ally, autonomous fighter
- ally_id: arnulf, max_hp: 200, basic_attack: 25.0, is_unique: true, is_starter_ally: true
- Full state machine: IDLE, PATROL, CHASE, ATTACK, DOWNED, RECOVERING
- Drunkenness system: FORMALLY CUT. Do not reference active drunkenness mechanics, only as past-tense character flavor.

### Sybil
- Role: Spell researcher / spell support
- Manages the spell system via SpellManager

## Hub Screens (§15)

- hub.tscn — 2D hub with CharacterCatalog. All TODO(ART).
- between_mission_screen.tscn — TabContainer: World Map, Shop, Research, Buildings, Weapons, Mercenaries.
- dialogue_panel.tscn — Click-to-continue dialogue overlay.
- Hub keeper presence: TAUR-style functional screens (NOT Hades-style 3D hub — FORMALLY CUT).

## Dialogue System (§17)

EXISTS IN CODE (all content is placeholder)

15 DialogueEntry .tres files. All TODO: text. Priority, AND conditions, once-only, chain_next_id.

Characters: FLORENCE, COMPANION_MELEE, SPELL_RESEARCHER, MERCHANT, WEAPONS_ENGINEER, ENCHANTER, MERCENARY_COMMANDER.

## DialogueManager API (§3.14)

| Signature | Returns | Usage |
|-----------|---------|-------|
| request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry | DialogueEntry | Highest-priority eligible entry |
| get_entry_by_id(entry_id: String) -> DialogueEntry | DialogueEntry | Direct lookup |
| mark_entry_played(entry_id: String) -> void | void | Marks once_only as played; activates chain |
| notify_dialogue_finished(entry_id: String, character_id: String) -> void | void | Emits dialogue_line_finished; clears chain |

Signals (now on SignalBus, moved from DialogueManager in batch 1):
- dialogue_line_started(entry_id: String, character_id: String)
- dialogue_line_finished(entry_id: String, character_id: String)

Condition keys: current_mission_number, mission_won_count, gold_amount, sybil_research_unlocked_any, arnulf_research_unlocked_any, research_unlocked_<id>, shop_item_purchased_<id>, arnulf_is_downed, florence.*, campaign.*.

## Formally Cut Features (§31)
| Feature | Status |
|---------|--------|
| Arnulf drunkenness system | FORMALLY CUT — do not implement |
| Time Stop spell | FORMALLY CUT |
| Hades-style 3D navigable hub | FORMALLY CUT |

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- Signals: past tense for events, present for requests
