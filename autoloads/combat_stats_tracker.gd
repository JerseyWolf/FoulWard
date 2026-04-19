## combat_stats_tracker.gd
## Autoload: mission/wave/building combat CSV for SimBot balance under user://simbot/runs/{mission_id}_{timestamp}/.

extends Node

# ---------------------------------------------------------------------------
# State (Prompt 48)
# ---------------------------------------------------------------------------

var _mission_id: String = ""
## SimBot loadout / profile label for balance CSV columns (e.g. "balanced").
var _run_label: String = ""
var _run_timestamp: String = ""
var _seed: int = 0
var _layout_rotation_deg: float = 0.0
var _run_id: String = ""
var _output_dir: String = ""

var _wave_rows: Array[Dictionary] = []
var _current_wave: Dictionary = {}
var _building_rows: Dictionary = {} # placed_instance_id -> Dictionary
var _event_log: Array[Dictionary] = []

## When true, writes event_log.csv with structured rows.
var debug_mode: bool = false

var _run_active: bool = false
var _wave_in_progress: bool = false
var _active_wave_number: int = 0
var _wave_start_usec: int = 0
var _tower_prev_hp: int = -1
var _wave_spawned_count: int = 0
var _wave_kills: int = 0
var _wave_leaks: int = 0
var _wave_damage_dealt: float = 0.0
var _wave_florence_damage_taken: int = 0
var _wave_florence_hp_start: int = 0
var _wave_spawn_hint: int = 0
var _prev_gold: int = -1
var _prev_mat: int = -1

const _RUN_ROOT: String = "user://simbot/runs"

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	if not OS.is_debug_build():
		debug_mode = false
	_connect_signals()


func _connect_signals() -> void:
	if not SignalBus.mission_started.is_connected(_on_mission_started_bus):
		SignalBus.mission_started.connect(_on_mission_started_bus)
	if not SignalBus.mission_won.is_connected(_on_mission_won_bus):
		SignalBus.mission_won.connect(_on_mission_won_bus)
	if not SignalBus.mission_failed.is_connected(_on_mission_failed_bus):
		SignalBus.mission_failed.connect(_on_mission_failed_bus)
	if not SignalBus.wave_started.is_connected(_on_wave_started_bus):
		SignalBus.wave_started.connect(_on_wave_started_bus)
	if not SignalBus.wave_cleared.is_connected(_on_wave_cleared_bus):
		SignalBus.wave_cleared.connect(_on_wave_cleared_bus)
	if not SignalBus.enemy_killed.is_connected(_on_enemy_killed_bus):
		SignalBus.enemy_killed.connect(_on_enemy_killed_bus)
	if not SignalBus.enemy_reached_tower.is_connected(_on_enemy_reached_tower):
		SignalBus.enemy_reached_tower.connect(_on_enemy_reached_tower)
	if not SignalBus.tower_damaged.is_connected(_on_tower_damaged):
		SignalBus.tower_damaged.connect(_on_tower_damaged)
	if not SignalBus.building_placed.is_connected(_on_building_placed_compat):
		SignalBus.building_placed.connect(_on_building_placed_compat)
	if not SignalBus.building_upgraded.is_connected(_on_building_upgraded):
		SignalBus.building_upgraded.connect(_on_building_upgraded)
	if not SignalBus.building_destroyed.is_connected(_on_building_destroyed_bus):
		SignalBus.building_destroyed.connect(_on_building_destroyed_bus)
	if not SignalBus.resource_changed.is_connected(_on_resource_changed):
		SignalBus.resource_changed.connect(_on_resource_changed)
	if not SignalBus.building_dealt_damage.is_connected(_on_building_dealt_damage):
		SignalBus.building_dealt_damage.connect(_on_building_dealt_damage)
	if not SignalBus.florence_damaged.is_connected(_on_florence_damaged):
		SignalBus.florence_damaged.connect(_on_florence_damaged)
	if not SignalBus.enemy_spawned.is_connected(_on_enemy_spawned):
		SignalBus.enemy_spawned.connect(_on_enemy_spawned)
	if not SignalBus.ally_died.is_connected(_on_ally_died_bus):
		SignalBus.ally_died.connect(_on_ally_died_bus)


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func begin_mission(mission_id: String, seed_val: int, layout_deg: float) -> void:
	_begin_run_internal(mission_id, "", seed_val, layout_deg)


