# FOUL WARD — SYSTEMS.md — Part 1 of 3
# Systems: Wave Manager | Economy Manager | Damage Calculator
# Reference: ARCHITECTURE.md + CONVENTIONS.md are canonical. This document specifies
# implementation-level pseudocode, edge cases, and GdUnit4 test specifications.
# UI layer MUST NOT appear anywhere — systems communicate only via SignalBus.

---

# ═══════════════════════════════════════════════════════════════════
# SYSTEM 1 — WAVE MANAGER
# File: res://scripts/wave_manager.gd
# Scene node: Main > Managers > WaveManager (Node)
# ═══════════════════════════════════════════════════════════════════

## 1.1 PURPOSE

WaveManager drives the per-mission wave loop: countdown → spawn → track → clear → repeat.
It owns the countdown timer, the spawn logic, and the living enemy count. It does NOT
decide mission success or failure — that is GameManager's responsibility via signals.

WaveManager requires two scene-tree references:
- EnemyContainer (Node3D): parent node for spawned enemies
- SpawnPoints (Node3D): parent node with 10 Marker3D children

These are the ONLY scene-tree dependencies. Document them clearly for SimBot awareness.

---

## 1.2 CLASS VARIABLES

```gdscript
class_name WaveManager
extends Node

## Seconds of countdown before each wave.
@export var wave_countdown_duration: float = 30.0

## Maximum waves per mission.
@export var max_waves: int = 10

## Enemy data resources — one per EnemyType, indexed by Types.EnemyType enum value.
## Order MUST match Types.EnemyType: [ORC_GRUNT, ORC_BRUTE, GOBLIN_FIREBUG,
## PLAGUE_ZOMBIE, ORC_ARCHER, BAT_SWARM]
@export var enemy_data_registry: Array[EnemyData] = []

# Preloaded scene
const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")

# Internal state
var _current_wave: int = 0              # 0 = no wave yet, 1-10 during mission
var _countdown_remaining: float = 0.0   # Seconds until next wave spawns
var _is_counting_down: bool = false     # True during countdown phase
var _is_wave_active: bool = false       # True while enemies from current wave alive
var _is_sequence_running: bool = false  # True from start_wave_sequence() to mission end
var _enemies_spawned_this_wave: int = 0 # For bookkeeping

# Scene references (set in _ready)
@onready var _enemy_container: Node3D = get_node("/root/Main/EnemyContainer")
@onready var _spawn_points: Node3D = get_node("/root/Main/SpawnPoints")
```

**ASSUMPTION**: `_enemy_container` and `_spawn_points` paths match the scene tree in
ARCHITECTURE.md §2. If the scene tree changes, these references must be updated.

---

## 1.3 SIGNALS EMITTED (via SignalBus)

| Signal                        | Payload                                 | When                                |
|-------------------------------|-----------------------------------------|-------------------------------------|
| `wave_countdown_started`      | `wave_number: int, seconds: float`      | Countdown begins for next wave      |
| `wave_started`                | `wave_number: int, enemy_count: int`    | Wave spawned, enemies active        |
| `wave_cleared`                | `wave_number: int`                      | All enemies from wave dead          |
| `all_waves_cleared`           | (none)                                  | Wave 10 cleared, mission complete   |

## 1.4 SIGNALS CONSUMED (from SignalBus)

| Signal              | Handler                    | Action                                    |
|---------------------|----------------------------|-------------------------------------------|
| `enemy_killed`      | `_on_enemy_killed()`       | Check if wave is now cleared              |
| `game_state_changed`| `_on_game_state_changed()` | Pause/resume countdown during build mode  |

---

## 1.5 METHOD SIGNATURES

```gdscript
# === PUBLIC API (Bot-callable) ===

## Begins the wave sequence for a mission. Starts countdown for wave 1.
## Call once when mission enters COMBAT state.
## Precondition: _is_sequence_running == false.
func start_wave_sequence() -> void

## Immediately spawns enemies for the given wave without countdown.
## Used by SimBot for fast-forward testing. Does NOT skip the wave —
## the wave still must be cleared before the next one starts.
func force_spawn_wave(wave_number: int) -> void

## Returns the number of living enemies (nodes in "enemies" group).
func get_living_enemy_count() -> int

## Returns the current wave number (0 if not started, 1-10 during mission).
func get_current_wave_number() -> int

## Returns true if a wave has been spawned and enemies are still alive.
func is_wave_active() -> bool

## Returns true if the countdown timer is ticking.
func is_counting_down() -> bool

## Returns the remaining countdown seconds. 0.0 if not counting down.
func get_countdown_remaining() -> float

## Resets all state for a new mission. Called by GameManager between missions.
func reset_for_new_mission() -> void

## Clears all enemies immediately. Used by GameManager on mission end/fail.
func clear_all_enemies() -> void


# === PRIVATE METHODS ===

## Spawns all enemies for the given wave number at random spawn points.
func _spawn_wave(wave_number: int) -> void

## Called every _physics_process frame. Manages countdown timer.
func _process_countdown(delta: float) -> void

## Finds a random spawn point from the SpawnPoints children.
func _get_random_spawn_position() -> Vector3

## Signal handler: checks if wave is cleared after an enemy dies.
func _on_enemy_killed(
    enemy_type: Types.EnemyType,
    position: Vector3,
    gold_reward: int
) -> void

## Signal handler: pauses countdown during build mode.
func _on_game_state_changed(
    old_state: Types.GameState,
    new_state: Types.GameState
) -> void
```

---

## 1.6 PSEUDOCODE

### _ready()

```gdscript
func _ready() -> void:
    SignalBus.enemy_killed.connect(_on_enemy_killed)
    SignalBus.game_state_changed.connect(_on_game_state_changed)
    # Validate registry has exactly 6 entries (one per EnemyType)
    assert(enemy_data_registry.size() == 6,
        "enemy_data_registry must have exactly 6 entries, got %d" % enemy_data_registry.size())
```

### start_wave_sequence()

```gdscript
func start_wave_sequence() -> void:
    assert(not _is_sequence_running, "start_wave_sequence called while already running")
    _is_sequence_running = true
    _current_wave = 0
    _begin_countdown_for_next_wave()
```

### _begin_countdown_for_next_wave()

```gdscript
func _begin_countdown_for_next_wave() -> void:
    _current_wave += 1
    _countdown_remaining = wave_countdown_duration
    _is_counting_down = true
    _is_wave_active = false
    SignalBus.wave_countdown_started.emit(_current_wave, wave_countdown_duration)
```

### _physics_process(delta)

```gdscript
func _physics_process(delta: float) -> void:
    if not _is_sequence_running:
        return

    if _is_counting_down:
        _process_countdown(delta)
```

### _process_countdown(delta)

```gdscript
func _process_countdown(delta: float) -> void:
    # delta is already scaled by Engine.time_scale (build mode = 0.1x)
    _countdown_remaining -= delta

    if _countdown_remaining <= 0.0:
        _countdown_remaining = 0.0
        _is_counting_down = false
        _spawn_wave(_current_wave)
```

### _spawn_wave(wave_number)

