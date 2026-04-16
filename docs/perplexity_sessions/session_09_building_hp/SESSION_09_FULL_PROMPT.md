PROMPT:

# Session 9: Building HP & Destruction System

## Goal
Design the building HP and destruction system. Currently buildings are indestructible. The building_destroyed signal exists on SignalBus but is never emitted. This session adds building HP, damage reception, destruction effects, and signal activation.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `building_base.gd` — BuildingBase scene script; initialization, combat, key methods (lines 1-80)
- `building_data.gd` — BuildingData resource class; all exported fields (lines 1-60)
- `health_component.gd` — HealthComponent script; HP management, damage, heal, signals
- `signal_bus.gd` — SignalBus; lines 100-110 covering building signals
- `hex_grid.gd` — HexGrid script; lines 1-50 covering slot data structure

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
Produce an implementation spec for: building HP, destruction, enemy targeting of buildings, and HP bar UI.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

REQUIREMENTS:
1. Add BuildingData fields: max_hp (int, default 0 — 0 means indestructible for backward compat), can_be_targeted_by_enemies (bool, default false).
2. Add a HealthComponent child to BuildingBase when max_hp > 0. Initialize with max_hp from BuildingData.
3. When HealthComponent.health_depleted fires on a building:
   - Emit SignalBus.building_destroyed(slot_index)
   - If summoner: AllyManager.despawn_squad(instance_id)
   - If aura: AuraManager.deregister_aura(instance_id)
   - Play a destruction visual (placeholder: scale to 0 over 0.5s, then queue_free)
   - HexGrid clears the slot
4. Which enemies attack buildings: only enemies with a new EnemyData field prefer_building_targets (bool, default false). When true AND a building with can_be_targeted_by_enemies is in range, the enemy attacks the building instead of pathing to the tower.
5. Set max_hp > 0 on MEDIUM and LARGE buildings only. SMALL buildings remain indestructible. Suggested values: MEDIUM = 200-400 HP, LARGE = 500-800 HP.
6. Repair mechanic: the existing tower_repair shop item repairs the tower. Add building_repair shop item behavior: restores 50% HP to the lowest-HP building.
7. Building HP bar: show a small HP bar above buildings with HP. Use the same visual pattern as enemy HP bars.
8. Save: building HP should persist within a mission but resets between missions (buildings are fresh each day).

Note: Batch 5 extracted hex_grid.gd's _try_place_building into _validate_placement() + _instantiate_and_place(). The destruction system interacts with slot clearing, not placement.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 9: Building HP

## Buildings (§8)

STATUS: EXISTS IN CODE

36 BuildingData .tres files under res://resources/building_data/.

Key field names (use exact names):
- gold_cost (not build_gold_cost), target_priority, damage_type, building_id

### BuildingSizeClass Enum
| Name | Value |
|------|-------|
| SINGLE_SLOT | 0 |
| DOUBLE_WIDE | 1 |
| TRIPLE_CLUSTER | 2 |
| SMALL | 3 |
| MEDIUM | 4 |
| LARGE | 5 |

### Ring Rotation
EXISTS: rotate_ring() in BuildPhaseManager / HexGrid.

## Signal Bus — Building Signals (§24)

| Signal | Parameters |
|--------|-----------|
| building_placed | slot_index: int, building_type: Types.BuildingType |
| building_sold | slot_index: int, building_type: Types.BuildingType |
| building_upgraded | slot_index: int, building_type: Types.BuildingType |
| building_destroyed | slot_index: int |

Note: building_destroyed is declared but never emitted (POST-MVP stub). This session activates it.

## Building Placement Flow (§27.2)

1. Player enters BUILD_MODE (B key or Tab)
2. Player clicks a HexGrid slot -> InputManager raycasts
3. Player selects building -> BuildMenu checks EconomyManager.can_afford_building
4. HexGrid.place_building(slot_index, building_type):
   - BuildPhaseManager.assert_build_phase("place_building")
   - EconomyManager.register_purchase(building_data)
   - building.initialize_with_economy(building_data, paid_gold, paid_material)
   - If building_data.is_aura: AuraManager.register_aura(building)
   - If building_data.is_summoner: AllyManager.spawn_squad(building)
   - SignalBus.building_placed.emit(slot_index, building_type)
5. Selling:
   - If summoner: AllyManager.despawn_squad(instance_id)
   - If aura: AuraManager.deregister_aura(instance_id)
   - building.queue_free()
   - SignalBus.building_sold.emit(slot_index, building_type)

Note: Batch 5 extracted _try_place_building into _validate_placement() + _instantiate_and_place().

## HealthComponent Pattern

HealthComponent is used by Tower and EnemyBase. Key signals:
- health_changed(current_hp: int, max_hp: int)
- health_depleted()

Methods: take_damage(amount: int), heal(amount: int), reset_to_max().

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- is_instance_valid() before accessing enemies, projectiles, or allies (freed mid-frame)
- push_warning() not assert() in production
- _physics_process for game logic — _process for visual/UI only

FILES:

