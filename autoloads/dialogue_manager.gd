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

var _rng := RandomNumberGenerator.new() # TUNING

## Test-only: incremented when CampaignManager starts a campaign day (non–endless mode).
var _campaign_day_started_calls_for_test: int = 0

signal dialogue_line_started(entry_id: String, character_id: String)
signal dialogue_line_finished(entry_id: String, character_id: String)


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
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	SignalBus.mission_started.connect(_on_mission_started)
	SignalBus.mission_won.connect(_on_mission_won)
	SignalBus.mission_failed.connect(_on_mission_failed)
	SignalBus.resource_changed.connect(_on_resource_changed)
	SignalBus.research_unlocked.connect(_on_research_unlocked)
	SignalBus.shop_item_purchased.connect(_on_shop_item_purchased)
	SignalBus.arnulf_state_changed.connect(_on_arnulf_state_changed)
	SignalBus.spell_cast.connect(_on_spell_cast)


## Returns the highest-priority eligible DialogueEntry for the given character and tags.
func request_entry_for_character(character_id: String, tags: Array[String] = []) -> DialogueEntry:
	if not entries_by_character.has(character_id):
		return null

	var active_chain_id: String = str(active_chains_by_character.get(character_id, ""))
	if not active_chain_id.is_empty():
		if entries_by_id.has(active_chain_id):
			var chain_entry: DialogueEntry = entries_by_id[active_chain_id] as DialogueEntry
			if not (chain_entry.once_only and played_once_only.get(chain_entry.entry_id, false)):
				if _entry_matches_tags(chain_entry, tags) and _evaluate_conditions(chain_entry):
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
		# SOURCE: Hades-style priority bucket selection (external analysis videos/articles).
		index = _rng.randi_range(0, best_candidates.size() - 1)

	var chosen: DialogueEntry = best_candidates[index]
	_emit_started(chosen)
	return chosen


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
	dialogue_line_started.emit(entry.entry_id, entry.character_id)


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
	dialogue_line_finished.emit(entry_id, character_id)
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
