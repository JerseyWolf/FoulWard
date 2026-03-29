## economy_manager.gd
## Owns gold, building_material, and research_material resource counters for FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

## When mission `duplicate_cost_k_override` is negative (typically [code]-1.0[/code] for "no override"), use this linear duplicate coefficient:
## multiplier = 1.0 + k * n (n = copies already purchased this mission for that building id).
const DEFAULT_DUPLICATE_COST_K: float = 0.08

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

## Mission-scoped economy (optional). Cleared in `reset_to_defaults`.
var _mission_economy: MissionEconomyData = null
var _sell_refund_global_multiplier: float = 1.0
## Count of paid placements per stable building id (see `_duplicate_key`). Not decremented on sell.
## Reset on `reset_to_defaults` and when a new mission economy is applied.
var _duplicate_placements_by_id: Dictionary = {} # String -> int
var _passive_gold_accum: float = 0.0
var _passive_material_accum: float = 0.0

func _ready() -> void:
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.wave_cleared.connect(_on_wave_cleared)
	set_process(false)


func _process(delta: float) -> void:
	if not (_mission_economy is MissionEconomyData):
		return
	var me: MissionEconomyData = _mission_economy as MissionEconomyData
	var pg: float = me.passive_gold_per_sec * delta
	var pm: float = me.passive_material_per_sec * delta
	if pg <= 0.0 and pm <= 0.0:
		return
	_passive_gold_accum += pg
	_passive_material_accum += pm
	var gi: int = int(_passive_gold_accum)
	var mi: int = int(_passive_material_accum)
	if gi > 0:
		_passive_gold_accum -= float(gi)
		add_gold(gi)
	if mi > 0:
		_passive_material_accum -= float(mi)
		add_building_material(mi)

# ── Signal receivers ───────────────────────────────────────────────────────────

func _on_enemy_killed(_enemy_type: Types.EnemyType, _position: Vector3, gold_reward: int) -> void:
	var bonus: int = GameManager.get_aggregate_flat_gold_per_kill()
	var total: int = gold_reward + bonus
	if total > 0:
		add_gold(total)


func _on_wave_cleared(wave_number: int) -> void:
	grant_wave_clear_reward(wave_number, _mission_economy)

# ── Gold ───────────────────────────────────────────────────────────────────────

## Adds amount to gold. Emits resource_changed(GOLD, new_amount).
func add_gold(amount: int) -> void:
	if amount <= 0:
		push_warning("add_gold called with non-positive amount: %d" % amount)
		return
	gold += amount
	SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)

## Deducts amount from gold. Returns false without modifying state if insufficient.
func spend_gold(amount: int) -> bool:
	if amount <= 0:
		push_warning("spend_gold called with non-positive amount: %d" % amount)
		return false
	if gold < amount:
		return false
	gold -= amount
	SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
	return true

# ── Building Material ──────────────────────────────────────────────────────────

## Adds amount to building_material. Emits resource_changed(BUILDING_MATERIAL, new_amount).
func add_building_material(amount: int) -> void:
	if amount <= 0:
		push_warning("add_building_material called with non-positive amount: %d" % amount)
		return
	building_material += amount
	SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)

## Deducts amount from building_material. Returns false without modifying state if insufficient.
func spend_building_material(amount: int) -> bool:
	if amount <= 0:
		push_warning("spend_building_material called with non-positive amount: %d" % amount)
		return false
	if building_material < amount:
		return false
	building_material -= amount
	SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
	return true

# ── Research Material ──────────────────────────────────────────────────────────

## Adds amount to research_material. Emits resource_changed(RESEARCH_MATERIAL, new_amount).
func add_research_material(amount: int) -> void:
	if amount <= 0:
		push_warning("add_research_material called with non-positive amount: %d" % amount)
		return
	research_material += amount
	SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)

## Deducts amount from research_material. Returns false without modifying state if insufficient.
func spend_research_material(amount: int) -> bool:
	if amount <= 0:
		push_warning("spend_research_material called with non-positive amount: %d" % amount)
		return false
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


# ── Mission economy & building transactions ────────────────────────────────────

func _duplicate_key(building_data: BuildingData) -> String:
	if building_data == null:
		return ""
	var id_str: String = building_data.id.strip_edges()
	if not id_str.is_empty():
		return id_str
	return "building_type:%d" % int(building_data.building_type)


## Number of paid placements this mission for [param building_id] (same key as duplicate scaling).
func get_duplicate_count(building_id: String) -> int:
	var key: String = building_id.strip_edges()
	if key.is_empty():
		return 0
	return int(_duplicate_placements_by_id.get(key, 0))


## Multiplier applied to base placement costs when `apply_duplicate_scaling` is true (next purchase).
## Returns 1.0 when duplicate scaling is off or [param building_data] is null.
func get_cost_multiplier(building_data: BuildingData) -> float:
	if building_data == null or not building_data.apply_duplicate_scaling:
		return 1.0
	var n: int = get_duplicate_count(_duplicate_key(building_data))
	var k: float = _get_duplicate_cost_k()
	return 1.0 + k * float(n)


