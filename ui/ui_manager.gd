# ui/ui_manager.gd
# UIManager — lightweight panel router; dialogue display is delegated to DialogueUI + DialogueManager.
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
@onready var _mission_briefing: Control = get_node("/root/Main/UI/MissionBriefing")
@onready var _end_screen: Control = get_node("/root/Main/UI/EndScreen")

var _dialogue_ui: DialogueUI = null
var _pending_dialogue_character_ids: Array[String] = []

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	DialogueManager.dialogue_line_finished.connect(_on_dialogue_line_finished)
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
	_mission_briefing.hide()
	_end_screen.hide()

	match state:
		Types.GameState.MAIN_MENU:
			_main_menu.show()

		Types.GameState.MISSION_BRIEFING:
			_mission_briefing.show()

		Types.GameState.COMBAT, \
		Types.GameState.WAVE_COUNTDOWN:
			_hud.show()

		Types.GameState.BUILD_MODE:
			_hud.show()
			# BuildMenu is shown only after selecting a hex slot (see `BuildMenu.open_for_slot()`).
			# Keeping it hidden at build-mode entry prevents it from covering most of the grid.

		Types.GameState.BETWEEN_MISSIONS:
			_between_mission_screen.show()

		Types.GameState.MISSION_WON, \
		Types.GameState.GAME_WON, \
		Types.GameState.MISSION_FAILED:
			_end_screen.show()


func _ensure_dialogue_ui() -> void:
	if _dialogue_ui == null:
		var scene: PackedScene = load("res://ui/dialogueui.tscn") as PackedScene
		_dialogue_ui = scene.instantiate() as DialogueUI
		add_child(_dialogue_ui)


func show_dialogue_for_character(character_id: String) -> void:
	_ensure_dialogue_ui()
	if _dialogue_ui.visible:
		_pending_dialogue_character_ids.append(character_id)
		return
	var entry: DialogueEntry = DialogueManager.request_entry_for_character(character_id)
	if entry != null:
		_dialogue_ui.show_entry(entry)
	else:
		_flush_pending_dialogue()


func _on_dialogue_line_finished(_entry_id: String, _character_id: String) -> void:
	_flush_pending_dialogue()


func _flush_pending_dialogue() -> void:
	_ensure_dialogue_ui()
	while _pending_dialogue_character_ids.size() > 0:
		var next_id: String = _pending_dialogue_character_ids.pop_front()
		var entry: DialogueEntry = DialogueManager.request_entry_for_character(next_id)
		if entry != null:
			_dialogue_ui.show_entry(entry)
			return

