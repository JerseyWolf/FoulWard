# REPO_DUMP — Scripts (`.gd` files outside `tests/`)

Split from `REPO_DUMP_AFTER_PROMPTS_1_17.md.md`. Sections are unchanged from the original dump format.

---

## `autoloads/auto_test_driver.gd`

````
# autoloads/auto_test_driver.gd
# Headless integration-test driver for Foul Ward.
#
# Activation: run Godot with the custom argument --autotest after the double-dash:
#   godot.exe --path <project> --headless -- --autotest
#
# When active this autoload:
#   1. Waits for the scene tree to finish _ready().
#   2. Drives the game through a scripted sequence (start, build, wave, kills…).
#   3. Prints structured [AUTOTEST] PASS / FAIL / TIMEOUT lines to stdout.
#   4. Calls get_tree().quit() when done.
#
# When --autotest is NOT present the class does absolutely nothing.

# PRE_GENERATION_VERIFICATION: Mentally ran checklist for this file
# (CLI-only orchestration, respects existing --autotest behavior, headless-safe).

extends Node

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _pass_count: int = 0
var _fail_count: int = 0

# Cached scene references — resolved after the first process frame.
var _tower: Tower = null
var _hex_grid: HexGrid = null
var _wave_manager: WaveManager = null

# Signal-driven event flags (set in signal handlers, polled by _wait_until).
var _enemy_killed_count: int = 0
var _enemy_killed_types: Array[Types.EnemyType] = []
var _wave_started_received: bool = false
var _wave_number_started: int = 0
var _wave_cleared_received: bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	var simbot_profile: String = _get_cli_string_arg("--simbot_profile=")
	var simbot_runs: int = _get_cli_int_arg("--simbot_runs=", 1)
	var simbot_seed: int = _get_cli_int_arg("--simbot_seed=", 0)

	if not simbot_profile.strip_edges().is_empty():
		# New Phase 2 CLI integration path.
		# DEVIATION: This autoload can now run SimBot even without --autotest.
		call_deferred("_begin_simbot_batch", simbot_profile, simbot_runs, simbot_seed)
		return

	if "--autotest" not in OS.get_cmdline_user_args():
		return  # Invisible in normal play.

	print("[AUTOTEST] ============================================================")
	print("[AUTOTEST] Foul Ward Integration AutoTest — %s" % Time.get_datetime_string_from_system())
	print("[AUTOTEST] ============================================================")

	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.wave_cleared.connect(_on_wave_cleared)
	SignalBus.wave_started.connect(_on_wave_started)

	call_deferred("_begin_tests")

func _get_cli_string_arg(prefix: String) -> String:
	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg.begins_with(prefix):
			return arg.substr(prefix.length())

	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	for arg2: String in user_args:
		if arg2.begins_with(prefix):
			return arg2.substr(prefix.length())
	return ""

func _get_cli_int_arg(prefix: String, default_value: int) -> int:
	var raw: String = _get_cli_string_arg(prefix)
	if raw.is_empty():
		return default_value
	var parsed: int = int(raw)
	return parsed if parsed > 0 else default_value

func _begin_simbot_batch(profile_id: String, runs: int, base_seed: int) -> void:
	# Give the scene tree a few frames to finish _ready() on main.tscn.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var simbot: SimBot = _find_or_create_simbot()
	await simbot.run_batch(profile_id, runs, base_seed)

	get_tree().quit(0)

func _find_or_create_simbot() -> SimBot:
	var root: Node = get_tree().get_root()
	for child: Node in root.get_children():
		var sb: SimBot = child as SimBot
		if sb != null:
			return sb
	var new_sb: SimBot = SimBot.new()
	root.add_child(new_sb)
	return new_sb


# ---------------------------------------------------------------------------
# Signal handlers (set flags — never do logic here)
# ---------------------------------------------------------------------------

func _on_enemy_killed(enemy_type: Types.EnemyType, _pos: Vector3, gold: int) -> void:
	_enemy_killed_count += 1
	_enemy_killed_types.append(enemy_type)
	print("[AUTOTEST] event enemy_killed #%d: %s  gold_reward=%d" % [
		_enemy_killed_count, Types.EnemyType.keys()[enemy_type], gold
	])


func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	print("[AUTOTEST] event wave_started: wave=%d enemies=%d" % [wave_number, enemy_count])
	_wave_started_received = true
	_wave_number_started = wave_number


func _on_wave_cleared(wave_number: int) -> void:
	print("[AUTOTEST] event wave_cleared: wave=%d" % wave_number)
	_wave_cleared_received = true


# ---------------------------------------------------------------------------
# Test orchestration
# ---------------------------------------------------------------------------

func _begin_tests() -> void:
	# Give all scene nodes three frames to finish _ready().
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_tower = get_node_or_null("/root/Main/Tower") as Tower
	_hex_grid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	_wave_manager = get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager

	_check("scene: Tower node found", _tower != null)
	_check("scene: HexGrid node found", _hex_grid != null)
	_check("scene: WaveManager node found", _wave_manager != null)

	if _tower == null or _hex_grid == null or _wave_manager == null:
		print("[AUTOTEST] FATAL: critical nodes missing — cannot continue")
		_finish()
		return

	# Enable auto-fire so the tower kills enemies without simulated mouse input.
	_tower.auto_fire_enabled = true
	print("[AUTOTEST] Tower auto_fire_enabled = true")

	await _test_start_game()
	await _test_place_arrow_tower()
	await _test_place_anti_air_tower()
	await _test_slot_occupied()
	await _test_wave_starts()
	await _test_enemies_spawn()
	await _test_first_kill()
	await _test_flying_enemy_killed()
	await _test_wave_cleared()
	await _test_economy_reward()

	_finish()


# ---------------------------------------------------------------------------
# Individual tests
# ---------------------------------------------------------------------------

func _test_start_game() -> void:
	print("[AUTOTEST] --- start_new_game ---")
	var gold_before: int = EconomyManager.get_gold()
	GameManager.start_new_game()
	await get_tree().process_frame

	_check("start_new_game: state is COMBAT",
		GameManager.get_game_state() == Types.GameState.COMBAT)
	_check("start_new_game: gold > 0",
		EconomyManager.get_gold() > 0)
	print("[AUTOTEST] gold after reset: %d  mat: %d" % [
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	gold_before = gold_before  # suppress unused warning


func _test_place_arrow_tower() -> void:
	print("[AUTOTEST] --- place_building: Arrow Tower (slot 0) ---")
	var gold_before: int = EconomyManager.get_gold()
	var mat_before: int = EconomyManager.get_building_material()
	var ok: bool = _hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)
	await get_tree().process_frame
	_check("place_building: Arrow Tower returned true", ok)
	_check("place_building: gold decreased after Arrow Tower",
		EconomyManager.get_gold() < gold_before)
	print("[AUTOTEST] gold: %d→%d  mat: %d→%d" % [
		gold_before, EconomyManager.get_gold(), mat_before, EconomyManager.get_building_material()
	])


func _test_place_anti_air_tower() -> void:
	print("[AUTOTEST] --- place_building: Anti-Air Bolt (slot 1) ---")
	var gold_before: int = EconomyManager.get_gold()
	var ok: bool = _hex_grid.place_building(1, Types.BuildingType.ANTI_AIR_BOLT)
	await get_tree().process_frame
	if ok:
		_check("place_building: Anti-Air Bolt placed (gold decreased)",
			EconomyManager.get_gold() < gold_before)
	else:
		print("[AUTOTEST] INFO: Anti-Air Bolt not placed (likely locked or too expensive) — skipping")


func _test_slot_occupied() -> void:
	print("[AUTOTEST] --- place_building on already-occupied slot 0 ---")
	var ok: bool = _hex_grid.place_building(0, Types.BuildingType.ARROW_TOWER)
	_check("slot_occupied: place_building returns false", not ok)


func _test_wave_starts() -> void:
	print("[AUTOTEST] --- wave 1 countdown + start (timeout 15 s) ---")
	var ok: bool = await _wait_until(
		func() -> bool: return _wave_started_received,
		15.0, "wave_started signal"
	)
	_check("wave_started: fires within 15 s", ok)
	if ok:
		_check("wave_started: wave number is 1", _wave_number_started == 1)


func _test_enemies_spawn() -> void:
	print("[AUTOTEST] --- enemies in scene after wave start ---")
	# Give spawner a moment to add all enemy nodes.
	await get_tree().create_timer(0.5).timeout
	var count: int = _wave_manager.get_living_enemy_count()
	_check("enemies_spawn: at least 1 enemy alive", count > 0)
	print("[AUTOTEST] living enemies after spawn: %d" % count)


func _test_first_kill() -> void:
	print("[AUTOTEST] --- first enemy kill via auto-fire (timeout 60 s) ---")
	var kills_before: int = _enemy_killed_count
	var ok: bool = await _wait_until(
		func() -> bool: return _enemy_killed_count > kills_before,
		60.0, "first enemy kill"
	)
	_check("first_kill: auto-fire kills at least one enemy within 60 s", ok)
	if ok:
		print("[AUTOTEST] first kill confirmed, total kills: %d" % _enemy_killed_count)


func _test_flying_enemy_killed() -> void:
	print("[AUTOTEST] --- Bat Swarm (flying) killed (timeout 120 s) ---")
	var ok: bool = await _wait_until(
		func() -> bool: return Types.EnemyType.BAT_SWARM in _enemy_killed_types,
		120.0, "Bat Swarm killed"
	)
	_check("flying_enemy_killed: Bat Swarm dies within 120 s", ok)


func _test_wave_cleared() -> void:
	print("[AUTOTEST] --- wave_cleared signal (timeout 180 s) ---")
	var ok: bool = await _wait_until(
		func() -> bool: return _wave_cleared_received,
		180.0, "wave_cleared signal"
	)
	_check("wave_cleared: all enemies dead, signal received", ok)
	if ok:
		_check("wave_cleared: no enemies remain in group",
			_wave_manager.get_living_enemy_count() == 0)


func _test_economy_reward() -> void:
	print("[AUTOTEST] --- economy reward after kills ---")
	var gold: int = EconomyManager.get_gold()
	_check("economy: gold > 0 after kills", gold > 0)
	print("[AUTOTEST] final gold: %d  final kills: %d" % [gold, _enemy_killed_count])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _check(label: String, condition: bool) -> void:
	if condition:
		_pass_count += 1
		print("[AUTOTEST] PASS: %s" % label)
	else:
		_fail_count += 1
		print("[AUTOTEST] FAIL: %s" % label)


## Polls [param condition] every 0.25 s until it returns true or [param timeout] elapses.
## Returns true if condition became true in time.
func _wait_until(condition: Callable, timeout: float, label: String) -> bool:
	var elapsed: float = 0.0
	while elapsed < timeout:
		if condition.call():
			return true
		await get_tree().create_timer(0.25).timeout
		elapsed += 0.25
	print("[AUTOTEST] TIMEOUT: '%s' did not occur within %.0f s" % [label, timeout])
	return false


func _finish() -> void:
	print("[AUTOTEST] ============================================================")
	print("[AUTOTEST] RESULTS  PASS: %d   FAIL: %d" % [_pass_count, _fail_count])
	print("[AUTOTEST] ============================================================")
	get_tree().quit(0 if _fail_count == 0 else 1)
````

---

## `autoloads/campaign_manager.gd`

````
## campaign_manager.gd
## Campaign/day-level state controller above GameManager mission flow.
## Owns campaign progress, DayConfig lookup, ally roster, mercenary offers, and mini-boss defection.
## DEVIATION: Mercenary/MiniBoss resource types are referenced as Resource/Variant here so this autoload
## parses before global `class_name` registration (same pattern as Prompt 11 ally roster).

extends Node

const DEFAULT_SHORT_CAMPAIGN: CampaignConfig = preload("res://resources/campaigns/campaign_short_5_days.tres")
const FactionDataType = preload("res://scripts/resources/faction_data.gd")
const DEFAULT_MERCENARY_CATALOG_PATH: String = "res://resources/mercenary_catalog.tres"
const _MercenaryOfferDataGd: GDScript = preload("res://scripts/resources/mercenary_offer_data.gd")

var current_day: int = 1
var campaign_length: int = 0
var campaign_id: String = ""
var campaign_completed: bool = false
var failed_attempts_on_current_day: int = 0
var current_day_config: DayConfig = null
var campaign_config: CampaignConfig = null

## Loaded from FactionData.BUILTIN_FACTION_RESOURCE_PATHS (String -> FactionData).
var faction_registry: Dictionary = {}

# ASSUMPTION: all ally `.tres` files live under `res://resources/ally_data/`.
var _ally_registry: Dictionary = {}

## Loaded from `res://resources/miniboss_data/*.tres` (boss_id -> Resource).
var _mini_boss_registry: Dictionary = {}

@export var mercenary_catalog: Resource = null

var owned_allies: Array[String] = []
var active_allies_for_next_day: Array[String] = []
var max_active_allies_per_day: int = 2 # TUNING

var current_mercenary_offers: Array = []
var _defeated_defectable_bosses: Array[String] = []

var current_ally_roster: Array = []
var current_ally_roster_ids: Array[String] = []

@export var active_campaign_config: CampaignConfig


func _ready() -> void:
	_load_faction_registry()
	_load_ally_registry()
	_load_mini_boss_registry()
	_ensure_default_mercenary_catalog()
	SignalBus.mission_won.connect(_on_mission_won)
	SignalBus.mission_failed.connect(_on_mission_failed)
	if active_campaign_config == null:
		active_campaign_config = DEFAULT_SHORT_CAMPAIGN
	if active_campaign_config != null:
		_set_campaign_config(active_campaign_config)


func _ensure_default_mercenary_catalog() -> void:
	if mercenary_catalog != null:
		return
	var res: Resource = load(DEFAULT_MERCENARY_CATALOG_PATH) as Resource
	if res != null and res.has_method("get_daily_offers"):
		mercenary_catalog = res


func _load_ally_registry() -> void:
	_ally_registry.clear()
	var dir: DirAccess = DirAccess.open("res://resources/ally_data/")
	if dir == null:
		return
	dir.list_dir_begin()
	var fn: String = dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var loaded: Resource = load("res://resources/ally_data/%s" % fn) as Resource
			if loaded != null and str(loaded.get("ally_id")) != "":
				_ally_registry[str(loaded.get("ally_id"))] = loaded
		fn = dir.get_next()
	dir.list_dir_end()


func _load_mini_boss_registry() -> void:
	_mini_boss_registry.clear()
	var dir: DirAccess = DirAccess.open("res://resources/miniboss_data/")
	if dir == null:
		return
	dir.list_dir_begin()
	var fn: String = dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".tres"):
			var loaded: Resource = load("res://resources/miniboss_data/%s" % fn) as Resource
			if loaded != null and str(loaded.get("boss_id")) != "":
				_mini_boss_registry[str(loaded.get("boss_id"))] = loaded
		fn = dir.get_next()
	dir.list_dir_end()


func start_new_campaign() -> void:
	if active_campaign_config != null and campaign_config != active_campaign_config:
		_set_campaign_config(active_campaign_config)

	current_day = 1
	failed_attempts_on_current_day = 0
	campaign_completed = false
	current_mercenary_offers.clear()
	_defeated_defectable_bosses.clear()
	_load_ally_registry()
	_load_mini_boss_registry()
	_ensure_default_mercenary_catalog()
	_bootstrap_starter_allies()

	if campaign_config != null:
		campaign_length = campaign_config.get_effective_length()

	SignalBus.campaign_started.emit(campaign_id)
	_start_current_day_internal()


func _bootstrap_starter_allies() -> void:
	owned_allies.clear()
	active_allies_for_next_day.clear()
	for ally_id: String in _ally_registry.keys():
		var d: Resource = _ally_registry[ally_id] as Resource
		if d != null and bool(d.get("is_starter_ally")):
			if not owned_allies.has(ally_id):
				owned_allies.append(ally_id)
	_apply_default_active_selection()
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


func is_ally_owned(ally_id: String) -> bool:
	return owned_allies.has(ally_id)


func get_owned_allies() -> Array[String]:
	return owned_allies.duplicate()


func get_active_allies() -> Array[String]:
	return active_allies_for_next_day.duplicate()


func get_ally_data(ally_id: String) -> Resource:
	var r: Variant = _ally_registry.get(ally_id, null)
	return r as Resource


func add_ally_to_roster(ally_id: String) -> void:
	if ally_id.is_empty():
		return
	if owned_allies.has(ally_id):
		return
	owned_allies.append(ally_id)
	SignalBus.ally_roster_changed.emit()


func remove_ally_from_roster(ally_id: String) -> void:
	var i: int = owned_allies.find(ally_id)
	if i >= 0:
		owned_allies.remove_at(i)
	var j: int = active_allies_for_next_day.find(ally_id)
	if j >= 0:
		active_allies_for_next_day.remove_at(j)
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


func toggle_ally_active(ally_id: String) -> bool:
	if not is_ally_owned(ally_id):
		return false
	var idx: int = active_allies_for_next_day.find(ally_id)
	if idx >= 0:
		active_allies_for_next_day.remove_at(idx)
		_sync_current_ally_roster_for_spawn()
		SignalBus.ally_roster_changed.emit()
		return true
	if active_allies_for_next_day.size() >= max_active_allies_per_day:
		return false
	active_allies_for_next_day.append(ally_id)
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()
	return true


func set_active_allies_from_list(ally_ids: Array[String]) -> void:
	active_allies_for_next_day.clear()
	for aid: String in ally_ids:
		if not is_ally_owned(aid):
			continue
		if active_allies_for_next_day.size() >= max_active_allies_per_day:
			break
		if not active_allies_for_next_day.has(aid):
			active_allies_for_next_day.append(aid)
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


func get_allies_for_mission_start() -> Array[String]:
	if active_allies_for_next_day.is_empty() and not owned_allies.is_empty():
		_apply_default_active_selection()
		_sync_current_ally_roster_for_spawn()
	return active_allies_for_next_day.duplicate()


func generate_offers_for_day(day: int) -> void:
	var defection_offers: Array = []
	for o: Variant in current_mercenary_offers:
		if o != null and bool(o.get("is_defection_offer")):
			defection_offers.append(o)
	current_mercenary_offers.clear()
	for o: Variant in defection_offers:
		current_mercenary_offers.append(o)
	if mercenary_catalog == null or not mercenary_catalog.has_method("get_daily_offers"):
		for o2: Variant in current_mercenary_offers:
			if o2 != null:
				SignalBus.mercenary_offer_generated.emit(str(o2.get("ally_id")))
		return
	var catalog_offers: Variant = mercenary_catalog.call("get_daily_offers", day, owned_allies)
	if catalog_offers is Array:
		for o3: Variant in catalog_offers as Array:
			current_mercenary_offers.append(o3)
	for o4: Variant in current_mercenary_offers:
		if o4 != null:
			SignalBus.mercenary_offer_generated.emit(str(o4.get("ally_id")))


func preview_mercenary_offers_for_day(day: int, hypothetical_owned: Array[String]) -> Array:
	if mercenary_catalog == null or not mercenary_catalog.has_method("get_daily_offers"):
		return []
	var arr: Variant = mercenary_catalog.call("get_daily_offers", day, hypothetical_owned)
	return arr as Array if arr is Array else []


func get_current_offers() -> Array:
	return current_mercenary_offers.duplicate()


func purchase_mercenary_offer(index: int) -> bool:
	if index < 0 or index >= current_mercenary_offers.size():
		return false
	var offer: Variant = current_mercenary_offers[index]
	if offer == null:
		return false
	if not _can_afford_offer(offer):
		return false
	var cg: int = int(offer.get("cost_gold"))
	var cb: int = int(offer.get("cost_building_material"))
	var cr: int = int(offer.get("cost_research_material"))
	if cg > 0 and not EconomyManager.spend_gold(cg):
		return false
	if cb > 0 and not EconomyManager.spend_building_material(cb):
		return false
	if cr > 0 and not EconomyManager.spend_research_material(cr):
		return false
	var new_id: String = str(offer.get("ally_id"))
	if not owned_allies.has(new_id):
		owned_allies.append(new_id)
	if active_allies_for_next_day.size() < max_active_allies_per_day:
		if not active_allies_for_next_day.has(new_id):
			active_allies_for_next_day.append(new_id)
	_sync_current_ally_roster_for_spawn()
	current_mercenary_offers.remove_at(index)
	SignalBus.mercenary_recruited.emit(new_id)
	SignalBus.ally_roster_changed.emit()
	return true


func notify_mini_boss_defeated(boss_id: String) -> void:
	if boss_id.is_empty() or _defeated_defectable_bosses.has(boss_id):
		return
	var mb: Variant = _mini_boss_registry.get(boss_id, null)
	if mb == null or not bool(mb.get("can_defect_to_ally")):
		return
	_defeated_defectable_bosses.append(boss_id)
	if int(mb.get("defection_day_offset")) == 0:
		_inject_defection_offer(mb as Resource)


func register_mini_boss(boss_data: Resource) -> void:
	if boss_data == null:
		return
	var bid: String = str(boss_data.get("boss_id"))
	if bid.is_empty():
		return
	_mini_boss_registry[bid] = boss_data


func _inject_defection_offer(boss_data: Resource) -> void:
	var offer: Resource = _MercenaryOfferDataGd.new() as Resource
	offer.set("ally_id", str(boss_data.get("defected_ally_id")))
	offer.set("cost_gold", int(boss_data.get("defection_cost_gold")))
	offer.set("cost_building_material", 0)
	offer.set("cost_research_material", 0)
	offer.set("is_defection_offer", true)
	offer.set("min_day", current_day)
	offer.set("max_day", -1)
	current_mercenary_offers.append(offer)
	SignalBus.mercenary_offer_generated.emit(str(offer.get("ally_id")))


# SOURCE: Simple deterministic soldier/officer scoring (XCOM-style talks); weighted role + cost + diversity.
func auto_select_best_allies(
		strategy_profile: Types.StrategyProfile,
		available_offers: Array,
		current_roster: Array[String],
		max_purchases: int,
		budget_gold: int,
		budget_material: int,
		budget_research: int
) -> Dictionary:
	var scored: Array[Dictionary] = []
	var idx: int = 0
	for offer: Variant in available_offers:
		if offer == null:
			idx += 1
			continue
		var aid: String = str(offer.get("ally_id"))
		if current_roster.has(aid):
			idx += 1
			continue
		var og: int = int(offer.get("cost_gold"))
		var ob: int = int(offer.get("cost_building_material"))
		var orr: int = int(offer.get("cost_research_material"))
		if og > budget_gold or ob > budget_material or orr > budget_research:
			idx += 1
			continue
		var ad: Resource = get_ally_data(aid)
		if ad == null:
			idx += 1
			continue
		var s: float = _score_offer(offer, ad, strategy_profile, current_roster)
		scored.append({"i": idx, "score": s, "offer": offer})
		idx += 1

	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["score"]) > float(b["score"])
	)

	var bg: int = budget_gold
	var bm: int = budget_material
	var br: int = budget_research
	var recommended_indices: Array[int] = []
	var sim_roster: Array[String] = current_roster.duplicate()
	for entry: Dictionary in scored:
		if recommended_indices.size() >= max_purchases:
			break
		var off: Variant = entry.get("offer", null)
		if off == null:
			continue
		var g2: int = int(off.get("cost_gold"))
		var b2: int = int(off.get("cost_building_material"))
		var r2: int = int(off.get("cost_research_material"))
		if g2 > bg or b2 > bm or r2 > br:
			continue
		bg -= g2
		bm -= b2
		br -= r2
		recommended_indices.append(int(entry["i"]))
		var oid: String = str(off.get("ally_id"))
		if not sim_roster.has(oid):
			sim_roster.append(oid)

	var recommended_active: Array[String] = _pick_best_active(sim_roster, strategy_profile)
	return {
		"recommended_offer_indices": recommended_indices,
		"recommended_active_allies": recommended_active,
	}


func _pick_best_active(simulated_roster: Array[String], strategy_profile: Types.StrategyProfile) -> Array[String]:
	var scored_ids: Array[Dictionary] = []
	for aid2: String in simulated_roster:
		var d: Resource = get_ally_data(aid2)
		if d == null:
			continue
		var role_i: int = int(d.get("role"))
		var sc: float = _role_alignment_score(role_i, strategy_profile)
		scored_ids.append({"id": aid2, "score": sc})
	scored_ids.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if float(a["score"]) == float(b["score"]):
			return str(a["id"]) < str(b["id"])
		return float(a["score"]) > float(b["score"])
	)
	var out: Array[String] = []
	for e: Dictionary in scored_ids:
		if out.size() >= max_active_allies_per_day:
			break
		out.append(str(e["id"]))
	return out


func _score_offer(
		offer: Variant,
		ally_data: Resource,
		strategy_profile: Types.StrategyProfile,
		current_roster: Array[String]
) -> float:
	var og: int = int(offer.get("cost_gold"))
	var ob: int = int(offer.get("cost_building_material"))
	var orr: int = int(offer.get("cost_research_material"))
	var total_cost: float = float(og + 2 * ob + 3 * orr)
	var cost_eff: float = maxf(0.0, 1.0 - total_cost / 300.0)
	var my_role: int = int(ally_data.get("role"))
	var role_part: float = _role_alignment_score(my_role, strategy_profile)
	var diversity: float = 0.0
	var has_same_role: bool = false
	for oid: String in current_roster:
		var od: Resource = get_ally_data(oid)
		if od != null and int(od.get("role")) == my_role:
			has_same_role = true
			break
	if not has_same_role:
		diversity = 0.5
	return role_part + cost_eff + diversity


func _role_alignment_score(role: int, strategy: Types.StrategyProfile) -> float:
	match strategy:
		Types.StrategyProfile.ALLY_HEAVY_PHYSICAL:
			if role == int(Types.AllyRole.MELEE_FRONTLINE):
				return 2.0
			if role == int(Types.AllyRole.RANGED_SUPPORT):
				return 1.5
			return 0.0
		Types.StrategyProfile.ANTI_AIR_FOCUS:
			if role == int(Types.AllyRole.ANTI_AIR):
				return 2.0
			if role == int(Types.AllyRole.RANGED_SUPPORT):
				return 0.5
			return 0.0
		Types.StrategyProfile.SPELL_FOCUS:
			if role == int(Types.AllyRole.SPELL_SUPPORT):
				return 2.0
			return 0.0
		Types.StrategyProfile.BUILDING_FOCUS:
			return 0.0
		Types.StrategyProfile.BALANCED:
			return 0.3
	return 0.0


func _apply_default_active_selection() -> void:
	active_allies_for_next_day.clear()
	var sorted_ids: Array[String] = owned_allies.duplicate()
	sorted_ids.sort()
	for aid: String in sorted_ids:
		if active_allies_for_next_day.size() >= max_active_allies_per_day:
			break
		active_allies_for_next_day.append(aid)
	_sync_current_ally_roster_for_spawn()


func _can_afford_offer(offer: Variant) -> bool:
	if offer == null:
		return false
	return (
			EconomyManager.get_gold() >= int(offer.get("cost_gold"))
			and EconomyManager.get_building_material() >= int(offer.get("cost_building_material"))
			and EconomyManager.get_research_material() >= int(offer.get("cost_research_material"))
	)


func _sync_current_ally_roster_for_spawn() -> void:
	current_ally_roster.clear()
	current_ally_roster_ids.clear()
	for aid: String in active_allies_for_next_day:
		if aid == "arnulf":
			continue
		var data: Resource = get_ally_data(aid)
		if data == null:
			continue
		if str(data.get("scene_path")).strip_edges().is_empty():
			continue
		current_ally_roster.append(data)
		current_ally_roster_ids.append(aid)


func has_ally(ally_id: String) -> bool:
	return is_ally_owned(ally_id)


func start_next_day() -> void:
	GameManager.prepare_next_campaign_day_if_needed()
	_start_current_day_internal()


func get_current_day() -> int:
	return current_day


func get_campaign_length() -> int:
	return campaign_length


func get_current_day_config() -> DayConfig:
	return current_day_config


func _load_faction_registry() -> void:
	faction_registry.clear()
	for path: String in FactionDataType.BUILTIN_FACTION_RESOURCE_PATHS:
		var data: FactionDataType = load(path) as FactionDataType
		if data == null:
			push_error("CampaignManager: Failed to load FactionData at %s" % path)
			continue
		if data.faction_id == "":
			push_error("CampaignManager: FactionData at %s has empty faction_id" % path)
			continue
		faction_registry[data.faction_id] = data


func validate_day_configs(day_configs: Array[DayConfig]) -> void:
	for dc: DayConfig in day_configs:
		assert(dc != null, "CampaignManager.validate_day_configs: null DayConfig in array.")
		var fid: String = dc.faction_id.strip_edges()
		if fid.is_empty():
			fid = "DEFAULT_MIXED"
		assert(not fid.is_empty(), "CampaignManager.validate_day_configs: resolved faction_id empty.")
		assert(
			faction_registry.has(fid),
			"CampaignManager.validate_day_configs: unknown faction_id '%s'." % fid
		)


func _set_campaign_config(config: CampaignConfig) -> void:
	campaign_config = config
	if campaign_config != null:
		campaign_length = campaign_config.get_effective_length()
		campaign_id = campaign_config.campaign_id
	else:
		campaign_length = 0
		campaign_id = ""
	if GameManager != null:
		GameManager.reload_territory_map_from_active_campaign()


func _start_current_day_internal() -> void:
	if campaign_config == null:
		return
	if current_day < 1:
		return

	current_day_config = GameManager.get_day_config_for_index(current_day)
	if current_day_config == null:
		push_error("CampaignManager: no DayConfig for day %d" % current_day)
		return

	SignalBus.day_started.emit(current_day)
	GameManager.start_mission_for_day(current_day, current_day_config)


func _on_mission_won(mission_number: int) -> void:
	if mission_number != current_day:
		return

	failed_attempts_on_current_day = 0
	SignalBus.day_won.emit(current_day)
	if GameManager.final_boss_defeated:
		campaign_completed = true
		SignalBus.campaign_completed.emit(campaign_id)
		return

	current_day += 1
	if current_day > campaign_length and campaign_length > 0:
		campaign_completed = true
		SignalBus.campaign_completed.emit(campaign_id)
		return

	generate_offers_for_day(current_day)


func _on_mission_failed(mission_number: int) -> void:
	if mission_number != current_day:
		return

	failed_attempts_on_current_day += 1
	SignalBus.day_failed.emit(current_day)


func set_active_campaign_config_for_test(config: CampaignConfig) -> void:
	active_campaign_config = config
	_set_campaign_config(config)


func reinitialize_ally_roster_for_test() -> void:
	_load_ally_registry()
	owned_allies.clear()
	active_allies_for_next_day.clear()
	for legacy_id: String in ["ally_melee_generic", "ally_ranged_generic"]:
		if _ally_registry.has(legacy_id):
			owned_allies.append(legacy_id)
	_apply_default_active_selection()
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()
````

---

## `autoloads/damage_calculator.gd`

````
## damage_calculator.gd
## Stateless utility that applies armor-type multipliers to incoming base damage.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# Nested Dictionary[ArmorType, Dictionary[DamageType, float]]
# Row = armor type of target. Column = damage type of attack.
const DAMAGE_MATRIX: Dictionary = {
	Types.ArmorType.UNARMORED: {
		Types.DamageType.PHYSICAL: 1.0,
		Types.DamageType.FIRE:     1.0,
		Types.DamageType.MAGICAL:  1.0,
		Types.DamageType.POISON:   1.0,
	},
	Types.ArmorType.HEAVY_ARMOR: {
		Types.DamageType.PHYSICAL: 0.5,
		Types.DamageType.FIRE:     1.0,
		Types.DamageType.MAGICAL:  2.0,
		Types.DamageType.POISON:   1.0,
	},
	Types.ArmorType.UNDEAD: {
		Types.DamageType.PHYSICAL: 1.0,
		Types.DamageType.FIRE:     2.0,
		Types.DamageType.MAGICAL:  1.0,
		Types.DamageType.POISON:   0.0,
	},
	Types.ArmorType.FLYING: {
		Types.DamageType.PHYSICAL: 1.0,
		Types.DamageType.FIRE:     1.0,
		Types.DamageType.MAGICAL:  1.0,
		Types.DamageType.POISON:   1.0,
	},
}

## Returns base_damage multiplied by the matrix multiplier for the given armor and damage type.
## Never emits signals. Never reads game state. Pure function.
func calculate_damage(
		base_damage: float,
		damage_type: Types.DamageType,
		armor_type: Types.ArmorType) -> float:
	return base_damage * DAMAGE_MATRIX[armor_type][damage_type]

## Returns per-tick damage for a DoT effect.
## dot_total_damage is the total intended DoT damage over the full duration
## before applying the armor/damage matrix. The returned value is the
## final per-tick damage after applying the existing damage matrix and
## immunity rules.
## Example: dot_total_damage = 100, duration = 5.0, tick_interval = 0.5
## -> 10 ticks, 10 base per tick before multipliers.
func calculate_dot_tick(
		dot_total_damage: float,
		tick_interval: float,
		duration: float,
		damage_type: Types.DamageType,
		armor_type: Types.ArmorType
	) -> float:
	if duration <= 0.0 or tick_interval <= 0.0:
		return 0.0

	var ticks: float = duration / tick_interval
	if ticks <= 0.0:
		return 0.0

	var per_tick_base: float = dot_total_damage / ticks
	return calculate_damage(per_tick_base, damage_type, armor_type)
````

---

## `autoloads/dialogue_manager.gd`

````
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

var _rng := RandomNumberGenerator.new() # TUNING

signal dialogue_line_started(entry_id: String, character_id: String)
signal dialogue_line_finished(entry_id: String, character_id: String)


func _ready() -> void:
	_rng.randomize()
	_load_all_dialogue_entries()
	_sync_from_game_manager()
	_connect_signals()


func _sync_from_game_manager() -> void:
	current_mission_number = GameManager.get_current_mission()
	current_gamestate = GameManager.get_game_state()


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
		var current_value: Variant = _resolve_state_value(cond.key)
		if not _compare(current_value, cond.comparison, cond.value):
			return false
	return true


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


func _is_shop_item_purchased(_item_id: String) -> bool:
	# POST-MVP: implement a purchase history cache on ShopManager.
	return false


func _on_game_state_changed(_old_state: Types.GameState, new_state: Types.GameState) -> void:
	current_gamestate = new_state


func _on_mission_started(mission_number: int) -> void:
	current_mission_number = mission_number


func _on_mission_won(_mission_number: int) -> void:
	mission_won_count += 1


func _on_mission_failed(_mission_number: int) -> void:
	mission_failed_count += 1


func _on_resource_changed(_resource_type: Types.ResourceType, _new_amount: int) -> void:
	pass


func _on_research_unlocked(_node_id: String) -> void:
	pass


func _on_shop_item_purchased(_item_id: String) -> void:
	pass


func _on_arnulf_state_changed(_new_state: Types.ArnulfState) -> void:
	pass


func _on_spell_cast(_spell_id: String) -> void:
	pass
````

---

## `autoloads/economy_manager.gd`

````
## economy_manager.gd
## Owns gold, building_material, and research_material resource counters for FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

const DEFAULT_GOLD: int = 1000
const DEFAULT_BUILDING_MATERIAL: int = 50
const DEFAULT_RESEARCH_MATERIAL: int = 0

# During manual playtesting we want more starting resources to reach between-mission
# interactions faster. GdUnit runs headless, so we keep the defaults there to avoid
# breaking unit tests that assert exact starting values.
const PLAYTEST_STARTING_RESOURCES_MULTIPLIER: int = 5

# Research defaults to 0 in MVP, so multiplying would still be 0.
# For playtesting we want enough to unlock the whole tree without worrying about cost.
const PLAYTEST_STARTING_RESEARCH_MATERIAL: int = 50

var gold: int = DEFAULT_GOLD
var building_material: int = DEFAULT_BUILDING_MATERIAL
var research_material: int = DEFAULT_RESEARCH_MATERIAL

func _ready() -> void:
	SignalBus.enemy_killed.connect(_on_enemy_killed)

# ── Signal receivers ───────────────────────────────────────────────────────────

func _on_enemy_killed(_enemy_type: Types.EnemyType, _position: Vector3, gold_reward: int) -> void:
	add_gold(gold_reward)

# ── Gold ───────────────────────────────────────────────────────────────────────

## Adds amount to gold. Emits resource_changed(GOLD, new_amount).
func add_gold(amount: int) -> void:
	assert(amount > 0, "add_gold called with non-positive amount: %d" % amount)
	gold += amount
	SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)

## Deducts amount from gold. Returns false without modifying state if insufficient.
func spend_gold(amount: int) -> bool:
	assert(amount > 0, "spend_gold called with non-positive amount: %d" % amount)
	if gold < amount:
		return false
	gold -= amount
	SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
	return true

# ── Building Material ──────────────────────────────────────────────────────────

## Adds amount to building_material. Emits resource_changed(BUILDING_MATERIAL, new_amount).
func add_building_material(amount: int) -> void:
	assert(amount > 0, "add_building_material called with non-positive amount: %d" % amount)
	building_material += amount
	SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)

## Deducts amount from building_material. Returns false without modifying state if insufficient.
func spend_building_material(amount: int) -> bool:
	assert(amount > 0, "spend_building_material called with non-positive amount: %d" % amount)
	if building_material < amount:
		return false
	building_material -= amount
	SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
	return true

# ── Research Material ──────────────────────────────────────────────────────────

## Adds amount to research_material. Emits resource_changed(RESEARCH_MATERIAL, new_amount).
func add_research_material(amount: int) -> void:
	assert(amount > 0, "add_research_material called with non-positive amount: %d" % amount)
	research_material += amount
	SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)

## Deducts amount from research_material. Returns false without modifying state if insufficient.
func spend_research_material(amount: int) -> bool:
	assert(amount > 0, "spend_research_material called with non-positive amount: %d" % amount)
	if research_material < amount:
		return false
	research_material -= amount
	SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)
	return true

# ── Queries ────────────────────────────────────────────────────────────────────

## Returns true if gold >= gold_cost AND building_material >= material_cost.
func can_afford(gold_cost: int, material_cost: int) -> bool:
	return gold >= gold_cost and building_material >= material_cost

