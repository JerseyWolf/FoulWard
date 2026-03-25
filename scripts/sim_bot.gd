# scripts/sim_bot.gd
# PRE_GENERATION_VERIFICATION: Mentally ran the required checklist for this file
# (signal wiring, no UI dependencies, data-driven build/spell via StrategyProfile).
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

# ---------------------------------------------------------------------------
# Prompt 16 Phase 2: StrategyProfile-driven headless runs + CSV logging.
# ---------------------------------------------------------------------------
var _profile: StrategyProfile = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_run_index: int = 0
var _base_seed: int = 0

var _research_manager: ResearchManager = null

var _logger: Node = null
var _csv_columns: Array[String] = []
var _metrics: Dictionary = {}

var _resource_prev: Dictionary = {} # Types.ResourceType -> int
var _run_done: bool = false

var _decision_frame: int = 0
var _last_spell_eval_frame: int = -1

const _SPELL_ID_SHOCKWAVE: String = "shockwave"
const _CSV_LOG_DIR: String = "user://simbot_logs"
const _CSV_DEFAULT_FILENAME: String = "simbot_balance_log.csv"

func _ready() -> void:
	# CSV IO is run-scoped (run_single/run_batch). _ready only allocates logger + columns.
	if _csv_columns.is_empty():
		_csv_columns = _build_csv_columns()


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

# ============================================================================
# Prompt 16 Phase 2: StrategyProfile-driven headless simulation
# ============================================================================

## Runs one mission headlessly using the selected StrategyProfile.
## Returns per-run metrics used by balance logging and tests.
func run_single(profile_id: String, run_index: int, seed_value: int) -> Dictionary:
	# Arrange
	deactivate() # ensure legacy mercenary handlers are not active

	_activate_for_run(profile_id, run_index, seed_value)
	_reset_managers_for_run()
	_capture_starting_resource_state()
	_connect_metric_signals()

	_start_new_game_for_run()

	# Act
	await _run_loop_until_mission_finished()

	# Cleanup
	_disconnect_metric_signals()
	_finalize_metrics()
	return _metrics.duplicate(true)

## Runs multiple missions for one profile and appends results to CSV.
func run_batch(profile_id: String, runs: int, base_seed: int = 0, csv_path: String = "") -> void:
	if runs <= 0:
		return

	if _csv_columns.is_empty():
		_csv_columns = _build_csv_columns()

	if csv_path == "":
		csv_path = _get_default_csv_path()
	
	_csv_write_header_if_needed(csv_path, _csv_columns)

	for i: int in range(runs):
		var run_seed: int = base_seed + i
		var row: Dictionary = await run_single(profile_id, i, run_seed)
		_csv_append_row(csv_path, _csv_columns, row)

func _get_default_csv_path() -> String:
	return _CSV_LOG_DIR + "/" + _CSV_DEFAULT_FILENAME

func _ensure_csv_dir_exists() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("simbot_logs"):
		dir.make_dir_recursive("simbot_logs")

func _csv_write_header_if_needed(file_path: String, columns: Array[String]) -> void:
	_ensure_csv_dir_exists()
	if FileAccess.file_exists(file_path):
		return

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return

	file.store_line(",".join(columns))
	file.flush()
	file.close()

func _csv_append_row(file_path: String, columns: Array[String], row: Dictionary) -> void:
	_ensure_csv_dir_exists()
	# Godot 4.x: FileAccess.APPEND is not available in this build.
	# Implement append by opening READ_WRITE and seeking to end.
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ_WRITE)
	if file == null:
		return
	file.seek_end(0)

	var values: Array[String] = []
	values.resize(columns.size())
	for i: int in range(columns.size()):
		var col: String = columns[i]
		if row.has(col):
			values[i] = str(row[col])
		else:
			values[i] = "0"

	file.store_line(",".join(values))
	file.flush()
	file.close()

# ---------------------------------------------------------------------------
# Orchestration helpers
# ---------------------------------------------------------------------------

