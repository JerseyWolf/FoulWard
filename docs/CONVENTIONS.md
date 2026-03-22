# FOUL WARD — CONVENTIONS.md
# Prepend this document IN FULL to every Perplexity Pro and Cursor session.
# Every rule here is LAW. Two independent AI instances must produce code that
# integrates without naming conflicts by following this document alone.

---

## 1. FILE & DIRECTORY STRUCTURE

```
res://
├── project.godot
├── autoloads/
│   ├── signal_bus.gd          # SignalBus singleton
│   ├── game_manager.gd        # GameManager singleton
│   ├── economy_manager.gd     # EconomyManager singleton
│   └── damage_calculator.gd   # DamageCalculator singleton
├── scenes/
│   ├── main.tscn              # Root scene
│   ├── tower/
│   │   └── tower.tscn
│   ├── arnulf/
│   │   └── arnulf.tscn
│   ├── hex_grid/
│   │   └── hex_grid.tscn
│   ├── buildings/
│   │   ├── building_base.tscn
│   │   └── building_base.gd
│   ├── enemies/
│   │   ├── enemy_base.tscn
│   │   └── enemy_base.gd
│   └── projectiles/
│       ├── projectile_base.tscn
│       └── projectile_base.gd
├── scripts/
│   ├── types.gd               # Global enums + constants (class_name Types)
│   ├── health_component.gd    # Reusable HP component
│   ├── wave_manager.gd
│   ├── spell_manager.gd
│   ├── research_manager.gd
│   ├── shop_manager.gd
│   ├── input_manager.gd       # Translates input → public method calls
│   └── sim_bot.gd             # Headless bot stub
├── ui/
│   ├── ui_manager.gd          # Lightweight signal→panel router
│   ├── hud.gd
│   ├── hud.tscn
│   ├── build_menu.gd
│   ├── build_menu.tscn
│   ├── between_mission_screen.gd
│   ├── between_mission_screen.tscn
│   ├── main_menu.gd
│   ├── main_menu.tscn
│   └── end_screen.gd
├── resources/
│   ├── enemy_data/
│   │   ├── orc_grunt.tres
│   │   ├── orc_brute.tres
│   │   ├── goblin_firebug.tres
│   │   ├── plague_zombie.tres
│   │   ├── orc_archer.tres
│   │   └── bat_swarm.tres
│   ├── building_data/
│   │   ├── arrow_tower.tres
│   │   ├── fire_brazier.tres
│   │   ├── magic_obelisk.tres
│   │   ├── poison_vat.tres
│   │   ├── ballista.tres
│   │   ├── archer_barracks.tres
│   │   ├── anti_air_bolt.tres
│   │   └── shield_generator.tres
│   ├── weapon_data/
│   │   ├── crossbow.tres
│   │   └── rapid_missile.tres
│   ├── research_data/
│   │   └── base_structures_tree.tres
│   ├── shop_data/
│   │   └── shop_catalog.tres
│   └── spell_data/
│       └── shockwave.tres
└── tests/
    ├── test_economy_manager.gd
    ├── test_damage_calculator.gd
    ├── test_wave_manager.gd
    ├── test_spell_manager.gd
    ├── test_arnulf_state_machine.gd
    ├── test_health_component.gd
    ├── test_research_manager.gd
    ├── test_shop_manager.gd
    ├── test_game_manager.gd
    ├── test_hex_grid.gd
    ├── test_building_base.gd
    ├── test_projectile_system.gd
    └── test_simulation_api.gd
```

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
| Constant             | UPPER_SNAKE_CASE     | `const MAX_WAVES := 10`     |
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
- Payload is always typed: `signal enemy_killed(enemy_data: EnemyData, position: Vector3, gold_reward: int)`

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

---

## 3. SHARED VARIABLE NAMES — CROSS-MODULE CONTRACT

These exact variable names and types MUST be used by every module that touches them.
No aliases. No abbreviations. No synonyms.

### 3.1 EconomyManager (autoload: `EconomyManager`)

```gdscript
var gold: int = 100                 # Starting gold
var building_material: int = 10     # Starting building material
var research_material: int = 0      # Starting research material
```

