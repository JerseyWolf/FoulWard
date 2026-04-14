## projectile_base.gd
## Physics-driven projectile for FOUL WARD: straight-line Area3D with damage on hit or miss timeout.
## Simulation API: all public methods callable without UI nodes present.

# Credit (straight-line Area3D movement + miss/lifetime logic):
#   FOUL WARD SYSTEMS_part2.md §6.1–6.6 ProjectileBase pseudocode.
#   Godot Docs Area3D.body_entered pattern & CollisionObject3D layer/mask helpers.
#   https://docs.godotengine.org/en/stable/classes/class_area3d.html
#   https://docs.godotengine.org/en/stable/classes/class_collisionobject3d.html
#   License: CC BY 3.0
#   Adapted by FOUL WARD team to use EnemyBase + EnemyData + DamageCalculator.

class_name ProjectileBase
extends Area3D

const ProjectilePhysicsScript: CSharpScript = preload("res://scripts/ProjectilePhysics.cs")

const MAX_LIFETIME: float = 5.0

# Visual/collision scaling for all projectile types.
# User request: make every projectile "twice bigger".
const PROJECTILE_VISUAL_SCALE: float = 2.0
const BASE_HIT_OVERLAP_SPHERE_RADIUS: float = 0.4
const BASE_COLLISION_SPHERE_RADIUS: float = 0.2

var _damage: float = 0.0
var _damage_type: Types.DamageType = Types.DamageType.PHYSICAL
var _speed: float = 20.0
var _origin: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.ZERO
var _max_travel_distance: float = 0.0
var _distance_traveled: float = 0.0
var _lifetime: float = 0.0
var _targets_air_only: bool = false
var _dot_enabled: bool = false
var _dot_total_damage: float = 0.0
var _dot_tick_interval: float = 1.0
var _dot_duration: float = 0.0
var _dot_effect_type: String = ""
var _dot_source_id: String = ""
var _dot_in_addition_to_hit: bool = true

var _mesh: MeshInstance3D = null

## Prevents double application when both overlap scan and body_entered run same frame.
var _hit_processed: bool = false

## Piercing: total successful hits allowed (1 = default single-target).
var _hits_remaining: int = 1
var _splash_radius: float = 0.0
const SPLASH_DAMAGE_FRACTION: float = 0.5
var _struck_instance_ids: Array[int] = []

## CombatStatsTracker attribution (initialize_from_weapon / initialize_from_building).
var _stat_source_kind: String = "none"
var _stat_placed_instance_id: String = ""
var _stat_slot_index: int = -1

## Bridge for ProjectilePhysics.cs — straight-line speed vector (read via .Get("velocity") from C#).
var velocity: Vector3:
	get:
		return _direction * _speed

## Max travel before despawn (read via .Get("max_range") from C#).
var max_range: float:
	get:
		return _max_travel_distance

## Distance along the flight vector (read/write from C# via .Get/.Set).
var traveled_distance: float:
	get:
		return _distance_traveled
	set(value):
		_distance_traveled = value

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true
	# Physics process loop runs in C# — see res://scripts/ProjectilePhysics.cs
	var physics_child: Node = ProjectilePhysicsScript.new() as Node
	physics_child.name = "ProjectilePhysics"
	add_child(physics_child)

# === PUBLIC INITIALIZATION PATHS ===================================

