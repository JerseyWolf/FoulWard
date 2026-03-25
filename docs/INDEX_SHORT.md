INDEXSHORT.md
=============

FOUL WARD — INDEXSHORT.md

Compact repository reference. One-liner per file. Updated: 2026-03-25 (Prompt 13 hub dialogue: DialogueManager + DialogueEntry/Condition + DialogueUI; see `docs/PROMPT_13_IMPLEMENTATION.md`).
Source of truth: REPO_DUMP_AFTER_MVP.md; **re-run** `./tools/run_gdunit.sh` after Prompt 12/13 (use `./tools/run_gdunit_quick.sh` for iteration). **Handoff:** `docs/PROBLEM_REPORT.md` lists files and log snippets for GdUnit / `mission_won` / `push_warning` work.
AUTOLOADS (registered in project.godot, in init order)
Autoload Name	Path	What it does
SignalBus	res://autoloads/signal_bus.gd	Central hub for ALL cross-system typed signals. Prompt 10: boss_spawned, boss_killed, campaign_boss_attempted. Prompt 11: ally_spawned, ally_downed, ally_recovered, ally_killed, ally_state_changed (POST-MVP). Prompt 12: mercenary_offer_generated, mercenary_recruited, ally_roster_changed. No logic, no state.
CampaignManager	res://autoloads/campaign_manager.gd	Day/campaign progress; faction_registry + validate_day_configs; **owned_allies / active_allies_for_next_day**, mercenary catalog + offers, purchase + defection + `auto_select_best_allies` (Prompt 12); **current_ally_roster** sync for spawn (Prompt 11). **Init order:** must load **before** GameManager in `project.godot` so `SignalBus.mission_won` runs `_on_mission_won` (day increment) before GameManager hub transition.
DamageCalculator	res://autoloads/damage_calculator.gd	Stateless 4×4 damage-type × armor-type matrix. Pure function singleton.
EconomyManager	res://autoloads/economy_manager.gd	Owns gold, building_material, research_material. Emits resource_changed.
GameManager	res://autoloads/game_manager.gd	Owns game state, mission index, wave index, territory map runtime; mission rewards + territory bonuses. Prompt 10: final boss state, synthetic boss-attack days, held_territory_ids, prepare_next_campaign_day_if_needed / advance_to_next_day / get_day_config_for_index. Prompt 11: `_spawn_allies_for_current_mission` / `_cleanup_allies` (Main/AllyContainer, AllySpawnPoints). Prompt 12: `notify_mini_boss_defeated` → CampaignManager; `_transition_to` skips duplicate same-state transitions. `_begin_mission_wave_sequence`: Main→Managers→WaveManager via get_node_or_null; `push_warning` if absent (not `push_error` — GdUnit). Subscribes to `mission_won` for BETWEEN_MISSIONS / GAME_WON after CampaignManager (see `PROBLEM_REPORT.md`).
DialogueManager	res://autoloads/dialogue_manager.gd	Prompt 13: loads `DialogueEntry` `.tres` under `res://resources/dialogue/**`; priority, AND conditions, once-only, chain_next_id; signals `dialogue_line_started` / `dialogue_line_finished`; ResearchManager heuristics for `sybil_research_unlocked_any` (`spell` in node_id) and `arnulf_research_unlocked_any` (`arnulf` in node_id). See `docs/PROMPT_13_IMPLEMENTATION.md`.
AutoTestDriver	res://autoloads/auto_test_driver.gd	Headless smoke-test driver. Active only when --autotest flag is present.
SCRIPTS (attached to Manager nodes in main.tscn under /root/Main/Managers/)
Class Name	Path	What it does
Types	res://scripts/types.gd	All enums and shared constants. Prompt 11: `AllyClass` (MELEE/RANGED/SUPPORT); `TargetPriority` shared with allies (MVP: CLOSEST). Not an autoload; referenced as Types.XXX.
HealthComponent	res://scripts/healthcomponent.gd	Reusable HP tracker. Emits local signals health_depleted, health_changed.
WaveManager	res://scripts/wave_manager.gd	Spawns enemies per wave from FactionData-weighted roster (total N×6), countdown, wave signals. `_enemy_container` / `_spawn_points` via get_node_or_null(/root/Main/...); null-safe spawn. Prompt 10: boss_registry, ensure_boss_registry_loaded, set_day_context, boss wave on configured index + escorts.
SpellManager	res://scripts/spellmanager.gd	Owns mana pool, spell cooldowns. Executes Shockwave AoE in MVP.
ResearchManager	res://scripts/researchmanager.gd	Tracks unlocked research nodes. Gates locked buildings.
ShopManager	res://scripts/shopmanager.gd	Processes shop purchases. Applies mission-start consumable effects.
InputManager	res://scripts/inputmanager.gd	Translates mouse/keyboard input into public method calls on managers.
SimBot	res://scripts/sim_bot.gd	Headless automated playtester stub. Prompt 12: `activate(strategy)`, `decide_mercenaries`, `get_log`; plus existing bot_* helpers.
MainRoot	res://scripts/mainroot.gd	Applies root window content scale at startup (stretch fix for Godot 4.4+).
SCENES (runtime instantiated or statically placed)
Class Name	Script Path	Scene Path	What it does
Tower	res://scenes/tower/tower.gd	res://scenes/tower/tower.tscn	Player's stationary avatar. Fires crossbow + rapid missile.
Arnulf	res://scenes/arnulf/arnulf.gd	res://scenes/arnulf/arnulf.tscn	AI melee companion. State machine: IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING. Prompt 11: emits generic `ally_*` with id `arnulf` + `ALLY_ID_ARNULF`.
AllyBase	res://scenes/allies/ally_base.gd	res://scenes/allies/ally_base.tscn	Prompt 11: generic ally; CLOSEST targeting; nav chase; direct damage; ally_spawned / ally_killed.
HexGrid	res://scenes/hexgrid/hexgrid.gd	res://scenes/hexgrid/hexgrid.tscn	24-slot ring grid. Manages building placement, sell, upgrade.
BuildingBase	res://scenes/buildings/buildingbase.gd	res://scenes/buildings/buildingbase.tscn	Base class for all 8 building types. Auto-targets and fires.
EnemyBase	res://scenes/enemies/enemybase.gd	res://scenes/enemies/enemybase.tscn	Base class for all 6 enemy types. Nav, attack, die, reward.
BossBase	res://scenes/bosses/boss_base.gd	res://scenes/bosses/boss_base.tscn	Prompt 10: extends EnemyBase; initialize_boss_data(BossData); emits boss_spawned / boss_killed.
ProjectileBase	res://scenes/projectiles/projectilebase.gd	res://scenes/projectiles/projectilebase.tscn	Physics-driven projectile. Hits first valid enemy, self-destructs.
UI SCRIPTS & SCENES
Class Name	Script Path	Scene Path	What it does
UIManager	res://ui/ui_manager.gd	(Control node in main.tscn)	Lightweight state router. Shows/hides UI panels on game_state_changed. Prompt 13: `show_dialogue_for_character` + queue; instantiates `dialogueui.tscn` on demand.
DialogueUI	res://ui/dialogueui.gd	res://ui/dialogueui.tscn	Placeholder hub dialogue panel (name, text, Continue). Calls DialogueManager on advance.
HUD	res://ui/hud.gd	res://ui/hud.tscn	Combat overlay: resources, wave counter, HP bar, spells.
BuildMenu	res://ui/buildmenu.gd	res://ui/buildmenu.tscn	Radial building placement panel. Opens on hex slot click in BUILDMODE.
BetweenMissionScreen	res://ui/between_mission_screen.gd	res://ui/between_mission_screen.tscn	Post-mission tabs: World Map, Shop, Research, Buildings, Weapons, Mercenaries (Prompt 12). NEXT DAY. Prompt 13: on `BETWEEN_MISSIONS`, `_show_hub_dialogue()` → UIManager for SPELL_RESEARCHER then COMPANION_MELEE (queued).
WorldMap	res://ui/world_map.gd	res://ui/world_map.tscn	Territory list + details (read-only; GameManager state).
MainMenu	res://ui/mainmenu.gd	res://ui/mainmenu.tscn	Title screen. Start, Settings (placeholder), Quit.
MissionBriefing	res://ui/missionbriefing.gd	(Control node in main.tscn)	Shows mission number. BEGIN button → GameManager.start_wave_countdown.
EndScreen	res://ui/endscreen.gd	(Control node in main.tscn)	Final screen for win/lose. Restart and Quit buttons.
CUSTOM RESOURCE TYPES (script classes, not .tres files)
Class Name	Script Path	Fields summary
EnemyData	res://scripts/resources/enemydata.gd	enemy_type, display_name, max_hp, move_speed, damage, attack_range, attack_cooldown, armor_type, gold_reward, is_ranged, is_flying, color, damage_immunities[]
BuildingData	res://scripts/resources/buildingdata.gd	building_type, display_name, gold_cost, material_cost, upgrade_gold_cost, upgrade_material_cost, damage, upgraded_damage, fire_rate, attack_range, upgraded_range, damage_type, targets_air, targets_ground, is_locked, unlock_research_id, color, dot_enabled, dot_total_damage, dot_tick_interval, dot_duration, dot_effect_type, dot_source_id, dot_in_addition_to_hit
WeaponData	res://scripts/resources/weapondata.gd	weapon_slot, display_name, damage, projectile_speed, reload_time, burst_count, burst_interval, can_target_flying, assist_angle_degrees, assist_max_distance, base_miss_chance, max_miss_angle_degrees
SpellData	res://scripts/resources/spelldata.gd	spell_id, display_name, mana_cost, cooldown, damage, radius, damage_type, hits_flying
ResearchNodeData	res://scripts/resources/researchnodedata.gd	node_id, display_name, research_cost, prerequisite_ids[], description
ShopItemData	res://scripts/resources/shopitemdata.gd	item_id, display_name, gold_cost, material_cost, description
TerritoryData	res://scripts/resources/territory_data.gd	territory_id, terrain_type, ownership, default_faction_id (POST-MVP), is_secured, has_boss_threat, bonus_flat_gold_end_of_day, bonus_percent_gold_end_of_day, POST-MVP bonus hooks
TerritoryMapData	res://scripts/resources/territory_map_data.gd	territories: Array[TerritoryData], get_territory_by_id, has_territory
FactionRosterEntry	res://scripts/resources/faction_roster_entry.gd	enemy_type, base_weight, min_wave_index, max_wave_index, tier
FactionData	res://scripts/resources/faction_data.gd	faction_id, display_name, description, roster[], mini_boss_ids (BossData.boss_id strings), mini_boss_wave_hints, roster_tier, difficulty_offset; get_entries_for_wave, get_effective_weight_for_wave; BUILTIN_FACTION_RESOURCE_PATHS
BossData	res://scripts/resources/boss_data.gd	boss_id, stats, escort_unit_ids, phase_count, is_mini_boss / is_final_boss, boss_scene; build_placeholder_enemy_data(); BUILTIN_BOSS_RESOURCE_PATHS
DayConfig	res://scripts/resources/day_config.gd	day_index, mission_index, territory_id, faction_id (default DEFAULT_MIXED), is_mini_boss_day, is_mini_boss (alias), is_final_boss, boss_id, is_boss_attack_day, display_name, wave/tuning multipliers
CampaignConfig	res://scripts/resources/campaign_config.gd	campaign_id, display_name, day_configs, starting_territory_ids, territory_map_resource_path, short-campaign flags
AllyData	res://scripts/resources/ally_data.gd	Prompt 11: ally_id, ally_class, stats, preferred_targeting (CLOSEST MVP), is_unique. Prompt 12: role, damage_type, attack_damage / patrol / recovery, scene_path, is_starter_ally, is_defected_ally, debug_color; POST-MVP progression fields.
MercenaryOfferData	res://scripts/resources/mercenary_offer_data.gd	Prompt 12: ally_id, costs, day range, is_defection_offer.
MercenaryCatalog	res://scripts/resources/mercenary_catalog.gd	Prompt 12: offers pool, max_offers_per_day, get_daily_offers.
MiniBossData	res://scripts/resources/mini_boss_data.gd	Prompt 12: defection metadata (defected_ally_id, costs).
DialogueCondition	res://scripts/resources/dialogue/dialogue_condition.gd	key, comparison (==, !=, >, >=, <, <=), value (Variant) — AND only; evaluated by DialogueManager
DialogueEntry	res://scripts/resources/dialogue/dialogue_entry.gd	entry_id, character_id, text, priority, once_only, chain_next_id, conditions[]
RESOURCE FILES (.tres — actual data)
Ally data (Prompt 11)
File	ally_id	Notes
res://resources/ally_data/ally_melee_generic.tres	ally_melee_generic	Placeholder melee merc
res://resources/ally_data/ally_ranged_generic.tres	ally_ranged_generic	Placeholder ranged merc
res://resources/ally_data/ally_support_generic.tres	ally_support_generic	Optional; not in static roster by default
Mercenary data (Prompt 12)
File	Notes
res://resources/mercenary_catalog.tres	Default offer pool; referenced by CampaignManager
res://resources/mercenary_offers/*.tres	Per-offer rows (subset; catalog may embed sub-resources)
res://resources/miniboss_data/*.tres	Mini-boss defection metadata
Dialogue pools (Prompt 13)
Folder	Notes
res://resources/dialogue/florence/	FLORENCE lines (placeholder TODO)
res://resources/dialogue/companion_melee/	COMPANION_MELEE (Arnulf) — intro, arnulf research hook, generic
res://resources/dialogue/spell_researcher/	SPELL_RESEARCHER (Sybil) — intro, spell-unlock hook, generic
res://resources/dialogue/weapons_engineer/	WEAPONS_ENGINEER placeholder pool
res://resources/dialogue/enchanter/	ENCHANTER placeholder pool
res://resources/dialogue/merchant/	MERCHANT placeholder pool
res://resources/dialogue/mercenary_commander/	MERCENARY_COMMANDER placeholder pool
res://resources/dialogue/campaign_character_template/	CAMPAIGN_CHARACTER_X template pool
res://resources/dialogue/example_character/	EXAMPLE_CHARACTER — conditional + chain demo entries
Enemy Data
File	enemy_type	armor_type	Notes
res://resources/enemydata/orcgrunt.tres	ORCGRUNT	UNARMORED	Basic melee runner
res://resources/enemydata/orcbrute.tres	ORCBRUTE	HEAVYARMOR	Slow, high HP, melee
res://resources/enemydata/goblinfirebug.tres	GOBLINFIREBUG	UNARMORED	Fast melee, fire immune
res://resources/enemydata/plaguezombie.tres	PLAGUEZOMBIE	UNARMORED	Slow tank, poison immune
res://resources/enemydata/orcarcher.tres	ORCARCHER	UNARMORED	Stops at range, fires
res://resources/enemydata/batswarm.tres	BATSWARM	FLYING	Flying, anti-air only
Building Data
File	building_type	is_locked	unlock_research_id
res://resources/buildingdata/arrowtower.tres	ARROWTOWER	false	—
res://resources/buildingdata/firebrazier.tres	FIREBRAZIER	false	—
res://resources/buildingdata/magicobelisk.tres	MAGICOBELISK	false	—
res://resources/buildingdata/poisonvat.tres	POISONVAT	false	—
res://resources/buildingdata/ballista.tres	BALLISTA	true	unlock_ballista
res://resources/buildingdata/archerbarracks.tres	ARCHERBARRACKS	true	(POST-MVP stub)
res://resources/buildingdata/antiairbolt.tres	ANTIAIRBOLT	false	—
res://resources/buildingdata/shieldgenerator.tres	SHIELDGENERATOR	true	(POST-MVP stub)
Weapon Data
File	weapon_slot	burst_count
res://resources/weapondata/crossbow.tres	CROSSBOW	1
res://resources/weapondata/rapidmissile.tres	RAPIDMISSILE	10
Spell / Research / Shop Data
File	Class	Notes
res://resources/spelldata/shockwave.tres	SpellData	Shockwave AoE, 50 mana, 60s cooldown
res://resources/researchdata/basestructurestree.tres	ResearchNodeData	6 nodes: unlock_ballista, unlock_antiair, arrow_tower_dmg, unlock_shield_gen, fire_brazier_range, unlock_archer_barracks
res://resources/shopdata/shopcatalog.tres	ShopItemData[]	4 items: tower_repair, building_repair, arrow_tower (voucher), mana_draught
res://resources/territories/main_campaign_territories.tres	TerritoryMapData	Five placeholder territories for main campaign
res://resources/campaign_main_50days.tres	CampaignConfig	50 linear days + territory_map_resource_path (Prompt 8 canonical)
res://resources/campaigns/campaign_short_5_days.tres	CampaignConfig	Default MVP 5-day short campaign (mission_index 1–5)
Faction data
File	faction_id	Notes
res://resources/faction_data_default_mixed.tres	DEFAULT_MIXED	Equal-weight six-type MVP mix
res://resources/faction_data_orc_raiders.tres	ORC_RAIDERS	Orc-heavy roster + placeholder mini-boss id
res://resources/faction_data_plague_cult.tres	PLAGUE_CULT	Undead/fire/flyer mix + mini-boss id (BossData)
Boss data (Prompt 10)
File	boss_id	Notes
res://resources/bossdata_plague_cult_miniboss.tres	plague_cult_miniboss	Shared boss_base.tscn
res://resources/bossdata_orc_warlord_miniboss.tres	orc_warlord	Shared boss_base.tscn
res://resources/bossdata_final_boss.tres	final_boss	Day 50 / campaign boss
TEST FILES (res://tests/, GdUnit4 framework; full run see PROMPT_9_IMPLEMENTATION.md / PROMPT_10_IMPLEMENTATION.md / PROMPT_12_IMPLEMENTATION.md / PROMPT_13_IMPLEMENTATION.md)
File	What it covers
testmercenaryoffers.gd	Prompt 12: offer generation / preview
testmercenarypurchase.gd	Prompt 12: purchase + economy
testcampaignallyroster.gd	Prompt 12: owned/active roster APIs
testminibossdefection.gd	Prompt 12: defection offer injection
testsimbotmercenaries.gd	Prompt 12: SimBot mercenary API
test_dialogue_manager.gd	Prompt 13: DialogueManager conditions, priority, once-only, chain fallback, resource load
testeconomymanager.gd	gold/material add/spend/reset, signal emission, transactions
testdamagecalculator.gd	Full 4×4 matrix, boundary values, DoT stub
testwavemanager.gd	Wave scaling, countdown, spawn count, faction-weighted composition, mini-boss hook, Prompt 10: regular day spawns no bosses
testbossdata.gd	BossData load, BUILTIN paths, placeholder EnemyData build
testbossbase.gd	BossBase init, nav present, kill → boss_killed
testbosswaves.gd	Boss wave index + escorts + wave_cleared to max
testfinalbossday.gd	Final-boss day / GameManager campaign hooks (see test file)
testfactiondata.gd	Faction .tres load + roster→EnemyData; validate_day_configs on short campaign
testspellmanager.gd	Mana regen, deduct, cooldown, shockwave AoE damage
testarnulfstatemachine.gd	All state transitions, downed/recover cycle
testallydata.gd	AllyData defaults + all res://resources/ally_data/*.tres loads
testallybase.gd	AllyBase find_target, attack in range, ally_killed on HP depletion
testallysignals.gd	ally_spawned, ally_killed, Arnulf generic ally_* + reset ally_spawned
testallyspawning.gd	Campaign roster count under AllyContainer; cleanup on waves cleared / new game
testhealthcomponent.gd	take_damage, heal, reset, health_depleted signal
testresearchmanager.gd	unlock, prereq gating, insufficient material, reset
testshopmanager.gd	purchase flow, affordability, effect application, signal
testgamemanager.gd	State transitions, mission progression, win/fail paths, campaign/territory integration
testterritorydata.gd	Main territory map load and IDs
testcampaignterritorymapping.gd	50-day DayConfig → territory_id validity
testcampaignterritoryupdates.gd	apply_day_result_to_territory + SignalBus
testterritoryeconomybonuses.gd	Gold modifier aggregation
testworldmapui.gd	WorldMap button labels on territory_state_changed
testhexgrid.gd	24 slots, place/sell/upgrade, resource deduction, signals
testbuildingbase.gd	Combat loop, targeting, fire rate, upgrade stats
testprojectilesystem.gd	Init paths, travel, collision, damage matrix, immunity, miss
testsimulationapi.gd	All manager public methods callable without UI
testenemypathfinding.gd	EnemyBase nav, attack, health_depleted → gold signal
KNOWN OPEN ISSUES (as of Autonomous Session 3)

    Sell UX is now wired in build mode: InputManager routes slot clicks to BuildMenu placement/sell mode.

    Phase 6 playtest rows 5 (sell), 6 (Sybil shockwave full verify), 7 (Arnulf full verify), 10 (between-mission full loop) not fully confirmed.

    WAVES_PER_MISSION = 3 in GameManager (dev cap; final value is 10).

    dev_unlock_all_research = true in main.tscn (dev flag; must be set false for release).

    SimBot: strategy `activate`, `decide_mercenaries`, `get_log` (Prompt 12); building/spell/wave bot_* helpers remain.

    Windows headless main.tscn run may SIGSEGV; use editor F5 for full loop on Windows.

    GDAI MCP Runtime autoload removed from project.godot (resolved noise issue).

PHYSICS LAYERS
Layer	Assigned to
1	Tower (StaticBody3D)
2	Enemies
5	Projectiles
7	HexGrid slots (Area3D)
INPUT ACTIONS (defined in project.godot Input Map)
Action Name	Default Binding	Purpose
fire_primary	Left Mouse	Florence crossbow
fire_secondary	Right Mouse	Florence rapid missile
cast_shockwave	Space	Sybil's Shockwave spell
toggle_build_mode	B or Tab	Enter/exit build mode
cancel	Escape	Exit build mode / close menu
SCENE TREE OVERVIEW (main.tscn)

/root/Main (Node3D)
├── Camera3D
├── WorldEnvironment
├── Tower (StaticBody3D) [tower.tscn]
│ ├── TowerMesh (MeshInstance3D)
│ ├── TowerCollision (CollisionShape3D)
│ ├── HealthComponent (Node)
│ └── TowerLabel (Label3D)
├── HexGrid (Node3D) [hexgrid.tscn]
│ └── HexSlot00..HexSlot23 (Area3D ×24)
├── Arnulf (CharacterBody3D) [arnulf.tscn]
├── BuildingContainer (Node3D)
├── ProjectileContainer (Node3D)
├── EnemyContainer (Node3D)
├── Managers (Node)
│ ├── WaveManager (Node)
│ ├── SpellManager (Node)
│ ├── ResearchManager (Node)
│ ├── ShopManager (Node)
│ └── InputManager (Node)
└── UI (CanvasLayer)
  ├── UIManager (Control)
  ├── HUD [hud.tscn]
  ├── BuildMenu [buildmenu.tscn]
  ├── BetweenMissionScreen [betweenmissionscreen.tscn]
  ├── MainMenu [mainmenu.tscn]
  ├── MissionBriefing (Control)
  └── EndScreen (Control)

LATEST CHANGES (2026-03-25)

    - Prompt 13 hub dialogue (`docs/PROMPT_13_IMPLEMENTATION.md`): `DialogueManager` autoload; `DialogueEntry` / `DialogueCondition`; `res://resources/dialogue/**` pools; `dialogue_ui.tscn`; `UIManager.show_dialogue_for_character` + queue; `BetweenMissionScreen` hub lines for Sybil + Arnulf; `test_dialogue_manager.gd` + `run_gdunit_quick.sh` allowlist.

    - Prompt 12 mercenary roster + offers (`docs/PROMPT_12_IMPLEMENTATION.md`): `MercenaryOfferData`, `MercenaryCatalog`, `MiniBossData`, `res://resources/mercenary_catalog.tres` + offers; `CampaignManager` purchase/preview/defection/auto-select; `SignalBus` mercenary + roster signals; `BetweenMissionScreen` Mercenaries tab; `SimBot` strategy + `decide_mercenaries`; GdUnit suites in `run_gdunit_quick.sh` allowlist; `GameManager._transition_to` idempotent for same state.

LATEST CHANGES (2026-03-24)

    - Prompt 10 fixes (`docs/PROMPT_10_FIXES.md`): WaveManager `get_node_or_null` for EnemyContainer/SpawnPoints; `test_wave_manager` / `test_boss_waves` add SpawnPoints to tree before Marker3D `global_position`; `WeaponLevelData` `.tres` `script_class` header; `test_campaign_manager` GdUnit `assert_that().is_not_null()`; `GameManager` `push_warning` + `mission_won` hub (`project.godot` CampaignManager before GameManager); `docs/PROBLEM_REPORT.md` for errors/snippets.
- Prompt 10 mini-boss + campaign boss (`docs/PROMPT_10_IMPLEMENTATION.md`):
  - `BossData` (`res://scripts/resources/boss_data.gd`), `.tres` bosses under `res://resources/bossdata_*.tres`.
  - `BossBase` (`res://scenes/bosses/boss_base.{gd,tscn}`).
  - `SignalBus`: `boss_spawned`, `boss_killed`, `campaign_boss_attempted`.
  - `GameManager` / `CampaignManager`: Day 50 + synthetic boss-attack day flow; `get_day_config_for_index`; territory secure on mini-boss kill.
  - `WaveManager`: `boss_registry`, `set_day_context`, `ensure_boss_registry_loaded`, boss wave + escorts (`Types.EnemyType.keys()` string match).
  - `DayConfig`: `boss_id`, `is_mini_boss`, `is_boss_attack_day`; `CampaignConfig.starting_territory_ids`; `TerritoryData.is_secured`, `has_boss_threat`.
  - Tests: `test_boss_data.gd`, `test_boss_base.gd`, `test_boss_waves.gd`, `test_final_boss_day.gd`; additions in `test_wave_manager.gd`.

- Prompt 7 campaign/day layer added:
  - New autoload: `CampaignManager` (`res://autoloads/campaign_manager.gd`).
  - New resource classes:
    - `CampaignConfig` (`res://scripts/resources/campaign_config.gd`)
    - `DayConfig` (`res://scripts/resources/day_config.gd`)
  - New campaign resources:
    - `res://resources/campaigns/campaign_short_5_days.tres`
    - `res://resources/campaigns/campaign_main_50_days.tres`
  - `SignalBus` added campaign/day lifecycle signals:
    - `campaign_started`, `day_started`, `day_won`, `day_failed`, `campaign_completed`
  - `GameManager` now exposes `start_mission_for_day(day_index, day_config)` and delegates day progression to `CampaignManager`.
  - `WaveManager` now supports day config fields:
    - `configured_max_waves`, `enemy_hp_multiplier`, `enemy_damage_multiplier`, `gold_reward_multiplier`
  - `BetweenMissionScreen` now displays day info and routes next progression via `CampaignManager.start_next_day()`.
  - Added tests:
    - `res://tests/test_campaign_manager.gd`
    - Prompt 7 additions in `res://tests/test_wave_manager.gd`
    - Prompt 7 additions in `res://tests/test_game_manager.gd`

- Prompt 9 factions + weighted waves (`docs/PROMPT_9_IMPLEMENTATION.md`):
  - `FactionData`, `FactionRosterEntry`; `.tres` factions `DEFAULT_MIXED`, `ORC_RAIDERS`, `PLAGUE_CULT`.
  - `WaveManager` roster-weighted spawns (total `N×6`), `set_faction_data_override`, `get_mini_boss_info_for_wave`, `faction_registry`.
  - `CampaignManager.faction_registry`, `validate_day_configs`.
  - `DayConfig.faction_id` default `DEFAULT_MIXED`; `is_mini_boss_day`; `TerritoryData.default_faction_id`.
  - `GameManager` applies `WaveManager.configure_for_day` after `reset_for_new_mission`.
  - Tests: `res://tests/test_faction_data.gd`, Prompt 9 cases in `res://tests/test_wave_manager.gd`.

- InputManager build-mode click now raycasts hex slots on layer 7 and routes menu mode by occupancy.
- BuildMenu now supports `open_for_sell_slot(slot_index, slot_data)` and a sell panel with Sell/Cancel actions.
- HexGrid slot click callback now only updates highlight in build mode (menu opening is centralized in InputManager).
- Added concrete HexGrid sell-flow tests for slot clearing, refund correctness, and `building_sold` signal emission.
- Implementation notes recorded in `docs/PROMPT_1_IMPLEMENTATION.md`.
- Phase 2 firing changes added:
  - `WeaponData` now includes assist/miss tuning fields (all default to `0.0`).
  - `Tower` manual shots now pass through private aim helper for cone assist + miss perturbation.
  - `crossbow.tres` has initial tuning defaults (`7.5`, `0.05`, `2.0`), `rapid_missile.tres` remains `0.0`.
  - Added simulation API tests covering assist, miss, and autofire bypass behavior.
- Implementation notes recorded in `docs/PROMPT_2_IMPLEMENTATION.md`.
- Phase 3 weapon-upgrade system added:
  - `WeaponLevelData` resource class (`res://scripts/resources/weapon_level_data.gd`)
  - `WeaponUpgradeManager` scene-bound manager (`/root/Main/Managers/WeaponUpgradeManager`)
  - New level resources in `res://resources/weapon_level_data/` (crossbow + rapid missile, levels 1-3)
  - `SignalBus.weapon_upgraded(weapon_slot, new_level)`
  - `BetweenMissionScreen` now includes a Weapons tab with upgrade controls
  - `Tower` now resolves effective damage/speed/reload/burst via manager with null-guard fallback
  - `docs/PROMPT_3_IMPLEMENTATION.md` records implementation details
- Phase 4 two-slot enchantment system added:
  - New autoload: `EnchantmentManager` (`res://autoloads/enchantment_manager.gd`)
  - New resource class: `EnchantmentData` (`res://scripts/resources/enchantment_data.gd`)
  - New resources: `res://resources/enchantments/{scorching_bolts,sharpened_mechanism,toxic_payload,arcane_focus}.tres`
  - New SignalBus signals: `enchantment_applied(...)`, `enchantment_removed(...)`
  - `Tower` now composes projectile damage + damage type using `"elemental"` and `"power"` enchantment slots
  - `ProjectileBase.initialize_from_weapon(...)` now supports optional custom damage and damage type
  - `GameManager.start_new_game()` resets enchantment state
  - `BetweenMissionScreen` now includes enchantment apply/remove controls in Weapons tab
  - Added tests: `res://tests/test_enchantment_manager.gd`, `res://tests/test_tower_enchantments.gd`
  - Added projectile regression: `test_initialize_from_weapon_without_custom_values_uses_physical`
- Phase 5 DoT system added:
  - `DamageCalculator.calculate_dot_tick(...)` now returns live per-tick DoT values (no stub).
  - `EnemyBase` now stores `active_status_effects` and exposes `apply_dot_effect(effect_data: Dictionary)`.
  - Burn: one stack per source with duration refresh + max total damage retention.
  - Poison: additive stacks capped by `MAX_POISON_STACKS`.
  - `ProjectileBase.initialize_from_building(...)` now accepts DoT fields and applies DoT on hit for fire/poison.
  - Fire Brazier / Poison Vat `.tres` now include conservative DoT defaults.
  - Added tests: `res://tests/test_enemy_dot_system.gd`; DoT integration coverage in `res://tests/test_projectile_system.gd`.
- Phase 6 solid-building navigation added:
  - `BuildingBase` scene now includes `BuildingCollision` (`StaticBody3D`) + `NavigationObstacle3D`.
  - `BuildingBase` script now centralizes footprint/obstacle tuning constants and setup.
  - `EnemyBase` ground pathing now tracks progress and applies stuck recovery retargeting.
  - `EnemyBase` flying pathing remains direct steering and ignores ground obstacles.
  - `HexGrid` placement now calls `_activate_building_obstacle(...)` hook.
  - Added pathing integration scenarios in `res://tests/test_enemy_pathfinding.gd`.
  - Added building collision/obstacle scene assertion in `res://tests/test_building_base.gd`.
