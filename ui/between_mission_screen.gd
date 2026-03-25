# ui/between_mission_screen.gd
# BetweenMissionScreen — Shop, Research, Buildings tabs + Next Mission button.
# Zero game logic. All decisions delegated to ShopManager, ResearchManager,
# HexGrid, and GameManager.
#
# Credit: Foul Ward ARCHITECTURE.md §3.4 — BetweenMissionScreen class responsibilities.

class_name BetweenMissionScreen
extends Control

@onready var _next_mission_btn: Button = $NextMissionButton
@onready var _day_progress_label: Label = $DayProgressLabel
@onready var _day_name_label: Label = $DayNameLabel

@onready var _shop_list: VBoxContainer = $TabContainer/ShopTab/ShopList
@onready var _research_list: VBoxContainer = $TabContainer/ResearchTab/ResearchList
@onready var _buildings_list: VBoxContainer = $TabContainer/BuildingsTab/BuildingsList
@onready var _offers_list: VBoxContainer = $TabContainer/MercenariesTab/OffersSection/OffersList
@onready var _roster_list: VBoxContainer = $TabContainer/MercenariesTab/RosterSection/RosterList
@onready var _active_cap_label: Label = $TabContainer/MercenariesTab/RosterSection/CapLabel
@onready var _weapons_tab: Control = $TabContainer/WeaponsTab
@onready var _crossbow_enchant_label: Label = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/EnchantmentLabel
@onready var _rapid_enchant_label: Label = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/EnchantmentLabel

@onready var _tab_container: TabContainer = $TabContainer # ASSUMPTION: TabContainer node exists at root.

@onready var _crossbow_elemental_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/ApplyElementalButton
@onready var _crossbow_power_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/ApplyPowerButton
@onready var _crossbow_remove_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/RemoveAllButton

@onready var _rapid_elemental_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/ApplyElementalButton
@onready var _rapid_power_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/ApplyPowerButton
@onready var _rapid_remove_button: Button = $TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/RemoveAllButton

@onready var _shop_manager: ShopManager = get_node(
	"/root/Main/Managers/ShopManager"
)
@onready var _research_manager: ResearchManager = get_node(
	"/root/Main/Managers/ResearchManager"
)
@onready var _hex_grid: HexGrid = get_node("/root/Main/HexGrid")
@onready var _ui_manager: UIManager = get_node("/root/Main/UI/UIManager")
var _weapon_upgrade_manager: Node = null

# ─────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SignalBus.game_state_changed.connect(_on_game_state_changed)
	_next_mission_btn.pressed.connect(_on_next_mission_pressed)
	_weapon_upgrade_manager = get_node_or_null("/root/Main/Managers/WeaponUpgradeManager")
	SignalBus.weapon_upgraded.connect(_on_weapon_upgraded)
	SignalBus.resource_changed.connect(_on_resource_changed_weapons)
	SignalBus.enchantment_applied.connect(_on_enchantment_applied)
	SignalBus.enchantment_removed.connect(_on_enchantment_removed)
	SignalBus.mercenary_offer_generated.connect(_refresh_offers)
	SignalBus.ally_roster_changed.connect(_refresh_roster)
	SignalBus.mercenary_recruited.connect(_on_mercenary_recruited)
	_refresh_weapons_tab()
	_refresh_day_info()


func _on_game_state_changed(
		_old: Types.GameState,
		new_state: Types.GameState
) -> void:
	if new_state == Types.GameState.BETWEEN_MISSIONS:
		_refresh_all()
		_show_hub_dialogue()


func open_shop_panel() -> void:
	if _tab_container == null:
		return
	# ASSUMPTION (from between_mission_screen.tscn):
	# MapTab=0, ShopTab=1.
	_tab_container.current_tab = 1


func open_research_panel() -> void:
	if _tab_container == null:
		return
	# ASSUMPTION (from between_mission_screen.tscn): ResearchTab index=2.
	_tab_container.current_tab = 2


