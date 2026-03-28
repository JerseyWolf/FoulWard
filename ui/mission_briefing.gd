## MissionBriefing — Shows mission number and BEGIN button to start the wave countdown; zero game logic.
extends Control

@onready var mission_label: Label = $MissionLabel
@onready var begin_button: Button = $BeginButton

func _ready() -> void:
	SignalBus.mission_started.connect(_on_mission_started)
	begin_button.pressed.connect(_on_begin_pressed)

func _on_mission_started(mission_number: int) -> void:
	mission_label.text = "MISSION %d" % mission_number

func _on_begin_pressed() -> void:
	if GameManager.get_game_state() != Types.GameState.MISSION_BRIEFING:
		return
	GameManager.start_wave_countdown()
