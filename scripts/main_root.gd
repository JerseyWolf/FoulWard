# scripts/main_root.gd
# Root scene: enforce window stretch after the scene tree is ready (some editor /
# plugin init order can leave content scale feeling wrong until the Window is
# fully configured).

extends Node3D

func _ready() -> void:
	call_deferred("_apply_root_window_stretch")


func _apply_root_window_stretch() -> void:
	var w: Window = get_tree().root as Window
	if w == null:
		return
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	w.content_scale_factor = 1.0