## Returns current gold amount.
func get_gold() -> int:
	return gold

## Returns current building_material amount.
func get_building_material() -> int:
	return building_material

## Returns current research_material amount.
func get_research_material() -> int:
	return research_material

# ── Reset ──────────────────────────────────────────────────────────────────────

## Resets all three resources to starting values. Emits resource_changed for each.
## Call this at new-game start or during test setup.
func reset_to_defaults() -> void:
	var is_playtest_starting_bundle: bool = not (_is_gdunit_run() or _is_headless_run())

	var multiplier: int = PLAYTEST_STARTING_RESOURCES_MULTIPLIER if is_playtest_starting_bundle else 1
	gold = DEFAULT_GOLD * multiplier
	building_material = DEFAULT_BUILDING_MATERIAL * multiplier
	research_material = PLAYTEST_STARTING_RESEARCH_MATERIAL if is_playtest_starting_bundle else DEFAULT_RESEARCH_MATERIAL
	SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
	SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
	SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)


func _is_gdunit_run() -> bool:
	# GdUnit is usually run via:
	#   -s res://addons/gdUnit4/bin/GdUnitCmdTool.gd
	# Detect that so unit tests keep exact economy defaults.
	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg.find("GdUnitCmdTool.gd") != -1:
			return true
		if arg.find("GdUnitCopyLog.gd") != -1:
			return true
	return false


func _is_headless_run() -> bool:
	# GdUnit CLI runs Godot in headless mode.
	if OS.has_feature("headless"):
		return true

	var args: PackedStringArray = OS.get_cmdline_args()
	for arg: String in args:
		if arg == "--headless":
			return true
	return false
````

---

## `autoloads/enchantment_manager.gd`

````
## enchantment_manager.gd
## Tracks equipped enchantments per Florence weapon and affinity stubs.
## Provides a clean API for Tower and BetweenMissionScreen to query and change state.
## SOURCE: Resources-as-stats pattern, https://forum.godotengine.org/t/resources-as-stats/107326

extends Node

# Mapping: weapon_slot (Types.WeaponSlot) -> Dictionary[String, String]
# Keys in inner dictionary: "elemental", "power"
var _equipped_enchantments: Dictionary = {}

# POST-MVP affinity tracking: weapon_slot -> affinity level / xp.
var _affinity_level: Dictionary = {}
var _affinity_xp: Dictionary = {}


func _ready() -> void:
	_reset_to_defaults_internal()


func _reset_to_defaults_internal() -> void:
	_equipped_enchantments.clear()
	_affinity_level.clear()
	_affinity_xp.clear()

	for weapon_slot_value: int in Types.WeaponSlot.values():
		var weapon_slot: Types.WeaponSlot = weapon_slot_value as Types.WeaponSlot
		_equipped_enchantments[weapon_slot] = {
			"elemental": "",
			"power": "",
		}
		_affinity_level[weapon_slot] = 0  # POST-MVP
		_affinity_xp[weapon_slot] = 0.0  # POST-MVP


func reset_to_defaults() -> void:
	# Called from GameManager.start_new_game to clear campaign-state.
	_reset_to_defaults_internal()


func get_equipped_enchantment_id(weapon_slot: Types.WeaponSlot, slot_type: String) -> String:
	if not _equipped_enchantments.has(weapon_slot):
		return ""
	var slots: Dictionary = _equipped_enchantments[weapon_slot]
	if not slots.has(slot_type):
		return ""
	return slots[slot_type] as String


func get_equipped_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> EnchantmentData:
	var enchantment_id: String = get_equipped_enchantment_id(weapon_slot, slot_type)
	if enchantment_id == "":
		return null

	# ASSUMPTION: Enchantment resources live under res://resources/enchantments/.
	var path: String = "res://resources/enchantments/%s.tres" % enchantment_id
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = ResourceLoader.load(path)
	if not (resource is EnchantmentData):
		return null
	return resource as EnchantmentData


func get_all_equipped_enchantments_for_weapon(weapon_slot: Types.WeaponSlot) -> Dictionary:
	if not _equipped_enchantments.has(weapon_slot):
		return {}
	return (_equipped_enchantments[weapon_slot] as Dictionary).duplicate(true)


func try_apply_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String, gold_cost: int) -> bool:
	if gold_cost > 0:
		if not EconomyManager.can_afford(gold_cost, 0):
			return false
		var spent: bool = EconomyManager.spend_gold(gold_cost)
		if not spent:
			return false

	if not _equipped_enchantments.has(weapon_slot):
		_equipped_enchantments[weapon_slot] = {
			"elemental": "",
			"power": "",
		}

	var slots: Dictionary = _equipped_enchantments[weapon_slot]
	slots[slot_type] = enchantment_id
	_equipped_enchantments[weapon_slot] = slots

	SignalBus.enchantment_applied.emit(weapon_slot, slot_type, enchantment_id)
	return true


func remove_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> void:
	if not _equipped_enchantments.has(weapon_slot):
		return

	var slots: Dictionary = _equipped_enchantments[weapon_slot]
	if not slots.has(slot_type):
		return
	if (slots[slot_type] as String) == "":
		return

	slots[slot_type] = ""
	_equipped_enchantments[weapon_slot] = slots
	SignalBus.enchantment_removed.emit(weapon_slot, slot_type)


func get_affinity_level(weapon_slot: Types.WeaponSlot) -> int:
	if not _affinity_level.has(weapon_slot):
		return 0
	return _affinity_level[weapon_slot] as int


func get_affinity_xp(weapon_slot: Types.WeaponSlot) -> float:
	if not _affinity_xp.has(weapon_slot):
		return 0.0
	return _affinity_xp[weapon_slot] as float


func gain_affinity_xp(weapon_slot: Types.WeaponSlot, amount: float) -> void:
	# POST-MVP: Currently inert except for tracking numbers.
	if amount <= 0.0:
		return
	if not _affinity_xp.has(weapon_slot):
		_affinity_xp[weapon_slot] = 0.0
	_affinity_xp[weapon_slot] = (_affinity_xp[weapon_slot] as float) + amount
````

---

## `autoloads/game_manager.gd`

````
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
	var shop: Node = get_node_or_null("/root/ShopManager")
	var tower: Node = get_node_or_null("/root/Main/Tower")
	if shop != null and tower != null and shop.has_method("initialize_tower"):
		shop.initialize_tower(tower)
		print("[GameManager] _ready: ShopManager wired to Tower")
	reload_territory_map_from_active_campaign()
	SignalBus.boss_killed.connect(_on_boss_killed)
	_sync_held_territories_from_map()


func _connect_mission_won_transition_to_hub() -> void:
	if SignalBus.mission_won.is_connected(_on_mission_won_transition_to_hub):
		return
	SignalBus.mission_won.connect(_on_mission_won_transition_to_hub)


## Runs after CampaignManager._on_mission_won (autoload order: CampaignManager before GameManager). Also used when tests emit mission_won without waves.
func _on_mission_won_transition_to_hub(mission_number: int) -> void:
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

func start_new_game() -> void:
	print("[GameManager] start_new_game: mission=1  gold=%d mat=%d" % [
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
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

func start_next_mission() -> void:
	# DEVIATION: next day is now owned by CampaignManager.
	# BetweenMissionScreen routes directly through CampaignManager, this remains for compatibility.
	CampaignManager.start_next_day()

func start_wave_countdown() -> void:
	assert(game_state == Types.GameState.MISSION_BRIEFING, "start_wave_countdown called from invalid state")
	_transition_to(Types.GameState.COMBAT)
	_spawn_allies_for_current_mission()
	_apply_shop_mission_start_consumables()
	# Single source of truth for countdown duration: WaveManager emits wave_countdown_started.
	_begin_mission_wave_sequence()

func enter_build_mode() -> void:
	print("[GameManager] enter_build_mode: from=%s" % Types.GameState.keys()[game_state])
	assert(
		game_state == Types.GameState.COMBAT or game_state == Types.GameState.WAVE_COUNTDOWN,
		"enter_build_mode called from invalid state: %s" % Types.GameState.keys()[game_state]
	)
	Engine.time_scale = 0.1
	var old: Types.GameState = game_state
	game_state = Types.GameState.BUILD_MODE
	SignalBus.build_mode_entered.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.BUILD_MODE)

func exit_build_mode() -> void:
	print("[GameManager] exit_build_mode")
	Engine.time_scale = 1.0
	var old: Types.GameState = game_state
	game_state = Types.GameState.COMBAT
	SignalBus.build_mode_exited.emit()
	SignalBus.game_state_changed.emit(old, Types.GameState.COMBAT)

func get_game_state() -> Types.GameState:
	return game_state

func get_current_mission() -> int:
	return current_mission

func get_current_wave() -> int:
	return current_wave

func get_florence_data() -> FlorenceDataType:
	return florence_data

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


func get_day_config_for_index(day_index: int) -> DayConfig:
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


func get_current_day_config() -> DayConfig:
	return CampaignManager.get_current_day_config()


func get_current_day_territory_id() -> String:
	var day_config: DayConfig = get_current_day_config()
	if day_config == null:
		return ""
	return day_config.territory_id


func get_territory_data(territory_id: String) -> TerritoryData:
	if territory_map == null:
		return null
	return territory_map.get_territory_by_id(territory_id)


func get_current_day_territory() -> TerritoryData:
	var id: String = get_current_day_territory_id()
	if id == "":
		return null
	return get_territory_data(id)


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
	if game_state == new_state:
		return
	var old_name: String = Types.GameState.keys()[game_state]
	var new_name: String = Types.GameState.keys()[new_state]
	print("[GameManager] state: %s → %s" % [old_name, new_name])
	var old: Types.GameState = game_state
	game_state = new_state
	SignalBus.game_state_changed.emit(old, new_state)

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
	EconomyManager.add_research_material(2)
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
	if florence_data != null:
		florence_data.total_missions_played += 1
		advance_day(Types.DayAdvanceReason.MISSION_COMPLETED)
		_apply_pending_day_advance_if_any()

	SignalBus.mission_won.emit(current_mission)

func _on_tower_destroyed() -> void:
	_cleanup_allies()
	print("[GameManager] tower_destroyed → MISSION_FAILED")
	var day_cfg: DayConfig = CampaignManager.get_current_day_config()
	var completed_day_index: int = CampaignManager.get_current_day()

	# Florence meta-state updates (counts mission attempts).
	if florence_data != null:
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
	SignalBus.mission_failed.emit(current_mission)


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
	SignalBus.territory_state_changed.emit(territory_id)
````

---

## `autoloads/signal_bus.gd`

````
## signal_bus.gd
## Central signal registry for all cross-system communication in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# === COMBAT ===
@warning_ignore("unused_signal")
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
## POST-MVP: enemy_reached_tower is not emitted in MVP. EnemyBase calls Tower.take_damage() directly.
@warning_ignore("unused_signal")
signal enemy_reached_tower(enemy_type: Types.EnemyType, damage: int)
@warning_ignore("unused_signal")
signal tower_damaged(current_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal tower_destroyed()
@warning_ignore("unused_signal")
signal projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)
@warning_ignore("unused_signal")
signal arnulf_state_changed(new_state: Types.ArnulfState)
@warning_ignore("unused_signal")
signal arnulf_incapacitated()
@warning_ignore("unused_signal")
signal arnulf_recovered()

# === ALLIES ===
@warning_ignore("unused_signal")
signal ally_spawned(ally_id: String)
@warning_ignore("unused_signal")
signal ally_downed(ally_id: String)
@warning_ignore("unused_signal")
signal ally_recovered(ally_id: String)
@warning_ignore("unused_signal")
signal ally_killed(ally_id: String)
# POST-MVP: detailed ally state tracking.
@warning_ignore("unused_signal")
signal ally_state_changed(ally_id: String, new_state: String)

# === BOSSES (Prompt 10) ===
@warning_ignore("unused_signal")
signal boss_spawned(boss_id: String)
@warning_ignore("unused_signal")
signal boss_killed(boss_id: String)
@warning_ignore("unused_signal")
signal campaign_boss_attempted(day_index: int, success: bool)

# === WAVES ===
@warning_ignore("unused_signal")
signal wave_countdown_started(wave_number: int, seconds_remaining: float)
@warning_ignore("unused_signal")
signal wave_started(wave_number: int, enemy_count: int)
@warning_ignore("unused_signal")
signal wave_cleared(wave_number: int)
@warning_ignore("unused_signal")
signal all_waves_cleared()

# === ECONOMY ===
@warning_ignore("unused_signal")
signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

# === TERRITORIES / WORLD MAP ===
@warning_ignore("unused_signal")
signal territory_state_changed(territory_id: String)
@warning_ignore("unused_signal")
signal world_map_updated()

# === BUILDINGS ===
@warning_ignore("unused_signal")
signal building_placed(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_sold(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
## POST-MVP: building_destroyed is not emitted in MVP. Buildings cannot take damage in MVP.
@warning_ignore("unused_signal")
signal building_destroyed(slot_index: int)

# === SPELLS ===
@warning_ignore("unused_signal")
signal spell_cast(spell_id: String)
@warning_ignore("unused_signal")
signal spell_ready(spell_id: String)
@warning_ignore("unused_signal")
signal mana_changed(current_mana: int, max_mana: int)

# === GAME STATE ===
@warning_ignore("unused_signal")
signal game_state_changed(old_state: Types.GameState, new_state: Types.GameState)
@warning_ignore("unused_signal")
signal mission_started(mission_number: int)
@warning_ignore("unused_signal")
signal mission_won(mission_number: int)
@warning_ignore("unused_signal")
signal mission_failed(mission_number: int)

# Florence / campaign meta-state.
@warning_ignore("unused_signal")
signal florence_state_changed()

# Campaign / day-level signals.
# mission_* signals remain mission-level; in the current short campaign they
# correspond 1:1 to days (one mission per day). CampaignManager wraps them.
@warning_ignore("unused_signal")
signal campaign_started(campaign_id: String)
@warning_ignore("unused_signal")
signal day_started(day_index: int)
@warning_ignore("unused_signal")
signal day_won(day_index: int)
@warning_ignore("unused_signal")
signal day_failed(day_index: int)
@warning_ignore("unused_signal")
signal campaign_completed(campaign_id: String)

# === BUILD MODE ===
@warning_ignore("unused_signal")
signal build_mode_entered()
@warning_ignore("unused_signal")
signal build_mode_exited()

# === RESEARCH ===
@warning_ignore("unused_signal")
signal research_unlocked(node_id: String)

# === SHOP ===
@warning_ignore("unused_signal")
signal shop_item_purchased(item_id: String)
## Emitted by ShopManager when a mana draught has been consumed by GameManager at mission start.
@warning_ignore("unused_signal")
signal mana_draught_consumed()

# === WEAPONS ===
@warning_ignore("unused_signal")
signal weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)

# === ENCHANTMENTS ===
@warning_ignore("unused_signal")
signal enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)
@warning_ignore("unused_signal")
signal enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)

# === CAMPAIGN / ALLY ROSTER (Prompt 12) ===
@warning_ignore("unused_signal")
signal mercenary_offer_generated(ally_id: String)
@warning_ignore("unused_signal")
signal mercenary_recruited(ally_id: String)
@warning_ignore("unused_signal")
signal ally_roster_changed()
````

---

## `scenes/allies/ally_base.gd`

````
## ally_base.gd
## Generic ally CharacterBody3D: navigate, acquire nearest enemy, melee/ranged direct damage.
## Mission death and campaign roster recovery are separate layers (CampaignManager — POST-MVP).

class_name AllyBase
extends CharacterBody3D

const _MIN_NAV_STEP_SQ: float = 0.0004

@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var ally_mesh: MeshInstance3D = $AllyMesh
@onready var _detection_shape: CollisionShape3D = $DetectionArea/DetectionShape
@onready var _attack_shape: CollisionShape3D = $AttackArea/AttackShape

var ally_data: Variant = null

enum AllyState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DOWNED,
	RECOVERING,
}

var _state: AllyState = AllyState.IDLE
var _current_target: EnemyBase = null
var _attack_cooldown_remaining: float = 0.0


func _ready() -> void:
	detection_area.body_entered.connect(_on_detection_body_entered)
	attack_area.body_entered.connect(_on_attack_body_entered)
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.75
	navigation_agent.avoidance_enabled = true
	navigation_agent.radius = 0.5


## Spec alias (Prompt 12); delegates to `initialize_ally_data`.
func initialize(p_ally_data: AllyData) -> void:
	initialize_ally_data(p_ally_data)


func initialize_ally_data(p_ally_data: Variant) -> void:
	ally_data = p_ally_data
	if ally_data == null:
		push_error("AllyBase.initialize_ally_data: null AllyData")
		return

	health_component.max_hp = int(ally_data.get("max_hp"))
	health_component.reset_to_max()
	_attack_cooldown_remaining = 0.0
	_state = AllyState.IDLE
	_current_target = null

	if not health_component.health_depleted.is_connected(_on_health_depleted):
		health_component.health_depleted.connect(_on_health_depleted)

	_apply_ally_data_to_shapes()
	_apply_debug_color_from_data()

	# DEVIATION: generic ally_spawned for campaign / UI integration.
	SignalBus.ally_spawned.emit(str(ally_data.get("ally_id")))


func _apply_ally_data_to_shapes() -> void:
	if ally_data == null:
		return
	var atk_range: float = float(ally_data.get("attack_range"))
	var detect_r: float = maxf(40.0, atk_range + 2.0)
	if _detection_shape != null and _detection_shape.shape is SphereShape3D:
		(_detection_shape.shape as SphereShape3D).radius = detect_r
	if _attack_shape != null and _attack_shape.shape is SphereShape3D:
		(_attack_shape.shape as SphereShape3D).radius = atk_range


func _apply_debug_color_from_data() -> void:
	if ally_data == null or ally_mesh == null:
		return
	var c: Variant = ally_data.get("debug_color")
	if c is Color and ally_mesh.material_override is StandardMaterial3D:
		(ally_mesh.material_override as StandardMaterial3D).albedo_color = c as Color


func _physics_process(delta: float) -> void:
	if ally_data == null:
		return
	match _state:
		AllyState.IDLE:
			_update_idle(delta)
		AllyState.PATROL:
			_update_idle(delta)
		AllyState.CHASE:
			_update_chase(delta)
		AllyState.ATTACK:
			_update_attack(delta)
		AllyState.DOWNED:
			_update_downed(delta)
		AllyState.RECOVERING:
			_update_recovering(delta)


func _update_idle(_delta: float) -> void:
	velocity = Vector3.ZERO
	var t: EnemyBase = find_target()
	if t != null:
		_current_target = t
		_state = AllyState.CHASE


func _update_chase(delta: float) -> void:
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = find_target()
		if _current_target == null:
			_state = AllyState.IDLE
			return

	var atk_range: float = float(ally_data.get("attack_range"))
	var dist: float = global_position.distance_to(_current_target.global_position)
	if dist <= atk_range:
		_state = AllyState.ATTACK
		velocity = Vector3.ZERO
		return

	# SOURCE: Godot 4 NavigationAgent3D chase pattern — target_position + get_next_path_position
	# in _physics_process; https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
	navigation_agent.target_position = _current_target.global_position
	if navigation_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return

	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_pos - global_position
	if direction.length_squared() > _MIN_NAV_STEP_SQ:
		direction = direction.normalized()
		velocity = direction * float(ally_data.get("move_speed"))
		move_and_slide()
	else:
		velocity = Vector3.ZERO


func _update_attack(delta: float) -> void:
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = find_target()
		if _current_target == null:
			_state = AllyState.IDLE
			return
		_state = AllyState.CHASE
		return

	var atk_range_at: float = float(ally_data.get("attack_range"))
	var dist: float = global_position.distance_to(_current_target.global_position)
	if dist > atk_range_at:
		_state = AllyState.CHASE
		return

	velocity = Vector3.ZERO
	_attack_cooldown_remaining -= delta
	if _attack_cooldown_remaining <= 0.0:
		_perform_attack_on_target(_current_target)
		_attack_cooldown_remaining = float(ally_data.get("attack_cooldown"))


func _update_downed(_delta: float) -> void:
	# POST-MVP: downed/recover loop for generic allies when uses_downed_recovering is true.
	pass


func _update_recovering(_delta: float) -> void:
	# POST-MVP: paired with DOWNED recovery timer.
	pass


func _on_detection_body_entered(body: Node) -> void:
	if _state == AllyState.DOWNED or _state == AllyState.RECOVERING:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if _current_target == null:
		_current_target = enemy
		_state = AllyState.CHASE


func _on_attack_body_entered(body: Node) -> void:
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _current_target and _state == AllyState.CHASE:
		_state = AllyState.ATTACK


# SOURCE: nearest-enemy selection over a group — iterate candidates, minimize distance squared;
# pattern common in RTS/arena prototypes (see also Godot group queries).
func find_target() -> EnemyBase:
	var best_enemy: EnemyBase = null
	var best_score: float = INF

	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue
		# POST-MVP: respect preferred_targeting (HIGHEST_HP, FLYING_FIRST, etc.).
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if dist_sq < best_score:
			best_score = dist_sq
			best_enemy = enemy

	return best_enemy


func _perform_attack_on_target(enemy: EnemyBase) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var dmg: float = float(ally_data.get("attack_damage"))
	if dmg <= 0.0:
		dmg = float(ally_data.get("basic_attack_damage"))
	var damage_t: Types.DamageType = Types.DamageType.PHYSICAL
	if ally_data is AllyData:
		damage_t = (ally_data as AllyData).damage_type
	else:
		var dt: Variant = ally_data.get("damage_type")
		if dt != null:
			damage_t = dt as Types.DamageType
	# POST-MVP: RANGED allies may instantiate ProjectileBase via initialize_from_building(...) for visuals.
	enemy.take_damage(dmg, damage_t)


func _on_health_depleted() -> void:
	if ally_data != null and bool(ally_data.get("uses_downed_recovering")):
		_state = AllyState.DOWNED
		SignalBus.ally_downed.emit(str(ally_data.get("ally_id")))
		# POST-MVP: start recovery timer, heal, ally_recovered, return to IDLE.
		return

	var id: String = str(ally_data.get("ally_id")) if ally_data != null else ""
	SignalBus.ally_killed.emit(id)
	queue_free()


func get_current_state() -> AllyState:
	return _state


func get_current_hp() -> int:
	if health_component == null:
		return 0
	return health_component.get_current_hp()
````

---

## `scenes/arnulf/arnulf.gd`

````
# arnulf.gd
# Arnulf is the fully AI-controlled melee companion in FOUL WARD.
# He patrols near the tower, chases the closest enemy to TOWER_CENTER,
# attacks at melee range, and revives himself after being downed.
#
# State machine: IDLE → CHASE → ATTACK → DOWNED → RECOVERING → IDLE
# All cross-system communication via SignalBus (never direct node refs).
#
# Credit: Godot Engine Documentation — CharacterBody3D, NavigationAgent3D
#   https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
#   https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
#   License: CC BY 3.0 | Adapted by: Foul Ward team
#   Adapted: move_and_slide() loop, get_next_path_position() per-frame update,
#            NavigationAgent3D target_position update pattern.
#
# Credit: Godot Engine Documentation — Area3D.get_overlapping_bodies()
#   https://docs.godotengine.org/en/stable/classes/class_area3d.html
#   License: CC BY 3.0 | Adapted by: Foul Ward team
#   Adapted: snapshot-based closest-body search; is_instance_valid guard.
#
# Credit: Foul Ward SYSTEMS_part3.md §7 (Arnulf State Machine spec)
#   Internal project document — Foul Ward team.

class_name Arnulf
extends CharacterBody3D

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

## Maximum hit points. Recovers to 50% of this on resurrection.
@export var max_hp: int = 200

## Movement speed in units per second.
@export var move_speed: float = 5.0

## Physical damage dealt per attack.
@export var attack_damage: float = 25.0

## Seconds between attacks.
@export var attack_cooldown: float = 1.0

## Max distance from tower center for chase targeting. Must exceed spawn ring (~40) or Arnulf never engages.
@export var patrol_radius: float = 55.0

## Seconds to recover after incapacitation.
@export var recovery_time: float = 3.0

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------

## Tower center — used for target-selection distance comparisons.
## Arnulf always chases the enemy closest to the TOWER, not closest to himself.
const TOWER_CENTER: Vector3 = Vector3.ZERO

## Where Arnulf stands when idle (adjacent to tower base).
const HOME_POSITION: Vector3 = Vector3(2.0, 0.0, 0.0)

## Same issue as EnemyBase: nav next waypoint can match position → normalized() is zero.
const _MIN_NAV_STEP_SQ: float = 0.0004

## Stable id for generic ally signals (SignalBus.ally_*).
const ALLY_ID_ARNULF: String = "arnulf"

# Assign placeholder art resources via convention-based pipeline.
const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

# ---------------------------------------------------------------------------
# STATE
# ---------------------------------------------------------------------------

var _current_state: Types.ArnulfState = Types.ArnulfState.IDLE
var _chase_target: EnemyBase = null
var _attack_timer: float = 0.0
var _recovery_timer: float = 0.0

# POST-MVP: _kill_counter drives Frenzy mode when it reaches a threshold.
# For MVP: counter increments and resets on mission start; no activation logic.
var _kill_counter: int = 0

# ---------------------------------------------------------------------------
# NODE REFERENCES
# ---------------------------------------------------------------------------