## Initialize from Florence's WeaponData (player weapons).
func initialize_from_weapon(
	weapon_data: WeaponData,
	origin: Vector3,
	target_position: Vector3,
	custom_damage: float = -1.0,
	custom_damage_type: Types.DamageType = Types.DamageType.PHYSICAL,
	pierce_extra_hits: int = 0,
	splash_radius_world: float = 0.0,
	track_tower_damage_for_stats: bool = true
) -> void:
	# Credit (two-path initialization pattern, overshoot buffer):
	#   FOUL WARD SYSTEMS_part2.md §6.5 initialize_from_weapon.
	_stat_source_kind = "tower" if track_tower_damage_for_stats else "none"
	_stat_placed_instance_id = ""
	_stat_slot_index = -1
	_damage = custom_damage if custom_damage >= 0.0 else weapon_data.damage
	_damage_type = custom_damage_type
	_speed = weapon_data.projectile_speed
	_origin = origin
	_target_position = target_position
	_direction = (target_position - origin).normalized()
	var base_dist: float = origin.distance_to(target_position) + 5.0
	var pierce_bonus: float = float(maxi(0, pierce_extra_hits)) * 30.0
	_max_travel_distance = base_dist + pierce_bonus
	_distance_traveled = 0.0
	_lifetime = 0.0
	_targets_air_only = false  # Florence cannot target flying in MVP.
	_hits_remaining = 1 + maxi(0, pierce_extra_hits)
	_splash_radius = maxf(0.0, splash_radius_world)
	_struck_instance_ids.clear()
	_hit_processed = false

	global_position = origin
	_configure_collision(false)
	_configure_visuals(weapon_data.burst_count == 1)

## Initialize from BuildingBase (turret shots).
func initialize_from_building(
	damage: float,
	damage_type: Types.DamageType,
	speed: float,
	origin: Vector3,
	target_position: Vector3,
	targets_air_only: bool,
	dot_enabled: bool,
	dot_total_damage: float,
	dot_tick_interval: float,
	dot_duration: float,
	dot_effect_type: String,
	dot_source_id: String,
	dot_in_addition_to_hit: bool,
	source_placed_instance_id: String = "",
	source_slot_index: int = -1
) -> void:
	_stat_placed_instance_id = source_placed_instance_id
	_stat_slot_index = source_slot_index
	_stat_source_kind = "building" if not source_placed_instance_id.is_empty() else "none"
	_damage = damage
	_damage_type = damage_type
	_speed = speed
	_origin = origin
	_target_position = target_position
	_direction = (target_position - origin).normalized()
	_max_travel_distance = origin.distance_to(target_position) + 5.0
	_distance_traveled = 0.0
	_lifetime = 0.0
	_targets_air_only = targets_air_only
	_dot_enabled = dot_enabled
	_dot_total_damage = dot_total_damage
	_dot_tick_interval = dot_tick_interval
	_dot_duration = dot_duration
	_dot_effect_type = dot_effect_type
	_dot_source_id = dot_source_id
	_dot_in_addition_to_hit = dot_in_addition_to_hit

	global_position = origin
	_configure_collision(targets_air_only)
	_configure_visuals(true)

# === COLLISION/LAYERS ==============================================

func _configure_collision(_targets_air_only_flag: bool) -> void:
	# Projectiles always live on layer 5, hit enemies on layer 2 only.
	# Credit (layer/mask convention):
	#   FOUL WARD CONVENTIONS.md §16 Physics layers & docs/archived/PRE_GENERATION_VERIFICATION.md §3.3.
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)
	set_collision_mask_value(2, true)
	_targets_air_only = _targets_air_only_flag

	# Keep collision shape consistent with visuals scaling so the "bigger projectile"
	# also feels bigger when hitting.
	var collision_shape: CollisionShape3D = get_node_or_null("ProjectileCollision") as CollisionShape3D
	var sphere_shape: SphereShape3D = null
	if collision_shape != null:
		sphere_shape = collision_shape.shape as SphereShape3D
	if sphere_shape != null:
		sphere_shape.radius = BASE_COLLISION_SPHERE_RADIUS * PROJECTILE_VISUAL_SCALE

	# NOTE: Filtering flying vs ground is done in targeting code (which decides where
	# the projectile is fired), not via different masks. All projectiles collide with
	# any enemy body on layer 2.

