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
const ARRIVAL_TOLERANCE: float = 0.5

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

var _mesh: MeshInstance3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

# === PUBLIC INITIALIZATION PATHS ===================================

## Initialize from Florence's WeaponData (player weapons).
func initialize_from_weapon(
	weapon_data: WeaponData,
	origin: Vector3,
	target_position: Vector3
) -> void:
	# Credit (two-path initialization pattern, overshoot buffer):
	#   FOUL WARD SYSTEMS_part2.md §6.5 initialize_from_weapon.
	_damage = weapon_data.damage
	_damage_type = Types.DamageType.PHYSICAL  # MVP: Florence weapons are PHYSICAL.
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
	targets_air_only: bool
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
		_mesh.scale = Vector3(1.1, 1.1, 1.1)
	else:
		# Rapid missile (small + fast look).
		_mesh.scale = Vector3(0.55, 0.55, 0.55)

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
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		queue_free()
		return

	var movement: Vector3 = _direction * _speed * delta
	global_position += movement
	_distance_traveled += movement.length()

	if _distance_traveled >= _max_travel_distance:
		queue_free()
		return

	var dist_to_target := global_position.distance_to(_target_position)
	if dist_to_target <= ARRIVAL_TOLERANCE:
		queue_free()
		return

# === COLLISION HANDLER =============================================

func _on_body_entered(body: Node3D) -> void:
	var enemy := body as EnemyBase
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	# Credit (skip dead enemies to avoid double-hit):
	#   FOUL WARD SYSTEMS_part2.md §6.6 Edge case "Projectile hits dead enemy".
	if not enemy.health_component.is_alive():
		return

	_apply_damage_to_enemy(enemy)
	queue_free()

# === DAMAGE APPLICATION ============================================

func _apply_damage_to_enemy(enemy: EnemyBase) -> void:
	# Credit (damage_immunities + DamageCalculator):
	#   FOUL WARD SYSTEMS_part1/2/3 EnemyBase & ProjectileBase.apply_damage_to_enemy.
	var enemy_data := enemy.get_enemy_data()

	if _damage_type in enemy_data.damage_immunities:
		return

	var final_damage: float = DamageCalculator.calculate_damage(
		_damage,
		_damage_type,
		enemy_data.armor_type
	)
	enemy.health_component.take_damage(final_damage)

