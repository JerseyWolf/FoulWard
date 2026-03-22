# FOUL WARD — SYSTEMS.md — Part 3 of 3
# Systems: Arnulf State Machine | Enemy Pathfinding | Spell & Mana System | SimBot API Contract
# Reference: ARCHITECTURE.md + CONVENTIONS.md are canonical.
# UI layer MUST NOT appear anywhere — systems communicate only via SignalBus.
#
# CARRIES FORWARD from Parts 1 and 2:
# - damage_immunities: Array[Types.DamageType] field on EnemyData
# - EnemyBase.take_damage() checks immunity list before calling DamageCalculator
# - HealthComponent is "intentionally dumb" — it subtracts final damage and emits
#   local signals. DamageCalculator is called by the ATTACKER, not by HealthComponent.
# - HealthComponent._is_depleted prevents double health_depleted emission.
# - heal() clears _is_depleted, enabling repeated death/revive cycles (Arnulf).

---

# ═══════════════════════════════════════════════════════════════════
# SYSTEM 7 — ARNULF STATE MACHINE
# File: res://scenes/arnulf/arnulf.gd
# Scene node: Main > Arnulf (CharacterBody3D)
# ═══════════════════════════════════════════════════════════════════

## 7.1 PURPOSE

Arnulf is a fully AI-controlled melee unit. The player never gives him direct commands.
He patrols around the tower, chases the enemy closest to tower center, attacks at melee
range, and revives himself indefinitely when incapacitated.

His state machine has six states from Types.ArnulfState:
- IDLE — standing adjacent to tower, waiting for enemies.
- PATROL — reserved for post-MVP (random roaming). In MVP, unused; IDLE handles
  the return-to-tower behavior. Included in the enum for forward compatibility.
- CHASE — moving toward a target enemy via NavigationAgent3D.
- ATTACK — in melee range, dealing damage on a cooldown timer.
- DOWNED — incapacitated (HP reached 0). 3-second timer before recovery.
- RECOVERING — instant transition state. Heals to 50% HP, then returns to IDLE.

Arnulf uses NavigationAgent3D for pathfinding (consistent with ARCHITECTURE.md section 9).
His target selection always picks the enemy closest to tower center (Vector3.ZERO),
NOT closest to Arnulf's own position.

Drunkenness mechanic is DEFERRED — incapacitation cycle only for MVP.

---

## 7.2 CLASS VARIABLES

```gdscript
class_name Arnulf
extends CharacterBody3D

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

# Tower center — Arnulf's home position and target-selection reference point
const TOWER_CENTER: Vector3 = Vector3.ZERO
const HOME_POSITION: Vector3 = Vector3(2.0, 0.0, 0.0)  # Adjacent to tower

# Internal state
var _current_state: Types.ArnulfState = Types.ArnulfState.IDLE
var _chase_target: EnemyBase = null
var _attack_timer: float = 0.0
var _recovery_timer: float = 0.0

# Node references
@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
```

---

## 7.3 SIGNALS EMITTED (via SignalBus)

| Signal                   | Payload                            | When                              |
|--------------------------|------------------------------------|-----------------------------------|
| `arnulf_state_changed`   | `new_state: Types.ArnulfState`     | Every state transition            |
| `arnulf_incapacitated`   | (none)                             | Transition to DOWNED              |
| `arnulf_recovered`       | (none)                             | Transition out of RECOVERING      |

## 7.4 SIGNALS CONSUMED (from SignalBus)

None directly. Arnulf reacts to physics overlaps (DetectionArea, AttackArea) and
HealthComponent's local signals. He does NOT listen to enemy_killed — he detects
target loss via is_instance_valid() checks in his state loop.

---

## 7.5 METHOD SIGNATURES

```gdscript
# === PUBLIC API (Bot-observable, not bot-controlled) ===

## Returns the current state.
func get_current_state() -> Types.ArnulfState

## Returns current HP via HealthComponent.
func get_current_hp() -> int

## Returns max HP via HealthComponent.
func get_max_hp() -> int

## Resets Arnulf for a new mission: full HP, IDLE state, home position.
func reset_for_new_mission() -> void


# === PRIVATE ===

## Transitions to a new state. Emits arnulf_state_changed.
func _transition_to_state(new_state: Types.ArnulfState) -> void

## Finds the enemy closest to TOWER_CENTER within patrol_radius.
func _find_closest_enemy_to_tower() -> EnemyBase

## Returns true if there are any enemies in the DetectionArea.
func _has_enemies_in_range() -> bool

## State handlers — called each _physics_process frame depending on current state.
func _process_idle(delta: float) -> void
func _process_chase(delta: float) -> void
func _process_attack(delta: float) -> void
func _process_downed(delta: float) -> void
func _process_recovering() -> void

## Area3D signal handlers
func _on_detection_area_body_entered(body: Node3D) -> void
func _on_attack_area_body_entered(body: Node3D) -> void
func _on_attack_area_body_exited(body: Node3D) -> void

## HealthComponent signal handler
func _on_health_depleted() -> void
```

---

## 7.6 PSEUDOCODE

### _ready()

```gdscript
func _ready() -> void:
    health_component.max_hp = max_hp
    health_component.reset_to_max()
    health_component.health_depleted.connect(_on_health_depleted)

    detection_area.body_entered.connect(_on_detection_area_body_entered)
    attack_area.body_entered.connect(_on_attack_area_body_entered)
    attack_area.body_exited.connect(_on_attack_area_body_exited)

    # Configure NavigationAgent3D
    navigation_agent.path_desired_distance = 1.0
    navigation_agent.target_desired_distance = 1.5
    navigation_agent.avoidance_enabled = true

    _transition_to_state(Types.ArnulfState.IDLE)
```

### _physics_process(delta)

```gdscript
func _physics_process(delta: float) -> void:
    match _current_state:
        Types.ArnulfState.IDLE:
            _process_idle(delta)
        Types.ArnulfState.CHASE:
            _process_chase(delta)
        Types.ArnulfState.ATTACK:
            _process_attack(delta)
        Types.ArnulfState.DOWNED:
            _process_downed(delta)
        Types.ArnulfState.RECOVERING:
            _process_recovering()
        Types.ArnulfState.PATROL:
            # PATROL unused in MVP — treat as IDLE
            _process_idle(delta)
```

### _process_idle(delta)

```gdscript
func _process_idle(delta: float) -> void:
    # Move toward home position if not there
    var dist_to_home: float = global_position.distance_to(HOME_POSITION)
    if dist_to_home > 1.0:
        navigation_agent.target_position = HOME_POSITION
        var next_pos: Vector3 = navigation_agent.get_next_path_position()
        var direction: Vector3 = (next_pos - global_position).normalized()
        velocity = direction * move_speed
        move_and_slide()
    else:
        velocity = Vector3.ZERO

    # Check if any enemies are in detection range — if so, find best target and chase
    var target: EnemyBase = _find_closest_enemy_to_tower()
    if target != null:
        _chase_target = target
        _transition_to_state(Types.ArnulfState.CHASE)
```

