# FOUL WARD — MASTER DOCUMENTATION

> **Living document.** Updated every time a system is added, changed, or formally cut.
> Readable by both **human developers** and **LLM agents** (Cursor, Perplexity, or otherwise).
> Every section distinguishes between **EXISTS IN CODE** and **PLANNED / NOT YET IMPLEMENTED**.
> **Target reader:** An LLM agent given only this document, a task, and access to the codebase.

---

## Changelog

Rows that cite historical SignalBus totals (e.g. **67**, **72**, **73**, **76**) are **intentional snapshots** from the day that feature landed; the current canonical total is **77** (see `AGENTS.md` and `autoloads/signal_bus.gd`).

| Date | Author | Summary |
|------|--------|---------|
| 2026-04-20 | Cursor agent | Documentation sweep: `INDEX_SHORT` / `INDEX_FULL`, `HOW_IT_WORKS`, `INTERVIEW_CHEATSHEET`, `AGENTS.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`, `SUMMARY_VERIFICATION.md`, `docs/README.md` — metrics and file-tree refs; gen3d canonical path **`res://tools/gen3d/`** (versioned); §22 art pipeline updated (no longer references an off-repo `gen3d/` tree); `art/gen3d_candidates/`, `art/gen3d_previews/`, `orc_berserker.glb` noted; rolling session logs **`PROMPT_80`…`PROMPT_89`** in `docs/`; `find … PROMPT_*_IMPLEMENTATION.md` → **90** files. |
| 2026-04-19 | Cursor agent | Prompts 77–83: gen3d automated asset pipeline (`foulward_gen.py`, stages 1–5: ComfyUI FLUX → TRELLIS.2 mesh → Blender rig → Mixamo anim → Godot drop); `.cursor/skills/gen3d/SKILL.md`; ComfyUI LoRA workflow (`turnaround_flux.json`); TRELLIS.2 `transformers==4.56.0` pin; BiRefNet `.float()` workaround; `stage2_mesh.py` `guidance_strength` fix; orc_grunt.glb pipeline e2e pass. Signal count **77** unchanged; test count **665** (parallel, 2026-04-19). |
| 2026-04-18 | Cursor agent | Group 11 reconciliation: `Types.DifficultyTier` + `DifficultyTierData` + `resources/difficulty/tier_*.tres`; `TerritoryData` tier/star fields; `GameManager` `_load_tier_data`, `set_active_tier` / `get_active_tier`, `_apply_tier_to_day_config`, `_handle_tier_cleared`, save payload `territories` tier keys; tests `test_difficulty_tier_system.gd` (17); GdUnit harness: `monitor_signals(SignalBus, false)` in tier + building HP tests. Signal count **77** unchanged. |
| 2026-04-18 | Cursor agent | Group 9 (S05) hub dialogue content (30 `.tres` × 6 NPCs), `DialogueEntry.is_combat_line`, combat condition keys + `request_combat_line`, SignalBus `combat_dialogue_requested` (**77** signals), `CombatDialogueBanner` under `UI/UIManager`, hub `TalkButton` visibility via `peek_entry_for_character`; tests +12 (`test_dialogue_content.gd`, `test_combat_dialogue.gd`); `run_gdunit_quick.sh` allowlist. |
| 2026-04-18 | Cursor agent | Group 8 Chronicle meta-progression: `ChronicleManager` autoload **#15**, `ChronicleEntryData` / `ChroniclePerkData`, `resources/chronicle/**/*.tres`, SignalBus `chronicle_*` (**76** signals), `chronicle_screen.tscn`, main menu Chronicle; tests +11 (`test_chronicle_manager.gd`); `ring_rotation_screen.gd` `@onready` path fix. |
| 2026-04-18 | Cursor agent | Group 7 ring rotation: HexGrid **42** slots (ring 3 expanded), per-ring `rotate_ring(ring_index, angle_rad)`, `RING_ROTATE` game state, SignalBus `ring_rotated` (**73** signals), `ring_rotation_screen.tscn`, save payload `version` **2** + `SaveManager.is_hex_slot_index_in_save_range`; tests +13 (`test_ring_rotation.gd`). |
| 2026-04-18 | Cursor agent | Sybil passive system: `SybilPassiveManager` autoload #14, `PASSIVE_SELECT` game state, `resources/passive_data/*.tres`, SignalBus `sybil_passives_offered` / `sybil_passive_selected` (**72** signals); tests +11 (`test_sybil_passive_manager.gd`); save key `sybil`. |
| 2026-04-14 | Cursor agent | SignalBus **67** typed signals (as of this date) — same total in `AGENTS.md`, §3.1, §24, `CONVENTIONS.md`, `ARCHITECTURE.md`, indexes, `.cursor/skills/signal-bus/` (see skill § *Signal count in documentation*). |
| 2026-04-18 | Cursor agent | G1 S01: campaign content tests +11 (`test_campaign_config.gd`); test total 623; reconciliation tracker G1 row filled. |
| 2026-04-14 | Cursor agent | Batch verification doc sync: dialogue line signals on SignalBus (§3.14, §24 Dialogue); `AllyRole` four values / TANK removed (§5); test baseline 612 GdUnit4 (§1, §23); main campaign path `res://resources/campaigns/campaign_main_50_days.tres` (canonical; legacy duplicate removed 2026-04-19). |
| 2026-04-14 | mcp-purge | Moved godot-mcp-pro and gdai-mcp-godot above repo root to ../foulward-mcp-servers/. |
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
| **Test count** | 665 GdUnit4 test cases (`./tools/run_gdunit_parallel.sh` aggregate, 2026-04-19; see `docs/archived/prompts/PROMPT_76_IMPLEMENTATION.md`) |

### Primary Files of Record

