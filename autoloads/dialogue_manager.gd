## dialogue_manager.gd
## Loads DialogueEntry resources, tracks hub dialogue state (priority, once-only, chains).
## UI-agnostic: UIManager / DialogueUI call request_entry_for_character and mark_entry_played.

extends Node

const DIALOGUE_ROOT_PATH: String = "res://resources/dialogue"

var entries_by_id: Dictionary = {}
var entries_by_character: Dictionary = {}
var played_once_only: Dictionary = {}
var active_chains_by_character: Dictionary = {}

var mission_won_count: int = 0
var mission_failed_count: int = 0
var current_mission_number: int = 1
var current_gamestate: Types.GameState = Types.GameState.MAIN_MENU

## Snapshot of gold for dialogue conditions; updated on `resource_changed` (GOLD).
var _current_gold: int = 0

## node_id → true — supplements ResearchManager for `research_unlocked_<id>` conditions.
var _unlocked_research_ids: Dictionary = {}

## Total shop purchases tracked for dialogue; last item id stored separately.
var _purchase_count: int = 0
var _last_purchased_item_id: String = ""
var _shop_purchased_item_ids: Dictionary = {}

var _arnulf_current_state: Types.ArnulfState = Types.ArnulfState.IDLE

var _spell_cast_count: int = 0
var _last_spell_cast_id: String = ""

## Per-mission combat dialogue state (reset on mission_started).
var _combat_kills_this_mission: int = 0
var _combat_wave_number: int = 0
var _combat_boss_seen: bool = false
var _combat_first_blood: bool = false
var _combat_florence_damaged: bool = false
## entry_id → true — combat lines shown this mission (request_combat_line dedup).
var _seen_combat_lines: Dictionary = {}

var _rng := RandomNumberGenerator.new() # TUNING

## Test-only: incremented when CampaignManager starts a campaign day (non–endless mode).
var _campaign_day_started_calls_for_test: int = 0

# dialogue_line_started and dialogue_line_finished are declared on SignalBus.


func _ready() -> void:
	_rng.randomize()
	_load_all_dialogue_entries()
	_sync_from_game_manager()
	_current_gold = EconomyManager.get_gold()
	_connect_signals()


func _sync_from_game_manager() -> void:
	current_mission_number = GameManager.get_current_mission()
	current_gamestate = GameManager.get_game_state()
	_current_gold = EconomyManager.get_gold()


## Called from CampaignManager when a new campaign day begins (skipped in endless mode).
func on_campaign_day_started() -> void:
	_campaign_day_started_calls_for_test += 1
	_sync_from_game_manager()


## Test helper: returns how many times on_campaign_day_started was called.
func get_campaign_day_started_calls_for_test() -> int:
	return _campaign_day_started_calls_for_test


## Test helper: resets the campaign_day_started call counter to zero.
func reset_campaign_day_started_calls_for_test() -> void:
	_campaign_day_started_calls_for_test = 0


func _load_all_dialogue_entries() -> void:
	entries_by_id.clear()
	entries_by_character.clear()
	played_once_only.clear()
	active_chains_by_character.clear()

	var dir := DirAccess.open(DIALOGUE_ROOT_PATH)
	if dir == null:
		push_warning("DialogueManager: could not open dialogue root at %s" % DIALOGUE_ROOT_PATH)
		return

	_scan_directory_recursive(DIALOGUE_ROOT_PATH)


func _scan_directory_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var file_name := dir.get_next()
		if file_name == "":
			break
		if file_name.begins_with("."):
			continue

		var full_path := "%s/%s" % [path, file_name]
		if dir.current_is_dir():
			_scan_directory_recursive(full_path)
		else:
			if full_path.ends_with(".tres"):
				_try_register_entry(full_path)

	dir.list_dir_end()


func _try_register_entry(path: String) -> void:
	var res: Resource = load(path)
	if res == null:
		push_warning("DialogueManager: failed to load resource at %s" % path)
		return
	if not res is DialogueEntry:
		return

	var entry: DialogueEntry = res as DialogueEntry
	if entry.entry_id.is_empty():
		push_warning("DialogueManager: DialogueEntry at %s has empty entry_id" % path)
		return

	if entries_by_id.has(entry.entry_id):
		push_warning("DialogueManager: duplicate entry_id '%s' at %s" % [entry.entry_id, path])

	entries_by_id[entry.entry_id] = entry

	if not entries_by_character.has(entry.character_id):
		entries_by_character[entry.character_id] = [] as Array[DialogueEntry]
	(entries_by_character[entry.character_id] as Array).append(entry)


