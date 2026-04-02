---
name: campaign-and-progression
description: >-
  Activate when working with the campaign, mission flow, days, territories,
  world map, or game state transitions in Foul Ward. Use when: campaign,
  day, mission, progression, territory, world map, endless mode, CampaignManager,
  GameManager, game state, state transition, day config, next day, ally roster,
  mercenary offers, DayConfig, WAVES_PER_MISSION, TOTAL_MISSIONS.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Campaign and Progression — Foul Ward

---

## Campaign Structure

- **50-day main campaign** (`50_day_campaign.tres`)
- **5-day short campaign** (`5_day_campaign.tres`)
- **Endless mode**: synthetic scaling, no day limit
- `WAVES_PER_MISSION = 5` (5 waves per mission)
- `TOTAL_MISSIONS = 5`

*Verified against `autoloads/game_manager.gd` constants (2026-03-31).*

---

## Init Order Critical

CampaignManager (Init #6) MUST load before GameManager (Init #9).
`mission_won` signal listeners run in autoload registration order.
CampaignManager's day increment must fire before GameManager's hub transition.

> ⚠️ NOTE: `GameManager.advance_to_next_day()` and the `current_day_index` setter call `CampaignManager.force_set_day()` (DIAG-1 mitigation). Do not assign to `CampaignManager.current_day` directly from other systems. See AGENTS.md Known Gotchas 6–7.

---

## CampaignManager API (Init #6)

```gdscript
CampaignManager.start_new_campaign() -> void
CampaignManager.start_endless_run() -> void
CampaignManager.start_next_day() -> void
CampaignManager.force_set_day(day: int) -> void        # edge paths / tests; normal advance via mission_won
CampaignManager.get_current_day() -> int              # 1-based
CampaignManager.get_campaign_length() -> int
CampaignManager.get_current_day_config() -> DayConfig
CampaignManager.validate_day_configs(day_configs: Array[DayConfig]) -> void

# Ally roster
CampaignManager.is_ally_owned(ally_id: String) -> bool
CampaignManager.get_owned_allies() -> Array[String]
CampaignManager.get_active_allies() -> Array[String]
CampaignManager.get_ally_data(ally_id: String) -> Resource
CampaignManager.add_ally_to_roster(ally_id: String) -> void
CampaignManager.remove_ally_from_roster(ally_id: String) -> void
CampaignManager.toggle_ally_active(ally_id: String) -> bool
CampaignManager.set_active_allies_from_list(ally_ids: Array[String]) -> void
CampaignManager.get_allies_for_mission_start() -> Array[String]

# Mercenaries
CampaignManager.generate_offers_for_day(day: int) -> void
CampaignManager.preview_mercenary_offers_for_day(day: int, hypothetical_owned: Array[String]) -> Array
CampaignManager.get_current_offers() -> Array
CampaignManager.purchase_mercenary_offer(index: int) -> bool
CampaignManager.notify_mini_boss_defeated(boss_id: String) -> void
CampaignManager.auto_select_best_allies(strategy, offers, roster, max_purchases, budget_gold, budget_material, budget_research) -> Dictionary

# Save/load
CampaignManager.get_save_data() -> Dictionary
CampaignManager.restore_from_save(data: Dictionary) -> void
```

**Key state:** `max_active_allies_per_day = 2`

---

## Game State Transition Graph

MAIN_MENU
→ MISSION_BRIEFING
→ COMBAT ↔ BUILD_MODE
→ WAVE_COUNTDOWN
→ (COMBAT loop)
→ MISSION_WON → BETWEEN_MISSIONS → MISSION_BRIEFING...
→ MISSION_FAILED → BETWEEN_MISSIONS → MISSION_BRIEFING...
→ GAME_WON (after day 50)
→ GAME_OVER
→ ENDLESS


**PLANNED states** (not in code): `RING_ROTATE`, `PASSIVE_SELECT`

---

## Territory System

5 territories with passive bonuses. Read `references/game-manager-api.md` for
GameManager territory methods.

Key: `get_current_day_territory() -> TerritoryData`

---

## GameManager Key Methods (Init #9)

```gdscript
GameManager.start_new_game() -> void           # Full reset; calls CampaignManager
GameManager.start_next_mission() -> void
GameManager.start_wave_countdown() -> void     # MISSION_BRIEFING → COMBAT
GameManager.enter_build_mode() -> void         # COMBAT → BUILD_MODE (time_scale 0.1)
GameManager.exit_build_mode() -> void          # BUILD_MODE → COMBAT (time_scale 1.0)
GameManager.get_game_state() -> Types.GameState
GameManager.get_current_mission() -> int       # 1-indexed
GameManager.get_current_wave() -> int
GameManager.get_current_day_index() -> int
```

For full GameManager API (30+ methods), read `references/game-manager-api.md`.

---
