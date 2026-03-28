# AUDIT_CONTEXT_SUMMARY.md

**Generated for:** Sonnet code-audit instances  
**Source:** Opus documentation synthesis from Prompts 1–17  
**Date:** 2026-03-26

---

## Section 1 — Project Overview

- **FOUL WARD** is an active fantasy tower-defense game built in Godot 4 / GDScript. The player controls a stationary Tower at the center of a hex-grid map, aiming and shooting with the mouse. Automated buildings, AI allies, and spells provide layered real-time defense. Inspired by TAUR (Echo Entertainment, 2020).
- **Campaign structure:** Up to 50 days per campaign. Each day = one battle. Day 50 introduces the campaign boss. Free version ships one campaign + one endless mode. Paid campaigns add new factions, characters, and plotlines.
- **Core loop:** Direct aiming/shooting (Florence's crossbow + rapid missile), strategic hex-grid building placement, passive AI melee companion (Arnulf) + generic allies, hotkey spellcasting (Shockwave MVP), between-mission progression (shop, research, enchanting, mercenary recruitment, world map).
- **Core systems present after Prompts 1–17:**
  - Sell UX in build mode (Prompt 1)
  - Firing assist / miss perturbation system (Prompt 2)
  - Weapon upgrade station with leveled data (Prompt 3)
  - Two-slot enchantment system with EnchantmentManager autoload (Prompt 4)
  - DoT system — burn/poison on building projectiles (Prompt 5)
  - Solid building collision + NavigationObstacle3D for enemy pathing (Prompt 6)
  - Campaign/day abstraction with CampaignManager (Prompt 7)
  - Territory system, world map, 50-day CampaignConfig (Prompt 8)
  - Faction system with weighted wave composition (Prompt 9)
  - Mini-boss + campaign boss + Day 50 loop (Prompt 10)
  - Generic ally framework — AllyBase, AllyData, CampaignManager roster (Prompt 11)
  - Mercenary offers, purchases, mini-boss defection, SimBot mercenary hooks (Prompt 12)
  - Hub dialogue system — DialogueManager autoload, Hades-model priority/condition/chain (Prompt 13)
  - Between-mission 2D hub with clickable characters, DialoguePanel overlay (Prompt 14)
  - Florence meta-state scaffold — FlorenceData, day advance reasons, dialogue condition hooks (Prompt 15)
  - SimBot strategy profiles, `run_single`/`run_batch`, CSV balance logging (Prompt 16)
  - Art placeholder pipeline — `ArtPlaceholderHelper`, `res://art/` hierarchy, scene wiring (Prompt 17)
- **Prompts 16 and 17 are the newest, least-indexed work.** Prompt 16 added `StrategyProfile` resource, SimBot headless batch runs, and CSV logging. Prompt 17 added the art placeholder helper and primitive mesh/material resources under `res://art/`. Both are partially reflected in INDEX files (see Section 7).
- **Test framework:** GdUnit4. Approximately **440 test cases** across ~40+ test files as of Prompt 17. Full suite: `./tools/run_gdunit.sh`. Quick subset: `./tools/run_gdunit_quick.sh`.
- **Source of truth hierarchy Sonnet must use (descending priority):**
  1. `Foul Ward - end product estimate.md` — design law (what the game is supposed to be)
  2. `ARCHITECTURE.md` + `CONVENTIONS.md` — implementation law (how the code must be structured)
  3. `INDEX_FULL.md` + `PROMPT_X_IMPLEMENTATION.md` — implementation record (what was documented as done)
  4. REPO_DUMP code — ground truth (what actually exists)
- **Critical constraints Sonnet must not forget:**
  - **No UI logic in game scripts.** UI scripts are pure presentation + delegation.
  - **No game logic in `input_manager.gd` or any `res://ui/` script.** InputManager is a thin translation layer only.
  - **SimBot headless API:** All simulation methods must never touch UI nodes. All manager public methods must be callable without `main.tscn` present.
  - **All cross-system signals must be declared in `signal_bus.gd` before use.** Local signals (within one scene tree) may live on the emitting node.
  - **Signal names must be `snake_case` past-tense verbs** for events that happened, present-tense for requests.
  - **No magic numbers.** All gameplay constants live in `.tres` resources or `types.gd`.
  - **Type safety.** All function parameters, return types, and variable declarations must have explicit types.
  - **`_physics_process` for game logic, `_process` for UI.** Never mix.
- **PROBLEM_REPORT.md was referenced but not provided to this synthesis.** Known issues are reconstructed from PROMPT_X_IMPLEMENTATION files below. Sonnet should check whether a separate PROBLEM_REPORT.md exists in the repo and treat it as authoritative if found.

---

## Section 2 — Prompt-by-Prompt Implementation Record

### Prompt 1 — Sell UX in build mode

**Status:** Fully implemented

**Files added [NEW]:**
- (none — all modifications to existing files)

**Files modified [MODIFIED]:**
- `res://scripts/input_manager.gd` — Added build-mode left-click raycast on layer 7, occupancy-aware routing to BuildMenu placement/sell
- `res://ui/build_menu.gd` — Added `open_for_sell_slot()`, sell panel handlers (Sell/Cancel)
- `res://ui/build_menu.tscn` — Added SellPanel UI (BuildingNameLabel, UpgradeStatusLabel, RefundLabel, buttons)
- `res://scenes/hex_grid/hex_grid.gd` — Slot click now only highlights; removed direct BuildMenu open
- `res://tests/test_hex_grid.gd` — Added sell-flow tests (3 new cases)

**Key decisions and deviations:**
- InputManager remains pure input router; no game logic added
- HexGrid no longer opens BuildMenu directly — centralized in InputManager
- Between-mission sell UX explicitly deferred as POST-MVP

**Explicitly deferred POST-MVP:**
- Between-mission sell interface

**Remaining known issues:**
- Phase 6 playtest rows 5–7, 10 not fully confirmed (Sybil shockwave, Arnulf full verify, between-mission full loop)

---

### Prompt 2 — Firing assist and miss perturbation

**Status:** Fully implemented

**Files added [NEW]:**
- (none — all modifications)

**Files modified [MODIFIED]:**
- `res://scripts/resources/weapon_data.gd` — Added `assist_angle_degrees`, `assist_max_distance`, `base_miss_chance`, `max_miss_angle_degrees` (all default `0.0`)
- `res://resources/weapon_data/crossbow.tres` — Initial tuning: `7.5 / 0.0 / 0.05 / 2.0`
- `res://resources/weapon_data/rapid_missile.tres` — All assist/miss fields at `0.0` (deterministic)
- `res://scenes/tower/tower.gd` — Added `_resolve_manual_aim_target()` private helper; applied in crossbow and rapid missile fire paths
- `res://tests/test_simulation_api.gd` — Added assist/miss coverage

**Key decisions and deviations:**
- Assist/miss applies only to manual shots (`auto_fire_enabled == false`); autofire/SimBot bypasses entirely
- Public firing API signatures unchanged
- `ProjectileBase.initialize_from_weapon()` contract unchanged
- Uses project-approved deterministic RNG (seedable for tests/SimBot)
- `SignalBus.projectile_fired` now emits the adjusted target position

**Explicitly deferred POST-MVP:**
- (none)

**Remaining known issues:**
- (none documented)

---

### Prompt 3 — Weapon upgrade station

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/weapon_level_data.gd` — WeaponLevelData resource class
- `res://scripts/weapon_upgrade_manager.gd` — WeaponUpgradeManager scene-bound manager
- `res://resources/weapon_level_data/crossbow_level_{1..3}.tres` — Level data
- `res://resources/weapon_level_data/rapid_missile_level_{1..3}.tres` — Level data
- `res://tests/test_weapon_upgrade_manager.gd` — Manager test suite

**Files modified [MODIFIED]:**
- `res://autoloads/signal_bus.gd` — Added `weapon_upgraded(weapon_slot, new_level)`
- `res://autoloads/game_manager.gd` — `start_new_game()` resets WeaponUpgradeManager
- `res://scenes/tower/tower.gd` — Runtime manager lookup via `/root/Main/Managers/WeaponUpgradeManager`; null-guard fallback
- `res://scenes/main.tscn` — Added `Managers/WeaponUpgradeManager` node
- `res://ui/between_mission_screen.tscn` — Added WeaponsTab
- `res://ui/between_mission_screen.gd` — Upgrade UI refresh and handlers

**Key decisions and deviations:**
- Tower resolves effective stats via manager with fallback to raw WeaponData when manager absent
- Base `.tres` kept immutable via `duplicate()` override path

**Explicitly deferred POST-MVP:**
- Save/load persistence for weapon levels

**Remaining known issues:**
- (none documented)

---

### Prompt 4 — Two-slot enchantment system

**Status:** Fully implemented

**Files added [NEW]:**
- `res://autoloads/enchantment_manager.gd` — EnchantmentManager autoload [DOCUMENTED DEVIATION: not in original ARCHITECTURE.md §1]
- `res://scripts/resources/enchantment_data.gd` — EnchantmentData resource class
- `res://resources/enchantments/{scorching_bolts,sharpened_mechanism,toxic_payload,arcane_focus}.tres`
- `res://tests/test_enchantment_manager.gd`
- `res://tests/test_tower_enchantments.gd`

**Files modified [MODIFIED]:**
- `res://autoloads/signal_bus.gd` — Added `enchantment_applied(...)`, `enchantment_removed(...)`
- `res://scenes/projectiles/projectile_base.gd` — `initialize_from_weapon()` now accepts optional `custom_damage` and `custom_damage_type`
- `res://scenes/tower/tower.gd` — Added `_compose_projectile_stats()` and `_spawn_weapon_projectile()`; enchantment composition via `"elemental"` and `"power"` slots
- `res://autoloads/game_manager.gd` — `start_new_game()` resets enchantments
- `res://ui/between_mission_screen.tscn` — Enchantment controls under WeaponsTab
- `res://ui/between_mission_screen.gd` — Apply/remove handlers

**Key decisions and deviations:**
- EnchantmentManager is a new autoload NOT in original ARCHITECTURE.md [DOCUMENTED DEVIATION]
- Affinity level/XP tracked as inert state — no gameplay effects yet

**Explicitly deferred POST-MVP:**
- Enchantment affinity gameplay effects

**Remaining known issues:**
- (none documented)

---

### Prompt 5 — DoT system (burn/poison)

**Status:** Fully implemented

**Files added [NEW]:**
- `res://tests/test_enemy_dot_system.gd`

**Files modified [MODIFIED]:**
- `res://autoloads/damage_calculator.gd` — Added `calculate_dot_tick()`
- `res://scripts/resources/building_data.gd` — Added DoT export fields
- `res://scenes/enemies/enemy_base.gd` — Added `active_status_effects`, `apply_dot_effect()`, burn/poison stacking logic
- `res://scenes/projectiles/projectile_base.gd` — `initialize_from_building()` accepts DoT params
- `res://scenes/buildings/building_base.gd` — Passes DoT fields from BuildingData
- `res://resources/building_data/fire_brazier.tres` — DoT defaults
- `res://resources/building_data/poison_vat.tres` — DoT defaults
- `res://tests/test_damage_calculator.gd` — DoT tick tests
- `res://tests/test_projectile_system.gd` — DoT integration

**Key decisions and deviations:**
- DoT runs enemy-local (no new autoload)
- Burn: one stack per source, refresh duration, keep max total_damage
- Poison: additive stacks capped by `MAX_POISON_STACKS`

**Explicitly deferred POST-MVP:**
- (none)

**Remaining known issues:**
- GdUnit CLI may return exit code 101 due to orphan-node warnings (not a Prompt 5 issue)

---

### Prompt 6 — Solid building collision + navigation obstacle

**Status:** Fully implemented

**Files added [NEW]:**
- (none — all modifications)

**Files modified [MODIFIED]:**
- `res://scenes/buildings/building_base.tscn` — Added `BuildingCollision` (StaticBody3D) + `NavigationObstacle3D`
- `res://scenes/buildings/building_base.gd` — Footprint/obstacle tuning constants, enable/disable helpers
- `res://scenes/hex_grid/hex_grid.gd` — Added `_activate_building_obstacle()` hook
- `res://scenes/enemies/enemy_base.tscn` — Updated collision mask to include buildings
- `res://scenes/enemies/enemy_base.gd` — Split into `_physics_process_ground()` / `_physics_process_flying()`, added stuck recovery
- `res://tests/test_enemy_pathfinding.gd` — Replaced with scenario tests
- `res://tests/test_building_base.gd` — Added collision/obstacle assertion

**Key decisions and deviations:**
- No runtime navmesh rebaking — uses NavigationObstacle3D for dynamic avoidance
- Flying enemies remain direct-steering, ignore ground obstacles
- Building footprint: `2.5 x 3.0 x 2.5`; obstacle radius: `2.0`
- No new SignalBus signals introduced

**Explicitly deferred POST-MVP:**
- Runtime navmesh rebaking (if buildings need to block paths as walls)

**Remaining known issues:**
- (none documented)

---

### Prompt 7 — Campaign/day abstraction layer

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/day_config.gd` — DayConfig resource class
- `res://scripts/resources/campaign_config.gd` — CampaignConfig resource class
- `res://resources/campaigns/campaign_short_5_days.tres`
- `res://resources/campaigns/campaign_main_50_days.tres`
- `res://autoloads/campaign_manager.gd` — CampaignManager autoload
- `res://tests/test_campaign_manager.gd`

**Files modified [MODIFIED]:**
- `res://project.godot` — CampaignManager registered before GameManager
- `res://autoloads/signal_bus.gd` — Campaign/day lifecycle signals
- `res://autoloads/game_manager.gd` — Campaign-owned mission kickoff, `start_mission_for_day()`
- `res://scripts/wave_manager.gd` — `configure_for_day()`, configurable wave cap, day multipliers
- `res://ui/between_mission_screen.gd` / `.tscn` — Day progression display
- `res://tests/test_wave_manager.gd` — Prompt 7 additions
- `res://tests/test_game_manager.gd` — Prompt 7 additions

**Key decisions and deviations:**
- [DOCUMENTED DEVIATION] `GameManager.start_next_mission()` now delegates to `CampaignManager.start_next_day()`
- [DOCUMENTED DEVIATION] WaveManager supports per-day wave cap and difficulty multipliers
- Short-campaign flow maps `mission_number == day_index` [ASSUMPTION]

**Explicitly deferred POST-MVP:**
- Mini/final boss fields data-ready but not consumed by gameplay logic (resolved in Prompt 10)

**Remaining known issues:**
- GdUnit CLI argument issue (environment/runner, not code)

---

### Prompt 8 — Territory system + world map + 50-day data

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/territory_data.gd` — TerritoryData
- `res://scripts/resources/territory_map_data.gd` — TerritoryMapData
- `res://resources/territories/main_campaign_territories.tres` — 5 placeholder territories
- `res://resources/campaign_main_50days.tres` — Canonical 50-day campaign
- `res://ui/world_map.gd` / `world_map.tscn` — Territory list + details
- `res://tests/test_territory_data.gd`
- `res://tests/test_campaign_territory_mapping.gd`
- `res://tests/test_campaign_territory_updates.gd`
- `res://tests/test_territory_economy_bonuses.gd`
- `res://tests/test_world_map_ui.gd`

**Files modified [MODIFIED]:**
- `res://autoloads/signal_bus.gd` — `territory_state_changed`, `world_map_updated`
- `res://autoloads/game_manager.gd` — Territory map ownership, gold modifiers, day result application
- `res://autoloads/campaign_manager.gd` — Triggers territory map reload on campaign change
- `res://scripts/resources/day_config.gd` — Added `mission_index`
- `res://scripts/resources/campaign_config.gd` — Added `territory_map_resource_path`
- `res://ui/between_mission_screen.tscn` — WorldMap as first tab

**Key decisions and deviations:**
- Territory state and map live on GameManager (not CampaignManager)
- Duplicate campaign asset: `campaign_main_50_days.tres` (Prompt 7) vs `campaign_main_50days.tres` (Prompt 8 canonical) — may coexist
- Win condition snapshot: `completed_day_index == campaign_len` before `mission_won` emission

**Explicitly deferred POST-MVP:**
- TerritoryData bonus hooks (research, enchant/upgrade cost multipliers)

**Remaining known issues:**
- (none documented)

---

### Prompt 9 — Faction system + weighted waves

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/faction_data.gd` — FactionData
- `res://scripts/resources/faction_roster_entry.gd` — FactionRosterEntry
- `res://resources/faction_data_default_mixed.tres`
- `res://resources/faction_data_orc_raiders.tres`
- `res://resources/faction_data_plague_cult.tres`
- `res://tests/test_faction_data.gd`

**Files modified [MODIFIED]:**
- `res://scripts/resources/day_config.gd` — `faction_id` default `DEFAULT_MIXED`; `is_mini_boss` renamed `is_mini_boss_day`
- `res://scripts/resources/territory_data.gd` — Added `default_faction_id` (POST-MVP)
- `res://autoloads/campaign_manager.gd` — `faction_registry`, `validate_day_configs()`
- `res://scripts/wave_manager.gd` — Faction-driven weighted spawning, `set_faction_data_override()`, mini-boss hook
- `res://autoloads/game_manager.gd` — `configure_for_day` after `reset_for_new_mission()`
- `res://tests/test_wave_manager.gd` — Prompt 9 cases

**Key decisions and deviations:**
- [DOCUMENTED DEVIATION] FactionRosterEntry is a separate Resource script (not nested) for `.tres` serialization
- [DOCUMENTED DEVIATION] CampaignManager/WaveManager use `preload` aliases for FactionData due to autoload parse order
- Total enemies per wave remain `N×6` (unless `difficulty_offset != 0`)

**Explicitly deferred POST-MVP:**
- TerritoryData.default_faction_id consumption

**Remaining known issues:**
- (none documented)

---

### Prompt 10 — Mini-boss + campaign boss + Day 50 loop

**Status:** Partially implemented (tests require local validation)

**Files added [NEW]:**
- `res://scripts/resources/boss_data.gd` — BossData
- `res://scenes/bosses/boss_base.gd` / `boss_base.tscn` — BossBase extends EnemyBase
- `res://resources/bossdata_plague_cult_miniboss.tres`
- `res://resources/bossdata_orc_warlord_miniboss.tres`
- `res://resources/bossdata_final_boss.tres`
- `res://tests/test_boss_data.gd`
- `res://tests/test_boss_base.gd`
- `res://tests/test_boss_waves.gd`
- `res://tests/test_final_boss_day.gd`

**Files modified [MODIFIED]:**
- `res://autoloads/signal_bus.gd` — `boss_spawned`, `boss_killed`, `campaign_boss_attempted`
- `res://autoloads/game_manager.gd` — Final-boss state, `held_territory_ids`, synthetic boss-attack days, `get_day_config_for_index()`, territory secure on mini-boss kill
- `res://autoloads/campaign_manager.gd` — `start_next_day` calls `prepare_next_campaign_day_if_needed()`; win path respects `final_boss_defeated`
- `res://scripts/wave_manager.gd` — `boss_registry`, `set_day_context()`, boss wave + escorts
- `res://scripts/resources/day_config.gd` — `boss_id`, `is_boss_attack_day`, `is_mini_boss`
- `res://scripts/resources/campaign_config.gd` — `starting_territory_ids`
- `res://scripts/resources/territory_data.gd` — `is_secured`, `has_boss_threat`

**Key decisions and deviations:**
- Escort resolution uses `Types.EnemyType.keys()` string matching (not enum values directly)
- Full GdUnit pass not recorded in implementation doc — requires local validation
- `push_warning` used instead of `push_error` for missing WaveManager node (GdUnit-safe)

**Explicitly deferred POST-MVP:**
- (none)

**Remaining known issues:**
- Global `class_name` cache must be refreshed after adding BossData/BossBase (editor rescan)
- Full test suite needs local validation run
- `mission_won` hub transition requires CampaignManager before GameManager in `project.godot`

---

### Prompt 11 — Ally framework

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/ally_data.gd` — AllyData
- `res://scenes/allies/ally_base.gd` / `ally_base.tscn` — AllyBase CharacterBody3D
- `res://resources/ally_data/ally_melee_generic.tres`
- `res://resources/ally_data/ally_ranged_generic.tres`
- `res://resources/ally_data/ally_support_generic.tres`
- `res://tests/test_ally_data.gd`
- `res://tests/test_ally_base.gd`
- `res://tests/test_ally_signals.gd`
- `res://tests/test_ally_spawning.gd`

**Files modified [MODIFIED]:**
- `res://scripts/types.gd` — Added `enum AllyClass`
- `res://autoloads/signal_bus.gd` — `ally_spawned`, `ally_downed`, `ally_recovered`, `ally_killed`, `ally_state_changed` (POST-MVP)
- `res://autoloads/campaign_manager.gd` — `current_ally_roster`, roster management methods
- `res://autoloads/game_manager.gd` — `_spawn_allies_for_current_mission`, `_cleanup_allies`
- `res://scenes/arnulf/arnulf.gd` — Emits generic `ally_*` with id `arnulf`
- `res://scenes/main.tscn` — Added `AllyContainer`, `AllySpawnPoints` + 3 markers

**Key decisions and deviations:**
- [DOCUMENTED DEVIATION] Avoided typed `Array[AllyData]` in autoloads; uses `Array` + `Variant` for headless parse safety
- AllyBase uses `Variant` for `ally_data` with `.get("field")` pattern
- Allies reuse layer 3 (Arnulf) for collision [ASSUMPTION]

**Explicitly deferred POST-MVP:**
- Downed/recover cycle for generic allies
- Projectiles for ranged allies
- Support ally buffs
- `ally_state_changed` detailed tracking
- Permanent `ally_killed` for Arnulf

**Remaining known issues:**
- Full `./tools/run_gdunit.sh` not completed in Prompt 11 session

---

### Prompt 12 — Mercenary offers, ally roster, mini-boss defection

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/mercenary_offer_data.gd` — MercenaryOfferData
- `res://scripts/resources/mercenary_catalog.gd` — MercenaryCatalog
- `res://scripts/resources/mini_boss_data.gd` — MiniBossData
- `res://resources/mercenary_catalog.tres`
- `res://resources/mercenary_offers/*.tres`
- `res://resources/miniboss_data/*.tres`
- `res://tests/test_mercenary_offers.gd`
- `res://tests/test_mercenary_purchase.gd`
- `res://tests/test_campaign_ally_roster.gd`
- `res://tests/test_mini_boss_defection.gd`
- `res://tests/test_simbot_mercenaries.gd`

**Files modified [MODIFIED]:**
- `res://scripts/types.gd` — Added `AllyRole`, `StrategyProfile` enums
- `res://autoloads/signal_bus.gd` — `mercenary_offer_generated`, `mercenary_recruited`, `ally_roster_changed`
- `res://autoloads/campaign_manager.gd` — Owned/active roster, mercenary catalog, purchase/preview/defection/auto-select
- `res://autoloads/game_manager.gd` — `_transition_to` idempotent for same state; `notify_mini_boss_defeated` routing
- `res://scripts/resources/ally_data.gd` — Extended with `role`, `damage_type`, `scene_path`, `is_starter_ally`, `is_defected_ally`, etc.
- `res://scripts/simbot.gd` — `activate(strategy)`, `decide_mercenaries()`, `get_log()`
- `res://ui/between_mission_screen.gd` — Mercenaries tab

**Key decisions and deviations:**
- MercenaryCatalog uses untyped `Array` for offers (autoload parse order safety)
- `_transition_to` no-ops on same-state to prevent duplicate hub transitions
- Day advance after `mission_won` only when `mission_number == current_day`

**Explicitly deferred POST-MVP:**
- (none noted)

**Remaining known issues:**
- (none — 398 cases / 0 failures verified)

---

### Prompt 13 — Hub dialogue system

**Status:** Fully implemented

**Files added [NEW]:**
- `res://autoloads/dialogue_manager.gd` — DialogueManager autoload
- `res://scripts/resources/dialogue/dialogue_condition.gd` — DialogueCondition
- `res://scripts/resources/dialogue/dialogue_entry.gd` — DialogueEntry
- `res://resources/dialogue/**/*.tres` — Character pools (all placeholder TODO text)
- `res://ui/dialogueui.gd` / `dialogueui.tscn` — Legacy dialogue panel
- `res://tests/test_dialogue_manager.gd`

**Files modified [MODIFIED]:**
- `res://project.godot` — DialogueManager registered after GameManager
- `res://ui/ui_manager.gd` — `show_dialogue_for_character()` + queue support
- `res://ui/between_mission_screen.gd` — Triggers hub dialogue for Sybil + Arnulf on `BETWEEN_MISSIONS`

**Key decisions and deviations:**
- `sybil_research_unlocked_any` uses substring `spell` in node_id — current research tree has NO such IDs [DESIGN GAP]
- `arnulf_research_unlocked_any` uses substring `arnulf` — none exist in default tree yet [DESIGN GAP]
- ResearchManager resolved via `Main/Managers/ResearchManager` — headless tests treat research conditions as false

**Explicitly deferred POST-MVP:**
- All dialogue `text` fields are TODO placeholders
- `shop_item_purchased_<ITEM_ID>` conditions are stub false

**Remaining known issues:**
- (none documented)

---

### Prompt 14 — Between-mission hub framework

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/character_data.gd` — CharacterData
- `res://scripts/resources/character_catalog.gd` — CharacterCatalog
- `res://resources/character_data/{merchant,researcher,enchantress,mercenary_captain,arnulf_hub,flavor_npc_01}.tres`
- `res://resources/character_catalog.tres`
- `res://scenes/hub/character_base_2d.gd` / `character_base_2d.tscn`
- `res://ui/hub.gd` / `hub.tscn` — Hub2DHub
- `res://ui/dialogue_panel.gd` / `dialogue_panel.tscn` — DialoguePanel
- `res://tests/test_character_hub.gd`

**Files modified [MODIFIED]:**
- `res://scripts/types.gd` — Added `enum HubRole`
- `res://ui/ui_manager.gd` — Hub wiring, `show_dialogue()`, `clear_dialogue()`, safe re-fetch fallback
- `res://ui/between_mission_screen.gd` — Panel helpers (`open_shop_panel`, etc.)
- `res://scenes/main.tscn` — Instanced `Hub` and `DialoguePanel` under `UI`

**Key decisions and deviations:**
- UIManager uses `_get_hub()` / `_get_dialogue_panel()` with safe re-fetch fallback (headless GdUnit safety)

**Explicitly deferred POST-MVP:**
- Index updates noted as next step in implementation log [UNKNOWN — check if completed]

**Remaining known issues:**
- (none documented)

---

### Prompt 15 — Florence meta-state + day progression

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/florence_data.gd` — FlorenceData resource
- `res://tests/test_florence.gd`

**Files modified [MODIFIED]:**
- `res://scripts/types.gd` — Added `enum DayAdvanceReason`, `get_day_advance_priority()` helper
- `res://autoloads/signal_bus.gd` — `florence_state_changed()`
- `res://autoloads/game_manager.gd` — `florence_data`, `current_day`, `advance_day()`, mission win/fail Florence counter increments
- `res://autoloads/dialogue_manager.gd` — Resolves `florence.*` and `campaign.*` condition keys
- `res://scripts/research_manager.gd` — Florence unlock hook
- `res://scripts/shop_manager.gd` — Placeholder enchantments unlock hook
- `res://ui/between_mission_screen.tscn` / `.gd` — FlorenceDebugLabel

**Key decisions and deviations:**
- Avoided `: FlorenceData` type annotations in locals (parse-time safety)
- `advance_day()` uses match helper instead of int→enum cast (Godot parse error fix)

**Explicitly deferred POST-MVP:**
- Full Florence narrative content

**Remaining known issues:**
- (none — parse-safety fixes applied)

---

### Prompt 16 — SimBot strategy profiles + balance logging

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/resources/strategyprofile.gd` — StrategyProfile resource
- `res://resources/strategyprofiles/strategy_balanced_default.tres`
- `res://resources/strategyprofiles/strategy_greedy_econ.tres`
- `res://resources/strategyprofiles/strategy_heavy_fire.tres`
- `res://tests/test_simbot_profiles.gd`
- `res://tests/test_simbot_basic_run.gd`
- `res://tests/test_simbot_logging.gd`
- `res://tests/test_simbot_determinism.gd`
- `res://tests/test_simbot_safety.gd`

**Files modified [MODIFIED]:**
- `res://scripts/simbot.gd` — Added `run_single()`, `run_batch()`, per-run CSV logging
- `res://autoloads/auto_test_driver.gd` — Added `--simbot_profile`, `--simbot_runs`, `--simbot_seed` CLI args

**Key decisions and deviations:**
- CSV logs written to `user://simbot_logs/simbot_balance_log.csv` by default
- Full GdUnit suite intentionally skipped in session; quick run passed

**Explicitly deferred POST-MVP:**
- (none noted)

**Remaining known issues:**
- Full GdUnit suite not run during Prompt 16 session — run before release

---

### Prompt 17 — Art placeholder pipeline scaffolding

**Status:** Fully implemented

**Files added [NEW]:**
- `res://scripts/art/art_placeholder_helper.gd` — ArtPlaceholderHelper
- `res://art/meshes/{enemies,buildings,allies,misc}/*.tres` — Primitive mesh placeholders
- `res://art/materials/factions/*.tres` — StandardMaterial3D faction materials
- `res://art/icons/{buildings,enemies,allies}/` — Empty (POST-MVP)
- `res://art/generated/{meshes,icons}/` — Drop zone for AI/Blender outputs
- `README_ART_PIPELINE.md` files in each leaf folder
- `res://tests/test_art_placeholders.gd`

**Files modified [MODIFIED]:**
- `res://scenes/enemies/enemy_base.tscn` — References `res://art/` resources
- `res://scenes/tower/tower.tscn` — References `res://art/` resources
- `res://scenes/arnulf/arnulf.tscn` — References `res://art/` resources
- `res://scenes/buildings/building_base.tscn` — References `res://art/` resources
- `res://scenes/projectiles/projectile_base.tscn` — References `res://art/` resources
- `res://scenes/hex_grid/hex_grid.tscn` — References `res://art/` resources
- `res://scenes/enemies/enemy_base.gd` — Runtime visual override via helper
- `res://scenes/buildings/building_base.gd` — Runtime visual override via helper
- `res://scenes/tower/tower.gd` — Runtime visual override via helper
- `res://scenes/arnulf/arnulf.gd` — Runtime visual override via helper

**Key decisions and deviations:**
- Icon methods are POST-MVP stubs (return `null`)
- `res://art/generated/` takes priority over placeholders for future asset drop-in
- Test uses `preload()` instead of `class_name` global resolution (headless safety)

**Explicitly deferred POST-MVP:**
- Icon texture resolution
- Blender/AI generated asset pipeline

**Remaining known issues:**
- (none — 440 cases / 0 failures)

---

### Implementation Coverage Summary

```
Prompts fully implemented:      15/17  (1,2,3,4,5,6,7,8,9,11,12,13,14,15,16,17)
Prompts partially implemented:  1/17   (10 — tests need local validation)
Prompts unclear / no record:    0/17
Total POST-MVP items deferred:  ~18
Total open issues across all prompts: ~6 (see Section 6)
Prompts 16 and 17 reflected in INDEX files: partial
  - INDEX_SHORT.md: Prompt 16 and 17 entries present
  - INDEX_FULL.md: updated through Prompt 15; Prompt 16/17 content NOT in delta sections
  - INDEX_MACHINE.md: Prompt 16/17 entries NOT present
```

---

## Section 3 — Annotated File Map

```
res://
├── project.godot                                     [MODIFIED] — Autoload registry, input map
├── autoloads/
│   ├── signal_bus.gd                                 [MODIFIED] — SignalBus; central signal registry (expanded through P17)
│   ├── campaign_manager.gd                           [NEW P7] — CampaignManager; day/campaign state, faction registry, ally roster
│   ├── damage_calculator.gd                          [MODIFIED] — DamageCalculator; stateless 4×4 matrix + DoT tick
│   ├── economy_manager.gd                            [UNCHANGED] — EconomyManager; resource tracking
│   ├── game_manager.gd                               [MODIFIED] — GameManager; session FSM, territory, boss state, Florence
│   ├── dialogue_manager.gd                           [NEW P13] — DialogueManager; Hades-model hub dialogue
│   ├── enchantment_manager.gd                        [NEW P4] — EnchantmentManager; two-slot enchantments
│   └── auto_test_driver.gd                           [MODIFIED P16] — AutoTestDriver; headless smoke + SimBot CLI
├── scripts/
│   ├── types.gd                                      [MODIFIED] — Types; all enums (AllyClass P11, HubRole P14, DayAdvanceReason P15)
│   ├── health_component.gd                           [UNCHANGED] — HealthComponent; reusable HP tracker
│   ├── wave_manager.gd                               [MODIFIED] — WaveManager; faction-weighted spawns, boss wave, day config
│   ├── spell_manager.gd                              [UNCHANGED] — SpellManager; mana pool, Shockwave AoE
│   ├── research_manager.gd                           [MODIFIED P15] — ResearchManager; Florence unlock hook
│   ├── shop_manager.gd                               [MODIFIED P15] — ShopManager; Florence enchantment hook
│   ├── input_manager.gd                              [MODIFIED P1] — InputManager; build-mode sell routing
│   ├── simbot.gd                                     [MODIFIED P12,P16] — SimBot; strategy profiles, run_single/batch, CSV
│   ├── weapon_upgrade_manager.gd                     [NEW P3] — WeaponUpgradeManager; scene-bound manager
│   ├── main_root.gd                                  [NEW] — MainRoot; window content scale fix
│   ├── florence_data.gd                              [NEW P15] — FlorenceData; run-scoped meta-state
│   ├── art/
│   │   └── art_placeholder_helper.gd                 [NEW P17] — ArtPlaceholderHelper; convention-based art resolver
│   └── resources/
│       ├── enemy_data.gd                             [MODIFIED P5] — EnemyData + damage_immunities
│       ├── building_data.gd                          [MODIFIED P5] — BuildingData + DoT fields
│       ├── weapon_data.gd                            [MODIFIED P2] — WeaponData + assist/miss fields
│       ├── weapon_level_data.gd                      [NEW P3] — WeaponLevelData
│       ├── spell_data.gd                             [UNCHANGED] — SpellData
│       ├── research_node_data.gd                     [UNCHANGED] — ResearchNodeData
│       ├── shop_item_data.gd                         [UNCHANGED] — ShopItemData
│       ├── territory_data.gd                         [NEW P8] — TerritoryData
│       ├── territory_map_data.gd                     [NEW P8] — TerritoryMapData
│       ├── faction_roster_entry.gd                   [NEW P9] — FactionRosterEntry
│       ├── faction_data.gd                           [NEW P9] — FactionData
│       ├── boss_data.gd                              [NEW P10] — BossData
│       ├── day_config.gd                             [NEW P7] — DayConfig
│       ├── campaign_config.gd                        [NEW P7] — CampaignConfig
│       ├── strategyprofile.gd                        [NEW P16] — StrategyProfile
│       ├── ally_data.gd                              [NEW P11] — AllyData
│       ├── mercenary_offer_data.gd                   [NEW P12] — MercenaryOfferData
│       ├── mercenary_catalog.gd                      [NEW P12] — MercenaryCatalog
│       ├── mini_boss_data.gd                         [NEW P12] — MiniBossData
│       ├── enchantment_data.gd                       [NEW P4] — EnchantmentData
│       ├── character_data.gd                         [NEW P14] — CharacterData
│       ├── character_catalog.gd                      [NEW P14] — CharacterCatalog
│       └── dialogue/
│           ├── dialogue_condition.gd                 [NEW P13] — DialogueCondition
│           └── dialogue_entry.gd                     [NEW P13] — DialogueEntry
├── scenes/
│   ├── main.tscn                                     [MODIFIED] — Root scene (AllyContainer, hub, dialogue panel)
│   ├── tower/
│   │   ├── tower.gd                                  [MODIFIED P2,P3,P4,P17] — Tower; assist/miss, upgrades, enchantments, art
│   │   └── tower.tscn                                [MODIFIED P17] — Art resource references
│   ├── arnulf/
│   │   ├── arnulf.gd                                 [MODIFIED P11,P17] — Arnulf; generic ally signals, art
│   │   └── arnulf.tscn                               [MODIFIED P17] — Art resource references
│   ├── hex_grid/
│   │   ├── hex_grid.gd                               [MODIFIED P1,P6] — HexGrid; sell routing, obstacle activation
│   │   └── hex_grid.tscn                             [MODIFIED P17] — Art resource references
│   ├── buildings/
│   │   ├── building_base.gd                          [MODIFIED P5,P6,P17] — BuildingBase; DoT, collision, art
│   │   └── building_base.tscn                        [MODIFIED P6,P17] — BuildingCollision, obstacle, art
│   ├── enemies/
│   │   ├── enemy_base.gd                             [MODIFIED P5,P6,P17] — EnemyBase; DoT, split pathing, art
│   │   └── enemy_base.tscn                           [MODIFIED P6,P17] — Collision mask, art
│   ├── bosses/
│   │   ├── boss_base.gd                              [NEW P10] — BossBase extends EnemyBase
│   │   └── boss_base.tscn                            [NEW P10] — Boss scene
│   ├── allies/
│   │   ├── ally_base.gd                              [NEW P11] — AllyBase CharacterBody3D
│   │   └── ally_base.tscn                            [NEW P11] — Ally scene
│   ├── hub/
│   │   ├── character_base_2d.gd                      [NEW P14] — HubCharacterBase2D
│   │   └── character_base_2d.tscn                    [NEW P14]
│   └── projectiles/
│       ├── projectile_base.gd                        [MODIFIED P4,P5] — Optional custom damage, DoT params
│       └── projectile_base.tscn                      [MODIFIED P17] — Art resource references
├── ui/
│   ├── ui_manager.gd                                 [MODIFIED P13,P14] — Hub/dialogue wiring
│   ├── hub.gd / hub.tscn                             [NEW P14] — Hub2DHub
│   ├── dialogue_panel.gd / dialogue_panel.tscn       [NEW P14] — DialoguePanel
│   ├── dialogueui.gd / dialogueui.tscn               [NEW P13] — Legacy dialogue (kept for reference)
│   ├── hud.gd / hud.tscn                             [UNCHANGED]
│   ├── build_menu.gd / build_menu.tscn               [MODIFIED P1] — Sell panel
│   ├── between_mission_screen.gd / .tscn             [MODIFIED P3,P7,P8,P12,P14,P15] — Weapons, map, mercs, Florence
│   ├── world_map.gd / world_map.tscn                 [NEW P8] — Territory display
│   ├── main_menu.gd / main_menu.tscn                 [UNCHANGED]
│   ├── mission_briefing.gd                           [UNCHANGED]
│   └── end_screen.gd                                 [UNCHANGED]
├── resources/
│   ├── enemy_data/*.tres                             [UNCHANGED] — 6 enemy types
│   ├── building_data/*.tres                          [MODIFIED P5] — fire_brazier/poison_vat DoT
│   ├── weapon_data/*.tres                            [MODIFIED P2] — crossbow assist/miss values
│   ├── weapon_level_data/*.tres                      [NEW P3] — 6 level resources
│   ├── spell_data/shockwave.tres                     [UNCHANGED]
│   ├── research_data/base_structures_tree.tres       [UNCHANGED]
│   ├── shop_data/shop_catalog.tres                   [UNCHANGED]
│   ├── territories/main_campaign_territories.tres    [NEW P8]
│   ├── campaigns/*.tres                              [NEW P7,P8]
│   ├── faction_data_*.tres                           [NEW P9]
│   ├── bossdata_*.tres                               [NEW P10]
│   ├── ally_data/*.tres                              [NEW P11]
│   ├── mercenary_catalog.tres                        [NEW P12]
│   ├── mercenary_offers/*.tres                       [NEW P12]
│   ├── miniboss_data/*.tres                          [NEW P12]
│   ├── enchantments/*.tres                           [NEW P4]
│   ├── dialogue/**/*.tres                            [NEW P13]
│   ├── character_data/*.tres                         [NEW P14]
│   ├── character_catalog.tres                        [NEW P14]
│   └── strategyprofiles/*.tres                       [NEW P16]
├── art/                                              [NEW P17]
│   ├── meshes/{enemies,buildings,allies,misc}/*.tres
│   ├── materials/factions/*.tres
│   ├── icons/{buildings,enemies,allies}/             [EMPTY — POST-MVP]
│   └── generated/{meshes,icons}/                     [DROP ZONE — POST-MVP]
└── tests/                                            [~40+ test files, ~440 cases]
    ├── (see INDEX_SHORT.md for full list)
    └── ...
```

**Files from Prompts 16/17 not fully indexed:**

- [UNINDEXED — Prompt 16] `res://scripts/resources/strategyprofile.gd` — present in INDEX_SHORT.md but NOT in INDEX_FULL.md delta or INDEX_MACHINE.md
- [UNINDEXED — Prompt 16] `res://resources/strategyprofiles/*.tres` — present in INDEX_SHORT.md but NOT in INDEX_FULL.md or INDEX_MACHINE.md
- [UNINDEXED — Prompt 16] `res://tests/test_simbot_profiles.gd` and siblings — present in INDEX_SHORT.md test list
- [UNINDEXED — Prompt 16] `SimBot.run_single()` / `run_batch()` — NOT in INDEX_FULL.md SimBot API section
- [UNINDEXED — Prompt 17] `res://scripts/art/art_placeholder_helper.gd` — present in INDEX_SHORT.md and INDEX_FULL.md
- [UNINDEXED — Prompt 17] `res://art/**/*.tres` — NOT enumerated in INDEX files
- [UNINDEXED — Prompt 17] Scene `.tscn` art references — NOT documented in INDEX_FULL.md delta sections

---

## Section 4 — Rules Reference for Sonnet

### 4a — Naming Rules

| Entity | Convention | Example |
|--------|-----------|---------|
| Script file | `snake_case.gd` | `economy_manager.gd` |
| Scene file | `snake_case.tscn` | `enemy_base.tscn` |
| Resource file | `snake_case.tres` | `orc_grunt.tres` |
| `class_name` | `PascalCase` | `class_name EconomyManager` |
| Enum type | `PascalCase` | `enum DamageType` |
| Enum value | `UPPER_SNAKE_CASE` | `DamageType.PHYSICAL` |
| Constant | `UPPER_SNAKE_CASE` | `const MAX_WAVES := 10` |
| Variable (local/member) | `snake_case` | `var current_hp: int` |
| Private member | `_snake_case` | `var _internal_timer: float` |
| Function (public) | `snake_case` | `func add_gold(amount: int)` |
| Function (private) | `_snake_case` | `func _update_state() -> void` |
| Signal | `snake_case` past-tense verb | `signal enemy_killed` |
| @export variable | `snake_case` | `@export var move_speed: float = 5.0` |
| Node in scene tree | `PascalCase` | `EnemyContainer`, `HexGrid` |
| Test file | `test_<module>.gd` | `test_economy_manager.gd` |
| Test function | `test_<what>_<condition>_<expected>` | `test_add_gold_positive_amount_increases_total` |

### 4b — Autoload Registry

| # | Autoload Name | Path | Sole Responsibility | Must NOT Touch |
|---|--------------|------|---------------------|----------------|
| 1 | `SignalBus` | `res://autoloads/signal_bus.gd` | Central signal declarations only. Zero logic, zero state. | Any game logic, any state mutation |
| 2 | `CampaignManager` | `res://autoloads/campaign_manager.gd` | Day/campaign progression, faction registry, ally roster management, mercenary offers/purchase. Must load BEFORE GameManager. | Wave spawning, UI display, direct economy mutation outside EconomyManager |
| 3 | `DamageCalculator` | `res://autoloads/damage_calculator.gd` | Stateless 4×4 damage multiplier matrix + DoT tick calculation. Pure function. | Any state, any signals |
| 4 | `EconomyManager` | `res://autoloads/economy_manager.gd` | Owns gold, building_material, research_material. All resource modifications route through it. | Game state transitions, wave logic, UI |
| 5 | `GameManager` | `res://autoloads/game_manager.gd` | Session state machine, mission/wave counters, territory map, boss state, Florence data. Spawns/cleans allies. | Direct resource mutation (delegates to EconomyManager), UI display |
| 6 | `DialogueManager` | `res://autoloads/dialogue_manager.gd` | Hub dialogue: loads entries, priority selection, conditions, chains. UI-agnostic. | Any game state mutation, direct UI manipulation |
| 7 | `EnchantmentManager` | `res://autoloads/enchantment_manager.gd` | Weapon enchantment slot state. Two slots: "elemental" + "power". | Economy operations (delegates), UI |
| 8 | `AutoTestDriver` | `res://autoloads/auto_test_driver.gd` | Headless smoke test. Active only with `--autotest` flag. | Normal gameplay |

**Note:** `Types` at `res://scripts/types.gd` is a `class_name` script, NOT an autoload. Accessed as `Types.GameState`, `Types.DamageType`, etc.

### 4c — Scene Tree and Node Path Contracts

**Authoritative scene tree** (from ARCHITECTURE.md §2, updated through Prompt 14):

```
/root/Main (Node3D)
├── Camera3D
├── DirectionalLight3D
├── Ground (StaticBody3D)
│   ├── GroundMesh, GroundCollision
│   └── NavigationRegion3D
├── Tower (StaticBody3D)
│   ├── TowerMesh, TowerCollision, HealthComponent, TowerLabel
├── Arnulf (CharacterBody3D)
│   ├── ArnulfMesh, ArnulfCollision, HealthComponent, NavigationAgent3D
│   ├── DetectionArea → DetectionShape
│   ├── AttackArea → AttackShape
│   └── ArnulfLabel
├── HexGrid (Node3D) → HexSlot_00..HexSlot_23
├── SpawnPoints (Node3D) → SpawnPoint_00..SpawnPoint_09
├── EnemyContainer (Node3D)
├── AllyContainer (Node3D)
├── AllySpawnPoints (Node3D) → AllySpawnPoint_00..02
├── BuildingContainer (Node3D)
├── ProjectileContainer (Node3D)
├── Managers (Node)
│   ├── WaveManager, SpellManager, ResearchManager
│   ├── ShopManager, InputManager, WeaponUpgradeManager
└── UI (CanvasLayer)
    ├── UIManager (Control)
    │   └── DialoguePanel
    ├── HUD, BuildMenu, BetweenMissionScreen
    ├── Hub (hub.tscn)
    ├── MainMenu, MissionBriefing, EndScreen
```

**Hard-coded node path contracts:**

| Path String | Used By | What Breaks If Wrong |
|-------------|---------|---------------------|
| `/root/Main` | GameManager (`_begin_mission_wave_sequence`) | Wave sequence silently skipped (push_warning) |
| `/root/Main/Managers/WaveManager` | GameManager | Wave sequence silently skipped |
| `/root/Main/Managers/WeaponUpgradeManager` | Tower | Falls back to raw WeaponData stats |
| `/root/Main/Managers/ResearchManager` | DialogueManager | Research conditions evaluate false |
| `/root/Main/EnemyContainer` | WaveManager | Enemies not spawned |
| `/root/Main/SpawnPoints` | WaveManager | Enemies not spawned |
| `/root/Main/AllyContainer` | GameManager | Allies not spawned |
| `/root/Main/AllySpawnPoints` | GameManager | Ally positions wrong |
| `/root/Main/ProjectileContainer` | Tower, BuildingBase | Projectiles orphaned |
| `/root/Main/Managers/ShopManager` | GameManager (`start_new_game()`, `start_mission_for_day()`) | Mission-start consumables not applied; shop-driven mission modifiers silently disabled. |
| `/root/Main/Managers/SpellManager` | InputManager (spell hotkeys / casting) | Spells cannot be cast or configured; hotkeys may appear to do nothing. |

### 4d — SimBot Headless API Contract

**API file:** `res://scripts/simbot.gd` (`class_name SimBot`)

**Methods:**

| Method | Signature | Return |
|--------|-----------|--------|
| `activate` | `(strategy: Types.StrategyProfile) -> void` | void |
| `run_single` | `(profile_id: String, run_index: int, seed_value: int) -> Dictionary` | Per-run metrics dict |
| `run_batch` | `(profile_id: String, runs: int, base_seed: int = 0, csv_path: String = "") -> void` | void (writes CSV) |
| `decide_mercenaries` | `() -> void` | void |
| `get_log` | `() -> Dictionary` | Accumulated run log |

**What "headless safe" means:** A method is headless-safe if it can execute without any node from the `UI (CanvasLayer)` subtree present in the scene tree, and without `main.tscn` loaded. All manager public methods (GameManager, EconomyManager, WaveManager, SpellManager, HexGrid, ResearchManager, ShopManager) must be callable from SimBot without referencing or requiring UI nodes.

**What a violation looks like:** Any game logic script that calls `get_node("/root/Main/UI/...")`, accesses a Control node, reads a UI label, or requires a CanvasLayer child to function. Also: any manager method that crashes when `Main` or `Managers` is absent (should use `get_node_or_null` + `push_warning`).

**Files most at risk:** `game_manager.gd` (already patched to use `get_node_or_null`), `wave_manager.gd` (already patched), any new manager that resolves nodes via hardcoded paths.

### 4e — Signal Rules

- **Where signals must be declared:** All **cross-system** signals go in `signal_bus.gd` ONLY. No exceptions. Local signals (within one scene tree, e.g., `health_depleted`, `health_changed`) may live on the emitting node directly.
- **Naming format:**
  - CORRECT: `signal enemy_killed` (past tense), `signal build_requested` (present tense request)
  - INCORRECT: `signal enemy_will_die` (future tense — NEVER)
- **Payload must be typed:** `signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)`
- **Emission pattern:** Signals are emitted via `SignalBus.signal_name.emit(...)`. Autoloads emit through SignalBus, not directly. Example: `SignalBus.enemy_killed.emit(enemy_type, position, gold_reward)`.

### 4f — No-Game-Logic Boundaries

**What counts as "game logic":** Any code that mutates game state: changing resource amounts, transitioning game states, spawning/destroying entities, calculating damage, changing wave/mission counters, modifying research/shop state, or making strategic decisions.

**Which files this boundary applies to:** All files under `res://ui/` (ui_manager.gd, hud.gd, build_menu.gd, between_mission_screen.gd, world_map.gd, hub.gd, dialogue_panel.gd, dialogueui.gd, main_menu.gd, mission_briefing.gd, end_screen.gd) and `res://scripts/input_manager.gd`.

**What is explicitly allowed:** Signal routing (connecting to SignalBus and updating display), delegating to manager public methods (e.g., `ShopManager.purchase_item()`), showing/hiding panels, updating labels/progress bars, reading state from managers (e.g., `EconomyManager.get_gold()`), displaying data.

**What is explicitly forbidden:** Direct state mutation (e.g., `EconomyManager.gold -= 50`), calling economy add/spend without going through a manager method, spawning enemies, modifying wave state, changing `game_state` directly, calling `queue_free()` on game entities, calculating damage.

---

## Section 5 — Design Intent vs Implementation Status

| Feature / System | Designed (end product estimate) | Implemented (Prompt) | Status | Notes |
|-----------------|-------------------------------|---------------------|--------|-------|
| Stationary tower with mouse-aimed weapons | Yes | MVP + P2 | Complete | Crossbow + rapid missile; assist/miss in P2 |
| Weapon upgrade levels | Yes | P3 | Complete | 3 levels per weapon; deterministic upgrades |
| Weapon enchantment system | Yes | P4 | Partial | Two-slot system works; affinity XP/gameplay effects inert |
| Damage type × armor type matrix | Yes | MVP | Complete | 4×4 matrix in DamageCalculator |
| DoT effects (burn/poison) | Yes (status effects) | P5 | Partial | Burn + poison on buildings; no player weapon DoT; no slow/infected |
| Hex grid buildings (8 types) | Yes | MVP | Complete | 24 slots, place/sell/upgrade |
| Solid building collision + pathfinding | Yes ("cannot walk through") | P6 | Complete | NavigationObstacle3D; no navmesh rebake |
| AI melee companion (Arnulf) | Yes | MVP | Complete | Full state machine, downed/recover cycle |
| Generic allies (mercenaries) | Yes | P11, P12 | Partial | AllyBase + roster; no ranged/support AI behavior yet |
| Mercenary recruitment | Yes | P12 | Complete | Offers, purchase, defection, auto-select |
| Spells (Shockwave) | Yes | MVP | Partial | Only shockwave; design calls for multiple spells |
| Research tree | Yes | MVP | Complete | 6-node tree with gating |
| Shop system | Yes | MVP | Complete | 4 items; data-driven catalog |
| Campaign/day system (50 days) | Yes | P7, P8 | Complete | CampaignConfig + DayConfig + territory mapping |
| Territory system + world map | Yes | P8 | Complete | 5 territories; ownership + gold bonuses |
| Faction system | Yes | P9 | Complete | 3 factions; weighted wave composition |
| Mini-bosses + campaign boss | Yes | P10 | Partial | BossBase exists; Day 50 loop; tests need local validation |
| Hub dialogue (Hades model) | Yes | P13 | Partial | Framework complete; all text is TODO placeholder |
| Between-mission hub (visual characters) | Yes | P14 | Partial | 2D clickable characters; visual art pending |
| Florence meta-state | Yes (protagonist arc) | P15 | Partial | Scaffold only; no narrative content |
| SimBot automated playtesting | Yes | P12, P16 | Partial | Strategy profiles + batch runs; no full campaign playthrough verified |
| Art placeholder pipeline | Implied | P17 | Partial | Infrastructure only; no real art assets |
| Auto-aim assist system | Yes | P2 | Complete | Cone-based assist, miss perturbation |
| Weapon structural upgrades (research) | Yes | P3 (partial) | Partial | Level upgrades done; structural upgrades (pierce, clip) not implemented |
| Multiple spell types | Yes | — | Not started | [DESIGN GAP] Only shockwave exists |
| Terrain types affecting gameplay | Yes | — | Not started | [DESIGN GAP] TerritoryData has terrain enum but no gameplay modifiers |
| Destructible environment props | Yes | — | Not started | [DESIGN GAP] No destructible component exists |
| Weapon upgrade station (between battles) | Yes | P3 | Complete | WeaponUpgradeManager + UI |
| Endless mode | Yes | — | Not started | [DESIGN GAP] No endless mode implementation |
| Save/load persistence | Yes (implied) | — | Not started | [DESIGN GAP] No save system |
| Character relationship values | Yes (Hades model) | — | Not started | [DESIGN GAP] DialogueManager has no relationship tracking |
| Mid-battle dialogue triggers | Yes | — | Not started | [DESIGN GAP] Dialogue is between-mission only |
| Mana draught / battle consumables | Partial (shop) | MVP (stub) | Stub only | `mana_draught_consumed` signal exists |

**Overall completion summary:** The core combat loop (tower shooting, building placement, enemy waves, Arnulf, damage system) is solidly implemented and tested. The campaign/day/territory/faction/boss layer provides full structural support for a 50-day campaign but with placeholder data. Between-mission systems (shop, research, weapons, enchantments, mercenaries) are mechanically functional but UI is basic. The dialogue and hub systems have complete frameworks but zero narrative content. Major design gaps remain in: multiple spell types, terrain gameplay effects, destructible props, endless mode, save/load, relationship values, mid-battle dialogue, and weapon structural upgrades.

---

## Section 6 — Consolidated Known Issues

| # | Source | Issue Description | Severity | System Affected | Prompt Introduced |
|---|--------|-------------------|----------|----------------|-------------------|
| 1 | P10 | Full GdUnit suite pass not recorded; tests need local validation run | High | Testing / Boss | P10 |
| 2 | P10 | Global `class_name` cache must be refreshed after adding BossData/BossBase (requires editor rescan) | Medium | Build / Boss | P10 |
| 3 | P10, P7 | `mission_won` hub transition requires CampaignManager before GameManager in `project.godot` autoload order — misconfiguration silently breaks day progression | High | GameManager / CampaignManager | P10 |
| 4 | INDEX_SHORT | `WAVES_PER_MISSION = 3` in GameManager (dev cap; final value is 10) | Medium | GameManager | Pre-MVP |
| 5 | INDEX_SHORT | `dev_unlock_all_research = true` in main.tscn (dev flag; must be set false for release) | Medium | ResearchManager / main.tscn | Pre-MVP |
| 6 | INDEX_SHORT | Windows headless `main.tscn` run may SIGSEGV; use editor F5 for full loop on Windows | Low | Platform | Pre-MVP |
| 7 | P1 | Phase 6 playtest rows 5 (sell), 6 (shockwave verify), 7 (Arnulf verify), 10 (between-mission loop) not fully confirmed | Medium | Multiple | P1 |
| 8 | P5, P8, P12 | GdUnit CLI exit code 101 from orphan-node warnings (not a failure; known GdUnit noise) | Low | Testing | P5 |
| 9 | P11 | Full `./tools/run_gdunit.sh` not completed in Prompt 11 session (long runtime) | Medium | Testing / Ally | P11 |
| 10 | P16 | Full GdUnit suite intentionally skipped in Prompt 16 session; quick run only | Medium | Testing / SimBot | P16 |
| 11 | P13 | `sybil_research_unlocked_any` / `arnulf_research_unlocked_any` conditions have no matching research node IDs in current tree | Medium | DialogueManager | P13 |
| 12 | P14 | INDEX_FULL.md update for Prompt 14 noted as "next step" — may not be complete | Low | Documentation | P14 |
| 13 | P8 | Duplicate campaign asset: `campaign_main_50_days.tres` (P7) vs `campaign_main_50days.tres` (P8 canonical) may coexist causing confusion | Low | Resources | P8 |
| 14 | INDEX_SHORT | SimBot strategy `activate`, `decide_mercenaries`, `get_log` (P12); building/spell/wave bot helpers remain incomplete | Medium | SimBot | P12 |

```
Total issues: 14
  Critical: 0
  High:     2
  Medium:   8
  Low:      4
```

---

## Section 7 — Audit Cheat Sheet

**Top priority issues (High severity):**
- **#1:** Full GdUnit suite pass not recorded for Prompt 10 boss work — run `./tools/run_gdunit.sh` and verify 0 failures
- **#3:** `project.godot` autoload order MUST have CampaignManager before GameManager — verify this

**Files most at risk:**
- `res://autoloads/game_manager.gd` — Massive file; boss state, Florence, territory, ally spawn, multiple prompt modifications. Most complex single file in project.
- `res://autoloads/campaign_manager.gd` — Ally roster, mercenary system, faction registry, day progression. Second most complex.
- `res://scenes/tower/tower.gd` — Weapon composition (upgrades + enchantments + assist/miss). Multiple prompt overlays.
- `res://scripts/wave_manager.gd` — Faction-weighted spawning + boss waves + day config. Parse-order workarounds with `preload` aliases.
- `res://autoloads/signal_bus.gd` — Must contain ALL cross-system signals. Verify completeness.
- `res://scenes/enemies/enemy_base.gd` — DoT system, split ground/flying pathing, stuck recovery.

**Newest / least-indexed work (Prompts 16 and 17):**
- **P16 files added:** `strategyprofile.gd`, 3 `.tres` profiles, 5 test files, SimBot `run_single`/`run_batch`
- **P17 files added:** `art_placeholder_helper.gd`, `res://art/**` hierarchy, scene `.tscn` updates, 1 test file
- **INDEX_FULL.md covers them:** Partial — P17 helper is documented; P16 SimBot new methods are NOT in INDEX_FULL.md
- **INDEX_MACHINE.md covers them:** No — neither P16 nor P17 entries present

**Signal audit quick reference:**
- Declaration location: `res://autoloads/signal_bus.gd` ONLY (for cross-system); local signals on emitting node
- Naming rule: `snake_case`, past-tense for events (`enemy_killed`), present-tense for requests (`build_requested`); NEVER future tense
- Known signals added across prompts: `weapon_upgraded` (P3), `enchantment_applied`/`removed` (P4), `territory_state_changed`/`world_map_updated` (P8), `boss_spawned`/`boss_killed`/`campaign_boss_attempted` (P10), `ally_spawned`/`downed`/`recovered`/`killed` (P11), `mercenary_offer_generated`/`recruited`/`ally_roster_changed` (P12), `florence_state_changed` (P15)
- Known potential gap: verify `florence_state_changed` is in signal_bus.gd and not just on GameManager

**Node path audit quick reference:**
- Hard-coded paths to verify: `/root/Main`, `/root/Main/Managers/WaveManager`, `/root/Main/Managers/WeaponUpgradeManager`, `/root/Main/Managers/ResearchManager`, `/root/Main/EnemyContainer`, `/root/Main/SpawnPoints`, `/root/Main/AllyContainer`, `/root/Main/AllySpawnPoints`, `/root/Main/ProjectileContainer`
- Scene tree root: `/root/Main (Node3D)` from `main.tscn`
- All should use `get_node_or_null` pattern, not bare `get_node`

**SimBot audit quick reference:**
- API file: `res://scripts/simbot.gd`
- Methods to verify headless-safe: `run_single()`, `run_batch()`, `activate()`, `decide_mercenaries()`
- What breaks headless safety: Any reference to `res://ui/` paths, any `get_node` for UI nodes, any method that crashes without `main.tscn`
- Safety test exists: `res://tests/test_simbot_safety.gd` (static check for no UI path references)

**Naming audit quick reference:**
1. Script files: `snake_case.gd`
2. `class_name`: `PascalCase`
3. Functions/variables: `snake_case`; private: `_snake_case`
4. Constants/enum values: `UPPER_SNAKE_CASE`
5. Signals: `snake_case` past-tense verbs
6. Scene tree nodes: `PascalCase`

---

## Confirmation

```
Files read:
- PROMPT_X_IMPLEMENTATION files: 17/17 (all present and read)
- Foul Ward - end product estimate.md: read
- PROBLEM_REPORT.md: not provided (reconstructed from prompt implementation docs)
- INDEX_FULL.md: read
- INDEX_SHORT.md: read
- INDEX_MACHINE.md: read
- CONVENTIONS.md: read
- ARCHITECTURE.md: read
- PRE_GENERATION_VERIFICATION.md: read

Stats:
- Files in annotated map (Section 3): ~120+ (scripts, scenes, resources, tests, art)
- [UNKNOWN] entries: 1 (P14 index update completion status)
- [DOCUMENTED DEVIATION] entries: 6
  - P4: EnchantmentManager not in original ARCHITECTURE.md
  - P7: GameManager.start_next_mission delegates to CampaignManager
  - P7: WaveManager supports per-day wave cap
  - P9: FactionRosterEntry separate Resource script
  - P9: preload aliases for autoload parse order
  - P11: Untyped Array for AllyData in autoloads
- [DESIGN GAP] entries: 8
  - Multiple spell types
  - Terrain gameplay effects
  - Destructible environment props
  - Endless mode
  - Save/load persistence
  - Character relationship values
  - Mid-battle dialogue triggers
  - Weapon structural upgrades (pierce, clip size)
- [UNINDEXED — Prompt 16/17] entries: 7
- Issues in Section 6: 14 (Critical: 0, High: 2, Medium: 8, Low: 4)

Flags:
- Prompts 16/17 fully reflected in INDEX: partial
  - INDEX_SHORT.md: yes (both)
  - INDEX_FULL.md: partial (P17 yes, P16 SimBot methods missing)
  - INDEX_MACHINE.md: no (neither)
- PROBLEM_REPORT.md contained Critical issues: unknown (file not provided)
- Any repo dump files accidentally attached: none
```
