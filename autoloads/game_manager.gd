## game_manager.gd
## State machine for overall game flow: missions, waves, and build mode in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.
##
## Territory + day summary:
## - CampaignConfig on CampaignManager defines DayConfig entries (mission_index, territory_id, waves, etc.).
## - CampaignManager tracks current_day; GameManager maps day to current_mission via DayConfig.mission_index.
## - TerritoryMapData lists all TerritoryData; GameManager mutates ownership flags on mission win/loss
##   and aggregates end-of-mission gold bonuses for EconomyManager.
## - MVP: player cannot choose territories; CampaignConfig fixes day→territory mapping.
##   POST-MVP: multi-front choices, boss advance after final day, factions, and research/enchant/upgrade
##   modifiers from TerritoryData hook into this layer.

extends Node

const TOTAL_MISSIONS: int = 5
# Temporary dev/testing cap so we can reach "mission won" quickly.
const WAVES_PER_MISSION: int = 3

const FlorenceDataType = preload("res://scripts/florence_data.gd")

## Optional reference path for the main 50-day campaign asset (documentation / tools).
## ASSUMPTION: Runtime loads territory map from CampaignManager.campaign_config.territory_map_resource_path.
const MAIN_CAMPAIGN_CONFIG_PATH: String = "res://resources/campaign_main_50days.tres"

var _active_allies: Array = []
var _ally_base_scene: PackedScene = preload("res://scenes/allies/ally_base.tscn")

var current_mission: int = 1
var current_wave: int = 0
## ASSUMPTION: meta campaign day index, 1-based (independent from CampaignManager.current_day).
var current_day: int = 1
var game_state: Types.GameState = Types.GameState.MAIN_MENU

## SOURCE: Roguelike meta-state Resource pattern (data-only model state).
var florence_data: FlorenceDataType = null

const INVALID_DAY_ADVANCE_REASON: int = -1
var _pending_day_advance_reason: int = INVALID_DAY_ADVANCE_REASON

## Loaded from the active campaign's territory_map_resource_path when set; otherwise null.
var territory_map: TerritoryMapData = null

# --- Final boss / post–Day-50 loop (Prompt 10) --------------------------------
var final_boss_id: String = ""
var final_boss_day_index: int = 50
var final_boss_active: bool = false
var final_boss_defeated: bool = false
var current_boss_threat_territory_id: String = ""
## ASSUMPTION: populated from TerritoryMapData or tests; used for random boss strikes.
var held_territory_ids: Array[String] = []
## Runtime-only day config when current_day exceeds CampaignConfig.day_configs (boss repeat days).
var _synthetic_boss_attack_day: DayConfig = null

func _ready() -> void:
	print("[GameManager] _ready: initial state=%s" % Types.GameState.keys()[game_state])
	SignalBus.all_waves_cleared.connect(_on_all_waves_cleared)
	SignalBus.tower_destroyed.connect(_on_tower_destroyed)
	# Autoload order: CampaignManager before GameManager — connect second so day increments first on mission_won.
	_connect_mission_won_transition_to_hub()
	var shop: Node = get_node_or_null("/root/Main/Managers/ShopManager")
	var tower: Node = get_node_or_null("/root/Main/Tower")
	if shop != null and tower != null and shop.has_method("initialize_tower"):
		shop.initialize_tower(tower)
	print("[GameManager] _ready: ShopManager wired to Tower")
	reload_territory_map_from_active_campaign()
	SignalBus.boss_killed.connect(_on_boss_killed)
	_sync_held_territories_from_map()
	if SaveManager.has_method("save_current_state"):
		if not SignalBus.mission_won.is_connected(SaveManager.save_current_state):
			SignalBus.mission_won.connect(SaveManager.save_current_state)
		if not SignalBus.mission_failed.is_connected(SaveManager.save_current_state):
			SignalBus.mission_failed.connect(SaveManager.save_current_state)


func _connect_mission_won_transition_to_hub() -> void:
	if SignalBus.mission_won.is_connected(_on_mission_won_transition_to_hub):
		return
	SignalBus.mission_won.connect(_on_mission_won_transition_to_hub)


