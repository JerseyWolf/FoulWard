## mission_economy_data.gd
## Passive income, wave clear rewards, leak penalties, and duplicate scaling knobs for a mission.
## Pair with MissionWavesData only when needed: both can carry starting_*; loaders should
## pick one source of truth (typically MissionEconomyData for active mission economy).

class_name MissionEconomyData
extends Resource

@export var mission_id: String = "standard_economy"

@export var starting_gold: int = 400
@export var starting_material: int = 20

@export var passive_gold_per_sec: float = 0.0
@export var passive_material_per_sec: float = 0.0

# Wave clear rewards (applied when a wave completes; see EconomyManager / SignalBus.wave_cleared).
## Flat bonus per wave clear while this mission economy is active (wave index is 1-based; see `EconomyManager.get_wave_reward_*`).
@export var wave_clear_bonus_gold: int = 25
@export var wave_clear_bonus_material: int = 5

# Leak penalties (enemy reached core / Florence — wired when mission economy consumes these).
@export var leak_penalty_gold: int = 15
@export var leak_penalty_material: int = 0

## Multiplies per-building `BuildingData.sell_refund_fraction` when applying refunds.
@export var sell_refund_global_multiplier: float = 1.0

## Overrides duplicate cost linear coefficient; use [code]-1.0[/code] for "no override" (default gameplay curve).
@export var duplicate_cost_k_override: float = -1.0

@export var tags: PackedStringArray = PackedStringArray()


func collect_validation_warnings() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	if mission_id.is_empty():
		out.append("mission_id is empty")
	if sell_refund_global_multiplier < 0.0:
		out.append("sell_refund_global_multiplier is negative")
	if duplicate_cost_k_override < -1.0:
		out.append("duplicate_cost_k_override should be >= -1.0 (use -1 for no override)")
	return out
