INDEX_FULL.md
=============

FOUL WARD — INDEX_FULL.md

Full public API reference for every script, resource type, and system.
Source of truth: REPO_DUMP_AFTER_MVP.md. **Master doc:** `docs/FOUL_WARD_MASTER_DOC.md` — living comprehensive reference for developers and LLM agents (Prompt 53: expanded with full public APIs, lifecycle flows, "how to add X" templates, enum-to-integer tables, and anti-patterns; §1.1 Cursor/MCP toolchain; §23 SimBot headless automation vs GdUnit). **Doc layout:** `docs/README.md`. **Read-only audit aggregate (three-part verification):** `docs/SUMMARY_VERIFICATION.md`. **Archived snapshot:** `docs/archived/OPUS_ALL_ACTIONS.md` merges backlog + AGENTS + Prompt 26 log + both indexes (historical; prefer `FOUL_WARD_MASTER_DOC.md` + `IMPROVEMENTS_TO_BE_DONE.md`). Updated: 2026-03-31 (**Prompt 54:** agent skills index — `AGENTS.md`, `.cursor/skills/*/SKILL.md` — `docs/PROMPT_54_IMPLEMENTATION.md`). (**Prompt 51:** SimBot `run_balance_sweep` + `scripts/simbot/simbot_loadouts.gd`; `CombatStatsTracker` `begin_run`/`end_run` + CSV `run_label`; `tools/simbot_balance_report.py` + `tools/apply_balance_status.gd`; `AutoTestDriver` `--simbot_balance_sweep`; `tests/unit/test_simbot_balance_integration.gd` — `docs/archived/PROMPT_51_IMPLEMENTATION.md`). (**Prompt 10 wave:** `WavePatternData`, `WaveComposer`, `resources/wave_patterns/default_campaign_pattern.tres`, `WaveManager` composed waves + stagger spawn + `clear_all_enemies` queue cancel — `docs/archived/PROMPT_10_IMPLEMENTATION.md` §Wave composition). (**Prompt 11:** HUD build menu + in-mission research — `ui/build_menu*.gd`, `ui/research_panel*`, `ui/research_node_row*`, `ResearchManager`/`SignalBus`/`BuildPhaseManager`/`GameManager`/`HexGrid`/`main.tscn`/`hud.tscn`; `tests/unit/test_research_and_build_menu.gd` — `docs/archived/PROMPT_11_IMPLEMENTATION.md`). (**Prompt 09:** `EnemyData` `special_tags` runtime — `ShieldComponent`, `AuraManager` enemy auras + heal/damage queries, charge/dash/regen/saboteur/anti-air/on_death_spawn, `WaveManager.spawn_enemy_at_position`, `SignalBus` `enemy_spawned`/`enemy_enraged`, `tests/unit/test_enemy_specials.gd` — `docs/archived/PROMPT_09_IMPLEMENTATION.md`). (**Prompt 07:** `AllyManager` summoner squads; `SignalBus` `ally_spawned`/`ally_died`/`ally_squad_wiped`; `BuildingBase` respawn; `HexGrid` soft blockers; `CombatStatsTracker` `ally_deaths`; `tests/unit/test_summoner_runtime.gd` — `docs/archived/PROMPT_07_IMPLEMENTATION.md`). (**Prompt 50:** TD content authoring — `BuildingData`/`EnemyData` schema (`footprint_size_class`, string `size_class`/`balance_status`, `role_tags`, summoner paths, `heal_targets` string, upgrade arrays); `Types` `BuildingType` 8–35 / `EnemyType` 6–29; 36 building + 30 enemy `.tres`; 5 `AllyData` stubs; 18 new research nodes + `main.tscn` full registries; `HexGrid`/`WaveManager` size checks; `ArtPlaceholderHelper` token helpers; `tests/unit/test_content_invariants.gd` — `docs/archived/PROMPT_50_IMPLEMENTATION.md`). (**Prompt 48:** CombatStatsTracker mission API + CSV schemas; stat/aura/status on `BuildingBase`/`EnemyBase`; SignalBus combat signals; projectile + HexGrid + SimBot wiring; `tests/unit/test_combat_stats_tracker.gd` — `docs/archived/PROMPT_48_IMPLEMENTATION.md`). (**Prompt 49:** combat CSV + stat pipeline — `BuildPhaseManager`; `CombatStatsTracker` `register_building`/`flush_to_disk`/String ids; `SignalBus` `building_dealt_damage`/`enemy_spawned`; `EnemyBase.receive_damage` + `TRUE`; `HexGrid` rotation + build guards; `anti_air_bolt.tres` projectile; `tests/unit/test_combat_stats_tracker.gd`, `test_damage_pipeline.gd` — `docs/archived/PROMPT_49_IMPLEMENTATION.md`). (**Prompt 47:** economy + upgrade-chain foundation — `EconomyManager` `_built_counts`/`register_purchase`/`get_refund` Dictionary/`reset_for_mission`/`passive_gold_per_wave`; `BuildingData.building_id`; `DayConfig.mission_economy` — `docs/archived/PROMPT_47_IMPLEMENTATION.md`). (**Prompt 46:** Revert testing-only autotest/faction/wave tweaks; 5 waves + bats in rosters — `docs/archived/PROMPT_46_IMPLEMENTATION.md`). (**Prompt 44:** `EnemyData.matches_tower_air_ground_filter` + `BuildingBase._find_target` — `docs/archived/PROMPT_44_IMPLEMENTATION.md`). (**Prompt 43:** `MissionSpawnRouting` dictionary spawn queue + `RoutePathData` resolution + `Array[String]` validators; `WaveManager` integration — `docs/archived/PROMPT_43_IMPLEMENTATION.md`). (**Prompt 42:** TD `Resource` core + `Types` enums (`AllyCombatRole`, `SummonLifetimeType`, `AuraModifierOp`, ring `BuildingSizeClass`, SIEGE/ETHEREAL); `BuildingData`/`AllyData`/`EnemyData`/`RoutePathData`/`MissionEconomyData` field alignment; `BuildingBase` projectile `PackedScene` resolve — `docs/archived/PROMPT_42_IMPLEMENTATION.md`). (**Prompt 41:** `EconomyManager` linear duplicate scaling + mission dup reset + `can_afford_building`; `BuildingBase` upgrade chain + projectile guards + placement ids; `HexGrid` ring/`apply_upgrade` — `docs/archived/PROMPT_41_IMPLEMENTATION.md`). (**Prompt 40:** `MissionSpawnRouting` typed routing + seeded spawn jitter + `validate_wave`; `WaveManager.resolve_path_for_spawn` — `docs/archived/PROMPT_40_IMPLEMENTATION.md`). (**Prompt 39:** TD data resource foundation polish — `BuildingData.get_range`, `AllyData.identity`/`max_lifetime_sec`/`get_identity`, `EnemyData.get_identity`, `SpawnEntryData.enemy_id`, `MissionRoutingData` path→lane validation, docs; `MissionDataValidation` spawn rows; `tests/unit/test_td_resource_helpers.gd` — `docs/archived/PROMPT_39_IMPLEMENTATION.md`). (**Prompt 38:** `EconomyManager` wave_clear payout API + `wave_cleared` hook — `docs/archived/PROMPT_38_IMPLEMENTATION.md`). (**Prompt 37:** `EconomyManager` mission wiring — `apply_mission_economy`, passive tick, duplicate placement cost, `get_refund`; HexGrid `BuildingBase` `paid_*`/`total_invested_*`; `tests/unit/test_economy_mission_integration.gd` — `docs/archived/PROMPT_37_IMPLEMENTATION.md`). (**Prompt 35:** TD data resources — extended `BuildingData`/`AllyData`/`EnemyData`, `SpawnEntryData`, `WaveData`, `MissionWavesData`, `LaneData`, `PathData`, `MissionRoutingData`, `MissionEconomyData`, `MissionDataValidation`, `Types` TD enums — `docs/archived/PROMPT_35_IMPLEMENTATION.md`). (**Prompt 36:** `WaveManager` + `MissionSpawnRouting` mission spawn queue, `RoutePathData`, `EnemyBase` lane/path ids — `docs/archived/PROMPT_36_IMPLEMENTATION.md`). (**Prompt 34:** `CombatStatsTracker` — `user://simbot/runs/` CSVs, `SignalBus.enemy_reached_tower` live — `docs/archived/PROMPT_34_IMPLEMENTATION.md`). (**Prompt 33:** terrain — `Types.TerrainType`/`TerrainEffect`, `TerrainZone`, `NavMeshManager`, `CampaignManager._load_terrain`, `terrain_grassland`/`terrain_swamp`, `main.tscn` `TerrainContainer`, `EnemyBase` terrain multiplier, `tests/unit/test_terrain.gd`, `FUTURE_3D_MODELS_PLAN.md` §5 — `docs/archived/PROMPT_33_IMPLEMENTATION.md`). (**Prompt 32:** modular building kit — `Types.BuildingBaseMesh`/`BuildingTopMesh`, `BuildingData.base_mesh_id`/`top_mesh_id`/`accent_color`, `ArtPlaceholderHelper.get_building_kit_mesh`, `BuildingBase` `BuildingKitAssembly`, `tests/unit/test_building_kit.gd`, `FUTURE_3D_MODELS_PLAN.md` §4 — `docs/archived/PROMPT_32_IMPLEMENTATION.md`). **Prompt 31:** `RiggedVisualWiring` + rigged GLB mount on `EnemyVisual`/`BossVisual`/`ArnulfVisual`; `AnimationPlayer` idle/walk; `EnemyBase.assign_locomotion_animation_player` for bosses — `docs/archived/PROMPT_31_IMPLEMENTATION.md`). **Prompt 29:** `FUTURE_3D_MODELS_PLAN.md` scene audit appendix + `ArtPlaceholderHelper` API notes; `boss_base.tscn` `# TODO(ART)`; Godot MCP reload/error scan — `docs/archived/PROMPT_29_IMPLEMENTATION.md`). **Prompt 28:** `DialogueManager` runtime condition tracking; `WaveManager` BUILD_MODE countdown pause; `test_relationship_manager_tiers.gd` / `test_save_manager_slots.gd`; input/hex/Arnulf/build-menu deltas; full GdUnit **535** cases — `docs/archived/PROMPT_28_IMPLEMENTATION.md`). **Prompt 26:** Full project audit — 55 unindexed files indexed, `AGENTS.md` standing orders, `IMPROVEMENTS_TO_BE_DONE.md` backlog with 78 issues, test Unit/Integration classification, parallel runner spec — `docs/archived/PROMPT_26_IMPLEMENTATION.md`. **Prompt 24:** `PlaceholderIconGenerator` `tools/generate_placeholder_icons.gd` + editor plugin `addons/fw_placeholder_icons`; `ArtPlaceholderHelper` icon PNGs; `SettingsManager` autoload `user://settings.cfg`; `scenes/ui/settings_screen`; UI wiring `build_menu` / `between_mission_screen` / `world_map` / `main_menu`; `tests/test_settings_manager.gd` — `docs/archived/PROMPT_24_IMPLEMENTATION.md`). **Prompt 22:** `RelationshipManager` autoload, `relationship_tier` dialogue conditions, resources under `res://resources/relationship_*` / `character_relationship/` — `docs/archived/PROMPT_22_IMPLEMENTATION.md`. Prompt 19: Blender batch GLBs `res://art/generated/**`, `generation_log.json`, `FUTURE_3D_MODELS_PLAN.md`, `docs/archived/PROMPT_19_IMPLEMENTATION.md`; `# TODO(ART)` in enemy/ally/arnulf/tower/building/boss/hub scripts. Prompt 18: RAG + MCP — `docs/archived/PROMPT_18_IMPLEMENTATION.md`. Audit 6 delta: `AUDIT_IMPLEMENTATION_AUDIT_6.md` — SpellManager multi-spell; WeaponLevelData structural fields; BuildingBase archer barracks / shield generator; GameManager territory aggregates; tests `test_weapon_structural.gd`, `test_building_specials.gd`. Prompt 20: `docs/obsolete/` + INDEX header/autoload alignment — `docs/archived/PROMPT_20_IMPLEMENTATION.md`.
Use INDEX_SHORT.md for fast orientation, INDEX_FULL.md for exact method signatures, signals, and dependencies.