### _process_chase(delta)

```gdscript
func _process_chase(delta: float) -> void:
    # Validate target still exists
    if _chase_target == null or not is_instance_valid(_chase_target):
        _chase_target = _find_closest_enemy_to_tower()
        if _chase_target == null:
            _transition_to_state(Types.ArnulfState.IDLE)
            return

    # Check patrol radius — don't chase beyond it
    var target_dist_from_tower: float = _chase_target.global_position.distance_to(TOWER_CENTER)
    if target_dist_from_tower > patrol_radius:
        # Target has moved outside patrol range — find a closer one or return home
        _chase_target = _find_closest_enemy_to_tower()
        if _chase_target == null:
            _transition_to_state(Types.ArnulfState.IDLE)
            return

    # Move toward target via NavigationAgent3D
    navigation_agent.target_position = _chase_target.global_position
    var next_pos: Vector3 = navigation_agent.get_next_path_position()
    var direction: Vector3 = (next_pos - global_position).normalized()
    velocity = direction * move_speed
    move_and_slide()

    # Attack transition is handled by AttackArea body_entered signal, not distance check.
    # This avoids duplicate detection logic.
```

### _process_attack(delta)

```gdscript
func _process_attack(delta: float) -> void:
    # Validate target still exists and is in melee range
    if _chase_target == null or not is_instance_valid(_chase_target):
        # Target died — find next
        _chase_target = _find_closest_enemy_to_tower()
        if _chase_target != null:
            _transition_to_state(Types.ArnulfState.CHASE)
        else:
            _transition_to_state(Types.ArnulfState.IDLE)
        return

    # Stand still while attacking
    velocity = Vector3.ZERO

    # Attack timer
    _attack_timer -= delta
    if _attack_timer <= 0.0:
        _attack_timer = attack_cooldown

        # Deal damage — Arnulf always deals PHYSICAL damage
        var final_damage: float = DamageCalculator.calculate_damage(
            attack_damage,
            Types.DamageType.PHYSICAL,
            _chase_target.get_enemy_data().armor_type
        )
        _chase_target.take_damage(final_damage, Types.DamageType.PHYSICAL)
```

### _process_downed(delta)

```gdscript
func _process_downed(delta: float) -> void:
    # Arnulf does not move or attack while downed
    velocity = Vector3.ZERO

    _recovery_timer -= delta
    if _recovery_timer <= 0.0:
        _transition_to_state(Types.ArnulfState.RECOVERING)
```

### _process_recovering()

```gdscript
func _process_recovering() -> void:
    # Instant transition state — heal and return to IDLE
    var heal_amount: int = max_hp / 2  # 50% of max HP
    health_component.heal(heal_amount)
    SignalBus.arnulf_recovered.emit()
    _transition_to_state(Types.ArnulfState.IDLE)
```

### _transition_to_state(new_state)

```gdscript
func _transition_to_state(new_state: Types.ArnulfState) -> void:
    var old_state: Types.ArnulfState = _current_state
    _current_state = new_state

    # State entry actions
    match new_state:
        Types.ArnulfState.IDLE:
            _chase_target = null
            _attack_timer = 0.0
        Types.ArnulfState.CHASE:
            _attack_timer = 0.0
        Types.ArnulfState.ATTACK:
            _attack_timer = 0.0  # Attack immediately upon entering ATTACK
        Types.ArnulfState.DOWNED:
            _recovery_timer = recovery_time
            _chase_target = null
            velocity = Vector3.ZERO
        Types.ArnulfState.RECOVERING:
            pass  # Handled in _process_recovering, immediate transition
        Types.ArnulfState.PATROL:
            pass  # Unused in MVP

    SignalBus.arnulf_state_changed.emit(new_state)
```

### _find_closest_enemy_to_tower()

```gdscript
func _find_closest_enemy_to_tower() -> EnemyBase:
    var best_target: EnemyBase = null
    var best_distance: float = patrol_radius + 1.0  # Beyond patrol range = invalid

    for node: Node in get_tree().get_nodes_in_group("enemies"):
        var enemy: EnemyBase = node as EnemyBase
        if enemy == null or not is_instance_valid(enemy):
            continue
        if enemy.health_component.is_dead():
            continue

        # Distance from TOWER CENTER, not from Arnulf
        var dist_to_tower: float = enemy.global_position.distance_to(TOWER_CENTER)
        if dist_to_tower > patrol_radius:
            continue

        if dist_to_tower < best_distance:
            best_distance = dist_to_tower
            best_target = enemy

    return best_target
```

### Area3D signal handlers

```gdscript
func _on_detection_area_body_entered(body: Node3D) -> void:
    if _current_state == Types.ArnulfState.DOWNED:
        return
    if _current_state == Types.ArnulfState.RECOVERING:
        return

    var enemy: EnemyBase = body as EnemyBase
    if enemy == null:
        return

    # Only react if idle — if already chasing or attacking, state machine handles it
    if _current_state == Types.ArnulfState.IDLE:
        _chase_target = _find_closest_enemy_to_tower()
        if _chase_target != null:
            _transition_to_state(Types.ArnulfState.CHASE)


func _on_attack_area_body_entered(body: Node3D) -> void:
    if _current_state != Types.ArnulfState.CHASE:
        return
    var enemy: EnemyBase = body as EnemyBase
    if enemy == null:
        return
    # Only transition to ATTACK if this is our current chase target
    if enemy == _chase_target:
        _transition_to_state(Types.ArnulfState.ATTACK)


func _on_attack_area_body_exited(body: Node3D) -> void:
    if _current_state != Types.ArnulfState.ATTACK:
        return
    var enemy: EnemyBase = body as EnemyBase
    if enemy == null:
        return
    if enemy == _chase_target:
        # Target walked out of melee range — chase again
        _transition_to_state(Types.ArnulfState.CHASE)
```

### _on_health_depleted()

```gdscript
func _on_health_depleted() -> void:
    # Overrides ANY combat state — downed takes priority
    SignalBus.arnulf_incapacitated.emit()
    _transition_to_state(Types.ArnulfState.DOWNED)
```

### reset_for_new_mission()

```gdscript
func reset_for_new_mission() -> void:
    health_component.max_hp = max_hp
    health_component.reset_to_max()
    _transition_to_state(Types.ArnulfState.IDLE)
    global_position = HOME_POSITION
    _chase_target = null
    _attack_timer = 0.0
    _recovery_timer = 0.0
    velocity = Vector3.ZERO
```

### Getters

```gdscript
func get_current_state() -> Types.ArnulfState:
    return _current_state

func get_current_hp() -> int:
    return health_component.get_current_hp()

func get_max_hp() -> int:
    return health_component.get_max_hp()
```

---

