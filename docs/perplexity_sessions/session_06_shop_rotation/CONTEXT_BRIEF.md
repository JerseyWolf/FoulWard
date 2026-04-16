# Context Brief — Session 6: Shop Rotation

## Economy (§18)

EXISTS IN CODE. Three currencies: gold (starting 1000), building_material (starting 50), research_material (starting 0).

Duplicate cost scaling: linear per BuildingData.building_id. Sell refund: sell_refund_fraction x sell_refund_global_multiplier.

## EconomyManager API (§3.5, relevant methods only)

| Signature | Returns | Usage |
|-----------|---------|-------|
| add_gold(amount: int) -> void | void | Adds gold |
| spend_gold(amount: int) -> bool | bool | Spends if affordable |
| can_afford_building(building_data: BuildingData) -> bool | bool | Check affordability |
| get_gold() -> int | int | Current gold |
| get_building_material() -> int | int | Current BM |
| get_research_material() -> int | int | Current RM |
| reset_to_defaults() -> void | void | Resets to starting values |

## Shop (§19)

EXISTS IN CODE (basic).

4 items: tower_repair, building_repair, arrow_tower (voucher), mana_draught.

PLANNED: Shop inventory rotation.

## ShopManager API (§4.4)

| Signature | Returns | Usage |
|-----------|---------|-------|
| get_shop_items() -> Array[ShopItemData] | Array | Current catalog |
| purchase_item(item_id: String) -> bool | bool | Spends gold, applies effect |

## SimBot and Testing (§23)

- SimBot — headless simulation: run_balance_sweep, run_batch, run_single.
- Loadouts: balanced, summoner_heavy, artillery_air.
- CombatStatsTracker writes wave/building CSVs.

## Shop Signal (§24)
| Signal | Parameters |
|--------|-----------|
| shop_item_purchased | item_id: String |

## Open TBD — Shop (§33)
| Item | Question | Who Decides |
|------|----------|-------------|
| Shop rotation count | How many items shown per day? | Designer |

Decision for this session: 4-6 items per day from a pool of 12-15.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- push_warning() not assert() in production
