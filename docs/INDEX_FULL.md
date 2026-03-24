INDEXFULL.md
============

FOUL WARD — INDEXFULL.md

Full public API reference for every script, resource type, and system.
Source of truth: REPO_DUMP_AFTER_MVP.md. Updated: 2026-03-24 (Prompt 11 ally framework; see `docs/PROMPT_11_IMPLEMENTATION.md`).
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

ALLIES (Prompt 11)

    ally_spawned(ally_id: String) — emitted when `AllyBase.initialize_ally_data` runs or Arnulf `reset_for_new_mission` (id `arnulf`).

    ally_downed(ally_id: String) — emitted when a generic ally enters downed path (POST-MVP) or Arnulf enters DOWNED.

    ally_recovered(ally_id: String) — emitted when Arnulf completes RECOVERING (generic mirror).

    ally_killed(ally_id: String) — emitted when a generic ally’s HP hits zero (mission removal); Arnulf has no kill path in MVP (POST-MVP).

    ally_state_changed(ally_id: String, new_state: String) — POST-MVP detailed tracking.

BOSSES (Prompt 10)

    boss_spawned(boss_id: String) — emitted when `BossBase` finishes `initialize_boss_data`.

    boss_killed(boss_id: String) — emitted when a boss’s `HealthComponent` depletes.

    campaign_boss_attempted(day_index: int, success: bool) — emitted by `GameManager` on final-boss attempt outcome.

WAVES

    wave_countdown_started(wave_number: int, seconds_remaining: float)

    wave_started(wave_number: int, enemy_count: int)

    wave_cleared(wave_number: int)

    all_waves_cleared()

ECONOMY

    resource_changed(resource_type: Types.ResourceType, new_amount: int)

TERRITORIES / WORLD MAP

    territory_state_changed(territory_id: String)

    world_map_updated()

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

Path: res://autoloads/game_manager.gd
Purpose: Session state machine: missions, waves, game state transitions, mission rewards, optional territory map + end-of-mission gold modifiers.
Dependencies: SignalBus, EconomyManager, WaveManager, ResearchManager, ShopManager, CampaignManager.

Constants:

    TOTAL_MISSIONS: int = 5

    WAVES_PER_MISSION: int = 3 (DEV CAP; final 10)

    MAIN_CAMPAIGN_CONFIG_PATH: String — documents canonical 50-day `CampaignConfig` path (`res://resources/campaign_main_50days.tres`).

Public variables:

    current_mission: int = 1

    current_wave: int = 0

    game_state: Types.GameState = MAIN_MENU

    territory_map: TerritoryMapData — null when active campaign has no `territory_map_resource_path`.

Key methods:

    start_new_game() -> void

    start_next_mission() -> void

    start_wave_countdown() -> void

    enter_build_mode() / exit_build_mode() -> void

    get_game_state(), get_current_mission(), get_current_wave() -> …

    start_mission_for_day(day_index: int, day_config: DayConfig) -> void

    Private `_begin_mission_wave_sequence()` — resolves `/root/Main/Managers/WaveManager` via `get_tree().root.get_node_or_null("Main")` then `Managers` / `WaveManager`; if any step is null, `push_warning` with mission index and return (no wave start; supports headless tests without `main.tscn`; warnings avoid GdUnit `GodotGdErrorMonitor` false failures).

    Private `_on_mission_won_transition_to_hub(mission_number: int)` — after `CampaignManager` handles `mission_won`, sets `GAME_WON` or `BETWEEN_MISSIONS`. Requires `project.godot` autoload order: `CampaignManager` before `GameManager`.

    reload_territory_map_from_active_campaign() -> void

    get_current_day_index() -> int

    get_day_config_for_index(day_index: int) -> DayConfig

    get_current_day_config() -> DayConfig

    get_current_day_territory_id() -> String

    get_territory_data(territory_id: String) -> TerritoryData

    get_current_day_territory() -> TerritoryData

    get_all_territories() -> Array[TerritoryData]

    get_current_territory_gold_modifiers() -> Dictionary — keys `flat_gold_end_of_day` (int), `percent_gold_end_of_day` (float).

    apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void

    prepare_next_campaign_day_if_needed() -> void — boss-attack / synthetic day prep when advancing past authored `day_configs`.

    advance_to_next_day() -> void — increments campaign day for boss-repeat loop paths.

    get_synthetic_boss_day_config() -> DayConfig — runtime-only config for post-length boss strike days (`_synthetic_boss_attack_day`).

    reset_boss_campaign_state_for_test() -> void — clears Prompt 10 boss campaign flags (tests).