## 7.7 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **All enemies die while Arnulf chasing** | _find_closest_enemy_to_tower() returns null. Transition to IDLE. Return to HOME_POSITION. |
| **Chase target killed by building/spell, not Arnulf** | is_instance_valid() fails next frame. Re-acquire target or go IDLE. |
| **Arnulf downed during ATTACK** | _on_health_depleted fires, transitions to DOWNED regardless of current state. _chase_target cleared. |
| **Arnulf downed, enemies still hitting him** | HealthComponent._is_depleted blocks further damage. Arnulf is invulnerable while downed. |
| **Multiple enemies enter DetectionArea simultaneously** | _find_closest_enemy_to_tower() picks the one closest to tower center. Only one target selected. |
| **Enemy enters AttackArea while Arnulf is IDLE (skipped CHASE)** | body_entered handler only triggers ATTACK from CHASE state. If IDLE, the detection handler fires first, causing CHASE, then if enemy is already in AttackArea the next frame's body_entered transitions to ATTACK. |
| **Recovery timer during build mode (0.1x)** | _physics_process(delta) receives scaled delta. Recovery takes 30 real seconds at 0.1x speed. Correct. |
| **Patrol radius = 0** | No enemies can enter range. Arnulf sits at tower permanently. Valid but useless config. |
| **Target beyond patrol radius after chase started** | Each CHASE frame re-checks target distance from tower center. If target moves outside patrol_radius, Arnulf re-acquires or goes IDLE. |
| **Arnulf at HOME_POSITION, no enemies** | _process_idle sees dist_to_home <= 1.0, sets velocity to zero. _find_closest_enemy_to_tower() returns null. Arnulf stands still. |
| **Arnulf heals from DOWNED — can he die again immediately?** | Yes. heal() clears _is_depleted. If enemies attack immediately, he can be downed again. The cycle repeats infinitely per spec. |
| **Dead enemy in enemies group** | health_component.is_dead() check in _find_closest_enemy_to_tower() filters these out. |
| **Shockwave hits Arnulf (friendly fire)** | MVP does not implement friendly fire. SpellManager iterates enemies group only. Arnulf is NOT in that group. Post-MVP: GDD mentions Sybil's spells hitting Arnulf for comedy. |

---

## 7.8 GdUnit4 TEST SPECIFICATIONS

File: res://tests/test_arnulf_state_machine.gd

```gdscript
class_name TestArnulfStateMachine
extends GdUnitTestSuite
```

### Test: State Transitions

```
test_initial_state_is_idle
    Arrange: Create Arnulf. Call _ready().
    Assert:  get_current_state() == Types.ArnulfState.IDLE.

test_idle_to_chase_when_enemy_detected
    Arrange: Arnulf in IDLE. Spawn enemy within patrol_radius.
    Act:     Trigger DetectionArea body_entered with enemy.
    Assert:  get_current_state() == CHASE.
             arnulf_state_changed signal emitted with CHASE.

test_chase_to_attack_when_target_in_melee_range
    Arrange: Arnulf in CHASE with valid _chase_target.
    Act:     Trigger AttackArea body_entered with _chase_target.
    Assert:  get_current_state() == ATTACK.

test_attack_to_chase_when_target_exits_melee
    Arrange: Arnulf in ATTACK.
    Act:     Trigger AttackArea body_exited with _chase_target.
    Assert:  get_current_state() == CHASE.

test_attack_to_idle_when_target_dies_no_others
    Arrange: Arnulf in ATTACK. Only 1 enemy. Kill it.
    Act:     Next _physics_process frame. is_instance_valid returns false.
    Assert:  get_current_state() == IDLE.

test_attack_to_chase_when_target_dies_others_remain
    Arrange: Arnulf in ATTACK. 2 enemies. Kill current target.
    Act:     Next frame.
    Assert:  get_current_state() == CHASE.
             _chase_target is the remaining enemy.

test_chase_to_idle_when_target_dies_no_others
    Arrange: Arnulf in CHASE. 1 enemy. Kill it.
    Act:     Next frame.
    Assert:  get_current_state() == IDLE.

test_any_combat_to_downed_on_health_depleted
    Arrange: Arnulf in CHASE.
    Act:     Deal enough damage to deplete HP.
    Assert:  get_current_state() == DOWNED.
             arnulf_incapacitated signal emitted.

test_attack_to_downed_on_health_depleted
    Arrange: Arnulf in ATTACK.
    Act:     Deplete HP.
    Assert:  get_current_state() == DOWNED.

test_idle_to_downed_on_health_depleted
    Arrange: Arnulf in IDLE.
    Act:     Deplete HP.
    Assert:  get_current_state() == DOWNED.

test_downed_to_recovering_after_recovery_time
    Arrange: Arnulf in DOWNED. recovery_time = 3.0.
    Act:     Simulate 3.0 seconds of _physics_process.
    Assert:  State transitions DOWNED -> RECOVERING -> IDLE.

test_recovering_to_idle_is_immediate
    Arrange: Force Arnulf into RECOVERING state.
    Act:     Single _physics_process call.
    Assert:  get_current_state() == IDLE.
             arnulf_recovered signal emitted.
```

### Test: Recovery and Resurrection

```
test_recovery_heals_to_50_percent
    Arrange: max_hp = 200. Deplete HP. Wait recovery_time.
    Assert:  After recovery: get_current_hp() == 100.

test_recovery_cycle_repeats_indefinitely
    Arrange: max_hp = 200.
    Act:     Cycle: deplete -> wait recovery -> check HP. Repeat 5 times.
    Assert:  Each recovery: HP == 100. State returns to IDLE each time.
             5 arnulf_incapacitated + 5 arnulf_recovered signals total.

test_recovery_timer_respects_time_scale
    Arrange: recovery_time = 3.0. Engine.time_scale = 0.1.
    Act:     Simulate _physics_process frames.
    Assert:  Recovery takes ~30 real-time seconds (3.0 game-time at 0.1x).
    ASSUMPTION: Test can control Engine.time_scale or call _process_downed(delta) directly.

test_arnulf_invulnerable_while_downed
    Arrange: Deplete HP -> DOWNED.
    Act:     Call health_component.take_damage(100.0) while downed.
    Assert:  HealthComponent._is_depleted == true -> damage ignored. HP stays at 0.

test_recovery_odd_max_hp_truncates
    Arrange: max_hp = 201. Deplete HP.
    Act:     Recovery heals max_hp / 2 = 100 (integer division).
    Assert:  get_current_hp() == 100 (not 100.5).
```

### Test: Target Selection

```
test_target_selection_closest_to_tower_not_arnulf
    Arrange: Arnulf at (10, 0, 0). Enemy A at (5, 0, 0), Enemy B at (3, 0, 0).
    Act:     _find_closest_enemy_to_tower()
    Assert:  Returns Enemy B (distance 3 from tower < 5).

test_target_selection_ignores_enemies_beyond_patrol_radius
    Arrange: patrol_radius = 25. Enemy at (30, 0, 0).
    Act:     _find_closest_enemy_to_tower()
    Assert:  Returns null.

test_target_selection_ignores_dead_enemies
    Arrange: Enemy in group but health_component.is_dead() == true.
    Act:     _find_closest_enemy_to_tower()
    Assert:  Returns null.

test_target_selection_with_no_enemies
    Assert:  _find_closest_enemy_to_tower() returns null.

test_chase_reacquires_if_target_leaves_patrol_radius
    Arrange: Arnulf in CHASE. Target at (20, 0, 0). patrol_radius = 25.
    Act:     Move target to (30, 0, 0). Simulate _physics_process.
    Assert:  Arnulf re-acquires next closest enemy or goes IDLE.
```

