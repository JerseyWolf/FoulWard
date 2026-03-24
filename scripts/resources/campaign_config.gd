## campaign_config.gd
## Campaign-level configuration resource containing ordered DayConfig entries.

class_name CampaignConfig
extends Resource

## Stable campaign identifier.
@export var campaign_id: String = ""
## Human-friendly campaign name.
@export var display_name: String = ""
## Ordered day configurations (index 0 => day 1).
@export var day_configs: Array[DayConfig] = []
## If true, uses short_campaign_length when > 0.
@export var is_short_campaign: bool = false
## Overrides day_configs size when short mode is enabled.
@export var short_campaign_length: int = 0

## Returns the usable campaign length for CampaignManager.
func get_effective_length() -> int:
	if is_short_campaign and short_campaign_length > 0:
		return short_campaign_length
	return day_configs.size()
