PROMPT:

# Session 6: Shop Rotation & Economy Tuning

## Goal
Design the shop inventory rotation system (different items available each day) and tune SimBot strategy profile difficulty_target values. The master doc TBD asks: "How many items shown per day?" — this session decides.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `shop_manager.gd` — ShopManager scene-bound manager; current shop logic
- `shop_item_data.gd` — ShopItemData resource class definition
- `economy_manager.gd` — EconomyManager autoload; lines 1-50 covering constants and currency fields
- `shop_catalog.tres` — Current static shop catalog (4 items)
- `strategy_balanced_default.tres` — SimBot balanced strategy profile
- `strategy_greedy_econ.tres` — SimBot greedy economy profile
- `strategy_heavy_fire.tres` — SimBot heavy fire profile
- `strategyprofile.gd` — StrategyProfile resource class definition

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: shop inventory rotation and SimBot profile tuning.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

DESIGN DECISION: Show 4-6 items per day from a larger pool of 12-15 total items.

REQUIREMENTS:

Part A — Shop Rotation:
1. Design 12-15 ShopItemData entries organized into categories: consumables (instant effects), equipment (persistent buffs for the mission), and vouchers (free building placements).
2. Include the existing 4 items plus: building_material_pack (gain 10 BM), research_boost (gain 3 RM), tower_armor_plate (+50 tower max HP for mission), fire_oil_flask (next 5 projectiles deal bonus fire damage), scout_report (reveal next wave composition), mercenary_discount (reduce next merc cost by 20%), emergency_repair (restore 25% tower HP mid-combat).
3. Design the rotation algorithm: seed with day_index for determinism. Always include at least 1 consumable and 1 equipment. Exclude items the player has already stacked to max (cap 5 per consumable).
4. Add to ShopManager: a get_daily_items(day_index: int) method that returns Array[ShopItemData].
5. Add ShopItemData fields: category (String: "consumable", "equipment", "voucher"), max_stack (int, default 5), rarity_weight (float, default 1.0).
6. Provide the complete .tres specification for each new item.

Part B — SimBot Profile Tuning:
1. Set difficulty_target for each profile: BALANCED_DEFAULT: 0.5, GREEDY_ECON: 0.3, HEAVY_FIRE: 0.7.
2. Provide exact .tres field values for each profile.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 6: Shop Rotation

## Economy (§18)

EXISTS IN CODE. Three currencies: gold (starting 1000), building_material (starting 50), research_material (starting 0).

Duplicate cost scaling: linear per BuildingData.building_id. Sell refund: sell_refund_fraction x sell_refund_global_multiplier.

## EconomyManager API (§3.5, relevant methods only)

| Signature | Returns | Usage |
|-----------|---------|-------|
| add_gold(amount: int) -> void | void | Adds gold |
| spend_gold(amount: int) -> bool | bool | Spends if affordable |
| can_afford_building(building_data: BuildingData) -> bool | bool | Check affordability |
| get_gold() -> int | int | Current gold |
| get_building_material() -> int | int | Current BM |
| get_research_material() -> int | int | Current RM |
| reset_to_defaults() -> void | void | Resets to starting values |

## Shop (§19)

EXISTS IN CODE (basic).

4 items: tower_repair, building_repair, arrow_tower (voucher), mana_draught.

PLANNED: Shop inventory rotation.

## ShopManager API (§4.4)

| Signature | Returns | Usage |
|-----------|---------|-------|
| get_shop_items() -> Array[ShopItemData] | Array | Current catalog |
| purchase_item(item_id: String) -> bool | bool | Spends gold, applies effect |

## SimBot and Testing (§23)

- SimBot — headless simulation: run_balance_sweep, run_batch, run_single.
- Loadouts: balanced, summoner_heavy, artillery_air.
- CombatStatsTracker writes wave/building CSVs.

## Shop Signal (§24)
| Signal | Parameters |
|--------|-----------|
| shop_item_purchased | item_id: String |

