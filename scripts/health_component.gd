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
	## Do not overwrite HP set by the owner before add_child() (damaged buildings, tests).
	if current_hp <= 0 or current_hp > max_hp:
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

