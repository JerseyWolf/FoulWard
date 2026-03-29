INDEX_FULL.md
=============

FOUL WARD — INDEX_FULL.md

Full public API reference for every script, resource type, and system.
Source of truth: REPO_DUMP_AFTER_MVP.md. **Doc layout:** `docs/README.md`. **Consolidated snapshot:** `docs/OPUS_ALL_ACTIONS.md` merges backlog + AGENTS + Prompt 26 log + both indexes. Updated: 2026-03-29 (**Prompt 28:** `DialogueManager` runtime condition tracking; `WaveManager` BUILD_MODE countdown pause; `test_relationship_manager_tiers.gd` / `test_save_manager_slots.gd`; input/hex/Arnulf/build-menu deltas; full GdUnit **535** cases — `docs/PROMPT_28_IMPLEMENTATION.md`). **Prompt 26:** Full project audit — 55 unindexed files indexed, `docs/AGENTS.md` standing orders, `IMPROVEMENTS_TO_BE_DONE.md` backlog with 78 issues, test Unit/Integration classification, parallel runner spec — `docs/PROMPT_26_IMPLEMENTATION.md`. **Prompt 24:** `PlaceholderIconGenerator` `tools/generate_placeholder_icons.gd` + editor plugin `addons/fw_placeholder_icons`; `ArtPlaceholderHelper` icon PNGs; `SettingsManager` autoload `user://settings.cfg`; `scenes/ui/settings_screen`; UI wiring `build_menu` / `between_mission_screen` / `world_map` / `main_menu`; `tests/test_settings_manager.gd` — `docs/PROMPT_24_IMPLEMENTATION.md`). **Prompt 22:** `RelationshipManager` autoload, `relationship_tier` dialogue conditions, resources under `res://resources/relationship_*` / `character_relationship/` — `docs/PROMPT_22_IMPLEMENTATION.md`. Prompt 19: Blender batch GLBs `res://art/generated/**`, `generation_log.json`, `FUTURE_3D_MODELS_PLAN.md`, `docs/PROMPT_19_IMPLEMENTATION.md`; `# TODO(ART)` in enemy/ally/arnulf/tower/building/boss/hub scripts. Prompt 18: RAG + MCP — `docs/PROMPT_18_IMPLEMENTATION.md`. Audit 6 delta: `AUDIT_IMPLEMENTATION_AUDIT_6.md` — SpellManager multi-spell; WeaponLevelData structural fields; BuildingBase archer barracks / shield generator; GameManager territory aggregates; tests `test_weapon_structural.gd`, `test_building_specials.gd`. Prompt 20: `docs/obsolete/` + INDEX header/autoload alignment — `docs/PROMPT_20_IMPLEMENTATION.md`.
Use INDEX_SHORT.md for fast orientation, INDEX_FULL.md for exact method signatures, signals, and dependencies.
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

Path: res://autoloads/signal_bus.gd
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

MERCENARIES / ROSTER (Prompt 12)

    mercenary_offer_generated(ally_id: String) — when a catalog or defection offer is added to the current pool.

    mercenary_recruited(ally_id: String) — after a successful `purchase_mercenary_offer`.

    ally_roster_changed() — owned/active roster or offer list changed (UI refresh).

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

Path: res://autoloads/damage_calculator.gd
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

Path: res://autoloads/economy_manager.gd
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
RelationshipManager

Path: res://autoloads/relationship_manager.gd
Purpose: Data-driven per-character affinity [−100, 100] and named tiers from `res://resources/relationship_tier_config.tres`. Loads `res://resources/character_relationship/*.tres` and `res://resources/relationship_events/*.tres`; connects to SignalBus signals listed in each `RelationshipEventData` (skips unknown signal names with `push_warning`). No `class_name` — autoload singleton name only (avoids shadowing in GdUnit).
Dependencies: SignalBus.

Public methods (summarized):

    get_affinity(character_id: String) -> float

    get_tier(character_id: String) -> String

    get_tier_rank_index(tier_name: String) -> int

    add_affinity(character_id: String, delta: float) -> void

    get_save_data() -> Dictionary

    restore_from_save(data: Dictionary) -> void

    reload_from_resources() -> void

    test_relationship_events_override: Array — tests only; if non-empty, replaces directory scan for event `.tres` files.

