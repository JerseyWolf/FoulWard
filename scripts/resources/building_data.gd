## building_data.gd
## Data resource describing stats for a single building type in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

class_name BuildingData
extends Resource

## Which building type this resource describes.
@export var building_type: Types.BuildingType
## Human-readable name shown in the build menu.
@export var display_name: String = ""
## Gold cost to place this building.
@export var gold_cost: int = 50
## Building material cost to place this building.
@export var material_cost: int = 2
## Gold cost to upgrade this building.
@export var upgrade_gold_cost: int = 75
## Building material cost to upgrade this building.
@export var upgrade_material_cost: int = 3
## Base damage per shot.
@export var damage: float = 20.0
## Damage per shot after upgrade.
@export var upgraded_damage: float = 35.0
## Shots per second.
@export var fire_rate: float = 1.0
## Attack range in world units.
@export var attack_range: float = 15.0
## Attack range after upgrade.
@export var upgraded_range: float = 18.0
## Damage type this building's projectiles deal.
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
## True if this building's targeting includes flying enemies.
@export var targets_air: bool = false
## True if this building's targeting includes ground enemies.
@export var targets_ground: bool = true
## True if a research node must be unlocked before this building is placeable.
@export var is_locked: bool = false
## ID of the research node that unlocks this building. Empty string = always available.
@export var unlock_research_id: String = ""
## MVP cube color for this building type.
@export var color: Color = Color.GRAY
## Targeting strategy this building uses to select its next attack target.
@export var target_priority: Types.TargetPriority = Types.TargetPriority.CLOSEST

