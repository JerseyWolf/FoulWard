## Tower — Central destructible structure owning Florence's two weapons; handles reload, burst-fire, enchantment composition, and assist/miss.
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

## Tower's starting hit point total at the beginning of each mission.
@export var starting_hp: int = 500
## WeaponData resource for Florence's primary crossbow weapon.
@export var crossbow_data: WeaponData
## WeaponData resource for Florence's secondary rapid missile weapon.
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
@onready var _health_component: HealthComponent = $HealthComponent

# ASSUMPTION: ProjectileContainer at /root/Main/ProjectileContainer per ARCHITECTURE.md §2.
# Null in isolated test scenes (no Main) — firing methods no-op spawn when absent.
@onready var _projectile_container: Node3D = get_node_or_null(
	"/root/Main/ProjectileContainer"
) as Node3D

# Reload timers — count DOWN to 0 (weapon ready when <= 0)
var _crossbow_reload_remaining: float = 0.0
var _rapid_missile_reload_remaining: float = 0.0

# Burst-fire state for Rapid Missile
var _burst_remaining: int = 0
var _burst_timer: float = 0.0
var _burst_target: Vector3 = Vector3.ZERO

## Temporary spell shield (SpellManager tower_shield). Absorbs damage before HP.
var _spell_shield_hp: float = 0.0
var _spell_shield_duration_remaining: float = 0.0
# ASSUMPTION: Tower-owned RNG is used instead of global randf() so tests can seed it.
var _shot_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("tower")
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

	# Production wiring: asset = RiggedVisualWiring.tower_glb_path()
	# → "res://art/characters/florence/florence.glb"; tower is static (no AnimationPlayer).
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
	if _spell_shield_duration_remaining > 0.0:
		_spell_shield_duration_remaining -= delta
		if _spell_shield_duration_remaining <= 0.0:
			_spell_shield_hp = 0.0
			_spell_shield_duration_remaining = 0.0
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
	var n_proj: int = 1
	var spread_deg: float = 0.0
	if _weapon_upgrade_manager != null:
		n_proj = _weapon_upgrade_manager.get_effective_projectile_count(weapon_slot)
		spread_deg = _weapon_upgrade_manager.get_effective_spread_angle_degrees(weapon_slot)
	var aim_points: Array[Vector3] = fan_aim_points(global_position, final_target, n_proj, spread_deg)
	for p: Vector3 in aim_points:
		_spawn_weapon_projectile(weapon_slot, composed, global_position, p)
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
	var remaining: float = float(amount)
	if _spell_shield_hp > 0.0:
		var absorb: float = minf(_spell_shield_hp, remaining)
		_spell_shield_hp -= absorb
		remaining -= absorb
	if remaining <= 0.0:
		return
	print("[Tower] take_damage: %d  hp=%d→%d" % [amount, _health_component.current_hp, _health_component.current_hp - int(remaining)])
	_health_component.take_damage(remaining)


## Adds or refreshes a spell shield (HP pool and duration). Larger pool replaces smaller.
func add_spell_shield(amount: float, duration_seconds: float) -> void:
	if amount <= 0.0 or duration_seconds <= 0.0:
		return
	_spell_shield_hp = maxf(_spell_shield_hp, amount)
	_spell_shield_duration_remaining = maxf(_spell_shield_duration_remaining, duration_seconds)


func get_spell_shield_hp() -> float:
	return _spell_shield_hp


func get_spell_shield_duration_remaining() -> float:
	return _spell_shield_duration_remaining


## Restores tower HP to maximum. Called by ShopManager (Tower Repair Kit).
func repair_to_full() -> void:
	_health_component.reset_to_max()


## POST-MVP: permanent max HP bonus from shop (tower_armor_plate).
func add_max_hp_bonus(amount: int) -> void:
	push_warning("Tower.add_max_hp_bonus: not yet fully implemented (amount=%d)" % amount)


## POST-MVP: heal tower by a fraction of max HP (emergency_repair consumable).
func heal_percent_max_hp(fraction: float) -> void:
	push_warning("Tower.heal_percent_max_hp: not yet fully implemented (fraction=%f)" % fraction)


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
	proj.initialize_from_weapon(weapon_data, global_position, target_pos, -1.0, Types.DamageType.PHYSICAL, 0, 0.0, true)
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


## Public for deterministic tests (SimBot / GdUnit).
func fan_aim_points(origin: Vector3, aim: Vector3, count: int, spread_deg: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if count < 2 or spread_deg <= 0.001:
		out.append(aim)
		return out
	var base_dir: Vector3 = aim - origin
	var dist: float = base_dir.length()
	if dist < 0.0001:
		base_dir = Vector3(0.0, 0.0, 1.0)
		dist = 1.0
	else:
		base_dir = base_dir / dist
	var axis: Vector3 = base_dir.cross(Vector3.UP)
	if axis.length_squared() < 0.000001:
		axis = Vector3.RIGHT
	else:
		axis = axis.normalized()
	var half: float = spread_deg * 0.5
	for i: int in range(count):
		var t: float = float(i) / float(count - 1)
		var ang_deg: float = lerp(-half, half, t)
		var dir: Vector3 = base_dir.rotated(axis, deg_to_rad(ang_deg)).normalized()
		out.append(origin + dir * dist)
	return out


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
	var pierce: int = 0
	var splash: float = 0.0
	if _weapon_upgrade_manager != null:
		pierce = _weapon_upgrade_manager.get_effective_pierce_count(weapon_slot)
		splash = _weapon_upgrade_manager.get_effective_splash_radius(weapon_slot)

	_projectile_container.add_child(projectile)
	projectile.initialize_from_weapon(
		weapon_data,
		origin,
		target_position,
		damage,
		damage_type,
		pierce,
		splash,
		true
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
			var nearest_enemy: Node3D = _find_assist_target(global_position, raw_dir, weapon_data)
			if nearest_enemy != null:
				assisted_target = nearest_enemy.global_position

	return assisted_target


## Scans the "enemies" group for the nearest living enemy within the assist cone.
## Returns null when no qualifying target is found.
func _find_assist_target(origin: Vector3, direction: Vector3, weapon_data: WeaponData) -> Node3D:
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

		var to_enemy_vec: Vector3 = enemy.global_position - origin
		var to_enemy_len_sq: float = to_enemy_vec.length_squared()
		if to_enemy_len_sq <= 0.000001:
			continue
		var distance_to_enemy: float = sqrt(to_enemy_len_sq)
		if weapon_data.assist_max_distance > 0.0 and distance_to_enemy > weapon_data.assist_max_distance:
			continue

		# SOURCE: Godot docs Vector3.angle_to + rad_to_deg cone check pattern.
		var to_enemy: Vector3 = to_enemy_vec / distance_to_enemy
		var angle_deg: float = rad_to_deg(direction.angle_to(to_enemy))
		if angle_deg > weapon_data.assist_angle_degrees:
			continue

		if distance_to_enemy < nearest_distance:
			nearest_distance = distance_to_enemy
			nearest_enemy = enemy

	return nearest_enemy


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

