extends Control

@onready var mission_label: Label = $MissionLabel
@onready var begin_button: Button = $BeginButton

func _ready() -> void:
	SignalBus.mission_started.connect(_on_mission_started)
	begin_button.pressed.connect(_on_begin_pressed)
	call_deferred("_auto_begin")

func _auto_begin() -> void:
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		_on_begin_pressed()

func _on_mission_started(mission_number: int) -> void:
	mission_label.text = "MISSION %d" % mission_number

func _on_begin_pressed() -> void:
	GameManager.start_wave_countdown()
