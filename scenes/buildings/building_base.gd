# scenes/buildings/building_base.gd
# BuildingBase – base class for all 8 building types.
# Initialized with a BuildingData resource. Handles targeting, combat, and projectile firing.
# Special types (Archer Barracks, Shield Generator) have fire_rate = 0 and are POST-MVP stubs.
#
# Credit: _find_target() group-based enemy iteration pattern:
#   ARCHITECTURE.md §3.2 – BuildingBase class responsibilities; Foul Ward project.
#
# Credit: is_instance_valid() pattern for enemies freed mid-frame:
#   CONVENTIONS.md §9.3 – "is_instance_valid for deferred references"; Foul Ward project.
#
# Credit: physics_process for all game logic (not process):
#   CONVENTIONS.md §14 – "PROCESS FUNCTION RULES"; Foul Ward project.

class_name BuildingBase
extends Node3D

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")
# ASSUMPTION: ProjectileBase at this path per ARCHITECTURE.md §11.
const BASE_HALF_EXTENT_X: float = 1.25
const BASE_HALF_EXTENT_Z: float = 1.25
const BASE_HEIGHT: float = 3.0
const OBSTACLE_RADIUS: float = 2.0

# Assign placeholder art resources via convention-based pipeline.
const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _building_data: BuildingData = null
var _is_upgraded: bool = false
var _attack_timer: float = 0.0
var _current_target: EnemyBase = null

# ---------------------------------------------------------------------------
# Children
# ---------------------------------------------------------------------------

# ASSUMPTION: ProjectileContainer at /root/Main/ProjectileContainer per ARCHITECTURE.md §2.
@onready var _projectile_container: Node3D = get_node_or_null("/root/Main/ProjectileContainer") as Node3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_body: StaticBody3D = $BuildingCollision
@onready var collision_shape: CollisionShape3D = $BuildingCollision/CollisionShape3D
@onready var navigation_obstacle: NavigationObstacle3D = $NavigationObstacle
@onready var mesh: MeshInstance3D = $BuildingMesh
@onready var label: Label3D = $BuildingLabel

# ---------------------------------------------------------------------------
# Public accessor – is_upgraded is read by HexGrid for sell refunds
# ---------------------------------------------------------------------------

var is_upgraded: bool:
	get:
		return _is_upgraded

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_configure_base_area()
	_enable_collision_and_obstacle()
	if _building_data != null:
		print("[Building] ready: %s at (%.1f,%.1f,%.1f)" % [
			_building_data.display_name,
			global_position.x, global_position.y, global_position.z
		])


func _configure_base_area() -> void:
	# ASSUMPTION: one footprint shape drives both collision and avoidance tuning.
	if collision_shape == null or navigation_obstacle == null:
		return
	var box_shape: BoxShape3D = collision_shape.shape as BoxShape3D
	if box_shape == null:
		return
	box_shape.size = Vector3(BASE_HALF_EXTENT_X * 2.0, BASE_HEIGHT, BASE_HALF_EXTENT_Z * 2.0)
	navigation_obstacle.radius = OBSTACLE_RADIUS


func _enable_collision_and_obstacle() -> void:
	if collision_shape == null or navigation_obstacle == null:
		return
	collision_shape.set_deferred("disabled", false)
	navigation_obstacle.set_deferred("enabled", true)


func _disable_collision_and_obstacle() -> void:
	# POST-MVP hook for destroyable buildings.
	if collision_shape == null or navigation_obstacle == null:
		return
	collision_shape.set_deferred("disabled", true)
	navigation_obstacle.set_deferred("enabled", false)


func _physics_process(delta: float) -> void:
	_combat_process(delta)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Call after the node is in the scene tree (add_child) so child paths resolve.
## Configures visuals and stats from the provided BuildingData resource.
func initialize(data: BuildingData) -> void:
	_building_data = data
	_is_upgraded = false
	_attack_timer = 0.0
	_current_target = null

	# MVP visual: colored cube + label (use get_node — @onready is not set before _ready()).
	var mesh_inst: MeshInstance3D = get_node_or_null("BuildingMesh") as MeshInstance3D
	if mesh_inst != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = data.color
		mesh_inst.material_override = mat

	# Art pipeline placeholder assignment (runtime override).
	# NOTE: keep existing MVP color material generation for now; we override it via helper.
	if mesh_inst != null:
		var _art_mesh: Mesh = ArtPlaceholderHelper.get_building_mesh(data.building_type)
		if _art_mesh != null:
			mesh_inst.mesh = _art_mesh
		var _art_mat: Material = ArtPlaceholderHelper.get_building_material(data.building_type)
		if _art_mat != null:
			mesh_inst.material_override = _art_mat

	var label_inst: Label3D = get_node_or_null("BuildingLabel") as Label3D
	if label_inst != null:
		label_inst.text = data.display_name

	print("[Building] initialized: %s  dmg=%.0f range=%.1f fire_rate=%.2f  air=%s gnd=%s" % [
		data.display_name, data.damage, data.attack_range, data.fire_rate,
		data.targets_air, data.targets_ground
	])


