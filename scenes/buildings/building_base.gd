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
	_setup_health_component()

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


func _setup_health_component() -> void:
	if _building_data == null or _building_data.max_hp <= 0:
		return
	if health_component != null and is_instance_valid(health_component):
		health_component.max_hp = _building_data.max_hp
		health_component.current_hp = _building_data.max_hp
		if not health_component.health_depleted.is_connected(_on_health_depleted):
			health_component.health_depleted.connect(_on_health_depleted)
		return
	var hc: HealthComponent = HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_hp = _building_data.max_hp
	hc.current_hp = _building_data.max_hp
	add_child(hc)
	health_component = hc
	hc.health_depleted.connect(_on_health_depleted)
	var hp_bar_scene: PackedScene = load("res://scenes/ui/building_hp_bar.tscn") as PackedScene
	if hp_bar_scene != null and hp_bar_scene.can_instantiate():
		var hp_bar: BuildingHpBar = hp_bar_scene.instantiate() as BuildingHpBar
		if hp_bar != null:
			add_child(hp_bar)
			hp_bar.setup(hc)


func _on_health_depleted() -> void:
	if slot_id >= 0:
		SignalBus.building_destroyed.emit(slot_id)
	if _building_data != null and _building_data.is_summoner:
		AllyManager.despawn_squad(placed_instance_id)
	if _building_data != null and _building_data.is_aura:
		AuraManager.deregister_aura(placed_instance_id)
	_spawn_destruction_effect()
	var hex: Node = get_node_or_null("/root/Main/HexGrid")
	if hex != null and hex.has_method("clear_slot_on_destruction"):
		hex.clear_slot_on_destruction(slot_id)
	else:
		push_warning("BuildingBase._on_health_depleted: HexGrid not found")
		_disable_collision_and_obstacle()
		queue_free()


func _spawn_destruction_effect() -> void:
	var fx_container: Node = get_node_or_null("/root/Main/FX")
	if fx_container == null:
		fx_container = get_parent()
	if fx_container == null:
		return
	var effect_scene: PackedScene = load("res://scenes/buildings/destruction_effect.tscn") as PackedScene
	if effect_scene == null or not effect_scene.can_instantiate():
		return
	var fx: Node3D = effect_scene.instantiate() as Node3D
	if fx == null:
		return
	fx_container.add_child(fx)
	fx.global_position = global_position
	if fx.has_method("play"):
		var mesh_ref: Mesh = null
		if is_instance_valid(mesh) and mesh.mesh != null:
			mesh_ref = mesh.mesh
		fx.call("play", global_position, mesh_ref)


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
