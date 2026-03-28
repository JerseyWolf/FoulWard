## mercenary_catalog.gd
## Pool of mercenary offers with day filtering and a daily cap.
# SOURCE: Pattern adapted from long-campaign mercenary pools (Battle Brothers style, day-range gating).

extends Resource
class_name MercenaryCatalog

# DEVIATION: untyped `Array` so autoloads parse before `MercenaryOfferData` global class is registered.
## Pool of MercenaryOfferData resources available for random daily sampling.
@export var offers: Array = []
## Maximum number of offers shown to the player per day.
@export var max_offers_per_day: int = 3 # TUNING


## Returns all offers eligible for the given day excluding already-owned allies.
func filter_offers_for_day(day: int, owned_ally_ids: Array[String]) -> Array:
	var result: Array = []
	for offer: Variant in offers:
		if offer == null:
			continue
		if bool(offer.get("is_defection_offer")):
			continue
		if not bool(offer.call("is_available_on_day", day)):
			continue
		if owned_ally_ids.has(str(offer.get("ally_id"))):
			continue
		result.append(offer)

	result.sort_custom(func(a: Variant, b: Variant) -> bool:
		return str(a.get("ally_id")) < str(b.get("ally_id"))
	)
	return result


## Returns a randomly sampled subset of eligible offers for the given day.
func get_daily_offers(day: int, owned_ally_ids: Array[String]) -> Array:
	var filtered: Array = filter_offers_for_day(day, owned_ally_ids)
	if filtered.size() <= max_offers_per_day:
		return filtered
	return filtered.slice(0, max_offers_per_day)
