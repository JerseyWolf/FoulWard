# FOUL WARD — CONVENTIONS.md
# Prepend this document IN FULL to every Perplexity Pro and Cursor session.
# Every rule here is LAW. Two independent AI instances must produce code that
# integrates without naming conflicts by following this document alone.

---

## Changelog

### 2026-04-14

- §2.4 C# Conventions — PascalCase/`_camelCase`, collections, `FoulWardTypes.cs`; autoload tree lists `DamageCalculator.cs`.

### 2026-03-31

- Refreshed counts, defaults, enums, SignalBus registry, autoload list, and init order to match `docs/FOUL_WARD_MASTER_DOC.md` (§2 Core Architecture, §3 Autoloads, §5 Types.gd, §29–30 agent rules, §32 field names). The MVP-era snapshot is preserved as `docs/archived/CONVENTIONS_MVP.md`.
- **Authoritative detail:** Full APIs, enum-to-integer tables, and the grouped signal reference also live in `docs/FOUL_WARD_MASTER_DOC.md` (especially §3, §5, §24).

---

## 1. FILE & DIRECTORY STRUCTURE

High-level layout (not exhaustive — see repo tree for every file):

```
res://
├── project.godot
├── autoloads/
│   ├── signal_bus.gd              # SignalBus — init #1
│   ├── DamageCalculator.cs        # DamageCalculator — init #3 (C#)
│   ├── aura_manager.gd            # AuraManager — init #4
│   ├── economy_manager.gd         # EconomyManager — init #5
│   ├── campaign_manager.gd        # CampaignManager — init #6
│   ├── relationship_manager.gd    # RelationshipManager — init #7
│   ├── settings_manager.gd        # SettingsManager — init #8
│   ├── game_manager.gd            # GameManager — init #9
│   ├── build_phase_manager.gd     # BuildPhaseManager — init #10
│   ├── ally_manager.gd            # AllyManager — init #11
│   ├── combat_stats_tracker.gd    # CombatStatsTracker — init #12
│   ├── save_manager.gd            # SaveManager — init #13
│   ├── dialogue_manager.gd        # DialogueManager — init #14
│   ├── auto_test_driver.gd        # AutoTestDriver — init #15
│   └── enchantment_manager.gd     # EnchantmentManager — init #17
├── scripts/
│   ├── nav_mesh_manager.gd        # NavMeshManager autoload — init #2
│   ├── types.gd                   # Global enums + constants (class_name Types)
│   ├── health_component.gd
│   ├── wave_manager.gd            # Scene-bound: /root/Main/Managers/WaveManager
│   ├── spell_manager.gd           # Scene-bound: .../SpellManager
│   ├── research_manager.gd        # Scene-bound: .../ResearchManager
│   ├── shop_manager.gd            # Scene-bound: .../ShopManager
│   ├── input_manager.gd           # Scene-bound: .../InputManager
│   ├── weapon_upgrade_manager.gd  # Scene-bound: .../WeaponUpgradeManager
│   └── sim_bot.gd                 # Headless / SimBot
├── scenes/
│   ├── main.tscn
│   ├── tower/
│   ├── arnulf/
│   ├── hex_grid/
│   ├── buildings/
│   ├── enemies/
│   └── projectiles/
├── ui/
│   ├── ui_manager.gd
│   ├── hud.gd / hud.tscn
│   ├── build_menu.gd / build_menu.tscn
│   ├── between_mission_screen.gd / between_mission_screen.tscn
│   ├── main_menu.gd / main_menu.tscn
│   └── end_screen.gd
├── resources/
│   ├── enemy_data/
│   ├── building_data/
│   ├── weapon_data/
│   ├── research_data/
│   ├── shop_data/
│   └── spell_data/
└── tests/
    └── unit/                      # GdUnit4 — `test_<module>.gd`
```