## Runs after CampaignManager._on_mission_won (autoload order: CampaignManager before GameManager). Also used when tests emit mission_won without waves.
func _on_mission_won_transition_to_hub(mission_number: int) -> void:
	if CampaignManager.is_endless_mode:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)
		return
	var campaign_len: int = CampaignManager.get_campaign_length()
	var completed_day_index: int = mission_number
	var is_final_day: bool = campaign_len > 0 and completed_day_index == campaign_len
	var should_game_won: bool = false

	if campaign_len == 0 and mission_number >= TOTAL_MISSIONS:
		should_game_won = true
	elif is_final_day or final_boss_defeated:
		should_game_won = true

	if should_game_won:
		# ASSUMPTION: run_count increments only on full campaign completion for now.
		if florence_data != null:
			florence_data.run_count += 1
			SignalBus.florence_state_changed.emit()
		_transition_to(Types.GameState.GAME_WON)
	else:
		_transition_to(Types.GameState.BETWEEN_MISSIONS)

# ── Public API ─────────────────────────────────────────────────────────────────

## Resets all game state and starts a fresh campaign from day one.
func start_new_game() -> void:
	print("[GameManager] start_new_game: mission=1  gold=%d mat=%d" % [
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	if CampaignManager.is_endless_mode:
		game_state = Types.GameState.ENDLESS
	_cleanup_allies()
	_reset_final_boss_campaign_state()
	current_mission = 1
	current_wave = 0
	EconomyManager.reset_to_defaults()
	EnchantmentManager.reset_to_defaults()
	# Ensure research unlock state is reset for a new run.
	# In dev mode, ResearchManager can choose to unlock all nodes to make
	# content reachable for testing (e.g., tower availability).
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm != null:
		rm.reset_to_defaults()
	var weapon_upgrade_manager: Node = get_node_or_null("/root/Main/Managers/WeaponUpgradeManager")
	if weapon_upgrade_manager != null:
		weapon_upgrade_manager.reset_to_defaults()

	# Florence meta-state bootstrap.
	# ASSUMPTION: New game starts meta day index at 1.
	current_day = 1
	_pending_day_advance_reason = INVALID_DAY_ADVANCE_REASON
	if florence_data == null:
		florence_data = FlorenceDataType.new()
	florence_data.reset_for_new_run()
	florence_data.update_day_threshold_flags(current_day)
	SignalBus.florence_state_changed.emit()
	# DEVIATION: CampaignManager owns day/campaign state and mission kickoff.
	CampaignManager.start_new_campaign()
	reload_territory_map_from_active_campaign()
	_sync_held_territories_from_map()

## Delegates to CampaignManager to begin the next day in the campaign.
func start_next_mission() -> void:
	# DEVIATION: next day is now owned by CampaignManager.
	# BetweenMissionScreen routes directly through CampaignManager, this remains for compatibility.
	CampaignManager.start_next_day()

## Begins the countdown timer before the first wave spawns.
func start_wave_countdown() -> void:
	if game_state != Types.GameState.MISSION_BRIEFING:
		push_warning("start_wave_countdown called from invalid state: %s" % Types.GameState.keys()[game_state])
		return
	_transition_to(Types.GameState.COMBAT)
	SignalBus.mission_started.emit(current_mission)
	_spawn_allies_for_current_mission()
	_apply_shop_mission_start_consumables()
	# Single source of truth for countdown duration: WaveManager emits wave_countdown_started.
	_begin_mission_wave_sequence()

## Transitions the game state to BUILD_MODE, pausing enemy movement.
func enter_build_mode() -> void:
	print("[GameManager] enter_build_mode: from=%s" % Types.GameState.keys()[game_state])
	if game_state != Types.GameState.COMBAT and game_state != Types.GameState.WAVE_COUNTDOWN:
		push_warning("enter_build_mode called from invalid state: %s" % Types.GameState.keys()[game_state])
		return
	Engine.time_scale = 0.1
	var old: Types.GameState = game_state
	game_state = Types.GameState.BUILD_MODE
	SignalBus.build_mode_entered.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.BUILD_MODE)

## Transitions the game state back to COMBAT from BUILD_MODE.
func exit_build_mode() -> void:
	print("[GameManager] exit_build_mode")
	Engine.time_scale = 1.0
	var old: Types.GameState = game_state
	game_state = Types.GameState.COMBAT
	SignalBus.build_mode_exited.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.COMBAT)

## Returns the current GameState enum value.
func get_game_state() -> Types.GameState:
	return game_state

## Returns the current mission number (1-indexed).
func get_current_mission() -> int:
	return current_mission

