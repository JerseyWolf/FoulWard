# WOLF Framework — Master Workplan
## Chunk 4a of 5: Phase 2 Sessions S21–S25
### Demo Games Part 1: Tower Defense MVPs · RTS MVPs · Card Roguelite MVP

**Document version:** 1.0 | **Continues from:** Chunk 3 (S15–S20)
**Covers:** The first five Phase 2 game sessions.
**Prerequisites:** All Phase 1 sessions complete; S20 integration test passed;
`PHASE1_ACCEPTANCE_REPORT.md` committed to `wolf-framework` main.

---

## Phase 2 Overview: All 18 Sessions at a Glance

Before diving into the first five sessions, the full Phase 2 map is recorded here
so every subsequent Chunk 4 sub-document can reference it.

| Session | Game Name | Genre | Primary New Systems Exercised |
|---------|-----------|-------|-------------------------------|
| S21 | WOLF-TD | Tower Defense (TAUR) | WaveData, Beehave enemy AI, TargetSelector, FOW2D |
| S22 | WOLF-TD-GRID | Tower Defense (Classic) | BuildingBase grid placement, path enemies, flow upkeep |
| S23 | WOLF-RTS | RTS (Warcraft-style) | FlowEconomy, SteeringAI, MultiUnitSelector, TechTreeUI |
| S24 | WOLF-FLOW-RTS | RTS (TA-style) | FlowEconomy nanostall, HTN constructor AI, BalanceGuardrails |
| S25 | WOLF-CARD | Card Roguelite | Card Framework, GAS status effects, run-state save |
| S26 | WOLF-DECKBUILDER | Card Campaign | Persistent card collection, meta-progression SavePayload |
| S27 | WOLF-GRAND | Grand Strategy | Province map, FactionManager, TechTree, TimeTick turns |
| S28 | WOLF-CRISIS | Survival Management | FlowEconomy crisis, Contagion spread, discrete choice events |
| S29 | WOLF-AUTO | Autobattler MVP | BoardManager, GAS combat, shop phase, round resolution |
| S30 | WOLF-SYNERGY | Autobattler Extended | Unit synergy system, reroll shop, 6-round campaign |
| S31 | WOLF-DUNGEON | Dungeon Keeper | Voxel dig, Fluid HTN creature AI, hero patrol waves |
| S32 | WOLF-NECRO | Dungeon Keeper variant | Contagion as room corruption, undead faction |
| S33 | WOLF-SURVIVAL | Hybrid TD + Province | Province control + night-wave defense, seasons |
| S34 | WOLF-NARRATIVE | Narrative RPG | DialogueBridge, Quest system, RelationshipManager |
| S35 | WOLF-ROGUE | Roguelite Dungeon | Gaea rooms, autobattler combat, card reward choices |
| S36 | WOLF-SHOWCASE | Demo Launcher | Menu scene loading all other demos, WOLF branding |
| S37 | Balance Pass | — | SimBot optimiser run across all 6 core MVPs |
| S38 | Asset Pass | — | studio.py + AudioCraft full pass for all games |

Each of S21–S36 produces a self-contained, playable Godot project in
`wolf-games/{game-name}/` with its own MASTER_DOC.md, AGENTS.md, and test suite.
The MVP definition for each: 1 map, 1 faction pair, 5–10 units/cards/provinces,
3 buildings/towers/rooms, 1 win condition, playable in under 10 minutes.

---

## Session S21 — WOLF-TD: Tower Defense MVP (TAUR Pattern)

**Goal:** A minimal but complete tower defense in the TAUR pattern (player
character IS the tower, manually aimed with mouse) that proves the framework
can reproduce the core Foul Ward loop without touching Foul Ward's codebase —
using only generalised framework templates.

**The game in one sentence:** Survive 5 enemy waves in a hex arena by manually
aiming your plague-doctor character at approaching enemies while your AI companion
Grimsby (a generalised Arnulf) tanks the frontline.

**Framework systems exercised:**
- `WaveData.tres` + spawner (path-following enemies)
- `UnitBase.tscn` + `UnitData.tres` (player character, Grimsby, 3 enemy types)
- `Beehave` PatrolAttackBT tree (Grimsby AI, enemy approach AI)
- `GAS` AttributeSet (HP, attack damage for all units)
- `EconomyManager` (gold from kills → buy barricades in build phase)
- `TargetSelector` (NEAREST mode for Grimsby auto-attack)
- `FogOfWar2D` (limited vision in later waves)
- `DialogueBridge` (tutorial after wave 1)
- `SoundBridge` + generated SFX (attack, hit, wave-start, wave-clear)
- `SignalBus` signals: `wave_started`, `wave_cleared`, `unit_died`, `unit_spawned`

**Perplexity context to load:**
- Chunks 1–3 (full workplan so far)
- MASTER_DOC §8 (Combat Loop), §12 (Wave system), §13 (Build Phase)
- `framework/templates/SignalBus.gd` (S09 deliverable)
- `framework/scenes/demos/BeehaveDemo.tscn` + `UnitBase.tscn` (S10 deliverables)
- Session Summary §6 (tower defense genre description)

