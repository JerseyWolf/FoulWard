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

const ProjectileScene: PackedScene = preload(
	"res://scenes/projectiles/projectile_base.tscn"
)

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

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	assert(crossbow_data != null,
		"Tower: crossbow_data export not assigned. Assign crossbow.tres in editor.")
	assert(rapid_missile_data != null,
		"Tower: rapid_missile_data export not assigned. Assign rapid_missile.tres in editor.")

	_health_component.max_hp = starting_hp
	_health_component.reset_to_max()

	_health_component.health_changed.connect(_on_health_changed)
	_health_component.health_depleted.connect(_on_health_depleted)


func _physics_process(delta: float) -> void:
	if _crossbow_reload_remaining > 0.0:
		_crossbow_reload_remaining -= delta
	if _rapid_missile_reload_remaining > 0.0:
		_rapid_missile_reload_remaining -= delta

	# Burst fire — ticks independently from the reload timer.
	if _burst_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_spawn_projectile(rapid_missile_data, _burst_target)
			_burst_remaining -= 1
			_burst_timer = rapid_missile_data.burst_interval

# ── Public API ────────────────────────────────────────────────────────────

## Fires one crossbow bolt toward target_position. Does nothing if reloading.
func fire_crossbow(target_position: Vector3) -> void:
	if _crossbow_reload_remaining > 0.0:
		return
	_spawn_projectile(crossbow_data, target_position)
	_crossbow_reload_remaining = crossbow_data.reload_time
	SignalBus.projectile_fired.emit(
		Types.WeaponSlot.CROSSBOW,
		global_position,
		target_position
	)


## Starts a burst of rapid_missile_data.burst_count projectiles.
## Does nothing if reloading or a burst is already in progress.
func fire_rapid_missile(target_position: Vector3) -> void:
	if _rapid_missile_reload_remaining > 0.0:
		return
	if _burst_remaining > 0:
		return
	_rapid_missile_reload_remaining = rapid_missile_data.reload_time
	_burst_remaining = rapid_missile_data.burst_count
	_burst_timer = 0.0  # First shot fires this same physics frame.
	_burst_target = target_position
	SignalBus.projectile_fired.emit(
		Types.WeaponSlot.RAPID_MISSILE,
		global_position,
		target_position
	)


## Applies raw integer damage to the HealthComponent.
func take_damage(amount: int) -> void:
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

# ── Private ───────────────────────────────────────────────────────────────

## Null guard: _projectile_container is null in headless test scenes.
## push_warning is logged; no crash.
func _spawn_projectile(weapon_data: WeaponData, target_pos: Vector3) -> void:
	if _projectile_container == null:
		push_warning("Tower._spawn_projectile: ProjectileContainer not found — skipping spawn.")
		return
	var proj: ProjectileBase = ProjectileScene.instantiate() as ProjectileBase
	# ASSUMPTION: ProjectileBase.initialize_from_weapon signature per Phase 2 output.
	proj.initialize_from_weapon(weapon_data, global_position, target_pos)
	_projectile_container.add_child(proj)
	proj.add_to_group("projectiles")


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	SignalBus.tower_damaged.emit(current_hp, max_hp)


func _on_health_depleted() -> void:
	SignalBus.tower_destroyed.emit()

