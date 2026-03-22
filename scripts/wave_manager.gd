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
# Credit: Foul Ward SYSTEMS_part1.md §1 (WaveManager spec) — Foul Ward team.
# Credit: Godot Engine Documentation — SceneTree.get_nodes_in_group()
#   https://docs.godotengine.org/en/stable/classes/class_scenetree.html
#   License: CC BY 3.0 | Adapted: group-as-source-of-truth for living enemy count.
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
#   License: CC BY 3.0 | Adapted: delta timers automatically respect time_scale.

class_name WaveManager
extends Node

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

## Seconds of countdown before each wave.
@export var wave_countdown_duration: float = 30.0

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
@onready var _enemy_container: Node3D = get_node("/root/Main/EnemyContainer")

## Container holding the 10 Marker3D spawn-point nodes.
@onready var _spawn_points: Node3D = get_node("/root/Main/SpawnPoints")

# ---------------------------------------------------------------------------
# INTERNAL STATE
# ---------------------------------------------------------------------------

var _current_wave: int = 0
var _countdown_remaining: float = 0.0
var _is_counting_down: bool = false
var _is_wave_active: bool = false
var _is_sequence_running: bool = false

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	assert(
		enemy_data_registry.size() == 6,
		"WaveManager: enemy_data_registry must have exactly 6 entries, got %d"
		% enemy_data_registry.size()
	)
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.game_state_changed.connect(_on_game_state_changed)

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
	clear_all_enemies()


## Immediately removes all enemies from the scene and the "enemies" group.
## remove_from_group() is called before queue_free() so get_living_enemy_count()
## is accurate within the same frame.
func clear_all_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		node.remove_from_group("enemies")
		node.queue_free()

# ---------------------------------------------------------------------------
# PRIVATE — COUNTDOWN & SPAWN
# ---------------------------------------------------------------------------

func _begin_countdown_for_next_wave() -> void:
	_current_wave += 1
	_countdown_remaining = wave_countdown_duration
	_is_counting_down = true
	_is_wave_active = false
	SignalBus.wave_countdown_started.emit(_current_wave, wave_countdown_duration)


## Wave formula: N enemies of EACH of the 6 types → total = N × 6.
## Wave 1 = 6, Wave 5 = 30, Wave 10 = 60.
func _spawn_wave(wave_number: int) -> void:
	assert(wave_number >= 1 and wave_number <= max_waves,
		"WaveManager: _spawn_wave() invalid wave_number %d." % wave_number)

	var spawn_point_nodes: Array[Node] = _spawn_points.get_children()
	assert(
		spawn_point_nodes.size() > 0,
		"WaveManager: No spawn points found under SpawnPoints node."
	)

	var total_spawned: int = 0

	for enemy_data: EnemyData in enemy_data_registry:
		for i: int in range(wave_number):
			var enemy: EnemyBase = EnemyScene.instantiate() as EnemyBase
			enemy.initialize(enemy_data)

			var spawn_marker: Marker3D = \
				spawn_point_nodes.pick_random() as Marker3D
			var offset: Vector3 = Vector3(
				randf_range(-2.0, 2.0),
				0.0,
				randf_range(-2.0, 2.0)
			)
			enemy.global_position = spawn_marker.global_position + offset

			if enemy_data.is_flying:
				enemy.global_position.y = 5.0

			_enemy_container.add_child(enemy)
			enemy.add_to_group("enemies")
			total_spawned += 1

	_is_wave_active = true
	SignalBus.wave_started.emit(wave_number, total_spawned)

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
	# call_deferred ensures _check_wave_cleared() runs AFTER the dying enemy's
	# queue_free() and remove_from_group() have resolved this frame.
	call_deferred("_check_wave_cleared")


func _check_wave_cleared() -> void:
	if get_living_enemy_count() > 0:
		return
	_is_wave_active = false
	SignalBus.wave_cleared.emit(_current_wave)

	if _current_wave >= max_waves:
		_is_sequence_running = false
		SignalBus.all_waves_cleared.emit()
	else:
		_begin_countdown_for_next_wave()


func _on_game_state_changed(
		_old_state: Types.GameState,
		_new_state: Types.GameState
) -> void:
	# Build mode slows countdown via Engine.time_scale — no special handling needed.
	pass

