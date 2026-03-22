# spell_manager.gd
# SpellManager owns Sybil's mana pool and spell cooldowns for FOUL WARD.
# MVP: one spell — Shockwave (ground AoE, MAGICAL damage).
# Mana regenerates in _physics_process, respecting Engine.time_scale.
#
# Scene placement: /root/Main/Managers/SpellManager (Node)
#
# Credit: Foul Ward SYSTEMS_part3.md §9 (SpellManager spec) — Foul Ward team.
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
#   License: CC BY 3.0 | Adapted: delta-based regen auto-scales with time_scale.
# Credit: Godot Engine Documentation — SceneTree.get_nodes_in_group()
#   https://docs.godotengine.org/en/stable/classes/class_scenetree.html
#   License: CC BY 3.0 | Adapted: group iteration + is_instance_valid guard.

class_name SpellManager
extends Node

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

@export var max_mana: int = 100
@export var mana_regen_rate: float = 5.0

## Array of SpellData resources. One entry per spell. MVP: only shockwave.
@export var spell_registry: Array[SpellData] = []

# ---------------------------------------------------------------------------
# INTERNAL STATE
# ---------------------------------------------------------------------------

# Float accumulator for smooth sub-integer regen per frame.
# Separate integer snapshot drives signals to avoid emitting 60×/sec.
var _current_mana_float: float = 0.0
var _current_mana: int = 0

# Per-spell cooldown tracking. Key: spell_id (String). Value: seconds remaining.
# A spell is OFF cooldown when its key is absent from this dictionary.
var _cooldown_remaining: Dictionary = {}

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	pass  # Cooldown dict is populated lazily on cast.

# ---------------------------------------------------------------------------
# PHYSICS PROCESS — Mana regen + cooldown tick
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_tick_mana_regen(delta)
	_tick_cooldowns(delta)


func _tick_mana_regen(delta: float) -> void:
	# Pattern: snapshot old int → apply regen → compare new int → emit only on change.
	# Avoids emitting mana_changed 60×/sec when regen is sub-integer per frame.
	if _current_mana_float >= float(max_mana):
		return

	_current_mana_float = minf(
		_current_mana_float + mana_regen_rate * delta,
		float(max_mana)
	)

	var new_int: int = int(_current_mana_float)
	if new_int != _current_mana:
		_current_mana = new_int
		SignalBus.mana_changed.emit(_current_mana, max_mana)


func _tick_cooldowns(delta: float) -> void:
	# Iterate over a copy of keys to allow safe erasure during iteration.
	for spell_id: String in _cooldown_remaining.keys():
		_cooldown_remaining[spell_id] -= delta
		if _cooldown_remaining[spell_id] <= 0.0:
			_cooldown_remaining.erase(spell_id)
			SignalBus.spell_ready.emit(spell_id)

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Attempts to cast a spell. Returns true on success, false on failure.
## Failure conditions: unknown spell_id, insufficient mana, on cooldown.
func cast_spell(spell_id: String) -> bool:
	var spell_data: SpellData = _get_spell_data(spell_id)
	if spell_data == null:
		push_warning("SpellManager: cast_spell() unknown spell_id '%s'." % spell_id)
		return false

	if _current_mana < spell_data.mana_cost:
		return false

	if _cooldown_remaining.has(spell_id):
		return false

	# Deduct mana — sync float accumulator to prevent regen overshooting.
	_current_mana -= spell_data.mana_cost
	_current_mana_float = float(_current_mana)

	_cooldown_remaining[spell_id] = spell_data.cooldown

	_apply_spell_effect(spell_data)

	SignalBus.spell_cast.emit(spell_id)
	SignalBus.mana_changed.emit(_current_mana, max_mana)
	return true


func get_current_mana() -> int:
	return _current_mana

func get_max_mana() -> int:
	return max_mana

## Returns remaining cooldown seconds (0.0 if ready or unknown).
func get_cooldown_remaining(spell_id: String) -> float:
	return _cooldown_remaining.get(spell_id, 0.0)

## Returns true if the spell is known, mana is sufficient, and cooldown is zero.
func is_spell_ready(spell_id: String) -> bool:
	var spell_data: SpellData = _get_spell_data(spell_id)
	if spell_data == null:
		return false
	return _current_mana >= spell_data.mana_cost \
		and not _cooldown_remaining.has(spell_id)

## Sets mana to full (used by Mana Draught shop item).
func set_mana_to_full() -> void:
	_current_mana = max_mana
	_current_mana_float = float(max_mana)
	SignalBus.mana_changed.emit(_current_mana, max_mana)

## Resets mana to 0 and clears all cooldowns.
func reset_to_defaults() -> void:
	_current_mana = 0
	_current_mana_float = 0.0
	_cooldown_remaining.clear()
	SignalBus.mana_changed.emit(0, max_mana)

# ---------------------------------------------------------------------------
# PRIVATE — SPELL LOOKUP & EFFECTS
# ---------------------------------------------------------------------------

func _get_spell_data(spell_id: String) -> SpellData:
	for spell_data: SpellData in spell_registry:
		if spell_data.spell_id == spell_id:
			return spell_data
	return null


func _apply_spell_effect(spell_data: SpellData) -> void:
	match spell_data.spell_id:
		"shockwave":
			_apply_shockwave(spell_data)
		_:
			push_warning(
				"SpellManager: _apply_spell_effect() unknown spell '%s'."
				% spell_data.spell_id
			)


## Applies Shockwave AoE — hits all ground enemies on the battlefield.
## Battlefield-wide (radius = 100.0 covers full map).
func _apply_shockwave(spell_data: SpellData) -> void:
	# Credit: Foul Ward SYSTEMS_part3.md §9.6 (_apply_shockwave)
	# get_nodes_in_group() returns a snapshot — safe to iterate even if enemies
	# are freed mid-loop. is_instance_valid() guards against chain-kills.
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue

		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue

		# hits_flying = false on shockwave.tres — skip Bat Swarm.
		if not spell_data.hits_flying and enemy.get_enemy_data().is_flying:
			continue

		# Single path: EnemyBase.take_damage applies immunities + armor matrix.
		enemy.take_damage(spell_data.damage, spell_data.damage_type)