## Balance sweep: identifies a run in CSV output ([member _run_label] + [member _mission_id] + timestamp).
func begin_run(mission_id: String, run_label: String) -> void:
	var seed_use: int = _seed
	if seed_use == 0:
		seed_use = int(Time.get_ticks_msec() & 0x7FFFFFFF)
	_begin_run_internal(mission_id, run_label, seed_use, _layout_rotation_deg)


func end_run() -> void:
	flush_to_disk()
	_run_active = false
	_run_label = ""


func _begin_run_internal(mission_id: String, run_label: String, seed_val: int, layout_deg: float) -> void:
	_mission_id = mission_id
	_run_label = run_label
	_seed = seed_val
	_layout_rotation_deg = layout_deg
	_run_timestamp = _file_safe_timestamp()
	if _run_label.strip_edges().is_empty():
		_run_id = "%s_%s" % [_mission_id, _run_timestamp]
	else:
		_run_id = "%s_%s_%s" % [_mission_id, _run_label, _run_timestamp]
	_output_dir = "%s/%s" % [_RUN_ROOT, _run_id]
	_wave_rows.clear()
	_building_rows.clear()
	_event_log.clear()
	_reset_wave_tracking()
	_run_active = true
	_tower_prev_hp = -1
	_prev_gold = -1
	_prev_mat = -1
	var tw: Tower = _get_tower()
	if tw != null:
		_tower_prev_hp = tw.get_current_hp()
	_log_event_debug("mission_begin", "", "", 0.0, 0, 0.0)


func register_building(
		instance_id: String,
		building_id: String,
		size_class: String,
		ring_index: int,
		slot_id: int,
		cost_gold: int,
		upgrade_level: int
) -> void:
	if instance_id.strip_edges().is_empty():
		push_warning("CombatStatsTracker.register_building: empty instance_id")
		return
	_building_rows[instance_id] = {
		"run_id": _run_id,
		"mission_id": _mission_id,
		"run_label": _run_label,
		"placed_instance_id": instance_id,
		"building_id": building_id,
		"size_class": size_class,
		"ring_index": ring_index,
		"slot_id": slot_id,
		"cost_gold_paid": maxi(0, cost_gold),
		"upgrade_level": maxi(0, upgrade_level),
		"total_damage_dealt": 0.0,
		"total_kills": 0,
		"ally_deaths": 0,
		"damage_per_gold": 0.0,
		"waves_active": 0,
		"was_destroyed": false,
		"balance_status": "ok",
	}
	_log_event_debug("register_building", instance_id, "", 0.0, _active_wave_number, 0.0)


func flush_to_disk() -> void:
	if _run_id.is_empty():
		push_warning("CombatStatsTracker.flush_to_disk: no active run_id")
		return
	var dir_path: String = _output_dir
	if dir_path.is_empty():
		dir_path = "%s/%s" % [_RUN_ROOT, _run_id]
	var err: Error = DirAccess.make_dir_recursive_absolute(dir_path)
	if err != OK and err != ERR_ALREADY_EXISTS:
		push_warning("CombatStatsTracker: could not create run dir: %s" % dir_path)
		return
	_write_wave_summary_csv("%s/%s" % [dir_path, "wave_summary.csv"])
	_write_building_summary_csv("%s/%s" % [dir_path, "building_summary.csv"])
	if debug_mode:
		_write_event_log_csv("%s/%s" % [dir_path, "event_log.csv"])


## Back-compat: SimBot/tests may call before [method begin_mission].
func set_session_seed(seed_value: int) -> void:
	_seed = seed_value


