## ally_base.gd
## Generic ally CharacterBody3D: navigate, acquire nearest enemy, melee/ranged direct damage.
## Mission death and campaign roster recovery are separate layers (CampaignManager — POST-MVP).

class_name AllyBase
extends CharacterBody3D

const _MIN_NAV_STEP_SQ: float = 0.0004

@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var ally_mesh: MeshInstance3D = $AllyMesh
@onready var _detection_shape: CollisionShape3D = $DetectionArea/DetectionShape
@onready var _attack_shape: CollisionShape3D = $AttackArea/AttackShape

var ally_data: Variant = null

enum AllyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DOWNED,
	RECOVERING,
}

var _state: AllyState = AllyState.IDLE
var _current_target: EnemyBase = null
var _attack_cooldown_remaining: float = 0.0


func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_body_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.75
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5


## Spec alias (Prompt 12); delegates to `initialize_ally_data`.
func initialize(p_ally_data: AllyData) -> void:
	initialize_ally_data(p_ally_data)


func initialize_ally_data(p_ally_data: Variant) -> void:
	ally_data = p_ally_data
	if ally_data == null:
		push_error("AllyBase.initialize_ally_data: null AllyData")
		return

	health_component.max_hp = int(ally_data.get("max_hp"))
	health_component.reset_to_max()
	_attack_cooldown_remaining = 0.0
	_state = AllyState.IDLE
	_current_target = null

	if not health_component.health_depleted.is_connected(_on_health_depleted):
		health_component.health_depleted.connect(_on_health_depleted)

	_apply_ally_data_to_shapes()
	_apply_debug_color_from_data()

	# DEVIATION: generic ally_spawned for campaign / UI integration.
	SignalBus.ally_spawned.emit(str(ally_data.get("ally_id")))


func _apply_ally_data_to_shapes() -> void:
	if ally_data == null:
		return
	var atk_range: float = float(ally_data.get("attack_range"))
	var detect_r: float = maxf(40.0, atk_range + 2.0)
	if _detection_shape != null and _detection_shape.shape is SphereShape3D:
		(_detection_shape.shape as SphereShape3D).radius = detect_r
	if _attack_shape != null and _attack_shape.shape is SphereShape3D:
		(_attack_shape.shape as SphereShape3D).radius = atk_range


func _apply_debug_color_from_data() -> void:
	if ally_data == null or ally_mesh == null:
		return
	var c: Variant = ally_data.get("debug_color")
	if c is Color and ally_mesh.material_override is StandardMaterial3D:
		(ally_mesh.material_override as StandardMaterial3D).albedo_color = c as Color


func _physics_process(delta: float) -> void:
	if ally_data == null:
		return
	match _state:
		AllyState.IDLE:
			_update_idle(delta)
		AllyState.PATROL:
			_update_idle(delta)
		AllyState.CHASE:
			_update_chase(delta)
		AllyState.ATTACK:
			_update_attack(delta)
		AllyState.DOWNED:
			_update_downed(delta)
		AllyState.RECOVERING:
			_update_recovering(delta)


func _update_idle(_delta: float) -> void:
	velocity = Vector3.ZERO
	var t: EnemyBase = find_target()
	if t != null:
		_current_target = t
		_state = AllyState.CHASE


func _update_chase(delta: float) -> void:
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = find_target()
		if _current_target == null:
			_state = AllyState.IDLE
			return

	var atk_range: float = float(ally_data.get("attack_range"))
	var dist: float = global_position.distance_to(_current_target.global_position)
	if dist <= atk_range:
		_state = AllyState.ATTACK
		velocity = Vector3.ZERO
		return

	# SOURCE: Godot 4 NavigationAgent3D chase pattern — target_position + get_next_path_position
	# in _physics_process; https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
	navigation_agent.target_position = _current_target.global_position
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_pos - global_position
	if direction.length_squared() > _MIN_NAV_STEP_SQ:
		direction = direction.normalized()
		velocity = direction * float(ally_data.get("move_speed"))
		move_and_slide()
	else:
		velocity = Vector3.ZERO


func _update_attack(delta: float) -> void:
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = find_target()
		if _current_target == null:
			_state = AllyState.IDLE
			return
		_state = AllyState.CHASE
		return

	var atk_range_at: float = float(ally_data.get("attack_range"))
	var dist: float = global_position.distance_to(_current_target.global_position)
	if dist > atk_range_at:
		_state = AllyState.CHASE
		return

	velocity = Vector3.ZERO
	_attack_cooldown_remaining -= delta
	if _attack_cooldown_remaining <= 0.0:
		_perform_attack_on_target(_current_target)
		_attack_cooldown_remaining = float(ally_data.get("attack_cooldown"))


func _update_downed(_delta: float) -> void:
	# POST-MVP: downed/recover loop for generic allies when uses_downed_recovering is true.
	pass


func _update_recovering(_delta: float) -> void:
	# POST-MVP: paired with DOWNED recovery timer.
	pass


func _on_detection_body_entered(body: Node) -> void:
	if _state == AllyState.DOWNED or _state == AllyState.RECOVERING:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if _current_target == null:
		_current_target = enemy
		_state = AllyState.CHASE


func _on_attack_body_entered(body: Node) -> void:
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _current_target and _state == AllyState.CHASE:
		_state = AllyState.ATTACK


# SOURCE: nearest-enemy selection over a group — iterate candidates, minimize distance squared;
# pattern common in RTS/arena prototypes (see also Godot group queries).
func find_target() -> EnemyBase:
	var best_enemy: EnemyBase = null
	var best_score: float = INF

	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue
		# POST-MVP: respect preferred_targeting (HIGHEST_HP, FLYING_FIRST, etc.).
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if dist_sq < best_score:
			best_score = dist_sq
			best_enemy = enemy

	return best_enemy


func _perform_attack_on_target(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var dmg: float = float(ally_data.get("attack_damage"))
	if dmg <= 0.0:
		dmg = float(ally_data.get("basic_attack_damage"))
	var damage_t: Types.DamageType = Types.DamageType.PHYSICAL
	if ally_data is AllyData:
		damage_t = (ally_data as AllyData).damage_type
	else:
		var dt: Variant = ally_data.get("damage_type")
		if dt != null:
			damage_t = dt as Types.DamageType
	# POST-MVP: RANGED allies may instantiate ProjectileBase via initialize_from_building(...) for visuals.
	enemy.take_damage(dmg, damage_t)


func _on_health_depleted() -> void:
	if ally_data != null and bool(ally_data.get("uses_downed_recovering")):
		_state = AllyState.DOWNED
		SignalBus.ally_downed.emit(str(ally_data.get("ally_id")))
		# POST-MVP: start recovery timer, heal, ally_recovered, return to IDLE.
		return

	var id: String = str(ally_data.get("ally_id")) if ally_data != null else ""
	SignalBus.ally_killed.emit(id)
	queue_free()


func get_current_state() -> AllyState:
	return _state


func get_current_hp() -> int:
	if health_component == null:
		return 0
	return health_component.get_current_hp()
