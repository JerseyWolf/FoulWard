## dialogue_entry.gd
## Data-driven hub dialogue line. Loaded from res://resources/dialogue/**/*.tres.

class_name DialogueEntry
extends Resource

@export var entry_id: String = ""
@export var character_id: String = ""
@export_multiline var text: String = "TODO: placeholder dialogue line." # PLACEHOLDER

@export var priority: int = 10 # TUNING
@export var once_only: bool = false
@export var chain_next_id: String = ""
@export var conditions: Array[DialogueCondition] = []
