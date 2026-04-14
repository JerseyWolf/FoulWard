# FOUL WARD — MASTER DOCUMENTATION

> **Living document.** Updated every time a system is added, changed, or formally cut.
> Readable by both **human developers** and **LLM agents** (Cursor, Perplexity, or otherwise).
> Every section distinguishes between **EXISTS IN CODE** and **PLANNED / NOT YET IMPLEMENTED**.
> **Target reader:** An LLM agent given only this document, a task, and access to the codebase.

---

## Changelog

| Date | Author | Summary |
|------|--------|---------|
| 2026-04-14 | Cursor agent | §2.4 C# Integration; §3.3 DamageCalculator (C#); §30.15 C# `class_name` vs autoloads; §34 `FoulWard.csproj` + `CREDITS.md`. |
| 2026-03-31 | Cursor agent | §1.1 Cursor/MCP toolchain (minimal consolidation); §23 headless automation vs GdUnit clarified. |
| 2026-03-31 | Opus (Prompt 53) | Full expansion: complete public APIs with GDScript signatures for every autoload/manager, three lifecycle flow sections, four "how to add X" templates, full enum-to-integer mapping table, expanded anti-patterns section. |
| 2026-03-31 | Opus (Prompt 52) | Initial creation from MASTER STATE BRIEFING, SUMMARY_VERIFICATION, INDEX_SHORT, INDEX_FULL, and CONVENTIONS sources. Verified against Prompt 51 codebase snapshot (525 passing tests). |

---

## Table of Contents

