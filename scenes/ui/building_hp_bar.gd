class_name BuildingHpBar
extends Node3D

@onready var _hp_bar: ProgressBar = $SubViewport/HpBar
@onready var _sprite: Sprite3D = $Sprite3D


func setup(health_comp: HealthComponent) -> void:
	if health_comp == null:
		push_warning("BuildingHpBar.setup: null HealthComponent")
		return
	_hp_bar.max_value = health_comp.max_hp
	_hp_bar.value = health_comp.current_hp
	if not health_comp.health_changed.is_connected(_on_health_changed):
		health_comp.health_changed.connect(_on_health_changed)
	visible = false


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = current_hp
	visible = current_hp < max_hp
