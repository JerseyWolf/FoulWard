## relationship_tier_config.gd
## Data-driven affinity tier thresholds (shared by all characters).

class_name RelationshipTierConfig
extends Resource

## Each entry: { "name": String, "min_affinity": float }, sorted ascending by min_affinity.
@export var tiers: Array[Dictionary] = []