## Open TBD — Shop (§33)
| Item | Question | Who Decides |
|------|----------|-------------|
| Shop rotation count | How many items shown per day? | Designer |

Decision for this session: 4-6 items per day from a pool of 12-15.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- push_warning() not assert() in production

FILES:

# Files to Upload for Session 6: Shop Rotation

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_06_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/shop_manager.gd` — ShopManager scene-bound manager; current shop logic (full file, ~150 lines estimated)
2. `scripts/resources/shop_item_data.gd` — ShopItemData resource class definition (~30 lines estimated)
3. `autoloads/economy_manager.gd` — EconomyManager autoload; lines 1-50 covering constants and currency fields (~50 lines)
4. `resources/shop_data/shop_catalog.tres` — Current static shop catalog with 4 items (~40 lines estimated)
5. `resources/strategyprofiles/strategy_balanced_default.tres` — Balanced SimBot profile (~20 lines)
6. `resources/strategyprofiles/strategy_greedy_econ.tres` — Greedy economy SimBot profile (~20 lines)
7. `resources/strategyprofiles/strategy_heavy_fire.tres` — Heavy fire SimBot profile (~20 lines)
8. `scripts/resources/strategyprofile.gd` — StrategyProfile resource class definition (~30 lines estimated)

Total estimated token load: ~360 lines across 8 files

scripts/shop_manager.gd:
## ShopManager — Owns the shop catalog and handles item purchases; consumables apply on mission start.
# scripts/shop_manager.gd
# ShopManager – owns the shop catalog and handles item purchases.
# Effects: tower_repair / building_repair immediate; consumables stack (cap 20) and apply on mission_started.
# Arrow tower voucher uses a pending flag consumed by apply_mission_start_consumables() from GameManager.
# All resource spending goes through EconomyManager.
# Emits SignalBus.shop_item_purchased(item_id) on success.

class_name ShopManager
extends Node

const CONSUMABLE_STACK_CAP: int = 20

# ---------------------------------------------------------------------------
# Exports
# ---------------------------------------------------------------------------

## All purchasable items. Populated via editor with shop_catalog.tres.
@export var shop_catalog: Array[ShopItemData] = []

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _consumable_stacks: Dictionary = {} ## String -> int
var _arrow_tower_shop_pending: bool = false

# ---------------------------------------------------------------------------
# Ready
# ---------------------------------------------------------------------------

func _ready() -> void:
	if not SignalBus.mission_started.is_connected(_on_mission_started):
		SignalBus.mission_started.connect(_on_mission_started)


func _exit_tree() -> void:
	if SignalBus.mission_started.is_connected(_on_mission_started):
		SignalBus.mission_started.disconnect(_on_mission_started)


# ---------------------------------------------------------------------------
# Public API — consumable stacks
# ---------------------------------------------------------------------------

## Adds the given amount of the item_id consumable to the stack (capped at 20).
func add_consumable(item_id: String, amount: int = 1) -> void:
	if amount <= 0:
		return
	var cur: int = int(_consumable_stacks.get(item_id, 0))
	_consumable_stacks[item_id] = mini(cur + amount, CONSUMABLE_STACK_CAP)


## Decrements one unit of the item_id consumable; returns false if stack is empty.
func consume(item_id: String) -> bool:
	var cur: int = int(_consumable_stacks.get(item_id, 0))
	if cur <= 0:
		return false
	var next: int = cur - 1
	if next <= 0:
		_consumable_stacks.erase(item_id)
	else:
		_consumable_stacks[item_id] = next
	return true


## Returns the current stack count for the given item_id consumable.
func get_stack_count(item_id: String) -> int:
	return int(_consumable_stacks.get(item_id, 0))


## Returns a Dictionary snapshot of current state for serialization.
func get_save_data() -> Dictionary:
	return {"consumable_stacks": _consumable_stacks.duplicate(true)}


## Restores state from a previously saved Dictionary snapshot.
func restore_from_save(data: Dictionary) -> void:
	_consumable_stacks.clear()
	var raw: Variant = data.get("consumable_stacks", {})
	if raw is Dictionary:
		var d: Dictionary = raw
		for k: Variant in d.keys():
			if k is String:
				var v: Variant = d[k]
				if v is int:
					var n: int = clampi(v, 0, CONSUMABLE_STACK_CAP)
					if n > 0:
						_consumable_stacks[k] = n


# ---------------------------------------------------------------------------
# Public API — shop
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
	if not gold_spent:
		push_warning("ShopManager: spend_gold failed after can_afford returned true")
		return false

	if item.material_cost > 0:
		var mat_spent: bool = EconomyManager.spend_building_material(item.material_cost)
		if not mat_spent:
			push_warning("ShopManager: spend_building_material failed after can_afford returned true")
			return false

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


## Consumes the pending arrow-tower voucher flag; returns true if it was set.
func consume_arrow_tower_pending() -> bool:
	var was_pending: bool = _arrow_tower_shop_pending
	_arrow_tower_shop_pending = false
	return was_pending


## Called by GameManager when entering COMBAT for a mission (after mission_started).
## Applies non-consumable mission-start effects (arrow tower voucher).
func apply_mission_start_consumables() -> void:
	var hex: HexGrid = get_node_or_null("/root/Main/HexGrid") as HexGrid
	if consume_arrow_tower_pending() and hex != null:
		if not hex.place_building_shop_free(Types.BuildingType.ARROW_TOWER):
			push_warning(
				"ShopManager: arrow_tower_placed voucher could not place (no slot or locked)"
			)


# ---------------------------------------------------------------------------
# Mission start — consumables (stacked)
# ---------------------------------------------------------------------------

func _on_mission_started(_mission_number: int) -> void:
	var to_process: Array[String] = []
	for k: Variant in _consumable_stacks.keys():
		if k is String and int(_consumable_stacks[k]) > 0:
			to_process.append(k)
	for item_id: String in to_process:
		if get_stack_count(item_id) <= 0:
			continue
		_apply_consumable_effect(item_id)
		consume(item_id)


func _apply_consumable_effect(item_id: String) -> void:
	var item_data: ShopItemData = _find_item(item_id)
	if item_data == null:
		push_warning("ShopManager._apply_consumable_effect: no ShopItemData for '%s'" % item_id)
		return
	for tag: String in item_data.effect_tags:
		match tag:
			"mana_restore":
				var spell: SpellManager = get_node_or_null("/root/Main/Managers/SpellManager") as SpellManager
				if spell != null:
					spell.restore_mana(item_data.value)
					SignalBus.mana_draught_consumed.emit()
			"gold_bonus":
				EconomyManager.add_gold(item_data.value)
			"shield":
				var tower: Node = get_node_or_null("/root/Main/Tower")
				if tower != null and tower.has_method("add_spell_shield"):
					var dur: float = item_data.duration
					if dur <= 0.0:
						dur = 1.0
					tower.add_spell_shield(float(item_data.value), dur)
			_:
				push_warning("ShopManager._apply_consumable_effect: unknown effect tag '%s'" % tag)


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
			add_consumable("mana_draught", 1)
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

scripts/resources/shop_item_data.gd:
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
## Category: use `"consumable"` for stack-based battle-start items.
@export var item_type: String = ""
## Tags consumed by ShopManager when applying consumable effects (e.g. `"mana_restore"`).
@export var effect_tags: Array[String] = []
## For timed effects; `0` means instant / not used.
@export var duration: float = 0.0
## Reserved for per-consumable cooldown tracking (data field).
@export var cooldown: float = 0.0
## Numeric magnitude for effect dispatch (mana restored, gold bonus, shield HP, etc.).
@export var value: int = 0


autoloads/economy_manager.gd:
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

const DEFAULT_SELL_REFUND_FRACTION: float = 0.6

var gold: int = DEFAULT_GOLD
var building_material: int = DEFAULT_BUILDING_MATERIAL
var research_material: int = DEFAULT_RESEARCH_MATERIAL

## Mission-scoped economy (optional). Cleared in `reset_to_defaults`.
var _mission_economy: MissionEconomyData = null

# --- Duplicate-cost scaling (Prompt 3) ---
var duplicate_cost_k: float = DEFAULT_DUPLICATE_COST_K
## building_id (or duplicate key string) -> count of paid placements this mission (not decremented on sell).
var _built_counts: Dictionary = {}

## Base fraction of invested gold/material returned on sell (before global multiplier).
var sell_refund_fraction: float = DEFAULT_SELL_REFUND_FRACTION
## Applied by MissionEconomyData; multiplies `sell_refund_fraction` for refunds.
var sell_refund_global_multiplier: float = 1.0

var _passive_gold_accum: float = 0.0
var _passive_material_accum: float = 0.0

func _ready() -> void:
	if not SignalBus.enemy_killed.is_connected(_on_enemy_killed):
		SignalBus.enemy_killed.connect(_on_enemy_killed)
	if not SignalBus.wave_cleared.is_connected(_on_wave_cleared):
		SignalBus.wave_cleared.connect(_on_wave_cleared)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	# Passive accrual in _physics_process — gameplay logic rule (godot-conventions §14)
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
	var bid: String = building_data.building_id.strip_edges()
	if not bid.is_empty():
		return bid
	var id_str: String = building_data.id.strip_edges()
	if not id_str.is_empty():
		return id_str
	return "building_type:%d" % int(building_data.building_type)


## Clears duplicate placement counts (call at mission start or when re-applying mission economy).
func reset_for_mission() -> void:
	_built_counts.clear()


## Number of paid placements this mission for [param building_id] (same key as duplicate scaling).
func get_duplicate_count(building_id: String) -> int:
	var key: String = building_id.strip_edges()
	if key.is_empty():
		return 0
	return int(_built_counts.get(key, 0))


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
	return ceili(float(base) * mult)


## Effective material to place [param building_data].
func get_material_cost(building_data: BuildingData) -> int:
	if building_data == null:
		return 0
	var base: int = building_data.get_effective_cost_material()
	if not building_data.apply_duplicate_scaling:
		return base
	var mult: float = get_cost_multiplier(building_data)
	return ceili(float(base) * mult)


func _get_duplicate_cost_k() -> float:
	if _mission_economy is MissionEconomyData:
		var me: MissionEconomyData = _mission_economy as MissionEconomyData
		if me.duplicate_cost_k_override >= 0.0:
			return me.duplicate_cost_k_override
	return duplicate_cost_k


## True if current wallet covers scaled placement cost for [param building_data].
func can_afford_building(building_data: BuildingData) -> bool:
	if building_data == null:
		return false
	return gold >= get_gold_cost(building_data) and building_material >= get_material_cost(building_data)


## Charges scaled placement costs, increments duplicate counts, and returns a receipt. Empty dict on failure.
func register_purchase(building_data: BuildingData) -> Dictionary:
	if building_data == null:
		return {}
	var paid_gold: int = get_gold_cost(building_data)
	var paid_material: int = get_material_cost(building_data)
	if not spend_gold(paid_gold):
		return {}
	if not spend_building_material(paid_material):
		add_gold(paid_gold)
		return {}
	var key: String = _duplicate_key(building_data)
	var dup_after: int = 0
	if not key.is_empty():
		_built_counts[key] = int(_built_counts.get(key, 0)) + 1
		dup_after = int(_built_counts[key])
	return {
		"paid_gold": paid_gold,
		"paid_material": paid_material,
		"duplicate_count_after": dup_after,
	}


## Sell refund: `ceil(invested * sell_refund_fraction * sell_refund_global_multiplier)` per resource.
func get_refund(_building_data: BuildingData, paid_gold: int, paid_material: int) -> Dictionary:
	var frac: float = sell_refund_fraction * sell_refund_global_multiplier
	return {
		"gold": ceili(float(paid_gold) * frac),
		"material": ceili(float(paid_material) * frac),
	}


## Applies mission economy overrides and optional starting stock. Enables `_physics_process` passive income when rates &gt; 0.
## Clears per-mission duplicate placement counts whenever mission economy is (re)applied.
func apply_mission_economy(econ: MissionEconomyData = null) -> void:
	reset_for_mission()
	_mission_economy = econ
	_passive_gold_accum = 0.0
	_passive_material_accum = 0.0
	if econ == null:
		sell_refund_global_multiplier = 1.0
		set_physics_process(false)
		return
	sell_refund_global_multiplier = maxf(0.0, econ.sell_refund_global_multiplier)
	if econ.sell_refund_fraction >= 0.0:
		sell_refund_fraction = econ.sell_refund_fraction
	if econ.duplicate_cost_k_override >= 0.0:
		duplicate_cost_k = econ.duplicate_cost_k_override
	gold = econ.starting_gold
	building_material = econ.starting_material
	SignalBus.resource_changed.emit(Types.ResourceType.GOLD, gold)
	SignalBus.resource_changed.emit(Types.ResourceType.BUILDING_MATERIAL, building_material)
	set_physics_process(econ.passive_gold_per_sec > 0.0 or econ.passive_material_per_sec > 0.0)


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
	if econ != null and wave >= 1:
		gg += maxi(0, econ.passive_gold_per_wave)
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
	sell_refund_global_multiplier = 1.0
	sell_refund_fraction = DEFAULT_SELL_REFUND_FRACTION
	duplicate_cost_k = DEFAULT_DUPLICATE_COST_K
	reset_for_mission()
	_passive_gold_accum = 0.0
	_passive_material_accum = 0.0
	set_physics_process(false)

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

resources/shop_data/shop_catalog.tres:
[gd_resource type="Resource" format=3]

[ext_resource type="Script" path="res://scripts/resources/shop_item_data.gd" id="1_shopitemdata"]

[sub_resource type="Resource" id="ShopItem_tower_repair"]
script = ExtResource("1_shopitemdata")
item_id = "tower_repair"
display_name = "Tower Repair Kit"
gold_cost = 50
material_cost = 0
description = "Restore tower to full HP"

[sub_resource type="Resource" id="ShopItem_mana_draught"]
script = ExtResource("1_shopitemdata")
item_id = "mana_draught"
display_name = "Mana Draught"
gold_cost = 20
material_cost = 0
description = "Start next mission at full mana"
item_type = "consumable"
effect_tags = Array[String](["mana_restore"])
duration = 0.0
cooldown = 0.0
value = 0

[resource]


resources/strategyprofiles/strategy_balanced_default.tres:
[gd_resource type="Resource" script_class="StrategyProfile" format=3]

[ext_resource type="Script" path="res://scripts/resources/strategyprofile.gd" id="1_strategyprofile"]

[resource]
script = ExtResource("1_strategyprofile")

profile_id = "BALANCED_DEFAULT"
description = "Balanced profile: mix of all building types, moderate spell usage."

build_priorities = [
	{"building_type": 0, "weight": 1.0, "min_wave": 1, "max_wave": 10},
	{"building_type": 1, "weight": 0.9, "min_wave": 2, "max_wave": 10},
	{"building_type": 2, "weight": 0.9, "min_wave": 3, "max_wave": 10},
	{"building_type": 3, "weight": 0.8, "min_wave": 1, "max_wave": 10},
	{"building_type": 4, "weight": 0.7, "min_wave": 3, "max_wave": 10},
	{"building_type": 5, "weight": 0.6, "min_wave": 2, "max_wave": 10},
	{"building_type": 6, "weight": 0.6, "min_wave": 4, "max_wave": 10},
	{"building_type": 7, "weight": 0.5, "min_wave": 4, "max_wave": 10}
]

placement_preferences = {
	"preferred_slots": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "INNER_FIRST",
}

spell_usage = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 8,
	"min_mana": 50,
	"cooldown_safety_margin": 0.5,
	"evaluation_interval": 1.0,
	"priority_vs_building": 1.0,
}

upgrade_behavior = {
	"prefer_upgrades_until_build_count": 6,
	"upgrade_weight": 1.0,
	"min_gold_reserve": 50,
	"max_upgrade_level": 1,
}

difficulty_target = 0.0


resources/strategyprofiles/strategy_greedy_econ.tres:
[gd_resource type="Resource" script_class="StrategyProfile" format=3]

[ext_resource type="Script" path="res://scripts/resources/strategyprofile.gd" id="1_strategyprofile"]

[resource]
script = ExtResource("1_strategyprofile")

profile_id = "GREEDY_ECON"
description = "Greedy econ: prioritize cheap/early towers, fewer upgrades and spells."

build_priorities = [
	{"building_type": 0, "weight": 1.2, "min_wave": 1, "max_wave": 10},
	{"building_type": 3, "weight": 1.0, "min_wave": 2, "max_wave": 10},
	{"building_type": 5, "weight": 0.8, "min_wave": 2, "max_wave": 10},
	{"building_type": 1, "weight": 0.5, "min_wave": 3, "max_wave": 10},
	{"building_type": 2, "weight": 0.4, "min_wave": 4, "max_wave": 10},
	{"building_type": 4, "weight": 0.3, "min_wave": 4, "max_wave": 10},
	{"building_type": 6, "weight": 0.3, "min_wave": 4, "max_wave": 10},
	{"building_type": 7, "weight": 0.3, "min_wave": 4, "max_wave": 10}
]

placement_preferences = {
	"preferred_slots": [0, 1, 2, 3, 4, 5],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "INNER_FIRST",
}

spell_usage = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 10,
	"min_mana": 70,
	"cooldown_safety_margin": 1.0,
	"evaluation_interval": 1.5,
	"priority_vs_building": 0.5,
}

upgrade_behavior = {
	"prefer_upgrades_until_build_count": 10,
	"upgrade_weight": 0.7,
	"min_gold_reserve": 0,
	"max_upgrade_level": 1,
}

difficulty_target = 0.0


resources/strategyprofiles/strategy_heavy_fire.tres:
[gd_resource type="Resource" script_class="StrategyProfile" format=3]

[ext_resource type="Script" path="res://scripts/resources/strategyprofile.gd" id="1_strategyprofile"]

[resource]
script = ExtResource("1_strategyprofile")

profile_id = "HEAVY_FIRE"
description = "Heavy fire: prioritize FireBrazier/Ballista/MagicObelisk, aggressive Shockwave."

build_priorities = [
	{"building_type": 0, "weight": 0.7, "min_wave": 1, "max_wave": 10},
	{"building_type": 1, "weight": 1.2, "min_wave": 2, "max_wave": 10},
	{"building_type": 2, "weight": 1.1, "min_wave": 3, "max_wave": 10},
	{"building_type": 4, "weight": 1.0, "min_wave": 3, "max_wave": 10},
	{"building_type": 3, "weight": 0.5, "min_wave": 2, "max_wave": 10},
	{"building_type": 5, "weight": 0.4, "min_wave": 2, "max_wave": 10},
	{"building_type": 6, "weight": 0.7, "min_wave": 4, "max_wave": 10},
	{"building_type": 7, "weight": 0.3, "min_wave": 4, "max_wave": 10}
]

placement_preferences = {
	"preferred_slots": [6, 7, 8, 9, 10, 11, 12, 13],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "OUTER_FIRST",
}

spell_usage = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 6,
	"min_mana": 40,
	"cooldown_safety_margin": 0.25,
	"evaluation_interval": 0.75,
	"priority_vs_building": 1.2,
}

upgrade_behavior = {
	"prefer_upgrades_until_build_count": 4,
	"upgrade_weight": 1.3,
	"min_gold_reserve": 50,
	"max_upgrade_level": 1,
}

difficulty_target = 0.0


scripts/resources/strategyprofile.gd:
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


