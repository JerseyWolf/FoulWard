## SybilPassiveData — Resource describing one selectable Sybil passive (S02).
extends Resource
class_name SybilPassiveData

# effect_type values: "spell_damage_pct", "mana_regen_pct", "max_mana_flat",
# "cooldown_pct", "mana_cost_pct", "max_hp_pct", "resource_income_pct",
# "heal_effectiveness_pct"

@export var passive_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_id: String = ""
@export var category: String = "" # "offense" | "defense" | "utility"
@export var effect_type: String = ""
@export var effect_value: float = 0.0
@export var is_unlocked: bool = true
@export var prerequisite_ids: Array[String] = []
