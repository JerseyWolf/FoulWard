## game_manager.gd
## State machine for overall game flow: missions, waves, and build mode in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

const TOTAL_MISSIONS: int = 5
const WAVES_PER_MISSION: int = 10

var current_mission: int = 1
var current_wave: int = 0
var game_state: Types.GameState = Types.GameState.MAIN_MENU

func _ready() -> void:
	SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
	SignalBus.tower_destroyed.connect(_on_tower_destroyed)
	# Wire ShopManager with the Tower node for tower_repair effect injection.
	var shop: Node = get_node_or_null("/root/ShopManager")
	var tower: Node = get_node_or_null("/root/Main/Tower")
	if shop != null and tower != null and shop.has_method("initialize_tower"):
		shop.initialize_tower(tower)

# ── Public API ─────────────────────────────────────────────────────────────────

## Resets all session state and begins mission 1 in combat (skips briefing).
func start_new_game() -> void:
	current_mission = 1
	current_wave = 0
	EconomyManager.reset_to_defaults()
	_transition_to(Types.GameState.COMBAT)
	SignalBus.mission_started.emit(current_mission)
	_begin_mission_wave_sequence()

## Advances to the next mission. Called from BetweenMissionScreen "NEXT MISSION" button.
## Buildings and resources carry over — only wave counter is reset.
func start_next_mission() -> void:
	current_mission += 1
	current_wave = 0
	_transition_to(Types.GameState.MISSION_BRIEFING)
	SignalBus.mission_started.emit(current_mission)
	_begin_mission_wave_sequence()

func start_wave_countdown() -> void:
	assert(game_state == Types.GameState.MISSION_BRIEFING, "start_wave_countdown called from invalid state")
	var old: Types.GameState = game_state
	game_state = Types.GameState.COMBAT
	SignalBus.game_state_changed.emit(old, Types.GameState.COMBAT)
	SignalBus.wave_countdown_started.emit(current_wave + 1, 5.0)

## Slows time and enters build mode. Only valid from COMBAT or WAVE_COUNTDOWN.
func enter_build_mode() -> void:
	assert(
		game_state == Types.GameState.COMBAT or game_state == Types.GameState.WAVE_COUNTDOWN,
		"enter_build_mode called from invalid state: %s" % Types.GameState.keys()[game_state]
	)
	Engine.time_scale = 0.1
	var old: Types.GameState = game_state
	game_state = Types.GameState.BUILD_MODE
	SignalBus.build_mode_entered.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.BUILD_MODE)

## Restores normal time and returns to COMBAT.
## DEVIATION: Always restores to COMBAT rather than the prior state (WAVE_COUNTDOWN
## is treated as COMBAT for MVP simplicity).
func exit_build_mode() -> void:
	Engine.time_scale = 1.0
	var old: Types.GameState = game_state
	game_state = Types.GameState.COMBAT
	SignalBus.build_mode_exited.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.COMBAT)

## Returns the current GameState.
func get_game_state() -> Types.GameState:
	return game_state

## Returns the current mission number (1–5).
func get_current_mission() -> int:
	return current_mission

## Returns the current wave number (0 = pre-wave, 1–10 during combat).
func get_current_wave() -> int:
	return current_wave

# ── Private helpers ────────────────────────────────────────────────────────────

func _begin_mission_wave_sequence() -> void:
	var wave_manager: WaveManager = get_node_or_null(
		"/root/Main/Managers/WaveManager"
	) as WaveManager
	if wave_manager == null:
		push_error(
			"GameManager: WaveManager not found at /root/Main/Managers/WaveManager"
		)
		return
	wave_manager.reset_for_new_mission()
	wave_manager.start_wave_sequence()

func _transition_to(new_state: Types.GameState) -> void:
	var old: Types.GameState = game_state
	game_state = new_state
	SignalBus.game_state_changed.emit(old, new_state)

func _on_all_waves_cleared() -> void:
	# Award post-mission resources before announcing the win.
	EconomyManager.add_gold(50 * current_mission)
	EconomyManager.add_building_material(3)
	EconomyManager.add_research_material(2)
	SignalBus.mission_won.emit(current_mission)

	if current_mission >= TOTAL_MISSIONS:
		_transition_to(Types.GameState.GAME_WON)
	else:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)

func _on_tower_destroyed() -> void:
	_transition_to(Types.GameState.MISSION_FAILED)
	SignalBus.mission_failed.emit(current_mission)

