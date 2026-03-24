## campaign_manager.gd
## Campaign/day-level state controller above GameManager mission flow.
## Owns campaign progress and DayConfig lookup.

extends Node

const DEFAULT_SHORT_CAMPAIGN: CampaignConfig = preload("res://resources/campaigns/campaign_short_5_days.tres")

var current_day: int = 1
var campaign_length: int = 0
var campaign_id: String = ""
var campaign_completed: bool = false
var failed_attempts_on_current_day: int = 0
var current_day_config: DayConfig = null
var campaign_config: CampaignConfig = null

## Assign the active campaign from the inspector.
## Default should be campaign_short_5_days.tres.
@export var active_campaign_config: CampaignConfig

func _ready() -> void:
	SignalBus.mission_won.connect(_on_mission_won)
	SignalBus.mission_failed.connect(_on_mission_failed)
	if active_campaign_config == null:
		active_campaign_config = DEFAULT_SHORT_CAMPAIGN
	if active_campaign_config != null:
		_set_campaign_config(active_campaign_config)

func start_new_campaign() -> void:
	if active_campaign_config != null and campaign_config != active_campaign_config:
		_set_campaign_config(active_campaign_config)

	current_day = 1
	failed_attempts_on_current_day = 0
	campaign_completed = false

	if campaign_config != null:
		campaign_length = campaign_config.get_effective_length()

	SignalBus.campaign_started.emit(campaign_id)
	_start_current_day_internal()

func start_next_day() -> void:
	_start_current_day_internal()

func get_current_day() -> int:
	return current_day

func get_campaign_length() -> int:
	return campaign_length

func get_current_day_config() -> DayConfig:
	return current_day_config

func _set_campaign_config(config: CampaignConfig) -> void:
	campaign_config = config
	if campaign_config != null:
		campaign_length = campaign_config.get_effective_length()
		campaign_id = campaign_config.campaign_id
	else:
		campaign_length = 0
		campaign_id = ""

func _start_current_day_internal() -> void:
	if campaign_config == null:
		return
	if current_day < 1 or current_day > campaign_length:
		return

	var idx: int = current_day - 1
	if idx >= 0 and idx < campaign_config.day_configs.size():
		current_day_config = campaign_config.day_configs[idx]
	else:
		current_day_config = null
		return

	SignalBus.day_started.emit(current_day)
	# DEVIATION: GameManager now receives DayConfig to configure mission start.
	GameManager.start_mission_for_day(current_day, current_day_config)

func _on_mission_won(mission_number: int) -> void:
	# ASSUMPTION: mission_number == current_day in short-campaign MVP.
	if mission_number != current_day:
		return

	failed_attempts_on_current_day = 0
	var finished_day: int = current_day
	SignalBus.day_won.emit(finished_day)
	current_day += 1

	if current_day > campaign_length and campaign_length > 0:
		campaign_completed = true
		SignalBus.campaign_completed.emit(campaign_id)
		# POST-MVP: save + meta-progression hooks.

func _on_mission_failed(mission_number: int) -> void:
	# ASSUMPTION: mission_number == current_day in short-campaign MVP.
	if mission_number != current_day:
		return

	failed_attempts_on_current_day += 1
	SignalBus.day_failed.emit(current_day)

# ─── TEST-ONLY helpers ────────────────────────────────────────────────────────
# These methods exist solely to allow GdUnit4 tests to inject configurations
# without reaching into private internals.
# Do NOT call these from any gameplay path.

func set_active_campaign_config_for_test(config: CampaignConfig) -> void:
	# TEST-ONLY: swaps the active campaign config and refreshes derived state.
	active_campaign_config = config
	_set_campaign_config(config)
