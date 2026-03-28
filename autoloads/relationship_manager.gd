## relationship_manager.gd
## Data-driven affinity (-100..100) and tiers; reacts to RelationshipEventData + SignalBus.
## Registered as autoload `RelationshipManager` (no `class_name` — avoids shadowing the singleton).

extends Node

const TIER_CONFIG_PATH: String = "res://resources/relationship_tier_config.tres"
const CHARACTER_REL_DIR: String = "res://resources/character_relationship/"
const RELATIONSHIP_EVENTS_DIR: String = "res://resources/relationship_events/"

const AFFINITY_MIN: float = -100.0
const AFFINITY_MAX: float = 100.0

var _affinities: Dictionary = {}
var _tier_config: RelationshipTierConfig

## When set before _ready() (e.g. tests), replaces directory scan for RelationshipEventData.
var test_relationship_events_override: Array[RelationshipEventData] = []

var _signal_bus_connections: Array[Dictionary] = []


func _ready() -> void:
	_tier_config = load(TIER_CONFIG_PATH) as RelationshipTierConfig
	if _tier_config == null:
		push_error("RelationshipManager: failed to load %s" % TIER_CONFIG_PATH)
		return
	_load_character_relationship_resources()
	_connect_relationship_events()


## Returns the raw affinity float (−100..100) for the given character_id.
func get_affinity(character_id: String) -> float:
	return float(_affinities.get(character_id, 0.0))


## Returns the tier name string for the given character_id based on current affinity.
func get_tier(character_id: String) -> String:
	if _tier_config == null:
		return ""
	var affinity: float = get_affinity(character_id)
	var best_name: String = ""
	var best_min: float = -INF
	for entry: Dictionary in _tier_config.tiers:
		var mn: float = float(entry.get("min_affinity", -INF))
		if mn <= affinity and mn >= best_min:
			best_min = mn
			best_name = str(entry.get("name", ""))
	return best_name


## Returns the numeric rank index of the given tier name (higher = warmer relationship).
func get_tier_rank_index(tier_name: String) -> int:
	if _tier_config == null:
		return -1
	for i: int in range(_tier_config.tiers.size()):
		var d: Dictionary = _tier_config.tiers[i]
		if str(d.get("name", "")) == tier_name:
			return i
	return -1


## Adds a delta to the affinity for the given character_id, clamping to −100..100.
func add_affinity(character_id: String, delta: float) -> void:
	var base: float = float(_affinities.get(character_id, 0.0))
	_affinities[character_id] = clampf(base + delta, AFFINITY_MIN, AFFINITY_MAX)


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	return {"affinities": _affinities.duplicate()}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	if not data.has("affinities"):
		return
	var raw: Variant = data["affinities"]
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var d: Dictionary = raw as Dictionary
	_affinities.clear()
	for k: Variant in d.keys():
		_affinities[str(k)] = clampf(float(d[k]), AFFINITY_MIN, AFFINITY_MAX)


## Reloads all CharacterRelationshipData and RelationshipEventData from disk.
func reload_from_resources() -> void:
	_disconnect_relationship_events()
	_affinities.clear()
	_load_character_relationship_resources()
	_connect_relationship_events()


func _load_character_relationship_resources() -> void:
	var paths: PackedStringArray = _list_tres_paths_recursive(CHARACTER_REL_DIR)
	for path: String in paths:
		var res: Resource = load(path)
		if res == null:
			continue
		if not res is CharacterRelationshipData:
			continue
		var cr: CharacterRelationshipData = res as CharacterRelationshipData
		if cr.character_id.is_empty():
			continue
		_affinities[cr.character_id] = clampf(cr.starting_affinity, AFFINITY_MIN, AFFINITY_MAX)


func _scan_relationship_event_data() -> Array[RelationshipEventData]:
	var out: Array[RelationshipEventData] = []
	var paths: PackedStringArray = _list_tres_paths_recursive(RELATIONSHIP_EVENTS_DIR)
	for path: String in paths:
		var res: Resource = load(path)
		if res == null:
			continue
		if not res is RelationshipEventData:
			continue
		out.append(res as RelationshipEventData)
	return out


func _list_tres_paths_recursive(root: String) -> PackedStringArray:
	var acc: PackedStringArray = []
	var dir := DirAccess.open(root)
	if dir == null:
		return acc
	_dir_scan_recursive(dir, root, acc)
	return acc


func _dir_scan_recursive(dir: DirAccess, base_path: String, acc: PackedStringArray) -> void:
	dir.list_dir_begin()
	while true:
		var n := dir.get_next()
		if n == "":
			break
		if n.begins_with("."):
			continue
		var full_path: String = "%s/%s" % [base_path, n]
		if dir.current_is_dir():
			var sub := DirAccess.open(full_path)
			if sub != null:
				_dir_scan_recursive(sub, full_path, acc)
		elif n.ends_with(".tres"):
			acc.append(full_path)
	dir.list_dir_end()


func _connect_relationship_events() -> void:
	_disconnect_relationship_events()
	var events: Array[RelationshipEventData] = []
	if not test_relationship_events_override.is_empty():
		events.append_array(test_relationship_events_override)
	else:
		events = _scan_relationship_event_data()
	for event: RelationshipEventData in events:
		_connect_one_event(event)


func _connect_one_event(event: RelationshipEventData) -> void:
	if not SignalBus.has_signal(StringName(event.signal_name)):
		push_warning(
			"RelationshipManager: SignalBus has no signal '%s', skipping relationship event" % event.signal_name
		)
		return
	var cb: Callable = func(_payload: Variant = null) -> void:
		_apply_event_deltas(event)
	var err: Error = SignalBus.connect(StringName(event.signal_name), cb)
	if err != OK:
		push_warning("RelationshipManager: connect failed for '%s' (%s)" % [event.signal_name, str(err)])
		return
	_signal_bus_connections.append({"signal": event.signal_name, "callable": cb})


func _disconnect_relationship_events() -> void:
	for d: Dictionary in _signal_bus_connections:
		var sn: StringName = StringName(str(d["signal"]))
		var cb: Callable = d["callable"] as Callable
		if SignalBus.is_connected(sn, cb):
			SignalBus.disconnect(sn, cb)
	_signal_bus_connections.clear()


func _apply_event_deltas(event: RelationshipEventData) -> void:
	for k: Variant in event.character_deltas.keys():
		var cid: String = str(k)
		add_affinity(cid, float(event.character_deltas[k]))
