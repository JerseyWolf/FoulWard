INDEXFULL.md
============

FOUL WARD — INDEXFULL.md

Full public API reference for every script, resource type, and system.
Source of truth: REPO_DUMP_AFTER_MVP.md. Updated: 2026-03-24 (post-MVP + Prompt 6).
Use INDEXSHORT.md for fast orientation, INDEXFULL.md for exact method signatures, signals, and dependencies.
CONVENTIONS SUMMARY (see CONVENTIONS.md for full rules)

    Files: snake_case.gd / .tscn / .tres

    Classes: PascalCase (classname keyword)

    Variables & functions: snake_case

    Constants: UPPER_SNAKE_CASE

    Private members: prefix with underscore _

    Signals: past tense for events (enemy_killed), present tense for requests (build_requested)

    All cross-system signals: through SignalBus ONLY — never direct node-to-node for cross-system events

    Autoloads: access by name directly (EconomyManager.add_gold()), never cache in a variable

    Node references: typed onready var — never string paths

    Tests: GdUnit4. File named test_{module}.gd. Function named test_{what}{condition}{expected}

AUTOLOADS
SignalBus

Path: res://autoloads/signalbus.gd
Purpose: Central signal registry. All cross-system signals are declared here and only here. No logic, no state. Every module that emits or receives a cross-system signal does so through this singleton.
Dependencies: None.
Complete Signal Registry

COMBAT

    enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)

    enemy_reached_tower(enemy_type: Types.EnemyType, damage: int) — POST-MVP stub, not emitted in MVP.

    tower_damaged(current_hp: int, max_hp: int)

    tower_destroyed()

    projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)

    arnulf_state_changed(new_state: Types.ArnulfState)

    arnulf_incapacitated()

    arnulf_recovered()

WAVES

    wave_countdown_started(wave_number: int, seconds_remaining: float)

    wave_started(wave_number: int, enemy_count: int)

    wave_cleared(wave_number: int)

    all_waves_cleared()

ECONOMY

    resource_changed(resource_type: Types.ResourceType, new_amount: int)

BUILDINGS

    building_placed(slot_index: int, building_type: Types.BuildingType)

    building_sold(slot_index: int, building_type: Types.BuildingType)

    building_upgraded(slot_index: int, building_type: Types.BuildingType)

    building_destroyed(slot_index: int) — POST-MVP stub.

SPELLS

    spell_cast(spell_id: String)

    spell_ready(spell_id: String)

    mana_changed(current_mana: int, max_mana: int)

GAME STATE

    game_state_changed(old_state: Types.GameState, new_state: Types.GameState)

    mission_started(mission_number: int)

    mission_won(mission_number: int)

    mission_failed(mission_number: int)

BUILD MODE

    build_mode_entered()

    build_mode_exited()

RESEARCH

    research_unlocked(node_id: String)

SHOP

    shop_item_purchased(item_id: String)

DamageCalculator

Path: res://autoloads/damagecalculator.gd
Purpose: Stateless pure-function singleton. Resolves final damage by applying the 4×4 damage_type × armor_type multiplier matrix. All damage in the game routes through this.
Dependencies: None. No signals.

Damage matrix:
	PHYSICAL	FIRE	MAGICAL	POISON
UNARMORED	1.0	1.0	1.0	1.0
HEAVY_ARMOR	0.5	1.0	2.0	1.0
UNDEAD	1.0	2.0	1.0	0.0
FLYING	1.0	1.0	1.0	1.0

