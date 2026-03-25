# Project Index Build Tasks

This file breaks index generation into small, verifiable tasks so updates stay accurate.

## Task 1: Inventory scope and source of truth
- Confirm first-party scope: `autoloads/`, `scripts/`, `scenes/`, `ui/`.
- Exclude `addons/`, `MCPs/`, and `tests/` from per-script API sections.
- Use `project.godot` as source of truth for autoload registrations.

## Task 2: Build compact index (`INDEX_SHORT.md`)
- List autoloads (name -> path).
- List first-party script files.
- List scene files.
- List resource class scripts.
- List resource instances grouped by folder.

## Task 3: Build full index (`INDEX_FULL.md`)
- Add SignalBus registry with payload signatures.
- For each first-party script include:
  - path, class name, purpose,
  - public methods (non-underscore) with signatures and plain-English behavior,
  - exported variables and what they are used for,
  - signals emitted and emission conditions,
  - major dependencies.
- Add resource class field reference for all resource scripts under `scripts/resources/`.

## Task 4: Consistency pass
- Ensure every listed file still exists.
- Ensure method/signature names match current code.
- Ensure all autoload entries in `project.godot` are represented in `INDEX_SHORT.md`.

## Task 5: Ongoing maintenance rule
- Update `INDEX_SHORT.md` and `INDEX_FULL.md` whenever:
  - a new first-party script/scene/resource is added,
  - a public method is added/removed/renamed,
  - an `@export` variable is added/removed/renamed,
  - a SignalBus signal is added/removed/renamed,
  - autoload registration changes.

## Task Update Log (2026-03-24)
- Added `docs/PROMPT_1_IMPLEMENTATION.md` with concrete implementation notes.
- Updated indexes for new BuildMenu sell-mode API and BuildMode input routing changes:
  - `InputManager` now routes hex-slot clicks by occupancy.
  - `BuildMenu` now supports placement mode + sell mode entrypoints.
  - `HexGrid` slot click callback no longer opens menu directly.
- Added HexGrid sell-flow test cases and reflected them in index notes.
- Added `docs/PROMPT_2_IMPLEMENTATION.md` with Phase 2 firing-system implementation notes.
- Indexed new `WeaponData` assist/miss fields and Tower manual-shot aim resolution behavior.
- Recorded new tests covering manual assist cone snap, miss perturbation, and autofire bypass.
- Added `docs/PROMPT_3_IMPLEMENTATION.md` with deterministic weapon-upgrade station integration notes.
- Added new indexed artifacts for Phase 3:
  - `res://scripts/resources/weapon_level_data.gd`
  - `res://scripts/weapon_upgrade_manager.gd`
  - `res://resources/weapon_level_data/*.tres` (6 level files)
  - `SignalBus.weapon_upgraded(...)`
  - `BetweenMissionScreen` Weapons tab
  - `res://tests/test_weapon_upgrade_manager.gd`
- Added Phase 4 indexed artifacts:
  - `res://autoloads/enchantment_manager.gd` (new autoload)
  - `res://scripts/resources/enchantment_data.gd` (new resource class)
  - `res://resources/enchantments/*.tres` (new enchantment data instances)
  - `SignalBus.enchantment_applied(...)`, `SignalBus.enchantment_removed(...)`
  - `Tower` projectile enchantment composition path updates
  - `BetweenMissionScreen` enchantment apply/remove controls in `WeaponsTab`
  - `res://tests/test_enchantment_manager.gd`
  - `res://tests/test_tower_enchantments.gd`
  - new regression in `res://tests/test_projectile_system.gd`
- Added Phase 5 indexed artifacts:
  - `DamageCalculator.calculate_dot_tick(...)` now implemented.
  - `EnemyBase.apply_dot_effect(effect_data: Dictionary)` added.
  - `BuildingData` DoT exports added (`dot_*` fields).
  - `ProjectileBase.initialize_from_building(...)` signature expanded for DoT parameters.
  - Added `res://tests/test_enemy_dot_system.gd`.
  - Updated `res://tests/test_projectile_system.gd` with fire/poison DoT integration checks.
