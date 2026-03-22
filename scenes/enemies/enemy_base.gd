## enemy_base.gd
## Runtime enemy controller: movement, tower attacks, and death handling for FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

# Credit (movement/NavigationAgent3D pattern):
#   Godot Docs — "Using NavigationAgents" (CharacterBody3D template, avoidance notes)
#   https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
#   License: CC BY 3.0
#   Adapted by FOUL WARD team to use EnemyData stats and tower-focused targeting.

class_name EnemyBase
extends CharacterBody3D

const TARGET_POSITION: Vector3 = Vector3.ZERO
const FLYING_HEIGHT: float = 5.0

var _enemy_data: EnemyData = null
var _attack_timer: float = 0.0
var _is_attacking: bool = false

# PUBLIC — required by BuildingBase._find_target() and Arnulf._find_closest_enemy_to_tower().
@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = get_node_or_null("EnemyMesh")
@onready var _label: Label3D = get_node_or_null("EnemyLabel")

# ASSUMPTION: These paths match ARCHITECTURE.md section 2.
@onready var _tower: Node = get_node_or_null("/root/Main/Tower")

func _ready() -> void:
	# Ensure enemies can be found via group for buildings and spells.
	add_to_group("enemies")
	if _label != null and _enemy_data != null:
		_label.text = _enemy_data.display_name

# === PUBLIC API =====================================================

## Initializes this enemy instance from its EnemyData resource.
func initialize(enemy_data: EnemyData) -> void:
	assert(enemy_data != null, "EnemyBase.initialize called with null EnemyData")
	_enemy_data = enemy_data
	_attack_timer = 0.0
	_is_attacking = false

	health_component.max_hp = _enemy_data.max_hp
	health_component.reset_to_max()
	health_component.health_depleted.connect(_on_health_depleted)

	# Ground enemies configure NavigationAgent3D; flying ones ignore it.
	if not _enemy_data.is_flying:
		# Credit (target_desired_distance + path_desired_distance usage):
		#   FOUL WARD SYSTEMS_part3.md §8.6 EnemyBase.move_ground pseudocode.
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = _enemy_data.attack_range
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 0.5

	# Visuals from EnemyData.color.
	if _mesh != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _enemy_data.color
		_mesh.material_override = mat
	if _label != null:
		_label.text = _enemy_data.display_name

## Applies damage of a given type to this enemy.
func take_damage(amount: float, damage_type: Types.DamageType) -> void:
	# Credit (immunity-before-matrix pattern):
	#   FOUL WARD SYSTEMS_part1/2/3: EnemyBase.take_damage spec with damage_immunities.
	if damage_type in _enemy_data.damage_immunities:
		return

	var final_damage: float = DamageCalculator.calculate_damage(
		amount,
		damage_type,
		_enemy_data.armor_type
	)
	health_component.take_damage(final_damage)

## Returns the EnemyData backing this enemy instance.
func get_enemy_data() -> EnemyData:
	return _enemy_data

# === PHYSICS LOOP ===================================================

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

# === MOVEMENT =======================================================

func _move_ground(_delta: float) -> void:
	# Guard for navigation map not yet synchronized (first frame after spawn).
	# Credit (map_get_iteration_id guard):
	#   Godot Docs NavigationAgents tutorial + community pattern.
	var nav_map := navigation_agent.get_navigation_map()
	if nav_map.is_valid():
		if NavigationServer3D.map_get_iteration_id(nav_map) == 0:
			return

	navigation_agent.target_position = TARGET_POSITION

	if navigation_agent.is_navigation_finished():
		_is_attacking = true
		_attack_timer = 0.0
		return

	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - global_position).normalized()
	velocity = direction * _enemy_data.move_speed
	move_and_slide()

	# Backup arrival check in case navmesh confirmation is delayed.
	if global_position.distance_to(TARGET_POSITION) <= _enemy_data.attack_range:
		_is_attacking = true
		_attack_timer = 0.0

func _move_flying(_delta: float) -> void:
	# Credit (constant-height + horizontal arrival):
	#   FOUL WARD SYSTEMS_part3.md §8.6 EnemyBase.move_flying pseudocode.
	var fly_target := Vector3(TARGET_POSITION.x, FLYING_HEIGHT, TARGET_POSITION.z)
	var direction: Vector3 = (fly_target - global_position).normalized()
	velocity = direction * _enemy_data.move_speed
	move_and_slide()

	var horizontal_dist := Vector2(
		global_position.x - TARGET_POSITION.x,
		global_position.z - TARGET_POSITION.z
	).length()
	if horizontal_dist <= _enemy_data.attack_range:
		_is_attacking = true
		_attack_timer = 0.0

# === ATTACK LOGIC ===================================================

func _attack_tower_melee(delta: float) -> void:
	velocity = Vector3.ZERO
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _enemy_data.attack_cooldown
		if is_instance_valid(_tower):
			# ASSUMPTION: Tower exposes take_damage(amount: int) -> void.
			_tower.take_damage(_enemy_data.damage)

func _attack_tower_ranged(delta: float) -> void:
	# DEVIATION (documented in SYSTEMS_part3 §8.6):
	#   Orc Archer uses instant-hit damage, not a visible projectile, for MVP.
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _enemy_data.attack_cooldown
		if is_instance_valid(_tower):
			_tower.take_damage(_enemy_data.damage)

# === DEATH HANDLING ================================================

func _on_health_depleted() -> void:
	# Credit (signal + group removal + queue_free order):
	#   FOUL WARD SYSTEMS_part3.md EnemyBase.on_health_depleted pseudocode.
	SignalBus.enemy_killed.emit(
		_enemy_data.enemy_type,
		global_position,
		_enemy_data.gold_reward
	)
	# EconomyManager already listens to enemy_killed in Phase 1, so we do NOT call
	# EconomyManager.add_gold() directly here to avoid double-award.

	remove_from_group("enemies")
	queue_free()