func set_layout_rotation_deg(degrees: float) -> void:
	_layout_rotation_deg = degrees


func set_verbose_logging(enabled: bool) -> void:
	debug_mode = enabled


## Projectile / combat hook: attributes damage to a placed building by [param source_placed_instance_id].
func record_projectile_damage(
		source_kind: String,
		source_placed_instance_id: String,
		slot_index: int,
		damage_applied: float,
		killed_target: bool
) -> void:
	if not _run_active or not _wave_in_progress:
		return
	if damage_applied <= 0.0:
		return
	_wave_damage_dealt += damage_applied
	if source_kind == "building" and not source_placed_instance_id.strip_edges().is_empty():
		_add_building_damage_string(source_placed_instance_id, damage_applied, killed_target, slot_index)
	if debug_mode:
		_log_event_debug(
				"projectile_damage",
				source_placed_instance_id,
				"",
				damage_applied,
				_active_wave_number,
				0.0
		)


## Maps HexGrid slot index (0..41) to ring tier 1..3.
static func slot_index_to_ring(slot_index: int) -> int:
	if slot_index < 0:
		return -1
	if slot_index < 6:
		return 1
	if slot_index < 18:
		return 2
	if slot_index < 42:
		return 3
	return -1


# ---------------------------------------------------------------------------
# Signal handlers (Prompt 48)
# ---------------------------------------------------------------------------

func _on_wave_started(wave_number: int, florence_hp: int) -> void:
	if not _run_active:
		return
	_wave_in_progress = true
	_active_wave_number = wave_number
	_wave_spawned_count = 0
	_wave_kills = 0
	_wave_leaks = 0
	_wave_damage_dealt = 0.0
	_wave_florence_damage_taken = 0
	_wave_start_usec = Time.get_ticks_usec()
	_wave_florence_hp_start = florence_hp
	_wave_spawn_hint = 0
	_prev_gold = EconomyManager.get_gold()
	_prev_mat = EconomyManager.get_building_material()
	var tw: Tower = _get_tower()
	if tw != null:
		_tower_prev_hp = tw.get_current_hp()
	_current_wave = {
		"wave_number": wave_number,
		"florence_hp_start": florence_hp,
	}
	_log_event_debug("wave_started", "", "", 0.0, wave_number, 0.0)


func _on_wave_ended(wave_number: int, florence_hp: int, leaked: int) -> void:
	if not _run_active:
		return
	var duration_sec: float = float(Time.get_ticks_usec() - _wave_start_usec) / 1000000.0
	var spawned: int = _wave_spawned_count
	if spawned <= 0 and _wave_spawn_hint > 0:
		spawned = _wave_spawn_hint
	var leak_rate: float = 0.0
	if spawned > 0:
		leak_rate = float(leaked) / float(spawned)
	var row: Dictionary = {
		"run_id": _run_id,
		"mission_id": _mission_id,
		"run_label": _run_label,
		"wave_number": wave_number,
		"enemies_spawned": spawned,
		"enemies_killed": _wave_kills,
		"enemies_leaked": leaked,
		"leak_rate": leak_rate,
		"florence_hp_start": _wave_florence_hp_start,
		"florence_hp_end": florence_hp,
		"florence_damage_taken": _wave_florence_damage_taken,
		"total_damage_dealt": _wave_damage_dealt,
		"wave_duration_sec": duration_sec,
	}
	_wave_rows.append(row)
	_wave_in_progress = false
	_increment_building_wave_counters(wave_number)
	_log_event_debug("wave_ended", "", "", float(leaked), wave_number, duration_sec)


func _on_building_dealt_damage(instance_id: String, damage: float, enemy_id: String) -> void:
	if not _run_active or not _wave_in_progress:
		return
	if damage <= 0.0:
		return
	# [method record_projectile_damage] already rolls building rows + wave total — avoid double-counting.
	if debug_mode:
		_log_event_debug("building_dealt_damage", instance_id, enemy_id, damage, _active_wave_number, 0.0)


