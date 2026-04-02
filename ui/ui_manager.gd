## UIManager — Lightweight state router that shows/hides UI panels on game_state_changed and wires hub dialogue.
# ui/ui_manager.gd
# UIManager — lightweight panel router. Hub dialogue is delegated to DialoguePanel + DialogueManager.
#
# Credit: Godot Engine Official Documentation — CanvasLayer
# https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html
# License: CC-BY-3.0
# Adapted: Control show/hide routing per game state.

class_name UIManager
extends Control

@onready var _hud: Control = get_node_or_null("/root/Main/UI/HUD")
@onready var _build_menu: Control = get_node_or_null("/root/Main/UI/BuildMenu")
@onready var _between_mission_screen: Control = get_node_or_null(
	"/root/Main/UI/BetweenMissionScreen"
)
@onready var _main_menu: Control = get_node_or_null("/root/Main/UI/MainMenu")
@onready var _mission_briefing: Control = get_node_or_null("/root/Main/UI/MissionBriefing")
@onready var _end_screen: Control = get_node_or_null("/root/Main/UI/EndScreen")

@onready var _hub: Control = get_node_or_null("/root/Main/UI/Hub") as Control
var _dialogue_panel: DialoguePanel = null

var _pending_dialogue_character_ids: Array[String] = []
var _pending_panel_dialogue_speaker_names: Array[String] = []
var _pending_panel_dialogue_entries: Array[DialogueEntry] = []

# Re-fetch hub for safety: @onready can be null in some headless/GdUnit stubs.
func _get_hub() -> Control:
	var hub_by_path: Control = get_node_or_null("/root/Main/UI/Hub") as Control
	if hub_by_path != null:
		return hub_by_path

	var ui_node: Node = get_node_or_null("/root/Main/UI")
	if ui_node == null:
		return null

	for child: Node in ui_node.get_children():
		if child.name.begins_with("Hub"):
			var hub_candidate: Control = child as Control
			if hub_candidate != null:
				return hub_candidate

	return null

func _get_dialogue_panel() -> DialoguePanel:
	if _dialogue_panel != null and is_instance_valid(_dialogue_panel):
		return _dialogue_panel
	_dialogue_panel = get_node_or_null("DialoguePanel") as DialoguePanel
	return _dialogue_panel

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	DialogueManager.dialogue_line_finished.connect(_on_dialogue_line_finished)

	# Wire the hub with stable references so it can route tab changes + dialogue.
	var hub: Control = _get_hub()
	if hub != null:
		var bms: BetweenMissionScreen = _between_mission_screen as BetweenMissionScreen
		if hub.has_method("set_between_mission_screen"):
			hub.set_between_mission_screen(bms)
		if hub.has_method("_set_ui_manager"):
			hub._set_ui_manager(self)

	# Sync to current state immediately for hot-reload safety.
	_apply_state(GameManager.get_game_state())

	# Ensure hub visibility is correct when syncing to an already-active state.
	var state_now: Types.GameState = GameManager.get_game_state()
	if state_now == Types.GameState.BETWEEN_MISSIONS or state_now == Types.GameState.ENDLESS:
		var hub2: Control = _get_hub()
		if hub2 != null:
			if hub2.has_method("open_hub"):
				hub2.open_hub()
			else:
				hub2.visible = true
	else:
		var hub3: Control = _get_hub()
		if hub3 != null:
			if hub3.has_method("close_hub"):
				hub3.close_hub()
			else:
				hub3.visible = false


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	var hub: Control = _get_hub()
	# Deterministic routing for tests + gameplay:
	# - Always hide hub + clear dialogue on any state change
	# - Re-open hub only when entering BETWEEN_MISSIONS from a non-between state
	#   (prevents ambiguous argument ordering from leaving the hub stuck open).
	if hub != null:
		hub.visible = false

	clear_dialogue()
	var dp: DialoguePanel = _get_dialogue_panel()
	if dp != null:
		dp.visible = false

	_apply_state(new_state)

	var was_between: bool = (
			_old_state == Types.GameState.BETWEEN_MISSIONS
			or _old_state == Types.GameState.ENDLESS
	)
	var is_between: bool = (
			new_state == Types.GameState.BETWEEN_MISSIONS
			or new_state == Types.GameState.ENDLESS
	)
	if not was_between and is_between:
		if hub != null:
			if hub.has_method("open_hub"):
				hub.open_hub()
			else:
				hub.visible = true


