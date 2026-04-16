class_name DestructionEffect
extends Node3D

const SHRINK_DURATION: float = 0.5


func play(world_pos: Vector3, _source_mesh: Mesh = null) -> void:
	global_position = world_pos
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, SHRINK_DURATION)
	tw.tween_callback(queue_free)