func _on_building_destroyed(instance_id: String) -> void:
	if not _run_active:
		return
	if _building_rows.has(instance_id):
		var row: Dictionary = _building_rows[instance_id]
		row["was_destroyed"] = true
		_building_rows[instance_id] = row
	_log_event_debug("building_destroyed", instance_id, "", 0.0, _active_wave_number, 0.0)


func _on_enemy_died(instance_id: String, killer_building_instance_id: String) -> void:
	if not _run_active or not _wave_in_progress:
		return
	_wave_kills += 1
	if debug_mode:
		_log_event_debug("enemy_died", killer_building_instance_id, instance_id, 0.0, _active_wave_number, 0.0)


func _on_florence_damaged(amount: int, source_enemy_id: String) -> void:
	if not _run_active or not _wave_in_progress:
		return
	if amount > 0:
		_wave_florence_damage_taken += amount
	if debug_mode:
		_log_event_debug("florence_damaged", source_enemy_id, "", float(amount), _active_wave_number, 0.0)


func _on_enemy_spawned(_enemy_type: Types.EnemyType, _position: Vector2) -> void:
	if not _run_active or not _wave_in_progress:
		return
	_wave_spawned_count += 1


func _on_ally_died_bus(_ally_id: String, building_instance_id: String) -> void:
	if not _run_active:
		return
	if building_instance_id.strip_edges().is_empty():
		return
	if not _building_rows.has(building_instance_id):
		return
	var row: Dictionary = _building_rows[building_instance_id]
	row["ally_deaths"] = int(row.get("ally_deaths", 0)) + 1
	_building_rows[building_instance_id] = row


func _on_building_placed_compat(slot_index: int, building_type: Types.BuildingType) -> void:
	if not _run_active:
		return
	var hg: HexGrid = _get_hex_grid()
	if hg == null:
		return
	var sd: Dictionary = hg.get_slot_data(slot_index)
	var building: BuildingBase = sd.get("building", null) as BuildingBase
	if building == null or not is_instance_valid(building):
		return
	var pid: String = building.placed_instance_id
	if pid.is_empty():
		return
	if _building_rows.has(pid):
		return
	var bd: BuildingData = building.get_building_data()
	if bd == null:
		return
	var bid: String = bd.building_id.strip_edges()
	if bid.is_empty():
		bid = "building_type:%d" % int(bd.building_type)
	var sc: String = bd.size_class.strip_edges()
	if sc.is_empty():
		sc = "MEDIUM"
	register_building(
			pid,
			bid,
			sc,
			building.ring_index,
			building.slot_id,
			building.paid_gold,
			0
	)


# ---------------------------------------------------------------------------
# Internal signal adapters
# ---------------------------------------------------------------------------

func _on_mission_started_bus(mission_number: int) -> void:
	if _run_active:
		return
	var seed_use: int = _seed
	if seed_use == 0:
		seed_use = int(Time.get_ticks_msec() & 0x7FFFFFFF)
	begin_mission(str(mission_number), seed_use, _layout_rotation_deg)


func _on_mission_won_bus(_mission_number: int) -> void:
	flush_to_disk()


func _on_mission_failed_bus(_mission_number: int) -> void:
	flush_to_disk()


func _on_wave_started_bus(wave_number: int, enemy_count: int) -> void:
	_wave_spawn_hint = enemy_count
	var tw: Tower = _get_tower()
	var hp: int = tw.get_current_hp() if tw != null else 0
	_on_wave_started(wave_number, hp)


func _on_wave_cleared_bus(wave_number: int) -> void:
	var tw: Tower = _get_tower()
	var hp_end: int = tw.get_current_hp() if tw != null else 0
	_on_wave_ended(wave_number, hp_end, _wave_leaks)


func _on_enemy_killed_bus(
		_enemy_type: Types.EnemyType,
		_position: Vector3,
		_gold_reward: int
) -> void:
	_on_enemy_died("", "")


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
	_tower_prev_hp = current_hp