## Returns the current wave index within the active mission.
func get_current_wave() -> int:
	return current_wave

## Returns the FlorenceData resource tracking protagonist meta-state.
func get_florence_data() -> FlorenceDataType:
	return florence_data

## Increments Florence's day counter with the given advance reason.
func advance_day(reason: Types.DayAdvanceReason) -> void:
	# SOURCE: Day/week advancement priority pattern using Types as central registry.
	var reason_priority: int = Types.get_day_advance_priority(reason)

	# ASSUMPTION: The “pending reasons” window is typically a mission resolution
	# (from win/fail events through state transitions).
	if _pending_day_advance_reason == INVALID_DAY_ADVANCE_REASON:
		_pending_day_advance_reason = int(reason)
		return

	var pending_priority: int = _get_day_advance_priority_from_int(_pending_day_advance_reason)
	if reason_priority > pending_priority:
		_pending_day_advance_reason = int(reason)


func _get_day_advance_priority_from_int(reason_id: int) -> int:
	# Godot does not allow casting enums via `Types.DayAdvanceReason(reason_id)` syntax.
	# We map the stored int back to the enum values via match.
	match reason_id:
		int(Types.DayAdvanceReason.MISSION_COMPLETED):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.MISSION_COMPLETED)
		int(Types.DayAdvanceReason.ACHIEVEMENT_EARNED):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.ACHIEVEMENT_EARNED)
		int(Types.DayAdvanceReason.MAJOR_STORY_EVENT):
			return Types.get_day_advance_priority(Types.DayAdvanceReason.MAJOR_STORY_EVENT)
		_:
			return 0


func _apply_pending_day_advance_if_any() -> void:
	if _pending_day_advance_reason == INVALID_DAY_ADVANCE_REASON:
		return

	current_day += 1
	if florence_data != null:
		florence_data.total_days_played += 1
		florence_data.update_day_threshold_flags(current_day)

	SignalBus.florence_state_changed.emit()
	_pending_day_advance_reason = INVALID_DAY_ADVANCE_REASON

## Linear day index within the active campaign (1-based). Delegates to CampaignManager.
func get_current_day_index() -> int:
	return CampaignManager.get_current_day()


## Alias for tests / Prompt 10 (syncs with CampaignManager.current_day).
var current_day_index: int:
	get:
		return CampaignManager.get_current_day()
	set(value):
		CampaignManager.current_day = value


## Campaign timeline resource (same as CampaignManager.campaign_config).
var campaign_config: CampaignConfig:
	get:
		return CampaignManager.campaign_config
	set(value):
		CampaignManager.set_active_campaign_config_for_test(value)


## Returns the DayConfig for the given day index from the active campaign.
func get_day_config_for_index(day_index: int) -> DayConfig:
	if CampaignManager.is_endless_mode:
		return _create_synthetic_endless_day_config(day_index)
	var cfg: CampaignConfig = CampaignManager.campaign_config
	if cfg == null:
		return null
	for d: DayConfig in cfg.day_configs:
		if d != null and d.day_index == day_index:
			return d
	if day_index >= 1 and day_index <= cfg.day_configs.size():
		return cfg.day_configs[day_index - 1]
	if _synthetic_boss_attack_day != null and _synthetic_boss_attack_day.day_index == day_index:
		return _synthetic_boss_attack_day
	return null


func _create_synthetic_endless_day_config(day_index: int) -> DayConfig:
	var d: DayConfig = DayConfig.new()
	d.day_index = day_index
	d.mission_index = mini(day_index, TOTAL_MISSIONS)
	d.display_name = "Endless"
	d.faction_id = "DEFAULT_MIXED"
	d.base_wave_count = WAVES_PER_MISSION
	d.enemy_hp_multiplier = WaveManager.get_effective_enemy_hp_multiplier_for_day(day_index)
	d.enemy_damage_multiplier = d.enemy_hp_multiplier
	d.gold_reward_multiplier = 1.0
	d.spawn_count_multiplier = WaveManager.get_effective_spawn_count_multiplier_for_day(day_index)
	return d


## Returns a synthetic DayConfig for a boss-attack day.
func get_synthetic_boss_day_config() -> DayConfig:
	return _synthetic_boss_attack_day


