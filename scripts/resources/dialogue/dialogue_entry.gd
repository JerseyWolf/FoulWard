## dialogue_entry.gd
## Data-driven hub dialogue line. Loaded from res://resources/dialogue/**/*.tres.

class_name DialogueEntry
extends Resource

## Unique identifier used for once_only tracking and chain_next_id linking.
@export var entry_id: String = ""
## ID of the hub character who speaks this line.
@export var character_id: String = ""
@export_multiline var text: String = "TODO: placeholder dialogue line." # PLACEHOLDER

## Sorting priority; higher values are returned first by DialogueManager.
@export var priority: int = 10 # TUNING
## True if this entry should never repeat once it has been played.
@export var once_only: bool = false
## entry_id of the next DialogueEntry to play automatically after this one.
@export var chain_next_id: String = ""
## Array of DialogueCondition resources; all must pass for this entry to be eligible.
@export var conditions: Array[DialogueCondition] = []
## True for mid-combat banner lines (filtered by DialogueManager.request_combat_line).
@export var is_combat_line: bool = false