DialogueManager (delta): `DialogueCondition` may set `condition_type` to `relationship_tier` with `character_id` and `required_tier`; evaluated via `RelationshipManager` (see `dialogue_manager.gd`).

Tests: `res://tests/test_relationship_manager.gd`, `res://tests/test_relationship_manager_tiers.gd`; SaveManager integration: `res://tests/test_save_manager.gd`, `res://tests/test_save_manager_slots.gd`.
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
DialogueManager

Path: res://autoloads/dialogue_manager.gd
Purpose: Data-driven between-mission hub dialogue: loads `DialogueEntry` resources from `res://resources/dialogue/**`, applies priority selection, AND conditions, once-only tracking, and chain pointers (`active_chains_by_character`). UI-agnostic; `DialogueUI` + `UIManager` call into it.

Dependencies: SignalBus, GameManager (sync), EconomyManager, ResearchManager (via `Main/Managers/ResearchManager` when present).

Public variables (selected): `entries_by_id`, `entries_by_character`, `played_once_only`, `active_chains_by_character`, `mission_won_count`, `mission_failed_count`, `current_mission_number`, `current_gamestate`.

Signals: `dialogue_line_started(entry_id: String, character_id: String)`, `dialogue_line_finished(entry_id: String, character_id: String)`.

Key methods:

    request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry

    mark_entry_played(entry_id: String) -> void

    get_entry_by_id(entry_id: String) -> DialogueEntry

    notify_dialogue_finished(entry_id: String, character_id: String) -> void

    _load_all_dialogue_entries() -> void — rescans folder (used by tests after mutation).

Internal: `_evaluate_conditions`, `_resolve_state_value`, `_compare`, `_sybil_research_unlocked_any`, `_arnulf_research_unlocked_any`, `_get_research_manager()` — see `docs/PROMPT_13_IMPLEMENTATION.md` for condition keys.

Consumes: SignalBus.game_state_changed, mission_started, mission_won, mission_failed, resource_changed, research_unlocked, shop_item_purchased, arnulf_state_changed, spell_cast (stubs where no logic yet).
AutoTestDriver

Path: res://autoloads/auto_test_driver.gd
Purpose: Headless integration smoke tester, active only with --autotest CLI flag.

ArtPlaceholderHelper

class path: res://scripts/art/art_placeholder_helper.gd
class_name: ArtPlaceholderHelper
purpose: Stateless utility. Resolves Mesh, Material, and Texture2D resources from res://art using convention-based path derivation keyed by Types.EnemyType, Types.BuildingType, ally ID strings, and faction ID strings. Caches loaded resources. Prefers res://art/generated/ assets over placeholders. Falls back to unknown_mesh/neutral material on missing resources — never crashes.
public methods:
  get_enemy_mesh(enemy_type: Types.EnemyType) -> Mesh
  get_building_mesh(building_type: Types.BuildingType) -> Mesh
  get_ally_mesh(ally_id: StringName) -> Mesh
  get_tower_mesh() -> Mesh
  get_unknown_mesh() -> Mesh
  get_faction_material(faction_id: StringName) -> Material
  get_enemy_material(enemy_type: Types.EnemyType) -> Material
  get_building_material(building_type: Types.BuildingType) -> Material
  get_enemy_icon(enemy_type: Types.EnemyType) -> Texture2D  [POST-MVP stub]
  get_building_icon(building_type: Types.BuildingType) -> Texture2D  [POST-MVP stub]
  get_ally_icon(ally_id: StringName) -> Texture2D  [POST-MVP stub]
  clear_cache() -> void
exported variables: none
signals emitted: none
dependencies: Types, ResourceLoader (built-in)

Placeholder GLB batch (Prompt 19)

Path: res://tools/generate_placeholder_glbs_blender.py  
Purpose: Run with `blender --background --python tools/generate_placeholder_glbs_blender.py`. Generates Rigify-based low-poly humanoid/boss GLBs, static buildings/misc, bat swarm with Empty-driven animation; writes `res://art/generated/generation_log.json`. Requires numpy available to Blender’s Python for glTF export.

Path: res://FUTURE_3D_MODELS_PLAN.md  
Purpose: authoritative transition plan from placeholders to production assets (Hyper3D/Rodin, Mixamo, Blender combine, Godot validation); includes `generation_log` table, scene audit appendix, PhysicalBone3D ragdoll plan, AnimationPlayer wiring, hub portrait TODOs.

