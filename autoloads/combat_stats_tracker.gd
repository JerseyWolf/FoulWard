## combat_stats_tracker.gd
## Autoload: wave- and building-level combat CSV for balancing / SimBot under user://simbot/runs/.
## Integrates with SignalBus and thin hooks from ProjectileBase / mission lifecycle.

extends Node

## When true, also writes event_log.csv with high-volume rows.
var verbose_logging_enabled: bool = false

var _run_active: bool = false
var _run_id: String = ""
var _mission_id: String = ""
var _run_timestamp: String = ""
var _session_seed: int = 0
var _layout_rotation_deg: float = 0.0

var _tower_prev_hp: int = -1

var _wave_in_progress: bool = false
var _active_wave_number: int = 0
var _wave_spawned: int = 0
var _wave_kills: int = 0
var _wave_leaks: int = 0
var _wave_damage_dealt: float = 0.0
var _wave_florence_damage_taken: int = 0
var _wave_florence_healing: int = 0
var _wave_start_usec: int = 0
var _wave_florence_hp_start: int = 0
var _wave_gold_start: int = 0
var _wave_mat_start: int = 0
var _wave_gold_earned: int = 0
var _wave_gold_spent: int = 0
var _wave_mat_earned: int = 0
var _wave_mat_spent: int = 0

var _wave_rows: Array[Dictionary] = []

## int (building instance_id) -> Dictionary (see _register_building_row)
var _buildings: Dictionary = {}

var _event_lines: Array[String] = []

var _prev_gold: int = -1
var _prev_mat: int = -1

const _RUN_DIR: String = "user://simbot/runs"


func _ready() -> void:
	verbose_logging_enabled = OS.is_debug_build()
	_connect_signals()


func _connect_signals() -> void:
	if not SignalBus.mission_started.is_connected(_on_mission_started):
		SignalBus.mission_started.connect(_on_mission_started)
	if not SignalBus.mission_won.is_connected(_on_mission_won):
		SignalBus.mission_won.connect(_on_mission_won)
	if not SignalBus.mission_failed.is_connected(_on_mission_failed):
		SignalBus.mission_failed.connect(_on_mission_failed)
	if not SignalBus.wave_started.is_connected(_on_wave_started):
		SignalBus.wave_started.connect(_on_wave_started)
	if not SignalBus.wave_cleared.is_connected(_on_wave_cleared):
		SignalBus.wave_cleared.connect(_on_wave_cleared)
	if not SignalBus.enemy_killed.is_connected(_on_enemy_killed):
		SignalBus.enemy_killed.connect(_on_enemy_killed)
	if not SignalBus.enemy_reached_tower.is_connected(_on_enemy_reached_tower):
		SignalBus.enemy_reached_tower.connect(_on_enemy_reached_tower)
	if not SignalBus.tower_damaged.is_connected(_on_tower_damaged):
		SignalBus.tower_damaged.connect(_on_tower_damaged)
	if not SignalBus.building_placed.is_connected(_on_building_placed):
		SignalBus.building_placed.connect(_on_building_placed)
	if not SignalBus.building_sold.is_connected(_on_building_sold):
		SignalBus.building_sold.connect(_on_building_sold)
	if not SignalBus.building_upgraded.is_connected(_on_building_upgraded):
		SignalBus.building_upgraded.connect(_on_building_upgraded)
	if not SignalBus.resource_changed.is_connected(_on_resource_changed):
		SignalBus.resource_changed.connect(_on_resource_changed)


## SimBot / tooling: set deterministic RNG seed for this mission run (logged in CSV).
func set_session_seed(seed_value: int) -> void:
	_session_seed = seed_value


## Optional layout parameter when the mission uses a rotated hex layout (default 0).
func set_layout_rotation_deg(degrees: float) -> void:
	_layout_rotation_deg = degrees


func set_verbose_logging(enabled: bool) -> void:
	verbose_logging_enabled = enabled