**Key questions for this session:**
1. The player character needs to be stationary but mouse-aimed. What is the
   correct Godot 4 pattern: a `RigidBody2D` with `freeze = true` + rotation
   towards mouse, or a `StaticBody2D` with a `Marker2D` for aim direction?
2. Projectiles: should they use `Area2D` sweep detection or `CharacterBody2D`
   move-and-collide? What is the recommended WOLF pattern for hitscan vs.
   projectile weapons?
3. Build phase UI: the player buys barricades on a hex grid. How does the
   `HexGrid.gd` autoload feed valid placement cells to the purchase UI?
4. How do we enforce the "5-wave survival = win" condition cleanly through
   SignalBus without storing win state in a scene node?

**Cursor prompts to generate (6 prompts):**

1. Scaffold WOLF-TD project — run `wolf new wolf-td --genre tower-defense`;
   fill in `docs/MASTER_DOC.md`: game name = "WOLF-TD", genre = Tower Defense,
   player count = 1, target session length = 8 minutes; wire autoloads:
   SignalBus, EconomyManager, FlowEconomyManager (inactive, declared), FactionManager,
   HexGrid, Localisation, DialogueBridge, SoundBridge; run `wolf doc generate` to
   verify autoloads table auto-fills correctly; commit initial scaffold

2. Write `scenes/Arena.tscn` — 11×9 hex tile map (TileMapLayer with hex offset);
   three enemy spawn points at map edges; player start position at centre;
   five camera-anchored wave-spawn markers; `scripts/ArenaManager.gd` autoload:
   listens to `wave_started(wave_index)` from SignalBus, loads the correct
   `WaveData.tres`, calls spawner; listens to `unit_died` and increments kill
   counter; emits `wave_cleared` when all enemies dead; emits `game_won` after
   wave 5 cleared; emits `game_lost` when player HP reaches 0

3. Write `scripts/player/PlayerTower.gd` extending `CharacterBody2D` (frozen) —
   `_process`: rotates sprite/muzzle Marker2D towards mouse position;
   `_unhandled_input`: left-click fires projectile from muzzle;
   `scripts/player/Projectile.gd` extending `Area2D`: moves in muzzle direction
   at 600 px/s, on `area_entered` calls `UnitAttributesBridge.deal_damage(target,
   damage)` and queues_free; player stats loaded from
   `resources/units/player_tower.tres` (UnitData subclass with attack_damage
   and fire_rate_sec); SoundBridge called on fire and on hit

4. Write `resources/waves/` — five `WaveData.tres` files: `wave_01.tres`
   (3 skeleton_basic, 10s between groups), `wave_02.tres` (5 skeleton_basic +
   2 armoured_ghoul), `wave_03.tres` (3 armoured_ghoul + 2 plague_carrier),
   `wave_04.tres` (8 skeleton_basic + 2 plague_carrier, dual spawn points),
   `wave_05.tres` (boss: 1 plague_lord + 4 armoured_ghoul escort);
   write `resources/units/` UnitData files for each enemy type;
   write `scripts/WaveSpawner.gd`: reads WaveData, instantiates UnitBase scenes
   on timer, emits `unit_spawned` to SignalBus

5. Write `scripts/ai/GrimsbyAI.gd` — Beehave tree: Selector root → Sequence(
   HPBelowThreshold → RetreatAction) → Sequence(EnemyInRange → AttackWithSelector
   → PlayAttackAnim) → PatrolAroundPlayer; attaches `TargetSelector` component
   (NEAREST, faction_filter = ENEMY); `GrimsbyAI` exposes `downState()` and
   `recoverState()` methods wired to SignalBus `unit_died(grimsby_id)` and
   `recovery_triggered(grimsby_id)`; write `scenes/Grimsby.tscn` extending
   UnitBase with the Beehave tree attached and Grimsby's UnitData

6. Write `scenes/BuildPhaseUI.tscn` — HUD panel that shows during build phase;
   reads valid hex cells from HexGrid (those not on the enemy path);
   displays gold balance from EconomyManager; "Place Barricade" button costs 30g;
   places a `BuildingBase` barricade on the selected hex; "Ready" button ends
   build phase and emits `combat_phase_started` to SignalBus;
   write 4 GdUnit4 tests: wave spawning fires correct count of units, player
   projectile deals damage to enemy HP, Grimsby transitions to retreat below
   30% HP, build phase ends on Ready signal

