## TODO: add before_test() isolation — see testing SKILL
## test_territory_data.gd
## Loads main campaign territory map and validates placeholder content.

class_name TestTerritoryData
extends GdUnitTestSuite

func test_territory_map_contains_expected_territories() -> void:
	var map: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	assert_object(map).is_not_null()

	var ids: Array[String] = []
	for t: TerritoryData in map.get_all_territories():
		if t != null:
			ids.append(t.territory_id)

	assert_bool(ids.has("heartland_plains")).is_true()
	assert_bool(ids.has("blackwood_forest")).is_true()
	assert_bool(ids.has("ashen_swamp")).is_true()
	assert_bool(ids.has("iron_ridge")).is_true()
	assert_bool(ids.has("outer_city")).is_true()

	var heart: TerritoryData = map.get_territory_by_id("heartland_plains")
	assert_object(heart).is_not_null()
	assert_bool(heart.is_controlled_by_player).is_true()
	assert_bool(heart.is_permanently_lost).is_false()
