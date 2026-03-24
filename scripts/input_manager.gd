# scripts/input_manager.gd
# InputManager — translates raw input into public API calls. Zero game logic.
#
# Credit: Godot Engine Official Documentation — Camera3D
# https://docs.godotengine.org/en/stable/classes/class_camera3d.html
# License: CC-BY-3.0
# Adapted: project_ray_origin / project_ray_normal + Plane.intersects_ray pattern.
#
# Credit: Godot Engine GitHub Issue #83983 — project_ray_origin orthographic behaviour
# https://github.com/godotengine/godot/issues/83983
# License: MIT | Returns near-clip-plane point for orthographic cameras.

class_name InputManager
extends Node

# ASSUMPTION: All node paths match ARCHITECTURE.md §2.
@onready var _tower: Tower = get_node("/root/Main/Tower")
@onready var _spell_manager: SpellManager = get_node("/root/Main/Managers/SpellManager")
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")
@onready var _camera: Camera3D = get_node("/root/Main/Camera3D")
@onready var _build_menu: BuildMenu = get_node("/root/Main/UI/BuildMenu")

const _RAY_MAX_DISTANCE: float = 10_000.0
## Physics layer 2 — enemies (see enemy_base.tscn collision_layer).
const _ENEMY_COLLISION_MASK: int = 2
## Physics layer 7 — hex slots (see hex_grid.gd collision layer setup).
const _HEX_SLOT_COLLISION_MASK: int = 64

var _selected_slot_index: int = -1

func _ready() -> void:
	print("[InputManager] _ready")

# ─────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	var state: Types.GameState = GameManager.get_game_state()

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			var can_manual_fire: bool = (
				state == Types.GameState.COMBAT
				or state == Types.GameState.WAVE_COUNTDOWN
			)
			if mb.button_index == MOUSE_BUTTON_LEFT and can_manual_fire:
				var aim: Vector3 = _get_fire_aim_position()
				if aim != Vector3.ZERO:
					print("[InputManager] LEFT click → fire_crossbow at (%.1f, %.1f, %.1f)" % [aim.x, aim.y, aim.z])
					_tower.fire_crossbow(aim)
				else:
					print("[InputManager] LEFT click — no aim (ZERO)")

			elif mb.button_index == MOUSE_BUTTON_RIGHT and can_manual_fire:
				var aim: Vector3 = _get_fire_aim_position()
				if aim != Vector3.ZERO:
					print("[InputManager] RIGHT click → fire_rapid_missile at (%.1f, %.1f, %.1f)" % [aim.x, aim.y, aim.z])
					_tower.fire_rapid_missile(aim)
				else:
					print("[InputManager] RIGHT click — no aim (ZERO)")

			elif mb.button_index == MOUSE_BUTTON_LEFT and state == Types.GameState.BUILD_MODE:
				_handle_build_mode_left_click()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("cast_shockwave"):
			print("[InputManager] cast_shockwave key pressed")
			_spell_manager.cast_spell("shockwave")

		elif event.is_action("toggle_build_mode"):
			if state == Types.GameState.COMBAT or state == Types.GameState.WAVE_COUNTDOWN:
				print("[InputManager] toggle_build_mode → entering BUILD_MODE")
				GameManager.enter_build_mode()
			elif state == Types.GameState.BUILD_MODE:
				print("[InputManager] toggle_build_mode → exiting BUILD_MODE")
				GameManager.exit_build_mode()
			else:
				print("[InputManager] toggle_build_mode ignored — state=%s" % Types.GameState.keys()[state])

		elif event.is_action("cancel"):
			if state == Types.GameState.BUILD_MODE:
				print("[InputManager] cancel → exiting BUILD_MODE")
				GameManager.exit_build_mode()


## World point on Y=0 under the mouse (no enemy bias). Used for build slot picking.
func _get_ground_plane_intersection() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	var ground_plane := Plane(Vector3.UP, 0.0)
	var intersection: Variant = ground_plane.intersects_ray(ray_origin, ray_normal)
	if intersection != null:
		return intersection as Vector3
	return Vector3.ZERO


## Combat aim: raycast enemies first (hits flying units at real height), else ground plane.
func _get_fire_aim_position() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	var ray_end: Vector3 = ray_origin + ray_normal * _RAY_MAX_DISTANCE

	var world: World3D = get_viewport().world_3d
	if world == null:
		return Vector3.ZERO
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	var pq: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	pq.collision_mask = _ENEMY_COLLISION_MASK
	var hit: Dictionary = space.intersect_ray(pq)
	if not hit.is_empty():
		var collider: Object = hit.get("collider", null)
		if collider is EnemyBase:
			var enemy: EnemyBase = collider as EnemyBase
			return enemy.global_position

	return _get_ground_plane_intersection()


func _handle_build_mode_left_click() -> void:
	var slot_index: int = _get_clicked_hex_slot_index()
	if slot_index < 0:
		return

	var slot_data: Dictionary = _hex_grid.get_slot_data(slot_index)
	var is_occupied: bool = bool(slot_data.get("is_occupied", false))
	print("[InputManager] BUILD_MODE left click → slot=%d occupied=%s" % [slot_index, str(is_occupied)])
	if is_occupied:
		_build_menu.open_for_sell_slot(slot_index, slot_data)
	else:
		_build_menu.open_for_slot(slot_index)


func _get_clicked_hex_slot_index() -> int:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	var ray_end: Vector3 = ray_origin + ray_normal * _RAY_MAX_DISTANCE

	var world: World3D = get_viewport().world_3d
	if world == null:
		return -1
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = _HEX_SLOT_COLLISION_MASK

	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return -1

	var collider: Object = hit.get("collider", null)
	if collider is Area3D:
		var slot_name: String = (collider as Area3D).name
		if slot_name.begins_with("HexSlot_"):
			var index_text: String = slot_name.trim_prefix("HexSlot_")
			return index_text.to_int()

	# Fallback for non-standard slot naming (keeps behavior robust).
	var hit_pos: Vector3 = hit.get("position", Vector3.ZERO)
	return _hex_grid.get_nearest_slot_index(hit_pos)