- Added Phase 6 indexed artifacts:
  - `res://scenes/buildings/building_base.tscn` now includes `BuildingCollision` and `NavigationObstacle`.
  - `res://scenes/buildings/building_base.gd` now exposes base-area obstacle tuning constants + setup helpers.
  - `res://scenes/enemies/enemy_base.gd` now includes ground/flying split process and stuck-prevention helpers.
  - `res://tests/test_enemy_pathfinding.gd` now includes integration pathing scenarios.
  - `res://tests/test_building_base.gd` now verifies collision/obstacle node presence and layer/mask values.
- Added Prompt 7 indexed artifacts:
  - `res://autoloads/campaign_manager.gd`
  - `res://scripts/resources/day_config.gd`
  - `res://scripts/resources/campaign_config.gd`
  - `res://resources/campaigns/campaign_short_5_days.tres`
  - `res://resources/campaigns/campaign_main_50_days.tres`
  - `SignalBus` campaign/day signals:
    - `campaign_started`, `day_started`, `day_won`, `day_failed`, `campaign_completed`
  - Prompt 7 tests:
    - `res://tests/test_campaign_manager.gd`
    - additions in `res://tests/test_wave_manager.gd`
    - additions in `res://tests/test_game_manager.gd`
- Prompt 8 (2026-03-24) — territory + world map + 50-day campaign data:
  - `docs/PROMPT_8_IMPLEMENTATION.md`
  - `res://scripts/resources/territory_data.gd`, `territory_map_data.gd`; `DayConfig.mission_index`; `CampaignConfig.territory_map_resource_path`
  - `res://resources/territories/main_campaign_territories.tres`, `res://resources/campaign_main_50days.tres`
  - `SignalBus.territory_state_changed`, `SignalBus.world_map_updated`
  - `GameManager` territory map, `apply_day_result_to_territory`, gold aggregation, last-day win snapshot before `mission_won`
  - `res://ui/world_map.gd`, `res://ui/world_map.tscn`; `between_mission_screen.tscn` Map tab
  - Tests: `test_territory_data.gd`, `test_campaign_territory_mapping.gd`, `test_campaign_territory_updates.gd`, `test_territory_economy_bonuses.gd`, `test_world_map_ui.gd`
  - `INDEX_SHORT.md`, `INDEX_FULL.md`, `INDEX_MACHINE.md` updated for new API and paths
- Prompt 9 (2026-03-24) — factions + weighted waves + mini-boss hook:
  - `docs/PROMPT_9_IMPLEMENTATION.md`
  - `res://scripts/resources/faction_data.gd`, `faction_roster_entry.gd`; `res://resources/faction_data_*.tres` (×3)
  - `WaveManager` faction-aware spawn + `get_mini_boss_info_for_wave`; `CampaignManager.validate_day_configs` + `faction_registry`
  - `DayConfig` `is_mini_boss_day`, default `faction_id`; campaign `.tres` migrated; `TerritoryData.default_faction_id`
  - `GameManager` configure WaveManager after reset in `_begin_mission_wave_sequence`
  - Tests: `test_faction_data.gd`; expanded `test_wave_manager.gd`
  - `INDEX_SHORT.md`, `INDEX_FULL.md`, `INDEX_MACHINE.md` updated