```gdscript
func _spawn_wave(wave_number: int) -> void:
    assert(wave_number >= 1 and wave_number <= max_waves,
        "Invalid wave_number: %d" % wave_number)

    var spawn_points_array: Array[Node] = _spawn_points.get_children()
    assert(spawn_points_array.size() > 0, "No spawn points found")

    var total_spawned: int = 0

    for enemy_type_index: int in range(enemy_data_registry.size()):
        var enemy_data: EnemyData = enemy_data_registry[enemy_type_index]

        for i: int in range(wave_number):
            var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
            enemy.initialize(enemy_data)

            # Pick random spawn point + small random offset to prevent stacking
            var spawn_marker: Marker3D = spawn_points_array.pick_random() as Marker3D
            var offset: Vector3 = Vector3(
                randf_range(-2.0, 2.0),
                0.0,
                randf_range(-2.0, 2.0)
            )
            enemy.global_position = spawn_marker.global_position + offset

            # Flying enemies get Y offset
            if enemy_data.is_flying:
                enemy.global_position.y = 5.0

            _enemy_container.add_child(enemy)
            enemy.add_to_group("enemies")
            total_spawned += 1

    _enemies_spawned_this_wave = total_spawned
    _is_wave_active = true
    SignalBus.wave_started.emit(wave_number, total_spawned)
```

### force_spawn_wave(wave_number)

```gdscript
func force_spawn_wave(wave_number: int) -> void:
    # Bot API: skip countdown entirely, just spawn
    _current_wave = wave_number
    _is_counting_down = false
    _countdown_remaining = 0.0
    _is_sequence_running = true
    _spawn_wave(wave_number)
```

### _on_enemy_killed(enemy_type, position, gold_reward)

```gdscript
func _on_enemy_killed(
    enemy_type: Types.EnemyType,
    position: Vector3,
    gold_reward: int
) -> void:
    if not _is_wave_active:
        return

    # Use call_deferred to let the dying enemy finish queue_free() this frame
    call_deferred("_check_wave_cleared")


func _check_wave_cleared() -> void:
    var living: int = get_living_enemy_count()
    if living > 0:
        return

    _is_wave_active = false
    SignalBus.wave_cleared.emit(_current_wave)

    if _current_wave >= max_waves:
        # Final wave cleared — mission complete
        _is_sequence_running = false
        SignalBus.all_waves_cleared.emit()
    else:
        # More waves to go — start next countdown
        _begin_countdown_for_next_wave()
```

### get_living_enemy_count()

```gdscript
func get_living_enemy_count() -> int:
    return get_tree().get_nodes_in_group("enemies").size()
```

### _on_game_state_changed(old_state, new_state)

```gdscript
func _on_game_state_changed(
    old_state: Types.GameState,
    new_state: Types.GameState
) -> void:
    # Build mode does NOT pause the countdown — it just slows it via time_scale.
    # No special handling needed because _physics_process delta is already scaled.
    # This handler is a no-op for MVP but exists for future use (e.g., mission pause).
    pass
```

### reset_for_new_mission()

```gdscript
func reset_for_new_mission() -> void:
    _current_wave = 0
    _countdown_remaining = 0.0
    _is_counting_down = false
    _is_wave_active = false
    _is_sequence_running = false
    _enemies_spawned_this_wave = 0
    clear_all_enemies()
```

### clear_all_enemies()

```gdscript
func clear_all_enemies() -> void:
    for enemy: Node in get_tree().get_nodes_in_group("enemies"):
        enemy.remove_from_group("enemies")
        enemy.queue_free()
```

### Helper methods

```gdscript
func get_current_wave_number() -> int:
    return _current_wave

func is_wave_active() -> bool:
    return _is_wave_active

func is_counting_down() -> bool:
    return _is_counting_down

func get_countdown_remaining() -> float:
    return _countdown_remaining
```

---

## 1.7 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **Wave spawned during build mode** | Countdown is slowed by `Engine.time_scale = 0.1`. If countdown reaches 0 while in build mode, wave spawns normally — enemies just move at 10% speed. This is by design (player sees enemies trickling in). |
| **Last enemy dies same frame as another spawns** | `call_deferred("_check_wave_cleared")` ensures the check runs after all physics processing for the frame completes. Group membership is the source of truth. |
| **force_spawn_wave called with wave > max_waves** | Assert fires in debug. In release: `_spawn_wave` still works but `_check_wave_cleared` will emit `all_waves_cleared` immediately after that wave clears. |
| **force_spawn_wave called while countdown active** | Overwrites countdown state. The forced wave becomes the current wave. Previous countdown is abandoned. |
| **start_wave_sequence called while already running** | Assert fires. This is a programming error — GameManager must call `reset_for_new_mission()` first. |
| **No spawn points in scene** | Assert fires in `_spawn_wave`. This is a scene setup error. |
| **enemy_data_registry has wrong size** | Assert fires in `_ready`. Must have exactly 6 entries. |
| **Enemy queue_free'd by spell same frame as projectile hit** | `is_instance_valid()` check in enemy death handler. Group count is authoritative — double-kills don't double-count because the enemy is only in the group once. |
| **All enemies killed before wave_started signal processed** | Extremely unlikely with 6+ enemies, but `_check_wave_cleared` uses `call_deferred`, so `wave_started` always fires first. |
| **Tower destroyed mid-wave** | WaveManager doesn't care — it keeps tracking. GameManager handles mission failure independently. WaveManager stops naturally when `reset_for_new_mission()` is called. |

---

## 1.8 GdUnit4 TEST SPECIFICATIONS

File: `res://tests/test_wave_manager.gd`

```gdscript
class_name TestWaveManager
extends GdUnitTestSuite
```

### Test: Wave Scaling Formula

```
test_wave_scaling_wave_1_spawns_6_enemies
    Arrange: Create WaveManager with 6 EnemyData entries. Mock EnemyContainer + SpawnPoints.
    Act:     force_spawn_wave(1)
    Assert:  get_living_enemy_count() == 6
             wave_started signal emitted with (1, 6)

test_wave_scaling_wave_5_spawns_30_enemies
    Arrange: Same setup.
    Act:     force_spawn_wave(5)
    Assert:  get_living_enemy_count() == 30
             wave_started signal emitted with (5, 30)

test_wave_scaling_wave_10_spawns_60_enemies
    Arrange: Same setup.
    Act:     force_spawn_wave(10)
    Assert:  get_living_enemy_count() == 60
             wave_started signal emitted with (10, 60)

test_wave_scaling_each_type_gets_n_enemies_for_wave_n
    Arrange: Create WaveManager. Tag each spawned enemy with its EnemyData type.
    Act:     force_spawn_wave(3)
    Assert:  For each of the 6 EnemyTypes, exactly 3 enemies of that type exist.
             Total == 18.

test_wave_scaling_wave_0_is_invalid
    Arrange: Create WaveManager.
    Act:     force_spawn_wave(0)
    Assert:  Assert fires (wave_number >= 1 violated).

test_wave_scaling_wave_11_is_invalid
    Arrange: Create WaveManager with max_waves = 10.
    Act:     force_spawn_wave(11)
    Assert:  Assert fires (wave_number <= max_waves violated).
```

### Test: Spawn Point Assignment