func _activate_for_run(profile_id: String, run_index: int, seed_value: int) -> void:
	_profile = _load_profile(profile_id)
	_current_run_index = run_index
	_base_seed = seed_value
	# SOURCE: deterministic RNG seeding for simulation testing.
	# In Godot 4.x, RandomNumberGenerator.seed is an int property (not a callable).
	_rng.seed = seed_value

	_decision_frame = 0
	_last_spell_eval_frame = -1
	_run_done = false

	_wave_manager = get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager
	_spell_manager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	_hex_grid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	_research_manager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager

	assert(_wave_manager != null, "SimBot.run_single: WaveManager missing from scene tree.")
	assert(_spell_manager != null, "SimBot.run_single: SpellManager missing from scene tree.")
	assert(_hex_grid != null, "SimBot.run_single: HexGrid missing from scene tree.")

	_reset_run_metrics()

func _load_profile(profile_id: String) -> StrategyProfile:
	# ASSUMPTION: Phase 2 ships exactly three StrategyProfile resources under this folder.
	var base_path: String = "res://resources/strategyprofiles/"
	var candidates: Array[String] = [
		base_path + "strategy_balanced_default.tres",
		base_path + "strategy_greedy_econ.tres",
		base_path + "strategy_heavy_fire.tres",
	]

	for path: String in candidates:
		var res: Resource = load(path)
		var profile: StrategyProfile = res as StrategyProfile
		if profile != null and profile.profile_id == profile_id:
			return profile

	# Fallback to first valid profile (keeps CLI/tests robust).
	for path2: String in candidates:
		var res2: Resource = load(path2)
		var profile2: StrategyProfile = res2 as StrategyProfile
		if profile2 != null:
			return profile2
	return null

func _reset_managers_for_run() -> void:
	# Determinism: seed global RNG for any global random calls in WaveManager and spawn logic.
	seed(_base_seed)

	_wave_manager.reset_for_new_mission()
	_wave_manager.clear_all_enemies()
	_hex_grid.clear_all_buildings()
	_spell_manager.reset_to_defaults()
	EconomyManager.reset_to_defaults()

	var rm: ResearchManager = _research_manager
	if rm != null:
		rm.reset_to_defaults()

func _capture_starting_resource_state() -> void:
	_resource_prev.clear()
	_resource_prev[Types.ResourceType.GOLD] = EconomyManager.get_gold()
	_resource_prev[Types.ResourceType.BUILDING_MATERIAL] = EconomyManager.get_building_material()
	_resource_prev[Types.ResourceType.RESEARCH_MATERIAL] = EconomyManager.get_research_material()

	_metrics["gold_end"] = _resource_prev[Types.ResourceType.GOLD]
	_metrics["building_material_end"] = _resource_prev[Types.ResourceType.BUILDING_MATERIAL]
	_metrics["research_material_end"] = _resource_prev[Types.ResourceType.RESEARCH_MATERIAL]

func _start_new_game_for_run() -> void:
	GameManager.start_new_game()

func _run_loop_until_mission_finished() -> void:
	# Hard upper bound to prevent test hangs if mission won/failed signals are not delivered.
	var max_frames: int = 1200
	var frame_count: int = 0

	while not _run_done and frame_count < max_frames:
		frame_count += 1

		var state: Types.GameState = GameManager.get_game_state()
		if state == Types.GameState.COMBAT or state == Types.GameState.WAVE_COUNTDOWN:
			_decision_frame += 1
			_process_combat_tick()

			# Dev/test acceleration: spawn waves during countdown to keep test runtime bounded.
			if _wave_manager.is_counting_down():
				_wave_manager.force_spawn_wave(_wave_manager.get_current_wave_number())

		# Belt-and-suspenders termination (headless runs can miss some metric signals).
		if state == Types.GameState.MISSION_WON or state == Types.GameState.MISSION_FAILED:
			_run_done = true

		await get_tree().process_frame

	if not _run_done:
		# Timeout fallback for robustness.
		_run_done = true

