## ChronicleManager — meta-progression chronicle entries, unlocks, and perk modifiers.
extends Node

## Preloaded so this autoload can type-check before global `class_name` registration order.
const _ENTRY_DATA_SCRIPT: GDScript = preload("res://scripts/resources/chronicle_entry_data.gd")
const _PERK_DATA_SCRIPT: GDScript = preload("res://scripts/resources/chronicle_perk_data.gd")

const _PROGRESS_VERSION: int = 1
const _ENTRIES_DIR: String = "res://resources/chronicle/entries"
const _PERKS_DIR: String = "res://resources/chronicle/perks"
const _ENEMY_DATA_DIR: String = "res://resources/enemy_data"

const _TRACK_FLYING_ONLY: String = "flying_only"
const _TRACK_UNIQUE_BOSSES: String = "unique_bosses"

## entry_id -> { data: Resource, progress: int, completed: bool, seen_boss_ids: Array[String] }
var _entries: Dictionary = {}
## perk_id -> Resource (ChroniclePerkData .tres)
var _perks: Dictionary = {}
## Unlocked perk ids (persisted).
var _active_perks: Array[String] = []
var _progress_file: String = "user://chronicle.json"

## enemy_type ordinal -> flying
var _enemy_type_is_flying: Dictionary = {}
var _last_gold_balance: int = -1


func _is_entry_data(res: Resource) -> bool:
	return res != null and res.get_script() == _ENTRY_DATA_SCRIPT


func _is_perk_data(res: Resource) -> bool:
	return res != null and res.get_script() == _PERK_DATA_SCRIPT


func _ready() -> void:
	_build_enemy_flying_map()
	_load_perk_resources()
	_load_entry_resources()
	_init_entry_runtime_state()
	load_progress()
	_last_gold_balance = EconomyManager.get_gold()
	_connect_signal_bus()


func _connect_signal_bus() -> void:
	if not SignalBus.enemy_killed.is_connected(_on_enemy_killed):
		SignalBus.enemy_killed.connect(_on_enemy_killed)
	if not SignalBus.mission_won.is_connected(_on_mission_won):
		SignalBus.mission_won.connect(_on_mission_won)
	if not SignalBus.building_placed.is_connected(_on_building_placed):
		SignalBus.building_placed.connect(_on_building_placed)
	if not SignalBus.boss_killed.is_connected(_on_boss_killed):
		SignalBus.boss_killed.connect(_on_boss_killed)
	if not SignalBus.campaign_completed.is_connected(_on_campaign_completed):
		SignalBus.campaign_completed.connect(_on_campaign_completed)
	if not SignalBus.resource_changed.is_connected(_on_resource_changed):
		SignalBus.resource_changed.connect(_on_resource_changed)
	if not SignalBus.research_unlocked.is_connected(_on_research_unlocked):
		SignalBus.research_unlocked.connect(_on_research_unlocked)


func _build_enemy_flying_map() -> void:
	_enemy_type_is_flying.clear()
	var dir: DirAccess = DirAccess.open(_ENEMY_DATA_DIR)
	if dir == null:
		push_warning("ChronicleManager: cannot open enemy_data directory.")
		return
	var err: Error = dir.list_dir_begin()
	if err != OK:
		push_warning("ChronicleManager: list_dir_begin failed for enemy_data.")
		return
	var fn: String = dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var path: String = _ENEMY_DATA_DIR.path_join(fn)
			var res: Resource = load(path) as Resource
			if res is EnemyData:
				var ed: EnemyData = res as EnemyData
				_enemy_type_is_flying[int(ed.enemy_type)] = ed.is_flying
		fn = dir.get_next()
	dir.list_dir_end()


func _load_perk_resources() -> void:
	_perks.clear()
	_scan_resources_dir(_PERKS_DIR, true)


func _load_entry_resources() -> void:
	_entries.clear()
	_scan_resources_dir(_ENTRIES_DIR, false)