Public method signatures (canonical — do not rename parameters):
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
var current_mission: int = 1        # 1-5
var current_wave: int = 0           # 0 = pre-first-wave, 1-10 during combat
var game_state: Types.GameState = Types.GameState.MAIN_MENU
const TOTAL_MISSIONS: int = 5
const WAVES_PER_MISSION: int = 10
```

### 3.3 DamageCalculator (autoload: `DamageCalculator`)

```gdscript
func calculate_damage(
    base_damage: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float
```

### 3.4 Tower (scene node)

```gdscript
var current_hp: int
var max_hp: int
@export var starting_hp: int = 500
```

### 3.5 Types.gd (class_name Types — NOT an autoload, used via class reference)

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
}

enum DamageType {
    PHYSICAL,
    FIRE,
    MAGICAL,
    POISON,
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
}

enum WeaponSlot {
    CROSSBOW,        # Left mouse
    RAPID_MISSILE,   # Right mouse
}

enum TargetPriority {
    CLOSEST,
    HIGHEST_HP,
    FLYING_FIRST,
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

---

## 5. SIGNAL BUS — COMPLETE SIGNAL REGISTRY

All signals below live on the `SignalBus` autoload. This is the ONLY place cross-system
signals are declared. No exceptions.

```gdscript
# === COMBAT ===
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
signal building_destroyed(slot_index: int)  # POST-MVP — not emitted by any module in MVP. Buildings cannot take damage in MVP. Keep as stub for future use.
signal tower_damaged(current_hp: int, max_hp: int)
signal tower_destroyed()
signal projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)
signal arnulf_state_changed(new_state: Types.ArnulfState)
signal arnulf_incapacitated()
signal arnulf_recovered()

# === WAVES ===
signal wave_countdown_started(wave_number: int, seconds_remaining: float)
signal wave_started(wave_number: int, enemy_count: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared()

# === ECONOMY ===
signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

# === BUILDINGS ===
signal building_placed(slot_index: int, building_type: Types.BuildingType)
signal building_sold(slot_index: int, building_type: Types.BuildingType)
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
signal building_destroyed(slot_index: int)  # POST-MVP — not emitted by any module in MVP. Buildings cannot take damage in MVP. Keep as stub for future use.

# === SPELLS ===
signal spell_cast(spell_id: String)
signal spell_ready(spell_id: String)
signal mana_changed(current_mana: int, max_mana: int)

# === GAME STATE ===
signal game_state_changed(old_state: Types.GameState, new_state: Types.GameState)
signal mission_started(mission_number: int)
signal mission_won(mission_number: int)
signal mission_failed(mission_number: int)

# === BUILD MODE ===
signal build_mode_entered()
signal build_mode_exited()

# === RESEARCH ===
signal research_unlocked(node_id: String)

# === SHOP ===
signal shop_item_purchased(item_id: String)
```

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

Autoloads are registered in `project.godot` with these exact names:

| Script                          | Autoload Name      |
|---------------------------------|--------------------|
| `res://autoloads/signal_bus.gd` | `SignalBus`        |
| `res://autoloads/game_manager.gd` | `GameManager`   |
| `res://autoloads/economy_manager.gd` | `EconomyManager` |
| `res://autoloads/damage_calculator.gd` | `DamageCalculator` |

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

### 9.1 Assertions for development

Use `assert()` for conditions that should NEVER be false in correct code:

```gdscript
func spend_gold(amount: int) -> bool:
    assert(amount > 0, "spend_gold called with non-positive amount: %d" % amount)
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

Test file: `test_<module_name>.gd` in `res://tests/` directory.
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
    assert_int(econ.gold).is_equal(150)  # 100 default + 200 added - 150 spent
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

Autoloads initialize in this order (as registered in project.godot):
1. SignalBus (no dependencies)
2. DamageCalculator (no dependencies)
3. EconomyManager (depends on SignalBus)
4. GameManager (depends on SignalBus, EconomyManager)

Scene _ready() order follows Godot's bottom-up tree traversal.
NEVER rely on _ready() order between sibling nodes — use signals or call_deferred().