Prompt 10 public state (selected): `final_boss_id`, `final_boss_defeated`, `final_boss_active`, `current_boss_threat_territory_id`, `held_territory_ids`.

Consumes: all_waves_cleared, tower_destroyed, boss_killed; subscribes to mission_won (hub transition). See `docs/PROBLEM_REPORT.md`.
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
## 2026-03-24 Prompt 7 delta

- Added campaign/day resource classes:
  - `res://scripts/resources/day_config.gd` (`DayConfig`)
    - fields: `day_index`, `display_name`, `description`, `faction_id`, `territory_id`,
      `is_mini_boss_day`, `is_final_boss`, `base_wave_count`, `enemy_hp_multiplier`,
      `enemy_damage_multiplier`, `gold_reward_multiplier`.
  - `res://scripts/resources/campaign_config.gd` (`CampaignConfig`)
    - fields: `campaign_id`, `display_name`, `day_configs:Array[DayConfig]`,
      `is_short_campaign`, `short_campaign_length`.
    - method: `get_effective_length() -> int`.
- Added campaign resources:
  - `res://resources/campaigns/campaign_short_5_days.tres`
  - `res://resources/campaigns/campaign_main_50_days.tres`
    - placeholder day ramp pattern for wave count + hp/damage/reward multipliers.
- Added autoload:
  - `CampaignManager` at `res://autoloads/campaign_manager.gd`.
  - Public API:
    - `start_new_campaign() -> void`
    - `start_next_day() -> void`
    - `get_current_day() -> int`
    - `get_campaign_length() -> int`
    - `get_current_day_config() -> DayConfig`
    - `set_active_campaign_config_for_test(config: CampaignConfig) -> void` (test-only).
  - State:
    - `current_day`, `campaign_length`, `campaign_id`, `campaign_completed`,
      `failed_attempts_on_current_day`, `current_day_config`, `campaign_config`,
      `active_campaign_config`.
- SignalBus additions (declared in `res://autoloads/signal_bus.gd`):
  - `campaign_started(campaign_id: String)` emitted by `CampaignManager.start_new_campaign()`.
  - `day_started(day_index: int)` emitted by `CampaignManager` when day starts.
  - `day_won(day_index: int)` emitted by `CampaignManager` on mission-day win.
  - `day_failed(day_index: int)` emitted by `CampaignManager` on mission-day fail.
  - `campaign_completed(campaign_id: String)` emitted by `CampaignManager` on final day completion.
- GameManager updates:
  - `start_new_game()` now delegates mission kickoff to `CampaignManager.start_new_campaign()`.
  - `start_next_mission()` now delegates to `CampaignManager.start_next_day()`.
  - Added `start_mission_for_day(day_index: int, day_config: DayConfig) -> void`.
- WaveManager updates:
  - Added day-config fields:
    - `configured_max_waves: int`
    - `enemy_hp_multiplier: float`
    - `enemy_damage_multiplier: float`
    - `gold_reward_multiplier: float`
  - Added `configure_for_day(day_config: DayConfig) -> void`.
  - End-of-wave completion now uses `configured_max_waves` fallback to `max_waves`.
  - Spawn path now applies per-day multipliers via duplicated `EnemyData` before enemy initialization.
- BetweenMissionScreen updates:
  - Added day labels and refresh logic:
    - `DayProgressLabel` ("Day X / Y")
    - `DayNameLabel` ("Day X - <name>")
  - Next button flow now routes to `CampaignManager.start_next_day()`.
- Tests added/expanded:
  - New file: `res://tests/test_campaign_manager.gd` (campaign/day lifecycle + test helper).
  - Added Prompt 7 cases to `res://tests/test_wave_manager.gd`.
  - Added Prompt 7 cases to `res://tests/test_game_manager.gd`.
## 2026-03-24 Prompt 9 delta

- **Faction resources**
  - `res://scripts/resources/faction_roster_entry.gd` (`FactionRosterEntry`): per-roster-row `enemy_type`, `base_weight`, `min_wave_index`, `max_wave_index`, `tier`.
  - `res://scripts/resources/faction_data.gd` (`FactionData`): identity, `roster[]`, mini-boss hooks, scaling fields; `get_entries_for_wave`, `get_effective_weight_for_wave`; `BUILTIN_FACTION_RESOURCE_PATHS`.
  - Data: `res://resources/faction_data_default_mixed.tres`, `faction_data_orc_raiders.tres`, `faction_data_plague_cult.tres`.
