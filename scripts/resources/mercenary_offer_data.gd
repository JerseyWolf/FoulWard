## mercenary_offer_data.gd
## Data for a single mercenary recruitment offer (catalog or defection-injected).

extends Resource
class_name MercenaryOfferData

## Must match `AllyData.ally_id` for the recruitable ally.
@export var ally_id: String = ""

@export var cost_gold: int = 0 # TUNING
@export var cost_building_material: int = 0 # TUNING
@export var cost_research_material: int = 0 # TUNING

@export var min_day: int = 1
## −1 = no upper day limit.
@export var max_day: int = -1

@export var required_territory_ids: Array[String] = [] # POST-MVP
@export var required_faction_ids: Array[String] = [] # POST-MVP
@export var required_research_ids: Array[String] = [] # POST-MVP

## True when created from a defeated mini-boss defection path (not from catalog filter).
@export var is_defection_offer: bool = false


func is_available_on_day(day: int) -> bool:
	if day < min_day:
		return false
	if max_day >= 0 and day > max_day:
		return false
	return true


func get_cost_summary() -> String:
	if cost_gold <= 0 and cost_building_material <= 0 and cost_research_material <= 0:
		return "Free"
	var parts: PackedStringArray = PackedStringArray()
	if cost_gold > 0:
		parts.append("%d Gold" % cost_gold)
	if cost_building_material > 0:
		parts.append("%d Mat" % cost_building_material)
	if cost_research_material > 0:
		parts.append("%d Res" % cost_research_material)
	return ", ".join(parts)
