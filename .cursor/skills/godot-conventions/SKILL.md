---
name: godot-conventions
description: >-
  Activate when writing or reviewing GDScript for Foul Ward. Covers all project-
  specific naming conventions, type safety rules, signal naming, field name
  discipline, code style, initialization order, process function rules, and the
  16 agent rules that are LAW. Use when: naming anything, declaring signals,
  writing new scripts, reviewing code, adding autoloads, using snake_case
  PascalCase UPPER_SNAKE_CASE, export variables, typed arrays, @onready patterns.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Godot Conventions — Foul Ward

These rules are LAW. Two independent agents must produce integrating code
by following this document alone.

---

## Agent Rules (§29 — non-negotiable)

1. Read `AGENTS.md` at session start — every session, no exceptions
2. Validate scene node paths with MCP `get_scene_tree` before writing any `get_node()` call
3. Run `get_godot_errors` after every change
4. Add every new `.gd` file to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
5. Log every session to `docs/PROMPT_[N]_IMPLEMENTATION.md`
6. Register new autoloads in `project.godot` at the correct init position
7. Declare new signals in `autoloads/signal_bus.gd` — past tense snake_case
8. Reference every new `.tres` from at least one `.gd` or other `.tres`
9. Do not change autoload registration order without reading `AGENTS.md`
10. Static typing on ALL parameters, returns, and variable declarations
11. `push_warning()` not `assert()` in production — assert() crashes headless builds
12. `get_node_or_null()` for runtime lookups, always with a null guard
13. `is_instance_valid()` before accessing any enemy, projectile, or ally reference
14. `_physics_process` for all game logic — `_process` for visual/UI only — never mix
15. `initialize()` called before or immediately after `add_child()` — never configure post-add
16. No magic numbers — all tuning in `.tres` resources or named constants in `types.gd`

---

## Naming Conventions Table

| Entity | Convention | Example |
|---|---|---|
| Script file | `snake_case.gd` | `economy_manager.gd` |
| Scene file | `snake_case.tscn` | `enemy_base.tscn` |
| Resource file | `snake_case.tres` | `orc_grunt.tres` |
| `class_name` | PascalCase | `class_name EconomyManager` |
| Enum type | PascalCase | `enum DamageType` |
| Enum value | UPPER_SNAKE_CASE | `DamageType.PHYSICAL` |
| Constant | UPPER_SNAKE_CASE | `const MAX_WAVES := 10` |
| Variable (local/member) | snake_case | `var current_hp: int` |
| Private variable | `_snake_case` | `var _internal_timer: float` |
| Function (public) | snake_case | `func add_gold(amount: int)` |
| Function (private) | `_snake_case` | `func _update_state() -> void` |
| Signal | snake_case past tense | `signal enemy_killed` |
| `@export` variable | snake_case | `@export var move_speed: float` |
| Node in scene tree | PascalCase | `EnemyContainer`, `HexGrid` |
| Test file | `test_<module>.gd` | `test_economy_manager.gd` |
| Test class | `Test<ModuleName>` | `class_name TestEconomyManager` |
| Test function | `test_<method>_<condition>_<expected>` | see testing skill |

---

## Signal Naming

- Past tense for events: `enemy_killed`, `wave_cleared`, `building_placed`
- Present tense for requests: `build_requested`, `sell_requested`
- NEVER future tense
- Payload ALWAYS typed: `signal enemy_killed(enemy_data: EnemyData, position: Vector3, gold_reward: int)`
- Local signals (within one scene tree) may live on the emitting node
- Cross-system signals: SignalBus ONLY — no exceptions

---

## Type Safety

```gdscript
# WRONG
func deal_damage(amount, type):
    var result = amount * get_multiplier(type)

# RIGHT
func deal_damage(amount: float, type: Types.DamageType) -> float:
    var result: float = amount * get_multiplier(type)
    return result
```

- ALL parameters typed
- ALL return types declared (`-> void` for no return)
- ALL variable declarations typed or use `:=` for inference
- NEVER `Variant` unless genuinely needed
- Arrays: `Array[EnemyBase]` not `Array`
- Avoid `Dictionary` when a typed Resource or class would work

