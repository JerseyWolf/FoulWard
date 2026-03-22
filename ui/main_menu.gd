# ui/main_menu.gd
# MainMenu — start screen. Zero game logic.

class_name MainMenu
extends Control

@onready var _start_button: Button = $StartButton
@onready var _settings_button: Button = $SettingsButton
@onready var _quit_button: Button = $QuitButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	GameManager.start_new_game()


func _on_settings_pressed() -> void:
	pass  # POST-MVP: open settings screen.


func _on_quit_pressed() -> void:
	get_tree().quit()

