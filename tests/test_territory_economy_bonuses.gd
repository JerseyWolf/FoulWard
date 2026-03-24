## test_territory_economy_bonuses.gd
## Aggregated territory gold modifiers vs EconomyManager.

class_name TestTerritoryEconomyBonuses
extends GdUnitTestSuite

var _saved_territory_map: TerritoryMapData = null


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	_saved_territory_map = GameManager.territory_map


func after_test() -> void:
	GameManager.territory_map = _saved_territory_map
	GameManager.reload_territory_map_from_active_campaign()


func test_controlled_territory_increases_end_of_day_gold() -> void:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap

	var heart: TerritoryData = tmap.get_territory_by_id("heartland_plains")
	assert_object(heart).is_not_null()
	heart.is_controlled_by_player = true
	heart.is_permanently_lost = false
	heart.bonus_flat_gold_end_of_day = 25
	heart.bonus_percent_gold_end_of_day = 0.0

	var modifiers: Dictionary = GameManager.get_current_territory_gold_modifiers()
	assert_int(int(modifiers.get("flat_gold_end_of_day", -1))).is_equal(25)

	var base_gold: int = 100
	var flat_bonus: int = int(modifiers.get("flat_gold_end_of_day", 0))
	var total: int = base_gold + flat_bonus
	EconomyManager.reset_to_defaults()
	EconomyManager.add_gold(total)
	assert_int(EconomyManager.get_gold()).is_equal(1000 + total)


func test_lost_territory_bonus_does_not_apply() -> void:
	var tmap: TerritoryMapData = load(
		"res://resources/territories/main_campaign_territories.tres"
	) as TerritoryMapData
	GameManager.territory_map = tmap

	var heart: TerritoryData = tmap.get_territory_by_id("heartland_plains")
	heart.is_controlled_by_player = false
	heart.is_permanently_lost = true
	heart.bonus_flat_gold_end_of_day = 99

	var modifiers: Dictionary = GameManager.get_current_territory_gold_modifiers()
	assert_int(int(modifiers.get("flat_gold_end_of_day", -1))).is_equal(0)