# Files to Upload for Session 9: Building HP

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_09_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scenes/buildings/building_base.gd` — BuildingBase scene script; lines 1-80 covering initialization, combat, and key methods (~80 lines)
2. `scripts/resources/building_data.gd` — BuildingData resource class; lines 1-60 covering exported fields (~60 lines)
3. `scripts/health_component.gd` — HealthComponent; full file (~55 lines)
4. `autoloads/signal_bus.gd` — SignalBus; lines 100-110 covering building signals (~10 lines)
5. `scenes/hex_grid/hex_grid.gd` — HexGrid; lines 1-50 covering slot data structure (~50 lines)

Total estimated token load: ~255 lines across 5 files

scenes/buildings/building_base.gd:
## BuildingBase — Base class for all building types; handles targeting, combat, projectile firing, and DoT effects.
# scenes/buildings/building_base.gd
# BuildingBase – base class for all tower-defense building types.
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

# Assign placeholder art resources via convention-based pipeline (global class_name ArtPlaceholderHelper).

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _building_data: BuildingData = null
## Gold/material actually charged for initial placement (audit / UI).
var paid_gold: int = 0
var paid_material: int = 0
## Placement + upgrade spends (sell refund basis before `sell_refund_fraction`).
var total_invested_gold: int = 0
var total_invested_material: int = 0
var _is_upgraded: bool = false
var _attack_timer: float = 0.0
var _current_target: EnemyBase = null
var _special_timer: float = 0.0
## Hex slot index (CombatStatsTracker / saves).
var slot_id: int = -1
## Ring tier 0..2 for analytics (set by HexGrid on placement).
var ring_index: int = -1
## Stable string id for this placed instance (set by [method initialize_with_economy]).
var placed_instance_id: String = ""
## Set by HexGrid on placement for CombatStatsTracker attribution (alias of [member slot_id]).
var _slot_index_for_stats: int = -1

## Runtime stat layer (Prompt 49): base from data, final after auras/status.
var base_stats: Dictionary = {}
var final_stats: Dictionary = {}
## Stat-layer DoTs/CC (distinct from projectile DoT on enemies).
var active_status_effects: Array[Dictionary] = []
var incoming_auras: Array[Dictionary] = []
var resolved_auras: Dictionary = {}

## Summoned units owned by this building (cleared on upgrade / free).
var active_summons: Array[Node] = []

## Summoner tower: respawn after squad wipe ([member BuildingData.summon_respawn_type]).
var _respawn_timer: Timer = null
var _respawn_type: String = ""

var _heal_timer: Timer = null

## Saboteur / disable: when true, tower does not acquire targets or fire.
var _disabled: bool = false
var _disable_timer: Timer = null

# Summon node expected fields (author later):
# var owner_building: Node
# var owner_building_id: String
# var owner_instance_id: String
# var summon_slot_index: int
# var home_position: Vector3

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


func set_slot_index_for_stats(slot_index: int) -> void:
	slot_id = slot_index
	_slot_index_for_stats = slot_index


func set_disabled(state: bool, duration: float = 0.0) -> void:
	_disabled = state
	if state and duration > 0.0:
		if _disable_timer != null and is_instance_valid(_disable_timer):
			_disable_timer.queue_free()
		_disable_timer = Timer.new()
		_disable_timer.wait_time = duration
		_disable_timer.one_shot = true
		add_child(_disable_timer)
		_disable_timer.timeout.connect(
			func() -> void:
				set_disabled(false)
		)
		_disable_timer.start()
	elif not state and _disable_timer != null and is_instance_valid(_disable_timer):
		_disable_timer.queue_free()
		_disable_timer = null

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
	_tick_status_effects(delta)
	_combat_process(delta)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Call after the node is in the scene tree (add_child) so child paths resolve.
## Configures visuals and stats from the provided BuildingData resource.
func initialize(data: BuildingData) -> void:
	_building_data = data
	paid_gold = 0
	paid_material = 0
	total_invested_gold = 0
	total_invested_material = 0
	_is_upgraded = false
	_attack_timer = 0.0
	_current_target = null
	_special_timer = data.special_pulse_interval * 0.25
	placed_instance_id = ""

	_apply_visuals_from_building_data(data)
	_apply_data_stats()

	print("[Building] initialized: %s  dmg=%.0f range=%.1f fire_rate=%.2f  air=%s gnd=%s" % [
		data.display_name, data.damage, data.attack_range, data.fire_rate,
		data.targets_air, data.targets_ground
	])


## Call after [method initialize] when the building is placed on the grid (sets slot, ring, instance id).
func initialize_with_economy(building_data: BuildingData, s_id: int, r_index: int) -> void:
	initialize(building_data)
	slot_id = s_id
	_slot_index_for_stats = s_id
	ring_index = r_index
	var bid: String = building_data.building_id.strip_edges()
	if bid.is_empty():
		bid = "building_type_%d" % int(building_data.building_type)
	placed_instance_id = "%s_%d_%d" % [bid, s_id, Time.get_ticks_msec()]
	_setup_aura_and_healer_runtime()
	_init_summoner()


func _exit_tree() -> void:
	_cleanup_summoner()


func _init_summoner() -> void:
	if _building_data == null or not _building_data.is_summoner:
		return
	_respawn_type = _building_data.summon_respawn_type.strip_edges()
	AllyManager.spawn_squad(self)
	if _respawn_type == "mortal" or _respawn_type == "recurring":
		if not SignalBus.ally_squad_wiped.is_connected(_on_squad_wiped):
			SignalBus.ally_squad_wiped.connect(_on_squad_wiped)


func _cleanup_summoner() -> void:
	if _building_data == null or not _building_data.is_summoner:
		return
	_cancel_respawn_timer()
	if SignalBus.ally_squad_wiped.is_connected(_on_squad_wiped):
		SignalBus.ally_squad_wiped.disconnect(_on_squad_wiped)
	AllyManager.despawn_squad(placed_instance_id)


func _on_squad_wiped(bid: String) -> void:
	if bid != placed_instance_id:
		return
	match _respawn_type:
		"mortal", "recurring":
			_start_respawn_once()
		"immortal":
			push_warning("Immortal squad wiped for building %s" % placed_instance_id)
		_:
			pass


func _start_respawn_once() -> void:
	if _building_data == null:
		return
	if _respawn_timer != null and is_instance_valid(_respawn_timer) and _respawn_timer.is_inside_tree():
		return
	_respawn_timer = Timer.new()
	_respawn_timer.wait_time = maxf(0.05, _building_data.summon_respawn_delay)
	_respawn_timer.one_shot = true
	add_child(_respawn_timer)
	_respawn_timer.timeout.connect(_do_respawn)
	_respawn_timer.start()


func _do_respawn() -> void:
	if _respawn_type == "mortal":
		if SignalBus.ally_squad_wiped.is_connected(_on_squad_wiped):
			SignalBus.ally_squad_wiped.disconnect(_on_squad_wiped)
		_respawn_type = "done"
	if _building_data != null and _building_data.is_summoner:
		AllyManager.spawn_squad(self)
	_cancel_respawn_timer()


func _cancel_respawn_timer() -> void:
	if _respawn_timer != null and is_instance_valid(_respawn_timer):
		_respawn_timer.queue_free()
	_respawn_timer = null


func _setup_aura_and_healer_runtime() -> void:
	if _building_data == null:
		return
	if _building_data.is_aura:
		AuraManager.register_aura(self)
	if _building_data.is_healer:
		_init_healer()


func _apply_data_stats() -> void:
	if _building_data == null:
		return
	_apply_visuals_from_building_data(_building_data)
	_attack_timer = 0.0
	_current_target = null
	_special_timer = _building_data.special_pulse_interval * 0.25
	_rebuild_base_stats()
	recompute_all_stats()


func _rebuild_base_stats() -> void:
	if _building_data == null:
		return
	base_stats = {
		"damage": _intrinsic_damage_scalar(),
		"fire_rate": float(_building_data.fire_rate),
		"range": _intrinsic_range_scalar(),
	}


func _intrinsic_damage_scalar() -> float:
	if _building_data == null:
		return 0.0
	if _building_data.upgrade_next != null or _building_data.upgrade_level > 0:
		if _has_research_damage_boost():
			return _building_data.upgraded_damage
		return _building_data.damage
	if _is_upgraded:
		return _building_data.upgraded_damage
	if _has_research_damage_boost():
		return _building_data.upgraded_damage
	return _building_data.damage


func _intrinsic_range_scalar() -> float:
	if _building_data == null:
		return 0.0
	if _building_data.upgrade_next != null or _building_data.upgrade_level > 0:
		if _has_research_range_boost():
			return _building_data.upgraded_range
		return _building_data.attack_range
	if _is_upgraded:
		return _building_data.upgraded_range
	if _has_research_range_boost():
		return _building_data.upgraded_range
	return _building_data.attack_range


func _apply_visuals_from_building_data(data: BuildingData) -> void:
	# MVP visual: colored cube + label (use get_node — @onready is not set before _ready()).
	var mesh_inst: MeshInstance3D = get_node_or_null("BuildingMesh") as MeshInstance3D
	if mesh_inst != null:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = data.color
		mesh_inst.material_override = mat

	if mesh_inst != null:
		var _art_mesh: Mesh = ArtPlaceholderHelper.get_building_mesh(data.building_type)
		if _art_mesh != null:
			mesh_inst.mesh = _art_mesh
		var _art_mat: Material = ArtPlaceholderHelper.get_building_material(data.building_type)
		if _art_mat != null:
			mesh_inst.material_override = _art_mat

	if _should_use_building_kit_visual(data):
		var existing_kit: Node = get_node_or_null("BuildingKitAssembly")
		if is_instance_valid(existing_kit):
			remove_child(existing_kit)
			existing_kit.free()
		var kit_visual: Node3D = ArtPlaceholderHelper.get_building_kit_mesh(
				data.base_mesh_id,
				data.top_mesh_id,
				data.accent_color
		) as Node3D
		kit_visual.name = "BuildingKitAssembly"
		kit_visual.position = Vector3.ZERO
		add_child(kit_visual)
		if mesh_inst != null:
			mesh_inst.visible = false

	var label_inst: Label3D = get_node_or_null("BuildingLabel") as Label3D
	if label_inst != null:
		label_inst.text = data.display_name


## Transitions the building from Basic to Upgraded tier (legacy two-tier rows without [member BuildingData.upgrade_next]).
func upgrade() -> void:
	_is_upgraded = true


## Data-driven upgrade chain: true when a next tier exists or legacy upgrade is available.
func can_upgrade() -> bool:
	if _building_data == null:
		return false
	if _building_data.upgrade_next != null:
		return true
	return not _is_upgraded and _legacy_upgrade_costs_exist()


func _legacy_upgrade_costs_exist() -> bool:
	return _building_data.get_effective_upgrade_cost_gold() > 0 \
			or _building_data.get_effective_upgrade_cost_material() > 0


## Switches stats to [param next_data] without respawning the node (upgrade chain). Adds [method get_upgrade_cost] to invested totals; caller must charge EconomyManager first.
func apply_upgrade(next_data: BuildingData) -> void:
	if next_data == null:
		push_warning("BuildingBase.apply_upgrade: next_data is null")
		return
	_despawn_all_summons()
	var cost: Dictionary = get_upgrade_cost()
	total_invested_gold += int(cost.get("gold", 0))
	total_invested_material += int(cost.get("material", 0))
	_building_data = next_data
	_is_upgraded = true
	_apply_data_stats()


## Records actual placement spend (call once after EconomyManager charges).
func record_initial_purchase(placement_gold: int, placement_material: int) -> void:
	paid_gold = placement_gold
	paid_material = placement_material
	total_invested_gold = placement_gold
	total_invested_material = placement_material


## Adds upgrade tier spend to invested totals (call after successful payment).
func record_upgrade_cost(upgrade_gold: int, upgrade_material: int) -> void:
	total_invested_gold += upgrade_gold
	total_invested_material += upgrade_material


## Refund preview using [method EconomyManager.get_refund] (mission sell fraction × global multiplier).
func get_sell_refund() -> Dictionary:
	if _building_data == null:
		return {"gold": 0, "material": 0}
	return EconomyManager.get_refund(_building_data, total_invested_gold, total_invested_material)


## Effective upgrade costs: chain uses [member BuildingData.upgrade_next_*] when [member BuildingData.upgrade_next] is set.
func get_upgrade_cost() -> Dictionary:
	if _building_data == null:
		return {"gold": 0, "material": 0}
	if _building_data.upgrade_next != null:
		var g: int = _building_data.upgrade_next_gold_cost
		var m: int = _building_data.upgrade_next_material_cost
		if g <= 0 and m <= 0:
			g = _building_data.get_effective_upgrade_cost_gold()
			m = _building_data.get_effective_upgrade_cost_material()
		return {"gold": g, "material": m}
	return {
		"gold": _building_data.get_effective_upgrade_cost_gold(),
		"material": _building_data.get_effective_upgrade_cost_material()
	}


## Returns the BuildingData resource this building was initialized with.
func get_building_data() -> BuildingData:
	return _building_data


func recompute_all_stats() -> void:
	final_stats = base_stats.duplicate()
	_resolve_auras()
	for e: Dictionary in active_status_effects:
		if str(e.get("stack_key", "")) == "":
			continue
		var stat: String = str(e.get("stat", ""))
		if stat.is_empty():
			continue
		_apply_modifier(final_stats, stat, str(e.get("modifier_type", "MULTIPLY")), float(e.get("modifier_value", 1.0)))
	var aura_damage_bonus: float = AuraManager.get_damage_pct_bonus(self)
	if final_stats.has("damage"):
		final_stats["damage"] = float(final_stats["damage"]) * (1.0 + aura_damage_bonus)
	var fr: float = float(final_stats.get("fire_rate", 1.0))
	final_stats["fire_rate"] = maxf(fr, 0.1)
	var rng: float = float(final_stats.get("range", 0.0))
	final_stats["range"] = maxf(rng, 0.5)
	_push_final_stats()


func _push_final_stats() -> void:
	if _building_data == null:
		return
	# Attack cadence uses effective fire rate from final_stats.
	var fr: float = float(final_stats.get("fire_rate", _building_data.fire_rate))
	if fr > 0.0 and _attack_timer > 1.0 / fr:
		_attack_timer = 1.0 / fr


func _resolve_auras() -> void:
	resolved_auras.clear()
	for a: Dictionary in incoming_auras:
		var cat: String = str(a.get("aura_category", "default"))
		var cur: Dictionary = resolved_auras.get(cat, {}) as Dictionary
		if cur.is_empty() or _aura_strength(a) > _aura_strength(cur):
			resolved_auras[cat] = a
	for _k: Variant in resolved_auras.keys():
		var aura: Dictionary = resolved_auras[_k] as Dictionary
		var st: String = str(aura.get("aura_stat", ""))
		if st.is_empty():
			continue
		_apply_modifier(final_stats, st, str(aura.get("modifier_type", "MULTIPLY")), float(aura.get("modifier_value", 1.0)))


func _aura_strength(aura: Dictionary) -> float:
	var mt: String = str(aura.get("modifier_type", "MULTIPLY"))
	var mv: float = float(aura.get("modifier_value", 1.0))
	match mt:
		"MULTIPLY":
			return absf(mv - 1.0)
		"ADD":
			return absf(mv)
		"OVERRIDE":
			return absf(mv)
		_:
			return absf(mv)


func _apply_modifier(stats: Dictionary, stat: String, mod_type: String, value: float) -> void:
	var cur: float = float(stats.get(stat, 0.0))
	match mod_type:
		"MULTIPLY":
			stats[stat] = cur * value
		"ADD":
			stats[stat] = cur + value
		"OVERRIDE":
			stats[stat] = value
		_:
			stats[stat] = cur * value


func add_status_effect(effect: Dictionary) -> void:
	var stack_key: String = str(effect.get("stack_key", ""))
	var mode: String = str(effect.get("stack_mode", "NONE"))
	var idx: int = _find_effect_index(stack_key)
	match mode:
		"NONE":
			if idx >= 0:
				return
			active_status_effects.append(effect.duplicate())
		"REFRESH":
			if idx >= 0:
				var old: Dictionary = active_status_effects[idx]
				old["duration_remaining"] = float(effect.get("duration_remaining", 0.0))
				active_status_effects[idx] = old
			else:
				active_status_effects.append(effect.duplicate())
		"REPLACE_STRONGEST":
			if idx >= 0:
				var old2: Dictionary = active_status_effects[idx]
				if float(effect.get("modifier_value", 0.0)) > float(old2.get("modifier_value", 0.0)):
					active_status_effects[idx] = effect.duplicate()
			else:
				active_status_effects.append(effect.duplicate())
		"STACK_DURATION":
			if idx >= 0:
				var old3: Dictionary = active_status_effects[idx]
				old3["duration_remaining"] = float(old3.get("duration_remaining", 0.0)) + float(effect.get("duration_remaining", 0.0))
				active_status_effects[idx] = old3
			else:
				active_status_effects.append(effect.duplicate())
		_:
			active_status_effects.append(effect.duplicate())
	recompute_all_stats()


func _tick_status_effects(delta: float) -> void:
	if active_status_effects.is_empty():
		return
	var i: int = 0
	var changed: bool = false
	while i < active_status_effects.size():
		var e: Dictionary = active_status_effects[i]
		if str(e.get("stack_key", "")) == "":
			i += 1
			continue
		var rem: float = float(e.get("duration_remaining", 0.0)) - delta
		e["duration_remaining"] = rem
		if rem <= 0.0:
			active_status_effects.remove_at(i)
			changed = true
		else:
			active_status_effects[i] = e
			i += 1
	if changed:
		recompute_all_stats()


func _find_effect_index(stack_key: String) -> int:
	if stack_key.is_empty():
		return -1
	for j: int in range(active_status_effects.size()):
		var e2: Dictionary = active_status_effects[j]
		if str(e2.get("stack_key", "")) == stack_key:
			return j
	return -1


func _despawn_all_summons() -> void:
	for s: Node in active_summons:
		if is_instance_valid(s):
			s.queue_free()
	active_summons.clear()


func receive_heal(amount: float) -> void:
	if amount <= 0.0:
		return
	if health_component == null:
		return
	health_component.heal(maxi(1, int(round(amount))))


func _init_healer() -> void:
	if _building_data == null:
		return
	if _heal_timer != null:
		return
	_heal_timer = Timer.new()
	_heal_timer.wait_time = maxf(0.05, _building_data.heal_tick_interval)
	_heal_timer.one_shot = false
	add_child(_heal_timer)
	_heal_timer.timeout.connect(_do_heal_tick)
	_heal_timer.start()


func _stop_healer_timer() -> void:
	if _heal_timer != null and is_instance_valid(_heal_timer):
		_heal_timer.stop()
		_heal_timer.queue_free()
	_heal_timer = null


func _do_heal_tick() -> void:
	var bd: BuildingData = _building_data
	if bd == null:
		return
	match bd.heal_targets:
		"allies":
			_heal_allies_in_radius(bd.heal_radius, bd.heal_per_tick)
		"buildings":
			_heal_buildings_in_radius(bd.heal_radius, bd.heal_per_tick)
		"both":
			_heal_allies_in_radius(bd.heal_radius, bd.heal_per_tick)
			_heal_buildings_in_radius(bd.heal_radius, bd.heal_per_tick)
		_:
			_heal_allies_in_radius(bd.heal_radius, bd.heal_per_tick)


func _heal_allies_in_radius(radius: float, amount: float) -> void:
	var root: SceneTree = get_tree()
	if root == null:
		return
	for n: Node in root.get_nodes_in_group("allies"):
		if not is_instance_valid(n):
			continue
		var node3: Node3D = n as Node3D
		if node3 == null:
			continue
		if global_position.distance_to(node3.global_position) > radius:
			continue
		if n.has_method("receive_heal"):
			n.call("receive_heal", amount)


func _heal_buildings_in_radius(radius: float, amount: float) -> void:
	for b: BuildingBase in _get_all_buildings_in_range(radius):
		if b == self:
			continue
		if b.has_method("receive_heal"):
			b.receive_heal(amount)


func _get_all_buildings_in_range(radius: float) -> Array[BuildingBase]:
	var out: Array[BuildingBase] = []
	var root: SceneTree = get_tree()
	if root == null:
		return out
	for n: Node in root.get_nodes_in_group("buildings"):
		var b: BuildingBase = n as BuildingBase
		if b == null or not is_instance_valid(b):
			continue
		if global_position.distance_to(b.global_position) <= radius:
			out.append(b)
	return out


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if not placed_instance_id.is_empty():
			AuraManager.deregister_aura(placed_instance_id)
		_stop_healer_timer()
		_despawn_all_summons()


## Returns the currently effective damage value (base or upgraded).
func get_effective_damage() -> float:
	if not final_stats.is_empty() and final_stats.has("damage"):
		return float(final_stats["damage"])
	if _building_data == null:
		return 0.0
	# Upgrade chain: each tier row uses [member BuildingData.damage] as its shot damage.
	if _building_data.upgrade_next != null or _building_data.upgrade_level > 0:
		if _has_research_damage_boost():
			return _building_data.upgraded_damage
		return _building_data.damage
	if _is_upgraded:
		return _building_data.upgraded_damage
	if _has_research_damage_boost():
		return _building_data.upgraded_damage
	return _building_data.damage


## Returns the currently effective attack range (base or upgraded).
func get_effective_range() -> float:
	if not final_stats.is_empty() and final_stats.has("range"):
		return float(final_stats["range"])
	if _building_data == null:
		return 0.0
	if _building_data.upgrade_next != null or _building_data.upgrade_level > 0:
		if _has_research_range_boost():
			return _building_data.upgraded_range
		return _building_data.attack_range
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


func _should_use_building_kit_visual(data: BuildingData) -> bool:
	# Default enum pair keeps the single-mesh placeholder pipeline (existing .tres files unchanged).
	return not (
			data.base_mesh_id == Types.BuildingBaseMesh.STONE_ROUND
			and data.top_mesh_id == Types.BuildingTopMesh.ROOF_CONE
	)

# ---------------------------------------------------------------------------
# Private – combat loop
# ---------------------------------------------------------------------------

func _combat_process(delta: float) -> void:
	if _building_data == null:
		return
	if _disabled:
		return

	if _building_data.building_type == Types.BuildingType.ARCHER_BARRACKS:
		_tick_archer_barracks(delta)
		return
	if _building_data.building_type == Types.BuildingType.SHIELD_GENERATOR:
		_tick_shield_generator(delta)
		return

	# Legacy stub guard for any other zero fire_rate types.
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
		var fr_eff: float = _building_data.fire_rate
		if not final_stats.is_empty() and final_stats.has("fire_rate"):
			fr_eff = float(final_stats["fire_rate"])
		_attack_timer = 1.0 / maxf(fr_eff, 0.1)


## Finds the best valid target within range.
## MVP strategy: CLOSEST enemy to this building.
## Respects [member BuildingData.targets_air] / [member BuildingData.targets_ground] via [method EnemyData.matches_tower_air_ground_filter].
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
		if enemy_data == null:
			continue

		# Filter by air/ground targeting (align with EnemyData.get_target_flag_bits, not is_flying alone).
		if not enemy_data.matches_tower_air_ground_filter(_building_data.targets_air, _building_data.targets_ground):
			continue

		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > effective_range:
			continue

		if distance < best_distance:
			best_distance = distance
			best_target = enemy

	return best_target


## Returns the preloaded default [member ProjectileScene] only if it can be instantiated (empty/corrupt scenes fail here).
func _get_validated_default_projectile_packed_scene() -> PackedScene:
	if ProjectileScene == null:
		push_error("BuildingBase: default ProjectileScene preload is null (projectile_base.tscn missing or unloadable).")
		return null
	if not ProjectileScene.can_instantiate():
		push_error(
				"BuildingBase: default ProjectileScene cannot be instantiated — check res://scenes/projectiles/projectile_base.tscn"
		)
		return null
	return ProjectileScene


## Resolves projectile scene: optional [member BuildingData.projectile_scene] override, else default [member ProjectileScene].
func _resolve_projectile_packed_scene() -> PackedScene:
	if _building_data == null:
		push_warning("BuildingBase._resolve_projectile_packed_scene: no building data")
		return null
	var override_ps: PackedScene = _building_data.projectile_scene
	if override_ps != null:
		if override_ps.can_instantiate():
			return override_ps
		push_warning(
				"BuildingBase: projectile_scene PackedScene cannot instantiate (building '%s'). Using default projectile."
				% _building_data.display_name
		)
		return _get_validated_default_projectile_packed_scene()
	return _get_validated_default_projectile_packed_scene()


## Instantiates and launches a projectile toward the current target.
func _fire_at_target() -> void:
	if not is_instance_valid(_current_target):
		return
	if _building_data == null:
		return
	if _projectile_container == null:
		push_warning("BuildingBase._fire_at_target: ProjectileContainer missing — skipping shot.")
		return

	var packed: PackedScene = _resolve_projectile_packed_scene()
	if packed == null:
		push_error(
				"BuildingBase._fire_at_target: no valid PackedScene for '%s' (check projectile_scene path and projectile_base.tscn)."
				% _building_data.display_name
		)
		return
	if not packed.can_instantiate():
		push_error(
				"BuildingBase._fire_at_target: resolved PackedScene not instantiable (building '%s')."
				% _building_data.display_name
		)
		return

	var inst: Node = packed.instantiate()
	if inst == null:
		push_error(
				"BuildingBase._fire_at_target: instantiate() returned null (building '%s')."
				% _building_data.display_name
		)
		return

	var proj: ProjectileBase = inst as ProjectileBase
	if proj == null:
		push_error(
				"BuildingBase._fire_at_target: projectile root is not ProjectileBase (building '%s')."
				% _building_data.display_name
		)
		inst.queue_free()
		return

	if not proj.has_method("initialize_from_building"):
		push_error(
				"BuildingBase._fire_at_target: projectile missing initialize_from_building() (building '%s')."
				% _building_data.display_name
		)
		proj.queue_free()
		return

	# Speed proxy: fire_rate * 15.0 gives reasonable projectile speed spread.
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
		_building_data.dot_in_addition_to_hit,
		placed_instance_id,
		slot_id
	)
	proj.add_to_group("projectiles")


func _tick_archer_barracks(delta: float) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	_special_timer -= delta
	if _special_timer > 0.0:
		return
	_special_timer = _building_data.special_pulse_interval
	var r2: float = _building_data.barracks_buff_radius * _building_data.barracks_buff_radius
	var bonus: float = _building_data.barracks_ally_damage_bonus
	for node: Node in tree.get_nodes_in_group("allies"):
		var ally: AllyBase = node as AllyBase
		if ally == null or not is_instance_valid(ally):
			continue
		if ally.health_component == null or not ally.health_component.is_alive():
			continue
		if global_position.distance_squared_to(ally.global_position) > r2:
			continue
		ally.add_barracks_strike_bonus(bonus)


func _tick_shield_generator(delta: float) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	_special_timer -= delta
	if _special_timer > 0.0:
		return
	_special_timer = _building_data.special_pulse_interval
	var tower: Tower = tree.get_first_node_in_group("tower") as Tower
	if tower == null:
		return
	tower.add_spell_shield(_building_data.shield_hp_per_pulse, _building_data.shield_pulse_duration)

scripts/resources/building_data.gd:
## building_data.gd
## Data resource describing stats for a single building type in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name BuildingData
extends Resource

## Which building type this resource describes.
@export var building_type: Types.BuildingType
## Unique stable ID for duplicate-cost tracking (e.g. [code]arrow_tower[/code]). Preferred over [member id] when both set.
@export var building_id: String = ""
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
## Attack range in world units (external specs use the word "range"; the GDScript keyword `range` cannot be a member name).
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

## Archer Barracks / Shield Generator: seconds between special pulses.
@export var special_pulse_interval: float = 10.0
## Radius for barracks ally buff (world units).
@export var barracks_buff_radius: float = 22.0
## Flat damage added to the next ally strike while in radius (applied on pulse).
@export var barracks_ally_damage_bonus: float = 8.0
## Shield pulse: temporary absorb HP granted to the central tower.
@export var shield_hp_per_pulse: float = 28.0
## Duration for shield HP pool from generator (seconds).
@export var shield_pulse_duration: float = 8.0

## Modular kit: base GLB id (`res://art/generated/kit/<name>.glb`).
@export var base_mesh_id: Types.BuildingBaseMesh = Types.BuildingBaseMesh.STONE_ROUND
## Modular kit: top GLB id (`res://art/generated/kit/<name>.glb`).
@export var top_mesh_id: Types.BuildingTopMesh = Types.BuildingTopMesh.ROOF_CONE
## Faction accent applied to the top kit mesh surface 0 (see ArtPlaceholderHelper.get_building_kit_mesh).
@export var accent_color: Color = Color(0.7, 0.3, 0.1)

