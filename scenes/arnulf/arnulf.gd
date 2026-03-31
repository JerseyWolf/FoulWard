## Arnulf — AI-controlled melee companion with IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING state machine.
# arnulf.gd
# Arnulf is the fully AI-controlled melee companion in FOUL WARD.
# He patrols near the tower, chases the closest enemy to TOWER_CENTER,
# attacks at melee range, and revives himself after being downed.
#
# State machine: IDLE → CHASE → ATTACK → DOWNED → RECOVERING → IDLE
# All cross-system communication via SignalBus (never direct node refs).
#
# Credit: Godot Engine Documentation — CharacterBody3D, NavigationAgent3D
#   https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
#   https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
#   License: CC BY 3.0 | Adapted by: Foul Ward team
#   Adapted: move_and_slide() loop, get_next_path_position() per-frame update,
#            NavigationAgent3D target_position update pattern.
#
# Credit: Godot Engine Documentation — Area3D.get_overlapping_bodies()
#   https://docs.godotengine.org/en/stable/classes/class_area3d.html
#   License: CC BY 3.0 | Adapted by: Foul Ward team
#   Adapted: snapshot-based closest-body search; is_instance_valid guard.
#
# Credit: Foul Ward SYSTEMS_part3.md §7 (Arnulf State Machine spec)
#   Internal project document — Foul Ward team.

class_name Arnulf
extends CharacterBody3D

const _RiggedVisualWiringScript: GDScript = preload("res://scripts/art/rigged_visual_wiring.gd")

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

## Maximum hit points. After downed, `HealthComponent.reset_to_max()` restores full HP.
@export var max_hp: int = 200

## Movement speed in units per second.
@export var move_speed: float = 5.0

## Physical damage dealt per attack.
@export var attack_damage: float = 25.0

## Seconds between attacks.
@export var attack_cooldown: float = 1.0

## Max distance from tower for an enemy to be considered for melee chase (enemy position vs tower).
@export var patrol_radius: float = 55.0

## Arnulf will not move farther than this from the tower center while chasing (leash).
@export var max_distance_from_tower: float = 16.0

## Seconds at 0 HP (downed) before standing up with full HP. Visual unchanged; body has no collision.
@export var recovery_time: float = 5.0

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------

## Tower center — used for target-selection distance comparisons.
## Arnulf always chases the enemy closest to the TOWER, not closest to himself.
const TOWER_CENTER: Vector3 = Vector3.ZERO

## Where Arnulf stands when idle (adjacent to tower base).
const HOME_POSITION: Vector3 = Vector3(2.0, 0.0, 0.0)

## Same issue as EnemyBase: nav next waypoint can match position → normalized() is zero.
const _MIN_NAV_STEP_SQ: float = 0.0004

## Stable id for generic ally signals (SignalBus.ally_*).
const ALLY_ID_ARNULF: String = "arnulf"

## Stop moving into the target beyond this XZ distance — stand and attack instead of pushing.
const ARNULF_MELEE_STOP_DISTANCE: float = 2.2
## If overlap fails (physics jitter), still enter ATTACK when this close on XZ.
const ARNULF_MELEE_SNAP_ATTACK_DISTANCE: float = 1.35

## Scene default: layer bit 2 (value 4) for CharacterBody3D.
const ARNULF_COLLISION_LAYER_BITS: int = 4

# Assign placeholder art resources via convention-based pipeline.
# ---------------------------------------------------------------------------
# STATE
# ---------------------------------------------------------------------------

var _current_state: Types.ArnulfState = Types.ArnulfState.IDLE
var _chase_target: EnemyBase = null
var _attack_timer: float = 0.0
var _recovery_timer: float = 0.0

# POST-MVP: _kill_counter drives Frenzy mode when it reaches a threshold.
# For MVP: counter increments and resets on mission start; no activation logic.
var _kill_counter: int = 0

# ---------------------------------------------------------------------------
# NODE REFERENCES
# ---------------------------------------------------------------------------

@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var _arnulf_collision: CollisionShape3D = get_node_or_null("ArnulfCollision") as CollisionShape3D
@onready var _visual_slot: Node3D = get_node_or_null("ArnulfVisual")