| File | Purpose |
|------|---------|
| `docs/INDEX_SHORT.md` | Compact one-liner-per-file index |
| `docs/INDEX_FULL.md` | Full public API reference for every script, resource, and system |
| `AGENTS.md` (repo root) | Standing orders for every Cursor/LLM session — **read first** (MCP habits; expands on [§1.1](#11-cursor-mcp-and-agent-toolchain)) |
| `docs/CONVENTIONS.md` | Naming, typing, and style law |
| `docs/SUMMARY_VERIFICATION.md` | Three-part read-only audit results |
| `docs/archived/prompts/` | Full `PROMPT_*_IMPLEMENTATION.md` session-log archive (10 newest logs live under `docs/` only) |

### 1.1 Cursor, MCP, and agent toolchain

**STATUS: EXISTS IN REPO (configuration + docs)**

Cursor loads MCP servers from **`.cursor/mcp.json`**. There is no separate “auto session” product mode documented in this repo: any Cursor chat or agent run can use whatever MCP tools Cursor exposes, subject to the servers below being up and reachable.

| Server (name in `mcp.json`) | Role (one line) | Path / vendor |
|----------------------------|------------------|----------------|
| `godot-mcp-pro` | Editor integration over WebSocket (default port **6505**); needs Godot open with the **Godot MCP Pro** plugin enabled. | `../foulward-mcp-servers/godot-mcp-pro` (paid — outside repo) |
| `gdai-mcp-godot` | Python bridge to the editor’s **HTTP API** (default port **3571**); needs Godot open with **GDAI MCP** enabled; proxies to `addons/gdai-mcp-plugin-godot/`. | `../foulward-mcp-servers/gdai-mcp-godot` (paid — outside repo) |
| `sequential-thinking` | Step-by-step reasoning MCP; needs **`node`** and `npm install` under `tools/mcp-support` (see workflow rule file). | — |
| `filesystem-workspace` | Broader workspace filesystem access via MCP. | — |
| `github` | GitHub API; requires **`GITHUB_PERSONAL_ACCESS_TOKEN`** (never commit secrets). | — |
| `foulward-rag` | Project RAG (`query_project_knowledge`, etc.); **optional** — requires the RAG service under **`~/LLM`** to be running; agents must not block if it is down. | — |

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
**STATUS: EXISTS IN CODE (spell management + passive selection)**

- Role: Spell researcher / spell support.
- Manages the spell system via `SpellManager` (see [Section 7](#7-spells)).
- **Passive selection:** `SybilPassiveManager` loads `res://resources/passive_data/*.tres` (`SybilPassiveData`). After mission briefing, `GameManager.enter_passive_select()` enters `Types.GameState.PASSIVE_SELECT`; the player chooses one offered passive; `SpellManager` applies modifiers via `SybilPassiveManager.get_modifier(effect_type)`.

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

Central typed signal hub. **77** typed `signal` declarations as of **2026-04-20** (re-count `^signal ` in this file when changed). **No logic, no state. Never add logic here.**

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

**Save payload structure:** `{version, attempt_id, campaign: {}, game: {}, relationship: {}, research: {}, shop: {}, enchantments: {}, sybil: {}}`.

### 3.14 SybilPassiveManager (`res://autoloads/sybil_passive_manager.gd`) — Init #14

Loads `SybilPassiveData` resources from `res://resources/passive_data/`. Offers a random subset each mission (`OFFER_COUNT` = 4); emits `SignalBus.sybil_passives_offered`. `select_passive(passive_id)` sets the active passive and emits `sybil_passive_selected`. `get_modifier(effect_type)` returns the active passive's `effect_value` when types match.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `get_offered_passives() -> Array` | Array | Picks unlocked passives; emits `sybil_passives_offered` |
| `select_passive(passive_id: String) -> void` | void | Sets active passive |
| `get_modifier(effect_type: String) -> float` | float | Modifier for `SpellManager` / future systems |
| `get_save_data() -> Dictionary` | Dictionary | `active_passive_id` for SaveManager |
| `restore_from_save_data(data: Dictionary) -> void` | void | Restores without duplicate selection signal |

### 3.15 ChronicleManager (`res://autoloads/chronicle_manager.gd`) — Init #15

Meta-progression achievements and perks. Loads `ChronicleEntryData` from `res://resources/chronicle/entries/` and `ChroniclePerkData` from `res://resources/chronicle/perks/`; persists progress to `user://chronicle.json`. Listens on SignalBus for `enemy_killed`, `mission_won`, `building_placed`, `boss_killed`, `campaign_completed`, `resource_changed` (gold earned delta), and `research_unlocked` (mapped to research-completed entries). Emits `chronicle_entry_completed`, `chronicle_perk_activated`, `chronicle_progress_updated`. `apply_perks_at_mission_start()` runs after mission economy is applied (from `GameManager._begin_mission_wave_sequence`). Percentage perks stack via `get_chronicle_research_cost_multiplier()`, `get_chronicle_enchanting_cost_multiplier()`, `get_chronicle_gold_per_kill_percent_bonus()`, `get_chronicle_wave_reward_gold_flat()` consumed by `ResearchManager`, `EnchantmentManager`, `EconomyManager`.

| Signature | Returns | Usage |
|-----------|---------|-------|
| `apply_perks_at_mission_start() -> void` | void | Applies starting gold/mana/material and sell-refund multiplier from unlocked perks |
| `save_progress() -> void` / `load_progress() -> void` | void | JSON persistence |
| `reset_for_test() -> void` | void | Clears progress and active perks (tests) |
| `get_entry_ids_sorted() -> PackedStringArray` | PackedStringArray | UI: ordered entry ids |
| `get_entry_state(entry_id: String) -> Dictionary` | Dictionary | `{data, progress, completed, seen_boss_ids}` |
| `get_perk_display_name(perk_id: String) -> String` | String | UI label for a perk id |

### 3.16 DialogueManager (`res://autoloads/dialogue_manager.gd`) — Init #16

Loads `DialogueEntry` `.tres` from `res://resources/dialogue/**`. Priority, AND conditions, once-only, `chain_next_id`. Hub selection skips `is_combat_line`; combat lines use `request_combat_line()` (per-mission dedup via `_seen_combat_lines`). **Combat line filenames (canonical on disk):** under `res://resources/dialogue/combat/` — e.g. `combat_first_blood.tres`, `combat_wave_2.tres`, `combat_wave_3.tres`, `combat_wave_5.tres`, `combat_kill_10.tres`, `combat_kill_50.tres`, `combat_florence_hit.tres`, `combat_florence_hit_2.tres`, `combat_boss_appears.tres`, `combat_boss_killed.tres` (Perplexity examples used different wave/kill numbers; tests and content use this set).

| Signature | Returns | Usage |
|-----------|---------|-------|
| `peek_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry` | DialogueEntry | Same selection as `request_entry_for_character` but does **not** emit `dialogue_line_started` (Talk button visibility) |
| `request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry` | DialogueEntry | Highest-priority eligible hub entry (chains have priority) |
| `request_combat_line() -> DialogueEntry` | DialogueEntry | Highest-priority eligible combat line; emits `SignalBus.combat_dialogue_requested` |
| `get_entry_by_id(entry_id: String) -> DialogueEntry` | DialogueEntry | Direct lookup |
| `mark_entry_played(entry_id: String) -> void` | void | Marks once_only as played; activates chain |
| `notify_dialogue_finished(entry_id: String, character_id: String) -> void` | void | Emits `SignalBus.dialogue_line_finished`; clears chain |
| `on_campaign_day_started() -> void` | void | Syncs state from GameManager at day start |
| `get_tracked_gold() -> int` | int | Gold snapshot for conditions |
| `get_unlocked_research_ids_snapshot() -> Dictionary` | Dict | Research IDs tracked for conditions |
| `get_total_shop_purchases_tracked() -> int` | int | Total shop purchases |
| `get_arnulf_state_tracked() -> Types.ArnulfState` | ArnulfState | Arnulf state for conditions |
| `get_spell_cast_count_tracked() -> int` | int | Spell cast counter |

**Dialogue signals (SignalBus):** `dialogue_line_started`, `dialogue_line_finished`, and **`combat_dialogue_requested(entry: DialogueEntry)`** are **declared on `SignalBus`** (see [Section 24](#24-signal-bus-reference), Dialogue subsection). `DialogueManager` emits hub line events via `SignalBus.dialogue_line_started.emit(...)` / `SignalBus.dialogue_line_finished.emit(...)` and combat selection via `SignalBus.combat_dialogue_requested.emit(...)` — they are not local signals on DialogueManager.

**Condition keys:** `current_mission_number`, `mission_won_count`, `gold_amount`, `sybil_research_unlocked_any`, `arnulf_research_unlocked_any`, `research_unlocked_<id>`, `shop_item_purchased_<id>`, `arnulf_is_downed`, `florence.*`, `campaign.*`, combat: `first_blood`, `wave_number_gte`, `kills_this_mission_gte`, `boss_active`, `florence_damaged`.

### 3.17 AutoTestDriver (`res://autoloads/auto_test_driver.gd`) — Init #17

Headless smoke-test driver. Active on `--autotest`, `--simbot_profile`, or `--simbot_balance_sweep`.

### 3.18 GDAIMCPRuntime — Init #18

GDAI MCP GDExtension bridge (editor only). Cursor agents reach it via the **`gdai-mcp-godot`** MCP server when Godot is running; see [§1.1](#11-cursor-mcp-and-agent-toolchain).

### 3.19 EnchantmentManager (`res://autoloads/enchantment_manager.gd`) — Init #19

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
| `get_daily_items(day_index: int) -> Array[ShopItemData]` | Array | Daily rotation: 4–6 items, RNG seeded by `day_index`; excludes capped consumables; guarantees ≥1 consumable + ≥1 equipment |
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
| PASSIVE_SELECT | 11 |
| RING_ROTATE | 12 |

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

### DifficultyTier
**EXISTS IN CODE** — `resources/difficulty/tier_*.tres` + `GameManager.set_active_tier()` / `get_active_tier()`.

| Name | Value |
|------|-------|
| NORMAL | 0 |
| VETERAN | 1 |
| NIGHTMARE | 2 |

### ChronicleRewardType
**EXISTS IN CODE** — used by `ChronicleEntryData`.

| Name | Value |
|------|-------|
| PERK | 0 |
| COSMETIC | 1 |
| TITLE | 2 |

### ChroniclePerkEffectType
**EXISTS IN CODE** — used by `ChroniclePerkData`; consumed by `ChronicleManager.apply_perks_at_mission_start()`.

| Name | Value |
|------|-------|
| STARTING_GOLD | 0 |
| STARTING_MANA | 1 |
| SELL_REFUND_PCT | 2 |
| RESEARCH_COST_PCT | 3 |
| GOLD_PER_KILL_PCT | 4 |
| BUILDING_MATERIAL_START | 5 |
| ENCHANTING_COST_PCT | 6 |
| WAVE_REWARD_GOLD | 7 |
| XP_GAIN_PCT | 8 |
| COSMETIC_SKIN | 9 |

### Other Enums (stable, rarely referenced directly)

`AllyRole` (0–3: `MELEE_FRONTLINE`, `RANGED_SUPPORT`, `ANTI_AIR`, `SPELL_SUPPORT` — `TANK` was removed), `StrategyProfile` (0–4), `BuildingBaseMesh` (0–3), `BuildingTopMesh` (0–6), `DayAdvanceReason` (0–2), `UnitSize` (0–3), `AllyAiMode` (0–4), `AuraModifierKind` (0–2), `AuraModifierOp` (0–1), `AuraCategory` (0–3), `AuraStat` (0–5), `MissionBalanceStatus` (0–3), `GraphicsQuality` (0–3: `LOW`, `MEDIUM`, `HIGH`, `CUSTOM`).

**Non-existent enum: `Types.SpellType` / `Types.SpellID` — do NOT use or assume.**

---

## 6. Game States

**STATUS: EXISTS IN CODE** — Defined in `res://scripts/types.gd` as `Types.GameState` (see [Section 5](#5-typesgd--full-enum-to-integer-mapping)).

**Transition graph:** `MAIN_MENU → MISSION_BRIEFING → PASSIVE_SELECT → RING_ROTATE → COMBAT ↔ BUILD_MODE → WAVE_COUNTDOWN → (COMBAT loop) → MISSION_WON/MISSION_FAILED → BETWEEN_MISSIONS → MISSION_BRIEFING...`

**`RING_ROTATE` EXISTS IN CODE:** `GameManager.enter_ring_rotate()` / `exit_ring_rotate()` (called after PASSIVE_SELECT). UI scene: `scenes/ui/ring_rotation_screen.tscn`. `HexGrid` exposes `rotate_ring(ring_index: int, angle_rad: float) -> void`.

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
**EXISTS:** `rotate_ring(ring_index: int, angle_rad: float)` in `HexGrid` (42 slots, 3 rings). `RING_ROTATE` game state, `ring_rotation_screen.tscn`, save payload `version` **2** with `SaveManager.is_hex_slot_index_in_save_range`. `GameManager.enter_ring_rotate()` / `exit_ring_rotate()` handle the state transition. Tests: `test_ring_rotation.gd` (+13 cases).

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
- 50 days main campaign (`res://resources/campaigns/campaign_main_50_days.tres` — `GameManager.MAIN_CAMPAIGN_CONFIG_PATH`), 5 days short (`campaign_short_5days.tres`).
- Each mission = 5 waves (`WAVES_PER_MISSION`).
- After Day 50 final boss: loop continues until player wins or tower destroyed.

### Endless Mode
**PARTIALLY EXISTS:** `CampaignManager.is_endless_mode`, `start_endless_run()`, synthetic day scaling.

### Star Difficulty System
**EXISTS IN CODE (backend; UI pending).** `Types.DifficultyTier` (NORMAL / VETERAN / NIGHTMARE), `DifficultyTierData` resource, `resources/difficulty/tier_normal.tres`, `tier_veteran.tres`, `tier_nightmare.tres`. `GameManager.set_active_tier()` / `get_active_tier()` / `_apply_tier_to_day_config()` / `_handle_tier_cleared()`. `TerritoryData` stores `highest_cleared_tier`. Tests: `test_difficulty_tier_system.gd` (17 cases). Per-map star selector UI is not yet wired.

---

## 14. Meta-Progression: The Chronicle of Foul Ward

**EXISTS IN CODE:** `ChronicleManager` autoload (Init #15), resources `ChronicleData` / `ChronicleEntryData` / `ChroniclePerkData`, data under `res://resources/chronicle/`, UI `scenes/ui/chronicle_screen.tscn`, main menu **Chronicle** button. SignalBus: `chronicle_entry_completed`, `chronicle_perk_activated`, `chronicle_progress_updated`. Types: `Types.ChronicleRewardType`, `Types.ChroniclePerkEffectType` (mirrored in `FoulWardTypes.cs`).

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

**PLACEHOLDER SYSTEM EXISTS; AUTOMATED GLB PIPELINE EXISTS (local, off-repo)**

`ArtPlaceholderHelper`, `RiggedVisualWiring`, `PlaceholderIconGenerator`. All combat/hub scenes marked `# TODO(ART)` for final production art.

### Gen3D Automated Asset Pipeline

**EXISTS** — orchestration and Python stages are **in this repository** under `res://tools/gen3d/` (`foulward_gen.py`, `pipeline/stage1_image.py` … `stage5_drop.py`, `promote_candidate.py`, `generate_all.sh`, `workflows/`, `requirements.txt`). **Still external** (not vendored): a local ComfyUI install, a TRELLIS.2-capable Python environment, Blender, and Mixamo — see `.cursor/skills/gen3d/SKILL.md`.

| Stage | Script | Tool | Purpose |
|-------|--------|------|---------|
| 1 | `tools/gen3d/pipeline/stage1_image.py` | ComfyUI + FLUX.1-dev + LoRAs | Generate turnaround-sheet reference PNGs |
| 2 | `tools/gen3d/pipeline/stage2_mesh.py` | TRELLIS.2 (`trellis2` conda env) | PNG → 3D mesh → GLB |
| 3 | `tools/gen3d/pipeline/stage3_rig.py` | Blender (headless) | Auto-rig GLB (Rigify / Auto-Rig Pro) |
| 4 | `tools/gen3d/pipeline/stage4_anim.py` | Mixamo automation | Upload FBX → download animated FBX |
| 5 | `tools/gen3d/pipeline/stage5_drop.py` | — | Drop final GLB to `res://art/generated/<category>/<slug>.glb` |

**Intermediate / review paths (working tree, not committed):** `art/gen3d_candidates/{slug}/`, `art/gen3d_previews/` — same policy as `art/generated/`: **gitignored** until production picks; see `docs/GEN3D_LOCAL_ARTIFACTS.md`.

**Large scratch (working tree, not committed):** `local/gen3d/` — staging PNGs/GLBs, optional A/B harness output, ComfyUI logs. `foulward_gen.py` writes pipeline scratch under `local/gen3d/staging/`.

**GLB output path (runtime; not in Git):** `art/generated/{enemies,allies,buildings,bosses}/{slug}.glb` (flat, auto-imported by Godot when present locally).

**Generated assets (representative; as of 2026-04-20):**
- Enemies: `orc_grunt.glb`, `orc_brute.glb`, `orc_berserker.glb`, `orc_archer.glb`, `bat_swarm.glb`, `goblin_firebug.glb`, `plague_zombie.glb`, `orc_warboss.glb`, `herald_of_worms.glb`
- Allies: `arnulf.glb`, `arnulf_the_warrior.glb`, `florence_the_plague_doctor.glb`, `sybil_the_witch.glb`

**Key env vars / tools:** `HF_TOKEN` (FLUX.1-dev gated), `MIXAMO_EMAIL`/`MIXAMO_PASSWORD`, `FOULWARD_GEN3D_WORKFLOW` (alternate ComfyUI workflow), `FOULWARD_GEN3D_STAGE2_MODE=input_file` (skip Stage 1). `tools/gen3d/setup_comfyui_flux_symlinks.sh` sets up ComfyUI model symlinks.

**TRELLIS.2 environment note:** Requires `transformers==4.56.0` (pin; 5.x breaks DINOv3). Requires `pipeline.rembg_model.model.float()` BiRefNet workaround.

**Skill:** `.cursor/skills/gen3d/SKILL.md` — full install checklist, troubleshooting, new-character procedure, Cursor prompt template.

---

## 23. SimBot and Testing

- `SimBot` — headless simulation: `run_balance_sweep`, `run_batch`, `run_single`.
- Loadouts: `balanced`, `summoner_heavy`, `artillery_air`.
- `CombatStatsTracker` writes wave/building CSVs (under `user://simbot/…` for SimBot runs); balance tooling includes `tools/simbot_balance_report.py` and related scripts (see repo and repo-root `AGENTS.md` test commands).

**Headless automation (not GdUnit):** `AutoTestDriver` activates when the project is run with CLI user args such as `--autotest`, `--simbot_profile=…`, or `--simbot_balance_sweep` (see `autoloads/auto_test_driver.gd`). That path boots the real game flow and drives `SimBot`, so **economy, waves, and combat stats behave like a mission** — useful for sweeps and integration-style balance checks. It is **not** a substitute for **GdUnit** unit/integration tests (`./tools/run_gdunit*.sh`), which assert specific APIs and run without full interactive mission requirements.

- **665 GdUnit4 test cases** (parallel runner aggregate, 2026-04-19; repo-root **`AGENTS.md`**; sequential `./tools/run_gdunit.sh` may exit early with engine segfault — prefer parallel totals for “cases run”).
- Quick: `./tools/run_gdunit_quick.sh`, Unit (~65s): `./tools/run_gdunit_unit.sh`, Parallel (~2m45s): `./tools/run_gdunit_parallel.sh`, Sequential: `./tools/run_gdunit.sh`.

---

## 24. Signal Bus Reference

**STATUS: EXISTS IN CODE** — **77** signals declared in `res://autoloads/signal_bus.gd` as of **2026-04-20** (verified by `grep -c '^signal '`). Keep the hero-line total in sync across repo docs — see `.cursor/skills/signal-bus/SKILL.md` § *Signal count in documentation*.

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
| `territory_tier_cleared` | `territory_id: String, tier: int` |
| `territory_selected_for_replay` | `territory_id: String` |

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

### Dialogue

| Signal | Parameters |
|--------|-----------|
| `dialogue_line_started` | `entry_id: String, character_id: String` |
| `dialogue_line_finished` | `entry_id: String, character_id: String` |
| `combat_dialogue_requested` | `entry: DialogueEntry` |

Declared on `SignalBus`; `dialogue_line_*` emitted by `DialogueManager` when a hub line starts / when `notify_dialogue_finished` runs. `combat_dialogue_requested` emitted when `request_combat_line()` selects a combat banner line. UI (e.g. `UIManager`, `CombatDialogueBanner`) connects to `SignalBus`, not to DialogueManager local signals.

### Build Mode

| Signal | Parameters |
|--------|-----------|
| `build_mode_entered` | (none) |
| `build_mode_exited` | (none) |
| `build_phase_started` | (none) |
| `combat_phase_started` | (none) |

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

### Sybil Passive

| Signal | Parameters |
|--------|-----------|
| `sybil_passive_selected` | `passive_id: String` |
| `sybil_passives_offered` | `passive_ids: Array` |

Note: `sybil_passive_selected` is declared **before** `sybil_passives_offered` in `signal_bus.gd` (Perplexity spec parity). Both emitted by `SybilPassiveManager`.

### Ring Rotation

| Signal | Parameters |
|--------|-----------|
| `ring_rotated` | `ring_index: int, angle_rad: float` |

Emitted by `HexGrid.rotate_ring()` when a ring is rotated. Consumed by ring rotation UI and save system.

### Chronicle / Meta-Progression

| Signal | Parameters |
|--------|-----------|
| `chronicle_entry_completed` | `entry_id: String` |
| `chronicle_perk_activated` | `perk_id: String` |
| `chronicle_progress_updated` | `entry_id: String, current: int, target: int` |

Emitted by `ChronicleManager`. `chronicle_entry_completed` fires when a tracked goal threshold is crossed. `chronicle_perk_activated` fires when a perk from a completed entry is applied. `chronicle_progress_updated` fires on every tracked event to drive UI progress bars.

### Settings

| Signal | Parameters |
|--------|-----------|
| `graphics_quality_changed` | `quality: int` |

Emitted by `SettingsManager.set_graphics_quality()`. Payload is `int(Types.GraphicsQuality)`. UI connects to this to refresh quality indicators.

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

5. **Update the SignalBus signal total** in prose everywhere (hero line in §3.1 and §24 intro, `AGENTS.md`, `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `INDEX_SHORT.md` / `INDEX_FULL.md`, `.cursor/skills/signal-bus/references/signal-table.md`, and any other file listed in `.cursor/skills/signal-bus/SKILL.md` § *Signal count in documentation*). Re-verify with a line count of `^signal ` in `signal_bus.gd`.

6. **If RelationshipManager should react**, create `res://resources/relationship_events/my_event.tres` with `signal_name = "my_event_happened"` and `character_deltas`.

7. **In tests**, if you emit the signal using the real autoload, reset state in `after_test()`.

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
- [ ] If the number of `signal` lines in `signal_bus.gd` changed, update the **exact total** and **as-of date** in every file listed in `.cursor/skills/signal-bus/SKILL.md` § *Signal count in documentation*.
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

### Feature Status Tracker

| Feature | Status | Cross-Reference |
|---------|--------|----------------|
| Chronicle / meta-progression system | **EXISTS** | [Section 14](#14-meta-progression-the-chronicle-of-foul-ward) |
| Ring rotation (`RING_ROTATE` state + `ring_rotation_screen.tscn`) | **EXISTS** | [Section 8](#8-buildings), [Section 6](#6-game-states) |
| Sybil passive selection (`SybilPassiveManager`, `passive_select_screen.tscn`) | **EXISTS (backend + screen)** | [Section 2.2](#22-ai-companions) |
| Star difficulty system (backend: `DifficultyTier` + resources + GameManager) | Backend **EXISTS**; per-map selector UI pending | [Section 13](#13-campaign-and-progression) |
| Mid-battle / combat dialogue (`CombatDialogueBanner`, `request_combat_line`) | **EXISTS** | [Section 17](#17-dialogue-system) |
| Gen3D asset pipeline (ComfyUI/TRELLIS.2/Blender, off-repo at `../gen3d/`) | **EXISTS (off-repo)** | [Section 22](#22-art-pipeline) |
| Leaderboards | Optional future | [Section 13](#13-campaign-and-progression) |
| Shop inventory rotation | Deferred | [Section 19](#19-shop) |
| Hand-drawn world map art | Art direction confirmed; production pending | [Section 16](#16-world-map) |
| Hub keeper portrait art | All `TODO(ART)` placeholders | [Section 15](#15-hub-screens) |
| Hub dialogue content | All entries are `TODO` placeholder text | [Section 17](#17-dialogue-system) |

---

## 33. Open TBD Items

| Item | Question | Who Decides |
|------|----------|-------------|
| Sybil passive selection (resolved: single pick before mission) | Backend exists; screen exists. Confirm UX flow and apply modifiers in SpellManager. | Designer |
| Hub keeper dialogue trigger | Auto-triggers on approach OR requires "Talk" button click? | Designer |
| Chronicle perk strength | Cosmetic micro-buffs vs meaningful advantage? | Designer/playtester |
| Shop rotation count | How many items shown per day? | Designer |
| Leaderboard backend | LootLocker, Supabase, or custom? | Developer |
| Star difficulty multipliers | Exact HP/damage/gold multipliers for Veteran and Nightmare; per-map selector UI not yet wired | Designer/playtester |
| WorldEnvironment path | `_find_world_environment()` in `SettingsManager` assumes `/root/Main/WorldEnvironment` — no `WorldEnvironment` node confirmed in repo; adjust path once node is added to scene | Developer |
| Gen3D Stage 3 (Mixamo rigging) | `MixamoBot` unavailable locally; Arnulf GLB has 0 animations. Need Mixamo credentials or alternative rigging solution. | Developer |
| Gen3D ComfyUI Stage 1 black images | `turnaround_flux_no_loras.json` produces black output; investigate FLUX positive prompt wiring vs `CLIPTextEncodeFlux` node. | Developer |

---
 
## 34. Related Documents

| Document | Purpose |
|----------|---------|
| `AGENTS.md` (repo root) | Standing orders for every LLM session — **read first** (MCP habits; expands on [§1.1](#11-cursor-mcp-and-agent-toolchain)) |
| `docs/CONVENTIONS.md` | Naming, typing, and style rules (LAW) |
| `docs/INDEX_SHORT.md` | Compact one-liner per file index |
| `docs/INDEX_FULL.md` | Full public API reference |
| `docs/SUMMARY_VERIFICATION.md` | Three-part read-only codebase audit results |
| `docs/archived/prompts/` | Full `PROMPT_*_IMPLEMENTATION.md` session-log history (rolling window: 10 newest under `docs/`) |
| `docs/FUTURE_3D_MODELS_PLAN.md` | Production 3D art roadmap |
| `tools/gen3d/foulward_gen.py` | Gen3D pipeline orchestrator — 5-stage ComfyUI/TRELLIS.2/Blender pipeline |
| `.cursor/skills/gen3d/SKILL.md` | Gen3D agent skill — install, add-character procedure, Cursor prompt template |
| `.cursorrules` | Workspace rules for Cursor agent behavior |
| `.cursor/rules/mcp-godot-workflow.mdc` | MCP server usage rules |
| `FoulWard.csproj` | C# project file — `dotnet build` before GdUnit when `.cs` changes |
| `CREDITS.md` (repo root) | Third-party / technique credits for C# modules |
| `docs/PROMPT_[N]_IMPLEMENTATION.md` (10-file rolling window) · `docs/archived/prompts/PROMPT_*_IMPLEMENTATION.md` (full history) | Per-session implementation logs |

---

## SECTION 31 — FRAMEWORK EVOLUTION PLAN

> Appended **2026-04-27** as a strategic forward-plan addendum.
> This section sits **after** the existing numbered §1-§34 and intentionally re-uses the
> "SECTION 31" heading per the planning brief — it does not replace §31 *Formally Cut
> Features*. Subsections below are numbered 31.1-31.11 to keep the section self-contained.

---

### 31.1 — AUDIT FINDINGS

Audit performed 2026-04-27 against the live repo. **All "EXISTS IN CODE" markers were verified by reading the file or running a search.**

| System | Status | Location in repo | Notes |
|---|---|---|---|
| RAG stack (Chroma + Ollama + LangGraph) | EXISTS IN CODE (out-of-tree) | `~/LLM/rag_mcp_server.py`, `~/LLM/index.py`, `~/LLM/rag_db/` (gitignored) | LangChain (not LlamaIndex). 4 collections. Embedding `nomic-embed-text`. LLM `qwen2.5:3b`. SqliteSaver checkpointer at `~/LLM/rag_memory.db`. |
| RAG MCP server registration | EXISTS IN CODE | `.cursor/mcp.json` (`foulward-rag` entry) | Tools: `query_project_knowledge`, `get_recent_simbot_summary`. Optional — agent must not block if down. |
| Alternate RAG copy in repo | EXISTS IN CODE (orphan) | `new_rag_mpc/rag_mcp_server.py` | Older standalone copy. Not wired in `.cursor/mcp.json`; can be deleted or hardened. |
| RAG indexer | EXISTS IN CODE | `~/LLM/index.py` | Hash-cached incremental indexer. CLI: `--force`, `--stats`. |
| RAG auto-update on SimBot run | NOT YET IMPLEMENTED | — | `simbot_logs` collection ingests `~/FoulWard/logs/*.json|*.csv`, but SimBot writes to `user://simbot/logs/` — no copy/upload trigger exists. |
| SimBot core | EXISTS IN CODE | `scripts/sim_bot.gd` (`class_name SimBot`) | Resource-driven via `StrategyProfile` `.tres`. |
| SimBot loadouts | EXISTS IN CODE | `scripts/simbot/simbot_loadouts.gd` | 3 named tower presets (`balanced`, `summoner_heavy`, `artillery_air`). |
| SimBot CLI driver | EXISTS IN CODE | `autoloads/auto_test_driver.gd` | Flags: `--autotest`, `--simbot_profile=<id>`, `--simbot_runs=<N>`, `--simbot_seed=<S>`, `--simbot_balance_sweep`. |
| SimBot multi-instance / parallel runner | NOT YET IMPLEMENTED | — | `run_batch()` is a sequential loop in one process. No port management, no headless harness for >1 game. |
| Dynamic-strategy AI (MCTS / RL) | NOT YET IMPLEMENTED | — | All decisions are scripted from `StrategyProfile`. No state-space search anywhere. |
| Economy / balance analyser | EXISTS IN CODE | `tools/simbot_balance_report.py` | Reads `building_summary.csv` recursively, emits markdown + status CSV. Tags: `OVERTUNED`/`UNDERTUNED`/`BASELINE`/`UNTESTED`. |
| Balance report → RAG feedback loop | NOT YET IMPLEMENTED | — | Manual: agent reads report; `simbot_logs` collection is unrelated to the balance report's output dir. |
| GdUnit4 test suite | EXISTS IN CODE | `tests/`, `tools/run_gdunit*.sh` | 665 cases / 8-way parallel runner. |
| CI/CD (GdUnit + SimBot on PR) | NOT YET IMPLEMENTED | — | No `.github/` directory, no `.gitlab-ci.yml`, no `Jenkinsfile`. |
| MCP servers configured | EXISTS IN CODE | `.cursor/mcp.json` | 6 servers — see §31.2. |
| Custom Foul Ward MCP (game-tool exposing) | NOT YET IMPLEMENTED | — | Only RAG is custom; no `add_unit`, `run_simbot`, `validate_signals`, etc. tools exposed. |
| Gen3D orchestrator | EXISTS IN CODE | `tools/gen3d/foulward_gen.py` | 5-stage pipeline. Single command per asset. |
| Gen3D Stage 1 (FLUX turnaround) | EXISTS IN CODE | `tools/gen3d/pipeline/stage1_turnaround.py`, `tools/gen3d/workflows/turnaround_flux*.json` | ComfyUI + FLUX.1-dev + 3 LoRAs. |
| Gen3D Stage 2 (TRELLIS.2 mesh) | EXISTS IN CODE | `tools/gen3d/pipeline/stage2_mesh.py` | TRELLIS.2-image-large (4B). VRAM-managed. |
| Gen3D Stage 3 (rigging) | EXISTS IN CODE | `tools/gen3d/pipeline/stage3_rig.py` | UniRig primary, Mixamo Selenium fallback, unrigged copy last-resort. |
| Gen3D Stage 4 (animation merge) | EXISTS IN CODE | `tools/gen3d/pipeline/stage4_anim.py` | Blender-driven; reads FBX clips from `anim_library/` named per Mixamo export convention. |
| Gen3D Stage 5 (Godot drop) | EXISTS IN CODE | `tools/gen3d/pipeline/stage5_godot_drop.py` | Copies final GLB into `art/generated/<faction>/<asset>/`. |
| Mixamo dependency | EXISTS IN CODE | `stage3_rig.py` (Selenium fallback), `stage4_anim.py` (`ANIM_NAME_MAP` keys = Mixamo export filenames) | Stage 4 *requires* clips to be exported in Mixamo's filename convention even if rigging used UniRig. |
| Mesh2Motion integration | NOT YET IMPLEMENTED | — | Zero references in repo (`rg -i mesh2motion` → 0 hits). |
| ComfyUI workflow JSON | EXISTS IN CODE | `tools/gen3d/workflows/turnaround_flux.json`, `turnaround_flux_no_loras.json`, `turnaround_flux_with_loras.json` | API-format workflows used by `comfy_client.py`. |
| Audio generation pipeline (AudioCraft / MusicGen) | NOT YET IMPLEMENTED | — | Zero references in repo. No `audio_library/`, no AudioCraft scripts. |
| Adaptive music runtime | NOT YET IMPLEMENTED | — | No `AudioStreamInteractive` resources, no Mixing Desk addon. Music is currently single-track per scene. |
| Docker (any container) | NOT YET IMPLEMENTED | — | No `Dockerfile`, no `docker-compose.yml`, no `.dockerignore` anywhere in repo or 2-level parent search. |
| Framework: SignalBus template | EXISTS IN CODE | `autoloads/signal_bus.gd` (77 signals) | Already battle-tested — a clean copy is the framework's seed. |
| Framework: HexGrid | EXISTS IN CODE | `scripts/hex_grid.gd` (3 rings × 14 = 42 slots) | Foul Ward-specific shape; needs generalisation pass for the framework. |
| Framework: FSM scaffold | PARTIAL | Per-class state machines exist (`scripts/enemies/`, `scripts/allies/`); no shared FSM base | A `Beehave`-style helper is missing. |
| Framework: FOW / Minimap / RTS Camera | NOT YET IMPLEMENTED | — | Foul Ward camera is fixed to the keep; no minimap. |
| Framework: Steering / Beehave / HTN | NOT YET IMPLEMENTED | — | All AI is hand-rolled per enemy/ally script. |
| Framework: Godot Gameplay Systems (OctoD GAS) | NOT YET IMPLEMENTED | — | Status effects use bespoke arrays in `EnemyBase`. |
| Framework: Dialogue Manager | EXISTS IN CODE | `autoloads/dialogue_manager.gd` + `resources/dialogue/*.tres` | Foul Ward's own minimal manager — not the third-party "Dialogue Manager" addon. |
| Framework: Quest System / Card Framework | NOT YET IMPLEMENTED | — | Out of scope for current MVP. |
| Framework: Gaea / Province Map Builder | NOT YET IMPLEMENTED | — | World map is hand-authored. |
| Framework: Terrain3D / Sky3D | NOT YET IMPLEMENTED | — | Foul Ward uses single static arena meshes. |
| Framework: Day/Night + TimeTick | PARTIAL | `CampaignManager.current_day` is a discrete counter | No real-time day/night cycle, no TimeTick autoload. |
| Framework: Rollback netcode / GodotSteam | NOT YET IMPLEMENTED | — | Single-player offline. |
| Framework: Mod loader (GML) | NOT YET IMPLEMENTED | — | No mod surface. |
| Framework: Replay recorder + GIF export | NOT YET IMPLEMENTED | — | SimBot logs metrics only; no input-tape replay. |
| MVP: Tower Defense (Foul Ward lite) | EXISTS IN CODE | The repo itself | Already 50-day TD; the "lite" cut is a doc/scope question, not a code question. |
| MVP: RTS / Card Roguelite / Grand Strategy | NOT YET IMPLEMENTED | — | New games, not features. |
| Community: docs site, CONTRIBUTING, demo video pipeline | NOT YET IMPLEMENTED | — | Repo has `README.md`, `HOW_IT_WORKS.md`, `INTERVIEW_CHEATSHEET.md` only. |

---

### 31.2 — MCP INVENTORY

Verified directly from `.cursor/mcp.json` plus `addons/godot_mcp/skills.md` and `addons/gdai-mcp-plugin-godot/`.

| Name | Free / Paid | Purpose | Framework features it enables | Replaceable by custom Foul Ward MCP? |
|---|---|---|---|---|
| `godot-mcp-pro` | **Paid** (vendor source at `../foulward-mcp-servers/godot-mcp-pro/`, not in repo) | 162 tools driving the live Godot 4 editor over WebSocket :6505 — scene CRUD, script editing, playtest, screenshots, frame capture, animation tracks, UI building, audio buses, profiling | Editor automation, scaffold-new-entity, automated scene QA, screenshot diff regression | **No.** Replicating 162 editor tools is out of scope; keep as a standing dependency. |
| `gdai-mcp-godot` | **Paid** (vendor at `../foulward-mcp-servers/gdai-mcp-godot/`; bridge stub `addons/gdai-mcp-plugin-godot/` lives in repo) | Python ↔ Godot HTTP API bridge :3571 for GDExtension-side runtime introspection | Live error pulling, lightweight `get_godot_errors`, runtime property reads | **Partial.** A custom MCP can wrap the same HTTP API for the small subset we use (`get_godot_errors`, `get_scene_tree`) without paying for unused tools. |
| `sequential-thinking` | Free (npm package, runs via local `tools/mcp-support/`) | Multi-step reasoning scratchpad | Planning, design tradeoffs, debugging chains | **No** — generic reasoning aid, keep it. |
| `filesystem-workspace` | Free (Anthropic reference MCP) | Broad workspace FS access outside the active project | Cross-project edits, vendor symlinks | **No** — generic. |
| `github` | Free (Anthropic reference MCP, requires `GITHUB_PERSONAL_ACCESS_TOKEN`) | Issues, PRs, releases, workflow runs | CI status, PR babysitting, issue triage | **No** — generic. |
| `foulward-rag` | **Custom (free, in-house)** | Project RAG — `query_project_knowledge`, `get_recent_simbot_summary` | Architecture lookup, balance summaries, signal docs retrieval | **Already custom.** Will be **subsumed** into the future Foul Ward MCP (§31.7) as two of its tools; the RAG retriever stays in `~/LLM/`, only the wiring layer moves. |

**Conclusion:** the two paid editor MCPs stay; the three Anthropic reference MCPs stay; the custom Foul Ward MCP described in §31.7 absorbs `foulward-rag` and adds game-specific tools (`run_simbot`, `import_3d_asset`, `validate_signals`, …) that today have no MCP surface.

---

### 31.3 — 3D ART PIPELINE: CURRENT STATE & MIGRATION PATH

#### 31.3.1 — Current pipeline (verified, file by file)

| Stage | Script | What it does today |
|---|---|---|
| Orchestrator | `tools/gen3d/foulward_gen.py` | CLI `python -m tools.gen3d.foulward_gen "<name>" <faction> <asset_type>`. Manages VRAM (waits until ≥12 GB free before TRELLIS), runs Stages 1→5 sequentially, logs to `local/gen3d/runs/`. |
| Stage 1 | `tools/gen3d/pipeline/stage1_turnaround.py` + `comfy_client.py` + `workflows/turnaround_flux*.json` | Submits a FLUX.1-dev turnaround prompt to ComfyUI :8188; outputs front/3-quarter/side reference PNGs into `art/gen3d_previews/`. |
| Stage 2 | `tools/gen3d/pipeline/stage2_mesh.py` + `mesh_post.py` | Calls TRELLIS.2-image-large-4B on the chosen reference; decimates the mesh, normalises scale, exports `.glb`. **Weapon gate** rejects ultra-thin geometries before TRELLIS runs. |
| Stage 3 | `tools/gen3d/pipeline/stage3_rig.py` | Tries **UniRig** first (3-shell-script pipeline gated by `$UNIRIG_REPO`). On failure, falls back to **Mixamo** via Selenium login (`MIXAMO_EMAIL`, `MIXAMO_PASSWORD`). On total failure, copies the unrigged GLB. |
| Stage 4 | `tools/gen3d/pipeline/stage4_anim.py` | Scans `anim_library/` for FBX clips named per `ANIM_NAME_MAP` (e.g. `Idle.fbx`, `Walking.fbx`, `Attack01.fbx`, `Death.fbx`). Blender CLI merges them onto the rigged GLB. If no clips found, copies rigged GLB unchanged. |
| Stage 5 | `tools/gen3d/pipeline/stage5_godot_drop.py` | Copies the final GLB into `art/generated/<faction>/<asset>/` (gitignored). The agent then runs Godot's import pipeline manually. |

#### 31.3.2 — Mixamo dependency map (exact replacement targets)

| Touch point | File | Lines / symbol | What Mixamo does |
|---|---|---|---|
| Credential loading | `tools/gen3d/pipeline/stage3_rig.py` | `_load_mixamo_credentials()` (~L173-213) | Reads `MIXAMO_EMAIL` / `MIXAMO_PASSWORD` from env or `~/.foulward_gen3d.env`. |
| Selenium upload + auto-rig | `tools/gen3d/pipeline/stage3_rig.py` | `_rig_with_mixamo()` (~L266-307) | Uploads GLB, performs auto-rig, downloads rigged FBX. |
| Animation library convention | `tools/gen3d/pipeline/stage4_anim.py` | `ANIM_NAME_MAP` (top of file) | Expects FBX filenames straight out of Mixamo export (`Idle.fbx`, `Walking.fbx`, `Attack01.fbx`, …). |
| Animation merge | `tools/gen3d/pipeline/stage4_anim.py` | `_merge_animations_blender()` | Calls Blender headless with the FBX clips listed above. |
| Documentation | `tools/gen3d/anim_library/README.md`, `PHASE_D_REPORT.md`, `AUDIT_REPORT.md` | Mixamo workflow text | Docs assume Mixamo as canonical clip source. |
| Open question logged in §33 | `MASTER_DOC` row "Gen3D Stage 3 (Mixamo rigging)" | n/a | Notes that Mixamo creds are unavailable locally → Arnulf shipped with 0 anims. |

UniRig itself is **not** Mixamo and is the desired primary path; the Mixamo coupling is purely in **rigging fallback** + **animation source**.

#### 31.3.3 — Mesh2Motion drop-in plan

**What changes:**

1. New module `tools/gen3d/pipeline/stage3_rig_mesh2motion.py` that exposes the same public surface as `stage3_rig.py::rig_glb(input_glb, output_glb, asset_type)`.
2. `stage3_rig.py` becomes a dispatcher: `RIG_BACKEND` env var (`unirig` | `mesh2motion` | `mixamo` | `unrigged`) selects the strategy. Default flips to `unirig → mesh2motion → unrigged`. **Mixamo path is retained** but moved off the default chain so existing creds-bearing users still work.
3. `tools/gen3d/anim_library/` gains a `mesh2motion/` subfolder. `ANIM_NAME_MAP` is extended (not replaced) with a parallel `MESH2MOTION_ANIM_NAME_MAP` keyed off Mesh2Motion's clip naming, and `stage4_anim.py` picks the map matching `RIG_BACKEND`.
4. `foulward_gen.py` adds `--rig-backend` CLI flag and surfaces it in the run-log JSON.

**What stays the same:**

- Stages 1, 2, 5 unchanged.
- VRAM management policy unchanged.
- The "weapon gate" stays in Stage 2.
- `art/generated/` layout, Godot drop step, and `local/gen3d/runs/` log format unchanged.

#### 31.3.4 — Single-command target (`studio.py`)

`tools/studio.py` (NEW) — one command end-to-end:

```bash
python -m tools.studio "Stoneward Sentinel" \
  --faction crusader --asset character \
  --rig-backend mesh2motion --auto-import-godot
```

Required behaviour:

1. Health-check ComfyUI :8188 → start it via `tools/comfy_launch.sh` if down.
2. Run `foulward_gen.py` Stages 1-5.
3. Health-check the Foul Ward MCP server (§31.7) → invoke `import_3d_asset` to register the new GLB in Godot's import database (uses `godot-mcp-pro` editor tools under the hood).
4. Append a row to `local/studio/manifest.csv`: timestamp, name, faction, asset_type, rig_backend, glb_path, import_status.
5. Exit non-zero on any stage failure with the failing stage's log path printed to stderr.

#### 31.3.5 — Audio pipeline (slot for AudioCraft)

Currently absent. Target slot:

| Stage | Tool | Output |
|---|---|---|
| Prompt → SFX | `tools/audio/stage1_audiocraft_sfx.py` (AudioCraft `audiogen-medium`) | 16-bit 44.1 kHz `.wav` into `art/audio_candidates/sfx/<category>/` |
| Prompt → music stem | `tools/audio/stage1_audiocraft_music.py` (AudioCraft `musicgen-medium`) | Stems (drum/bass/lead/pad) as separate `.wav` files |
| Encode | `tools/audio/stage2_encode.py` | `ffmpeg`-driven Vorbis `.ogg` (Godot's preferred streamable format) |
| Drop | `tools/audio/stage3_godot_drop.py` | Copies into `art/audio_generated/<sfx|music>/<faction>/<name>/` and emits a `.tres` `AudioStream` resource alongside |

`studio.py` learns to dispatch `--asset audio_sfx` / `--asset music_stem` to this pipeline. AudioCraft inference uses the same VRAM-budget guard (§31.6) as TRELLIS — they will not co-run.

---

### 31.4 — RAG SYSTEM: CURRENT STATE & EXPANSION PLAN

#### 31.4.1 — Current state (read from `~/LLM/index.py` + `~/LLM/rag_mcp_server.py`)

- **Stack:** ChromaDB (`PersistentClient` at `~/LLM/rag_db/`) + LangChain (`langchain_ollama`, `langchain_text_splitters`, `BM25Retriever`) + LangGraph (`StateGraph` with `SqliteSaver` at `~/LLM/rag_memory.db`).
- **Embeddings:** `nomic-embed-text` via Ollama at `localhost:11434`.
- **LLM:** `qwen2.5:3b` via `ChatOllama`.
- **Retrieval:** Hybrid — semantic (Chroma) + BM25, weighted at `SEMANTIC_WEIGHT` and merged.
- **Collections:** `architecture` (`docs/*.md` + 5 root docs), `code` (`scripts/*.gd`), `resources` (`resources/*.tres`), `simbot_logs` (`logs/*.json|*.csv`).
- **Query interface:** MCP tool only — `query_project_knowledge(question, domain="all")` and `get_recent_simbot_summary(n_runs=3)` exposed via the `foulward-rag` server in `.cursor/mcp.json`. **No GDScript caller, no CLI caller other than the MCP stdio entrypoint.**
- **Update mechanism:** Manual — `python ~/LLM/index.py [--force]` with hash-cache short-circuit.

#### 31.4.2 — Three-corpus target architecture

The current 4 collections collapse into **three named RAGs** with explicit ingestion triggers:

| RAG | Chroma collection name | Source corpus | Ingestion trigger |
|---|---|---|---|
| **Framework RAG** | `fw_framework` | All `.gd` + `.tscn` + `.cs` + `addons/` plus `docs/CONVENTIONS.md`, `docs/ARCHITECTURE.md`, `docs/INDEX_*` | Git pre-commit hook + nightly cron |
| **Balance RAG** | `fw_balance` | `resources/buildings/*.tres`, `resources/enemies/*.tres`, `resources/spells/*.tres`, **plus** SimBot `building_summary.csv` / `wave_summary.csv` aggregates and `tools/output/simbot_balance_status.csv` | Auto-triggered at end of every SimBot batch run via §31.5.4 pipeline |
| **Game Design RAG** | `fw_design` | `docs/FOUL_WARD_MASTER_DOC.md`, `HOW_IT_WORKS.md`, `INTERVIEW_CHEATSHEET.md`, `docs/FUTURE_*`, dialogue resource text fields | Manual + git pre-commit on these specific paths |

The current `architecture` / `code` / `resources` / `simbot_logs` collections become an internal implementation detail of `fw_framework` + `fw_balance`.

#### 31.4.3 — Embedding model recommendation

**Keep `nomic-embed-text`** (768 dim, Apache-2.0, currently working). Reason: it already indexes the codebase incrementally; switching to `mxbai-embed-large` (1024 dim) would double-cost a forced reindex and add ~33% query latency without measurable retrieval gain on a corpus this size (~5-15 k chunks). Reserve `mxbai-embed-large` for the **Game Design RAG** specifically if retrieval quality on prose is found lacking after 2 weeks of usage — it is markedly stronger on long-form English than `nomic-embed-text`.

#### 31.4.4 — Custom MCP exposure

Both the existing `foulward-rag` server and any successor expose RAG via three tools (replacing the current two):

- `query_framework(question)` → `fw_framework`
- `query_balance(question, days_back: int = 7)` → `fw_balance` filtered by `last_modified`
- `query_design(question)` → `fw_design`

These three become tools 4-6 of the custom Foul Ward MCP described in §31.7 — the standalone `foulward-rag` server stays as a fallback and dev-loop tool.

---

### 31.5 — AUTOMATED TESTING SYSTEM: CURRENT STATE & EXPANSION PLAN

#### 31.5.1 — Current SimBot capabilities (verified)

- **Living at:** `scripts/sim_bot.gd` (`class_name SimBot`), entry-driver `autoloads/auto_test_driver.gd` (`AutoTestDriver`).
- **CLI flags (auto_test_driver.gd):**
  - `--autotest` — generic scripted run, prints `[AUTOTEST] PASS/FAIL/TIMEOUT`.
  - `--simbot_profile=<id>` — single mission with the named `StrategyProfile.tres`.
  - `--simbot_runs=<N>` — number of runs (default 1).
  - `--simbot_seed=<S>` — RNG seed.
  - `--simbot_balance_sweep` — multi-profile sweep across all profiles in `resources/simbot_profiles/`.
- **Outputs (CSV columns at `user://simbot/logs/simbot_balance_log.csv`):**
  `profile_id, run_index, seed_value, result, waves_cleared, final_wave, enemies_killed, tower_hp_start, tower_hp_end, gold_earned, building_material_spent, spell_casts, duration_seconds`
- **Auxiliary outputs:** `building_summary.csv`, `wave_summary.csv` written by `CombatStatsTracker` per run.
- **Decision surface:** mercenary purchases, building placements (via `simbot_loadouts.gd`), spell casts.

#### 31.5.2 — Multi-instance parallel runner (NEW)

`tools/simbot_swarm.py` — orchestrates **N parallel headless Godot processes**.

- **Process count default:** `min(8, max(1, cpu_count() // 2))`.
- **Per-process isolation:** each process gets a unique `--simbot_seed`, its own `XDG_DATA_HOME` (so `user://` directories don't collide), and a derived `simbot_run_id` (`UUIDv4`).
- **Port management:** SimBot itself is fully offline — no ports needed for game logic. The only port concern is the `gdai-mcp-godot` plugin; the swarm runner sets `GODOT_DISABLE_GDAI_MCP=1` per-child so plugins don't fight over :3571.
- **Aggregation:** all child CSVs are streamed to a single `tools/output/simbot_swarm_<timestamp>/aggregate.csv` and the per-run subfolders preserved for the SimBot → RAG step.

#### 31.5.3 — Dynamic-strategy AI tester (MCTS-light) (NEW)

Replaces the static `StrategyProfile` for "exploration" runs.

- **State input format (per decision):**
  ```
  {
    "wave": int,
    "gold": int, "building_material": int, "research_material": int,
    "tower_hp_pct": float,
    "filled_slots": [building_id, ...],
    "empty_slots_by_ring": {ring: count, ...},
    "enemies_alive": int,
    "spell_cooldowns": {spell_id: float, ...},
    "active_allies": [ally_id, ...]
  }
  ```
- **Action space:** discrete — `BUILD(building_id, slot_id)`, `SELL(slot_id)`, `CAST(spell_id)`, `HIRE_MERC(merc_id)`, `NOOP`. Pruned by affordability + slot validity before search.
- **Search:** UCB1 MCTS with **simulation-via-fast-forward** — child sims run the *deterministic core* of `WaveManager` for K=1 wave instead of full game (≈100× speedup). Tree depth capped at `MCTS_DEPTH=3` waves.
- **Output:** the policy chosen at each decision is logged alongside the alternatives considered, so balance authors can read *why* the bot picked an action.

#### 31.5.4 — SimBot → RAG pipeline (NEW)

End-of-batch hook:

1. `simbot_swarm.py` calls `tools/simbot_balance_report.py` on `aggregate.csv` → produces `simbot_balance_report.md`.
2. Hook script `tools/simbot_index_to_rag.py` then:
   - copies the per-run JSON/CSV bundles into `~/FoulWard/logs/simbot_runs/<timestamp>/` (the path `index.py` already scans).
   - calls `python ~/LLM/index.py` (incremental → only the new bundle is embedded).
   - emits one *summary* document per batch into `fw_balance` with metadata `{kind: "balance_summary", batch_id, top_overtuned: [...], top_undertuned: [...]}`.
3. Optional: triggers a Qwen analysis query via the MCP tool `query_balance("Compare batch <id> against the previous 3 batches")` and stores the answer in `tools/output/simbot_swarm_<timestamp>/qwen_analysis.md`.

#### 31.5.5 — Replay + GIF export pipeline (NEW)

- SimBot gains an `--simbot_record_inputs=<path>` flag (writes a JSON tape of every decision and RNG draw).
- New tool `tools/simbot_replay.py` consumes the tape and re-runs the game **once** with `--render` and Godot's `--write-movie <out.png-sequence>` + `ffmpeg` to produce an MP4 + a 10-fps GIF.
- The GIF is the canonical artefact for the docs site (§31.10) — every PR that changes balance auto-regenerates it.

#### 31.5.6 — Economy optimiser loop (NEW)

`tools/economy_optimiser.py` — closes the loop:

```
while not converged:
    swarm.run(N=64)
    report = balance_report.parse(aggregate.csv)
    suggestions = propose_param_changes(report)   # rule-based, see below
    apply_to_resources(suggestions)               # writes .tres files via DataManager API
    git_diff_summary()
```

**Rule-based proposer (no LLM in the loop):**
- `OVERTUNED` building → +10% `gold_cost` OR -10% `damage`, alternating each iteration.
- `UNDERTUNED` building → -10% `gold_cost` OR +10% `damage`.
- Bounded by min/max guardrails per building category from `resources/balance/guardrails.tres` (NEW, `[PLANNED]`).
- Convergence: all buildings within ±25% of median `damage_per_gold`, sustained for 2 consecutive batches.

Optimiser runs are gated behind a `git checkout -b balance/auto-<timestamp>` so they never mutate `main`.

---

### 31.6 — DOCKER ARCHITECTURE PLAN

Two containers, both NEW.

#### 31.6.1 — `foulward-dev`

- **Purpose:** reproducible Godot 4.4 + .NET 8 + GdUnit4 + Python 3.11 (RAG client) build/test environment.
- **Base image:** `mcr.microsoft.com/dotnet/sdk:8.0-jammy` + manually layered Godot 4.4-stable headless Linux binary (downloaded in build).
- **Volume mounts (compose):**
  - `./:/workspace:rw` — repo root.
  - `~/.cache/godot:/root/.cache/godot:rw` — Godot import cache, persists between runs.
  - `~/LLM:/llm:rw` — RAG state (read-write for `index.py` runs).
- **Entry commands:**
  - default `bash`.
  - `foulward-dev build` → `dotnet build FoulWard.csproj`.
  - `foulward-dev test [unit|parallel|quick]` → calls `tools/run_gdunit_*.sh`.
  - `foulward-dev simbot <profile>` → headless `--simbot_profile=<id>`.
  - `foulward-dev rag-index` → `python /llm/index.py`.

#### 31.6.2 — `foulward-art`

- **Purpose:** GPU container for FLUX.1-dev + TRELLIS.2 + Mesh2Motion + AudioCraft.
- **Base image:** `nvidia/cuda:12.4.0-cudnn-devel-ubuntu22.04` + `python:3.11`.
- **GPU passthrough:** `runtime: nvidia` in compose, `gpus: all`. `NVIDIA_VISIBLE_DEVICES=all`, `NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics`.
- **Pinned deps:** `transformers==4.56.0` (matches `tools/gen3d/SKILL.md`), `torch>=2.4` CUDA 12.4 wheels, ComfyUI git-pinned, TRELLIS.2 git-pinned, AudioCraft git-pinned.
- **Model download entrypoint:** `art-bootstrap` script — first-run downloads FLUX.1-dev, TRELLIS.2-image-large-4B, AudioCraft `audiogen-medium` + `musicgen-medium` weights into a **named volume** `foulward-models:/models` (NOT into the image — keeps the image at ~8 GB, models at ~80 GB live in a volume).
- **Volume mounts:**
  - `foulward-models:/models:rw` — model weights.
  - `./art/generated:/out/generated:rw` — pipeline output, written back to host.
  - `./local/gen3d:/out/runs:rw` — run logs.
  - `./tools/gen3d:/work:ro` — pipeline scripts.
- **Entry commands:**
  - `art-comfyui` → starts ComfyUI server on :8188.
  - `art-gen <name> <faction> <asset_type> [--rig-backend …]` → invokes `foulward_gen.py`.
  - `art-audio <name> <category> [--type sfx|music]` → invokes the §31.3.5 audio pipeline.
  - `art-bootstrap` → idempotent model download.

#### 31.6.3 — `.env` template (`/.env.example`)

```env
# VRAM management
GEN3D_VRAM_BUDGET_GB=24
GEN3D_TRELLIS_MIN_FREE_GB=12
GEN3D_AUDIOCRAFT_MIN_FREE_GB=8

# Model selection
FLUX_MODEL=flux1-dev.safetensors
TRELLIS_MODEL=trellis2-image-large-4B
AUDIOCRAFT_SFX_MODEL=audiogen-medium
AUDIOCRAFT_MUSIC_MODEL=musicgen-medium
RAG_EMBED_MODEL=nomic-embed-text
RAG_LLM_MODEL=qwen2.5:3b

# Rigging backend
RIG_BACKEND=unirig            # unirig | mesh2motion | mixamo | unrigged
UNIRIG_REPO=/opt/unirig
MESH2MOTION_REPO=/opt/mesh2motion
MIXAMO_EMAIL=
MIXAMO_PASSWORD=

# Ports
COMFYUI_PORT=8188
OLLAMA_PORT=11434
GDAI_MCP_PORT=3571
GODOT_MCP_PRO_PORT=6505

# Paths
FOULWARD_LOG_ROOT=./local
FOULWARD_GENERATED_ROOT=./art/generated
```

#### 31.6.4 — First-run experience

`docker-compose up` first time:

1. Image builds run in parallel (`dev` and `art`).
2. `foulward-art` starts → runs `art-bootstrap` automatically because the `foulward-models` volume is empty → ~80 GB download with progress bars (≈ 30-60 min on a fast link). User sees a single "Downloading FLUX.1-dev (16 GB)…" style log.
3. `foulward-dev` starts → runs `foulward-dev rag-index` (incremental, fast on first empty cache because no source files have been hashed yet → indexes everything once, ~3 min).
4. Both containers print their ready banner: `[dev] ready — try: docker compose exec dev foulward-dev test quick` / `[art] ready — try: docker compose exec art art-gen "Test Goblin" goblinkin character`.
5. `studio.py` from the host can now drive both containers via `docker compose exec` calls without the user re-installing Python deps locally.

---

### 31.7 — CUSTOM MCP SERVER SPEC

**Server name:** `foulward` (registered in `.cursor/mcp.json` as a 7th entry; coexists with the existing `foulward-rag` until parity is reached, then `foulward-rag` is removed).

**Transport:** **stdio** (Cursor connects stdio MCPs without extra config; HTTP requires keeping a long-lived service alive). All other Foul Ward MCPs are stdio — keep the convention.

**Language:** Python 3.11 with the official `mcp` SDK (Anthropic, MIT). Lives at `tools/foulward_mcp/server.py` with module entries in `tools/foulward_mcp/tools/`.

**Tool list (15 — all tools wrap an existing CLI/HTTP client; no business logic in the MCP itself):**

| # | Tool | Wraps | What it does |
|---|---|---|---|
| 1 | `add_unit(unit_id, role, faction, base_stats)` | `tools/foulward_mcp/scaffolders/unit.py` | Generates `EnemyData.tres` or `AllyData.tres`, registers in `INDEX_*`, opens a PR-ready diff. |
| 2 | `add_building(building_id, category, slot_size, gold_cost, damage)` | scaffolder | Generates `BuildingData.tres`, slot icon stub, updates `BuildingType` enum if missing. |
| 3 | `run_tests(suite='quick' | 'unit' | 'parallel' | 'sequential')` | `tools/run_gdunit_*.sh` | Runs the appropriate GdUnit script, returns pass/fail counts and failure summary. |
| 4 | `query_rag(question, corpus='framework' | 'balance' | 'design')` | `~/LLM/rag_mcp_server.py` (in-process) | Replaces `query_project_knowledge` with corpus selection. |
| 5 | `read_master_doc(section)` | `docs/FOUL_WARD_MASTER_DOC.md` | Returns a single numbered section by `§N.M`. |
| 6 | `validate_signals()` | `tools/foulward_mcp/validators/signal_check.py` | Asserts SignalBus signal count matches docs and that all signals are past-tense snake_case. |
| 7 | `get_balance_report(latest=True)` | `tools/output/simbot_balance_report.md` | Returns the latest report text + status CSV summary. |
| 8 | `run_simbot(profile_id, runs=10, seed=None, swarm=False)` | `tools/simbot_swarm.py` (or single Godot child) | Returns aggregate metrics; on `swarm=True`, blocks until all children finish. |
| 9 | `import_3d_asset(glb_path, category, faction, name)` | `godot-mcp-pro` (proxied) | Drops GLB into `art/generated/` AND triggers Godot's import pipeline + creates the `.tscn` skeleton. |
| 10 | `generate_character(name, faction, asset_type='character', rig_backend=None)` | `tools/studio.py` | Invokes Stages 1-5 end-to-end; streams stage logs. |
| 11 | `generate_sfx(prompt, category, duration_s=2.0)` | `tools/audio/stage1_audiocraft_sfx.py` | Returns the resulting `.ogg` path. |
| 12 | `generate_music_stem(prompt, stem_role, length_s=30.0, key='Cmin')` | `tools/audio/stage1_audiocraft_music.py` | Returns the resulting stem path. |
| 13 | `add_signal(signal_name, payload_typedef)` | scaffolder | Inserts the signal into `signal_bus.gd`, bumps the count in `AGENTS.md` and `MASTER_DOC.md` and `signal-bus/SKILL.md`, validates past-tense naming. |
| 14 | `check_resource_schema(resource_path)` | validator | Confirms a `.tres` matches the schema for its declared `[gd_resource type="…"]` (catches the `gold_cost` vs `build_gold_cost` class of bugs). |
| 15 | `get_scene_tree(scene_path=None)` | `godot-mcp-pro` (proxied) | Mandatory pre-flight per `mcp-workflow` skill; proxied so agents in headless contexts can still query without the editor running. |

**Implementation notes:**

- Each tool is one file under `tools/foulward_mcp/tools/` with a `register(mcp)` function — keeps the server file under 100 lines.
- The MCP server *only* shells out / wraps; **no game logic ever leaves the Godot side**.
- ChromaDB Python client is reused in-process for tools 4 (no IPC). SimBot is shelled out as a child process. Studio.py is shelled out so VRAM budget guards are honoured. Editor-touching tools (9, 15) proxy to `godot-mcp-pro` over its WebSocket — the server requires an open editor for those tools, the rest work headless.

---

### 31.8 — ADAPTIVE MUSIC SYSTEM PLAN

**Runtime engine:** `AudioStreamInteractive` (Godot 4.3+ stdlib resource).

**Stem layering / mixing:** **Godot Mixing Desk** (kyzfrintin, MIT, `addons/mixing-desk/`) for fade curves and stem cross-bus routing. New autoload `MusicDirector` (`autoloads/music_director.gd`, **post-MVP**) holds the AudioStreamInteractive and listens to SignalBus for state transitions.

**SignalBus signals that drive transitions** (all already declared in `autoloads/signal_bus.gd` — verified count 77):

| Signal | Music transition target |
|---|---|
| `mission_started` | → `mission_intro` clip (one-shot, then enter `build_phase_calm`) |
| `build_phase_started` | → `build_phase_calm` |
| `wave_started` | → `combat_layer_low` |
| `wave_intensity_increased` (if not present, add via `add_signal`) | → `combat_layer_mid` |
| `boss_spawned` | → `combat_layer_boss` |
| `tower_hp_critical` (if not present, add via `add_signal`) | → `combat_layer_panic` |
| `wave_cleared` | → `combat_resolution` (one-shot) → `build_phase_calm` |
| `mission_won` | → `mission_won_stinger` |
| `mission_failed` | → `mission_failed_stinger` |

Two new signals (`wave_intensity_increased`, `tower_hp_critical`) are tracked as PLANNED — they require the standard add-signal procedure (bump counts in `AGENTS.md`, `MASTER_DOC`, and `signal-bus/SKILL.md`).

**AudioCraft generation workflow (per faction / per mission tier):**

1. Write a prompt brief (`tools/audio/briefs/<faction>_<tier>.md`) — natural-language tempo/key/instrumentation guidance.
2. `art-audio <name> music --stem <role>` for each of `drums`, `bass`, `lead`, `pad`. Each call yields a 30-second stem.
3. Encode to Vorbis `.ogg`.
4. Drop into `art/audio_generated/music/<faction>/<tier>/{drums|bass|lead|pad}.ogg`.
5. `tools/audio/stage4_make_interactive_resource.py` builds the `AudioStreamInteractive` `.tres` with named clip-ids matching the SignalBus state names.

**Naming conventions for generated audio files:**

- SFX: `art/audio_generated/sfx/<category>/<asset>__<descriptor>__<seed>.ogg`
  e.g. `sfx/buildings/arrow_tower__shoot__a91b.ogg`
- Music stems: `art/audio_generated/music/<faction>/<tier>/<role>.ogg`
  e.g. `music/crusader/wave_boss/lead.ogg`
- Stingers: `art/audio_generated/music/<faction>/stingers/<event>.ogg`
  e.g. `music/crusader/stingers/mission_won.ogg`
- All filenames are `[a-z0-9_]+` only (Godot import-safe; no spaces).

---

### 31.9 — MVP GAME PLAN

#### 31.9.1 — Foul Ward Lite (Tower Defense)

- **Genre:** real-time tower defense.
- **Core mechanic loop:** the player aims Florence's two weapons manually while building/upgrading turrets between waves; survive 10 days to see the credits roll.
- **Systems required from framework:** SignalBus, HexGrid, Resource templates, Dialogue Manager, EconomyManager, save/load, headless test harness.
- **New systems NOT in the framework:** none — this MVP **is** the framework's reference game.
- **Definition of done:** all 10 days playable end-to-end with at least 6 buildings, 8 enemies, 2 spells, 1 boss, 1 ally (Arnulf), GdUnit green, SimBot batch report shows no `OVERTUNED`/`UNDERTUNED` outliers.
- **Estimated dev weeks with full framework in place:** 0 (already exists; "lite" is a scope cut, not a build).

#### 31.9.2 — Tiny RTS

- **Genre:** small-scale real-time strategy.
- **Core mechanic loop:** harvest resources, build a base, train units, and destroy the enemy base on a single map.
- **Systems required from framework:** SignalBus, FSM, Steering AI / Beehave, RTS camera, FOW, minimap, EconomyManager.
- **New systems NOT in the framework:** unit selection (drag-box + control groups), production queue UI.
- **Definition of done:** 1 race, 6 unit types, 3 building types, 1 working AI opponent at single difficulty, FOW + minimap functional.
- **Estimated dev weeks with full framework in place:** 6.

#### 31.9.3 — Card Roguelite

- **Genre:** Slay-the-Spire-style deckbuilder.
- **Core mechanic loop:** play cards from a hand to defeat enemies, then choose one of three rewards on a node-based map.
- **Systems required from framework:** SignalBus, Resource templates, Dialogue Manager, save/load, headless test harness.
- **New systems NOT in the framework:** Card framework (hand/deck/discard/exhaust), node-graph map runner, status-effect engine.
- **Definition of done:** 1 character, 60 cards, 30 enemies, 3 acts, full Ascension-equivalent difficulty selector, run-history persistence.
- **Estimated dev weeks with full framework in place:** 10.

#### 31.9.4 — Grand Strategy

- **Genre:** province-based grand strategy.
- **Core mechanic loop:** manage a kingdom across years on a province map; balance economy, military, and diplomacy with neighbours.
- **Systems required from framework:** SignalBus, EconomyManager, save/load, Dialogue Manager, Resource templates, Day/Night + TimeTick calendar.
- **New systems NOT in the framework:** Province Map Builder, diplomacy state machine, multi-currency expansion of EconomyManager (gold + manpower + prestige + influence), AI nation simulator.
- **Definition of done:** 30-province map, 4 AI nations, 5 win conditions (conquest / diplomatic / economic / cultural / score), save survives quit-and-resume.
- **Estimated dev weeks with full framework in place:** 16.

---

### 31.10 — BUILD ORDER & DEPENDENCIES

Strict topological ordering. Phases marked **‖** can be parallelised with the prior phase.

| Phase | Task | Blocks | Est. weeks | Owner |
|---|---|---|---|---|
| **0** | Lock current Foul Ward MVP feature-complete; freeze `main` for breaking changes | All future phases | 1 | you |
| **1** | Docker `foulward-dev` container (§31.6.1) | All host-machine reproducibility from here on | 1 | you |
| **1‖** | Docker `foulward-art` container (§31.6.2) — runs in parallel with Phase 1 | Audio + Mesh2Motion work | 1 | you |
| **2** | Custom Foul Ward MCP skeleton with tools 3, 4, 5, 7, 8 (test/RAG/doc/balance/simbot) | Tools 1, 2, 6, 9-15; CI; MVP work | 1 | you |
| **2‖** | RAG migration to 3-corpus model (§31.4) | Custom MCP tool 4; balance loop | 1 | you |
| **3** | SimBot multi-instance runner (§31.5.2) | Dynamic-strategy tester; CI integration | 1 | you |
| **4** | SimBot → RAG pipeline + balance report automation (§31.5.4) | Economy optimiser loop | 1 | you |
| **4‖** | CI/CD: GitHub Actions running `foulward-dev test parallel` + `simbot run` on every PR | Future PRs from contributors | 1 | you |
| **5** | Mesh2Motion drop-in for Stage 3 + Stage 4 (§31.3.3) | `studio.py` end-to-end | 2 | you |
| **5‖** | AudioCraft SFX + music pipeline (§31.3.5) | Adaptive music runtime | 2 | you |
| **6** | `studio.py` single-command orchestrator (§31.3.4) | Custom MCP tools 9-12 | 1 | you |
| **7** | Dynamic-strategy tester (MCTS-light) (§31.5.3) | Economy optimiser | 2 | you |
| **8** | Economy optimiser loop (§31.5.6) | Balance-tuning automation | 1 | you |
| **9** | Adaptive music runtime: `MusicDirector` autoload + Mixing Desk integration (§31.8) | Polish phases for all MVPs | 2 | you |
| **10** | Custom MCP tools 1, 2, 6, 9, 13, 14, 15 (scaffolders, validators, editor proxies) | Scaffolding-driven contributor workflow | 2 | you |
| **11** | Framework extraction: SignalBus template, FSM scaffold, Resource templates as a separate addon repo | Other MVPs | 2 | you |
| **11‖** | Community: Astro Starlight docs site, `CONTRIBUTING.md`, demo-video pipeline using §31.5.5 GIF tool | Contributor onboarding | 2 | you + community |
| **12** | Framework: HexGrid generalisation, FOW, Minimap, RTS camera (RTS prerequisites) | RTS MVP | 3 | you |
| **12‖** | Framework: Steering AI / Beehave / HTN integrations | RTS MVP | 2 | you / community |
| **13** | RTS MVP (§31.9.2) | — | 6 | community-leadable, you-reviewed |
| **14** | Framework: Card framework, Quest System | Card Roguelite MVP | 3 | community-leadable |
| **15** | Card Roguelite MVP (§31.9.3) | — | 10 | community-leadable |
| **16** | Framework: Province Map Builder, Day/Night + TimeTick, expanded EconomyManager | Grand Strategy MVP | 4 | community-leadable |
| **17** | Grand Strategy MVP (§31.9.4) | — | 16 | community-leadable |

**Total elapsed time on critical path (excluding parallelised phases):** ~32 weeks for everything through MVP 4.

---

### 31.11 — OPEN QUESTIONS

Things the codebase alone can't answer. Each question lists the exact code reference that triggered it.

| # | Question | Code reference | Who decides |
|---|---|---|---|
| 1 | `tools/gen3d/pipeline/stage3_rig.py` `_load_mixamo_credentials()` reads `MIXAMO_EMAIL` / `MIXAMO_PASSWORD`. Once Mesh2Motion ships in §31.3.3, do we **delete** the Mixamo Selenium fallback entirely or keep it as `RIG_BACKEND=mixamo` opt-in? | `stage3_rig.py` ~L173-307 | you | Answer: Leave Mixamo in, but make it so it is not used and not called anywhere in actual code, I think it would be better to use the more reliable option, but leave it be in case someone wants to use it? Unless deleting it altogether would make more sense. What is the better option?
| 2 | `tools/gen3d/pipeline/stage4_anim.py` `ANIM_NAME_MAP` keys are Mixamo-export filenames. Does Mesh2Motion's CLI emit FBX clips with the same names or do we need a per-backend map? | `stage4_anim.py` top-of-file | art lead / Mesh2Motion docs | Answer: to be decided. What is the better option?
| 3 | `tools/gen3d/SKILL.md` pins `transformers==4.56.0`. Is this a TRELLIS.2-only constraint, or also a FLUX/AudioCraft constraint? Decision affects whether `foulward-art` can use one Python env or needs sub-envs per stage. | `.cursor/skills/gen3d/SKILL.md` | dev (verify against TRELLIS.2 + AudioCraft + ComfyUI requirements) | Answer: Please explain
| 4 | `~/LLM/index.py` line 32 hard-codes `FOULWARD_ROOT = Path.home() / "FoulWard"` but the live repo is at `~/workspace/foul-ward/FoulWard`. Was the indexer pointed at a **symlink**, an **older clone**, or is the path drifted? Affects whether `simbot_logs` are actually being indexed today. | `~/LLM/index.py` L32 | dev | Answer: The path needs to be adjusted to the new folder structure that uses docker anyway, so irrelevant, but should probably be path independent and relate to the relative path of the whole WOLF project root.
| 5 | Repo contains `new_rag_mpc/rag_mcp_server.py` — is this a deliberate alternate or dead code? `.cursor/mcp.json` only points at `~/LLM/rag_mcp_server.py`. Decision: delete from repo, or promote it as the canonical in-tree RAG and retire `~/LLM` copy? | `new_rag_mpc/`, `.cursor/mcp.json` | you | Answer: I need help deciding.
| 6 | `tools/simbot_balance_report.py` reads `building_summary.csv` files but the path is currently passed as a CLI argument with no default — what is the **canonical** SimBot output root (`user://simbot/logs/`) translation when running through Docker? Affects swarm runner volume mounts. | `tools/simbot_balance_report.py`, `simbot.gd::_on_run_completed` | you | Answer: The path needs to be adjusted to the new folder structure that uses docker anyway, so irrelevant, but should probably be path independent and relate to the relative path of the whole WOLF project root.
| 7 | Two of the SignalBus signals proposed in §31.8 (`wave_intensity_increased`, `tower_hp_critical`) are not currently declared (count remains 77). Confirm they should be added as **passive signals** emitted by `WaveManager` / `BuildingBase`(tower) respectively, not new responsibilities of the music director. | `autoloads/signal_bus.gd` | you | Answer: To be decided at architure planning phase and adjusted. music director idea was discussed with older version of MASTER_DOC.
| 8 | `addons/godot_mcp/` is the godot-mcp-pro **client-side plugin** living in-repo, while the server-side cwd in `.cursor/mcp.json` points at `../foulward-mcp-servers/godot-mcp-pro`. Should the `foulward` custom MCP also follow the split-repo pattern (server outside repo) or live entirely in `tools/foulward_mcp/`? | `.cursor/mcp.json`, `addons/godot_mcp/` | you | Answer: I don't know, please help me decide?
| 9 | `auto_test_driver.gd` flag set is the source of truth — but `autotest`, `simbot_balance_sweep`, and `simbot_profile` paths print to stdout while GDAI requires stdout to be JSON-RPC clean. Is the test driver ever launched from inside an MCP-attached editor, or only from CLI? Affects whether stdout is safe. | `auto_test_driver.gd`, `mcp-workflow/SKILL.md` "GDAI stdout/stderr Rule" | dev | Answer: Please help me decide.
| 10 | `local/`, `art/generated/`, `art/gen3d_previews/`, `art/gen3d_candidates/` are gitignored per `docs/GEN3D_LOCAL_ARTIFACTS.md`. For the docs-site GIF pipeline (§31.5.5), where do generated GIFs live — committed to a `docs/site/assets/` folder, or hosted via GitHub Pages artefacts? | `docs/GEN3D_LOCAL_ARTIFACTS.md` | you | Answer: Not commited anywhere yet, we're at the testing phase to save transfer and space on github. Please propose better solution.
| 11 | No `.github/` directory exists. Is GitHub Actions the chosen CI host, or is this project planning to use a different CI (Forgejo Actions, GitLab CI, Buildkite)? Affects Phase 4‖ in §31.10. | (absence of `.github/`) | you | Answer: Github is currently used, but please suggest better option for this project scope.
| 12 | `.cursor/mcp.json` uses paid `godot-mcp-pro` and `gdai-mcp-godot`. For community contributors who don't have those licences, what is the **degraded-mode** plan — does the custom Foul Ward MCP need to provide free fallbacks for `get_scene_tree` and `get_godot_errors`, or do contributors live without those tools? | `.cursor/mcp.json` | you | Answer: We will need to use free option of those, but leave comments that these are good alternatives. If it will degrade the experience, place free alternatives in project, but also assume that the paid MCPs can be used.