```
test_spawn_enemies_placed_at_spawn_point_positions
    Arrange: Create 10 SpawnPoint markers at known positions.
    Act:     force_spawn_wave(1)
    Assert:  Each spawned enemy's position is within 2.5 units (offset tolerance)
             of one of the 10 spawn point positions.

test_spawn_flying_enemies_have_y_offset
    Arrange: Create WaveManager with BAT_SWARM enemy_data (is_flying = true).
    Act:     force_spawn_wave(1)
    Assert:  All bat_swarm enemies have global_position.y == 5.0.

test_spawn_ground_enemies_have_y_zero
    Arrange: Create WaveManager with ORC_GRUNT (is_flying = false).
    Act:     force_spawn_wave(1)
    Assert:  All orc_grunt enemies have global_position.y == 0.0 (± offset tolerance).

test_spawn_enemies_added_to_enemies_group
    Arrange: Create WaveManager.
    Act:     force_spawn_wave(1)
    Assert:  get_tree().get_nodes_in_group("enemies").size() == 6.

test_spawn_enemies_are_children_of_enemy_container
    Arrange: Create WaveManager with EnemyContainer mock.
    Act:     force_spawn_wave(1)
    Assert:  _enemy_container.get_child_count() == 6.
```

### Test: Countdown Timer

```
test_countdown_starts_at_configured_duration
    Arrange: Set wave_countdown_duration = 30.0.
    Act:     start_wave_sequence()
    Assert:  get_countdown_remaining() == 30.0
             is_counting_down() == true
             wave_countdown_started signal emitted with (1, 30.0)

test_countdown_decrements_by_delta
    Arrange: start_wave_sequence()
    Act:     Simulate 5 physics frames at delta = 1.0 (5 seconds total)
    Assert:  get_countdown_remaining() == 25.0

test_countdown_reaching_zero_triggers_spawn
    Arrange: Set wave_countdown_duration = 1.0. start_wave_sequence()
    Act:     Simulate physics frames until countdown <= 0
    Assert:  is_counting_down() == false
             is_wave_active() == true
             wave_started signal emitted with (1, 6)

test_countdown_respects_time_scale
    Arrange: Set wave_countdown_duration = 10.0. Engine.time_scale = 0.1.
             start_wave_sequence()
    Act:     Simulate 10 physics frames at real delta = 1.0
             (effective delta per frame = 0.1 due to time_scale,
              but Godot passes scaled delta to _physics_process automatically)
    Note:    In Godot, _physics_process receives the UNSCALED fixed timestep.
             Engine.time_scale multiplies the physics tick rate itself.
             This test verifies the countdown accumulates correctly under
             the scaled tick rate.
    Assert:  Countdown progressed by ~1.0 seconds of game time after 10 real seconds.
    ASSUMPTION: GdUnit4 can simulate _physics_process with controlled delta. If not,
    test the countdown math directly by calling _process_countdown(delta) manually.

test_countdown_does_not_go_negative
    Arrange: Set wave_countdown_duration = 0.5.
    Act:     Call _process_countdown(1.0)  # Overshoots by 0.5s
    Assert:  get_countdown_remaining() == 0.0 (clamped, not -0.5)
```

### Test: Wave Start / End Signals

```
test_wave_started_signal_emitted_on_spawn
    Arrange: Monitor SignalBus.wave_started.
    Act:     force_spawn_wave(3)
    Assert:  wave_started emitted with (3, 18)

test_wave_cleared_signal_emitted_when_all_enemies_dead
    Arrange: force_spawn_wave(1) → 6 enemies.
    Act:     Manually free all 6 enemies (simulating kills).
             For each: emit SignalBus.enemy_killed then queue_free.
             Wait one frame for call_deferred.
    Assert:  wave_cleared emitted with (1)

test_all_waves_cleared_emitted_after_wave_10
    Arrange: Set max_waves = 10. Advance through waves 1-9 by spawning and killing.
    Act:     force_spawn_wave(10). Kill all 60 enemies. Wait one frame.
    Assert:  all_waves_cleared emitted.
             _is_sequence_running == false.

test_wave_cleared_not_emitted_while_enemies_alive
    Arrange: force_spawn_wave(2) → 12 enemies.
    Act:     Kill 11 enemies. Wait one frame.
    Assert:  wave_cleared NOT emitted.
             get_living_enemy_count() == 1.

test_next_countdown_starts_after_wave_cleared
    Arrange: force_spawn_wave(1). Kill all enemies. Wait one frame.
    Assert:  wave_cleared emitted with (1).
             is_counting_down() == true  (countdown for wave 2 started)
             get_current_wave_number() == 2
             wave_countdown_started emitted with (2, 30.0)
```

### Test: Sequence Control

```
test_start_wave_sequence_initializes_correctly
    Arrange: Create WaveManager.
    Act:     start_wave_sequence()
    Assert:  _is_sequence_running == true
             get_current_wave_number() == 1
             is_counting_down() == true

test_reset_for_new_mission_clears_all_state
    Arrange: force_spawn_wave(5). Don't kill enemies.
    Act:     reset_for_new_mission()
    Assert:  get_current_wave_number() == 0
             is_wave_active() == false
             is_counting_down() == false
             get_living_enemy_count() == 0
             _enemy_container.get_child_count() == 0

test_clear_all_enemies_removes_from_group_and_frees
    Arrange: force_spawn_wave(3) → 18 enemies.
    Act:     clear_all_enemies(). Wait one frame for queue_free.
    Assert:  get_living_enemy_count() == 0.

test_force_spawn_wave_overrides_countdown
    Arrange: start_wave_sequence(). Countdown is running for wave 1.
    Act:     force_spawn_wave(5)
    Assert:  get_current_wave_number() == 5
             is_counting_down() == false
             is_wave_active() == true

test_sequence_not_running_physics_process_is_noop
    Arrange: Create WaveManager. Do NOT call start_wave_sequence().
    Act:     Simulate 100 physics frames.
    Assert:  get_current_wave_number() == 0.
             No signals emitted.
```

### Test: Integration with Enemy Death

```
test_enemy_killed_signal_decrements_living_count
    Arrange: force_spawn_wave(1) → 6 enemies. Store reference to first enemy.
    Act:     First enemy emits health_depleted (simulating death), gets queue_free'd.
             SignalBus.enemy_killed is emitted. Wait one frame.
    Assert:  get_living_enemy_count() == 5.

test_double_kill_same_frame_does_not_double_decrement
    Arrange: force_spawn_wave(1) → 6 enemies. Store references to first two.
    Act:     Both enemies die same frame (both queue_free'd, both emit enemy_killed).
             Wait one frame.
    Assert:  get_living_enemy_count() == 4 (not 3 or lower).

test_enemy_killed_during_countdown_does_not_trigger_wave_cleared
    Arrange: start_wave_sequence(). Countdown running. No wave spawned yet.
             Leftover enemy from a previous test somehow still in group.
    Act:     Kill that enemy. Wait one frame.
    Assert:  wave_cleared NOT emitted (_is_wave_active == false, so handler returns early).
```

---


# ═══════════════════════════════════════════════════════════════════
# SYSTEM 2 — ECONOMY MANAGER
# File: res://autoloads/economy_manager.gd
# Autoload name: EconomyManager
# ═══════════════════════════════════════════════════════════════════

## 2.1 PURPOSE

EconomyManager is the single source of truth for all three resource types.
Every resource modification in the game MUST go through this class's public methods.
No other script may directly modify resource values. Every modification emits
`SignalBus.resource_changed` so UI and other systems stay synchronized.