- Pre-generation docs split (2026-03-24): **`docs/PRE_GENERATION_SPECIFICATION.md`** holds the full reference (signals, paths, project checklist, stubs); **`docs/PRE_GENERATION_VERIFICATION.md`** is the short checklist that links to it.
- Prompt 9 polish (2026-03-24): **`INDEX_FULL.md`** — full **FactionRosterEntry** / **FactionData** field tables under CUSTOM RESOURCE TYPES; **`territory_data.gd`** — `# DEVIATION` on `terrain_type` vs Prompt 9 string sketch; **`PROMPT_9_IMPLEMENTATION.md`** / **`INDEX_SHORT.md`** — GdUnit count **349** tests.
- Prompt 10 (2026-03-24) — mini-boss + campaign boss + Day 50 loop:
  - **`docs/PROMPT_10_IMPLEMENTATION.md`** — status, file list, verification checklist.
  - **`BossData`**, **`BossBase`**, **`res://resources/bossdata_*.tres`**
  - **`SignalBus`**: `boss_spawned`, `boss_killed`, `campaign_boss_attempted`
  - **`GameManager`** / **`CampaignManager`** / **`WaveManager`** boss APIs (see implementation doc).
  - **`DayConfig`**: `boss_id`, `is_mini_boss`, `is_boss_attack_day`; **`CampaignConfig.starting_territory_ids`**; **`TerritoryData.is_secured`**, **`has_boss_threat`**
  - Tests: **`test_boss_data.gd`**, **`test_boss_base.gd`**, **`test_boss_waves.gd`**, **`test_final_boss_day.gd`**; additions in **`test_wave_manager.gd`**
  - **`INDEX_SHORT.md`**, **`INDEX_FULL.md`**, **`INDEX_MACHINE.md`**, **`INDEX_TASKS.md`** updated for Prompt 10 (**re-run** `./tools/run_gdunit.sh` locally to refresh counts).
- Prompt 10 fixes (2026-03-24) — **`docs/PROMPT_10_FIXES.md`**:
  - **`WaveManager`**: `get_node_or_null` for `/root/Main/EnemyContainer` and `/root/Main/SpawnPoints`; combined null guard in **`_spawn_wave`** and **`_spawn_boss_wave`**.
  - **`test_wave_manager.gd`**, **`test_boss_waves.gd`**: spawn-point tree order + post-`add_child` injection of container refs.
  - **`WeaponLevelData`** `.tres` **`script_class`** line; **`test_campaign_manager.gd`** assertion style.
  - **`GameManager._begin_mission_wave_sequence`**: **`Main` → `Managers` → `WaveManager`** via **`get_node_or_null`**; soft skip (**`push_warning`** + return) when absent so suites like **`test_enchantment_manager`** do not require **`main.tscn`** (GdUnit error monitor); **`test_game_manager`** optional guard test.
  - **`GameManager`** + **`project.godot`**: **`mission_won`** → **`_on_mission_won_transition_to_hub`**; autoload order **`CampaignManager`** before **`GameManager`**; **`test_campaign_manager`** **`mission_failed`** payload fix; **`docs/PROBLEM_REPORT.md`** (errors + files).
  - Indexes updated (**`INDEX_SHORT`**, **`INDEX_FULL`**, **`INDEX_TASKS`**, **`INDEX_MACHINE`**).
- Prompt 11 (2026-03-24) — ally framework:
  - **`docs/PROMPT_11_IMPLEMENTATION.md`**
  - **`Types.AllyClass`**; **`AllyData`** + **`res://resources/ally_data/*.tres`**
  - **`AllyBase`** (`res://scenes/allies/ally_base.tscn`), **`main.tscn`**: `AllyContainer`, `AllySpawnPoints`
  - **`CampaignManager`**: `current_ally_roster`, `_initialize_static_roster`, `has_ally`, `get_ally_data`, `reinitialize_ally_roster_for_test`
  - **`GameManager`**: `_spawn_allies_for_current_mission`, `_cleanup_allies` (mission start / win / fail / `start_new_game`)
  - **`SignalBus`**: `ally_spawned`, `ally_downed`, `ally_recovered`, `ally_killed`, `ally_state_changed` (POST-MVP)
  - **`Arnulf`**: `ALLY_ID_ARNULF`, generic `ally_*` mirror emissions
  - Tests: **`test_ally_data.gd`**, **`test_ally_base.gd`**, **`test_ally_signals.gd`**, **`test_ally_spawning.gd`**
  - **`ARCHITECTURE.md`**, **`INDEX_SHORT.md`**, **`INDEX_FULL.md`**, **`INDEX_MACHINE.md`** updated
