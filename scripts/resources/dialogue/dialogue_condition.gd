## dialogue_condition.gd
## Single AND-clause for DialogueEntry. Evaluated by DialogueManager._evaluate_conditions.

class_name DialogueCondition
extends Resource

@export var key: String = ""
@export var comparison: String = "=="
@export var value: Variant

## Empty: legacy `key` / `comparison` / `value`. `relationship_tier`: uses `character_id` + `required_tier`.
@export var condition_type: String = ""
@export var character_id: String = ""
@export var required_tier: String = ""