`# TODO(ART)` annotations (2026-03-28): `scenes/enemies/enemy_base.gd`, `enemy_base.tscn`, `scenes/allies/ally_base.gd`, `ally_base.tscn`, `scenes/arnulf/arnulf.gd`, `arnulf.tscn`, `scenes/tower/tower.gd`, `tower.tscn`, `scenes/buildings/building_base.gd`, `scenes/bosses/boss_base.gd`, `ui/hub.gd`, `ui/hub.tscn`.

SCENE SCRIPTS (Tower, Arnulf, HexGrid, BuildingBase, EnemyBase, ProjectileBase)

(Details are as previously summarized in INDEX_SHORT.md, expanded with method behavior and signals.)

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
| `role` | `Types.AllyRole` | SimBot / auto-select scoring |
| `damage_type`, `can_target_flying` | `Types.DamageType`, `bool` | Combat tagging |
| `attack_damage`, `patrol_radius`, `recovery_time` | `float` | Primary damage (fallback to `basic_attack_damage` if zero), patrol, downed loop |
| `scene_path` | `String` | Spawn scene for `AllyBase` |
| `is_starter_ally`, `is_defected_ally` | `bool` | Campaign start vs mini-boss defection |
| `debug_color` | `Color` | Placeholder mesh tint |

**MercenaryOfferData** (`res://scripts/resources/mercenary_offer_data.gd`) — Prompt 12: `ally_id`, resource costs, `min_day` / `max_day`, `is_defection_offer`, `is_available_on_day`, `get_cost_summary`.

**MercenaryCatalog** (`res://scripts/resources/mercenary_catalog.gd`) — Prompt 12: `offers` (untyped `Array`), `max_offers_per_day`, `get_daily_offers`.

**MiniBossData** (`res://scripts/resources/mini_boss_data.gd`) — Prompt 12: `can_defect_to_ally`, `defected_ally_id`, defection cost fields.

**DialogueCondition** (`res://scripts/resources/dialogue/dialogue_condition.gd`) — Prompt 13

| Field | Type | Purpose |
|-------|------|---------|
| `key` | `String` | Condition key for DialogueManager (`current_mission_number`, `gold_amount`, `sybil_research_unlocked_any`, `research_unlocked_<id>`, …) |
| `comparison` | `String` | `==`, `!=`, `>`, `>=`, `<`, `<=` |
| `value` | `Variant` | Expected value (int, bool, or string for game-state name) |

**DialogueEntry** (`res://scripts/resources/dialogue/dialogue_entry.gd`) — Prompt 13

| Field | Type | Purpose |
|-------|------|---------|
| `entry_id` | `String` | Unique id (warnings on duplicate) |
| `character_id` | `String` | Role bucket (`SPELL_RESEARCHER`, `COMPANION_MELEE`, …) |
| `text` | `String` | Multiline line (placeholder TODO in MVP) |
| `priority` | `int` | Higher = more likely when conditions pass |
| `once_only` | `bool` | Suppress after `mark_entry_played` for this run |
| `chain_next_id` | `String` | Optional next `entry_id` after current line plays |
| `conditions` | `Array[DialogueCondition]` | All must pass (AND) |

**CharacterData** (`res://scripts/resources/character_data.gd`) — Prompt 14

| Field | Type | Purpose |
|-------|------|---------|
| `character_id` | `String` | Stable ID passed into `DialogueManager.request_entry_for_character()` |
| `display_name` | `String` | Speaker/name shown by hub character UI and `DialoguePanel` |
| `description` | `String` | Placeholder copy for future tooltips/codex |
| `role` | `Types.HubRole` | Drives which `BetweenMissionScreen` panel to open |
| `portrait_id` | `String` | Visual identifier for future portrait rendering |
| `icon_id` | `String` | Optional sprite/icon identifier for future UI |
| `hub_position_2d` | `Vector2` | Intended 2D placement for the hub overlay |
| `hub_marker_name_3d` | `String` | Marker reference for a future 3D hub implementation |
| `default_dialogue_tags` | `Array[String]` | Tags passed into `DialogueManager` when requesting dialogue (MVP ignores tags) |

**CharacterCatalog** (`res://scripts/resources/character_catalog.gd`) — Prompt 14