func _connect_signals() -> void:
	if not SignalBus.game_state_changed.is_connected(_on_game_state_changed):
		SignalBus.game_state_changed.connect(_on_game_state_changed)
	if not SignalBus.mission_started.is_connected(_on_mission_started):
		SignalBus.mission_started.connect(_on_mission_started)
	if not SignalBus.mission_won.is_connected(_on_mission_won):
		SignalBus.mission_won.connect(_on_mission_won)
	if not SignalBus.mission_failed.is_connected(_on_mission_failed):
		SignalBus.mission_failed.connect(_on_mission_failed)
	if not SignalBus.resource_changed.is_connected(_on_resource_changed):
		SignalBus.resource_changed.connect(_on_resource_changed)
	if not SignalBus.research_unlocked.is_connected(_on_research_unlocked):
		SignalBus.research_unlocked.connect(_on_research_unlocked)
	if not SignalBus.shop_item_purchased.is_connected(_on_shop_item_purchased):
		SignalBus.shop_item_purchased.connect(_on_shop_item_purchased)
	if not SignalBus.arnulf_state_changed.is_connected(_on_arnulf_state_changed):
		SignalBus.arnulf_state_changed.connect(_on_arnulf_state_changed)
	if not SignalBus.spell_cast.is_connected(_on_spell_cast):
		SignalBus.spell_cast.connect(_on_spell_cast)
	if not SignalBus.enemy_killed.is_connected(_on_combat_enemy_killed):
		SignalBus.enemy_killed.connect(_on_combat_enemy_killed)
	if not SignalBus.wave_started.is_connected(_on_combat_wave_started):
		SignalBus.wave_started.connect(_on_combat_wave_started)
	if not SignalBus.florence_damaged.is_connected(_on_combat_florence_damaged):
		SignalBus.florence_damaged.connect(_on_combat_florence_damaged)
	if not SignalBus.boss_spawned.is_connected(_on_combat_boss_spawned):
		SignalBus.boss_spawned.connect(_on_combat_boss_spawned)


## Peek-only: eligible hub line without emitting dialogue_line_started (e.g. Talk button visibility).
func peek_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry:
	return _request_entry_for_character(character_id, tags, false)


## Returns the highest-priority eligible DialogueEntry for the given character and tags.
func request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry:
	return _request_entry_for_character(character_id, tags, true)


func _request_entry_for_character(character_id: String, tags: Array[String], emit_started_signal: bool) -> DialogueEntry:
	if not entries_by_character.has(character_id):
		return null

	var active_chain_id: String = str(active_chains_by_character.get(character_id, ""))
	if not active_chain_id.is_empty():
		if entries_by_id.has(active_chain_id):
			var chain_entry: DialogueEntry = entries_by_id[active_chain_id] as DialogueEntry
			if chain_entry.is_combat_line:
				active_chains_by_character.erase(character_id)
			elif not (chain_entry.once_only and played_once_only.get(chain_entry.entry_id, false)):
				if _entry_matches_tags(chain_entry, tags) and _evaluate_conditions(chain_entry):
					if emit_started_signal:
						_emit_started(chain_entry)
					return chain_entry
			active_chains_by_character.erase(character_id)
			# Active chain exists but is blocked by once-only or fails conditions;
			# fall back to normal priority selection.
		else:
			active_chains_by_character.erase(character_id)

	var raw: Variant = entries_by_character[character_id]
	var source_list: Array = raw as Array
	var candidates: Array[DialogueEntry] = []
	for entry_variant: Variant in source_list:
		var entry: DialogueEntry = entry_variant as DialogueEntry
		if entry.is_combat_line:
			continue
		if entry.once_only and played_once_only.get(entry.entry_id, false):
			continue
		if not (_entry_matches_tags(entry, tags) and _evaluate_conditions(entry)):
			continue
		candidates.append(entry)

	if candidates.is_empty():
		return null

	var max_priority := _find_max_priority(candidates)
	var best_candidates: Array[DialogueEntry] = []
	for entry: DialogueEntry in candidates:
		if entry.priority == max_priority:
			best_candidates.append(entry)

	if best_candidates.is_empty():
		return null

	var index := 0
	if best_candidates.size() > 1:
		if emit_started_signal:
			# SOURCE: Hades-style priority bucket selection (external analysis videos/articles).
			index = _rng.randi_range(0, best_candidates.size() - 1)

	var chosen: DialogueEntry = best_candidates[index]
	if emit_started_signal:
		_emit_started(chosen)
	return chosen