## Single source of truth for UI panel visibility.
func _apply_state(state: Types.GameState) -> void:
	if not is_instance_valid(_hud):
		return
	_hud.hide()
	if is_instance_valid(_build_menu):
		_build_menu.hide()
	if is_instance_valid(_between_mission_screen):
		_between_mission_screen.hide()
	if is_instance_valid(_main_menu):
		_main_menu.hide()
	if is_instance_valid(_mission_briefing):
		_mission_briefing.hide()
	if is_instance_valid(_end_screen):
		_end_screen.hide()

	match state:
		Types.GameState.MAIN_MENU:
			if is_instance_valid(_main_menu):
				_main_menu.show()

		Types.GameState.MISSION_BRIEFING:
			if is_instance_valid(_mission_briefing):
				_mission_briefing.show()

		Types.GameState.COMBAT, \
		Types.GameState.WAVE_COUNTDOWN:
			_hud.show()

		Types.GameState.BUILD_MODE:
			_hud.show()

		Types.GameState.BETWEEN_MISSIONS, \
		Types.GameState.ENDLESS:
			if is_instance_valid(_between_mission_screen):
				_between_mission_screen.show()

		Types.GameState.MISSION_WON, \
		Types.GameState.GAME_WON, \
		Types.GameState.MISSION_FAILED, \
		Types.GameState.GAME_OVER:
			if is_instance_valid(_end_screen):
				_end_screen.show()


func _ensure_dialogue_panel() -> void:
	if _get_dialogue_panel() != null:
		return

	var scene: PackedScene = load("res://ui/dialogue_panel.tscn") as PackedScene
	_dialogue_panel = scene.instantiate() as DialoguePanel
	add_child(_dialogue_panel)


func show_dialogue_for_character(character_id: String) -> void:
	_ensure_dialogue_panel()
	if _dialogue_panel.visible:
		_pending_dialogue_character_ids.append(character_id)
		return
	var entry: DialogueEntry = DialogueManager.request_entry_for_character(character_id)
	if entry != null:
		var speaker: String = _get_display_name(character_id)
		show_dialogue(speaker, entry)
	else:
		_flush_pending_dialogue()


func _on_dialogue_line_finished(_entry_id: String, _character_id: String) -> void:
	_flush_pending_dialogue()


func _flush_pending_dialogue() -> void:
	_ensure_dialogue_panel()

	# 1) Hub-triggered dialogue queued via show_dialogue().
	while _pending_panel_dialogue_entries.size() > 0:
		var speaker: String = _pending_panel_dialogue_speaker_names.pop_front()
		var next_entry: DialogueEntry = _pending_panel_dialogue_entries.pop_front()
		if next_entry != null:
			_dialogue_panel.show_entry(speaker, next_entry)
			return

	# 2) Legacy queued dialogues based on character_id.
	while _pending_dialogue_character_ids.size() > 0:
		var next_id: String = _pending_dialogue_character_ids.pop_front()
		var entry: DialogueEntry = DialogueManager.request_entry_for_character(next_id)
		if entry != null:
			var speaker2: String = _get_display_name(next_id)
			_dialogue_panel.show_entry(speaker2, entry)
			return


func show_dialogue(display_name: String, entry: DialogueEntry) -> void:
	_ensure_dialogue_panel()
	if entry == null:
		return

	# If something is already visible, queue until the current chain finishes.
	if _dialogue_panel.visible:
		_pending_panel_dialogue_speaker_names.append(display_name)
		_pending_panel_dialogue_entries.append(entry)
		return

	_dialogue_panel.show_entry(display_name, entry)


func clear_dialogue() -> void:
	_pending_dialogue_character_ids.clear()
	_pending_panel_dialogue_speaker_names.clear()
	_pending_panel_dialogue_entries.clear()

	var dp: DialoguePanel = _get_dialogue_panel()
	if dp != null:
		dp.clear_dialogue()


func _get_display_name(character_id: String) -> String:
	match character_id:
		"FLORENCE":
			return "Florence"
		"COMPANION_MELEE":
			return "Arnulf"
		"SPELL_RESEARCHER":
			return "Sybil"
		"WEAPONS_ENGINEER":
			return "Weapons Engineer"
		"ENCHANTER":
			return "Enchanter"
		"MERCHANT":
			return "Merchant"
		"MERCENARY_COMMANDER":
			return "Commander"
		_:
			return character_id