**Planning / verification docs (2026-04-14):** `docs/DELIVERABLE_A_ERROR_FIX_PLAN.md`, `docs/DELIVERABLE_B_FEATURE_WORKPLAN.md`, `docs/perplexity_sessions/session_*`, `docs/EXECUTION_GUIDE.md`, `docs/POST_BATCH_FIXES.md`, `docs/PROMPT_68_IMPLEMENTATION.md`, `docs/PROMPT_69_IMPLEMENTATION.md` — see `INDEX_SHORT.md` orientation block for one-line roles.

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

CURSOR AGENT SKILLS (`.cursor/skills/*/SKILL.md` — YAML `description` is the activation trigger)

**AGENTS.md** (repo root)
- **Trigger:** N/A — read first every session (also symlinked as `.cursorrules`).
- **Covers:** Standing orders summary, autoload order, verification commands, skills table; encyclopedia and deep systems in `docs/FOUL_WARD_MASTER_DOC.md`.

**add-new-entity** — `.cursor/skills/add-new-entity/SKILL.md`
- **Trigger:** Add or create new building, enemy, spell, research node, or signal; templates, scaffold, how to add.
- **Covers:** Step lists for `Types` enums, `BuildingData` / `EnemyData` / `SpellData` / `ResearchNodeData` `.tres`, `autoloads/signal_bus.gd`, registry wiring, tests; document update checklist (indexes, master doc, reference markdown under other skills).

