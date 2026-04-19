## SybilPassiveManager — Loads Sybil passive resources, offers a random subset per mission, applies modifiers.
## Typed as Resource (not SybilPassiveData) so this autoload compiles before global class registration.
extends Node

const PASSIVE_DATA_DIR: String = "res://resources/passive_data/"
const OFFER_COUNT: int = 4

var _all_passives: Array = []
var _active_passive_id: String = ""
var _active_passive: Resource = null


func _ready() -> void:
	_load_passives_from_directory()


func _load_passives_from_directory() -> void:
	_all_passives.clear()
	var dir: DirAccess = DirAccess.open(PASSIVE_DATA_DIR)
	if dir == null:
		push_warning("SybilPassiveManager: cannot open directory %s" % PASSIVE_DATA_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = "%s%s" % [PASSIVE_DATA_DIR, file_name]
			var res: Resource = load(path) as Resource
			if res != null:
				_all_passives.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()


## Returns up to [constant OFFER_COUNT] random unlocked passives; emits [signal SignalBus.sybil_passives_offered].
func get_offered_passives() -> Array:
	var unlocked: Array = []
	for sp: Variant in _all_passives:
		var res: Resource = sp as Resource
		if res != null and bool(res.get("is_unlocked")):
			unlocked.append(res)
	var pool: Array = unlocked.duplicate()
	pool.shuffle()
	var result: Array = []
	var n: int = mini(OFFER_COUNT, pool.size())
	for i: int in range(n):
		result.append(pool[i])
	var ids: Array[String] = []
	for sp2: Variant in result:
		var r2: Resource = sp2 as Resource
		if r2 != null:
			ids.append(str(r2.get("passive_id")))
	SignalBus.sybil_passives_offered.emit(ids)
	return result


func select_passive(passive_id: String) -> void:
	_active_passive_id = ""
	_active_passive = null
	for sp: Variant in _all_passives:
		var res: Resource = sp as Resource
		if res != null and str(res.get("passive_id")) == passive_id:
			_active_passive_id = passive_id
			_active_passive = res
			break
	SignalBus.sybil_passive_selected.emit(passive_id)


func get_active_passive() -> Resource:
	return _active_passive


func get_passive_data_by_id(passive_id: String) -> Resource:
	for sp: Variant in _all_passives:
		var res: Resource = sp as Resource
		if res != null and str(res.get("passive_id")) == passive_id:
			return res
	return null


func get_modifier(effect_type: String) -> float:
	if _active_passive == null:
		return 0.0
	if str(_active_passive.get("effect_type")) == effect_type:
		return float(_active_passive.get("effect_value"))
	return 0.0


func clear_passive() -> void:
	_active_passive_id = ""
	_active_passive = null


func get_save_data() -> Dictionary:
	return {"active_passive_id": _active_passive_id}


func restore_from_save_data(data: Dictionary) -> void:
	var id_v: Variant = data.get("active_passive_id", "")
	var id: String = id_v as String if id_v is String else ""
	if id.is_empty():
		clear_passive()
		return
	for sp: Variant in _all_passives:
		var res: Resource = sp as Resource
		if res != null and str(res.get("passive_id")) == id:
			_active_passive_id = id
			_active_passive = res
			return
	clear_passive()
