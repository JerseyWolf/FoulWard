## enchantment_data.gd
## Data-driven definition of a single weapon enchantment for Florence.
## Combines with WeaponData at runtime to modify projectile damage and type.
## SOURCE: Godot docs — Resource composition patterns, https://docs.godotengine.org/

class_name EnchantmentData
extends Resource

@export var enchantment_id: String = ""
@export var display_name: String = ""
@export var description: String = ""

# Logical slot this enchantment can occupy, e.g. "elemental" or "power".
@export var slot_type: String = "generic"

# If true, override the projectile's primary damage type with damage_type_override.
@export var has_damage_type_override: bool = false
@export var damage_type_override: Types.DamageType = Types.DamageType.PHYSICAL

# Future hook for secondary damage channels or status effects.
@export var has_secondary_damage_type: bool = false
@export var secondary_damage_type: Types.DamageType = Types.DamageType.PHYSICAL  # POST-MVP

# Multiplicative modifier applied to WeaponData.damage before DamageCalculator.
@export var damage_multiplier: float = 1.0

# Generic extensibility hooks for POST-MVP behaviors.
@export var effect_tags: Array[String] = []
@export var effect_data: Dictionary = {}