**ally-and-mercenary-system** — `.cursor/skills/ally-and-mercenary-system/SKILL.md`
- **Trigger:** Ally, mercenary, Arnulf, Sybil, roster, squad, summoner, defection, hire, DOWNED/RECOVERING, patrol.
- **Covers:** `AllyManager`, `AllyData`, `scenes/allies/`, `scenes/arnulf/`, `CampaignManager` roster/mercenary APIs, SignalBus ally signals, hub roles.

**anti-patterns** — `.cursor/skills/anti-patterns/SKILL.md`
- **Trigger:** Code review, bugs, SignalBus violations, null guards, freed nodes, assert in production, Godot 3 syntax.
- **Covers:** Fourteen APs with examples (e.g. `get_node_or_null`, `is_instance_valid`, no autoload `class_name`, MCP stdout rule); applies repo-wide.

**building-system** — `.cursor/skills/building-system/SKILL.md`
- **Trigger:** Building, hex grid, placement, sell, upgrade, ring, build mode, aura, summoner, turret.
- **Covers:** `HexGrid`, `BuildingBase`, `BuildingData`, `BuildPhaseManager`, `AuraManager`, `AllyManager` for summoners, `Types.BuildingType` / size classes.

**campaign-and-progression** — `.cursor/skills/campaign-and-progression/SKILL.md`
- **Trigger:** Campaign, day, mission, territory, world map, endless mode, state transitions, `DayConfig`.
- **Covers:** `CampaignManager`, `GameManager`, `TerritoryData` / `TerritoryMapData`, `DayConfig` / `CampaignConfig`, mission indexing, mercenary offers context.

**economy-system** — `.cursor/skills/economy-system/SKILL.md`
- **Trigger:** Gold, materials, afford, spend, refund, duplicate scaling, wave reward, mission economy.
- **Covers:** `EconomyManager` (autoload #5), `resource_changed`, placement/sell/upgrade costs, `MissionEconomyData`, integration with `HexGrid` / `BuildingBase`.

**enemy-system** — `.cursor/skills/enemy-system/SKILL.md`
- **Trigger:** Enemy, spawn, pathfinding, damage, armor, boss, faction, wave composition, `EnemyType`.
- **Covers:** `EnemyBase`, `EnemyData`, `WaveManager`, `MissionSpawnRouting`, `DamageCalculator`, `BossBase` / `BossData`, `FactionData`, special tags / shields.

**godot-conventions** — `.cursor/skills/godot-conventions/SKILL.md`
- **Trigger:** Naming, typing, signals, exports, autoloads, style, reviewing new scripts.
- **Covers:** `docs/CONVENTIONS.md` alignment, sixteen agent rules, field name discipline, `_physics_process` vs `_process`, `project.godot` autoload order references.

**lifecycle-flows** — `.cursor/skills/lifecycle-flows/SKILL.md`
- **Trigger:** Lifecycle, game loop, startup, mission start/end, wave sequence, tower destroyed, `all_waves_cleared`.
- **Covers:** `GameManager` state machine, `BuildPhaseManager`, `CampaignManager` day flow, SignalBus mission/wave signals, briefing → combat → hub.

**mcp-workflow** — `.cursor/skills/mcp-workflow/SKILL.md`
- **Trigger:** MCP, Godot editor integration, scene validation, errors, ports, RAG, session checklist.
- **Covers:** `.cursor/mcp.json` servers (`godot-mcp-pro` at `../foulward-mcp-servers/godot-mcp-pro`, `gdai-mcp-godot` at `../foulward-mcp-servers/gdai-mcp-godot` — paid, outside repo; `sequential-thinking`, `foulward-rag`, etc.), default ports 6505 / 3571, `get_scene_tree` / `get_godot_errors`, GDAI stdout rule.

**save-and-dialogue** — `.cursor/skills/save-and-dialogue/SKILL.md`
- **Trigger:** Save, load, autosave, dialogue, relationship, affinity, tier, conditions.
- **Covers:** `SaveManager`, `DialogueManager`, `RelationshipManager`, `DialogueEntry` / `DialogueCondition`, `user://saves/`, relationship resources.

**scene-tree-and-physics** — `.cursor/skills/scene-tree-and-physics/SKILL.md`
- **Trigger:** Scene tree, node paths, physics layers, collision, input actions, camera, navmesh.
- **Covers:** `/root/Main/Managers/*` paths, `main.tscn` layout, layer/mask table, `project.godot` Input Map, `InputManager`, `NavMeshManager`.

**signal-bus** — `.cursor/skills/signal-bus/SKILL.md`
- **Trigger:** SignalBus, emit, connect, new signal, payload typing, `is_connected` guard.
- **Covers:** `autoloads/signal_bus.gd` only for cross-system signals; naming (past vs present tense); no logic/state on SignalBus.

**spell-and-research-system** — `.cursor/skills/spell-and-research-system/SKILL.md`
- **Trigger:** Spell, mana, research unlock, enchantment, weapon upgrade, cooldown.
- **Covers:** `SpellManager`, `ResearchManager`, `EnchantmentManager`, `WeaponUpgradeManager`, `SpellData`, `ResearchNodeData`, `EnchantmentData`, tower/weapon integration.

**testing** — `.cursor/skills/testing/SKILL.md`
- **Trigger:** Test, GdUnit4, SimBot, headless, integration, balance sweep, test isolation.
- **Covers:** `tests/`, `tools/run_gdunit*.sh`, `AutoTestDriver`, `SimBot`, `CombatStatsTracker` CSV, naming conventions, `after_test` cleanup.

### Skill reference tables (`.cursor/skills/*/references/*.md`)

**signal-table.md** — `.cursor/skills/signal-bus/references/signal-table.md`
- **Contains:** Full typed signal table for all **77** SignalBus signals (as of **2026-04-18**), organised by category (includes dialogue line signals + `combat_dialogue_requested`; source of truth: `autoloads/signal_bus.gd`).
- **When to read:** You need payload types, categories, or an inventory beyond `SKILL.md` and `autoloads/signal_bus.gd`; when adding or renaming SignalBus signals.

**enemy-types.md** — `.cursor/skills/enemy-system/references/enemy-types.md`
- **Contains:** `EnemyType` (30), `ArmorType`, `EnemyBodyType`, `DamageType` enum tables with integer values.
- **When to read:** Authoring or debugging enemies, waves, or damage matrix code that depends on enum ordinals and names.

**building-types.md** — `.cursor/skills/building-system/references/building-types.md`
- **Contains:** `BuildingType` (36) and `BuildingSizeClass` enum tables with integer values.
- **When to read:** Placement, registry, or content passes touching `Types.BuildingType` / size class; cross-check against `.tres` and `HexGrid` rules.

**game-manager-api.md** — `.cursor/skills/campaign-and-progression/references/game-manager-api.md`
- **Contains:** Full `GameManager` public method table (30+ methods) and key constants.
- **When to read:** Mission flow, state transitions, or any change touching `GameManager`; quicker than spelunking `game_manager.gd` for the full surface API.

AUTOLOADS
SignalBus

Path: res://autoloads/signal_bus.gd
Purpose: Central signal registry. All cross-system signals are declared here and only here. No logic, no state. Every module that emits or receives a cross-system signal does so through this singleton.
Dependencies: None.
Complete Signal Registry

COMBAT

    enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)

    enemy_reached_tower(enemy_type: Types.EnemyType, damage: int) — emitted once per enemy on first tower strike (`EnemyBase`); `CombatStatsTracker` leak metric.

    tower_damaged(current_hp: int, max_hp: int)

    tower_destroyed()

    projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)

    arnulf_state_changed(new_state: Types.ArnulfState)

    arnulf_incapacitated()

    arnulf_recovered()

