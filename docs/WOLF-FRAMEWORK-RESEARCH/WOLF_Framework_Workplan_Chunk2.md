# WOLF Framework — Master Workplan
## Chunk 2 of 5: Phase 1 Sessions S08–S14
### wolf-mcp Completion · Framework Core Extraction · All Addons · All Built-From-Scratch Systems

**Document version:** 1.0 | **Continues from:** Chunk 1 (S01–S07)
**Covers:** Sessions S08–S14 — the bulk of the framework's gameplay systems.
After S14, every system listed in the Open-Source Inventory document is present
in `wolf-framework`. Sessions S15–S20 (Chunk 3) wire, test, and ship it.

---

## Session S08 — wolf-mcp Complete (Remaining 7 Tools)

**Goal:** wolf-mcp exposes all 11 planned tools plus two additions
(`generate_character`, `generate_sfx`) so that every major framework operation
is callable from inside Cursor without leaving the editor.

**Perplexity context to load:**
- Chunk 1 of this workplan (decisions + S07 deliverables)
- Session Summary §3.6 — full 11-tool spec table
- S07 result report (what was already built)
- `wolf_mcp/server.py` current state (paste file contents)

**Key questions for this session:**
1. `add_building` — what fields does a `BuildingData.tres` need at minimum to be
   framework-generic (not Foul Ward specific)? What files does the scaffolder create?
2. `validate_signals` — what is the fastest way to parse `signal_bus.gd` and verify
   every declared signal is connected to at least one subscriber across the codebase?
3. `import_3d_asset` — godot-mcp-pro is optional (paid). How do we degrade gracefully
   when it is not present, using the free `coding-solo/godot-mcp` alternative instead?
4. `run_simbot` — SimBot lives in wolf-dev container; how does the MCP tool reach it?
   Direct subprocess or HTTP to a SimBot service endpoint?

**Cursor prompts to generate (7 prompts):**

1. Write `wolf_mcp/tools/scaffolders.py` addition — `add_building(building_id,
   category, slot_size, gold_cost, damage) -> str`; creates
   `resources/buildings/{building_id}.tres` from `BuildingData` template;
   creates `scripts/buildings/{building_id}.gd` extending `BuildingBase`;
   returns list of created files + any SignalBus wiring instructions

2. Write `wolf_mcp/tools/validation.py` — `validate_signals() -> str`;
   parses `autoloads/signal_bus.gd` with regex to collect all declared signal names;
   then greps entire codebase for each name; reports signals with zero connections
   (declared but never connected) and connections referencing undeclared signals;
   returns structured report with PASS / WARN / ERROR per signal

3. Write `wolf_mcp/tools/balance.py` — `get_balance_report(latest=True) -> str`;
   reads `tools/simbot/output/simbot_balance_report.md` (or latest timestamped file);
   returns full report text; if no report exists returns "No balance report found —
   run wolf simbot first"

4. Write `wolf_mcp/tools/simulation.py` — `run_simbot(profile_id, runs=10,
   seed=None, swarm=False) -> str`; calls `tools/simbot/simbot_swarm.py` via
   subprocess inside wolf-dev; streams stdout as tool response; returns path to
   output CSV when complete

5. Write `wolf_mcp/tools/assets.py` — `import_3d_asset(glb_path, category,
   faction, name) -> str`; detects if godot-mcp-pro is available in mcp.json;
   if yes: proxies to godot-mcp-pro's import tool via subprocess MCP call;
   if no: writes a `.import` resource file and returns instructions for manual
   import; always copies GLB to correct `assets/generated/{faction}/{category}/` path

6. Write `wolf_mcp/tools/generation.py` — `generate_character(name, faction,
   asset_type, rig_backend="mesh2motion") -> str` calls `pipelines/art/studio.py`
   via subprocess; streams progress; returns path to final GLB and manifest entry.
   `generate_sfx(prompt, category, duration=2.0) -> str` calls
   `pipelines/audio/stage1_audiocraft_sfx.py` + encode + drop chain; returns
   path to `.ogg` and `.tres`

7. Update `wolf_mcp/server.py` — register all new tool modules; update the tool
   manifest announced on startup; write `config/mcp/mcp.json.template` final version
   with all 11+ tools listed and their parameter schemas in comments;
   add `--list-tools` CLI flag to `wolf-mcp` command for quick reference

**Deliverables:**
- [ ] `wolf_mcp/tools/validation.py` — `validate_signals`
- [ ] `wolf_mcp/tools/balance.py` — `get_balance_report`
- [ ] `wolf_mcp/tools/simulation.py` — `run_simbot`
- [ ] `wolf_mcp/tools/assets.py` — `import_3d_asset`
- [ ] `wolf_mcp/tools/generation.py` — `generate_character`, `generate_sfx`
- [ ] `wolf_mcp/tools/scaffolders.py` updated — `add_building` added
- [ ] `wolf_mcp/server.py` updated — all 11+ tools registered
- [ ] `config/mcp/mcp.json.template` — final version with all tools
- [ ] All 11 tools callable from Cursor (verified via manual test in Cursor)
- [ ] `wolf-mcp --list-tools` prints full tool list (verified)

**Unlocks:** S15 (SimBot integration uses run_simbot tool), S16 (CI/CD tests
wolf-mcp tools), all Phase 2 sessions use scaffolders

---

## Session S09 — Framework Core Extraction from Foul Ward