EconomyManager is an autoload singleton with zero scene-tree dependencies.
It can be fully tested in isolation without any nodes in the scene.

---

## 2.2 CLASS VARIABLES

```gdscript
class_name EconomyManager
extends Node

# === Resource Counters ===
# These are the CANONICAL names. Every module that reads resources uses these.
var gold: int = 0
var building_material: int = 0
var research_material: int = 0

# === Starting Values (for reset) ===
const STARTING_GOLD: int = 100
const STARTING_BUILDING_MATERIAL: int = 10
const STARTING_RESEARCH_MATERIAL: int = 0

# === Post-Mission Reward Values ===
# These are flat amounts awarded after each mission completion.
# Future: scale by mission number, difficulty, performance.
const POST_MISSION_GOLD: int = 50
const POST_MISSION_BUILDING_MATERIAL: int = 5
const POST_MISSION_RESEARCH_MATERIAL: int = 3
```

---

## 2.3 SIGNALS EMITTED (via SignalBus)

| Signal              | Payload                                            | When                        |
|---------------------|----------------------------------------------------|-----------------------------|
| `resource_changed`  | `resource_type: Types.ResourceType, new_amount: int` | After ANY resource modification |

## 2.4 SIGNALS CONSUMED (from SignalBus)

| Signal          | Handler                   | Action                                  |
|-----------------|---------------------------|-----------------------------------------|
| `enemy_killed`  | `_on_enemy_killed()`      | Add gold_reward from killed enemy       |

---

## 2.5 METHOD SIGNATURES

```gdscript
# === PUBLIC API (Bot-callable) ===

## Adds [amount] gold. Emits resource_changed.
## Precondition: amount > 0.
func add_gold(amount: int) -> void

## Attempts to subtract [amount] gold. Returns true on success, false if
## insufficient funds. Emits resource_changed only on success.
## Precondition: amount > 0.
func spend_gold(amount: int) -> bool

## Adds [amount] building material. Emits resource_changed.
func add_building_material(amount: int) -> void

## Attempts to subtract [amount] building material. Returns true/false.
func spend_building_material(amount: int) -> bool

## Adds [amount] research material. Emits resource_changed.
func add_research_material(amount: int) -> void

## Attempts to subtract [amount] research material. Returns true/false.
func spend_research_material(amount: int) -> bool

## Returns true if player has >= gold_cost gold AND >= material_cost building material.
## Does NOT check research material (research uses its own check).
func can_afford(gold_cost: int, material_cost: int) -> bool

## Returns true if player has >= cost research material.
func can_afford_research(cost: int) -> bool

## Awards flat post-mission resources. Called by GameManager after wave 10 cleared.
func award_post_mission_rewards() -> void

## Resets all resources to starting values. Called on new game.
func reset_to_defaults() -> void

## Getters for SimBot observation
func get_gold() -> int
func get_building_material() -> int
func get_research_material() -> int
```

---

## 2.6 PSEUDOCODE

### _ready()

```gdscript
func _ready() -> void:
    SignalBus.enemy_killed.connect(_on_enemy_killed)
    reset_to_defaults()
```

### add_gold(amount)

```gdscript
func add_gold(amount: int) -> void:
    assert(amount > 0, "add_gold called with non-positive amount: %d" % amount)
    gold += amount
    SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
```

### spend_gold(amount)

```gdscript
func spend_gold(amount: int) -> bool:
    assert(amount > 0, "spend_gold called with non-positive amount: %d" % amount)
    if gold < amount:
        return false
    gold -= amount
    SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
    return true
```

### add_building_material(amount)

```gdscript
func add_building_material(amount: int) -> void:
    assert(amount > 0, "add_building_material called with non-positive amount: %d" % amount)
    building_material += amount
    SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
```

### spend_building_material(amount)

```gdscript
func spend_building_material(amount: int) -> bool:
    assert(amount > 0, "spend_building_material called with non-positive amount: %d" % amount)
    if building_material < amount:
        return false
    building_material -= amount
    SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
    return true
```

### add_research_material(amount)

```gdscript
func add_research_material(amount: int) -> void:
    assert(amount > 0, "add_research_material called with non-positive amount: %d" % amount)
    research_material += amount
    SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)
```

### spend_research_material(amount)

```gdscript
func spend_research_material(amount: int) -> bool:
    assert(amount > 0, "spend_research_material called with non-positive amount: %d" % amount)
    if research_material < amount:
        return false
    research_material -= amount
    SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)
    return true
```

### can_afford(gold_cost, material_cost)

```gdscript
func can_afford(gold_cost: int, material_cost: int) -> bool:
    return gold >= gold_cost and building_material >= material_cost
```

### can_afford_research(cost)

```gdscript
func can_afford_research(cost: int) -> bool:
    return research_material >= cost
```

### award_post_mission_rewards()

```gdscript
func award_post_mission_rewards() -> void:
    add_gold(POST_MISSION_GOLD)
    add_building_material(POST_MISSION_BUILDING_MATERIAL)
    add_research_material(POST_MISSION_RESEARCH_MATERIAL)
```

### reset_to_defaults()

```gdscript
func reset_to_defaults() -> void:
    gold = STARTING_GOLD
    building_material = STARTING_BUILDING_MATERIAL
    research_material = STARTING_RESEARCH_MATERIAL
    SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
    SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
    SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)
```

### _on_enemy_killed(enemy_type, position, gold_reward)

```gdscript
func _on_enemy_killed(
    enemy_type: Types.EnemyType,
    position: Vector3,
    gold_reward: int
) -> void:
    if gold_reward > 0:
        add_gold(gold_reward)
```

### Getters

```gdscript
func get_gold() -> int:
    return gold

func get_building_material() -> int:
    return building_material

func get_research_material() -> int:
    return research_material
```

---

## 2.7 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **Spend more than available** | `spend_*()` returns `false`, no modification, no signal emitted. |
| **Spend exact amount (balance goes to 0)** | Allowed. Returns `true`. Balance becomes 0. Signal emitted with 0. |
| **Add amount of 0** | Assert fires. Caller must validate before calling. |
| **Negative amount passed** | Assert fires. All amounts must be positive. |
| **Multiple rapid spend calls (race condition)** | Not possible — GDScript is single-threaded. Sequential calls are safe. |
| **enemy_killed with gold_reward = 0** | Guard `if gold_reward > 0` skips the add. No signal emitted for 0-reward enemies. This prevents a `resource_changed` event with no actual change. |
| **reset_to_defaults called mid-mission** | Emits 3 `resource_changed` signals for the reset values. UI updates accordingly. GameManager is responsible for calling this only at appropriate times. |
| **Integer overflow** | Extremely unlikely with MVP economy. Gold would need to exceed ~2 billion. Not guarded in MVP; add a cap if economy scales. |
| **can_afford with 0 costs** | Returns true (0 >= 0). Valid for free items. |
| **award_post_mission_rewards called multiple times** | Adds rewards each time. GameManager must ensure single call per mission. |

---

## 2.8 GdUnit4 TEST SPECIFICATIONS

File: `res://tests/test_economy_manager.gd`

```gdscript
class_name TestEconomyManager
extends GdUnitTestSuite
```

