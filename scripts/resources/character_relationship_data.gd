## character_relationship_data.gd
## Per-character starting affinity for RelationshipManager.

class_name CharacterRelationshipData
extends Resource

## ID of the hub character who speaks this line.
@export var character_id: String = ""
## Initial affinity value (−100..100) at the start of a new run.
@export var starting_affinity: float = 0.0
## Human-readable name shown in UI and debug labels.
@export var display_name: String = ""