---

## Autoload Access Pattern

```gdscript
# CORRECT
EconomyManager.add_gold(50)
SignalBus.enemy_killed.emit(enemy_data, position, gold_reward)

# WRONG — never cache autoloads
var econ = EconomyManager
econ.add_gold(50)
```

---

## Node Reference Patterns

```gdscript
# CORRECT — @onready typed reference within same scene
@onready var health_component: HealthComponent = $HealthComponent

# CORRECT — cross-scene via autoload name
EconomyManager.add_gold(50)

# CORRECT — runtime lookup with null guard
var wave_mgr := get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager
if wave_mgr == null:
    push_warning("WaveManager not found")
    return

# WRONG
var tower = get_node("/root/Main/Tower")  # bare get_node, no null guard
```

---

## Process Function Rules

```gdscript
func _physics_process(delta: float) -> void:
    # ALL game logic: movement, combat, AI timers, state machines

func _process(delta: float) -> void:
    # ONLY visual updates: animations, UI interpolation
    # NEVER game logic here
```

Both respect `Engine.time_scale` automatically.

---

## Initialization Order

Autoload registration order in `project.godot` — do not reorder core game autoloads without reading `AGENTS.md`:

| # | Autoload | Notes |
|---:|---|---|
| 1 | SignalBus | — |
| 2 | NavMeshManager | — |
| 3 | DamageCalculator | — |
| 4 | AuraManager | — |
| 5 | EconomyManager | — |
| 6 | CampaignManager | MUST be before GameManager |
| 7 | RelationshipManager | — |
| 8 | SettingsManager | — |
| 9 | GameManager | — |
| 10 | BuildPhaseManager | — |
| 11 | AllyManager | — |
| 12 | CombatStatsTracker | — |
| 13 | SaveManager | — |
| 14 | DialogueManager | — |
| 15 | AutoTestDriver | — |
| 16 | GDAIMCPRuntime | editor / tooling |
| 17 | EnchantmentManager | after GameManager by registration order |
| 18 | MCPScreenshot | `addons/godot_mcp/` — editor MCP |
| 19 | MCPInputService | `addons/godot_mcp/` |
| 20 | MCPGameInspector | `addons/godot_mcp/` |

**Total:** 20 entries in `[autoload]` (17 core game + GDAIMCPRuntime + EnchantmentManager + 3 Godot MCP addon services).

CampaignManager (#6) MUST be before GameManager (#9).

---

## Field Name Discipline (wrong → correct)

| ❌ Wrong | ✅ Correct | Context |
|---|---|---|
| `build_gold_cost` | `gold_cost` | BuildingData |
| `targeting_priority` | `target_priority` | BuildingData |
| `base_damage_min` / `base_damage_max` | `damage` (single float) | WeaponData |
| `rp_cost` | `research_cost` | ResearchNodeData |
| `hp` / `health` | `max_hp` | EnemyData, AllyData |
| `Types.SpellType` | does NOT exist | — |
| `Types.SpellID` | does NOT exist | — |

---

## Comment Style

```gdscript
## script_name.gd
## One-line purpose.
## Key behaviour and simulation API note.

## Returns true if gold was spent, false if insufficient.
func spend_gold(amount: int) -> bool:

# WHY comment (not what)
# Shockwave is battlefield-wide — intentional design
for enemy in _get_all_enemies():
    enemy.take_damage(spell_data.damage, spell_data.damage_type)
```

---

## @export Documentation

Every `@export` must have a `##` comment above it:
```gdscript
## Base move speed in units/sec.
@export var move_speed: float = 5.0
```

---

## Group Conventions

| Group | Members |
|---|---|
| `"enemies"` | All active EnemyBase instances |
| `"buildings"` | All active BuildingBase instances |
| `"projectiles"` | All active ProjectileBase instances |

---

**Doc drift note:** Older `CONVENTIONS.md` snippets may list fewer autoloads or outdated wave counts. Authoritative game constants: `project.godot` (autoload order), `scripts/types.gd` (BuildingType count), `autoloads/game_manager.gd` (`WAVES_PER_MISSION`, `TOTAL_MISSIONS`).