**Goal:** Every architectural pattern that makes Foul Ward's codebase readable by
LLM agents is extracted, generalized, and placed in `wolf-framework/framework/templates/`
and `wolf-framework/framework/scenes/` — ready for any new game to copy and customize.

**Perplexity context to load:**
- Chunk 1 of this workplan
- MASTER_DOC §2, §3.1 (SignalBus), §5 (Types.gd), §2.4 (C# integration)
- MASTER_DOC §29 (Conventions for LLM agents)
- MASTER_DOC §30 (Anti-patterns catalogue)
- Session Summary §4.1 (extraction scope list)
- Open-Source Inventory §2.1 (SignalBus), §2.2 (FSM), §2.3 (Resource-driven data)

**Key questions for this session:**
1. Which of Foul Ward's 77 signals are Foul Ward-specific vs. genuinely generic
   strategy-game signals? Target: ~20 canonical signals for the template.
2. What is the minimum viable `MASTER_DOC_TEMPLATE.md` that a new game developer
   can fill in for their game in under an hour?
3. How should the GDQuest node-based FSM be pre-wired to the SignalBus template?
   What should the default states be for a generic unit?
4. What C# interop rules are universal vs. Foul Ward-specific?

**Cursor prompts to generate (8 prompts):**

1. Write `framework/templates/SignalBus.gd` — stripped from Foul Ward's 77-signal
   hub to ~20 canonical strategy-game signals organized by category:
   Economy (resource_changed, purchase_made, refund_issued),
   Combat (unit_spawned, unit_died, damage_dealt, wave_started, wave_cleared),
   Build (building_placed, building_sold, build_phase_started, combat_phase_started),
   UI (game_state_changed, screen_transition_requested),
   Meta (save_requested, load_requested, settings_changed);
   strict header comment: "No logic. No state. Signal declarations only."

2. Write `framework/templates/Types.gd` + `framework/templates/GameTypes.cs` —
   canonical enum template with the most common strategy-game enum categories:
   GameState, DamageType, ArmorType, FactionId, UnitRole, BuildingCategory,
   ResourceType, DifficultyTier; C# mirror with matching integer values;
   documented pattern for how to extend these per-game

3. Write `framework/templates/resources/UnitData.tres` template + accompanying
   `framework/templates/resources/UnitData.gd` — fields: unit_id, display_name,
   faction_id (FactionId enum), role (UnitRole enum), base_hp, movement_speed,
   attack_damage, attack_range, armor_type (ArmorType enum), is_flying, cost_gold;
   all typed exports, all @export decorated

4. Write `framework/templates/resources/BuildingData.tres` template + `.gd` —
   fields: building_id, display_name, category (BuildingCategory enum), slot_size,
   gold_cost, material_cost, base_damage, damage_type (DamageType enum),
   attack_range, is_aura, aura_radius, upgrade_levels (Array[BuildingUpgradeData]);
   BuildingUpgradeData nested resource: cost_gold, damage_multiplier, range_multiplier

5. Write `framework/templates/resources/WaveData.tres` template + `.gd` —
   fields: wave_index, spawn_groups (Array[SpawnGroupData]); SpawnGroupData nested:
   unit_id, count, spawn_delay_sec, spawn_point_id, path_id;
   documented pattern for directional and timed wave variants

6. Write `framework/templates/SavePayload.cs` — versioned save payload pattern
   from Foul Ward; SAVE_VERSION const; serialization helpers; migration stub
   `MigrateFromVersion(int oldVersion, Dictionary data)`;
   documented rule: "Add fields. Never remove. Increment SAVE_VERSION."

7. Write `framework/templates/MASTER_DOC_TEMPLATE.md` — the generalized version
   of Foul Ward's MASTER_DOC; sections: Project Identity (fill-in table), Core
   Architecture, Autoloads (init order table with EXISTS/PLANNED status), Scene-Bound
   Managers, Types enum table, Game States, Core Game Loop, Signal Bus Reference,
   Conventions for LLM Agents, Anti-Patterns, Formally Cut Features, Open TBD Items;
   every section has instructional comments in italics explaining what to fill in;
   target: LLM agent can read this and fully understand any game built on WOLF

8. Write `framework/templates/AGENTS.md` — generalized standing orders for Cursor
   agents working on a WOLF game; sections: read-first files, MCP habits (get_scene_tree
   before editing, check errors after every run), signal rules, test requirements,
   resource-driven data rules, forbidden patterns (hardcoded stats, logic in SignalBus,
   C# enums that diverge from Types.gd); this ships as the default AGENTS.md that
   `wolf new` places at the root of every new game

**Deliverables:**
- [ ] `framework/templates/SignalBus.gd` — 20 canonical signals
- [ ] `framework/templates/Types.gd`
- [ ] `framework/templates/GameTypes.cs`
- [ ] `framework/templates/resources/UnitData.gd` + `.tres`
- [ ] `framework/templates/resources/BuildingData.gd` + `.tres`
- [ ] `framework/templates/resources/WaveData.gd` + `.tres`
- [ ] `framework/templates/SavePayload.cs`
- [ ] `framework/templates/MASTER_DOC_TEMPLATE.md`
- [ ] `framework/templates/AGENTS.md`
- [ ] GDQuest FSM wired to SignalBus template in `framework/scenes/StateMachine/`

**Unlocks:** S10, S11 (addons build on top of these templates), all Phase 2 sessions

---

## Session S10 — Direct-Install Addons: Batch 1 (Core Gameplay)

**Goal:** The five most gameplay-critical addons are installed, verified working in
Godot 4.4, and each has a minimal demo scene in `framework/scenes/demos/` that
proves the addon works and shows the recommended integration pattern.

**Addons in this session:**
- GDQuest Steering AI Framework (Razoric / Nathan Lovato, MIT)
- Beehave behavior trees (bitbrain, MIT)
- Godot Gameplay Systems / GAS (OctoD, MIT)
- Card Framework (chun92/chunuiyu, MIT)
- Dialogue Manager (Nathan Hoad, MIT)

**Perplexity context to load:**
- Chunk 1 + Chunk 2 so far
- Open-Source Inventory §4.1 (Steering AI), §4.2 (Beehave), §2.6 (GAS),
  §6.5 (Card Framework), §6.6 (Dialogue Manager)
- `framework/templates/SignalBus.gd` (from S09)

**Key questions for this session:**
1. Steering AI: what is the recommended integration pattern for pre-wiring the
   Steering AI agent to a UnitBase scene that also uses the GAS attribute system?
2. Beehave: what is the minimum PatrolAttackBT.tscn that demonstrates the typical
   Patrol → ChaseNearest → Attack → RetreatIfLowHP tree?
3. GAS: how do we map GAS attributes to UnitData.tres so a unit spawned from a
   resource automatically gets the right HP, speed, and attack attributes?
4. Card Framework: what is the minimum Slay the Spire–style hand scene to prove
   draw/play/discard works?
5. Dialogue Manager: how do we wire a dialogue `.dialogue` file to SignalBus so
   that dialogue choices can trigger SignalBus events?

**Cursor prompts to generate (6 prompts):**

1. Install and configure GDQuest Steering AI Framework — add as git submodule to
   `framework/addons/steering-ai/`; write `framework/scenes/demos/SteeringDemo.tscn`
   with a Seek agent chasing a moving target; write `framework/scenes/UnitBase.tscn`
   with SteeringAgent2D pre-attached; document the `move_order_received` signal
   → set_target_position() wiring pattern in a code comment header

2. Install and configure Beehave — add as git submodule to
   `framework/addons/beehave/`; write `framework/scenes/demos/BeehaveDemo.tscn`
   with PatrolAttackBT behavior tree: Selector root → Sequence(IsLowHP →
   RetreatAction) → Sequence(CanSeeEnemy → ChaseAction → AttackAction) →
   PatrolAction; write `framework/scripts/ai/PatrolAttackBT.gd` with all
   condition and action nodes using GAS HP attribute for IsLowHP check

3. Install and configure Godot Gameplay Systems — add as git submodule to
   `framework/addons/gameplay-systems/`; write `framework/scenes/UnitBase.tscn`
   addition — attach AttributeSet with HP, AttackDamage, MovementSpeed populated
   from UnitData.tres on _ready(); write `framework/scripts/components/
   UnitAttributesBridge.gd` that reads UnitData resource and initializes GAS
   attributes; wire `unit_died` signal to SignalBus when HP reaches 0

4. Install and configure Card Framework — add as git submodule to
   `framework/addons/card-framework/`; write `framework/scenes/demos/
   CardHandDemo.tscn` — DeckResource with 10 test cards, hand of 5 drawn cards,
   drag-to-play area, discard pile, draw-5 button; document the `Card.tres`
   resource extension pattern (subclass Card for game-specific card data)

5. Install and configure Dialogue Manager — add as git submodule to
   `framework/addons/dialogue-manager/`; write `framework/scenes/demos/
   DialogueDemo.tscn` — NPC with a balloon dialogue; write example
   `framework/dialogues/npc_greeting.dialogue` with two branches and a condition;
   write `framework/scripts/DialogueBridge.gd` autoload that starts/ends dialogue
   and emits `dialogue_started(npc_id)` / `dialogue_ended(npc_id, choices_made)`
   to SignalBus

6. Write `framework/scenes/demos/README.md` — table of every demo scene, what addon
   it demonstrates, what game genre it is most relevant for, and what to look for
   when running it; this is the "kick the tyres" guide for new developers evaluating
   the framework

**Deliverables:**
- [ ] `framework/addons/steering-ai/` — git submodule, verified in Godot 4.4
- [ ] `framework/addons/beehave/` — git submodule, verified
- [ ] `framework/addons/gameplay-systems/` — git submodule, verified
- [ ] `framework/addons/card-framework/` — git submodule, verified
- [ ] `framework/addons/dialogue-manager/` — git submodule, verified
- [ ] `framework/scenes/UnitBase.tscn` — with SteeringAgent + GAS AttributeSet
- [ ] `framework/scenes/demos/SteeringDemo.tscn`
- [ ] `framework/scenes/demos/BeehaveDemo.tscn` with PatrolAttackBT
- [ ] `framework/scenes/demos/CardHandDemo.tscn`
- [ ] `framework/scenes/demos/DialogueDemo.tscn`
- [ ] `framework/scripts/components/UnitAttributesBridge.gd`
- [ ] `framework/scripts/DialogueBridge.gd` autoload
- [ ] `framework/scenes/demos/README.md`

**Unlocks:** S11, S12, S13; all Phase 2 games that use units, cards, or dialogue

---

## Session S11 — Direct-Install Addons: Batch 2 (Infrastructure & Specialised)

**Goal:** All remaining 13 direct-install addons are added as git submodules,
verified in Godot 4.4, and each has at minimum a one-line usage example in the
framework's `ADDONS.md` reference document.

**Addons in this session:**
Quest System · Phantom Camera · GodotSteam · GLoot Inventory · Terrain3D · Sky3D ·
Gaea · Sound Manager · Rollback Netcode · Mini Map · Fluid HTN · Godot Mod Loader ·
TimeTick

**Perplexity context to load:**
- Chunk 2, S10 deliverables list
- Open-Source Inventory §6.4 (Quest), §3.2 (Phantom Camera), §7.2 (GodotSteam),
  §2.5 (GLoot), §5.7 (Terrain3D + Sky3D + Gaea), §2.7 (Sound Manager),
  §7.1 (Rollback Netcode), §5.5 (Mini Map), §4.3 (Fluid HTN), §8.1 (Mod Loader),
  §5.8 (TimeTick)

**Key questions for this session:**
1. GodotSteam requires the Steamworks SDK. What is the correct way to document
   this as optional — present in the addon folder but requiring a user step to
   activate? How does `OS.has_feature("steam")` conditional initialization work?
2. Rollback Netcode requires 100% deterministic game logic. What is the minimum
   checklist in the framework docs for developers who want to use it?
3. Terrain3D + Sky3D are designed as a pair. Should they ship as a combined
   `framework/addons/world3d/` folder or separate submodules?
4. Fluid HTN: the C# original vs. the GDScript port — which do we ship as default?

**Cursor prompts to generate (5 prompts):**

1. Install Quest System, Phantom Camera, GLoot Inventory, Mini Map, TimeTick —
   all as git submodules to `framework/addons/`; for each: verify Godot 4.4
   compatibility; write a 3-line usage example; add entry to `ADDONS.md`

2. Install Sound Manager, Godot Mod Loader, GdUnit4 — as git submodules;
   write `framework/scripts/SoundBridge.gd` that wraps Sound Manager and routes
   all audio through SignalBus events (`sfx_play_requested(sound_id, position)`);
   write `mods-unpacked/ExampleMod/` demonstrating how to add one new unit type
   via mod; verify GdUnit4 test runner command works inside wolf-dev container

3. Install Terrain3D + Sky3D as paired submodules to `framework/addons/world3d/`;
   install Gaea to `framework/addons/gaea/`; write
   `framework/scenes/demos/World3DDemo.tscn` showing a Terrain3D landscape with
   Sky3D day-night cycle; write `framework/scenes/demos/GaeaDemo.tscn` showing
   a procedurally generated dungeon layout rendered to GridMap

4. Install Fluid HTN (GDScript port) to `framework/addons/fluid-htn/`;
   write `framework/scenes/demos/HTNDemo.tscn` — construction planner that
   builds a base: HTNDomain with tasks GatherResources → BuildBarracks →
   TrainUnit; document when to use HTN vs. Beehave (HTN = goal-driven planner
   for builder AI; Beehave = reactive FSM for individual unit combat AI)

5. Install GodotSteam + Rollback Netcode as optional modules to
   `framework/addons/optional/`; write `framework/scripts/platform/SteamManager.gd`
   autoload with `OS.has_feature("steam")` guard and graceful fallback;
   write `framework/docs/ROLLBACK_NETCODE_CHECKLIST.md` — the 8-point checklist
   developers must complete before enabling rollback: deterministic RNG, no
   floating-point divergence, input serialization format, state snapshot size budget,
   frame delay tuning, debug overlay setup, local rollback test procedure, peer test

**Deliverables:**
- [ ] All 13 addons installed as git submodules under `framework/addons/`
- [ ] `framework/docs/ADDONS.md` — complete reference: all 18 addons, one-line
      description, genre relevance, install status, license
- [ ] `framework/scripts/SoundBridge.gd`
- [ ] `mods-unpacked/ExampleMod/` — functional new-unit-type mod
- [ ] `framework/scenes/demos/World3DDemo.tscn`
- [ ] `framework/scenes/demos/GaeaDemo.tscn`
- [ ] `framework/scenes/demos/HTNDemo.tscn`
- [ ] `framework/scripts/platform/SteamManager.gd`
- [ ] `framework/docs/ROLLBACK_NETCODE_CHECKLIST.md`
- [ ] GdUnit4 confirmed running in wolf-dev container

**Unlocks:** S12 (map systems build on top of addons), S13, S15, all Phase 2 games

---

## Session S12 — Adapt-from-Recipe: Map & Camera Systems

**Goal:** Six map/camera systems that have no single perfect open-source addon
are assembled from documented recipes into clean, framework-native scripts with
full SignalBus wiring and demo scenes.

**Systems in this session:**
- HexGrid mathematics (Red Blob Games recipes → `HexGrid.gd` autoload)
- RTS Camera 2D + 3D (artokun + monxa Gists → `RTSCamera.gd` + `RTSCamera3D.gd`)
- Multi-unit selection + formations (KidsCanCode + LeProfesseurStagiaire)
- Fog of War 2D small-map (godot-open-rts port)
- Fog of War GPU large-map (Compute Shader Plus)
- Province map pipeline (OpenGS → Province Map Builder)

**Perplexity context to load:**
- Chunk 2, S11 deliverables
- Open-Source Inventory §5.2 (HexGrid), §3.1 (RTS Camera), §4.4 (Multi-unit select),
  §4.5 (Formations), §5.4 (FOW), §5.6 (Province maps)
- Session Summary §4.3 (adapt-from-recipe list with source links)

**Key questions for this session:**
1. HexGrid: which coordinate system — cube, axial, or offset — should be the
   framework default? (Recommendation: axial for storage + cube for math.)
   What autoload API surface covers 90% of use cases?
2. RTS Camera: what exported variables should be on `RTSCamera3D.gd` to make it
   immediately usable without code modification for most RTS games?
3. Multi-unit select: how does the rubber-band selection box interact with Godot 4's
   `Area2D.get_overlapping_bodies()` — what physics layer conventions apply?
4. FOW: when should a developer use the 2D texture approach vs. the GPU compute
   approach? What map size is the crossover point?
5. Province map: what is the exact pipeline from OpenGS Map Tool output to
   Province Map Builder runtime? What intermediate files are needed?

**Cursor prompts to generate (7 prompts):**

1. Write `framework/scripts/map/HexGrid.gd` autoload — axial coordinate storage,
   cube coordinate math; public API: `axial_to_world(coord) -> Vector2`,
   `world_to_axial(pos) -> Vector2i`, `axial_neighbors(coord) -> Array[Vector2i]`,
   `axial_ring(center, radius) -> Array[Vector2i]`,
   `axial_path(from, to) -> Array[Vector2i]` (A* over axial grid),
   `axial_distance(a, b) -> int`; credit comment: "Hex math by Amit Patel
   (redblobgames.com)"; write `framework/scenes/demos/HexGridDemo.tscn`

2. Write `framework/scripts/camera/RTSCamera.gd` (2D) and
   `framework/scripts/camera/RTSCamera3D.gd` (3D) — exported vars: pan_speed,
   zoom_speed, edge_scroll_margin, min_zoom, max_zoom, pan_keys (WASD + arrows);
   mouse edge-panning; zoom-to-cursor; drag-to-pan (middle mouse); snap-to-position
   tween; both emit `camera_moved(new_position)` to SignalBus; write
   `framework/scenes/demos/RTSCameraDemo.tscn` using 3D variant

3. Write `framework/scripts/selection/MultiUnitSelector.gd` — rubber-band selection
   box drawn as a Control node overlay; collects units inside box on mouse release;
   emits `units_selected(units: Array[Node])` to SignalBus; right-click emits
   `move_order_issued(position: Vector2, selected_units: Array[Node])`;
   write `framework/scripts/selection/FormationManager.gd` — slot-based formation
   positions around a formation anchor; presets: LINE, WEDGE, CIRCLE, SQUARE;
   demo scene `framework/scenes/demos/SelectionFormationDemo.tscn`

4. Write `framework/scripts/map/FogOfWar2D.gd` — ported from godot-open-rts
   (Pawel Lampe, MIT); 2-channel Image texture approach (red = currently visible,
   green = previously explored); updates on 0.1s timer; takes Array[Node2D] of
   units as vision sources; recommended for maps up to 256×256 tiles;
   credit comment with Pawel Lampe attribution; demo scene
   `framework/scenes/demos/FogOfWarDemo.tscn`

5. Write `framework/scripts/map/FogOfWarGPU.gd` — uses DevPoodle's Compute Shader
   Plus (`framework/addons/compute-shader-plus/`); GLSL compute kernel for large
   maps (512×512+); same API surface as FogOfWar2D for drop-in replacement;
   add Compute Shader Plus as git submodule to `framework/addons/`

6. Write province map pipeline documentation and runtime script —
   `framework/docs/PROVINCE_MAP_PIPELINE.md` explaining the two-step process:
   (1) OpenGS Map Tool generates province colour image + metadata JSON from a
   hand-drawn input image; (2) Province Map Builder addon handles runtime
   click detection; write `framework/scripts/map/ProvinceMapManager.gd` autoload
   that loads Province Map Builder data and emits `province_clicked(province_id)`,
   `province_ownership_changed(province_id, new_faction_id)` to SignalBus

7. Write `framework/scripts/map/MinimapManager.gd` — wrapper around the Mini Map
   addon (sumri); configures unit and building icon tracking; exposes
   `register_tracked_unit(unit, icon_texture)` and
   `register_tracked_building(building, icon_texture)`; wires to SignalBus:
   on `unit_died` deregisters automatically; demo scene integrated into
   `RTSCameraDemo.tscn` as an overlay

**Deliverables:**
- [ ] `framework/scripts/map/HexGrid.gd`
- [ ] `framework/scripts/camera/RTSCamera.gd`
- [ ] `framework/scripts/camera/RTSCamera3D.gd`
- [ ] `framework/scripts/selection/MultiUnitSelector.gd`
- [ ] `framework/scripts/selection/FormationManager.gd`
- [ ] `framework/scripts/map/FogOfWar2D.gd`
- [ ] `framework/scripts/map/FogOfWarGPU.gd`
- [ ] `framework/addons/compute-shader-plus/` submodule
- [ ] `framework/scripts/map/ProvinceMapManager.gd`
- [ ] `framework/docs/PROVINCE_MAP_PIPELINE.md`
- [ ] `framework/scripts/map/MinimapManager.gd`
- [ ] Demo scenes: HexGridDemo, RTSCameraDemo, SelectionFormationDemo, FogOfWarDemo
- [ ] `framework/docs/FOW_SELECTION_GUIDE.md` — when to use which FOW variant

**Unlocks:** All strategy/RTS genre Phase 2 games (S31, S32, S33, S34, S35)

---

## Session S13 — Build-from-Scratch: Economy, Spread, Factions, Tech Tree

**Goal:** The four most complex original systems are built, tested with GdUnit4,
and have demo scenes. These systems have no direct open-source equivalent and
represent the framework's most unique contributions to the Godot ecosystem.

**Systems in this session:**
- `FlowEconomyManager.gd` — Total Annihilation nanostall rate-based economy
- `ContagionManager.gd` — SIR cellular-automaton spread simulation
- `FactionManager.gd` + `FactionData.tres` — generalized faction/relationship system
- `TechTreeUI.gd` — GraphEdit-based research tree UI

**Perplexity context to load:**
- Chunk 2, S09 (Types.gd + SignalBus templates)
- Open-Source Inventory §6.1 (Flow Economy + GPL warning), §6.2 (Contagion/SIR),
  §6.3 (Faction System), §6.7 (Tech Tree)
- MASTER_DOC §5 (RelationshipManager and EconomyManager APIs — for reference/contrast)
- Session Summary §4.4 (build-from-scratch table)

**Key questions for this session:**
1. FlowEconomyManager: what are the minimum fields for the `balance_guardrails.tres`
   resource that bounds the economy optimiser? What signals does this manager emit?
2. ContagionManager: should the SIR simulation run on the HexGrid coordinate system,
   a free GridMap, or both? What is the recommended tick rate?
3. FactionManager: how does the framework's generalized FactionManager relate to
   Foul Ward's RelationshipManager? Are they the same system generalized, or different
   systems serving different needs?
4. TechTreeUI: what is the data model — flat list of nodes with prerequisite links,
   or a tree structure? How does a player "researching" a node get represented?

**Cursor prompts to generate (7 prompts):**

1. Write `framework/scripts/economy/FlowEconomyManager.gd` autoload —
   Total Annihilation nanostall model: track income_rate (metal/energy per second),
   expenditure_rate, buffer (current stockpile), buffer_max; when buffer empties,
   proportionally slow all active build tasks (nanostall); signals:
   `flow_resource_changed(resource_type, rate, buffer)`,
   `nanostall_started(resource_type)`, `nanostall_cleared(resource_type)`;
   compatible with existing discrete EconomyManager — FlowEconomy handles
   rate resources (metal, energy, mana regen) while EconomyManager handles
   discrete pools (gold, build materials); write 8 GdUnit4 tests covering
   income calculation, stall detection, and stall recovery

2. Write `framework/templates/resources/balance_guardrails.tres` resource +
   `BalanceGuardrails.gd` — fields: min_income_metal, max_income_metal,
   min_unit_hp, max_unit_hp, max_dps_per_gold, convergence_tolerance_pct,
   consecutive_convergence_batches_required; this bounds the SimBot economy
   optimiser so auto-balance never produces degenerate outcomes

3. Write `framework/scripts/simulation/ContagionManager.gd` autoload — SIR
   cellular automaton over a Dictionary-keyed grid (compatible with HexGrid.gd
   axial coords OR flat tile indices); parameters: beta (infection rate),
   gamma (recovery rate), tick_interval_sec; per-cell states: S/I/R;
   signals: `infection_spread(cell_coord, new_count)`,
   `outbreak_started(origin_coord)`, `outbreak_resolved()`;
   expose `set_simulation_grid(grid: Dictionary)` and
   `seed_infection(coord, initial_infected: int)`;
   write 6 GdUnit4 tests covering basic spread, recovery, and containment;
   demo scene `framework/scenes/demos/ContagionDemo.tscn` on a 20×20 hex grid

4. Write `framework/scripts/world/FactionManager.gd` autoload —
   generalisation of Foul Ward's RelationshipManager but covering faction-to-faction
   rather than player-to-NPC; relationship matrix:
   `Dictionary[faction_id, Dictionary[faction_id, RelationshipState]]`;
   `RelationshipState` enum: WAR / HOSTILE / NEUTRAL / FRIENDLY / ALLIED;
   API: `declare_war(a, b)`, `form_alliance(a, b)`, `get_relationship(a, b)`,
   `is_enemy(a, b) -> bool`; signals: `war_declared(faction_a, faction_b)`,
   `alliance_formed(faction_a, faction_b)`, `relationship_changed(a, b, new_state)`;
   write `FactionData.tres` resource: faction_id, display_name, color, starting_gold,
   starting_relationships Dictionary; write 6 GdUnit4 tests

5. Write `framework/scripts/world/TechTreeUI.gd` — Godot native `GraphEdit` +
   `GraphNode` UI for research trees; data model: `ResearchNodeData.tres` resource
   (node_id, display_name, description, cost_research_points, prerequisite_ids
   Array[String], effect_description, is_unlocked); TechTreeUI reads an
   Array[ResearchNodeData] and auto-layouts nodes using prerequisite depth;
   signals: `research_node_selected(node_id)`,
   `research_node_unlocked(node_id, by_faction_id)`;
   demo scene `framework/scenes/demos/TechTreeDemo.tscn` with 12 sample nodes
   in a 3-tier tree

6. Write `framework/templates/resources/ResearchNodeData.gd` + `.tres` template
   (used by TechTreeUI); write 5 GdUnit4 tests for TechTreeUI covering:
   prerequisite validation (can't unlock node without prerequisites),
   cost deduction integration with EconomyManager's `spend_research_material`,
   unlock cascade (unlocking a node makes children available),
   save/load of unlock state via the framework SavePayload pattern

7. Write `framework/scenes/demos/EconomySystemsDemo.tscn` — side-by-side demo of
   both economy models: left panel shows discrete EconomyManager (gold pool, buy
   button, refund); right panel shows FlowEconomyManager (income rate slider,
   expenditure rate slider, live buffer bar, nanostall indicator); labels explain
   which games use which model

**Deliverables:**
- [ ] `framework/scripts/economy/FlowEconomyManager.gd` autoload
- [ ] `framework/templates/resources/BalanceGuardrails.gd` + `.tres`
- [ ] `framework/scripts/simulation/ContagionManager.gd` autoload
- [ ] `framework/scripts/world/FactionManager.gd` autoload
- [ ] `framework/templates/resources/FactionData.gd` + `.tres`
- [ ] `framework/scripts/world/TechTreeUI.gd`
- [ ] `framework/templates/resources/ResearchNodeData.gd` + `.tres`
- [ ] Demo scenes: ContagionDemo, TechTreeDemo, EconomySystemsDemo
- [ ] GdUnit4 tests: FlowEconomy (8), Contagion (6), FactionManager (6), TechTreeUI (5)
- [ ] All 25 new tests passing in parallel runner

**Unlocks:** S14, S15 (balance_guardrails.tres needed for SimBot optimiser),
S31 (Northgard), S32 (Frostpunk), S33 (TA clone), S34 (Majesty)

---

## Session S14 — Build-from-Scratch: Targeting, Replay, Localisation, Autobattler

**Goal:** The four remaining build-from-scratch systems are built and tested,
completing the full set of systems listed in the Open-Source Inventory document.
After this session, every system in the framework exists in code.

**Systems in this session:**
- `TargetSelector.gd` — four-mode targeting component
- `ReplayRecorder.gd` + `ReplayPlayer.gd` — frame-counter input replay system
- Localisation scaffold — `en.po` + `pl.po` stubs, `Localisation.gd` wrapper
- Autobattler framework — from guladam base, wired to GAS + SignalBus

**Perplexity context to load:**
- Chunk 2, S13 deliverables
- Open-Source Inventory §4.6 (Targeting), §8.2 (Replay), §9 (Localisation),
  §6.8 (Autobattler)
- `framework/templates/SignalBus.gd` (from S09) — need to add replay signals

**Key questions for this session:**
1. TargetSelector: should it be a standalone Node component or a static utility class?
   How does it interact with GAS HP attributes for LOWEST_HP / HIGHEST_HP modes?
2. ReplayRecorder: input-change-only recording vs. every-frame snapshot — which
   is more practical for strategy games where inputs are sparse?
3. Localisation: Godot 4 has native .po support. What does the `Localisation.gd`
   wrapper add that Godot's `TranslationServer` doesn't already provide?
4. Autobattler: the guladam base uses a component-based UnitStats resource.
   How do we bridge this to the framework's GAS-based UnitAttributesBridge?

**Cursor prompts to generate (6 prompts):**

1. Write `framework/scripts/components/TargetSelector.gd` — Node component;
   exported `mode: TargetMode` enum (NEAREST, FARTHEST, LOWEST_HP, HIGHEST_HP,
   RANDOM); exported `detection_radius: float`; exported `faction_filter: FactionId`
   (targets only this faction, or ALL if not set); uses `Area2D.get_overlapping_bodies()`
   for detection; HP queries via `UnitAttributesBridge.get_hp(unit)`;
   public API: `get_target() -> Node`; updates on a configurable timer tick;
   write `framework/scenes/demos/TargetSelectorDemo.tscn` with 5 dummy units
   and a live mode switcher showing different targets highlighted;
   write 5 GdUnit4 tests (one per mode)

2. Write `framework/scripts/replay/ReplayRecorder.gd` — input-change-only recording;
   records frame number, action name, pressed/released, and analog value on change;
   exports to `Dictionary` serializable via SavePayload; signals:
   `recording_started()`, `recording_stopped(frame_count: int)`;
   write `framework/scripts/replay/ReplayPlayer.gd` — reads recorded Dictionary,
   replays inputs via `Input.parse_input_event()`; signals:
   `playback_started()`, `playback_finished()`; add both to SignalBus template;
   write `framework/scenes/demos/ReplayDemo.tscn` — record button, play button,
   simple pawn that moves with WASD; verify recording and playback match

3. Write `framework/scripts/i18n/Localisation.gd` autoload — wraps
   `TranslationServer`; adds: `tr_format(key, args: Dictionary) -> String`
   (substitutes {name}, {count} etc. into translated strings); `set_locale_from_system()`
   on startup; signal `locale_changed(new_locale)` to SignalBus;
   write `framework/locale/en.po` stub with 20 example strings covering common
   strategy UI (resource names, button labels, status messages);
   write `framework/locale/pl.po` stub with same 20 strings translated to Polish;
   write `framework/docs/LOCALISATION_GUIDE.md` — how to add a new language,
   how to use POEdit or Weblate, how Dialogue Manager .dialogue files integrate
   with gettext

4. Write autobattler framework base — study guladam's component architecture;
   write `framework/scripts/autobattler/AutobattlerUnit.gd` extending UnitBase.tscn
   pattern; fields from GAS AttributeSet (HP, AttackDamage, AttackSpeed, Range);
   auto-attack state machine: IDLE → SCAN → APPROACH → ATTACK → COOLDOWN → SCAN;
   targeting uses TargetSelector component (NEAREST enemy by default);
   write `framework/scripts/autobattler/BoardManager.gd` — manages hex board,
   bench positions, drag-place unit logic, valid placement highlighting;
   signals: `unit_placed(unit, cell)`, `unit_benched(unit)`,
   `combat_round_started()`, `combat_round_ended(winner_side)`

5. Write `framework/scenes/demos/AutobattlerDemo.tscn` — 6×4 hex board; bench
   of 4 placeable units; Start Combat button; 2 rounds of auto-battle with
   visual HP bars above units; End screen showing winner; uses WOLFCharacterBase
   meshes (Soldier vs. Orc from the character pool);
   write 4 GdUnit4 tests: unit placement validation, attack targeting, HP depletion,
   round resolution

6. Write `framework/docs/SYSTEMS_REFERENCE.md` — the definitive one-page index
   of every system in the framework: system name, script path, type (autoload /
   component / addon / scene), brief description, which demo scene shows it,
   which game genres use it most; this is the single document a developer reads
   to understand what the framework can do without opening any code

**Deliverables:**
- [ ] `framework/scripts/components/TargetSelector.gd`
- [ ] `framework/scripts/replay/ReplayRecorder.gd`
- [ ] `framework/scripts/replay/ReplayPlayer.gd`
- [ ] `framework/scripts/i18n/Localisation.gd` autoload
- [ ] `framework/locale/en.po` (20 example strings)
- [ ] `framework/locale/pl.po` (20 Polish translations)
- [ ] `framework/docs/LOCALISATION_GUIDE.md`
- [ ] `framework/scripts/autobattler/AutobattlerUnit.gd`
- [ ] `framework/scripts/autobattler/BoardManager.gd`
- [ ] Demo scenes: TargetSelectorDemo, ReplayDemo, AutobattlerDemo
- [ ] GdUnit4 tests: TargetSelector (5), Replay (3), Autobattler (4)
- [ ] `framework/docs/SYSTEMS_REFERENCE.md` — complete index of all systems

**Unlocks:** S15, S16, S20 (integration test), all Phase 2 games, S39 (docs site
can reference SYSTEMS_REFERENCE.md directly)

---

## Phase 1, S08–S14 — Session Status Tracker

| Session | Title | Depends on | Status |
|---------|-------|-----------|--------|
| S08 | wolf-mcp complete (7 remaining tools) | S07 | ⏳ |
| S09 | Framework core extraction from Foul Ward | Phase 0, S01 | ⏳ |
| S10 | Direct-install addons batch 1 (5 addons) | S09 | ⏳ |
| S11 | Direct-install addons batch 2 (13 addons) | S10 | ⏳ |
| S12 | Map + camera systems (adapt from recipe) | S09, S11 | ⏳ |
| S13 | Economy, Spread, Factions, Tech Tree (build) | S09, S12 | ⏳ |
| S14 | Targeting, Replay, Localisation, Autobattler | S10, S13 | ⏳ |

---

## Cumulative Framework Inventory After S14

At the end of S14, `wolf-framework` contains the following (complete list):

**From Foul Ward (extracted):**
SignalBus template · Types.gd + GameTypes.cs · UnitData/BuildingData/WaveData resources ·
SavePayload.cs · MASTER_DOC_TEMPLATE.md · AGENTS.md template

**Direct-install addons (18):**
Steering AI · Beehave · GAS (Gameplay Systems) · Card Framework · Dialogue Manager ·
Sound Manager · Quest System · Phantom Camera · GodotSteam · GLoot · Terrain3D · Sky3D ·
Gaea · Rollback Netcode · Mini Map · Fluid HTN · Godot Mod Loader · TimeTick

**Adapted from recipes (11 scripts):**
HexGrid.gd · RTSCamera.gd · RTSCamera3D.gd · MultiUnitSelector.gd · FormationManager.gd ·
FogOfWar2D.gd · FogOfWarGPU.gd · ProvinceMapManager.gd · MinimapManager.gd ·
SoundBridge.gd · DialogueBridge.gd

**Built from scratch (13 scripts):**
FlowEconomyManager.gd · ContagionManager.gd · FactionManager.gd · TechTreeUI.gd ·
TargetSelector.gd · ReplayRecorder.gd · ReplayPlayer.gd · Localisation.gd ·
AutobattlerUnit.gd · BoardManager.gd · SteamManager.gd · UnitAttributesBridge.gd ·
WOLFCharacterBase.tscn

**AI Pipelines:**
Art (5 stages, studio.py) · Audio (3 stages) · RAG (3-corpus, per-game config)

**Tooling:**
wolf-mcp (11+ tools) · wolf CLI · GdUnit4 + parallel runner · docker-dev + docker-art

*End of Chunk 2. Chunk 3 covers Phase 1 sessions S15–S20: SimBot integration,
CI/CD, the wolf CLI tool, Cursor skills pack, MASTER_DOC automation, and the
final integration test that proves the complete framework works together.*