### Test: Movement

```
test_idle_returns_to_home_position
    Arrange: Arnulf at (15, 0, 0). No enemies.
    Act:     Simulate several _physics_process frames.
    Assert:  Arnulf moves toward HOME_POSITION. Velocity nonzero.

test_idle_at_home_stays_still
    Arrange: Arnulf at HOME_POSITION. No enemies.
    Act:     Simulate frame.
    Assert:  velocity == Vector3.ZERO.

test_chase_moves_toward_target
    Arrange: Arnulf in CHASE. Target at (10, 0, 10).
    Act:     Simulate frame.
    Assert:  Position moved toward target. velocity.length() approximately == move_speed.

test_downed_does_not_move
    Arrange: Arnulf in DOWNED.
    Assert:  velocity == Vector3.ZERO. Position unchanged.

test_attack_does_not_move
    Arrange: Arnulf in ATTACK.
    Assert:  velocity == Vector3.ZERO.
```

### Test: Attack

```
test_attack_deals_damage_on_cooldown
    Arrange: Arnulf in ATTACK. attack_damage = 25. attack_cooldown = 1.0.
             Target: ORC_GRUNT (UNARMORED).
    Act:     Simulate 1.0 seconds.
    Assert:  Target received 25 damage.

test_attack_respects_damage_matrix
    Arrange: attack_damage = 25. Target: ORC_BRUTE (HEAVY_ARMOR).
    Act:     One attack cycle.
    Assert:  Target received 12.5 damage (25 * 0.5) rounded up to 13.

test_attack_first_hit_is_immediate
    Arrange: Transition to ATTACK state.
    Assert:  _attack_timer == 0.0 on entry -> first attack happens this frame.

test_attack_timer_resets_after_each_hit
    Arrange: attack_cooldown = 1.0.
    Act:     First attack fires. Simulate 0.5 seconds.
    Assert:  No second attack yet.
```

### Test: Reset

```
test_reset_for_new_mission_restores_full_hp
    Arrange: Deplete HP.
    Act:     reset_for_new_mission()
    Assert:  get_current_hp() == max_hp.

test_reset_for_new_mission_sets_idle
    Arrange: Arnulf in DOWNED.
    Act:     reset_for_new_mission()
    Assert:  get_current_state() == IDLE.

test_reset_for_new_mission_moves_to_home
    Arrange: Arnulf at (20, 0, 15).
    Act:     reset_for_new_mission()
    Assert:  global_position == HOME_POSITION.
```

---


# ═══════════════════════════════════════════════════════════════════
# SYSTEM 8 — ENEMY PATHFINDING
# File: res://scenes/enemies/enemy_base.gd
# Scene node: instantiated at runtime into Main > EnemyContainer
# ═══════════════════════════════════════════════════════════════════

## 8.1 PURPOSE

EnemyBase is the runtime representation of a single enemy. It owns movement (pathfinding
toward the tower), attack behavior (melee or ranged), and death handling. Each enemy
instance is initialized with an EnemyData resource that defines all its stats.

Ground enemies use NavigationAgent3D. Flying enemies (Bat Swarm) use simple Vector3
steering. Ranged enemies (Orc Archer) stop at their attack_range and fire projectiles.

Dynamic navmesh rebaking is NOT implemented in MVP (ARCHITECTURE.md section 9.4).
Buildings do not block enemy paths — they are turrets, not walls.

---

## 8.2 CLASS VARIABLES

```gdscript
class_name EnemyBase
extends CharacterBody3D

var _enemy_data: EnemyData = null
var _attack_timer: float = 0.0
var _is_attacking: bool = false

const FLYING_HEIGHT: float = 5.0
const TARGET_POSITION: Vector3 = Vector3.ZERO

@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")

# ASSUMPTION: These paths match ARCHITECTURE.md section 2
@onready var _projectile_container: Node3D = get_node("/root/Main/ProjectileContainer")
@onready var _tower: Node = get_node("/root/Main/Tower")
```

---

## 8.3 SIGNALS EMITTED (via SignalBus)

| Signal          | Payload                                              | When              |
|-----------------|------------------------------------------------------|-------------------|
| `enemy_killed`  | `enemy_type, position: Vector3, gold_reward: int`    | HP reaches 0      |

## 8.4 SIGNALS CONSUMED

None from SignalBus. Reacts to own HealthComponent local signals.

---

## 8.5 METHOD SIGNATURES

```gdscript
func initialize(enemy_data: EnemyData) -> void
func take_damage(amount: float, damage_type: Types.DamageType) -> void
func get_enemy_data() -> EnemyData

func _move_ground(delta: float) -> void
func _move_flying(delta: float) -> void
func _attack_tower_melee(delta: float) -> void
func _attack_tower_ranged(delta: float) -> void
func _on_health_depleted() -> void
```

---

## 8.6 PSEUDOCODE

### initialize(enemy_data)

```gdscript
func initialize(enemy_data: EnemyData) -> void:
    assert(enemy_data != null)
    _enemy_data = enemy_data
    _attack_timer = 0.0
    _is_attacking = false

    health_component.max_hp = enemy_data.max_hp
    health_component.reset_to_max()
    health_component.health_depleted.connect(_on_health_depleted)

    if not enemy_data.is_flying:
        navigation_agent.target_position = TARGET_POSITION
        navigation_agent.path_desired_distance = 0.5
        navigation_agent.target_desired_distance = enemy_data.attack_range
        navigation_agent.avoidance_enabled = true
        navigation_agent.radius = 0.5

    var mesh: MeshInstance3D = get_node_or_null("EnemyMesh")
    if mesh != null:
        var mat: StandardMaterial3D = StandardMaterial3D.new()
        mat.albedo_color = enemy_data.color
        mesh.material_override = mat
```

### _physics_process(delta)

```gdscript
func _physics_process(delta: float) -> void:
    if _enemy_data == null:
        return
    if _is_attacking:
        if _enemy_data.is_ranged:
            _attack_tower_ranged(delta)
        else:
            _attack_tower_melee(delta)
        return
    if _enemy_data.is_flying:
        _move_flying(delta)
    else:
        _move_ground(delta)
```

### _move_ground(delta)

```gdscript
func _move_ground(delta: float) -> void:
    navigation_agent.target_position = TARGET_POSITION

    if navigation_agent.is_navigation_finished():
        _is_attacking = true
        _attack_timer = 0.0
        return

    var next_pos: Vector3 = navigation_agent.get_next_path_position()
    var direction: Vector3 = (next_pos - global_position).normalized()
    velocity = direction * _enemy_data.move_speed
    move_and_slide()

    # Backup arrival check
    if global_position.distance_to(TARGET_POSITION) <= _enemy_data.attack_range:
        _is_attacking = true
        _attack_timer = 0.0
```

