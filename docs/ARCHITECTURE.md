# FOUL WARD — ARCHITECTURE.md
# Complete architectural reference for the MVP prototype.
# Every AI coding session receives relevant sections of this document.

---

## 1. AUTOLOAD SINGLETONS

Registered in `project.godot` in this exact order (game singletons first; MCP editor helpers last):

| #  | Script Path                              | Autoload Name      | Purpose                                  |
|----|------------------------------------------|--------------------|------------------------------------------|
| 1  | `res://autoloads/signal_bus.gd`          | `SignalBus`        | Central signal registry (**77** signals as of **2026-04-18**, no logic) |
| 2  | `res://scripts/nav_mesh_manager.gd`      | `NavMeshManager`   | Registers `NavigationRegion3D`, queues rebakes |
| 3  | `res://autoloads/DamageCalculator.cs`    | `DamageCalculator` | Stateless damage multiplier lookups (C#) |
| 4  | `res://autoloads/aura_manager.gd`       | `AuraManager`      | Aura towers + enemy aura emitters        |
| 5  | `res://autoloads/economy_manager.gd`     | `EconomyManager`   | Resource tracking + transactions         |
| 6  | `res://autoloads/campaign_manager.gd`    | `CampaignManager`  | Day/campaign, factions, **ally roster**; must load **before** `GameManager` |
| 7  | `res://autoloads/relationship_manager.gd` | `RelationshipManager` | Affinity / tiers (no `class_name`)    |
| 8  | `res://autoloads/settings_manager.gd`    | `SettingsManager`  | `user://settings.cfg`                    |
| 9  | `res://autoloads/game_manager.gd`        | `GameManager`      | `Types.GameState`, missions, territory; allies under `Main/AllyContainer` |
| 10 | `res://autoloads/build_phase_manager.gd` | `BuildPhaseManager` | Build-phase vs combat-phase guard        |
| 11 | `res://autoloads/ally_manager.gd`       | `AllyManager`      | Summoner-building squads                 |
| 12 | `res://autoloads/combat_stats_tracker.gd` | `CombatStatsTracker` | SimBot / balance CSV output          |
| 13 | `res://autoloads/save_manager.gd`        | `SaveManager`      | Rolling autosaves (no `class_name`)      |
| 14 | `res://autoloads/sybil_passive_manager.gd` | `SybilPassiveManager` | Sybil passive `.tres` load, offers, modifiers |
| 15 | `res://autoloads/chronicle_manager.gd`   | `ChronicleManager` | Meta achievements + perks (`user://chronicle.json`) |
| 16 | `res://autoloads/dialogue_manager.gd`    | `DialogueManager`  | Hub + combat dialogue from `res://resources/dialogue/**` |
| 17 | `res://autoloads/auto_test_driver.gd`   | `AutoTestDriver`   | Headless `--autotest` / SimBot driver    |
| 18 | *(UID — GDAI extension)*                 | `GDAIMCPRuntime`   | Editor MCP bridge                        |
| 19 | `res://autoloads/enchantment_manager.gd` | `EnchantmentManager` | Weapon enchantment slots             |
| 20 | `res://addons/godot_mcp/mcp_screenshot_service.gd` | `MCPScreenshot` | Godot MCP Pro helper (editor)   |
| 21 | `res://addons/godot_mcp/mcp_input_service.gd` | `MCPInputService` | Godot MCP Pro helper (editor)   |
| 22 | `res://addons/godot_mcp/mcp_game_inspector_service.gd` | `MCPGameInspector` | Godot MCP Pro helper (editor) |

**Core game autoloads:** 19 entries (rows 1–19 above). **`project.godot`** lists **22** autoload lines total — the three **MCP** helpers (rows 20–22) are editor tooling, not part of the gameplay singleton chain in `AGENTS.md`.

`Types` is a `class_name` script at `res://scripts/types.gd` — NOT an autoload.
It provides enums and constants via `Types.GameState`, `Types.DamageType`, etc.

---

## 2. COMPLETE SCENE TREE

`res://scenes/main.tscn` — root scene. Runtime paths below use `/root/Main/...` (game) or match the edited scene when opened in the editor.

```
Main (Node3D)                                  [main.tscn — script: main_root.gd]
│
├── Camera3D (Camera3D)                        [Fixed isometric, orthographic]
│       projection = PROJECTION_ORTHOGRAPHIC
│       rotation_degrees = Vector3(-35.264, 45, 0)   # True isometric
│       size = 40.0                                    # Orthographic viewport size
│       position = Vector3(20, 20, 20)                 # Looking at origin
│
├── DirectionalLight3D (DirectionalLight3D)    [Scene-wide lighting]
│
├── TerrainContainer (Node3D)                  [Campaign terrain instanced here — see CampaignManager._load_terrain]
│   └── (e.g. grassland / swamp terrain scene at runtime: Ground mesh + NavigationRegion3D + …)
│
├── Tower (StaticBody3D)                       [tower.tscn — central destructible tower]
│   ├── TowerMesh (MeshInstance3D)             [Visual]
│   ├── TowerCollision (CollisionShape3D)      [Layer 1 — Tower]
│   ├── HealthComponent (Node)                 [health_component.gd — reusable HP system]
│   └── TowerLabel (Label3D)                   [Label]
│
├── Arnulf (CharacterBody3D)                   [arnulf.tscn — AI melee unit]
│   ├── ArnulfVisual (Node3D)                  [Rig / placeholder mount]
│   ├── ArnulfCollision (CollisionShape3D)     [Layer 3 — Arnulf]
│   ├── HealthComponent (Node)                 [health_component.gd instance]
│   ├── NavigationAgent3D (NavigationAgent3D)  [Pathfinding to enemies]
│   ├── DetectionArea (Area3D)                 [Patrol radius detection]
│   │   └── DetectionShape (CollisionShape3D)  [Sphere, mask = layer 2 (enemies)]
│   ├── AttackArea (Area3D)                    [Melee range detection]
│   │   └── AttackShape (CollisionShape3D)     [Small sphere, mask = layer 2]
│   └── ArnulfLabel (Label3D)                  ["ARNULF" text]
│
├── HexGrid (Node3D)                          [hex_grid.tscn — 42-slot build grid, 3 rings]
│   ├── HexSlot_00 (Area3D)                   [One per slot — collision layer 7 bit mask “HexSlots”]
│   │   ├── SlotCollision (CollisionShape3D)
│   │   └── SlotMesh (MeshInstance3D)          [Hex outline, visible only in build mode]
│   ├── HexSlot_01 (Area3D)
│   │   └── ...
│   └── ... (HexSlot_00 through HexSlot_23)
│
├── SpawnPoints (Node3D)                       [Container for fixed spawn locations]
│   ├── SpawnPoint_00 (Marker3D)               [10 points evenly around map edge]
│   ├── SpawnPoint_01 (Marker3D)
│   └── ... (SpawnPoint_00 through SpawnPoint_09)
│
├── EnemyContainer (Node3D)                    [Runtime parent for spawned enemies]
│   └── (enemies added at runtime)
│
├── AllyContainer (Node3D)                      [Runtime parent for generic allies spawned by GameManager]
│   └── (AllyBase instances added at mission start)
│
├── AllySpawnPoints (Node3D)                    [Fixed spawn locations for allies (near tower)]
│   ├── AllySpawnPoint_00 (Marker3D)
│   ├── AllySpawnPoint_01 (Marker3D)
│   └── AllySpawnPoint_02 (Marker3D)
│
├── BuildingContainer (Node3D)                 [Runtime parent for placed buildings]
│   └── (BuildingBase instances — building_base.tscn — added at runtime per placement)
│
├── ProjectileContainer (Node3D)               [Runtime parent for active projectiles]
│   └── (projectiles added at runtime)
│
├── Managers (Node)                            [Non-autoload scene-bound managers]
│   ├── WaveManager (Node)                     [wave_manager.gd]
│   ├── SpellManager (Node)                    [spell_manager.gd]
│   ├── ResearchManager (Node)                 [research_manager.gd]
│   ├── ShopManager (Node)                     [shop_manager.gd]
│   ├── WeaponUpgradeManager (Node)            [weapon_upgrade_manager.gd]
│   └── InputManager (Node)                    [input_manager.gd]
│
└── UI (CanvasLayer)                           [All UI elements]
    ├── UIManager (Control)                    [ui_manager.gd — signal→panel router]
    │   └── DialoguePanel                      [dialogue_panel.tscn — instance child]
    ├── Hub (Control)                          [hub.tscn — meta / campaign hub UI]
    ├── HUD (Control)                          [hud.tscn — always-visible combat UI]
    ├── BuildMenu (Control)                    [build_menu.tscn — radial menu overlay]
    ├── ResearchPanel (Control)                [research_panel.tscn]
    ├── BetweenMissionScreen (Control)         [between_mission_screen.tscn]
    ├── MainMenu (Control)                     [main_menu.tscn]
    ├── MissionBriefing (Control)              [mission_briefing.gd — e.g. BeginButton]
    └── EndScreen (Control)                    [end_screen.gd — Restart / Quit]
```

#### Manager node path contracts (FOUL WARD)

Several managers are resolved by absolute node path under `Main/Managers`:

- `WaveManager` is expected at `/root/Main/Managers/WaveManager` (wave spawning, countdown, boss registry).
- `ResearchManager` is expected at `/root/Main/Managers/ResearchManager` (DialogueManager research conditions; day-start resets).
- `WeaponUpgradeManager` is expected at `/root/Main/Managers/WeaponUpgradeManager` (Tower stat lookup and upgrade resets).
- `ShopManager` is expected at `/root/Main/Managers/ShopManager` (mission-start consumables, shop-driven mission modifiers).
- `SpellManager` is expected at `/root/Main/Managers/SpellManager` (spell hotkeys and casting from InputManager).
- `InputManager` is expected at `/root/Main/Managers/InputManager` (aim raycast, weapon fire, build mode, hex picks).

These paths are authoritative: any change to the `Main/Managers` subtree must keep these exact node names and positions, or the dependent systems will silently degrade.

---

## 3. CLASS RESPONSIBILITIES

### 3.1 Autoloads

**Full `project.godot` order and script paths:** see **§1** (17 core game singletons + `GDAIMCPRuntime` + three Godot MCP Pro helpers). The entries below expand the highest-traffic singletons only.

**SignalBus** (`signal_bus.gd`):
Declares all cross-system signals as listed in CONVENTIONS.md §5. Contains zero logic —
only signal declarations. Every system emits and connects through this singleton.
Exists purely so systems never need direct references to each other.
**Prompt 11:** ally lifecycle hooks: `ally_spawned`, `ally_downed`, `ally_recovered`, `ally_killed` (and POST-MVP `ally_state_changed`).

**DamageCalculator** (`DamageCalculator.cs`):
Stateless utility. Holds the damage-type × armor-type multiplier matrix (`Types.DamageType` × `Types.ArmorType`, including **TRUE** damage) as nested Dictionaries.
Single public method `calculate_damage(base_damage, damage_type, armor_type) -> float`.
No signals emitted, no signals consumed. Pure function.

**EconomyManager** (`economy_manager.gd`):
Owns the three resource counters: `gold`, `building_material`, `research_material`.
All resource modifications go through this class's public methods. Every modification
emits `SignalBus.resource_changed`. Provides `can_afford()` for pre-transaction checks.
`reset_to_defaults()` resets all resources to starting values (called at session start).

**CampaignManager** (`campaign_manager.gd`):
Owns short-campaign / day progression, `DayConfig` resolution, faction registry validation,
and **Prompt 11** `current_ally_roster` (which `AllyData` resources are fielded each mission).
Connects to `mission_won` / `mission_failed` for day advancement (must register before `GameManager` in `project.godot`).

**GameManager** (`game_manager.gd`):
State machine for the overall game flow. Owns `current_mission`, `current_wave`,
`game_state`. Transitions between states (MAIN_MENU → MISSION_BRIEFING → COMBAT →
BETWEEN_MISSIONS → ... → GAME_WON). Coordinates mission start/end, calls
`EconomyManager.reset_to_defaults()` on new game, awards post-mission resources.
**Prompt 11:** instantiates `AllyBase` under `Main/AllyContainer` from `CampaignManager.current_ally_roster`
when a mission enters combat (`start_mission_for_day`, `start_wave_countdown`); frees allies on mission win, tower loss, and `start_new_game` cleanup.
Listens to: `all_waves_cleared`, `tower_destroyed`. Emits: `game_state_changed`,
`mission_started`, `mission_won`, `mission_failed`.

### 3.2 Scene Scripts

**Tower** (`tower.gd` on Tower node):
Owns the tower's HealthComponent. Provides `take_damage(amount)` and `repair_to_full()`.
When HealthComponent emits `health_depleted`, Tower emits `SignalBus.tower_destroyed()`.
Florence's weapons are implemented as methods on Tower — `fire_crossbow(target_pos)` and
`fire_rapid_missile(target_pos)` — which instantiate projectiles. Tower knows the
projectile container node reference. Handles weapon reload timers internally.

**Arnulf** (`arnulf.gd` on Arnulf CharacterBody3D):
State machine with states: IDLE, PATROL, CHASE, ATTACK, DOWNED, RECOVERING.
Uses NavigationAgent3D for pathfinding to enemies. DetectionArea triggers CHASE when
enemies enter patrol radius. AttackArea triggers ATTACK when enemies are in melee range.
**Prompt 11:** also emits generic `SignalBus.ally_*` with id `arnulf` alongside Arnulf-specific signals (`reset_for_new_mission` → `ally_spawned`; downed/recover → `ally_downed` / `ally_recovered`).

**AllyBase** (`ally_base.gd` / `scenes/allies/ally_base.tscn`):
Generic mercenary / ally CharacterBody3D: **CLOSEST** enemy targeting (`find_target` over `enemies` group), NavigationAgent3D chase, direct damage via `EnemyBase.take_damage`. Emits `ally_spawned` / `ally_killed` for campaign and UI.
On HealthComponent `health_depleted`: transitions to DOWNED, waits 3 seconds, transitions
to RECOVERING (sets HP to 50% of max), then returns to IDLE. Cycle repeats infinitely.
Emits: `arnulf_state_changed`, `arnulf_incapacitated`, `arnulf_recovered` via SignalBus.
Targets closest enemy to tower center (Vector3.ZERO), not closest to Arnulf.

**HexGrid** (`hex_grid.gd` on HexGrid Node3D):
Manages 24 hex slots. Each slot tracks: `slot_index`, `axial_coordinate (Vector2i)`,
`world_position (Vector3)`, `building (BuildingBase or null)`, `is_occupied (bool)`.
Public methods: `place_building(slot_index, building_type) -> bool`,
`sell_building(slot_index) -> bool`, `upgrade_building(slot_index) -> bool`,
`get_slot_data(slot_index) -> Dictionary`, `get_all_occupied_slots() -> Array`.
Emits building_placed/sold/upgraded via SignalBus. Handles resource cost checks via
EconomyManager before placement. Slot visibility toggled by build mode state.

**BuildingBase** (`building_base.gd` on building_base.tscn root):
Base class for all **36** `Types.BuildingType` entries (registry-driven). Initialized with a `BuildingData` resource.
Has HealthComponent (buildings can be damaged — MVP: buildings don't take damage,
but the component is present for future use). Contains targeting logic:
`_find_target() -> EnemyBase` based on TargetPriority. Fires projectiles at target
within range and fire_rate. `is_upgraded: bool` toggles between base and upgraded stats.
Spawner type (Archer Barracks) overrides attack behavior to spawn units instead.
Shield Generator overrides to buff adjacent buildings instead of attacking.

**EnemyBase** (`enemy_base.gd` on enemy_base.tscn root):
Base class for all **30** `Types.EnemyType` entries. Initialized with an `EnemyData` resource.
Uses NavigationAgent3D to pathfind toward tower (Vector3.ZERO).
HealthComponent tracks HP. On death: emits `SignalBus.enemy_killed`, awards gold via
`EconomyManager.add_gold()`, then `queue_free()`. Melee enemies attack tower/buildings
on contact. Ranged enemies (Orc Archer) stop at range and fire projectiles.
Flying enemies (Bat Swarm) have Y offset and ignore ground-only buildings.

**ProjectileBase** (`projectile_base.gd` on projectile_base.tscn root):
Moves in a straight line from origin to target_position at `speed`.
On collision with enemy (Area3D body_entered on layer 2): applies damage via
`DamageCalculator.calculate_damage()`, then `queue_free()`.
On reaching target position without collision: `queue_free()` (miss).
Has `max_lifetime: float` as safety net to prevent orphaned projectiles.
Two subtypes configured via initialize(): crossbow bolt (slow, high damage, larger mesh)
and rapid missile (fast, low damage, smaller mesh).

**HealthComponent** (`health_component.gd`):
Reusable component attached to Tower, Arnulf, Buildings, Enemies.
Owns `current_hp: int` and `max_hp: int`. Public methods:
`take_damage(amount: float, damage_type: Types.DamageType) -> void`,
`heal(amount: int) -> void`, `reset_to_max() -> void`.
Signals (local, not on SignalBus): `health_changed(current_hp, max_hp)`,
`health_depleted()`. The owning node decides what `health_depleted` means
(Tower → game over, Arnulf → downed state, Enemy → death + gold).

### 3.3 Manager Scripts

**WaveManager** (`wave_manager.gd`):
Drives the wave loop within a mission. Uses **`WaveComposer`** + **`WavePatternData`** (`wave_pattern` export) for normal wave composition (point budget, tags — not “N × 6 types”). Exports: `first_wave_countdown_seconds` (default 3.0), `wave_countdown_duration` (default 10.0 between waves), `max_waves` (default 5, matches `GameManager.WAVES_PER_MISSION`). Spawns at random `SpawnPoints` children. `enemy_data_registry` holds **30** `EnemyData` resources (one per `Types.EnemyType`). Tracks living enemy count via group `"enemies"`; emits `wave_cleared` / `all_waves_cleared`. Does NOT decide mission success — GameManager does.

**SpellManager** (`spell_manager.gd`):
Owns mana pool: `current_mana: int`, `max_mana: int = 100`, `mana_regen_rate: float = 5.0`.
Tracks per-spell cooldowns. `spell_registry` lists all spells (e.g. shockwave, slow_field, arcane_beam, tower_shield — see scene on `Main/Managers/SpellManager`). Public methods:
`cast_spell(spell_id: String) -> bool`, `cast_selected_spell() -> bool` — checks mana, checks cooldown, applies effect.
Emits `spell_cast`, `mana_changed` via SignalBus.
`_physics_process` handles mana regen (respects Engine.time_scale automatically).

**ResearchManager** (`research_manager.gd`):
Owns the research tree state: which nodes are unlocked. Loaded from `ResearchNodeData`
resources. Public methods: `unlock_node(node_id: String) -> bool` (checks cost + prereqs),
`is_unlocked(node_id: String) -> bool`, `get_available_nodes() -> Array[ResearchNodeData]`.
Spends research_material via EconomyManager. Emits `research_unlocked` via SignalBus.
HexGrid listens to `research_unlocked` to update which buildings are available.

**ShopManager** (`shop_manager.gd`):
Owns the shop catalog (loaded from `shop_catalog.tres`). Public method:
`purchase_item(item_id: String) -> bool` — checks gold via EconomyManager, applies effect
(e.g., tower repair → calls Tower.repair_to_full(), mana draught → sets SpellManager flag).
Emits `shop_item_purchased` via SignalBus. All effects are applied immediately on purchase.

**InputManager** (`input_manager.gd`):
Translates player input into public method calls on other systems. Contains ZERO game logic.
Handles: mouse aim (raycast to ground plane), `fire_primary` → `Tower.fire_crossbow()`,
`fire_secondary` → `Tower.fire_rapid_missile()`, `cast_selected_spell` / `cast_shockwave` → `SpellManager` (`cast_selected_spell()` / `cast_spell()`),
spell cycle / slot actions → `SpellManager`, `toggle_build_mode` → `GameManager` build mode, hex slot clicks → `HexGrid.place/sell`.
In build mode: handles radial menu interaction.

A simulation bot (`SimBot`) replaces InputManager by calling the same public methods directly.

### 3.4 UI Scripts

**UIManager** (`ui_manager.gd`):
Lightweight coordinator. Connects to `SignalBus.game_state_changed` and shows/hides the
correct UI panel for each state. No game logic. Routes signals to child panels.

**HUD** (`hud.gd`):
Listens to: `resource_changed`, `wave_countdown_started`, `wave_started`, `tower_damaged`,
`mana_changed`, `spell_cast`, `spell_ready`, `build_mode_entered/exited`.
Updates labels and progress bars. Pure display — never modifies game state.

**BuildMenu** (`build_menu.gd`):
Shown during BUILD_MODE. Displays building options in a radial layout around the
selected hex slot (catalog from `HexGrid` / research unlocks). Greyed-out options for locked/unaffordable buildings. Clicking an
option calls `HexGrid.place_building()`. Pure UI — delegates all logic to HexGrid.

**BetweenMissionScreen** (`between_mission_screen.gd`):
Three tabs: Shop, Research, Buildings. Shop tab calls `ShopManager.purchase_item()`.
Research tab calls `ResearchManager.unlock_node()`. Buildings tab is read-only display.
"NEXT MISSION" button calls `GameManager.start_next_mission()`.

---

## 4. COMPLETE SIGNAL FLOW DIAGRAM

Format: `[Emitter] --signal_name(payload)--> [Receiver] → action`

### 4.1 Combat Flow

```
EnemyBase --health_depleted()--> EnemyBase._on_health_depleted()
    → EnemyBase emits SignalBus.enemy_killed(enemy_type, position, gold_reward)
    → EnemyBase calls queue_free()

SignalBus.enemy_killed --> EconomyManager._on_enemy_killed()
    → EconomyManager.add_gold(gold_reward)
    → EconomyManager emits SignalBus.resource_changed(GOLD, new_amount)

SignalBus.enemy_killed --> WaveManager._on_enemy_killed()
    → WaveManager checks get_living_enemy_count()
    → If 0 and wave active: WaveManager emits SignalBus.wave_cleared(wave_number)

SignalBus.resource_changed --> HUD._on_resource_changed()
    → HUD updates resource display labels

EnemyBase (reaches tower) --> Tower.take_damage(amount)
    → Tower.HealthComponent emits health_changed(current_hp, max_hp)
    → Tower emits SignalBus.tower_damaged(current_hp, max_hp)

SignalBus.tower_damaged --> HUD._on_tower_damaged()
    → HUD updates tower HP bar

Tower.HealthComponent --health_depleted()--> Tower._on_health_depleted()
    → Tower emits SignalBus.tower_destroyed()

SignalBus.tower_destroyed --> GameManager._on_tower_destroyed()
    → GameManager transitions to MISSION_FAILED state
```

### 4.2 Wave Flow

```
GameManager (enters COMBAT) --> WaveManager.start_wave_sequence()
    → WaveManager starts countdown for wave 1 (`first_wave_countdown_seconds`, default 3s)
    → WaveManager emits SignalBus.wave_countdown_started(1, seconds)

SignalBus.wave_countdown_started --> HUD._on_wave_countdown_started()
    → HUD shows "WAVE 1 INCOMING" + countdown timer

WaveManager (countdown reaches 0) --> WaveManager._spawn_wave()
    → Composes spawns via WaveComposer / WavePatternData; instantiates at random spawn points
    → Emits SignalBus.wave_started(wave_number, enemy_count)

SignalBus.wave_started --> HUD._on_wave_started()
    → HUD updates wave X / max (see `WaveManager.max_waves`, default 5)

SignalBus.wave_cleared --> WaveManager._on_wave_cleared()
    → If wave_number < max_waves: start next countdown (`wave_countdown_duration`, default 10s)
    → If last wave cleared: emit SignalBus.all_waves_cleared()

SignalBus.all_waves_cleared --> GameManager._on_all_waves_cleared()
    → GameManager awards post-mission resources via EconomyManager
    → GameManager emits SignalBus.mission_won(current_mission)
    → GameManager transitions to BETWEEN_MISSIONS (or GAME_WON per campaign rules)
```

### 4.3 Build Mode Flow

```
InputManager (B key pressed during COMBAT) --> GameManager.enter_build_mode()
    → GameManager sets Engine.time_scale = 0.1
    → GameManager transitions to BUILD_MODE
    → GameManager emits SignalBus.build_mode_entered()

SignalBus.build_mode_entered --> HexGrid._on_build_mode_entered()
    → HexGrid makes all slot meshes visible

SignalBus.build_mode_entered --> HUD._on_build_mode_entered()
    → HUD dims or adjusts display

InputManager (clicks hex slot) --> HexGrid.get_clicked_slot(camera, mouse_pos)
    → Returns slot_index or -1

InputManager (selects building from radial menu) -->
    HexGrid.place_building(slot_index, building_type)
    → HexGrid checks EconomyManager.can_afford(gold, material)
    → If affordable: EconomyManager.spend_gold() + spend_building_material()
    → HexGrid instantiates BuildingBase, initializes with BuildingData
    → Emits SignalBus.building_placed(slot_index, building_type)

InputManager (B key again / Escape) --> GameManager.exit_build_mode()
    → GameManager sets Engine.time_scale = 1.0
    → GameManager transitions to COMBAT (or WAVE_COUNTDOWN)
    → GameManager emits SignalBus.build_mode_exited()
```

### 4.4 Arnulf Flow

```
Arnulf._physics_process() [state machine]:

IDLE state:
    → Arnulf stands adjacent to tower
    → DetectionArea monitors for enemies on layer 2

DetectionArea --body_entered(enemy)--> Arnulf._on_enemy_detected(enemy)
    → If state == IDLE or PATROL: transition to CHASE
    → Set chase_target = closest enemy to Vector3.ZERO (tower center)
    → Emit SignalBus.arnulf_state_changed(CHASE)

CHASE state:
    → NavigationAgent3D.target_position = chase_target.global_position
    → Move along navigation path each _physics_process
    → If chase_target freed (is_instance_valid check): return to IDLE

AttackArea --body_entered(enemy)--> Arnulf._on_attack_range_entered(enemy)
    → Transition to ATTACK
    → Start attack timer

ATTACK state:
    → Deal damage to target each attack_cooldown interval
    → If target dies or leaves range: transition to CHASE (find next) or IDLE

HealthComponent --health_depleted()--> Arnulf._on_health_depleted()
    → Transition to DOWNED
    → Emit SignalBus.arnulf_incapacitated()
    → Start 3.0 second recovery timer

DOWNED state (3 seconds):
    → Arnulf does not move or attack
    → Timer expires → transition to RECOVERING

RECOVERING state:
    → HealthComponent.heal(max_hp * 0.5)
    → Emit SignalBus.arnulf_recovered()
    → Transition to IDLE
```

### 4.5 Spell Flow

```
InputManager (Space / cast actions) --> SpellManager.cast_selected_spell() or cast_spell(spell_id)
    → SpellManager checks: current_mana >= spell_data.mana_cost
    → SpellManager checks: cooldown_remaining <= 0
    → If both pass:
        → current_mana -= spell_data.mana_cost
        → Start cooldown timer
        → Iterate get_tree().get_nodes_in_group("enemies")
        → For each enemy: enemy.health_component.take_damage(damage, MAGICAL)
        → Emit SignalBus.spell_cast("shockwave")
        → Emit SignalBus.mana_changed(current_mana, max_mana)
    → Return true/false

SpellManager._physics_process(delta):
    → current_mana = min(current_mana + mana_regen_rate * delta, max_mana)
    → Emit SignalBus.mana_changed if mana changed this frame
    → Decrement all active cooldowns by delta
    → If cooldown reaches 0: emit SignalBus.spell_ready(spell_id)
```

### 4.6 Between-Mission Flow

```
GameManager (transitions to BETWEEN_MISSIONS):
    → Emit SignalBus.game_state_changed(old, BETWEEN_MISSIONS)

SignalBus.game_state_changed --> UIManager._on_game_state_changed()
    → UIManager hides HUD, shows BetweenMissionScreen

BetweenMissionScreen (Shop tab):
    → Player clicks item → ShopManager.purchase_item(item_id)
    → ShopManager checks EconomyManager.can_afford() → spends gold → applies effect
    → Emits SignalBus.shop_item_purchased(item_id)

BetweenMissionScreen (Research tab):
    → Player clicks node → ResearchManager.unlock_node(node_id)
    → ResearchManager checks cost + prereqs → spends research_material
    → Emits SignalBus.research_unlocked(node_id)

BetweenMissionScreen ("NEXT MISSION" button):
    → Calls GameManager.start_next_mission()
    → GameManager increments current_mission
    → GameManager resets tower HP, resets wave counter
    → GameManager transitions to MISSION_BRIEFING
    → Buildings and resources CARRY OVER (not reset)
```

---

## 5. DATA FLOW FOR KEY SYSTEMS

### 5.1 Projectile System

```
[Trigger]     InputManager detects fire_primary → calls Tower.fire_crossbow(aim_position)
              OR building auto-targets → calls BuildingBase._fire_at(target_enemy)

[Create]      Tower/Building instantiates ProjectileBase from preloaded scene
              Calls projectile.initialize(weapon_data_or_building_data, origin, target_pos)
              Adds projectile to ProjectileContainer

[Travel]      ProjectileBase._physics_process: move along direction vector at speed
              Direction = (target_position - origin).normalized()
              Position += direction * speed * delta

[Hit]         ProjectileBase Area3D detects body_entered on layer 2 (enemy)
              → Calls DamageCalculator.calculate_damage(base_damage, damage_type, armor_type)
              → Calls enemy.health_component.take_damage(calculated_damage, damage_type)
              → Projectile calls queue_free()

[Miss]        If projectile reaches target_position ± tolerance with no collision:
              → queue_free()

[Safety]      If projectile lifetime exceeds max_lifetime (5.0 seconds):
              → queue_free()

[Flying rule] Florence projectiles: collision_mask excludes flying enemies
              (Florence CANNOT target flying enemies)
              Anti-Air Bolt projectiles: ONLY collide with flying enemies
```

### 5.2 Hex Grid Slot Management

```
[Data]        HexGrid owns: Array[Dictionary] _slots, size 24
              Each slot: { index: int, axial: Vector2i, world_pos: Vector3,
                           building: BuildingBase or null, is_occupied: bool }

[Layout]      42 slots in 3 rings around tower center (Vector3.ZERO):
              Ring 1 (inner): 6 slots at distance ~6 units, 60° apart
              Ring 2 (outer): 12 slots at distance ~12 units, 30° apart
              Ring 3 (extended): 6 slots at distance ~18 units, 60° apart (offset)
              Axial coordinates (q, r) define grid position; world_pos computed at _ready()

[Place]       HexGrid.place_building(slot_index: int, building_type: Types.BuildingType):
              1. Validate: slot exists, not occupied
              2. Get BuildingData resource for building_type
              3. Check: ResearchManager.is_unlocked() if building is locked
              4. Check: EconomyManager.can_afford(gold_cost, material_cost)
              5. Call: EconomyManager.spend_gold() + spend_building_material()
              6. Instantiate BuildingBase, initialize(building_data)
              7. Set building position to slot world_pos
              8. Add to BuildingContainer
              9. Update slot: building = instance, is_occupied = true
              10. Emit SignalBus.building_placed(slot_index, building_type)

[Sell]        HexGrid.sell_building(slot_index: int):
              1. Validate: slot exists, is occupied
              2. Get BuildingData from building instance
              3. `building.get_sell_refund()` → EconomyManager.add_gold / add_building_material
              4. Call building.queue_free() (after AllyManager despawn, etc.)
              5. Update slot: building = null, is_occupied = false
              6. Emit SignalBus.building_sold(slot_index, building_type)

[Upgrade]     HexGrid.upgrade_building(slot_index: int):
              1. Validate: slot occupied, building not already upgraded
              2. Check: EconomyManager.can_afford(upgrade_gold, upgrade_material)
              3. Spend resources
              4. Call building.upgrade() — sets is_upgraded = true, applies stat boost
              5. Emit SignalBus.building_upgraded(slot_index, building_type)

[Persist]     Buildings survive between missions. HexGrid state is NOT reset.
              Tower HP resets; buildings do not.
```

### 5.3 Enemy Pathfinding

```
[Approach]    NavigationAgent3D on each EnemyBase instance.
              Target: Tower position (Vector3.ZERO).

[NavMesh]     NavigationRegion3D lives on **campaign terrain** scenes (e.g. `terrain_grassland.tscn`, `terrain_swamp.tscn`) loaded under `Main/TerrainContainer`. Registered with `NavMeshManager`.
              Baked at editor time to cover the playable area.
              Tower collision (layer 1) carves a hole — enemies path around it.

[Movement]    EnemyBase._physics_process(delta):
              1. navigation_agent.target_position = Vector3.ZERO
              2. var next_pos: Vector3 = navigation_agent.get_next_path_position()
              3. var direction: Vector3 = (next_pos - global_position).normalized()
              4. velocity = direction * enemy_data.move_speed
              5. move_and_slide()

[Arrival]     When enemy reaches tower (distance < attack_range):
              → Start attack loop: deal damage to tower every attack_cooldown
              → Tower.take_damage(enemy_data.damage)

[Flying]      Bat Swarm ignores navmesh. Uses simple Vector3 steering:
              direction = (Vector3(0, FLYING_HEIGHT, 0) - global_position).normalized()
              Flies in straight line toward tower at Y = 5.0

[OPEN QUESTION — DYNAMIC NAVMESH REBAKING]
              Buildings placed on hex grid currently do NOT affect the navmesh.
              Enemies can walk through buildings in MVP. This is acceptable for MVP
              since buildings don't physically block paths — they're turrets.
              POST-MVP: If buildings should block enemy paths, NavigationRegion3D
              must rebake at runtime when buildings are placed/sold. Godot 4 supports
              NavigationRegion3D.bake_navigation_mesh() but it can cause frame hitches.
              Research needed: async baking, NavigationObstacle3D as alternative.
              FLAG: Do not implement dynamic rebaking in MVP.
```

### 5.4 Wave Scaling

```
[Composition] Normal waves use WaveComposer + WavePatternData (point budget, wave_tags, tier).
              Enemy counts are not “wave_number × 6 types”; see `wave_manager.gd` and `wave_composer.gd`.

[Spawn]       WaveManager spawns from composed enemy selections at random SpawnPoints children,
              adds to EnemyContainer and group "enemies", emits SignalBus.wave_started.

[Timing]      first_wave_countdown_seconds (default 3) before wave 1; wave_countdown_duration
              (default 10) between subsequent waves. Timers respect Engine.time_scale.
```

### 5.5 Build Mode Time Scaling

```
[Enter]       GameManager.enter_build_mode():
              1. Assert game_state == COMBAT or WAVE_COUNTDOWN
              2. Store previous time_scale (should be 1.0)
              3. Engine.time_scale = 0.1
              4. Set game_state = BUILD_MODE
              5. Emit SignalBus.build_mode_entered()
              6. Emit SignalBus.game_state_changed(old_state, BUILD_MODE)

[Exit]        GameManager.exit_build_mode():
              1. Engine.time_scale = 1.0
              2. Restore game_state to previous state (COMBAT or WAVE_COUNTDOWN)
              3. Emit SignalBus.build_mode_exited()
              4. Emit SignalBus.game_state_changed(BUILD_MODE, restored_state)

[UI impact]   All _physics_process logic slows to 10%. Enemies crawl, timers slow.
              _process is NOT affected — UI remains responsive.
              CRITICAL: UI animations and input MUST use _process, not _physics_process.
```

### 5.6 Damage Type × Vulnerability Matrix

```
[Matrix]      Stored in DamageCalculator as:
              Dictionary[Types.ArmorType, Dictionary[Types.DamageType, float]]
              Five damage types: PHYSICAL, FIRE, MAGICAL, POISON, TRUE (TRUE bypasses matrix).

              Example rows (see `DamageCalculator.cs` for source of truth):
                  UNARMORED:   PHYSICAL 1.0, FIRE 1.0, MAGICAL 1.0, POISON 1.0, TRUE 1.0
                  HEAVY_ARMOR: PHYSICAL 0.5, …
                  UNDEAD:      … POISON 0.0 …
                  FLYING:      …

[Calculation] calculate_damage(base_damage, damage_type, armor_type) -> float:
              TRUE damage skips matrix; else base_damage * multiplier.

[Note]        Poison × Undead = 0.0 → immune. Handled naturally by multiplier.
```

### 5.7 Between-Mission Persistence

```
[Persists across missions]:
  - Gold (EconomyManager.gold)
  - Building Material (EconomyManager.building_material)
  - Research Material (EconomyManager.research_material)
  - All placed buildings (HexGrid slot state + BuildingBase instances)
  - All research unlocks (ResearchManager state)
  - Shop purchase effects already applied

[Resets each mission]:
  - Tower HP → reset to max (Tower.health_component.reset_to_max())
  - Arnulf HP → reset to max
  - Arnulf state → IDLE
  - Current wave → 0
  - Mana → reset to max (or to 0 — spec says mana_regen starts fresh)
  - All spell cooldowns → reset to ready
  - All enemies → cleared (EnemyContainer emptied)
  - All projectiles → cleared (ProjectileContainer emptied)

[Resets on new game (Start from Main Menu)]:
  - EVERYTHING resets to defaults
  - EconomyManager.reset_to_defaults()
  - HexGrid.clear_all_buildings()
  - ResearchManager.reset_to_defaults()
  - GameManager resets mission to 1
```

### 5.8 Arnulf State Machine

```
State transitions (from → to: condition):

IDLE → CHASE:        Enemy enters DetectionArea AND is_instance_valid(enemy)
IDLE → IDLE:         No enemies detected (stays idle, adjacent to tower)

CHASE → ATTACK:      Target enters AttackArea
CHASE → IDLE:        Target dies or exits DetectionArea with no other targets
CHASE → DOWNED:      HealthComponent.health_depleted

ATTACK → CHASE:      Target dies but other enemies in DetectionArea
ATTACK → IDLE:       Target dies, no other enemies
ATTACK → DOWNED:     HealthComponent.health_depleted

DOWNED → RECOVERING: 3.0 second timer expires
                     (timer uses _physics_process, respects time_scale)

RECOVERING → IDLE:   Heal applied (50% max HP), immediate transition

ANY_COMBAT → DOWNED: HealthComponent.health_depleted (overrides current state)

Target selection: Always closest enemy to tower center (Vector3.ZERO), not Arnulf.
```

### 5.9 Mana Regeneration & Spell Cooldown

```
[Mana Pool]
  current_mana: int = 0          # Starts at 0 each mission
  max_mana: int = 100
  mana_regen_rate: float = 5.0   # Per second (affected by time_scale)

[Regen]
  SpellManager._physics_process(delta):
    if current_mana < max_mana:
      current_mana = min(current_mana + int(mana_regen_rate * delta), max_mana)
      SignalBus.mana_changed.emit(current_mana, max_mana)

[Cooldown]
  Dictionary[String, float] _cooldown_remaining  # spell_id → seconds left
  _physics_process decrements all active cooldowns by delta
  When cooldown reaches 0: emit SignalBus.spell_ready(spell_id)

[Cast Check]
  cast_spell(spell_id) → bool:
    if current_mana < spell_data.mana_cost: return false
    if _cooldown_remaining.get(spell_id, 0.0) > 0: return false
    → proceed with cast
```

---

## 6. ALL @EXPORT VARIABLES

> **Note:** Default values below are illustrative — verify against the `.gd` / scene files.

### Tower (`tower.gd`)

```gdscript
## Maximum tower HP. Reset to this at mission start.
@export var starting_hp: int = 500
```

### Arnulf (`arnulf.gd`)

```gdscript
## Maximum hit points. Recovers to 50% of this on resurrection.
@export var max_hp: int = 200

## Movement speed in units per second.
@export var move_speed: float = 5.0

## Physical damage dealt per attack.
@export var attack_damage: float = 25.0

## Seconds between attacks.
@export var attack_cooldown: float = 1.0

## Radius of patrol/detection area (distance from tower center).
@export var patrol_radius: float = 25.0

## Seconds to recover after incapacitation.
@export var recovery_time: float = 3.0
```

### HealthComponent (`health_component.gd`)

```gdscript
## Maximum hit points for this entity.
@export var max_hp: int = 100
```

### WaveManager (`wave_manager.gd`)

```gdscript
## Seconds of countdown before waves after the first.
@export var wave_countdown_duration: float = 10.0

## Countdown for wave 1 only (quick start).
@export var first_wave_countdown_seconds: float = 3.0

## Maximum waves per mission.
@export var max_waves: int = 5

## Enemy data resources for each type (30 entries, Types.EnemyType order).
@export var enemy_data_registry: Array[EnemyData] = []

## Campaign wave curve (WavePatternData).
@export var wave_pattern: Resource = null
```

### SpellManager (`spell_manager.gd`)

```gdscript
## Maximum mana pool.
@export var max_mana: int = 100

## Mana regenerated per second.
@export var mana_regen_rate: float = 5.0

## Spell data resources (multiple entries in main scene registry).
@export var spell_registry: Array[SpellData] = []
```

### Camera3D (in-scene, not a custom script)

```gdscript
## Configured directly on Camera3D node in main.tscn:
## projection = PROJECTION_ORTHOGRAPHIC
## size = 40.0
## rotation_degrees = Vector3(-35.264, 45, 0)
## position = Vector3(20, 20, 20)
```

---

## 7. CUSTOM RESOURCE TYPES SUMMARY

(Full definitions in CONVENTIONS.md §4)

| Resource Class      | File Location                    | Purpose                        |
|---------------------|----------------------------------|--------------------------------|
| `EnemyData`         | `res://resources/enemy_data/`    | Per-enemy-type stats           |
| `BuildingData`      | `res://resources/building_data/` | Per-building-type stats        |
| `WeaponData`        | `res://resources/weapon_data/`   | Florence's weapon configs      |
| `SpellData`         | `res://resources/spell_data/`    | Per-spell configs              |
| `ResearchNodeData`  | `res://resources/research_data/` | Research tree node definitions |
| `ShopItemData`      | `res://resources/shop_data/`     | Shop item definitions          |

---

## 8. SIMULATION TESTING DESIGN

### 8.1 Architectural Constraint

ALL game logic lives in managers and scene scripts with public method APIs.
NO game logic lives in UI scripts or InputManager.
InputManager is a thin translation layer: input event → public method call.
A headless bot (SimBot) replaces InputManager entirely.

### 8.2 Public API Per Manager (Bot-Callable Methods)

**GameManager:**
```
start_new_game() -> void                  # Reset everything, begin mission 1
start_next_mission() -> void              # Advance to next mission
enter_build_mode() -> void                # Enter build mode (sets time_scale)
exit_build_mode() -> void                 # Exit build mode (restores time_scale)
get_game_state() -> Types.GameState       # Current state
get_current_mission() -> int              # 1-5
get_current_wave() -> int                 # 0-10
```

**EconomyManager:**
```
add_gold(amount: int) -> void
spend_gold(amount: int) -> bool
add_building_material(amount: int) -> void
spend_building_material(amount: int) -> bool
add_research_material(amount: int) -> void
spend_research_material(amount: int) -> bool
can_afford(gold_cost: int, material_cost: int) -> bool
get_gold() -> int
get_building_material() -> int
get_research_material() -> int
reset_to_defaults() -> void
```

**WaveManager:**
```
start_wave_sequence() -> void             # Begin countdown for wave 1
force_spawn_wave(wave_number: int) -> void  # Spawn immediately (bot use)
get_living_enemy_count() -> int
get_current_wave_number() -> int
is_wave_active() -> bool
```

**SpellManager:**
```
cast_spell(spell_id: String) -> bool
get_current_mana() -> int
get_max_mana() -> int
get_cooldown_remaining(spell_id: String) -> float
is_spell_ready(spell_id: String) -> bool
set_mana_to_full() -> void               # For shop mana draught
reset_to_defaults() -> void
```

**HexGrid:**
```
place_building(slot_index: int, building_type: Types.BuildingType) -> bool
sell_building(slot_index: int) -> bool
upgrade_building(slot_index: int) -> bool
get_slot_data(slot_index: int) -> Dictionary
get_all_occupied_slots() -> Array[int]
get_empty_slots() -> Array[int]
clear_all_buildings() -> void
```

**ResearchManager:**
```
unlock_node(node_id: String) -> bool
is_unlocked(node_id: String) -> bool
get_available_nodes() -> Array[ResearchNodeData]
reset_to_defaults() -> void
```

**ShopManager:**
```
purchase_item(item_id: String) -> bool
get_available_items() -> Array[ShopItemData]
can_purchase(item_id: String) -> bool
```

**Tower:**
```
fire_crossbow(target_position: Vector3) -> void
fire_rapid_missile(target_position: Vector3) -> void
take_damage(amount: int) -> void
repair_to_full() -> void
get_current_hp() -> int
get_max_hp() -> int
is_weapon_ready(weapon_slot: Types.WeaponSlot) -> bool
```

**Arnulf:**
```
get_current_state() -> Types.ArnulfState
get_current_hp() -> int
get_max_hp() -> int
# Arnulf is fully autonomous — bot observes via signals, doesn't control him
```

### 8.3 SimBot Stub

```gdscript
## sim_bot.gd
## Headless simulation bot. Drives the game loop via public API calls.
## MVP: Stub only — no strategy logic. Exists to prove the API is callable.
##
## Post-MVP strategies:
## - "Arrow Tower Only" — places only arrow towers
## - "Fire Buildings Only" — places only fire braziers
## - "Max Arnulf" — does nothing (Arnulf is autonomous), observes outcomes
##
## Each strategy plays through all 5 missions and logs results.

class_name SimBot
extends Node

var _is_active: bool = false

func activate() -> void:
    _is_active = true
    # Connect to SignalBus signals for observation
    SignalBus.wave_cleared.connect(_on_wave_cleared)
    SignalBus.mission_won.connect(_on_mission_won)
    SignalBus.mission_failed.connect(_on_mission_failed)
    SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
    # Start the game
    GameManager.start_new_game()

func _on_wave_cleared(wave_number: int) -> void:
    pass  # Strategy logic here post-MVP

func _on_mission_won(mission_number: int) -> void:
    pass  # Log results, advance

func _on_mission_failed(mission_number: int) -> void:
    pass  # Log results, stop

func _on_all_waves_cleared() -> void:
    pass  # Wait for GameManager to handle transition
```

### 8.4 Design Violations to Flag

Any of the following patterns is a VIOLATION of the simulation testing constraint:

1. Game logic inside `_input()`, `_unhandled_input()`, or any `InputEvent` handler
2. Game logic inside UI scripts (anything in `res://ui/`)
3. Manager methods that require a specific node to be in the scene tree to function
   (exception: WaveManager needs EnemyContainer and SpawnPoints — acceptable, document it)
4. State changes triggered by UI button signals directly (must go through a manager)
5. Resource modifications not going through EconomyManager
6. Direct node-to-node calls that bypass SignalBus for cross-system communication

---

## 9. NAVIGATION & PATHFINDING DESIGN

### 9.1 NavigationRegion3D Setup

The navigation mesh is hosted on **terrain** scenes (e.g. under `res://scenes/terrain/`) instantiated into `Main/TerrainContainer` at day start. `NavMeshManager` registers the region and can queue rebakes.
It is baked at editor time to cover the playable area.
The tower's collision shape creates a natural obstacle that enemies path around.

### 9.2 Per-Enemy NavigationAgent3D

Each EnemyBase instance has a NavigationAgent3D child.
- `target_position` = `Vector3.ZERO` (tower center)
- `path_desired_distance` = 1.0
- `target_desired_distance` = enemy_data.attack_range
- `avoidance_enabled` = true (enemies avoid each other)
- `radius` = 0.5 (avoidance radius)

### 9.3 Flying Enemies — No NavMesh

Bat Swarm does NOT use NavigationAgent3D. It uses simple steering:
```
direction = (Vector3(0, FLYING_HEIGHT, 0) - global_position).normalized()
velocity = direction * move_speed
```
This gives straight-line flight toward the tower at an elevated Y position.

### 9.4 Dynamic Rebaking — DEFERRED

**FLAG**: Buildings placed on the hex grid do NOT affect the navigation mesh in MVP.
Enemies can overlap with building positions. This is acceptable because buildings are
ranged turrets, not physical walls. If future design requires buildings to block paths,
investigate:
- `NavigationRegion3D.bake_navigation_mesh()` (runtime rebake, may cause frame hitch)
- `NavigationObstacle3D` (dynamic obstacle avoidance without rebaking)
- Async baking via thread (Godot 4.x support TBD)

---

## 10. GROUND PLANE & AIMING RAYCAST

Florence aims by raycasting from the camera through the mouse cursor to the ground plane.

```
InputManager._get_aim_position() -> Vector3:
    1. Get mouse position: get_viewport().get_mouse_position()
    2. Create ray from camera: camera.project_ray_origin(mouse_pos)
       + camera.project_ray_normal(mouse_pos)
    3. Intersect with ground plane (Y = 0):
       var plane := Plane(Vector3.UP, 0.0)
       var intersection: Variant = plane.intersects_ray(ray_origin, ray_direction)
    4. If intersection != null: return intersection as Vector3
       Else: return Vector3.ZERO (fallback)
```

This position is passed to `Tower.fire_crossbow(aim_position)` or
`Tower.fire_rapid_missile(aim_position)`. The Tower spawns a projectile directed
toward that world-space position.

---

## 11. SCENE INSTANTIATION REGISTRY

Preloaded scenes (used frequently, known at compile time):

```gdscript
# In WaveManager:
const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")

# In Tower:
const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")

# In HexGrid:
const BuildingScene: PackedScene = preload("res://scenes/buildings/building_base.tscn")
```

All three use the same pattern: instantiate → initialize(data_resource) → add_child.

---

## 12. SPAWN POINT LAYOUT

10 Marker3D nodes arranged in a circle at the map edge (radius ~40 units from center):

```
SpawnPoint_00: Vector3( 40,  0,   0)    # East
SpawnPoint_01: Vector3( 31,  0,  25)    # ENE
SpawnPoint_02: Vector3( 12,  0,  38)    # NNE
SpawnPoint_03: Vector3(-12,  0,  38)    # NNW
SpawnPoint_04: Vector3(-31,  0,  25)    # WNW
SpawnPoint_05: Vector3(-40,  0,   0)    # West
SpawnPoint_06: Vector3(-31,  0, -25)    # WSW
SpawnPoint_07: Vector3(-12,  0, -38)    # SSW
SpawnPoint_08: Vector3( 12,  0, -38)    # SSE
SpawnPoint_09: Vector3( 31,  0, -25)    # ESE
```

Positions are approximate; the exact circle is `radius * Vector3(cos(θ), 0, sin(θ))`
where θ = i × (2π / 10).