func _process_combat_tick() -> void:
	if _profile == null:
		return

	var can_cast: bool = _should_cast_spell()
	var build_choice: Dictionary = _choose_build_or_upgrade_action()

	if build_choice.is_empty():
		if can_cast:
			_cast_spell()
		return

	if can_cast:
		# Deterministic tie-break between spell and building actions.
		var spell_priority: float = float(_profile.spell_usage.get("priority_vs_building", 1.0))
		var best_build_score: float = float(build_choice.get("score", 0.0))
		if spell_priority >= best_build_score:
			_cast_spell()
			return

	_perform_build_action(build_choice)

func _should_cast_spell() -> bool:
	if _profile == null or _spell_manager == null or _wave_manager == null:
		return false

	var usage: Dictionary = _profile.spell_usage
	if not bool(usage.get("enabled", true)):
		return false

	var interval_sec: float = float(usage.get("evaluation_interval", 1.0))
	var interval_frames: int = maxi(1, int(round(interval_sec * float(Engine.physics_ticks_per_second))))
	if _last_spell_eval_frame >= 0 and (_decision_frame - _last_spell_eval_frame) < interval_frames:
		return false
	_last_spell_eval_frame = _decision_frame

	var spell_id: String = str(usage.get("spell_id", _SPELL_ID_SHOCKWAVE))
	if spell_id.is_empty():
		return false

	var current_mana: int = _spell_manager.get_current_mana()
	var min_mana: int = int(usage.get("min_mana", 0))
	if current_mana < min_mana:
		return false

	var min_enemies: int = int(usage.get("min_enemies_in_wave", 0))
	if _wave_manager.get_living_enemy_count() < min_enemies:
		return false

	var safety_margin: float = float(usage.get("cooldown_safety_margin", 0.0))
	var remaining: float = _spell_manager.get_cooldown_remaining(spell_id)
	if remaining > safety_margin:
		return false

	return _spell_manager.is_spell_ready(spell_id)

func _cast_spell() -> void:
	var usage: Dictionary = _profile.spell_usage
	var spell_id: String = str(usage.get("spell_id", _SPELL_ID_SHOCKWAVE))
	if spell_id.is_empty():
		return
	_spell_manager.cast_spell(spell_id)

func _choose_build_or_upgrade_action() -> Dictionary:
	if _profile == null:
		return {}

	# Upgrade preference.
	var occupied: Array[int] = _hex_grid.get_all_occupied_slots()
	var build_count: int = occupied.size()
	var upgrade_choice: Dictionary = _choose_upgrade_action_if_desired(build_count)
	if not upgrade_choice.is_empty():
		return upgrade_choice

	# Build preference.
	var wave_number: int = _wave_manager.get_current_wave_number()
	var best_weight: float = -1.0
	var best_entries: Array[Dictionary] = []

	for entry: Dictionary in _profile.build_priorities:
		var weight: float = float(entry.get("weight", 0.0))
		if weight <= 0.0:
			continue

		var min_wave: int = int(entry.get("min_wave", 1))
		var max_wave: int = int(entry.get("max_wave", 10))
		if wave_number < min_wave or wave_number > max_wave:
			continue

		var btype: Types.BuildingType = _cast_building_type(entry.get("building_type", 0))
		var bdata: BuildingData = _hex_grid.get_building_data(btype)
		if bdata == null:
			continue

		# If the profile wants a locked building, unlock its research prerequisite.
		# SOURCE: Rule-based unlock gating adapted from automated game testing literature.
		if bdata.is_locked and bdata.unlock_research_id.strip_edges() != "" and _research_manager != null:
			if not _research_manager.is_unlocked(bdata.unlock_research_id):
				_research_manager.unlock_node(bdata.unlock_research_id)

		if not _hex_grid.is_building_available(btype):
			continue
		if not EconomyManager.can_afford(bdata.gold_cost, bdata.material_cost):
			continue

		if weight > best_weight:
			best_weight = weight
			best_entries.clear()
			best_entries.append(entry)
		elif is_equal_approx(weight, best_weight):
			best_entries.append(entry)

	if best_entries.is_empty():
		return {}

	var chosen_entry: Dictionary = best_entries[0]
	if best_entries.size() > 1:
		var pick: int = _rng.randi_range(0, best_entries.size() - 1)
		chosen_entry = best_entries[pick]

	var chosen_btype: Types.BuildingType = _cast_building_type(chosen_entry.get("building_type", 0))
	var empties: Array[int] = _hex_grid.get_empty_slots()
	var slot_index: int = _choose_slot_for_build(empties)
	if slot_index < 0:
		return {}

	return {
		"action_type": "build",
		"slot_index": slot_index,
		"building_type": chosen_btype,
		"score": best_weight,
	}

