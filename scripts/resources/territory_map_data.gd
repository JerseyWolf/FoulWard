## territory_map_data.gd
## Campaign territory list with O(1) lookup by territory_id.
## SOURCE: FOUL WARD Prompt 8 spec.

class_name TerritoryMapData
extends Resource

## All territories in this map (order is display order; IDs must be unique).
@export var territories: Array[TerritoryData] = []

var _id_to_territory: Dictionary = {}
var _id_to_index: Dictionary = {}
var _cache_built: bool = false


func _ensure_cache_built() -> void:
	if _cache_built:
		return
	_id_to_territory.clear()
	_id_to_index.clear()
	for i: int in territories.size():
		var territory: TerritoryData = territories[i]
		if territory == null:
			continue
		if territory.territory_id == "":
			continue
		# ASSUMPTION: IDs unique within the campaign. Ignore duplicates after first.
		if not _id_to_territory.has(territory.territory_id):
			_id_to_territory[territory.territory_id] = territory
			_id_to_index[territory.territory_id] = i
	_cache_built = true


## Clears lookup cache after external edits to the territories array (e.g. tests).
func invalidate_cache() -> void:
	_cache_built = false


## Returns the TerritoryData with the matching territory_id, or null if not found.
func get_territory_by_id(id: String) -> TerritoryData:
	_ensure_cache_built()
	if not _id_to_territory.has(id):
		return null
	return _id_to_territory[id] as TerritoryData


## Returns true if a territory with the given id exists in the map.
func has_territory(id: String) -> bool:
	_ensure_cache_built()
	return _id_to_territory.has(id)


## Returns all TerritoryData entries in this map.
func get_all_territories() -> Array[TerritoryData]:
	return territories.duplicate()


## Returns the array index of the territory with the given id, or -1 if not found.
func get_index_by_id(id: String) -> int:
	_ensure_cache_built()
	if not _id_to_index.has(id):
		return -1
	return int(_id_to_index[id])
