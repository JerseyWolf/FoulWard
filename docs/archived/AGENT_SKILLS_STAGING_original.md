FILE SET: Foul Ward Agent Skills System

Target structure:

text
AGENTS.md                          ← repo root (upgraded)
.cursor/skills/
  godot-conventions/SKILL.md
  anti-patterns/SKILL.md
  signal-bus/SKILL.md
  signal-bus/references/signal-table.md
  enemy-system/SKILL.md
  enemy-system/references/enemy-types.md
  building-system/SKILL.md
  building-system/references/building-types.md
  economy-system/SKILL.md
  campaign-and-progression/SKILL.md
  campaign-and-progression/references/game-manager-api.md
  testing/SKILL.md
  add-new-entity/SKILL.md
  mcp-workflow/SKILL.md
  scene-tree-and-physics/SKILL.md
  spell-and-research-system/SKILL.md
  ally-and-mercenary-system/SKILL.md
  lifecycle-flows/SKILL.md
  save-and-dialogue/SKILL.md

FILE 1: AGENTS.md (repo root — upgraded from docs/AGENTS.md)

text
# Foul Ward — Agent Standing Orders
Last updated: 2026-03-31 (upgraded to Agent Skills root file)

> Read this file FIRST in every Cursor session, before opening any other file.
> This file is the always-loaded foundation. It points to skills for detail.

---

## What

Godot 4.4 GDScript real-time tower defense (inspired by TAUR).
Player IS Florence — a stationary tower aimed manually with the mouse.
50-day main campaign. Each day = one mission (build phase → wave combat).
525 GdUnit4 tests. 17 autoloads. 36 building types. 30 enemy types. 58+ signals.
Two weapons: Crossbow (CROSSBOW slot) and Rapid Missile (RAPID_MISSILE slot).
AI ally Arnulf (melee), Sybil (spell support). Hex grid: 24 slots across 3 rings.

---

## Architecture

17 autoloads init in strict order (SignalBus first, EnchantmentManager last).
6 scene-bound managers live under `/root/Main/Managers/` — not autoloads.
All data is resource-driven (.tres files). No magic numbers in .gd scripts.
All cross-system events go through SignalBus — no direct calls between autoloads.
SimBot / AutoTestDriver enables headless simulation without UI nodes.

### Autoload Init Order (DO NOT CHANGE without reading docs/AGENTS.md)

1.  SignalBus (`autoloads/signal_bus.gd`) — no deps
2.  NavMeshManager (`scripts/nav_mesh_manager.gd`) — no deps
3.  DamageCalculator (`autoloads/damage_calculator.gd`) — no deps
4.  AuraManager (`autoloads/aura_manager.gd`) — no deps
5.  EconomyManager (`autoloads/economy_manager.gd`) — depends on SignalBus
6.  CampaignManager (`autoloads/campaign_manager.gd`) — MUST load before GameManager
7.  RelationshipManager (`autoloads/relationship_manager.gd`)
8.  SettingsManager (`autoloads/settings_manager.gd`)
9.  GameManager (`autoloads/game_manager.gd`) — depends on CampaignManager
10. BuildPhaseManager (`autoloads/build_phase_manager.gd`)
11. AllyManager (`autoloads/ally_manager.gd`)
12. CombatStatsTracker (`autoloads/combat_stats_tracker.gd`)
13. SaveManager (`autoloads/save_manager.gd`)
14. DialogueManager (`autoloads/dialogue_manager.gd`)
15. AutoTestDriver (`autoloads/auto_test_driver.gd`)
16. GDAIMCPRuntime — editor only
17. EnchantmentManager (`autoloads/enchantment_manager.gd`)

### Scene-Bound Manager Paths (contracted — never assume)

- `/root/Main/Managers/WaveManager`
- `/root/Main/Managers/SpellManager`
- `/root/Main/Managers/ResearchManager`
- `/root/Main/Managers/ShopManager`
- `/root/Main/Managers/WeaponUpgradeManager`
- `/root/Main/Managers/InputManager`

---

## How to Verify Changes

```bash
./tools/run_gdunit_quick.sh        # after every change (~fast)
./tools/run_gdunit_unit.sh         # unit tests only, ~65s
./tools/run_gdunit_parallel.sh     # full suite, 8 parallel, ~2m45s
./tools/run_gdunit.sh              # sequential baseline before declaring done
```

MCP verification after every session:
- `get_scene_tree` — validate node paths before any get_node() call
- `get_godot_errors` — check for new errors after changes

---

## Critical Rules (always apply)

1. Static typing on ALL parameters, returns, and variable declarations
2. ALL cross-system events through SignalBus — no direct connects between unrelated nodes
3. Access autoloads by name: `EconomyManager.add_gold(50)` — never cache in a var
4. No magic numbers — all tuning in .tres resources or named constants in types.gd
5. `get_node_or_null()` for runtime lookups — never bare `get_node()` in headless contexts
6. `is_instance_valid()` before accessing enemies, projectiles, or allies (freed mid-frame)
7. `push_warning()` not `assert()` in production — assert() crashes headless builds
8. Signals: past tense for events (`enemy_killed`), present for requests (`build_requested`)
9. `_physics_process` for game logic — `_process` for visual/UI only — NEVER mix
10. Scene instantiation: call `initialize()` before or immediately after `add_child()`
11. ALL cross-system events use SignalBus — no direct method calls between autoloads for events
12. ALL node path lookups use `get_node_or_null()` with null guard
13. `SaveManager.save_current_state()` auto-called on mission_won/failed — no extra save calls
14. EVERY new .gd file → add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
15. EVERY session → log to `docs/PROMPT_[N]_IMPLEMENTATION.md` (next unused N)
16. EVERY new signal declared in `autoloads/signal_bus.gd`, past tense snake_case

---

## Field Name Discipline (wrong → correct)

| ❌ Wrong | ✅ Correct | Where |
|---|---|---|
| `build_gold_cost` | `gold_cost` | BuildingData |
| `targeting_priority` | `target_priority` | BuildingData |
| `base_damage_min` / `base_damage_max` | `damage` (single float) | WeaponData |
| `rp_cost` | `research_cost` | ResearchNodeData |
| `hp` / `health` | `max_hp` | EnemyData, AllyData |
| `spell_type` | spell_id is a String | SpellData |
| `Types.SpellType` | does NOT exist | Types.gd |
| `Types.SpellID` | does NOT exist | Types.gd |

---

## Formally Cut Features — NEVER Implement

- **Arnulf drunkenness system** — cut, do not implement
- **Time Stop spell** — cut, do not implement
- **Hades-style 3D hub** — cut, do not implement
- **Sybil passive selection system** — PLANNED, not in code yet; stubs only
- **Affinity XP system (EnchantmentManager)** — POST-MVP, all methods inert

---

## Available Skills — Load Before Working on That System

| When working on... | Load this skill |
|---|---|
| Naming, typing, style, field names | `.cursor/skills/godot-conventions/` |
| Code review, bugs, wrong patterns | `.cursor/skills/anti-patterns/` |
| Signals, SignalBus, connect/emit | `.cursor/skills/signal-bus/` |
| Enemies, damage, armor, bosses | `.cursor/skills/enemy-system/` |
| Buildings, hex grid, placement | `.cursor/skills/building-system/` |
| Gold, resources, costs, refunds | `.cursor/skills/economy-system/` |
| Campaign, days, territories, GameManager | `.cursor/skills/campaign-and-progression/` |
| GdUnit4 tests, SimBot, headless | `.cursor/skills/testing/` |
| Adding new building/signal/spell/research | `.cursor/skills/add-new-entity/` |
| MCP servers, Godot MCP, GDAI | `.cursor/skills/mcp-workflow/` |
| Scene tree, physics layers, input | `.cursor/skills/scene-tree-and-physics/` |
| Spells, mana, research, enchantments | `.cursor/skills/spell-and-research-system/` |
| Allies, Arnulf, mercenaries | `.cursor/skills/ally-and-mercenary-system/` |
| Mission flow, game loop, startup | `.cursor/skills/lifecycle-flows/` |
| Save/load, dialogue, relationships | `.cursor/skills/save-and-dialogue/` |

---

## Key Documents

| File | Purpose |
|---|---|
| `docs/FOUL_WARD_MASTER_DOC.md` | Human-readable encyclopedia — all systems |
| `docs/AGENTS.md` | Full standing orders (detail version of this file) |
| `docs/CONVENTIONS.md` | Naming, typing, style law |
| `docs/ARCHITECTURE.md` | Scene tree, class responsibilities, signal flow |
| `docs/INDEX_SHORT.md` | One-liner per file index |
| `docs/INDEX_FULL.md` | Full public API reference |
| `docs/SUMMARY_VERIFICATION.md` | Read-only audit results |

---

## Known Gotchas (top 5 — see docs/AGENTS.md §9 for full list)

1. **AllyData is a Resource** — use typed field access (`ally_data.ally_id`), not `.get(key, default)`
2. **CampaignManager MUST load before GameManager** — day increment must fire before hub transition
3. **WaveManager is a scene node, not an autoload** — GameManager silently skips if absent (headless safe)
4. **SaveManager / RelationshipManager have no `class_name`** — intentional; do not add one
5. **`slow_field.tres` has `damage = 0.0`** — intentional control spell; do not fix

FILE 2: .cursor/skills/godot-conventions/SKILL.md

text
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

1. Read `docs/AGENTS.md` at session start — every session, no exceptions
2. Validate scene node paths with MCP `get_scene_tree` before writing any `get_node()` call
3. Run `get_godot_errors` after every change
4. Add every new `.gd` file to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
5. Log every session to `docs/PROMPT_[N]_IMPLEMENTATION.md`
6. Register new autoloads in `project.godot` at the correct init position
7. Declare new signals in `autoloads/signal_bus.gd` — past tense snake_case
8. Reference every new `.tres` from at least one `.gd` or other `.tres`
9. Do not change autoload registration order without reading `docs/AGENTS.md`
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