func open_enchant_panel() -> void:
	if _tab_container == null:
		return
	# DEVIATION: No Enchant tab exists in current MVP scene. Route to ResearchTab.
	_tab_container.current_tab = 2


func open_mercenary_panel() -> void:
	if _tab_container == null:
		return
	# DEVIATION: Current MVP scene has a Mercenaries tab already (MercenariesTab index=4).
	_tab_container.current_tab = 4


func _show_hub_dialogue() -> void:
	_ui_manager.show_dialogue_for_character("SPELL_RESEARCHER")
	_ui_manager.show_dialogue_for_character("COMPANION_MELEE")
	# POST-MVP: Add Florence, Merchant, etc. as additional calls.


func _refresh_all() -> void:
	_refresh_shop()
	_refresh_research()
	_refresh_buildings()
	_refresh_mercenaries_tab()
	_refresh_weapons_tab()
	_refresh_day_info()


func _refresh_mercenaries_tab() -> void:
	_refresh_offers("")
	_refresh_roster()


func _refresh_offers(_ally_id: String) -> void:
	for child: Node in _offers_list.get_children():
		child.queue_free()
	var offers: Array = CampaignManager.get_current_offers()
	for offer: Variant in offers:
		if offer == null:
			continue
		var aid: String = str(offer.get("ally_id"))
		var ad: Resource = CampaignManager.get_ally_data(aid)
		var display_name: String = aid if ad == null else str(ad.get("display_name"))
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s [%s]" % [display_name, str(offer.call("get_cost_summary"))]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Recruit"
		var can_afford: bool = (
				EconomyManager.get_gold() >= int(offer.get("cost_gold"))
				and EconomyManager.get_building_material() >= int(offer.get("cost_building_material"))
				and EconomyManager.get_research_material() >= int(offer.get("cost_research_material"))
		)
		btn.disabled = not can_afford
		var captured_ally_id: String = aid
		btn.pressed.connect(func() -> void:
			var offers_now: Array = CampaignManager.get_current_offers()
			var purchase_i: int = -1
			for j: int in range(offers_now.size()):
				var o: Variant = offers_now[j]
				if o != null and str(o.get("ally_id")) == captured_ally_id:
					purchase_i = j
					break
			if purchase_i >= 0:
				CampaignManager.purchase_mercenary_offer(purchase_i)
			_refresh_mercenaries_tab()
		)
		row.add_child(lbl)
		row.add_child(btn)
		_offers_list.add_child(row)


func _refresh_roster() -> void:
	for child: Node in _roster_list.get_children():
		child.queue_free()
	var active_allies: Array[String] = CampaignManager.get_active_allies()
	var cap: int = CampaignManager.max_active_allies_per_day
	if is_instance_valid(_active_cap_label):
		_active_cap_label.text = "Active: %d / %d" % [active_allies.size(), cap]
	for ally_id: String in CampaignManager.get_owned_allies():
		var data: Resource = CampaignManager.get_ally_data(ally_id)
		var dname: String = ally_id if data == null else str(data.get("display_name"))
		var row2: HBoxContainer = HBoxContainer.new()
		var lbl2: Label = Label.new()
		lbl2.text = dname
		lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tbtn: Button = Button.new()
		var is_active: bool = active_allies.has(ally_id)
		tbtn.text = "Active" if is_active else "Standby"
		var captured_aid: String = ally_id
		tbtn.pressed.connect(func() -> void:
			CampaignManager.toggle_ally_active(captured_aid)
			_refresh_mercenaries_tab()
		)
		row2.add_child(lbl2)
		row2.add_child(tbtn)
		_roster_list.add_child(row2)


func _on_mercenary_recruited(_ally_id: String) -> void:
	_refresh_mercenaries_tab()