### Test: Gold Operations

```
test_add_gold_positive_amount_increases_total
    Arrange: reset_to_defaults() → gold = 100.
    Act:     add_gold(50)
    Assert:  get_gold() == 150

test_add_gold_emits_resource_changed_signal
    Arrange: reset_to_defaults(). Monitor SignalBus.resource_changed.
    Act:     add_gold(25)
    Assert:  resource_changed emitted with (Types.ResourceType.GOLD, 125)

test_spend_gold_sufficient_funds_returns_true
    Arrange: reset_to_defaults() → gold = 100.
    Act:     var result: bool = spend_gold(60)
    Assert:  result == true
             get_gold() == 40

test_spend_gold_insufficient_funds_returns_false
    Arrange: reset_to_defaults() → gold = 100.
    Act:     var result: bool = spend_gold(150)
    Assert:  result == false
             get_gold() == 100 (unchanged)

test_spend_gold_exact_amount_succeeds
    Arrange: reset_to_defaults() → gold = 100.
    Act:     var result: bool = spend_gold(100)
    Assert:  result == true
             get_gold() == 0

test_spend_gold_insufficient_does_not_emit_signal
    Arrange: reset_to_defaults(). Monitor SignalBus.resource_changed.
             Clear signal monitor after reset signals.
    Act:     spend_gold(999)
    Assert:  resource_changed NOT emitted after the spend attempt.

test_spend_gold_emits_resource_changed_on_success
    Arrange: reset_to_defaults(). add_gold(200). Clear signal monitor.
    Act:     spend_gold(150)
    Assert:  resource_changed emitted with (GOLD, 150)  # 100 + 200 - 150

test_add_gold_zero_amount_asserts
    Arrange: reset_to_defaults().
    Act:     add_gold(0)
    Assert:  Assert fires.

test_spend_gold_zero_amount_asserts
    Arrange: reset_to_defaults().
    Act:     spend_gold(0)
    Assert:  Assert fires.

test_add_gold_negative_amount_asserts
    Arrange: reset_to_defaults().
    Act:     add_gold(-10)
    Assert:  Assert fires.

test_spend_gold_negative_amount_asserts
    Arrange: reset_to_defaults().
    Act:     spend_gold(-10)
    Assert:  Assert fires.
```

### Test: Building Material Operations

```
test_add_building_material_increases_total
    Arrange: reset_to_defaults() → building_material = 10.
    Act:     add_building_material(5)
    Assert:  get_building_material() == 15

test_spend_building_material_sufficient_returns_true
    Arrange: reset_to_defaults().
    Act:     var result: bool = spend_building_material(8)
    Assert:  result == true
             get_building_material() == 2

test_spend_building_material_insufficient_returns_false
    Arrange: reset_to_defaults() → building_material = 10.
    Act:     var result: bool = spend_building_material(20)
    Assert:  result == false
             get_building_material() == 10

test_add_building_material_emits_resource_changed
    Arrange: Monitor SignalBus.resource_changed. reset_to_defaults(). Clear monitor.
    Act:     add_building_material(3)
    Assert:  resource_changed emitted with (BUILDING_MATERIAL, 13)
```

### Test: Research Material Operations

```
test_add_research_material_increases_total
    Arrange: reset_to_defaults() → research_material = 0.
    Act:     add_research_material(3)
    Assert:  get_research_material() == 3

test_spend_research_material_sufficient_returns_true
    Arrange: reset_to_defaults(). add_research_material(5).
    Act:     var result: bool = spend_research_material(3)
    Assert:  result == true
             get_research_material() == 2

test_spend_research_material_insufficient_returns_false
    Arrange: reset_to_defaults() → research_material = 0.
    Act:     var result: bool = spend_research_material(1)
    Assert:  result == false
             get_research_material() == 0

test_spend_research_material_exact_succeeds
    Arrange: reset_to_defaults(). add_research_material(3).
    Act:     spend_research_material(3)
    Assert:  get_research_material() == 0
```

### Test: can_afford

```
test_can_afford_both_sufficient_returns_true
    Arrange: reset_to_defaults() → gold = 100, building_material = 10.
    Act:     var result: bool = can_afford(50, 5)
    Assert:  result == true

test_can_afford_gold_insufficient_returns_false
    Arrange: reset_to_defaults().
    Act:     var result: bool = can_afford(200, 5)
    Assert:  result == false

test_can_afford_material_insufficient_returns_false
    Arrange: reset_to_defaults().
    Act:     var result: bool = can_afford(50, 20)
    Assert:  result == false

test_can_afford_both_insufficient_returns_false
    Arrange: reset_to_defaults().
    Act:     var result: bool = can_afford(200, 20)
    Assert:  result == false

test_can_afford_zero_costs_returns_true
    Arrange: reset_to_defaults().
    Act:     var result: bool = can_afford(0, 0)
    Assert:  result == true

test_can_afford_exact_amounts_returns_true
    Arrange: reset_to_defaults() → gold = 100, building_material = 10.
    Act:     var result: bool = can_afford(100, 10)
    Assert:  result == true

test_can_afford_does_not_modify_resources
    Arrange: reset_to_defaults().
    Act:     can_afford(50, 5)
    Assert:  get_gold() == 100 (unchanged)
             get_building_material() == 10 (unchanged)
```

### Test: can_afford_research

```
test_can_afford_research_sufficient_returns_true
    Arrange: reset_to_defaults(). add_research_material(5).
    Act:     var result: bool = can_afford_research(3)
    Assert:  result == true

test_can_afford_research_insufficient_returns_false
    Arrange: reset_to_defaults() → research_material = 0.
    Act:     var result: bool = can_afford_research(1)
    Assert:  result == false

test_can_afford_research_exact_returns_true
    Arrange: reset_to_defaults(). add_research_material(2).
    Act:     can_afford_research(2)
    Assert:  result == true

test_can_afford_research_zero_cost_returns_true
    Arrange: reset_to_defaults().
    Act:     can_afford_research(0)
    Assert:  result == true
```

### Test: Post-Mission Rewards

```
test_award_post_mission_rewards_adds_all_three
    Arrange: reset_to_defaults().
    Act:     award_post_mission_rewards()
    Assert:  get_gold() == 100 + 50 = 150
             get_building_material() == 10 + 5 = 15
             get_research_material() == 0 + 3 = 3

test_award_post_mission_rewards_emits_three_signals
    Arrange: reset_to_defaults(). Monitor SignalBus.resource_changed. Clear after reset.
    Act:     award_post_mission_rewards()
    Assert:  resource_changed emitted exactly 3 times:
             (GOLD, 150), (BUILDING_MATERIAL, 15), (RESEARCH_MATERIAL, 3)

test_award_post_mission_rewards_stacks_with_existing
    Arrange: reset_to_defaults(). add_gold(200). add_building_material(10).
    Act:     award_post_mission_rewards()
    Assert:  get_gold() == 100 + 200 + 50 = 350
             get_building_material() == 10 + 10 + 5 = 25
```

### Test: Reset