func _choose_upgrade_action_if_desired(build_count: int) -> Dictionary:
	var upgrade_cfg: Dictionary = _profile.upgrade_behavior
	var prefer_until: int = int(upgrade_cfg.get("prefer_upgrades_until_build_count", 6))
	var min_gold_reserve: int = int(upgrade_cfg.get("min_gold_reserve", 0))
	var max_upgrade_level: int = int(upgrade_cfg.get("max_upgrade_level", 1))

	if max_upgrade_level <= 0:
		return {}
	if build_count >= prefer_until:
		return {}
	if EconomyManager.get_gold() < min_gold_reserve:
		return {}

	var upgrade_weight: float = float(upgrade_cfg.get("upgrade_weight", 1.0))
	var best_score: float = -1.0
	var best_slots: Array[int] = []

	for slot_index: int in _hex_grid.get_all_occupied_slots():
		var slot_data: Dictionary = _hex_grid.get_slot_data(slot_index)
		var building: BuildingBase = slot_data.get("building") as BuildingBase
		if building == null:
			continue
		if building.is_upgraded:
			continue

		var bdata: BuildingData = building.get_building_data()
		if bdata == null:
			continue
		if not EconomyManager.can_afford(bdata.upgrade_gold_cost, bdata.upgrade_material_cost):
			continue

		var base_weight: float = _get_build_weight_for_type(bdata.building_type)
		var score: float = base_weight * upgrade_weight

		if score > best_score:
			best_score = score
			best_slots.clear()
			best_slots.append(slot_index)
		elif is_equal_approx(score, best_score):
			best_slots.append(slot_index)

	if best_slots.is_empty():
		return {}

	var chosen_slot: int = best_slots[0]
	if best_slots.size() > 1:
		var pick: int = _rng.randi_range(0, best_slots.size() - 1)
		chosen_slot = best_slots[pick]

	var chosen_building: BuildingBase = _hex_grid.get_slot_data(chosen_slot).get("building") as BuildingBase
	var chosen_type: Types.BuildingType = Types.BuildingType.ARROW_TOWER
	if chosen_building != null:
		var bd: BuildingData = chosen_building.get_building_data()
		if bd != null:
			chosen_type = bd.building_type

	return {
		"action_type": "upgrade",
		"slot_index": chosen_slot,
		"building_type": chosen_type,
		"score": best_score,
	}

func _perform_build_action(choice: Dictionary) -> void:
	var action_type: String = str(choice.get("action_type", ""))
	var slot_index: int = int(choice.get("slot_index", -1))
	if slot_index < 0:
		return

	match action_type:
		"upgrade":
			_hex_grid.upgrade_building(slot_index)
		"build":
			var raw_btype: Variant = choice.get("building_type", 0)
			var btype: Types.BuildingType = _cast_building_type(raw_btype)
			_hex_grid.place_building(slot_index, btype)
		_:
			return

func _cast_building_type(raw: Variant) -> Types.BuildingType:
	var idx: int = int(raw)
	# Godot returns enum values as a generic Array; avoid assigning to a typed Array.
	var values: Array = Types.BuildingType.values()
	if idx < 0 or idx >= values.size():
		return Types.BuildingType.ARROW_TOWER
	return values[idx]

