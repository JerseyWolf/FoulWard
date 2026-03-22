# ui/end_screen.gd
# EndScreen — shown on MISSION_WON, GAME_WON, MISSION_FAILED.
# Zero game logic.

class_name EndScreen
extends Control

@onready var _message_label: Label = $MessageLabel
@onready var _restart_button: Button = $RestartButton
@onready var _quit_button: Button = $QuitButton

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	match new_state:
		Types.GameState.GAME_WON:
			_message_label.text = "YOU SURVIVED 5 MISSIONS"
		Types.GameState.MISSION_WON:
			_message_label.text = "MISSION %d COMPLETE" % GameManager.get_current_mission()
		Types.GameState.MISSION_FAILED:
			_message_label.text = "TOWER DESTROYED"
		_:
			pass


func _on_restart_pressed() -> void:
	GameManager.start_new_game()


func _on_quit_pressed() -> void:
	get_tree().quit()