```
test_reset_to_defaults_restores_starting_values
    Arrange: add_gold(9999). spend_building_material(10). add_research_material(50).
    Act:     reset_to_defaults()
    Assert:  get_gold() == 100
             get_building_material() == 10
             get_research_material() == 0

test_reset_to_defaults_emits_three_resource_changed_signals
    Arrange: Monitor SignalBus.resource_changed.
    Act:     reset_to_defaults()
    Assert:  resource_changed emitted 3 times with starting values.

test_reset_to_defaults_called_twice_is_idempotent
    Arrange: reset_to_defaults(). add_gold(50).
    Act:     reset_to_defaults()
    Assert:  get_gold() == 100 (not 150)
```

### Test: Enemy Kill Integration

```
test_enemy_killed_signal_adds_gold_reward
    Arrange: reset_to_defaults().
    Act:     SignalBus.enemy_killed.emit(Types.EnemyType.ORC_GRUNT, Vector3.ZERO, 10)
    Assert:  get_gold() == 110

test_enemy_killed_zero_reward_does_not_change_gold
    Arrange: reset_to_defaults(). Monitor resource_changed. Clear after reset.
    Act:     SignalBus.enemy_killed.emit(Types.EnemyType.BAT_SWARM, Vector3.ZERO, 0)
    Assert:  get_gold() == 100
             resource_changed NOT emitted.

test_multiple_enemy_kills_accumulate_gold
    Arrange: reset_to_defaults().
    Act:     Emit enemy_killed 5 times with gold_reward = 10 each.
    Assert:  get_gold() == 150

test_enemy_kill_gold_combined_with_direct_add
    Arrange: reset_to_defaults(). add_gold(50).
    Act:     SignalBus.enemy_killed.emit(Types.EnemyType.ORC_BRUTE, Vector3.ZERO, 25)
    Assert:  get_gold() == 175  # 100 + 50 + 25
```

### Test: Transaction Sequences

```
test_spend_then_add_maintains_correct_balance
    Arrange: reset_to_defaults() → gold = 100.
    Act:     spend_gold(60) → gold = 40.
             add_gold(30) → gold = 70.
    Assert:  get_gold() == 70

test_multiple_spends_accumulate_correctly
    Arrange: reset_to_defaults() → gold = 100.
    Act:     spend_gold(30) → true, gold = 70.
             spend_gold(30) → true, gold = 40.
             spend_gold(30) → true, gold = 10.
             spend_gold(30) → false, gold = 10.
    Assert:  get_gold() == 10

test_interleaved_resource_operations
    Arrange: reset_to_defaults().
    Act:     spend_gold(50). add_building_material(5). spend_research_material(1).
    Assert:  get_gold() == 50
             get_building_material() == 15
             spend_research_material returned false (0 < 1)
             get_research_material() == 0
```

---


# ═══════════════════════════════════════════════════════════════════
# SYSTEM 3 — DAMAGE CALCULATOR
# File: res://autoloads/damage_calculator.gd
# Autoload name: DamageCalculator
# ═══════════════════════════════════════════════════════════════════

## 3.1 PURPOSE

DamageCalculator is a stateless autoload that resolves damage amounts by applying the
4x4 damage type x armor type multiplier matrix. It has no internal state, emits no
signals, consumes no signals, and has zero scene-tree dependencies.

This is the simplest system in the project. It is a pure function wrapped in a singleton
for global access. All damage resolution in the game routes through this single method.

**MVP scope note on DoT**: The MVP spec lists Fire Brazier as applying "burn DoT" and
Poison Vat as "ground AoE, slows + damages." However, the MVP spec does NOT specify
detailed DoT tick mechanics. For MVP, Fire and Poison damage are applied as instant
hits (not ticks over time). The DamageCalculator provides a helper method
`calculate_dot_tick()` as a STUB for post-MVP implementation. The Fire Brazier's burn
and Poison Vat's damage-over-time will be implemented as rapid repeated instant hits
by the building's own attack loop at its fire_rate, NOT as a separate DoT subsystem.

---

## 3.2 CLASS VARIABLES

```gdscript
class_name DamageCalculator
extends Node

# The 4x4 damage multiplier matrix.
# Outer key: ArmorType. Inner key: DamageType. Value: multiplier.
# Read as: "An enemy with [ArmorType] takes [multiplier]x damage from [DamageType]."
var _damage_matrix: Dictionary = {}

# Lookup for readable armor/damage names (for debug logging)
var _armor_names: Dictionary = {}
var _damage_type_names: Dictionary = {}
```

---

## 3.3 SIGNALS

None emitted. None consumed. This is a pure utility class.

---

## 3.4 METHOD SIGNATURES

```gdscript
# === PUBLIC API ===

## Calculates final damage by applying the matrix multiplier.
## Returns: base_damage * multiplier for the given (damage_type, armor_type) pair.
## Guaranteed: result >= 0.0. If multiplier is 0.0 (immunity), returns 0.0.
func calculate_damage(
    base_damage: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float

## Returns the raw multiplier for a given (damage_type, armor_type) pair.
## Useful for UI tooltips ("2x effective" / "immune").
func get_multiplier(
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float

## Returns true if the given armor type is immune to the given damage type
## (multiplier == 0.0).
func is_immune(
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> bool

## STUB — Post-MVP DoT tick calculation.
## Returns damage per tick for a DoT effect. Currently returns 0.0.
## Post-MVP: Will use dot_damage, tick_interval, duration to compute per-tick values.
func calculate_dot_tick(
    dot_total_damage: float,
    tick_interval: float,
    duration: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float
```

---

## 3.5 PSEUDOCODE

### _ready()

```gdscript
func _ready() -> void:
    _build_damage_matrix()
    _build_debug_names()
```

### _build_damage_matrix()

```gdscript
func _build_damage_matrix() -> void:
    # Matrix from MVP spec — exact values:
    #              Physical  Fire  Magical  Poison
    # Unarmored:   1.0       1.0   1.0      1.0
    # Heavy Armor: 0.5       1.0   2.0      1.0
    # Undead:      1.0       2.0   1.0      0.0
    # Flying:      1.0       1.0   1.0      1.0

    _damage_matrix = {
        Types.ArmorType.UNARMORED: {
            Types.DamageType.PHYSICAL: 1.0,
            Types.DamageType.FIRE: 1.0,
            Types.DamageType.MAGICAL: 1.0,
            Types.DamageType.POISON: 1.0,
        },
        Types.ArmorType.HEAVY_ARMOR: {
            Types.DamageType.PHYSICAL: 0.5,
            Types.DamageType.FIRE: 1.0,
            Types.DamageType.MAGICAL: 2.0,
            Types.DamageType.POISON: 1.0,
        },
        Types.ArmorType.UNDEAD: {
            Types.DamageType.PHYSICAL: 1.0,
            Types.DamageType.FIRE: 2.0,
            Types.DamageType.MAGICAL: 1.0,
            Types.DamageType.POISON: 0.0,
        },
        Types.ArmorType.FLYING: {
            Types.DamageType.PHYSICAL: 1.0,
            Types.DamageType.FIRE: 1.0,
            Types.DamageType.MAGICAL: 1.0,
            Types.DamageType.POISON: 1.0,
        },
    }
```

### calculate_damage(base_damage, damage_type, armor_type)

