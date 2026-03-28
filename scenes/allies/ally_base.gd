## ally_base.gd
## Generic ally CharacterBody3D: navigate, acquire nearest enemy, melee/ranged direct damage.
## Mission death and campaign roster recovery are separate layers (CampaignManager — POST-MVP).

class_name AllyBase
extends CharacterBody3D

const _MIN_NAV_STEP_SQ: float = 0.0004
const ALLY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")
const ALLY_PROJECTILE_SPEED: float = 20.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var ally_mesh: MeshInstance3D = $AllyMesh
@onready var _detection_shape: CollisionShape3D = $DetectionArea/DetectionShape
@onready var _attack_shape: CollisionShape3D = $AttackArea/AttackShape

var ally_data: Variant = null

## Dictionary-style get for Variant ally_data: Resource.get() only accepts one argument in Godot 4.
func _ally_data_get(key: String, default: Variant = null) -> Variant:
	if ally_data is Dictionary:
		return (ally_data as Dictionary).get(key, default)
	var typed: AllyData = ally_data as AllyData
	if typed != null:
		var v: Variant = typed.get(key)
		if v != null:
			return v
		return default
	var res: Resource = ally_data as Resource
	if res != null:
		var v2: Variant = res.get(key)
		if v2 != null:
			return v2
	return default


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
var _barracks_strike_bonus: float = 0.0
var _recovery_timer: float = 0.0
var current_level: int = 1