**Deliverables:**
- [ ] `wolf-games/wolf-td/` — scaffolded via `wolf new`
- [ ] `scenes/Arena.tscn` with `scripts/ArenaManager.gd`
- [ ] `scripts/player/PlayerTower.gd` + `Projectile.gd`
- [ ] `resources/waves/wave_01.tres` through `wave_05.tres`
- [ ] `resources/units/` — skeleton_basic, armoured_ghoul, plague_carrier, plague_lord
- [ ] `resources/units/player_tower.tres`
- [ ] `scripts/WaveSpawner.gd`
- [ ] `scripts/ai/GrimsbyAI.gd` + `scenes/Grimsby.tscn`
- [ ] `scenes/BuildPhaseUI.tscn` + `scripts/BuildPhaseManager.gd`
- [ ] 4 GdUnit4 tests passing
- [ ] Game is playable: wave 1 starts, enemies pathfind, player shoots, Grimsby tanks
- [ ] `wolf simbot run baseline --game wolf-td` completes without crash

**Unlocks:** S22 (grid TD reuses WaveSpawner), S37 (balance pass), S38 (asset pass)

---

## Session S22 — WOLF-TD-GRID: Classic Grid Tower Defense

**Goal:** A lane-based tower defense (player places static towers on a grid,
enemies walk a fixed path) demonstrating that the WOLF framework supports the
classic genre interpretation as cleanly as the TAUR pattern — using mostly
the same framework systems from a different angle.

**The game in one sentence:** Place and upgrade three tower types on a 12×8 tile
grid to stop 10 escalating enemy waves from reaching your base.

**Framework systems exercised:**
- `BuildingData.tres` + `BuildingBase.gd` (three tower types, each with upgrade)
- `FlowEconomyManager` (gold income per second from a "tax" building + kills)
- `WaveData.tres` + `WaveSpawner.gd` (reused from S21 — different wave files)
- `UnitBase.tscn` + `TargetSelector` (towers use NEAREST + LOWEST_HP modes)
- `Beehave` (enemies: ADVANCE_TO_GOAL tree, no combat — just walk)
- `TechTreeUI` (two-tier tower upgrade system: tier 1 → tier 2 → tier 3)
- `GAS` AttributeSet (tower attack damage + range + fire rate attributes)
- `SoundBridge` + `Localisation` (all tower names through en.po)

**Perplexity context to load:**
- Chunk 4a: S21 deliverables (WaveSpawner.gd, UnitData files, SoundBridge)
- `framework/scripts/world/TechTreeUI.gd` (S13 deliverable)
- `framework/templates/resources/BuildingData.gd` (S09 deliverable)

**Key questions for this session:**
1. Tower placement: should valid grid cells be stored in a `TileMapLayer` using
   a custom data layer, or computed at runtime by checking if a cell is not on
   the enemy path and not already occupied?
2. The TechTreeUI was designed for research trees. How do we repurpose it for
   a per-tower in-place upgrade panel? Should we subclass TechTreeUI or write
   a separate `TowerUpgradePanel.tscn` that shares only the ResearchNodeData
   resource format?
3. FlowEconomy and discrete EconomyManager are both active here (gold income rate
   + kill bonus). What is the correct way to bridge FlowEconomy's accumulated
   buffer back to the discrete EconomyManager's `gold` pool?
4. 10-wave escalation: what multiplier per wave keeps the game challenging without
   becoming unsolvable? What is the SimBot quick-profile target win rate?

**Cursor prompts to generate (5 prompts):**

1. Scaffold WOLF-TD-GRID — `wolf new wolf-td-grid --genre tower-defense`;
   write `scenes/GridArena.tscn` — 12×8 TileMapLayer (square grid, not hex);
   place enemy path using TileMapLayer custom data layer `is_path: true`;
   enemy enters at top-left, exits at bottom-right; six non-path columns
   available for tower placement; `scripts/GridArenaManager.gd` handles wave
   lifecycle same as ArenaManager in S21 but reads path from TileMap data;
   enemy `scripts/ai/GridEnemy.gd` using Beehave: AdvancePath → ReachGoal
   (sets `base_reached = true` and emits `game_lost` signal on goal)

2. Write three tower types as `BuildingData.tres` resources and `BuildingBase`
   extensions: `ArcherTower` (fast fire rate, low damage, NEAREST targeting,
   range 3 tiles); `CannonTower` (slow fire rate, AoE splash damage,
   NEAREST targeting, range 2 tiles); `FreezeTower` (no damage, applies
   `slowed` GAS effect reducing enemy move speed by 50% for 3 seconds,
   range 4 tiles); each tower has a Tier2 upgrade nested `BuildingUpgradeData`
   (+30% damage, +1 range) and Tier3 upgrade (+50% damage, +2 range, special
   effect unlock); write `scenes/towers/` folder with one .tscn per tower type

3. Write `scenes/TowerPlacementManager.gd` — detects mouse click on valid
   (non-path, non-occupied) grid cell; opens `TowerShopPopup.tscn` showing
   three tower icons with costs; on selection deducts gold from EconomyManager,
   instances tower .tscn, marks cell as occupied; right-click on placed tower
   opens `TowerUpgradePanel.tscn` — shows current stats, upgrade cost, upgrade
   button (calls BuildingData tier upgrade); write sell button that returns 50%
   of total investment