func _get_build_weight_for_type(btype: Types.BuildingType) -> float:
	var best: float = 0.0
	for entry: Dictionary in _profile.build_priorities:
		var entry_type: Types.BuildingType = _cast_building_type(entry.get("building_type", 0))
		if entry_type != btype:
			continue
		var w: float = float(entry.get("weight", 0.0))
		if w > best:
			best = w
	return best

func _choose_slot_for_build(empties: Array[int]) -> int:
	if empties.is_empty():
		return -1

	var prefs: Dictionary = _profile.placement_preferences
	var preferred_slots: Array = prefs.get("preferred_slots", [])
	for idx_variant: Variant in preferred_slots:
		var slot_index: int = int(idx_variant)
		if empties.has(slot_index):
			return slot_index

	var ring_hint: String = str(prefs.get("ring_hint", "ANY"))
	var fallback: String = str(prefs.get("fallback_strategy", "FIRST_EMPTY"))
	var ordered: Array[int] = _order_empties_by_ring_hint(empties, ring_hint)

	if fallback == "RANDOM_EMPTY":
		if ordered.is_empty():
			return -1
		var top_bucket: Array[int] = _ring_bucket_for_first_available(ordered, ring_hint)
		if top_bucket.is_empty():
			top_bucket = ordered
		var pick: int = _rng.randi_range(0, top_bucket.size() - 1)
		return top_bucket[pick]

	# FIRST_EMPTY
	return ordered[0]

func _order_empties_by_ring_hint(empties: Array[int], ring_hint: String) -> Array[int]:
	var inner: Array[int] = []
	var mid: Array[int] = []
	var outer: Array[int] = []

	for slot_index: int in empties:
		if slot_index >= 0 and slot_index <= 5:
			inner.append(slot_index)
		elif slot_index >= 6 and slot_index <= 17:
			mid.append(slot_index)
		else:
			outer.append(slot_index)

	inner.sort()
	mid.sort()
	outer.sort()

	if ring_hint == "OUTER_FIRST":
		return outer + mid + inner
	return inner + mid + outer

func _ring_bucket_for_first_available(ordered: Array[int], ring_hint: String) -> Array[int]:
	# Godot GDScript does not support nested typed collections (e.g. Array[Array[int]]).
	# Use separate arrays per ring instead.
	var ring1: Array[int] = []
	var ring2: Array[int] = []
	var ring3: Array[int] = []
	for slot_index: int in ordered:
		if slot_index >= 0 and slot_index <= 5:
			ring1.append(slot_index)
		elif slot_index >= 6 and slot_index <= 17:
			ring2.append(slot_index)
		else:
			ring3.append(slot_index)

	if ring_hint == "OUTER_FIRST":
		if not ring3.is_empty():
			return ring3
		if not ring2.is_empty():
			return ring2
		return ring1

	if not ring1.is_empty():
		return ring1
	if not ring2.is_empty():
		return ring2
	return ring3

func _reset_run_metrics() -> void:
	_metrics.clear()
	_metrics["profile_id"] = _profile.profile_id if _profile != null else ""
	_metrics["run_index"] = _current_run_index
	_metrics["mission_number"] = 1
	_metrics["waves_cleared"] = 0
	_metrics["outcome"] = "unknown"
	_metrics["tower_hp_end"] = 0
	_metrics["total_enemies_killed"] = 0

	_metrics["total_gold_earned"] = 0
	_metrics["total_gold_spent"] = 0
	_metrics["total_building_material_earned"] = 0
	_metrics["total_building_material_spent"] = 0
	_metrics["total_research_material_earned"] = 0
	_metrics["total_research_material_spent"] = 0

	_metrics["gold_end"] = 0
	_metrics["building_material_end"] = 0
	_metrics["research_material_end"] = 0

	_metrics["tower_damage_taken"] = 0
	_metrics["spells_cast_shockwave"] = 0
	_metrics["difficulty_score"] = 0.0

	for enemy_type: Types.EnemyType in Types.EnemyType.values():
		_metrics["enemies_killed_%s" % str(enemy_type)] = 0
	for btype: Types.BuildingType in Types.BuildingType.values():
		_metrics["buildings_built_%s" % str(btype)] = 0
		_metrics["buildings_sold_%s" % str(btype)] = 0
		_metrics["buildings_upgraded_%s" % str(btype)] = 0