- [1. Project Identity](#1-project-identity) — [1.1 Cursor, MCP, and agent toolchain](#11-cursor-mcp-and-agent-toolchain)
- [2. Core Architecture](#2-core-architecture) — [2.4 C# Integration](#24-c-integration)
- [3. Autoloads — Init Order and Complete Public APIs](#3-autoloads--init-order-and-complete-public-apis)
- [4. Scene-Bound Managers — Complete Public APIs](#4-scene-bound-managers--complete-public-apis)
- [5. Types.gd — Full Enum-to-Integer Mapping](#5-typesgd--full-enum-to-integer-mapping)
- [6. Game States](#6-game-states)
- [7. Spells](#7-spells)
- [8. Buildings](#8-buildings)
- [9. Research](#9-research)
- [10. Enchantments](#10-enchantments)
- [11. Allies and Mercenaries](#11-allies-and-mercenaries)
- [12. Enemies and Bosses](#12-enemies-and-bosses)
- [13. Campaign and Progression](#13-campaign-and-progression)
- [14. Meta-Progression: The Chronicle of Foul Ward](#14-meta-progression-the-chronicle-of-foul-ward)
- [15. Hub Screens](#15-hub-screens)
- [16. World Map](#16-world-map)
- [17. Dialogue System](#17-dialogue-system)
- [18. Economy](#18-economy)
- [19. Shop](#19-shop)
- [20. Wave System](#20-wave-system)
- [21. Terrain](#21-terrain)
- [22. Art Pipeline](#22-art-pipeline)
- [23. SimBot and Testing](#23-simbot-and-testing)
- [24. Signal Bus Reference](#24-signal-bus-reference)
- [25. Scene Tree Overview](#25-scene-tree-overview)
- [26. Physics Layers and Input Actions](#26-physics-layers-and-input-actions)
- [27. Lifecycle Flows](#27-lifecycle-flows)
- [28. How To Add X — Templates](#28-how-to-add-x--templates)
- [29. Conventions and Rules for LLM Agents](#29-conventions-and-rules-for-llm-agents)
- [30. Anti-Patterns — Code-Level Mistakes to Avoid](#30-anti-patterns--code-level-mistakes-to-avoid)
- [31. Formally Cut Features — Never Implement](#31-formally-cut-features--never-implement)
- [32. Field Name Discipline — Correct vs Wrong Names](#32-field-name-discipline--correct-vs-wrong-names)
- [33. Open TBD Items](#33-open-tbd-items)
- [34. Related Documents](#34-related-documents)

---

## 1. Project Identity

| Property | Value |
|----------|-------|
| **Game title** | Foul Ward |
| **Engine** | Godot 4.4 (GDScript) |
| **Genre** | Real-time tower defense, stationary perspective (player IS the tower, aims manually with mouse) |
| **Inspiration** | TAUR |
| **Campaign structure** | 50-day main campaign. Each day = one mission. Missions have a build phase then wave combat. |
| **Test count** | 525 passing GdUnit4 tests (as of Prompt 51) |

### Primary Files of Record

| File | Purpose |
|------|---------|
| `docs/INDEX_SHORT.md` | Compact one-liner-per-file index |
| `docs/INDEX_FULL.md` | Full public API reference for every script, resource, and system |
| `AGENTS.md` (repo root) | Standing orders for every Cursor/LLM session — **read first** (MCP habits; expands on [§1.1](#11-cursor-mcp-and-agent-toolchain)) |
| `docs/CONVENTIONS.md` | Naming, typing, and style law |
| `docs/SUMMARY_VERIFICATION.md` | Three-part read-only audit results |
| `docs/archived/OPUS_ALL_ACTIONS.md` | Archived consolidated snapshot + improvement backlog (historical) |

### 1.1 Cursor, MCP, and agent toolchain

**STATUS: EXISTS IN REPO (configuration + docs)**

Cursor loads MCP servers from **`.cursor/mcp.json`**. There is no separate “auto session” product mode documented in this repo: any Cursor chat or agent run can use whatever MCP tools Cursor exposes, subject to the servers below being up and reachable.

| Server (name in `mcp.json`) | Role (one line) |
|----------------------------|------------------|
| `godot-mcp-pro` | Editor integration over WebSocket (default port **6505**); needs Godot open with the **Godot MCP Pro** plugin enabled. |
| `gdai-mcp-godot` | Python bridge to the editor’s **HTTP API** (default port **3571**); needs Godot open with **GDAI MCP** enabled; proxies to `addons/gdai-mcp-plugin-godot/`. |
| `sequential-thinking` | Step-by-step reasoning MCP; needs **`node`** and `npm install` under `tools/mcp-support` (see workflow rule file). |
| `filesystem-workspace` | Broader workspace filesystem access via MCP. |
| `github` | GitHub API; requires **`GITHUB_PERSONAL_ACCESS_TOKEN`** (never commit secrets). |
| `foulward-rag` | Project RAG (`query_project_knowledge`, etc.); **optional** — requires the RAG service under **`~/LLM`** to be running; agents must not block if it is down. |

**Authoritative detail** (ports, “No tools” recovery, mandatory calls like `get_scene_tree` / `get_godot_errors`, GDAI stdout/stderr rule): **`AGENTS.md`** (repo root) and **`.cursor/rules/mcp-godot-workflow.mdc`**. This section does not duplicate those files.

---

## 2. Core Architecture

### 2.1 Player Character: Florence

**STATUS: EXISTS IN CODE**

- Male plague doctor. The player IS Florence — a stationary tower aimed manually with the mouse.
- Script: `res://scripts/florence_data.gd` — `class FlorenceData extends Resource` (**not** an autoload).
- Tracked fields: `florence_id`, `display_name`, `total_days_played`, `run_count`, `total_missions_played`, `boss_attempts`, `boss_victories`, `mission_failures`, `has_unlocked_research`, `has_unlocked_enchantments`, `has_recruited_any_mercenary`, `has_seen_any_mini_boss`, `has_defeated_any_mini_boss`, `has_reached_day_25`, `has_reached_day_50`, `has_seen_first_boss`.
- Florence takes damage from enemies reaching the tower (`SignalBus.florence_damaged`).
- Two weapon slots: CROSSBOW and RAPID_MISSILE (see [Section 2.3](#23-weapons)).

### 2.2 AI Companions

#### Arnulf
**STATUS: EXISTS IN CODE**

| Field | Value |
|-------|-------|
| Role | Melee frontline ally, autonomous fighter |
| `ally_id` | `arnulf` |
| `max_hp` | 200 |
| `basic_attack` | 25.0 |
| `is_unique` | true |
| `is_starter_ally` | true |

- Full state machine in `arnulf.gd` with `Types.ArnulfState` (IDLE, PATROL, CHASE, ATTACK, DOWNED, RECOVERING).
- Signals: `arnulf_state_changed`, `arnulf_incapacitated`, `arnulf_recovered`.
- `patrol_radius`: 55.0. Kill counter exists but frenzy activation is not in MVP.
- DOWNED to RECOVERING uses `health_component.reset_to_max()` (full HP recovery).
- **Drunkenness system: FORMALLY CUT.** See [Section 31](#31-formally-cut-features--never-implement).

#### Sybil
**STATUS: EXISTS IN CODE (spell management); PASSIVE SYSTEM PLANNED**

- Role: Spell researcher / spell support.
- Manages the spell system via `SpellManager` (see [Section 7](#7-spells)).

**PLANNED — Sybil Passive Selection System** (not yet in code).

#### Florence (Hub Role)
- Male plague doctor (see [Section 2.1](#21-player-character-florence)).

### 2.3 Weapons

**STATUS: EXISTS IN CODE**

`WeaponData` fields: `weapon_slot` (enum `Types.WeaponSlot`), `display_name`, `damage` (single float — **not** `base_damage_min`/`base_damage_max`).

| Weapon | File | Slot | Damage | `can_target_flying` | Burst |
|--------|------|------|--------|---------------------|-------|
| Crossbow | `res://resources/weapon_data/crossbow.tres` | CROSSBOW (0) | 50.0 | false | 1 |
| Rapid Missile | `res://resources/weapon_data/rapid_missile.tres` | RAPID_MISSILE (1) | 8.0 | false | 10 |

Additional fields (Phase 2): `assist_angle_degrees`, `assist_max_distance`, `base_miss_chance`, `max_miss_angle_degrees` — all default `0.0`.

Weapon upgrades tracked via `SignalBus.weapon_upgraded(weapon_slot, new_level)`. `WeaponUpgradeManager` scene-bound under `/root/Main/Managers/WeaponUpgradeManager`.

### 2.4 C# Integration

**STATUS: EXISTS IN CODE**

| File | Role |
|------|------|
| `res://autoloads/DamageCalculator.cs` | Autoload singleton — damage matrix |
| `res://autoloads/SavePayload.cs` | RefCounted save payload helpers |
| `res://scripts/FoulWardTypes.cs` | Integer enum mirror for C# (see [§5](#5-typesgd--full-enum-to-integer-mapping)) |
| `res://scripts/WaveCompositionHelper.cs` | RefCounted helper (wave roster) |
| `res://scripts/ProjectilePhysics.cs` | Node — projectile `_PhysicsProcess` |

**Interop rules**

- **Autoloads:** implemented in GDScript unless listed above; C# autoloads register in `project.godot` like GDScript.
- **Signals:** declare and emit only from `autoloads/signal_bus.gd` — C# consumes `SignalBus` like any autoload.
- **Enums:** `FoulWardTypes.cs` mirrors `types.gd` integer values; edit `types.gd` first, then align C#.

**Build requirements**

- **.NET 8 SDK** and **Godot .NET** editor/binary (Mono-enabled export template where relevant).
- Run `dotnet build FoulWard.csproj` **before** `./tools/run_gdunit.sh` when `.cs` sources change; stale or failing C# builds break GdUnit autoload resolution.

---

## 3. Autoloads — Init Order and Complete Public APIs

All registered in `project.godot`. **Init order matters** — do not change without reading repo-root **`AGENTS.md`**.

### 3.1 SignalBus (`res://autoloads/signal_bus.gd`) — Init #1

Central typed signal hub. 58+ signals. **No logic, no state. Never add logic here.**

All signals are declared only — no methods, no variables besides signals. See [Section 24](#24-signal-bus-reference) for the full signal table.

### 3.2 NavMeshManager (`res://scripts/nav_mesh_manager.gd`) — Init #2

Registers `NavigationRegion3D`, queues bake on `nav_mesh_rebake_requested`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `register_region(region: NavigationRegion3D) -> void` | void | Call when a NavRegion enters the tree |
| `request_rebake() -> void` | void | Queues a `bake_navigation_mesh()` on next idle |

### 3.3 DamageCalculator (`res://autoloads/DamageCalculator.cs`) — Init #3 — **C#**

Stateless 4×5 damage-type × armor-type matrix. Pure function singleton (C# autoload).

| Signature | Returns | Usage |
|-----------|---------|-------|
| `calculate_damage(base_damage: float, damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float` | float | Multiplied damage after armor matrix; TRUE type bypasses matrix |
| `calculate_dot_tick(dot_total_damage: float, tick_interval: float, duration: float, damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float` | float | Per-tick DoT damage after armor matrix |

**Damage Matrix:**

```
              PHYSICAL  FIRE  MAGICAL  POISON  TRUE
UNARMORED       1.0     1.0    1.0      1.0    1.0
HEAVY_ARMOR     0.5     1.0    2.0      1.0    1.0
UNDEAD          1.0     2.0    1.0      0.0    1.0
FLYING          1.0     1.0    1.0      1.0    1.0
```

### 3.4 AuraManager (`res://autoloads/aura_manager.gd`) — Init #4

Registers aura towers and enemy aura emitters. Queries bonuses by position.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `register_aura(building: BuildingBase) -> void` | void | Call when an `is_aura` building is placed |
| `deregister_aura(building_instance_id: String) -> void` | void | Call when an aura building is sold/destroyed |
| `get_damage_pct_bonus(building: BuildingBase) -> float` | float | Fractional dmg bonus from `damage_pct` auras covering this building |
| `get_enemy_speed_modifier(world_pos: Vector3) -> float` | float | Worst (most negative) speed debuff from `enemy_speed_pct` auras at position |
| `register_enemy_aura(enemy: EnemyBase, tag: String) -> void` | void | Registers a war shaman / plague shaman aura emitter |
| `deregister_enemy_aura(enemy_instance_id: String) -> void` | void | Removes enemy aura on death |
| `get_enemy_damage_bonus(world_pos: Vector2) -> float` | float | Max fractional damage bonus from `aura_buff` enemies at XZ position |
| `get_enemy_heal_per_sec(world_pos: Vector2) -> float` | float | Sum of heal/sec from `aura_heal` enemies at XZ position |
| `clear_all_emitters_for_tests() -> void` | void | Test helper: clears both registries |

### 3.5 EconomyManager (`res://autoloads/economy_manager.gd`) — Init #5

Owns `gold`, `building_material`, `research_material`. Duplicate cost scaling via `building_id`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `add_gold(amount: int) -> void` | void | Adds gold; emits `resource_changed(GOLD)` |
| `spend_gold(amount: int) -> bool` | bool | Deducts gold if sufficient; returns false otherwise |
| `add_building_material(amount: int) -> void` | void | Adds building material |
| `spend_building_material(amount: int) -> bool` | bool | Deducts building material if sufficient |
| `add_research_material(amount: int) -> void` | void | Adds research material |
| `spend_research_material(amount: int) -> bool` | bool | Deducts research material if sufficient |
| `can_afford(gold_cost: int, material_cost: int) -> bool` | bool | True if wallet covers both |
| `get_gold() -> int` | int | Current gold |
| `get_building_material() -> int` | int | Current building material |
| `get_research_material() -> int` | int | Current research material |
| `can_afford_building(building_data: BuildingData) -> bool` | bool | True if wallet covers scaled placement cost |
| `register_purchase(building_data: BuildingData) -> Dictionary` | Dict | Charges scaled cost, increments dup count, returns `{paid_gold, paid_material, duplicate_count_after}` or `{}` on failure |
| `get_refund(_building_data: BuildingData, paid_gold: int, paid_material: int) -> Dictionary` | Dict | Returns `{gold, material}` sell refund amounts |
| `get_gold_cost(building_data: BuildingData) -> int` | int | Effective gold cost with duplicate scaling |
| `get_material_cost(building_data: BuildingData) -> int` | int | Effective material cost with duplicate scaling |
| `get_cost_multiplier(building_data: BuildingData) -> float` | float | Current dup multiplier: `1.0 + k * n` |
| `get_duplicate_count(building_id: String) -> int` | int | Paid placements this mission for this building id |
| `reset_for_mission() -> void` | void | Clears duplicate counts |
| `apply_mission_economy(econ: MissionEconomyData) -> void` | void | Applies mission-start resources and overrides |
| `grant_wave_clear_reward(wave: int, econ: MissionEconomyData) -> Vector2i` | Vector2i | Adds wave-clear bonuses; returns `(gold, material)` granted |
| `get_wave_reward_gold(wave: int, econ: MissionEconomyData) -> int` | int | Gold for clearing wave N |
| `get_wave_reward_material(wave: int, econ: MissionEconomyData) -> int` | int | Material for clearing wave N |
| `reset_to_defaults() -> void` | void | Full reset for new game |
| `apply_save_snapshot(g: int, building_mat: int, research_mat: int) -> void` | void | Restore from save |

**Constants:** `DEFAULT_GOLD = 1000`, `DEFAULT_BUILDING_MATERIAL = 50`, `DEFAULT_RESEARCH_MATERIAL = 0`, `DEFAULT_SELL_REFUND_FRACTION = 0.6`, `DEFAULT_DUPLICATE_COST_K = 0.08`.

### 3.6 CampaignManager (`res://autoloads/campaign_manager.gd`) — Init #6

Day/campaign progress, faction registry, ally roster, mercenary catalog + offers. **MUST load before GameManager.**

| Signature | Returns | Usage |
|-----------|---------|-------|
| `start_new_campaign() -> void` | void | Resets everything, starts day 1 |
| `start_endless_run() -> void` | void | Initializes endless mode with synthetic scaling |
| `start_next_day() -> void` | void | Advances to the next day |
| `get_current_day() -> int` | int | Current day index (1-based) |
| `get_campaign_length() -> int` | int | Total days in active campaign |
| `get_current_day_config() -> DayConfig` | DayConfig | DayConfig for active day |
| `validate_day_configs(day_configs: Array[DayConfig]) -> void` | void | Warns on unknown faction/boss IDs |
| `is_ally_owned(ally_id: String) -> bool` | bool | True if ally is in owned roster |
| `get_owned_allies() -> Array[String]` | Array[String] | Copy of owned ally IDs |
| `get_active_allies() -> Array[String]` | Array[String] | Copy of ally IDs selected for next mission |
| `get_ally_data(ally_id: String) -> Resource` | Resource | AllyData for the given ID |
| `add_ally_to_roster(ally_id: String) -> void` | void | Adds ally; emits `ally_roster_changed` |
| `remove_ally_from_roster(ally_id: String) -> void` | void | Removes from owned+active; emits signal |
| `toggle_ally_active(ally_id: String) -> bool` | bool | Toggles active state; false if at max cap |
| `set_active_allies_from_list(ally_ids: Array[String]) -> void` | void | Replaces active set |
| `get_allies_for_mission_start() -> Array[String]` | Array[String] | IDs that should spawn at mission start |
| `generate_offers_for_day(day: int) -> void` | void | Generates mercenary offers from catalog |
| `preview_mercenary_offers_for_day(day: int, hypothetical_owned: Array[String]) -> Array` | Array | Preview offers without mutating state |
| `get_current_offers() -> Array` | Array | Current mercenary offers |
| `purchase_mercenary_offer(index: int) -> bool` | bool | Buys offer at index; spends resources, adds ally |
| `notify_mini_boss_defeated(boss_id: String) -> void` | void | May inject defection offer |
| `auto_select_best_allies(strategy: Types.StrategyProfile, offers: Array, roster: Array[String], max_purchases: int, budget_gold: int, budget_material: int, budget_research: int) -> Dictionary` | Dict | Returns `{recommended_offer_indices, recommended_active_allies}` |
| `get_save_data() -> Dictionary` | Dict | Save snapshot |
| `restore_from_save(data: Dictionary) -> void` | void | Restore from save |

**Key state:** `current_day`, `campaign_length`, `is_endless_mode`, `owned_allies`, `active_allies_for_next_day`, `max_active_allies_per_day` (2), `faction_registry`.

### 3.7 RelationshipManager (`res://autoloads/relationship_manager.gd`) — Init #7

Affinity −100..100 per `character_id`, tiers from `relationship_tier_config.tres`. No `class_name`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `get_affinity(character_id: String) -> float` | float | Raw affinity (−100..100) |
| `get_tier(character_id: String) -> String` | String | Tier name (e.g. "Hostile", "Neutral", "Friendly") |
| `get_tier_rank_index(tier_name: String) -> int` | int | Numeric rank (higher = warmer) |
| `add_affinity(character_id: String, delta: float) -> void` | void | Adjusts affinity, clamped |
| `reload_from_resources() -> void` | void | Reloads all character/event data from disk |
| `get_save_data() -> Dictionary` | Dict | `{affinities: {id: float}}` |
| `restore_from_save(data: Dictionary) -> void` | void | Restore affinity map |

### 3.8 SettingsManager (`res://autoloads/settings_manager.gd`) — Init #8

`user://settings.cfg` — volumes, graphics quality, keybind mirror.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `save_settings() -> void` | void | Persists to `user://settings.cfg` |
| `load_settings() -> void` | void | Loads from config file |
| `set_volume(bus_name: String, value: float) -> void` | void | Sets "Master", "Music", or "SFX" (0.0–1.0) |
| `set_graphics_quality(quality: String) -> void` | void | Stores string; no RenderingServer calls (MVP) |
| `remap_action(action_name: String, new_event: InputEvent) -> void` | void | Replaces first binding and saves |

### 3.9 GameManager (`res://autoloads/game_manager.gd`) — Init #9

Owns game state (`Types.GameState`), mission/wave index, territory map runtime, mission rewards, final boss state.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `start_new_game() -> void` | void | Full reset; calls `CampaignManager.start_new_campaign()` |
| `start_next_mission() -> void` | void | Delegates to `CampaignManager.start_next_day()` |
| `start_wave_countdown() -> void` | void | Begins combat from MISSION_BRIEFING |
| `enter_build_mode() -> void` | void | COMBAT → BUILD_MODE (time_scale 0.1) |
| `exit_build_mode() -> void` | void | BUILD_MODE → COMBAT (time_scale 1.0) |
| `get_game_state() -> Types.GameState` | GameState | Current state |
| `get_current_mission() -> int` | int | Mission number (1-indexed) |
| `get_current_wave() -> int` | int | Wave index in active mission |
| `get_florence_data() -> FlorenceData` | FlorenceData | Protagonist meta-state resource |
| `advance_day(reason: Types.DayAdvanceReason) -> void` | void | Increments Florence day counter |
| `get_current_day_index() -> int` | int | Delegates to CampaignManager |
| `get_day_config_for_index(day_index: int) -> DayConfig` | DayConfig | Looks up from campaign or creates synthetic |
| `start_mission_for_day(day_index: int, day_config: DayConfig) -> void` | void | Initializes mission and begins waves |
| `advance_to_next_day() -> void` | void | Advances calendar; assigns boss attack if needed |
| `get_territory_data(territory_id: String) -> TerritoryData` | TerritoryData | Lookup from territory map |
| `get_current_day_territory() -> TerritoryData` | TerritoryData | Territory for current day |
| `get_all_territories() -> Array[TerritoryData]` | Array | All territories |
| `reload_territory_map_from_active_campaign() -> void` | void | Reloads territory map resource |
| `apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void` | void | Updates territory ownership |
| `get_current_territory_gold_modifiers() -> Dictionary` | Dict | `{flat_gold_end_of_day, percent_gold_end_of_day}` |
| `get_aggregate_flat_gold_per_kill() -> int` | int | Sum of kill bonuses from held territories |
| `get_aggregate_research_cost_multiplier() -> float` | float | Product of research cost mults |
| `get_aggregate_enchanting_cost_multiplier() -> float` | float | Product of enchanting cost mults |
| `get_aggregate_weapon_upgrade_cost_multiplier() -> float` | float | Product of weapon upgrade cost mults |
| `get_aggregate_bonus_research_per_day() -> int` | int | Sum of bonus research per mission |
| `get_save_data() -> Dictionary` | Dict | Save snapshot |
| `restore_from_save(data: Dictionary) -> void` | void | Restore from save |

**Constants:** `TOTAL_MISSIONS = 5`, `WAVES_PER_MISSION = 5`.

### 3.10 BuildPhaseManager (`res://autoloads/build_phase_manager.gd`) — Init #10

Headless-safe guard for hex placement. Default `is_build_phase = true` (headless tests).

| Signature | Returns | Usage |
|-----------|---------|-------|
| `assert_build_phase(context: String) -> bool` | bool | Returns true if in build phase; warns otherwise |
| `set_build_phase_active(active: bool) -> void` | void | Toggles + emits `SignalBus.build_phase_started` or `SignalBus.combat_phase_started` |

**Signals (on SignalBus):** `build_phase_started()`, `combat_phase_started()` — emitted from here when `is_build_phase` changes.

### 3.11 AllyManager (`res://autoloads/ally_manager.gd`) — Init #11

Summoner building squads. `spawn_squad` / `despawn_squad` keyed by `placed_instance_id`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `spawn_squad(building: BuildingBase) -> void` | void | Spawns leader + followers for a summoner building |
| `despawn_squad(building_instance_id: String) -> void` | void | Frees all allies for that building |

### 3.12 CombatStatsTracker (`res://autoloads/combat_stats_tracker.gd`) — Init #12

CSV output to `user://simbot/runs/`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `begin_mission(mission_id: String, seed_val: int, layout_deg: float) -> void` | void | Start tracking a mission |
| `begin_run(mission_id: String, run_label: String) -> void` | void | Balance sweep run start |
| `end_run() -> void` | void | Flushes and deactivates run |
| `register_building(instance_id: String, building_id: String, size_class: String, ring_index: int, slot_id: int, cost_gold: int, upgrade_level: int) -> void` | void | Registers building for tracking |
| `flush_to_disk() -> void` | void | Writes wave_summary.csv + building_summary.csv |
| `record_projectile_damage(source_kind: String, source_placed_instance_id: String, slot_index: int, damage_applied: float, killed_target: bool) -> void` | void | Attributes damage to a building |
| `set_session_seed(seed_value: int) -> void` | void | Sets seed before begin_mission |
| `set_layout_rotation_deg(degrees: float) -> void` | void | Layout rotation for CSV |
| `set_verbose_logging(enabled: bool) -> void` | void | Enables event_log.csv output |
| `slot_index_to_ring(slot_index: int) -> int` | int | Maps slot 0..23 to ring 1..3 (static) |

### 3.13 SaveManager (`res://autoloads/save_manager.gd`) — Init #13

Rolling autosaves to `user://saves/attempt_*/slot_*.json`. 5 slots. No `class_name`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `start_new_attempt() -> void` | void | Creates new attempt directory |
| `save_current_state() -> void` | void | Builds payload from all managers and writes slot 0 |
| `load_slot(slot_index: int) -> bool` | bool | Restores state from slot; discards newer slots |
| `get_available_slots() -> Array[int]` | Array[int] | Slots with saved data |
| `has_resumable_attempt() -> bool` | bool | True if any attempt has at least one save |
| `clear_all_saves_for_test() -> void` | void | Test helper: removes all attempt dirs |

**Save payload structure:** `{version, attempt_id, campaign: {}, game: {}, relationship: {}, research: {}, shop: {}, enchantments: {}}`.

### 3.14 DialogueManager (`res://autoloads/dialogue_manager.gd`) — Init #14

Loads `DialogueEntry` `.tres` from `res://resources/dialogue/**`. Priority, AND conditions, once-only, `chain_next_id`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry` | DialogueEntry | Highest-priority eligible entry (chains have priority) |
| `get_entry_by_id(entry_id: String) -> DialogueEntry` | DialogueEntry | Direct lookup |
| `mark_entry_played(entry_id: String) -> void` | void | Marks once_only as played; activates chain |
| `notify_dialogue_finished(entry_id: String, character_id: String) -> void` | void | Emits `dialogue_line_finished`; clears chain |
| `on_campaign_day_started() -> void` | void | Syncs state from GameManager at day start |
| `get_tracked_gold() -> int` | int | Gold snapshot for conditions |
| `get_unlocked_research_ids_snapshot() -> Dictionary` | Dict | Research IDs tracked for conditions |
| `get_total_shop_purchases_tracked() -> int` | int | Total shop purchases |
| `get_arnulf_state_tracked() -> Types.ArnulfState` | ArnulfState | Arnulf state for conditions |
| `get_spell_cast_count_tracked() -> int` | int | Spell cast counter |

**Signals (local):** `dialogue_line_started(entry_id, character_id)`, `dialogue_line_finished(entry_id, character_id)`.

**Condition keys:** `current_mission_number`, `mission_won_count`, `gold_amount`, `sybil_research_unlocked_any`, `arnulf_research_unlocked_any`, `research_unlocked_<id>`, `shop_item_purchased_<id>`, `arnulf_is_downed`, `florence.*`, `campaign.*`.

### 3.15 AutoTestDriver (`res://autoloads/auto_test_driver.gd`) — Init #15

Headless smoke-test driver. Active on `--autotest`, `--simbot_profile`, or `--simbot_balance_sweep`.

### 3.16 GDAIMCPRuntime — Init #16

GDAI MCP GDExtension bridge (editor only). Cursor agents reach it via the **`gdai-mcp-godot`** MCP server when Godot is running; see [§1.1](#11-cursor-mcp-and-agent-toolchain).

### 3.17 EnchantmentManager (`res://autoloads/enchantment_manager.gd`) — Init #17

Per-weapon enchantment slots (elemental, power).

| Signature | Returns | Usage |
|-----------|---------|-------|
| `get_equipped_enchantment_id(weapon_slot: Types.WeaponSlot, slot_type: String) -> String` | String | ID of equipped enchantment (empty if none) |
| `get_equipped_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> EnchantmentData` | EnchantmentData | Loaded resource (null if none) |
| `get_all_equipped_enchantments_for_weapon(weapon_slot: Types.WeaponSlot) -> Dictionary` | Dict | `{elemental: id, power: id}` |
| `try_apply_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String, gold_cost: int) -> bool` | bool | Equips; spends gold; emits `enchantment_applied` |
| `remove_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> void` | void | Unequips; emits `enchantment_removed`. FREE (no cost). |
| `get_affinity_level(weapon_slot: Types.WeaponSlot) -> int` | int | POST-MVP: inert |
| `get_affinity_xp(weapon_slot: Types.WeaponSlot) -> float` | float | POST-MVP: inert |
| `gain_affinity_xp(weapon_slot: Types.WeaponSlot, amount: float) -> void` | void | POST-MVP: inert |
| `reset_to_defaults() -> void` | void | Clears all enchantments |
| `get_save_data() -> Dictionary` | Dict | Save snapshot |
| `restore_from_save(data: Dictionary) -> void` | void | Restore from save |

---

## 4. Scene-Bound Managers — Complete Public APIs

These live under `/root/Main/Managers/` and are **not** autoloads.

### 4.1 WaveManager (`res://scripts/wave_manager.gd`)

Path: `/root/Main/Managers/WaveManager`

Key methods (resolved via `get_node_or_null`):

| Signature | Returns | Usage |
|-----------|---------|-------|
| `reset_for_new_mission() -> void` | void | Clears all state for a new mission |
| `configure_for_day(day_config: DayConfig) -> void` | void | Applies multipliers, faction, wave count |
| `start_wave_sequence() -> void` | void | Begins first wave countdown |
| `ensure_boss_registry_loaded() -> void` | void | Loads boss data if not already |
| `set_day_context(day_config: DayConfig) -> void` | void | Sets day-level context |
| `clear_all_enemies() -> void` | void | Clears composed + mission spawn queues |
| `spawn_enemy_at_position(enemy_data: EnemyData, pos: Vector3) -> void` | void | Used by Brood Carrier on-death spawn |
| `get_enemy_data_by_type(enemy_type: Types.EnemyType) -> EnemyData` | EnemyData | Lookup from registry |

### 4.2 SpellManager (`res://scripts/spell_manager.gd`)

Path: `/root/Main/Managers/SpellManager`

| Signature | Returns | Usage |
|-----------|---------|-------|
| `cast_spell(spell_id: String) -> bool` | bool | Casts if mana sufficient and off cooldown |
| `cast_selected_spell() -> bool` | bool | Casts the currently-selected spell |
| `get_current_mana() -> int` | int | Current mana |
| `get_max_mana() -> int` | int | Max mana capacity (default 100) |
| `get_cooldown_remaining(spell_id: String) -> float` | float | Seconds remaining (0.0 if ready) |
| `is_spell_ready(spell_id: String) -> bool` | bool | Mana sufficient + off cooldown |
| `set_mana_to_full() -> void` | void | Used by mana draught |
| `restore_mana(amount: int) -> void` | void | Adds mana; ≤0 means full restore |
| `reset_to_defaults() -> void` | void | Mana to 0, clear cooldowns |
| `set_mana_for_save_restore(mana: int) -> void` | void | Save/load restore |
| `get_selected_spell_index() -> int` | int | Index in spell_registry |
| `set_selected_spell_index(index: int) -> void` | void | Sets selected (wraps) |
| `cycle_selected_spell(delta: int) -> void` | void | Cycles selection by ±1 |
| `get_selected_spell_id() -> String` | String | Empty if registry is empty |

### 4.3 ResearchManager (`res://scripts/research_manager.gd`)

Path: `/root/Main/Managers/ResearchManager`

| Signature | Returns | Usage |
|-----------|---------|-------|
| `can_unlock(node_id: String) -> bool` | bool | Material + prereqs met + not already unlocked |
| `unlock_node(node_id: String) -> bool` | bool | Spends material, unlocks building, emits signals |
| `unlock(node_id: String) -> void` | void | Alias for `unlock_node` |
| `is_unlocked(node_id: String) -> bool` | bool | True if unlocked |
| `get_available_nodes() -> Array[ResearchNodeData]` | Array | Nodes whose prereqs are met |
| `get_research_points() -> int` | int | Current research material |
| `add_research_points(amount: int) -> void` | void | Awards research material |
| `show_research_panel_for(node_id: String) -> void` | void | Opens in-mission research panel |
| `reset_to_defaults() -> void` | void | Clears unlocks; may dev-unlock all |
| `get_save_data() -> Dictionary` | Dict | `{unlocked_node_ids: [...]}` |
| `restore_from_save(data: Dictionary) -> void` | void | Restore unlocked set |

### 4.4 ShopManager (`res://scripts/shop_manager.gd`)

Path: `/root/Main/Managers/ShopManager`

| Signature | Returns | Usage |
|-----------|---------|-------|
| `purchase_item(item_id: String) -> bool` | bool | Checks affordability, applies effect, emits signal |
| `get_available_items() -> Array[ShopItemData]` | Array | Copy of shop catalog |
| `can_purchase(item_id: String) -> bool` | bool | Exists + affordable + preconditions |
| `add_consumable(item_id: String, amount: int = 1) -> void` | void | Adds to consumable stack (cap 20) |
| `consume(item_id: String) -> bool` | bool | Decrements stack; false if empty |
| `get_stack_count(item_id: String) -> int` | int | Current stack for consumable |
| `apply_mission_start_consumables() -> void` | void | Called by GameManager at mission start |
| `get_save_data() -> Dictionary` | Dict | `{consumable_stacks: {...}}` |
| `restore_from_save(data: Dictionary) -> void` | void | Restore stacks |

### 4.5 WeaponUpgradeManager (`res://scripts/weapon_upgrade_manager.gd`)

Path: `/root/Main/Managers/WeaponUpgradeManager`

Per-weapon level tracking, upgrade cost, stat lookup. Emits `SignalBus.weapon_upgraded`.

### 4.6 InputManager (`res://scripts/input_manager.gd`)

Path: `/root/Main/Managers/InputManager`

Translates mouse/keyboard input into public method calls on managers.

---

## 5. Types.gd — Full Enum-to-Integer Mapping

All enums defined in `res://scripts/types.gd`. Accessed as `Types.EnumName.VALUE`.

### GameState
| Name | Value |
|------|-------|
| MAIN_MENU | 0 |
| MISSION_BRIEFING | 1 |
| COMBAT | 2 |
| BUILD_MODE | 3 |
| WAVE_COUNTDOWN | 4 |
| BETWEEN_MISSIONS | 5 |
| MISSION_WON | 6 |
| MISSION_FAILED | 7 |
| GAME_WON | 8 |
| GAME_OVER | 9 |
| ENDLESS | 10 |

### DamageType
| Name | Value |
|------|-------|
| PHYSICAL | 0 |
| FIRE | 1 |
| MAGICAL | 2 |
| POISON | 3 |
| TRUE | 4 |

### ArmorType
| Name | Value |
|------|-------|
| UNARMORED | 0 |
| HEAVY_ARMOR | 1 |
| UNDEAD | 2 |
| FLYING | 3 |

### BuildingType (36 values)
| Name | Value | Size | Role |
|------|-------|------|------|
| ARROW_TOWER | 0 | starter | PHYSICAL |
| FIRE_BRAZIER | 1 | starter | FIRE |
| MAGIC_OBELISK | 2 | starter | MAGICAL |
| POISON_VAT | 3 | starter | POISON |
| BALLISTA | 4 | starter | PHYSICAL |
| ARCHER_BARRACKS | 5 | starter | SUMMONER |
| ANTI_AIR_BOLT | 6 | starter | AA |
| SHIELD_GENERATOR | 7 | starter | SHIELD |
| SPIKE_SPITTER | 8 | SMALL | PHYSICAL |
| EMBER_VENT | 9 | SMALL | FIRE DoT |
| FROST_PINGER | 10 | SMALL | MAGICAL slow |
| NETGUN | 11 | SMALL | PHYSICAL stop |
| ACID_DRIPPER | 12 | SMALL | POISON DoT |
| WOLFDEN | 13 | SMALL | SUMMONER |
| CROW_ROOST | 14 | SMALL | AA |
| ALARM_TOTEMS | 15 | SMALL | AURA |
| CROSSFIRE_NEST | 16 | SMALL | PHYSICAL |
| BOLT_SHRINE | 17 | SMALL | MAGICAL |
| THORNWALL | 18 | SMALL | PHYSICAL passive |
| FIELD_MEDIC | 19 | SMALL | HEALER |
| GREATBOW_TURRET | 20 | MEDIUM | PHYSICAL |
| MOLTEN_CASTER | 21 | MEDIUM | FIRE splash |
| ARCANE_LENS | 22 | MEDIUM | MAGICAL chain |
| PLAGUE_MORTAR | 23 | MEDIUM | POISON lob |
| BEAR_DEN | 24 | MEDIUM | SUMMONER |
| GUST_CANNON | 25 | MEDIUM | AA knockback |
| WARDEN_SHRINE | 26 | MEDIUM | AURA +15% dmg |
| IRON_CLERIC | 27 | MEDIUM | HEALER |
| SIEGE_BALLISTA | 28 | MEDIUM | PHYSICAL pierce |
| CHAIN_LIGHTNING | 29 | MEDIUM | MAGICAL |
| FORTRESS_CANNON | 30 | LARGE | PHYSICAL |
| DRAGON_FORGE | 31 | LARGE | FIRE AoE |
| VOID_OBELISK | 32 | LARGE | MAGICAL debuff |
| PLAGUE_CAULDRON | 33 | LARGE | POISON AoE |
| BARRACKS_FORTRESS | 34 | LARGE | SUMMONER |
| CITADEL_AURA | 35 | LARGE | AURA +20% |

### EnemyType (30 values)
| Name | Value | Tier |
|------|-------|------|
| ORC_GRUNT | 0 | Base |
| ORC_BRUTE | 1 | Base |
| GOBLIN_FIREBUG | 2 | Base |
| PLAGUE_ZOMBIE | 3 | Base |
| ORC_ARCHER | 4 | Base |
| BAT_SWARM | 5 | Base |
| ORC_SKIRMISHER | 6 | T1 |
| ORC_RATLING | 7 | T1 |
| GOBLIN_RUNTS | 8 | T1 |
| HOUND | 9 | T1 |
| ORC_RAIDER | 10 | T2 |
| ORC_MARKSMAN | 11 | T2 |
| WAR_SHAMAN | 12 | T2 |
| PLAGUE_SHAMAN | 13 | T2 |
| TOTEM_CARRIER | 14 | T2 |
| HARPY_SCOUT | 15 | T2 |
| ORC_SHIELDBEARER | 16 | T3 |
| ORC_BERSERKER | 17 | T3 |
| ORC_SABOTEUR | 18 | T3 |
| HEXBREAKER | 19 | T3 |
| WYVERN_RIDER | 20 | T3 |
| BROOD_CARRIER | 21 | T3 |
| TROLL | 22 | T4 |
| IRONCLAD_CRUSHER | 23 | T4 |
| ORC_OGRE | 24 | T4 |
| WAR_BOAR | 25 | T4 |
| ORC_SKYTHROWER | 26 | T4 |
| WARLORDS_GUARD | 27 | T5 |
| ORCISH_SPIRIT | 28 | T5 |
| PLAGUE_HERALD | 29 | T5 |

### WeaponSlot
| Name | Value |
|------|-------|
| CROSSBOW | 0 |
| RAPID_MISSILE | 1 |

### ResourceType
| Name | Value |
|------|-------|
| GOLD | 0 |
| BUILDING_MATERIAL | 1 |
| RESEARCH_MATERIAL | 2 |

### ArnulfState
| Name | Value |
|------|-------|
| IDLE | 0 |
| PATROL | 1 |
| CHASE | 2 |
| ATTACK | 3 |
| DOWNED | 4 |
| RECOVERING | 5 |

### TargetPriority
| Name | Value |
|------|-------|
| CLOSEST | 0 |
| HIGHEST_HP | 1 |
| FLYING_FIRST | 2 |
| LOWEST_HP | 3 |

### AllyClass
| Name | Value |
|------|-------|
| MELEE | 0 |
| RANGED | 1 |
| SUPPORT | 2 |

### AllyCombatRole
| Name | Value |
|------|-------|
| MELEE | 0 |
| RANGED | 1 |
| HEALER | 2 |
| BOMBER | 3 |
| AURA | 4 |

### HubRole
| Name | Value |
|------|-------|
| SHOP | 0 |
| RESEARCH | 1 |
| ENCHANT | 2 |
| MERCENARY | 3 |
| ALLY | 4 |
| FLAVOR_ONLY | 5 |

### TerrainType
| Name | Value |
|------|-------|
| GRASSLAND | 0 |
| FOREST | 1 |
| SWAMP | 2 |
| RUINS | 3 |
| TUNDRA | 4 |

### TerrainEffect
| Name | Value |
|------|-------|
| NONE | 0 |
| SLOW | 1 |
| IMPASSABLE | 2 |

### EnemyBodyType
| Name | Value |
|------|-------|
| GROUND | 0 |
| FLYING | 1 |
| HOVER | 2 |
| BOSS | 3 |
| STRUCTURE | 4 |
| LARGE_GROUND | 5 |
| SIEGE | 6 |
| ETHEREAL | 7 |

### SummonLifetimeType
| Name | Value |
|------|-------|
| NONE | 0 |
| MORTAL | 1 |
| RECURRING | 2 |
| IMMORTAL | 3 |

### BuildingSizeClass
| Name | Value |
|------|-------|
| SINGLE_SLOT | 0 |
| DOUBLE_WIDE | 1 |
| TRIPLE_CLUSTER | 2 |
| SMALL | 3 |
| MEDIUM | 4 |
| LARGE | 5 |

### Other Enums (stable, rarely referenced directly)

`AllyRole` (0–4), `StrategyProfile` (0–4), `BuildingBaseMesh` (0–3), `BuildingTopMesh` (0–6), `DayAdvanceReason` (0–2), `UnitSize` (0–3), `AllyAiMode` (0–4), `AuraModifierKind` (0–2), `AuraModifierOp` (0–1), `AuraCategory` (0–3), `AuraStat` (0–5), `MissionBalanceStatus` (0–3).

**Non-existent enum: `Types.SpellType` / `Types.SpellID` — do NOT use or assume.**

---

## 6. Game States

**STATUS: EXISTS IN CODE** — Defined in `res://scripts/types.gd` as `Types.GameState` (see [Section 5](#5-typesgd--full-enum-to-integer-mapping)).

**Transition graph:** `MAIN_MENU → MISSION_BRIEFING → COMBAT ↔ BUILD_MODE → WAVE_COUNTDOWN → (COMBAT loop) → MISSION_WON/MISSION_FAILED → BETWEEN_MISSIONS → MISSION_BRIEFING...`

**PLANNED states:** `RING_ROTATE` (pre-battle ring rotation), `PASSIVE_SELECT` (Sybil passives).

---

## 7. Spells

**STATUS: EXISTS IN CODE**

Manager: `SpellManager` (scene node under `/root/Main/Managers/`) — `max_mana`: 100, `mana_regen_rate`: 5.0/sec.

Four registered spells (wired in `main.tscn`):

| `.tres` File | Display Name | Mana | Cooldown |
|--------------|-------------|------|----------|
| `shockwave.tres` | Shockwave | 50 | 60s |
| `slow_field.tres` | Slow Field | — | — |
| `arcane_beam.tres` | Arcane Beam | — | — |
| `tower_shield.tres` | Aegis Pulse | — | — |

> `slow_field.tres` has `damage = 0.0` intentionally (control spell). Do not "fix" it.

**Hotkeys:** Space = cast selected, Tab/Shift+Tab = cycle, 1-4 = select slot.

**FORMALLY CUT:** Time Stop spell. See [Section 31](#31-formally-cut-features--never-implement).

---

## 8. Buildings

**STATUS: EXISTS IN CODE**

36 `BuildingData` `.tres` files under `res://resources/building_data/`. See [Section 5 BuildingType](#buildingtype-36-values) for the full enum.

Key field names (use exact names — see [Section 32](#32-field-name-discipline--correct-vs-wrong-names)):
- `gold_cost` (not `build_gold_cost`), `target_priority`, `damage_type`, `building_id`

### Ring Rotation
**EXISTS:** `rotate_ring()` in `BuildPhaseManager` / `HexGrid`.
**PLANNED:** Pre-battle ring rotation UI.

---

## 9. Research

**STATUS: EXISTS IN CODE**

24 `research_data/*.tres` files. Field names: `node_id`, `display_name`, `research_cost` (**not** `rp_cost`), `prerequisite_ids`.

See the research manager API in [Section 4.3](#43-researchmanager).

---

## 10. Enchantments

**STATUS: EXISTS IN CODE**

- Two slot types per weapon: `"elemental"` and `"power"`.
- Four `.tres` files: `arcane_focus`, `scorching_bolts`, `sharpened_mechanism`, `toxic_payload`.
- Remove enchantment: **FREE**. Apply: uses `try_apply_enchantment(..., gold_cost: int)`.
- `_affinity_xp` / `_affinity_level` stubs exist — **POST-MVP, not active**.

---

## 11. Allies and Mercenaries

**STATUS: EXISTS IN CODE**

12 ally `.tres` files under `res://resources/ally_data/`.

| `ally_id` | `max_hp` | `attack_damage` | `is_unique` | `is_starter` |
|-----------|----------|-----------------|-------------|--------------|
| arnulf | 200 | 25.0 | true | true |
| anti_air_scout | 65 | 11.0 | false | false |
| ally_melee_generic | 90 | 12.0 | false | false |
| ally_ranged_generic | 70 | 14.0 | false | false |
| ally_support_generic | 80 | 8.0 | false | false |
| bear_alpha | 200 | 22.0 | false | — |
| defected_orc_captain | 140 | 18.0 | true | false |
| hired_archer | 70 | 14.0 | false | false |
| knight_captain | 180 | 28.0 | false | — |
| militia_archer | 90 | 14.0 | false | — |
| wolf_alpha | 80 | 12.0 | false | — |
| wolf_pup | 50 | 7.0 | false | — |

---

## 12. Enemies and Bosses

**STATUS: EXISTS IN CODE**

30 `EnemyData` `.tres` files. See [Section 5 EnemyType](#enemytype-30-values) for the full enum.

### Bosses

| File | `boss_id` | Notes |
|------|-----------|-------|
| `bossdata_final_boss.tres` | `final_boss` | Day 50. 5000 HP, 80 dmg, phase 3. |
| `bossdata_orc_warlord_miniboss.tres` | `orc_warlord` | 400 HP, 32 dmg. |
| `bossdata_plague_cult_miniboss.tres` | `plague_cult_miniboss` | 450 HP, 35 dmg. |
| `bossdata_audit5_territory_miniboss.tres` | — | Territory mini-boss. |

### Factions

| File | `faction_id` | Notes |
|------|-------------|-------|
| `faction_data_default_mixed.tres` | DEFAULT_MIXED | Equal-weight six-type MVP mix |
| `faction_data_orc_raiders.tres` | ORC_RAIDERS | Orc-heavy + mini-boss |
| `faction_data_plague_cult.tres` | PLAGUE_CULT | Undead/fire/flyer + mini-boss |

---

## 13. Campaign and Progression

### Day/Wave Structure
- 50 days main campaign (`campaign_main_50days.tres`), 5 days short (`campaign_short_5days.tres`).
- Each mission = 5 waves (`WAVES_PER_MISSION`).
- After Day 50 final boss: loop continues until player wins or tower destroyed.

### Endless Mode
**PARTIALLY EXISTS:** `CampaignManager.is_endless_mode`, `start_endless_run()`, synthetic day scaling.

### Star Difficulty System
**DOES NOT EXIST IN CODE. ON ROADMAP.** Normal / Veteran / Nightmare per-map.

---

## 14. Meta-Progression: The Chronicle of Foul Ward

**DOES NOT EXIST IN CODE. CONFIRMED ADDED TO DESIGN. Must be implemented.**

See implementation spec: `ChronicleData`, `ChroniclePerkData`, achievement triggers via SignalBus.

---

## 15. Hub Screens

- `hub.tscn` — 2D hub with `CharacterCatalog`. All `# TODO(ART)`.
- `between_mission_screen.tscn` — `TabContainer`: World Map, Shop, Research, Buildings, Weapons, Mercenaries.
- `dialogue_panel.tscn` — Click-to-continue dialogue overlay.
- Hub keeper presence: TAUR-style functional screens (NOT Hades-style 3D hub — **FORMALLY CUT**).

---

## 16. World Map

- `ui/world_map.tscn` — territory list + labels.
- 5 territories: `heartland_plains`, `blackwood_forest`, `ashen_swamp`, `iron_ridge`, `outer_city`.
- **PLANNED:** Hand-drawn illustrated fantasy map with hotspot overlays.

---

## 17. Dialogue System

**EXISTS IN CODE (all content is placeholder)**

15 `DialogueEntry` `.tres` files. All `TODO:` text. Priority, AND conditions, once-only, chain_next_id.

Characters: `FLORENCE`, `COMPANION_MELEE`, `SPELL_RESEARCHER`, `MERCHANT`, `WEAPONS_ENGINEER`, `ENCHANTER`, `MERCENARY_COMMANDER`.

---

## 18. Economy

**EXISTS IN CODE.** See [Section 3.5 EconomyManager](#35-economymanager) for the complete API.

Three currencies: `gold` (starting 1000), `building_material` (starting 50), `research_material` (starting 0).

Duplicate cost scaling: linear per `BuildingData.building_id`. Sell refund: `sell_refund_fraction` × `sell_refund_global_multiplier`.

---

## 19. Shop

**EXISTS IN CODE (basic)**

4 items: `tower_repair`, `building_repair`, `arrow_tower` (voucher), `mana_draught`.

**PLANNED:** Shop inventory rotation.

---

## 20. Wave System

**EXISTS IN CODE.** See [Section 4.1 WaveManager](#41-wavemanager).

`WaveComposer` + `WavePatternData` + point budgets. Staggered spawn in `_physics_process`. `enemy_data_registry.size() == 30` enforced.

---

## 21. Terrain

**EXISTS IN CODE**

- `Types.TerrainType`: GRASSLAND, FOREST, SWAMP, RUINS, TUNDRA.
- Two terrain scenes: `terrain_grassland.tscn`, `terrain_swamp.tscn` (0.55× speed).
- `NavMeshManager`, `TerrainZone`, `CampaignManager._load_terrain`.

---

## 22. Art Pipeline

**PLACEHOLDER SYSTEM EXISTS; PRODUCTION ART PLANNED**

`ArtPlaceholderHelper`, `RiggedVisualWiring`, `PlaceholderIconGenerator`. All combat/hub scenes marked `# TODO(ART)`.

---

## 23. SimBot and Testing

- `SimBot` — headless simulation: `run_balance_sweep`, `run_batch`, `run_single`.
- Loadouts: `balanced`, `summoner_heavy`, `artillery_air`.
- `CombatStatsTracker` writes wave/building CSVs (under `user://simbot/…` for SimBot runs); balance tooling includes `tools/simbot_balance_report.py` and related scripts (see repo and repo-root `AGENTS.md` test commands).

**Headless automation (not GdUnit):** `AutoTestDriver` activates when the project is run with CLI user args such as `--autotest`, `--simbot_profile=…`, or `--simbot_balance_sweep` (see `autoloads/auto_test_driver.gd`). That path boots the real game flow and drives `SimBot`, so **economy, waves, and combat stats behave like a mission** — useful for sweeps and integration-style balance checks. It is **not** a substitute for **GdUnit** unit/integration tests (`./tools/run_gdunit*.sh`), which assert specific APIs and run without full interactive mission requirements.

- **525 passing GdUnit4 tests.**
- Quick: `./tools/run_gdunit_quick.sh`, Unit (~65s): `./tools/run_gdunit_unit.sh`, Parallel (~2m45s): `./tools/run_gdunit_parallel.sh`, Sequential: `./tools/run_gdunit.sh`.

---

## 24. Signal Bus Reference

**STATUS: EXISTS IN CODE** — All 58+ signals declared in `res://autoloads/signal_bus.gd`.

### Combat

| Signal | Parameters |
|--------|-----------|
| `enemy_killed` | `enemy_type: Types.EnemyType, position: Vector3, gold_reward: int` |
| `enemy_reached_tower` | `enemy_type: Types.EnemyType, damage: int` |
| `tower_damaged` | `current_hp: int, max_hp: int` |
| `tower_destroyed` | (none) |
| `projectile_fired` | `weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3` |
| `arnulf_state_changed` | `new_state: Types.ArnulfState` |
| `arnulf_incapacitated` | (none) |
| `arnulf_recovered` | (none) |
| `building_dealt_damage` | `instance_id: String, damage: float, enemy_id: String` |
| `florence_damaged` | `amount: int, source_enemy_id: String` |

### Allies

| Signal | Parameters |
|--------|-----------|
| `ally_spawned` | `ally_id: String, building_instance_id: String` |
| `ally_died` | `ally_id: String, building_instance_id: String` |
| `ally_squad_wiped` | `building_instance_id: String` |
| `ally_downed` | `ally_id: String` |
| `ally_recovered` | `ally_id: String` |
| `ally_killed` | `ally_id: String` |
| `ally_state_changed` | `ally_id: String, new_state: String` |

### Bosses

| Signal | Parameters |
|--------|-----------|
| `boss_spawned` | `boss_id: String` |
| `boss_killed` | `boss_id: String` |
| `campaign_boss_attempted` | `day_index: int, success: bool` |

### Waves

| Signal | Parameters |
|--------|-----------|
| `wave_countdown_started` | `wave_number: int, seconds_remaining: float` |
| `wave_started` | `wave_number: int, enemy_count: int` |
| `enemy_spawned` | `enemy_type: Types.EnemyType, position: Vector2` |
| `enemy_enraged` | `enemy_instance_id: String` |
| `wave_cleared` | `wave_number: int` |
| `all_waves_cleared` | (none) |

### Economy

| Signal | Parameters |
|--------|-----------|
| `resource_changed` | `resource_type: Types.ResourceType, new_amount: int` |

### Territories / World Map

| Signal | Parameters |
|--------|-----------|
| `territory_state_changed` | `territory_id: String` |
| `world_map_updated` | (none) |

### Terrain

| Signal | Parameters |
|--------|-----------|
| `enemy_entered_terrain_zone` | `enemy: Node, speed_multiplier: float` |
| `enemy_exited_terrain_zone` | `enemy: Node, speed_multiplier: float` |
| `terrain_prop_destroyed` | `prop: Node, world_position: Vector3` |
| `nav_mesh_rebake_requested` | (none) |

### Buildings

| Signal | Parameters |
|--------|-----------|
| `building_placed` | `slot_index: int, building_type: Types.BuildingType` |
| `building_sold` | `slot_index: int, building_type: Types.BuildingType` |
| `building_upgraded` | `slot_index: int, building_type: Types.BuildingType` |
| `building_destroyed` | `slot_index: int` |

### Spells

| Signal | Parameters |
|--------|-----------|
| `spell_cast` | `spell_id: String` |
| `spell_ready` | `spell_id: String` |
| `mana_changed` | `current_mana: int, max_mana: int` |

### Game State

| Signal | Parameters |
|--------|-----------|
| `game_state_changed` | `old_state: Types.GameState, new_state: Types.GameState` |
| `mission_started` | `mission_number: int` |
| `mission_won` | `mission_number: int` |
| `mission_failed` | `mission_number: int` |
| `florence_state_changed` | (none) |

### Campaign

| Signal | Parameters |
|--------|-----------|
| `campaign_started` | `campaign_id: String` |
| `day_started` | `day_index: int` |
| `day_won` | `day_index: int` |
| `day_failed` | `day_index: int` |
| `campaign_completed` | `campaign_id: String` |

### Build Mode

| Signal | Parameters |
|--------|-----------|
| `build_mode_entered` | (none) |
| `build_mode_exited` | (none) |

### Research

| Signal | Parameters |
|--------|-----------|
| `research_unlocked` | `node_id: String` |
| `research_node_unlocked` | `node_id: String` |
| `research_points_changed` | `points: int` |

### Shop

| Signal | Parameters |
|--------|-----------|
| `shop_item_purchased` | `item_id: String` |
| `mana_draught_consumed` | (none) |

### Weapons / Enchantments

| Signal | Parameters |
|--------|-----------|
| `weapon_upgraded` | `weapon_slot: Types.WeaponSlot, new_level: int` |
| `enchantment_applied` | `weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String` |
| `enchantment_removed` | `weapon_slot: Types.WeaponSlot, slot_type: String` |

### Mercenaries / Roster

| Signal | Parameters |
|--------|-----------|
| `mercenary_offer_generated` | `ally_id: String` |
| `mercenary_recruited` | `ally_id: String` |
| `ally_roster_changed` | (none) |

---

## 25. Scene Tree Overview

```
/root/Main (Node3D)
├── Camera3D
├── DirectionalLight3D
├── TerrainContainer (Node3D) — CampaignManager._load_terrain
├── Tower (StaticBody3D) [tower.tscn]
│   ├── TowerMesh (MeshInstance3D)
│   ├── TowerCollision (CollisionShape3D)
│   ├── HealthComponent (Node)
│   └── TowerLabel (Label3D)
├── HexGrid (Node3D) [hex_grid.tscn]
│   └── HexSlot00..HexSlot23 (Area3D x24)
├── Arnulf (CharacterBody3D) [arnulf.tscn]
├── BuildingContainer (Node3D)
├── ProjectileContainer (Node3D)
├── EnemyContainer (Node3D)
├── Managers (Node)
│   ├── WaveManager (Node)
│   ├── SpellManager (Node)
│   ├── ResearchManager (Node)
│   ├── ShopManager (Node)
│   ├── WeaponUpgradeManager (Node)
│   └── InputManager (Node)
└── UI (CanvasLayer)
    ├── UIManager (Control)
    ├── HUD [hud.tscn]
    ├── BuildMenu [build_menu.tscn]
    ├── BetweenMissionScreen [between_mission_screen.tscn]
    ├── MainMenu [main_menu.tscn]
    ├── MissionBriefing (Control)
    └── EndScreen (Control)
```

Manager node path contracts:

| Path | Node |
|------|------|
| `/root/Main/Managers/WaveManager` | WaveManager |
| `/root/Main/Managers/ResearchManager` | ResearchManager |
| `/root/Main/Managers/WeaponUpgradeManager` | WeaponUpgradeManager |
| `/root/Main/Managers/ShopManager` | ShopManager |
| `/root/Main/Managers/SpellManager` | SpellManager |
| `/root/Main/Managers/InputManager` | InputManager |

---

## 26. Physics Layers and Input Actions

### Physics Layers

| Layer | Assigned To |
|-------|------------|
| 1 | Tower (StaticBody3D) |
| 2 | Enemies |
| 3 | Arnulf |
| 4 | Buildings |
| 5 | Projectiles |
| 6 | Ground |
| 7 | HexGrid slots (Area3D) |

### Input Actions

| Action Name | Default Binding | Purpose |
|-------------|----------------|---------|
| `fire_primary` | Left Mouse | Florence crossbow |
| `fire_secondary` | Right Mouse | Florence rapid missile |
| `cast_shockwave` | Space | Cast selected spell |
| `toggle_build_mode` | B or Tab | Enter/exit build mode |
| `cancel` | Escape | Exit build mode / close menu |

---

## 27. Lifecycle Flows

### 27.1 Full Mission Cycle

```
1. MAIN_MENU
   ↓ User clicks "Start"
2. GameManager.start_new_game()
   → EconomyManager.reset_to_defaults()
   → EnchantmentManager.reset_to_defaults()
   → ResearchManager.reset_to_defaults()
   → WeaponUpgradeManager.reset_to_defaults()
   → FlorenceData.reset_for_new_run()
   → CampaignManager.start_new_campaign()
     → _bootstrap_starter_allies()
     → _start_current_day_internal()
       → SignalBus.day_started.emit(1)
       → CampaignManager._load_terrain(territory)
       → GameManager.start_mission_for_day(1, day_config)
         → _transition_to(COMBAT)
         → BuildPhaseManager.set_build_phase_active(false)
         → SignalBus.mission_started.emit(1)
         → _spawn_allies_for_current_mission()
         → _apply_shop_mission_start_consumables()
         → _begin_mission_wave_sequence()
           → WaveManager.ensure_boss_registry_loaded()
           → EconomyManager.apply_mission_economy(day_config.mission_economy)
           → WaveManager.reset_for_new_mission()
           → WaveManager.configure_for_day(day_config)
           → WaveManager.start_wave_sequence() [deferred]

3. COMBAT (waves loop)
   → WaveManager emits wave_countdown_started(N, seconds)
   → WaveManager emits wave_started(N, count)
   → Enemies spawn, pathfind, attack tower
   → Buildings auto-target and fire projectiles
   → On last enemy dead: WaveManager emits wave_cleared(N)
   → EconomyManager.grant_wave_clear_reward()
   → Next wave starts... or:

4. ALL WAVES CLEARED
   → SignalBus.all_waves_cleared.emit()
   → GameManager._on_all_waves_cleared()
     → _cleanup_allies()
     → apply_day_result_to_territory(day_config, true)
     → EconomyManager.add_gold(reward), add_building_material, add_research_material
     → SignalBus.mission_won.emit(day_index)
       → CampaignManager._on_mission_won(day_index)
         → SignalBus.day_won.emit(day)
         → current_day += 1
         → generate_offers_for_day(current_day)
       → GameManager._on_mission_won_transition_to_hub(day)
         → _transition_to(BETWEEN_MISSIONS)
       → SaveManager.save_current_state()

5. BETWEEN_MISSIONS (hub)
   → Player uses Shop, Research, Weapons, Enchantments, Mercenaries tabs
   → Player clicks "NEXT DAY"
   → CampaignManager.start_next_day()
     → GameManager.prepare_next_campaign_day_if_needed()
     → _start_current_day_internal() [cycle repeats from step 2]

6. TOWER DESTROYED (alternative)
   → SignalBus.tower_destroyed.emit()
   → GameManager._on_tower_destroyed()
     → _transition_to(MISSION_FAILED)
     → SignalBus.mission_failed.emit(day)
     → CampaignManager._on_mission_failed(day)
       → failed_attempts_on_current_day += 1
       → SignalBus.day_failed.emit(day)
```

### 27.2 Building Placement Flow

```
1. Player enters BUILD_MODE (B key or Tab)
   → GameManager.enter_build_mode()
     → Engine.time_scale = 0.1
     → BuildPhaseManager.set_build_phase_active(true)
     → SignalBus.build_mode_entered.emit()

2. Player clicks a HexGrid slot
   → InputManager raycasts layer 7 → finds HexSlot
   → If slot empty: BuildMenu opens with available buildings
   → If slot occupied: BuildMenu opens sell panel

3. Player selects a building from BuildMenu
   → BuildMenu checks EconomyManager.can_afford_building(building_data)
   → BuildMenu checks is_locked (ResearchManager gating)
   → If locked: ResearchManager.show_research_panel_for(node_id)

4. HexGrid.place_building(slot_index, building_type)
   → BuildPhaseManager.assert_build_phase("place_building") → must be true
   → EconomyManager.register_purchase(building_data) → {paid_gold, paid_material}
   → BuildingScene.instantiate() → BuildingBase
   → building.initialize_with_economy(building_data, paid_gold, paid_material)
   → _building_container.add_child(building)
   → building.placed_instance_id = "slot_%d_%s" % [slot_index, building_id]
   → If building_data.is_aura: AuraManager.register_aura(building)
   → If building_data.is_summoner: AllyManager.spawn_squad(building)
   → CombatStatsTracker registers building
   → SignalBus.building_placed.emit(slot_index, building_type)

5. Selling:
   → HexGrid.sell_building(slot_index)
   → EconomyManager.get_refund(data, invested_gold, invested_material)
   → Refund gold + material to player
   → If summoner: AllyManager.despawn_squad(instance_id)
   → If aura: AuraManager.deregister_aura(instance_id)
   → building.queue_free()
   → SignalBus.building_sold.emit(slot_index, building_type)
```

### 27.3 Enemy Reaching Tower Flow

```
1. EnemyBase spawns (WaveManager instantiates)
   → Added to "enemies" group
   → initialize(enemy_data) sets stats, shield, special tags
   → NavigationAgent3D target = tower position
   → SignalBus.enemy_spawned.emit(enemy_type, position)

2. Movement (_physics_process)
   → NavigationAgent3D pathfinds toward tower
   → AuraManager.get_enemy_speed_modifier() adjusts speed
   → TerrainZone multipliers applied (min of overlapping zones)
   → Stuck detection: if no progress for 1.5s, retarget

3. Enemy reaches tower (distance < attack_range)
   → _is_attacking = true
   → _attack_timer counts down
   → On attack: deals damage to Tower.health_component
   → SignalBus.enemy_reached_tower.emit(enemy_type, damage) [first time only]
   → SignalBus.florence_damaged.emit(amount, instance_id)
   → SignalBus.tower_damaged.emit(current_hp, max_hp)

4. Tower HP reaches 0
   → Tower.health_component.health_depleted emits
   → SignalBus.tower_destroyed.emit()
   → GameManager._on_tower_destroyed() → MISSION_FAILED

5. Enemy killed (HP reaches 0)
   → health_component.health_depleted emits
   → EnemyBase._on_health_depleted()
   → SignalBus.enemy_killed.emit(enemy_type, position, gold_reward)
   → EconomyManager._on_enemy_killed() adds gold
   → enemy.queue_free()
```

---

## 28. How To Add X — Templates

### 28.1 How to Add a New Building

1. **Add enum value** to `Types.BuildingType` at the end of the appropriate size section (SMALL 8–19, MEDIUM 20–29, LARGE 30–35). **Never reorder existing values.**

2. **Create resource file** `res://resources/building_data/my_building.tres`:
   - Script: `res://scripts/resources/building_data.gd`
   - Required fields: `building_type` (new enum), `building_id` (snake_case string), `display_name`, `gold_cost`, `damage`, `fire_rate`, `attack_range`, `damage_type` (int matching `Types.DamageType`), `size_class` (string: "SMALL"/"MEDIUM"/"LARGE"), `is_locked` (true if gated by research), `unlock_research_id` (matching a `ResearchNodeData.node_id`)

3. **Register in HexGrid** — add the `.tres` to `building_data_registry` in `hex_grid.tscn` (must have exactly 36 entries, indexed by `Types.BuildingType` ordinal).

4. **If research-gated**, create `res://resources/research_data/unlock_my_building.tres`:
   - Script: `res://scripts/resources/research_node_data.gd`
   - Fields: `node_id`, `display_name`, `research_cost`, `prerequisite_ids[]`
   - Add to `ResearchManager.research_nodes` in `main.tscn`.

5. **If summoner**, set `is_summoner = true`, `summon_squad_size`, `summon_leader_data_path`, `summon_follower_data_path`. `AllyManager.spawn_squad()` handles the rest.

6. **If aura**, set `is_aura = true`, `aura_radius`, `aura_effect_type` (`"damage_pct"` or `"enemy_speed_pct"`), `aura_effect_value`, `aura_category`.

7. **Update docs**: Add to `INDEX_SHORT.md` and `INDEX_FULL.md`. Update this document's building list.

8. **Add test coverage** in `tests/unit/test_content_invariants.gd` (parametric `.tres` validation).

9. **Run tests**: `./tools/run_gdunit_unit.sh` — fix failures before continuing.

### 28.2 How to Add a New Signal

1. **Declare in `autoloads/signal_bus.gd`**:
   ```gdscript
   @warning_ignore("unused_signal")
   signal my_event_happened(param1: String, param2: int)
   ```
   Name: past tense, snake_case. All parameters typed.

2. **Emit from the source system** (not from SignalBus itself — SignalBus has no logic):
   ```gdscript
   SignalBus.my_event_happened.emit("value", 42)
   ```

3. **Connect from the consuming system** (in `_ready()` or with `is_connected` guard):
   ```gdscript
   func _ready() -> void:
       if not SignalBus.my_event_happened.is_connected(_on_my_event):
           SignalBus.my_event_happened.connect(_on_my_event)

   func _on_my_event(param1: String, param2: int) -> void:
       # handle
   ```

4. **Update Signal Bus Reference** in this document ([Section 24](#24-signal-bus-reference)).

5. **If RelationshipManager should react**, create `res://resources/relationship_events/my_event.tres` with `signal_name = "my_event_happened"` and `character_deltas`.

6. **In tests**, if you emit the signal using the real autoload, reset state in `after_test()`.

### 28.3 How to Add a New Spell

1. **Create resource** `res://resources/spell_data/my_spell.tres`:
   - Script: `res://scripts/resources/spell_data.gd`
   - Fields: `spell_id` (snake_case), `display_name`, `mana_cost`, `cooldown`, `damage`, `radius`, `damage_type`, `hits_flying`

2. **Add to SpellManager's `spell_registry`** in `main.tscn` (append to the array).

3. **Implement the effect** in `SpellManager._apply_spell_effect()`:
   ```gdscript
   func _apply_spell_effect(spell_data: SpellData) -> void:
       match spell_data.spell_id:
           # ... existing ...
           "my_spell":
               _apply_my_spell(spell_data)

   func _apply_my_spell(spell_data: SpellData) -> void:
       # Iterate enemies in group, apply damage/effect
       for node: Node in get_tree().get_nodes_in_group("enemies"):
           if not is_instance_valid(node):
               continue
           var enemy: EnemyBase = node as EnemyBase
           if enemy == null:
               continue
           if not spell_data.hits_flying and enemy.get_enemy_data().is_flying:
               continue
           enemy.take_damage(spell_data.damage, spell_data.damage_type)
   ```

4. **Hotkey** — update `InputManager` if adding a new slot beyond 1–4.

5. **Update docs**: Add to this document's spell table, update INDEX files.

### 28.4 How to Add a New Research Node

1. **Create resource** `res://resources/research_data/my_node.tres`:
   - Script: `res://scripts/resources/research_node_data.gd`
   - Fields: `node_id` (snake_case, unique), `display_name`, `research_cost` (**not** `rp_cost`), `prerequisite_ids[]` (array of `node_id` strings), `description`

2. **Add to ResearchManager** — append to the `research_nodes` export array in `main.tscn`.

3. **If it unlocks a building**, set the building's `is_locked = true` and `unlock_research_id = "my_node"` in the `.tres`. `ResearchManager._unlock_building_for_node()` automatically clears `is_locked` on the matching `BuildingData` in HexGrid.

4. **Prerequisite chain** — reference other nodes' `node_id` strings. `ResearchManager.can_unlock()` checks all prerequisites are satisfied before allowing unlock.

5. **Cost scaling** — `_effective_research_cost()` multiplies `research_cost` by `GameManager.get_aggregate_research_cost_multiplier()` (from territory bonuses).

6. **Update docs**: Add to research tree section, update INDEX files.

---

## 29. Conventions and Rules for LLM Agents

These rules apply to **every** future Cursor session. See also repo-root **`AGENTS.md`**.

1. **Never add logic to SignalBus.** Pure signal hub. No state, no methods beyond signal declarations.
2. **CampaignManager must be registered before GameManager** in `project.godot` init order.
3. **Field name discipline:** `gold_cost`, `target_priority`, `research_cost`, `weapon_slot`, `damage`. See [Section 32](#32-field-name-discipline--correct-vs-wrong-names).
4. **`Types.gd` is the single source of truth for all enums.** If not in `types.gd`, it does not exist.
5. **All new signals go in `signal_bus.gd`** with full typed parameters.
6. **All new persistent data resources** go under `res://resources/` in an appropriate subdirectory.
7. **All new GdUnit4 tests** go under `res://tests/unit/` following `test_{system_name}.gd`.
8. **`FlorenceData` is not an autoload** — it is a Resource loaded by `SaveManager`/`GameManager`.
9. **SimBot must remain headless-safe** — no UI node dependencies.
10. **`push_warning` not `push_error`** for missing optional nodes in `GameManager`.
11. **`get_node_or_null()` for runtime lookups** — never bare `get_node()`.
12. **`is_instance_valid()` before accessing freed nodes** — enemies, projectiles, allies can be freed mid-frame.
13. **Static typing everywhere.**
14. **`_physics_process` for game logic; `_process` for visual/UI only.**
15. **Scene instantiation via `initialize()`** — never set properties after `add_child()`.
16. **This document must be updated** in the same session as implementation changes.

### Document Update Checklist

- [ ] Move feature from "planned" to "exists" (or vice versa if cut).
- [ ] Add correct field names to [Section 32](#32-field-name-discipline--correct-vs-wrong-names).
- [ ] Add new signals to [Section 24](#24-signal-bus-reference).
- [ ] Add a changelog entry at the top.
- [ ] Update `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`.

---

## 30. Anti-Patterns — Code-Level Mistakes to Avoid

### 30.1 SignalBus Violations

**WRONG — Adding logic to SignalBus:**
```gdscript
# signal_bus.gd — NEVER DO THIS
signal enemy_killed(...)
var kill_count: int = 0  # NO STATE IN SIGNALBUS
func _on_enemy_killed(...):  # NO METHODS IN SIGNALBUS
    kill_count += 1
```

**RIGHT:** SignalBus is declarations only. Logic goes in the consuming system.

### 30.2 Bare get_node() Without Null Guard

**WRONG:**
```gdscript
var wm: WaveManager = get_node("/root/Main/Managers/WaveManager")
wm.start_wave_sequence()  # Crashes in headless/test if Main is absent
```

**RIGHT:**
```gdscript
var wm: WaveManager = get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager
if wm == null:
    push_warning("WaveManager not found; skipping wave sequence")
    return
wm.start_wave_sequence()
```

### 30.3 Accessing Freed Nodes

**WRONG:**
```gdscript
var target: EnemyBase = _current_target
target.take_damage(10.0, Types.DamageType.PHYSICAL)  # CRASH if freed mid-frame
```

**RIGHT:**
```gdscript
if not is_instance_valid(_current_target):
    _current_target = null
    return
_current_target.take_damage(10.0, Types.DamageType.PHYSICAL)
```

### 30.4 Using assert() in Production Code

**WRONG:**
```gdscript
assert(building_data != null, "BuildingData must not be null")  # Crashes headless builds
```

**RIGHT:**
```gdscript
if building_data == null:
    push_warning("BuildingBase: building_data is null")
    return
```

### 30.5 Direct Method Calls Between Unrelated Autoloads for Events

**WRONG:**
```gdscript
# In EconomyManager:
func _on_enemy_died():
    CampaignManager.increment_kill_count()  # Cross-autoload direct call for events
```

**RIGHT:**
```gdscript
# Events go through SignalBus:
SignalBus.enemy_killed.connect(_on_enemy_killed)
func _on_enemy_killed(et: Types.EnemyType, pos: Vector3, gold: int) -> void:
    add_gold(gold)
```

### 30.6 Wrong Field Names on Resources

**WRONG:**
```gdscript
var cost: int = building_data.build_gold_cost  # DOES NOT EXIST
var priority = building_data.targeting_priority  # DOES NOT EXIST
var rp: int = research_data.rp_cost  # DOES NOT EXIST
```

**RIGHT:**
```gdscript
var cost: int = building_data.gold_cost
var priority: Types.TargetPriority = building_data.target_priority
var rp: int = research_data.research_cost
```

### 30.7 Untyped Variables and Parameters

**WRONG:**
```gdscript
func process_enemy(enemy, damage, type):
    var result = enemy.take_damage(damage, type)
```

**RIGHT:**
```gdscript
func process_enemy(enemy: EnemyBase, damage: float, type: Types.DamageType) -> void:
    enemy.take_damage(damage, type)
```

### 30.8 Using _process for Game Logic

**WRONG:**
```gdscript
func _process(delta: float) -> void:
    _attack_timer -= delta  # Game logic in _process
    if _attack_timer <= 0.0:
        _fire_projectile()
```

**RIGHT:**
```gdscript
func _physics_process(delta: float) -> void:
    _attack_timer -= delta
    if _attack_timer <= 0.0:
        _fire_projectile()
```

### 30.9 Setting Properties After add_child()

**WRONG:**
```gdscript
var building: BuildingBase = BuildingScene.instantiate()
_building_container.add_child(building)
building.initialize(building_data)  # Too late — _ready() already ran without data
```

**RIGHT:**
```gdscript
var building: BuildingBase = BuildingScene.instantiate()
building.initialize(building_data)  # Set up before _ready()
_building_container.add_child(building)
# OR call initialize() immediately after add_child() if designed for it
```

### 30.10 Adding class_name to SaveManager or RelationshipManager

**WRONG:**
```gdscript
class_name SaveManager  # Causes GdUnit shadowing of the autoload singleton
```

**RIGHT:** These are autoload-only singletons — no `class_name`. Access by autoload name only.

### 30.11 Printing to stdout in MCP Bridge Scripts

**WRONG:**
```gdscript
print("Debug: processing tool call")  # Breaks GDAI MCP JSON-RPC on stdout
```

**RIGHT:** Debug logs go to **stderr** only (`push_warning`, `printerr`). Only JSON-RPC uses stdout.

### 30.12 Connecting Signals Without is_connected Guard

**WRONG:**
```gdscript
func _ready() -> void:
    SignalBus.enemy_killed.connect(_on_enemy_killed)
    # Double-connect if _ready() runs twice or node re-enters tree
```

**RIGHT:**
```gdscript
func _ready() -> void:
    if not SignalBus.enemy_killed.is_connected(_on_enemy_killed):
        SignalBus.enemy_killed.connect(_on_enemy_killed)
```

### 30.13 Hardcoding Game Stats in GDScript

**WRONG:**
```gdscript
const ARROW_TOWER_DAMAGE: float = 50.0  # Stats belong in .tres
const ORC_GRUNT_HP: int = 100
```

**RIGHT:** All gameplay tuning lives in `.tres` resource files or named constants in `types.gd`. Load via `BuildingData`, `EnemyData`, etc.

### 30.14 Using Godot 3 Syntax

**WRONG:**
```gdscript
onready var x = $Node          # Godot 3
export var speed: float        # Godot 3
connect("signal", self, "fn")  # Godot 3
emit_signal("done")            # Godot 3
yield(timer, "timeout")        # Godot 3
```

**RIGHT (Godot 4.4):**
```gdscript
@onready var x: Node = $Node
@export var speed: float
signal_ref.connect(callable)
signal_ref.emit()
await timer.timeout
```

### 30.15 Adding `class_name` to C# Scripts That Shadow Autoload Names

**WRONG:**

```csharp
// DamageCalculator.cs — NEVER
public partial class DamageCalculator : Node
{
    // class_name-equivalent in C# can shadow the autoload singleton in tests/tools
}
```

**RIGHT:** Do not declare a `class_name`-style global name on C# types that duplicate autoload singleton names. Access the autoload by its registered name (`DamageCalculator`, `SavePayload`, etc.) from GDScript and from C# via the Godot autoload API.

---

## 31. Formally Cut Features — Never Implement

| Feature | Status | Notes |
|---------|--------|-------|
| Arnulf drunkenness system | **FORMALLY CUT** | No enum, no state. Never implement. |
| Time Stop spell | **FORMALLY CUT** | Too complex. Never implement. |
| Hades-style 3D navigable hub | **FORMALLY CUT** | Replaced by TAUR-style functional screens. |

---

## 32. Field Name Discipline — Correct vs Wrong Names

### Wrong Names (DO NOT USE)

| Wrong Name | Correct Name | Context |
|------------|-------------|---------|
| `build_gold_cost` | `gold_cost` | BuildingData |
| `targeting_priority` | `target_priority` | BuildingData |
| `rp_cost` | `research_cost` | ResearchData |
| `weapon_id` | `weapon_slot` | WeaponData |
| `base_damage_min` / `base_damage_max` | `damage` (single float) | WeaponData |

### Non-Existent Enums/Types (DO NOT ASSUME)

| Non-existent | Notes |
|-------------|-------|
| `Types.SpellType` / `Types.SpellID` | Do not exist in `types.gd` |

### Features That Do Not Exist Yet

| Feature | Status | Cross-Reference |
|---------|--------|----------------|
| Chronicle / meta-progression system | Planned | [Section 14](#14-meta-progression-the-chronicle-of-foul-ward) |
| Ring rotation UI | Planned | [Section 8](#8-buildings) |
| Sybil passive selection | Planned | [Section 2.2](#22-ai-companions) |
| Star difficulty system | Planned | [Section 13](#13-campaign-and-progression) |
| Leaderboards | Optional future | [Section 13](#13-campaign-and-progression) |
| Shop inventory rotation | Deferred | [Section 19](#19-shop) |
| Hand-drawn world map art | Art direction confirmed | [Section 16](#16-world-map) |
| Hub keeper portrait art | All `TODO(ART)` placeholders | [Section 15](#15-hub-screens) |
| Any dialogue content | All 15 entries are `TODO` placeholders | [Section 17](#17-dialogue-system) |
| Mid-battle dialogue | Planned | [Section 15](#15-hub-screens) |

---

## 33. Open TBD Items

| Item | Question | Who Decides |
|------|----------|-------------|
| Sybil passive selection | Single pick before mission OR all passives always active? | Designer |
| Hub keeper dialogue trigger | Auto-triggers OR requires "Talk" button click? | Designer |
| Chronicle perk strength | Cosmetic micro-buffs vs meaningful advantage? | Designer/playtester |
| Shop rotation count | How many items shown per day? | Designer |
| Leaderboard backend | LootLocker, Supabase, or custom? | Developer |
| Star difficulty multipliers | Exact HP/damage/gold multipliers for Veteran and Nightmare | Designer/playtester |

---
 
## 34. Related Documents

| Document | Purpose |
|----------|---------|
| `AGENTS.md` (repo root) | Standing orders for every LLM session — **read first** (MCP habits; expands on [§1.1](#11-cursor-mcp-and-agent-toolchain)) |
| `docs/CONVENTIONS.md` | Naming, typing, and style rules (LAW) |
| `docs/INDEX_SHORT.md` | Compact one-liner per file index |
| `docs/INDEX_FULL.md` | Full public API reference |
| `docs/SUMMARY_VERIFICATION.md` | Three-part read-only codebase audit results |
| `docs/archived/OPUS_ALL_ACTIONS.md` | Archived consolidated snapshot + improvement backlog (historical) |
| `docs/IMPROVEMENTS_TO_BE_DONE.md` | 78-issue backlog |
| `FUTURE_3D_MODELS_PLAN.md` | Production 3D art roadmap |
| `.cursorrules` | Workspace rules for Cursor agent behavior |
| `.cursor/rules/mcp-godot-workflow.mdc` | MCP server usage rules |
| `FoulWard.csproj` | C# project file — `dotnet build` before GdUnit when `.cs` changes |
| `CREDITS.md` (repo root) | Third-party / technique credits for C# modules |
| `docs/PROMPT_[N]_IMPLEMENTATION.md` (new) · `docs/archived/PROMPT_*_IMPLEMENTATION.md` (history) | Per-session implementation logs |