## Projectile hook: records damage attributed to Florence weapons or placed buildings.
func record_projectile_damage(
		source_kind: String,
		source_building_instance_id: int,
		slot_index: int,
		damage_applied: float,
		killed_target: bool
) -> void:
	if not _run_active or not _wave_in_progress:
		return
	if damage_applied <= 0.0:
		return
	_wave_damage_dealt += damage_applied
	if source_kind == "building" and source_building_instance_id != 0:
		_add_building_damage(source_building_instance_id, damage_applied, killed_target, slot_index)
	elif source_kind == "tower":
		pass
	if verbose_logging_enabled:
		_event_lines.append(
			"%s,damage,%s,%d,%d,%.3f,%s"
			% [
				_iso_timestamp(),
				source_kind,
				source_building_instance_id,
				slot_index,
				damage_applied,
				str(killed_target).to_lower()
			]
		)


func _on_mission_started(mission_number: int) -> void:
	_begin_run(str(mission_number))


func _begin_run(mission_id_str: String) -> void:
	_reset_run_state()
	_mission_id = mission_id_str
	_run_timestamp = _file_safe_timestamp()
	_run_id = "%s_%s" % [_mission_id, _run_timestamp]
	if _session_seed == 0:
		_session_seed = int(Time.get_ticks_msec() & 0x7FFFFFFF)
	_run_active = true
	_prev_gold = -1
	_prev_mat = -1
	_tower_prev_hp = -1
	var tw: Tower = _get_tower()
	if tw != null:
		_tower_prev_hp = tw.get_current_hp()
	if verbose_logging_enabled:
		_event_lines.append("%s,mission_start,mission_id=%s,seed=%d" % [_iso_timestamp(), _mission_id, _session_seed])


func _on_mission_won(_mission_number: int) -> void:
	_finalize_run("mission_won")


func _on_mission_failed(_mission_number: int) -> void:
	_finalize_run("mission_failed")


func _reset_run_state() -> void:
	_wave_rows.clear()
	_buildings.clear()
	_event_lines.clear()
	_wave_in_progress = false
	_active_wave_number = 0


func _finalize_run(outcome: String) -> void:
	if not _run_active:
		return
	_run_active = false
	if verbose_logging_enabled:
		_event_lines.append("%s,mission_end,%s" % [_iso_timestamp(), outcome])
	_write_all_csv_files()


func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	if not _run_active:
		return
	_wave_in_progress = true
	_active_wave_number = wave_number
	_wave_spawned = enemy_count
	_wave_kills = 0
	_wave_leaks = 0
	_wave_damage_dealt = 0.0
	_wave_florence_damage_taken = 0
	_wave_florence_healing = 0
	_wave_start_usec = Time.get_ticks_usec()
	_wave_gold_earned = 0
	_wave_gold_spent = 0
	_wave_mat_earned = 0
	_wave_mat_spent = 0
	var tw: Tower = _get_tower()
	_wave_florence_hp_start = tw.get_current_hp() if tw != null else 0
	_wave_gold_start = EconomyManager.get_gold()
	_wave_mat_start = EconomyManager.get_building_material()
	_prev_gold = _wave_gold_start
	_prev_mat = _wave_mat_start
	if tw != null:
		_tower_prev_hp = tw.get_current_hp()
	if verbose_logging_enabled:
		_event_lines.append(
			"%s,wave_start,%d,%d" % [_iso_timestamp(), wave_number, enemy_count]
		)


func _on_wave_cleared(wave_number: int) -> void:
	if not _run_active:
		return
	var duration_sec: float = float(Time.get_ticks_usec() - _wave_start_usec) / 1000000.0
	var tw: Tower = _get_tower()
	var florence_hp_end: int = tw.get_current_hp() if tw != null else 0
	var leak_rate: float = 0.0
	if _wave_spawned > 0:
		leak_rate = float(_wave_leaks) / float(_wave_spawned)
	var row: Dictionary = {
		"run_id": _run_id,
		"mission_id": _mission_id,
		"seed": _session_seed,
		"layout_rotation_deg": _layout_rotation_deg,
		"wave_number": wave_number,
		"enemies_spawned": _wave_spawned,
		"enemies_killed": _wave_kills,
		"enemies_leaked": _wave_leaks,
		"leak_rate": leak_rate,
		"florence_hp_start": _wave_florence_hp_start,
		"florence_hp_end": florence_hp_end,
		"florence_damage_taken": _wave_florence_damage_taken,
		"florence_healing_received": _wave_florence_healing,
		"total_damage_dealt": _wave_damage_dealt,
		"wave_duration_sec": duration_sec,
		"gold_start": _wave_gold_start,
		"gold_end": EconomyManager.get_gold(),
		"building_material_start": _wave_mat_start,
		"building_material_end": EconomyManager.get_building_material(),
		"gold_spent_wave": _wave_gold_spent,
		"gold_earned_wave": _wave_gold_earned,
		"material_spent_wave": _wave_mat_spent,
		"material_earned_wave": _wave_mat_earned,
	}
	_wave_rows.append(row)
	_wave_in_progress = false
	_increment_building_wave_counters(wave_number)
	if verbose_logging_enabled:
		_event_lines.append("%s,wave_cleared,%d" % [_iso_timestamp(), wave_number])