## Advances calendar by one day; after a failed final boss, assigns a random threatened territory.
func advance_to_next_day() -> void:
	CampaignManager.current_day += 1
	var day: DayConfig = get_day_config_for_index(CampaignManager.current_day)
	if final_boss_active and not final_boss_defeated:
		if day == null:
			day = _ensure_synthetic_boss_attack_day_config()
		_assign_boss_attack_to_day(day)


## Returns the DayConfig for the currently active day.
func get_current_day_config() -> DayConfig:
	return CampaignManager.get_current_day_config()


## Returns the territory_id for the current day's mission.
func get_current_day_territory_id() -> String:
	var day_config: DayConfig = get_current_day_config()
	if day_config == null:
		return ""
	return day_config.territory_id


## Returns the TerritoryData resource for the given territory_id.
func get_territory_data(territory_id: String) -> TerritoryData:
	if territory_map == null:
		return null
	return territory_map.get_territory_by_id(territory_id)


## Returns the TerritoryData for the territory of the current day.
func get_current_day_territory() -> TerritoryData:
	var id: String = get_current_day_territory_id()
	if id == "":
		return null
	return get_territory_data(id)


## Returns all TerritoryData entries in this map.
func get_all_territories() -> Array[TerritoryData]:
	if territory_map == null:
		return []
	return territory_map.get_all_territories()


## Reloads TerritoryMapData from CampaignManager.campaign_config.territory_map_resource_path.
func reload_territory_map_from_active_campaign() -> void:
	territory_map = null
	var cfg: CampaignConfig = CampaignManager.campaign_config
	if cfg == null:
		return
	if cfg.territory_map_resource_path == "":
		return
	var res: Resource = load(cfg.territory_map_resource_path)
	if res == null:
		push_error(
			"GameManager: Failed to load TerritoryMapData from %s"
			% cfg.territory_map_resource_path
		)
		return
	territory_map = res as TerritoryMapData
	if territory_map == null:
		push_error(
			"GameManager: Resource at %s is not a TerritoryMapData"
			% cfg.territory_map_resource_path
		)
		return
	territory_map.invalidate_cache()
	SignalBus.world_map_updated.emit()
	_sync_held_territories_from_map()


## Updates territory ownership and threat flags based on the day win/loss result.
func apply_day_result_to_territory(day_config: DayConfig, was_won: bool) -> void:
	if territory_map == null or day_config == null:
		return
	if day_config.territory_id == "":
		return

	var territory: TerritoryData = territory_map.get_territory_by_id(day_config.territory_id)
	if territory == null:
		push_error(
			"GameManager: DayConfig references unknown territory_id '%s'."
			% day_config.territory_id
		)
		return

	# Prompt 10 MVP: failing a final boss encounter does not permanently conquer territory.
	if (
			not was_won
			and day_config.boss_id != ""
			and (day_config.is_final_boss or day_config.is_boss_attack_day)
	):
		return

	if was_won:
		territory.is_controlled_by_player = true
		# TUNING: MVP does not change is_permanently_lost on win; future campaigns
		# may allow recovery clearing this flag.
	else:
		territory.is_controlled_by_player = false
		territory.is_permanently_lost = true

	SignalBus.territory_state_changed.emit(territory.territory_id)
	SignalBus.world_map_updated.emit()


## Aggregates end-of-mission gold modifiers from all controlled territories.
## Keys: flat_gold_end_of_day (int), percent_gold_end_of_day (float additive fractions).
func get_current_territory_gold_modifiers() -> Dictionary:
	var result: Dictionary = {
		"flat_gold_end_of_day": 0,
		"percent_gold_end_of_day": 0.0,
	}
	if territory_map == null:
		return result

	for t: TerritoryData in territory_map.get_all_territories():
		if t == null:
			continue
		if not t.is_active_for_bonuses():
			continue
		result["flat_gold_end_of_day"] += t.get_effective_end_of_day_gold_flat()
		result["percent_gold_end_of_day"] += t.get_effective_end_of_day_gold_percent()
	return result


## Sum of bonus_flat_gold_per_kill from all territories that pass is_active_for_bonuses().
func get_aggregate_flat_gold_per_kill() -> int:
	var s: int = 0
	if territory_map == null:
		return 0
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		s += t.bonus_flat_gold_per_kill
	return s


## Product of bonus_research_cost_multiplier across active territories (empty map = 1.0).
func get_aggregate_research_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_research_cost_multiplier > 0.0:
			p *= t.bonus_research_cost_multiplier
	return p


