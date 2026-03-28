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
	if enemy_data == null:
		push_error("EnemyBase.initialize called with null EnemyData")
		return
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

	# TODO(ART): Swap MeshInstance3D for res://art/generated/enemies/<enemy_id>.glb (PackedScene)
	# when AnimationPlayer-driven visuals replace primitive mesh; wire idle/walk/death clips.
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
## Applies a non-stacking slow: worst (lowest) multiplier wins while any slow is active.
func apply_slow_effect(speed_multiplier: float, duration_seconds: float, source_id: String) -> void:
	if duration_seconds <= 0.0:
		return
	var mult: float = clampf(speed_multiplier, 0.05, 1.0)
	var effect: Dictionary = {
		"effect_type": "slow",
		"remaining_time": duration_seconds,
		"speed_multiplier": mult,
		"source_id": source_id,
	}
	# Replace existing slow from same source, else append (worst multiplier kept in movement).
	var idx: int = -1
	for i: int in range(active_status_effects.size()):
		var e: Dictionary = active_status_effects[i]
		if e.get("effect_type", "") == "slow" and e.get("source_id", "") == source_id:
			idx = i
			break
	if idx >= 0:
		var old: Dictionary = active_status_effects[idx]
		if float(effect["remaining_time"]) > float(old.get("remaining_time", 0.0)):
			active_status_effects[idx] = effect
	else:
		active_status_effects.append(effect)


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
		if effect.get("effect_type", "") == "slow":
			var slow_rem: float = float(effect.get("remaining_time", 0.0)) - delta
			effect["remaining_time"] = slow_rem
			if slow_rem <= 0.0:
				active_status_effects.remove_at(i)
			else:
				active_status_effects[i] = effect
				i += 1
			continue

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

## Returns combined slow multiplier from active slow effects (1.0 = no slow).
func get_move_speed_slow_multiplier() -> float:
	var worst: float = 1.0
	for effect: Dictionary in active_status_effects:
		if effect.get("effect_type", "") != "slow":
			continue
		var m: float = float(effect.get("speed_multiplier", 1.0))
		worst = minf(worst, m)
	return worst


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
	var speed_mult: float = get_move_speed_slow_multiplier()
	if direction != Vector3.ZERO:
		velocity = direction * _enemy_data.move_speed * speed_mult
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
	var speed_mult: float = get_move_speed_slow_multiplier()
	velocity = direction * _enemy_data.move_speed * speed_mult
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