func _on_enemy_killed(
		_enemy_type: Types.EnemyType,
		_position: Vector3,
		_gold_reward: int
) -> void:
	if not _run_active or not _wave_in_progress:
		return
	_wave_kills += 1


func _on_enemy_reached_tower(_enemy_type: Types.EnemyType, _damage: int) -> void:
	if not _run_active or not _wave_in_progress:
		return
	_wave_leaks += 1


func _on_tower_damaged(current_hp: int, _max_hp: int) -> void:
	if not _run_active or not _wave_in_progress:
		return
	if _tower_prev_hp < 0:
		_tower_prev_hp = current_hp
		return
	var delta: int = current_hp - _tower_prev_hp
	if delta < 0:
		_wave_florence_damage_taken += -delta
	elif delta > 0:
		_wave_florence_healing += delta
	_tower_prev_hp = current_hp


func _on_resource_changed(resource_type: Types.ResourceType, new_amount: int) -> void:
	if not _run_active or not _wave_in_progress:
		return
	match resource_type:
		Types.ResourceType.GOLD:
			if _prev_gold < 0:
				_prev_gold = new_amount
				return
			var dg: int = new_amount - _prev_gold
			if dg > 0:
				_wave_gold_earned += dg
			elif dg < 0:
				_wave_gold_spent += -dg
			_prev_gold = new_amount
		Types.ResourceType.BUILDING_MATERIAL:
			if _prev_mat < 0:
				_prev_mat = new_amount
				return
			var dm: int = new_amount - _prev_mat
			if dm > 0:
				_wave_mat_earned += dm
			elif dm < 0:
				_wave_mat_spent += -dm
			_prev_mat = new_amount
		_:
			pass


func _on_building_placed(slot_index: int, building_type: Types.BuildingType) -> void:
	if not _run_active:
		return
	var hg: HexGrid = _get_hex_grid()
	if hg == null:
		return
	var sd: Dictionary = hg.get_slot_data(slot_index)
	var building: BuildingBase = sd.get("building", null) as BuildingBase
	if building == null or not is_instance_valid(building):
		return
	var iid: int = building.get_instance_id()
	var bd: BuildingData = building.get_building_data()
	if bd == null:
		return
	var gold_cost: int = bd.gold_cost
	_buildings[iid] = {
		"placed_instance_id": iid,
		"slot_index": slot_index,
		"building_type": building_type,
		"building_id": Types.BuildingType.keys()[int(building_type)],
		"display_name": bd.display_name,
		"size_class": "default",
		"ring_index": slot_index_to_ring(slot_index),
		"slot_id": "slot_%02d" % slot_index,
		"cost_gold_paid": gold_cost,
		"upgrade_level": 0,
		"total_damage_dealt": 0.0,
		"total_kills": 0,
		"waves_active": 0,
		"aura_uptime_waves": 0,
		"was_destroyed": false,
		"summons_deployed": 0,
		"summon_kills": 0,
		"balance_status": "unverified",
		"sold": false,
		"placement_wave": _active_wave_number,
	}
	if verbose_logging_enabled:
		_event_lines.append(
			"%s,building_placed,%d,%s"
			% [_iso_timestamp(), iid, Types.BuildingType.keys()[building_type]]
		)


