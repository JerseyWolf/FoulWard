## dialogue_condition.gd
## Single AND-clause for DialogueEntry. Evaluated by DialogueManager._evaluate_conditions.

class_name DialogueCondition
extends Resource

## Game-state key to evaluate (e.g. "florence.day_count", "research.unlocked.*").
@export var key: String = ""
## Comparison operator string: "==", "!=", ">", ">=", "<", or "<=".
@export var comparison: String = "=="
## Value to compare the resolved key against.
@export var value: Variant

## Empty: legacy `key` / `comparison` / `value`. `relationship_tier`: uses `character_id` + `required_tier`.
@export var condition_type: String = ""
## ID of the hub character who speaks this line.
@export var character_id: String = ""
## Minimum relationship tier name required for this condition to pass.
@export var required_tier: String = ""