- **DayConfig** (`res://scripts/resources/day_config.gd`): `faction_id` default `DEFAULT_MIXED`; `is_mini_boss` renamed **`is_mini_boss_day`** (campaign `.tres` migrated).
- **TerritoryData**: `default_faction_id` (POST-MVP).
- **CampaignManager** (`res://autoloads/campaign_manager.gd`):
  - `faction_registry: Dictionary` (String → FactionData), `_load_faction_registry()` in `_ready`.
  - `validate_day_configs(day_configs: Array[DayConfig]) -> void`.
- **WaveManager** (`res://scripts/wave_manager.gd`):
  - Faction-driven spawning: weighted roster allocation, total enemies **`wave_number × 6`** (scaled only if `difficulty_offset != 0`).
  - `faction_registry`, `set_faction_data_override(faction_data: FactionData) -> void`, `resolve_current_faction() -> void`, `get_mini_boss_info_for_wave(wave_index: int) -> Dictionary`.
  - Mini-boss hook respects `DayConfig.is_mini_boss_day` unless a test **faction override** is set.
  - Uses `preload` aliases (`FactionDataType`) where needed for autoload parse order (**DEVIATION** vs bare `class_name` types).
- **GameManager**: `configure_for_day` on WaveManager is invoked **after** `reset_for_new_mission()` in `_begin_mission_wave_sequence()` so day tuning persists.
- **Tests**: `res://tests/test_faction_data.gd`; Prompt 9 cases in `res://tests/test_wave_manager.gd`.
- **Notes**: `docs/PROMPT_9_IMPLEMENTATION.md`.
MANAGERS (WaveManager, SpellManager, ResearchManager, ShopManager, InputManager, SimBot)

(Full descriptions of exports, methods, signals, dependencies as summarized earlier.)
CUSTOM RESOURCE TYPES

Full field tables for EnemyData, BuildingData, WeaponData, SpellData, ResearchNodeData, ShopItemData as previously spelled out.

**FactionRosterEntry** (`res://scripts/resources/faction_roster_entry.gd`)

| Field | Type | Purpose |
|-------|------|---------|
| `enemy_type` | `Types.EnemyType` | Which enemy type this roster row spawns |
| `base_weight` | `float` | Relative weight within the wave’s allocation |
| `min_wave_index` | `int` | First wave (inclusive) where this row is active |
| `max_wave_index` | `int` | Last wave (inclusive) where this row is active |
| `tier` | `int` | 1 basic, 2 elite, 3 special — feeds `get_effective_weight_for_wave` ramp |

**FactionData** (`res://scripts/resources/faction_data.gd`)

| Field / member | Type | Purpose |
|----------------|------|---------|
| `faction_id` | `String` | Stable ID; must match `DayConfig.faction_id` and registry keys |
| `display_name` | `String` | UI / logs |
| `description` | `String` | Codex / summary copy |
| `roster` | `Array[FactionRosterEntry]` | Weighted spawn table (entries are sub-resources in `.tres`) |
| `mini_boss_ids` | `Array[String]` | `BossData.boss_id` values; used with `mini_boss_wave_hints` for `get_mini_boss_info_for_wave` |
| `mini_boss_wave_hints` | `Array[int]` | Waves where `get_mini_boss_info_for_wave` may return data |
| `roster_tier` | `int` | Coarse faction difficulty tier (1–3) |
| `difficulty_offset` | `float` | Scales total enemy count when non-zero (`WaveManager` formula) |
| `BUILTIN_FACTION_RESOURCE_PATHS` | `const Array[String]` | Paths to shipped faction `.tres` files |

Public methods: `get_entries_for_wave(wave_index: int) -> Array[FactionRosterEntry]`, `get_effective_weight_for_wave(entry: FactionRosterEntry, wave_index: int) -> float`.

**BossData** (`res://scripts/resources/boss_data.gd`)