func _ready() -> void:
	add_to_group("allies")
	detection_area.body_entered.connect(_on_detection_body_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.75
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5
	_apply_starting_level_from_data()


## Spec alias (Prompt 12); delegates to `initialize_ally_data`.
func initialize(p_ally_data: AllyData) -> void:
	initialize_ally_data(p_ally_data)


func initialize_ally_data(p_ally_data: Variant) -> void:
	ally_data = p_ally_data
	if ally_data == null:
		push_error("AllyBase.initialize_ally_data: null AllyData")
		return

	_apply_starting_level_from_data()
	health_component.max_hp = get_effective_max_hp()
	health_component.reset_to_max()
	_attack_cooldown_remaining = 0.0
	_recovery_timer = 0.0
	_state = AllyState.IDLE
	_current_target = null

	if not health_component.health_depleted.is_connected(_on_health_depleted):
		health_component.health_depleted.connect(_on_health_depleted)

	_apply_ally_data_to_shapes()
	_apply_debug_color_from_data()

	# DEVIATION: generic ally_spawned for campaign / UI integration.
	SignalBus.ally_spawned.emit(str(_ally_data_get("ally_id", "")))


func _apply_starting_level_from_data() -> void:
	if ally_data == null:
		current_level = 1
		return
	var sl: int = 1
	if ally_data is AllyData:
		sl = (ally_data as AllyData).starting_level
	else:
		sl = int(_ally_data_get("starting_level", 1))
	current_level = maxi(1, sl)


func get_effective_damage() -> int:
	var base: int = _get_base_damage_stat()
	return _scaled_stat_from_base(base)


func get_effective_max_hp() -> int:
	var base: int = _get_base_hp_stat()
	return _scaled_stat_from_base(base)


func _get_level_scaling_factor() -> float:
	if ally_data is AllyData:
		return (ally_data as AllyData).level_scaling_factor
	return float(_ally_data_get("level_scaling_factor", 1.0))


func _scaled_stat_from_base(base_stat: int) -> int:
	var f: float = _get_level_scaling_factor()
	return base_stat + int(floor(float(base_stat) * f * float(current_level - 1)))


func _get_base_damage_stat() -> int:
	if ally_data is AllyData:
		var ad: AllyData = ally_data as AllyData
		if ad.base_damage > 0:
			return ad.base_damage
		if ad.attack_damage > 0.0:
			return int(ad.attack_damage)
		return int(ad.basic_attack_damage)
	var bd: int = int(_ally_data_get("base_damage", 0))
	if bd > 0:
		return bd
	var admg: float = float(_ally_data_get("attack_damage", 0.0))
	if admg > 0.0:
		return int(admg)
	return int(float(_ally_data_get("basic_attack_damage", 10.0)))


func _get_base_hp_stat() -> int:
	if ally_data is AllyData:
		var ad: AllyData = ally_data as AllyData
		if ad.base_hp > 0:
			return ad.base_hp
		return int(ad.max_hp)
	var bh: int = int(_ally_data_get("base_hp", 0))
	if bh > 0:
		return bh
	return int(_ally_data_get("max_hp", 100))


func _get_ally_projectile_base_damage_stat() -> int:
	if ally_data is AllyData:
		var ad: AllyData = ally_data as AllyData
		if ad.ally_base_damage > 0:
			return ad.ally_base_damage
		return _get_base_damage_stat()
	var abd: int = int(_ally_data_get("ally_base_damage", 0))
	if abd > 0:
		return abd
	return _get_base_damage_stat()


func _get_effective_projectile_damage() -> int:
	return _scaled_stat_from_base(_get_ally_projectile_base_damage_stat())


func _apply_ally_data_to_shapes() -> void:
	if ally_data == null:
		return
	var atk_range: float = float(_ally_data_get("attack_range", 2.0))
	var detect_r: float = maxf(40.0, atk_range + 2.0)
	if _detection_shape != null and _detection_shape.shape is SphereShape3D:
		(_detection_shape.shape as SphereShape3D).radius = detect_r
	if _attack_shape != null and _attack_shape.shape is SphereShape3D:
		(_attack_shape.shape as SphereShape3D).radius = atk_range


func _apply_debug_color_from_data() -> void:
	# TODO(ART): Apply ArtPlaceholderHelper.get_ally_mesh(ally_id) here when generic allies use
	# res://art/generated/allies/<ally_id>.glb; keep debug_color as fallback until then.
	if ally_data == null or ally_mesh == null:
		return
	var c: Variant = _ally_data_get("debug_color", Color.WHITE)
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

	var atk_range: float = float(_ally_data_get("attack_range", 2.0))
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
		velocity = direction * float(_ally_data_get("move_speed", 5.0))
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

	var atk_range_at: float = float(_ally_data_get("attack_range", 2.0))
	var dist: float = global_position.distance_to(_current_target.global_position)
	if dist > atk_range_at:
		_state = AllyState.CHASE
		return

	velocity = Vector3.ZERO
	_attack_cooldown_remaining -= delta
	if _attack_cooldown_remaining <= 0.0:
		_perform_attack_on_target(_current_target)
		_attack_cooldown_remaining = float(_ally_data_get("attack_cooldown", 1.0))


func _update_downed(delta: float) -> void:
	velocity = Vector3.ZERO
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		_state = AllyState.RECOVERING


func _update_recovering(_delta: float) -> void:
	health_component.reset_to_max()
	SignalBus.ally_recovered.emit(str(_ally_data_get("ally_id", "")))
	_state = AllyState.IDLE
	_current_target = null


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


func _get_preferred_targeting() -> Types.TargetPriority:
	if ally_data is AllyData:
		return (ally_data as AllyData).preferred_targeting
	var v: Variant = _ally_data_get("preferred_targeting", Types.TargetPriority.CLOSEST)
	if v is Types.TargetPriority:
		return v as Types.TargetPriority
	return Types.TargetPriority.CLOSEST


func _can_consider_enemy(enemy: EnemyBase) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy.health_component.is_alive():
		return false
	var allow_flying: bool = true
	if ally_data is AllyData:
		allow_flying = (ally_data as AllyData).can_target_flying
	else:
		allow_flying = bool(_ally_data_get("can_target_flying", false))
	if not allow_flying and enemy.get_enemy_data().is_flying:
		return false
	return true


func _pick_closest_enemies(candidates: Array[EnemyBase]) -> EnemyBase:
	var best_enemy: EnemyBase = null
	var best_score: float = INF
	for enemy: EnemyBase in candidates:
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if dist_sq < best_score:
			best_score = dist_sq
			best_enemy = enemy
	return best_enemy


func _pick_lowest_hp_enemies(candidates: Array[EnemyBase]) -> EnemyBase:
	var best_enemy: EnemyBase = null
	var best_hp: int = 2147483647
	var best_dist_sq: float = INF
	for enemy: EnemyBase in candidates:
		var hp: int = enemy.health_component.get_current_hp()
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if hp < best_hp or (hp == best_hp and dist_sq < best_dist_sq):
			best_hp = hp
			best_dist_sq = dist_sq
			best_enemy = enemy
	return best_enemy


func _pick_highest_hp_enemies(candidates: Array[EnemyBase]) -> EnemyBase:
	var best_enemy: EnemyBase = null
	var best_hp: int = -1
	var best_dist_sq: float = INF
	for enemy: EnemyBase in candidates:
		var hp: int = enemy.health_component.get_current_hp()
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if hp > best_hp or (hp == best_hp and dist_sq < best_dist_sq):
			best_hp = hp
			best_dist_sq = dist_sq
			best_enemy = enemy
	return best_enemy


func _pick_flying_first_enemies(candidates: Array[EnemyBase]) -> EnemyBase:
	var flying: Array[EnemyBase] = []
	var ground: Array[EnemyBase] = []
	for enemy: EnemyBase in candidates:
		if enemy.get_enemy_data().is_flying:
			flying.append(enemy)
		else:
			ground.append(enemy)
	if not flying.is_empty():
		return _pick_closest_enemies(flying)
	return _pick_closest_enemies(ground)


# SOURCE: group query over "enemies"; scoring depends on AllyData.preferred_targeting.
func find_target() -> EnemyBase:
	var candidates: Array[EnemyBase] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if not _can_consider_enemy(enemy):
			continue
		candidates.append(enemy)
	if candidates.is_empty():
		return null

	var prio: Types.TargetPriority = _get_preferred_targeting()
	match prio:
		Types.TargetPriority.CLOSEST:
			return _pick_closest_enemies(candidates)
		Types.TargetPriority.LOWEST_HP:
			return _pick_lowest_hp_enemies(candidates)
		Types.TargetPriority.HIGHEST_HP:
			return _pick_highest_hp_enemies(candidates)
		Types.TargetPriority.FLYING_FIRST:
			return _pick_flying_first_enemies(candidates)
		_:
			return _pick_closest_enemies(candidates)


func _perform_attack_on_target(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var damage_t: Types.DamageType = Types.DamageType.PHYSICAL
	if ally_data is AllyData:
		damage_t = (ally_data as AllyData).damage_type
	else:
		var dt: Variant = _ally_data_get("damage_type", Types.DamageType.PHYSICAL)
		if dt != null:
			damage_t = dt as Types.DamageType
	var extra: float = _barracks_strike_bonus
	_barracks_strike_bonus = 0.0
	var is_ranged_attack: bool = false
	if ally_data is AllyData:
		is_ranged_attack = (ally_data as AllyData).is_ranged
	else:
		is_ranged_attack = bool(_ally_data_get("is_ranged", false))
	if is_ranged_attack:
		var proj_dmg: float = float(_get_effective_projectile_damage()) + extra
		_spawn_ally_projectile(enemy, proj_dmg, damage_t)
		return
	var dmg: float = float(get_effective_damage()) + extra
	enemy.take_damage(dmg, damage_t)


func _spawn_ally_projectile(enemy: EnemyBase, total_damage: float, damage_t: Types.DamageType) -> void:
	var proj: ProjectileBase = ALLY_PROJECTILE_SCENE.instantiate() as ProjectileBase
	var pc: Node = get_node_or_null("/root/Main/ProjectileContainer")
	if pc == null:
		proj.queue_free()
		enemy.take_damage(total_damage, damage_t)
		return
	var origin: Vector3 = global_position + Vector3(0.0, 0.5, 0.0)
	var target_pos: Vector3 = enemy.global_position
	pc.add_child(proj)
	proj.initialize_from_building(
		total_damage,
		damage_t,
		ALLY_PROJECTILE_SPEED,
		origin,
		target_pos,
		false,
		false,
		0.0,
		1.0,
		0.0,
		"",
		"",
		false
	)
	proj.add_to_group("projectiles")


func _on_health_depleted() -> void:
	if ally_data != null and bool(_ally_data_get("uses_downed_recovering", false)):
		velocity = Vector3.ZERO
		_current_target = null
		_recovery_timer = maxf(0.0, float(_ally_data_get("recovery_time", 0.0)))
		_state = AllyState.DOWNED
		SignalBus.ally_downed.emit(str(_ally_data_get("ally_id", "")))
		return

	var id: String = str(_ally_data_get("ally_id", "")) if ally_data != null else ""
	SignalBus.ally_killed.emit(id)
	queue_free()


func get_current_state() -> AllyState:
	return _state


func get_current_hp() -> int:
	if health_component == null:
		return 0
	return health_component.get_current_hp()


## Stacked by Archer Barracks pulses; consumed on next attack.
func add_barracks_strike_bonus(amount: float) -> void:
	if amount > 0.0:
		_barracks_strike_bonus += amount


func get_barracks_strike_bonus() -> float:
	return _barracks_strike_bonus