func _refresh_day_info() -> void:
	var cur: int = CampaignManager.get_current_day()
	var len: int = CampaignManager.get_campaign_length()
	var cfg: DayConfig = CampaignManager.get_current_day_config()

	if is_instance_valid(_day_progress_label):
		_day_progress_label.text = "Day %d / %d" % [cur, maxi(len, 1)]

	if is_instance_valid(_day_name_label):
		if cfg != null:
			_day_name_label.text = "Day %d - %s" % [cfg.day_index, cfg.display_name]
		else:
			_day_name_label.text = "Day %d" % cur


func _refresh_shop() -> void:
	for child: Node in _shop_list.get_children():
		child.queue_free()

	var items: Array[ShopItemData] = _shop_manager.get_available_items()
	for item: ShopItemData in items:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		var price_text: String = "%s — %dg" % [item.display_name, item.gold_cost]
		if item.material_cost > 0:
			price_text = "%s — %dg + %dm" % [
				item.display_name, item.gold_cost, item.material_cost
			]
		lbl.text = price_text
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Buy"
		btn.disabled = not _shop_manager.can_purchase(item.item_id)
		var captured_id: String = item.item_id
		btn.pressed.connect(func() -> void: _on_shop_buy_pressed(captured_id))
		row.add_child(lbl)
		row.add_child(btn)
		_shop_list.add_child(row)


func _refresh_research() -> void:
	for child: Node in _research_list.get_children():
		child.queue_free()

	var nodes: Array[ResearchNodeData] = _research_manager.get_available_nodes()
	for node_data: ResearchNodeData in nodes:
		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s — %d res" % [node_data.display_name, node_data.research_cost]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn: Button = Button.new()
		btn.text = "Unlock"
		btn.disabled = (
			EconomyManager.get_research_material() < node_data.research_cost
		)
		var captured_id: String = node_data.node_id
		btn.pressed.connect(func() -> void: _on_research_unlock_pressed(captured_id))
		row.add_child(lbl)
		row.add_child(btn)
		_research_list.add_child(row)


func _refresh_buildings() -> void:
	for child: Node in _buildings_list.get_children():
		child.queue_free()

	var occupied: Array[int] = _hex_grid.get_all_occupied_slots()
	if occupied.is_empty():
		var lbl: Label = Label.new()
		lbl.text = "No buildings placed."
		_buildings_list.add_child(lbl)
		return

	for slot_index: int in occupied:
		var slot_data: Dictionary = _hex_grid.get_slot_data(slot_index)
		var building: BuildingBase = slot_data.get("building", null)
		if building == null:
			continue
		var bd: BuildingData = building.get_building_data()
		var lbl: Label = Label.new()
		lbl.text = "Slot %d: %s%s" % [
			slot_index,
			bd.display_name,
			" (Upgraded)" if building.is_upgraded else ""
		]
		_buildings_list.add_child(lbl)


func _on_shop_buy_pressed(item_id: String) -> void:
	_shop_manager.purchase_item(item_id)
	_refresh_shop()


func _on_research_unlock_pressed(node_id: String) -> void:
	_research_manager.unlock_node(node_id)
	_refresh_research()


func _on_next_mission_pressed() -> void:
	# DEVIATION: BetweenMissionScreen now routes through CampaignManager.
	CampaignManager.start_next_day()


## Refreshes the entire Weapons tab display. Called on show and after any upgrade.
func _refresh_weapons_tab() -> void:
	if _weapon_upgrade_manager != null:
		_refresh_weapon_panel(Types.WeaponSlot.CROSSBOW)
		_refresh_weapon_panel(Types.WeaponSlot.RAPID_MISSILE)
	_refresh_weapon_enchantments()