## Returns the aggregated enchanting cost multiplier from all held territories.
func get_aggregate_enchanting_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_enchanting_cost_multiplier > 0.0:
			p *= t.bonus_enchanting_cost_multiplier
	return p


## Returns the aggregated weapon upgrade cost multiplier from all held territories.
func get_aggregate_weapon_upgrade_cost_multiplier() -> float:
	var p: float = 1.0
	if territory_map == null:
		return p
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		if t.bonus_weapon_upgrade_cost_multiplier > 0.0:
			p *= t.bonus_weapon_upgrade_cost_multiplier
	return p


## Extra research material granted at end of a successful mission wave clear (not per-kill).
func get_aggregate_bonus_research_per_day() -> int:
	var s: int = 0
	if territory_map == null:
		return 0
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null or not t.is_active_for_bonuses():
			continue
		s += t.bonus_research_per_day
	return s


## When DayConfig.faction_id is empty, use territory default_faction_id.
func get_effective_faction_id_for_territory(territory_id: String) -> String:
	if territory_id.strip_edges() == "" or territory_map == null:
		return ""
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return ""
	return t.default_faction_id.strip_edges()


## Initializes the mission for the given day index and DayConfig, then begins combat.
func start_mission_for_day(day_index: int, day_config: DayConfig) -> void:
	var mission_from_config: int = day_index
	if day_config != null:
		mission_from_config = day_config.mission_index
	current_mission = clampi(mission_from_config, 1, TOTAL_MISSIONS)
	current_wave = 0

	_transition_to(Types.GameState.COMBAT)
	SignalBus.mission_started.emit(current_mission)
	_spawn_allies_for_current_mission()
	_apply_shop_mission_start_consumables()
	_begin_mission_wave_sequence()

# ── Private helpers ────────────────────────────────────────────────────────────

func _apply_shop_mission_start_consumables() -> void:
	var shop: ShopManager = get_node_or_null("/root/Main/Managers/ShopManager") as ShopManager
	if shop == null:
		return
	shop.apply_mission_start_consumables()


func _spawn_allies_for_current_mission() -> void:
	var main: Node = get_node_or_null("/root/Main")
	if main == null:
		push_warning(
			"GameManager: Main scene not found at /root/Main; skipping ally spawn (mission %d)."
			% current_mission
		)
		return

	var ally_container: Node3D = main.get_node_or_null("AllyContainer") as Node3D
	var spawn_points_root: Node3D = main.get_node_or_null("AllySpawnPoints") as Node3D
	if ally_container == null or spawn_points_root == null:
		push_warning(
			"GameManager: AllyContainer or AllySpawnPoints missing under Main; skipping ally spawn (mission %d)."
			% current_mission
		)
		return

	_cleanup_allies()

	var ally_datas: Array = CampaignManager.current_ally_roster
	var spawn_points: Array[Node3D] = []
	for child: Node in spawn_points_root.get_children():
		if child is Node3D:
			spawn_points.append(child as Node3D)

	if ally_datas.is_empty() or spawn_points.is_empty():
		return

	var index: int = 0
	for data: Variant in ally_datas:
		if data == null:
			continue
		var ally: Node = _ally_base_scene.instantiate()
		if ally == null:
			continue

		ally_container.add_child(ally)
		var spawn_point: Node3D = spawn_points[index % spawn_points.size()] as Node3D
		ally.global_position = spawn_point.global_position

		if ally.has_method("initialize_ally_data"):
			ally.call("initialize_ally_data", data)
		_active_allies.append(ally)

		index += 1


func _cleanup_allies() -> void:
	for ally: Variant in _active_allies:
		if ally != null and is_instance_valid(ally):
			(ally as Node).queue_free()
	_active_allies.clear()