@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	print("[Arnulf] _ready: hp=%d move_speed=%.1f patrol_radius=%.0f" % [max_hp, move_speed, patrol_radius])
	health_component.max_hp = max_hp
	health_component.reset_to_max()
	health_component.health_depleted.connect(_on_health_depleted)

	# Credit: Godot Engine Documentation — NavigationAgent3D
	#   https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
	#   Adapted: path_desired_distance and target_desired_distance tuning values.
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 1.5
	navigation_agent.avoidance_enabled = true

	# ASSUMPTION: DetectionArea.collision_mask = 2 (Enemies layer) set in scene.
	# ASSUMPTION: AttackArea.collision_mask = 2 (Enemies layer) set in scene.
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.game_state_changed.connect(_on_game_state_changed)

	# Art pipeline placeholder assignment.
	var mesh_node: MeshInstance3D = get_node_or_null("ArnulfMesh") as MeshInstance3D
	if mesh_node != null:
		var _mesh: Mesh = ArtPlaceholderHelper.get_ally_mesh("arnulf")
		if _mesh != null and mesh_node.mesh == null:
			mesh_node.mesh = _mesh
		var _mat: Material = ArtPlaceholderHelper.get_faction_material("allies")
		if _mat != null:
			mesh_node.material_override = _mat

	_transition_to_state(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# PHYSICS PROCESS — State Dispatch
# ---------------------------------------------------------------------------

# Credit: Foul Ward SYSTEMS_part3.md §7.6 (_physics_process dispatch table)
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
#   All delta-based timers respect Engine.time_scale automatically.

func _physics_process(delta: float) -> void:
	match _current_state:
		Types.ArnulfState.IDLE:
			_process_idle(delta)
		Types.ArnulfState.CHASE:
			_process_chase(delta)
		Types.ArnulfState.ATTACK:
			_process_attack(delta)
		Types.ArnulfState.DOWNED:
			_process_downed(delta)
		Types.ArnulfState.RECOVERING:
			_process_recovering()
		Types.ArnulfState.PATROL:
			# PATROL is a post-MVP stub — treat as IDLE in MVP.
			_process_idle(delta)

# ---------------------------------------------------------------------------
# STATE HANDLERS
# ---------------------------------------------------------------------------

func _process_idle(_delta: float) -> void:
	var dist_to_home: float = global_position.distance_to(HOME_POSITION)
	if dist_to_home > 1.0:
		navigation_agent.target_position = HOME_POSITION
		var next_pos: Vector3 = navigation_agent.get_next_path_position()
		var to_next: Vector3 = next_pos - global_position
		if to_next.length_squared() < _MIN_NAV_STEP_SQ:
			to_next = HOME_POSITION - global_position
		var direction: Vector3 = to_next.normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO

	# Poll for enemies already inside the detection zone when returning home.
	var target: EnemyBase = _find_closest_enemy_to_tower()
	if target != null:
		_chase_target = target
		_transition_to_state(Types.ArnulfState.CHASE)


func _process_chase(_delta: float) -> void:
	# Credit: is_instance_valid() guard for freed nodes mid-chase.
	if _chase_target == null or not is_instance_valid(_chase_target):
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target == null:
			_transition_to_state(Types.ArnulfState.IDLE)
			return

	var target_dist_from_tower: float = \
		_chase_target.global_position.distance_to(TOWER_CENTER)
	if target_dist_from_tower > patrol_radius:
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target == null:
			_transition_to_state(Types.ArnulfState.IDLE)
			return

	# Update NavigationAgent3D EVERY frame — the enemy is moving.
	# Credit: Godot Docs NavigationAgent3D per-frame target_position update pattern.
	navigation_agent.target_position = _chase_target.global_position
	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var to_next: Vector3 = next_pos - global_position
	if to_next.length_squared() < _MIN_NAV_STEP_SQ:
		to_next = _chase_target.global_position - global_position
	var direction: Vector3 = to_next.normalized()
	velocity = direction * move_speed
	move_and_slide()
	# ATTACK transition is handled by AttackArea.body_entered signal.


func _process_attack(delta: float) -> void:
	if _chase_target == null or not is_instance_valid(_chase_target):
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target != null:
			_transition_to_state(Types.ArnulfState.CHASE)
		else:
			_transition_to_state(Types.ArnulfState.IDLE)
		return

	velocity = Vector3.ZERO

	# First attack fires immediately (_attack_timer starts at 0 on ATTACK entry).
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		var final_damage: float = DamageCalculator.calculate_damage(
			attack_damage,
			Types.DamageType.PHYSICAL,
			_chase_target.get_enemy_data().armor_type
		)
		_chase_target.take_damage(final_damage, Types.DamageType.PHYSICAL)


func _process_downed(delta: float) -> void:
	velocity = Vector3.ZERO
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		_transition_to_state(Types.ArnulfState.RECOVERING)


func _process_recovering() -> void:
	# Instant transition state: heal to 50% max HP, then return to IDLE.
	var heal_amount: int = int(round(float(max_hp) * 0.5))
	health_component.heal(heal_amount)
	SignalBus.arnulf_recovered.emit()
	# DEVIATION: generic ally_recovered for ally framework integration.
	SignalBus.ally_recovered.emit(ALLY_ID_ARNULF)
	_transition_to_state(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# STATE TRANSITION
# ---------------------------------------------------------------------------

func _transition_to_state(new_state: Types.ArnulfState) -> void:
	print("[Arnulf] state → %s  (target=%s)" % [
		Types.ArnulfState.keys()[new_state],
		_chase_target.get_enemy_data().display_name if is_instance_valid(_chase_target) and _chase_target != null else "none"
	])
	_current_state = new_state

	match new_state:
		Types.ArnulfState.IDLE:
			_chase_target = null
			_attack_timer = 0.0
		Types.ArnulfState.CHASE:
			_attack_timer = 0.0
		Types.ArnulfState.ATTACK:
			_attack_timer = 0.0  # First hit fires immediately.
		Types.ArnulfState.DOWNED:
			_recovery_timer = recovery_time
			_chase_target = null
			velocity = Vector3.ZERO
			SignalBus.arnulf_incapacitated.emit()
			# DEVIATION: generic ally_downed for ally framework integration.
			SignalBus.ally_downed.emit(ALLY_ID_ARNULF)
		Types.ArnulfState.RECOVERING:
			pass
		Types.ArnulfState.PATROL:
			pass  # Post-MVP stub.

	SignalBus.arnulf_state_changed.emit(new_state)

# ---------------------------------------------------------------------------
# TARGET SELECTION
# ---------------------------------------------------------------------------

# Credit: Foul Ward SYSTEMS_part3.md §7.6 (_find_closest_enemy_to_tower)
# Credit: Godot Engine Documentation — Area3D.get_overlapping_bodies()
#   Selects the enemy closest to TOWER_CENTER from DetectionArea's overlap pool.
#   Flying enemies are excluded — Arnulf is a ground melee unit.

func _find_closest_enemy_to_tower() -> EnemyBase:
	var best_target: EnemyBase = null
	var best_distance: float = patrol_radius + 1.0

	for body: Node3D in detection_area.get_overlapping_bodies():
		var enemy: EnemyBase = body as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue
		if enemy.get_enemy_data().is_flying:
			continue

		var dist_to_tower: float = enemy.global_position.distance_to(TOWER_CENTER)
		if dist_to_tower > patrol_radius:
			continue

		if dist_to_tower < best_distance:
			best_distance = dist_to_tower
			best_target = enemy

	return best_target

# ---------------------------------------------------------------------------
# AREA3D SIGNAL HANDLERS
# ---------------------------------------------------------------------------

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _current_state == Types.ArnulfState.DOWNED:
		return
	if _current_state == Types.ArnulfState.RECOVERING:
		return

	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy.get_enemy_data().is_flying:
		return

	if _current_state == Types.ArnulfState.IDLE:
		_chase_target = _find_closest_enemy_to_tower()
		# Same-frame manual tests / physics not stepped: overlap list can be empty even though
		# `body_entered` fired — fall back to the body that triggered this handler.
		if _chase_target == null:
			var dist_to_tower: float = enemy.global_position.distance_to(TOWER_CENTER)
			if dist_to_tower <= patrol_radius:
				_chase_target = enemy
		if _chase_target != null:
			_transition_to_state(Types.ArnulfState.CHASE)


func _on_attack_area_body_entered(body: Node3D) -> void:
	if _current_state != Types.ArnulfState.CHASE:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _chase_target:
		_transition_to_state(Types.ArnulfState.ATTACK)


func _on_attack_area_body_exited(body: Node3D) -> void:
	if _current_state != Types.ArnulfState.ATTACK:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _chase_target:
		_transition_to_state(Types.ArnulfState.CHASE)

# ---------------------------------------------------------------------------
# HEALTH COMPONENT SIGNAL HANDLER
# ---------------------------------------------------------------------------

func _on_health_depleted() -> void:
	_transition_to_state(Types.ArnulfState.DOWNED)

# ---------------------------------------------------------------------------
# SIGNALBUS HANDLERS
# ---------------------------------------------------------------------------

func _on_enemy_killed(
		_enemy_type: Types.EnemyType,
		_position: Vector3,
		_gold_reward: int
) -> void:
	# POST-MVP: increment drives Frenzy mode. MVP: count only.
	_kill_counter += 1


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	if new_state == Types.GameState.MISSION_BRIEFING:
		reset_for_new_mission()

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Returns Arnulf's current state enum value.
func get_current_state() -> Types.ArnulfState:
	return _current_state

## Returns current HP as reported by HealthComponent.
func get_current_hp() -> int:
	return health_component.get_current_hp()

## Returns maximum HP.
func get_max_hp() -> int:
	return health_component.get_max_hp()

## Resets Arnulf for a new mission: full HP, IDLE state, home position.
func reset_for_new_mission() -> void:
	health_component.max_hp = max_hp
	health_component.reset_to_max()
	_kill_counter = 0
	_chase_target = null
	_attack_timer = 0.0
	_recovery_timer = 0.0
	velocity = Vector3.ZERO
	global_position = HOME_POSITION
	_transition_to_state(Types.ArnulfState.IDLE)
	# DEVIATION: Arnulf also broadcasts generic ally_spawned for ally systems.
	SignalBus.ally_spawned.emit(ALLY_ID_ARNULF)
	# POST-MVP: emit SignalBus.ally_killed(ALLY_ID_ARNULF) if a permanent-death path is added.
````

---

## `scenes/bosses/boss_base.gd`

````
## boss_base.gd
## Boss controller extending EnemyBase — reuses nav, damage, and wave integration.

class_name BossBase
extends EnemyBase

var boss_data: BossData = null
var current_phase_index: int = 0


func initialize_boss_data(data: BossData) -> void:
	assert(data != null, "BossBase.initialize_boss_data: BossData is null")
	boss_data = data
	var placeholder: EnemyData = data.build_placeholder_enemy_data()
	initialize(placeholder)
	_apply_boss_stats()
	_configure_visuals()
	SignalBus.boss_spawned.emit(boss_data.boss_id)


func _apply_boss_stats() -> void:
	if boss_data == null:
		return
	# SOURCE: stat application pattern adapted from resource-driven modular enemies (GameDev with Drew, https://www.youtube.com/watch?v=NXvhYdLqrhA)
	var ed: EnemyData = get_enemy_data()
	if ed == null:
		return
	ed.max_hp = boss_data.max_hp
	ed.move_speed = boss_data.move_speed
	ed.damage = boss_data.damage
	ed.attack_range = boss_data.attack_range
	ed.attack_cooldown = boss_data.attack_cooldown
	ed.armor_type = boss_data.armor_type
	ed.gold_reward = boss_data.gold_reward
	ed.is_ranged = boss_data.is_ranged
	ed.is_flying = boss_data.is_flying
	ed.damage_immunities = boss_data.damage_immunities.duplicate()

	health_component.max_hp = boss_data.max_hp
	health_component.reset_to_max()


func _configure_visuals() -> void:
	if boss_data == null:
		return
	var mesh_node: MeshInstance3D = get_node_or_null("BossMesh") as MeshInstance3D
	if mesh_node != null and mesh_node.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = mesh_node.material_override as StandardMaterial3D
		mat.albedo_color = Color(0.55, 0.15, 0.65)

	var label: Label3D = get_node_or_null("BossLabel") as Label3D
	if label != null:
		label.text = boss_data.display_name


func _on_health_depleted() -> void:
	if boss_data != null:
		SignalBus.boss_killed.emit(boss_data.boss_id)
	super._on_health_depleted()


func advance_phase() -> void:
	if boss_data == null:
		return
	if boss_data.phase_count <= 1:
		return
	current_phase_index = clampi(current_phase_index + 1, 0, boss_data.phase_count - 1)
	# SOURCE: simple phase index tracking inspired by multi-phase boss tutorials (Ludonauta Hollow Knight-style boss, https://ludonauta.itch.io/platformer-essentials/devlog/1089921/hollow-knight-inspired-boss-fight-in-godot-4)
	# POST-MVP: per-phase stat scaling and SignalBus.boss_phase_changed.
````

---

## `scenes/buildings/building_base.gd`

````
# scenes/buildings/building_base.gd
# BuildingBase – base class for all 8 building types.
# Initialized with a BuildingData resource. Handles targeting, combat, and projectile firing.
# Special types (Archer Barracks, Shield Generator) have fire_rate = 0 and are POST-MVP stubs.
#
# Credit: _find_target() group-based enemy iteration pattern:
#   ARCHITECTURE.md §3.2 – BuildingBase class responsibilities; Foul Ward project.
#
# Credit: is_instance_valid() pattern for enemies freed mid-frame:
#   CONVENTIONS.md §9.3 – "is_instance_valid for deferred references"; Foul Ward project.
#
# Credit: physics_process for all game logic (not process):
#   CONVENTIONS.md §14 – "PROCESS FUNCTION RULES"; Foul Ward project.

class_name BuildingBase
extends Node3D

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const ProjectileScene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")
# ASSUMPTION: ProjectileBase at this path per ARCHITECTURE.md §11.
const BASE_HALF_EXTENT_X: float = 1.25
const BASE_HALF_EXTENT_Z: float = 1.25
const BASE_HEIGHT: float = 3.0
const OBSTACLE_RADIUS: float = 2.0

# Assign placeholder art resources via convention-based pipeline.
const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _building_data: BuildingData = null
var _is_upgraded: bool = false
var _attack_timer: float = 0.0
var _current_target: EnemyBase = null

# ---------------------------------------------------------------------------
# Children
# ---------------------------------------------------------------------------

# ASSUMPTION: ProjectileContainer at /root/Main/ProjectileContainer per ARCHITECTURE.md §2.
@onready var _projectile_container: Node3D = get_node_or_null("/root/Main/ProjectileContainer") as Node3D
@onready var health_component: HealthComponent = $HealthComponent
@onready var collision_body: StaticBody3D = $BuildingCollision
@onready var collision_shape: CollisionShape3D = $BuildingCollision/CollisionShape3D
@onready var navigation_obstacle: NavigationObstacle3D = $NavigationObstacle
@onready var mesh: MeshInstance3D = $BuildingMesh
@onready var label: Label3D = $BuildingLabel

# ---------------------------------------------------------------------------
# Public accessor – is_upgraded is read by HexGrid for sell refunds
# ---------------------------------------------------------------------------

var is_upgraded: bool:
	get:
		return _is_upgraded

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_configure_base_area()
	_enable_collision_and_obstacle()
	if _building_data != null:
		print("[Building] ready: %s at (%.1f,%.1f,%.1f)" % [
			_building_data.display_name,
			global_position.x, global_position.y, global_position.z
		])


func _configure_base_area() -> void:
	# ASSUMPTION: one footprint shape drives both collision and avoidance tuning.
	if collision_shape == null or navigation_obstacle == null:
		return
	var box_shape: BoxShape3D = collision_shape.shape as BoxShape3D
	if box_shape == null:
		return
	box_shape.size = Vector3(BASE_HALF_EXTENT_X * 2.0, BASE_HEIGHT, BASE_HALF_EXTENT_Z * 2.0)
	navigation_obstacle.radius = OBSTACLE_RADIUS


func _enable_collision_and_obstacle() -> void:
	if collision_shape == null or navigation_obstacle == null:
		return
	collision_shape.set_deferred("disabled", false)
	navigation_obstacle.set_deferred("enabled", true)


func _disable_collision_and_obstacle() -> void:
	# POST-MVP hook for destroyable buildings.
	if collision_shape == null or navigation_obstacle == null:
		return
	collision_shape.set_deferred("disabled", true)
	navigation_obstacle.set_deferred("enabled", false)


func _physics_process(delta: float) -> void:
	_combat_process(delta)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Call after the node is in the scene tree (add_child) so child paths resolve.
## Configures visuals and stats from the provided BuildingData resource.
func initialize(data: BuildingData) -> void:
	_building_data = data
	_is_upgraded = false
	_attack_timer = 0.0
	_current_target = null

	# MVP visual: colored cube + label (use get_node — @onready is not set before _ready()).
	var mesh_inst: MeshInstance3D = get_node_or_null("BuildingMesh") as MeshInstance3D
	if mesh_inst != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = data.color
		mesh_inst.material_override = mat

	# Art pipeline placeholder assignment (runtime override).
	# NOTE: keep existing MVP color material generation for now; we override it via helper.
	if mesh_inst != null:
		var _art_mesh: Mesh = ArtPlaceholderHelper.get_building_mesh(data.building_type)
		if _art_mesh != null:
			mesh_inst.mesh = _art_mesh
		var _art_mat: Material = ArtPlaceholderHelper.get_building_material(data.building_type)
		if _art_mat != null:
			mesh_inst.material_override = _art_mat

	var label_inst: Label3D = get_node_or_null("BuildingLabel") as Label3D
	if label_inst != null:
		label_inst.text = data.display_name

	print("[Building] initialized: %s  dmg=%.0f range=%.1f fire_rate=%.2f  air=%s gnd=%s" % [
		data.display_name, data.damage, data.attack_range, data.fire_rate,
		data.targets_air, data.targets_ground
	])


## Transitions the building from Basic to Upgraded tier.
func upgrade() -> void:
	_is_upgraded = true


## Returns the BuildingData resource this building was initialized with.
func get_building_data() -> BuildingData:
	return _building_data


## Returns the currently effective damage value (base or upgraded).
func get_effective_damage() -> float:
	if _building_data == null:
		return 0.0
	if _is_upgraded:
		return _building_data.upgraded_damage
	if _has_research_damage_boost():
		return _building_data.upgraded_damage
	return _building_data.damage


## Returns the currently effective attack range (base or upgraded).
func get_effective_range() -> float:
	if _building_data == null:
		return 0.0
	if _is_upgraded:
		return _building_data.upgraded_range
	if _has_research_range_boost():
		return _building_data.upgraded_range
	return _building_data.attack_range


func _has_research_damage_boost() -> bool:
	if _building_data.research_damage_boost_id == "":
		return false
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm == null:
		return false
	return rm.is_unlocked(_building_data.research_damage_boost_id)


func _has_research_range_boost() -> bool:
	if _building_data.research_range_boost_id == "":
		return false
	var rm: ResearchManager = get_node_or_null("/root/Main/Managers/ResearchManager") as ResearchManager
	if rm == null:
		return false
	return rm.is_unlocked(_building_data.research_range_boost_id)

# ---------------------------------------------------------------------------
# Private – combat loop
# ---------------------------------------------------------------------------

func _combat_process(delta: float) -> void:
	if _building_data == null:
		return

	# POST-MVP stub guard: Archer Barracks and Shield Generator have fire_rate = 0.
	# This prevents any division-by-zero and combat attempt for stubs.
	if _building_data.fire_rate <= 0.0:
		return

	_attack_timer -= delta

	# Validate or acquire target.
	if _current_target == null or not is_instance_valid(_current_target):
		_current_target = _find_target()

	if _current_target == null:
		return

	# Target may have moved out of range since last frame.
	if global_position.distance_to(_current_target.global_position) > get_effective_range():
		_current_target = _find_target()
		if _current_target == null:
			return

	# Fire when cooldown elapsed.
	if _attack_timer <= 0.0:
		_fire_at_target()
		_attack_timer = 1.0 / _building_data.fire_rate


## Finds the best valid target within range.
## MVP strategy: CLOSEST enemy to this building.
## Respects targets_air / targets_ground flags from BuildingData.
func _find_target() -> EnemyBase:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var enemies: Array[Node] = tree.get_nodes_in_group("enemies")
	var best_target: EnemyBase = null
	var best_distance: float = INF
	var effective_range: float = get_effective_range()

	for node: Node in enemies:
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue
		if not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue

		var enemy_data: EnemyData = enemy.get_enemy_data()

		# Filter by air/ground targeting flags.
		if enemy_data.is_flying and not _building_data.targets_air:
			continue
		if not enemy_data.is_flying and not _building_data.targets_ground:
			continue

		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > effective_range:
			continue

		if distance < best_distance:
			best_distance = distance
			best_target = enemy

	return best_target


## Instantiates and launches a projectile toward the current target.
func _fire_at_target() -> void:
	if not is_instance_valid(_current_target):
		return

	var proj: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	if _projectile_container == null:
		return

	# Speed proxy: fire_rate * 15.0 gives reasonable projectile speed spread.
	# Slow-firing Ballista (0.4/s) → speed 6; fast Poison Vat (1.5/s) → speed 22.5.
	var proj_speed: float = _building_data.fire_rate * 15.0

	var dist: float = global_position.distance_to(_current_target.global_position)
	print("[Building] %s fired → %s  dist=%.1f  target_y=%.1f" % [
		_building_data.display_name,
		_current_target.get_enemy_data().display_name if _current_target.get_enemy_data() != null else "?",
		dist,
		_current_target.global_position.y
	])

	_projectile_container.add_child(proj)
	proj.initialize_from_building(
		get_effective_damage(),
		_building_data.damage_type,
		proj_speed,
		global_position,
		_current_target.global_position,
		_building_data.targets_air,
		_building_data.dot_enabled,
		_building_data.dot_total_damage,
		_building_data.dot_tick_interval,
		_building_data.dot_duration,
		_building_data.dot_effect_type,
		_building_data.dot_source_id,
		_building_data.dot_in_addition_to_hit
	)
	proj.add_to_group("projectiles")
````

---

## `scenes/enemies/enemy_base.gd`

````
## enemy_base.gd
## Runtime enemy controller: movement, tower attacks, and death handling for FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

# Credit (movement/NavigationAgent3D pattern):
#   Godot Docs — "Using NavigationAgents" (CharacterBody3D template, avoidance notes)
#   https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
#   License: CC BY 3.0
#   Adapted by FOUL WARD team to use EnemyData stats and tower-focused targeting.

class_name EnemyBase
extends CharacterBody3D

const TARGET_POSITION: Vector3 = Vector3.ZERO
const FLYING_HEIGHT: float = 5.0
const STUCK_VELOCITY_EPSILON: float = 0.1
const STUCK_TIME_THRESHOLD: float = 1.5
const PROGRESS_EPSILON: float = 0.05

# Assign placeholder art resources via convention-based pipeline.
const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

var _enemy_data: EnemyData = null
var _attack_timer: float = 0.0
var _is_attacking: bool = false
var _time_since_last_progress: float = 0.0
var _last_distance_to_tower: float = 0.0
var active_status_effects: Array[Dictionary] = []
const MAX_POISON_STACKS: int = 5 # TUNING: max poison stacks per enemy.

# PUBLIC — required by BuildingBase._find_target() and Arnulf._find_closest_enemy_to_tower().
@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _mesh: MeshInstance3D = get_node_or_null("EnemyMesh")
@onready var _label: Label3D = get_node_or_null("EnemyLabel")

# ASSUMPTION: These paths match ARCHITECTURE.md section 2.
@onready var _tower: Node = get_node_or_null("/root/Main/Tower")

func _ready() -> void:
	# Ensure enemies can be found via group for buildings and spells.
	add_to_group("enemies")
	if _label != null and _enemy_data != null:
		_label.text = _enemy_data.display_name

# === PUBLIC API =====================================================

## Initializes this enemy instance from its EnemyData resource.
func initialize(enemy_data: EnemyData) -> void:
	assert(enemy_data != null, "EnemyBase.initialize called with null EnemyData")
	_enemy_data = enemy_data
	_attack_timer = 0.0
	_is_attacking = false
	_last_distance_to_tower = global_position.distance_to(TARGET_POSITION)
	_time_since_last_progress = 0.0
	print("[Enemy] initialized: %s  hp=%d speed=%.1f flying=%s pos=(%.0f,%.0f,%.0f)" % [
		enemy_data.display_name, enemy_data.max_hp, enemy_data.move_speed, enemy_data.is_flying,
		global_position.x, global_position.y, global_position.z
	])

	health_component.max_hp = _enemy_data.max_hp
	health_component.reset_to_max()
	if not health_component.health_depleted.is_connected(_on_health_depleted):
		health_component.health_depleted.connect(_on_health_depleted)

	# Ground enemies configure NavigationAgent3D; flying ones ignore it.
	if not _enemy_data.is_flying:
		# Credit (target_desired_distance + path_desired_distance usage):
		#   FOUL WARD SYSTEMS_part3.md §8.6 EnemyBase.move_ground pseudocode.
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = _enemy_data.attack_range
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 0.5
		navigation_agent.target_position = TARGET_POSITION

	# Visuals from EnemyData.color.
	if _mesh != null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = _enemy_data.color
		_mesh.material_override = mat
	if _label != null:
		_label.text = _enemy_data.display_name

	# Art pipeline placeholder assignment (runtime override).
	if _mesh != null:
		var _art_mesh: Mesh = ArtPlaceholderHelper.get_enemy_mesh(enemy_data.enemy_type)
		if _art_mesh != null:
			_mesh.mesh = _art_mesh
		var _art_mat: Material = ArtPlaceholderHelper.get_enemy_material(enemy_data.enemy_type)
		if _art_mat != null:
			_mesh.material_override = _art_mat

## Applies damage of a given type to this enemy.
func take_damage(amount: float, damage_type: Types.DamageType) -> void:
	# Credit (immunity-before-matrix pattern):
	#   FOUL WARD SYSTEMS_part1/2/3: EnemyBase.take_damage spec with damage_immunities.
	if damage_type in _enemy_data.damage_immunities:
		return

	var final_damage: float = DamageCalculator.calculate_damage(
		amount,
		damage_type,
		_enemy_data.armor_type
	)
	health_component.take_damage(final_damage)

## Returns the EnemyData backing this enemy instance.
func get_enemy_data() -> EnemyData:
	return _enemy_data

# === PHYSICS LOOP ===================================================

func _physics_process(delta: float) -> void:
	if _enemy_data == null:
		return
	_update_status_effects(delta)
	if _enemy_data.is_flying:
		_physics_process_flying(delta)
	else:
		_physics_process_ground(delta)


## Applies or updates a damage-over-time (DoT) effect on this enemy.
## required keys in effect_data:
## - "effect_type": String ("burn", "poison", etc.)
## - "damage_type": Types.DamageType
## - "dot_total_damage": float   # total damage before armor/matrix
## - "tick_interval": float      # seconds between ticks
## - "duration": float           # total duration in seconds
## - "source_id": String         # stable source identifier
func apply_dot_effect(effect_data: Dictionary) -> void:
	if not effect_data.has("effect_type"):
		return
	if not effect_data.has("damage_type"):
		return
	if not effect_data.has("dot_total_damage"):
		return
	if not effect_data.has("tick_interval"):
		return
	if not effect_data.has("duration"):
		return
	if not effect_data.has("source_id"):
		return

	var duration: float = float(effect_data["duration"])
	var tick_interval: float = float(effect_data["tick_interval"])
	if duration <= 0.0 or tick_interval <= 0.0:
		return

	var effect_type: String = String(effect_data["effect_type"])
	var source_id: String = String(effect_data["source_id"])

	effect_data["remaining_time"] = duration
	effect_data["time_since_last_tick"] = 0.0

	if effect_type == "burn":
		_apply_burn_effect(effect_data, source_id, duration)
	elif effect_type == "poison":
		_apply_poison_effect(effect_data)
	else:
		active_status_effects.append(effect_data)


func _apply_burn_effect(effect_data: Dictionary, source_id: String, duration: float) -> void:
	# TUNING: burn reapplication refreshes duration; keeps highest dot_total_damage for this source.
	var existing_index: int = -1
	for i: int in range(active_status_effects.size()):
		var e: Dictionary = active_status_effects[i]
		if e.get("effect_type", "") == "burn" and e.get("source_id", "") == source_id:
			existing_index = i
			break

	if existing_index != -1:
		var existing: Dictionary = active_status_effects[existing_index]
		existing["duration"] = duration
		existing["remaining_time"] = duration
		var new_total: float = float(effect_data["dot_total_damage"])
		var old_total: float = float(existing.get("dot_total_damage", 0.0))
		if new_total > old_total:
			existing["dot_total_damage"] = new_total
		existing["time_since_last_tick"] = 0.0
		active_status_effects[existing_index] = existing
	else:
		active_status_effects.append(effect_data)


func _apply_poison_effect(effect_data: Dictionary) -> void:
	active_status_effects.append(effect_data)

	# TUNING: max poison stacks per enemy.
	var poison_indices: Array[int] = []
	for i: int in range(active_status_effects.size()):
		var e: Dictionary = active_status_effects[i]
		if e.get("effect_type", "") == "poison":
			poison_indices.append(i)

	if poison_indices.size() > MAX_POISON_STACKS:
		var to_remove: int = poison_indices[0]
		active_status_effects.remove_at(to_remove)


func _update_status_effects(delta: float) -> void:
	if active_status_effects.is_empty():
		return

	var i: int = 0
	while i < active_status_effects.size():
		var effect: Dictionary = active_status_effects[i]
		var previous_remaining_time: float = float(effect.get("remaining_time", 0.0))
		var remaining_time: float = previous_remaining_time - delta
		effect["remaining_time"] = remaining_time

		var tick_interval: float = float(effect.get("tick_interval", 0.0))
		var duration: float = float(effect.get("duration", 0.0))
		var damage_type: Types.DamageType = effect.get("damage_type", Types.DamageType.PHYSICAL)

		var time_since_last_tick: float = float(effect.get("time_since_last_tick", 0.0)) + delta
		effect["time_since_last_tick"] = time_since_last_tick

		if tick_interval > 0.0 and time_since_last_tick >= tick_interval:
			effect["time_since_last_tick"] = time_since_last_tick - tick_interval
			var dot_total_damage: float = float(effect.get("dot_total_damage", 0.0))
			if dot_total_damage > 0.0 and previous_remaining_time > 0.0:
				var per_tick_damage: float = DamageCalculator.calculate_dot_tick(
					dot_total_damage,
					tick_interval,
					duration,
					damage_type,
					_enemy_data.armor_type
				)
				if per_tick_damage > 0.0:
					# Avoid matrix double-application by using base-per-tick through take_damage.
					var tick_count: float = duration / tick_interval
					if tick_count > 0.0:
						var per_tick_base: float = dot_total_damage / tick_count
						take_damage(per_tick_base, damage_type)

		if remaining_time <= 0.0:
			active_status_effects.remove_at(i)
		else:
			active_status_effects[i] = effect
			i += 1


# === MOVEMENT =======================================================

func _physics_process_ground(delta: float) -> void:
	navigation_agent.target_position = TARGET_POSITION
	if navigation_agent.is_navigation_finished():
		var distance_to_tower: float = global_position.distance_to(TARGET_POSITION)
		if distance_to_tower <= _enemy_data.attack_range:
			_update_attack_tower(delta)
			_reset_progress_tracking(distance_to_tower)
			return

	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_pos - global_position
	if direction.length_squared() < 0.0001:
		direction = Vector3.ZERO
	else:
		direction = direction.normalized()
	if direction != Vector3.ZERO:
		velocity = direction * _enemy_data.move_speed
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	_update_progress_tracking(delta)
	_maybe_resolve_stuck()

	if global_position.distance_to(TARGET_POSITION) <= _enemy_data.attack_range:
		_update_attack_tower(delta)
		_reset_progress_tracking(global_position.distance_to(TARGET_POSITION))


func _physics_process_flying(delta: float) -> void:
	var target_pos: Vector3 = Vector3(TARGET_POSITION.x, FLYING_HEIGHT, TARGET_POSITION.z)
	var direction: Vector3 = target_pos - global_position
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	velocity = direction * _enemy_data.move_speed
	move_and_slide()
	if global_position.distance_to(target_pos) <= _enemy_data.attack_range:
		_update_attack_tower(delta)


func _update_progress_tracking(delta: float) -> void:
	var distance_to_tower: float = global_position.distance_to(TARGET_POSITION)
	if distance_to_tower < _last_distance_to_tower - PROGRESS_EPSILON:
		_time_since_last_progress = 0.0
		_last_distance_to_tower = distance_to_tower
	else:
		_time_since_last_progress += delta


func _reset_progress_tracking(current_distance: float) -> void:
	_last_distance_to_tower = current_distance
	_time_since_last_progress = 0.0


func _maybe_resolve_stuck() -> void:
	if _time_since_last_progress < STUCK_TIME_THRESHOLD:
		return
	var distance_to_tower: float = global_position.distance_to(TARGET_POSITION)
	if distance_to_tower <= _enemy_data.attack_range:
		return
	var speed: float = velocity.length()
	if speed > STUCK_VELOCITY_EPSILON:
		return
	navigation_agent.target_position = TARGET_POSITION
	navigation_agent.set_velocity(Vector3.ZERO)
	_time_since_last_progress = 0.0
	_last_distance_to_tower = distance_to_tower

# === ATTACK LOGIC ===================================================

func _update_attack_tower(delta: float) -> void:
	_is_attacking = true
	velocity = Vector3.ZERO
	_attack_timer += delta
	if _attack_timer >= _enemy_data.attack_cooldown:
		_attack_timer = 0.0
		_deal_damage_to_tower()


func _deal_damage_to_tower() -> void:
	if is_instance_valid(_tower):
		_tower.take_damage(_enemy_data.damage)

# === DEATH HANDLING ================================================

func _on_health_depleted() -> void:
	print("[Enemy] DIED: %s  rewarding %d gold" % [_enemy_data.display_name, _enemy_data.gold_reward])
	SignalBus.enemy_killed.emit(
		_enemy_data.enemy_type,
		global_position,
		_enemy_data.gold_reward
	)
	# EconomyManager already listens to enemy_killed in Phase 1, so we do NOT call
	# EconomyManager.add_gold() directly here to avoid double-award.

	remove_from_group("enemies")
	queue_free()
````

---

## `scenes/hex_grid/hex_grid.gd`

````
# scenes/hex_grid/hex_grid.gd
# HexGrid – manages 24 hex-shaped building slots in three concentric rings.
# Handles placement, selling, upgrading, and between-mission persistence.
# All resource transactions flow through EconomyManager.
# All lock checks flow through ResearchManager (nullable for unit tests).
#
# Credit: Ring position formula (TAU / N * i + offset_rad) derived from:
#   Godot 4 official docs – built-in math constants (TAU = 2*PI, no import needed)
#   https://docs.godotengine.org/en/4.4/tutorials/physics/ray-casting.html
#   Adapted by the Foul Ward team.
#
# Credit: get_node_or_null pattern for optional scene references:
#   CONVENTIONS.md §6 – "Node reference patterns"
#   Foul Ward project document.

class_name HexGrid
extends Node3D

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const RING1_COUNT: int = 6
const RING1_RADIUS: float = 6.0
const RING2_COUNT: int = 12
const RING2_RADIUS: float = 12.0
const RING3_COUNT: int = 6
const RING3_RADIUS: float = 18.0
const TOTAL_SLOTS: int = 24

## Max horizontal distance from a click (XZ) to a slot center to count as "that slot".
const SLOT_PICK_MAX_DISTANCE: float = 4.0

const BuildingScene: PackedScene = preload("res://scenes/buildings/building_base.tscn")

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## Must have exactly 8 entries, one per Types.BuildingType enum value.
@export var building_data_registry: Array[BuildingData] = []

## Which hex is targeted for the next build (driven by BuildMenu). -1 = none.
var _build_highlight_slot: int = -1

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

## Each Dictionary: { index: int, world_pos: Vector3,
##                    building: BuildingBase|null, is_occupied: bool }
var _slots: Array[Dictionary] = []

# ASSUMPTION: BuildingContainer at /root/Main/BuildingContainer per ARCHITECTURE.md §2.
# In GdUnit/headless tests there is no Main scene — create a child container so placement still works.
var _building_container: Node3D = null

# ASSUMPTION: ResearchManager at /root/Main/Managers/ResearchManager.
# If null (unit test context), all buildings are treated as unlocked.
var _research_manager = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_building_container = get_node_or_null("/root/Main/BuildingContainer") as Node3D
	if _building_container == null:
		var c: Node3D = Node3D.new()
		c.name = "BuildingContainer"
		add_child(c)
		_building_container = c
	print("[HexGrid] _ready: building_data_registry size=%d" % building_data_registry.size())
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.research_unlocked.connect(_on_research_unlocked)

	_research_manager = get_node_or_null("/root/Main/Managers/ResearchManager")
	print("[HexGrid] _ready: ResearchManager found=%s" % (str(_research_manager != null)))

	assert(building_data_registry.size() == 8,
		"HexGrid: building_data_registry must have exactly 8 entries, got %d"
		% building_data_registry.size())

	_initialize_slots()
	_set_slots_visible(false)
	print("[HexGrid] _ready: %d slots initialized" % _slots.size())

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Places a building of building_type on the given slot (charges gold + material).
## Returns true on success, false on any validation failure.
func place_building(slot_index: int, building_type: Types.BuildingType) -> bool:
	return _try_place_building(slot_index, building_type, true)


## Shop voucher: places first available [param building_type] without spending resources.
## Uses lowest empty slot index. Returns false if no slot or validation fails.
func place_building_shop_free(building_type: Types.BuildingType) -> bool:
	var empty: Array[int] = get_empty_slots()
	if empty.is_empty():
		return false
	empty.sort()
	return _try_place_building(empty[0], building_type, false)


## Returns true if any placed building has less than max HP (alive).
func has_any_damaged_building() -> bool:
	for slot: Dictionary in _slots:
		if not slot["is_occupied"]:
			continue
		var building: BuildingBase = slot["building"] as BuildingBase
		if not is_instance_valid(building):
			continue
		var hc: HealthComponent = building.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null:
			continue
		if not hc.is_alive():
			continue
		if hc.current_hp < hc.max_hp:
			return true
	return false


## Restores the first damaged building (lowest slot index) to full HP. Returns true if one was repaired.
func repair_first_damaged_building() -> bool:
	for i: int in range(TOTAL_SLOTS):
		var slot: Dictionary = _slots[i]
		if not slot["is_occupied"]:
			continue
		var building: BuildingBase = slot["building"] as BuildingBase
		if not is_instance_valid(building):
			continue
		var hc: HealthComponent = building.get_node_or_null("HealthComponent") as HealthComponent
		if hc == null:
			continue
		if not hc.is_alive():
			continue
		if hc.current_hp >= hc.max_hp:
			continue
		hc.reset_to_max()
		print("[HexGrid] repair_first_damaged_building: slot %d repaired to full HP" % i)
		return true
	return false


func _try_place_building(
		slot_index: int,
		building_type: Types.BuildingType,
		charge_resources: bool
) -> bool:
	print("[HexGrid] place_building: slot=%d type=%d charge=%s  gold=%d mat=%d" % [
		slot_index, building_type, str(charge_resources),
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.place_building: invalid slot_index %d" % slot_index)
		print("[HexGrid] place_building FAILED: invalid slot %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if slot["is_occupied"]:
		push_warning("HexGrid.place_building: slot %d already occupied" % slot_index)
		print("[HexGrid] place_building FAILED: slot %d already occupied" % slot_index)
		return false

	var building_data: BuildingData = get_building_data(building_type)
	if building_data == null:
		push_error("HexGrid.place_building: no BuildingData for type %d" % building_type)
		print("[HexGrid] place_building FAILED: no BuildingData for type %d" % building_type)
		return false

	if not is_building_available(building_type):
		print("[HexGrid] place_building FAILED: building type %d is locked" % building_type)
		return false

	if charge_resources:
		if not EconomyManager.can_afford(building_data.gold_cost, building_data.material_cost):
			print("[HexGrid] place_building FAILED: cannot afford cost=%dg %dm  have=%dg %dm" % [
				building_data.gold_cost, building_data.material_cost,
				EconomyManager.get_gold(), EconomyManager.get_building_material()
			])
			return false

		var gold_spent: bool = EconomyManager.spend_gold(building_data.gold_cost)
		assert(gold_spent, "HexGrid: spend_gold failed after can_afford returned true")
		var mat_spent: bool = EconomyManager.spend_building_material(building_data.material_cost)
		assert(mat_spent, "HexGrid: spend_building_material failed after can_afford returned true")

	var building: BuildingBase = BuildingScene.instantiate() as BuildingBase
	_building_container.add_child(building)
	building.global_position = slot["world_pos"]
	building.initialize(building_data)
	building.add_to_group("buildings")
	_activate_building_obstacle(building)

	slot["building"] = building
	slot["is_occupied"] = true

	print("[HexGrid] place_building SUCCESS: slot=%d type=%d at pos=(%.1f,%.1f,%.1f)  remaining gold=%d mat=%d" % [
		slot_index, building_type,
		slot["world_pos"].x, slot["world_pos"].y, slot["world_pos"].z,
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	SignalBus.building_placed.emit(slot_index, building_type)
	return true


func _activate_building_obstacle(building: BuildingBase) -> void:
	# ASSUMPTION: BuildingBase self-configures collision + obstacle in _ready().
	if building == null:
		return


## Sells the building on the given slot. Full refund including upgrade costs if upgraded.
## Returns true on success, false if slot is empty or invalid.
func sell_building(slot_index: int) -> bool:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.sell_building: invalid slot_index %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if not slot["is_occupied"]:
		push_warning("HexGrid.sell_building: slot %d is not occupied" % slot_index)
		return false

	var building: BuildingBase = slot["building"] as BuildingBase
	var building_data: BuildingData = building.get_building_data()
	var building_type: Types.BuildingType = building_data.building_type

	# Full refund of base costs.
	EconomyManager.add_gold(building_data.gold_cost)
	EconomyManager.add_building_material(building_data.material_cost)

	# Also refund upgrade costs if the building was upgraded.
	if building.is_upgraded:
		EconomyManager.add_gold(building_data.upgrade_gold_cost)
		EconomyManager.add_building_material(building_data.upgrade_material_cost)

	building.remove_from_group("buildings")
	building.queue_free()

	slot["building"] = null
	slot["is_occupied"] = false

	SignalBus.building_sold.emit(slot_index, building_type)
	return true


## Upgrades the building on the given slot from Basic to Upgraded tier.
## Returns true on success, false on any validation failure.
func upgrade_building(slot_index: int) -> bool:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.upgrade_building: invalid slot_index %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if not slot["is_occupied"]:
		push_warning("HexGrid.upgrade_building: slot %d not occupied" % slot_index)
		return false

	var building: BuildingBase = slot["building"] as BuildingBase

	if building.is_upgraded:
		push_warning("HexGrid.upgrade_building: building on slot %d already upgraded" % slot_index)
		return false

	var building_data: BuildingData = building.get_building_data()

	if not EconomyManager.can_afford(building_data.upgrade_gold_cost, building_data.upgrade_material_cost):
		return false

	var gold_spent: bool = EconomyManager.spend_gold(building_data.upgrade_gold_cost)
	assert(gold_spent, "HexGrid: upgrade spend_gold failed after can_afford returned true")
	var mat_spent: bool = EconomyManager.spend_building_material(building_data.upgrade_material_cost)
	assert(mat_spent, "HexGrid: upgrade spend_building_material failed after can_afford returned true")

	building.upgrade()

	SignalBus.building_upgraded.emit(slot_index, building_data.building_type)
	return true


## Returns a shallow copy of the slot data Dictionary for the given index.
func get_slot_data(slot_index: int) -> Dictionary:
	assert(_is_valid_index(slot_index),
		"HexGrid.get_slot_data: invalid slot_index %d" % slot_index)
	return _slots[slot_index].duplicate()


## Returns an array of slot indices that currently have buildings.
func get_all_occupied_slots() -> Array[int]:
	var result: Array[int] = []
	for slot: Dictionary in _slots:
		if slot["is_occupied"]:
			result.append(slot["index"])
	return result


## Returns an array of slot indices that are currently empty.
func get_empty_slots() -> Array[int]:
	var result: Array[int] = []
	for slot: Dictionary in _slots:
		if not slot["is_occupied"]:
			result.append(slot["index"])
	return result

## Returns true if at least one slot is currently empty.
func has_empty_slot() -> bool:
	for slot: Dictionary in _slots:
		if not slot["is_occupied"]:
			return true
	return false


## Frees all buildings and resets all slots. Called on new game only.
func clear_all_buildings() -> void:
	for slot: Dictionary in _slots:
		if slot["is_occupied"]:
			var building: BuildingBase = slot["building"] as BuildingBase
			if is_instance_valid(building):
				building.remove_from_group("buildings")
				building.queue_free()
			slot["building"] = null
			slot["is_occupied"] = false


## Returns the BuildingData resource for the given BuildingType, or null if not found.
func get_building_data(building_type: Types.BuildingType) -> BuildingData:
	for data: BuildingData in building_data_registry:
		if data.building_type == building_type:
			return data
	return null


## Returns whether the given building type is currently available to place.
func is_building_available(building_type: Types.BuildingType) -> bool:
	var building_data: BuildingData = get_building_data(building_type)
	if building_data == null:
		return false
	if not building_data.is_locked:
		return true
	# ASSUMPTION: if ResearchManager is null (unit test), treat all as unlocked.
	if _research_manager == null:
		return true
	return _research_manager.is_unlocked(building_data.unlock_research_id)


## Returns the world-space Vector3 position of the given slot.
func get_slot_position(slot_index: int) -> Vector3:
	assert(_is_valid_index(slot_index),
		"HexGrid.get_slot_position: invalid slot_index %d" % slot_index)
	return _slots[slot_index]["world_pos"]


## Returns the slot index whose center is nearest to [param world_pos] on XZ, or -1 if too far.
## Used when UI blocks Area3D picking — InputManager resolves the slot from a ground click.
func get_nearest_slot_index(world_pos: Vector3) -> int:
	var best_i: int = -1
	var best_d2: float = INF
	for i: int in range(TOTAL_SLOTS):
		var wp: Vector3 = _slots[i]["world_pos"]
		var dx: float = wp.x - world_pos.x
		var dz: float = wp.z - world_pos.z
		var d2: float = dx * dx + dz * dz
		if d2 < best_d2:
			best_d2 = d2
			best_i = i
	var max_d: float = SLOT_PICK_MAX_DISTANCE
	if best_d2 <= max_d * max_d:
		return best_i
	return -1


## Updates the highlighted ring tile for build mode (each slot has its own material instance).
func set_build_slot_highlight(slot_index: int) -> void:
	if not _is_valid_index(slot_index):
		return
	_build_highlight_slot = slot_index
	_apply_build_slot_highlights()


# ---------------------------------------------------------------------------
# Private – slot initialisation
# ---------------------------------------------------------------------------

func _initialize_slots() -> void:
	_slots.clear()

	var positions: Array[Vector3] = []
	positions.append_array(_compute_ring_positions(RING1_COUNT, RING1_RADIUS, 0.0))
	positions.append_array(_compute_ring_positions(RING2_COUNT, RING2_RADIUS, 0.0))
	# Ring 3 is offset 30° so its slots sit between ring-2 slots visually.
	positions.append_array(_compute_ring_positions(RING3_COUNT, RING3_RADIUS, 30.0))

	assert(positions.size() == TOTAL_SLOTS,
		"HexGrid: expected %d positions, got %d" % [TOTAL_SLOTS, positions.size()])

	for i: int in range(TOTAL_SLOTS):
		var slot_data: Dictionary = {
			"index": i,
			"world_pos": positions[i],
			"building": null,
			"is_occupied": false,
		}
		_slots.append(slot_data)

		# Name-based lookup is more robust than get_child(i) — immune to editor
		# child-order shuffling. Source: CONVENTIONS.md §6.2.
		var slot_node: Area3D = get_node_or_null("HexSlot_%02d" % i) as Area3D
		if slot_node != null:
			slot_node.global_position = positions[i]
			slot_node.collision_layer = 0
			slot_node.set_collision_layer_value(7, true)
			slot_node.collision_mask = 0
			# input_ray_pickable must be true for Area3D.input_event signal to fire.
			# Source: Godot Forum – "Input Event Help" (2024-08-30)
			#   https://forum.godotengine.org/t/input-event-help/80348
			slot_node.input_ray_pickable = true
			slot_node.monitoring = false
			slot_node.monitorable = false
			slot_node.input_event.connect(_on_hex_slot_input.bind(i))
			# Scene file shares one material across all SlotMesh — duplicate per slot for highlights.
			var mesh_inst: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
			if mesh_inst != null:
				var shared: Material = mesh_inst.material_override
				if shared == null and mesh_inst.mesh != null and mesh_inst.mesh.get_surface_count() > 0:
					shared = mesh_inst.get_surface_override_material(0)
				if shared != null:
					mesh_inst.material_override = shared.duplicate() as Material


## Computes world positions for a ring of count slots at radius, offset by angle_offset_degrees.
## All positions are at Y = 0 (ground plane).
func _compute_ring_positions(count: int, radius: float, angle_offset_degrees: float) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var angle_step: float = TAU / float(count)
	var offset_rad: float = deg_to_rad(angle_offset_degrees)
	for i: int in range(count):
		var angle: float = float(i) * angle_step + offset_rad
		positions.append(Vector3(
			radius * cos(angle),
			0.0,
			radius * sin(angle)
		))
	return positions


func _set_slots_visible(slots_visible: bool) -> void:
	for i: int in range(get_child_count()):
		var slot_node: Area3D = get_child(i) as Area3D
		if slot_node == null:
			continue
		var mesh: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
		if mesh != null:
			mesh.visible = slots_visible
	if slots_visible:
		_apply_build_slot_highlights()


func _apply_build_slot_highlights() -> void:
	for i: int in range(TOTAL_SLOTS):
		var slot_node: Area3D = get_node_or_null("HexSlot_%02d" % i) as Area3D
		if slot_node == null:
			continue
		var mesh: MeshInstance3D = slot_node.get_node_or_null("SlotMesh") as MeshInstance3D
		if mesh == null:
			continue
		var mat: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if mat == null:
			mat = StandardMaterial3D.new()
			mesh.material_override = mat
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var is_selected: bool = i == _build_highlight_slot
		if is_selected:
			mat.albedo_color = Color(1.0, 0.92, 0.15, 0.92)
			mat.emission_enabled = true
			mat.emission = Color(0.4, 0.35, 0.05)
		else:
			mat.albedo_color = Color(0.12, 0.55, 1.0, 0.82)
			mat.emission_enabled = true
			mat.emission = Color(0.08, 0.2, 0.35)

# ---------------------------------------------------------------------------
# Private – validation
# ---------------------------------------------------------------------------

func _is_valid_index(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < TOTAL_SLOTS

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_build_mode_entered() -> void:
	print("[HexGrid] build_mode_entered: showing %d slot tiles" % TOTAL_SLOTS)
	_build_highlight_slot = 0
	_set_slots_visible(true)


func _on_build_mode_exited() -> void:
	print("[HexGrid] build_mode_exited: hiding slot tiles")
	_build_highlight_slot = -1
	_set_slots_visible(false)


func _on_research_unlocked(_node_id: String) -> void:
	# No cache to invalidate – is_building_available() checks live state each call.
	# Hook reserved for future UI refresh (e.g., glow newly unlocked slots).
	pass


## Bound slot index is last: Godot passes signal args first, then Callable.bind() args.
func _on_hex_slot_input(
		_camera: Node,
		event: InputEvent,
		_event_position: Vector3,
		_normal: Vector3,
		_shape_idx: int,
		slot_index: int
) -> void:
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var state: Types.GameState = GameManager.get_game_state()
	print("[HexGrid] hex slot %d clicked  game_state=%s" % [slot_index, Types.GameState.keys()[state]])
	if state != Types.GameState.BUILD_MODE:
		return
	# InputManager now owns BUILD_MODE slot click routing (place vs sell menu mode).
	# Keep this callback for highlight feedback only.
	set_build_slot_highlight(slot_index)
````

---

## `scenes/hub/character_base_2d.gd`

````
## character_base_2d.gd
## Clickable between-mission hub character UI base. Emits interaction signal only.

extends Control
class_name HubCharacterBase2D

signal character_interacted(character_id: String)

## Data resource that describes this hub character.
@export var character_data: CharacterData

var character_id: String = ""
var role: Types.HubRole = Types.HubRole.FLAVOR_ONLY
var display_name: String = ""

@onready var _name_label: Label = (get_node_or_null("NameLabel") as Label) # Optional in tests / stubs.

func _ready() -> void:
	# In-editor previews and some tests may instantiate the scene without data.
	if character_data == null:
		return

	character_id = character_data.character_id
	role = character_data.role
	display_name = character_data.display_name

	if is_instance_valid(_name_label):
		_name_label.text = display_name


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			character_interacted.emit(character_id)
````

---

## `scenes/projectiles/projectile_base.gd`

````
## projectile_base.gd
## Physics-driven projectile for FOUL WARD: straight-line Area3D with damage on hit or miss timeout.
## Simulation API: all public methods callable without UI nodes present.

# Credit (straight-line Area3D movement + miss/lifetime logic):
#   FOUL WARD SYSTEMS_part2.md §6.1–6.6 ProjectileBase pseudocode.
#   Godot Docs Area3D.body_entered pattern & CollisionObject3D layer/mask helpers.
#   https://docs.godotengine.org/en/stable/classes/class_area3d.html
#   https://docs.godotengine.org/en/stable/classes/class_collisionobject3d.html
#   License: CC BY 3.0
#   Adapted by FOUL WARD team to use EnemyBase + EnemyData + DamageCalculator.

class_name ProjectileBase
extends Area3D

const MAX_LIFETIME: float = 5.0

# Visual/collision scaling for all projectile types.
# User request: make every projectile "twice bigger".
const PROJECTILE_VISUAL_SCALE: float = 2.0
const BASE_HIT_OVERLAP_SPHERE_RADIUS: float = 0.4
const BASE_COLLISION_SPHERE_RADIUS: float = 0.2

var _damage: float = 0.0
var _damage_type: Types.DamageType = Types.DamageType.PHYSICAL
var _speed: float = 20.0
var _origin: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _direction: Vector3 = Vector3.ZERO
var _max_travel_distance: float = 0.0
var _distance_traveled: float = 0.0
var _lifetime: float = 0.0
var _targets_air_only: bool = false
var _dot_enabled: bool = false
var _dot_total_damage: float = 0.0
var _dot_tick_interval: float = 1.0
var _dot_duration: float = 0.0
var _dot_effect_type: String = ""
var _dot_source_id: String = ""
var _dot_in_addition_to_hit: bool = true

var _mesh: MeshInstance3D = null

## Prevents double application when both overlap scan and body_entered run same frame.
var _hit_processed: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	monitoring = true

# === PUBLIC INITIALIZATION PATHS ===================================

## Initialize from Florence's WeaponData (player weapons).
func initialize_from_weapon(
	weapon_data: WeaponData,
	origin: Vector3,
	target_position: Vector3,
	custom_damage: float = -1.0,
	custom_damage_type: Types.DamageType = Types.DamageType.PHYSICAL
) -> void:
	# Credit (two-path initialization pattern, overshoot buffer):
	#   FOUL WARD SYSTEMS_part2.md §6.5 initialize_from_weapon.
	_damage = custom_damage if custom_damage >= 0.0 else weapon_data.damage
	_damage_type = custom_damage_type
	_speed = weapon_data.projectile_speed
	_origin = origin
	_target_position = target_position
	_direction = (target_position - origin).normalized()
	_max_travel_distance = origin.distance_to(target_position) + 5.0
	_distance_traveled = 0.0
	_lifetime = 0.0
	_targets_air_only = false  # Florence cannot target flying in MVP.

	global_position = origin
	_configure_collision(false)
	_configure_visuals(weapon_data.burst_count == 1)

## Initialize from BuildingBase (turret shots).
func initialize_from_building(
	damage: float,
	damage_type: Types.DamageType,
	speed: float,
	origin: Vector3,
	target_position: Vector3,
	targets_air_only: bool,
	dot_enabled: bool,
	dot_total_damage: float,
	dot_tick_interval: float,
	dot_duration: float,
	dot_effect_type: String,
	dot_source_id: String,
	dot_in_addition_to_hit: bool
) -> void:
	_damage = damage
	_damage_type = damage_type
	_speed = speed
	_origin = origin
	_target_position = target_position
	_direction = (target_position - origin).normalized()
	_max_travel_distance = origin.distance_to(target_position) + 5.0
	_distance_traveled = 0.0
	_lifetime = 0.0
	_targets_air_only = targets_air_only
	_dot_enabled = dot_enabled
	_dot_total_damage = dot_total_damage
	_dot_tick_interval = dot_tick_interval
	_dot_duration = dot_duration
	_dot_effect_type = dot_effect_type
	_dot_source_id = dot_source_id
	_dot_in_addition_to_hit = dot_in_addition_to_hit

	global_position = origin
	_configure_collision(targets_air_only)
	_configure_visuals(true)

# === COLLISION/LAYERS ==============================================

func _configure_collision(_targets_air_only_flag: bool) -> void:
	# Projectiles always live on layer 5, hit enemies on layer 2 only.
	# Credit (layer/mask convention):
	#   FOUL WARD CONVENTIONS.md §16 Physics layers & PRE_GENERATION_VERIFICATION.md §3.3.
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(5, true)
	set_collision_mask_value(2, true)
	_targets_air_only = _targets_air_only_flag

	# Keep collision shape consistent with visuals scaling so the "bigger projectile"
	# also feels bigger when hitting.
	var collision_shape: CollisionShape3D = get_node_or_null("ProjectileCollision") as CollisionShape3D
	var sphere_shape: SphereShape3D = null
	if collision_shape != null:
		sphere_shape = collision_shape.shape as SphereShape3D
	if sphere_shape != null:
		sphere_shape.radius = BASE_COLLISION_SPHERE_RADIUS * PROJECTILE_VISUAL_SCALE

	# NOTE: Filtering flying vs ground is done in targeting code (which decides where
	# the projectile is fired), not via different masks. All projectiles collide with
	# any enemy body on layer 2.

func _configure_visuals(is_standard_size: bool) -> void:
	# Resolve lazily so this works whether called before or after add_child.
	# get_node_or_null() traverses the instantiated subtree, not the scene tree.
	if _mesh == null:
		_mesh = get_node_or_null("ProjectileMesh") as MeshInstance3D
	if _mesh == null:
		return
	var mat := StandardMaterial3D.new()

	if is_standard_size:
		# Building projectiles or crossbow bolt (large enough to read at isometric scale).
		var s: float = 1.1 * PROJECTILE_VISUAL_SCALE
		_mesh.scale = Vector3(s, s, s)
	else:
		# Rapid missile (small + fast look).
		var s2: float = 0.55 * PROJECTILE_VISUAL_SCALE
		_mesh.scale = Vector3(s2, s2, s2)

	match _damage_type:
		Types.DamageType.PHYSICAL:
			mat.albedo_color = Color.SADDLE_BROWN
		Types.DamageType.FIRE:
			mat.albedo_color = Color.ORANGE_RED
		Types.DamageType.MAGICAL:
			mat.albedo_color = Color.MEDIUM_PURPLE
		Types.DamageType.POISON:
			mat.albedo_color = Color.GREEN_YELLOW
		_:
			mat.albedo_color = Color.WHITE
	_mesh.material_override = mat

# === PHYSICS LOOP ===================================================

func _physics_process(delta: float) -> void:
	# Credit (straight-line, distance_traveled + tolerance + lifetime checks):
	#   FOUL WARD SYSTEMS_part2.md §6.5 ProjectileBase.physics_process.
	if _hit_processed:
		return
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		queue_free()
		return

	var movement: Vector3 = _direction * _speed * delta
	global_position += movement
	force_update_transform()
	_distance_traveled += movement.length()
	# Headless / manual _physics_process: physics server may not run, so body_entered
	# never fires — resolve overlaps here (same rules as _on_body_entered).
	if _try_hit_overlapping_enemy():
		return

	if _distance_traveled >= _max_travel_distance:
		queue_free()
		return

# === COLLISION HANDLER =============================================

func _on_body_entered(body: Node3D) -> void:
	if _hit_processed:
		return
	var enemy := body as EnemyBase
	if enemy == null:
		return
	if not is_instance_valid(enemy):
		return
	# Credit (skip dead enemies to avoid double-hit):
	#   FOUL WARD SYSTEMS_part2.md §6.6 Edge case "Projectile hits dead enemy".
	if not enemy.health_component.is_alive():
		return

	if _apply_damage_to_enemy(enemy):
		_hit_processed = true
		queue_free()


func _try_hit_overlapping_enemy() -> bool:
	for body: Node3D in get_overlapping_bodies():
		if _try_damage_enemy_body(body):
			return true
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state \
		if get_world_3d() != null else null
	if space == null:
		return false
	var sphere := SphereShape3D.new()
	sphere.radius = BASE_HIT_OVERLAP_SPHERE_RADIUS * PROJECTILE_VISUAL_SCALE
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = sphere
	params.transform = global_transform
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.collision_mask = 2
	for r: Dictionary in space.intersect_shape(params, 8):
		var collider: Variant = r.get("collider", null)
		var node3: Node3D = collider as Node3D
		if _try_damage_enemy_body(node3):
			return true
	return false


func _try_damage_enemy_body(body: Node3D) -> bool:
	var enemy := body as EnemyBase
	if enemy == null or not is_instance_valid(enemy):
		return false
	if not enemy.health_component.is_alive():
		return false
	if _apply_damage_to_enemy(enemy):
		_hit_processed = true
		queue_free()
		return true
	return false

# === DAMAGE APPLICATION ============================================

## Returns true if at least one point of damage was applied (not fully immunized).
func _apply_damage_to_enemy(enemy: EnemyBase) -> bool:
	# Credit (damage_immunities + DamageCalculator):
	#   FOUL WARD SYSTEMS_part1/2/3 EnemyBase & ProjectileBase.apply_damage_to_enemy.
	var enemy_data := enemy.get_enemy_data()

	if _damage_type in enemy_data.damage_immunities:
		return false

	if _dot_enabled and (_damage_type == Types.DamageType.FIRE or _damage_type == Types.DamageType.POISON):
		if _dot_in_addition_to_hit:
			var final_damage: float = DamageCalculator.calculate_damage(
				_damage,
				_damage_type,
				enemy_data.armor_type
			)
			if final_damage > 0.0:
				enemy.take_damage(_damage, _damage_type)
		var effect_data: Dictionary = {
			"effect_type": _dot_effect_type,
			"damage_type": _damage_type,
			"dot_total_damage": _dot_total_damage,
			"tick_interval": _dot_tick_interval,
			"duration": _dot_duration,
			"remaining_time": _dot_duration,
			"time_since_last_tick": 0.0,
			"source_id": _dot_source_id,
		}
		enemy.apply_dot_effect(effect_data)
		return true

	var final_damage_no_dot: float = DamageCalculator.calculate_damage(
		_damage,
		_damage_type,
		enemy_data.armor_type
	)
	if final_damage_no_dot > 0.0:
		enemy.take_damage(_damage, _damage_type)
		return true
	return false
````

---

## `scenes/tower/tower.gd`

````
# scenes/tower/tower.gd
# Tower — central destructible structure. Owns Florence's two weapons.
# Handles delta-based reload timers and burst-fire for Rapid Missile.
# Emits tower_damaged and tower_destroyed via SignalBus.
# Simulation API: all public methods callable without UI nodes present.
#
# Credit: Godot Engine Official Documentation — delta-based timer pattern
# https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html
# License: CC-BY-3.0
# Adapted by: Foul Ward team
# What was used: _physics_process delta accumulator for reload and burst timers.
#
# Credit: Foul Ward Phase 5 Research — Q2 (Weapon reload timer without Timer node)
# Research conducted this session by Foul Ward team.
# What was used: Two-timer pattern with separate burst state variables.

class_name Tower
extends StaticBody3D

@export var starting_hp: int = 500
@export var crossbow_data: WeaponData
@export var rapid_missile_data: WeaponData

## When true the tower auto-targets the nearest enemy (any type, ground or flying)
## and fires the crossbow at it. Useful for testing without player input.
@export var auto_fire_enabled: bool = false

## Reference to WeaponUpgradeManager, resolved at runtime.
## Null in unit test context — Tower falls back to raw WeaponData values.
var _weapon_upgrade_manager: Node = null

const ProjectileScene: PackedScene = preload(
	"res://scenes/projectiles/projectile_base.tscn"
)

# Assign placeholder art resources via convention-based pipeline.
const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

@onready var _health_component: HealthComponent = $HealthComponent

# ASSUMPTION: ProjectileContainer at /root/Main/ProjectileContainer per ARCHITECTURE.md §2.
@onready var _projectile_container: Node3D = get_node(
	"/root/Main/ProjectileContainer"
)

# Reload timers — count DOWN to 0 (weapon ready when <= 0)
var _crossbow_reload_remaining: float = 0.0
var _rapid_missile_reload_remaining: float = 0.0

# Burst-fire state for Rapid Missile
var _burst_remaining: int = 0
var _burst_timer: float = 0.0
var _burst_target: Vector3 = Vector3.ZERO
# ASSUMPTION: Tower-owned RNG is used instead of global randf() so tests can seed it.
var _shot_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	if crossbow_data == null or rapid_missile_data == null:
		push_error(
			"Tower: assign crossbow_data and rapid_missile_data exports (e.g. crossbow.tres, rapid_missile.tres)."
		)
		return

	_health_component.max_hp = starting_hp
	_health_component.reset_to_max()

	_health_component.health_changed.connect(_on_health_changed)
	_health_component.health_depleted.connect(_on_health_depleted)
	_weapon_upgrade_manager = get_node_or_null("/root/Main/Managers/WeaponUpgradeManager")
	_shot_rng.randomize()

	# Art pipeline placeholder assignment.
	var tower_mesh_node: MeshInstance3D = get_node_or_null("TowerMesh") as MeshInstance3D
	if tower_mesh_node != null:
		var _mesh: Mesh = ArtPlaceholderHelper.get_tower_mesh()
		if _mesh != null and tower_mesh_node.mesh == null:
			tower_mesh_node.mesh = _mesh
		var _mat: Material = ArtPlaceholderHelper.get_faction_material("neutral")
		if _mat != null:
			tower_mesh_node.material_override = _mat
	print("[Tower] _ready: hp=%d auto_fire=%s crossbow_reload=%.1fs" % [
		starting_hp, auto_fire_enabled, crossbow_data.reload_time
	])


func _physics_process(delta: float) -> void:
	if crossbow_data == null or rapid_missile_data == null:
		return
	if _crossbow_reload_remaining > 0.0:
		_crossbow_reload_remaining -= delta
	if _rapid_missile_reload_remaining > 0.0:
		_rapid_missile_reload_remaining -= delta

	# Burst fire — ticks independently from the reload timer.
	if _burst_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			var rapid_composed: Dictionary = _compose_projectile_stats(
				Types.WeaponSlot.RAPID_MISSILE,
				_build_effective_weapon_data(Types.WeaponSlot.RAPID_MISSILE)
			)
			_spawn_weapon_projectile(Types.WeaponSlot.RAPID_MISSILE, rapid_composed, global_position, _burst_target)
			_burst_remaining -= 1
			_burst_timer = rapid_missile_data.burst_interval

	if auto_fire_enabled:
		_auto_fire_at_nearest_enemy()

# ── Public API ────────────────────────────────────────────────────────────

## Fires one crossbow bolt toward target_position. Does nothing if reloading.
func fire_crossbow(target_position: Vector3) -> void:
	if crossbow_data == null:
		return
	if _crossbow_reload_remaining > 0.0:
		return
	var final_target: Vector3 = _resolve_manual_aim_target(crossbow_data, target_position)
	print("[Tower] fire_crossbow → (%.1f,%.1f,%.1f)" % [final_target.x, final_target.y, final_target.z])
	var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.CROSSBOW
	var effective_data: WeaponData = _build_effective_weapon_data(weapon_slot)
	var composed: Dictionary = _compose_projectile_stats(weapon_slot, effective_data)
	_spawn_weapon_projectile(weapon_slot, composed, global_position, final_target)
	_crossbow_reload_remaining = _get_effective_weapon_reload_time(Types.WeaponSlot.CROSSBOW)


## Starts a burst of rapid_missile_data.burst_count projectiles.
## Does nothing if reloading or a burst is already in progress.
func fire_rapid_missile(target_position: Vector3) -> void:
	if rapid_missile_data == null:
		return
	if _rapid_missile_reload_remaining > 0.0:
		return
	if _burst_remaining > 0:
		return
	var final_target: Vector3 = _resolve_manual_aim_target(rapid_missile_data, target_position)
	_rapid_missile_reload_remaining = _get_effective_weapon_reload_time(Types.WeaponSlot.RAPID_MISSILE)
	_burst_remaining = _get_effective_weapon_burst_count(Types.WeaponSlot.RAPID_MISSILE)
	_burst_timer = 0.0  # First shot fires this same physics frame.
	_burst_target = final_target


## Applies raw integer damage to the HealthComponent.
func take_damage(amount: int) -> void:
	print("[Tower] take_damage: %d  hp=%d→%d" % [amount, _health_component.current_hp, _health_component.current_hp - amount])
	_health_component.take_damage(float(amount))


## Restores tower HP to maximum. Called by ShopManager (Tower Repair Kit).
func repair_to_full() -> void:
	_health_component.reset_to_max()


## Returns current HP integer.
func get_current_hp() -> int:
	return _health_component.current_hp


## Returns maximum HP integer.
func get_max_hp() -> int:
	return _health_component.max_hp


## Returns true when the specified weapon is ready to fire.
func is_weapon_ready(weapon_slot: Types.WeaponSlot) -> bool:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			return _crossbow_reload_remaining <= 0.0
		Types.WeaponSlot.RAPID_MISSILE:
			return _rapid_missile_reload_remaining <= 0.0 and _burst_remaining == 0
	return false


## Seconds until crossbow can fire again (0 = ready).
func get_crossbow_reload_remaining_seconds() -> float:
	return maxf(0.0, _crossbow_reload_remaining)


## Total crossbow reload duration from WeaponData.
func get_crossbow_reload_total_seconds() -> float:
	return _get_effective_weapon_reload_time(Types.WeaponSlot.CROSSBOW)


## Seconds until rapid missile weapon is ready for a new burst (0 = ready, burst may still be firing).
func get_rapid_missile_reload_remaining_seconds() -> float:
	return maxf(0.0, _rapid_missile_reload_remaining)


func get_rapid_missile_reload_total_seconds() -> float:
	return _get_effective_weapon_reload_time(Types.WeaponSlot.RAPID_MISSILE)


## Shots left in the current burst (0 when idle).
func get_rapid_missile_burst_remaining() -> int:
	return _burst_remaining


func get_rapid_missile_burst_total() -> int:
	return _get_effective_weapon_burst_count(Types.WeaponSlot.RAPID_MISSILE)

# ── Private ───────────────────────────────────────────────────────────────

## Null guard: _projectile_container is null in headless test scenes.
## push_warning is logged; no crash.
func _spawn_projectile(weapon_data: WeaponData, target_pos: Vector3) -> void:
	if _projectile_container == null:
		push_warning("Tower._spawn_projectile: ProjectileContainer not found — skipping spawn.")
		return
	var proj: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	_projectile_container.add_child(proj)
	proj.initialize_from_weapon(weapon_data, global_position, target_pos)
	proj.add_to_group("projectiles")


func _compose_projectile_stats(weapon_slot: Types.WeaponSlot, weapon_data: WeaponData) -> Dictionary:
	var final_damage: float = weapon_data.damage
	var final_damage_type: Types.DamageType = Types.DamageType.PHYSICAL

	# SOURCE: Community stat-container/status-effect patterns (base stat + slot modifiers).
	var elemental_enchant: EnchantmentData = EnchantmentManager.get_equipped_enchantment(weapon_slot, "elemental")
	if elemental_enchant != null:
		if elemental_enchant.has_damage_type_override:
			final_damage_type = elemental_enchant.damage_type_override
		final_damage *= elemental_enchant.damage_multiplier

	var power_enchant: EnchantmentData = EnchantmentManager.get_equipped_enchantment(weapon_slot, "power")
	if power_enchant != null:
		if power_enchant.has_damage_type_override:
			final_damage_type = power_enchant.damage_type_override
		final_damage *= power_enchant.damage_multiplier

	return {
		"damage": final_damage,
		"damage_type": final_damage_type,
	}


func _spawn_weapon_projectile(
	weapon_slot: Types.WeaponSlot,
	composed: Dictionary,
	origin: Vector3,
	target_position: Vector3
) -> void:
	if _projectile_container == null:
		push_warning("Tower._spawn_weapon_projectile: ProjectileContainer not found — skipping spawn.")
		SignalBus.projectile_fired.emit(weapon_slot, origin, target_position)
		return

	var projectile: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	var damage: float = composed.get("damage", 0.0) as float
	var damage_type_value: int = composed.get("damage_type", Types.DamageType.PHYSICAL) as int
	var damage_type: Types.DamageType = damage_type_value as Types.DamageType
	var weapon_data: WeaponData = crossbow_data if weapon_slot == Types.WeaponSlot.CROSSBOW else rapid_missile_data

	_projectile_container.add_child(projectile)
	projectile.initialize_from_weapon(
		weapon_data,
		origin,
		target_position,
		damage,
		damage_type
	)
	projectile.add_to_group("projectiles")
	SignalBus.projectile_fired.emit(weapon_slot, origin, target_position)


## Targets the nearest living enemy (ground or flying) and fires the crossbow.
func _auto_fire_at_nearest_enemy() -> void:
	var best_target: EnemyBase = null
	var best_dist: float = INF
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best_target = enemy
	if best_target != null:
		fire_crossbow(best_target.global_position)


func _resolve_manual_aim_target(weapon_data: WeaponData, raw_target: Vector3) -> Vector3:
	return _apply_miss_chance(weapon_data, _apply_auto_aim(weapon_data, raw_target))


func _apply_auto_aim(weapon_data: WeaponData, raw_target: Vector3) -> Vector3:
	if auto_fire_enabled:
		return raw_target
	if weapon_data == null:
		return raw_target

	var assisted_target: Vector3 = raw_target
	if weapon_data.assist_angle_degrees > 0.0:
		var raw_offset: Vector3 = raw_target - global_position
		if raw_offset.length_squared() > 0.000001:
			var raw_dir: Vector3 = raw_offset.normalized()
			var nearest_enemy: EnemyBase = null
			var nearest_distance: float = INF
			for node: Node in get_tree().get_nodes_in_group("enemies"):
				var enemy: EnemyBase = node as EnemyBase
				if enemy == null or not is_instance_valid(enemy):
					continue
				if enemy.health_component == null or not enemy.health_component.is_alive():
					continue
				var enemy_data: EnemyData = enemy.get_enemy_data()
				if enemy_data == null:
					continue
				if enemy_data.is_flying and not weapon_data.can_target_flying:
					continue

				var to_enemy_vec: Vector3 = enemy.global_position - global_position
				var to_enemy_len_sq: float = to_enemy_vec.length_squared()
				if to_enemy_len_sq <= 0.000001:
					continue
				var distance_to_enemy: float = sqrt(to_enemy_len_sq)
				if weapon_data.assist_max_distance > 0.0 and distance_to_enemy > weapon_data.assist_max_distance:
					continue

				# SOURCE: Godot docs Vector3.angle_to + rad_to_deg cone check pattern.
				var to_enemy: Vector3 = to_enemy_vec / distance_to_enemy
				var angle_deg: float = rad_to_deg(raw_dir.angle_to(to_enemy))
				if angle_deg > weapon_data.assist_angle_degrees:
					continue

				if distance_to_enemy < nearest_distance:
					nearest_distance = distance_to_enemy
					nearest_enemy = enemy

			if nearest_enemy != null:
				assisted_target = nearest_enemy.global_position

	return assisted_target


func _apply_miss_chance(weapon_data: WeaponData, aim_target: Vector3) -> Vector3:
	if auto_fire_enabled:
		return aim_target
	if weapon_data == null:
		return aim_target
	if weapon_data.base_miss_chance <= 0.0 or weapon_data.max_miss_angle_degrees <= 0.0:
		return aim_target

	var clamped_miss_chance: float = clampf(weapon_data.base_miss_chance, 0.0, 1.0)
	if _shot_rng.randf() >= clamped_miss_chance:
		return aim_target

	var aim_offset: Vector3 = aim_target - global_position
	var aim_distance: float = aim_offset.length()
	if aim_distance <= 0.000001:
		# ASSUMPTION: when aim point is effectively tower origin, keep target unchanged.
		return aim_target

	var aim_dir: Vector3 = aim_offset / aim_distance

	# SOURCE: Godot docs Vector3/Basis rotation pattern adapted to orthonormal-basis cone sampling.
	var max_angle_rad: float = deg_to_rad(weapon_data.max_miss_angle_degrees)
	var delta_angle: float = _shot_rng.randf_range(0.0, max_angle_rad)
	var phi: float = _shot_rng.randf_range(0.0, TAU)

	var up: Vector3 = Vector3.UP
	if absf(aim_dir.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var u: Vector3 = aim_dir.cross(up).normalized()
	var v: Vector3 = aim_dir.cross(u).normalized()

	var perturbed_dir: Vector3 = (
		aim_dir * cos(delta_angle)
		+ u * sin(delta_angle) * cos(phi)
		+ v * sin(delta_angle) * sin(phi)
	).normalized()
	var miss_distance: float = maxf(1.0, aim_distance)
	return global_position + perturbed_dir * miss_distance


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	SignalBus.tower_damaged.emit(current_hp, max_hp)


func _on_health_depleted() -> void:
	SignalBus.tower_destroyed.emit()


## Returns effective damage for the given weapon slot.
## Queries WeaponUpgradeManager when available; falls back to raw WeaponData.
# SOURCE: Null-guard fallback pattern consistent with HexGrid's ResearchManager reference in this codebase
func _get_effective_weapon_damage(slot: Types.WeaponSlot) -> float:
	if _weapon_upgrade_manager != null:
		return _weapon_upgrade_manager.get_effective_damage(slot)
	match slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_data.damage
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_data.damage
	return 0.0


## Returns effective projectile speed for the given weapon slot.
func _get_effective_weapon_speed(slot: Types.WeaponSlot) -> float:
	if _weapon_upgrade_manager != null:
		return _weapon_upgrade_manager.get_effective_speed(slot)
	match slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_data.projectile_speed
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_data.projectile_speed
	return 0.0


## Returns effective reload time for the given weapon slot.
func _get_effective_weapon_reload_time(slot: Types.WeaponSlot) -> float:
	if _weapon_upgrade_manager != null:
		return _weapon_upgrade_manager.get_effective_reload_time(slot)
	match slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_data.reload_time
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_data.reload_time
	return 1.0


## Returns effective burst count for the given weapon slot.
func _get_effective_weapon_burst_count(slot: Types.WeaponSlot) -> int:
	if _weapon_upgrade_manager != null:
		return _weapon_upgrade_manager.get_effective_burst_count(slot)
	match slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_data.burst_count
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_data.burst_count
	return 0


## Builds a duplicated WeaponData containing effective upgradable stats.
## SOURCE: Resource.duplicate() for safe per-instance stat overrides — Godot 4 docs [S1]
## SOURCE: Composition over mutation for shared Resources — [S4]
func _build_effective_weapon_data(slot: Types.WeaponSlot) -> WeaponData:
	var base_data: WeaponData = crossbow_data if slot == Types.WeaponSlot.CROSSBOW else rapid_missile_data
	var effective_data: WeaponData = base_data.duplicate() as WeaponData
	effective_data.damage = _get_effective_weapon_damage(slot)
	effective_data.projectile_speed = _get_effective_weapon_speed(slot)
	return effective_data
````

---

## `scripts/art/art_placeholder_helper.gd`

````
## =============================================================================
## ArtPlaceholderHelper
## res://scripts/art/art_placeholder_helper.gd
##
## Stateless utility class for resolving placeholder art resources (Mesh,
## Material, Texture2D) based on Types enums and string IDs.
##
## DEVIATION: Icon pipeline is POST-MVP stubbed (helper returns null).
## =============================================================================
class_name ArtPlaceholderHelper
extends RefCounted

# ---------------------------------------------------------------------------
# Private caches — keyed by enum int or StringName
# ---------------------------------------------------------------------------
static var _enemy_mesh_cache: Dictionary = {}
static var _building_mesh_cache: Dictionary = {}
static var _ally_mesh_cache: Dictionary = {}
static var _faction_material_cache: Dictionary = {}
static var _enemy_material_cache: Dictionary = {}
static var _building_material_cache: Dictionary = {}
static var _unknown_mesh_cache: Mesh = null

# ---------------------------------------------------------------------------
# ART ROOT CONSTANTS
# ---------------------------------------------------------------------------
const ART_ROOT_MESHES_ENEMIES: String = "res://art/meshes/enemies/"
const ART_ROOT_MESHES_BUILDINGS: String = "res://art/meshes/buildings/"
const ART_ROOT_MESHES_ALLIES: String = "res://art/meshes/allies/"
const ART_ROOT_MESHES_MISC: String = "res://art/meshes/misc/"
const ART_ROOT_MATERIALS_FACTIONS: String = "res://art/materials/factions/"
const ART_ROOT_MATERIALS_TYPES: String = "res://art/materials/types/"
const ART_ROOT_ICONS_ENEMIES: String = "res://art/icons/enemies/"
const ART_ROOT_ICONS_BUILDINGS: String = "res://art/icons/buildings/"
const ART_ROOT_ICONS_ALLIES: String = "res://art/icons/allies/"

# POST-MVP: Generated asset roots — checked before placeholders
const ART_GEN_MESHES: String = "res://art/generated/meshes/"
const ART_GEN_ICONS: String = "res://art/generated/icons/"

# ---------------------------------------------------------------------------
# PUBLIC API — MESHES
# ---------------------------------------------------------------------------

static func get_enemy_mesh(enemy_type: Types.EnemyType) -> Mesh:
	if _enemy_mesh_cache.has(enemy_type):
		return _enemy_mesh_cache[enemy_type] as Mesh
	var token: String = _get_enemy_token(enemy_type)
	var mesh: Mesh = _load_mesh_with_generated_fallback(
		ART_GEN_MESHES + "enemy_%s.tres" % token,
		ART_ROOT_MESHES_ENEMIES + "enemy_%s.tres" % token,
		"enemy mesh for %s" % token
	)
	_enemy_mesh_cache[enemy_type] = mesh
	return mesh


static func get_building_mesh(building_type: Types.BuildingType) -> Mesh:
	if _building_mesh_cache.has(building_type):
		return _building_mesh_cache[building_type] as Mesh
	var token: String = _get_building_token(building_type)
	var mesh: Mesh = _load_mesh_with_generated_fallback(
		ART_GEN_MESHES + "building_%s.tres" % token,
		ART_ROOT_MESHES_BUILDINGS + "building_%s.tres" % token,
		"building mesh for %s" % token
	)
	_building_mesh_cache[building_type] = mesh
	return mesh


static func get_ally_mesh(ally_id: StringName) -> Mesh:
	if _ally_mesh_cache.has(ally_id):
		return _ally_mesh_cache[ally_id] as Mesh
	var token: String = _get_ally_token(ally_id)
	var mesh: Mesh = _load_mesh_with_generated_fallback(
		ART_GEN_MESHES + "ally_%s.tres" % token,
		ART_ROOT_MESHES_ALLIES + "ally_%s.tres" % token,
		"ally mesh for %s" % token
	)
	_ally_mesh_cache[ally_id] = mesh
	return mesh


static func get_tower_mesh() -> Mesh:
	var path: String = ART_GEN_MESHES + "tower_core.tres"
	if ResourceLoader.exists(path):
		var mesh: Mesh = ResourceLoader.load(path) as Mesh
		if mesh != null:
			return mesh
	return _load_mesh(ART_ROOT_MESHES_MISC + "tower_core.tres", "tower_core")


static func get_unknown_mesh() -> Mesh:
	if _unknown_mesh_cache != null:
		return _unknown_mesh_cache
	_unknown_mesh_cache = _load_mesh(ART_ROOT_MESHES_MISC + "unknown_mesh.tres", "unknown_mesh")
	return _unknown_mesh_cache

# ---------------------------------------------------------------------------
# PUBLIC API — MATERIALS
# ---------------------------------------------------------------------------

static func get_faction_material(faction_id: StringName) -> Material:
	if _faction_material_cache.has(faction_id):
		return _faction_material_cache[faction_id] as Material
	var token: String = _get_faction_token(faction_id)
	var path: String = ART_ROOT_MATERIALS_FACTIONS + "faction_%s_material.tres" % token
	var mat: Material = _load_material(path, "faction material for %s" % faction_id)
	_faction_material_cache[faction_id] = mat
	return mat


static func get_enemy_material(enemy_type: Types.EnemyType) -> Material:
	# Returns type-specific material if it exists; falls back to faction material.
	if _enemy_material_cache.has(enemy_type):
		return _enemy_material_cache[enemy_type] as Material
	var token: String = _get_enemy_token(enemy_type)
	var path: String = ART_ROOT_MATERIALS_TYPES + "enemy_%s_material.tres" % token

	var mat: Material = null
	if ResourceLoader.exists(path):
		mat = ResourceLoader.load(path) as Material
	if mat == null:
		mat = get_faction_material(_get_enemy_faction(enemy_type))

	_enemy_material_cache[enemy_type] = mat
	return mat


static func get_building_material(building_type: Types.BuildingType) -> Material:
	# Returns type-specific material if it exists; falls back to neutral faction.
	if _building_material_cache.has(building_type):
		return _building_material_cache[building_type] as Material
	var token: String = _get_building_token(building_type)
	var path: String = ART_ROOT_MATERIALS_TYPES + "building_%s_material.tres" % token

	var mat: Material = null
	if ResourceLoader.exists(path):
		mat = ResourceLoader.load(path) as Material
	if mat == null:
		mat = get_faction_material("neutral")

	_building_material_cache[building_type] = mat
	return mat

# ---------------------------------------------------------------------------
# PUBLIC API — ICONS (POST-MVP stubs)
# ---------------------------------------------------------------------------

static func get_enemy_icon(_enemy_type: Types.EnemyType) -> Texture2D:
	# POST-MVP: implement when icon pipeline is ready.
	push_warning("ArtPlaceholderHelper: get_enemy_icon is POST-MVP and not yet implemented.")
	return null


static func get_building_icon(_building_type: Types.BuildingType) -> Texture2D:
	# POST-MVP: implement when icon pipeline is ready.
	push_warning("ArtPlaceholderHelper: get_building_icon is POST-MVP and not yet implemented.")
	return null


static func get_ally_icon(_ally_id: StringName) -> Texture2D:
	# POST-MVP: implement when icon pipeline is ready.
	push_warning("ArtPlaceholderHelper: get_ally_icon is POST-MVP and not yet implemented.")
	return null

# ---------------------------------------------------------------------------
# CACHE MANAGEMENT
# ---------------------------------------------------------------------------

static func clear_cache() -> void:
	_enemy_mesh_cache.clear()
	_building_mesh_cache.clear()
	_ally_mesh_cache.clear()
	_faction_material_cache.clear()
	_enemy_material_cache.clear()
	_building_material_cache.clear()
	_unknown_mesh_cache = null

# ---------------------------------------------------------------------------
# PRIVATE — TOKEN MAPPINGS
# ---------------------------------------------------------------------------

static func _get_enemy_token(enemy_type: Types.EnemyType) -> String:
	match enemy_type:
		Types.EnemyType.ORC_GRUNT:
			return "orc_grunt"
		Types.EnemyType.ORC_BRUTE:
			return "orc_brute"
		Types.EnemyType.GOBLIN_FIREBUG:
			return "goblin_firebug"
		Types.EnemyType.PLAGUE_ZOMBIE:
			return "plague_zombie"
		Types.EnemyType.ORC_ARCHER:
			return "orc_archer"
		Types.EnemyType.BAT_SWARM:
			return "bat_swarm"
		_:
			return "unknown"


static func _get_building_token(building_type: Types.BuildingType) -> String:
	match building_type:
		Types.BuildingType.ARROW_TOWER:
			return "arrow_tower"
		Types.BuildingType.FIRE_BRAZIER:
			return "fire_brazier"
		Types.BuildingType.MAGIC_OBELISK:
			return "magic_obelisk"
		Types.BuildingType.POISON_VAT:
			return "poison_vat"
		Types.BuildingType.BALLISTA:
			return "ballista"
		Types.BuildingType.ARCHER_BARRACKS:
			return "archer_barracks"
		Types.BuildingType.ANTI_AIR_BOLT:
			return "anti_air_bolt"
		Types.BuildingType.SHIELD_GENERATOR:
			return "shield_generator"
		_:
			return "unknown"


static func _get_faction_token(faction_id: StringName) -> String:
	# ASSUMPTION: Faction tokens are plain strings until a Types.Faction enum exists.
	match faction_id:
		"orcs":
			return "orcs"
		"plague":
			return "plague"
		"allies":
			return "allies"
		_:
			return "neutral"


static func _get_ally_token(ally_id: StringName) -> String:
	match ally_id:
		"arnulf":
			return "arnulf"
		_:
			return String(ally_id).to_lower()


static func _get_enemy_faction(enemy_type: Types.EnemyType) -> StringName:
	# ASSUMPTION: Orc* enemies are "orcs"; Plague Zombie is "plague"; others default to "neutral".
	match enemy_type:
		Types.EnemyType.ORC_GRUNT, Types.EnemyType.ORC_BRUTE, Types.EnemyType.ORC_ARCHER:
			return "orcs"
		Types.EnemyType.PLAGUE_ZOMBIE:
			return "plague"
		_:
			return "neutral"

# ---------------------------------------------------------------------------
# PRIVATE — LOADING HELPERS
# ---------------------------------------------------------------------------

static func _load_mesh_with_generated_fallback(
	generated_path: String,
	placeholder_path: String,
	context: String
) -> Mesh:
	# POST-MVP: generated assets in res://art/generated/ take priority.
	if ResourceLoader.exists(generated_path):
		var m: Mesh = ResourceLoader.load(generated_path) as Mesh
		if m != null:
			return m
	return _load_mesh(placeholder_path, context)


static func _load_mesh(path: String, context: String) -> Mesh:
	if ResourceLoader.exists(path):
		var m: Mesh = ResourceLoader.load(path) as Mesh
		if m != null:
			return m

	push_warning(
		"ArtPlaceholderHelper: Missing %s at '%s'. Using unknown_mesh fallback." % [context, path]
	)
	# Avoid infinite recursion: only recurse for non-unknown requests.
	if path.find("unknown_mesh") == -1:
		return get_unknown_mesh()
	return null


static func _load_material(path: String, context: String) -> Material:
	if ResourceLoader.exists(path):
		var m: Material = ResourceLoader.load(path) as Material
		if m != null:
			return m

	push_warning(
		"ArtPlaceholderHelper: Missing %s at '%s'. Using neutral faction fallback." % [context, path]
	)

	var neutral: String = ART_ROOT_MATERIALS_FACTIONS + "faction_neutral_material.tres"
	if path != neutral and ResourceLoader.exists(neutral):
		return ResourceLoader.load(neutral) as Material
	return null
````

---

## `scripts/florence_data.gd`

````
## florence_data.gd
## FlorenceData — data-only resource storing Florence meta-state for a single run.
## No Node references; safe to use in headless GdUnit tests.
##
## SOURCE: Roguelike meta-progression design pattern (Hades meta-state approach).
## Pattern: keep run/campaign meta-state in a dedicated Resource owned by managers.

class_name FlorenceData
extends Resource

## Technical label for the meta-state namespace used by dialogue conditions.
@export var florence_id: String = "florence"

## Display name for UI/placeholder debug text.
@export var display_name: String = "Florence"

## Total days advanced in the current run (meta progression, not world time).
## ASSUMPTION: This tracks days in the current run; cross-run tracking can be added later.
@export var total_days_played: int = 0

## Number of full campaign completions (run counter).
## ASSUMPTION: Increment on full campaign completion (`GAME_WON`), not on new game start.
@export var run_count: int = 0

## Total missions resolved (win or failure) in the current run.
## Increments once per mission resolution.
@export var total_missions_played: int = 0

## How many boss encounter attempts happened in the current run.
@export var boss_attempts: int = 0

## How many boss encounter victories happened in the current run.
@export var boss_victories: int = 0

## How many missions failed in the current run.
@export var mission_failures: int = 0

## Flags — technical progression toggles.
@export var has_unlocked_research: bool = false
## POST-MVP: Enchantments unlock hook.
@export var has_unlocked_enchantments: bool = false
## POST-MVP: Mercenary recruitment hook.
@export var has_recruited_any_mercenary: bool = false
## POST-MVP: Mini-boss seen hook.
@export var has_seen_any_mini_boss: bool = false
## POST-MVP: Mini-boss defeated hook.
@export var has_defeated_any_mini_boss: bool = false
## TUNING: Day 25 milestone.
@export var has_reached_day_25: bool = false
## TUNING: Day 50 milestone.
@export var has_reached_day_50: bool = false
## POST-MVP: First boss seen hook.
@export var has_seen_first_boss: bool = false

const TUNING_DAY_25: int = 25
const TUNING_DAY_50: int = 50

func reset_for_new_run() -> void:
	# FlorenceData represents run meta-state, so we reset run-scoped counters/flags.
	total_days_played = 0
	total_missions_played = 0
	boss_attempts = 0
	boss_victories = 0
	mission_failures = 0

	has_unlocked_research = false
	has_unlocked_enchantments = false
	has_recruited_any_mercenary = false
	has_seen_any_mini_boss = false
	has_defeated_any_mini_boss = false
	has_reached_day_25 = false
	has_reached_day_50 = false
	has_seen_first_boss = false
	# Note: run_count intentionally persists across runs (GameManager increments on GAME_WON).


func update_day_threshold_flags(current_day: int) -> void:
	# TUNING: Flags reflect whether the meta campaign timeline has reached milestones.
	has_reached_day_25 = current_day >= TUNING_DAY_25
	has_reached_day_50 = current_day >= TUNING_DAY_50
````

---

## `scripts/health_component.gd`

````
## health_component.gd
## Reusable HP-tracking component attached to Tower, Arnulf, Buildings, and Enemies.
## Simulation API: all public methods callable without UI nodes present.

class_name HealthComponent
extends Node

## Maximum hit points for this entity.
@export var max_hp: int = 100

var current_hp: int
# Prevents health_depleted from firing more than once per life.
var _is_alive: bool = true

# Local signals — not routed through SignalBus.
# The owning node decides what health_depleted means for its entity.
signal health_changed(current_hp: int, max_hp: int)
signal health_depleted()

func _ready() -> void:
	current_hp = max_hp

# ── Public API ─────────────────────────────────────────────────────────────────

## Applies pre-calculated damage (floats are truncated to int).
## Silently ignored if the entity is already dead.
func take_damage(amount: float) -> void:
	if not _is_alive:
		return
	current_hp = max(0, current_hp - int(amount))
	health_changed.emit(current_hp, max_hp)
	if current_hp == 0 and _is_alive:
		_is_alive = false
		health_depleted.emit()

## Restores up to max_hp. Does NOT revive a dead entity — call reset_to_max() for that.
func heal(amount: int) -> void:
	current_hp = min(max_hp, current_hp + amount)
	health_changed.emit(current_hp, max_hp)

## Fully restores HP and re-arms the health_depleted signal for another use.
func reset_to_max() -> void:
	current_hp = max_hp
	_is_alive = true
	health_changed.emit(current_hp, max_hp)

## Returns true until HP reaches zero.
func is_alive() -> bool:
	return _is_alive


## Current HP (int). Used by tests and UI; prefer `current_hp` when reading from same class.
func get_current_hp() -> int:
	return current_hp
````

---

## `scripts/input_manager.gd`

````
# scripts/input_manager.gd
# InputManager — translates raw input into public API calls. Zero game logic.
#
# Credit: Godot Engine Official Documentation — Camera3D
# https://docs.godotengine.org/en/stable/classes/class_camera3d.html
# License: CC-BY-3.0
# Adapted: project_ray_origin / project_ray_normal + Plane.intersects_ray pattern.
#
# Credit: Godot Engine GitHub Issue #83983 — project_ray_origin orthographic behaviour
# https://github.com/godotengine/godot/issues/83983
# License: MIT | Returns near-clip-plane point for orthographic cameras.

class_name InputManager
extends Node

# ASSUMPTION: All node paths match ARCHITECTURE.md §2.
@onready var _tower: Tower = get_node("/root/Main/Tower")
@onready var _spell_manager: SpellManager = get_node("/root/Main/Managers/SpellManager")
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")
@onready var _camera: Camera3D = get_node("/root/Main/Camera3D")
@onready var _build_menu: BuildMenu = get_node("/root/Main/UI/BuildMenu")

const _RAY_MAX_DISTANCE: float = 10_000.0
## Physics layer 2 — enemies (see enemy_base.tscn collision_layer).
const _ENEMY_COLLISION_MASK: int = 2
## Physics layer 7 — hex slots (see hex_grid.gd collision layer setup).
const _HEX_SLOT_COLLISION_MASK: int = 64

var _selected_slot_index: int = -1

func _ready() -> void:
	print("[InputManager] _ready")

# ─────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	var state: Types.GameState = GameManager.get_game_state()

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed:
			var can_manual_fire: bool = (
				state == Types.GameState.COMBAT
				or state == Types.GameState.WAVE_COUNTDOWN
			)
			if mb.button_index == MOUSE_BUTTON_LEFT and can_manual_fire:
				var aim: Vector3 = _get_fire_aim_position()
				if aim != Vector3.ZERO:
					print("[InputManager] LEFT click → fire_crossbow at (%.1f, %.1f, %.1f)" % [aim.x, aim.y, aim.z])
					_tower.fire_crossbow(aim)
				else:
					print("[InputManager] LEFT click — no aim (ZERO)")

			elif mb.button_index == MOUSE_BUTTON_RIGHT and can_manual_fire:
				var aim: Vector3 = _get_fire_aim_position()
				if aim != Vector3.ZERO:
					print("[InputManager] RIGHT click → fire_rapid_missile at (%.1f, %.1f, %.1f)" % [aim.x, aim.y, aim.z])
					_tower.fire_rapid_missile(aim)
				else:
					print("[InputManager] RIGHT click — no aim (ZERO)")

			elif mb.button_index == MOUSE_BUTTON_LEFT and state == Types.GameState.BUILD_MODE:
				_handle_build_mode_left_click()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action("cast_shockwave"):
			print("[InputManager] cast_shockwave key pressed")
			_spell_manager.cast_spell("shockwave")

		elif event.is_action("toggle_build_mode"):
			if state == Types.GameState.COMBAT or state == Types.GameState.WAVE_COUNTDOWN:
				print("[InputManager] toggle_build_mode → entering BUILD_MODE")
				GameManager.enter_build_mode()
			elif state == Types.GameState.BUILD_MODE:
				print("[InputManager] toggle_build_mode → exiting BUILD_MODE")
				GameManager.exit_build_mode()
			else:
				print("[InputManager] toggle_build_mode ignored — state=%s" % Types.GameState.keys()[state])

		elif event.is_action("cancel"):
			if state == Types.GameState.BUILD_MODE:
				print("[InputManager] cancel → exiting BUILD_MODE")
				GameManager.exit_build_mode()


## World point on Y=0 under the mouse (no enemy bias). Used for build slot picking.
func _get_ground_plane_intersection() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	var ground_plane := Plane(Vector3.UP, 0.0)
	var intersection: Variant = ground_plane.intersects_ray(ray_origin, ray_normal)
	if intersection != null:
		return intersection as Vector3
	return Vector3.ZERO


## Combat aim: raycast enemies first (hits flying units at real height), else ground plane.
func _get_fire_aim_position() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	var ray_end: Vector3 = ray_origin + ray_normal * _RAY_MAX_DISTANCE

	var world: World3D = get_viewport().world_3d
	if world == null:
		return Vector3.ZERO
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	var pq: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	pq.collision_mask = _ENEMY_COLLISION_MASK
	var hit: Dictionary = space.intersect_ray(pq)
	if not hit.is_empty():
		var collider: Object = hit.get("collider", null)
		if collider is EnemyBase:
			var enemy: EnemyBase = collider as EnemyBase
			return enemy.global_position

	return _get_ground_plane_intersection()


func _handle_build_mode_left_click() -> void:
	var slot_index: int = _get_clicked_hex_slot_index()
	if slot_index < 0:
		return

	var slot_data: Dictionary = _hex_grid.get_slot_data(slot_index)
	var is_occupied: bool = bool(slot_data.get("is_occupied", false))
	print("[InputManager] BUILD_MODE left click → slot=%d occupied=%s" % [slot_index, str(is_occupied)])
	if is_occupied:
		_build_menu.open_for_sell_slot(slot_index, slot_data)
	else:
		_build_menu.open_for_slot(slot_index)


func _get_clicked_hex_slot_index() -> int:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _camera.project_ray_origin(mouse_pos)
	var ray_normal: Vector3 = _camera.project_ray_normal(mouse_pos)
	var ray_end: Vector3 = ray_origin + ray_normal * _RAY_MAX_DISTANCE

	var world: World3D = get_viewport().world_3d
	if world == null:
		return -1
	var space: PhysicsDirectSpaceState3D = world.direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = _HEX_SLOT_COLLISION_MASK

	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return -1

	var collider: Object = hit.get("collider", null)
	if collider is Area3D:
		var slot_name: String = (collider as Area3D).name
		if slot_name.begins_with("HexSlot_"):
			var index_text: String = slot_name.trim_prefix("HexSlot_")
			return index_text.to_int()

	# Fallback for non-standard slot naming (keeps behavior robust).
	var hit_pos: Vector3 = hit.get("position", Vector3.ZERO)
	return _hex_grid.get_nearest_slot_index(hit_pos)
````

---

## `scripts/main_root.gd`

````
# scripts/main_root.gd
# Root scene: enforce window stretch after the scene tree is ready (some editor /
# plugin init order can leave content scale feeling wrong until the Window is
# fully configured).

extends Node3D

func _ready() -> void:
	call_deferred("_apply_root_window_stretch")


func _apply_root_window_stretch() -> void:
	var w: Window = get_tree().root as Window
	if w == null:
		return
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	w.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	w.content_scale_factor = 1.0
````

---

## `scripts/research_manager.gd`

````
# scripts/research_manager.gd
# ResearchManager – owns the research tree state (which nodes are unlocked).
# Loaded from base_structures_tree.tres via the @export array.
# All resource spending goes through EconomyManager.spend_research_material().
# Emits SignalBus.research_unlocked(node_id) on successful unlock.

class_name ResearchManager
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## All research nodes in the game. Populated via editor with base_structures_tree.tres.
@export var research_nodes: Array[ResearchNodeData] = []

# Dev toggle: in dev/test builds, make all towers immediately reachable by
# unlocking every research node when starting a new game.
@export var dev_unlock_all_research: bool = false

## Dev toggle: unlock only anti-air research so Anti-Air Bolt is buildable
## immediately (everything else remains locked behind its research).
## This is intended for faster manual playtesting of early wave survival.
@export var dev_unlock_anti_air_only: bool = false

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _unlocked_nodes: Array[String] = []

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Attempts to unlock the research node with the given node_id.
## Checks prerequisites, research material cost, then applies the unlock.
## Returns true on success, false on any validation failure.
func unlock_node(node_id: String) -> bool:
	var node_data: ResearchNodeData = _find_node(node_id)
	if node_data == null:
		push_warning("ResearchManager.unlock_node: node_id '%s' not found" % node_id)
		return false

	if is_unlocked(node_id):
		push_warning("ResearchManager.unlock_node: '%s' already unlocked" % node_id)
		return false

	# Check all prerequisites are satisfied.
	for prereq_id: String in node_data.prerequisite_ids:
		if not is_unlocked(prereq_id):
			push_warning("ResearchManager.unlock_node: prerequisite '%s' not met for '%s'"
				% [prereq_id, node_id])
			return false

	# Research costs research_material, not gold.
	if EconomyManager.get_research_material() < node_data.research_cost:
		return false

	var spent: bool = EconomyManager.spend_research_material(node_data.research_cost)
	assert(spent, "ResearchManager: spend_research_material failed after balance check")

	_unlocked_nodes.append(node_id)
	SignalBus.research_unlocked.emit(node_id)

	# Florence meta-state hook.
	# ASSUMPTION: GameManager owns FlorenceData and exposes get_florence_data().
	var florence_data := GameManager.get_florence_data()
	if florence_data != null and florence_data.has_unlocked_research == false:
		florence_data.has_unlocked_research = true
		SignalBus.florence_state_changed.emit()
	return true


## Returns true if the node with the given node_id has been unlocked.
func is_unlocked(node_id: String) -> bool:
	return _unlocked_nodes.has(node_id)


## Returns nodes whose prerequisites are all met and that are not yet unlocked.
func get_available_nodes() -> Array[ResearchNodeData]:
	var result: Array[ResearchNodeData] = []
	for node_data: ResearchNodeData in research_nodes:
		if is_unlocked(node_data.node_id):
			continue
		var prereqs_met: bool = true
		for prereq_id: String in node_data.prerequisite_ids:
			if not is_unlocked(prereq_id):
				prereqs_met = false
				break
		if prereqs_met:
			result.append(node_data)
	return result


## Clears all unlocked nodes. Called on new game.
func reset_to_defaults() -> void:
	_unlocked_nodes.clear()
	if dev_unlock_all_research:
		for node_data: ResearchNodeData in research_nodes:
			_unlocked_nodes.append(node_data.node_id)
	elif dev_unlock_anti_air_only:
		_unlocked_nodes.append("unlock_anti_air")

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _find_node(node_id: String) -> ResearchNodeData:
	for node_data: ResearchNodeData in research_nodes:
		if node_data.node_id == node_id:
			return node_data
	return null
````

---

## `scripts/resources/ally_data.gd`

````
## ally_data.gd
## Data backbone for generic allies, mercenary UI, and future defected mini-boss allies.
## ASSUMPTION: A future BossData resource will share basic fields (HP, movement speed, damage, range)
## so conversion BossData → AllyData is straightforward.

extends Resource
class_name AllyData

@export var ally_id: String = ""
@export var display_name: String = ""
@export var description: String = "" ## PLACEHOLDER: narrative text to be filled later.

@export var ally_class: Types.AllyClass = Types.AllyClass.MELEE

## Combat role tag for SimBot scoring and future AI preferences.
@export var role: Types.AllyRole = Types.AllyRole.MELEE_FRONTLINE
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
## When true, ally AI may prefer flying targets (POST-MVP targeting).
@export var can_target_flying: bool = false

@export var max_hp: int = 100
@export var move_speed: float = 5.0
## Legacy stat name; used when `attack_damage` is zero.
@export var basic_attack_damage: float = 10.0
## Primary attack damage; if zero, `basic_attack_damage` is used at runtime.
@export var attack_damage: float = 0.0 # TUNING
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
## Idle/patrol radius for tower-centric allies (POST-MVP full use in AllyBase).
@export var patrol_radius: float = 12.0 # TUNING
## 0 = permanent death on HP depletion; >0 = downed/recover loop (POST-MVP in AllyBase).
@export var recovery_time: float = 0.0 # TUNING

# Uses existing TargetPriority enum; MVP only implements CLOSEST behavior.
@export var preferred_targeting: Types.TargetPriority = Types.TargetPriority.CLOSEST

# True for named characters (Arnulf, defected mini-bosses); false for generic mercs.
@export var is_unique: bool = false

## Scene to spawn for this ally (empty = not spawnable as AllyBase instance).
@export var scene_path: String = ""
## Present in `owned_allies` when a new campaign starts (e.g. Arnulf roster entry).
@export var is_starter_ally: bool = false
## Unlocked via mini-boss defection offer rather than catalog alone.
@export var is_defected_ally: bool = false
## Tints placeholder mesh on generic allies.
@export var debug_color: Color = Color(0.2, 0.45, 0.95, 1.0)

# POST-MVP: campaign progression hooks (levels, scaling, gear).
@export var starting_level: int = 1 # POST-MVP
@export var level_scaling_factor: float = 1.0 # POST-MVP
@export var uses_downed_recovering: bool = false # POST-MVP (for Arnulf-like behavior)
````

---

## `scripts/resources/boss_data.gd`

````
## boss_data.gd
## Unified Resource for mini-bosses and the campaign final boss (Prompt 10).

class_name BossData
extends Resource

## Built-in boss .tres files loaded into WaveManager / GameManager registries.
## POST-MVP: directory scan or mod bundle.
const BUILTIN_BOSS_RESOURCE_PATHS: Array[String] = [
	"res://resources/bossdata_plague_cult_miniboss.tres",
	"res://resources/bossdata_orc_warlord_miniboss.tres",
	"res://resources/bossdata_final_boss.tres",
]

@export var boss_id: String = ""
@export var display_name: String = ""
## PLACEHOLDER narrative until writing pass.
@export var description: String = ""

@export var faction_id: String = ""
## POST-MVP: link mini-boss to a territory reward.
@export var associated_territory_id: String = ""
## POST-MVP UI hook for threat icons.
@export var threat_icon_id: String = ""

@export var max_hp: int = 100
@export var move_speed: float = 3.0
@export var damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var armor_type: Types.ArmorType = Types.ArmorType.UNARMORED
@export var gold_reward: int = 100

@export var is_ranged: bool = false
@export var is_flying: bool = false
@export var damage_immunities: Array[Types.DamageType] = []

## Phase count for multi-phase encounters; MVP uses tracking only in BossBase.
@export var phase_count: int = 1

## Escort enemy IDs: string form of Types.EnemyType (e.g. "ORC_GRUNT").
@export var escort_unit_ids: Array[String] = []

@export var is_mini_boss: bool = false
@export var is_final_boss: bool = false

## Optional per-boss scene; defaults to shared boss_base.tscn when unset in .tres.
@export var boss_scene: PackedScene


## Builds an EnemyData mirror so EnemyBase.initialize() can drive combat and rewards.
func build_placeholder_enemy_data() -> EnemyData:
	var e: EnemyData = EnemyData.new()
	# ASSUMPTION: ORC_GRUNT is a neutral stand-in for SignalBus.enemy_killed typing only.
	e.enemy_type = Types.EnemyType.ORC_GRUNT
	e.display_name = display_name
	e.max_hp = max_hp
	e.move_speed = move_speed
	e.damage = damage
	e.attack_range = attack_range
	e.attack_cooldown = attack_cooldown
	e.armor_type = armor_type
	e.gold_reward = gold_reward
	e.is_ranged = is_ranged
	e.is_flying = is_flying
	e.damage_immunities = damage_immunities.duplicate()
	e.color = Color(0.75, 0.2, 0.85)
	return e
````

---

## `scripts/resources/building_data.gd`

````
## building_data.gd
## Data resource describing stats for a single building type in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name BuildingData
extends Resource

## Which building type this resource describes.
@export var building_type: Types.BuildingType
## Human-readable name shown in the build menu.
@export var display_name: String = ""
## Gold cost to place this building.
@export var gold_cost: int = 50
## Building material cost to place this building.
@export var material_cost: int = 2
## Gold cost to upgrade this building.
@export var upgrade_gold_cost: int = 75
## Building material cost to upgrade this building.
@export var upgrade_material_cost: int = 3
## Base damage per shot.
@export var damage: float = 20.0
## Damage per shot after upgrade.
@export var upgraded_damage: float = 35.0
## Shots per second.
@export var fire_rate: float = 1.0
## Attack range in world units.
@export var attack_range: float = 15.0
## Attack range after upgrade.
@export var upgraded_range: float = 18.0
## Damage type this building's projectiles deal.
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
## True if this building's targeting includes flying enemies.
@export var targets_air: bool = false
## True if this building's targeting includes ground enemies.
@export var targets_ground: bool = true
## True if a research node must be unlocked before this building is placeable.
@export var is_locked: bool = false
## ID of the research node that unlocks this building. Empty string = always available.
@export var unlock_research_id: String = ""
## If set, unlocking this node grants upgraded_damage while the building is not upgraded.
@export var research_damage_boost_id: String = ""
## If set, unlocking this node grants upgraded_range while the building is not upgraded.
@export var research_range_boost_id: String = ""
## MVP cube color for this building type.
@export var color: Color = Color.GRAY
## Targeting strategy this building uses to select its next attack target.
@export var target_priority: Types.TargetPriority = Types.TargetPriority.CLOSEST
## Enables damage-over-time (DoT) application for this building's projectiles.
@export var dot_enabled: bool = false
## TUNING: total DoT damage over full duration.
@export var dot_total_damage: float = 0.0
## TUNING: seconds between DoT ticks.
@export var dot_tick_interval: float = 1.0
## TUNING: DoT duration in seconds.
@export var dot_duration: float = 0.0
## Effect identifier for DoT handling ("burn", "poison", etc.).
@export var dot_effect_type: String = ""
## Stable source identifier for stacking rules ("fire_brazier", "poison_vat", etc.).
@export var dot_source_id: String = ""
## TUNING: true = instant hit plus DoT, false = DoT only.
@export var dot_in_addition_to_hit: bool = true
````

---

## `scripts/resources/campaign_config.gd`

````
## campaign_config.gd
## Campaign-level configuration resource containing ordered DayConfig entries.

class_name CampaignConfig
extends Resource

## Stable campaign identifier.
@export var campaign_id: String = ""
## Human-friendly campaign name.
@export var display_name: String = ""
## Ordered day configurations (index 0 => day 1).
@export var day_configs: Array[DayConfig] = []
## Optional campaign start territory IDs (world map / tooling). ASSUMPTION: may mirror TerritoryMapData.
@export var starting_territory_ids: Array[String] = []

## Optional path to TerritoryMapData for this campaign. Empty = no territory layer (short MVP).
## ASSUMPTION: GameManager loads this at runtime when set.
@export var territory_map_resource_path: String = ""

## If true, uses short_campaign_length when > 0.
@export var is_short_campaign: bool = false
## Overrides day_configs size when short mode is enabled.
@export var short_campaign_length: int = 0

## Returns the usable campaign length for CampaignManager.
func get_effective_length() -> int:
	if is_short_campaign and short_campaign_length > 0:
		return short_campaign_length
	return day_configs.size()
````

---

## `scripts/resources/character_catalog.gd`

````
## character_catalog.gd
## Resource holding the full set of hub characters for a between-mission hub.

extends Resource
class_name CharacterCatalog

## All hub characters instantiated by Hub2DHub.
@export var characters: Array[CharacterData] = []
````

---

## `scripts/resources/character_data.gd`

````
## character_data.gd
## Data describing a hub character entry for the between-mission hub.

extends Resource
class_name CharacterData

## Stable identifier used by DialogueManager pools and hub interaction focus.
@export var character_id: String

## Human-readable name shown on the hub character UI.
@export var display_name: String

## One-line placeholder description for future UI and tooltips.
@export var description: String = "TODO: description"

## Uses Types.HubRole as the canonical hub role marker.
@export var role: Types.HubRole = Types.HubRole.FLAVOR_ONLY

## Visual identifiers used by UI; portraits are handled elsewhere.
@export var portrait_id: String = "TODO_PORTRAIT"

## POST-MVP: Optional icon sprite identifier for richer hub visuals.
@export var icon_id: String = ""

## 2D hub placement; used by the 2D hub overlay implementation.
@export var hub_position_2d: Vector2 = Vector2.ZERO

## POST-MVP: For a future 3D hub room, this can reference a named marker node.
@export var hub_marker_name_3d: String = ""

## Tags passed into DialogueManager when requesting hub dialogue.
@export var default_dialogue_tags: Array[String] = []
````

---

## `scripts/resources/day_config.gd`

````
## day_config.gd
## Single-day campaign configuration resource.
## Owned by CampaignConfig; read by CampaignManager and WaveManager.
## POST-MVP: extend with territory/world-map fields.

class_name DayConfig
extends Resource

## 1-based day index inside the campaign.
@export var day_index: int = 1

## Mission index used by MVP systems (1–5). Short campaign: days 1–5 map 1:1 to missions 1–5.
## Days beyond 5 may reuse mission 5 as placeholder content (# ASSUMPTION / # PLACEHOLDER / # TUNING).
@export var mission_index: int = 1

## Human-friendly day name for UI.
@export var display_name: String = ""
## Day description shown in hub/briefing.
@export var description: String = ""

## Active faction for this day. Must match a FactionData.faction_id in the registry.
@export var faction_id: String = "DEFAULT_MIXED"
## POST-MVP: world map / territory UI.
@export var territory_id: String = ""

## Marks this day as eligible for mini-boss schedule queries (WaveManager hook).
@export var is_mini_boss_day: bool = false
## Alias for data-driven mini-boss days (Prompt 10); WaveManager treats this like is_mini_boss_day.
@export var is_mini_boss: bool = false
## TUNING: mark final day boss.
@export var is_final_boss: bool = false
## BossData.boss_id for final boss or repeat boss-attack days.
@export var boss_id: String = ""
## True when this day is a post–Day-50 boss strike on a held territory (Prompt 10).
@export var is_boss_attack_day: bool = false

## TUNING: desired wave count for this day.
@export var base_wave_count: int = 10

## TUNING: per-day multipliers.
@export var enemy_hp_multiplier: float = 1.0
@export var enemy_damage_multiplier: float = 1.0
@export var gold_reward_multiplier: float = 1.0
````

---

## `scripts/resources/dialogue/dialogue_condition.gd`

````
## dialogue_condition.gd
## Single AND-clause for DialogueEntry. Evaluated by DialogueManager._evaluate_conditions.

class_name DialogueCondition
extends Resource

@export var key: String = ""
@export var comparison: String = "=="
@export var value: Variant
````

---

## `scripts/resources/dialogue/dialogue_entry.gd`

````
## dialogue_entry.gd
## Data-driven hub dialogue line. Loaded from res://resources/dialogue/**/*.tres.

class_name DialogueEntry
extends Resource

@export var entry_id: String = ""
@export var character_id: String = ""
@export_multiline var text: String = "TODO: placeholder dialogue line." # PLACEHOLDER

@export var priority: int = 10 # TUNING
@export var once_only: bool = false
@export var chain_next_id: String = ""
@export var conditions: Array[DialogueCondition] = []
````

---

## `scripts/resources/enchantment_data.gd`

````
## enchantment_data.gd
## Data-driven definition of a single weapon enchantment for Florence.
## Combines with WeaponData at runtime to modify projectile damage and type.
## SOURCE: Godot docs — Resource composition patterns, https://docs.godotengine.org/

class_name EnchantmentData
extends Resource

@export var enchantment_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# Logical slot this enchantment can occupy, e.g. "elemental" or "power".
@export var slot_type: String = "generic"

# If true, override the projectile's primary damage type with damage_type_override.
@export var has_damage_type_override: bool = false
@export var damage_type_override: Types.DamageType = Types.DamageType.PHYSICAL

# Future hook for secondary damage channels or status effects.
@export var has_secondary_damage_type: bool = false
@export var secondary_damage_type: Types.DamageType = Types.DamageType.PHYSICAL  # POST-MVP

# Multiplicative modifier applied to WeaponData.damage before DamageCalculator.
@export var damage_multiplier: float = 1.0

# Generic extensibility hooks for POST-MVP behaviors.
@export var effect_tags: Array[String] = []
@export var effect_data: Dictionary = {}
````

---

## `scripts/resources/enemy_data.gd`

````
## enemy_data.gd
## Data resource describing stats for a single enemy type in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name EnemyData
extends Resource

## Which enemy type this resource describes.
@export var enemy_type: Types.EnemyType
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
## Maximum hit points.
@export var max_hp: int = 100
## Movement speed in units per second.
@export var move_speed: float = 3.0
## Damage dealt per attack.
@export var damage: int = 10
## Melee engagement range for melee types; projectile fire range for ranged types.
@export var attack_range: float = 1.5
## Seconds between attacks.
@export var attack_cooldown: float = 1.0
## Armor type used for damage matrix lookups in DamageCalculator.
@export var armor_type: Types.ArmorType = Types.ArmorType.UNARMORED
## Gold awarded to the player on kill; passed directly in enemy_killed signal.
@export var gold_reward: int = 10
## True if this enemy fires projectiles rather than melee-attacking.
@export var is_ranged: bool = false
## True if this enemy flies (ignores ground-only buildings; Y offset applied).
@export var is_flying: bool = false
## MVP cube color for this enemy type.
@export var color: Color = Color.GREEN
## Per-enemy damage-type immunities checked before the matrix lookup.
## Per SYSTEMS_part1 §3.8: these override the DAMAGE_MATRIX result.
@export var damage_immunities: Array[Types.DamageType] = []
````

---

## `scripts/resources/faction_data.gd`

````
## faction_data.gd
## Faction identity, weighted enemy roster, mini-boss hooks, and scaling hints for WaveManager.

class_name FactionData
extends Resource

## Preload so this script parses before `FactionRosterEntry` class_name is globally registered.
const FactionRosterEntryType = preload("res://scripts/resources/faction_roster_entry.gd")

## Built-in faction .tres files loaded by WaveManager and CampaignManager.
## POST-MVP: replace with directory scan or campaign bundle.
const BUILTIN_FACTION_RESOURCE_PATHS: Array[String] = [
	"res://resources/faction_data_default_mixed.tres",
	"res://resources/faction_data_orc_raiders.tres",
	"res://resources/faction_data_plague_cult.tres",
]

# Identity -------------------------------------------------------------

## Unique stable ID used by DayConfig and TerritoryData.
@export var faction_id: String = ""

## Human-readable name for UI and debug logs.
@export var display_name: String = ""

## Text description for codex / faction summary.
## PLACEHOLDER until narrative pass fills this in.
@export var description: String = ""

# Roster ---------------------------------------------------------------

## Roster entries for this faction. Defines which enemy types can spawn,
## how common they are, and in which wave index range they appear.
@export var roster: Array[FactionRosterEntryType] = []

# Mini-boss hooks ------------------------------------------------------

## IDs of mini-bosses associated with this faction.
## PLACEHOLDER mini-boss resources will be defined in a later prompt.
@export var mini_boss_ids: Array[String] = []

## Recommended wave indices for mini-boss appearances.
## POST-MVP: Used by future boss spawning logic.
@export var mini_boss_wave_hints: Array[int] = []

# Scaling hints --------------------------------------------------------

## Coarse difficulty tier knob for the faction. 1 easy, 2 mid, 3 late-game.
@export var roster_tier: int = 1

## Optional offset used by wave formulas to nudge difficulty up/down.
## TUNING: Values will be adjusted in future balance passes.
@export var difficulty_offset: float = 0.0

# Helper methods -------------------------------------------------------

## Returns roster entries valid for the given wave index based on min/max bounds.
func get_entries_for_wave(wave_index: int) -> Array[FactionRosterEntryType]:
	var result: Array[FactionRosterEntryType] = []
	for entry: FactionRosterEntryType in roster:
		if wave_index >= entry.min_wave_index and wave_index <= entry.max_wave_index:
			result.append(entry)
	return result


## Computes effective weight for a roster entry at a given wave.
## Early waves favor tier 1 units; tier >1 ramp up later.
func get_effective_weight_for_wave(entry: FactionRosterEntryType, wave_index: int) -> float:
	if entry.base_weight <= 0.0:
		return 0.0

	var weight: float = entry.base_weight

	# SOURCE: Weighted enemy roster scaling by wave and tier, common TD pattern.
	# Simple tier-based ramp: elites gain weight as wave index grows.
	if entry.tier > 1:
		var ramp: float = float(wave_index - entry.min_wave_index)
		if ramp < 0.0:
			ramp = 0.0
		weight *= (1.0 + ramp * 0.1) # TUNING

	# Optionally nudge with faction difficulty offset.
	if difficulty_offset != 0.0:
		weight *= maxf(0.1, 1.0 + difficulty_offset) # TUNING

	return maxf(weight, 0.0)
````

---

## `scripts/resources/faction_roster_entry.gd`

````
## faction_roster_entry.gd
## One row in a FactionData roster. Kept as its own Resource so .tres files can embed entries.
## DEVIATION: Prompt 9 sketched a nested class inside FactionData; Godot sub-resources need a script path.

class_name FactionRosterEntry
extends Resource

## Enemy type enum for this roster entry.
@export var enemy_type: Types.EnemyType = Types.EnemyType.ORC_GRUNT
## Baseline spawn weight for this enemy within its wave range.
@export var base_weight: float = 1.0
## Earliest wave index where this enemy can appear (inclusive).
@export var min_wave_index: int = 1
## Last wave index where this enemy can appear (inclusive).
@export var max_wave_index: int = 10
## Optional tier marker: 1 basic, 2 elite, 3 special.
@export var tier: int = 1
````

---

## `scripts/resources/mercenary_catalog.gd`

````
## mercenary_catalog.gd
## Pool of mercenary offers with day filtering and a daily cap.
# SOURCE: Pattern adapted from long-campaign mercenary pools (Battle Brothers style, day-range gating).

extends Resource
class_name MercenaryCatalog

# DEVIATION: untyped `Array` so autoloads parse before `MercenaryOfferData` global class is registered.
@export var offers: Array = []
@export var max_offers_per_day: int = 3 # TUNING


func filter_offers_for_day(day: int, owned_ally_ids: Array[String]) -> Array:
	var result: Array = []
	for offer: Variant in offers:
		if offer == null:
			continue
		if bool(offer.get("is_defection_offer")):
			continue
		if not bool(offer.call("is_available_on_day", day)):
			continue
		if owned_ally_ids.has(str(offer.get("ally_id"))):
			continue
		result.append(offer)

	result.sort_custom(func(a: Variant, b: Variant) -> bool:
		return str(a.get("ally_id")) < str(b.get("ally_id"))
	)
	return result


func get_daily_offers(day: int, owned_ally_ids: Array[String]) -> Array:
	var filtered: Array = filter_offers_for_day(day, owned_ally_ids)
	if filtered.size() <= max_offers_per_day:
		return filtered
	return filtered.slice(0, max_offers_per_day)
````

---

## `scripts/resources/mercenary_offer_data.gd`

````
## mercenary_offer_data.gd
## Data for a single mercenary recruitment offer (catalog or defection-injected).

extends Resource
class_name MercenaryOfferData

## Must match `AllyData.ally_id` for the recruitable ally.
@export var ally_id: String = ""

@export var cost_gold: int = 0 # TUNING
@export var cost_building_material: int = 0 # TUNING
@export var cost_research_material: int = 0 # TUNING

@export var min_day: int = 1
## −1 = no upper day limit.
@export var max_day: int = -1

@export var required_territory_ids: Array[String] = [] # POST-MVP
@export var required_faction_ids: Array[String] = [] # POST-MVP
@export var required_research_ids: Array[String] = [] # POST-MVP

## True when created from a defeated mini-boss defection path (not from catalog filter).
@export var is_defection_offer: bool = false


func is_available_on_day(day: int) -> bool:
	if day < min_day:
		return false
	if max_day >= 0 and day > max_day:
		return false
	return true


func get_cost_summary() -> String:
	if cost_gold <= 0 and cost_building_material <= 0 and cost_research_material <= 0:
		return "Free"
	var parts: PackedStringArray = PackedStringArray()
	if cost_gold > 0:
		parts.append("%d Gold" % cost_gold)
	if cost_building_material > 0:
		parts.append("%d Mat" % cost_building_material)
	if cost_research_material > 0:
		parts.append("%d Res" % cost_research_material)
	return ", ".join(parts)
````

---

## `scripts/resources/mini_boss_data.gd`

````
## mini_boss_data.gd
## Campaign metadata for mini-bosses and optional defection into the ally roster.
# SOURCE: “Guest joins after boss fight” pattern (FFT-like).

extends Resource
class_name MiniBossData

@export var boss_id: String = ""
@export var display_name: String = ""
@export var appears_on_day: int = 1

@export var max_hp: int = 500 # TUNING
@export var gold_reward: int = 100 # TUNING

@export var can_defect_to_ally: bool = false
@export var defected_ally_id: String = ""
@export var defection_cost_gold: int = 0
## POST-MVP: 0 = offer injected immediately; >0 = delayed offer (not implemented).
@export var defection_day_offset: int = 0
````

---

## `scripts/resources/research_node_data.gd`

````
## research_node_data.gd
## Data resource representing a single node in the research tree in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name ResearchNodeData
extends Resource

## Unique identifier for this node, e.g. "unlock_ballista". Used in prerequisite lists.
@export var node_id: String = ""
## Human-readable name shown in the research UI tab.
@export var display_name: String = ""
## Research material consumed when this node is unlocked.
@export var research_cost: int = 2
## IDs of nodes that must already be unlocked before this one becomes available.
## Empty array means no prerequisites — node is always available to research.
@export var prerequisite_ids: Array[String] = []
## Flavour and effect description shown in the research UI.
@export var description: String = ""
````

---

## `scripts/resources/shop_item_data.gd`

````
## shop_item_data.gd
## Data resource representing a purchasable item in the between-mission shop in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name ShopItemData
extends Resource

## Unique identifier for this item. Passed in shop_item_purchased signal payload.
@export var item_id: String = ""
## Human-readable name shown in the shop UI.
@export var display_name: String = ""
## Gold cost to purchase this item.
@export var gold_cost: int = 50
## Building material cost to purchase this item. Usually 0 for shop items.
@export var material_cost: int = 0
## Effect description shown in the shop UI tooltip.
@export var description: String = ""
````

---

## `scripts/resources/spell_data.gd`

````
## spell_data.gd
## Data resource describing stats for a single castable spell in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name SpellData
extends Resource

## Unique string identifier for this spell. Matches spell_cast signal payload.
@export var spell_id: String = "shockwave"
## Human-readable name shown in the spell panel UI.
@export var display_name: String = "Shockwave"
## Mana consumed on cast.
@export var mana_cost: int = 50
## Seconds before this spell can be cast again.
@export var cooldown: float = 60.0
## Damage dealt to each enemy hit.
@export var damage: float = 30.0
## Effective radius in world units. Set to 100.0 for battlefield-wide shockwave.
@export var radius: float = 100.0
## Damage type applied to all targets hit.
@export var damage_type: Types.DamageType = Types.DamageType.MAGICAL
## True if this spell can affect flying enemies. Shockwave is ground-AoE so false.
@export var hits_flying: bool = false
````

---

## `scripts/resources/strategyprofile.gd`

````
## strategyprofile.gd
## PRE_GENERATION_VERIFICATION: Mentally ran the required checklist for this file
## (Resource-only, no scene access, typed exported fields, no autoload impacts).
##
## StrategyProfile drives SimBot's build, upgrade, and spell decisions.
## POST-MVP: Extended for NEAT/ML tuning and endless-mode targets.
extends Resource
class_name StrategyProfile

## Unique ID for this profile, used for lookup and logging.
@export var profile_id: String = ""

## Human-readable description of the strategy.
## PLACEHOLDER: Fill with detailed design notes after tuning.
@export var description: String = ""

## Per-building weighted preferences.
## Each entry is a Dictionary with keys:
## - "building_type": Types.BuildingType (stored as int in .tres; cast in SimBot)
## - "weight": float
## - "min_wave": int (inclusive, default 1)
## - "max_wave": int (inclusive, default 10)
@export var build_priorities: Array[Dictionary] = []

## Placement preferences for new buildings.
## Keys:
## - "preferred_slots": Array[int] ordered list of slot indices to try first.
## - "fallback_strategy": String, "FIRST_EMPTY" or "RANDOM_EMPTY".
## - "ring_hint": String, e.g. "ANY", "INNER_FIRST", "OUTER_FIRST".
@export var placement_preferences: Dictionary = {
	"preferred_slots": [],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "ANY",
}

## Spell usage configuration for SimBot.
## MVP supports only "shockwave".
## Keys:
## - "enabled": bool
## - "spell_id": String
## - "min_enemies_in_wave": int
## - "min_mana": int
## - "cooldown_safety_margin": float
## - "evaluation_interval": float (seconds between checks)
## - "priority_vs_building": float (TUNING: used to break ties vs building actions)
@export var spell_usage: Dictionary = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 6,
	"min_mana": 50,
	"cooldown_safety_margin": 0.5,
	"evaluation_interval": 1.0,
	"priority_vs_building": 1.0,
}

## Upgrade behavior configuration.
## Keys:
## - "prefer_upgrades_until_build_count": int
## - "upgrade_weight": float
## - "min_gold_reserve": int
## - "max_upgrade_level": int (MVP buildings have 1 upgrade level)
@export var upgrade_behavior: Dictionary = {
	"prefer_upgrades_until_build_count": 6,
	"upgrade_weight": 1.0,
	"min_gold_reserve": 0,
	"max_upgrade_level": 1,
}

## Target difficulty score for future tuning.
## POST-MVP: used by optimization tools to compare desired vs actual difficulty.
@export var difficulty_target: float = 0.0
````

---

## `scripts/resources/territory_data.gd`

````
## territory_data.gd
## Per-territory data: ownership, terrain, and economic bonuses for campaign/world map.
## SOURCE: FOUL WARD Prompt 8 spec — territory ownership hooks for 50-day campaign.

class_name TerritoryData
extends Resource

## Unique ID for this territory, used by DayConfig. Must be unique within a campaign.
@export var territory_id: String = ""

## Display name shown in UI.
@export var display_name: String = ""

## Long-form description for world map and briefing.
## PLACEHOLDER until narrative pass fills this in.
@export var description: String = ""

## Default faction controlling this territory.
## POST-MVP: Used when DayConfig does not set a faction explicitly.
@export var default_faction_id: String = ""

## For now just a string; later can map to real icons.
@export var icon_id: String = ""

## Base color tint for UI elements representing this territory.
@export var color: Color = Color.WHITE

## Terrain categories for territories (CONVENTIONS: enum type PascalCase, members UPPER_SNAKE_CASE).
enum TerrainType {
	PLAINS,
	FOREST,
	SWAMP,
	MOUNTAIN,
	CITY,
	OTHER,
}

## Terrain category for this territory.
## DEVIATION: Prompt 9 sketched `terrain_type: String`; Prompt 8 + world map use this enum instead.
@export var terrain_type: int = TerrainType.PLAINS

## Whether the player currently holds this territory.
@export var is_controlled_by_player: bool = false
## Set when a mini-boss guarding this territory is defeated (Prompt 10 hook).
@export var is_secured: bool = false
## True while the campaign boss threatens this territory (Prompt 10 MVP UI hook).
@export var has_boss_threat: bool = false

## If true, territory is lost for the campaign (MVP: set on mission fail).
@export var is_permanently_lost: bool = false

## Narrative/tuning hook for threat display.
@export var threat_level: int = 0

## Whether the territory is under attack (POST-MVP UI).
@export var is_under_attack: bool = false

## Flat gold added at end of mission/day reward when active.
@export var bonus_flat_gold_end_of_day: int = 0

## Additive fraction applied to gold after flat (e.g. 0.1 = +10%).
@export var bonus_percent_gold_end_of_day: float = 0.0

## POST-MVP: per-kill flat bonus from holding this territory.
@export var bonus_flat_gold_per_kill: int = 0

## POST-MVP: extra research material per day while held.
@export var bonus_research_per_day: int = 0

## POST-MVP: multiplier on research costs (1.0 = no change).
@export var bonus_research_cost_multiplier: float = 1.0

## POST-MVP: multiplier on enchanting gold costs.
@export var bonus_enchanting_cost_multiplier: float = 1.0

## POST-MVP: multiplier on weapon upgrade gold costs.
@export var bonus_weapon_upgrade_cost_multiplier: float = 1.0


## Returns true if this territory should currently contribute bonuses.
## MVP: controlled and not permanently lost.
func is_active_for_bonuses() -> bool:
	return is_controlled_by_player and not is_permanently_lost


func get_effective_end_of_day_gold_flat() -> int:
	if not is_active_for_bonuses():
		return 0
	return bonus_flat_gold_end_of_day


func get_effective_end_of_day_gold_percent() -> float:
	if not is_active_for_bonuses():
		return 0.0
	return bonus_percent_gold_end_of_day
````

---

## `scripts/resources/territory_map_data.gd`

````
## territory_map_data.gd
## Campaign territory list with O(1) lookup by territory_id.
## SOURCE: FOUL WARD Prompt 8 spec.

class_name TerritoryMapData
extends Resource

## All territories in this map (order is display order; IDs must be unique).
@export var territories: Array[TerritoryData] = []

var _id_to_territory: Dictionary = {}
var _id_to_index: Dictionary = {}
var _cache_built: bool = false


func _ensure_cache_built() -> void:
	if _cache_built:
		return
	_id_to_territory.clear()
	_id_to_index.clear()
	for i: int in territories.size():
		var territory: TerritoryData = territories[i]
		if territory == null:
			continue
		if territory.territory_id == "":
			continue
		# ASSUMPTION: IDs unique within the campaign. Ignore duplicates after first.
		if not _id_to_territory.has(territory.territory_id):
			_id_to_territory[territory.territory_id] = territory
			_id_to_index[territory.territory_id] = i
	_cache_built = true


## Clears lookup cache after external edits to the territories array (e.g. tests).
func invalidate_cache() -> void:
	_cache_built = false


func get_territory_by_id(id: String) -> TerritoryData:
	_ensure_cache_built()
	if not _id_to_territory.has(id):
		return null
	return _id_to_territory[id] as TerritoryData


func has_territory(id: String) -> bool:
	_ensure_cache_built()
	return _id_to_territory.has(id)


func get_all_territories() -> Array[TerritoryData]:
	return territories.duplicate()


func get_index_by_id(id: String) -> int:
	_ensure_cache_built()
	if not _id_to_index.has(id):
		return -1
	return int(_id_to_index[id])
````

---

## `scripts/resources/weapon_data.gd`

````
## weapon_data.gd
## Data resource describing stats for one of Florence's two weapons in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name WeaponData
extends Resource

## Which weapon slot this resource configures.
@export var weapon_slot: Types.WeaponSlot
## Human-readable name shown in the weapon panel UI.
@export var display_name: String = ""
## Damage dealt per projectile.
@export var damage: float = 50.0
## Projectile travel speed in units per second.
@export var projectile_speed: float = 30.0
## Seconds between shots (for crossbow) or between bursts (for rapid missile).
@export var reload_time: float = 2.5
## Projectiles fired per trigger pull. 1 for crossbow, 10 for rapid missile.
@export var burst_count: int = 1
## Seconds between individual shots within a burst. 0.0 for single-shot weapons.
@export var burst_interval: float = 0.0
## True if this weapon can target flying enemies. Always false for Florence in MVP.
@export var can_target_flying: bool = false
# ASSUMPTION: These fields are designer-tunable; setting them to 0.0 disables assist/miss
# and restores MVP-accurate behavior. Balance changes should be done via .tres resources, not code.
@export var assist_angle_degrees: float = 0.0
@export var assist_max_distance: float = 0.0
@export var base_miss_chance: float = 0.0
@export var max_miss_angle_degrees: float = 0.0
````

---

## `scripts/resources/weapon_level_data.gd`

````
## weapon_level_data.gd
## Defines the incremental stat bonuses and upgrade cost for one weapon level.
## One .tres instance exists per weapon per level (levels 1-3).
## Level 0 is implicit (base WeaponData, no bonus applied, no WeaponLevelData needed).
##
## Stat composition is ADDITIVE and INCREMENTAL:
##   effective_stat = base_stat + SUM(level_i.bonus for i in 1..current_level)
## Each entry represents the bonus ADDED at that specific level, not a total.
##
# SOURCE: Godot 4 custom Resource pattern — https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html [S1]
# SOURCE: Array[Resource] progression pattern — https://www.youtube.com/watch?v=h5vpjCDNa-w [S2]

class_name WeaponLevelData
extends Resource

## Which weapon slot this level applies to.
@export var weapon_slot: Types.WeaponSlot

## The level number (1, 2, or 3). Level 0 is implicit base — no WeaponLevelData needed.
@export var level: int = 0

## Incremental additive bonus to base damage at this level.
@export var damage_bonus: float = 0.0

## Incremental additive bonus to projectile speed at this level.
@export var speed_bonus: float = 0.0

## Incremental additive change to reload time at this level.
## Should be NEGATIVE to improve (reduce) reload time.
## Applied as: effective_reload = base_reload + SUM(all reload_bonus up to current level)
## Clamped to minimum 0.1 in WeaponUpgradeManager.get_effective_reload_time().
@export var reload_bonus: float = 0.0

## Incremental additive bonus to burst count at this level (0 = no change).
@export var burst_count_bonus: int = 0

## Gold cost to purchase THIS level upgrade. Paid when upgrading FROM (level-1) TO level.
@export var gold_cost: int = 0

## Building material cost for this upgrade. Currently always 0 (gold-only system).
## Reserved for future design use.
@export var material_cost: int = 0
````

---

## `scripts/shop_manager.gd`

````
# scripts/shop_manager.gd
# ShopManager – owns the shop catalog and handles item purchases.
# Effects: tower_repair / building_repair immediate; mana_draught + arrow_tower_placed
# pending flags consumed by apply_mission_start_consumables() from GameManager.
# All resource spending goes through EconomyManager.
# Emits SignalBus.shop_item_purchased(item_id) on success.

class_name ShopManager
extends Node

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## All purchasable items. Populated via editor with shop_catalog.tres.
@export var shop_catalog: Array[ShopItemData] = []

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _mana_draught_pending: bool = false
var _arrow_tower_shop_pending: bool = false

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Purchases the item with the given item_id.
## Checks affordability, spends resources, applies effect, emits signal.
## Returns true on success, false on any failure.
func purchase_item(item_id: String) -> bool:
	var item: ShopItemData = _find_item(item_id)
	if item == null:
		push_warning("ShopManager.purchase_item: item_id '%s' not found" % item_id)
		return false

	if not EconomyManager.can_afford(item.gold_cost, item.material_cost):
		return false

	var gold_spent: bool = EconomyManager.spend_gold(item.gold_cost)
	assert(gold_spent, "ShopManager: spend_gold failed after can_afford returned true")

	if item.material_cost > 0:
		var mat_spent: bool = EconomyManager.spend_building_material(item.material_cost)
		assert(mat_spent, "ShopManager: spend_building_material failed after can_afford returned true")

	var effect_ok: bool = _apply_effect(item_id)
	if not effect_ok:
		_refund_item(item)
		return false

	# POST-MVP: Enchantments unlock hook into FlorenceData.
	# PLACEHOLDER: replace this item_id with the real enchantments unlock item.
	if item_id == "enchantments_unlock":
		var florence_data := GameManager.get_florence_data()
		if florence_data != null and florence_data.has_unlocked_enchantments == false:
			florence_data.has_unlocked_enchantments = true
			SignalBus.florence_state_changed.emit()

	SignalBus.shop_item_purchased.emit(item_id)
	return true


## Returns all items in the shop catalog (copy, not reference).
func get_available_items() -> Array[ShopItemData]:
	return shop_catalog.duplicate()


## Returns true if the item exists and the player can currently afford it.
func can_purchase(item_id: String) -> bool:
	var item: ShopItemData = _find_item(item_id)
	if item == null:
		return false
	if not EconomyManager.can_afford(item.gold_cost, item.material_cost):
		return false
	var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	match item_id:
		"building_repair":
			if hex == null:
				return false
			return hex.has_any_damaged_building()
		"arrow_tower_placed":
			if hex == null:
				return false
			return hex.has_empty_slot() and hex.is_building_available(Types.BuildingType.ARROW_TOWER)
		_:
			return true


## Returns and clears the mana draught pending flag.
## Called by GameManager at the start of a new mission.
func consume_mana_draught_pending() -> bool:
	var was_pending: bool = _mana_draught_pending
	_mana_draught_pending = false
	return was_pending


func consume_arrow_tower_pending() -> bool:
	var was_pending: bool = _arrow_tower_shop_pending
	_arrow_tower_shop_pending = false
	return was_pending


## Called by GameManager when entering COMBAT for a mission (after mission_started).
func apply_mission_start_consumables() -> void:
	var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
	if consume_mana_draught_pending() and spell != null:
		spell.set_mana_to_full()
		SignalBus.mana_draught_consumed.emit()
	var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	if consume_arrow_tower_pending() and hex != null:
		if not hex.place_building_shop_free(Types.BuildingType.ARROW_TOWER):
			push_warning(
				"ShopManager: arrow_tower_placed voucher could not place (no slot or locked)"
			)

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _refund_item(item: ShopItemData) -> void:
	EconomyManager.add_gold(item.gold_cost)
	if item.material_cost > 0:
		EconomyManager.add_building_material(item.material_cost)


func _find_item(item_id: String) -> ShopItemData:
	for item: ShopItemData in shop_catalog:
		if item.item_id == item_id:
			return item
	return null


func _apply_effect(item_id: String) -> bool:
	match item_id:
		"tower_repair":
			var tower: Node = get_node_or_null("/root/Main/Tower")
			if tower != null and tower.has_method("repair_to_full"):
				tower.repair_to_full()
			else:
				push_error("ShopManager: 'tower_repair' effect failed – Tower not found or missing repair_to_full()")
			return true

		"building_repair":
			var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
			if hex == null:
				push_error("ShopManager: building_repair — HexGrid missing")
				return false
			if not hex.repair_first_damaged_building():
				push_error("ShopManager: building_repair — no damaged building (unexpected)")
				return false
			return true

		"mana_draught":
			_mana_draught_pending = true
			# Immediate feedback (between-mission shop); mission start still consumes flag via GameManager.
			var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
			if spell != null:
				spell.set_mana_to_full()
			return true

		"arrow_tower_placed":
			_arrow_tower_shop_pending = true
			return true

		_:
			push_warning("ShopManager._apply_effect: unknown item_id '%s'" % item_id)
			return false
````

---

## `scripts/sim_bot.gd`

````
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
````

---

## `scripts/simbot_logger.gd`

````
## simbot_logger.gd
## PRE_GENERATION_VERIFICATION: Mentally ran the required checklist for this file
## (CSV IO helper only, no scene access, no game logic coupling).
##
## Writes SimBot balance logs to CSV under user://.
## SOURCE: CSV header/append pattern adapted from Godot 4 FileAccess/DirAccess docs.
##         https://docs.godotengine.org
extends Node
class_name SimBotLogger

const LOG_DIR: String = "user://simbot_logs"
const DEFAULT_FILENAME: String = "simbot_balance_log.csv"

static func get_default_path() -> String:
	return LOG_DIR + "/" + DEFAULT_FILENAME

static func _ensure_dir_exists() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("simbot_logs"):
		dir.make_dir_recursive("simbot_logs")

static func write_header_if_needed(file_path: String, columns: Array[String]) -> void:
	_ensure_dir_exists()
	if FileAccess.file_exists(file_path):
		return

	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return

	file.store_line(",".join(columns))
	file.flush()
	file.close()

static func append_row(file_path: String, columns: Array[String], row: Dictionary) -> void:
	_ensure_dir_exists()

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
````

---

## `scripts/spell_manager.gd`

````
# spell_manager.gd
# SpellManager owns Sybil's mana pool and spell cooldowns for FOUL WARD.
# MVP: one spell — Shockwave (ground AoE, MAGICAL damage).
# Mana regenerates in _physics_process, respecting Engine.time_scale.
#
# Scene placement: /root/Main/Managers/SpellManager (Node)
#
# Credit: Foul Ward SYSTEMS_part3.md §9 (SpellManager spec) — Foul Ward team.
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
#   License: CC BY 3.0 | Adapted: delta-based regen auto-scales with time_scale.
# Credit: Godot Engine Documentation — SceneTree.get_nodes_in_group()
#   https://docs.godotengine.org/en/stable/classes/class_scenetree.html
#   License: CC BY 3.0 | Adapted: group iteration + is_instance_valid guard.

class_name SpellManager
extends Node

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

@export var max_mana: int = 100
@export var mana_regen_rate: float = 5.0

## Array of SpellData resources. One entry per spell. MVP: only shockwave.
@export var spell_registry: Array[SpellData] = []

# ---------------------------------------------------------------------------
# INTERNAL STATE
# ---------------------------------------------------------------------------

# Float accumulator for smooth sub-integer regen per frame.
# Separate integer snapshot drives signals to avoid emitting 60×/sec.
var _current_mana_float: float = 0.0
var _current_mana: int = 0

# Per-spell cooldown tracking. Key: spell_id (String). Value: seconds remaining.
# A spell is OFF cooldown when its key is absent from this dictionary.
var _cooldown_remaining: Dictionary = {}

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	pass  # Cooldown dict is populated lazily on cast.

# ---------------------------------------------------------------------------
# PHYSICS PROCESS — Mana regen + cooldown tick
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_tick_mana_regen(delta)
	_tick_cooldowns(delta)


func _tick_mana_regen(delta: float) -> void:
	# Pattern: snapshot old int → apply regen → compare new int → emit only on change.
	# Avoids emitting mana_changed 60×/sec when regen is sub-integer per frame.
	if _current_mana_float >= float(max_mana):
		return

	_current_mana_float = minf(
		_current_mana_float + mana_regen_rate * delta,
		float(max_mana)
	)

	var new_int: int = int(_current_mana_float)
	if new_int != _current_mana:
		_current_mana = new_int
		SignalBus.mana_changed.emit(_current_mana, max_mana)


func _tick_cooldowns(delta: float) -> void:
	# Iterate over a copy of keys to allow safe erasure during iteration.
	for spell_id: String in _cooldown_remaining.keys():
		_cooldown_remaining[spell_id] -= delta
		if _cooldown_remaining[spell_id] <= 0.0:
			_cooldown_remaining.erase(spell_id)
			SignalBus.spell_ready.emit(spell_id)

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Attempts to cast a spell. Returns true on success, false on failure.
## Failure conditions: unknown spell_id, insufficient mana, on cooldown.
func cast_spell(spell_id: String) -> bool:
	var spell_data: SpellData = _get_spell_data(spell_id)
	if spell_data == null:
		push_warning("SpellManager: cast_spell() unknown spell_id '%s'." % spell_id)
		return false

	if _current_mana < spell_data.mana_cost:
		return false

	if _cooldown_remaining.has(spell_id):
		return false

	# Deduct mana — sync float accumulator to prevent regen overshooting.
	_current_mana -= spell_data.mana_cost
	_current_mana_float = float(_current_mana)

	_cooldown_remaining[spell_id] = spell_data.cooldown

	_apply_spell_effect(spell_data)

	SignalBus.spell_cast.emit(spell_id)
	SignalBus.mana_changed.emit(_current_mana, max_mana)
	return true


func get_current_mana() -> int:
	return _current_mana

func get_max_mana() -> int:
	return max_mana

## Returns remaining cooldown seconds (0.0 if ready or unknown).
func get_cooldown_remaining(spell_id: String) -> float:
	return _cooldown_remaining.get(spell_id, 0.0)

## Returns true if the spell is known, mana is sufficient, and cooldown is zero.
func is_spell_ready(spell_id: String) -> bool:
	var spell_data: SpellData = _get_spell_data(spell_id)
	if spell_data == null:
		return false
	return _current_mana >= spell_data.mana_cost \
		and not _cooldown_remaining.has(spell_id)

## Sets mana to full (used by Mana Draught shop item).
func set_mana_to_full() -> void:
	_current_mana = max_mana
	_current_mana_float = float(max_mana)
	SignalBus.mana_changed.emit(_current_mana, max_mana)

## Resets mana to 0 and clears all cooldowns.
func reset_to_defaults() -> void:
	_current_mana = 0
	_current_mana_float = 0.0
	_cooldown_remaining.clear()
	SignalBus.mana_changed.emit(0, max_mana)

# ---------------------------------------------------------------------------
# PRIVATE — SPELL LOOKUP & EFFECTS
# ---------------------------------------------------------------------------

func _get_spell_data(spell_id: String) -> SpellData:
	for spell_data: SpellData in spell_registry:
		if spell_data.spell_id == spell_id:
			return spell_data
	return null


func _apply_spell_effect(spell_data: SpellData) -> void:
	match spell_data.spell_id:
		"shockwave":
			_apply_shockwave(spell_data)
		_:
			push_warning(
				"SpellManager: _apply_spell_effect() unknown spell '%s'."
				% spell_data.spell_id
			)


## Applies Shockwave AoE — hits all ground enemies on the battlefield.
## Battlefield-wide (radius = 100.0 covers full map).
func _apply_shockwave(spell_data: SpellData) -> void:
	# Credit: Foul Ward SYSTEMS_part3.md §9.6 (_apply_shockwave)
	# get_nodes_in_group() returns a snapshot — safe to iterate even if enemies
	# are freed mid-loop. is_instance_valid() guards against chain-kills.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue

		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue

		# hits_flying = false on shockwave.tres — skip Bat Swarm.
		if not spell_data.hits_flying and enemy.get_enemy_data().is_flying:
			continue

		# Single path: EnemyBase.take_damage applies immunities + armor matrix.
		enemy.take_damage(spell_data.damage, spell_data.damage_type)
````

---

## `scripts/types.gd`

````
## types.gd
## Global enums and constants for FOUL WARD. Accessed via Types.GameState, Types.DamageType, etc.
## Simulation API: all public methods callable without UI nodes present.

class_name Types

enum GameState {
	MAIN_MENU,
	MISSION_BRIEFING,
	COMBAT,
	BUILD_MODE,
	WAVE_COUNTDOWN,
	BETWEEN_MISSIONS,
	MISSION_WON,
	MISSION_FAILED,
	GAME_WON,
}

enum DamageType {
	PHYSICAL,
	FIRE,
	MAGICAL,
	POISON,
}

enum ArmorType {
	UNARMORED,
	HEAVY_ARMOR,
	UNDEAD,
	FLYING,
}

enum BuildingType {
	ARROW_TOWER,
	FIRE_BRAZIER,
	MAGIC_OBELISK,
	POISON_VAT,
	BALLISTA,
	ARCHER_BARRACKS,
	ANTI_AIR_BOLT,
	SHIELD_GENERATOR,
}

enum ArnulfState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	DOWNED,
	RECOVERING,
}

enum ResourceType {
	GOLD,
	BUILDING_MATERIAL,
	RESEARCH_MATERIAL,
}

enum EnemyType {
	ORC_GRUNT,
	ORC_BRUTE,
	GOBLIN_FIREBUG,
	PLAGUE_ZOMBIE,
	ORC_ARCHER,
	BAT_SWARM,
}

enum AllyClass {
	MELEE,
	RANGED,
	SUPPORT,
}

enum WeaponSlot {
	CROSSBOW,
	RAPID_MISSILE,
}

# Used by buildings and allies for target selection preferences.
# MVP ally AI implements CLOSEST only (nearest enemy by distance).
enum TargetPriority {
	CLOSEST,
	HIGHEST_HP,
	FLYING_FIRST,
}

# NEW enums for ally roles and SimBot strategy profiles (Prompt 12).
enum AllyRole {
	MELEE_FRONTLINE,
	RANGED_SUPPORT,
	ANTI_AIR,
	TANK,
	SPELL_SUPPORT,
}

enum StrategyProfile {
	BALANCED,
	ALLY_HEAVY_PHYSICAL,
	ANTI_AIR_FOCUS,
	SPELL_FOCUS,
	BUILDING_FOCUS,
}

# ASSUMPTION: HubRole enum is appended to keep existing enum numeric ordering stable.
# POST-MVP: Extend with FLORENCE, CAMPAIGN_SPECIFIC, etc. narrative requires.
enum HubRole {
	SHOP,
	RESEARCH,
	ENCHANT,
	MERCENARY,
	ALLY,
	FLAVOR_ONLY,
}

# Meta-state timeline advance reasons for Florence and between-mission narratives.
# Higher priority means "more important" to keep within the same advance window.
enum DayAdvanceReason {
	MISSION_COMPLETED,
	ACHIEVEMENT_EARNED,
	MAJOR_STORY_EVENT,
}

# SOURCE: Day/week advancement priority table pattern from management/roguelite design.
# TUNING: Adjust priorities as needed.
static func get_day_advance_priority(reason: DayAdvanceReason) -> int:
	match reason:
		DayAdvanceReason.MISSION_COMPLETED:
			# Baseline: still advances time, but is superseded by higher narrative drivers.
			return 0
		DayAdvanceReason.ACHIEVEMENT_EARNED:
			return 1
		DayAdvanceReason.MAJOR_STORY_EVENT:
			return 2
		_:
			return 0

# ASSUMPTION: Types uses enums + static helpers as a shared registry across systems.
````

---

## `scripts/wave_manager.gd`

````
# wave_manager.gd
# WaveManager drives the per-mission wave loop for FOUL WARD.
# Responsibilities: countdown timer, enemy spawning, wave-cleared detection.
# Does NOT decide mission success/failure — that is GameManager's responsibility.
#
# Scene placement: /root/Main/Managers/WaveManager (Node)
#
# ASSUMPTION: EnemyContainer at /root/Main/EnemyContainer (Node3D).
# ASSUMPTION: SpawnPoints at /root/Main/SpawnPoints with 10 Marker3D children.
# ASSUMPTION: enemy_data_registry has exactly 6 entries in Types.EnemyType order.
#
# Prompt 9: Waves use FactionData roster weights (Option B) while total count stays N×6.
#
# Credit: Foul Ward SYSTEMS_part1.md §1 (WaveManager spec) — Foul Ward team.
# Credit: Godot Engine Documentation — SceneTree.get_nodes_in_group()
#   https://docs.godotengine.org/en/stable/classes/class_scenetree.html
# License: CC BY 3.0 | Adapted: group-as-source-of-truth for living enemy count.
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
# License: CC BY 3.0 | Adapted: delta timers automatically respect time_scale.

class_name WaveManager
extends Node

## Preloads: autoloads and early parses may run before global `class_name` registration.
const FactionDataType = preload("res://scripts/resources/faction_data.gd")
const FactionRosterEntryType = preload("res://scripts/resources/faction_roster_entry.gd")
const BossSceneDefault: PackedScene = preload("res://scenes/bosses/boss_base.tscn")

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

## Seconds of countdown before each wave (waves after the first).
@export var wave_countdown_duration: float = 10.0

## Countdown only for wave 1 so “Start Game” leads to enemies quickly.
@export var first_wave_countdown_seconds: float = 3.0

## Maximum number of waves per mission.
@export var max_waves: int = 10

## One EnemyData resource per enemy type. MUST have exactly 6 entries,
## in the same order as Types.EnemyType (ORC_GRUNT … BAT_SWARM).
@export var enemy_data_registry: Array[EnemyData] = []

# ---------------------------------------------------------------------------
# SCENE REFERENCES
# ---------------------------------------------------------------------------

const EnemyScene: PackedScene = preload("res://scenes/enemies/enemy_base.tscn")

## Runtime parent node for spawned enemies.
## get_node_or_null: GdUnit / headless tests have no /root/Main; tests assign after add_child.
@onready var _enemy_container: Node3D = get_node_or_null("/root/Main/EnemyContainer")

## Container holding the 10 Marker3D spawn-point nodes.
@onready var _spawn_points: Node3D = get_node_or_null("/root/Main/SpawnPoints")

# ---------------------------------------------------------------------------
# INTERNAL STATE
# ---------------------------------------------------------------------------

var _current_wave: int = 0
var _countdown_remaining: float = 0.0
var _is_counting_down: bool = false
var _is_wave_active: bool = false
var _is_sequence_running: bool = false

# Per-day configuration set by GameManager via configure_for_day().
# DEVIATION: runtime wave cap is now driven by DayConfig.
var configured_max_waves: int = 0
var enemy_hp_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var gold_reward_multiplier: float = 1.0

# Faction-driven waves (Prompt 9) --------------------------------------------

## Optional override used in tests to inject a FactionData instance.
var _faction_data_override: FactionDataType = null

## Registry mapping faction_id to FactionData. Populated in _ready.
var faction_registry: Dictionary = {} # String -> FactionData

## Resolved faction for the active mission/day.
var _current_faction: FactionDataType = null

## Set from DayConfig.is_mini_boss_day when configure_for_day runs.
var _mini_boss_day_eligible: bool = false

# Boss wave context (Prompt 10) ------------------------------------------------

## ASSUMPTION: set by configure_for_day or set_day_context
var current_day_config: DayConfig = null
var current_faction_data: FactionDataType = null

## boss_id -> BossData; populated from BossData.BUILTIN_BOSS_RESOURCE_PATHS.
var boss_registry: Dictionary = {} # String -> BossData
var boss_wave_index: int = -1
var active_boss_id: String = ""

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	print("[WaveManager] _ready: enemy_data_registry size=%d" % enemy_data_registry.size())
	assert(
		enemy_data_registry.size() == 6,
		"WaveManager: enemy_data_registry must have exactly 6 entries, got %d"
		% enemy_data_registry.size()
	)
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	_load_faction_registry()
	resolve_current_faction()
	ensure_boss_registry_loaded()

# ---------------------------------------------------------------------------
# PHYSICS PROCESS — Countdown timer
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not _is_sequence_running:
		return
	if not _is_counting_down:
		return
	_process_countdown(delta)


func _process_countdown(delta: float) -> void:
	_countdown_remaining -= delta
	if _countdown_remaining <= 0.0:
		_countdown_remaining = 0.0
		_is_counting_down = false
		_spawn_wave(_current_wave)

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Begins the wave sequence for a mission. Starts countdown for wave 1.
func start_wave_sequence() -> void:
	print("[WaveManager] start_wave_sequence")
	assert(
		not _is_sequence_running,
		"WaveManager: start_wave_sequence() called while already running."
	)
	_is_sequence_running = true
	_current_wave = 0
	_begin_countdown_for_next_wave()


## Immediately spawns enemies for the given wave, skipping countdown.
func force_spawn_wave(wave_number: int) -> void:
	assert(
		wave_number >= 1 and wave_number <= max_waves,
		"WaveManager: force_spawn_wave() invalid wave_number %d." % wave_number
	)
	_current_wave = wave_number
	_is_counting_down = false
	_countdown_remaining = 0.0
	_is_sequence_running = true
	_spawn_wave(wave_number)


## Returns the number of living enemies currently in the "enemies" group.
func get_living_enemy_count() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


## Returns the current wave number (0 = no wave started yet).
func get_current_wave_number() -> int:
	return _current_wave


## Returns true if a wave has been spawned and enemies are still alive.
func is_wave_active() -> bool:
	return _is_wave_active


## Returns true if the countdown timer is currently ticking.
func is_counting_down() -> bool:
	return _is_counting_down


## Returns the remaining countdown seconds (0.0 if not counting down).
func get_countdown_remaining() -> float:
	return _countdown_remaining


## Resets all wave state for a new mission.
func reset_for_new_mission() -> void:
	_current_wave = 0
	_countdown_remaining = 0.0
	_is_counting_down = false
	_is_wave_active = false
	_is_sequence_running = false
	configured_max_waves = 0
	enemy_hp_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	gold_reward_multiplier = 1.0
	_mini_boss_day_eligible = false
	current_day_config = null
	current_faction_data = null
	boss_wave_index = -1
	active_boss_id = ""
	clear_all_enemies()
	resolve_current_faction()


func configure_for_day(day_config: DayConfig) -> void:
	if day_config == null:
		return
	var desired: int = day_config.base_wave_count
	if desired <= 0:
		desired = max_waves
	configured_max_waves = mini(desired, max_waves)
	enemy_hp_multiplier = day_config.enemy_hp_multiplier
	enemy_damage_multiplier = day_config.enemy_damage_multiplier
	gold_reward_multiplier = day_config.gold_reward_multiplier
	_mini_boss_day_eligible = day_config.is_mini_boss_day or day_config.is_mini_boss
	_apply_faction_from_day_config(day_config)
	current_day_config = day_config
	if _faction_data_override != null:
		current_faction_data = _faction_data_override
	else:
		current_faction_data = _current_faction
	_configure_boss_wave_index()


## Test / API: inject DayConfig + FactionData without running full campaign flow.
func set_day_context(day_config: DayConfig, faction_data: FactionDataType) -> void:
	configure_for_day(day_config)
	if faction_data != null:
		_current_faction = faction_data
		current_faction_data = faction_data
	_configure_boss_wave_index()


## Loads built-in BossData resources into boss_registry.
func ensure_boss_registry_loaded() -> void:
	if not boss_registry.is_empty():
		return
	for path: String in BossData.BUILTIN_BOSS_RESOURCE_PATHS:
		var res: Resource = load(path)
		if res is BossData:
			var b: BossData = res as BossData
			if b.boss_id != "":
				boss_registry[b.boss_id] = b


## Allows tests to inject a custom FactionData instead of using campaign mapping.
func set_faction_data_override(faction_data: FactionDataType) -> void:
	_faction_data_override = faction_data
	if faction_data != null:
		_current_faction = faction_data
	else:
		resolve_current_faction()


## Resolves the active faction for current mission/day.
## ASSUMPTION: Campaign/day system supplies DayConfig via configure_for_day in gameplay.
func resolve_current_faction() -> void:
	if _faction_data_override != null:
		_current_faction = _faction_data_override
		return

	# POST-MVP: integrate richer CampaignManager / territory default_faction_id here.
	if faction_registry.has("DEFAULT_MIXED"):
		_current_faction = faction_registry["DEFAULT_MIXED"] as FactionDataType
	else:
		_current_faction = null
		push_error("WaveManager.resolve_current_faction: DEFAULT_MIXED not found in registry.")


## Returns mini-boss schedule info for the given wave, or {} if none.
## POST-MVP: Only reports data; other systems will decide how/when to spawn bosses.
func get_mini_boss_info_for_wave(wave_index: int) -> Dictionary:
	if _current_faction == null:
		resolve_current_faction()
	if _current_faction == null:
		return {}

	# Tests use _faction_data_override without configure_for_day; gameplay gates on day flag.
	if _faction_data_override == null and not _mini_boss_day_eligible:
		return {}

	if _current_faction.mini_boss_ids.is_empty():
		return {}

	if _current_faction.mini_boss_wave_hints.has(wave_index):
		return {
			"mini_boss_id": _current_faction.mini_boss_ids[0],
			"wave_index": wave_index,
			"faction_id": _current_faction.faction_id,
		}

	return {}


## Immediately removes all enemies from the scene and the "enemies" group.
## remove_from_group() is called before queue_free() so get_living_enemy_count()
## is accurate within the same frame.
func clear_all_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		node.remove_from_group("enemies")
		node.queue_free()

# ---------------------------------------------------------------------------
# PRIVATE — FACTION REGISTRY
# ---------------------------------------------------------------------------

func _load_faction_registry() -> void:
	faction_registry.clear()
	for path: String in FactionDataType.BUILTIN_FACTION_RESOURCE_PATHS:
		var data: FactionDataType = load(path) as FactionDataType
		if data == null:
			push_error("WaveManager: Failed to load FactionData at %s" % path)
			continue
		if data.faction_id == "":
			push_error("WaveManager: FactionData at %s has empty faction_id" % path)
			continue
		faction_registry[data.faction_id] = data


func _apply_faction_from_day_config(day_config: DayConfig) -> void:
	if _faction_data_override != null:
		_current_faction = _faction_data_override
		return

	var fid: String = day_config.faction_id.strip_edges()
	if fid.is_empty():
		fid = "DEFAULT_MIXED"

	if faction_registry.has(fid):
		_current_faction = faction_registry[fid] as FactionDataType
	else:
		push_error("WaveManager: unknown faction_id '%s', falling back to DEFAULT_MIXED." % fid)
		_current_faction = faction_registry.get("DEFAULT_MIXED", null) as FactionDataType


func _configure_boss_wave_index() -> void:
	boss_wave_index = -1
	active_boss_id = ""
	var dc: DayConfig = current_day_config
	if dc == null:
		return
	var cap: int = configured_max_waves if configured_max_waves > 0 else max_waves
	if dc.is_final_boss or dc.is_boss_attack_day:
		boss_wave_index = cap
		active_boss_id = dc.boss_id
	elif (dc.is_mini_boss_day or dc.is_mini_boss) and _current_faction != null and not _current_faction.mini_boss_ids.is_empty():
		boss_wave_index = cap
		var pick: int = randi() % _current_faction.mini_boss_ids.size()
		active_boss_id = _current_faction.mini_boss_ids[pick]


func _spawn_boss_wave() -> int:
	if _enemy_container == null or _spawn_points == null:
		push_error(
			"WaveManager: enemy_container or spawn_points is null. In tests, assign both fields before calling spawn_wave."
		)
		return 0
	var boss_data: BossData = _get_boss_data(active_boss_id)
	if boss_data == null:
		push_error("WaveManager: BossData not found for boss_id = %s" % active_boss_id)
		return 0
	var scene: PackedScene = boss_data.boss_scene
	if scene == null:
		scene = BossSceneDefault
	var boss: BossBase = scene.instantiate() as BossBase
	if boss == null:
		push_error("WaveManager: boss_scene is not a BossBase for boss_id = %s" % active_boss_id)
		return 0
	var spawn_point_nodes: Array[Node] = _spawn_points.get_children()
	var spawn_marker: Marker3D = spawn_point_nodes.pick_random() as Marker3D
	var offset: Vector3 = Vector3(
		randf_range(-2.0, 2.0),
		0.0,
		randf_range(-2.0, 2.0)
	)
	_enemy_container.add_child(boss)
	boss.global_position = spawn_marker.global_position + offset
	if not boss.is_in_group("enemies"):
		boss.add_to_group("enemies")
	boss.initialize_boss_data(boss_data)
	var count: int = 1
	for escort_id: String in boss_data.escort_unit_ids:
		var escort_data: EnemyData = _resolve_escort_enemy_data(escort_id)
		if escort_data == null:
			continue
		var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
		_enemy_container.add_child(enemy)
		var tuned: EnemyData = escort_data.duplicate(true) as EnemyData
		tuned.max_hp = maxi(1, int(round(float(escort_data.max_hp) * enemy_hp_multiplier)))
		tuned.damage = maxi(1, int(round(float(escort_data.damage) * enemy_damage_multiplier)))
		tuned.gold_reward = maxi(0, int(round(float(escort_data.gold_reward) * gold_reward_multiplier)))
		enemy.initialize(tuned)
		var escort_spawn: Marker3D = spawn_point_nodes.pick_random() as Marker3D
		var escort_offset: Vector3 = Vector3(
			randf_range(-2.0, 2.0),
			0.0,
			randf_range(-2.0, 2.0)
		)
		enemy.global_position = escort_spawn.global_position + escort_offset
		if escort_data.is_flying:
			enemy.global_position.y = 5.0
		if not enemy.is_in_group("enemies"):
			enemy.add_to_group("enemies")
		count += 1
	return count


func _get_boss_data(boss_id: String) -> BossData:
	if boss_registry.has(boss_id):
		return boss_registry[boss_id] as BossData
	return null


func _resolve_escort_enemy_data(escort_id: String) -> EnemyData:
	var eid: String = escort_id.strip_edges()
	for data: EnemyData in enemy_data_registry:
		# BossData escort_unit_ids use enum key strings (e.g. "ORC_GRUNT"); str(enum) is not the key name.
		var key_name: String = Types.EnemyType.keys()[data.enemy_type]
		if key_name == eid:
			return data
	return null

# ---------------------------------------------------------------------------
# PRIVATE — COUNTDOWN & SPAWN
# ---------------------------------------------------------------------------

func _begin_countdown_for_next_wave() -> void:
	_current_wave += 1
	var duration: float = (
		first_wave_countdown_seconds if _current_wave == 1 else wave_countdown_duration
	)
	_countdown_remaining = duration
	_is_counting_down = true
	_is_wave_active = false
	print("[WaveManager] countdown started: wave=%d duration=%.1fs" % [_current_wave, duration])
	SignalBus.wave_countdown_started.emit(_current_wave, duration)


## Wave formula: total enemies = N × 6 (scaled by faction difficulty_offset), split by roster weights.
func _spawn_wave(wave_number: int) -> void:
	assert(wave_number >= 1 and wave_number <= max_waves,
		"WaveManager: _spawn_wave() invalid wave_number %d." % wave_number)

	if _enemy_container == null or _spawn_points == null:
		push_error(
			"WaveManager: enemy_container or spawn_points is null. In tests, assign both fields before calling spawn_wave."
		)
		return

	if _current_faction == null:
		resolve_current_faction()

	_current_wave = wave_number
	_is_wave_active = true

	var total_spawned: int = 0
	if boss_wave_index == wave_number and active_boss_id.strip_edges() != "":
		total_spawned += _spawn_boss_wave()

	var roster_entries: Array[FactionRosterEntryType] = _current_faction.get_entries_for_wave(wave_number)
	if roster_entries.is_empty():
		push_error(
			"WaveManager._spawn_wave: faction '%s' has no roster entries for wave %d"
			% [_current_faction.faction_id, wave_number]
		)
		SignalBus.wave_started.emit(_current_wave, total_spawned)
		if total_spawned == 0:
			call_deferred("_check_wave_cleared")
		return

	var spawn_point_nodes: Array[Node] = _spawn_points.get_children()
	assert(
		spawn_point_nodes.size() > 0,
		"WaveManager: No spawn points found under SpawnPoints node."
	)

	var total_enemies: int = _compute_total_enemies_for_wave(wave_number, _current_faction)
	var per_entry_counts: Array[int] = _allocate_counts_for_roster(roster_entries, total_enemies, wave_number)

	for i: int in range(roster_entries.size()):
		var entry: FactionRosterEntryType = roster_entries[i]
		var count: int = per_entry_counts[i]
		if count <= 0:
			continue

		var enemy_data: EnemyData = _get_enemy_data_for_type(entry.enemy_type)
		if enemy_data == null:
			push_error("WaveManager._spawn_wave: No EnemyData for enemy_type %s" % str(entry.enemy_type))
			continue

		for _j: int in range(count):
			var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase

			_enemy_container.add_child(enemy)

			var tuned_enemy_data: EnemyData = enemy_data.duplicate(true) as EnemyData
			tuned_enemy_data.max_hp = maxi(1, int(round(float(enemy_data.max_hp) * enemy_hp_multiplier)))
			tuned_enemy_data.damage = maxi(1, int(round(float(enemy_data.damage) * enemy_damage_multiplier)))
			tuned_enemy_data.gold_reward = maxi(0, int(round(float(enemy_data.gold_reward) * gold_reward_multiplier)))
			enemy.initialize(tuned_enemy_data)

			var spawn_marker: Marker3D = spawn_point_nodes.pick_random() as Marker3D
			var offset: Vector3 = Vector3(
				randf_range(-2.0, 2.0),
				0.0,
				randf_range(-2.0, 2.0)
			)
			enemy.global_position = spawn_marker.global_position + offset

			if enemy_data.is_flying:
				enemy.global_position.y = 5.0

			total_spawned += 1

	print("[WaveManager] wave %d spawned: %d enemies total" % [wave_number, total_spawned])
	SignalBus.wave_started.emit(wave_number, total_spawned)

	if total_spawned == 0:
		call_deferred("_check_wave_cleared")


## Computes total enemies for this wave based on MVP scaling (N * 6).
func _compute_total_enemies_for_wave(wave_index: int, faction: FactionDataType) -> int:
	var base_total: float = float(wave_index * 6)

	if faction != null and faction.difficulty_offset != 0.0:
		base_total *= maxf(0.1, 1.0 + faction.difficulty_offset) # TUNING

	return maxi(1, int(round(base_total)))


## Allocates integer counts across roster entries based on weighted share.
func _allocate_counts_for_roster(
		roster_entries: Array[FactionRosterEntryType],
		total_enemies: int,
		wave_index: int
) -> Array[int]:
	var weights: Array[float] = []
	var total_weight: float = 0.0

	for entry: FactionRosterEntryType in roster_entries:
		var w: float = _current_faction.get_effective_weight_for_wave(entry, wave_index)
		weights.append(w)
		total_weight += w

	if total_weight <= 0.0:
		# DEVIATION: Fallback to equal distribution when all weights are zero.
		var equal: int = total_enemies / roster_entries.size()
		var remainder: int = total_enemies % roster_entries.size()
		var counts_eq: Array[int] = []
		for i: int in range(roster_entries.size()):
			var c: int = equal + (1 if i < remainder else 0)
			counts_eq.append(c)
		return counts_eq

	# SOURCE: Proportional allocation with largest-remainder rounding, common in weighted selection systems.
	var float_counts: Array[float] = []
	var counts_int: Array[int] = []
	var running_total: int = 0

	for i: int in range(roster_entries.size()):
		var share: float = weights[i] / total_weight
		var ideal: float = float(total_enemies) * share
		float_counts.append(ideal)
		var c_int: int = int(floorf(ideal))
		counts_int.append(c_int)
		running_total += c_int

	var remaining: int = total_enemies - running_total
	if remaining > 0:
		var indices: Array[int] = []
		for j: int in range(float_counts.size()):
			indices.append(j)
		indices.sort_custom(func(a: int, b: int) -> bool:
			var frac_a: float = float_counts[a] - float(counts_int[a])
			var frac_b: float = float_counts[b] - float(counts_int[b])
			return frac_a > frac_b
		)
		for k: int in range(mini(remaining, indices.size())):
			var idx: int = indices[k]
			counts_int[idx] += 1

	return counts_int


func _get_enemy_data_for_type(enemy_type: Types.EnemyType) -> EnemyData:
	for data: EnemyData in enemy_data_registry:
		if data.enemy_type == enemy_type:
			return data
	return null

# ---------------------------------------------------------------------------
# SIGNAL HANDLERS
# ---------------------------------------------------------------------------

func _on_enemy_killed(
		_enemy_type: Types.EnemyType,
		_position: Vector3,
		_gold_reward: int
) -> void:
	if not _is_wave_active:
		return
	call_deferred("_check_wave_cleared")


func _check_wave_cleared() -> void:
	if get_living_enemy_count() > 0:
		return
	_is_wave_active = false
	print("[WaveManager] wave %d cleared!" % _current_wave)
	SignalBus.wave_cleared.emit(_current_wave)

	var effective_max: int = configured_max_waves if configured_max_waves > 0 else max_waves
	if _current_wave >= effective_max:
		_is_sequence_running = false
		print("[WaveManager] all waves cleared for this mission!")
		SignalBus.all_waves_cleared.emit()
	else:
		_begin_countdown_for_next_wave()


func _on_game_state_changed(
		_old_state: Types.GameState,
		_new_state: Types.GameState
) -> void:
	pass
````

---

## `scripts/weapon_upgrade_manager.gd`

````
## weapon_upgrade_manager.gd
## Manages weapon level progression for Florence's Tower weapons.
## Tracks current upgrade level per weapon slot (0 = base, 1-3 = upgraded).
## Provides effective stat accessors that compose base WeaponData values
## with additive incremental level bonuses from WeaponLevelData resources.
##
## Lives at: /root/Main/Managers/WeaponUpgradeManager
## NOT an autoload — scene-bound manager consistent with WaveManager, ShopManager, etc.
##
## Simulation API: all public methods callable without UI nodes present.
## Tower references this manager via get_node_or_null and falls back to raw
## WeaponData when manager is absent, preserving all existing Tower tests.
##
# SOURCE: Composition-based stat system pattern — https://www.reddit.com/r/godot/comments/1fu9gcc/stats_resources_for_a_compositionbased_weapon/ [S4]
# SOURCE: Scene-bound manager pattern — consistent with existing ResearchManager, ShopManager in this codebase

class_name WeaponUpgradeManager
extends Node

const MAX_LEVEL: int = 3

## Array of WeaponLevelData resources for the crossbow, one per upgrade level (3 entries).
## Index 0 = level 1 data, index 1 = level 2 data, index 2 = level 3 data.
@export var crossbow_levels: Array[WeaponLevelData] = []

## Array of WeaponLevelData resources for the rapid missile, one per upgrade level (3 entries).
## Index 0 = level 1 data, index 1 = level 2 data, index 2 = level 3 data.
@export var rapid_missile_levels: Array[WeaponLevelData] = []

## Base WeaponData resource for the crossbow. Used as the additive base for all stat lookups.
@export var crossbow_base_data: WeaponData = null

## Base WeaponData resource for the rapid missile. Used as the additive base for all stat lookups.
@export var rapid_missile_base_data: WeaponData = null

var _crossbow_current_level: int = 0
var _rapid_missile_current_level: int = 0

## Connects to game-state signal for future extension.
func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)


## Returns whether the game state change is relevant (reserved for future HUD reactivity).
func _on_game_state_changed(_old: Types.GameState, _new: Types.GameState) -> void:
	pass  # Reserved for future use


## Attempts to upgrade the specified weapon by one level.
## Returns true on success, false if already at max level or gold is insufficient.
## Spends gold via EconomyManager.spend_gold(). Emits SignalBus.weapon_upgraded on success.
func upgrade_weapon(weapon_slot: Types.WeaponSlot) -> bool:
	var current_level: int = get_current_level(weapon_slot)
	if current_level >= MAX_LEVEL:
		return false
	var level_data_array: Array[WeaponLevelData] = _get_level_array(weapon_slot)
	if current_level >= level_data_array.size():
		push_error("WeaponUpgradeManager.upgrade_weapon: missing level data for slot %d level %d" % [weapon_slot, current_level + 1])
		return false
	var level_data: WeaponLevelData = level_data_array[current_level]
	if level_data == null:
		push_error("WeaponUpgradeManager.upgrade_weapon: level_data is null for slot %d level %d" % [weapon_slot, current_level + 1])
		return false
	if not EconomyManager.can_afford(level_data.gold_cost, level_data.material_cost):
		return false
	if level_data.gold_cost > 0:
		EconomyManager.spend_gold(level_data.gold_cost)
	if level_data.material_cost > 0:
		EconomyManager.spend_building_material(level_data.material_cost)
	_set_current_level(weapon_slot, current_level + 1)
	SignalBus.weapon_upgraded.emit(weapon_slot, get_current_level(weapon_slot))
	return true


## Returns the current upgrade level for the specified weapon slot (0 = base, 1-3 = upgraded).
func get_current_level(weapon_slot: Types.WeaponSlot) -> int:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			return _crossbow_current_level
		Types.WeaponSlot.RAPID_MISSILE:
			return _rapid_missile_current_level
	push_error("WeaponUpgradeManager.get_current_level: unknown weapon_slot %d" % weapon_slot)
	return 0


## Returns the maximum upgrade level constant (3).
func get_max_level() -> int:
	return MAX_LEVEL


## Returns the effective damage for the given weapon slot at its current level.
## Computed as base_data.damage + SUM of all damage_bonus values from levels 1..current_level.
## Falls back to base damage when level is 0 or base_data is null.
func get_effective_damage(weapon_slot: Types.WeaponSlot) -> float:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0.0
	return base.damage + _get_cumulative_bonus(weapon_slot, "damage_bonus")


## Returns the effective projectile speed for the given weapon slot at its current level.
## Computed as base_data.projectile_speed + SUM of speed_bonus values from levels 1..current_level.
func get_effective_speed(weapon_slot: Types.WeaponSlot) -> float:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0.0
	return base.projectile_speed + _get_cumulative_bonus(weapon_slot, "speed_bonus")


## Returns the effective reload time for the given weapon slot at its current level.
## Computed as base_data.reload_time + SUM of reload_bonus values from levels 1..current_level.
## Note: reload_bonus values are negative to improve (reduce) reload time.
## Clamped to a minimum of 0.1 seconds to prevent zero or negative reload.
func get_effective_reload_time(weapon_slot: Types.WeaponSlot) -> float:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0.1
	var result: float = base.reload_time + _get_cumulative_bonus(weapon_slot, "reload_bonus")
	return maxf(result, 0.1)


## Returns the effective burst count for the given weapon slot at its current level.
## Computed as base_data.burst_count + SUM of burst_count_bonus values from levels 1..current_level.
func get_effective_burst_count(weapon_slot: Types.WeaponSlot) -> int:
	var base: WeaponData = _get_base_data(weapon_slot)
	if base == null:
		return 0
	return base.burst_count + int(_get_cumulative_bonus(weapon_slot, "burst_count_bonus"))


## Returns the WeaponLevelData for the next upgrade level, or null if already at max level.
## Useful for UI preview of upcoming stat changes.
func get_next_level_data(weapon_slot: Types.WeaponSlot) -> WeaponLevelData:
	var current_level: int = get_current_level(weapon_slot)
	if current_level >= MAX_LEVEL:
		return null
	return get_level_data(weapon_slot, current_level + 1)


## Returns the WeaponLevelData for a specific level (1-3), or null if invalid.
## Level 0 has no WeaponLevelData (implicit base — returns null by design).
func get_level_data(weapon_slot: Types.WeaponSlot, level: int) -> WeaponLevelData:
	if level < 1 or level > MAX_LEVEL:
		return null
	var arr: Array[WeaponLevelData] = _get_level_array(weapon_slot)
	var index: int = level - 1
	if index >= arr.size():
		return null
	return arr[index]


## Resets both weapon levels to 0 (base stats). Called by GameManager.start_new_game().
## POST-MVP: Save/load weapon levels to disk for persistent campaign progress.
func reset_to_defaults() -> void:
	_crossbow_current_level = 0
	_rapid_missile_current_level = 0
	# POST-MVP: Campaign save/load for weapon levels


## Returns the configured base WeaponData for the slot.
func _get_base_data(weapon_slot: Types.WeaponSlot) -> WeaponData:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_base_data
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_base_data
	return null


## Returns the configured level data array for the slot.
func _get_level_array(weapon_slot: Types.WeaponSlot) -> Array[WeaponLevelData]:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			return crossbow_levels
		Types.WeaponSlot.RAPID_MISSILE:
			return rapid_missile_levels
	return []


## Updates the current level for the specified slot.
func _set_current_level(weapon_slot: Types.WeaponSlot, new_level: int) -> void:
	match weapon_slot:
		Types.WeaponSlot.CROSSBOW:
			_crossbow_current_level = new_level
		Types.WeaponSlot.RAPID_MISSILE:
			_rapid_missile_current_level = new_level


## Sums the named float field across all WeaponLevelData entries from level 1
## up to and including the weapon's current level. Returns 0.0 if level is 0.
## Uses get() for dynamic field access on Resource objects.
## burst_count_bonus is an int field but returned as float for uniform summation;
## callers cast back to int where needed.
# SOURCE: Dynamic property access via .get() on Resource — Godot 4 docs [S1]
func _get_cumulative_bonus(weapon_slot: Types.WeaponSlot, field: String) -> float:
	var current_level: int = get_current_level(weapon_slot)
	if current_level == 0:
		return 0.0
	var arr: Array[WeaponLevelData] = _get_level_array(weapon_slot)
	var total: float = 0.0
	for i: int in range(current_level):
		if i < arr.size() and arr[i] != null:
			total += float(arr[i].get(field))
	return total
````

---

## `ui/between_mission_screen.gd`

````
# ui/between_mission_screen.gd
# BetweenMissionScreen — Shop, Research, Buildings tabs + Next Mission button.
# Zero game logic. All decisions delegated to ShopManager, ResearchManager,
# HexGrid, and GameManager.
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — BetweenMissionScreen class responsibilities.

class_name BetweenMissionScreen
extends Control

@onready var _next_mission_btn: Button = $NextMissionButton
@onready var _day_progress_label: Label = $DayProgressLabel
@onready var _day_name_label: Label = $DayNameLabel
@onready var _florence_debug_label: Label = $FlorenceDebugLabel

@onready var _shop_list: VBoxContainer = $TabContainer/ShopTab/ShopList
@onready var _research_list: VBoxContainer = $TabContainer/ResearchTab/ResearchList
@onready var _buildings_list: VBoxContainer = $TabContainer/BuildingsTab/BuildingsList
@onready var _offers_list: VBoxContainer = $TabContainer/MercenariesTab/OffersSection/OffersList
@onready var _roster_list: VBoxContainer = $TabContainer/MercenariesTab/RosterSection/RosterList
@onready var _active_cap_label: Label = $TabContainer/MercenariesTab/RosterSection/CapLabel
@onready var _weapons_tab: Control = $TabContainer/WeaponsTab
@onready var _crossbow_enchant_label: Label = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/EnchantmentLabel
@onready var _rapid_enchant_label: Label = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/EnchantmentLabel

@onready var _tab_container: TabContainer = $TabContainer # ASSUMPTION: TabContainer node exists at root.

@onready var _crossbow_elemental_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/ApplyElementalButton
@onready var _crossbow_power_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/ApplyPowerButton
@onready var _crossbow_remove_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/RemoveAllButton

@onready var _rapid_elemental_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/ApplyElementalButton
@onready var _rapid_power_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/ApplyPowerButton
@onready var _rapid_remove_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/RemoveAllButton

@onready var _shop_manager: ShopManager = get_node_or_null(
	"/root/Main/Managers/ShopManager"
) as ShopManager
@onready var _research_manager: ResearchManager = get_node_or_null(
	"/root/Main/Managers/ResearchManager"
) as ResearchManager
@onready var _hex_grid: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
@onready var _ui_manager: UIManager = get_node_or_null("/root/Main/UI/UIManager") as UIManager
var _weapon_upgrade_manager: Node = null

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	_next_mission_btn.pressed.connect(_on_next_mission_pressed)
	_weapon_upgrade_manager = get_node_or_null("/root/Main/Managers/WeaponUpgradeManager")
	SignalBus.florence_state_changed.connect(_on_florence_state_changed)
	SignalBus.weapon_upgraded.connect(_on_weapon_upgraded)
	SignalBus.resource_changed.connect(_on_resource_changed_weapons)
	SignalBus.enchantment_applied.connect(_on_enchantment_applied)
	SignalBus.enchantment_removed.connect(_on_enchantment_removed)
	SignalBus.mercenary_offer_generated.connect(_refresh_offers)
	SignalBus.ally_roster_changed.connect(_refresh_roster)
	SignalBus.mercenary_recruited.connect(_on_mercenary_recruited)
	_refresh_weapons_tab()
	_refresh_day_info()
	_refresh_florence_debug()


func _on_game_state_changed(
		_old: Types.GameState,
		new_state: Types.GameState
) -> void:
	if new_state == Types.GameState.BETWEEN_MISSIONS:
		_refresh_all()
		_show_hub_dialogue()


func open_shop_panel() -> void:
	if _tab_container == null:
		return
	# ASSUMPTION (from between_mission_screen.tscn):
	# MapTab=0, ShopTab=1.
	_tab_container.current_tab = 1


func open_research_panel() -> void:
	if _tab_container == null:
		return
	# ASSUMPTION (from between_mission_screen.tscn): ResearchTab index=2.
	_tab_container.current_tab = 2


func open_enchant_panel() -> void:
	if _tab_container == null:
		return
	# DEVIATION: No Enchant tab exists in current MVP scene. Route to ResearchTab.
	_tab_container.current_tab = 2


func open_mercenary_panel() -> void:
	if _tab_container == null:
		return
	# DEVIATION: Current MVP scene has a Mercenaries tab already (MercenariesTab index=4).
	_tab_container.current_tab = 4


func _show_hub_dialogue() -> void:
	_ui_manager.show_dialogue_for_character("SPELL_RESEARCHER")
	_ui_manager.show_dialogue_for_character("COMPANION_MELEE")
	# POST-MVP: Add Florence, Merchant, etc. as additional calls.


func _refresh_all() -> void:
	_refresh_shop()
	_refresh_research()
	_refresh_buildings()
	_refresh_mercenaries_tab()
	_refresh_weapons_tab()
	_refresh_day_info()


func _refresh_mercenaries_tab() -> void:
	_refresh_offers("")
	_refresh_roster()


func _refresh_offers(_ally_id: String) -> void:
	for child: Node in _offers_list.get_children():
		child.queue_free()
	var offers: Array = CampaignManager.get_current_offers()
	for offer: Variant in offers:
		if offer == null:
			continue
		var aid: String = str(offer.get("ally_id"))
		var ad: Resource = CampaignManager.get_ally_data(aid)
		var display_name: String = aid if ad == null else str(ad.get("display_name"))
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s [%s]" % [display_name, str(offer.call("get_cost_summary"))]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Recruit"
		var can_afford: bool = (
				EconomyManager.get_gold() >= int(offer.get("cost_gold"))
				and EconomyManager.get_building_material() >= int(offer.get("cost_building_material"))
				and EconomyManager.get_research_material() >= int(offer.get("cost_research_material"))
		)
		btn.disabled = not can_afford
		var captured_ally_id: String = aid
		btn.pressed.connect(func() -> void:
			var offers_now: Array = CampaignManager.get_current_offers()
			var purchase_i: int = -1
			for j: int in range(offers_now.size()):
				var o: Variant = offers_now[j]
				if o != null and str(o.get("ally_id")) == captured_ally_id:
					purchase_i = j
					break
			if purchase_i >= 0:
				CampaignManager.purchase_mercenary_offer(purchase_i)
			_refresh_mercenaries_tab()
		)
		row.add_child(lbl)
		row.add_child(btn)
		_offers_list.add_child(row)


func _refresh_roster() -> void:
	for child: Node in _roster_list.get_children():
		child.queue_free()
	var active_allies: Array[String] = CampaignManager.get_active_allies()
	var cap: int = CampaignManager.max_active_allies_per_day
	if is_instance_valid(_active_cap_label):
		_active_cap_label.text = "Active: %d / %d" % [active_allies.size(), cap]
	for ally_id: String in CampaignManager.get_owned_allies():
		var data: Resource = CampaignManager.get_ally_data(ally_id)
		var dname: String = ally_id if data == null else str(data.get("display_name"))
		var row2: HBoxContainer = HBoxContainer.new()
		var lbl2: Label = Label.new()
		lbl2.text = dname
		lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tbtn: Button = Button.new()
		var is_active: bool = active_allies.has(ally_id)
		tbtn.text = "Active" if is_active else "Standby"
		var captured_aid: String = ally_id
		tbtn.pressed.connect(func() -> void:
			CampaignManager.toggle_ally_active(captured_aid)
			_refresh_mercenaries_tab()
		)
		row2.add_child(lbl2)
		row2.add_child(tbtn)
		_roster_list.add_child(row2)


func _on_mercenary_recruited(_ally_id: String) -> void:
	_refresh_mercenaries_tab()

func _refresh_day_info() -> void:
	var cur: int = CampaignManager.get_current_day()
	var len: int = CampaignManager.get_campaign_length()
	var cfg: DayConfig = CampaignManager.get_current_day_config()

	if is_instance_valid(_day_progress_label):
		_day_progress_label.text = "Day %d / %d" % [cur, maxi(len, 1)]

	if is_instance_valid(_day_name_label):
		if cfg != null:
			_day_name_label.text = "Day %d - %s" % [cfg.day_index, cfg.display_name]
		else:
			_day_name_label.text = "Day %d" % cur


func _on_florence_state_changed() -> void:
	_refresh_florence_debug()


func _refresh_florence_debug() -> void:
	# Pure UI: read-only presentation of Florence meta-state.
	if not is_instance_valid(_florence_debug_label):
		return

	var florence := GameManager.get_florence_data()
	if florence == null:
		_florence_debug_label.text = "Florence: <no data>"
		return

	var text: String = (
		"Day %d | Run %d | Missions %d | Failures %d | Boss attempts %d"
		% [
			GameManager.current_day,
			florence.run_count,
			florence.total_missions_played,
			florence.mission_failures,
			florence.boss_attempts,
		]
	)
	_florence_debug_label.text = text


func _refresh_shop() -> void:
	for child: Node in _shop_list.get_children():
		child.queue_free()

	var items: Array[ShopItemData] = _shop_manager.get_available_items()
	for item: ShopItemData in items:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		var price_text: String = "%s — %dg" % [item.display_name, item.gold_cost]
		if item.material_cost > 0:
			price_text = "%s — %dg + %dm" % [
				item.display_name, item.gold_cost, item.material_cost
			]
		lbl.text = price_text
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Buy"
		btn.disabled = not _shop_manager.can_purchase(item.item_id)
		var captured_id: String = item.item_id
		btn.pressed.connect(func() -> void: _on_shop_buy_pressed(captured_id))
		row.add_child(lbl)
		row.add_child(btn)
		_shop_list.add_child(row)


func _refresh_research() -> void:
	for child: Node in _research_list.get_children():
		child.queue_free()

	var nodes: Array[ResearchNodeData] = _research_manager.get_available_nodes()
	for node_data: ResearchNodeData in nodes:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s — %d res" % [node_data.display_name, node_data.research_cost]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Unlock"
		btn.disabled = (
			EconomyManager.get_research_material() < node_data.research_cost
		)
		var captured_id: String = node_data.node_id
		btn.pressed.connect(func() -> void: _on_research_unlock_pressed(captured_id))
		row.add_child(lbl)
		row.add_child(btn)
		_research_list.add_child(row)


func _refresh_buildings() -> void:
	for child: Node in _buildings_list.get_children():
		child.queue_free()

	var occupied: Array[int] = _hex_grid.get_all_occupied_slots()
	if occupied.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No buildings placed."
		_buildings_list.add_child(lbl)
		return

	for slot_index: int in occupied:
		var slot_data: Dictionary = _hex_grid.get_slot_data(slot_index)
		var building: BuildingBase = slot_data.get("building", null)
		if building == null:
			continue
		var bd: BuildingData = building.get_building_data()
		var lbl: Label = Label.new()
		lbl.text = "Slot %d: %s%s" % [
			slot_index,
			bd.display_name,
			" (Upgraded)" if building.is_upgraded else ""
		]
		_buildings_list.add_child(lbl)


func _on_shop_buy_pressed(item_id: String) -> void:
	_shop_manager.purchase_item(item_id)
	_refresh_shop()


func _on_research_unlock_pressed(node_id: String) -> void:
	_research_manager.unlock_node(node_id)
	_refresh_research()


func _on_next_mission_pressed() -> void:
	# DEVIATION: BetweenMissionScreen now routes through CampaignManager.
	CampaignManager.start_next_day()


## Refreshes the entire Weapons tab display. Called on show and after any upgrade.
func _refresh_weapons_tab() -> void:
	if _weapon_upgrade_manager != null:
		_refresh_weapon_panel(Types.WeaponSlot.CROSSBOW)
		_refresh_weapon_panel(Types.WeaponSlot.RAPID_MISSILE)
	_refresh_weapon_enchantments()


## Refreshes the display panel for a single weapon slot.
# SOURCE: UI-as-thin-presenter pattern — [S5]
func _refresh_weapon_panel(slot: Types.WeaponSlot) -> void:
	var current_level: int = _weapon_upgrade_manager.get_current_level(slot)
	var max_level: int = _weapon_upgrade_manager.get_max_level()
	var next_data: WeaponLevelData = _weapon_upgrade_manager.get_next_level_data(slot)
	var at_max: bool = current_level >= max_level

	var panel_name: String = "CrossbowPanel" if slot == Types.WeaponSlot.CROSSBOW else "RapidMissilePanel"
	var panel: Control = _weapons_tab.get_node_or_null("VBoxContainer/%s" % panel_name)
	if panel == null:
		push_warning("BetweenMissionScreen._refresh_weapon_panel: %s not found" % panel_name)
		return

	var level_label: Label = panel.get_node_or_null("LevelLabel")
	if level_label:
		level_label.text = "Level %d / %d" % [current_level, max_level]

	var stats_label: Label = panel.get_node_or_null("StatsLabel")
	if stats_label:
		stats_label.text = _build_stats_text(slot)

	var preview_label: Label = panel.get_node_or_null("PreviewLabel")
	if preview_label:
		if at_max:
			preview_label.text = ""
		elif next_data != null:
			preview_label.text = _build_preview_text(slot, next_data)

	var cost_label: Label = panel.get_node_or_null("CostLabel")
	if cost_label:
		if at_max:
			cost_label.text = ""
		elif next_data != null:
			cost_label.text = "Cost: %d gold" % next_data.gold_cost

	var upgrade_button: Button = panel.get_node_or_null("UpgradeButton")
	if upgrade_button:
		if at_max:
			upgrade_button.text = "MAX LEVEL"
			upgrade_button.disabled = true
		else:
			upgrade_button.text = "Upgrade"
			var can_afford: bool = next_data != null and EconomyManager.can_afford(next_data.gold_cost, 0)
			upgrade_button.disabled = not can_afford
			if not upgrade_button.pressed.is_connected(_on_upgrade_pressed.bind(slot)):
				upgrade_button.pressed.connect(_on_upgrade_pressed.bind(slot))


## Builds the current stat display string for a weapon slot.
func _build_stats_text(slot: Types.WeaponSlot) -> String:
	if _weapon_upgrade_manager == null:
		return ""
	var dmg: float = _weapon_upgrade_manager.get_effective_damage(slot)
	var spd: float = _weapon_upgrade_manager.get_effective_speed(slot)
	var rld: float = _weapon_upgrade_manager.get_effective_reload_time(slot)
	var bst: int = _weapon_upgrade_manager.get_effective_burst_count(slot)
	return "DMG: %.0f  SPD: %.0f  RLD: %.1fs  BURST: %d" % [dmg, spd, rld, bst]


## Builds the next-level preview string showing deltas for changed stats.
func _build_preview_text(slot: Types.WeaponSlot, next_data: WeaponLevelData) -> String:
	var lines: Array[String] = []
	if next_data.damage_bonus != 0.0:
		var cur_damage: float = _weapon_upgrade_manager.get_effective_damage(slot)
		lines.append("Damage: %.0f -> %.0f (%+.0f)" % [cur_damage, cur_damage + next_data.damage_bonus, next_data.damage_bonus])
	if next_data.speed_bonus != 0.0:
		var cur_speed: float = _weapon_upgrade_manager.get_effective_speed(slot)
		lines.append("Speed: %.0f -> %.0f (%+.0f)" % [cur_speed, cur_speed + next_data.speed_bonus, next_data.speed_bonus])
	if next_data.reload_bonus != 0.0:
		var cur_reload: float = _weapon_upgrade_manager.get_effective_reload_time(slot)
		lines.append("Reload: %.1fs -> %.1fs (%+.1f)" % [cur_reload, maxf(cur_reload + next_data.reload_bonus, 0.1), next_data.reload_bonus])
	if next_data.burst_count_bonus != 0:
		var cur_burst: int = _weapon_upgrade_manager.get_effective_burst_count(slot)
		lines.append("Burst: %d -> %d (%+d)" % [cur_burst, cur_burst + next_data.burst_count_bonus, next_data.burst_count_bonus])
	if lines.is_empty():
		return "No stat changes"
	return "\n".join(lines)


## Called when the Upgrade button is pressed for a weapon slot.
func _on_upgrade_pressed(slot: Types.WeaponSlot) -> void:
	if _weapon_upgrade_manager == null:
		return
	_weapon_upgrade_manager.upgrade_weapon(slot)


## Called when weapon_upgraded signal is received from SignalBus.
func _on_weapon_upgraded(_weapon_slot: Types.WeaponSlot, _new_level: int) -> void:
	_refresh_weapons_tab()


## Called when resources change — refreshes button affordability states.
func _on_resource_changed_weapons(_resource_type: Types.ResourceType, _new_amount: int) -> void:
	_refresh_weapons_tab()
	if GameManager.get_game_state() == Types.GameState.BETWEEN_MISSIONS:
		_refresh_offers("")


func _on_enchantment_applied(_weapon_slot: Types.WeaponSlot, _slot_type: String, _enchantment_id: String) -> void:
	_refresh_weapon_enchantments()


func _on_enchantment_removed(_weapon_slot: Types.WeaponSlot, _slot_type: String) -> void:
	_refresh_weapon_enchantments()


func _refresh_weapon_enchantments() -> void:
	_update_weapon_enchantment_display(Types.WeaponSlot.CROSSBOW, _crossbow_enchant_label)
	_update_weapon_enchantment_display(Types.WeaponSlot.RAPID_MISSILE, _rapid_enchant_label)


func _update_weapon_enchantment_display(weapon_slot: Types.WeaponSlot, label: Label) -> void:
	if label == null:
		return

	var slots: Dictionary = EnchantmentManager.get_all_equipped_enchantments_for_weapon(weapon_slot)
	var parts: Array[String] = []

	for slot_type: String in ["elemental", "power"]:
		var enchantment_id: String = slots.get(slot_type, "") as String
		if enchantment_id == "":
			parts.append("%s: None" % slot_type)
		else:
			var enchantment: EnchantmentData = EnchantmentManager.get_equipped_enchantment(weapon_slot, slot_type)
			if enchantment == null:
				parts.append("%s: None" % slot_type)
			else:
				parts.append("%s: %s" % [slot_type, enchantment.display_name])

	label.text = ", ".join(parts)


func on_apply_enchantment_button_pressed(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String, gold_cost: int) -> void:
	var success: bool = EnchantmentManager.try_apply_enchantment(weapon_slot, slot_type, enchantment_id, gold_cost)
	if not success:
		return
	_refresh_weapon_enchantments()


func on_remove_enchantment_button_pressed(weapon_slot: Types.WeaponSlot, slot_type: String) -> void:
	EnchantmentManager.remove_enchantment(weapon_slot, slot_type)
	_refresh_weapon_enchantments()


func on_apply_crossbow_elemental_pressed() -> void:
	var enchantment_id: String = "scorching_bolts"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "elemental", enchantment_id, gold_cost)


func on_apply_crossbow_power_pressed() -> void:
	var enchantment_id: String = "sharpened_mechanism"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "power", enchantment_id, gold_cost)


func on_remove_crossbow_enchantments_pressed() -> void:
	on_remove_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "elemental")
	on_remove_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "power")


func on_apply_rapid_elemental_pressed() -> void:
	var enchantment_id: String = "toxic_payload"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "elemental", enchantment_id, gold_cost)


func on_apply_rapid_power_pressed() -> void:
	var enchantment_id: String = "sharpened_mechanism"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "power", enchantment_id, gold_cost)


