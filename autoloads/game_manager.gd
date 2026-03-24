## game_manager.gd
## State machine for overall game flow: missions, waves, and build mode in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

const TOTAL_MISSIONS: int = 5
# Temporary dev/testing cap so we can reach "mission won" quickly.
const WAVES_PER_MISSION: int = 3

var current_mission: int = 1
var current_wave: int = 0
var game_state: Types.GameState = Types.GameState.MAIN_MENU

func _ready() -> void:
	print("[GameManager] _ready: initial state=%s" % Types.GameState.keys()[game_state])
	SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
	SignalBus.tower_destroyed.connect(_on_tower_destroyed)
	var shop: Node = get_node_or_null("/root/ShopManager")
	var tower: Node = get_node_or_null("/root/Main/Tower")
	if shop != null and tower != null and shop.has_method("initialize_tower"):
		shop.initialize_tower(tower)
		print("[GameManager] _ready: ShopManager wired to Tower")

# ── Public API ─────────────────────────────────────────────────────────────────

func start_new_game() -> void:
	print("[GameManager] start_new_game: mission=1  gold=%d mat=%d" % [
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	current_mission = 1
	current_wave = 0
	EconomyManager.reset_to_defaults()
	# Ensure research unlock state is reset for a new run.
	# In dev mode, ResearchManager can choose to unlock all nodes to make
	# content reachable for testing (e.g., tower availability).
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm != null:
		rm.reset_to_defaults()
	var weapon_upgrade_manager: Node = get_node_or_null("/root/Main/Managers/WeaponUpgradeManager")
	if weapon_upgrade_manager != null:
		weapon_upgrade_manager.reset_to_defaults()
	_transition_to(Types.GameState.COMBAT)
	SignalBus.mission_started.emit(current_mission)
	_apply_shop_mission_start_consumables()
	_begin_mission_wave_sequence()

func start_next_mission() -> void:
	current_mission += 1
	current_wave = 0
	print("[GameManager] start_next_mission: now mission=%d" % current_mission)
	_transition_to(Types.GameState.MISSION_BRIEFING)
	SignalBus.mission_started.emit(current_mission)
	# Wave sequence starts in start_wave_countdown() after briefing (MVP: player confirms).

func start_wave_countdown() -> void:
	assert(game_state == Types.GameState.MISSION_BRIEFING, "start_wave_countdown called from invalid state")
	_transition_to(Types.GameState.COMBAT)
	_apply_shop_mission_start_consumables()
	# Single source of truth for countdown duration: WaveManager emits wave_countdown_started.
	_begin_mission_wave_sequence()

func enter_build_mode() -> void:
	print("[GameManager] enter_build_mode: from=%s" % Types.GameState.keys()[game_state])
	assert(
		game_state == Types.GameState.COMBAT or game_state == Types.GameState.WAVE_COUNTDOWN,
		"enter_build_mode called from invalid state: %s" % Types.GameState.keys()[game_state]
	)
	Engine.time_scale = 0.1
	var old: Types.GameState = game_state
	game_state = Types.GameState.BUILD_MODE
	SignalBus.build_mode_entered.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.BUILD_MODE)

func exit_build_mode() -> void:
	print("[GameManager] exit_build_mode")
	Engine.time_scale = 1.0
	var old: Types.GameState = game_state
	game_state = Types.GameState.COMBAT
	SignalBus.build_mode_exited.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.COMBAT)

func get_game_state() -> Types.GameState:
	return game_state

func get_current_mission() -> int:
	return current_mission

func get_current_wave() -> int:
	return current_wave

# ── Private helpers ────────────────────────────────────────────────────────────

func _apply_shop_mission_start_consumables() -> void:
	var shop: ShopManager = get_node_or_null("/root/Main/Managers/ShopManager") as ShopManager
	if shop == null:
		return
	shop.apply_mission_start_consumables()


func _begin_mission_wave_sequence() -> void:
	var wave_manager: WaveManager = get_node_or_null(
		"/root/Main/Managers/WaveManager"
	) as WaveManager
	if wave_manager == null:
		push_error("GameManager: WaveManager not found at /root/Main/Managers/WaveManager")
		print("[GameManager] ERROR: WaveManager not found!")
		return
	print("[GameManager] _begin_mission_wave_sequence: mission=%d" % current_mission)
	wave_manager.max_waves = WAVES_PER_MISSION
	wave_manager.reset_for_new_mission()
	wave_manager.call_deferred("start_wave_sequence")

func _transition_to(new_state: Types.GameState) -> void:
	var old_name: String = Types.GameState.keys()[game_state]
	var new_name: String = Types.GameState.keys()[new_state]
	print("[GameManager] state: %s → %s" % [old_name, new_name])
	var old: Types.GameState = game_state
	game_state = new_state
	SignalBus.game_state_changed.emit(old, new_state)

func _on_all_waves_cleared() -> void:
	print("[GameManager] all_waves_cleared: awarding mission=%d resources" % current_mission)
	EconomyManager.add_gold(50 * current_mission)
	EconomyManager.add_building_material(3)
	EconomyManager.add_research_material(2)
	SignalBus.mission_won.emit(current_mission)

	if current_mission >= TOTAL_MISSIONS:
		_transition_to(Types.GameState.GAME_WON)
	else:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)

func _on_tower_destroyed() -> void:
	print("[GameManager] tower_destroyed → MISSION_FAILED")
	_transition_to(Types.GameState.MISSION_FAILED)
	SignalBus.mission_failed.emit(current_mission)
