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
