# ui/hud.gd
# HUD — pure display. Never modifies game state.
# Uses _process (never _physics_process) to stay responsive at
# Engine.time_scale = 0.1 (build mode).
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — HUD class responsibilities.

class_name HUD
extends Control

@onready var _gold_label: Label = $ResourceDisplay/GoldLabel
@onready var _material_label: Label = $ResourceDisplay/MaterialLabel
@onready var _research_label: Label = $ResourceDisplay/ResearchLabel
@onready var _wave_label: Label = $WaveDisplay/WaveLabel
@onready var _countdown_label: Label = $WaveDisplay/CountdownLabel
@onready var _tower_hp_bar: ProgressBar = $TowerHPBar
@onready var _mana_bar: ProgressBar = $SpellPanel/ManaBar
@onready var _cooldown_label: Label = $SpellPanel/CooldownLabel
@onready var _crossbow_label: Label = $WeaponPanel/CrossbowLabel
@onready var _missile_label: Label = $WeaponPanel/MissileLabel
@onready var _build_mode_hint: Label = $BuildModeHint

var _countdown_seconds: float = 0.0
var _is_counting_down: bool = false

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.resource_changed.connect(_on_resource_changed)
	SignalBus.wave_countdown_started.connect(_on_wave_countdown_started)
	SignalBus.wave_started.connect(_on_wave_started)
	SignalBus.tower_damaged.connect(_on_tower_damaged)
	SignalBus.mana_changed.connect(_on_mana_changed)
	SignalBus.spell_cast.connect(_on_spell_cast)
	SignalBus.spell_ready.connect(_on_spell_ready)
	SignalBus.build_mode_entered.connect(_on_build_mode_entered)
	SignalBus.build_mode_exited.connect(_on_build_mode_exited)

	_build_mode_hint.hide()
	_countdown_label.hide()

	_gold_label.text = "Gold: %d" % EconomyManager.get_gold()
	_material_label.text = "Mat: %d" % EconomyManager.get_building_material()
	_research_label.text = "Res: %d" % EconomyManager.get_research_material()


# _process fires every render frame regardless of Engine.time_scale.
func _process(delta: float) -> void:
	if _is_counting_down:
		_countdown_seconds -= delta
		if _countdown_seconds < 0.0:
			_countdown_seconds = 0.0
			_is_counting_down = false
		_countdown_label.text = "%.0f" % _countdown_seconds

# ── Signal handlers ───────────────────────────────────────────────────────

func _on_resource_changed(resource_type: Types.ResourceType, new_amount: int) -> void:
	match resource_type:
		Types.ResourceType.GOLD:
			_gold_label.text = "Gold: %d" % new_amount
		Types.ResourceType.BUILDING_MATERIAL:
			_material_label.text = "Mat: %d" % new_amount
		Types.ResourceType.RESEARCH_MATERIAL:
			_research_label.text = "Res: %d" % new_amount


func _on_wave_countdown_started(wave_number: int, seconds_remaining: float) -> void:
	_wave_label.text = "WAVE %d / %d INCOMING" % [
		wave_number,
		GameManager.WAVES_PER_MISSION
	]
	_countdown_seconds = seconds_remaining
	_is_counting_down = true
	_countdown_label.show()


func _on_wave_started(wave_number: int, _enemy_count: int) -> void:
	_wave_label.text = "Wave %d / %d" % [
		wave_number,
		GameManager.WAVES_PER_MISSION
	]
	_is_counting_down = false
	_countdown_label.hide()


func _on_tower_damaged(current_hp: int, max_hp: int) -> void:
	_tower_hp_bar.max_value = float(max_hp)
	_tower_hp_bar.value = float(current_hp)


func _on_mana_changed(current_mana: int, max_mana: int) -> void:
	_mana_bar.max_value = float(max_mana)
	_mana_bar.value = float(current_mana)


func _on_spell_cast(_spell_id: String) -> void:
	_cooldown_label.text = "Shockwave: ON COOLDOWN"


func _on_spell_ready(_spell_id: String) -> void:
	_cooldown_label.text = "Shockwave: READY"


func _on_build_mode_entered() -> void:
	_build_mode_hint.show()


func _on_build_mode_exited() -> void:
	_build_mode_hint.hide()


## Updates weapon readiness display.
## POST-MVP: connect to dedicated weapon_ready / weapon_reloading signals.
func update_weapon_display(
		crossbow_ready: bool,
		missile_ready: bool
) -> void:
	_crossbow_label.text = "Crossbow: %s" % ("READY" if crossbow_ready else "RELOADING")
	_missile_label.text = "Missile: %s" % ("READY" if missile_ready else "RELOADING")