### _move_flying(delta)

```gdscript
func _move_flying(delta: float) -> void:
    var fly_target: Vector3 = Vector3(TARGET_POSITION.x, FLYING_HEIGHT, TARGET_POSITION.z)
    var direction: Vector3 = (fly_target - global_position).normalized()
    velocity = direction * _enemy_data.move_speed
    move_and_slide()

    var horizontal_dist: float = Vector2(
        global_position.x - TARGET_POSITION.x,
        global_position.z - TARGET_POSITION.z
    ).length()
    if horizontal_dist <= _enemy_data.attack_range:
        _is_attacking = true
        _attack_timer = 0.0
```

### _attack_tower_melee(delta)

```gdscript
func _attack_tower_melee(delta: float) -> void:
    _attack_timer -= delta
    if _attack_timer <= 0.0:
        _attack_timer = _enemy_data.attack_cooldown
        if is_instance_valid(_tower):
            _tower.take_damage(_enemy_data.damage)
```

### _attack_tower_ranged(delta)

```gdscript
func _attack_tower_ranged(delta: float) -> void:
    _attack_timer -= delta
    if _attack_timer <= 0.0:
        _attack_timer = _enemy_data.attack_cooldown
        if is_instance_valid(_tower):
            # DEVIATION: Orc Archer fires as instant hit, not visible projectile.
            # Avoids implementing enemy-to-tower projectile system in MVP.
            _tower.take_damage(_enemy_data.damage)
```

### take_damage(amount, damage_type)

```gdscript
func take_damage(amount: float, damage_type: Types.DamageType) -> void:
    if damage_type in _enemy_data.damage_immunities:
        return
    health_component.take_damage(amount, damage_type)
```

### _on_health_depleted()

```gdscript
func _on_health_depleted() -> void:
    SignalBus.enemy_killed.emit(
        _enemy_data.enemy_type,
        global_position,
        _enemy_data.gold_reward
    )
    remove_from_group("enemies")
    queue_free()
```

---

## 8.7 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **Flying enemy ignores navmesh** | _move_flying() uses Vector3 steering. NavigationAgent3D present but unused. |
| **Ranged enemy stops at range** | _move_ground() detects distance <= attack_range, sets _is_attacking. |
| **Tower destroyed while enemies attacking** | is_instance_valid(_tower) check prevents crash. |
| **Dynamic navmesh rebaking** | NOT in MVP. Enemies walk through building positions. |
| **Goblin Firebug fire immunity** | take_damage() checks damage_immunities before HealthComponent. |
| **Plague Zombie poison immunity** | Same mechanism. |
| **Bat Swarm horizontal arrival** | Uses Vector2 horizontal distance check ignoring Y. |
| **Enemy spawned inside tower** | NavigationAgent3D routes around. move_and_slide() collision pushes out. |
| **Orc Archer instant hit (MVP deviation)** | No visible projectile. Damage applied directly to tower. |

---

## 8.8 GdUnit4 TEST SPECIFICATIONS

File: res://tests/test_enemy_base.gd

```gdscript
class_name TestEnemyBase
extends GdUnitTestSuite
```

```
test_initialize_sets_hp_from_data
test_ground_enemy_moves_toward_tower
test_ground_enemy_stops_at_attack_range
test_flying_enemy_moves_at_flying_height
test_flying_enemy_straight_line_to_tower
test_melee_enemy_deals_damage_to_tower
test_ranged_enemy_deals_instant_damage_mvp
test_attack_respects_cooldown
test_death_emits_enemy_killed_signal
test_death_removes_from_group
test_goblin_firebug_immune_to_fire
test_plague_zombie_immune_to_poison
test_goblin_firebug_takes_physical_normally
test_non_immune_enemy_takes_all_types
test_flying_arrival_uses_horizontal_distance
test_ground_velocity_equals_move_speed
```

(Full Arrange-Act-Assert for each test specified in section 8.8 of Part 2 enemy tests.
These are the same test names — EnemyBase tests live in one file across Parts 2 and 3.)

---


# ═══════════════════════════════════════════════════════════════════
# SYSTEM 9 — SPELL AND MANA SYSTEM
# File: res://scripts/spell_manager.gd
# Scene node: Main > Managers > SpellManager (Node)
# ═══════════════════════════════════════════════════════════════════

## 9.1 PURPOSE

SpellManager owns Sybil's mana pool and spell cooldowns. In MVP, there is one spell:
Shockwave. SpellManager validates cast attempts (mana check + cooldown check),
applies the spell effect, deducts mana, starts the cooldown, and emits signals.

SpellManager regenerates mana over time in _physics_process, respecting
Engine.time_scale automatically.

---

## 9.2 CLASS VARIABLES

```gdscript
class_name SpellManager
extends Node

## Maximum mana pool.
@export var max_mana: int = 100

## Mana regenerated per second (game time, scales with Engine.time_scale).
@export var mana_regen_rate: float = 5.0

## Spell data resources (1 in MVP: shockwave).
@export var spell_registry: Array[SpellData] = []

var _current_mana: float = 0.0
var _cooldown_remaining: Dictionary = {}
var _mana_draught_pending: bool = false
```

---

## 9.3 SIGNALS EMITTED (via SignalBus)

| Signal          | Payload                           | When                                     |
|-----------------|-----------------------------------|------------------------------------------|
| `spell_cast`    | `spell_id: String`                | After successful cast                     |
| `spell_ready`   | `spell_id: String`                | Cooldown reaches 0                        |
| `mana_changed`  | `current_mana: int, max_mana: int`| Every frame mana changes (regen or cast)  |

## 9.4 SIGNALS CONSUMED

None. Called directly by InputManager or SimBot.

---

## 9.5 METHOD SIGNATURES

```gdscript
func cast_spell(spell_id: String) -> bool
func get_current_mana() -> int
func get_max_mana() -> int
func get_cooldown_remaining(spell_id: String) -> float
func is_spell_ready(spell_id: String) -> bool
func set_mana_to_full() -> void
func set_mana_draught_pending() -> void
func reset_for_new_mission() -> void
func reset_to_defaults() -> void

func _get_spell_data(spell_id: String) -> SpellData
func _apply_spell_effect(spell_data: SpellData) -> void
func _apply_shockwave(spell_data: SpellData) -> void
```

---

## 9.6 PSEUDOCODE

### _ready()

```gdscript
func _ready() -> void:
    for spell_data: SpellData in spell_registry:
        _cooldown_remaining[spell_data.spell_id] = 0.0
```

### _physics_process(delta)