func _scan_resources_dir(dir_path: String, is_perk: bool) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("ChronicleManager: cannot open directory: %s" % dir_path)
		return
	var err: Error = dir.list_dir_begin()
	if err != OK:
		push_warning("ChronicleManager: list_dir_begin failed: %s" % dir_path)
		return
	var fn: String = dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var full_path: String = dir_path.path_join(fn)
			var res: Resource = load(full_path) as Resource
			if is_perk:
				if _is_perk_data(res as Resource):
					var pd: Resource = res as Resource
					var pid: String = String(pd.perk_id).strip_edges()
					if not pid.is_empty():
						_perks[pid] = pd
			else:
				if _is_entry_data(res as Resource):
					var ed: Resource = res as Resource
					var eid: String = String(ed.entry_id).strip_edges()
					if not eid.is_empty():
						var seen_new: Array[String] = []
						_entries[eid] = {
							"data": ed,
							"progress": 0,
							"completed": false,
							"seen_boss_ids": seen_new,
						}
		fn = dir.get_next()
	dir.list_dir_end()


func _init_entry_runtime_state() -> void:
	## Ensure every loaded entry has required keys (after partial loads).
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		if not st.has("seen_boss_ids"):
			var empty_seen: Array[String] = []
			st["seen_boss_ids"] = empty_seen
		if not st.has("progress"):
			st["progress"] = 0
		if not st.has("completed"):
			st["completed"] = false


func _is_enemy_type_flying(enemy_type: Types.EnemyType) -> bool:
	var key: int = int(enemy_type)
	return bool(_enemy_type_is_flying.get(key, false))


func get_entry_ids_sorted() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for k: Variant in _entries.keys():
		ids.append(String(k))
	ids.sort()
	return ids


func get_entry_state(entry_id: String) -> Dictionary:
	var st: Variant = _entries.get(entry_id, {})
	if st is Dictionary:
		return st as Dictionary
	return {}


func get_perk_display_name(perk_id: String) -> String:
	var pid: String = perk_id.strip_edges()
	if pid.is_empty():
		return ""
	var pd: Resource = _perks.get(pid) as Resource
	if pd == null:
		return pid
	return String(pd.display_name)


## Multiplier applied on top of territory research cost multiplier (each perk stacks multiplicatively).
func get_chronicle_research_cost_multiplier() -> float:
	var m: float = 1.0
	for pid: String in _active_perks:
		var pd: Resource = _perks.get(pid) as Resource
		if pd == null:
			continue
		if pd.effect_type == Types.ChroniclePerkEffectType.RESEARCH_COST_PCT:
			m *= maxf(0.05, 1.0 - pd.effect_value)
	return m


## Multiplier on enchanting gold costs (stacks multiplicatively).
func get_chronicle_enchanting_cost_multiplier() -> float:
	var m: float = 1.0
	for pid: String in _active_perks:
		var pd: Resource = _perks.get(pid) as Resource
		if pd == null:
			continue
		if pd.effect_type == Types.ChroniclePerkEffectType.ENCHANTING_COST_PCT:
			m *= maxf(0.05, 1.0 - pd.effect_value)
	return m


## Additive fraction of base kill gold (e.g. 0.02 = +2%).
func get_chronicle_gold_per_kill_percent_bonus() -> float:
	var s: float = 0.0
	for pid: String in _active_perks:
		var pd: Resource = _perks.get(pid) as Resource
		if pd == null:
			continue
		if pd.effect_type == Types.ChroniclePerkEffectType.GOLD_PER_KILL_PCT:
			s += pd.effect_value
	return s


## Flat gold added to each wave-clear reward grant.
func get_chronicle_wave_reward_gold_flat() -> int:
	var t: int = 0
	for pid: String in _active_perks:
		var pd: Resource = _perks.get(pid) as Resource
		if pd == null:
			continue
		if pd.effect_type == Types.ChroniclePerkEffectType.WAVE_REWARD_GOLD:
			t += int(round(pd.effect_value))
	return t