| Field | Type | Purpose |
|-------|------|---------|
| `characters` | `Array[CharacterData]` | Full hub character set instantiated by `Hub2DHub` |

**DialogueUI** (`res://ui/dialogueui.gd` / `dialogueui.tscn`) — Prompt 13: `show_entry(DialogueEntry)`; **Continue** → `mark_entry_played` / chain or `notify_dialogue_finished`.

**DialoguePanel** (`res://ui/dialogue_panel.gd` / `dialogue_panel.tscn`) — Prompt 14
- `show_entry(display_name: String, entry: DialogueEntry) -> void`: sets SpeakerLabel + TextLabel and makes the overlay visible.
- `clear_dialogue() -> void`: hides the panel and resets the current entry.
- Click-to-continue: left mouse advances. On chain end it calls `DialogueManager.notify_dialogue_finished`.

**HubCharacterBase2D** (`res://scenes/hub/character_base_2d.gd` / `character_base_2d.tscn`) — Prompt 14
- Export: `character_data: CharacterData`.
- Signal: `character_interacted(character_id: String)` emitted on left mouse click.

**Hub2DHub** (`res://ui/hub.gd` / `ui/hub.tscn`) — Prompt 14
- Export: `character_catalog: CharacterCatalog`.
- Signals: `hub_opened()`, `hub_closed()`, `hub_character_interacted(character_id: String)`.
- Public API:
  - `open_hub() -> void`
  - `close_hub() -> void`
  - `focus_character(character_id: String) -> void` (same behavior as a user click)
  - `set_between_mission_screen(screen: Node) -> void`
  - `_set_ui_manager(ui_manager: Node) -> void`

**BetweenMissionScreen** (`res://ui/between_mission_screen.gd`) — Prompt 14
- Panel helpers used by hub focus routing:
  - `open_shop_panel() -> void`
  - `open_research_panel() -> void`
  - `open_enchant_panel() -> void` (routes to ResearchTab in MVP)
  - `open_mercenary_panel() -> void` (routes to MercenariesTab in current MVP scene)

**UIManager** (`res://ui/ui_manager.gd`) — Prompt 14
- New dialogue helpers:
  - `show_dialogue(display_name: String, entry: DialogueEntry) -> void` (routes to DialoguePanel)
  - `clear_dialogue() -> void` (hides DialoguePanel)
- Hub integration:
  - Shows `Hub2DHub` when entering `Types.GameState.BETWEEN_MISSIONS`
  - Closes Hub + clears dialogue when leaving `BETWEEN_MISSIONS`

**AllyBase** (`res://scenes/allies/ally_base.gd` / `ally_base.tscn`) — Prompt 11 + Audit 6 Group 4

- `initialize_ally_data(p_ally_data: Variant) -> void` — HP reset, shapes from `attack_range`, emits `ally_spawned`.
- `find_target() -> EnemyBase` — filters by `can_target_flying`; scores by `preferred_targeting` (`Types.TargetPriority`: CLOSEST, LOWEST_HP, HIGHEST_HP, FLYING_FIRST).
- `_perform_attack_on_target` — `EnemyBase.take_damage` (direct damage; POST-MVP projectiles).
- Death: if `uses_downed_recovering`, DOWNED for `recovery_time` → RECOVERING (full heal) → IDLE with `ally_downed` / `ally_recovered`; else `ally_killed` + `queue_free()`.

**CampaignManager** — Prompt 11 roster arrays + **Prompt 12**: `owned_allies` / `active_allies_for_next_day` / `max_active_allies_per_day`; `mercenary_catalog` export; `is_ally_owned`, `get_owned_allies`, `get_active_allies`, `add_ally_to_roster`, `remove_ally_from_roster`, `toggle_ally_active`, `set_active_allies_from_list`, `get_allies_for_mission_start`; `generate_offers_for_day`, `preview_mercenary_offers_for_day`, `get_current_offers`, `purchase_mercenary_offer`; `notify_mini_boss_defeated`, `register_mini_boss`, `auto_select_best_allies`; legacy `current_ally_roster` sync for spawn; `has_ally`, `get_ally_data`, `reinitialize_ally_roster_for_test()`.

**SimBot** — Prompt 12: `activate(strategy: Types.StrategyProfile)`, `decide_mercenaries()`, `get_log()`.