func _configure_visuals(is_standard_size: bool) -> void:
	# Resolve lazily so this works whether called before or after add_child.
	# get_node_or_null() traverses the instantiated subtree, not the scene tree.
	if _mesh == null:
		_mesh = get_node_or_null("ProjectileMesh") as MeshInstance3D
	if _mesh == null:
		return
	var mat := StandardMaterial3D.new()

	if is_standard_size:
		# Building projectiles or crossbow bolt (large enough to read at isometric scale).
		var s: float = 1.1 * PROJECTILE_VISUAL_SCALE
		_mesh.scale = Vector3(s, s, s)
	else:
		# Rapid missile (small + fast look).
		var s2: float = 0.55 * PROJECTILE_VISUAL_SCALE
		_mesh.scale = Vector3(s2, s2, s2)

	match _damage_type:
		Types.DamageType.PHYSICAL:
			mat.albedo_color = Color.SADDLE_BROWN
		Types.DamageType.FIRE:
			mat.albedo_color = Color.ORANGE_RED
		Types.DamageType.MAGICAL:
			mat.albedo_color = Color.MEDIUM_PURPLE
		Types.DamageType.POISON:
			mat.albedo_color = Color.GREEN_YELLOW
		Types.DamageType.TRUE:
			mat.albedo_color = Color.WHITE
		_:
			mat.albedo_color = Color.WHITE
	_mesh.material_override = mat

# === PHYSICS LOOP (C# child ProjectilePhysics) =======================

func _on_hit(_target: Variant) -> bool:
	# Invoked from ProjectilePhysics._PhysicsProcess — overlap + ray order matches legacy _physics_process.
	return _try_hit_overlapping_enemy()


func _on_range_exceeded() -> void:
	queue_free()

# === COLLISION HANDLER =============================================

func _on_body_entered(_body: Node3D) -> void:
	if _hit_processed:
		return
	# Resolve all overlaps and strike the closest enemy along the flight vector first.
	_try_hit_overlapping_enemy()


func _ray_projection_t(enemy: EnemyBase) -> float:
	var rel: Vector3 = enemy.global_position - global_position
	return rel.dot(_direction)


func _try_hit_overlapping_enemy() -> bool:
	var candidates: Array[EnemyBase] = []
	for body: Node3D in get_overlapping_bodies():
		var e: EnemyBase = body as EnemyBase
		if e == null or not is_instance_valid(e):
			continue
		if not e.health_component.is_alive():
			continue
		if not _candidate_contains(candidates, e):
			candidates.append(e)
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state \
		if get_world_3d() != null else null
	if space != null:
		var sphere := SphereShape3D.new()
		sphere.radius = BASE_HIT_OVERLAP_SPHERE_RADIUS * PROJECTILE_VISUAL_SCALE
		var params := PhysicsShapeQueryParameters3D.new()
		params.shape = sphere
		params.transform = global_transform
		params.collide_with_areas = false
		params.collide_with_bodies = true
		params.collision_mask = 2
		for r: Dictionary in space.intersect_shape(params, 16):
			var collider: Variant = r.get("collider", null)
			var node3: Node3D = collider as Node3D
			var e2: EnemyBase = node3 as EnemyBase
			if e2 == null or not is_instance_valid(e2):
				continue
			if not e2.health_component.is_alive():
				continue
			if not _candidate_contains(candidates, e2):
				candidates.append(e2)
	if candidates.is_empty():
		return false
	candidates.sort_custom(func(a: EnemyBase, b: EnemyBase) -> bool:
		return _ray_projection_t(a) < _ray_projection_t(b)
	)
	for e3: EnemyBase in candidates:
		if _try_damage_enemy_body(e3):
			return true
	return false


func _candidate_contains(arr: Array[EnemyBase], e: EnemyBase) -> bool:
	for x: EnemyBase in arr:
		if x == e:
			return true
	return false


func _try_damage_enemy_body(body: Node3D) -> bool:
	var enemy := body as EnemyBase
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy.health_component.is_alive():
		return false
	return _resolve_hit_on_enemy(enemy)


## Returns true when the projectile should stop processing (destroyed or pierce exhausted this frame).
func _resolve_hit_on_enemy(enemy: EnemyBase) -> bool:
	var eid: int = enemy.get_instance_id()
	if eid in _struck_instance_ids:
		return false
	if not _apply_damage_to_enemy(enemy):
		return false
	_struck_instance_ids.append(eid)
	if _splash_radius > 0.001:
		_apply_splash_damage(enemy.global_position, enemy)
	_hits_remaining -= 1
	if _hits_remaining <= 0:
		_hit_processed = true
		queue_free()
		return true
	# Nudge forward so overlap does not re-trigger the same body this frame.
	global_position += _direction * 0.75
	return false