func _on_building_destroyed_bus(slot_index: int) -> void:
	var hg: HexGrid = _get_hex_grid()
	if hg == null:
		return
	var sd: Dictionary = hg.get_slot_data(slot_index)
	var building: BuildingBase = sd.get("building", null) as BuildingBase
	if building == null or not is_instance_valid(building):
		return
	var pid: String = building.placed_instance_id
	if pid.is_empty():
		return
	_on_building_destroyed(pid)


func _on_building_upgraded(slot_index: int, _building_type: Types.BuildingType) -> void:
	if not _run_active:
		return
	var hg: HexGrid = _get_hex_grid()
	if hg == null:
		return
	var sd: Dictionary = hg.get_slot_data(slot_index)
	var building: BuildingBase = sd.get("building", null) as BuildingBase
	if building == null:
		return
	var pid: String = building.placed_instance_id
	if pid.is_empty() or not _building_rows.has(pid):
		return
	var row: Dictionary = _building_rows[pid]
	row["upgrade_level"] = int(row.get("upgrade_level", 0)) + 1
	_building_rows[pid] = row


func _on_resource_changed(resource_type: Types.ResourceType, new_amount: int) -> void:
	if not _run_active or not _wave_in_progress:
		return
	match resource_type:
		Types.ResourceType.GOLD:
			if _prev_gold < 0:
				_prev_gold = new_amount
				return
			_prev_gold = new_amount
		Types.ResourceType.BUILDING_MATERIAL:
			if _prev_mat < 0:
				_prev_mat = new_amount
				return
			_prev_mat = new_amount
		_:
			pass


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _reset_wave_tracking() -> void:
	_wave_in_progress = false
	_active_wave_number = 0
	_current_wave.clear()


func _add_building_damage_string(
		placed_id: String,
		damage_applied: float,
		killed_target: bool,
		_slot_fallback: int
) -> void:
	if not _building_rows.has(placed_id):
		return
	var row: Dictionary = _building_rows[placed_id]
	row["total_damage_dealt"] = float(row.get("total_damage_dealt", 0.0)) + damage_applied
	if killed_target:
		row["total_kills"] = int(row.get("total_kills", 0)) + 1
	_building_rows[placed_id] = row


func _increment_building_wave_counters(wave_number: int) -> void:
	for k: String in _building_rows.keys():
		var row: Dictionary = _building_rows[k]
		if bool(row.get("was_destroyed", false)):
			continue
		row["waves_active"] = int(row.get("waves_active", 0)) + 1
		_building_rows[k] = row


func _log_event_debug(
		event: String,
		source_instance_id: String,
		target_instance_id: String,
		amount: float,
		wave_number: int,
		t_sec: float
) -> void:
	if not debug_mode:
		return
	if t_sec <= 0.0 and _wave_start_usec > 0:
		t_sec = float(Time.get_ticks_usec() - _wave_start_usec) / 1000000.0
	_event_log.append(
			{
				"event": event,
				"source_instance_id": source_instance_id,
				"target_instance_id": target_instance_id,
				"amount": amount,
				"wave_number": wave_number,
				"t_sec": t_sec,
			}
	)


func _write_wave_summary_csv(path: String) -> void:
	var header: PackedStringArray = PackedStringArray([
		"run_id",
		"mission_id",
		"run_label",
		"wave_number",
		"enemies_spawned",
		"enemies_killed",
		"enemies_leaked",
		"leak_rate",
		"florence_hp_start",
		"florence_hp_end",
		"florence_damage_taken",
		"total_damage_dealt",
		"wave_duration_sec",
	])
	var lines: Array[String] = []
	lines.append(_join_csv_line(header))
	for row: Dictionary in _wave_rows:
		var vals: PackedStringArray = PackedStringArray([
			str(row.get("run_id", "")),
			str(row.get("mission_id", "")),
			str(row.get("run_label", "")),
			str(row.get("wave_number", "")),
			str(row.get("enemies_spawned", "")),
			str(row.get("enemies_killed", "")),
			str(row.get("enemies_leaked", "")),
			str(row.get("leak_rate", "")),
			str(row.get("florence_hp_start", "")),
			str(row.get("florence_hp_end", "")),
			str(row.get("florence_damage_taken", "")),
			str(row.get("total_damage_dealt", "")),
			str(row.get("wave_duration_sec", "")),
		])
		lines.append(_join_csv_line(vals))
	_write_text_file(path, "\n".join(lines))