# ---------------------------------------------------------------------------
# Data-driven tower defense foundation (Prompt 34) — identity & presentation
# ---------------------------------------------------------------------------

## Stable string id for JSON / saves (optional; legacy content may leave empty).
@export var id: String = ""
## Longer description for tooltips / codex.
@export var description: String = ""
## `res://` path to icon texture (optional).
@export var icon: String = ""
## Optional PackedScene path for bespoke building root (empty = default BuildingBase).
@export var scene_path: String = ""

# ---------------------------------------------------------------------------
# Layout (future hex / multi-slot placement)
# ---------------------------------------------------------------------------

## Hex footprint / layout tier (SINGLE_SLOT, ring SMALL/MEDIUM/LARGE, etc.).
@export var footprint_size_class: Types.BuildingSizeClass = Types.BuildingSizeClass.SINGLE_SLOT
## Preferred ring for auto-layout presets (-1 = any ring).
@export var ring_index: int = -1

# ---------------------------------------------------------------------------
# Economy — canonical `cost_*` with legacy fallback (`gold_cost` / `material_cost`)
# ---------------------------------------------------------------------------

## When >= 0, overrides `gold_cost` for new pipelines. -1 = use `gold_cost`.
@export var cost_gold: int = -1
## When >= 0, overrides `material_cost`. -1 = use `material_cost`.
@export var cost_material: int = -1
## Fraction of placement + upgrade costs refunded on sell (1.0 = full refund; matches legacy behaviour).
@export var sell_refund_fraction: float = 1.0
## When true, duplicate placements apply global duplicate scaling from mission economy.
@export var apply_duplicate_scaling: bool = true

