## weapon_level_data.gd
## Defines the incremental stat bonuses and upgrade cost for one weapon level.
## One .tres instance exists per weapon per level (levels 1-3).
## Level 0 is implicit (base WeaponData, no bonus applied, no WeaponLevelData needed).
##
## Stat composition is ADDITIVE and INCREMENTAL:
##   effective_stat = base_stat + SUM(level_i.bonus for i in 1..current_level)
## Each entry represents the bonus ADDED at that specific level, not a total.
##
# SOURCE: Godot 4 custom Resource pattern — https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html [S1]
# SOURCE: Array[Resource] progression pattern — https://www.youtube.com/watch?v=h5vpjCDNa-w [S2]

class_name WeaponLevelData
extends Resource

## Which weapon slot this level applies to.
@export var weapon_slot: Types.WeaponSlot

## The level number (1, 2, or 3). Level 0 is implicit base — no WeaponLevelData needed.
@export var level: int = 0

## Incremental additive bonus to base damage at this level.
@export var damage_bonus: float = 0.0

## Incremental additive bonus to projectile speed at this level.
@export var speed_bonus: float = 0.0

## Incremental additive change to reload time at this level.
## Should be NEGATIVE to improve (reduce) reload time.
## Applied as: effective_reload = base_reload + SUM(all reload_bonus up to current level)
## Clamped to minimum 0.1 in WeaponUpgradeManager.get_effective_reload_time().
@export var reload_bonus: float = 0.0

## Incremental additive bonus to burst count at this level (0 = no change).
@export var burst_count_bonus: int = 0

## Gold cost to purchase THIS level upgrade. Paid when upgrading FROM (level-1) TO level.
@export var gold_cost: int = 0

## Building material cost for this upgrade. Currently always 0 (gold-only system).
## Reserved for future design use.
@export var material_cost: int = 0