- Prompt 12 (2026-03-25) — mercenary offers + roster + defection + SimBot:
  - **`docs/PROMPT_12_IMPLEMENTATION.md`**
  - **`MercenaryOfferData`**, **`MercenaryCatalog`**, **`MiniBossData`**; **`res://resources/mercenary_catalog.tres`**, **`mercenary_offers/`**, **`miniboss_data/`**
  - **`SignalBus`**: `mercenary_offer_generated`, `mercenary_recruited`, `ally_roster_changed`
  - **`CampaignManager`**: owned/active allies, offers, purchase, preview, defection, `auto_select_best_allies`
  - **`BetweenMissionScreen`**: Mercenaries tab; **`SimBot`**: `activate(strategy)`, `decide_mercenaries`, `get_log`
  - Tests: **`test_mercenary_offers.gd`**, **`test_mercenary_purchase.gd`**, **`test_campaign_ally_roster.gd`**, **`test_mini_boss_defection.gd`**, **`test_simbot_mercenaries.gd`**; **`./tools/run_gdunit_quick.sh`** allowlist
  - **`INDEX_SHORT.md`**, **`INDEX_FULL.md`**, **`INDEX_MACHINE.md`** updated
- Prompt 13 (2026-03-25) — hub dialogue (data-driven):
  - **`docs/PROMPT_13_IMPLEMENTATION.md`**
  - **`DialogueEntry`**, **`DialogueCondition`**; **`DialogueManager`** autoload; **`res://resources/dialogue/**`** pools
  - **`dialogue_ui.tscn`**, **`UIManager.show_dialogue_for_character`**, **`BetweenMissionScreen._show_hub_dialogue`**
  - Tests: **`test_dialogue_manager.gd`**; **`run_gdunit_quick.sh`** allowlist
  - **`INDEX_SHORT.md`**, **`INDEX_FULL.md`**, **`INDEX_MACHINE.md`**, **`ARCHITECTURE.md`** §1 updated

- Prompt 15 (2026-03-25) — Florence meta-state + day progression:
  - **`docs/PROMPT_15_IMPLEMENTATION.md`**
  - `res://scripts/florence_data.gd` (`FlorenceData`), `Types.DayAdvanceReason`, `SignalBus.florence_state_changed`
  - `GameManager` Florence ownership + meta day advancement + `get_florence_data()`
  - `ResearchManager` / `ShopManager` technical unlock hooks
  - `BetweenMissionScreen` Florence debug label + refresh on `florence_state_changed`
  - `DialogueManager` resolver support for `florence.*` and `campaign.*`
  - Tests: `res://tests/test_florence.gd` (+ quick allowlist update); parse-safety fixes (no invalid `Types.DayAdvanceReason(...)` cast; avoid `: FlorenceData` local type annotations)

- Prompt 17 (2026-03-25) — art placeholder pipeline scaffolding:
  - **`docs/PROMPT_17_IMPLEMENTATION.md`**
  - `res://scripts/art/art_placeholder_helper.gd` (`ArtPlaceholderHelper`)
  - `res://art/` hierarchy + `README_ART_PIPELINE.md` files
  - Primitive placeholder mesh/material `.tres` resources
  - Fixed Godot primitive `.tres` text format: added required `[resource]` wrapper to `art/meshes/**/*.tres` and `art/materials/factions/*.tres` (and matched `StandardMaterial3D` property order)
  - Updated `tests/test_art_placeholders.gd` to preload the helper script and fixed invalid enum fallback casting for headless parsing
  - Scene + script wiring for enemy/building/tower/arnulf + helper overrides
  - Tests: `res://tests/test_art_placeholders.gd` (+ quick allowlist update)
  - `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, `docs/INDEX_MACHINE.md` updated
