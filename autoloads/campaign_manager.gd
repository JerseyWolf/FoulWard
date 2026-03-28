## campaign_manager.gd
## Campaign/day-level state controller above GameManager mission flow.
## Owns campaign progress, DayConfig lookup, ally roster, mercenary offers, and mini-boss defection.
## DEVIATION: Mercenary/MiniBoss resource types are referenced as Resource/Variant here so this autoload
## parses before global `class_name` registration (same pattern as Prompt 11 ally roster).

extends Node

const DEFAULT_SHORT_CAMPAIGN: CampaignConfig = preload("res://resources/campaigns/campaign_short_5_days.tres")
const FactionDataType = preload("res://scripts/resources/faction_data.gd")
const DEFAULT_MERCENARY_CATALOG_PATH: String = "res://resources/mercenary_catalog.tres"
const _MERCENARY_OFFER_DATA_GD: GDScript = preload("res://scripts/resources/mercenary_offer_data.gd")

var current_day: int = 1
var campaign_length: int = 0
var campaign_id: String = ""
var campaign_completed: bool = false
## When false, day progression handlers ignore `mission_won` / `mission_failed` (no `start_new_campaign()` yet).
var _has_active_campaign_run: bool = false
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
	_has_active_campaign_run = true
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
	var offer: Resource = _MERCENARY_OFFER_DATA_GD.new() as Resource
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
	if not _has_active_campaign_run:
		return
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
	if not _has_active_campaign_run:
		return
	if mission_number != current_day:
		return

	failed_attempts_on_current_day += 1
	SignalBus.day_failed.emit(current_day)


func set_active_campaign_config_for_test(config: CampaignConfig) -> void:
	active_campaign_config = config
	_set_campaign_config(config)


func remove_all_allies() -> void:
	owned_allies.clear()
	active_allies_for_next_day.clear()
	_sync_current_ally_roster_for_spawn()
	SignalBus.ally_roster_changed.emit()


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
