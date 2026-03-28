## relationship_event_data.gd
## Maps a SignalBus signal to per-character affinity deltas.

class_name RelationshipEventData
extends Resource

## Must match a signal name on SignalBus exactly.
@export var signal_name: String = ""

## character_id → delta (float)
@export var character_deltas: Dictionary = {}
