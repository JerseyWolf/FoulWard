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

## Endless mode: per-day scaling (no cap past campaign_length; same formula for all days ≥ 1).
const ENDLESS_HP_MULT_PER_DAY: float = 0.02
const ENDLESS_SPAWN_MULT_PER_DAY: float = 0.01

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
var spawn_count_multiplier: float = 1.0

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

## Effective HP multiplier for a given calendar day (endless scaling; unbounded).
static func get_effective_enemy_hp_multiplier_for_day(day_index: int) -> float:
	var d: int = maxi(day_index, 1)
	return 1.0 + float(d - 1) * ENDLESS_HP_MULT_PER_DAY


## Effective spawn-count multiplier for a given calendar day (endless scaling; unbounded).
static func get_effective_spawn_count_multiplier_for_day(day_index: int) -> float:
	var d: int = maxi(day_index, 1)
	return 1.0 + float(d - 1) * ENDLESS_SPAWN_MULT_PER_DAY


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
	spawn_count_multiplier = 1.0
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
	spawn_count_multiplier = day_config.spawn_count_multiplier
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
		var from_map: String = GameManager.get_effective_faction_id_for_territory(day_config.territory_id)
		fid = from_map if not from_map.is_empty() else "DEFAULT_MIXED"

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
	var base_total: float = float(wave_index * 6) * spawn_count_multiplier

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