func _on_building_sold(slot_index: int, building_type: Types.BuildingType) -> void:
	if not _run_active:
		return
	for k: int in _buildings.keys():
		var row: Dictionary = _buildings[k] as Dictionary
		if int(row.get("slot_index", -99)) != slot_index:
			continue
		var stored_bt: int = int(row.get("building_type", -1))
		if stored_bt != int(building_type):
			continue
		row["sold"] = true
		row["balance_status"] = "sold"
		_buildings[k] = row
		break


func _on_building_upgraded(slot_index: int, building_type: Types.BuildingType) -> void:
	if not _run_active:
		return
	var hg: HexGrid = _get_hex_grid()
	if hg == null:
		return
	var sd: Dictionary = hg.get_slot_data(slot_index)
	var building: BuildingBase = sd.get("building", null) as BuildingBase
	if building == null:
		return
	var iid: int = building.get_instance_id()
	if not _buildings.has(iid):
		return
	var bd: BuildingData = building.get_building_data()
	if bd == null:
		return
	var row: Dictionary = _buildings[iid] as Dictionary
	row["upgrade_level"] = 1
	row["cost_gold_paid"] = int(row.get("cost_gold_paid", 0)) + bd.upgrade_gold_cost
	_buildings[iid] = row


func _add_building_damage(
		instance_id: int,
		damage_applied: float,
		killed_target: bool,
		_slot_fallback: int
) -> void:
	if not _buildings.has(instance_id):
		return
	var row: Dictionary = _buildings[instance_id] as Dictionary
	row["total_damage_dealt"] = float(row.get("total_damage_dealt", 0.0)) + damage_applied
	if killed_target:
		row["total_kills"] = int(row.get("total_kills", 0)) + 1
	_buildings[instance_id] = row


func _increment_building_wave_counters(wave_number: int) -> void:
	for k: int in _buildings.keys():
		var row: Dictionary = _buildings[k] as Dictionary
		if bool(row.get("sold", false)):
			continue
		var pw: int = int(row.get("placement_wave", 9999))
		if wave_number < pw:
			continue
		row["waves_active"] = int(row.get("waves_active", 0)) + 1
		var bt: int = int(row.get("building_type", 0))
		if bt == int(Types.BuildingType.ARCHER_BARRACKS) or bt == int(Types.BuildingType.SHIELD_GENERATOR):
			row["aura_uptime_waves"] = int(row.get("aura_uptime_waves", 0)) + 1
		_buildings[k] = row


func _write_all_csv_files() -> void:
	var dir_path: String = "%s/%s" % [_RUN_DIR, _run_id]
	var err: Error = DirAccess.make_dir_recursive_absolute(dir_path)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("CombatStatsTracker: could not create run dir: %s" % dir_path)
		return
	_write_wave_summary_csv(dir_path + "/wave_summary.csv")
	_write_building_summary_csv(dir_path + "/building_summary.csv")
	if verbose_logging_enabled:
		_write_event_log_csv(dir_path + "/event_log.csv")


func _write_wave_summary_csv(path: String) -> void:
	var header: PackedStringArray = PackedStringArray([
		"run_id",
		"mission_id",
		"seed",
		"layout_rotation_deg",
		"wave_number",
		"enemies_spawned",
		"enemies_killed",
		"enemies_leaked",
		"leak_rate",
		"florence_hp_start",
		"florence_hp_end",
		"florence_damage_taken",
		"florence_healing_received",
		"total_damage_dealt",
		"wave_duration_sec",
		"gold_start",
		"gold_end",
		"building_material_start",
		"building_material_end",
		"gold_spent_wave",
		"gold_earned_wave",
		"material_spent_wave",
		"material_earned_wave",
	])
	var lines: Array[String] = []
	lines.append(_join_csv_line(header))
	for row: Dictionary in _wave_rows:
		var vals: PackedStringArray = PackedStringArray([
			str(row.get("run_id", "")),
			str(row.get("mission_id", "")),
			str(row.get("seed", "")),
			str(row.get("layout_rotation_deg", "")),
			str(row.get("wave_number", "")),
			str(row.get("enemies_spawned", "")),
			str(row.get("enemies_killed", "")),
			str(row.get("enemies_leaked", "")),
			str(row.get("leak_rate", "")),
			str(row.get("florence_hp_start", "")),
			str(row.get("florence_hp_end", "")),
			str(row.get("florence_damage_taken", "")),
			str(row.get("florence_healing_received", "")),
			str(row.get("total_damage_dealt", "")),
			str(row.get("wave_duration_sec", "")),
			str(row.get("gold_start", "")),
			str(row.get("gold_end", "")),
			str(row.get("building_material_start", "")),
			str(row.get("building_material_end", "")),
			str(row.get("gold_spent_wave", "")),
			str(row.get("gold_earned_wave", "")),
			str(row.get("material_spent_wave", "")),
			str(row.get("material_earned_wave", "")),
		])
		lines.append(_join_csv_line(vals))
	_write_text_file(path, "\n".join(lines))


