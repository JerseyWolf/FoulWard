## TODO: add before_test() isolation — see testing SKILL
## test_campaign_territory_mapping.gd
## Validates every DayConfig in the main 50-day campaign references a real territory.

class_name TestCampaignTerritoryMapping
extends GdUnitTestSuite

func test_day_config_has_valid_territory_id() -> void:
	var campaign: CampaignConfig = load(
		"res://resources/campaigns/campaign_main_50_days.tres"
	) as CampaignConfig
	assert_object(campaign).is_not_null()

	var territory_map: TerritoryMapData = load(
		campaign.territory_map_resource_path
	) as TerritoryMapData
	assert_object(territory_map).is_not_null()

	for day: DayConfig in campaign.day_configs:
		assert_str(day.territory_id).is_not_empty()
		assert_bool(territory_map.has_territory(day.territory_id)).is_true()
