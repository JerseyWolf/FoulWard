# scripts/sim_bot.gd
# SimBot — headless simulation bot. Observes signals and can drive mercenary APIs (Prompt 12).

class_name SimBot
extends Node

var _is_active: bool = false
var is_active: bool:
	get:
		return _is_active

var _strategy: Types.StrategyProfile = Types.StrategyProfile.BALANCED
var _log: Array[String] = []

var _tower: Tower = null
var _wave_manager: WaveManager = null
var _spell_manager: SpellManager = null
var _hex_grid: HexGrid = null


func activate(strategy: Types.StrategyProfile = Types.StrategyProfile.BALANCED) -> void:
	if _is_active:
		return
	_is_active = true
	_strategy = strategy
	_log.clear()

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
	SignalBus.mercenary_recruited.connect(_on_mercenary_recruited)

	GameManager.start_new_game()


func get_log() -> Array[String]:
	return _log.duplicate()


func decide_mercenaries() -> void:
	var preview: Array = CampaignManager.preview_mercenary_offers_for_day(
			CampaignManager.current_day,
			CampaignManager.get_owned_allies()
	)
	_log.append("preview_offers_count=%d" % preview.size())
	var result: Dictionary = CampaignManager.auto_select_best_allies(
			_strategy,
			CampaignManager.get_current_offers(),
			CampaignManager.get_owned_allies(),
			2,
			EconomyManager.get_gold(),
			EconomyManager.get_building_material(),
			EconomyManager.get_research_material()
	)
	var indices: Array = result.get("recommended_offer_indices", []) as Array
	var sorted_idx: Array[int] = []
	for v: Variant in indices:
		sorted_idx.append(int(v))
	sorted_idx.sort()
	sorted_idx.reverse()
	for idx: int in sorted_idx:
		var ok: bool = CampaignManager.purchase_mercenary_offer(idx)
		_log.append("purchase_index_%d=%s" % [idx, str(ok)])
	var raw_active: Variant = result.get("recommended_active_allies", [])
	var act: Array[String] = []
	if raw_active is Array:
		for item: Variant in raw_active as Array:
			act.append(str(item))
	CampaignManager.set_active_allies_from_list(act)


func deactivate() -> void:
	if not _is_active:
		return
	_is_active = false
	if SignalBus.wave_cleared.is_connected(_on_wave_cleared):
		SignalBus.wave_cleared.disconnect(_on_wave_cleared)
	if SignalBus.mission_won.is_connected(_on_mission_won):
		SignalBus.mission_won.disconnect(_on_mission_won)
	if SignalBus.mission_failed.is_connected(_on_mission_failed):
		SignalBus.mission_failed.disconnect(_on_mission_failed)
	if SignalBus.all_waves_cleared.is_connected(_on_all_waves_cleared):
		SignalBus.all_waves_cleared.disconnect(_on_all_waves_cleared)
	if SignalBus.game_state_changed.is_connected(_on_game_state_changed):
		SignalBus.game_state_changed.disconnect(_on_game_state_changed)
	if SignalBus.mission_started.is_connected(_on_mission_started):
		SignalBus.mission_started.disconnect(_on_mission_started)
	if SignalBus.mercenary_recruited.is_connected(_on_mercenary_recruited):
		SignalBus.mercenary_recruited.disconnect(_on_mercenary_recruited)


func bot_enter_build_mode() -> void:
	GameManager.enter_build_mode()


func bot_exit_build_mode() -> void:
	GameManager.exit_build_mode()


func bot_place_building(slot: int, building_type: Types.BuildingType) -> bool:
	if _hex_grid == null:
		push_error("SimBot.bot_place_building: HexGrid reference is null.")
		return false
	return _hex_grid.place_building(slot, building_type)


func bot_cast_spell(spell_id: String) -> bool:
	if _spell_manager == null:
		push_error("SimBot.bot_cast_spell: SpellManager reference is null.")
		return false
	return _spell_manager.cast_spell(spell_id)


func bot_fire_crossbow(target: Vector3) -> void:
	if _tower == null:
		push_error("SimBot.bot_fire_crossbow: Tower reference is null.")
		return
	_tower.fire_crossbow(target)


func bot_advance_wave() -> void:
	if _wave_manager == null:
		push_error("SimBot.bot_advance_wave: WaveManager reference is null.")
		return
	_wave_manager.force_spawn_wave(GameManager.get_current_wave() + 1)


func _on_wave_cleared(_wave_number: int) -> void:
	pass


func _on_mission_won(_mission_number: int) -> void:
	decide_mercenaries()


func _on_mission_failed(_mission_number: int) -> void:
	deactivate()


func _on_all_waves_cleared() -> void:
	pass


func _on_game_state_changed(
		_old_state: Types.GameState,
		_new_state: Types.GameState
) -> void:
	pass


func _on_mission_started(_mission_number: int) -> void:
	pass


func _on_mercenary_recruited(ally_id: String) -> void:
	_log.append("mercenary_recruited:%s" % ally_id)
