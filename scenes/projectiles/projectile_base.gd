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

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true

# === PUBLIC INITIALIZATION PATHS ===================================

## Initialize from Florence's WeaponData (player weapons).
func initialize_from_weapon(
	weapon_data: WeaponData,
	origin: Vector3,
	target_position: Vector3,
	custom_damage: float = -1.0,
	custom_damage_type: Types.DamageType = Types.DamageType.PHYSICAL
) -> void:
	# Credit (two-path initialization pattern, overshoot buffer):
	#   FOUL WARD SYSTEMS_part2.md §6.5 initialize_from_weapon.
	_damage = custom_damage if custom_damage >= 0.0 else weapon_data.damage
	_damage_type = custom_damage_type
	_speed = weapon_data.projectile_speed
	_origin = origin
	_target_position = target_position
	_direction = (target_position - origin).normalized()
	_max_travel_distance = origin.distance_to(target_position) + 5.0
	_distance_traveled = 0.0
	_lifetime = 0.0
	_targets_air_only = false  # Florence cannot target flying in MVP.

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
	dot_in_addition_to_hit: bool
) -> void:
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
	#   FOUL WARD CONVENTIONS.md §16 Physics layers & PRE_GENERATION_VERIFICATION.md §3.3.
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
		_:
			mat.albedo_color = Color.WHITE
	_mesh.material_override = mat

# === PHYSICS LOOP ===================================================

func _physics_process(delta: float) -> void:
	# Credit (straight-line, distance_traveled + tolerance + lifetime checks):
	#   FOUL WARD SYSTEMS_part2.md §6.5 ProjectileBase.physics_process.
	if _hit_processed:
		return
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		queue_free()
		return

	var movement: Vector3 = _direction * _speed * delta
	global_position += movement
	force_update_transform()
	_distance_traveled += movement.length()
	# Headless / manual _physics_process: physics server may not run, so body_entered
	# never fires — resolve overlaps here (same rules as _on_body_entered).
	if _try_hit_overlapping_enemy():
		return

	if _distance_traveled >= _max_travel_distance:
		queue_free()
		return

# === COLLISION HANDLER =============================================

func _on_body_entered(body: Node3D) -> void:
	if _hit_processed:
		return
	var enemy := body as EnemyBase
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	# Credit (skip dead enemies to avoid double-hit):
	#   FOUL WARD SYSTEMS_part2.md §6.6 Edge case "Projectile hits dead enemy".
	if not enemy.health_component.is_alive():
		return

	if _apply_damage_to_enemy(enemy):
		_hit_processed = true
		queue_free()


func _try_hit_overlapping_enemy() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if _try_damage_enemy_body(body):
			return true
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state \
		if get_world_3d() != null else null
	if space == null:
		return false
	var sphere := SphereShape3D.new()
	sphere.radius = BASE_HIT_OVERLAP_SPHERE_RADIUS * PROJECTILE_VISUAL_SCALE
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = sphere
	params.transform = global_transform
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = 2
	for r: Dictionary in space.intersect_shape(params, 8):
		var collider: Variant = r.get("collider", null)
		var node3: Node3D = collider as Node3D
		if _try_damage_enemy_body(node3):
			return true
	return false


func _try_damage_enemy_body(body: Node3D) -> bool:
	var enemy := body as EnemyBase
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy.health_component.is_alive():
		return false
	if _apply_damage_to_enemy(enemy):
		_hit_processed = true
		queue_free()
		return true
	return false

# === DAMAGE APPLICATION ============================================

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
				enemy.take_damage(_damage, _damage_type)
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
		enemy.take_damage(_damage, _damage_type)
		return true
	return false