## Highest-priority eligible combat banner line; marks seen and emits combat_dialogue_requested.
func request_combat_line() -> DialogueEntry:
	var best: DialogueEntry = null
	for entry_variant: Variant in entries_by_id.values():
		var entry: DialogueEntry = entry_variant as DialogueEntry
		if not entry.is_combat_line:
			continue
		if _seen_combat_lines.has(entry.entry_id):
			continue
		if not _evaluate_conditions(entry):
			continue
		if best == null or entry.priority > best.priority:
			best = entry
	if best != null:
		_seen_combat_lines[best.entry_id] = true
		SignalBus.combat_dialogue_requested.emit(best)
	return best


## Returns the DialogueEntry with the given entry_id, or null if not found.
func get_entry_by_id(entry_id: String) -> DialogueEntry:
	if entries_by_id.has(entry_id):
		return entries_by_id[entry_id] as DialogueEntry
	return null


func _entry_matches_tags(_entry: DialogueEntry, _tags: Array[String]) -> bool:
	# ASSUMPTION: DialogueEntry resources currently do not include tag metadata.
	# The hub passes CharacterData.default_dialogue_tags for future expansion.
	# For MVP, all tags are treated as non-filtering.
	return true


func _emit_started(entry: DialogueEntry) -> void:
	SignalBus.dialogue_line_started.emit(entry.entry_id, entry.character_id)


## Marks a once_only DialogueEntry as played so it will not be returned again.
func mark_entry_played(entry_id: String) -> void:
	if not entries_by_id.has(entry_id):
		return

	var entry: DialogueEntry = entries_by_id[entry_id] as DialogueEntry
	if entry.once_only:
		played_once_only[entry_id] = true

	if not entry.chain_next_id.is_empty():
		if entries_by_id.has(entry.chain_next_id):
			active_chains_by_character[entry.character_id] = entry.chain_next_id
		else:
			active_chains_by_character.erase(entry.character_id)
	else:
		active_chains_by_character.erase(entry.character_id)


## Called when a dialogue line finishes; handles chain_next_id and emits dialogue_line_finished.
func notify_dialogue_finished(entry_id: String, character_id: String) -> void:
	SignalBus.dialogue_line_finished.emit(entry_id, character_id)
	active_chains_by_character.erase(character_id)


func _find_max_priority(candidates: Array[DialogueEntry]) -> int:
	var max_priority := -999999
	for entry: DialogueEntry in candidates:
		if entry.priority > max_priority:
			max_priority = entry.priority
	return max_priority


func _evaluate_conditions(entry: DialogueEntry) -> bool:
	for cond: DialogueCondition in entry.conditions:
		if cond.condition_type == "relationship_tier":
			if not _evaluate_relationship_tier_condition(cond):
				return false
			continue
		var current_value: Variant = _resolve_state_value(cond.key)
		if not _compare(current_value, cond.comparison, cond.value):
			return false
	return true


## Neutral tier index in `relationship_tier_config.tres` (Hostile=0, Cold=1, Neutral=2, …).
const _REL_TIER_NEUTRAL_INDEX: int = 2


func _evaluate_relationship_tier_condition(cond: DialogueCondition) -> bool:
	var current_tier: String = RelationshipManager.get_tier(cond.character_id)
	var required: String = cond.required_tier
	if current_tier == required:
		return true
	var cur_i: int = RelationshipManager.get_tier_rank_index(current_tier)
	var req_i: int = RelationshipManager.get_tier_rank_index(required)
	if cur_i < 0 or req_i < 0:
		return false
	# Neutral and warmer: "at least this warm" (higher index = friendlier).
	# Below Neutral: "at most this cold" (Hostile/Cold-gated lines).
	if req_i >= _REL_TIER_NEUTRAL_INDEX:
		return cur_i >= req_i
	return cur_i <= req_i