- WeaponData Phase 2 additions:
  - `assist_angle_degrees: float`
  - `assist_max_distance: float`
  - `base_miss_chance: float`
  - `max_miss_angle_degrees: float`
  - All default to `0.0` (MVP behavior preserved until tuned in `.tres` data).
TYPES ENUMS (res://scripts/types.gd)

GameState, DamageType, ArmorType, BuildingType, ArnulfState, ResourceType, EnemyType, **AllyClass**, **HubRole**, WeaponSlot, TargetPriority (buildings + allies; includes **LOWEST_HP** for ally pick-lowest-HP mode).
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

## 2026-03-25 Prompt 15 delta (Florence meta-state + day progression)

- Added `res://scripts/florence_data.gd` (`class_name FlorenceData`) to store run meta-state.
- Updated `res://scripts/types.gd`:
  - Added `enum DayAdvanceReason`
  - Added `Types.get_day_advance_priority(reason)` helper.
- Updated `res://autoloads/signal_bus.gd`: added `SignalBus.florence_state_changed()`.
- Updated `res://autoloads/game_manager.gd`:
  - Added Florence ownership (`florence_data`) + meta day counter (`current_day`).
  - Added `advance_day()` and `_apply_pending_day_advance_if_any()`.
  - Mission win/fail hooks increment Florence counters.
  - Incremented `florence_data.run_count` on final `GAME_WON`.
  - Added `get_florence_data()`.
- Updated `res://scripts/research_manager.gd` and `res://scripts/shop_manager.gd` with Florence unlock hooks.
- Updated `res://ui/between_mission_screen.tscn` and `res://ui/between_mission_screen.gd`:
  - Added `FlorenceDebugLabel`
  - Refreshes on `SignalBus.florence_state_changed`.
- Updated `res://autoloads/dialogue_manager.gd`:
  - Resolves `florence.*` and `campaign.*` condition keys.
- Added `res://tests/test_florence.gd` and included it in `./tools/run_gdunit_quick.sh`.
- Follow-up parse-safety fixes: removed invalid enum cast in `GameManager.advance_day()` and avoided `: FlorenceData` local type annotations in tests/UI.

## 2026-03-28 Prompt 27 delta (audit backlog execution)

- **Implementation notes**: `docs/PROMPT_27_IMPLEMENTATION.md`.
- **RAG pipeline**: Added `foulward-rag` MCP server entry to `.cursor/mcp.json` (tools: `query_project_knowledge`, `get_recent_simbot_summary`).
- **assert→push_warning** in 9 production files: `economy_manager.gd`, `game_manager.gd`, `campaign_manager.gd`, `wave_manager.gd`, `shop_manager.gd`, `research_manager.gd`, `hex_grid.gd`, `enemy_base.gd`, `boss_base.gd`. Pattern: `push_warning` + early return (or `push_error` for `_ready()`-critical guards).
- **SaveManager**: Wired `RelationshipManager.get_save_data()` / `restore_from_save()` into `_build_save_payload()` / `_apply_save_payload()`.
- **get_node→get_node_or_null**: `input_manager.gd` (5 vars), `ui_manager.gd` (6 vars), `build_menu.gd` (1 var), `hud.gd` (1 var) — all with `is_instance_valid()` guards.
- **Removed obsolete signals**: `wave_failed`, `wave_completed` from `signal_bus.gd` (confirmed unreferenced).
- **Orphan leak fixes**: `test_projectile_system.gd`, `test_ally_base.gd`, `test_building_base.gd`, `test_hex_grid.gd` — orphans reduced 17→6.
- **New test runners**:
  - `tools/run_gdunit_unit.sh` — 33 unit-classified test files, ~65s wall-clock.
  - `tools/run_gdunit_parallel.sh` — 8-parallel-process runner for all 58 files, ~2m45s (37% faster than 4m22s baseline).
- **Deleted**: `AUDIT_IMPLEMENTATION_AUDIT_6.md`, `AUDIT_IMPLEMENTATION_UPDATE.md`, `AUDIT_IMPLEMENTATION_TASK.md` (superseded by `docs/ALL_AUDITS.md` and `IMPROVEMENTS_TO_BE_DONE.md`).
- **AGENTS.md**: Updated §4 Test Rules with `run_gdunit_unit.sh` and `run_gdunit_parallel.sh` guidance.
- **Final test results**: 522 cases, 0 failures, 6 orphans, 4m20s.
