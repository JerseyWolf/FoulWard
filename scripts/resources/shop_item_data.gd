## shop_item_data.gd
## Data resource representing a purchasable item in the between-mission shop in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name ShopItemData
extends Resource

## Unique identifier for this item. Passed in shop_item_purchased signal payload.
@export var item_id: String = ""
## Human-readable name shown in the shop UI.
@export var display_name: String = ""
## Gold cost to purchase this item.
@export var gold_cost: int = 50
## Building material cost to purchase this item. Usually 0 for shop items.
@export var material_cost: int = 0
## Effect description shown in the shop UI tooltip.
@export var description: String = ""

