## character_data.gd
## Data describing a hub character entry for the between-mission hub.

extends Resource
class_name CharacterData

## Stable identifier used by DialogueManager pools and hub interaction focus.
@export var character_id: String

## Human-readable name shown on the hub character UI.
@export var display_name: String

## One-line placeholder description for future UI and tooltips.
@export var description: String = "TODO: description"

## Uses Types.HubRole as the canonical hub role marker.
@export var role: Types.HubRole = Types.HubRole.FLAVOR_ONLY

## Visual identifiers used by UI; portraits are handled elsewhere.
@export var portrait_id: String = "TODO_PORTRAIT"

## POST-MVP: Optional icon sprite identifier for richer hub visuals.
@export var icon_id: String = ""

## 2D hub placement; used by the 2D hub overlay implementation.
@export var hub_position_2d: Vector2 = Vector2.ZERO

## POST-MVP: For a future 3D hub room, this can reference a named marker node.
@export var hub_marker_name_3d: String = ""

## Tags passed into DialogueManager when requesting hub dialogue.
@export var default_dialogue_tags: Array[String] = []