var _arnulf_anim_player: AnimationPlayer = null
var _arnulf_locomotion_clip: StringName = &""

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	print("[Arnulf] _ready: hp=%d move_speed=%.1f patrol_radius=%.0f" % [max_hp, move_speed, patrol_radius])
	health_component.max_hp = max_hp
	health_component.reset_to_max()
	health_component.health_depleted.connect(_on_health_depleted)

	# Credit: Godot Engine Documentation — NavigationAgent3D
	#   https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
	#   Adapted: path_desired_distance and target_desired_distance tuning values.
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 1.5
	navigation_agent.avoidance_enabled = true

	# ASSUMPTION: DetectionArea.collision_mask = 2 (Enemies layer) set in scene.
	# ASSUMPTION: AttackArea.collision_mask = 2 (Enemies layer) set in scene.
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.game_state_changed.connect(_on_game_state_changed)

	# TODO(ART): Add attack/death clips; drive from ArnulfState when production assets land.
	if _visual_slot != null:
		_arnulf_anim_player = RiggedVisualWiring.mount_glb_scene(
			_visual_slot, RiggedVisualWiring.ALLY_ARNULF_GLB
		)
		if _arnulf_anim_player == null:
			RiggedVisualWiring.clear_visual_slot(_visual_slot)
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = ArtPlaceholderHelper.get_ally_mesh("arnulf")
			mi.material_override = ArtPlaceholderHelper.get_faction_material("allies")
			_visual_slot.add_child(mi)

	_transition_to_state(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# PHYSICS PROCESS — State Dispatch
# ---------------------------------------------------------------------------

# Credit: Foul Ward SYSTEMS_part3.md §7.6 (_physics_process dispatch table)
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
#   All delta-based timers respect Engine.time_scale automatically.

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
			# PATROL is a post-MVP stub — treat as IDLE in MVP.
			_process_idle(delta)

	_sync_arnulf_locomotion_animation()

# ---------------------------------------------------------------------------
# STATE HANDLERS
# ---------------------------------------------------------------------------

func _process_idle(_delta: float) -> void:
	var dist_to_home: float = global_position.distance_to(HOME_POSITION)
	if dist_to_home > 1.0:
		navigation_agent.target_position = HOME_POSITION
		var next_pos: Vector3 = navigation_agent.get_next_path_position()
		var to_next: Vector3 = next_pos - global_position
		if to_next.length_squared() < _MIN_NAV_STEP_SQ:
			to_next = HOME_POSITION - global_position
		var direction: Vector3 = to_next.normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO

	# Poll for enemies already inside the detection zone when returning home.
	var target: EnemyBase = _find_closest_enemy_to_tower()
	if target != null:
		_chase_target = target
		_transition_to_state(Types.ArnulfState.CHASE)


func _process_chase(_delta: float) -> void:
	# Credit: is_instance_valid() guard for freed nodes mid-chase.
	if _chase_target == null or not is_instance_valid(_chase_target):
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target == null:
			_transition_to_state(Types.ArnulfState.IDLE)
			return

	if global_position.distance_to(TOWER_CENTER) > max_distance_from_tower:
		_chase_target = null
		_transition_to_state(Types.ArnulfState.IDLE)
		return

	var target_dist_from_tower: float = \
		_chase_target.global_position.distance_to(TOWER_CENTER)
	if target_dist_from_tower > patrol_radius:
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target == null:
			_transition_to_state(Types.ArnulfState.IDLE)
			return

	var to_target_flat: Vector3 = _chase_target.global_position - global_position
	to_target_flat.y = 0.0
	var dist_xz: float = to_target_flat.length()
	if dist_xz <= ARNULF_MELEE_STOP_DISTANCE:
		velocity = Vector3.ZERO
		move_and_slide()
		if attack_area.overlaps_body(_chase_target) or dist_xz <= ARNULF_MELEE_SNAP_ATTACK_DISTANCE:
			_transition_to_state(Types.ArnulfState.ATTACK)
		return

	# Update NavigationAgent3D EVERY frame — the enemy is moving.
	# Credit: Godot Docs NavigationAgent3D per-frame target_position update pattern.
	navigation_agent.target_position = _chase_target.global_position
	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var to_next: Vector3 = next_pos - global_position
	if to_next.length_squared() < _MIN_NAV_STEP_SQ:
		to_next = _chase_target.global_position - global_position
	var direction: Vector3 = to_next.normalized()
	velocity = direction * move_speed
	move_and_slide()
	# ATTACK transition is also handled by AttackArea.body_entered signal.


func _process_attack(delta: float) -> void:
	if _chase_target == null or not is_instance_valid(_chase_target):
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target != null:
			_transition_to_state(Types.ArnulfState.CHASE)
		else:
			_transition_to_state(Types.ArnulfState.IDLE)
		return

	velocity = Vector3.ZERO

	# First attack fires immediately (_attack_timer starts at 0 on ATTACK entry).
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		var final_damage: float = DamageCalculator.calculate_damage(
			attack_damage,
			Types.DamageType.PHYSICAL,
			_chase_target.get_enemy_data().armor_type
		)
		_chase_target.take_damage(final_damage, Types.DamageType.PHYSICAL)


func _process_downed(delta: float) -> void:
	velocity = Vector3.ZERO
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		_transition_to_state(Types.ArnulfState.RECOVERING)


func _process_recovering() -> void:
	_restore_arnulf_body_after_downed()
	health_component.reset_to_max()
	_clear_all_enemy_arnulf_aggro()
	SignalBus.arnulf_recovered.emit()
	# DEVIATION: generic ally_recovered for ally framework integration.
	SignalBus.ally_recovered.emit(ALLY_ID_ARNULF)
	_transition_to_state(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# STATE TRANSITION
# ---------------------------------------------------------------------------

func _transition_to_state(new_state: Types.ArnulfState) -> void:
	print("[Arnulf] state → %s  (target=%s)" % [
		Types.ArnulfState.keys()[new_state],
		_chase_target.get_enemy_data().display_name if is_instance_valid(_chase_target) and _chase_target != null else "none"
	])
	_current_state = new_state

	match new_state:
		Types.ArnulfState.IDLE:
			_chase_target = null
			_attack_timer = 0.0
		Types.ArnulfState.CHASE:
			_attack_timer = 0.0
		Types.ArnulfState.ATTACK:
			_attack_timer = 0.0  # First hit fires immediately.
			if is_instance_valid(_chase_target):
				_chase_target.begin_arnulf_retaliation(self)
		Types.ArnulfState.DOWNED:
			_recovery_timer = recovery_time
			_chase_target = null
			velocity = Vector3.ZERO
			_disable_arnulf_body_for_downed()
			_clear_all_enemy_arnulf_aggro()
			SignalBus.arnulf_incapacitated.emit()
			# DEVIATION: generic ally_downed for ally framework integration.
			SignalBus.ally_downed.emit(ALLY_ID_ARNULF)
		Types.ArnulfState.RECOVERING:
			pass
		Types.ArnulfState.PATROL:
			pass  # Post-MVP stub.

	SignalBus.arnulf_state_changed.emit(new_state)


func _disable_arnulf_body_for_downed() -> void:
	if _arnulf_collision != null:
		_arnulf_collision.disabled = true
	collision_layer = 0


func _restore_arnulf_body_after_downed() -> void:
	if _arnulf_collision != null:
		_arnulf_collision.disabled = false
	collision_layer = ARNULF_COLLISION_LAYER_BITS


func _clear_all_enemy_arnulf_aggro() -> void:
	var st: SceneTree = get_tree()
	if st == null:
		return
	st.call_group("enemies", "clear_arnulf_retaliation")


func _sync_arnulf_locomotion_animation() -> void:
	if _arnulf_anim_player == null:
		return
	var horiz: float = 0.0
	if _current_state != Types.ArnulfState.DOWNED and _current_state != Types.ArnulfState.RECOVERING:
		horiz = Vector2(velocity.x, velocity.z).length()
	_arnulf_locomotion_clip = RiggedVisualWiring.update_locomotion_animation(
		_arnulf_anim_player, horiz, _arnulf_locomotion_clip
	)

# ---------------------------------------------------------------------------
# TARGET SELECTION
# ---------------------------------------------------------------------------

# Credit: Foul Ward SYSTEMS_part3.md §7.6 (_find_closest_enemy_to_tower)
# Credit: Godot Engine Documentation — Area3D.get_overlapping_bodies()
#   Selects the enemy closest to TOWER_CENTER from DetectionArea's overlap pool.
#   Flying enemies are excluded — Arnulf is a ground melee unit.

func _find_closest_enemy_to_tower() -> EnemyBase:
	var best_target: EnemyBase = null
	var best_distance: float = patrol_radius + 1.0

	for body: Node3D in detection_area.get_overlapping_bodies():
		var enemy: EnemyBase = body as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue
		if enemy.get_enemy_data().is_flying:
			continue
		if enemy.get_enemy_data().move_speed <= 0.001:
			continue

		var dist_to_tower: float = enemy.global_position.distance_to(TOWER_CENTER)
		if dist_to_tower > patrol_radius:
			continue

		if dist_to_tower < best_distance:
			best_distance = dist_to_tower
			best_target = enemy

	return best_target

# ---------------------------------------------------------------------------
# AREA3D SIGNAL HANDLERS
# ---------------------------------------------------------------------------

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _current_state == Types.ArnulfState.DOWNED:
		return
	if _current_state == Types.ArnulfState.RECOVERING:
		return

	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy.get_enemy_data().is_flying:
		return
	if enemy.get_enemy_data().move_speed <= 0.001:
		return

	if _current_state == Types.ArnulfState.IDLE:
		_chase_target = _find_closest_enemy_to_tower()
		# Same-frame manual tests / physics not stepped: overlap list can be empty even though
		# `body_entered` fired — fall back to the body that triggered this handler.
		if _chase_target == null:
			var dist_to_tower: float = enemy.global_position.distance_to(TOWER_CENTER)
			if dist_to_tower <= patrol_radius:
				_chase_target = enemy
		if _chase_target != null:
			_transition_to_state(Types.ArnulfState.CHASE)


func _on_attack_area_body_entered(body: Node3D) -> void:
	if _current_state != Types.ArnulfState.CHASE:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _chase_target:
		_transition_to_state(Types.ArnulfState.ATTACK)


func _on_attack_area_body_exited(body: Node3D) -> void:
	if _current_state != Types.ArnulfState.ATTACK:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _chase_target:
		_transition_to_state(Types.ArnulfState.CHASE)

# ---------------------------------------------------------------------------
# HEALTH COMPONENT SIGNAL HANDLER
# ---------------------------------------------------------------------------

func _on_health_depleted() -> void:
	_transition_to_state(Types.ArnulfState.DOWNED)

# ---------------------------------------------------------------------------
# SIGNALBUS HANDLERS
# ---------------------------------------------------------------------------

func _on_enemy_killed(
		_enemy_type: Types.EnemyType,
		_position: Vector3,
		_gold_reward: int
) -> void:
	# POST-MVP: increment drives Frenzy mode. MVP: count only.
	_kill_counter += 1


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	if new_state == Types.GameState.MISSION_BRIEFING:
		reset_for_new_mission()

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Returns Arnulf's current state enum value.
func get_current_state() -> Types.ArnulfState:
	return _current_state

## Returns current HP as reported by HealthComponent.
func get_current_hp() -> int:
	return health_component.get_current_hp()

## Returns maximum HP.
func get_max_hp() -> int:
	return health_component.get_max_hp()

## Resets Arnulf for a new mission: full HP, IDLE state, home position.
func reset_for_new_mission() -> void:
	health_component.max_hp = max_hp
	health_component.reset_to_max()
	_restore_arnulf_body_after_downed()
	_clear_all_enemy_arnulf_aggro()
	_kill_counter = 0
	_chase_target = null
	_attack_timer = 0.0
	_recovery_timer = 0.0
	velocity = Vector3.ZERO
	global_position = HOME_POSITION
	_transition_to_state(Types.ArnulfState.IDLE)
	# DEVIATION: Arnulf also broadcasts generic ally_spawned for ally systems.
	SignalBus.ally_spawned.emit(ALLY_ID_ARNULF, "")
	# POST-MVP: emit SignalBus.ally_killed(ALLY_ID_ARNULF) if a permanent-death path is added.

