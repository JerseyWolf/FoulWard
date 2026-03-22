# scripts/sim_bot.gd
# SimBot — headless simulation bot stub. Replaces InputManager.
# MVP: proves every public API method is callable without UI nodes.
# Zero strategy logic. POST-MVP strategies are comments only.
#
# POST-MVP strategies (do NOT implement in MVP):
#   - ArrowTowerOnly: places only Arrow Towers, observes outcome
#   - FireBuildingsOnly: places only Fire Braziers, observes outcome
#   - MaxArnulf: does nothing (Arnulf is autonomous), observes outcome

class_name SimBot
extends Node

var _is_active: bool = false

var _tower: Tower = null
var _wave_manager: WaveManager = null
var _spell_manager: SpellManager = null
var _hex_grid: HexGrid = null

# ── Public API ────────────────────────────────────────────────────────────

## Activates the bot. Resolves node refs, connects observation signals,
## then starts a new game. All refs use get_node_or_null (never crashes).
func activate() -> void:
	_is_active = true

	_tower = get_node_or_null("/root/Main/Tower") as Tower
	_wave_manager = get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager
	_spell_manager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	_hex_grid = get_node_or_null("/root/Main/HexGrid") as HexGrid

	SignalBus.wave_cleared.connect(_on_wave_cleared)
	SignalBus.mission_won.connect(_on_mission_won)
	SignalBus.mission_failed.connect(_on_mission_failed)
	SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	SignalBus.mission_started.connect(_on_mission_started)

	GameManager.start_new_game()


func bot_enter_build_mode() -> void:
	GameManager.enter_build_mode()


func bot_exit_build_mode() -> void:
	GameManager.exit_build_mode()


## Places a building on a hex slot via HexGrid.
func bot_place_building(slot: int, building_type: Types.BuildingType) -> bool:
	if _hex_grid == null:
		push_error("SimBot.bot_place_building: HexGrid reference is null.")
		return false
	return _hex_grid.place_building(slot, building_type)


## Casts a spell via SpellManager.
func bot_cast_spell(spell_id: String) -> bool:
	if _spell_manager == null:
		push_error("SimBot.bot_cast_spell: SpellManager reference is null.")
		return false
	return _spell_manager.cast_spell(spell_id)


## Fires the crossbow at a world position via Tower.
func bot_fire_crossbow(target: Vector3) -> void:
	if _tower == null:
		push_error("SimBot.bot_fire_crossbow: Tower reference is null.")
		return
	_tower.fire_crossbow(target)


## Forces a wave to spawn immediately via WaveManager.
func bot_advance_wave() -> void:
	if _wave_manager == null:
		push_error("SimBot.bot_advance_wave: WaveManager reference is null.")
		return
	_wave_manager.force_spawn_wave(GameManager.get_current_wave() + 1)

# ── Signal observers (stub — no strategy logic in MVP) ────────────────────

func _on_wave_cleared(_wave_number: int) -> void:
	pass

func _on_mission_won(_mission_number: int) -> void:
	pass

func _on_mission_failed(_mission_number: int) -> void:
	pass

func _on_all_waves_cleared() -> void:
	pass

func _on_game_state_changed(
		_old_state: Types.GameState,
		_new_state: Types.GameState
) -> void:
	pass

func _on_mission_started(_mission_number: int) -> void:
	pass