4. Write `resources/waves/` ten-wave escalation set — `wave_01.tres` through
   `wave_10.tres`; use WaveData's SpawnGroupData to model escalation:
   basic walker only in waves 1-3, armoured walker added in waves 4-6,
   fast sprinter added in waves 7-8, boss wave in wave 9 (1 mega-walker),
   final wave 10 (all types + double spawn speed); write
   `scripts/EconomyBridge.gd` — converts FlowEconomyManager's metal buffer
   ticks into discrete EconomyManager gold additions at 0.5s intervals;
   also adds +10 gold per kill from `unit_died` signal

5. Write 5 GdUnit4 tests: CannonTower AoE damages two enemies in radius,
   FreezeTower applies slowed status effect correctly, TowerUpgradePanel
   deducts correct cost and updates BuildingData stats, GridArenaManager
   emits game_lost when enemy reaches goal, wave 10 spawns all three enemy
   types; run `wolf test --game wolf-td-grid` confirming all pass

**Deliverables:**
- [ ] `wolf-games/wolf-td-grid/` — scaffolded
- [ ] `scenes/GridArena.tscn` with path TileMap
- [ ] `scenes/towers/` — ArcherTower, CannonTower, FreezeTower .tscn + .tres
- [ ] `scripts/GridArenaManager.gd`
- [ ] `scripts/ai/GridEnemy.gd` Beehave tree
- [ ] `scripts/TowerPlacementManager.gd`
- [ ] `scenes/TowerShopPopup.tscn` + `scenes/TowerUpgradePanel.tscn`
- [ ] `scripts/EconomyBridge.gd`
- [ ] `resources/waves/wave_01.tres` through `wave_10.tres`
- [ ] 5 GdUnit4 tests passing
- [ ] Game is playable: towers fire at enemies, freeze works, upgrades apply
- [ ] `wolf simbot run baseline --game wolf-td-grid` completes

**Unlocks:** S33 (Hybrid TD+Province uses GridArena + wave system), S37 (balance)

---

## Session S23 — WOLF-RTS: Real-Time Strategy MVP

**Goal:** A two-faction, base-building RTS with worker units, resource gathering,
unit production from barracks, and a destroy-the-enemy-HQ win condition —
demonstrating that the framework's Steering AI, Flow Economy, Formation Manager,
and FOW GPU systems combine cleanly into a playable RTS loop.

**The game in one sentence:** Build a base, produce armies, and destroy the
enemy faction's headquarters before they destroy yours — on a 3D terrain map
with fog of war and tech upgrades.

**Framework systems exercised:**
- `FlowEconomyManager` (metal + energy income from extractor buildings)
- `GDQuest Steering AI` (all unit movement: workers, soldiers, siege units)
- `Beehave` (enemy base AI: expand → tech → attack behaviour tree)
- `FormationManager` (player-issued move orders use WEDGE formation)
- `MultiUnitSelector` + `RTSCamera3D` (full RTS control scheme)
- `FogOfWarGPU` (large map, vision by unit sight radius)
- `TechTreeUI` (two tiers: basic barracks → advanced barracks → siege factory)
- `FactionManager` (`declare_war` on game start, `is_enemy` for targeting)
- `Terrain3D` + `Sky3D` (3D map with day/night cycle)
- `Minimap` (unit + building positions)
- `ReplayRecorder` (optional: records full match for review)

**Perplexity context to load:**
- Chunks 1–3 full workplan
- `framework/scripts/economy/FlowEconomyManager.gd` (S13)
- `framework/scripts/selection/MultiUnitSelector.gd` + `FormationManager.gd` (S12)
- `framework/scripts/camera/RTSCamera3D.gd` (S12)
- `framework/scripts/map/FogOfWarGPU.gd` (S12)
- `framework/scripts/world/TechTreeUI.gd` (S13)
- Session Summary §6 (RTS genre description)

**Key questions for this session:**
1. Worker units need to autonomously travel to the nearest metal extractor, mine,
   and return to a depot. Is this best modelled as a Beehave tree
   (Mine → ReturnToDepot loop) or as a Fluid HTN task (plan: move to resource →
   mine → move to depot → deposit)?
2. Enemy base AI: should the enemy faction build at fixed positions (scripted
   placement) or use HTN to plan base expansion? For MVP, scripted with a
   Beehave "if income > threshold → expand" condition is probably sufficient.
3. 3D terrain: Terrain3D requires a heightmap. Do we ship a pre-baked heightmap
   asset or generate one at startup via Gaea? For MVP, a pre-baked 256×256
   heightmap is faster.
4. Formation movement: when the player issues a move order to 8 selected units,
   FormationManager assigns slot positions. How does this interact with
   SteeringAI's individual pathfinding — do formation positions override or
   guide the steering target?

**Cursor prompts to generate (7 prompts):**

1. Scaffold WOLF-RTS — `wolf new wolf-rts --genre rts`; wire autoloads adding
   FlowEconomyManager (active), FactionManager, HexGrid (unused here — for
   grid reference), MinimapManager; set up `FactionManager` on `_ready`: call
   `declare_war(FactionId.PLAYER, FactionId.ENEMY)`; write `docs/MASTER_DOC.md`
   RTS-specific sections: two factions (Iron Compact = PLAYER, Dust Marauders =
   ENEMY), core game loop (economy → production → combat), win condition
   (destroy enemy HQ building), session length target = 12 minutes