```gdscript
func _physics_process(delta: float) -> void:
    # Mana Regeneration
    var old_mana: int = int(_current_mana)
    if _current_mana < float(max_mana):
        _current_mana = minf(_current_mana + mana_regen_rate * delta, float(max_mana))
        var new_mana: int = int(_current_mana)
        if new_mana != old_mana:
            SignalBus.mana_changed.emit(new_mana, max_mana)

    # Cooldown Tick
    for spell_id: String in _cooldown_remaining:
        if _cooldown_remaining[spell_id] > 0.0:
            _cooldown_remaining[spell_id] -= delta
            if _cooldown_remaining[spell_id] <= 0.0:
                _cooldown_remaining[spell_id] = 0.0
                SignalBus.spell_ready.emit(spell_id)
```

### cast_spell(spell_id)

```gdscript
func cast_spell(spell_id: String) -> bool:
    var spell_data: SpellData = _get_spell_data(spell_id)
    if spell_data == null:
        push_warning("cast_spell: unknown spell_id '%s'" % spell_id)
        return false

    if int(_current_mana) < spell_data.mana_cost:
        return false

    if _cooldown_remaining.get(spell_id, 0.0) > 0.0:
        return false

    # CAST
    _current_mana -= float(spell_data.mana_cost)
    SignalBus.mana_changed.emit(int(_current_mana), max_mana)

    _cooldown_remaining[spell_id] = spell_data.cooldown

    _apply_spell_effect(spell_data)
    SignalBus.spell_cast.emit(spell_id)
    return true
```

### _apply_shockwave(spell_data)

```gdscript
func _apply_shockwave(spell_data: SpellData) -> void:
    for node: Node in get_tree().get_nodes_in_group("enemies"):
        var enemy: EnemyBase = node as EnemyBase
        if enemy == null or not is_instance_valid(enemy):
            continue

        # Skip flying if spell doesn't hit air
        if not spell_data.hits_flying and enemy.get_enemy_data().is_flying:
            continue

        var final_damage: float = DamageCalculator.calculate_damage(
            spell_data.damage,
            spell_data.damage_type,
            enemy.get_enemy_data().armor_type
        )
        # Checks damage_immunities inside enemy.take_damage (Part 1 section 3.8)
        enemy.take_damage(final_damage, spell_data.damage_type)
```

### _apply_spell_effect(spell_data)

```gdscript
func _apply_spell_effect(spell_data: SpellData) -> void:
    match spell_data.spell_id:
        "shockwave":
            _apply_shockwave(spell_data)
        _:
            push_warning("Unknown spell effect for '%s'" % spell_data.spell_id)
```

### Helpers

```gdscript
func _get_spell_data(spell_id: String) -> SpellData:
    for spell_data: SpellData in spell_registry:
        if spell_data.spell_id == spell_id:
            return spell_data
    return null

func get_current_mana() -> int:
    return int(_current_mana)

func get_max_mana() -> int:
    return max_mana

func get_cooldown_remaining(spell_id: String) -> float:
    return _cooldown_remaining.get(spell_id, 0.0)

func is_spell_ready(spell_id: String) -> bool:
    var spell_data: SpellData = _get_spell_data(spell_id)
    if spell_data == null:
        return false
    return int(_current_mana) >= spell_data.mana_cost and get_cooldown_remaining(spell_id) <= 0.0

func set_mana_to_full() -> void:
    _current_mana = float(max_mana)
    SignalBus.mana_changed.emit(max_mana, max_mana)

func set_mana_draught_pending() -> void:
    _mana_draught_pending = true

func reset_for_new_mission() -> void:
    if _mana_draught_pending:
        _current_mana = float(max_mana)
        _mana_draught_pending = false
    else:
        _current_mana = 0.0
    for spell_id: String in _cooldown_remaining:
        _cooldown_remaining[spell_id] = 0.0
    SignalBus.mana_changed.emit(int(_current_mana), max_mana)

func reset_to_defaults() -> void:
    _current_mana = 0.0
    _mana_draught_pending = false
    for spell_id: String in _cooldown_remaining:
        _cooldown_remaining[spell_id] = 0.0
    SignalBus.mana_changed.emit(0, max_mana)
```

---

## 9.7 EDGE CASES

| Edge Case | Handling |
|-----------|----------|
| **Cast with insufficient mana** | Returns false. No deduction, no cooldown, no effect. |
| **Cast while on cooldown** | Returns false. |
| **Mana regen exceeds max** | Clamped by minf(). Cannot exceed max_mana. |
| **Mana signal only on integer change** | Internal float, signal only when int() changes. |
| **Shockwave hits 0 enemies** | No damage dealt. Mana consumed, cooldown starts. |
| **Shockwave skips flying** | SpellData.hits_flying = false. Bat Swarm skipped. |
| **Mana Draught pending** | reset_for_new_mission starts at full mana. Flag cleared. |
| **Build mode slows mana regen** | delta is scaled. Correct behavior. |
| **Unknown spell_id** | Returns false with push_warning. |

---

## 9.8 GdUnit4 TEST SPECIFICATIONS

File: res://tests/test_spell_manager.gd

```
test_mana_starts_at_zero
test_mana_regens_over_time
test_mana_regen_caps_at_max
test_mana_regen_emits_signal_on_integer_change
test_mana_regen_does_not_emit_when_at_max
test_mana_regen_with_fractional_accumulation
test_cast_spell_sufficient_mana_and_ready_succeeds
test_cast_spell_insufficient_mana_fails
test_cast_spell_on_cooldown_fails
test_cast_spell_unknown_id_fails
test_cast_deducts_mana
test_cast_starts_cooldown
test_cast_emits_spell_cast_signal
test_cast_emits_mana_changed_signal
test_cooldown_decrements_over_time
test_cooldown_reaching_zero_emits_spell_ready
test_cooldown_does_not_go_negative
test_is_spell_ready_after_cooldown
test_is_spell_ready_during_cooldown
test_is_spell_ready_insufficient_mana_after_cooldown
test_shockwave_damages_all_ground_enemies
test_shockwave_skips_flying_enemies
test_shockwave_applies_damage_matrix
test_shockwave_respects_immunity
test_shockwave_on_empty_battlefield
test_mana_draught_pending_starts_full
test_mana_draught_clears_flag_after_use
test_without_draught_mission_starts_at_zero
test_reset_for_new_mission_clears_cooldowns
test_reset_to_defaults_clears_everything
```

(Full Arrange-Act-Assert for each test follows the same format as Systems 1-6.
Each test name above has the structure detailed in the pseudocode section.)

---


# ═══════════════════════════════════════════════════════════════════
# SYSTEM 10 — SIMBOT API CONTRACT
# File: res://scripts/sim_bot.gd
# Scene node: injected into Main > Managers (not in default scene tree)
# ═══════════════════════════════════════════════════════════════════

## 10.1 PURPOSE

SimBot is a headless automation agent that drives the entire game loop via public method
calls. It replaces InputManager — no mouse, no keyboard, no UI interaction.
In MVP, SimBot is a stub with no strategy logic. Its purpose is to PROVE the API contract:
every manager's public methods are callable without UI nodes present.

---

## 10.2 COMPLETE API REGISTRY

### GameManager (autoload)

