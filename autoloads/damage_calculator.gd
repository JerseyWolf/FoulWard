## damage_calculator.gd
## Stateless utility that applies armor-type multipliers to incoming base damage.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# Nested Dictionary[ArmorType, Dictionary[DamageType, float]]
# Row = armor type of target. Column = damage type of attack.
const DAMAGE_MATRIX: Dictionary = {
	Types.ArmorType.UNARMORED: {
		Types.DamageType.PHYSICAL: 1.0,
		Types.DamageType.FIRE:     1.0,
		Types.DamageType.MAGICAL:  1.0,
		Types.DamageType.POISON:   1.0,
	},
	Types.ArmorType.HEAVY_ARMOR: {
		Types.DamageType.PHYSICAL: 0.5,
		Types.DamageType.FIRE:     1.0,
		Types.DamageType.MAGICAL:  2.0,
		Types.DamageType.POISON:   1.0,
	},
	Types.ArmorType.UNDEAD: {
		Types.DamageType.PHYSICAL: 1.0,
		Types.DamageType.FIRE:     2.0,
		Types.DamageType.MAGICAL:  1.0,
		Types.DamageType.POISON:   0.0,
	},
	Types.ArmorType.FLYING: {
		Types.DamageType.PHYSICAL: 1.0,
		Types.DamageType.FIRE:     1.0,
		Types.DamageType.MAGICAL:  1.0,
		Types.DamageType.POISON:   1.0,
	},
}

## Returns base_damage multiplied by the matrix multiplier for the given armor and damage type.
## Never emits signals. Never reads game state. Pure function.
func calculate_damage(
		base_damage: float,
		damage_type: Types.DamageType,
		armor_type: Types.ArmorType) -> float:
	return base_damage * DAMAGE_MATRIX[armor_type][damage_type]