2. Write `scenes/RTSMap.tscn` — Terrain3D node with pre-baked 256×256 heightmap
   (flat central plateau, ridges at edges); Sky3D attached with 10-minute
   day/night cycle; four metal extractor spots marked with `Marker3D`;
   two HQ spawn points (PLAYER: bottom-left, ENEMY: top-right); RTSCamera3D
   attached to scene root; FogOfWarGPU initialised with 256 tile resolution;
   Minimap overlay in top-right corner linked to MinimapManager

3. Write `scripts/economy/RTSEconomySetup.gd` — initialises FlowEconomyManager
   with starting income rates (metal: 2/s base); write `scenes/buildings/`
   folder with four BuildingBase extensions: `HQ.tscn` (no attack, provides
   +1 metal/s income when active, loss condition on destruction), `MetalExtractor.tscn`
   (placeable on extractor spots, adds +3 metal/s to FlowEconomy),
   `Barracks.tscn` (produces Soldier unit every 8s, costs 50 metal, requires
   FlowEconomy buffer ≥ 20), `SiegeFactory.tscn` (produces Siege unit every 15s,
   costs 120 metal, requires Barracks already placed); all buildings register
   with MinimapManager on _ready

4. Write unit scripts for three unit types: `scripts/units/Worker.gd` extending
   UnitBase — Beehave tree: Sequence(FindNearestExtractor → MoveToExtractor →
   Mine3sAction → MoveToHQ → DepositAction) looping; deposit calls
   FlowEconomyManager to increase income_rate by 0.5/s permanently;
   `scripts/units/Soldier.gd` extending UnitBase — SteeringAI seek + TargetSelector
   (NEAREST ENEMY); `scripts/units/SiegeUnit.gd` extending UnitBase — slower,
   bonus damage vs. buildings; all units register vision radius with FogOfWarGPU

5. Write `scripts/player/RTSPlayerController.gd` — handles MultiUnitSelector
   rubber-band selection; on `units_selected` signal: stores selected group;
   right-click: if target is enemy unit/building → attack-move command
   (FormationManager WEDGE, then each unit sets nearest enemy as TargetSelector);
   right-click on ground → move command (FormationManager LINE formation);
   Ctrl+1-5 → save/recall selection group; write `scenes/RTSHUD.tscn` — mini
   panel showing metal income rate, buffer, production queue per building,
   selected unit stats

6. Write `scripts/ai/EnemyBaseAI.gd` — Beehave tree for the enemy faction:
   Sequence(MetalAbove100 → PlaceNextBuilding) → Sequence(ArmyStrength > 5 →
   LaunchAttack(formation: WEDGE, target: player_hq)) → IdleExpand;
   PlaceNextBuilding picks the next building in a fixed build order (Extractor →
   Barracks → Extractor → SiegeFactory); LaunchAttack groups all enemy Soldiers
   and SiegeUnits, uses FormationManager, pathfinds to player HQ;
   enemy AI ticks every 5 seconds to avoid frame overhead

7. Write 6 GdUnit4 tests: FlowEconomy metal income increases after extractor
   placed, Worker deposits correctly increment income rate, FormationManager
   WEDGE positions 5 units correctly around anchor, FogOfWarGPU marks cell
   invisible after unit with vision dies, Barracks produces unit after buffer
   threshold met, `game_won` signal emitted when enemy HQ HP reaches 0;
   run `wolf test --game wolf-rts` confirming all pass

**Deliverables:**
- [ ] `wolf-games/wolf-rts/` — scaffolded
- [ ] `scenes/RTSMap.tscn` with Terrain3D + Sky3D + FOW + Minimap
- [ ] `scenes/buildings/` — HQ, MetalExtractor, Barracks, SiegeFactory
- [ ] `scripts/units/Worker.gd`, `Soldier.gd`, `SiegeUnit.gd`
- [ ] `scripts/player/RTSPlayerController.gd`
- [ ] `scenes/RTSHUD.tscn`
- [ ] `scripts/ai/EnemyBaseAI.gd` Beehave tree
- [ ] `scripts/economy/RTSEconomySetup.gd`
- [ ] 6 GdUnit4 tests passing
- [ ] Game is playable end-to-end: start → build extractor → train soldiers
      → attack enemy HQ → win/lose condition triggers
- [ ] ReplayRecorder optionally active (verify replay.tres is written on game end)
- [ ] `wolf simbot run baseline --game wolf-rts` completes without crash

**Unlocks:** S24 (flow-RTS variant extends this), S33 (hybrid), S37 (balance)

---

## Session S24 — WOLF-FLOW-RTS: Total Annihilation-Style RTS