| Method | Return | Description |
|--------|--------|-------------|
| `start_new_game()` | `void` | Resets all state, begins mission 1 |
| `start_next_mission()` | `void` | Increments mission, resets per-mission state |
| `enter_build_mode()` | `void` | Sets Engine.time_scale = 0.1, BUILD_MODE |
| `exit_build_mode()` | `void` | Restores time_scale, returns to previous state |
| `get_game_state()` | `Types.GameState` | Current game state |
| `get_current_mission()` | `int` | 1-5 (0 before start) |
| `get_current_wave()` | `int` | 0-10 |

### EconomyManager (autoload)

| Method | Return | Description |
|--------|--------|-------------|
| `add_gold(amount: int)` | `void` | Add gold, emit signal |
| `spend_gold(amount: int)` | `bool` | Deduct gold if sufficient |
| `add_building_material(amount: int)` | `void` | Add material |
| `spend_building_material(amount: int)` | `bool` | Deduct if sufficient |
| `add_research_material(amount: int)` | `void` | Add research |
| `spend_research_material(amount: int)` | `bool` | Deduct if sufficient |
| `can_afford(gold_cost: int, material_cost: int)` | `bool` | Check gold + material |
| `can_afford_research(cost: int)` | `bool` | Check research material |
| `award_post_mission_rewards()` | `void` | Add flat post-mission amounts |
| `get_gold()` | `int` | Current gold |
| `get_building_material()` | `int` | Current building material |
| `get_research_material()` | `int` | Current research material |
| `reset_to_defaults()` | `void` | Reset to starting values |

### DamageCalculator (autoload)

| Method | Return | Description |
|--------|--------|-------------|
| `calculate_damage(base: float, dmg_type: DamageType, armor: ArmorType)` | `float` | Apply matrix multiplier |
| `get_multiplier(dmg_type: DamageType, armor: ArmorType)` | `float` | Raw multiplier |
| `is_immune(dmg_type: DamageType, armor: ArmorType)` | `bool` | True if multiplier == 0.0 |

### WaveManager (scene node)

| Method | Return | Description |
|--------|--------|-------------|
| `start_wave_sequence()` | `void` | Begin countdown for wave 1 |
| `force_spawn_wave(wave_number: int)` | `void` | Spawn immediately (bot use) |
| `get_living_enemy_count()` | `int` | Enemies in "enemies" group |
| `get_current_wave_number()` | `int` | 0-10 |
| `is_wave_active()` | `bool` | True if wave spawned, enemies alive |
| `is_counting_down()` | `bool` | True during countdown |
| `get_countdown_remaining()` | `float` | Seconds until next wave |
| `reset_for_new_mission()` | `void` | Clear all state + enemies |
| `clear_all_enemies()` | `void` | Remove all enemy instances |

### SpellManager (scene node)

| Method | Return | Description |
|--------|--------|-------------|
| `cast_spell(spell_id: String)` | `bool` | Cast if mana + cooldown allow |
| `get_current_mana()` | `int` | Current mana (truncated) |
| `get_max_mana()` | `int` | Max mana cap |
| `get_cooldown_remaining(spell_id: String)` | `float` | Seconds left on cooldown |
| `is_spell_ready(spell_id: String)` | `bool` | Mana sufficient AND cooldown 0 |
| `set_mana_to_full()` | `void` | Instant full mana |
| `set_mana_draught_pending()` | `void` | Flag for next mission start |
| `reset_for_new_mission()` | `void` | Reset mana + cooldowns |
| `reset_to_defaults()` | `void` | Full reset including flags |

### HexGrid (scene node)

| Method | Return | Description |
|--------|--------|-------------|
| `place_building(slot: int, type: BuildingType)` | `bool` | Place if valid + affordable |
| `sell_building(slot: int)` | `bool` | Sell with full refund |
| `upgrade_building(slot: int)` | `bool` | Upgrade if affordable |
| `get_slot_data(slot: int)` | `Dictionary` | Slot info for UI/bot |
| `get_all_occupied_slots()` | `Array[int]` | Indices with buildings |
| `get_empty_slots()` | `Array[int]` | Indices without buildings |
| `clear_all_buildings()` | `void` | Remove all buildings |
| `is_building_available(type: BuildingType)` | `bool` | Unlocked check |
| `get_building_data(type: BuildingType)` | `BuildingData` | Data resource lookup |

### ResearchManager (scene node)

| Method | Return | Description |
|--------|--------|-------------|
| `unlock_node(node_id: String)` | `bool` | Unlock if affordable + prereqs met |
| `is_unlocked(node_id: String)` | `bool` | Check unlock status |
| `get_available_nodes()` | `Array[ResearchNodeData]` | Nodes that can be unlocked now |
| `reset_to_defaults()` | `void` | Clear all unlocks |

### ShopManager (scene node)

| Method | Return | Description |
|--------|--------|-------------|
| `purchase_item(item_id: String)` | `bool` | Buy if affordable, apply effect |
| `get_available_items()` | `Array[ShopItemData]` | All shop items |
| `can_purchase(item_id: String)` | `bool` | Affordability check |

### Tower (scene node)

| Method | Return | Description |
|--------|--------|-------------|
| `fire_crossbow(target_pos: Vector3)` | `void` | Fire crossbow projectile |
| `fire_rapid_missile(target_pos: Vector3)` | `void` | Fire rapid missile burst |
| `take_damage(amount: int)` | `void` | Apply damage to tower |
| `repair_to_full()` | `void` | Restore HP to max |
| `get_current_hp()` | `int` | Current tower HP |
| `get_max_hp()` | `int` | Max tower HP |
| `is_weapon_ready(slot: WeaponSlot)` | `bool` | Reload complete check |

### Arnulf (scene node — observe only)

| Method | Return | Description |
|--------|--------|-------------|
| `get_current_state()` | `Types.ArnulfState` | Current AI state |
| `get_current_hp()` | `int` | Current HP |
| `get_max_hp()` | `int` | Max HP |
| `reset_for_new_mission()` | `void` | Full HP, IDLE, home position |

---

## 10.3 SIGNALBUS SIGNALS THE BOT OBSERVES

```
# Game Flow
game_state_changed(old_state: Types.GameState, new_state: Types.GameState)
mission_started(mission_number: int)
mission_won(mission_number: int)
mission_failed(mission_number: int)

# Wave Flow
wave_countdown_started(wave_number: int, seconds_remaining: float)
wave_started(wave_number: int, enemy_count: int)
wave_cleared(wave_number: int)
all_waves_cleared()

# Economy
resource_changed(resource_type: Types.ResourceType, new_amount: int)

# Combat Observation
enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
tower_damaged(current_hp: int, max_hp: int)
tower_destroyed()
arnulf_state_changed(new_state: Types.ArnulfState)
arnulf_incapacitated()
arnulf_recovered()

# Build Feedback
building_placed(slot_index: int, building_type: Types.BuildingType)
building_sold(slot_index: int, building_type: Types.BuildingType)
building_upgraded(slot_index: int, building_type: Types.BuildingType)

# Spell Feedback
spell_cast(spell_id: String)
spell_ready(spell_id: String)
mana_changed(current_mana: int, max_mana: int)
```