func _write_building_summary_csv(path: String) -> void:
	var header: PackedStringArray = PackedStringArray([
		"run_id",
		"mission_id",
		"placed_instance_id",
		"building_id",
		"display_name",
		"size_class",
		"ring_index",
		"slot_id",
		"cost_gold_paid",
		"upgrade_level",
		"total_damage_dealt",
		"total_kills",
		"damage_per_gold",
		"waves_active",
		"was_destroyed",
		"summons_deployed",
		"summon_kills",
		"aura_uptime_waves",
		"balance_status",
	])
	var lines: Array[String] = []
	lines.append(_join_csv_line(header))
	for k: int in _buildings.keys():
		var row: Dictionary = _buildings[k] as Dictionary
		var cost: int = maxi(1, int(row.get("cost_gold_paid", 1)))
		var dmg: float = float(row.get("total_damage_dealt", 0.0))
		var dpg: float = dmg / float(cost)
		var vals: PackedStringArray = PackedStringArray([
			_run_id,
			_mission_id,
			str(row.get("placed_instance_id", "")),
			str(row.get("building_id", "")),
			str(row.get("display_name", "")),
			str(row.get("size_class", "")),
			str(row.get("ring_index", "")),
			str(row.get("slot_id", "")),
			str(row.get("cost_gold_paid", "")),
			str(row.get("upgrade_level", "")),
			str(dmg),
			str(row.get("total_kills", "")),
			str(dpg),
			str(row.get("waves_active", "")),
			str(row.get("was_destroyed", "")).to_lower(),
			str(row.get("summons_deployed", "")),
			str(row.get("summon_kills", "")),
			str(row.get("aura_uptime_waves", "")),
			str(row.get("balance_status", "")),
		])
		lines.append(_join_csv_line(vals))
	_write_text_file(path, "\n".join(lines))


func _write_event_log_csv(path: String) -> void:
	var lines: Array[String] = []
	lines.append("message")
	for s: String in _event_lines:
		lines.append(_csv_escape(s))
	_write_text_file(path, "\n".join(lines))


func _write_text_file(path: String, content: String) -> void:
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("CombatStatsTracker: could not write %s" % path)
		return
	f.store_string(content)
	f.flush()


func _join_csv_line(fields: PackedStringArray) -> String:
	var parts: Array[String] = []
	for i: int in range(fields.size()):
		parts.append(_csv_escape(str(fields[i])))
	return ",".join(parts)


func _csv_escape(s: String) -> String:
	if s.find(",") != -1 or s.find("\"") != -1 or s.find("\n") != -1:
		return "\"" + s.replace("\"", "\"\"") + "\""
	return s


func _iso_timestamp() -> String:
	return Time.get_datetime_string_from_system(true, true)


func _file_safe_timestamp() -> String:
	var t: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d%02d%02d_%02d%02d%02d" % [
		int(t.get("year", 0)),
		int(t.get("month", 0)),
		int(t.get("day", 0)),
		int(t.get("hour", 0)),
		int(t.get("minute", 0)),
		int(t.get("second", 0)),
	]


func _get_tower() -> Tower:
	return get_node_or_null("/root/Main/Tower") as Tower


func _get_hex_grid() -> HexGrid:
	return get_node_or_null("/root/Main/HexGrid") as HexGrid


## Maps HexGrid slot index (0..23) to ring 1..3 matching _initialize_slots order.
static func slot_index_to_ring(slot_index: int) -> int:
	if slot_index < 0:
		return -1
	if slot_index < 6:
		return 1
	if slot_index < 18:
		return 2
	if slot_index < 24:
		return 3
	return -1
