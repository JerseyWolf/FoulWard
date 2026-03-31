## Absorbs damage before HP (Orc Shieldbearer and similar).
class_name ShieldComponent
extends Node

var shield_hp: float = 0.0
var max_shield_hp: float = 0.0


func initialise(params: Dictionary) -> void:
	max_shield_hp = float(params.get("shield_hp", 0))
	shield_hp = max_shield_hp


func is_active() -> bool:
	return shield_hp > 0.0


## Returns leftover damage after absorbing what it can.
func absorb(damage: float) -> float:
	if not is_active():
		return damage
	if damage <= shield_hp:
		shield_hp -= damage
		return 0.0
	else:
		var leftover: float = damage - shield_hp
		shield_hp = 0.0
		return leftover