### GameManager Note

GameManager is a simple sequential state machine (MAIN_MENU -> MISSION_BRIEFING ->
COMBAT -> BETWEEN_MISSIONS -> ... -> GAME_WON). It does not warrant full pseudocode.
SimBot interacts with it via:
- start_new_game() to begin
- Observing mission_won / mission_failed / game_state_changed
- start_next_mission() during BETWEEN_MISSIONS
- enter_build_mode() / exit_build_mode() during COMBAT

GameManager internally calls WaveManager.start_wave_sequence() on COMBAT entry,
EconomyManager.award_post_mission_rewards() on mission win,
EconomyManager.reset_to_defaults() on new game. These are not bot-exposed.

---

## 10.4 SCENE-TREE DEPENDENCIES

| Manager         | Dependency                             | Required For                |
|-----------------|----------------------------------------|-----------------------------|
| WaveManager     | EnemyContainer, SpawnPoints            | Spawning enemies            |
| HexGrid         | BuildingContainer, ResearchManager     | Placing buildings           |
| Tower           | HealthComponent (child)                | HP tracking                 |
| Arnulf          | HealthComponent, NavigationAgent3D,    | State machine + pathfinding |
|                 | DetectionArea, AttackArea              |                             |
| BuildingBase    | ProjectileContainer                    | Firing projectiles          |
| EnemyBase       | NavigationAgent3D, Tower               | Pathfinding + attacking     |

Autoloads (EconomyManager, DamageCalculator, GameManager, SignalBus) have zero
scene-tree dependencies and can be tested completely in isolation.

---

## 10.5 GdUnit4 TEST SPECIFICATIONS — API CALLABILITY

File: res://tests/test_simulation_api.gd

```gdscript
class_name TestSimulationAPI
extends GdUnitTestSuite
```

### Test: Autoload APIs (no scene required)

```
test_economy_manager_add_gold_callable
    Act:     EconomyManager.reset_to_defaults(). EconomyManager.add_gold(10)
    Assert:  No error. get_gold() == 110.

test_economy_manager_spend_gold_callable
    Act:     EconomyManager.spend_gold(50)
    Assert:  Returns bool. No error.

test_economy_manager_can_afford_callable
    Act:     EconomyManager.can_afford(10, 5)
    Assert:  Returns bool.

test_economy_manager_can_afford_research_callable
    Act:     EconomyManager.can_afford_research(2)
    Assert:  Returns bool.

test_economy_manager_award_post_mission_callable
    Act:     EconomyManager.award_post_mission_rewards()
    Assert:  No error. Resources increased.

test_economy_manager_reset_callable
    Act:     EconomyManager.reset_to_defaults()
    Assert:  Resources at starting values.

test_damage_calculator_calculate_damage_callable
    Act:     DamageCalculator.calculate_damage(100.0, PHYSICAL, UNARMORED)
    Assert:  result == 100.0.

test_damage_calculator_get_multiplier_callable
    Act:     DamageCalculator.get_multiplier(FIRE, UNDEAD)
    Assert:  result == 2.0.

test_damage_calculator_is_immune_callable
    Act:     DamageCalculator.is_immune(POISON, UNDEAD)
    Assert:  result == true.

test_game_manager_get_state_callable
    Act:     GameManager.get_game_state()
    Assert:  Returns valid GameState.

test_game_manager_get_mission_callable
    Act:     GameManager.get_current_mission()
    Assert:  Returns int.
```

### Test: Scene-Bound APIs (minimal mock scene)

```
test_wave_manager_methods_callable_with_mock_scene
    Arrange: Create Node3D EnemyContainer + SpawnPoints with 1 Marker3D.
             Create WaveManager with 6 EnemyData entries.
    Act:     Call: start_wave_sequence(), get_living_enemy_count(),
             get_current_wave_number(), is_wave_active(), is_counting_down(),
             get_countdown_remaining(), reset_for_new_mission()
    Assert:  All return without error.

test_spell_manager_methods_callable_without_ui
    Arrange: Create SpellManager with 1 SpellData (shockwave).
    Act:     Call: cast_spell("shockwave"), get_current_mana(), get_max_mana(),
             get_cooldown_remaining("shockwave"), is_spell_ready("shockwave"),
             set_mana_to_full(), reset_for_new_mission(), reset_to_defaults()
    Assert:  All return without error. No UI dependency.

test_hex_grid_methods_callable_with_mock_scene
    Arrange: Create BuildingContainer + mock ResearchManager. HexGrid with registry.
    Act:     Call: get_empty_slots(), get_all_occupied_slots(),
             place_building(0, ARROW_TOWER), get_slot_data(0),
             is_building_available(ARROW_TOWER), clear_all_buildings()
    Assert:  All return without error.

test_tower_methods_callable_with_health_component
    Arrange: Create Tower with HealthComponent child.
    Act:     Call: get_current_hp(), get_max_hp(), take_damage(10),
             repair_to_full(), is_weapon_ready(CROSSBOW)
    Assert:  All return without error.

test_arnulf_methods_callable_with_components
    Arrange: Create Arnulf with HealthComponent, NavigationAgent3D,
             DetectionArea, AttackArea.
    Act:     Call: get_current_state(), get_current_hp(), get_max_hp(),
             reset_for_new_mission()
    Assert:  All return without error.

test_no_ui_node_in_test_scene
    Assert:  No CanvasLayer, no Control in the test scene tree.
             Proves API is UI-independent.
```

### Test: Signal Connectivity

```
test_simbot_can_connect_to_all_observation_signals
    Arrange: Create callable for each signal in section 10.3.
    Act:     Connect to each signal on SignalBus.
    Assert:  All connections succeed. No "signal not found" error.

test_simbot_receives_enemy_killed_signal
    Act:     Emit SignalBus.enemy_killed(ORC_GRUNT, Vector3.ZERO, 10)
    Assert:  Handler invoked.

test_simbot_receives_wave_cleared_signal
    Act:     Emit SignalBus.wave_cleared(1)
    Assert:  Handler invoked.

test_simbot_receives_game_state_changed_signal
    Act:     Emit SignalBus.game_state_changed(MAIN_MENU, COMBAT)
    Assert:  Handler invoked with both state values.
```

### Test: Full API Loop (smoke test)

```
test_simbot_can_drive_minimal_game_loop
    Arrange: Minimal scene: Tower + WaveManager + SpawnPoints +
             EnemyContainer + HexGrid + BuildingContainer + SpellManager.
             No UI nodes.
    Act:
        1. GameManager.start_new_game()
        2. WaveManager.force_spawn_wave(1)
        3. Assert get_living_enemy_count() == 6
        4. EconomyManager.get_gold() returns starting gold
        5. SpellManager.set_mana_to_full()
        6. SpellManager.cast_spell("shockwave") returns true
        7. HexGrid.get_empty_slots() returns 24
    Assert:  Entire sequence completes without error.
             Game loop is drivable headlessly.
```

---

# END OF SYSTEMS.md — Part 3 of 3