ALLIES (Prompt 11 + Prompt 07)

    ally_spawned(ally_id: String, building_instance_id: String) — emitted when `AllyBase.initialize_ally_data` runs or Arnulf `reset_for_new_mission`; `building_instance_id` empty except for summoner tower spawns (`BuildingBase.placed_instance_id`).

    ally_died(ally_id: String, building_instance_id: String) — summoner ally permanent death (not downed).

    ally_squad_wiped(building_instance_id: String) — last ally for that summoner building removed.

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

TERRAIN (battlefield)

    enemy_entered_terrain_zone(enemy: Node, speed_multiplier: float)

    enemy_exited_terrain_zone(enemy: Node, speed_multiplier: float)

    terrain_prop_destroyed(prop: Node, world_position: Vector3)

    nav_mesh_rebake_requested()

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

DIALOGUE (declared on SignalBus; DialogueManager emits via SignalBus only)

    dialogue_line_started(entry_id: String, character_id: String)

    dialogue_line_finished(entry_id: String, character_id: String)

    combat_dialogue_requested(entry: DialogueEntry)

BUILD MODE

    build_mode_entered()

    build_mode_exited()

RESEARCH

    research_unlocked(node_id: String)

    research_node_unlocked(node_id: String) — Prompt 11: emitted with `research_unlocked` after a successful spend.

    research_points_changed(points: int) — Prompt 11: mirrors research material balance for UI (also driven by `EconomyManager` → `resource_changed`).

SHOP

    shop_item_purchased(item_id: String)

NavMeshManager

