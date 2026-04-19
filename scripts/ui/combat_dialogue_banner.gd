## combat_dialogue_banner.gd
## Shows a timed combat quip banner at the top of the screen during wave combat.
extends PanelContainer

@onready var _label: Label = $Label
@export var display_duration: float = 4.0 # TUNING

var _timer: float = 0.0
var _is_showing: bool = false


func _ready() -> void:
	visible = false
	if not SignalBus.combat_dialogue_requested.is_connected(_on_combat_dialogue_requested):
		SignalBus.combat_dialogue_requested.connect(_on_combat_dialogue_requested)


func _process(delta: float) -> void:
	if not _is_showing:
		return
	_timer -= delta
	if _timer <= 0.0:
		visible = false
		_is_showing = false


func _on_combat_dialogue_requested(entry: DialogueEntry) -> void:
	_label.text = entry.text
	_timer = display_duration
	_is_showing = true
	visible = true