## Called after mission economy is applied, before waves start.
func apply_perks_at_mission_start() -> void:
	var starting_gold: int = 0
	var starting_mana: int = 0
	var starting_bm: int = 0
	var sell_stack: float = 1.0
	for pid: String in _active_perks:
		var pd: Resource = _perks.get(pid) as Resource
		if pd == null:
			continue
		match pd.effect_type:
			Types.ChroniclePerkEffectType.STARTING_GOLD:
				starting_gold += int(round(pd.effect_value))
			Types.ChroniclePerkEffectType.STARTING_MANA:
				starting_mana += int(round(pd.effect_value))
			Types.ChroniclePerkEffectType.BUILDING_MATERIAL_START:
				starting_bm += int(round(pd.effect_value))
			Types.ChroniclePerkEffectType.SELL_REFUND_PCT:
				sell_stack *= 1.0 + pd.effect_value
			_:
				pass
	if starting_gold > 0:
		EconomyManager.add_gold(starting_gold)
	if starting_bm > 0:
		EconomyManager.add_building_material(starting_bm)
	if sell_stack > 1.00001:
		EconomyManager.sell_refund_global_multiplier *= sell_stack
	if starting_mana > 0:
		var spell: SpellManager = get_tree().root.get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
		if spell != null:
			spell.restore_mana(starting_mana)


func save_progress() -> void:
	var entries_out: Dictionary = {}
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var seen_raw: Variant = st.get("seen_boss_ids", [])
		var seen_list: Array = []
		if seen_raw is Array:
			for x: Variant in seen_raw as Array:
				if x is String:
					seen_list.append(x)
		entries_out[entry_id] = {
			"progress": int(st.get("progress", 0)),
			"completed": bool(st.get("completed", false)),
			"seen_boss_ids": seen_list,
		}
	var root: Dictionary = {
		"version": _PROGRESS_VERSION,
		"entries": entries_out,
		"active_perks": _active_perks.duplicate(),
	}
	var json_text: String = JSON.stringify(root)
	var f: FileAccess = FileAccess.open(_progress_file, FileAccess.WRITE)
	if f == null:
		push_warning("ChronicleManager: could not write progress file.")
		return
	f.store_string(json_text)
	f.close()


func load_progress() -> void:
	if not FileAccess.file_exists(_progress_file):
		return
	var f: FileAccess = FileAccess.open(_progress_file, FileAccess.READ)
	if f == null:
		push_warning("ChronicleManager: could not read progress file.")
		return
	var json_text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("ChronicleManager: progress JSON invalid; using defaults.")
		return
	var root: Dictionary = parsed as Dictionary
	var ver: int = int(root.get("version", 0))
	if ver != _PROGRESS_VERSION:
		push_warning("ChronicleManager: progress version mismatch; merging cautiously.")
	var entries_blob: Dictionary = root.get("entries", {}) as Dictionary
	for entry_id: String in entries_blob.keys():
		if not _entries.has(entry_id):
			continue
		var st: Dictionary = _entries[entry_id] as Dictionary
		var blob: Dictionary = entries_blob[entry_id] as Dictionary
		st["progress"] = int(blob.get("progress", st.get("progress", 0)))
		st["completed"] = bool(blob.get("completed", st.get("completed", false)))
		var seen_raw: Variant = blob.get("seen_boss_ids", [])
		var seen_list: Array[String] = []
		if seen_raw is Array:
			for x: Variant in seen_raw as Array:
				if x is String:
					seen_list.append(x as String)
		st["seen_boss_ids"] = seen_list
	var ap: Variant = root.get("active_perks", [])
	_active_perks.clear()
	if ap is Array:
		for x: Variant in ap as Array:
			if x is String:
				var sid: String = x as String
				if _perks.has(sid) and not _active_perks.has(sid):
					_active_perks.append(sid)


func reset_for_test() -> void:
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		st["progress"] = 0
		st["completed"] = false
		var empty_reset: Array[String] = []
		st["seen_boss_ids"] = empty_reset
	_active_perks.clear()
	_last_gold_balance = EconomyManager.get_gold()


func _on_enemy_killed(enemy_type: Types.EnemyType, _position: Vector3, _gold_reward: int) -> void:
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var data: Resource = st.get("data") as Resource
		if data == null or data.tracking_signal != "enemy_killed":
			continue
		if bool(st.get("completed", false)):
			continue
		if data.tracking_field == _TRACK_FLYING_ONLY and not _is_enemy_type_flying(enemy_type):
			continue
		_add_progress(entry_id, 1)


func _on_mission_won(_mission_number: int) -> void:
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var data: Resource = st.get("data") as Resource
		if data == null or data.tracking_signal != "mission_won":
			continue
		if bool(st.get("completed", false)):
			continue
		_add_progress(entry_id, 1)