# ---------------------------------------------------------------------------
# Combat — extended fields (legacy `attack_range` / DoT block remains authoritative for MVP)
# ---------------------------------------------------------------------------

@export_flags("ground", "air", "boss", "structure", "summoned") var target_flags: int = 0
## Optional projectile scene override (null = use BuildingBase default projectile).
@export var projectile_scene: PackedScene = null
## Splash radius in world units (0 = single-target impact only).
@export var splash_radius: float = 0.0
## DoT DPS; ticks may still use `dot_tick_interval` / `dot_duration` from legacy fields.
@export var dot_damage_per_second: float = 0.0

# ---------------------------------------------------------------------------
# Summoner / spawner buildings
# ---------------------------------------------------------------------------

@export var is_summoner: bool = false
@export var summon_leader_data: AllyData = null
@export var summon_follower_data: AllyData = null
@export var summon_follower_count: int = 0
@export var summon_type: Types.SummonLifetimeType = Types.SummonLifetimeType.NONE
@export var respawn_cooldown: float = 0.0
@export var summon_is_ground: bool = true
@export var summon_is_blocker: bool = false

# ---------------------------------------------------------------------------
# Aura / support buildings
# ---------------------------------------------------------------------------

@export var is_aura: bool = false
## Authoring string id (e.g. "enemy_slow", "damage_flat"); distinct from [enum Types.AuraCategory] tooling.
@export var aura_category: String = ""
@export var aura_radius: float = 0.0
@export_flags("allies", "buildings", "summons", "tower") var aura_targets: int = 0
@export var aura_stat: Types.AuraStat = Types.AuraStat.DAMAGE
@export var aura_modifier_type: Types.AuraModifierOp = Types.AuraModifierOp.ADD
@export var aura_modifier_value: float = 0.0
## When true, `aura_damage_type_filter` restricts which incoming damage types receive the aura.
@export var aura_limit_damage_type: bool = false
## Only read when `aura_limit_damage_type` is true.
@export var aura_damage_type_filter: Types.DamageType = Types.DamageType.PHYSICAL