func _resolve_state_value(key: String) -> Variant:
	match key:
		"wave_number_gte":
			return _combat_wave_number
		"kills_this_mission_gte":
			return _combat_kills_this_mission
		"boss_active":
			return _combat_boss_seen
		"first_blood":
			return _combat_first_blood
		"florence_damaged":
			return _combat_florence_damaged
		"current_mission_number":
			return current_mission_number
		"mission_won_count":
			return mission_won_count
		"mission_failed_count":
			return mission_failed_count
		"current_gamestate":
			return Types.GameState.keys()[current_gamestate]
		"gold_amount":
			return EconomyManager.get_gold()
		"building_material_amount":
			return EconomyManager.get_building_material()
		"research_material_amount":
			return EconomyManager.get_research_material()
		"sybil_research_unlocked_any":
			return _sybil_research_unlocked_any()
		"arnulf_research_unlocked_any":
			return _arnulf_research_unlocked_any()
		_:
			# SOURCE: Dialogue variable-store pattern with namespaced keys ("florence.", "campaign.").
			if key.begins_with("florence."):
				return _resolve_florence_state_value(key)
			if key.begins_with("campaign."):
				return _resolve_campaign_state_value(key)

			if key.begins_with("research_unlocked_"):
				var node_id := key.substr("research_unlocked_".length())
				return _is_research_unlocked(node_id)
			if key.begins_with("shop_item_purchased_"):
				var item_id := key.substr("shop_item_purchased_".length())
				return _is_shop_item_purchased(item_id)
			if key == "arnulf_is_downed":
				return _arnulf_current_state == Types.ArnulfState.DOWNED
			push_warning("DialogueManager: unknown condition key '%s'" % key)
			return null


func _resolve_florence_state_value(key: String) -> Variant:
	var florence := GameManager.get_florence_data()
	if florence == null:
		return null

	match key:
		"florence.run_count":
			return florence.run_count
		"florence.total_missions_played":
			return florence.total_missions_played
		"florence.total_days_played":
			return florence.total_days_played
		"florence.boss_attempts":
			return florence.boss_attempts
		"florence.boss_victories":
			return florence.boss_victories
		"florence.mission_failures":
			return florence.mission_failures

		"florence.flags.has_unlocked_research":
			return florence.has_unlocked_research
		"florence.flags.has_unlocked_enchantments":
			return florence.has_unlocked_enchantments
		"florence.flags.has_recruited_any_mercenary":
			return florence.has_recruited_any_mercenary
		"florence.flags.has_seen_any_mini_boss":
			return florence.has_seen_any_mini_boss
		"florence.flags.has_defeated_any_mini_boss":
			return florence.has_defeated_any_mini_boss
		"florence.flags.has_reached_day_25":
			return florence.has_reached_day_25
		"florence.flags.has_reached_day_50":
			return florence.has_reached_day_50
		"florence.flags.has_seen_first_boss":
			return florence.has_seen_first_boss
		_:
			return null


func _resolve_campaign_state_value(key: String) -> Variant:
	match key:
		"campaign.current_day":
			return GameManager.current_day
		"campaign.current_mission":
			return GameManager.current_mission
		_:
			return null


func _compare(current_value: Variant, op: String, expected: Variant) -> bool:
	if current_value == null:
		return false

	match op:
		"==":
			return current_value == expected
		"!=":
			return current_value != expected
		">":
			return typeof(current_value) == TYPE_INT and int(current_value) > int(expected)
		">=":
			return typeof(current_value) == TYPE_INT and int(current_value) >= int(expected)
		"<":
			return typeof(current_value) == TYPE_INT and int(current_value) < int(expected)
		"<=":
			return typeof(current_value) == TYPE_INT and int(current_value) <= int(expected)
		_:
			push_warning("DialogueManager: unsupported comparison operator '%s'" % op)
			return false