func _build_csv_columns() -> Array[String]:
	var cols: Array[String] = []
	cols.append("profile_id")
	cols.append("run_index")
	cols.append("mission_number")
	cols.append("waves_cleared")
	cols.append("outcome")
	cols.append("tower_hp_end")
	cols.append("total_enemies_killed")
	cols.append("total_gold_earned")
	cols.append("total_gold_spent")
	cols.append("total_building_material_earned")
	cols.append("total_building_material_spent")
	cols.append("total_research_material_earned")
	cols.append("total_research_material_spent")
	cols.append("gold_end")
	cols.append("building_material_end")
	cols.append("research_material_end")

	for enemy_type: Types.EnemyType in Types.EnemyType.values():
		cols.append("enemies_killed_%s" % str(enemy_type))
	for btype: Types.BuildingType in Types.BuildingType.values():
		cols.append("buildings_built_%s" % str(btype))
		cols.append("buildings_sold_%s" % str(btype))
		cols.append("buildings_upgraded_%s" % str(btype))

	cols.append("spells_cast_shockwave")
	cols.append("tower_damage_taken")
	cols.append("difficulty_score")
	return cols

func _connect_metric_signals() -> void:
	_disconnect_metric_signals()
	SignalBus.enemy_killed.connect(_on_metric_enemy_killed)
	SignalBus.wave_cleared.connect(_on_metric_wave_cleared)
	SignalBus.mission_won.connect(_on_metric_mission_won)
	SignalBus.mission_failed.connect(_on_metric_mission_failed)
	SignalBus.resource_changed.connect(_on_metric_resource_changed)
	SignalBus.building_placed.connect(_on_metric_building_placed)
	SignalBus.building_sold.connect(_on_metric_building_sold)
	SignalBus.building_upgraded.connect(_on_metric_building_upgraded)
	SignalBus.spell_cast.connect(_on_metric_spell_cast)
	SignalBus.tower_damaged.connect(_on_metric_tower_damaged)
	SignalBus.tower_destroyed.connect(_on_metric_tower_destroyed)

func _disconnect_metric_signals() -> void:
	if SignalBus.enemy_killed.is_connected(_on_metric_enemy_killed):
		SignalBus.enemy_killed.disconnect(_on_metric_enemy_killed)
	if SignalBus.wave_cleared.is_connected(_on_metric_wave_cleared):
		SignalBus.wave_cleared.disconnect(_on_metric_wave_cleared)
	if SignalBus.mission_won.is_connected(_on_metric_mission_won):
		SignalBus.mission_won.disconnect(_on_metric_mission_won)
	if SignalBus.mission_failed.is_connected(_on_metric_mission_failed):
		SignalBus.mission_failed.disconnect(_on_metric_mission_failed)
	if SignalBus.resource_changed.is_connected(_on_metric_resource_changed):
		SignalBus.resource_changed.disconnect(_on_metric_resource_changed)
	if SignalBus.building_placed.is_connected(_on_metric_building_placed):
		SignalBus.building_placed.disconnect(_on_metric_building_placed)
	if SignalBus.building_sold.is_connected(_on_metric_building_sold):
		SignalBus.building_sold.disconnect(_on_metric_building_sold)
	if SignalBus.building_upgraded.is_connected(_on_metric_building_upgraded):
		SignalBus.building_upgraded.disconnect(_on_metric_building_upgraded)
	if SignalBus.spell_cast.is_connected(_on_metric_spell_cast):
		SignalBus.spell_cast.disconnect(_on_metric_spell_cast)
	if SignalBus.tower_damaged.is_connected(_on_metric_tower_damaged):
		SignalBus.tower_damaged.disconnect(_on_metric_tower_damaged)
	if SignalBus.tower_destroyed.is_connected(_on_metric_tower_destroyed):
		SignalBus.tower_destroyed.disconnect(_on_metric_tower_destroyed)