# ---------------------------------------------------------------------------
# Healer buildings
# ---------------------------------------------------------------------------

@export var is_healer: bool = false
@export var heal_per_second: float = 0.0
@export var heal_radius: float = 0.0
@export_flags("allies", "tower", "buildings") var heal_target_flags: int = 0
@export var cleanse_on_heal: bool = false
@export var shield_on_heal: float = 0.0

# ---------------------------------------------------------------------------
# Upgrade chain (data-driven)
# ---------------------------------------------------------------------------

## When >= 0, overrides `upgrade_gold_cost`. -1 = use `upgrade_gold_cost`.
@export var upgrade_cost_gold: int = -1
## When >= 0, overrides `upgrade_material_cost`. -1 = use `upgrade_material_cost`.
@export var upgrade_cost_material: int = -1
## Next tier in an upgrade chain (null = terminal).
@export var upgrade_next: BuildingData = null
## Gold / material paid to upgrade into [member upgrade_next] (falls back to effective legacy upgrade costs when both zero).
@export var upgrade_next_gold_cost: int = 0
@export var upgrade_next_material_cost: int = 0
@export var upgrade_level: int = 0
@export var upgrade_label: String = ""

# ---------------------------------------------------------------------------
# Meta
# ---------------------------------------------------------------------------

