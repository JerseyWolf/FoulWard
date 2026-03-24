INDEXSHORT.md
=============

FOUL WARD — INDEXSHORT.md

Compact repository reference. One-liner per file. Updated: 2026-03-24 (post-MVP, after Autonomous Sessions 1–3).
Source of truth: REPO_DUMP_AFTER_MVP.md (110 files, 289 GdUnit4 tests, 0 failures).
AUTOLOADS (registered in project.godot, in init order)
Autoload Name	Path	What it does
SignalBus	res://autoloads/signalbus.gd	Central hub for ALL cross-system typed signals. No logic, no state.
DamageCalculator	res://autoloads/damagecalculator.gd	Stateless 4×4 damage-type × armor-type matrix. Pure function singleton.
EconomyManager	res://autoloads/economymanager.gd	Owns gold, building_material, research_material. Emits resource_changed.
GameManager	res://autoloads/gamemanager.gd	Owns game state, mission index, wave index. Drives the full session loop.
AutoTestDriver	res://autoloads/autotestdriver.gd	Headless smoke-test driver. Active only when --autotest flag is present.
SCRIPTS (attached to Manager nodes in main.tscn under /root/Main/Managers/)
Class Name	Path	What it does
Types	res://scripts/types.gd	All enums and shared constants. Not an autoload; referenced as Types.XXX.
HealthComponent	res://scripts/healthcomponent.gd	Reusable HP tracker. Emits local signals health_depleted, health_changed.
WaveManager	res://scripts/wavemanager.gd	Spawns enemies per wave, runs countdown timer, emits wave signals.
SpellManager	res://scripts/spellmanager.gd	Owns mana pool, spell cooldowns. Executes Shockwave AoE in MVP.
ResearchManager	res://scripts/researchmanager.gd	Tracks unlocked research nodes. Gates locked buildings.
ShopManager	res://scripts/shopmanager.gd	Processes shop purchases. Applies mission-start consumable effects.
InputManager	res://scripts/inputmanager.gd	Translates mouse/keyboard input into public method calls on managers.
SimBot	res://scripts/simbot.gd	Headless automated playtester stub. activate/deactivate only in MVP.
MainRoot	res://scripts/mainroot.gd	Applies root window content scale at startup (stretch fix for Godot 4.4+).
SCENES (runtime instantiated or statically placed)
Class Name	Script Path	Scene Path	What it does
Tower	res://scenes/tower/tower.gd	res://scenes/tower/tower.tscn	Player's stationary avatar. Fires crossbow + rapid missile.
Arnulf	res://scenes/arnulf/arnulf.gd	res://scenes/arnulf/arnulf.tscn	AI melee companion. State machine: IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING.
HexGrid	res://scenes/hexgrid/hexgrid.gd	res://scenes/hexgrid/hexgrid.tscn	24-slot ring grid. Manages building placement, sell, upgrade.
BuildingBase	res://scenes/buildings/buildingbase.gd	res://scenes/buildings/buildingbase.tscn	Base class for all 8 building types. Auto-targets and fires.
EnemyBase	res://scenes/enemies/enemybase.gd	res://scenes/enemies/enemybase.tscn	Base class for all 6 enemy types. Nav, attack, die, reward.
ProjectileBase	res://scenes/projectiles/projectilebase.gd	res://scenes/projectiles/projectilebase.tscn	Physics-driven projectile. Hits first valid enemy, self-destructs.
UI SCRIPTS & SCENES
Class Name	Script Path	Scene Path	What it does
UIManager	res://ui/uimanager.gd	(Control node in main.tscn)	Lightweight state router. Shows/hides UI panels on game_state_changed.
HUD	res://ui/hud.gd	res://ui/hud.tscn	Combat overlay: resources, wave counter, HP bar, spells.
BuildMenu	res://ui/buildmenu.gd	res://ui/buildmenu.tscn	Radial building placement panel. Opens on hex slot click in BUILDMODE.
BetweenMissionScreen	res://ui/betweenmissionscreen.gd	res://ui/betweenmissionscreen.tscn	Post-mission tabs: Shop, Research, Buildings. NEXT MISSION.
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
RESOURCE FILES (.tres — actual data)
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
TEST FILES (res://tests/, GdUnit4 framework, 289 cases total, 0 failures)
File	What it covers
testeconomymanager.gd	gold/material add/spend/reset, signal emission, transactions
testdamagecalculator.gd	Full 4×4 matrix, boundary values, DoT stub
testwavemanager.gd	Wave scaling, countdown, spawn count, signal sequence
testspellmanager.gd	Mana regen, deduct, cooldown, shockwave AoE damage
testarnulfstatemachine.gd	All state transitions, downed/recover cycle
testhealthcomponent.gd	take_damage, heal, reset, health_depleted signal
testresearchmanager.gd	unlock, prereq gating, insufficient material, reset
testshopmanager.gd	purchase flow, affordability, effect application, signal
testgamemanager.gd	State transitions, mission progression, win/fail paths
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

    SimBot: activate/deactivate only. No strategy profiles, no balance logging output.

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

LATEST CHANGES (2026-03-24)

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