**Goal:** A rate-based RTS where income and expenditure are continuous flows,
constructors build at reduced speed when the economy is stalled (nanostall),
and battles involve 20–30 units per side — proving the FlowEconomyManager's
nanostall mechanic under real gameplay pressure and the framework's performance
with larger unit counts.

**The game in one sentence:** Command a flow-economy base where constructors
auto-build a production chain in priority order and your metal income races
your expenditure — survive the nanostall crises and overwhelm the enemy
commander unit with massed forces.

**Key differences from WOLF-RTS:**
No discrete resource pools, no manual worker assignment. All buildings are
constructed by `Constructor` units that draw from the metal flow. The player's
primary decisions are: build order priority, constructor allocation, and attack
timing during enemy nanostalls.

**Framework systems exercised:**
- `FlowEconomyManager` (nanostall fully engaged — primary gameplay mechanic)
- `BalanceGuardrails.tres` (income rate bounds, unit DPS bounds, cost bounds)
- `Fluid HTN` (constructor AI: goal-directed building plan)
- `GDQuest Steering AI` (large unit swarms, 20+ units)
- `FogOfWarGPU` (large 512×512 map)
- `RTSCamera3D` + `MultiUnitSelector` (all-unit attack-move)
- `SimBot balance_optimiser.py` (run as part of S37, but guardrails set here)

**Perplexity context to load:**
- Chunk 4a: S23 deliverables (RTSMap.tscn pattern, unit scripts)
- `framework/scripts/economy/FlowEconomyManager.gd` (S13)
- `framework/templates/resources/BalanceGuardrails.gd` (S13)
- `framework/addons/fluid-htn/` (S11)

**Key questions for this session:**
1. HTN constructor planner: the build order is a queue of tasks
   (build metal extractor → build solar panel → build vehicle plant →
   build tank). How does the HTN domain model the preconditions for each task
   (e.g., "cannot build vehicle plant until income_rate > 8/s")?
2. Nanostall recovery: when metal buffer empties, constructors slow to 10%
   speed. What is the best visual indicator for nanostall state so the player
   can see it instantly?
3. 20+ unit steering: SteeringAI works per-unit. What is the recommended
   collision avoidance setup to prevent unit clumping at scale without
   impacting frame rate on the target hardware (RTX 4090)?
4. Commander unit: the TA-style "game ends when Commander dies" mechanic.
   Should the Commander be a regular UnitBase with high HP, or a unique
   singleton scene?

**Cursor prompts to generate (6 prompts):**

1. Scaffold WOLF-FLOW-RTS — `wolf new wolf-flow-rts --genre rts`;
   write `config/balance_guardrails.tres` with TA-calibrated bounds:
   min_income_metal=2, max_income_metal=40, min_unit_hp=80, max_unit_hp=2000,
   max_dps_per_metal_cost=0.08; write `docs/MASTER_DOC.md` sections explaining
   nanostall mechanic, commander-death loss condition, and the role of
   BalanceGuardrails in bounding the optimiser

2. Write `scripts/economy/FlowEconomyHUD.tscn` — real-time economy display:
   metal income rate bar (green fill), metal expenditure rate bar (red fill),
   metal buffer gauge (yellow), nanostall indicator (red pulsing border when
   stalling, text "METAL STALL"); write `scripts/economy/NanostallVisualizer.gd`
   — listens to `nanostall_started(METAL)` from SignalBus, applies shader
   parameter to all active constructor models (desaturate + slow animation)

3. Write Fluid HTN constructor AI — `scripts/ai/ConstructorHTN.gd`:
   HTNDomain with world state properties (metal_income_rate, energy_income_rate,
   has_vehicle_plant, has_air_factory, army_strength); tasks in order:
   BuildMetalExtractor (precondition: metal_income < 12, effect: +4/s),
   BuildSolarPanel (precondition: energy_income < 8, effect: +3/s),
   BuildVehiclePlant (precondition: metal_income >= 8, effect: enables tank),
   BuildAirFactory (precondition: vehicle_plant exists); constructor runs HTN
   planner every 5s, picks highest-priority unmet task, pathfinds to build
   location, places building

4. Write five unit types for large-scale battle: `LightBot.tres` (fast, low HP,
   cheap — 30 metal, floods enemy), `HeavyTank.tres` (slow, high HP — 120 metal),
   `Artillery.tres` (long range, splash — 200 metal, requires vehicle plant),
   `ScoutDrone.tres` (fast, no attack, large vision radius — 20 metal, expands
   FOW), `Commander.tres` (unique, high HP, can also construct, death = game over);
   all use SteeringAI seek with TargetSelector NEAREST ENEMY;
   write `scripts/player/SwarmController.gd` — Ctrl+A selects all combat units,
   right-click anywhere sends full swarm in CIRCLE formation toward target

5. Write `scripts/ai/EnemyFlowAI.gd` — mirror of ConstructorHTN but for ENEMY
   faction; adds slight randomness to build order (±2s delay per task) so enemy
   economy doesn't perfectly mirror player; enemy attacks when army_strength > 8
   OR when player has nanostalled for > 15s (opportunistic attack on stall);
   enemy Commander never leaves base (defensive anchor)