**GDAIMCPRuntime** (init #16) is registered in `project.godot` from the GDAI GDExtension (editor / MCP tooling). **17 gameplay-related autoloads** are listed in §19; with GDAIMCPRuntime that is **18** engine registrations before optional MCP addon autoloads.

Scene-bound managers live under `/root/Main/Managers/` — not additional autoloads. See `docs/FOUL_WARD_MASTER_DOC.md` §4.

---

## 2. NAMING CONVENTIONS

### 2.1 Classes & Scripts

| Entity               | Convention          | Example                      |
|----------------------|---------------------|------------------------------|
| Script file          | snake_case.gd       | `economy_manager.gd`        |
| Scene file           | snake_case.tscn      | `enemy_base.tscn`           |
| Resource file        | snake_case.tres      | `orc_grunt.tres`            |
| class_name           | PascalCase           | `class_name EconomyManager` |
| Enum type            | PascalCase           | `enum DamageType`           |
| Enum value           | UPPER_SNAKE_CASE     | `DamageType.PHYSICAL`       |
| Constant             | UPPER_SNAKE_CASE     | `const WAVES_PER_MISSION := 5` |
| Variable (local/member) | snake_case        | `var current_hp: int`       |
| Private variable     | _snake_case          | `var _internal_timer: float` |
| Function (public)    | snake_case           | `func add_gold(amount: int)` |
| Function (private)   | _snake_case          | `func _update_state() -> void` |
| Signal               | snake_case (past tense verb) | `signal enemy_killed`  |
| @export variable     | snake_case           | `@export var move_speed: float = 5.0` |
| Node in scene tree   | PascalCase           | `EnemyContainer`, `HexGrid` |
| Test file            | test_<module>.gd     | `test_economy_manager.gd`   |
| Test function        | test_<what>_<condition>_<expected> | `test_add_gold_positive_amount_increases_total` |

### 2.2 Signal Naming Rules

All cross-system signals live on `SignalBus` autoload. Signal names:
- Past tense for events that happened: `enemy_killed`, `wave_started`
- Present tense for requests: `build_requested`, `sell_requested`
- NEVER future tense
- Payload is always typed: `signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)`

Local signals (within one scene tree) may live on the emitting node directly.
Name format: `<noun>_<past_verb>` — e.g., `health_depleted`, `cooldown_finished`.

### 2.3 Constants Naming

All gameplay-tuning constants live in the relevant Resource `.tres` files or in `types.gd`.
NEVER use magic numbers inline. Always reference a named constant or resource property.

```gdscript
# WRONG
if mana >= 50:
    mana -= 50

# RIGHT
if mana >= spell_data.mana_cost:
    mana -= spell_data.mana_cost
```

### 2.4 C# Conventions

| Topic | Rule |
|-------|------|
| Methods | **PascalCase** on public and private instance/static methods. |
| Private fields | **`_camelCase`**. |
| Public API | **PascalCase** properties and public fields intended as API. |
| `class_name` | Not required for C# scripts; avoid patterns that shadow autoload singleton names (see `docs/FOUL_WARD_MASTER_DOC.md` §30.15). |
| Helpers | Prefer **`RefCounted`** for stateless or shared helpers not in the scene tree. |
| Scene nodes | Inherit **`Node`** (or appropriate `Node` subclass). |
| Public API surface to GDScript | Prefer **`Godot.Collections`** types where marshalling matters. |
| Internal C#-only code | **`System.Collections.Generic`** is fine. |
| Enums | **`FoulWardTypes.cs`** mirrors `types.gd`; **`types.gd` is source of truth**. |

---

## 3. SHARED VARIABLE NAMES — CROSS-MODULE CONTRACT

These exact variable names and types MUST be used by every module that touches them.
No aliases. No abbreviations. No synonyms.

Extended method lists for autoloads: **`docs/FOUL_WARD_MASTER_DOC.md` §3**.

### 3.1 EconomyManager (autoload: `EconomyManager`)

Defaults match `EconomyManager` constants (`DEFAULT_GOLD`, etc.):

```gdscript
var gold: int = 1000                # DEFAULT_GOLD
var building_material: int = 50     # DEFAULT_BUILDING_MATERIAL
var research_material: int = 0      # DEFAULT_RESEARCH_MATERIAL
```

Public method signatures (canonical — do not rename parameters; additional APIs in master doc §3.5):

```gdscript
func add_gold(amount: int) -> void
func spend_gold(amount: int) -> bool           # Returns false if insufficient
func add_building_material(amount: int) -> void
func spend_building_material(amount: int) -> bool
func add_research_material(amount: int) -> void
func spend_research_material(amount: int) -> bool
func can_afford(gold_cost: int, material_cost: int) -> bool
func reset_to_defaults() -> void
```

### 3.2 GameManager (autoload: `GameManager`)

```gdscript
var current_mission: int = 1        # Mission index (see CampaignManager / DayConfig)
var current_wave: int = 0           # 0 = pre-first-wave; 1..WAVES_PER_MISSION during combat
var game_state: Types.GameState = Types.GameState.MAIN_MENU
const TOTAL_MISSIONS: int = 5
const WAVES_PER_MISSION: int = 5
```

### 3.3 DamageCalculator (autoload: `DamageCalculator`)

```gdscript
func calculate_damage(
    base_damage: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float
```

`Types.DamageType.TRUE` bypasses the armor matrix (see master doc §3.3).

### 3.4 Tower (scene node)

```gdscript
var current_hp: int
var max_hp: int
@export var starting_hp: int = 500
```

### 3.5 Types.gd (class_name Types — NOT an autoload, used via class reference)

`Types.gd` is the single source of truth for enums. **Non-existent:** `Types.SpellType`, `Types.SpellID`.

Additional enums (`AllyRole`, `BuildingSizeClass`, `EnemyBodyType`, `TerrainType`, …): see `scripts/types.gd` and master doc §5.

```gdscript
class_name Types

enum GameState {
    MAIN_MENU,
    MISSION_BRIEFING,
    COMBAT,
    BUILD_MODE,
    WAVE_COUNTDOWN,
    BETWEEN_MISSIONS,
    MISSION_WON,
    MISSION_FAILED,
    GAME_WON,
    GAME_OVER,
    ENDLESS,
}

enum DamageType {
    PHYSICAL,
    FIRE,
    MAGICAL,
    POISON,
    TRUE,
}

enum ArmorType {
    UNARMORED,
    HEAVY_ARMOR,
    UNDEAD,
    FLYING,
}

enum BuildingType {
    ARROW_TOWER,
    FIRE_BRAZIER,
    MAGIC_OBELISK,
    POISON_VAT,
    BALLISTA,
    ARCHER_BARRACKS,
    ANTI_AIR_BOLT,
    SHIELD_GENERATOR,
    SPIKE_SPITTER,
    EMBER_VENT,
    FROST_PINGER,
    NETGUN,
    ACID_DRIPPER,
    WOLFDEN,
    CROW_ROOST,
    ALARM_TOTEMS,
    CROSSFIRE_NEST,
    BOLT_SHRINE,
    THORNWALL,
    FIELD_MEDIC,
    GREATBOW_TURRET,
    MOLTEN_CASTER,
    ARCANE_LENS,
    PLAGUE_MORTAR,
    BEAR_DEN,
    GUST_CANNON,
    WARDEN_SHRINE,
    IRON_CLERIC,
    SIEGE_BALLISTA,
    CHAIN_LIGHTNING,
    FORTRESS_CANNON,
    DRAGON_FORGE,
    VOID_OBELISK,
    PLAGUE_CAULDRON,
    BARRACKS_FORTRESS,
    CITADEL_AURA,
}

enum ArnulfState {
    IDLE,
    PATROL,
    CHASE,
    ATTACK,
    DOWNED,
    RECOVERING,
}

enum ResourceType {
    GOLD,
    BUILDING_MATERIAL,
    RESEARCH_MATERIAL,
}

enum EnemyType {
    ORC_GRUNT,
    ORC_BRUTE,
    GOBLIN_FIREBUG,
    PLAGUE_ZOMBIE,
    ORC_ARCHER,
    BAT_SWARM,
    ORC_SKIRMISHER,
    ORC_RATLING,
    GOBLIN_RUNTS,
    HOUND,
    ORC_RAIDER,
    ORC_MARKSMAN,
    WAR_SHAMAN,
    PLAGUE_SHAMAN,
    TOTEM_CARRIER,
    HARPY_SCOUT,
    ORC_SHIELDBEARER,
    ORC_BERSERKER,
    ORC_SABOTEUR,
    HEXBREAKER,
    WYVERN_RIDER,
    BROOD_CARRIER,
    TROLL,
    IRONCLAD_CRUSHER,
    ORC_OGRE,
    WAR_BOAR,
    ORC_SKYTHROWER,
    WARLORDS_GUARD,
    ORCISH_SPIRIT,
    PLAGUE_HERALD,
}

enum WeaponSlot {
    CROSSBOW,        # Left mouse
    RAPID_MISSILE,   # Right mouse
}

enum TargetPriority {
    CLOSEST,
    HIGHEST_HP,
    FLYING_FIRST,
    LOWEST_HP,
}
```

---

## 4. CUSTOM RESOURCE TYPES

All data-driven configuration uses custom Resource classes. Resources are `.tres` files
loaded at startup. NEVER hardcode stats in scripts.

### 4.1 EnemyData (resource class)

```gdscript
class_name EnemyData
extends Resource

@export var enemy_type: Types.EnemyType
@export var display_name: String = ""
@export var max_hp: int = 100
@export var move_speed: float = 3.0
@export var damage: int = 10
@export var attack_range: float = 1.5        # Melee range for melee, projectile range for ranged
@export var attack_cooldown: float = 1.0
@export var armor_type: Types.ArmorType = Types.ArmorType.UNARMORED
@export var gold_reward: int = 10
@export var is_ranged: bool = false
@export var is_flying: bool = false
@export var color: Color = Color.GREEN       # MVP cube color
```

### 4.2 BuildingData (resource class)

```gdscript
class_name BuildingData
extends Resource

@export var building_type: Types.BuildingType
@export var display_name: String = ""
@export var gold_cost: int = 50
@export var material_cost: int = 2
@export var upgrade_gold_cost: int = 75
@export var upgrade_material_cost: int = 3
@export var damage: float = 20.0
@export var upgraded_damage: float = 35.0
@export var fire_rate: float = 1.0           # Shots per second
@export var attack_range: float = 15.0
@export var upgraded_range: float = 18.0
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
@export var targets_air: bool = false
@export var targets_ground: bool = true
@export var is_locked: bool = false          # Requires research to unlock
@export var unlock_research_id: String = ""  # Research node ID that unlocks this
@export var color: Color = Color.GRAY        # MVP cube color
```

### 4.3 WeaponData (resource class)

```gdscript
class_name WeaponData
extends Resource

@export var weapon_slot: Types.WeaponSlot
@export var display_name: String = ""
@export var damage: float = 50.0
@export var projectile_speed: float = 30.0
@export var reload_time: float = 2.5         # Seconds between shots/bursts
@export var burst_count: int = 1             # 1 for crossbow, 10 for rapid missile
@export var burst_interval: float = 0.0      # Seconds between burst shots
@export var can_target_flying: bool = false   # Always false for Florence in MVP
```

### 4.4 SpellData (resource class)

```gdscript
class_name SpellData
extends Resource

@export var spell_id: String = "shockwave"
@export var display_name: String = "Shockwave"
@export var mana_cost: int = 50
@export var cooldown: float = 60.0
@export var damage: float = 30.0
@export var radius: float = 100.0            # Battlefield-wide for shockwave
@export var damage_type: Types.DamageType = Types.DamageType.MAGICAL
@export var hits_flying: bool = false         # Shockwave = ground AoE
```

### 4.5 ResearchNodeData (resource class)

```gdscript
class_name ResearchNodeData
extends Resource

@export var node_id: String = ""             # e.g., "unlock_ballista"
@export var display_name: String = ""
@export var research_cost: int = 2
@export var prerequisite_ids: Array[String] = []  # Empty = no prerequisites
@export var description: String = ""
```

### 4.6 ShopItemData (resource class)

```gdscript
class_name ShopItemData
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export var gold_cost: int = 50
@export var material_cost: int = 0
@export var description: String = ""
```

**Field name discipline (wrong → correct):** `gold_cost` not `build_gold_cost`; `target_priority` not `targeting_priority`; `research_cost` not `rp_cost`; `damage` on WeaponData not `base_damage_min`/`base_damage_max`. Full table: **`docs/FOUL_WARD_MASTER_DOC.md` §32**.

---

## 5. SIGNAL BUS — COMPLETE SIGNAL REGISTRY

All signals below live on the `SignalBus` autoload (`res://autoloads/signal_bus.gd`). **58+** typed declarations — the only place cross-system signals are declared. No logic or state on SignalBus.

Grouped reference (matches `docs/FOUL_WARD_MASTER_DOC.md` §24):

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

## 6. NODE REFERENCE PATTERNS

### 6.1 NEVER use string paths to find nodes

```gdscript
# FORBIDDEN — breaks on scene tree changes
var tower = get_node("/root/Main/Tower")

# CORRECT — typed @onready reference within same scene
@onready var tower: Tower = $Tower

# CORRECT — cross-scene via autoload
GameManager.some_method()

# CORRECT — cross-scene via signal (preferred for loose coupling)
SignalBus.enemy_killed.connect(_on_enemy_killed)
```

Runtime lookups outside the edited scene: use `get_node_or_null()` and null-guard (see `docs/FOUL_WARD_MASTER_DOC.md` §30.2).

### 6.2 @onready pattern

All node references use `@onready var name: Type = $NodeName`. Always include the type.

```gdscript
@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
```

### 6.3 Typed references for child scenes

When a parent scene instances a child scene, the parent declares a typed @export or
@onready variable. The child scene's root script must have a `class_name`.

---

## 7. SCENE INSTANTIATION PATTERNS

### 7.1 Preload for known scene types (used frequently, known at compile time)

```gdscript
const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")
const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")
```

### 7.2 Load for data-driven or rarely used scenes

```gdscript
var scene: PackedScene = load("res://scenes/buildings/building_base.tscn")
```

### 7.3 Instantiation pattern

```gdscript
func _spawn_enemy(enemy_data: EnemyData, spawn_position: Vector3) -> EnemyBase:
    var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
    enemy.initialize(enemy_data)
    enemy.global_position = spawn_position
    enemy_container.add_child(enemy)
    return enemy
```

RULE: Every scene that gets instantiated at runtime MUST have an `initialize()` method.
NEVER configure an instanced scene by setting properties after `add_child()` — always
call `initialize()` BEFORE `add_child()` when possible, or immediately after if the
node needs to be in the tree first.

---

## 8. AUTOLOAD ACCESS PATTERNS

Autoloads are registered in `project.godot` with these exact names (order: §19):

| Script | Autoload Name |
|--------|----------------|
| `res://autoloads/signal_bus.gd` | `SignalBus` |
| `res://scripts/nav_mesh_manager.gd` | `NavMeshManager` |
| `res://autoloads/damage_calculator.gd` | `DamageCalculator` |
| `res://autoloads/aura_manager.gd` | `AuraManager` |
| `res://autoloads/economy_manager.gd` | `EconomyManager` |
| `res://autoloads/campaign_manager.gd` | `CampaignManager` |
| `res://autoloads/relationship_manager.gd` | `RelationshipManager` |
| `res://autoloads/settings_manager.gd` | `SettingsManager` |
| `res://autoloads/game_manager.gd` | `GameManager` |
| `res://autoloads/build_phase_manager.gd` | `BuildPhaseManager` |
| `res://autoloads/ally_manager.gd` | `AllyManager` |
| `res://autoloads/combat_stats_tracker.gd` | `CombatStatsTracker` |
| `res://autoloads/save_manager.gd` | `SaveManager` |
| `res://autoloads/dialogue_manager.gd` | `DialogueManager` |
| `res://autoloads/auto_test_driver.gd` | `AutoTestDriver` |
| *(GDAI GDExtension UID in project.godot)* | `GDAIMCPRuntime` |
| `res://autoloads/enchantment_manager.gd` | `EnchantmentManager` |

Access pattern: Always use the autoload name directly. Never cache it in a variable.

```gdscript
# CORRECT
EconomyManager.add_gold(50)
SignalBus.enemy_killed.emit(enemy_type, position, gold_reward)

# WRONG — unnecessary indirection
var econ = EconomyManager
econ.add_gold(50)
```

---

## 9. ERROR HANDLING & NULL CHECKS

### 9.1 Assertions vs production and headless

Avoid `assert()` for conditions that must hold during normal gameplay or in **headless / export** builds — failed asserts crash the process. Use `push_warning()` and early return instead (see `docs/FOUL_WARD_MASTER_DOC.md` §30.4). Reserve `assert()` for strict editor-only or test-only checks if used at all.

```gdscript
func spend_gold(amount: int) -> bool:
    if amount <= 0:
        push_warning("spend_gold called with non-positive amount: %d" % amount)
        return false
    if gold < amount:
        return false
    gold -= amount
    return true
```

### 9.2 Null checks for runtime safety

Any node reference obtained at runtime (not @onready) must be null-checked:

```gdscript
var target: EnemyBase = _find_closest_enemy()
if target == null:
    return
# proceed with target
```

### 9.3 is_instance_valid for deferred references

Enemies and projectiles can be freed mid-frame. Always check before accessing:

```gdscript
if is_instance_valid(target_enemy):
    _move_toward(target_enemy.global_position)
```

### 9.4 Return values for failable operations

Functions that can fail return `bool` (success/failure) or `null` (not found).
NEVER use exceptions or error codes. Document failure conditions in the docstring.

---

## 10. COMMENT STYLE

### 10.1 Script header (every .gd file)

```gdscript
## economy_manager.gd
## Tracks gold, building material, and research material.
## Exposes public transaction methods for all systems that modify resources.
## Emits resource_changed via SignalBus on every modification.
##
## Simulation API: All public methods callable without UI nodes present.
```

### 10.2 Function documentation

```gdscript
## Attempts to spend [amount] gold. Returns true if successful, false if
## insufficient funds. Emits SignalBus.resource_changed on success.
func spend_gold(amount: int) -> bool:
```

### 10.3 Inline comments

Explain WHY, not WHAT. The code shows what.

```gdscript
# Shockwave damages all enemies regardless of distance — it is battlefield-wide
for enemy in _get_all_enemies():
    enemy.take_damage(spell_data.damage, spell_data.damage_type)
```

### 10.4 Assumption comments

When a module assumes something about another module's behavior:

```gdscript
# ASSUMPTION: EconomyManager.spend_gold() emits resource_changed via SignalBus
```

### 10.5 Deviation comments

When code intentionally differs from the spec:

```gdscript
# DEVIATION: Using 0.08 time_scale instead of 0.1 — 0.1 felt too fast during
# manual testing. Revert if spec compliance is required.
```

### 10.6 Credit block (for adapted external code)

```gdscript
# ============================================================
# Credit: [Project Name]
# Source: [Full URL]
# License: [License type]
# Adapted by: Foul Ward team
# What was used: [Brief description of what was taken/adapted]
# ============================================================
```

---

## 11. @EXPORT VARIABLE DOCUMENTATION

Every @export variable must have an inline `##` comment above it:

```gdscript
## Base movement speed in units per second. Affected by drunkenness in full GDD.
@export var move_speed: float = 5.0

## Maximum hit points. Reset to this value at mission start.
@export var max_hp: int = 200
```

---

## 12. GdUnit4 TEST CONVENTIONS

### 12.1 File naming

Test file: `test_<module_name>.gd` in `res://tests/unit/` directory.
Test class: `class_name Test<ModuleName>` extending `GdUnitTestSuite`.

### 12.2 Test function naming

```
test_<method_or_behavior>_<condition>_<expected_result>
```

Examples:
```gdscript
func test_add_gold_positive_amount_increases_total() -> void:
func test_spend_gold_insufficient_funds_returns_false() -> void:
func test_arnulf_downed_state_recovers_after_three_seconds() -> void:
func test_wave_scaling_wave_5_spawns_30_enemies() -> void:
```

### 12.3 Test structure (Arrange-Act-Assert)

```gdscript
func test_spend_gold_sufficient_funds_returns_true() -> void:
    # Arrange
    var econ := EconomyManager
    econ.reset_to_defaults()
    econ.add_gold(200)

    # Act
    var result: bool = econ.spend_gold(150)

    # Assert
    assert_bool(result).is_true()
    assert_int(econ.gold).is_equal(1050)  # 1000 default + 200 added - 150 spent
```

### 12.4 Test isolation

Every test must call the relevant manager's `reset_to_defaults()` in setup or at the
start of the test. Tests MUST NOT depend on execution order.

### 12.5 Signal testing

Use GdUnit4's signal assertion helpers:

```gdscript
func test_add_gold_emits_resource_changed() -> void:
    var econ := EconomyManager
    econ.reset_to_defaults()

    # Use GdUnit4 signal monitoring
    var monitor := monitor_signals(SignalBus)
    econ.add_gold(50)
    await assert_signal(monitor).is_emitted("resource_changed")
```

---

## 13. TYPE SAFETY RULES

- ALL function parameters must have explicit types
- ALL function return types must be declared (use `-> void` for no return)
- ALL variable declarations must have explicit types or `:=` for inference
- NEVER use `Variant` unless genuinely needed (rare)
- Arrays must be typed: `Array[EnemyBase]`, not `Array`
- Dictionaries: avoid when a typed Resource or class would work instead

```gdscript
# WRONG
func deal_damage(amount, type):
    var result = amount * get_multiplier(type)

# RIGHT
func deal_damage(amount: float, type: Types.DamageType) -> float:
    var result: float = amount * get_multiplier(type)
```

---

## 14. PROCESS FUNCTION RULES

- `_process(delta)` — for visual updates, UI, non-physics interpolation
- `_physics_process(delta)` — for ALL game logic: movement, combat, timers
- NEVER mix. If it affects gameplay, it goes in `_physics_process`.
- Both respect `Engine.time_scale` automatically — no manual scaling needed.

---

## 15. GROUP CONVENTIONS

Nodes that need to be found by category use Godot groups:

| Group Name    | Members                              |
|---------------|--------------------------------------|
| `"enemies"`   | All active EnemyBase instances       |
| `"buildings"` | All active BuildingBase instances    |
| `"projectiles"` | All active ProjectileBase instances |

Access pattern:
```gdscript
var all_enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
```

---

## 16. LAYER & MASK CONVENTIONS (Physics)

| Layer # | Name            | Used By                          |
|---------|-----------------|----------------------------------|
| 1       | Tower           | Tower collision body             |
| 2       | Enemies         | All enemy collision bodies       |
| 3       | Arnulf          | Arnulf's collision body          |
| 4       | Buildings       | All building collision bodies    |
| 5       | Projectiles     | All projectile collision bodies  |
| 6       | Ground          | Ground plane / navigation mesh   |
| 7       | HexSlots        | Hex slot click detection (Area3D)|

Florence projectiles: collision_mask = Layer 2 (Enemies) only.
Building projectiles: collision_mask = Layer 2 (Enemies) only.
Enemies: collision_mask = Layer 1 (Tower) + Layer 3 (Arnulf) + Layer 4 (Buildings).

---

## 17. INPUT ACTION NAMES

Defined in `project.godot` Input Map:

| Action Name        | Default Binding  | Purpose                      |
|--------------------|-----------------|-------------------------------|
| `fire_primary`     | Left Mouse      | Florence crossbow             |
| `fire_secondary`   | Right Mouse     | Florence rapid missile        |
| `cast_shockwave`   | Space           | Sybil's shockwave spell      |
| `toggle_build_mode`| B or Tab        | Enter/exit build mode         |
| `cancel`           | Escape          | Exit build mode / close menu  |

---

## 18. COORDINATE SYSTEM

- Godot 4 uses Y-up coordinate system
- Ground plane is at Y = 0
- Tower center is at world origin: Vector3(0, 0, 0)
- Hex grid positions are computed from axial coordinates and stored as Vector3
- All positions use `global_position`, never `position`, for cross-node calculations
- Flying enemies have Y offset (e.g., Y = 5.0) above ground level

---

## 19. INITIALIZATION ORDER

Autoloads initialize in **registration order** in `project.godot` (do not reorder without reading `AGENTS.md` / master doc §3):

1. SignalBus (no dependencies)
2. NavMeshManager (no dependencies)
3. DamageCalculator (no dependencies)
4. AuraManager (no dependencies)
5. EconomyManager (depends on SignalBus)
6. CampaignManager (must load before GameManager)
7. RelationshipManager
8. SettingsManager
9. GameManager (depends on CampaignManager)
10. BuildPhaseManager
11. AllyManager
12. CombatStatsTracker
13. SaveManager
14. DialogueManager
15. AutoTestDriver
16. GDAIMCPRuntime (editor / MCP)
17. EnchantmentManager

Scene `_ready()` order follows Godot's bottom-up tree traversal.
NEVER rely on `_ready()` order between sibling nodes — use signals or call_deferred().