## Content pipeline: UNTESTED, BASELINE, OVERTUNED, UNDERTUNED, CUT_CAMPAIGN_1.
@export var balance_status: String = "UNTESTED"
## Preferred research gate id for new content; falls back to `unlock_research_id` when empty.
@export var research_unlock_id: String = ""
## Campaign day index at which this blueprint appears (0 = no gate).
@export var campaign_unlock_day: int = 0
@export var tags: PackedStringArray = PackedStringArray()

# ─── CONTENT AUTHORING (Prompt 50) — tower band, roles, extended summoner/aura/healer/upgrade fields ───

## Tower content band: "SMALL", "MEDIUM", "LARGE" (distinct from [member footprint_size_class]).
@export var size_class: String = "MEDIUM"
## Valid values: "DPS", "SUMMONER", "SUPPORT", "HEALER", "AA", "BLOCKER", "AURA", "ARTILLERY"
@export var role_tags: Array[String] = []
@export var summon_squad_size: int = 1
@export var summon_leader_data_path: String = ""
@export var summon_follower_data_path: String = ""
@export var summon_cooldown: float = 15.0
@export var summon_respawn_type: String = "mortal"
@export var summon_respawn_delay: float = 8.0
@export var aura_effect_type: String = ""
@export var aura_effect_value: float = 0.0
@export var heal_per_tick: float = 0.0
@export var heal_tick_interval: float = 1.0
## "allies", "buildings", "both" — string mode for new healer pipelines (see [member heal_target_flags] for bitmask).
@export var heal_targets: String = "allies"
@export var max_upgrade_level: int = 2
@export var upgrade_costs: Array[Dictionary] = []
@export var upgrade_damage_multipliers: Array[float] = [1.25, 1.5]
@export var upgrade_range_multipliers: Array[float] = [1.1, 1.15]
@export var upgrade_fire_rate_multipliers: Array[float] = [1.0, 1.15]
@export var duplicate_cost_k: float = 0.08


## Attack range in world units (alias for authoring tools / external specs that refer to “range”).
func get_range() -> float:
	return attack_range


## Effective gold cost for placement (respects legacy `gold_cost` when override unset).
func get_effective_cost_gold() -> int:
	return gold_cost if cost_gold < 0 else cost_gold


## Effective material cost for placement.
func get_effective_cost_material() -> int:
	return material_cost if cost_material < 0 else cost_material


## Effective upgrade gold cost.
func get_effective_upgrade_cost_gold() -> int:
	return upgrade_gold_cost if upgrade_cost_gold < 0 else upgrade_cost_gold


## Effective upgrade material cost.
func get_effective_upgrade_cost_material() -> int:
	return upgrade_material_cost if upgrade_cost_material < 0 else upgrade_cost_material


## Single research gate: prefers `research_unlock_id`, then legacy `unlock_research_id`.
func get_research_gate_id() -> String:
	if not research_unlock_id.is_empty():
		return research_unlock_id
	return unlock_research_id


## Lightweight checks for authoring; returns human-readable issues (not exhaustive).
func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if get_effective_cost_gold() < 0:
		out.append("effective cost_gold is negative")
	if get_effective_cost_material() < 0:
		out.append("effective cost_material is negative")
	if sell_refund_fraction < 0.0 or sell_refund_fraction > 1.0:
		out.append("sell_refund_fraction should be in [0,1]")
	if is_summoner and summon_squad_size < 1 and summon_follower_count < 1:
		out.append("is_summoner but summon_squad_size/summon_follower_count < 1")
	if is_aura and aura_radius <= 0.0:
		out.append("is_aura but aura_radius <= 0")
	if (
			is_healer
			and (heal_per_second > 0.0 or heal_per_tick > 0.0)
			and heal_radius <= 0.0
	):
		out.append("healer with healing but heal_radius <= 0")
	return out


scripts/health_component.gd:
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


autoloads/signal_bus.gd:
## signal_bus.gd
## Central signal registry for all cross-system communication in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# === COMBAT ===
@warning_ignore("unused_signal")
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
## Emitted once per enemy the first time it deals damage to the central tower (leak / reach metric).
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
## Second arg is empty for roster allies (e.g. Arnulf); set for summoner-tower allies.
@warning_ignore("unused_signal")
signal ally_spawned(ally_id: String, building_instance_id: String)
## Emitted when a summoner ally dies (permanent death, not downed).
@warning_ignore("unused_signal")
signal ally_died(ally_id: String, building_instance_id: String)
## Emitted when the last living ally for a summoner building is removed.
@warning_ignore("unused_signal")
signal ally_squad_wiped(building_instance_id: String)
@warning_ignore("unused_signal")
signal ally_downed(ally_id: String)
@warning_ignore("unused_signal")
signal ally_recovered(ally_id: String)
@warning_ignore("unused_signal")
signal ally_killed(ally_id: String)
## POST-MVP: not yet emitted. Will be emitted from AllyBase._transition_state() when ally state tracking is implemented.
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
## Emitted once per enemy spawned into the mission (Prompt 49 / WaveManager; Prompt 9: type + XZ position).
@warning_ignore("unused_signal")
signal enemy_spawned(enemy_type: Types.EnemyType, position: Vector2)
## Emitted when an enemy with [code]charge[/code] special first crosses its enrage HP threshold.
@warning_ignore("unused_signal")
signal enemy_enraged(enemy_instance_id: String)
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

# === TERRAIN (battlefield zones, navmesh) ===
@warning_ignore("unused_signal")
signal enemy_entered_terrain_zone(enemy: Node, speed_multiplier: float)
@warning_ignore("unused_signal")
signal enemy_exited_terrain_zone(enemy: Node, speed_multiplier: float)
## POST-MVP: not yet emitted. Reserved for destructible terrain props.
@warning_ignore("unused_signal")
signal terrain_prop_destroyed(prop: Node, world_position: Vector3)
## POST-MVP: connected in NavMeshManager but never emitted. Will be emitted from terrain/build flows.
@warning_ignore("unused_signal")
signal nav_mesh_rebake_requested()