func _begin_mission_wave_sequence() -> void:
	var main: Node = get_tree().root.get_node_or_null("Main")
	if main == null:
		push_warning(
			"GameManager: Main scene not found at /root/Main; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	var managers: Node = main.get_node_or_null("Managers")
	if managers == null:
		push_warning(
			"GameManager: Managers node not found at /root/Main/Managers; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	var wave_manager: WaveManager = managers.get_node_or_null("WaveManager") as WaveManager
	if wave_manager == null:
		push_warning(
			"GameManager: WaveManager not found at /root/Main/Managers/WaveManager; skipping wave sequence (mission %d)."
			% current_mission
		)
		return
	print("[GameManager] _begin_mission_wave_sequence: mission=%d" % current_mission)
	wave_manager.ensure_boss_registry_loaded()
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	_update_final_boss_tracking_from_day(day_cfg)
	wave_manager.reset_for_new_mission()
	# Apply day config after reset — reset clears per-day tuning (waves, faction, multipliers).
	wave_manager.configure_for_day(day_cfg)
	wave_manager.call_deferred("start_wave_sequence")

func _transition_to(new_state: Types.GameState) -> void:
	var resolved: Types.GameState = new_state
	if new_state == Types.GameState.BETWEEN_MISSIONS and CampaignManager.is_endless_mode:
		resolved = Types.GameState.ENDLESS
	if game_state == resolved:
		return
	var old_name: String = Types.GameState.keys()[game_state]
	var new_name: String = Types.GameState.keys()[resolved]
	print("[GameManager] state: %s → %s" % [old_name, new_name])
	var old: Types.GameState = game_state
	game_state = resolved
	SignalBus.game_state_changed.emit(old, resolved)

func _on_all_waves_cleared() -> void:
	_cleanup_allies()
	print("[GameManager] all_waves_cleared: awarding mission=%d resources" % current_mission)
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	apply_day_result_to_territory(day_cfg, true)

	var base_gold_reward: int = 50 * current_mission
	var modifiers: Dictionary = get_current_territory_gold_modifiers()
	var flat_bonus: int = int(modifiers.get("flat_gold_end_of_day", 0))
	var percent_bonus: float = float(modifiers.get("percent_gold_end_of_day", 0.0))
	var total_gold: int = base_gold_reward + flat_bonus
	if percent_bonus != 0.0:
		total_gold = int(round(float(total_gold) * (1.0 + percent_bonus)))

	EconomyManager.add_gold(total_gold)
	EconomyManager.add_building_material(3)
	var extra_rm: int = get_aggregate_bonus_research_per_day()
	EconomyManager.add_research_material(2 + extra_rm)
	# Snapshot before mission_won: CampaignManager may increment current_day on mission_won.
	var completed_day_index: int = CampaignManager.get_current_day()

	if (
			day_cfg != null
			and day_cfg.boss_id != ""
			and (day_cfg.is_final_boss or day_cfg.is_boss_attack_day)
	):
		final_boss_id = day_cfg.boss_id
		final_boss_defeated = true
		final_boss_active = false
		_synthetic_boss_attack_day = null
		SignalBus.campaign_boss_attempted.emit(completed_day_index, true)

	# Florence meta-state updates (run meta-progression).
	if florence_data != null and not CampaignManager.is_endless_mode:
		florence_data.total_missions_played += 1
		advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
		_apply_pending_day_advance_if_any()

	SignalBus.mission_won.emit(CampaignManager.get_current_day())

func _on_tower_destroyed() -> void:
	_cleanup_allies()
	print("[GameManager] tower_destroyed → MISSION_FAILED")
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	var completed_day_index: int = CampaignManager.get_current_day()

	# Florence meta-state updates (counts mission attempts).
	if florence_data != null and not CampaignManager.is_endless_mode:
		florence_data.total_missions_played += 1
		florence_data.mission_failures += 1
		advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
		_apply_pending_day_advance_if_any()
	if (
			day_cfg != null
			and day_cfg.boss_id != ""
			and (day_cfg.is_final_boss or day_cfg.is_boss_attack_day)
			and not final_boss_defeated
	):
		final_boss_id = day_cfg.boss_id
		final_boss_active = true
		SignalBus.campaign_boss_attempted.emit(completed_day_index, false)
	else:
		apply_day_result_to_territory(day_cfg, false)
	_transition_to(Types.GameState.MISSION_FAILED)
	# Snapshot from entry — advance_day above may have incremented CampaignManager.current_day.
	SignalBus.mission_failed.emit(completed_day_index)


## Pre-loads the next day's DayConfig into WaveManager if not already prepared.
func prepare_next_campaign_day_if_needed() -> void:
	if not final_boss_active or final_boss_defeated:
		return
	advance_to_next_day()


## TEST-ONLY: resets Prompt 10 boss campaign fields without starting a new game.
func reset_boss_campaign_state_for_test() -> void:
	_reset_final_boss_campaign_state()


func _reset_final_boss_campaign_state() -> void:
	final_boss_id = ""
	final_boss_day_index = 50
	final_boss_active = false
	final_boss_defeated = false
	current_boss_threat_territory_id = ""
	held_territory_ids.clear()
	_synthetic_boss_attack_day = null


func _sync_held_territories_from_map() -> void:
	held_territory_ids.clear()
	if territory_map == null:
		return
	for t: TerritoryData in territory_map.get_all_territories():
		if t != null and t.is_controlled_by_player:
			held_territory_ids.append(t.territory_id)


func _update_final_boss_tracking_from_day(day_cfg: DayConfig) -> void:
	if day_cfg == null:
		return
	if day_cfg.boss_id != "":
		final_boss_id = day_cfg.boss_id
	if day_cfg.is_final_boss:
		final_boss_day_index = day_cfg.day_index


func _ensure_synthetic_boss_attack_day_config() -> DayConfig:
	var syn: DayConfig = DayConfig.new()
	syn.day_index = CampaignManager.current_day
	syn.mission_index = 5
	syn.display_name = "Boss strike"
	syn.description = "PLACEHOLDER: The campaign boss strikes again."
	syn.faction_id = "PLAGUE_CULT"
	syn.base_wave_count = 10
	syn.enemy_hp_multiplier = 1.0
	syn.enemy_damage_multiplier = 1.0
	syn.gold_reward_multiplier = 1.0
	syn.is_mini_boss_day = false
	syn.is_mini_boss = false
	syn.is_final_boss = true
	syn.is_boss_attack_day = true
	syn.boss_id = final_boss_id
	_synthetic_boss_attack_day = syn
	return syn


func _assign_boss_attack_to_day(day_config: DayConfig) -> void:
	if day_config == null:
		return
	if held_territory_ids.is_empty():
		_sync_held_territories_from_map()
	if held_territory_ids.is_empty():
		return
	var idx: int = randi() % held_territory_ids.size()
	current_boss_threat_territory_id = held_territory_ids[idx]
	day_config.territory_id = current_boss_threat_territory_id
	day_config.is_boss_attack_day = true
	day_config.is_final_boss = true
	day_config.boss_id = final_boss_id
	_mark_territory_boss_threat(current_boss_threat_territory_id, true)


func _mark_territory_boss_threat(territory_id: String, threatened: bool) -> void:
	if territory_map == null or territory_id == "":
		return
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return
	t.has_boss_threat = threatened
	SignalBus.territory_state_changed.emit(territory_id)


func _on_boss_killed(boss_id: String) -> void:
	CampaignManager.notify_mini_boss_defeated(boss_id)
	var data: BossData = _get_boss_data(boss_id)
	if data != null and data.is_mini_boss and data.associated_territory_id != "":
		_mark_territory_secured(data.associated_territory_id)


func _get_boss_data(boss_id: String) -> BossData:
	for path: String in BossData.BUILTIN_BOSS_RESOURCE_PATHS:
		var res: Resource = load(path)
		if res is BossData:
			var b: BossData = res as BossData
			if b.boss_id == boss_id:
				return b
	return null


func _mark_territory_secured(territory_id: String) -> void:
	if territory_map == null or territory_id == "":
		return
	var t: TerritoryData = territory_map.get_territory_by_id(territory_id)
	if t == null:
		return
	t.is_secured = true
	t.has_boss_threat = false
	SignalBus.territory_state_changed.emit(territory_id)


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	var mana: int = 0
	if spell != null:
		mana = spell.get_current_mana()
	var florence_dict: Dictionary = {}
	if florence_data != null:
		florence_dict = {
			"total_days_played": florence_data.total_days_played,
			"run_count": florence_data.run_count,
			"total_missions_played": florence_data.total_missions_played,
			"boss_attempts": florence_data.boss_attempts,
			"boss_victories": florence_data.boss_victories,
			"mission_failures": florence_data.mission_failures,
			"has_unlocked_research": florence_data.has_unlocked_research,
			"has_unlocked_enchantments": florence_data.has_unlocked_enchantments,
			"has_recruited_any_mercenary": florence_data.has_recruited_any_mercenary,
			"has_seen_any_mini_boss": florence_data.has_seen_any_mini_boss,
			"has_defeated_any_mini_boss": florence_data.has_defeated_any_mini_boss,
			"has_reached_day_25": florence_data.has_reached_day_25,
			"has_reached_day_50": florence_data.has_reached_day_50,
			"has_seen_first_boss": florence_data.has_seen_first_boss,
		}
	return {
		"game_state": int(game_state),
		"final_boss_defeated": final_boss_defeated,
		"current_gold": EconomyManager.get_gold(),
		"current_building_material": EconomyManager.get_building_material(),
		"current_research_material": EconomyManager.get_research_material(),
		"current_mana": mana,
		"current_mission": current_mission,
		"current_wave": current_wave,
		"current_day": CampaignManager.get_current_day(),
		"florence_data": florence_dict,
		"final_boss_id": final_boss_id,
		"final_boss_day_index": final_boss_day_index,
		"final_boss_active": final_boss_active,
		"current_boss_threat_territory_id": current_boss_threat_territory_id,
	}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	var gs: int = int(data.get("game_state", int(Types.GameState.MAIN_MENU)))
	game_state = gs as Types.GameState
	final_boss_defeated = bool(data.get("final_boss_defeated", false))
	current_mission = int(data.get("current_mission", 1))
	current_wave = int(data.get("current_wave", 0))
	current_day = int(data.get("current_day", 1))
	final_boss_id = str(data.get("final_boss_id", ""))
	final_boss_day_index = int(data.get("final_boss_day_index", 50))
	final_boss_active = bool(data.get("final_boss_active", false))
	current_boss_threat_territory_id = str(data.get("current_boss_threat_territory_id", ""))
	EconomyManager.apply_save_snapshot(
		int(data.get("current_gold", EconomyManager.get_gold())),
		int(data.get("current_building_material", EconomyManager.get_building_material())),
		int(data.get("current_research_material", EconomyManager.get_research_material()))
	)
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	if spell != null:
		spell.set_mana_for_save_restore(int(data.get("current_mana", 0)))
	if florence_data == null:
		florence_data = FlorenceDataType.new()
	var fd: Variant = data.get("florence_data", {})
	if fd is Dictionary:
		var fdd: Dictionary = fd as Dictionary
		florence_data.total_days_played = int(fdd.get("total_days_played", florence_data.total_days_played))
		florence_data.run_count = int(fdd.get("run_count", florence_data.run_count))
		florence_data.total_missions_played = int(fdd.get("total_missions_played", florence_data.total_missions_played))
		florence_data.boss_attempts = int(fdd.get("boss_attempts", florence_data.boss_attempts))
		florence_data.boss_victories = int(fdd.get("boss_victories", florence_data.boss_victories))
		florence_data.mission_failures = int(fdd.get("mission_failures", florence_data.mission_failures))
		florence_data.has_unlocked_research = bool(fdd.get("has_unlocked_research", florence_data.has_unlocked_research))
		florence_data.has_unlocked_enchantments = bool(fdd.get("has_unlocked_enchantments", florence_data.has_unlocked_enchantments))
		florence_data.has_recruited_any_mercenary = bool(fdd.get("has_recruited_any_mercenary", florence_data.has_recruited_any_mercenary))
		florence_data.has_seen_any_mini_boss = bool(fdd.get("has_seen_any_mini_boss", florence_data.has_seen_any_mini_boss))
		florence_data.has_defeated_any_mini_boss = bool(fdd.get("has_defeated_any_mini_boss", florence_data.has_defeated_any_mini_boss))
		florence_data.has_reached_day_25 = bool(fdd.get("has_reached_day_25", florence_data.has_reached_day_25))
		florence_data.has_reached_day_50 = bool(fdd.get("has_reached_day_50", florence_data.has_reached_day_50))
		florence_data.has_seen_first_boss = bool(fdd.get("has_seen_first_boss", florence_data.has_seen_first_boss))
		florence_data.update_day_threshold_flags(current_day)
	SignalBus.florence_state_changed.emit()


## Restores the set of held territory IDs from a saved snapshot.
func apply_save_held_territory_ids(ids: Array[String]) -> void:
	held_territory_ids = ids.duplicate()
	if territory_map == null:
		return
	for t: TerritoryData in territory_map.get_all_territories():
		if t == null:
			continue
		t.is_controlled_by_player = held_territory_ids.has(t.territory_id)
	SignalBus.world_map_updated.emit()