6. Write 5 GdUnit4 tests: nanostall triggers when buffer hits 0 and clears when
   income exceeds expenditure, HTN planner selects correct task given world state,
   Commander death emits `game_lost`, SteeringAI units separate correctly at
   10-unit density (average inter-unit distance > 0.8 * collision_radius),
   BalanceGuardrails `validate_stat(unit_id, dps_per_cost)` returns false for
   out-of-bounds values

**Deliverables:**
- [ ] `wolf-games/wolf-flow-rts/` — scaffolded
- [ ] `config/balance_guardrails.tres` — TA-calibrated values
- [ ] `scenes/economy/FlowEconomyHUD.tscn`
- [ ] `scripts/economy/NanostallVisualizer.gd`
- [ ] `scripts/ai/ConstructorHTN.gd` — Fluid HTN build planner
- [ ] `scripts/ai/EnemyFlowAI.gd`
- [ ] `scripts/player/SwarmController.gd`
- [ ] Unit resources: LightBot, HeavyTank, Artillery, ScoutDrone, Commander
- [ ] 5 GdUnit4 tests passing
- [ ] Nanostall visual indicator works and is clearly readable
- [ ] 20-unit battle runs at >60 fps on target hardware (noted in result report)
- [ ] `wolf simbot run baseline --game wolf-flow-rts` completes; nanostall
      frequency noted in balance report

**Unlocks:** S37 (balance optimiser most relevant for this game), S38 (asset pass)

---

## Session S25 — WOLF-CARD: Card Roguelite MVP

**Goal:** A three-room Slay the Spire–style card roguelite with an energy system,
status effects, card rewards between rooms, and a boss fight — demonstrating
that the Card Framework, GAS, Dialogue Manager, and run-state SavePayload
combine into a complete roguelite loop.

**The game in one sentence:** Fight through three increasingly difficult combat
rooms using a 10-card starter deck, pick up new cards and relics between rooms,
and defeat the Plague Warden boss to win the run.

**Framework systems exercised:**
- `Card Framework` (chun92) — deck, hand, draw, play, discard, exhaust
- `GAS` AttributeSet — HP, energy, block, status effects (burn, freeze, poison)
- `Beehave` — enemy intent tree (pattern: ATTACK/BLOCK/BUFF cycling with intent display)
- `DialogueBridge` — story flavour text before room 1, after boss death
- `Quest System` (optional run objective: "Deal 100 damage with a single card")
- `SoundBridge` + `Localisation` (all card names through en.po)
- `SavePayload.cs` — run state (deck, HP, gold, relics) persisted between rooms

**Perplexity context to load:**
- Chunk 2 (S10: Card Framework demo, CardHandDemo.tscn)
- `framework/scripts/components/TargetSelector.gd` (S14)
- `framework/scripts/i18n/Localisation.gd` (S14)
- `framework/templates/SavePayload.cs` (S09)

**Key questions for this session:**
1. How does the Card Framework represent "targeting" — when the player plays an
   attack card, how does it know which enemy to target? Click-to-target or
   auto-nearest?
2. Status effects (burn, freeze, poison): GAS has the Gameplay Effect system
   for temporary attribute modifiers. What is the correct GAS Effect setup for
   a DoT (damage over time) effect like poison?
3. Run state persistence between rooms: the player's deck, HP, and relics need
   to persist across scene transitions. Should this use SavePayload's full
   serialization, or a lighter `RunState.tres` AutoLoad resource that lives
   in memory for the duration of the run?
4. Card reward screen between rooms: player picks 1 of 3 cards. How do we
   generate the three options? Random from a card pool filtered by rarity tier?

**Cursor prompts to generate (7 prompts):**

1. Scaffold WOLF-CARD — `wolf new wolf-card --genre card-roguelite`; write
   `autoloads/RunState.gd` singleton — holds current run data: `deck: Array[CardData]`,
   `hp: int`, `max_hp: int`, `gold: int`, `relics: Array[RelicData]`,
   `room_index: int (0-2)`, `run_won: bool`; `save_run()` and `load_run()`
   methods using a lightweight Dictionary (not full SavePayload — run is lost
   on quit by design, SavePayload only for meta-progression in S26); wire
   RunState as an autoload after SignalBus in project.godot

2. Write 20 starter card resources in `resources/cards/` — 10 in the starter
   deck, 10 as reward pool; categories: Strike (6 damage, 1 energy), Defend
   (5 block, 1 energy), Fireball (10 damage + 2 burn, 2 energy), Ice Shard
   (6 damage + freeze 1 turn, 1 energy), Poison Dart (4 damage + poison 3,
   1 energy), Heavy Blow (18 damage, 3 energy), Body Slam (damage = current block,
   1 energy), Shrug It Off (8 block + remove 1 debuff, 1 energy), Draw Two
   (draw 2 cards, 0 energy), Limit Break (next card costs 0 energy, 1 energy);
   each card is a `CardData.tres` extending Card Framework's Card resource