func _sybil_research_unlocked_any() -> bool:
	var rm: ResearchManager = _get_research_manager()
	if rm == null:
		return false
	# ASSUMPTION: spell-related research nodes include substring "spell" in node_id (see PROMPT_13_IMPLEMENTATION.md).
	for node_data: ResearchNodeData in rm.research_nodes:
		if "spell" in node_data.node_id.to_lower():
			if rm.is_unlocked(node_data.node_id):
				return true
	return false


func _arnulf_research_unlocked_any() -> bool:
	var rm: ResearchManager = _get_research_manager()
	if rm == null:
		return false
	# ASSUMPTION: Arnulf-related nodes include "arnulf" in node_id (none in current tree — condition stays false until data adds one).
	for node_data: ResearchNodeData in rm.research_nodes:
		if "arnulf" in node_data.node_id.to_lower():
			if rm.is_unlocked(node_data.node_id):
				return true
	return false


func _is_research_unlocked(node_id: String) -> bool:
	if _unlocked_research_ids.has(node_id):
		return true
	var rm: ResearchManager = _get_research_manager()
	if rm == null:
		return false
	return rm.is_unlocked(node_id)


func _get_research_manager() -> ResearchManager:
	var main := get_tree().root.get_node_or_null("Main")
	if main == null:
		return null
	var managers := main.get_node_or_null("Managers")
	if managers == null:
		return null
	return managers.get_node_or_null("ResearchManager") as ResearchManager


func _is_shop_item_purchased(item_id: String) -> bool:
	return bool(_shop_purchased_item_ids.get(item_id, false))


func _on_game_state_changed(_old_state: Types.GameState, new_state: Types.GameState) -> void:
	current_gamestate = new_state


func _on_mission_started(mission_number: int) -> void:
	current_mission_number = mission_number
	_combat_kills_this_mission = 0
	_combat_wave_number = 0
	_combat_boss_seen = false
	_combat_first_blood = false
	_combat_florence_damaged = false
	_seen_combat_lines.clear()


func _on_combat_enemy_killed(_enemy_type: Types.EnemyType, _position: Vector3, _gold_reward: int) -> void:
	_combat_kills_this_mission += 1
	_combat_first_blood = true
	request_combat_line()


func _on_combat_wave_started(wave_number: int, _enemy_count: int) -> void:
	_combat_wave_number = wave_number
	request_combat_line()


func _on_combat_florence_damaged(_amount: int, _source_enemy_id: String) -> void:
	_combat_florence_damaged = true
	request_combat_line()


func _on_combat_boss_spawned(_boss_id: String) -> void:
	_combat_boss_seen = true
	request_combat_line()


func _on_mission_won(_mission_number: int) -> void:
	mission_won_count += 1


func _on_mission_failed(_mission_number: int) -> void:
	mission_failed_count += 1


func _on_resource_changed(resource_type: Types.ResourceType, _new_amount: int) -> void:
	if resource_type == Types.ResourceType.GOLD:
		_current_gold = EconomyManager.get_gold()


func _on_research_unlocked(node_id: String) -> void:
	if node_id.is_empty():
		return
	_unlocked_research_ids[node_id] = true


func _on_shop_item_purchased(item_id: String) -> void:
	_purchase_count += 1
	_last_purchased_item_id = item_id
	if not item_id.is_empty():
		_shop_purchased_item_ids[item_id] = true


func _on_arnulf_state_changed(new_state: Types.ArnulfState) -> void:
	_arnulf_current_state = new_state


func _on_spell_cast(spell_id: String) -> void:
	_spell_cast_count += 1
	_last_spell_cast_id = spell_id


## Gold snapshot updated on GOLD `resource_changed` (mirrors EconomyManager for dialogue).
func get_tracked_gold() -> int:
	return _current_gold


func get_unlocked_research_ids_snapshot() -> Dictionary:
	return _unlocked_research_ids.duplicate()


func get_total_shop_purchases_tracked() -> int:
	return _purchase_count


func get_last_shop_item_purchased_id() -> String:
	return _last_purchased_item_id


func get_arnulf_state_tracked() -> Types.ArnulfState:
	return _arnulf_current_state


func get_spell_cast_count_tracked() -> int:
	return _spell_cast_count


func get_last_spell_cast_id_tracked() -> String:
	return _last_spell_cast_id
