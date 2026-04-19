## One row in the Chronicle achievement list.
extends HBoxContainer

@onready var _name_label: Label = $NameLabel
@onready var _progress_bar: ProgressBar = $ProgressBar
@onready var _reward_label: Label = $RewardLabel


func setup(entry_data: Resource, progress: int, completed: bool) -> void:
	if entry_data == null:
		return
	var tgt: int = maxi(1, int(entry_data.target_count))
	_progress_bar.max_value = float(tgt)
	if completed:
		_progress_bar.value = float(tgt)
		_name_label.text = "%s (Done)" % String(entry_data.display_name)
	else:
		_progress_bar.value = float(clampi(progress, 0, tgt))
		_name_label.text = String(entry_data.display_name)
	var reward_text: String = ChronicleManager.get_perk_display_name(String(entry_data.reward_id))
	if reward_text.is_empty():
		_reward_label.text = ""
	else:
		_reward_label.text = "Reward: %s" % reward_text
