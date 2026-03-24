## test_campaign_territory_updates.gd
## GameManager.apply_day_result_to_territory ownership and SignalBus emission.

class_name TestCampaignTerritoryUpdates
extends GdUnitTestSuite

var _saved_territory_map: TerritoryMapData = null


func before_test() -> void:
	_saved_territory_map = GameManager.territory_map


func after_test() -> void:
	GameManager.territory_map = _saved_territory_map
	if GameManager.territory_map != null:
		GameManager.territory_map.invalidate_cache()
	GameManager.reload_territory_map_from_active_campaign()


func test_winning_day_marks_territory_controlled() -> void:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap

	var day_config: DayConfig = DayConfig.new()
	day_config.territory_id = "blackwood_forest"

	var territory: TerritoryData = tmap.get_territory_by_id("blackwood_forest")
	assert_object(territory).is_not_null()
	territory.is_controlled_by_player = false
	territory.is_permanently_lost = false

	var monitor := monitor_signals(SignalBus, false)
	GameManager.apply_day_result_to_territory(day_config, true)

	assert_bool(territory.is_controlled_by_player).is_true()
	assert_bool(territory.is_permanently_lost).is_false()
	await assert_signal(monitor).is_emitted("territory_state_changed", ["blackwood_forest"])


func test_losing_day_marks_territory_lost() -> void:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap

	var day_config: DayConfig = DayConfig.new()
	day_config.territory_id = "blackwood_forest"

	var territory: TerritoryData = tmap.get_territory_by_id("blackwood_forest")
	territory.is_controlled_by_player = true
	territory.is_permanently_lost = false

	var monitor := monitor_signals(SignalBus, false)
	GameManager.apply_day_result_to_territory(day_config, false)

	assert_bool(territory.is_controlled_by_player).is_false()
	assert_bool(territory.is_permanently_lost).is_true()
	await assert_signal(monitor).is_emitted("territory_state_changed", ["blackwood_forest"])