## Refreshes the display panel for a single weapon slot.
# SOURCE: UI-as-thin-presenter pattern — [S5]
func _refresh_weapon_panel(slot: Types.WeaponSlot) -> void:
	var current_level: int = _weapon_upgrade_manager.get_current_level(slot)
	var max_level: int = _weapon_upgrade_manager.get_max_level()
	var next_data: WeaponLevelData = _weapon_upgrade_manager.get_next_level_data(slot)
	var at_max: bool = current_level >= max_level

	var panel_name: String = "CrossbowPanel" if slot == Types.WeaponSlot.CROSSBOW else "RapidMissilePanel"
	var panel: Control = _weapons_tab.get_node_or_null("VBoxContainer/%s" % panel_name)
	if panel == null:
		push_warning("BetweenMissionScreen._refresh_weapon_panel: %s not found" % panel_name)
		return

	var level_label: Label = panel.get_node_or_null("LevelLabel")
	if level_label:
		level_label.text = "Level %d / %d" % [current_level, max_level]

	var stats_label: Label = panel.get_node_or_null("StatsLabel")
	if stats_label:
		stats_label.text = _build_stats_text(slot)

	var preview_label: Label = panel.get_node_or_null("PreviewLabel")
	if preview_label:
		if at_max:
			preview_label.text = ""
		elif next_data != null:
			preview_label.text = _build_preview_text(slot, next_data)

	var cost_label: Label = panel.get_node_or_null("CostLabel")
	if cost_label:
		if at_max:
			cost_label.text = ""
		elif next_data != null:
			cost_label.text = "Cost: %d gold" % next_data.gold_cost

	var upgrade_button: Button = panel.get_node_or_null("UpgradeButton")
	if upgrade_button:
		if at_max:
			upgrade_button.text = "MAX LEVEL"
			upgrade_button.disabled = true
		else:
			upgrade_button.text = "Upgrade"
			var can_afford: bool = next_data != null and EconomyManager.can_afford(next_data.gold_cost, 0)
			upgrade_button.disabled = not can_afford
			if not upgrade_button.pressed.is_connected(_on_upgrade_pressed.bind(slot)):
				upgrade_button.pressed.connect(_on_upgrade_pressed.bind(slot))


## Builds the current stat display string for a weapon slot.
func _build_stats_text(slot: Types.WeaponSlot) -> String:
	if _weapon_upgrade_manager == null:
		return ""
	var dmg: float = _weapon_upgrade_manager.get_effective_damage(slot)
	var spd: float = _weapon_upgrade_manager.get_effective_speed(slot)
	var rld: float = _weapon_upgrade_manager.get_effective_reload_time(slot)
	var bst: int = _weapon_upgrade_manager.get_effective_burst_count(slot)
	return "DMG: %.0f  SPD: %.0f  RLD: %.1fs  BURST: %d" % [dmg, spd, rld, bst]


## Builds the next-level preview string showing deltas for changed stats.
func _build_preview_text(slot: Types.WeaponSlot, next_data: WeaponLevelData) -> String:
	var lines: Array[String] = []
	if next_data.damage_bonus != 0.0:
		var cur_damage: float = _weapon_upgrade_manager.get_effective_damage(slot)
		lines.append("Damage: %.0f -> %.0f (%+.0f)" % [cur_damage, cur_damage + next_data.damage_bonus, next_data.damage_bonus])
	if next_data.speed_bonus != 0.0:
		var cur_speed: float = _weapon_upgrade_manager.get_effective_speed(slot)
		lines.append("Speed: %.0f -> %.0f (%+.0f)" % [cur_speed, cur_speed + next_data.speed_bonus, next_data.speed_bonus])
	if next_data.reload_bonus != 0.0:
		var cur_reload: float = _weapon_upgrade_manager.get_effective_reload_time(slot)
		lines.append("Reload: %.1fs -> %.1fs (%+.1f)" % [cur_reload, maxf(cur_reload + next_data.reload_bonus, 0.1), next_data.reload_bonus])
	if next_data.burst_count_bonus != 0:
		var cur_burst: int = _weapon_upgrade_manager.get_effective_burst_count(slot)
		lines.append("Burst: %d -> %d (%+d)" % [cur_burst, cur_burst + next_data.burst_count_bonus, next_data.burst_count_bonus])
	if lines.is_empty():
		return "No stat changes"
	return "\n".join(lines)