func _write_building_summary_csv(path: String) -> void:
	var header: PackedStringArray = PackedStringArray([
		"run_id",
		"mission_id",
		"run_label",
		"display_name",
		"role_tags",
		"placed_instance_id",
		"building_id",
		"size_class",
		"ring_index",
		"slot_id",
		"cost_gold_paid",
		"upgrade_level",
		"total_damage_dealt",
		"total_kills",
		"ally_deaths",
		"damage_per_gold",
		"waves_active",
		"was_destroyed",
		"balance_status",
	])
	var lines: Array[String] = []
	lines.append(_join_csv_line(header))
	for k: String in _building_rows.keys():
		var row: Dictionary = _building_rows[k]
		var bid: String = str(row.get("building_id", ""))
		var meta: Dictionary = _lookup_building_meta(bid)
		var cost: int = maxi(0, int(row.get("cost_gold_paid", 0)))
		var dmg: float = float(row.get("total_damage_dealt", 0.0))
		var dpg: float = 0.0
		if cost > 0:
			dpg = dmg / float(cost)
		row["damage_per_gold"] = dpg
		_building_rows[k] = row
		var vals: PackedStringArray = PackedStringArray([
			str(row.get("run_id", _run_id)),
			str(row.get("mission_id", _mission_id)),
			str(row.get("run_label", _run_label)),
			str(meta.get("display_name", "")),
			str(meta.get("role_tags", "")),
			str(row.get("placed_instance_id", k)),
			str(row.get("building_id", "")),
			str(row.get("size_class", "")),
			str(row.get("ring_index", "")),
			str(row.get("slot_id", "")),
			str(row.get("cost_gold_paid", "")),
			str(row.get("upgrade_level", "")),
			str(dmg),
			str(row.get("total_kills", "")),
			str(row.get("ally_deaths", "")),
			str(dpg),
			str(row.get("waves_active", "")),
			str(row.get("was_destroyed", "")).to_lower(),
			str(row.get("balance_status", "ok")),
		])
		lines.append(_join_csv_line(vals))
	_write_text_file(path, "\n".join(lines))


func _write_event_log_csv(path: String) -> void:
	var header: PackedStringArray = PackedStringArray([
		"event",
		"source_instance_id",
		"target_instance_id",
		"amount",
		"wave_number",
		"t_sec",
	])
	var lines: Array[String] = []
	lines.append(_join_csv_line(header))
	for ev: Dictionary in _event_log:
		var vals: PackedStringArray = PackedStringArray([
			str(ev.get("event", "")),
			str(ev.get("source_instance_id", "")),
			str(ev.get("target_instance_id", "")),
			str(ev.get("amount", "")),
			str(ev.get("wave_number", "")),
			str(ev.get("t_sec", "")),
		])
		lines.append(_join_csv_line(vals))
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


func _lookup_building_meta(building_id: String) -> Dictionary:
	var out: Dictionary = {"display_name": "", "role_tags": ""}
	if building_id.strip_edges().is_empty():
		return out
	var hg: HexGrid = _get_hex_grid()
	if hg == null:
		return out
	for bd: BuildingData in hg.building_data_registry:
		if bd != null and bd.building_id == building_id:
			out["display_name"] = bd.display_name
			var tags: Array[String] = bd.role_tags
			var tag_str: String = ""
			var ti: int = 0
			for t: String in tags:
				if ti > 0:
					tag_str += ", "
				tag_str += t
				ti += 1
			out["role_tags"] = tag_str
			return out
	return out
