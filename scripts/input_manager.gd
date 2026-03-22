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

var _selected_slot_index: int = -1

# ─────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	var state: Types.GameState = GameManager.get_game_state()

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if state == Types.GameState.COMBAT:
					var aim: Vector3 = _get_aim_position()
					if aim != Vector3.ZERO:
						_tower.fire_crossbow(aim)

			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				if state == Types.GameState.COMBAT:
					var aim: Vector3 = _get_aim_position()
					if aim != Vector3.ZERO:
						_tower.fire_rapid_missile(aim)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("cast_shockwave"):
			_spell_manager.cast_spell("shockwave")

		elif event.is_action("toggle_build_mode"):
			if state == Types.GameState.COMBAT or state == Types.GameState.WAVE_COUNTDOWN:
				GameManager.enter_build_mode()
			elif state == Types.GameState.BUILD_MODE:
				GameManager.exit_build_mode()

		elif event.is_action("cancel"):
			if state == Types.GameState.BUILD_MODE:
				GameManager.exit_build_mode()


## Returns the world-space Vector3 on the Y=0 ground plane under the mouse.
## Returns Vector3.ZERO on miss or when ray is parallel to the ground.
func _get_aim_position() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	var ground_plane := Plane(Vector3.UP, 0.0)
	var intersection: Variant = ground_plane.intersects_ray(ray_origin, ray_normal)
	if intersection != null:
		return intersection as Vector3
	return Vector3.ZERO