# === BUILDINGS ===
@warning_ignore("unused_signal")
signal building_placed(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_sold(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
## Building projectile / aura attribution for CombatStatsTracker (placed_instance_id string).
@warning_ignore("unused_signal")
signal building_dealt_damage(instance_id: String, damage: float, enemy_id: String)
## POST-MVP: connected in CombatStatsTracker but not yet emitted from game code. EnemyBase attack flow should emit this.
@warning_ignore("unused_signal")
signal florence_damaged(amount: int, source_enemy_id: String)
## POST-MVP: not yet emitted. Requires building HP/destruction system.
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

# === DIALOGUE ===
@warning_ignore("unused_signal")
signal dialogue_line_started(entry_id: String, character_id: String)
@warning_ignore("unused_signal")
signal dialogue_line_finished(entry_id: String, character_id: String)

# === BUILD MODE ===
@warning_ignore("unused_signal")
signal build_mode_entered()
@warning_ignore("unused_signal")
signal build_mode_exited()
## Emitted when [member BuildPhaseManager.is_build_phase] becomes true (mission build phase / build mode).
@warning_ignore("unused_signal")
signal build_phase_started()
## Emitted when [member BuildPhaseManager.is_build_phase] becomes false (combat / waves).
@warning_ignore("unused_signal")
signal combat_phase_started()

# === RESEARCH ===
@warning_ignore("unused_signal")
signal research_unlocked(node_id: String)
## Prompt 11: alias event for research UI; mirrors [signal research_unlocked].
@warning_ignore("unused_signal")
signal research_node_unlocked(node_id: String)
## Prompt 11: current research material (RP) for in-mission research panel.
@warning_ignore("unused_signal")
signal research_points_changed(points: int)

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

scenes/hex_grid/hex_grid.gd:
## HexGrid — Manages 24 hex-shaped building slots; handles placement, selling, upgrading, and between-mission persistence.
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

## Must have exactly 36 entries, one per Types.BuildingType enum value.
@export var building_data_registry: Array[BuildingData] = []

## Which hex is targeted for the next build (driven by BuildMenu). -1 = none.
var _build_highlight_slot: int = -1

## Visual ring rotation (build phase only); does not change slot indices.
var rotation_offset_degrees: float = 0.0
const ROTATION_STEP_DEG: float = 15.0

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

## Each Dictionary: { index: int, world_pos: Vector3,
##                    building: BuildingBase|null, is_occupied: bool,
##                    soft_blocker_count: int }
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
	add_to_group("hex_grid")
	_building_container = get_node_or_null("/root/Main/BuildingContainer") as Node3D
	if _building_container == null:
		var c: Node3D = Node3D.new()
		c.name = "BuildingContainer"
		# AP-06 exception: Node3D placeholder has no initialize() — name set above only
		add_child(c)
		_building_container = c
	print("[HexGrid] _ready: building_data_registry size=%d" % building_data_registry.size())
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)
	SignalBus.research_unlocked.connect(_on_research_unlocked)

	_research_manager = get_node_or_null("/root/Main/Managers/ResearchManager")
	print("[HexGrid] _ready: ResearchManager found=%s" % (str(_research_manager != null)))

	if building_data_registry.size() != 36:
		push_error("HexGrid: building_data_registry must have exactly 36 entries, got %d" % building_data_registry.size())
		return

	_initialize_slots()
	_set_slots_visible(false)
	print("[HexGrid] _ready: %d slots initialized" % _slots.size())

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Places a building of building_type on the given slot (charges gold + material).
## Returns true on success, false on any validation failure.
func place_building(slot_index: int, building_type: Types.BuildingType) -> bool:
	if not BuildPhaseManager.assert_build_phase("place_building"):
		return false
	return _try_place_building(slot_index, building_type, true)


## Shop voucher: places first available [param building_type] without spending resources.
## Uses lowest empty slot index. Returns false if no slot or validation fails.
# Intentional: shop voucher placement bypasses build-phase guard by design.
# See docs/FOUL_WARD_MASTER_DOC.md §ShopManager for voucher rules.
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
	if not _validate_placement(slot_index, building_type):
		return false
	return _instantiate_and_place(slot_index, building_type, charge_resources)


## Validates that slot_index is in range, unoccupied, has a BuildingData entry, and is unlocked.
## Does not check affordability (handled by _instantiate_and_place when charge_economy is true).
func _validate_placement(slot_index: int, building_type: Types.BuildingType) -> bool:
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

	return true


## Instantiates and places a building on slot_index.
## When charge_economy is true, checks affordability, registers the purchase, and records costs.
## When charge_economy is false (shop voucher), skips economy checks entirely.
## Assumes _validate_placement(slot_index, building_type) has already returned true.
func _instantiate_and_place(
		slot_index: int,
		building_type: Types.BuildingType,
		charge_economy: bool
) -> bool:
	var slot: Dictionary = _slots[slot_index]
	var building_data: BuildingData = get_building_data(building_type)

	if charge_economy:
		if not EconomyManager.can_afford_building(building_data):
			print("[HexGrid] place_building FAILED: cannot afford scaled cost  have=%dg %dm" % [
				EconomyManager.get_gold(), EconomyManager.get_building_material()
			])
			return false

		var receipt: Dictionary = EconomyManager.register_purchase(building_data)
		if receipt.is_empty():
			push_warning("HexGrid: register_purchase failed after can_afford_building returned true")
			return false

		var building: BuildingBase = BuildingScene.instantiate() as BuildingBase
		# AP-06 exception: add_child before initialize_with_economy — BuildingBase.initialize()
		# expects the node in the tree (see docstring); slot world_pos is applied immediately
		# after add_child, then init. (Swapping init before add_child broke nav/path tests.)
		_building_container.add_child(building)
		building.global_position = slot["world_pos"]
		building.add_to_group("buildings")
		building.initialize_with_economy(building_data, slot_index, _ring_index_for_slot(slot_index))
		building.paid_gold = int(receipt.get("paid_gold", 0))
		building.paid_material = int(receipt.get("paid_material", 0))
		building.total_invested_gold = building.paid_gold
		building.total_invested_material = building.paid_material
		_activate_building_obstacle(building)

		slot["building"] = building
		slot["is_occupied"] = true

		print("[HexGrid] place_building SUCCESS: slot=%d type=%d at pos=(%.1f,%.1f,%.1f)  remaining gold=%d mat=%d" % [
			slot_index, building_type,
			slot["world_pos"].x, slot["world_pos"].y, slot["world_pos"].z,
			EconomyManager.get_gold(), EconomyManager.get_building_material()
		])
		_register_combat_stats_building(building, building_data)
		SignalBus.building_placed.emit(slot_index, building_type)
		return true

	var building_free: BuildingBase = BuildingScene.instantiate() as BuildingBase
	# Same AP-06 exception as paid placement (add_child → pose → initialize_with_economy).
	_building_container.add_child(building_free)
	building_free.global_position = slot["world_pos"]
	building_free.add_to_group("buildings")
	building_free.initialize_with_economy(building_data, slot_index, _ring_index_for_slot(slot_index))
	building_free.record_initial_purchase(0, 0)
	_activate_building_obstacle(building_free)

	slot["building"] = building_free
	slot["is_occupied"] = true

	print("[HexGrid] place_building SUCCESS: slot=%d type=%d at pos=(%.1f,%.1f,%.1f)  remaining gold=%d mat=%d" % [
		slot_index, building_type,
		slot["world_pos"].x, slot["world_pos"].y, slot["world_pos"].z,
		EconomyManager.get_gold(), EconomyManager.get_building_material()
	])
	_register_combat_stats_building(building_free, building_data)
	SignalBus.building_placed.emit(slot_index, building_type)
	return true


func _register_combat_stats_building(building: BuildingBase, building_data: BuildingData) -> void:
	if building == null or building_data == null:
		return
	var bid: String = building_data.building_id.strip_edges()
	if bid.is_empty():
		bid = "building_type:%d" % int(building_data.building_type)
	var sc: String = building_data.size_class.strip_edges()
	if sc.is_empty():
		sc = "MEDIUM"
	CombatStatsTracker.register_building(
			building.placed_instance_id,
			bid,
			sc,
			building.ring_index,
			building.slot_id,
			building.paid_gold,
			0
	)


func rotate_ring(delta_steps: int) -> void:
	if not BuildPhaseManager.is_build_phase:
		push_warning("HexGrid.rotate_ring: attempted outside build phase")
		return
	rotation_offset_degrees += float(delta_steps) * ROTATION_STEP_DEG
	rotation_offset_degrees = fposmod(rotation_offset_degrees, 360.0)
	_rebuild_slot_positions()


func _rebuild_slot_positions() -> void:
	var new_positions: Array[Vector3] = []
	new_positions.append_array(_compute_ring_positions(RING1_COUNT, RING1_RADIUS, rotation_offset_degrees))
	new_positions.append_array(_compute_ring_positions(RING2_COUNT, RING2_RADIUS, rotation_offset_degrees))
	new_positions.append_array(_compute_ring_positions(RING3_COUNT, RING3_RADIUS, 30.0 + rotation_offset_degrees))
	if new_positions.size() != TOTAL_SLOTS:
		push_error("HexGrid._rebuild_slot_positions: position count mismatch")
		return
	for i: int in TOTAL_SLOTS:
		_slots[i]["world_pos"] = new_positions[i]
		var node: Area3D = get_node_or_null("HexSlot_%02d" % i) as Area3D
		if node != null:
			node.global_position = new_positions[i]


func _activate_building_obstacle(building: BuildingBase) -> void:
	# ASSUMPTION: BuildingBase self-configures collision + obstacle in _ready().
	if building == null:
		return


## Sells the building on the given slot. Full refund including upgrade costs if upgraded.
## Returns true on success, false if slot is empty or invalid.
func sell_building(slot_index: int) -> bool:
	if not BuildPhaseManager.assert_build_phase("sell_building"):
		return false
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

	var refund: Dictionary = building.get_sell_refund()
	var rg: int = int(refund.get("gold", 0))
	var rmat: int = int(refund.get("material", 0))
	if rg > 0:
		EconomyManager.add_gold(rg)
	if rmat > 0:
		EconomyManager.add_building_material(rmat)

	AllyManager.despawn_squad(building.placed_instance_id)

	building.remove_from_group("buildings")
	building.queue_free()

	slot["building"] = null
	slot["is_occupied"] = false

	SignalBus.building_sold.emit(slot_index, building_type)
	return true


## Upgrades the building on the given slot from Basic to Upgraded tier.
## Returns true on success, false on any validation failure.
func upgrade_building(slot_index: int) -> bool:
	if not BuildPhaseManager.assert_build_phase("upgrade_building"):
		return false
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.upgrade_building: invalid slot_index %d" % slot_index)
		return false

	var slot: Dictionary = _slots[slot_index]

	if not slot["is_occupied"]:
		push_warning("HexGrid.upgrade_building: slot %d not occupied" % slot_index)
		return false

	var building: BuildingBase = slot["building"] as BuildingBase

	if not building.can_upgrade():
		push_warning("HexGrid.upgrade_building: building on slot %d cannot upgrade" % slot_index)
		return false

	var building_data: BuildingData = building.get_building_data()
	var cost: Dictionary = building.get_upgrade_cost()
	var ug: int = int(cost.get("gold", 0))
	var um: int = int(cost.get("material", 0))

	if not EconomyManager.can_afford(ug, um):
		return false

	var gold_spent: bool = EconomyManager.spend_gold(ug)
	if not gold_spent:
		push_warning("HexGrid: upgrade spend_gold failed after can_afford returned true")
		return false
	var mat_spent: bool = EconomyManager.spend_building_material(um)
	if not mat_spent:
		push_warning("HexGrid: upgrade spend_building_material failed after can_afford returned true")
		EconomyManager.add_gold(ug)
		return false

	var next_chain: BuildingData = building_data.upgrade_next
	if next_chain != null:
		building.apply_upgrade(next_chain)
	else:
		building.record_upgrade_cost(ug, um)
		building.upgrade()

	var upgraded_type: Types.BuildingType = building.get_building_data().building_type
	SignalBus.building_upgraded.emit(slot_index, upgraded_type)
	return true


## Returns a shallow copy of the slot data Dictionary for the given index.
func get_slot_data(slot_index: int) -> Dictionary:
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.get_slot_data: invalid slot_index %d" % slot_index)
		return {}
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
	if not _is_valid_index(slot_index):
		push_warning("HexGrid.get_slot_position: invalid slot_index %d" % slot_index)
		return Vector3.ZERO
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


## Maps a world position to a logical hex key; [member Vector2i.x] is the slot index (0..23), [member Vector2i.y] is unused (0).
func world_to_hex(world_pos: Vector3) -> Vector2i:
	var best_i: int = -1
	var best_d: float = INF
	for i: int in range(TOTAL_SLOTS):
		var wp: Vector3 = _slots[i]["world_pos"] as Vector3
		var d: float = Vector2(wp.x, wp.z).distance_to(Vector2(world_pos.x, world_pos.z))
		if d < best_d:
			best_d = d
			best_i = i
	if best_i < 0:
		return Vector2i(-1, -1)
	return Vector2i(best_i, 0)


## Pathfinding hint: allies patrolling a slot count as soft obstacles (enemies may path around later).
func register_soft_blocker(hex_coord: Vector2i) -> void:
	var idx: int = hex_coord.x
	if not _is_valid_index(idx):
		return
	var slot: Dictionary = _slots[idx]
	var n: int = int(slot.get("soft_blocker_count", 0))
	slot["soft_blocker_count"] = n + 1


func unregister_soft_blocker(hex_coord: Vector2i) -> void:
	var idx: int = hex_coord.x
	if not _is_valid_index(idx):
		return
	var slot: Dictionary = _slots[idx]
	var n: int = int(slot.get("soft_blocker_count", 0))
	slot["soft_blocker_count"] = maxi(0, n - 1)


func has_soft_blocker(hex_coord: Vector2i) -> bool:
	var idx: int = hex_coord.x
	if not _is_valid_index(idx):
		return false
	return int(_slots[idx].get("soft_blocker_count", 0)) > 0


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

	if positions.size() != TOTAL_SLOTS:
		push_error("HexGrid: expected %d positions, got %d" % [TOTAL_SLOTS, positions.size()])
		return

	for i: int in range(TOTAL_SLOTS):
		var slot_data: Dictionary = {
			"index": i,
			"world_pos": positions[i],
			"building": null,
			"is_occupied": false,
			"soft_blocker_count": 0,
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


## Ring index 0 = inner (6 slots), 1 = middle (12), 2 = outer (6).
func _ring_index_for_slot(slot_index: int) -> int:
	if slot_index < RING1_COUNT:
		return 0
	if slot_index < RING1_COUNT + RING2_COUNT:
		return 1
	return 2

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