func _on_metric_enemy_killed(enemy_type: Types.EnemyType, _position: Vector3, _gold_reward: int) -> void:
	_metrics["total_enemies_killed"] += 1
	var key: String = "enemies_killed_%s" % str(enemy_type)
	if _metrics.has(key):
		_metrics[key] += 1

func _on_metric_wave_cleared(wave_number: int) -> void:
	if wave_number > int(_metrics["waves_cleared"]):
		_metrics["waves_cleared"] = wave_number

func _on_metric_mission_won(mission_number: int) -> void:
	_metrics["outcome"] = "mission_won"
	_metrics["mission_number"] = mission_number
	_run_done = true

func _on_metric_mission_failed(mission_number: int) -> void:
	_metrics["outcome"] = "mission_failed"
	_metrics["mission_number"] = mission_number
	_run_done = true

func _on_metric_resource_changed(resource_type: Types.ResourceType, new_amount: int) -> void:
	var prev: int = int(_resource_prev.get(resource_type, new_amount))
	var delta: int = new_amount - prev
	_resource_prev[resource_type] = new_amount

	match resource_type:
		Types.ResourceType.GOLD:
			if delta > 0:
				_metrics["total_gold_earned"] += delta
			elif delta < 0:
				_metrics["total_gold_spent"] += -delta
			_metrics["gold_end"] = new_amount
		Types.ResourceType.BUILDING_MATERIAL:
			if delta > 0:
				_metrics["total_building_material_earned"] += delta
			elif delta < 0:
				_metrics["total_building_material_spent"] += -delta
			_metrics["building_material_end"] = new_amount
		Types.ResourceType.RESEARCH_MATERIAL:
			if delta > 0:
				_metrics["total_research_material_earned"] += delta
			elif delta < 0:
				_metrics["total_research_material_spent"] += -delta
			_metrics["research_material_end"] = new_amount

func _on_metric_building_placed(_slot_index: int, building_type: Types.BuildingType) -> void:
	var key: String = "buildings_built_%s" % str(building_type)
	if _metrics.has(key):
		_metrics[key] += 1

func _on_metric_building_sold(_slot_index: int, building_type: Types.BuildingType) -> void:
	var key: String = "buildings_sold_%s" % str(building_type)
	if _metrics.has(key):
		_metrics[key] += 1

func _on_metric_building_upgraded(_slot_index: int, building_type: Types.BuildingType) -> void:
	var key: String = "buildings_upgraded_%s" % str(building_type)
	if _metrics.has(key):
		_metrics[key] += 1

func _on_metric_spell_cast(spell_id: String) -> void:
	if spell_id == _SPELL_ID_SHOCKWAVE:
		_metrics["spells_cast_shockwave"] += 1

func _on_metric_tower_damaged(current_hp: int, max_hp: int) -> void:
	_metrics["tower_hp_end"] = current_hp
	var damage_taken: int = max_hp - current_hp
	if damage_taken > int(_metrics["tower_damage_taken"]):
		_metrics["tower_damage_taken"] = damage_taken

func _on_metric_tower_destroyed() -> void:
	_metrics["tower_hp_end"] = 0

func _finalize_metrics() -> void:
	var max_waves: int = _wave_manager.max_waves if _wave_manager != null else 1
	max_waves = maxi(1, max_waves)

	var waves_cleared: int = int(_metrics.get("waves_cleared", 0))

	# TUNING: simple difficulty score.
	var base: float = float(waves_cleared) / float(max_waves) * 1000.0
	var tower_penalty: float = float(_metrics.get("tower_damage_taken", 0)) * 0.3
	var unspent_gold_penalty: float = float(_metrics.get("gold_end", 0)) * 0.1
	_metrics["difficulty_score"] = base - tower_penalty - unspent_gold_penalty