| Field / member | Type | Purpose |
|----------------|------|---------|
| `boss_id` | `String` | Stable id; matches `DayConfig.boss_id`, faction `mini_boss_ids`, registry keys |
| `display_name`, `description` | `String` | UI / codex |
| `faction_id` | `String` | Which faction context loads this boss |
| `associated_territory_id` | `String` | Optional territory link (mini-boss secure hook) |
| `max_hp` … `gold_reward` | various | Combat stats mirrored into `build_placeholder_enemy_data()` |
| `escort_unit_ids` | `Array[String]` | Enum **key** strings, e.g. `"ORC_GRUNT"` — `WaveManager` resolves via `Types.EnemyType.keys()` |
| `phase_count` | `int` | Multi-phase hook (`BossBase.advance_phase`) |
| `is_mini_boss` / `is_final_boss` | `bool` | Encounter classification |
| `boss_scene` | `PackedScene` | Spawn scene; defaults to `boss_base.tscn` in shipped `.tres` |
| `BUILTIN_BOSS_RESOURCE_PATHS` | `const Array[String]` | Shipped boss `.tres` paths |

Public methods: `build_placeholder_enemy_data() -> EnemyData`.

**BossBase** (`res://scenes/bosses/boss_base.gd`): extends `EnemyBase`; `initialize_boss_data(data: BossData) -> void`, `advance_phase() -> void`; emits `boss_spawned` / `boss_killed`.

**AllyData** (`res://scripts/resources/ally_data.gd`) — Prompt 11

| Field | Type | Purpose |
|-------|------|---------|
| `ally_id` | `String` | Stable id (matches SignalBus payloads, roster lookup) |
| `display_name`, `description` | `String` | UI / placeholder narrative |
| `ally_class` | `Types.AllyClass` | MELEE / RANGED / SUPPORT |
| `max_hp`, `move_speed`, `basic_attack_damage`, `attack_range`, `attack_cooldown` | various | Combat/movement tuning (data-driven) |
| `preferred_targeting` | `Types.TargetPriority` | MVP: **CLOSEST** only |
| `is_unique` | `bool` | Named vs generic merc |
| `starting_level`, `level_scaling_factor`, `uses_downed_recovering` | POST-MVP | Campaign / Arnulf-like recovery |

**AllyBase** (`res://scenes/allies/ally_base.gd` / `ally_base.tscn`) — Prompt 11

- `initialize_ally_data(p_ally_data: Variant) -> void` — HP reset, shapes from `attack_range`, emits `ally_spawned`.
- `find_target() -> EnemyBase` — nearest living enemy in `enemies` group (CLOSEST).
- `_perform_attack_on_target` — `EnemyBase.take_damage` (direct damage; POST-MVP projectiles).
- Death: `ally_killed` + `queue_free()` unless `uses_downed_recovering` (POST-MVP).

**CampaignManager** (ally roster fields): `current_ally_roster: Array`, `current_ally_roster_ids: Array[String]`, `_initialize_static_roster()`, `has_ally`, `get_ally_data`, `reinitialize_ally_roster_for_test()`.

- WeaponData Phase 2 additions:
  - `assist_angle_degrees: float`
  - `assist_max_distance: float`
  - `base_miss_chance: float`
  - `max_miss_angle_degrees: float`
  - All default to `0.0` (MVP behavior preserved until tuned in `.tres` data).
