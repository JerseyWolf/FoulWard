## SaveManager — rolling autosaves per campaign/endless attempt (AUDIT 6 §3.5).
## Paths: user://saves/attempt_{attempt_id}/slot_{0..4}.json — slot 0 is most recent.
## Autoload singleton only (no class_name — avoids hiding the autoload).

extends Node

const MAX_SLOTS: int = 5
const SAVES_ROOT: String = "user://saves"

var current_attempt_id: String = ""


func _ready() -> void:
	_ensure_saves_root()


func _ensure_saves_root() -> void:
	if DirAccess.open(SAVES_ROOT) == null:
		DirAccess.make_dir_recursive_absolute(SAVES_ROOT)


func _sanitize_attempt_id(raw: String) -> String:
	return raw.replace(":", "-").replace("/", "-").replace("\\", "-")


func _attempt_dir_path() -> String:
	return "%s/attempt_%s" % [SAVES_ROOT, current_attempt_id]


func _slot_file_name(slot_index: int) -> String:
	return "slot_%d.json" % slot_index


func _slot_path(slot_index: int) -> String:
	return "%s/%s" % [_attempt_dir_path(), _slot_file_name(slot_index)]


## Initializes a new save attempt directory and resets the slot ring.
func start_new_attempt() -> void:
	var raw: String = Time.get_datetime_string_from_system()
	current_attempt_id = _sanitize_attempt_id(raw)
	_ensure_saves_root()
	var attempt_dir: String = _attempt_dir_path()
	if DirAccess.open(attempt_dir) == null:
		DirAccess.make_dir_recursive_absolute(attempt_dir)
	else:
		_clear_attempt_slots(attempt_dir)


func _clear_attempt_slots(attempt_dir: String) -> void:
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return
	for i: int in range(MAX_SLOTS):
		var fn: String = _slot_file_name(i)
		if dir.file_exists(fn):
			dir.remove(fn)


## Collects state from all managers and writes a new save slot JSON file.
func save_current_state() -> void:
	if current_attempt_id.is_empty():
		push_warning("SaveManager.save_current_state: current_attempt_id is empty; call start_new_attempt() first.")
		return
	_ensure_saves_root()
	var attempt_dir: String = _attempt_dir_path()
	if DirAccess.open(attempt_dir) == null:
		DirAccess.make_dir_recursive_absolute(attempt_dir)
	_shift_slots(attempt_dir)
	var payload: Dictionary = _build_save_payload()
	var json_text: String = JSON.stringify(payload)
	var path: String = "%s/%s" % [attempt_dir, _slot_file_name(0)]
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: failed to write %s" % path)
		return
	f.store_string(json_text)
	f.close()


func _shift_slots(attempt_dir: String) -> void:
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return
	var last: int = MAX_SLOTS - 1
	var last_fn: String = _slot_file_name(last)
	if dir.file_exists(last_fn):
		dir.remove(last_fn)
	for i: int in range(last - 1, -1, -1):
		var fn: String = _slot_file_name(i)
		if dir.file_exists(fn):
			var err: Error = dir.rename(fn, _slot_file_name(i + 1))
			if err != OK:
				push_error("SaveManager._shift_slots: rename failed %s" % str(err))


func _build_save_payload() -> Dictionary:
	return {
		"version": 1,
		"attempt_id": current_attempt_id,
		"campaign": CampaignManager.get_save_data(),
		"game": GameManager.get_save_data(),
		"relationship": RelationshipManager.get_save_data(),
		"research": _get_research_save(),
		"shop": _get_shop_save(),
		"enchantments": EnchantmentManager.get_save_data(),
	}


func _get_research_save() -> Dictionary:
	var rm: ResearchManager = _get_research_manager()
	if rm == null:
		return {"unlocked_node_ids": [] as Array[String]}
	return rm.get_save_data()


func _get_shop_save() -> Dictionary:
	var sm: ShopManager = _get_shop_manager()
	if sm == null:
		return {}
	return sm.get_save_data()


func _get_research_manager() -> ResearchManager:
	return get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager


func _get_shop_manager() -> ShopManager:
	return get_node_or_null("/root/Main/Managers/ShopManager") as ShopManager


## Restores all manager state from the save slot at the given index.
func load_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false
	var attempt_dir: String = ""
	if current_attempt_id.is_empty():
		attempt_dir = _find_attempt_dir_with_slot(slot_index)
		if attempt_dir.is_empty():
			return false
		var folder_name: String = attempt_dir.get_file()
		current_attempt_id = folder_name.trim_prefix("attempt_")
	else:
		attempt_dir = _attempt_dir_path()
	var path: String = "%s/%s" % [attempt_dir, _slot_file_name(slot_index)]
	if not FileAccess.file_exists(path):
		return false
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var text: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager.load_slot: JSON parse error")
		return false
	var d: Dictionary = parsed as Dictionary
	var aid: Variant = d.get("attempt_id", "")
	if aid is String and not (aid as String).is_empty():
		current_attempt_id = aid as String
	_apply_save_payload(d)
	_discard_newer_slots(attempt_dir, slot_index)
	return true