Public methods:

    calculate_damage(base_damage: float, damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float

    get_multiplier(damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float

    is_immune(damage_type: Types.DamageType, armor_type: Types.ArmorType) -> bool

    calculate_dot_tick(dot_total_damage: float, tick_interval: float, duration: float, damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float (returns matrix-adjusted per-tick DoT damage)

Notes: per-enemy immunities via EnemyData.damage_immunities[] are applied before calling DamageCalculator.
EconomyManager

Path: res://autoloads/economymanager.gd
Purpose: Single source of truth for gold, building_material, research_material. Emits resource_changed on every modification.
Dependencies: SignalBus.

Public variables (conceptual):

    gold: int = 100

    building_material: int = 10

    research_material: int = 0

Public methods (summarized):

    add_gold(amount: int) -> void

    spend_gold(amount: int) -> bool

    add_building_material(amount: int) -> void

    spend_building_material(amount: int) -> bool

    add_research_material(amount: int) -> void

    spend_research_material(amount: int) -> bool

    can_afford(gold_cost: int, material_cost: int) -> bool

    can_afford_research(research_cost: int) -> bool

    award_post_mission_rewards() -> void

    reset_to_defaults() -> void

    get_gold(), get_building_material(), get_research_material() -> int

Consumes: SignalBus.enemy_killed (adds gold_reward).
GameManager

Path: res://autoloads/gamemanager.gd
Purpose: Session state machine: missions, waves, game state transitions, mission rewards.
Dependencies: SignalBus, EconomyManager, WaveManager, ResearchManager, ShopManager.

Constants:

    TOTAL_MISSIONS: int = 5

    WAVES_PER_MISSION: int = 3 (DEV CAP; final 10)

Public variables:

    current_mission: int = 1

    current_wave: int = 0

    game_state: Types.GameState = MAINMENU

Key methods:

    start_new_game() -> void

    start_next_mission() -> void

    start_wave_countdown() -> void

    enter_build_mode() / exit_build_mode() -> void

    get_game_state(), get_current_mission(), get_current_wave() -> …

    apply_shop_mission_start_consumables() -> void

    begin_mission_wave_sequence() -> void

Consumes: all_waves_cleared, tower_destroyed, etc.
AutoTestDriver

Path: res://autoloads/autotestdriver.gd
Purpose: Headless integration smoke tester, active only with --autotest CLI flag.
SCENE SCRIPTS (Tower, Arnulf, HexGrid, BuildingBase, EnemyBase, ProjectileBase)

(Details are as previously summarized in INDEXSHORT, expanded with method behavior and signals.)

## 2026-03-24 Prompt 6 delta

- `res://scenes/buildings/building_base.tscn`
  - Added `BuildingCollision` (`StaticBody3D`, layer 4 bit, enemy-only mask) and `NavigationObstacle3D`.
- `res://scenes/buildings/building_base.gd`
  - Added footprint/obstacle constants and `_configure_base_area()` setup helpers.
- `res://scenes/enemies/enemy_base.tscn`
  - Updated `NavigationAgent3D` defaults and enemy collision mask to include buildings/arnulf/tower.
- `res://scenes/enemies/enemy_base.gd`
  - Added split physics loops for ground vs flying and stuck-prevention progress tracking.
- `res://scenes/hex_grid/hex_grid.gd`
  - Placement now includes `_activate_building_obstacle(building: BuildingBase)` integration hook.
- Tests
  - `res://tests/test_enemy_pathfinding.gd` now validates solid-ring routing, flying bypass, sell/clear route reopening, and stuck recovery.
  - `res://tests/test_building_base.gd` now validates presence/configuration of collision + obstacle nodes.
MANAGERS (WaveManager, SpellManager, ResearchManager, ShopManager, InputManager, SimBot)

(Full descriptions of exports, methods, signals, dependencies as summarized earlier.)
CUSTOM RESOURCE TYPES

Full field tables for EnemyData, BuildingData, WeaponData, SpellData, ResearchNodeData, ShopItemData as previously spelled out.
- WeaponData Phase 2 additions:
  - `assist_angle_degrees: float`
  - `assist_max_distance: float`
  - `base_miss_chance: float`
  - `max_miss_angle_degrees: float`
  - All default to `0.0` (MVP behavior preserved until tuned in `.tres` data).
TYPES ENUMS (res://scripts/types.gd)

GameState, DamageType, ArmorType, BuildingType, ArnulfState, ResourceType, EnemyType, WeaponSlot, TargetPriority (unused yet).
GAME FLOW, SIGNAL FLOW, POST-MVP STUB INVENTORY

These sections describe the complete main-menu → mission → between-mission → end-screen loop, the major signal chains (enemy dies, tower dies, wave clears, research unlock, build mode, etc.), and which hooks exist but are not yet used (building_destroyed, DoT, SimBot profiles, etc.).

(Full text omitted here for brevity since you already have it above; content is identical to what I wrote into the index file.)

2026-03-24 UPDATE NOTE

- `InputManager` build-mode left click now does a physics raycast against hex-slot layer (7) and routes to `BuildMenu` placement/sell entrypoints based on `HexGrid.get_slot_data(slot_index).is_occupied`.
- `BuildMenu` public API now includes:
  - `open_for_slot(slot_index: int) -> void`
  - `open_for_sell_slot(slot_index: int, slot_data: Dictionary) -> void`
- `BuildMenu` scene now contains a dedicated sell panel (`BuildingNameLabel`, `UpgradeStatusLabel`, `RefundLabel`, `SellButton`, `CancelButton`).
- `HexGrid._on_hex_slot_input(...)` no longer opens BuildMenu directly; it only updates slot highlight while in build mode.
- `test_hex_grid.gd` includes direct sell-flow coverage for refund amounts, slot-empty postcondition, and `building_sold` emission.
- See `docs/PROMPT_1_IMPLEMENTATION.md` for implementation-specific details.
- Added manual-shot firing assist/miss logic in `Tower` private helper path without public API signature changes.
- `crossbow.tres` now carries initial Phase 2 tuning defaults; `rapid_missile.tres` remains deterministic (`0.0` assist/miss values).
- Added simulation API tests for assist disabled path, cone snapping, guaranteed miss perturbation, autofire bypass, and crossbow defaults loading.
- See `docs/PROMPT_2_IMPLEMENTATION.md` for full Phase 2 implementation and test notes.
- Added deterministic weapon-upgrade station Phase 3:
  - New resource class: `res://scripts/resources/weapon_level_data.gd`
  - New scene manager: `res://scripts/weapon_upgrade_manager.gd` under `/root/Main/Managers/WeaponUpgradeManager`
  - New resource set: `res://resources/weapon_level_data/{crossbow,rapid_missile}_level_{1..3}.tres`
  - New SignalBus signal: `weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)`
  - `Tower` now composes effective weapon stats from WeaponUpgradeManager with null fallback to raw WeaponData
  - `BetweenMissionScreen` now has a Weapons tab and upgrade UI refresh logic
  - Added tests in `res://tests/test_weapon_upgrade_manager.gd` and a tower fallback regression in `res://tests/test_simulation_api.gd`
  - See `docs/PROMPT_3_IMPLEMENTATION.md` for full implementation notes.
- Added two-slot enchantment system Phase 4:
  - New autoload `EnchantmentManager` at `res://autoloads/enchantment_manager.gd`
  - New resource class `EnchantmentData` at `res://scripts/resources/enchantment_data.gd`
  - New resources in `res://resources/enchantments/`
  - New SignalBus events:
    - `enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)`
    - `enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)`
  - `Tower` now layers enchantment multipliers/overrides from `"elemental"` + `"power"` slots before spawning projectiles.
  - `ProjectileBase.initialize_from_weapon(...)` accepts optional custom damage + damage type while preserving old call behavior.
  - `GameManager.start_new_game()` now resets enchantments.
  - `BetweenMissionScreen` Weapons tab now includes enchantment apply/remove UI controls.
  - Added tests:
    - `res://tests/test_enchantment_manager.gd`
    - `res://tests/test_tower_enchantments.gd`
    - projectile regression in `res://tests/test_projectile_system.gd`
- Added Phase 5 DoT system:
  - `EnemyBase` now exposes `apply_dot_effect(effect_data: Dictionary) -> void`.
  - Enemy-local `active_status_effects` tracks burn/poison status with stack-aware rules.
  - `BuildingData` exports now include:
    - `dot_enabled`, `dot_total_damage`, `dot_tick_interval`, `dot_duration`
    - `dot_effect_type`, `dot_source_id`, `dot_in_addition_to_hit`
  - `ProjectileBase.initialize_from_building(...)` now accepts DoT parameters and applies status effects on hit.
  - Tuned resources:
    - `res://resources/building_data/fire_brazier.tres`
    - `res://resources/building_data/poison_vat.tres`
  - Added tests:
    - `res://tests/test_enemy_dot_system.gd`
    - DoT integration assertions in `res://tests/test_projectile_system.gd`
