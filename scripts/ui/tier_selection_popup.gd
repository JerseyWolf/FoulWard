## tier_selection_popup.gd
## Popup that lets the player choose a difficulty tier when replaying a controlled territory.
## Nightmare is gated: only available when the territory's highest_cleared_tier >= VETERAN.
## Requires: Types.DifficultyTier, GameManager.set_active_tier (Chat 4A steps 1 + 5),
##           TerritoryData.highest_cleared_tier (Chat 4A step 3).

extends Control

@onready var _title_label: Label = get_node_or_null("Panel/TitleLabel") as Label
@onready var _normal_button: Button = get_node_or_null("Panel/NormalButton") as Button
@onready var _veteran_button: Button = get_node_or_null("Panel/VeteranButton") as Button
@onready var _nightmare_button: Button = get_node_or_null("Panel/NightmareButton") as Button
@onready var _close_button: Button = get_node_or_null("Panel/CloseButton") as Button

var _pending_territory_id: String = ""


func _ready() -> void:
	hide()
	if not SignalBus.territory_selected_for_replay.is_connected(_on_territory_selected):
		SignalBus.territory_selected_for_replay.connect(_on_territory_selected)
	if _normal_button != null:
		_normal_button.pressed.connect(_on_normal_pressed)
	if _veteran_button != null:
		_veteran_button.pressed.connect(_on_veteran_pressed)
	if _nightmare_button != null:
		_nightmare_button.pressed.connect(_on_nightmare_pressed)
	if _close_button != null:
		_close_button.pressed.connect(_on_close_pressed)


func _on_territory_selected(territory_id: String) -> void:
	_pending_territory_id = territory_id
	var territory: TerritoryData = GameManager.get_territory_data(territory_id)
	if _title_label != null:
		_title_label.text = "Choose Difficulty"
	if _nightmare_button != null:
		var nightmare_locked: bool = true
		if territory != null:
			nightmare_locked = territory.highest_cleared_tier < Types.DifficultyTier.VETERAN
		_nightmare_button.disabled = nightmare_locked
	show()


func _on_normal_pressed() -> void:
	GameManager.set_active_tier(Types.DifficultyTier.NORMAL)
	hide()


func _on_veteran_pressed() -> void:
	GameManager.set_active_tier(Types.DifficultyTier.VETERAN)
	hide()


func _on_nightmare_pressed() -> void:
	var territory: TerritoryData = GameManager.get_territory_data(_pending_territory_id)
	if territory != null and territory.highest_cleared_tier < Types.DifficultyTier.VETERAN:
		push_warning(
			"TierSelectionPopup: Nightmare locked — VETERAN not cleared for '%s'."
			% _pending_territory_id
		)
		return
	GameManager.set_active_tier(Types.DifficultyTier.NIGHTMARE)
	hide()


func _on_close_pressed() -> void:
	hide()
