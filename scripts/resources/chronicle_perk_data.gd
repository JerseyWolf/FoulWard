## ChroniclePerkData — one meta perk granted by a Chronicle entry.
class_name ChroniclePerkData
extends Resource

@export var perk_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var effect_type: Types.ChroniclePerkEffectType = Types.ChroniclePerkEffectType.STARTING_GOLD
@export var effect_value: float = 0.0