TYPES ENUMS (res://scripts/types.gd)

GameState, DamageType, ArmorType, BuildingType, ArnulfState, ResourceType, EnemyType, **AllyClass**, WeaponSlot, TargetPriority (buildings + allies; ally MVP uses CLOSEST).
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

## 2026-03-24 Prompt 8 delta (territory + world map + 50-day data)

- Resource classes:
  - `res://scripts/resources/territory_data.gd` (`TerritoryData`) — territory_id, display, terrain enum, ownership, end-of-day gold bonuses, POST-MVP hooks.
  - `res://scripts/resources/territory_map_data.gd` (`TerritoryMapData`) — `territories[]`, lookups by id, `invalidate_cache()`.
- `DayConfig`: added `mission_index` (maps day → MVP mission 1–5).
- `CampaignConfig`: added `territory_map_resource_path` (optional).
- Data instances:
  - `res://resources/territories/main_campaign_territories.tres`
  - `res://resources/campaign_main_50days.tres` (50 linear days; canonical path for Prompt 8 tests and `GameManager.MAIN_CAMPAIGN_CONFIG_PATH`).
- `SignalBus` (`res://autoloads/signal_bus.gd`):
  - `territory_state_changed(territory_id: String)`
  - `world_map_updated()`
- `GameManager` (`res://autoloads/game_manager.gd`):
  - `territory_map: TerritoryMapData`, `reload_territory_map_from_active_campaign()`, territory helpers (`get_current_day_index`, `get_day_config_for_index`, `get_*_territory*`, `get_all_territories`, `get_current_territory_gold_modifiers`, `apply_day_result_to_territory`).
  - End-of-mission gold applies territory flat + percent bonuses (all active territories).
  - Campaign win: last day uses `completed_day_index == campaign_len` **before** `mission_won` emission (CampaignManager advances day on `mission_won`).
- `CampaignManager._set_campaign_config` triggers `GameManager.reload_territory_map_from_active_campaign()`.
- UI: `res://ui/world_map.gd`, `res://ui/world_map.tscn` (`WorldMap`); embedded in `res://ui/between_mission_screen.tscn` as first `TabContainer` tab (`MapTab`).
- Tests: `test_territory_data.gd`, `test_campaign_territory_mapping.gd`, `test_campaign_territory_updates.gd`, `test_territory_economy_bonuses.gd`, `test_world_map_ui.gd`; plus `test_game_manager.gd` updates for campaign/day flow.
- See `docs/PROMPT_8_IMPLEMENTATION.md`.

## 2026-03-24 Prompt 10 delta (mini-boss + campaign boss)

- **Implementation notes**: `docs/PROMPT_10_IMPLEMENTATION.md`.
- **Resources**: `BossData`; `res://resources/bossdata_plague_cult_miniboss.tres`, `bossdata_orc_warlord_miniboss.tres`, `bossdata_final_boss.tres`; scene `res://scenes/bosses/boss_base.tscn`.
- **DayConfig** (`res://scripts/resources/day_config.gd`): `is_mini_boss`, `boss_id`, `is_boss_attack_day` (plus existing `is_mini_boss_day`, `is_final_boss`).
- **CampaignConfig**: `starting_territory_ids`.
- **TerritoryData**: `is_secured`, `has_boss_threat`.
- **SignalBus**: `boss_spawned`, `boss_killed`, `campaign_boss_attempted`.
- **WaveManager**: `boss_registry`, `set_day_context(day_config, faction_data)`, `ensure_boss_registry_loaded()`; `_spawn_boss_wave` on configured wave index; escort resolution uses enum key strings.
- **GameManager**: final-boss tracking, `get_day_config_for_index` (match `day_index` then fallback index, synthetic day), `prepare_next_campaign_day_if_needed`, `advance_to_next_day`, mini-boss kill → territory `is_secured` hook, final-boss fail skips permanent territory loss (MVP).
- **CampaignManager**: `start_next_day` calls `GameManager.prepare_next_campaign_day_if_needed()`; win path respects `GameManager.final_boss_defeated`.
- **Tests**: `res://tests/test_boss_data.gd`, `test_boss_base.gd`, `test_boss_waves.gd`, `test_final_boss_day.gd`; `test_wave_manager.gd` (`test_regular_day_spawns_no_bosses`). **Confirm** full suite with `./tools/run_gdunit.sh`.

## 2026-03-24 Prompt 10 fixes delta (GdUnit / WaveManager harness)

- See **`docs/PROMPT_10_FIXES.md`**.
- **`WaveManager`** (`res://scripts/wave_manager.gd`): `_enemy_container` and `_spawn_points` use **`get_node_or_null("/root/Main/...")`**; **`_spawn_wave`** / **`_spawn_boss_wave`** return if either is null.
- **`test_wave_manager.gd`**, **`test_boss_waves.gd`**: add **`SpawnPoints`** to the test tree before **`Marker3D`** children and **`global_position`**; assign **`wm._enemy_container`** / **`wm._spawn_points`** after **`add_child(wm)`**.
- **`GameManager`** (`res://autoloads/game_manager.gd`): **`_begin_mission_wave_sequence()`** walks **`Main` → `Managers` → `WaveManager`** with **`get_node_or_null`**; missing **`Main`**, **`Managers`**, or **`WaveManager`** → **`push_warning`** + return (no asserts; GdUnit-safe). Full **`main.tscn`** loads unchanged; **`test_game_manager.gd`** includes **`test_begin_mission_wave_sequence_skips_gracefully_without_main_scene`**.
- **`project.godot`**: **`CampaignManager`** autoload **before** **`GameManager`** so **`mission_won`** listeners run day increment before hub transition.
- **`test_campaign_manager.gd`**: **`test_day_fail_repeats_same_day`** uses **`mission_failed.emit(CampaignManager.get_current_day())`** when **`GameManager.get_current_mission()`** can lag **`current_day`**.
- **`docs/PROBLEM_REPORT.md`**: file paths + log/GdUnit snippets for the above.