Autoloads initialize in strict order — do not reorder:
1→SignalBus 2→NavMeshManager 3→DamageCalculator 4→AuraManager 5→EconomyManager
6→CampaignManager 7→RelationshipManager 8→SettingsManager 9→GameManager
10→BuildPhaseManager 11→AllyManager 12→CombatStatsTracker 13→SaveManager
14→DialogueManager 15→AutoTestDriver 16→GDAIMCPRuntime 17→EnchantmentManager

CampaignManager (#6) MUST be before GameManager (#9).
EnchantmentManager (#17) is AFTER GameManager — intentional (both in tree by _ready()).

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

> ⚠️ VERIFY: `CONVENTIONS.md` in the repo lists only 4 autoloads, 8 building types, and `WAVES_PER_MISSION = 10`. These are MVP-era values. The authoritative counts are in `FOUL_WARD_MASTER_DOC.md` (17 autoloads, 36 buildings, `WAVES_PER_MISSION = 5`). The CONVENTIONS.md file needs updating.

FILE 3: .cursor/skills/anti-patterns/SKILL.md

text
---
name: anti-patterns
description: >-
  Activate when writing, reviewing, or debugging any GDScript in Foul Ward.
  Contains all 14 project-specific anti-patterns with WRONG and RIGHT code
  examples. Use when: code review, finding bugs, SignalBus violations, null
  guard errors, freed node crashes, assert in production, get_node without guard,
  add_child before initialize, class_name on autoload, stdout in MCP, hardcoded
  stats, untyped code, Godot 3 syntax, signal connect without guard.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Anti-Patterns — Foul Ward

All 14 known failure modes with correct alternatives. Agents repeatedly make
these exact mistakes. Verify against this list before every code review.

---

## AP-01: Bare `get_node()` Without Null Guard

```gdscript
# WRONG — crashes in headless/test contexts
var wave_mgr = get_node("/root/Main/Managers/WaveManager")
wave_mgr.start_wave_sequence()

# RIGHT
var wave_mgr := get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager
if wave_mgr == null:
    push_warning("WaveManager not found — skipping wave start")
    return
wave_mgr.start_wave_sequence()
```

---

## AP-02: Accessing Freed Nodes Without `is_instance_valid()`

```gdscript
# WRONG — enemies, allies, projectiles can be freed mid-frame
func _on_target_timer_timeout() -> void:
    _move_toward(target_enemy.global_position)  # crash if freed

# RIGHT
func _on_target_timer_timeout() -> void:
    if not is_instance_valid(target_enemy):
        _clear_target()
        return
    _move_toward(target_enemy.global_position)
```

---

## AP-03: `assert()` in Production Code

```gdscript
# WRONG — crashes headless simulation builds
func spend_gold(amount: int) -> bool:
    assert(amount > 0, "spend_gold called with non-positive amount")

# RIGHT
func spend_gold(amount: int) -> bool:
    if amount <= 0:
        push_warning("spend_gold called with non-positive amount: %d" % amount)
        return false
```

---

## AP-04: Direct SignalBus Bypass — Cross-System Direct Calls

```gdscript
# WRONG — direct call between unrelated systems
func _on_enemy_killed(enemy: EnemyBase) -> void:
    EconomyManager.add_gold(enemy.gold_reward)  # direct call, bypasses signal

# RIGHT — use the signal the system already emits
func _ready() -> void:
    SignalBus.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(enemy_data: EnemyData, position: Vector3, gold_reward: int) -> void:
    EconomyManager.add_gold(gold_reward)
```

---

## AP-05: Caching Autoload Reference in a Variable

```gdscript
# WRONG
var _econ: EconomyManager = EconomyManager
_econ.add_gold(50)

# RIGHT
EconomyManager.add_gold(50)
```

---

## AP-06: Configuring a Scene After `add_child()`

```gdscript
# WRONG — properties set after add_child may fire _ready() with defaults
var enemy: EnemyBase = EnemyScene.instantiate()
enemy_container.add_child(enemy)
enemy.initialize(enemy_data)  # too late

# RIGHT
var enemy: EnemyBase = EnemyScene.instantiate()
enemy.initialize(enemy_data)  # before add_child
enemy_container.add_child(enemy)
```

---

## AP-07: `class_name` on SaveManager or RelationshipManager

```gdscript
# WRONG — causes GdUnit test shadowing of the autoload singleton
class_name SaveManager
extends Node

# RIGHT — no class_name on these two autoloads
extends Node
# SaveManager is accessed only by its autoload name
```

---

## AP-08: stdout Output in MCP Bridge Scripts (GDAI)

```gdscript
# WRONG — stdout is reserved for JSON-RPC in GDAI scripts
print("Debug: wave started")

# RIGHT — debug logs go to stderr only
push_warning("Debug: wave started")
# or
printerr("Debug: wave started")
```

---

## AP-09: Hardcoding Stats in `.gd` Files

```gdscript
# WRONG
if mana >= 50:
    mana -= 50

# RIGHT
if mana >= spell_data.mana_cost:
    mana -= spell_data.mana_cost
```

---

## AP-10: Untyped Function Signatures

```gdscript
# WRONG
func deal_damage(amount, type):
    return amount * get_multiplier(type)

# RIGHT
func deal_damage(amount: float, damage_type: Types.DamageType) -> float:
    return amount * get_multiplier(damage_type)
```

---

## AP-11: Godot 3 Syntax

```gdscript
# WRONG (Godot 3)
yield(get_tree().create_timer(1.0), "timeout")
connect("enemy_killed", self, "_on_enemy_killed")
export var speed = 5.0

# RIGHT (Godot 4)
await get_tree().create_timer(1.0).timeout
SignalBus.enemy_killed.connect(_on_enemy_killed)
@export var speed: float = 5.0
```

---

## AP-12: Signal Connect Without `is_connected` Guard (Where Reconnection is Possible)

```gdscript
# WRONG — duplicate connect if called more than once
SignalBus.wave_cleared.connect(_on_wave_cleared)

# RIGHT — guard against duplicate connections
if not SignalBus.wave_cleared.is_connected(_on_wave_cleared):
    SignalBus.wave_cleared.connect(_on_wave_cleared)
```

---

## AP-13: Logic Inside SignalBus

```gdscript
# WRONG — SignalBus must have ZERO logic, ZERO state, ZERO methods
extends Node

var total_gold_earned: int = 0  # NO — no state on SignalBus

signal enemy_killed(enemy_data: EnemyData, position: Vector3, gold_reward: int)

func on_enemy_killed(gold: int) -> void:  # NO — no methods on SignalBus
    total_gold_earned += gold

# RIGHT — SignalBus is declarations only
extends Node

signal enemy_killed(enemy_data: EnemyData, position: Vector3, gold_reward: int)
# That's it. No vars, no funcs.
```

---

## AP-14: Writing `get_save_data()` / `restore_from_save()` Without Wiring into SaveManager

```gdscript
# WRONG — implementing the interface but not connecting it
func get_save_data() -> Dictionary:
    return {enchantments: _slots}
# (never called because SaveManager._build_save_payload() doesn't reference this)

# RIGHT — after writing get_save_data() / restore_from_save(), immediately wire into:
# SaveManager._build_save_payload() — add: "enchantments": EnchantmentManager.get_save_data()
# SaveManager._apply_save_payload() — add: EnchantmentManager.restore_from_save(data.enchantments)
```

FILE 4: .cursor/skills/signal-bus/SKILL.md

text
---
name: signal-bus
description: >-
  Activate when working with signals in Foul Ward: emitting, connecting,
  declaring, or verifying signals. Use when: SignalBus, emit, connect,
  signal payload, cross-system communication, add new signal, signal reference,
  signal naming, signal table, is_connected guard, typed signal parameters.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Signal Bus — Foul Ward

---

## The Rule

SignalBus (`autoloads/signal_bus.gd`) is declarations only.
- NO logic
- NO state (no variables)
- NO methods

All cross-system signals declared here. Local signals (within one scene tree)
may live on the emitting node directly.

---

## How to Add a New Signal (6 steps)

1. Declare in `autoloads/signal_bus.gd` — past tense, typed payload
2. Emit at the correct point: `SignalBus.your_signal.emit(args)`
3. Connect with guard: `if not SignalBus.x.is_connected(fn): SignalBus.x.connect(fn)`
4. Add to signal table in `docs/INDEX_FULL.md`
5. Update `docs/PROMPT_[N]_IMPLEMENTATION.md`
6. Write a test using `monitor_signals` + `assert_signal`

---

## Signal Naming Convention

- Events (something happened): **past tense** — `enemy_killed`, `wave_cleared`, `building_placed`
- Requests (something is being asked): **present tense** — `build_requested`, `sell_requested`
- NEVER future tense
- Always fully typed payload

---

## The `is_connected` Guard Pattern

Always use when a connect might be called more than once:

```gdscript
if not SignalBus.wave_cleared.is_connected(_on_wave_cleared):
    SignalBus.wave_cleared.connect(_on_wave_cleared)
```

---

## Emit Pattern

```gdscript
# Correct typed emit
SignalBus.enemy_killed.emit(enemy_data, global_position, enemy_data.gold_reward)

# Never emit with wrong types or missing args
```

---

## Signal Testing Pattern

```gdscript
func test_gold_awarded_on_enemy_killed() -> void:
    var monitor := monitor_signals(SignalBus)
    EconomyManager.reset_to_defaults()
    SignalBus.enemy_killed.emit(mock_enemy_data, Vector3.ZERO, 25)
    await assert_signal(monitor).is_emitted("resource_changed")
```

---

## When to Read the Signal Table

Read `references/signal-table.md` when:
- Checking whether a signal already exists before declaring a new one
- Verifying the exact parameter types of a signal you're connecting to
- Looking up which category a signal belongs to
- Auditing signal coverage for a system

---

> ⚠️ VERIFY: Check `autoloads/signal_bus.gd` to confirm the full signal list matches `references/signal-table.md`. The master doc lists 58+ signals; earlier versions had fewer.

FILE 5: .cursor/skills/signal-bus/references/signal-table.md

text
# Signal Table — Foul Ward SignalBus

All signals declared in `autoloads/signal_bus.gd`. Organized by category.
Source: FOUL_WARD_MASTER_DOC.md §24.

> ⚠️ VERIFY: Confirm this table against the actual `signal_bus.gd` file.
> Earlier CONVENTIONS.md had a smaller signal set. Master doc is authoritative.

---

## Combat

| Signal | Parameters |
|---|---|
| `enemy_killed` | `enemy_data: EnemyData, position: Vector3, gold_reward: int` |
| `tower_damaged` | `current_hp: int, max_hp: int` |
| `tower_destroyed` | *(no params)* |
| `projectile_fired` | `weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3` |
| `building_destroyed` | `slot_index: int` *(POST-MVP stub)* |
| `florence_damaged` | `current_hp: int, max_hp: int` |

## Allies

| Signal | Parameters |
|---|---|
| `arnulf_state_changed` | `new_state: Types.ArnulfState` |
| `arnulf_incapacitated` | *(no params)* |
| `arnulf_recovered` | *(no params)* |
| `ally_roster_changed` | *(no params)* |

## Bosses

| Signal | Parameters |
|---|---|
| `boss_spawned` | `boss_id: String` |
| `boss_defeated` | `boss_id: String` |
| `mini_boss_defeated` | `boss_id: String` |

## Waves

| Signal | Parameters |
|---|---|
| `wave_countdown_started` | `wave_number: int, seconds_remaining: float` |
| `wave_started` | `wave_number: int, enemy_count: int` |
| `wave_cleared` | `wave_number: int` |
| `all_waves_cleared` | *(no params)* |

## Economy

| Signal | Parameters |
|---|---|
| `resource_changed` | `resource_type: Types.ResourceType, new_amount: int` |

## Territories

| Signal | Parameters |
|---|---|
| `territory_captured` | `territory_id: String` |
| `territory_lost` | `territory_id: String` |

## Terrain

| Signal | Parameters |
|---|---|
| `nav_mesh_rebake_requested` | *(no params)* |

## Buildings

| Signal | Parameters |
|---|---|
| `building_placed` | `slot_index: int, building_type: Types.BuildingType` |
| `building_sold` | `slot_index: int, building_type: Types.BuildingType` |
| `building_upgraded` | `slot_index: int, building_type: Types.BuildingType` |

## Spells

| Signal | Parameters |
|---|---|
| `spell_cast` | `spell_id: String` |
| `spell_ready` | `spell_id: String` |
| `mana_changed` | `current_mana: int, max_mana: int` |

## Game State

| Signal | Parameters |
|---|---|
| `game_state_changed` | `old_state: Types.GameState, new_state: Types.GameState` |
| `mission_started` | `mission_number: int` |
| `mission_won` | `mission_number: int` |
| `mission_failed` | `mission_number: int` |

## Campaign

| Signal | Parameters |
|---|---|
| `campaign_started` | *(no params)* |
| `day_advanced` | `new_day: int` |

## Build Mode

| Signal | Parameters |
|---|---|
| `build_mode_entered` | *(no params)* |
| `build_mode_exited` | *(no params)* |

## Research

| Signal | Parameters |
|---|---|
| `research_unlocked` | `node_id: String` |

## Shop

| Signal | Parameters |
|---|---|
| `shop_item_purchased` | `item_id: String` |

## Weapons / Enchantments

| Signal | Parameters |
|---|---|
| `weapon_upgraded` | `weapon_slot: Types.WeaponSlot, new_level: int` |
| `enchantment_applied` | `weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String` |
| `enchantment_removed` | `weapon_slot: Types.WeaponSlot, slot_type: String` |

## Mercenaries

| Signal | Parameters |
|---|---|
| `mercenary_hired` | `ally_id: String` |

> ⚠️ VERIFY: This table is sourced from FOUL_WARD_MASTER_DOC.md §24 which states 58+ signals.
> Cross-reference against `autoloads/signal_bus.gd` and ensure all signals are listed here.
> Categories may have additional signals not captured above.

FILE 6: .cursor/skills/enemy-system/SKILL.md

text
---
name: enemy-system
description: >-
  Activate when working with enemies in Foul Ward: EnemyBase, EnemyData,
  spawning, damage calculation, pathfinding, bosses, factions, armor types,
  damage types, damage matrix. Use when: enemy, EnemyBase, EnemyData, spawn,
  pathfinding, damage calculator, armor, DamageType, ArmorType, boss, faction,
  mini-boss, flying enemy, ground enemy, undead, wave composition, EnemyType.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Enemy System — Foul Ward

---

## Key Classes

| Class | File | Role |
|---|---|---|
| `EnemyBase` | `scenes/enemies/enemy_base.gd` | Base enemy scene script |
| `EnemyData` | `resources/enemy_data/*.tres` | Resource: all enemy stats |
| `DamageCalculator` | `autoloads/damage_calculator.gd` | Autoload #3: stateless damage matrix |

---

## DamageCalculator API

```gdscript
# Autoload #3 — stateless, pure function
DamageCalculator.calculate_damage(
    base_damage: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float

DamageCalculator.calculate_dot_tick(
    dot_total_damage: float,
    tick_interval: float,
    duration: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float
```

---

## Damage Matrix (4×5)

PHYSICAL FIRE MAGICAL POISON TRUE
UNARMORED 1.0 1.0 1.0 1.0 1.0
HEAVY_ARMOR 0.5 1.0 2.0 1.0 1.0
UNDEAD 1.0 2.0 1.0 0.0 1.0
FLYING 1.0 1.0 1.0 1.0 1.0

text

TRUE damage type bypasses the matrix entirely — always 1.0 multiplier.

---

## EnemyData Fields

```gdscript
@export var enemy_type: Types.EnemyType
@export var display_name: String
@export var max_hp: int              # NOT hp, NOT health
@export var move_speed: float
@export var damage: int
@export var armor_type: Types.ArmorType
@export var gold_reward: int
@export var is_flying: bool
@export var body_type: Types.EnemyBodyType
```

---

## Navigation

- **Ground enemies**: `NavigationAgent3D` + NavMesh baked by `NavMeshManager`
- **Flying enemies**: Simple steering, Y offset (e.g. Y = 5.0), ignore NavMesh
- **Hover enemies**: Body type HOVER — ground movement, elevated collision
- Always check `is_instance_valid(target)` before accessing enemy reference

---

## Faction Structure

3 factions defined in `.tres` resources:

| Faction ID | Composition |
|---|---|
| `DEFAULT_MIXED` | Fallback — used when `DayConfig.faction_id` is empty |
| `ORC_RAIDERS` | Orc-heavy physical damage enemies |
| `PLAGUE_CULT` | Undead + poison enemies |

> ⚠️ VERIFY: 50-day DayConfigs all have empty `faction_id` — WaveManager falls back to DEFAULT_MIXED. Confirm in `autoloads/campaign_manager.gd`.

---

## Boss Structure

4 boss types with `boss_id` string keys:

| boss_id | Notes |
|---|---|
| `plague_lord` | Final boss |
| `orc_warlord` | Mid-campaign boss |
| `brood_mother` | Mini-boss |
| `iron_golem` | Mini-boss |

> ⚠️ VERIFY: Confirm exact boss_id strings against `resources/boss_data/*.tres`.

---

## Enemy-Reaching-Tower Flow (§27.3)

1. Enemy `HealthComponent` reaches 0 OR enemy reaches tower origin
2. If tower reached: `SignalBus.tower_damaged.emit(current_hp, max_hp)`
3. If hp = 0: `SignalBus.enemy_killed.emit(enemy_data, position, gold_reward)`
4. `EnemyBase.queue_free()` — always deferred
5. `is_instance_valid()` guard required on any reference held by other systems

---

## Critical Rules

- Always `is_instance_valid()` before accessing any enemy reference
- Never access `enemy.global_position` without an `is_instance_valid()` guard
- EnemyData files: `max_hp` (not `hp`, not `health`)
- Brood Carrier on-death spawns via `WaveManager.spawn_enemy_at_position()`
- Enemy groups: all active instances in group `"enemies"`

---

## Full Type Tables

Read `references/enemy-types.md` when:
- Looking up the integer value of an EnemyType enum
- Checking which tier an enemy belongs to
- Verifying ArmorType or EnemyBodyType values

FILE 7: .cursor/skills/enemy-system/references/enemy-types.md

text
# Enemy Type Reference — Foul Ward

Source: FOUL_WARD_MASTER_DOC.md §5

---

## EnemyType (30 values)

| Name | Value | Tier |
|---|---|---|
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

> ⚠️ VERIFY: CONVENTIONS.md (MVP era) listed only 6 enemy types. The master doc lists 30. Confirm `types.gd` matches this table.

---

## ArmorType (4 values)

| Name | Value |
|---|---|
| UNARMORED | 0 |
| HEAVY_ARMOR | 1 |
| UNDEAD | 2 |
| FLYING | 3 |

---

## EnemyBodyType (8 values)

| Name | Value |
|---|---|
| GROUND | 0 |
| FLYING | 1 |
| HOVER | 2 |
| BOSS | 3 |
| STRUCTURE | 4 |
| LARGE_GROUND | 5 |
| SIEGE | 6 |
| ETHEREAL | 7 |

---

## DamageType (5 values)

| Name | Value |
|---|---|
| PHYSICAL | 0 |
| FIRE | 1 |
| MAGICAL | 2 |
| POISON | 3 |
| TRUE | 4 |

> ⚠️ VERIFY: CONVENTIONS.md listed only 4 DamageTypes (no TRUE). Master doc adds TRUE (value 4). Confirm `types.gd`.

FILE 8: .cursor/skills/building-system/SKILL.md

text
---
name: building-system
description: >-
  Activate when working with buildings in Foul Ward: placement, selling,
  HexGrid, BuildingBase, BuildingData, aura buildings, summoner buildings,
  build phase, ring rotation. Use when: building, BuildingBase, BuildingData,
  HexGrid, hex grid, placement, sell, upgrade, ring, slot, build mode,
  build phase, aura, summoner, turret, BuildingType, BuildingSizeClass,
  BuildPhaseManager, AuraManager, AllyManager.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Building System — Foul Ward

---

## Key Classes

| Class | File/Path | Role |
|---|---|---|
| `HexGrid` | `scenes/hex_grid/hex_grid.gd` | 24-slot grid management |
| `BuildingBase` | `scenes/buildings/building_base.gd` | Building logic base |
| `BuildingData` | `resources/building_data/*.tres` | Resource: all building stats |
| `BuildPhaseManager` | Autoload #10 | Headless-safe build-phase guard |
| `AuraManager` | Autoload #4 | Registers aura towers, queries bonuses |
| `AllyManager` | Autoload #11 | Summoner building squads |

---

## Field Name Discipline (BuildingData)

| ❌ Wrong | ✅ Correct |
|---|---|
| `build_gold_cost` | `gold_cost` |
| `targeting_priority` | `target_priority` |
| `build_material_cost` | `material_cost` |

---

## Building Placement Flow (§27.2)

1. Player clicks hex slot → `BuildPhaseManager.assert_build_phase("placement")` must return `true`
2. `EconomyManager.can_afford_building(building_data)` — abort if false
3. `EconomyManager.register_purchase(building_data)` — charges scaled cost, increments dup count
4. `BuildingBase.initialize(building_data, slot_index)` called BEFORE `add_child()`
5. `HexGrid` places building node; emits `SignalBus.building_placed(slot_index, building_type)`

### Sell Flow
1. `EconomyManager.get_refund(building_data, paid_gold, paid_material)` → refund dict
2. `EconomyManager.add_gold(refund.gold)` + `add_building_material(refund.material)`
3. `HexGrid` frees building node; emits `SignalBus.building_sold(slot_index, building_type)`

---

## How to Add a New Building (9 steps)

1. Add `BUILDING_NAME` to `Types.BuildingType` enum in `scripts/types.gd`
2. Create `resources/building_data/building_name.tres` with all required fields
3. Set `building_id` = `"building_name"` (matches file name, no .tres extension)
4. Set `gold_cost`, `material_cost`, `damage`, `damage_type`, `target_priority`, `building_size_class`
5. If aura building: set `is_aura = true`, `aura_effect_type`, `aura_modifier_value`
6. If summoner building: set `is_summoner = true`, `squad_ally_ids`
7. If research-locked: set `is_locked = true`, `unlock_research_id`
8. Add to `BuildMenu` scene — register the .tres in the build menu catalog
9. Write test: at minimum `test_building_name_can_be_placed_and_sold()`

---

## Ring Structure

- 24 slots across 3 rings
- Ring 1 (inner): slots 0–5
- Ring 2 (middle): slots 6–13
- Ring 3 (outer): slots 14–23
- `ring_rotation` exists on HexGrid
- Pre-battle ring rotation UI: **PLANNED, not yet implemented**

---

## BuildPhaseManager

```gdscript
# Autoload #10 — headless-safe
BuildPhaseManager.assert_build_phase("context_string") -> bool
# Returns true if in build phase. Default: true (headless tests).

BuildPhaseManager.set_build_phase_active(active: bool) -> void
# Emits local signals: build_phase_started() or combat_phase_started()
```

Always call `assert_build_phase()` before any placement operation.

---

## Aura Buildings

```gdscript
# Registration
AuraManager.register_aura(building: BuildingBase) -> void
AuraManager.deregister_aura(building_instance_id: String) -> void

# Query
AuraManager.get_damage_pct_bonus(building: BuildingBase) -> float
AuraManager.get_enemy_speed_modifier(world_pos: Vector3) -> float
```

Aura effect types: `damage_pct`, `enemy_speed_pct`.

---

## Summoner Buildings

```gdscript
# Spawn/despawn squads keyed by placed_instance_id
AllyManager.spawn_squad(building: BuildingBase) -> void
AllyManager.despawn_squad(building_instance_id: String) -> void
```

---

## Full Type Tables

Read `references/building-types.md` when:
- Looking up the integer value of a BuildingType enum
- Checking the size class of a building
- Verifying all 36 building IDs

---

> ⚠️ VERIFY: CONVENTIONS.md (MVP era) listed only 8 building types. The master doc has 36. Confirm `types.gd` and `resources/building_data/` match the full list in `references/building-types.md`.

FILE 9: .cursor/skills/building-system/references/building-types.md

text
# Building Types Reference — Foul Ward

Source: FOUL_WARD_MASTER_DOC.md §5 BuildingType

> ⚠️ VERIFY: This list should match `scripts/types.gd` enum BuildingType exactly.

---

## BuildingType (36 values)

| Name | Value | Size | Role |
|---|---|---|---|
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

---

## BuildingSizeClass (6 values)

| Name | Value |
|---|---|
| SINGLE_SLOT | 0 |
| DOUBLE_WIDE | 1 |
| TRIPLE_CLUSTER | 2 |
| SMALL | 3 |
| MEDIUM | 4 |
| LARGE | 5 |

FILE 10: .cursor/skills/economy-system/SKILL.md

text
---
name: economy-system
description: >-
  Activate when working with resources, costs, or purchases in Foul Ward.
  Use when: gold, building material, research material, EconomyManager,
  afford, spend, refund, duplicate cost scaling, currency, purchase,
  resource_changed, wave reward, mission economy, sell refund fraction.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Economy System — Foul Ward

---

## Autoload: EconomyManager (Init #5)

File: `autoloads/economy_manager.gd`

ALL resource modifications go through EconomyManager's public methods.
Never access `gold`, `building_material`, or `research_material` directly.

---

## Constants

```gdscript
DEFAULT_GOLD = 1000
DEFAULT_BUILDING_MATERIAL = 50
DEFAULT_RESEARCH_MATERIAL = 0
DEFAULT_SELL_REFUND_FRACTION = 0.6
DEFAULT_DUPLICATE_COST_K = 0.08
```

> ⚠️ VERIFY: CONVENTIONS.md (MVP era) listed starting gold as 100 and building_material as 10.
> Master doc lists DEFAULT_GOLD = 1000, DEFAULT_BUILDING_MATERIAL = 50.
> Confirm against actual `economy_manager.gd` constants.

---

## Duplicate Cost Scaling

Linear per `building_id`:
- Formula: `cost_multiplier = 1.0 + k * n`
- `k` = `DEFAULT_DUPLICATE_COST_K` (0.08)
- `n` = number of times that building_id has been purchased this mission

---

## Sell Refund

refund = sell_refund_fraction × sell_refund_global_multiplier × paid_cost

text
Default fraction: 0.6 (60% refund).

---

## Full API

```gdscript
# Resource modifications
EconomyManager.add_gold(amount: int) -> void
EconomyManager.spend_gold(amount: int) -> bool        # false if insufficient
EconomyManager.add_building_material(amount: int) -> void
EconomyManager.spend_building_material(amount: int) -> bool
EconomyManager.add_research_material(amount: int) -> void
EconomyManager.spend_research_material(amount: int) -> bool

# Affordability
EconomyManager.can_afford(gold_cost: int, material_cost: int) -> bool
EconomyManager.can_afford_building(building_data: BuildingData) -> bool

# Queries
EconomyManager.get_gold() -> int
EconomyManager.get_building_material() -> int
EconomyManager.get_research_material() -> int
EconomyManager.get_gold_cost(building_data: BuildingData) -> int
EconomyManager.get_material_cost(building_data: BuildingData) -> int
EconomyManager.get_cost_multiplier(building_data: BuildingData) -> float
EconomyManager.get_duplicate_count(building_id: String) -> int

# Transactions
EconomyManager.register_purchase(building_data: BuildingData) -> Dictionary
# Returns: {paid_gold, paid_material, duplicate_count_after} or {} on failure

EconomyManager.get_refund(building_data: BuildingData, paid_gold: int, paid_material: int) -> Dictionary
# Returns: {gold, material}

# Wave rewards
EconomyManager.grant_wave_clear_reward(wave: int, econ: MissionEconomyData) -> Vector2i
EconomyManager.get_wave_reward_gold(wave: int, econ: MissionEconomyData) -> int
EconomyManager.get_wave_reward_material(wave: int, econ: MissionEconomyData) -> int

# Mission / lifecycle
EconomyManager.reset_for_mission() -> void          # clears dup counts
EconomyManager.apply_mission_economy(econ: MissionEconomyData) -> void
EconomyManager.reset_to_defaults() -> void          # full reset for new game
EconomyManager.apply_save_snapshot(g: int, building_mat: int, research_mat: int) -> void
```

---

## Signal

```gdscript
SignalBus.resource_changed(resource_type: Types.ResourceType, new_amount: int)
# Emitted on EVERY modification — gold, building_material, or research_material
```

---

## Usage Patterns

```gdscript
# Check before purchase
if EconomyManager.can_afford_building(building_data):
    var result := EconomyManager.register_purchase(building_data)
    if result.is_empty():
        push_warning("Purchase failed")
        return
    # proceed with placement

# Manual refund on sell
var refund := EconomyManager.get_refund(building_data, paid_gold, paid_material)
EconomyManager.add_gold(refund.gold)
EconomyManager.add_building_material(refund.material)
```

FILE 11: .cursor/skills/campaign-and-progression/SKILL.md

text
---
name: campaign-and-progression
description: >-
  Activate when working with the campaign, mission flow, days, territories,
  world map, or game state transitions in Foul Ward. Use when: campaign,
  day, mission, progression, territory, world map, endless mode, CampaignManager,
  GameManager, game state, state transition, day config, next day, ally roster,
  mercenary offers, DayConfig, WAVES_PER_MISSION, TOTAL_MISSIONS.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Campaign and Progression — Foul Ward

---

## Campaign Structure

- **50-day main campaign** (`50_day_campaign.tres`)
- **5-day short campaign** (`5_day_campaign.tres`)
- **Endless mode**: synthetic scaling, no day limit
- `WAVES_PER_MISSION = 5` (5 waves per mission)
- `TOTAL_MISSIONS = 5`

> ⚠️ VERIFY: CONVENTIONS.md (MVP era) had `WAVES_PER_MISSION = 10`. Master doc has 5. Confirm `game_manager.gd` constant.

---

## Init Order Critical

CampaignManager (Init #6) MUST load before GameManager (Init #9).
`mission_won` signal listeners run in autoload registration order.
CampaignManager's day increment must fire before GameManager's hub transition.

---

## CampaignManager API (Init #6)

```gdscript
CampaignManager.start_new_campaign() -> void
CampaignManager.start_endless_run() -> void
CampaignManager.start_next_day() -> void
CampaignManager.get_current_day() -> int              # 1-based
CampaignManager.get_campaign_length() -> int
CampaignManager.get_current_day_config() -> DayConfig
CampaignManager.validate_day_configs(day_configs: Array[DayConfig]) -> void

# Ally roster
CampaignManager.is_ally_owned(ally_id: String) -> bool
CampaignManager.get_owned_allies() -> Array[String]
CampaignManager.get_active_allies() -> Array[String]
CampaignManager.get_ally_data(ally_id: String) -> Resource
CampaignManager.add_ally_to_roster(ally_id: String) -> void
CampaignManager.remove_ally_from_roster(ally_id: String) -> void
CampaignManager.toggle_ally_active(ally_id: String) -> bool
CampaignManager.set_active_allies_from_list(ally_ids: Array[String]) -> void
CampaignManager.get_allies_for_mission_start() -> Array[String]

# Mercenaries
CampaignManager.generate_offers_for_day(day: int) -> void
CampaignManager.preview_mercenary_offers_for_day(day: int, hypothetical_owned: Array[String]) -> Array
CampaignManager.get_current_offers() -> Array
CampaignManager.purchase_mercenary_offer(index: int) -> bool
CampaignManager.notify_mini_boss_defeated(boss_id: String) -> void
CampaignManager.auto_select_best_allies(strategy, offers, roster, max_purchases, budget_gold, budget_material, budget_research) -> Dictionary

# Save/load
CampaignManager.get_save_data() -> Dictionary
CampaignManager.restore_from_save(data: Dictionary) -> void
```

**Key state:** `max_active_allies_per_day = 2`

---

## Game State Transition Graph

MAIN_MENU
→ MISSION_BRIEFING
→ COMBAT ↔ BUILD_MODE
→ WAVE_COUNTDOWN
→ (COMBAT loop)
→ MISSION_WON → BETWEEN_MISSIONS → MISSION_BRIEFING...
→ MISSION_FAILED → BETWEEN_MISSIONS → MISSION_BRIEFING...
→ GAME_WON (after day 50)
→ GAME_OVER
→ ENDLESS

text

**PLANNED states** (not in code): `RING_ROTATE`, `PASSIVE_SELECT`

---

## Territory System

5 territories with passive bonuses. Read `references/game-manager-api.md` for
GameManager territory methods.

Key: `get_current_day_territory() -> TerritoryData`

---

## GameManager Key Methods (Init #9)

```gdscript
GameManager.start_new_game() -> void           # Full reset; calls CampaignManager
GameManager.start_next_mission() -> void
GameManager.start_wave_countdown() -> void     # MISSION_BRIEFING → COMBAT
GameManager.enter_build_mode() -> void         # COMBAT → BUILD_MODE (time_scale 0.1)
GameManager.exit_build_mode() -> void          # BUILD_MODE → COMBAT (time_scale 1.0)
GameManager.get_game_state() -> Types.GameState
GameManager.get_current_mission() -> int       # 1-indexed
GameManager.get_current_wave() -> int
GameManager.get_current_day_index() -> int
```

For full GameManager API (30+ methods), read `references/game-manager-api.md`.

---

> ⚠️ VERIFY: Confirm `WAVES_PER_MISSION` and `TOTAL_MISSIONS` constants in `game_manager.gd` match master doc values (5 and 5).

FILE 12: .cursor/skills/campaign-and-progression/references/game-manager-api.md

text
# GameManager Full API — Foul Ward

Source: FOUL_WARD_MASTER_DOC.md §3.9
File: `autoloads/game_manager.gd` — Autoload Init #9

---

## Full Method Table

| Signature | Returns | Usage |
|---|---|---|
| `start_new_game() -> void` | void | Full reset; calls CampaignManager.start_new_campaign() |
| `start_next_mission() -> void` | void | Delegates to CampaignManager.start_next_day() |
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

## Constants

```gdscript
TOTAL_MISSIONS = 5
WAVES_PER_MISSION = 5
```

> ⚠️ VERIFY: Confirm these constant values in `autoloads/game_manager.gd`.

FILE 13: .cursor/skills/testing/SKILL.md

text
---
name: testing
description: >-
  Activate when writing, running, or debugging tests for Foul Ward. Covers
  GdUnit4 conventions, test file naming, test isolation, signal testing,
  SimBot, headless simulation, AutoTestDriver, CombatStatsTracker, test run
  commands. Use when: test, GdUnit4, unit test, integration test, SimBot,
  headless, assert, test file, run tests, balance sweep, test isolation,
  test naming, after_test, reset_to_defaults.
compatibility: Godot 4.4 GDScript, GdUnit4. Foul Ward project only.
---

# Testing — Foul Ward

Current passing tests: **525** (as of Prompt 51).

---

## Test Run Commands

```bash
./tools/run_gdunit_quick.sh        # After every change — fast subset
./tools/run_gdunit_unit.sh         # Unit tests only, 33 files, ~65s
./tools/run_gdunit_parallel.sh     # All 58 files, 8 parallel, ~2m45s
./tools/run_gdunit.sh              # Sequential baseline — run before declaring done
```

**Exit codes:**
- `101` = warnings only (orphan nodes) — treat as PASS when failure count is 0
- `100` with "0 failures" = `push_warning()` calls counted — treat as PASS

---

## File and Class Naming

test_<module_name>.gd # e.g. test_economy_manager.gd
class_name Test<ModuleName> # e.g. class_name TestEconomyManager
extends GdUnitTestSuite

text

All test files go in `res://tests/unit/`.

---

## Function Naming

test_<method><condition><expected>

text

Examples:
```gdscript
func test_add_gold_positive_amount_increases_total() -> void:
func test_spend_gold_insufficient_funds_returns_false() -> void:
func test_arnulf_downed_state_recovers_after_three_seconds() -> void:
```

---

## Arrange-Act-Assert Structure

```gdscript
func test_spend_gold_sufficient_funds_returns_true() -> void:
    # Arrange
    EconomyManager.reset_to_defaults()
    EconomyManager.add_gold(200)

    # Act
    var result: bool = EconomyManager.spend_gold(150)

    # Assert
    assert_bool(result).is_true()
    assert_int(EconomyManager.get_gold()).is_equal(850)  # 1000 default + 200 - 150
```

---

## Test Isolation

- Call `reset_to_defaults()` at the start of every test (or in `before_test()`)
- Tests MUST NOT depend on execution order
- Never emit SignalBus signals from tests using the real autoload without resetting in `after_test()`
- No UI nodes, no editor APIs, no `@tool` in test files

---

## Signal Testing

```gdscript
func test_add_gold_emits_resource_changed() -> void:
    EconomyManager.reset_to_defaults()
    var monitor := monitor_signals(SignalBus)
    EconomyManager.add_gold(50)
    await assert_signal(monitor).is_emitted("resource_changed")
```

---

## Integration Tests (await / timers)

Tests using `await` or timers are Integration tests.
Keep them OUT of `run_gdunit_unit.sh`.
Add lightweight tests to the allowlist in `run_gdunit_quick.sh`.

---

## SimBot / AutoTestDriver

Activated by CLI args:
- `--autotest` → headless smoke test
- `--simbot_profile=<name>` → run strategy profile
- `--simbot_balance_sweep` → run all profiles

Strategy profiles: `balanced`, `summoner_heavy`, `artillery_air`

`CombatStatsTracker` outputs:
- `user://simbot/runs/wave_summary.csv`
- `user://simbot/runs/building_summary.csv`
- `user://simbot/runs/event_log.csv` (when verbose enabled)

SimBot `compute_difficulty_fit()` early exit is effectively unreachable during
interactive runs (requires prior batch log data). Mission completion ends runs
via `all_waves_cleared`.

---

## Headless Safety Rules

All tests must be headless-safe:
- No UI node references in autoloads or SimBot scripts
- `get_node_or_null()` with null guard for scene nodes (WaveManager etc.)
- `BuildPhaseManager` defaults `is_build_phase = true` in headless contexts
- WaveManager absent → GameManager silently skips wave spawning (by design)

FILE 14: .cursor/skills/add-new-entity/SKILL.md

text
---
name: add-new-entity
description: >-
  Activate when adding any new entity type to Foul Ward: new building, new
  enemy type, new spell, new research node, or new signal. Contains complete
  step-by-step templates for all four entity types. Use when: add new, create
  new, new building, new spell, new research, new signal, template, scaffold,
  how to add, new entity.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Add New Entity Templates — Foul Ward

---

## How to Add a New Building (9 steps)

1. Add `BUILDING_NAME` to `Types.BuildingType` enum in `scripts/types.gd` (append — do not change existing values)
2. Create `resources/building_data/building_name.tres` (`class_name BuildingData`)
3. Set `building_id = "building_name"` (matches .tres filename without extension)
4. Populate required

FILE 14 (continued): .cursor/skills/add-new-entity/SKILL.md

text
---
name: add-new-entity
description: >-
  Activate when adding any new entity type to Foul Ward: new building, new
  enemy type, new spell, new research node, or new signal. Contains complete
  step-by-step templates for all four entity types. Use when: add new, create
  new, new building, new spell, new research, new signal, template, scaffold,
  how to add, new entity.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Add New Entity Templates — Foul Ward

---

## How to Add a New Building (9 steps)

1. Add `BUILDING_NAME` to `Types.BuildingType` enum in `scripts/types.gd` — **append only**, never change existing values
2. Create `resources/building_data/building_name.tres` (`class_name BuildingData`)
3. Set `building_id = "building_name"` (matches .tres filename without extension — no spaces)
4. Populate required fields: `gold_cost`, `material_cost`, `damage`, `damage_type`, `target_priority`, `building_size_class`
5. If aura: set `is_aura = true`, `aura_effect_type` (`damage_pct` or `enemy_speed_pct`), `aura_modifier_value`
6. If summoner: set `is_summoner = true`, `squad_ally_ids: Array[String]`
7. If research-locked: set `is_locked = true`, `unlock_research_id = "node_id_string"`
8. Register .tres in the `BuildMenu` scene's building catalog
9. Write at minimum: `test_building_name_can_be_placed_and_sold()`

**Document update checklist:**
- Move from PLANNED → EXISTS in `docs/FOUL_WARD_MASTER_DOC.md` §8
- Add to enum table in §5
- Add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- Update `.cursor/skills/building-system/references/building-types.md`

---

## How to Add a New Signal (6 steps)

1. Declare in `autoloads/signal_bus.gd` — past tense, fully typed payload:
```gdscript
signal your_event_happened(param_one: Type, param_two: Type)
```
2. Emit at the correct point in the emitting script:
```gdscript
SignalBus.your_event_happened.emit(param_one, param_two)
```
3. Connect with `is_connected` guard in any listener:
```gdscript
if not SignalBus.your_event_happened.is_connected(_on_your_event_happened):
    SignalBus.your_event_happened.connect(_on_your_event_happened)
```
4. Add to `.cursor/skills/signal-bus/references/signal-table.md` under the correct category
5. Add to `docs/INDEX_FULL.md` signal section
6. Write a test using `monitor_signals` + `assert_signal`

**Never declare a cross-system signal anywhere other than `signal_bus.gd`.**

---

## How to Add a New Spell (5 steps)

1. Create `resources/spell_data/spell_name.tres` (`class_name SpellData`)
2. Set required fields:
```gdscript
spell_id: String = "spell_name"       # snake_case, unique
display_name: String = "Display Name"
mana_cost: int = 50
cooldown: float = 60.0
damage: float = 0.0                   # 0.0 is valid for control spells
damage_type: Types.DamageType
hits_flying: bool = false
radius: float = 10.0
```
3. Register the .tres in `main.tscn` → SpellManager's `spell_registry` array (wired in the scene, not in code)
4. Wire hotkey if needed: hotkeys 1–4 map to spell slots 0–3 (set in InputManager)
5. Write test: `test_spell_name_casts_when_mana_sufficient()`

**NEVER implement Time Stop spell — formally cut.**
`slow_field.tres` has `damage = 0.0` intentionally — do not "fix" it.

**Document update checklist:**
- Move from PLANNED → EXISTS in `docs/FOUL_WARD_MASTER_DOC.md` §7
- Add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`

---

## How to Add a New Research Node (6 steps)

1. Create `resources/research_data/node_id.tres` (`class_name ResearchNodeData`)
2. Set required fields:
```gdscript
node_id: String = "node_id"              # snake_case, unique — field is "node_id" NOT "id"
display_name: String = "Display Name"
research_cost: int = 2                   # field is "research_cost" NOT "rp_cost"
prerequisite_ids: Array[String] = []     # empty = no prerequisites
description: String = ""
```
3. If this node unlocks a building: also set `is_locked = true` and `unlock_research_id = "node_id"` on that `BuildingData`
4. Register .tres in `ResearchManager`'s node catalog (loaded from `res://resources/research_data/`)
5. Add to research tree UI if a panel exists
6. Write test: `test_node_id_unlocks_when_prereqs_met()`

**Document update checklist:**
- Move from PLANNED → EXISTS in `docs/FOUL_WARD_MASTER_DOC.md` §9
- Add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`

---

## Universal Document Update Checklist

After adding ANY new entity:
- [ ] Move from PLANNED → EXISTS in the relevant master doc section
- [ ] Add field names to §32 (Field Name Discipline) if any new fields introduced
- [ ] Add new signals to §24 (Signal Bus Reference)
- [ ] Update changelog at top of `docs/FOUL_WARD_MASTER_DOC.md`
- [ ] Update `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- [ ] Log in `docs/PROMPT_[N]_IMPLEMENTATION.md`

FILE 15: .cursor/skills/mcp-workflow/SKILL.md

text
---
name: mcp-workflow
description: >-
  Activate at the start of any Cursor session working on Foul Ward, or when
  working with MCP tools, Godot editor integration, scene tree validation,
  or error checking. Use when: MCP, Godot MCP, GDAI, cursor agent, editor
  integration, get_scene_tree, get_godot_errors, MCP server, port, WebSocket,
  toolchain, RAG, foulward-rag, sequential-thinking, no tools recovery.
compatibility: Godot 4.4, Cursor Pro, MCP servers listed below.
---

# MCP Workflow — Foul Ward

---

## MCP Servers

| Server name (in `.cursor/mcp.json`) | Role | Port / Notes |
|---|---|---|
| `godot-mcp-pro` | Editor integration via WebSocket | Port **6505**; needs Godot open with Godot MCP Pro plugin enabled |
| `gdai-mcp-godot` | Python bridge to editor HTTP API | Port **3571**; needs Godot open with GDAI MCP plugin enabled |
| `sequential-thinking` | Step-by-step reasoning | Needs `node` + `npm install` under `tools/mcp-support` |
| `filesystem-workspace` | Broader workspace filesystem access | — |
| `github` | GitHub API | Requires `GITHUB_PERSONAL_ACCESS_TOKEN` — never commit |
| `foulward-rag` | Project RAG (`query_project_knowledge`, etc.) | **Optional** — requires RAG service running from `~/LLM`; agents must NOT block if down |

---

## Mandatory Calls Every Session

    get_scene_tree — validate node paths BEFORE writing any get_node() call

    get_godot_errors — check for new errors AFTER making changes

text

Never write a `get_node()` call without first confirming the path exists in `get_scene_tree` output.

---

## RAG Server Rules

- `foulward-rag` is NOT always available — it requires the service under `~/LLM` to be running
- If available: call `query_project_knowledge` before writing new code for an existing system
- If available: call `get_recent_simbot_summary` when task touches balance, economy, or wave scaling
- If unavailable: note it in the implementation log and continue — never block on it

---

## GDAI stdout/stderr Rule

In any MCP bridge script (GDAI plugin code):
- **stdout**: JSON-RPC messages ONLY
- **stderr**: all debug logs
- `print()` to stdout will corrupt the JSON-RPC protocol

```gdscript
# WRONG in GDAI scripts
print("Debug: scene loaded")

# RIGHT
printerr("Debug: scene loaded")
```

---

## "No Tools" Recovery Procedure

If MCP tools fail to respond during a session:

1. Note the failure in `docs/PROMPT_[N]_IMPLEMENTATION.md`
2. Fall back to reading scene files directly via `filesystem-workspace`
3. Use known contracted node paths from `docs/AGENTS.md` §Architecture
4. Do NOT assume node paths — use only contracted paths or read the .tscn file
5. Continue the session; do not block

Full detail: `docs/AGENTS.md` and `.cursor/rules/mcp-godot-workflow.mdc`

---

## Session Start Checklist

[] Read docs/AGENTS.md
[] Read docs/INDEX_SHORT.md
[] Call get_scene_tree (if task involves nodes)
[] Check get_godot_errors baseline
[] Check if foulward-rag is available (one test call)
[] Identify the relevant skill(s) for this session's task

text

FILE 16: .cursor/skills/scene-tree-and-physics/SKILL.md

text
---
name: scene-tree-and-physics
description: >-
  Activate when working with scene tree structure, node paths, physics layers,
  collision masks, input actions, or coordinate system in Foul Ward. Use when:
  scene tree, node path, get_node, physics layer, collision, input action,
  camera, ground, navigation, navmesh, spawn point, container, layer mask,
  keybinding, coordinate system, Y-up, global_position.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Scene Tree and Physics — Foul Ward

---

## Scene Tree Overview

/root
└── Main (main.tscn)
├── Managers/
│ ├── WaveManager
│ ├── SpellManager
│ ├── ResearchManager
│ ├── ShopManager
│ ├── WeaponUpgradeManager
│ └── InputManager
├── Tower (Florence — stationary, player-controlled)
├── HexGrid
│ └── [Slot_0 .. Slot_23] (Area3D nodes)
├── EnemyContainer (dynamic — EnemyBase instances)
├── ProjectileContainer (dynamic — ProjectileBase instances)
├── Arnulf
├── SpawnPoints/
│ └── [SpawnPoint_0 .. SpawnPoint_N]
├── NavigationRegion3D
└── UI/
├── HUD
├── BuildMenu
├── BetweenMissionScreen
├── MainMenu
└── EndScreen

text

> ⚠️ VERIFY: Use `get_scene_tree` MCP call to confirm actual tree. This structure is from master doc §25 and ARCHITECTURE.md — node names may differ slightly. Always validate before writing `get_node()` calls.

---

## Manager Node Path Contracts

These paths are contracted — they will not change without updating this document and `docs/AGENTS.md`:

| Manager | Path |
|---|---|
| WaveManager | `/root/Main/Managers/WaveManager` |
| SpellManager | `/root/Main/Managers/SpellManager` |
| ResearchManager | `/root/Main/Managers/ResearchManager` |
| ShopManager | `/root/Main/Managers/ShopManager` |
| WeaponUpgradeManager | `/root/Main/Managers/WeaponUpgradeManager` |
| InputManager | `/root/Main/Managers/InputManager` |

All resolved via `get_node_or_null()` with a null guard. WaveManager absent in headless = silent skip (by design).

---

## Physics Layers

| Layer # | Name | Used By |
|---|---|---|
| 1 | Tower | Tower collision body |
| 2 | Enemies | All EnemyBase collision bodies |
| 3 | Arnulf | Arnulf's collision body |
| 4 | Buildings | All BuildingBase collision bodies |
| 5 | Projectiles | All ProjectileBase collision bodies |
| 6 | Ground | Ground plane / NavigationMesh |
| 7 | HexSlots | Hex slot click detection (Area3D) |

---

## Collision Mask Configuration

| Actor | Collides With (layers) |
|---|---|
| Florence projectiles | Layer 2 (Enemies) only |
| Building projectiles | Layer 2 (Enemies) only |
| Enemies | Layer 1 (Tower) + Layer 3 (Arnulf) + Layer 4 (Buildings) |
| Arnulf | Layer 2 (Enemies) |
| HexSlot Area3D | Layer 7 only (mouse click detection) |

---

## Input Actions

Defined in `project.godot` Input Map:

| Action Name | Default Binding | Purpose |
|---|---|---|
| `fire_primary` | Left Mouse | Florence crossbow |
| `fire_secondary` | Right Mouse | Florence rapid missile |
| `cast_shockwave` | Space | Cast selected spell |
| `toggle_build_mode` | B or Tab | Enter/exit build mode |
| `cancel` | Escape | Exit build mode / close menu |

> ⚠️ VERIFY: `cast_shockwave` action name may be generic `cast_spell` now. Check `project.godot` Input Map — master doc §26 lists `cast_shockwave` but SpellManager supports 4 spells with 1–4 hotkeys.

---

## Coordinate System

- **Y-up** coordinate system (Godot 4 standard)
- **Ground plane**: Y = 0
- **Tower center**: world origin `Vector3(0, 0, 0)`
- **Flying enemies**: Y offset above ground (e.g. Y = 5.0)
- **All positions**: use `global_position`, never local `position`, for cross-node calculations
- Hex grid positions computed from axial coordinates, stored as `Vector3`

---

## NavMesh

- `NavMeshManager` (Autoload #2) registers `NavigationRegion3D`
- Rebake triggered by: `SignalBus.nav_mesh_rebake_requested.emit()`
- Ground enemies use `NavigationAgent3D`
- Flying enemies bypass NavMesh entirely (simple steering)

FILE 17: .cursor/skills/spell-and-research-system/SKILL.md

text
---
name: spell-and-research-system
description: >-
  Activate when working with spells, mana, research nodes, enchantments, or
  weapon upgrades in Foul Ward. Use when: spell, mana, cooldown, shockwave,
  research, unlock, prerequisite, enchantment, weapon upgrade, SpellManager,
  ResearchManager, EnchantmentManager, WeaponUpgradeManager, mana_regen,
  spell_id, research_cost, enchantment slot, elemental, power slot.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Spell and Research System — Foul Ward

---

## SpellManager (Scene-Bound)

Path: `/root/Main/Managers/SpellManager`

```gdscript
SpellManager.cast_spell(spell_id: String) -> bool
SpellManager.cast_selected_spell() -> bool
SpellManager.get_current_mana() -> int
SpellManager.get_max_mana() -> int             # default 100
SpellManager.get_cooldown_remaining(spell_id: String) -> float
SpellManager.is_spell_ready(spell_id: String) -> bool
SpellManager.set_mana_to_full() -> void
SpellManager.restore_mana(amount: int) -> void  # ≤0 = full restore
SpellManager.reset_to_defaults() -> void
SpellManager.set_mana_for_save_restore(mana: int) -> void
SpellManager.get_selected_spell_index() -> int
SpellManager.set_selected_spell_index(index: int) -> void
SpellManager.cycle_selected_spell(delta: int) -> void  # ±1
SpellManager.get_selected_spell_id() -> String
```

**Mana:** max 100, regen 5.0/sec
**Hotkeys:** Space = cast selected, Tab/Shift+Tab = cycle, 1–4 = select slot

---

## Registered Spells

| .tres File | Display Name | Mana | Cooldown |
|---|---|---|---|
| `shockwave.tres` | Shockwave | 50 | 60s |
| `slow_field.tres` | Slow Field | — | — |
| `arcane_beam.tres` | Arcane Beam | — | — |
| `tower_shield.tres` | Aegis Pulse | — | — |

`slow_field.tres` has `damage = 0.0` — **intentional control spell, do not fix**.
**FORMALLY CUT: Time Stop spell — never implement.**

---

## ResearchManager (Scene-Bound)

Path: `/root/Main/Managers/ResearchManager`

```gdscript
ResearchManager.can_unlock(node_id: String) -> bool
ResearchManager.unlock_node(node_id: String) -> bool
ResearchManager.unlock(node_id: String) -> void       # alias
ResearchManager.is_unlocked(node_id: String) -> bool
ResearchManager.get_available_nodes() -> Array[ResearchNodeData]
ResearchManager.get_research_points() -> int
ResearchManager.add_research_points(amount: int) -> void
ResearchManager.show_research_panel_for(node_id: String) -> void
ResearchManager.reset_to_defaults() -> void
ResearchManager.get_save_data() -> Dictionary         # {unlocked_node_ids: [...]}
ResearchManager.restore_from_save(data: Dictionary) -> void
```

**24 research nodes** in `resources/research_data/`.
Field names: `node_id`, `research_cost` (**NOT** `rp_cost`), `prerequisite_ids`.

---

## EnchantmentManager (Autoload #17)

```gdscript
EnchantmentManager.get_equipped_enchantment_id(weapon_slot: Types.WeaponSlot, slot_type: String) -> String
EnchantmentManager.get_equipped_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> EnchantmentData
EnchantmentManager.get_all_equipped_enchantments_for_weapon(weapon_slot: Types.WeaponSlot) -> Dictionary
EnchantmentManager.try_apply_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String, gold_cost: int) -> bool
EnchantmentManager.remove_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> void  # FREE
EnchantmentManager.get_affinity_level(weapon_slot: Types.WeaponSlot) -> int    # POST-MVP inert
EnchantmentManager.get_affinity_xp(weapon_slot: Types.WeaponSlot) -> float     # POST-MVP inert
EnchantmentManager.gain_affinity_xp(weapon_slot: Types.WeaponSlot, amount: float) -> void  # POST-MVP inert
EnchantmentManager.reset_to_defaults() -> void
EnchantmentManager.get_save_data() -> Dictionary
EnchantmentManager.restore_from_save(data: Dictionary) -> void
```

**Slot types per weapon:** `"elemental"` and `"power"`
**4 enchantments:** `arcane_focus`, `scorching_bolts`, `sharpened_mechanism`, `toxic_payload`
**Remove:** FREE. **Apply:** costs gold.
**Affinity XP:** POST-MVP — all three affinity methods are inert stubs. Do NOT implement.

---

## WeaponUpgradeManager (Scene-Bound)

Path: `/root/Main/Managers/WeaponUpgradeManager`
Per-weapon level tracking, upgrade cost, stat lookup.
Emits `SignalBus.weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)`.

> ⚠️ VERIFY: Confirm WeaponUpgradeManager's public API against `scripts/weapon_upgrade_manager.gd`. Master doc §4.5 does not list individual method signatures for this manager.

FILE 18: .cursor/skills/ally-and-mercenary-system/SKILL.md

text
---
name: ally-and-mercenary-system
description: >-
  Activate when working with allies, Arnulf, Sybil, mercenaries, or the ally
  roster in Foul Ward. Use when: ally, mercenary, Arnulf, Sybil, Florence hub
  role, companion, recruit, roster, squad, summoner building ally, defection,
  hire, AllyManager, AllyData, ally_id, is_starter_ally, is_unique, DOWNED,
  RECOVERING, patrol_radius, state machine.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Ally and Mercenary System — Foul Ward

---

## Arnulf (EXISTS IN CODE)

| Field | Value |
|---|---|
| Script | `scenes/arnulf/arnulf.gd` |
| `ally_id` | `"arnulf"` |
| `max_hp` | 200 |
| `basic_attack` | 25.0 |
| `is_unique` | true |
| `is_starter_ally` | true |
| `patrol_radius` | 55.0 |

**State machine** (`Types.ArnulfState`):

| State | Value | Behaviour |
|---|---|---|
| IDLE | 0 | Standing still |
| PATROL | 1 | Wandering within patrol_radius |
| CHASE | 2 | Moving toward target enemy |
| ATTACK | 3 | Attacking target enemy |
| DOWNED | 4 | Incapacitated |
| RECOVERING | 5 | Recovering — `health_component.reset_to_max()` (full HP) |

**Signals** (local on Arnulf node):
`arnulf_state_changed`, `arnulf_incapacitated`, `arnulf_recovered`
(Also on SignalBus — see signal table.)

**Kill counter** exists but frenzy activation is NOT in MVP.
**FORMALLY CUT: Arnulf drunkenness system — never implement.**

---

## Sybil (PARTIAL — spell management exists; passive system PLANNED)

- Role: Spell researcher / spell support
- Spell system managed via SpellManager (see spell-and-research-system skill)
- **Sybil Passive Selection System**: PLANNED, not yet in code — stubs only
- Do not implement passive system until explicitly tasked

---

## AllyManager (Autoload #11)

```gdscript
AllyManager.spawn_squad(building: BuildingBase) -> void
# Spawns leader + followers for a summoner building

AllyManager.despawn_squad(building_instance_id: String) -> void
# Frees all allies for that building — keyed by placed_instance_id
```

---

## AllyData Fields

```gdscript
@export var ally_id: String             # use ally_data.ally_id (NOT .get("ally_id", ""))
@export var display_name: String
@export var max_hp: int
@export var attack_damage: float
@export var is_unique: bool
@export var is_starter_ally: bool
@export var ally_class: Types.AllyClass
```

**AllyData is a Resource** — use typed field access, never `.get(key, default)`.

---

## 12 Ally .tres Files

| ally_id | is_unique | is_starter |
|---|---|---|
| `arnulf` | true | true |
| *(11 more — see `resources/ally_data/`)* | — | — |

> ⚠️ VERIFY: Confirm all 12 ally IDs against `resources/ally_data/*.tres`. Master doc §11 states 12 ally .tres files but only lists Arnulf by name in detail.

---

## Mercenary System

```gdscript
# Generate offers for a given day
CampaignManager.generate_offers_for_day(day: int) -> void

# Preview without mutating state
CampaignManager.preview_mercenary_offers_for_day(day: int, hypothetical_owned: Array[String]) -> Array

# Get current offers
CampaignManager.get_current_offers() -> Array

# Purchase offer at index (spends resources, adds ally to roster)
CampaignManager.purchase_mercenary_offer(index: int) -> bool

# Defection offer injection after mini-boss defeat
CampaignManager.notify_mini_boss_defeated(boss_id: String) -> void
```

**Max active allies per day:** 2 (`max_active_allies_per_day`)

---

## DOWNED → RECOVERING

```gdscript
# On DOWNED→RECOVERING transition:
health_component.reset_to_max()  # Full HP recovery — not partial
```

FILE 19: .cursor/skills/lifecycle-flows/SKILL.md

text
---
name: lifecycle-flows
description: >-
  Activate when implementing or debugging mission flow, game loop, startup
  sequence, wave sequence, or tower destruction in Foul Ward. Use when:
  lifecycle, flow, mission cycle, game loop, startup, new game, mission start,
  mission end, wave sequence, between missions, tower destroyed, mission failed,
  mission won, build phase start, enemy spawn flow, all_waves_cleared.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Lifecycle Flows — Foul Ward

---

## Flow 1: Full Mission Cycle (§27.1)

GameManager.start_new_game()
└─ CampaignManager.start_new_campaign() # resets day to 1
└─ EconomyManager.reset_to_defaults()
└─ emit game_state_changed → MISSION_BRIEFING

Player confirms briefing:
└─ GameManager.start_wave_countdown()
└─ BuildPhaseManager.set_build_phase_active(true)
└─ emit build_mode_entered

Player exits build mode / wave countdown begins:
└─ BuildPhaseManager.set_build_phase_active(false)
└─ WaveManager.start_wave_sequence()
└─ emit game_state_changed → COMBAT

COMBAT LOOP (per wave):
└─ WaveManager emits wave_started(wave_number, enemy_count)
└─ Enemies spawn at SpawnPoints
└─ [enemies path toward Tower]
└─ WaveManager emits wave_cleared(wave_number) when all enemies dead
└─ EconomyManager.grant_wave_clear_reward(wave, day_config.economy)
└─ Repeat until wave == WAVES_PER_MISSION

All waves cleared:
└─ WaveManager emits all_waves_cleared
└─ SaveManager.save_current_state() # automatic — do not add extra save calls
└─ emit mission_won(mission_number)
└─ game_state_changed → MISSION_WON → BETWEEN_MISSIONS

Between missions:
└─ CampaignManager.start_next_day()
└─ GameManager.advance_to_next_day()
└─ game_state_changed → MISSION_BRIEFING # loop for next day

Campaign complete (day 50):
└─ game_state_changed → GAME_WON

Tower destroyed alternative path:
└─ SignalBus.tower_destroyed emitted
└─ SaveManager.save_current_state() # automatic
└─ emit mission_failed(mission_number)
└─ game_state_changed → MISSION_FAILED → BETWEEN_MISSIONS

text

---

## Flow 2: Building Placement (§27.2)

Player clicks hex slot (HexGrid Area3D, Layer 7)
└─ BuildPhaseManager.assert_build_phase("placement") → must be true
└─ EconomyManager.can_afford_building(building_data) → must be true
└─ building: BuildingBase = BuildingScene.instantiate()
└─ building.initialize(building_data, slot_index) # BEFORE add_child
└─ HexGrid.add_child(building)
└─ EconomyManager.register_purchase(building_data)
└─ If aura: AuraManager.register_aura(building)
└─ If summoner: AllyManager.spawn_squad(building)
└─ SignalBus.building_placed.emit(slot_index, building_type)

Sell flow:
└─ refund = EconomyManager.get_refund(building_data, paid_gold, paid_material)
└─ EconomyManager.add_gold(refund.gold)
└─ EconomyManager.add_building_material(refund.material)
└─ If aura: AuraManager.deregister_aura(building.placed_instance_id)
└─ If summoner: AllyManager.despawn_squad(building.placed_instance_id)
└─ building.queue_free()
└─ SignalBus.building_sold.emit(slot_index, building_type)

text

---

## Flow 3: Enemy Reaching Tower (§27.3)

Enemy NavigationAgent3D reaches tower proximity (or target distance)
└─ enemy.on_reached_tower()
└─ SignalBus.tower_damaged.emit(tower.current_hp - enemy.damage, tower.max_hp)
└─ tower.current_hp -= enemy.damage
└─ enemy.queue_free() # deferred

If tower.current_hp <= 0:
└─ SignalBus.tower_destroyed.emit()
└─ [triggers mission failed path above]

Any system holding enemy reference:
└─ MUST call is_instance_valid(enemy_ref) before accessing
└─ enemy.queue_free() is deferred — reference may be valid one frame after

text

---

## Build Mode Mid-Combat

GameManager.enter_build_mode()
└─ Engine.time_scale = 0.1 # slow-mo during build
└─ BuildPhaseManager.set_build_phase_active(true)
└─ game_state_changed → BUILD_MODE

GameManager.exit_build_mode()
└─ Engine.time_scale = 1.0
└─ BuildPhaseManager.set_build_phase_active(false)
└─ game_state_changed → COMBAT

text

FILE 20: .cursor/skills/save-and-dialogue/SKILL.md

text
---
name: save-and-dialogue
description: >-
  Activate when working with save/load, autosave, dialogue, relationship
  affinity, or character conditions in Foul Ward. Use when: save, load,
  autosave, save slot, attempt, restore, dialogue, conversation, relationship,
  affinity, tier, DialogueManager, SaveManager, RelationshipManager,
  DialogueEntry, condition keys, character_id, once_only, chain_next_id.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Save and Dialogue — Foul Ward

---

## SaveManager (Autoload #13)

File: `autoloads/save_manager.gd`
**No `class_name`** — intentional, prevents GdUnit autoload shadowing. Do not add one.

Rolling autosaves to `user://saves/attempt_*/slot_*.json`. 5 slots.

```gdscript
SaveManager.start_new_attempt() -> void
SaveManager.save_current_state() -> void    # builds payload from all managers, writes slot 0
SaveManager.load_slot(slot_index: int) -> bool
SaveManager.get_available_slots() -> Array[int]
SaveManager.has_resumable_attempt() -> bool
SaveManager.clear_all_saves_for_test() -> void  # test helper only
```

**Save payload structure:**
```gdscript
{
    version: int,
    attempt_id: String,
    campaign: {},      # CampaignManager.get_save_data()
    game: {},          # GameManager.get_save_data()
    relationship: {},  # RelationshipManager.get_save_data()
    research: {},      # ResearchManager.get_save_data()
    shop: {},          # ShopManager.get_save_data()
    enchantments: {}   # EnchantmentManager.get_save_data()
}
```

**Critical:** `save_current_state()` is called automatically on `mission_won` and
`mission_failed`. Do NOT add extra save calls elsewhere.

**When adding a new saveable system:** wire both `get_save_data()` and
`restore_from_save()` into `SaveManager._build_save_payload()` and
`_apply_save_payload()` immediately — see anti-pattern AP-14.

---

## DialogueManager (Autoload #14)

File: `autoloads/dialogue_manager.gd`
Loads `DialogueEntry` .tres from `res://resources/dialogue/`.

```gdscript
DialogueManager.request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry
DialogueManager.get_entry_by_id(entry_id: String) -> DialogueEntry
DialogueManager.mark_entry_played(entry_id: String) -> void
DialogueManager.notify_dialogue_finished(entry_id: String, character_id: String) -> void
DialogueManager.on_campaign_day_started() -> void
DialogueManager.get_tracked_gold() -> int
DialogueManager.get_unlocked_research_ids_snapshot() -> Dictionary
DialogueManager.get_total_shop_purchases_tracked() -> int
DialogueManager.get_arnulf_state_tracked() -> Types.ArnulfState
DialogueManager.get_spell_cast_count_tracked() -> int
```

**Local signals** (NOT on SignalBus — known convention exception):
```gdscript
signal dialogue_line_started(entry_id: String, character_id: String)
signal dialogue_line_finished(entry_id: String, character_id: String)
```
UIManager connects to `dialogue_line_finished` directly on the DialogueManager node.

**Condition keys** for `DialogueEntry.conditions`:
`current_mission_number`, `mission_won_count`, `gold_amount`,
`sybil_research_unlocked_any`, `arnulf_research_unlocked_any`,
`research_unlocked_<id>`, `shop_item_purchased_<id>`,
`arnulf_is_downed`, `florence.*`, `campaign.*`

**7 character IDs:**
`FLORENCE`, `COMPANION_MELEE`, `SPELL_RESEARCHER`, `MERCHANT`,
`WEAPONS_ENGINEER`, `ENCHANTER`, `MERCENARY_COMMANDER`

**All 15 dialogue entries are TODO placeholders** as of Prompt 51.

---

## RelationshipManager (Autoload #7)

File: `autoloads/relationship_manager.gd`
**No `class_name`** — intentional. Do not add one.

Affinity range: −100..100 per `character_id`. Tiers from `relationship_tier_config.tres`.

```gdscript
RelationshipManager.get_affinity(character_id: String) -> float
RelationshipManager.get_tier(character_id: String) -> String        # e.g. "Hostile", "Neutral", "Friendly"
RelationshipManager.get_tier_rank_index(tier_name: String) -> int
RelationshipManager.add_affinity(character_id: String, delta: float) -> void
RelationshipManager.reload_from_resources() -> void
RelationshipManager.get_save_data() -> Dictionary                   # {affinities: {id: float}}
RelationshipManager.restore_from_save(data: Dictionary) -> void
```

Relationship events driven by `RelationshipEventData` .tres resources.
**Do not hardcode affinity delta values in .gd files** — always via resource.
