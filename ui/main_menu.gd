## MainMenu — Title screen with Start, Settings, and Quit buttons; zero game logic.
# ui/main_menu.gd
# MainMenu — start screen. Zero game logic.

class_name MainMenu
extends Control

@onready var _resume_button: Button = $ResumeButton
@onready var _start_button: Button = $StartButton
@onready var _endless_run_button: Button = $EndlessRunButton
@onready var _chronicle_button: Button = $ChronicleButton
@onready var _settings_button: Button = $SettingsButton
@onready var _quit_button: Button = $QuitButton

func _ready() -> void:
	_resume_button.visible = SaveManager.has_resumable_attempt()
	_resume_button.pressed.connect(_on_resume_pressed)
	_start_button.pressed.connect(_on_start_pressed)
	_endless_run_button.pressed.connect(_on_endless_run_pressed)
	_chronicle_button.pressed.connect(_on_chronicle_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_resume_pressed() -> void:
	if not SaveManager.load_slot(0):
		return
	var old: Types.GameState = Types.GameState.MAIN_MENU
	SignalBus.game_state_changed.emit(old, GameManager.get_game_state())


func _on_start_pressed() -> void:
	CampaignManager.is_endless_mode = false
	SaveManager.start_new_attempt()
	GameManager.start_new_game()


func _on_endless_run_pressed() -> void:
	CampaignManager.start_endless_run()
	SaveManager.start_new_attempt()
	GameManager.start_new_game()


func _on_chronicle_pressed() -> void:
	var ui: CanvasLayer = get_parent() as CanvasLayer
	if ui == null:
		return
	var scene: PackedScene = load("res://scenes/ui/chronicle_screen.tscn") as PackedScene
	if scene == null:
		return
	var panel: Control = scene.instantiate() as Control
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(panel)
	hide()
	panel.tree_exited.connect(func() -> void: show())


func _on_settings_pressed() -> void:
	var ui: CanvasLayer = get_parent() as CanvasLayer
	if ui == null:
		return
	var scene: PackedScene = load("res://scenes/ui/settings_screen.tscn") as PackedScene
	if scene == null:
		return
	var panel: Control = scene.instantiate() as Control
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(panel)
	hide()
	panel.tree_exited.connect(func() -> void: show())


func _on_quit_pressed() -> void:
	get_tree().quit()