## Effective gold to place [param building_data] (duplicate linear scaling when enabled).
func get_gold_cost(building_data: BuildingData) -> int:
	if building_data == null:
		return 0
	var base: int = building_data.get_effective_cost_gold()
	if not building_data.apply_duplicate_scaling:
		return base
	var mult: float = get_cost_multiplier(building_data)
	return int(round(float(base) * mult))


## Effective material to place [param building_data].
func get_material_cost(building_data: BuildingData) -> int:
	if building_data == null:
		return 0
	var base: int = building_data.get_effective_cost_material()
	if not building_data.apply_duplicate_scaling:
		return base
	var mult: float = get_cost_multiplier(building_data)
	return int(round(float(base) * mult))


func _get_duplicate_cost_k() -> float:
	if _mission_economy is MissionEconomyData:
		var me: MissionEconomyData = _mission_economy as MissionEconomyData
		if me.duplicate_cost_k_override >= 0.0:
			return me.duplicate_cost_k_override
	return DEFAULT_DUPLICATE_COST_K


## Call after a successful **paid** placement (not shop-free vouchers). Counts toward duplicate scaling only for new placements.
func register_purchase(building_data: BuildingData) -> void:
	if building_data == null:
		return
	var key: String = _duplicate_key(building_data)
	if key.is_empty():
		return
	_duplicate_placements_by_id[key] = int(_duplicate_placements_by_id.get(key, 0)) + 1


## True if [param wallet_gold] / [param wallet_material] cover `get_*_cost` for this placement (duplicate scaling included).
func can_afford_building(building_data: BuildingData, wallet_gold: int, wallet_material: int) -> bool:
	if building_data == null:
		return false
	return wallet_gold >= get_gold_cost(building_data) and wallet_material >= get_material_cost(building_data)


## Sell refund: `invested * sell_refund_fraction * sell_refund_global_multiplier` (rounded per resource).
func get_refund(building_data: BuildingData, invested_gold: int, invested_material: int) -> Vector2i:
	if building_data == null:
		return Vector2i.ZERO
	var f: float = building_data.sell_refund_fraction * _sell_refund_global_multiplier
	return Vector2i(
			int(round(float(invested_gold) * f)),
			int(round(float(invested_material) * f))
	)


## Applies mission economy overrides and optional starting stock. Enables `_process` passive income when rates &gt; 0.
## Clears per-mission duplicate placement counts whenever mission economy is (re)applied.
func apply_mission_economy(econ: MissionEconomyData = null) -> void:
	_duplicate_placements_by_id.clear()
	_mission_economy = econ
	_passive_gold_accum = 0.0
	_passive_material_accum = 0.0
	if econ == null:
		_sell_refund_global_multiplier = 1.0
		set_process(false)
		return
	_sell_refund_global_multiplier = maxf(0.0, econ.sell_refund_global_multiplier)
	if econ.starting_gold > 0:
		gold = econ.starting_gold
	if econ.starting_material > 0:
		building_material = econ.starting_material
	if econ.starting_gold > 0 or econ.starting_material > 0:
		SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
		SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
	set_process(econ.passive_gold_per_sec > 0.0 or econ.passive_material_per_sec > 0.0)


func get_sell_refund_global_multiplier() -> float:
	return _sell_refund_global_multiplier


## Gold granted for clearing [param wave] (1-based). [param econ] may be null (returns 0).
func get_wave_reward_gold(wave: int, econ: MissionEconomyData) -> int:
	if econ == null or wave < 1:
		return 0
	return maxi(0, econ.wave_clear_bonus_gold)


## Building material granted for clearing [param wave]. [param econ] may be null (returns 0).
func get_wave_reward_material(wave: int, econ: MissionEconomyData) -> int:
	if econ == null or wave < 1:
		return 0
	return maxi(0, econ.wave_clear_bonus_material)


## Adds wave-clear rewards to player currency. No-op when [param econ] is null or amounts are 0.
## Returns Vector2i(granted_gold, granted_material) for tests and UI.
func grant_wave_clear_reward(wave: int, econ: MissionEconomyData) -> Vector2i:
	var gg: int = get_wave_reward_gold(wave, econ)
	var gm: int = get_wave_reward_material(wave, econ)
	if gg > 0:
		add_gold(gg)
	if gm > 0:
		add_building_material(gm)
	return Vector2i(gg, gm)


# ── Reset ──────────────────────────────────────────────────────────────────────

## Apply gold / building / research from a save snapshot (SaveManager).
func apply_save_snapshot(g: int, building_mat: int, research_mat: int) -> void:
	gold = maxi(0, g)
	building_material = maxi(0, building_mat)
	research_material = maxi(0, research_mat)
	SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
	SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
	SignalBus.resource_changed.emit(Types.ResourceType.RESEARCH_MATERIAL, research_material)


## Resets all three resources to starting values. Emits resource_changed for each.
## Call this at new-game start or during test setup.
func reset_to_defaults() -> void:
	_mission_economy = null
	_sell_refund_global_multiplier = 1.0
	_duplicate_placements_by_id.clear()
	_passive_gold_accum = 0.0
	_passive_material_accum = 0.0
	set_process(false)

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