3. Write `scenes/CombatRoom.tscn` — the main combat scene: `CardHand.tscn`
   at bottom (Card Framework hand component), energy orbs HUD (max 3),
   discard pile + draw pile count; two enemy slots (up to 2 enemies per room);
   `scripts/CombatManager.gd` turn loop: PLAYER_TURN (play cards freely) →
   END_TURN button → ENEMY_TURN (Beehave tree fires intent) → back to PLAYER_TURN;
   on player HP reaches 0: emit `run_lost`; on all enemies dead: emit
   `room_cleared(room_index)`

4. Write GAS status effect setup: `scripts/effects/BurnEffect.gd` — GAS
   GameplayEffect: deals 2 damage per turn, stacks (burn_stacks attribute),
   decrements by 1 each turn; `scripts/effects/FreezeEffect.gd` — GAS
   GameplayEffect: sets movement speed to 0 for N turns (no movement in card
   game context = skips enemy attack for 1 turn); `scripts/effects/PoisonEffect.gd`
   — deals poison_stacks damage per turn, does not decrement; all three apply
   via `UnitAttributesBridge.apply_effect(target, effect_resource)`;
   write status effect icons shown on enemy/player portraits

5. Write enemy resources and Beehave intent trees: three room enemies —
   `SkeletonGuard.tres` (intent loop: ATTACK 8 → BLOCK 5 → ATTACK 8),
   `PlagueRat.tres` (ATTACK 4 → APPLY_POISON 3 → ATTACK 4 → APPLY_POISON 3),
   `PlagueWarden.tres` (boss: ATTACK 12 → BUFF(+3 attack next turn) → ATTACK 15
   → HEAL 20 → repeat); intent displayed on enemy portrait as icon + number
   so player can see what's coming; Beehave tree emits intent to UI before
   executing it on end of player turn

6. Write `scenes/RewardScreen.tscn` — displayed between rooms;
   shows 3 randomly drawn cards from reward pool (weighted by rarity);
   "Add to Deck" button calls `RunState.deck.append(card_data)`;
   "Skip" button available; also shows random relic offer (1 of 3 relics);
   `scripts/RelicManager.gd` — 5 starter relics as `RelicData.tres` resources
   with passive effects (e.g., "Bloodstone: start each combat with 10 block");
   write `scenes/MapScreen.tscn` — simple 3-node linear map: Room 1 →
   Room 2 → Boss Room, with locked nodes unlocking on room clear

7. Write 6 GdUnit4 tests: CardHand draws 5 cards from deck on combat start,
   playing a Strike card reduces enemy HP by 6, Burn deals 2 damage on enemy
   turn and stacks, Freeze skips enemy attack for 1 turn, RunState deck
   persists after room 1 clears and scene transitions to room 2,
   PlagueWarden boss Beehave tree executes HEAL intent after ATTACK 15;
   run `wolf test --game wolf-card` confirming all pass

**Deliverables:**
- [ ] `wolf-games/wolf-card/` — scaffolded
- [ ] `autoloads/RunState.gd` — lightweight run state singleton
- [ ] `resources/cards/` — 20 card resources (10 starter + 10 reward)
- [ ] `scenes/CombatRoom.tscn` + `scripts/CombatManager.gd`
- [ ] `scripts/effects/BurnEffect.gd`, `FreezeEffect.gd`, `PoisonEffect.gd`
- [ ] Enemy resources: SkeletonGuard, PlagueRat, PlagueWarden (boss)
- [ ] `scenes/RewardScreen.tscn` + `scripts/RelicManager.gd`
- [ ] `scenes/MapScreen.tscn` — 3-node linear run map
- [ ] 6 GdUnit4 tests passing
- [ ] Full run is completable: Room 1 → Reward → Room 2 → Reward → Boss
- [ ] Run state (deck + HP + relics) persists across scene changes
- [ ] `wolf simbot run baseline --game wolf-card` completes

**Unlocks:** S26 (deck-builder campaign reuses all card resources and CombatRoom)

---

## Phase 2, S21–S25 — Session Status Tracker

| Session | Game | Genre | Depends on | Status |
|---------|------|-------|-----------|--------|
| S21 | WOLF-TD | Tower Defense (TAUR) | S20 (Phase 1 gate) | ⏳ |
| S22 | WOLF-TD-GRID | Tower Defense (Classic) | S21 | ⏳ |
| S23 | WOLF-RTS | RTS (Warcraft-style) | S20 | ⏳ |
| S24 | WOLF-FLOW-RTS | RTS (TA-style) | S23 | ⏳ |
| S25 | WOLF-CARD | Card Roguelite | S20 | ⏳ |

*Note: S21, S23, and S25 all depend only on S20 and can be run in parallel
in different Perplexity sessions if desired.*

*End of Chunk 4a. Chunk 4b covers Phase 2 Sessions S26–S32:
Card Campaign, Grand Strategy, Crisis Management, Autobattler MVP,
Autobattler Extended, and both Dungeon Keeper variants.*
