## enchantment_data.gd
## Data-driven definition of a single weapon enchantment for Florence.
## Combines with WeaponData at runtime to modify projectile damage and type.
## SOURCE: Godot docs — Resource composition patterns, https://docs.godotengine.org/

class_name EnchantmentData
extends Resource

## Unique string identifier for this enchantment.
@export var enchantment_id: String = ""
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
## Human-readable description of the enchantment's effect shown in UI.
@export var description: String = ""

# Logical slot this enchantment can occupy, e.g. "elemental" or "power".
## Which enchantment slot this occupies: "elemental" or "power".
@export var slot_type: String = "generic"

# If true, override the projectile's primary damage type with damage_type_override.
## True if this enchantment replaces the projectile's primary damage type.
@export var has_damage_type_override: bool = false
## The damage type that overrides the weapon's base damage type when active.
@export var damage_type_override: Types.DamageType = Types.DamageType.PHYSICAL

# Future hook for secondary damage channels or status effects.
## True if this enchantment adds a secondary damage type to the projectile.
@export var has_secondary_damage_type: bool = false
## The additional damage type applied alongside the primary type.
@export var secondary_damage_type: Types.DamageType = Types.DamageType.PHYSICAL  # POST-MVP

# Multiplicative modifier applied to WeaponData.damage before DamageCalculator.
## Multiplier applied to the weapon's base damage output while this enchantment is active.
@export var damage_multiplier: float = 1.0

# Generic extensibility hooks for POST-MVP behaviors.
## String tags describing the enchantment's special effects (e.g. "burn", "pierce").
@export var effect_tags: Array[String] = []
## Dictionary of additional effect parameters consumed by the projectile system.
@export var effect_data: Dictionary = {}
