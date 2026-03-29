## terrain_zone.gd
## Area3D speed-modifier zone; emits SignalBus when enemies enter/exit.

class_name TerrainZone
extends Area3D

@export var speed_multiplier: float = 0.6
@export var terrain_effect: Types.TerrainEffect = Types.TerrainEffect.SLOW


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	SignalBus.enemy_entered_terrain_zone.emit(body, speed_multiplier)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	SignalBus.enemy_exited_terrain_zone.emit(body, speed_multiplier)