# === DAMAGE APPLICATION ============================================

func _apply_splash_damage(center: Vector3, primary: EnemyBase) -> void:
	var r2: float = _splash_radius * _splash_radius
	var splash_damage: float = _damage * SPLASH_DAMAGE_FRACTION
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		var e: EnemyBase = node as EnemyBase
		if e == null or e == primary:
			continue
		if not e.health_component.is_alive():
			continue
		if e.global_position.distance_squared_to(center) > r2:
			continue
		var ed := e.get_enemy_data()
		if ed == null or _damage_type in ed.damage_immunities:
			continue
		var fd: float = DamageCalculator.calculate_damage(
			splash_damage,
			_damage_type,
			ed.armor_type
		)
		if fd > 0.0:
			var hp_before_splash: int = e.health_component.current_hp
			e.take_damage(splash_damage, _damage_type)
			_notify_combat_stat(e, hp_before_splash)


## Returns true if at least one point of damage was applied (not fully immunized).
func _apply_damage_to_enemy(enemy: EnemyBase) -> bool:
	# Credit (damage_immunities + DamageCalculator):
	#   FOUL WARD SYSTEMS_part1/2/3 EnemyBase & ProjectileBase.apply_damage_to_enemy.
	var enemy_data := enemy.get_enemy_data()

	if _damage_type in enemy_data.damage_immunities:
		return false

	if _dot_enabled and (_damage_type == Types.DamageType.FIRE or _damage_type == Types.DamageType.POISON):
		if _dot_in_addition_to_hit:
			var final_damage: float = DamageCalculator.calculate_damage(
				_damage,
				_damage_type,
				enemy_data.armor_type
			)
			if final_damage > 0.0:
				var hp_before_dot: int = enemy.health_component.current_hp
				enemy.take_damage(_damage, _damage_type)
				_notify_combat_stat(enemy, hp_before_dot)
		var effect_data: Dictionary = {
			"effect_type": _dot_effect_type,
			"damage_type": _damage_type,
			"dot_total_damage": _dot_total_damage,
			"tick_interval": _dot_tick_interval,
			"duration": _dot_duration,
			"remaining_time": _dot_duration,
			"time_since_last_tick": 0.0,
			"source_id": _dot_source_id,
		}
		enemy.apply_dot_effect(effect_data)
		return true

	var final_damage_no_dot: float = DamageCalculator.calculate_damage(
		_damage,
		_damage_type,
		enemy_data.armor_type
	)
	if final_damage_no_dot > 0.0:
		var hp_before: int = enemy.health_component.current_hp
		enemy.take_damage(_damage, _damage_type)
		_notify_combat_stat(enemy, hp_before)
		return true
	return false


func _notify_combat_stat(enemy: EnemyBase, hp_before: int) -> void:
	if _stat_source_kind == "none":
		return
	var hp_after: int = enemy.health_component.current_hp
	var dmg: float = float(maxi(0, hp_before - hp_after))
	var killed: bool = hp_before > 0 and hp_after <= 0
	if dmg <= 0.0:
		return
	var enemy_id_str: String = ""
	var ed: EnemyData = enemy.get_enemy_data()
	if ed != null:
		if not ed.id.strip_edges().is_empty():
			enemy_id_str = ed.id
		else:
			enemy_id_str = str(ed.enemy_type)
	if _stat_source_kind == "building" and not _stat_placed_instance_id.is_empty():
		SignalBus.building_dealt_damage.emit(_stat_placed_instance_id, dmg, enemy_id_str)
	CombatStatsTracker.record_projectile_damage(
		_stat_source_kind,
		_stat_placed_instance_id,
		_stat_slot_index,
		dmg,
		killed
	)

