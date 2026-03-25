## dialogue_condition.gd
## Single AND-clause for DialogueEntry. Evaluated by DialogueManager._evaluate_conditions.

class_name DialogueCondition
extends Resource

@export var key: String = ""
@export var comparison: String = "=="
@export var value: Variant