## Transitions the building from Basic to Upgraded tier.
func upgrade() -> void:
	_is_upgraded = true


## Returns the BuildingData resource this building was initialized with.
func get_building_data() -> BuildingData:
	return _building_data


## Returns the currently effective damage value (base or upgraded).
func get_effective_damage() -> float:
	if _building_data == null:
		return 0.0
	if _is_upgraded:
		return _building_data.upgraded_damage
	if _has_research_damage_boost():
		return _building_data.upgraded_damage
	return _building_data.damage


## Returns the currently effective attack range (base or upgraded).
func get_effective_range() -> float:
	if _building_data == null:
		return 0.0
	if _is_upgraded:
		return _building_data.upgraded_range
	if _has_research_range_boost():
		return _building_data.upgraded_range
	return _building_data.attack_range


func _has_research_damage_boost() -> bool:
	if _building_data.research_damage_boost_id == "":
		return false
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm == null:
		return false
	return rm.is_unlocked(_building_data.research_damage_boost_id)


func _has_research_range_boost() -> bool:
	if _building_data.research_range_boost_id == "":
		return false
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm == null:
		return false
	return rm.is_unlocked(_building_data.research_range_boost_id)

# ---------------------------------------------------------------------------
# Private – combat loop
# ---------------------------------------------------------------------------

func _combat_process(delta: float) -> void:
	if _building_data == null:
		return

	# POST-MVP stub guard: Archer Barracks and Shield Generator have fire_rate = 0.
	# This prevents any division-by-zero and combat attempt for stubs.
	if _building_data.fire_rate <= 0.0:
		return

	_attack_timer -= delta

	# Validate or acquire target.
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = _find_target()

	if _current_target == null:
		return

	# Target may have moved out of range since last frame.
	if global_position.distance_to(_current_target.global_position) > get_effective_range():
		_current_target = _find_target()
		if _current_target == null:
			return

	# Fire when cooldown elapsed.
	if _attack_timer <= 0.0:
		_fire_at_target()
		_attack_timer = 1.0 / _building_data.fire_rate


## Finds the best valid target within range.
## MVP strategy: CLOSEST enemy to this building.
## Respects targets_air / targets_ground flags from BuildingData.
func _find_target() -> EnemyBase:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var enemies: Array[Node] = tree.get_nodes_in_group("enemies")
	var best_target: EnemyBase = null
	var best_distance: float = INF
	var effective_range: float = get_effective_range()

	for node: Node in enemies:
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue

		var enemy_data: EnemyData = enemy.get_enemy_data()

		# Filter by air/ground targeting flags.
		if enemy_data.is_flying and not _building_data.targets_air:
			continue
		if not enemy_data.is_flying and not _building_data.targets_ground:
			continue

		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > effective_range:
			continue

		if distance < best_distance:
			best_distance = distance
			best_target = enemy

	return best_target


## Instantiates and launches a projectile toward the current target.
func _fire_at_target() -> void:
	if not is_instance_valid(_current_target):
		return

	var proj: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	if _projectile_container == null:
		return

	# Speed proxy: fire_rate * 15.0 gives reasonable projectile speed spread.
	# Slow-firing Ballista (0.4/s) → speed 6; fast Poison Vat (1.5/s) → speed 22.5.
	var proj_speed: float = _building_data.fire_rate * 15.0

	var dist: float = global_position.distance_to(_current_target.global_position)
	print("[Building] %s fired → %s  dist=%.1f  target_y=%.1f" % [
		_building_data.display_name,
		_current_target.get_enemy_data().display_name if _current_target.get_enemy_data() != null else "?",
		dist,
		_current_target.global_position.y
	])

	_projectile_container.add_child(proj)
	proj.initialize_from_building(
		get_effective_damage(),
		_building_data.damage_type,
		proj_speed,
		global_position,
		_current_target.global_position,
		_building_data.targets_air,
		_building_data.dot_enabled,
		_building_data.dot_total_damage,
		_building_data.dot_tick_interval,
		_building_data.dot_duration,
		_building_data.dot_effect_type,
		_building_data.dot_source_id,
		_building_data.dot_in_addition_to_hit
	)
	proj.add_to_group("projectiles")