func _find_attempt_dir_with_slot(slot_index: int) -> String:
	var root: DirAccess = DirAccess.open(SAVES_ROOT)
	if root == null:
		return ""
	var best_dir: String = ""
	var best_mtime: int = 0
	root.list_dir_begin()
	var entry: String = root.get_next()
	while entry != "":
		if root.current_is_dir() and entry.begins_with("attempt_"):
			var sub: String = "%s/%s" % [SAVES_ROOT, entry]
			var sp: String = "%s/%s" % [sub, _slot_file_name(slot_index)]
			if FileAccess.file_exists(sp):
				var mt: int = FileAccess.get_modified_time(sp)
				if mt >= best_mtime:
					best_mtime = mt
					best_dir = sub
		entry = root.get_next()
	root.list_dir_end()
	return best_dir


func _apply_save_payload(d: Dictionary) -> void:
	var camp: Variant = d.get("campaign", {})
	if camp is Dictionary:
		CampaignManager.restore_from_save(camp as Dictionary)
	var game: Variant = d.get("game", {})
	if game is Dictionary:
		GameManager.restore_from_save(game as Dictionary)
	var rel: Variant = d.get("relationship", {})
	if rel is Dictionary:
		RelationshipManager.restore_from_save(rel as Dictionary)
	var res: Variant = d.get("research", {})
	if res is Dictionary:
		var rm: ResearchManager = _get_research_manager()
		if rm != null:
			rm.restore_from_save(res as Dictionary)
	var shop: Variant = d.get("shop", {})
	if shop is Dictionary:
		var sm: ShopManager = _get_shop_manager()
		if sm != null:
			sm.restore_from_save(shop as Dictionary)
	var ench: Variant = d.get("enchantments", {})
	if ench is Dictionary:
		EnchantmentManager.restore_from_save(ench as Dictionary)


func _discard_newer_slots(attempt_dir: String, loaded_slot_index: int) -> void:
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return
	for i: int in range(0, loaded_slot_index):
		var fn: String = _slot_file_name(i)
		if dir.file_exists(fn):
			dir.remove(fn)


## Returns the list of slot indices that have saved data in the current attempt.
func get_available_slots() -> Array[int]:
	var result: Array[int] = []
	if current_attempt_id.is_empty():
		return result
	var attempt_dir: String = _attempt_dir_path()
	var dir: DirAccess = DirAccess.open(attempt_dir)
	if dir == null:
		return result
	for i: int in range(MAX_SLOTS):
		if dir.file_exists(_slot_file_name(i)):
			result.append(i)
	return result


## Returns true if at least one save slot exists in the current attempt directory.
func has_resumable_attempt() -> bool:
	_ensure_saves_root()
	var root: DirAccess = DirAccess.open(SAVES_ROOT)
	if root == null:
		return false
	root.list_dir_begin()
	var entry: String = root.get_next()
	while entry != "":
		if root.current_is_dir() and entry.begins_with("attempt_"):
			var sub: String = "%s/%s" % [SAVES_ROOT, entry]
			var dir2: DirAccess = DirAccess.open(sub)
			if dir2 != null:
				for i: int in range(MAX_SLOTS):
					if dir2.file_exists(_slot_file_name(i)):
						root.list_dir_end()
						return true
		entry = root.get_next()
	root.list_dir_end()
	return false


## Test helper: removes all attempt_* folders under user://saves (headless tests only).
func clear_all_saves_for_test() -> void:
	var root: DirAccess = DirAccess.open(SAVES_ROOT)
	if root == null:
		return
	var to_remove: PackedStringArray = PackedStringArray()
	root.list_dir_begin()
	var entry: String = root.get_next()
	while entry != "":
		if root.current_is_dir() and entry.begins_with("attempt_"):
			to_remove.append(entry)
		entry = root.get_next()
	root.list_dir_end()
	for name: String in to_remove:
		var sub: String = "%s/%s" % [SAVES_ROOT, name]
		var inner: DirAccess = DirAccess.open(sub)
		if inner != null:
			for i: int in range(MAX_SLOTS):
				var fn: String = _slot_file_name(i)
				if inner.file_exists(fn):
					inner.remove(fn)
		var rr: DirAccess = DirAccess.open(SAVES_ROOT)
		if rr != null:
			rr.remove(name)
