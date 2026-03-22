# ui/ui_manager.gd
# UIManager — lightweight panel router. Zero game logic.
#
# Credit: Godot Engine Official Documentation — CanvasLayer
# https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html
# License: CC-BY-3.0
# Adapted: Control show/hide routing per game state.

class_name UIManager
extends Control

@onready var _hud: Control = get_node("/root/Main/UI/HUD")
@onready var _build_menu: Control = get_node("/root/Main/UI/BuildMenu")
@onready var _between_mission_screen: Control = get_node(
	"/root/Main/UI/BetweenMissionScreen"
)
@onready var _main_menu: Control = get_node("/root/Main/UI/MainMenu")
@onready var _end_screen: Control = get_node("/root/Main/UI/EndScreen")

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	# Sync to current state immediately for hot-reload safety.
	_apply_state(GameManager.get_game_state())


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	_apply_state(new_state)


## Single source of truth for UI panel visibility.
func _apply_state(state: Types.GameState) -> void:
	_hud.hide()
	_build_menu.hide()
	_between_mission_screen.hide()
	_main_menu.hide()
	_end_screen.hide()

	match state:
		Types.GameState.MAIN_MENU:
			_main_menu.show()

		Types.GameState.MISSION_BRIEFING, \
		Types.GameState.COMBAT, \
		Types.GameState.WAVE_COUNTDOWN:
			_hud.show()

		Types.GameState.BUILD_MODE:
			_hud.show()
			_build_menu.show()

		Types.GameState.BETWEEN_MISSIONS:
			_between_mission_screen.show()

		Types.GameState.MISSION_WON, \
		Types.GameState.GAME_WON, \
		Types.GameState.MISSION_FAILED:
			_end_screen.show()

