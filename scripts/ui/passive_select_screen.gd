## PassiveSelectScreen — Mission flow UI for choosing one Sybil passive before combat.
extends Control

@onready var _cards_row: HBoxContainer = $Panel/VBoxContainer/CardsRow


func _ready() -> void:
	if not SignalBus.sybil_passives_offered.is_connected(_on_passives_offered):
		SignalBus.sybil_passives_offered.connect(_on_passives_offered)
	hide()


func _on_passives_offered(passive_ids: Array) -> void:
	for child: Node in _cards_row.get_children():
		child.queue_free()
	for id_v: Variant in passive_ids:
		var pid: String = id_v as String if id_v is String else str(id_v)
		var data: Resource = SybilPassiveManager.get_passive_data_by_id(pid)
		if data == null:
			continue
		var card: Panel = Panel.new()
		card.custom_minimum_size = Vector2(180.0, 220.0)
		var vbox: VBoxContainer = VBoxContainer.new()
		card.add_child(vbox)
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		var name_lbl: Label = Label.new()
		name_lbl.text = str(data.get("display_name"))
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(name_lbl)
		var desc_lbl: Label = Label.new()
		desc_lbl.text = str(data.get("description"))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(desc_lbl)
		var btn: Button = Button.new()
		btn.text = "Select"
		var captured_id: String = str(data.get("passive_id"))
		btn.pressed.connect(func() -> void:
			SybilPassiveManager.select_passive(captured_id)
			GameManager.exit_passive_select()
		)
		vbox.add_child(btn)
		_cards_row.add_child(card)


func _exit_tree() -> void:
	if SignalBus.sybil_passives_offered.is_connected(_on_passives_offered):
		SignalBus.sybil_passives_offered.disconnect(_on_passives_offered)