## Called when the Upgrade button is pressed for a weapon slot.
func _on_upgrade_pressed(slot: Types.WeaponSlot) -> void:
	if _weapon_upgrade_manager == null:
		return
	_weapon_upgrade_manager.upgrade_weapon(slot)


## Called when weapon_upgraded signal is received from SignalBus.
func _on_weapon_upgraded(_weapon_slot: Types.WeaponSlot, _new_level: int) -> void:
	_refresh_weapons_tab()


## Called when resources change — refreshes button affordability states.
func _on_resource_changed_weapons(_resource_type: Types.ResourceType, _new_amount: int) -> void:
	_refresh_weapons_tab()
	if GameManager.get_game_state() == Types.GameState.BETWEEN_MISSIONS:
		_refresh_offers("")


func _on_enchantment_applied(_weapon_slot: Types.WeaponSlot, _slot_type: String, _enchantment_id: String) -> void:
	_refresh_weapon_enchantments()


func _on_enchantment_removed(_weapon_slot: Types.WeaponSlot, _slot_type: String) -> void:
	_refresh_weapon_enchantments()


func _refresh_weapon_enchantments() -> void:
	_update_weapon_enchantment_display(Types.WeaponSlot.CROSSBOW, _crossbow_enchant_label)
	_update_weapon_enchantment_display(Types.WeaponSlot.RAPID_MISSILE, _rapid_enchant_label)


func _update_weapon_enchantment_display(weapon_slot: Types.WeaponSlot, label: Label) -> void:
	if label == null:
		return

	var slots: Dictionary = EnchantmentManager.get_all_equipped_enchantments_for_weapon(weapon_slot)
	var parts: Array[String] = []

	for slot_type: String in ["elemental", "power"]:
		var enchantment_id: String = slots.get(slot_type, "") as String
		if enchantment_id == "":
			parts.append("%s: None" % slot_type)
		else:
			var enchantment: EnchantmentData = EnchantmentManager.get_equipped_enchantment(weapon_slot, slot_type)
			if enchantment == null:
				parts.append("%s: None" % slot_type)
			else:
				parts.append("%s: %s" % [slot_type, enchantment.display_name])

	label.text = ", ".join(parts)


func on_apply_enchantment_button_pressed(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String, gold_cost: int) -> void:
	var success: bool = EnchantmentManager.try_apply_enchantment(weapon_slot, slot_type, enchantment_id, gold_cost)
	if not success:
		return
	_refresh_weapon_enchantments()


func on_remove_enchantment_button_pressed(weapon_slot: Types.WeaponSlot, slot_type: String) -> void:
	EnchantmentManager.remove_enchantment(weapon_slot, slot_type)
	_refresh_weapon_enchantments()


func on_apply_crossbow_elemental_pressed() -> void:
	var enchantment_id: String = "scorching_bolts"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "elemental", enchantment_id, gold_cost)


func on_apply_crossbow_power_pressed() -> void:
	var enchantment_id: String = "sharpened_mechanism"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "power", enchantment_id, gold_cost)


func on_remove_crossbow_enchantments_pressed() -> void:
	on_remove_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "elemental")
	on_remove_enchantment_button_pressed(Types.WeaponSlot.CROSSBOW, "power")


func on_apply_rapid_elemental_pressed() -> void:
	var enchantment_id: String = "toxic_payload"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "elemental", enchantment_id, gold_cost)


func on_apply_rapid_power_pressed() -> void:
	var enchantment_id: String = "sharpened_mechanism"
	var gold_cost: int = 0
	on_apply_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "power", enchantment_id, gold_cost)


func on_remove_rapid_enchantments_pressed() -> void:
	on_remove_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "elemental")
	on_remove_enchantment_button_pressed(Types.WeaponSlot.RAPID_MISSILE, "power")