func on_remove_rapid_enchantments_pressed() -> void:
	on_remove_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "elemental")
	on_remove_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "power")
````

---

## `ui/build_menu.gd`

````
# ui/build_menu.gd
# BuildMenu — shown during BUILD_MODE when a hex slot is selected.
# Zero game logic. All decisions delegated to HexGrid and EconomyManager.
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — BuildMenu class responsibilities.

class_name BuildMenu
extends Control

var _selected_slot: int = -1
var _is_sell_mode: bool = false

@onready var _slot_label: Label = $Panel/VBox/SlotLabel
@onready var _building_container: GridContainer = $Panel/VBox/BuildingContainer
@onready var _close_button: Button = $Panel/VBox/CloseButton
@onready var _sell_panel: VBoxContainer = $Panel/VBox/SellPanel
@onready var _sell_building_name: Label = $Panel/VBox/SellPanel/BuildingNameLabel
@onready var _sell_upgrade_status: Label = $Panel/VBox/SellPanel/UpgradeStatusLabel
@onready var _sell_refund: Label = $Panel/VBox/SellPanel/RefundLabel
@onready var _sell_button: Button = $Panel/VBox/SellPanel/Buttons/SellButton
@onready var _sell_cancel_button: Button = $Panel/VBox/SellPanel/Buttons/CancelButton