```gdscript
func calculate_damage(
    base_damage: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float:
    assert(base_damage >= 0.0,
        "calculate_damage called with negative base_damage: %f" % base_damage)
    assert(_damage_matrix.has(armor_type),
        "Unknown armor_type: %d" % armor_type)
    assert(_damage_matrix[armor_type].has(damage_type),
        "Unknown damage_type: %d" % damage_type)

    var multiplier: float = _damage_matrix[armor_type][damage_type]
    return base_damage * multiplier
```

### get_multiplier(damage_type, armor_type)

```gdscript
func get_multiplier(
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float:
    assert(_damage_matrix.has(armor_type),
        "Unknown armor_type: %d" % armor_type)
    assert(_damage_matrix[armor_type].has(damage_type),
        "Unknown damage_type: %d" % damage_type)

    return _damage_matrix[armor_type][damage_type]
```

### is_immune(damage_type, armor_type)

```gdscript
func is_immune(
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> bool:
    return get_multiplier(damage_type, armor_type) == 0.0
```

### calculate_dot_tick() — STUB

```gdscript
func calculate_dot_tick(
    dot_total_damage: float,
    tick_interval: float,
    duration: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float:
    # STUB: Post-MVP DoT system. Currently returns 0.0.
    # Future implementation:
    # var ticks: int = int(duration / tick_interval)
    # var damage_per_tick: float = dot_total_damage / float(ticks)
    # return damage_per_tick * get_multiplier(damage_type, armor_type)
    return 0.0
```

### _build_debug_names()

```gdscript
func _build_debug_names() -> void:
    _armor_names = {
        Types.ArmorType.UNARMORED: "Unarmored",
        Types.ArmorType.HEAVY_ARMOR: "Heavy Armor",
        Types.ArmorType.UNDEAD: "Undead",
        Types.ArmorType.FLYING: "Flying",
    }
    _damage_type_names = {
        Types.DamageType.PHYSICAL: "Physical",
        Types.DamageType.FIRE: "Fire",
        Types.DamageType.MAGICAL: "Magical",
        Types.DamageType.POISON: "Poison",
    }
```

---