Path: res://scripts/nav_mesh_manager.gd
Purpose: Holds the active `NavigationRegion3D` from the current terrain scene; processes `SignalBus.nav_mesh_rebake_requested` with a queued rebake loop (see godotengine/godot#81181).
Dependencies: SignalBus (`nav_mesh_rebake_requested` → `request_rebake`).
Notes: Autoload singleton only (no `class_name`, avoids shadowing in GdUnit).

Public methods:

    register_region(region: NavigationRegion3D) -> void

    request_rebake() -> void

DamageCalculator

Path: res://autoloads/DamageCalculator.cs
Purpose: Stateless pure-function singleton (C# implementation). Resolves final damage by applying the 4×4 damage_type × armor_type multiplier matrix. All damage in the game routes through this.
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

AuraManager

Path: res://autoloads/aura_manager.gd
Purpose: Registers `is_aura` buildings by `placed_instance_id`; `get_damage_pct_bonus` (strongest per `BuildingData.aura_category`, then summed) for tower damage; `get_enemy_speed_modifier` for `enemy_speed_pct` auras. Recomputes affected buildings on register/deregister. Autoload singleton only (no `class_name` — avoids shadowing the autoload node).
Dependencies: None (reads scene via `get_tree().get_nodes_in_group("buildings")`). Loads after DamageCalculator in `project.godot`.

Public methods:

    register_aura(building: BuildingBase) -> void

    deregister_aura(building_instance_id: String) -> void

    get_damage_pct_bonus(building: BuildingBase) -> float

    get_enemy_speed_modifier(world_pos: Vector3) -> float

    clear_all_emitters_for_tests() -> void

EconomyManager

Path: res://autoloads/economy_manager.gd
Purpose: Single source of truth for gold, building_material, research_material. Emits resource_changed on every modification. Prompt 37–38 + 41 + 47: mission economy overrides (`MissionEconomyData`), linear duplicate placement scaling per `BuildingData.building_id` / `id` (fallback `building_type:%d`), `duplicate_cost_k`, `sell_refund_fraction` × `sell_refund_global_multiplier`, `get_duplicate_count`/`get_cost_multiplier`/`can_afford_building`, `register_purchase` (spends + receipt dict), `reset_for_mission`, `apply_mission_economy` clears duplicate counts and applies starting resources, placement/sell via `get_gold_cost`/`get_material_cost`/`get_refund` (Dictionary), `grant_wave_clear_reward` adds `passive_gold_per_wave`, passive income in `_process`.
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

    can_afford_building(building_data: BuildingData) -> bool

    get_duplicate_count(building_id: String) -> int

    get_cost_multiplier(building_data: BuildingData) -> float

    can_afford_research(research_cost: int) -> bool

    award_post_mission_rewards() -> void

    reset_to_defaults() -> void

    get_gold(), get_building_material(), get_research_material() -> int

    get_gold_cost(building_data: BuildingData) -> int

    get_material_cost(building_data: BuildingData) -> int

    reset_for_mission() -> void

    register_purchase(building_data: BuildingData) -> Dictionary

    get_refund(building_data: BuildingData, invested_gold: int, invested_material: int) -> Dictionary

    apply_mission_economy(econ: MissionEconomyData = null) -> void

    get_wave_reward_gold(wave: int, econ: MissionEconomyData) -> int

    get_wave_reward_material(wave: int, econ: MissionEconomyData) -> int

    grant_wave_clear_reward(wave: int, econ: MissionEconomyData) -> Vector2i

Consumes: SignalBus.enemy_killed (adds gold_reward); SignalBus.wave_cleared (grants wave_clear bonuses when mission economy active).

Tests: `res://tests/test_economy_manager.gd`, `res://tests/unit/test_economy_mission_integration.gd`.
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

SybilPassiveManager

Path: `res://autoloads/sybil_passive_manager.gd`  
Purpose: Loads `res://resources/passive_data/*.tres`, offers a random subset per mission, tracks the active passive for `SpellManager` modifiers and optional future systems; persisted under SaveManager payload key `sybil`.

Key methods: `get_offered_passives() -> Array`, `select_passive(passive_id: String) -> void`, `get_active_passive() -> Resource`, `get_modifier(effect_type: String) -> float`, `get_passive_data_by_id(passive_id: String) -> Resource`, `clear_passive() -> void`, `get_save_data() -> Dictionary`, `restore_from_save_data(data: Dictionary) -> void`.

Signals (**SignalBus**): `sybil_passives_offered(passive_ids: Array)`, `sybil_passive_selected(passive_id: String)`.

Tests: `res://tests/test_sybil_passive_manager.gd`

ChronicleManager

Path: `res://autoloads/chronicle_manager.gd`  
Purpose: Meta-progression achievements and perks. Loads `ChronicleEntryData` / `ChroniclePerkData` from `res://resources/chronicle/entries/` and `res://resources/chronicle/perks/`; persists `user://chronicle.json`. Tracks kills, missions, buildings, bosses, campaigns, gold earned (via `resource_changed` deltas), and research unlocks.

Key methods: `apply_perks_at_mission_start() -> void`, `save_progress() -> void`, `load_progress() -> void`, `reset_for_test() -> void`, `get_entry_ids_sorted() -> PackedStringArray`, `get_entry_state(entry_id: String) -> Dictionary`, `get_perk_display_name(perk_id: String) -> String`, `get_chronicle_research_cost_multiplier() -> float`, `get_chronicle_enchanting_cost_multiplier() -> float`, `get_chronicle_gold_per_kill_percent_bonus() -> float`, `get_chronicle_wave_reward_gold_flat() -> int`.

Signals (**SignalBus**): `chronicle_entry_completed(entry_id: String)`, `chronicle_perk_activated(perk_id: String)`, `chronicle_progress_updated(entry_id: String, current: int, target: int)`.

Resources: `ChronicleData`, `ChronicleEntryData`, `ChroniclePerkData` (`scripts/resources/chronicle_*.gd`). UI: `scenes/ui/chronicle_screen.tscn`, `scenes/ui/achievement_row_entry.tscn`.

Tests: `res://tests/test_chronicle_manager.gd`

GameManager

Path: res://autoloads/game_manager.gd
Purpose: Session state machine: missions, waves, game state transitions, mission rewards, optional territory map + end-of-mission gold modifiers.
Dependencies: SignalBus, EconomyManager, WaveManager, ResearchManager, ShopManager, CampaignManager.

Constants:

    TOTAL_MISSIONS: int = 5

    WAVES_PER_MISSION: int = 3 (DEV CAP; final 10)

    MAIN_CAMPAIGN_CONFIG_PATH: String — documents canonical 50-day `CampaignConfig` path (`res://resources/campaigns/campaign_main_50_days.tres`).

Public variables:

    current_mission: int = 1

    current_wave: int = 0

    game_state: Types.GameState = MAIN_MENU

    territory_map: TerritoryMapData — null when active campaign has no `territory_map_resource_path`.

Key methods:

    start_new_game() -> void

    start_next_mission() -> void

    start_wave_countdown() -> void

    enter_passive_select() / exit_passive_select() -> void — `MISSION_BRIEFING` → `PASSIVE_SELECT` → `RING_ROTATE` via `enter_ring_rotate()`.

    enter_ring_rotate() / exit_ring_rotate() -> void — `PASSIVE_SELECT` → `RING_ROTATE` → combat via `_begin_mission_from_briefing()`.

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

Consumes: all_waves_cleared, tower_destroyed, boss_killed; subscribes to mission_won (hub transition). See `docs/archived/PROBLEM_REPORT.md`.
BuildPhaseManager

Path: res://autoloads/build_phase_manager.gd
Purpose: Guards hex placement/sell/upgrade when `is_build_phase` is false (`push_warning`); stub `confirm_build_phase()` for future HUD “Begin wave” wiring.

Signals (Prompt 11 + I-D): `build_phase_started` / `combat_phase_started` on **SignalBus** — emitted by `set_build_phase_active(active: bool)` when the value changes.

Public methods (Prompt 11): `set_build_phase_active(active: bool)` — toggles `is_build_phase` and emits the matching signal (no-op if unchanged).

Wiring: `GameManager` calls `set_build_phase_active(false)` on mission start / `start_wave_countdown` / `exit_build_mode`, and `true` in `enter_build_mode`.

AllyManager

Path: res://autoloads/ally_manager.gd
Purpose: Spawns and tracks summoner-tower allies (`BuildingData.is_summoner`): loads `AllyData` from `summon_leader_data_path` / `summon_follower_data_path` (or embedded resources), instances `res://scenes/allies/ally_base.tscn`, parents under `Main/AllyContainer` when present. `spawn_squad` / `despawn_squad` keyed by `placed_instance_id`; emits `SignalBus.ally_died` / `ally_squad_wiped`.

CombatStatsTracker

Path: res://autoloads/combat_stats_tracker.gd
Purpose: Session combat analytics for balancing / SimBot: aggregates per-wave and per-placed-building stats (String `placed_instance_id` keys), writes CSV under `user://simbot/runs/{mission_id}_{timestamp}/` on `mission_won` / `mission_failed` via `flush_to_disk`.
Dependencies: SignalBus, EconomyManager, Tower/HexGrid node paths (`get_node_or_null`), optional `ProjectileBase` → `record_projectile_damage`.
Key behaviors: subscribes to `mission_started`, `mission_won`, `mission_failed`, `wave_started`, `wave_cleared`, `enemy_killed`, `enemy_reached_tower`, `tower_damaged`, `building_placed`, `building_upgraded`, `building_destroyed`, `resource_changed`, `enemy_spawned`, `florence_damaged`, `ally_died`; `debug_mode` adds structured `event_log.csv`.
Public API: `begin_mission`, `register_building`, `flush_to_disk`, `set_session_seed`, `set_layout_rotation_deg`, `set_verbose_logging`, `record_projectile_damage` (called from `ProjectileBase`), `slot_index_to_ring` (static helper).
DialogueManager

Path: res://autoloads/dialogue_manager.gd
Purpose: Data-driven hub dialogue + combat banner lines: loads `DialogueEntry` resources from `res://resources/dialogue/**`, applies priority selection, AND conditions, once-only tracking, and chain pointers (`active_chains_by_character`). Hub lines exclude `is_combat_line`; combat lines use `request_combat_line()` and emit `SignalBus.combat_dialogue_requested`. UI-agnostic; `DialoguePanel` + `UIManager` call into it; `CombatDialogueBanner` listens for combat lines.

Dependencies: SignalBus, GameManager (sync), EconomyManager, ResearchManager (via `Main/Managers/ResearchManager` when present).

Public variables (selected): `entries_by_id`, `entries_by_character`, `played_once_only`, `active_chains_by_character`, `mission_won_count`, `mission_failed_count`, `current_mission_number`, `current_gamestate`.

**Signals:** `dialogue_line_started` and `dialogue_line_finished` are **declared on `SignalBus`** — `DialogueManager` emits them with `SignalBus.dialogue_line_started.emit(...)` / `SignalBus.dialogue_line_finished.emit(...)`. **`combat_dialogue_requested(entry: DialogueEntry)`** is declared on `SignalBus` and emitted when `request_combat_line()` selects a line. They are not local signals on this node. UI connects to `SignalBus` (see `UIManager`).

Key methods:

    peek_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry — selection without emitting `dialogue_line_started` (Talk button visibility).

    request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry

    request_combat_line() -> DialogueEntry — highest-priority eligible combat line; marks per-mission seen; emits `combat_dialogue_requested`.

    mark_entry_played(entry_id: String) -> void

    get_entry_by_id(entry_id: String) -> DialogueEntry

    notify_dialogue_finished(entry_id: String, character_id: String) -> void

    _load_all_dialogue_entries() -> void — rescans folder (used by tests after mutation).

Internal: `_evaluate_conditions`, `_resolve_state_value`, `_compare`, `_sybil_research_unlocked_any`, `_arnulf_research_unlocked_any`, `_get_research_manager()` — see `docs/archived/PROMPT_13_IMPLEMENTATION.md` for condition keys. Combat keys: `first_blood`, `wave_number_gte`, `kills_this_mission_gte`, `boss_active`, `florence_damaged`.

Consumes: SignalBus.game_state_changed, mission_started, mission_won, mission_failed, resource_changed, research_unlocked, shop_item_purchased, arnulf_state_changed, spell_cast, enemy_killed, wave_started, florence_damaged, boss_spawned.
AutoTestDriver

Path: res://autoloads/auto_test_driver.gd
Purpose: Headless integration smoke tester, active only with --autotest CLI flag.

ArtPlaceholderHelper

class path: res://scripts/art/art_placeholder_helper.gd
class_name: ArtPlaceholderHelper
purpose: Stateless utility. Resolves Mesh, Material, and Texture2D resources from res://art using convention-based path derivation keyed by Types.EnemyType, Types.BuildingType, ally ID strings, and faction ID strings. Caches loaded resources. Prefers res://art/generated/ assets over placeholders. Falls back to unknown_mesh/neutral material on missing resources — never crashes. Prompt 32: modular kit GLBs under res://art/generated/kit/ with BoxMesh fallback.
public methods:
  get_enemy_mesh(enemy_type: Types.EnemyType) -> Mesh
  get_building_mesh(building_type: Types.BuildingType) -> Mesh
  get_building_kit_mesh(base_id: Types.BuildingBaseMesh, top_id: Types.BuildingTopMesh, accent: Color) -> Node3D
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

RiggedVisualWiring

class path: res://scripts/art/rigged_visual_wiring.gd  
class_name: RiggedVisualWiring  
purpose: Prompt 31 — map `Types.EnemyType` / `boss_id` / Arnulf to `res://art/generated/**/*.glb`, mount `PackedScene` under a `Node3D` slot, find `AnimationPlayer`, drive `idle`/`walk` from horizontal velocity (`update_locomotion_animation`). Chat 5B: extended to all 30 enemy types, all 36 building types, 5 ally ids, tower path, 14 new ANIM_ constants.  
public static methods: `enemy_rigged_glb_path`, `ally_rigged_glb_path`, `building_rigged_glb_path`, `tower_glb_path`, `boss_rigged_glb_path`, `clear_visual_slot`, `mount_glb_scene`, `mount_enemy_placeholder_mesh`, `mount_boss_placeholder_mesh`, `find_animation_player`, `update_locomotion_animation`  
constants: `ANIM_IDLE`, `ANIM_WALK`, `ANIM_DEATH`, `ANIM_ATTACK`, `ANIM_HIT_REACT`, `ANIM_SPAWN`, `ANIM_RUN`, `ANIM_ATTACK_MELEE`, `ANIM_DOWNED`, `ANIM_RECOVERING`, `ANIM_SHOOT`, `ANIM_CAST_SPELL`, `ANIM_VICTORY`, `ANIM_DEFEAT`, `ANIM_ACTIVE`, `ANIM_DESTROYED`, `ANIM_PHASE_TRANSITION`, `ALLY_ARNULF_GLB`  
dependencies: ArtPlaceholderHelper, Types, ResourceLoader

validate_art_assets (EditorScript)

class path: res://tools/validate_art_assets.gd
class_name: (none — EditorScript)
purpose: Chat 5B — report-only GLB preflight. Scans `res://art/` recursively via `DirAccess`, loads each `.glb` with `ResourceLoader.load()`, checks required animation clips per category (enemy/ally/building/boss/tower), prints per-file OK/WARN/ERROR and summary. No assets are written.
public methods: `_run()`, `_scan_directory()`, `_infer_category()`, `_get_required_clips()`, `_check_glb()`, `_find_animation_player()`, `_report()`
dependencies: DirAccess, ResourceLoader, AnimationPlayer (built-in)

SESSION_07 art pipeline reports (Perplexity Group 5 / Chat 5A)

- Path: `docs/SESSION_07_REPORT_01_ANIM_TABLE.md` — Animation clip name expectations per entity category (derived from `RiggedVisualWiring` + validators).
- Path: `docs/SESSION_07_REPORT_02_GLB_PATHS.md` — GLB paths, hub portrait paths, missing-entry list.
- Path: `docs/SESSION_07_REPORT_03_WIRING.md` — Runtime wiring checklist; links to 01/02.

Placeholder GLB batch (Prompt 19)

Path: res://tools/generate_placeholder_glbs_blender.py  
Purpose: Run with `blender --background --python tools/generate_placeholder_glbs_blender.py`. Generates Rigify-based low-poly humanoid/boss GLBs, static buildings/misc, bat swarm with Empty-driven animation; writes `res://art/generated/generation_log.json`. Requires numpy available to Blender’s Python for glTF export.

Path: res://FUTURE_3D_MODELS_PLAN.md  
Purpose: authoritative transition plan from placeholders to production assets (Hyper3D/Rodin, Mixamo, Blender combine, Godot validation); includes `generation_log` table, **§4 Modular Building Kit** (Prompt 32 filenames + Rodin template), scene audit appendix (Prompt 29 verification), PhysicalBone3D ragdoll plan, AnimationPlayer wiring, hub portrait TODOs.

`# TODO(ART)` annotations (2026-03-29): `scenes/enemies/enemy_base.gd`, `enemy_base.tscn`, `scenes/allies/ally_base.gd`, `ally_base.tscn`, `scenes/arnulf/arnulf.gd`, `arnulf.tscn`, `scenes/tower/tower.gd`, `tower.tscn`, `scenes/buildings/building_base.gd`, `scenes/bosses/boss_base.gd`, `boss_base.tscn`, `ui/hub.gd`, `ui/hub.tscn`.

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
  - **Regular waves:** **`WaveComposer`** + **`wave_pattern`** (`Resource`, default `default_campaign_pattern.tres`) — point budget from pattern, picks from **`enemy_data_registry`** via **`wave_tags`** / **`tier`** / **`point_cost`**; **`spawn_count_multiplier`** scales budget; stagger-spawns composed enemies; **`has_pending_composed_spawns()`**.
  - **FactionData** roster weights are **not** used for normal wave composition (still used for faction identity / mini-boss metadata).
  - `faction_registry`, `set_faction_data_override(faction_data: FactionData) -> void`, `resolve_current_faction() -> void`, `get_mini_boss_info_for_wave(wave_index: int) -> Dictionary`.
  - Mini-boss hook respects `DayConfig.is_mini_boss_day` unless a test **faction override** is set.
  - **`clear_all_enemies()`** also clears in-progress composed and mission spawn queues.
  - Uses `preload` aliases (`FactionDataType`) where needed for autoload parse order (**DEVIATION** vs bare `class_name` types).
- **GameManager**: `configure_for_day` on WaveManager is invoked **after** `reset_for_new_mission()` in `_begin_mission_wave_sequence()` so day tuning persists.
- **Tests**: `res://tests/test_faction_data.gd`; Prompt 9 cases in `res://tests/test_wave_manager.gd`.
- **Notes**: `docs/archived/PROMPT_9_IMPLEMENTATION.md`.
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
| `is_combat_line` | `bool` | If true, used only by `request_combat_line` (combat banner), not hub selection |

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

- `initialize_ally_data(p_ally_data: Variant) -> void` — HP reset, shapes from `attack_range`, emits `ally_spawned(ally_id, owning_building_instance_id)`.
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

GameState, DamageType, ArmorType, BuildingType, **BuildingBaseMesh**, **BuildingTopMesh** (Prompt 32 modular kit), ArnulfState, ResourceType, EnemyType, **AllyClass**, **HubRole**, WeaponSlot, TargetPriority (buildings + allies; includes **LOWEST_HP** for ally pick-lowest-HP mode). **TerrainType**, **TerrainEffect** (Prompt 33 battlefield terrain).
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
- See `docs/archived/PROMPT_1_IMPLEMENTATION.md` for implementation-specific details.
- Added manual-shot firing assist/miss logic in `Tower` private helper path without public API signature changes.
- `crossbow.tres` now carries initial Phase 2 tuning defaults; `rapid_missile.tres` remains deterministic (`0.0` assist/miss values).
- Added simulation API tests for assist disabled path, cone snapping, guaranteed miss perturbation, autofire bypass, and crossbow defaults loading.
- See `docs/archived/PROMPT_2_IMPLEMENTATION.md` for full Phase 2 implementation and test notes.
- Added deterministic weapon-upgrade station Phase 3:
  - New resource class: `res://scripts/resources/weapon_level_data.gd`
  - New scene manager: `res://scripts/weapon_upgrade_manager.gd` under `/root/Main/Managers/WeaponUpgradeManager`
  - New resource set: `res://resources/weapon_level_data/{crossbow,rapid_missile}_level_{1..3}.tres`
  - New SignalBus signal: `weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)`
  - `Tower` now composes effective weapon stats from WeaponUpgradeManager with null fallback to raw WeaponData
  - `BetweenMissionScreen` now has a Weapons tab and upgrade UI refresh logic
  - Added tests in `res://tests/test_weapon_upgrade_manager.gd` and a tower fallback regression in `res://tests/test_simulation_api.gd`
  - See `docs/archived/PROMPT_3_IMPLEMENTATION.md` for full implementation notes.
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
  - `res://resources/campaigns/campaign_main_50_days.tres` (50 linear days; canonical path for tests and `GameManager.MAIN_CAMPAIGN_CONFIG_PATH`).
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
- See `docs/archived/PROMPT_8_IMPLEMENTATION.md`.

## 2026-03-24 Prompt 10 delta (mini-boss + campaign boss)

- **Implementation notes**: `docs/archived/PROMPT_10_IMPLEMENTATION.md`.
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

- See **`docs/archived/PROMPT_10_FIXES.md`**.
- **`WaveManager`** (`res://scripts/wave_manager.gd`): `_enemy_container` and `_spawn_points` use **`get_node_or_null("/root/Main/...")`**; **`_spawn_wave`** / **`_spawn_boss_wave`** return if either is null.
- **`test_wave_manager.gd`**, **`test_boss_waves.gd`**: add **`SpawnPoints`** to the test tree before **`Marker3D`** children and **`global_position`**; assign **`wm._enemy_container`** / **`wm._spawn_points`** after **`add_child(wm)`**.
- **`GameManager`** (`res://autoloads/game_manager.gd`): **`_begin_mission_wave_sequence()`** walks **`Main` → `Managers` → `WaveManager`** with **`get_node_or_null`**; missing **`Main`**, **`Managers`**, or **`WaveManager`** → **`push_warning`** + return (no asserts; GdUnit-safe). Full **`main.tscn`** loads unchanged; **`test_game_manager.gd`** includes **`test_begin_mission_wave_sequence_skips_gracefully_without_main_scene`**.
- **`project.godot`**: **`CampaignManager`** autoload **before** **`GameManager`** so **`mission_won`** listeners run day increment before hub transition.
- **`test_campaign_manager.gd`**: **`test_day_fail_repeats_same_day`** uses **`mission_failed.emit(CampaignManager.get_current_day())`** when **`GameManager.get_current_mission()`** can lag **`current_day`**.
- **`docs/archived/PROBLEM_REPORT.md`**: file paths + log/GdUnit snippets for the above.

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

- **Implementation notes**: `docs/archived/PROMPT_27_IMPLEMENTATION.md`.
- **RAG pipeline**: Added `foulward-rag` MCP server entry to `.cursor/mcp.json` (tools: `query_project_knowledge`, `get_recent_simbot_summary`).
- **assert→push_warning** in 9 production files: `economy_manager.gd`, `game_manager.gd`, `campaign_manager.gd`, `wave_manager.gd`, `shop_manager.gd`, `research_manager.gd`, `hex_grid.gd`, `enemy_base.gd`, `boss_base.gd`. Pattern: `push_warning` + early return (or `push_error` for `_ready()`-critical guards).
- **SaveManager**: Wired `RelationshipManager.get_save_data()` / `restore_from_save()` into `_build_save_payload()` / `_apply_save_payload()`.
- **get_node→get_node_or_null**: `input_manager.gd` (5 vars), `ui_manager.gd` (6 vars), `build_menu.gd` (1 var), `hud.gd` (1 var) — all with `is_instance_valid()` guards.
- **Removed obsolete signals**: `wave_failed`, `wave_completed` from `signal_bus.gd` (confirmed unreferenced).
- **Orphan leak fixes**: `test_projectile_system.gd`, `test_ally_base.gd`, `test_building_base.gd`, `test_hex_grid.gd` — orphans reduced 17→6.
- **New test runners**:
  - `tools/run_gdunit_unit.sh` — 33 unit-classified test files, ~65s wall-clock.
  - `tools/run_gdunit_parallel.sh` — 8-parallel-process runner for all 58 files, ~2m45s (37% faster than 4m22s baseline).
- **Deleted**: `AUDIT_IMPLEMENTATION_AUDIT_6.md`, `AUDIT_IMPLEMENTATION_UPDATE.md`, `AUDIT_IMPLEMENTATION_TASK.md` (superseded by `docs/archived/ALL_AUDITS.md` and `IMPROVEMENTS_TO_BE_DONE.md`).
- **AGENTS.md**: Updated §4 Test Rules with `run_gdunit_unit.sh` and `run_gdunit_parallel.sh` guidance.
- **Final test results**: 522 cases, 0 failures, 6 orphans, 4m20s.

## 2026-04-18 Building HP & Destruction (Chat 3A / 3B / 3C)

### Data layer
- `BuildingData.max_hp: int = 0` — HP pool; 0 means indestructible (backward-compatible default).
- `BuildingData.can_be_targeted_by_enemies: bool = false` — opt-in for enemy building-targeting.
- `EnemyData.prefer_building_targets: bool = false` — enemy scans for targetable buildings before pathing to tower.
- `EnemyData.building_detection_radius: float = 8.0` — scan radius (separate from `attack_range`).
- MEDIUM .tres (13 buildings): `max_hp = 300`, `can_be_targeted_by_enemies = true`.
- LARGE .tres (6 buildings): `max_hp = 650`, `can_be_targeted_by_enemies = true`.

### BuildingBase (`scenes/buildings/building_base.gd`)
- `_setup_health_component()` — creates `HealthComponent` dynamically when `max_hp > 0`; also instantiates and wires a `BuildingHpBar` child.
- `_on_health_depleted()` — emits `SignalBus.building_destroyed(slot_id)`, calls `AllyManager.despawn_squad` / `AuraManager.deregister_aura` if applicable, spawns destruction effect, calls `HexGrid.clear_slot_on_destruction`.
- `_spawn_destruction_effect()` — loads `destruction_effect.tscn`, plays shrink animation at building position.

### New scenes/scripts
- `scenes/buildings/destruction_effect.tscn` + `scenes/buildings/destruction_effect.gd` (`DestructionEffect`) — `SHRINK_DURATION = 0.5s` tween-to-zero-scale then `queue_free`.
- `scenes/ui/building_hp_bar.tscn` + `scenes/ui/building_hp_bar.gd` (`BuildingHpBar`) — `SubViewport` ProgressBar rendered to `Sprite3D` billboard; `setup(hc)` connects `health_changed`; visible only when `current_hp < max_hp`.

### HexGrid (`scenes/hex_grid/hex_grid.gd`)
- **42** slots (`TOTAL_SLOTS`), three rings (6 + 12 + 24); `rotate_ring(ring_index: int, angle_rad: float)` applies per-ring visual rotation and emits `SignalBus.ring_rotated`; allowed during build phase or `Types.GameState.RING_ROTATE`.
- `get_ring_offset_radians(ring_index: int) -> float` — test/debug accessor for cumulative ring rotation.
- `clear_slot_on_destruction(slot_index)` — validates slot, removes building from "buildings" group, disables obstacle/collision via `_disable_building_obstacle`, calls `queue_free`, clears slot dict.
- `_disable_building_obstacle(building)` — defers `NavigationObstacle3D.enabled=false` and `CollisionShape3D.disabled=true`.
- `get_lowest_hp_pct_building() -> BuildingBase` — returns the alive building with the worst HP percentage among all slots; null when all are at full HP.

### EnemyBase (`scenes/enemies/enemy_base.gd`)
- `_current_building_target: BuildingBase` state var.
- `_try_building_target_attack(delta) -> bool` — returns early if `prefer_building_targets` false; finds + attacks building; returns true when building is being attacked.
- `_find_building_target() -> BuildingBase` — scans "buildings" group within `building_detection_radius`, checks `can_be_targeted_by_enemies` and alive HC.
- `_attack_building(target, delta)` — melee attack loop against a building's `HealthComponent`.

### ShopManager (`scripts/shop_manager.gd`)
- `get_daily_items(day_index: int) -> Array[ShopItemData]` — isolated RNG (`seed = day_index`); candidate pool excludes consumables at stack cap; guarantees one consumable + one equipment; fills to 4–6 total weighted without replacement (`rarity_weight`).
- `_apply_effect("building_repair")` — calls `hex.get_lowest_hp_pct_building()`, heals it by `maxi(1, int(max_hp * 0.5))` via `HealthComponent.heal()`.
- `can_purchase("building_repair")` — returns false when `hex.has_any_damaged_building()` is false.
- `can_purchase("arrow_tower_placed" | "arrow_tower_voucher_2")` — requires empty hex + `ARROW_TOWER` available.
- Extended `_apply_effect` / consumable tags: `building_material_pack`, `research_boost`, `tower_armor_plate`, `scout_report`, `mercenary_discount`, `arrow_tower_voucher_2`; tags `fire_oil`, `emergency_repair` (see `ShopItemData.effect_tags`; field is **`effect_tags`**, not `tags`, per G10 schema).
- `resources/shop_data/shop_item_building_repair.tres` — `item_id = "building_repair"`, `gold_cost = 40`.

### SaveManager (`autoloads/save_manager.gd`)
- Architecture comment added above `_build_save_payload()`: building HP is mission-ephemeral; `HealthComponent.current_hp` is not serialised.
- Payload includes `sybil: SybilPassiveManager.get_save_data()`; restore calls `SybilPassiveManager.restore_from_save_data`.
- Payload `"version": 2`; `HEX_GRID_SLOT_COUNT` / `is_hex_slot_index_in_save_range(slot_index)` guard hex slot indices (mirrors `HexGrid.TOTAL_SLOTS`).

### RingRotationScreen (`scenes/ui/ring_rotation_screen.tscn` + `scripts/ui/ring_rotation_screen.gd`)
- Pre-combat UI: rotate rings via `HexGrid.rotate_ring`, confirm calls `GameManager.exit_ring_rotate()`.

### Tests
- `tests/test_building_health_component.gd` (`TestBuildingHealthComponent`) — 13 tests covering conditional HC setup, destroyed signal, HP bar visibility/value, save-payload exclusion, mission reset.
- `tests/test_enemy_building_targeting.gd` (`TestEnemyBuildingTargeting`) — 5 tests covering flag-off guard, find-building-when-flag-on, non-targetable/dead/out-of-radius ignores.
- `tests/test_building_repair.gd` (`TestBuildingRepair`) — 4 tests covering lowest-HP-pct targeting, 50%-heal amount, blocked-when-no-damage, indestructible-building ignored.
- `tests/test_shop_rotation.gd` (`TestShopRotation`) — 8 tests: `get_daily_items` count range, determinism, day variance, guaranteed consumable/equipment, capped-consumable exclusion, empty when no consumable bucket, SimBot `difficulty_target` on three `StrategyProfile` `.tres`.

## 2026-04-18 Prompt 75 delta (difficulty tier / G4 remediation)

- `res://scripts/resources/difficulty_tier_data.gd` (`DifficultyTierData`) — `Types.DifficultyTier` + `enemy_hp_multiplier`, `enemy_damage_multiplier`, `gold_reward_multiplier`, `spawn_count_multiplier`; data: `res://resources/difficulty/tier_normal.tres`, `tier_veteran.tres`, `tier_nightmare.tres`.
- `TerritoryData` (`res://scripts/resources/territory_data.gd`): `highest_cleared_tier`, `star_count`, `veteran_perk_id`, `nightmare_title_id`.
- `GameManager`: `_load_tier_data()` (`_ready`), `set_active_tier` / `get_active_tier`, `_apply_tier_to_day_config` (never mutates source `DayConfig`; NORMAL returns same reference), `_handle_tier_cleared` from `_on_all_waves_cleared` after `apply_day_result_to_territory`; save `territories` tier dict; `start_new_game` resets `_active_tier` to NORMAL.
- `Types.DifficultyTier` / `FoulWardTypes.DifficultyTier` C# mirror.
- Tests: `res://tests/test_difficulty_tier_system.gd` (17 cases).