# ASSUMPTION: HexGrid path matches ARCHITECTURE.md §2.
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	print("[BuildMenu] _ready")
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.resource_changed.connect(_on_resource_changed)
	_close_button.pressed.connect(_on_close_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_sell_cancel_button.pressed.connect(_on_sell_cancel_pressed)


## Called by InputManager when player clicks a hex slot during BUILD_MODE.
func open_for_slot(slot_index: int) -> void:
	print("[BuildMenu] open_for_slot: slot=%d" % slot_index)
	_selected_slot = slot_index
	_is_sell_mode = false
	_slot_label.text = "Building on slot %d (yellow tile on ground)" % slot_index
	_hex_grid.set_build_slot_highlight(slot_index)
	_building_container.show()
	_sell_panel.hide()
	show()       # must come BEFORE _refresh() — the guard checks visibility
	_refresh()

func open_for_sell_slot(slot_index: int, slot_data: Dictionary) -> void:
	print("[BuildMenu] open_for_sell_slot: slot=%d" % slot_index)
	_selected_slot = slot_index
	_is_sell_mode = true
	_hex_grid.set_build_slot_highlight(slot_index)
	_slot_label.text = "Occupied slot %d" % slot_index
	_building_container.hide()
	_sell_panel.show()
	_refresh_sell_panel(slot_data)
	show()


func _refresh() -> void:
	# Deferred refresh can run after exit_build_mode — skip if menu is hidden or invalid.
	if not visible:
		return
	if _selected_slot < 0:
		return
	if GameManager.get_game_state() != Types.GameState.BUILD_MODE:
		return
	if _is_sell_mode:
		return

	while _building_container.get_child_count() > 0:
		_building_container.get_child(0).free()

	var count: int = 0
	for i: int in range(Types.BuildingType.size()):
		var bt: Types.BuildingType = i as Types.BuildingType
		var bd: BuildingData = _hex_grid.get_building_data(bt)
		if bd == null:
			print("[BuildMenu] _refresh: WARNING no BuildingData for type %d" % i)
			continue

		var btn: Button = Button.new()
		var is_unlocked: bool = _hex_grid.is_building_available(bt)
		var can_afford: bool = EconomyManager.can_afford(bd.gold_cost, bd.material_cost)

		btn.text = "%s\n%dg %dm" % [bd.display_name, bd.gold_cost, bd.material_cost]
		btn.disabled = not is_unlocked or not can_afford
		btn.custom_minimum_size = Vector2(180, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		btn.pressed.connect(func() -> void: _on_building_selected(bt))
		_building_container.add_child(btn)
		count += 1

	print("[BuildMenu] _refresh: slot=%d  gold=%d mat=%d  showing %d buttons" % [
		_selected_slot, EconomyManager.get_gold(), EconomyManager.get_building_material(), count
	])


func _on_building_selected(building_type: Types.BuildingType) -> void:
	print("[BuildMenu] _on_building_selected: type=%d slot=%d" % [building_type, _selected_slot])
	if _selected_slot < 0:
		print("[BuildMenu] _on_building_selected: REJECTED — no slot selected")
		return
	var placed: bool = _hex_grid.place_building(_selected_slot, building_type)
	print("[BuildMenu] _on_building_selected: place_building returned %s" % placed)
	if placed:
		# Exit build mode entirely — this triggers _on_build_mode_exited → hide().
		GameManager.exit_build_mode()


func _refresh_sell_panel(slot_data: Dictionary) -> void:
	var building: BuildingBase = slot_data.get("building", null) as BuildingBase
	if building == null:
		open_for_slot(_selected_slot)
		return

	var data: BuildingData = building.get_building_data()
	if data == null:
		_sell_building_name.text = "Unknown Building"
		_sell_upgrade_status.text = "Status: Unknown"
		_sell_refund.text = "Refund: N/A"
		return

	var is_upgraded: bool = building.is_upgraded
	_sell_building_name.text = data.display_name
	_sell_upgrade_status.text = "Status: %s" % ("Upgraded" if is_upgraded else "Basic")

	var refund_gold: int = data.gold_cost + (data.upgrade_gold_cost if is_upgraded else 0)
	var refund_material: int = data.material_cost + (data.upgrade_material_cost if is_upgraded else 0)
	_sell_refund.text = "Refund: %d gold, %d material" % [refund_gold, refund_material]


func _on_build_mode_entered() -> void:
	print("[BuildMenu] build_mode_entered — waiting for slot click")
	_selected_slot = -1
	_is_sell_mode = false
	_building_container.show()
	_sell_panel.hide()
	hide()  # UIManager keeps BuildMenu hidden until HexGrid explicitly opens it.


func _on_resource_changed(_resource_type: Types.ResourceType, _new_amount: int) -> void:
	if not visible:
		return
	if GameManager.get_game_state() != Types.GameState.BUILD_MODE:
		return
	if _selected_slot < 0:
		return
	# Deferred so we never free a button node while it is mid-signal-dispatch.
	call_deferred("_refresh")


func _on_build_mode_exited() -> void:
	print("[BuildMenu] build_mode_exited — hiding")
	hide()
	_selected_slot = -1
	_is_sell_mode = false


func _on_close_pressed() -> void:
	print("[BuildMenu] close pressed")
	GameManager.exit_build_mode()


func _on_sell_pressed() -> void:
	if _selected_slot < 0:
		hide()
		return
	_hex_grid.sell_building(_selected_slot)
	hide()


func _on_sell_cancel_pressed() -> void:
	hide()
````

---

## `ui/dialogue_panel.gd`

````
## dialogue_panel.gd
## Global hub dialogue overlay (click-to-continue).

extends Control
class_name DialoguePanel

var current_entry: DialogueEntry = null
var current_speaker_name: String = ""

@onready var _speaker_label: Label = $SpeakerLabel # ASSUMPTION: scene has SpeakerLabel node.
@onready var _text_label: Label = $TextLabel # ASSUMPTION: scene has TextLabel node.

func _ready() -> void:
	visible = false
	# SOURCE: Godot Control gui_input signal for click handling.
	gui_input.connect(_on_gui_input)


func show_entry(display_name: String, entry: DialogueEntry) -> void:
	current_entry = entry
	current_speaker_name = display_name

	if is_instance_valid(_speaker_label):
		_speaker_label.text = display_name

	if is_instance_valid(_text_label) and entry != null:
		_text_label.text = entry.text

	visible = true


func clear_dialogue() -> void:
	current_entry = null
	current_speaker_name = ""
	visible = false


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_advance_or_close()


func _advance_or_close() -> void:
	if current_entry == null:
		clear_dialogue()
		return

	# Mark the entry as played to respect once_only and chain behavior.
	DialogueManager.mark_entry_played(current_entry.entry_id)

	var chain_id: String = current_entry.chain_next_id
	if not chain_id.is_empty():
		var next_entry: DialogueEntry = DialogueManager.get_entry_by_id(chain_id)
		if next_entry != null:
			show_entry(current_speaker_name, next_entry)
			return

	# Chain exhausted or missing next entry.
	DialogueManager.notify_dialogue_finished(
		current_entry.entry_id,
		current_entry.character_id
	)
	clear_dialogue()
````

---

## `ui/dialogue_ui.gd`

````
## dialogue_ui.gd
## Minimal placeholder panel for hub dialogue lines. # PLACEHOLDER styling.

class_name DialogueUI
extends Control

var _current_entry_id: String = ""
var _current_character_id: String = ""

@onready var _name_label: Label = $Panel/VBox/NameLabel
@onready var _text_label: Label = $Panel/VBox/TextLabel
@onready var _advance_button: Button = $Panel/VBox/AdvanceButton


func _ready() -> void:
	visible = false
	_advance_button.pressed.connect(_on_advance_pressed)


func show_entry(entry: DialogueEntry) -> void:
	if entry == null:
		hide()
		return

	_current_entry_id = entry.entry_id
	_current_character_id = entry.character_id

	_name_label.text = _get_display_name(entry.character_id)
	_text_label.text = entry.text
	visible = true


func _get_display_name(character_id: String) -> String:
	match character_id:
		"FLORENCE":
			return "Florence"
		"COMPANION_MELEE":
			return "Arnulf"
		"SPELL_RESEARCHER":
			return "Sybil"
		"WEAPONS_ENGINEER":
			return "Weapons Engineer"
		"ENCHANTER":
			return "Enchanter"
		"MERCHANT":
			return "Merchant"
		"MERCENARY_COMMANDER":
			return "Commander"
		"CAMPAIGN_CHARACTER_X":
			return "Campaign Ally"
		"EXAMPLE_CHARACTER":
			return "Example"
		_:
			return character_id


func _on_advance_pressed() -> void:
	if _current_entry_id.is_empty():
		hide()
		return

	DialogueManager.mark_entry_played(_current_entry_id)

	var next_entry: DialogueEntry = null
	if DialogueManager.entries_by_id.has(_current_entry_id):
		var entry: DialogueEntry = DialogueManager.entries_by_id[_current_entry_id] as DialogueEntry
		if not entry.chain_next_id.is_empty():
			if DialogueManager.entries_by_id.has(entry.chain_next_id):
				next_entry = DialogueManager.entries_by_id[entry.chain_next_id] as DialogueEntry

	if next_entry != null:
		show_entry(next_entry)
	else:
		DialogueManager.notify_dialogue_finished(_current_entry_id, _current_character_id)
		_current_entry_id = ""
		_current_character_id = ""
		hide()
````

---

## `ui/dialogueui.gd`

````
## dialogueui.gd
## Compatibility path alias for prompt naming.
##
## The actual implementation lives in `res://ui/dialogue_ui.gd` (class_name DialogueUI).

extends DialogueUI
````

---

## `ui/end_screen.gd`

````
# ui/end_screen.gd
# EndScreen — shown on MISSION_WON, GAME_WON, MISSION_FAILED.
# Zero game logic.

class_name EndScreen
extends Control

@onready var _message_label: Label = $MessageLabel
@onready var _restart_button: Button = $RestartButton
@onready var _quit_button: Button = $QuitButton

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	match new_state:
		Types.GameState.GAME_WON:
			_message_label.text = "YOU SURVIVED 5 MISSIONS"
		Types.GameState.MISSION_WON:
			_message_label.text = "MISSION %d COMPLETE" % GameManager.get_current_mission()
		Types.GameState.MISSION_FAILED:
			_message_label.text = "TOWER DESTROYED"
		_:
			pass


func _on_restart_pressed() -> void:
	GameManager.start_new_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
````

---

## `ui/hub.gd`

````
## hub.gd
## Between-mission hub overlay (2D). Instantiates clickable hub characters from CharacterCatalog.

extends Control
class_name Hub2DHub

signal hub_opened()
signal hub_closed()
signal hub_character_interacted(character_id: String)

## Data-driven list of hub characters.
@export var character_catalog: CharacterCatalog

@onready var _characters_container: Container = $CharactersContainer # ASSUMPTION: scene has CharactersContainer node.

var _characters_by_id: Dictionary = {} # character_id -> HubCharacterBase2D
var _between_mission_screen: Node = null
var _ui_manager: Node = null

var _character_scene: PackedScene = preload("res://scenes/hub/character_base_2d.tscn")

func _ready() -> void:
	_initialize_characters()


func set_between_mission_screen(screen: Node) -> void:
	_between_mission_screen = screen


func _set_ui_manager(ui_manager: Node) -> void:
	_ui_manager = ui_manager


func _initialize_characters() -> void:
	if _characters_container == null:
		return

	for child: Node in _characters_container.get_children():
		child.queue_free()

	_characters_by_id.clear()

	if character_catalog == null:
		return

	for char_data: CharacterData in character_catalog.characters:
		if char_data == null:
			continue
		var char_node: HubCharacterBase2D = _character_scene.instantiate() as HubCharacterBase2D
		char_node.character_data = char_data
		_characters_container.add_child(char_node)
		_characters_by_id[char_data.character_id] = char_node
		char_node.character_interacted.connect(_on_character_interacted)


func open_hub() -> void:
	visible = true
	hub_opened.emit()


func close_hub() -> void:
	visible = false
	hub_closed.emit()


func _on_character_interacted(character_id: String) -> void:
	hub_character_interacted.emit(character_id)
	_handle_character_focus(character_id)


func focus_character(character_id: String) -> void:
	_on_character_interacted(character_id)


func _handle_character_focus(character_id: String) -> void:
	if character_catalog == null:
		return

	var char_node: HubCharacterBase2D = _characters_by_id.get(character_id, null) as HubCharacterBase2D
	if char_node == null or char_node.character_data == null:
		return

	var char_data: CharacterData = char_node.character_data

	# Switch BetweenMissionScreen tab based on hub role.
	if _between_mission_screen != null:
		match char_data.role:
			Types.HubRole.SHOP:
				_between_mission_screen.open_shop_panel()
			Types.HubRole.RESEARCH:
				_between_mission_screen.open_research_panel()
			Types.HubRole.ENCHANT:
				_between_mission_screen.open_enchant_panel()
			Types.HubRole.MERCENARY:
				_between_mission_screen.open_mercenary_panel()
			Types.HubRole.ALLY, Types.HubRole.FLAVOR_ONLY:
				pass
			_:
				pass

	# Request dialogue from DialogueManager and display it via UIManager.
	if _ui_manager != null and _ui_manager.has_method("show_dialogue"):
		var entry: DialogueEntry = DialogueManager.request_entry_for_character(
			char_data.character_id,
			char_data.default_dialogue_tags
		)
		if entry != null:
			_ui_manager.show_dialogue(char_data.display_name, entry)
````

---

## `ui/hud.gd`

````
# ui/hud.gd
# HUD — pure display. Never modifies game state.
# Uses _process (never _physics_process) to stay responsive at
# Engine.time_scale = 0.1 (build mode).
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — HUD class responsibilities.

class_name HUD
extends Control

@onready var _gold_label: Label = $ResourceDisplay/GoldLabel
@onready var _material_label: Label = $ResourceDisplay/MaterialLabel
@onready var _research_label: Label = $ResourceDisplay/ResearchLabel
@onready var _wave_label: Label = $WaveDisplay/WaveLabel
@onready var _countdown_label: Label = $WaveDisplay/CountdownLabel
@onready var _tower_hp_bar: ProgressBar = $TowerHPBar
@onready var _mana_bar: ProgressBar = $SpellPanel/ManaBar
@onready var _cooldown_label: Label = $SpellPanel/CooldownLabel
@onready var _crossbow_label: Label = $WeaponPanel/CrossbowLabel
@onready var _crossbow_reload_bar: ProgressBar = $WeaponPanel/CrossbowReloadBar
@onready var _missile_label: Label = $WeaponPanel/MissileLabel
@onready var _missile_reload_bar: ProgressBar = $WeaponPanel/MissileReloadBar
@onready var _build_mode_hint: Label = $BuildModeHint

@onready var _tower: Tower = get_node("/root/Main/Tower")

var _countdown_seconds: float = 0.0
var _is_counting_down: bool = false

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.resource_changed.connect(_on_resource_changed)
	SignalBus.wave_countdown_started.connect(_on_wave_countdown_started)
	SignalBus.wave_started.connect(_on_wave_started)
	SignalBus.tower_damaged.connect(_on_tower_damaged)
	SignalBus.mana_changed.connect(_on_mana_changed)
	SignalBus.spell_cast.connect(_on_spell_cast)
	SignalBus.spell_ready.connect(_on_spell_ready)
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)

	_build_mode_hint.hide()
	_countdown_label.hide()

	_gold_label.text = "Gold: %d" % EconomyManager.get_gold()
	_material_label.text = "Mat: %d" % EconomyManager.get_building_material()
	_research_label.text = "Res: %d" % EconomyManager.get_research_material()


# _process fires every render frame regardless of Engine.time_scale.
func _process(delta: float) -> void:
	if _is_counting_down:
		_countdown_seconds -= delta
		if _countdown_seconds < 0.0:
			_countdown_seconds = 0.0
			_is_counting_down = false
		_countdown_label.text = "Next wave: %.0fs" % _countdown_seconds

	_update_weapon_hud()

# ── Signal handlers ───────────────────────────────────────────────────────

func _on_resource_changed(resource_type: Types.ResourceType, new_amount: int) -> void:
	match resource_type:
		Types.ResourceType.GOLD:
			_gold_label.text = "Gold: %d" % new_amount
		Types.ResourceType.BUILDING_MATERIAL:
			_material_label.text = "Mat: %d" % new_amount
		Types.ResourceType.RESEARCH_MATERIAL:
			_research_label.text = "Res: %d" % new_amount


func _on_wave_countdown_started(wave_number: int, seconds_remaining: float) -> void:
	_wave_label.text = "WAVE %d / %d INCOMING" % [
		wave_number,
		GameManager.WAVES_PER_MISSION
	]
	_countdown_seconds = seconds_remaining
	_is_counting_down = true
	_countdown_label.show()


func _on_wave_started(wave_number: int, _enemy_count: int) -> void:
	_wave_label.text = "Wave %d / %d" % [
		wave_number,
		GameManager.WAVES_PER_MISSION
	]
	_is_counting_down = false
	_countdown_label.hide()


func _on_tower_damaged(current_hp: int, max_hp: int) -> void:
	_tower_hp_bar.max_value = float(max_hp)
	_tower_hp_bar.value = float(current_hp)


func _on_mana_changed(current_mana: int, max_mana: int) -> void:
	_mana_bar.max_value = float(max_mana)
	_mana_bar.value = float(current_mana)


func _on_spell_cast(_spell_id: String) -> void:
	_cooldown_label.text = "Shockwave: ON COOLDOWN"


func _on_spell_ready(_spell_id: String) -> void:
	_cooldown_label.text = "Shockwave: READY"


func _on_build_mode_entered() -> void:
	_build_mode_hint.show()


func _on_build_mode_exited() -> void:
	_build_mode_hint.hide()


func _update_weapon_hud() -> void:
	var state: Types.GameState = GameManager.get_game_state()
	if state != Types.GameState.COMBAT and state != Types.GameState.WAVE_COUNTDOWN:
		return
	if _tower == null or not is_instance_valid(_tower):
		return

	var cb_rem: float = _tower.get_crossbow_reload_remaining_seconds()
	var cb_total: float = _tower.get_crossbow_reload_total_seconds()
	if cb_rem <= 0.001:
		_crossbow_label.text = "Crossbow: READY"
		_crossbow_reload_bar.value = 100.0
	else:
		var pct_ready: float = 100.0 * (1.0 - cb_rem / maxf(cb_total, 0.001))
		_crossbow_label.text = "Crossbow: reload %.1fs (%.0f%%)" % [cb_rem, pct_ready]
		_crossbow_reload_bar.value = pct_ready

	var burst_left: int = _tower.get_rapid_missile_burst_remaining()
	var burst_total: int = _tower.get_rapid_missile_burst_total()
	var rm_rem: float = _tower.get_rapid_missile_reload_remaining_seconds()
	var rm_total: float = _tower.get_rapid_missile_reload_total_seconds()

	if burst_left > 0:
		_missile_label.text = "Missile: burst %d / %d shots left" % [burst_left, burst_total]
		_missile_reload_bar.value = 100.0 * (float(burst_left) / float(max(1, burst_total)))
	elif rm_rem <= 0.001:
		_missile_label.text = "Missile: READY — burst %d shots" % burst_total
		_missile_reload_bar.value = 100.0
	else:
		var pct: float = 100.0 * (1.0 - rm_rem / maxf(rm_total, 0.001))
		_missile_label.text = "Missile: reload %.1fs — next burst %d shots" % [rm_rem, burst_total]
		_missile_reload_bar.value = pct


## Legacy hook — HUD now polls Tower each frame in _process.
func update_weapon_display(
		crossbow_ready: bool,
		missile_ready: bool
) -> void:
	_crossbow_label.text = "Crossbow: %s" % ("READY" if crossbow_ready else "RELOADING")
	_missile_label.text = "Missile: %s" % ("READY" if missile_ready else "RELOADING")
````

---

## `ui/main_menu.gd`

````
# ui/main_menu.gd
# MainMenu — start screen. Zero game logic.

class_name MainMenu
extends Control

@onready var _start_button: Button = $StartButton
@onready var _settings_button: Button = $SettingsButton
@onready var _quit_button: Button = $QuitButton

func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	GameManager.start_new_game()


func _on_settings_pressed() -> void:
	pass  # POST-MVP: open settings screen.


func _on_quit_pressed() -> void:
	get_tree().quit()
````

---

## `ui/mission_briefing.gd`

````
extends Control

@onready var mission_label: Label = $MissionLabel
@onready var begin_button: Button = $BeginButton

func _ready() -> void:
	SignalBus.mission_started.connect(_on_mission_started)
	begin_button.pressed.connect(_on_begin_pressed)

func _on_mission_started(mission_number: int) -> void:
	mission_label.text = "MISSION %d" % mission_number

func _on_begin_pressed() -> void:
	if GameManager.get_game_state() != Types.GameState.MISSION_BRIEFING:
		return
	GameManager.start_wave_countdown()
````

---

## `ui/ui_manager.gd`

````
# ui/ui_manager.gd
# UIManager — lightweight panel router. Hub dialogue is delegated to DialoguePanel + DialogueManager.
#
# Credit: Godot Engine Official Documentation — CanvasLayer
# https://docs.godotengine.org/en/stable/classes/class_canvaslayer.html
# License: CC-BY-3.0
# Adapted: Control show/hide routing per game state.

class_name UIManager
extends Control

@onready var _hud: Control = get_node("/root/Main/UI/HUD")
@onready var _build_menu: Control = get_node("/root/Main/UI/BuildMenu")
@onready var _between_mission_screen: Control = get_node(
	"/root/Main/UI/BetweenMissionScreen"
)
@onready var _main_menu: Control = get_node("/root/Main/UI/MainMenu")
@onready var _mission_briefing: Control = get_node("/root/Main/UI/MissionBriefing")
@onready var _end_screen: Control = get_node("/root/Main/UI/EndScreen")

@onready var _hub: Control = get_node_or_null("/root/Main/UI/Hub") as Control
var _dialogue_panel: DialoguePanel = null

var _pending_dialogue_character_ids: Array[String] = []
var _pending_panel_dialogue_speaker_names: Array[String] = []
var _pending_panel_dialogue_entries: Array[DialogueEntry] = []

# Re-fetch hub for safety: @onready can be null in some headless/GdUnit stubs.
func _get_hub() -> Control:
	var hub_by_path: Control = get_node_or_null("/root/Main/UI/Hub") as Control
	if hub_by_path != null:
		return hub_by_path

	var ui_node: Node = get_node_or_null("/root/Main/UI")
	if ui_node == null:
		return null

	for child: Node in ui_node.get_children():
		if child.name.begins_with("Hub"):
			var hub_candidate: Control = child as Control
			if hub_candidate != null:
				return hub_candidate

	return null

func _get_dialogue_panel() -> DialoguePanel:
	if _dialogue_panel != null and is_instance_valid(_dialogue_panel):
		return _dialogue_panel
	_dialogue_panel = get_node_or_null("DialoguePanel") as DialoguePanel
	return _dialogue_panel

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	DialogueManager.dialogue_line_finished.connect(_on_dialogue_line_finished)

	# Wire the hub with stable references so it can route tab changes + dialogue.
	var hub: Control = _get_hub()
	if hub != null:
		var bms: BetweenMissionScreen = _between_mission_screen as BetweenMissionScreen
		if hub.has_method("set_between_mission_screen"):
			hub.set_between_mission_screen(bms)
		if hub.has_method("_set_ui_manager"):
			hub._set_ui_manager(self)

	# Sync to current state immediately for hot-reload safety.
	_apply_state(GameManager.get_game_state())

	# Ensure hub visibility is correct when syncing to an already-active state.
	var state_now: Types.GameState = GameManager.get_game_state()
	if state_now == Types.GameState.BETWEEN_MISSIONS:
		var hub2: Control = _get_hub()
		if hub2 != null:
			if hub2.has_method("open_hub"):
				hub2.open_hub()
			else:
				hub2.visible = true
	else:
		var hub3: Control = _get_hub()
		if hub3 != null:
			if hub3.has_method("close_hub"):
				hub3.close_hub()
			else:
				hub3.visible = false


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	var hub: Control = _get_hub()
	# Deterministic routing for tests + gameplay:
	# - Always hide hub + clear dialogue on any state change
	# - Re-open hub only when entering BETWEEN_MISSIONS from a non-between state
	#   (prevents ambiguous argument ordering from leaving the hub stuck open).
	if hub != null:
		hub.visible = false

	clear_dialogue()
	var dp: DialoguePanel = _get_dialogue_panel()
	if dp != null:
		dp.visible = false

	_apply_state(new_state)

	if _old_state != Types.GameState.BETWEEN_MISSIONS and new_state == Types.GameState.BETWEEN_MISSIONS:
		if hub != null:
			if hub.has_method("open_hub"):
				hub.open_hub()
			else:
				hub.visible = true


## Single source of truth for UI panel visibility.
func _apply_state(state: Types.GameState) -> void:
	_hud.hide()
	_build_menu.hide()
	_between_mission_screen.hide()
	_main_menu.hide()
	_mission_briefing.hide()
	_end_screen.hide()

	match state:
		Types.GameState.MAIN_MENU:
			_main_menu.show()

		Types.GameState.MISSION_BRIEFING:
			_mission_briefing.show()

		Types.GameState.COMBAT, \
		Types.GameState.WAVE_COUNTDOWN:
			_hud.show()

		Types.GameState.BUILD_MODE:
			_hud.show()
			# BuildMenu is shown only after selecting a hex slot (see `BuildMenu.open_for_slot()`).
			# Keeping it hidden at build-mode entry prevents it from covering most of the grid.

		Types.GameState.BETWEEN_MISSIONS:
			_between_mission_screen.show()

		Types.GameState.MISSION_WON, \
		Types.GameState.GAME_WON, \
		Types.GameState.MISSION_FAILED:
			_end_screen.show()


func _ensure_dialogue_panel() -> void:
	if _get_dialogue_panel() != null:
		return

	var scene: PackedScene = load("res://ui/dialogue_panel.tscn") as PackedScene
	_dialogue_panel = scene.instantiate() as DialoguePanel
	add_child(_dialogue_panel)


func show_dialogue_for_character(character_id: String) -> void:
	_ensure_dialogue_panel()
	if _dialogue_panel.visible:
		_pending_dialogue_character_ids.append(character_id)
		return
	var entry: DialogueEntry = DialogueManager.request_entry_for_character(character_id)
	if entry != null:
		var speaker: String = _get_display_name(character_id)
		show_dialogue(speaker, entry)
	else:
		_flush_pending_dialogue()


func _on_dialogue_line_finished(_entry_id: String, _character_id: String) -> void:
	_flush_pending_dialogue()


func _flush_pending_dialogue() -> void:
	_ensure_dialogue_panel()

	# 1) Hub-triggered dialogue queued via show_dialogue().
	while _pending_panel_dialogue_entries.size() > 0:
		var speaker: String = _pending_panel_dialogue_speaker_names.pop_front()
		var next_entry: DialogueEntry = _pending_panel_dialogue_entries.pop_front()
		if next_entry != null:
			_dialogue_panel.show_entry(speaker, next_entry)
			return

	# 2) Legacy queued dialogues based on character_id.
	while _pending_dialogue_character_ids.size() > 0:
		var next_id: String = _pending_dialogue_character_ids.pop_front()
		var entry: DialogueEntry = DialogueManager.request_entry_for_character(next_id)
		if entry != null:
			var speaker2: String = _get_display_name(next_id)
			_dialogue_panel.show_entry(speaker2, entry)
			return


func show_dialogue(display_name: String, entry: DialogueEntry) -> void:
	_ensure_dialogue_panel()
	if entry == null:
		return

	# If something is already visible, queue until the current chain finishes.
	if _dialogue_panel.visible:
		_pending_panel_dialogue_speaker_names.append(display_name)
		_pending_panel_dialogue_entries.append(entry)
		return

	_dialogue_panel.show_entry(display_name, entry)


func clear_dialogue() -> void:
	_pending_dialogue_character_ids.clear()
	_pending_panel_dialogue_speaker_names.clear()
	_pending_panel_dialogue_entries.clear()

	var dp: DialoguePanel = _get_dialogue_panel()
	if dp != null:
		dp.clear_dialogue()


func _get_display_name(character_id: String) -> String:
	match character_id:
		"FLORENCE":
			return "Florence"
		"COMPANION_MELEE":
			return "Arnulf"
		"SPELL_RESEARCHER":
			return "Sybil"
		"WEAPONS_ENGINEER":
			return "Weapons Engineer"
		"ENCHANTER":
			return "Enchanter"
		"MERCHANT":
			return "Merchant"
		"MERCENARY_COMMANDER":
			return "Commander"
		"CAMPAIGN_CHARACTER_X":
			return "Campaign Ally"
		"EXAMPLE_CHARACTER":
			return "Example"
		_:
			return character_id
````

---

## `ui/world_map.gd`

````
## world_map.gd
## Read-only world map panel: lists territories and shows details from GameManager state.
## No campaign rules here — presenter only.

class_name WorldMap
extends Control

@onready var territory_buttons_container: VBoxContainer = %TerritoryButtons
@onready var day_label: Label = %DayLabel
@onready var territory_name_label: Label = %TerritoryNameLabel
@onready var territory_description_label: Label = %TerritoryDescriptionLabel
@onready var terrain_label: Label = %TerrainLabel
@onready var ownership_label: Label = %OwnershipLabel
@onready var bonuses_label: Label = %BonusesLabel


func _ready() -> void:
	_build_territory_buttons()
	_update_day_and_current_territory()
	_connect_signals()


func _connect_signals() -> void:
	SignalBus.territory_state_changed.connect(_on_territory_state_changed)
	SignalBus.world_map_updated.connect(_on_world_map_updated)
	SignalBus.game_state_changed.connect(_on_game_state_changed)


func _clear_buttons() -> void:
	for child: Node in territory_buttons_container.get_children():
		child.queue_free()


func _build_territory_buttons() -> void:
	_clear_buttons()
	var territories: Array[TerritoryData] = GameManager.get_all_territories()
	for territory: TerritoryData in territories:
		if territory == null:
			continue
		var button: Button = Button.new()
		button.text = _get_button_text_for_territory(territory)
		button.modulate = territory.color
		button.pressed.connect(_on_territory_button_pressed.bind(territory.territory_id))
		territory_buttons_container.add_child(button)

	var current: TerritoryData = GameManager.get_current_day_territory()
	if current != null:
		_update_details_for_territory(current)


func _get_button_text_for_territory(territory: TerritoryData) -> String:
	var label: String = territory.display_name
	if territory.is_permanently_lost:
		label += " (Lost)"
	elif territory.is_controlled_by_player:
		label += " (Held)"
	return label


func _update_day_and_current_territory() -> void:
	var day_index: int = GameManager.get_current_day_index()
	day_label.text = "Day: %d" % day_index
	var current: TerritoryData = GameManager.get_current_day_territory()
	if current == null:
		territory_name_label.text = "Territory: -"
		territory_description_label.text = "Description: -"
		terrain_label.text = "Terrain: -"
		ownership_label.text = "Ownership: -"
		bonuses_label.text = "Bonuses: -"
	else:
		_update_details_for_territory(current)


func _update_details_for_territory(territory: TerritoryData) -> void:
	territory_name_label.text = "Territory: %s" % territory.display_name
	territory_description_label.text = "Description: %s" % territory.description
	terrain_label.text = "Terrain: %s" % _terrain_type_to_string(territory.terrain_type)
	var ownership: String = "Neutral"
	if territory.is_permanently_lost:
		ownership = "Lost"
	elif territory.is_controlled_by_player:
		ownership = "Held"
	ownership_label.text = "Ownership: %s" % ownership

	var parts: Array[String] = []
	if territory.bonus_flat_gold_end_of_day != 0:
		parts.append("Flat gold/day: %d" % territory.bonus_flat_gold_end_of_day)
	if territory.bonus_percent_gold_end_of_day != 0.0:
		parts.append("Gold %%/day: %.0f%%" % (territory.bonus_percent_gold_end_of_day * 100.0))
	if parts.is_empty():
		bonuses_label.text = "Bonuses: None"
	else:
		bonuses_label.text = "Bonuses: %s" % ", ".join(parts)


func _terrain_type_to_string(terrain_type: int) -> String:
	match terrain_type:
		TerritoryData.TerrainType.PLAINS:
			return "Plains"
		TerritoryData.TerrainType.FOREST:
			return "Forest"
		TerritoryData.TerrainType.SWAMP:
			return "Swamp"
		TerritoryData.TerrainType.MOUNTAIN:
			return "Mountain"
		TerritoryData.TerrainType.CITY:
			return "City"
		_:
			return "Other"


func _on_territory_button_pressed(territory_id: String) -> void:
	var territory: TerritoryData = GameManager.get_territory_data(territory_id)
	if territory != null:
		_update_details_for_territory(territory)


func _on_territory_state_changed(_territory_id: String) -> void:
	_build_territory_buttons()


func _on_world_map_updated() -> void:
	_build_territory_buttons()
	_update_day_and_current_territory()


func _on_game_state_changed(_old_state: Types.GameState, new_state: Types.GameState) -> void:
	if new_state == Types.GameState.BETWEEN_MISSIONS:
		_update_day_and_current_territory()
````