## 3.6 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **Poison vs Undead (immunity)** | Multiplier = 0.0. `calculate_damage()` returns 0.0. No special case needed — the matrix handles it naturally. `is_immune()` returns `true`. |
| **base_damage = 0.0** | Returns 0.0. Valid case (e.g., a building with 0 damage configured). Not asserted. |
| **base_damage negative** | Assert fires. No system should produce negative damage. |
| **Unknown ArmorType enum value** | Assert fires. All enum values must be in the matrix. If a new ArmorType is added to `Types.gd`, it MUST also be added to `_build_damage_matrix()`. |
| **Unknown DamageType enum value** | Same — assert fires. Matrix must cover all enum values. |
| **Very high base_damage** | No cap in MVP. Damage can be astronomical if base_damage is huge. Post-MVP: consider a damage cap or diminishing returns. |
| **Float precision** | Multipliers are clean (0.0, 0.5, 1.0, 2.0). No precision issues. If future multipliers use non-binary-representable fractions (e.g., 0.33), watch for accumulation errors. |
| **Concurrent access** | Stateless — safe. Matrix is read-only after `_ready()`. |
| **DoT stub called** | Returns 0.0. No side effects. Callers must check return and skip applying 0 damage to avoid unnecessary signal noise. |
| **Flying enemies and ground AoE** | DamageCalculator does NOT handle targeting rules. Flying immunity to ground AoE is enforced by the attacking system (Poison Vat's targeting logic), NOT by the damage matrix. The matrix shows Flying takes normal damage from Poison — but the Poison Vat simply never targets flying enemies. |

---

## 3.7 GdUnit4 TEST SPECIFICATIONS

File: `res://tests/test_damage_calculator.gd`

```gdscript
class_name TestDamageCalculator
extends GdUnitTestSuite
```

### Test: Full Matrix Coverage (all 16 combinations)

```
test_physical_vs_unarmored_multiplier_is_1_0
    Act:     calculate_damage(100.0, PHYSICAL, UNARMORED)
    Assert:  result == 100.0

test_physical_vs_heavy_armor_multiplier_is_0_5
    Act:     calculate_damage(100.0, PHYSICAL, HEAVY_ARMOR)
    Assert:  result == 50.0

test_physical_vs_undead_multiplier_is_1_0
    Act:     calculate_damage(100.0, PHYSICAL, UNDEAD)
    Assert:  result == 100.0

test_physical_vs_flying_multiplier_is_1_0
    Act:     calculate_damage(100.0, PHYSICAL, FLYING)
    Assert:  result == 100.0

test_fire_vs_unarmored_multiplier_is_1_0
    Act:     calculate_damage(100.0, FIRE, UNARMORED)
    Assert:  result == 100.0

test_fire_vs_heavy_armor_multiplier_is_1_0
    Act:     calculate_damage(100.0, FIRE, HEAVY_ARMOR)
    Assert:  result == 100.0

test_fire_vs_undead_multiplier_is_2_0
    Act:     calculate_damage(100.0, FIRE, UNDEAD)
    Assert:  result == 200.0

test_fire_vs_flying_multiplier_is_1_0
    Act:     calculate_damage(100.0, FIRE, FLYING)
    Assert:  result == 100.0

test_magical_vs_unarmored_multiplier_is_1_0
    Act:     calculate_damage(100.0, MAGICAL, UNARMORED)
    Assert:  result == 100.0

test_magical_vs_heavy_armor_multiplier_is_2_0
    Act:     calculate_damage(100.0, MAGICAL, HEAVY_ARMOR)
    Assert:  result == 200.0

test_magical_vs_undead_multiplier_is_1_0
    Act:     calculate_damage(100.0, MAGICAL, UNDEAD)
    Assert:  result == 100.0

test_magical_vs_flying_multiplier_is_1_0
    Act:     calculate_damage(100.0, MAGICAL, FLYING)
    Assert:  result == 100.0

test_poison_vs_unarmored_multiplier_is_1_0
    Act:     calculate_damage(100.0, POISON, UNARMORED)
    Assert:  result == 100.0

test_poison_vs_heavy_armor_multiplier_is_1_0
    Act:     calculate_damage(100.0, POISON, HEAVY_ARMOR)
    Assert:  result == 100.0

test_poison_vs_undead_multiplier_is_0_0_immunity
    Act:     calculate_damage(100.0, POISON, UNDEAD)
    Assert:  result == 0.0

test_poison_vs_flying_multiplier_is_1_0
    Act:     calculate_damage(100.0, POISON, FLYING)
    Assert:  result == 100.0
```

### Test: get_multiplier()

```
test_get_multiplier_physical_heavy_armor_returns_0_5
    Act:     get_multiplier(PHYSICAL, HEAVY_ARMOR)
    Assert:  result == 0.5

test_get_multiplier_fire_undead_returns_2_0
    Act:     get_multiplier(FIRE, UNDEAD)
    Assert:  result == 2.0

test_get_multiplier_poison_undead_returns_0_0
    Act:     get_multiplier(POISON, UNDEAD)
    Assert:  result == 0.0

test_get_multiplier_magical_heavy_armor_returns_2_0
    Act:     get_multiplier(MAGICAL, HEAVY_ARMOR)
    Assert:  result == 2.0
```

### Test: is_immune()

```
test_is_immune_poison_vs_undead_returns_true
    Act:     is_immune(POISON, UNDEAD)
    Assert:  result == true

test_is_immune_physical_vs_unarmored_returns_false
    Act:     is_immune(PHYSICAL, UNARMORED)
    Assert:  result == false

test_is_immune_fire_vs_undead_returns_false
    Act:     is_immune(FIRE, UNDEAD)
    Assert:  result == false  # 2.0 multiplier, not immune

test_is_immune_physical_vs_heavy_armor_returns_false
    Act:     is_immune(PHYSICAL, HEAVY_ARMOR)
    Assert:  result == false  # 0.5 = resistant, not immune
```

### Test: Boundary Values

```
test_calculate_damage_zero_base_returns_zero
    Act:     calculate_damage(0.0, PHYSICAL, UNARMORED)
    Assert:  result == 0.0

test_calculate_damage_zero_base_with_multiplier_2_returns_zero
    Act:     calculate_damage(0.0, FIRE, UNDEAD)
    Assert:  result == 0.0  # 0.0 * 2.0 = 0.0

test_calculate_damage_small_value
    Act:     calculate_damage(1.0, PHYSICAL, HEAVY_ARMOR)
    Assert:  result == 0.5

test_calculate_damage_large_value
    Act:     calculate_damage(10000.0, MAGICAL, HEAVY_ARMOR)
    Assert:  result == 20000.0

test_calculate_damage_fractional_base
    Act:     calculate_damage(33.3, PHYSICAL, HEAVY_ARMOR)
    Assert:  result is approximately 16.65 (within float tolerance)

test_calculate_damage_negative_base_asserts
    Act:     calculate_damage(-10.0, PHYSICAL, UNARMORED)
    Assert:  Assert fires.
```

### Test: Matrix Completeness

```
test_matrix_has_all_four_armor_types
    Arrange: Get all ArmorType enum values.
    Assert:  _damage_matrix has a key for each ArmorType.

test_matrix_has_all_four_damage_types_per_armor
    Arrange: For each ArmorType in _damage_matrix.
    Assert:  Inner dictionary has keys for all 4 DamageType values.

test_matrix_total_entries_is_16
    Arrange: Count all entries.
    Assert:  Total key-value pairs across all inner dicts == 16.

test_all_multipliers_are_non_negative
    Arrange: Iterate all 16 entries.
    Assert:  Every multiplier >= 0.0.
```

### Test: DoT Stub

```
test_calculate_dot_tick_returns_zero_in_mvp
    Act:     calculate_dot_tick(100.0, 0.5, 5.0, FIRE, UNARMORED)
    Assert:  result == 0.0

test_calculate_dot_tick_with_immunity_returns_zero
    Act:     calculate_dot_tick(100.0, 0.5, 5.0, POISON, UNDEAD)
    Assert:  result == 0.0
```

### Test: Consistency with Spec

```
test_orc_grunt_takes_full_physical_damage
    Arrange: ORC_GRUNT has armor_type = UNARMORED (from EnemyData).
    Act:     calculate_damage(50.0, PHYSICAL, UNARMORED)
    Assert:  result == 50.0  # Unarmored takes full physical

test_orc_brute_resists_physical_weak_to_magical
    Arrange: ORC_BRUTE has armor_type = HEAVY_ARMOR.
    Act:     physical = calculate_damage(50.0, PHYSICAL, HEAVY_ARMOR)
             magical = calculate_damage(50.0, MAGICAL, HEAVY_ARMOR)
    Assert:  physical == 25.0 (half)
             magical == 100.0 (double)

test_plague_zombie_immune_to_poison
    Arrange: PLAGUE_ZOMBIE has armor_type = UNARMORED per MVP spec
             (poison immunity is handled by EnemyData flag, not ArmorType).
    Note:    Wait — MVP spec says "poison immune" for Plague Zombie, but its
             armor_type is UNARMORED (multiplier = 1.0 for poison).
             RESOLUTION: Plague Zombie's poison immunity must be handled by
             EnemyData having a special flag OR by giving it ArmorType.UNDEAD.
             CHECK MVP SPEC: Plague Zombie color=Brown, Armor=Unarmored,
             but behavior says "poison immune."
             DECISION: This is a data issue, not a DamageCalculator issue.
             Two options:
             (a) Change Plague Zombie armor_type to UNDEAD in its .tres
             (b) Add an immune_to: Array[Types.DamageType] field to EnemyData
             Recommend (b) for MVP — see §3.8 below.
    # ASSUMPTION: Plague Zombie uses per-enemy immunity override, not ArmorType.UNDEAD.
    # The UNDEAD ArmorType would also give fire weakness (2.0x) which may not be
    # intended for a Plague Zombie. Using damage_immunities field is more precise.

test_bat_swarm_takes_normal_damage_from_all_types
    Arrange: BAT_SWARM has armor_type = FLYING.
    Act:     For each DamageType: calculate_damage(50.0, type, FLYING)
    Assert:  All results == 50.0 (all multipliers 1.0)

test_goblin_firebug_fire_immune_not_in_matrix
    Arrange: GOBLIN_FIREBUG has armor_type = UNARMORED per MVP spec.
    Note:    MVP spec says "fire immune" but armor is Unarmored.
             Fire immunity is NOT expressed in the 4x4 matrix.
             RESOLUTION: Same as Plague Zombie — use damage_immunities field.
    # ASSUMPTION: EnemyBase.take_damage() checks an immunity list before calling
    # DamageCalculator. DamageCalculator itself only knows the 4x4 matrix.
    # Specific immunity for Goblin Firebug (fire) and Plague Zombie (poison)
    # are EnemyData-level overrides, not matrix entries.
```

---

## 3.8 DESIGN NOTE: PER-ENEMY IMMUNITY OVERRIDES

The 4x4 matrix cleanly handles the four broad armor categories. However, the MVP spec
has two enemies with immunities that don't align with their armor type:

| Enemy          | Armor Type | Matrix Says               | Spec Says          |
|----------------|-----------|---------------------------|--------------------|
| Goblin Firebug | Unarmored | Takes 1.0x Fire damage    | Fire immune        |
| Plague Zombie  | Unarmored | Takes 1.0x Poison damage  | Poison immune      |

**Recommended solution** (for the team implementing EnemyBase and EnemyData):

Add to `EnemyData`:
```gdscript
## Damage types this enemy is completely immune to, overriding the matrix.
@export var damage_immunities: Array[Types.DamageType] = []
```

In `EnemyBase.take_damage()`:
```gdscript
func take_damage(amount: float, damage_type: Types.DamageType) -> void:
    # Check per-enemy immunity override BEFORE consulting DamageCalculator
    if damage_type in _enemy_data.damage_immunities:
        return  # Immune — no damage, no signal

    var final_damage: float = DamageCalculator.calculate_damage(
        amount, damage_type, _enemy_data.armor_type
    )
    health_component.apply_damage(final_damage)
```

This keeps DamageCalculator pure and stateless while allowing data-driven exceptions.

The `.tres` files for these enemies would be:
- `goblin_firebug.tres`: `damage_immunities = [Types.DamageType.FIRE]`
- `plague_zombie.tres`: `damage_immunities = [Types.DamageType.POISON]`

All other enemies: `damage_immunities = []` (empty — use matrix as-is).

---

# END OF SYSTEMS.md — Part 1 of 3
