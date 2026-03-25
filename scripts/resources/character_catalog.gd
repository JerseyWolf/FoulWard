## character_catalog.gd
## Resource holding the full set of hub characters for a between-mission hub.

extends Resource
class_name CharacterCatalog

## All hub characters instantiated by Hub2DHub.
@export var characters: Array[CharacterData] = []