func _on_building_placed(_slot_index: int, _building_type: Types.BuildingType) -> void:
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var data: Resource = st.get("data") as Resource
		if data == null or data.tracking_signal != "building_placed":
			continue
		if bool(st.get("completed", false)):
			continue
		_add_progress(entry_id, 1)


func _on_boss_killed(boss_id: String) -> void:
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var data: Resource = st.get("data") as Resource
		if data == null or data.tracking_signal != "boss_killed":
			continue
		if bool(st.get("completed", false)):
			continue
		if data.tracking_field == _TRACK_UNIQUE_BOSSES:
			var seen: Array = st.get("seen_boss_ids", []) as Array
			if not seen.has(boss_id):
				seen.append(boss_id)
				st["seen_boss_ids"] = seen
			var seen2: Array = st["seen_boss_ids"] as Array
			var uq: int = seen2.size()
			var trg: int = maxi(1, data.target_count)
			var prog: int = mini(uq, trg)
			st["progress"] = prog
			SignalBus.chronicle_progress_updated.emit(entry_id, prog, trg)
			if uq >= trg:
				_finish_entry(entry_id)
		else:
			_add_progress(entry_id, 1)


func _on_campaign_completed(_campaign_id: String) -> void:
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var data: Resource = st.get("data") as Resource
		if data == null or data.tracking_signal != "campaign_completed":
			continue
		if bool(st.get("completed", false)):
			continue
		_add_progress(entry_id, 1)


func _on_resource_changed(resource_type: Types.ResourceType, new_amount: int) -> void:
	if resource_type != Types.ResourceType.GOLD:
		return
	if _last_gold_balance < 0:
		_last_gold_balance = new_amount
		return
	var delta: int = new_amount - _last_gold_balance
	_last_gold_balance = new_amount
	if delta <= 0:
		return
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var data: Resource = st.get("data") as Resource
		if data == null or data.tracking_signal != "gold_earned":
			continue
		if bool(st.get("completed", false)):
			continue
		_add_progress(entry_id, delta)


func _on_research_unlocked(_node_id: String) -> void:
	for entry_id: String in _entries.keys():
		var st: Dictionary = _entries[entry_id] as Dictionary
		var data: Resource = st.get("data") as Resource
		if data == null or data.tracking_signal != "research_completed":
			continue
		if bool(st.get("completed", false)):
			continue
		_add_progress(entry_id, 1)


func _add_progress(entry_id: String, delta: int) -> void:
	if delta <= 0:
		return
	if not _entries.has(entry_id):
		return
	var st: Dictionary = _entries[entry_id] as Dictionary
	if bool(st.get("completed", false)):
		return
	var data: Resource = st.get("data") as Resource
	if data == null:
		return
	var trg: int = maxi(1, data.target_count)
	var prog: int = int(st.get("progress", 0))
	prog = mini(prog + delta, trg)
	st["progress"] = prog
	SignalBus.chronicle_progress_updated.emit(entry_id, prog, trg)
	_check_completion(entry_id)


func _check_completion(entry_id: String) -> void:
	var st: Dictionary = _entries[entry_id] as Dictionary
	if bool(st.get("completed", false)):
		return
	var data: Resource = st.get("data") as Resource
	if data == null:
		return
	var prog: int = int(st.get("progress", 0))
	var trg: int = maxi(1, data.target_count)
	if prog >= trg:
		_finish_entry(entry_id)


func _finish_entry(entry_id: String) -> void:
	var st: Dictionary = _entries[entry_id] as Dictionary
	if bool(st.get("completed", false)):
		return
	st["completed"] = true
	var data: Resource = st.get("data") as Resource
	SignalBus.chronicle_entry_completed.emit(entry_id)
	_grant_reward(data)


func _grant_reward(entry: Resource) -> void:
	if entry == null:
		return
	if entry.reward_type != Types.ChronicleRewardType.PERK:
		save_progress()
		return
	var rid: String = entry.reward_id.strip_edges()
	if rid.is_empty():
		save_progress()
		return
	if not _perks.has(rid):
		push_warning("ChronicleManager: reward perk not found: %s" % rid)
		save_progress()
		return
	if not _active_perks.has(rid):
		_active_perks.append(rid)
	SignalBus.chronicle_perk_activated.emit(rid)
	save_progress()
