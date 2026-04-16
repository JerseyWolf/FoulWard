## test_character_hub.gd
## GdUnit4 tests for between-mission hub framework (Prompt 14).

class_name TestCharacterHub
extends GdUnitTestSuite


class BetweenMissionScreenStub:
	extends Node

	var shop_opened: bool = false
	var research_opened: bool = false
	var enchant_opened: bool = false
	var mercenary_opened: bool = false

	func open_shop_panel() -> void:
		shop_opened = true

	func open_research_panel() -> void:
		research_opened = true

	func open_enchant_panel() -> void:
		enchant_opened = true

	func open_mercenary_panel() -> void:
		mercenary_opened = true

	func reset() -> void:
		shop_opened = false
		research_opened = false
		enchant_opened = false
		mercenary_opened = false


class UiManagerStub:
	extends Node

	var show_dialogue_calls: int = 0
	var last_speaker_name: String = ""
	var last_entry_id: String = ""

	func show_dialogue(display_name: String, entry: DialogueEntry) -> void:
		show_dialogue_calls += 1
		last_speaker_name = display_name
		last_entry_id = "" if entry == null else entry.entry_id

	func reset() -> void:
		show_dialogue_calls = 0
		last_speaker_name = ""
		last_entry_id = ""


func _mouse_left_click_event() -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	return ev


func before_test() -> void:
	EconomyManager.reset_to_defaults()
	DialogueManager.entries_by_id.clear()
	DialogueManager.entries_by_character.clear()


func after_test() -> void:
	DialogueManager.entries_by_id.clear()
	DialogueManager.entries_by_character.clear()
	for child: Node in get_children():
		if is_instance_valid(child) and not child is Timer:
			child.queue_free()
	await get_tree().process_frame


func _register_dialogue_entries(entries: Array[DialogueEntry]) -> void:
	for e: DialogueEntry in entries:
		if e == null:
			continue
		DialogueManager.entries_by_id[e.entry_id] = e
		if not DialogueManager.entries_by_character.has(e.character_id):
			DialogueManager.entries_by_character[e.character_id] = [] as Array[DialogueEntry]
		(DialogueManager.entries_by_character[e.character_id] as Array).append(e)


func _make_dialogue_entry(
	entry_id: String,
	character_id: String,
	text_value: String,
	priority_value: int,
	once_only_value: bool = false,
	chain_next_id: String = ""
) -> DialogueEntry:
	var e := DialogueEntry.new()
	e.entry_id = entry_id
	e.character_id = character_id
	e.text = text_value
	e.priority = priority_value
	e.once_only = once_only_value
	e.chain_next_id = chain_next_id
	e.conditions = []
	return e


func test_character_data_resources_load_with_expected_ids_and_roles() -> void:
	var merchant: CharacterData = load(
		"res://resources/character_data/merchant.tres"
	) as CharacterData
	assert_object(merchant).is_not_null()
	assert_str(merchant.character_id).is_equal("MERCHANT")
	assert_int(merchant.role).is_equal(Types.HubRole.SHOP)

	var researcher: CharacterData = load(
		"res://resources/character_data/researcher.tres"
	) as CharacterData
	assert_object(researcher).is_not_null()
	assert_str(researcher.character_id).is_equal("SPELL_RESEARCHER")
	assert_int(researcher.role).is_equal(Types.HubRole.RESEARCH)

	var enchantress: CharacterData = load(
		"res://resources/character_data/enchantress.tres"
	) as CharacterData
	assert_object(enchantress).is_not_null()
	assert_str(enchantress.character_id).is_equal("ENCHANTER")
	assert_int(enchantress.role).is_equal(Types.HubRole.ENCHANT)

	var mercenary_captain: CharacterData = load(
		"res://resources/character_data/mercenary_captain.tres"
	) as CharacterData
	assert_object(mercenary_captain).is_not_null()
	assert_str(mercenary_captain.character_id).is_equal("MERCENARY_COMMANDER")
	assert_int(mercenary_captain.role).is_equal(Types.HubRole.MERCENARY)

	var arnulf_hub: CharacterData = load(
		"res://resources/character_data/arnulf_hub.tres"
	) as CharacterData
	assert_object(arnulf_hub).is_not_null()
	assert_str(arnulf_hub.character_id).is_equal("COMPANION_MELEE")
	assert_int(arnulf_hub.role).is_equal(Types.HubRole.ALLY)

	var flavor_npc_01: CharacterData = load(
		"res://resources/character_data/flavor_npc_01.tres"
	) as CharacterData
	assert_object(flavor_npc_01).is_not_null()
	assert_str(flavor_npc_01.character_id).is_equal("EXAMPLE_CHARACTER")
	assert_int(flavor_npc_01.role).is_equal(Types.HubRole.FLAVOR_ONLY)


func test_hub_character_base_2d_emits_interaction_signal_with_correct_id() -> void:
	var scene: PackedScene = load("res://scenes/hub/character_base_2d.tscn") as PackedScene
	var char_node: HubCharacterBase2D = scene.instantiate() as HubCharacterBase2D

	var data := CharacterData.new()
	data.character_id = "TEST_CHAR"
	data.display_name = "Test"
	data.role = Types.HubRole.FLAVOR_ONLY
	data.portrait_id = ""
	data.icon_id = ""
	data.hub_position_2d = Vector2.ZERO
	data.hub_marker_name_3d = ""
	data.default_dialogue_tags = []
	data.description = "TODO: description"

	char_node.character_data = data
	add_child(char_node)

	var monitor := monitor_signals(char_node, false)
	var ev := _mouse_left_click_event()
	char_node._gui_input(ev)

	await assert_signal(monitor).is_emitted("character_interacted", ["TEST_CHAR"])

	char_node.queue_free()


func test_hub_initializes_characters_from_catalog() -> void:
	var a := CharacterData.new()
	a.character_id = "CHAR_A"
	a.display_name = "A"
	a.role = Types.HubRole.SHOP
	a.description = "TODO: description"
	a.portrait_id = ""
	a.icon_id = ""
	a.hub_position_2d = Vector2.ZERO
	a.hub_marker_name_3d = ""
	a.default_dialogue_tags = []

	var b := CharacterData.new()
	b.character_id = "CHAR_B"
	b.display_name = "B"
	b.role = Types.HubRole.RESEARCH
	b.description = "TODO: description"
	b.portrait_id = ""
	b.icon_id = ""
	b.hub_position_2d = Vector2.ZERO
	b.hub_marker_name_3d = ""
	b.default_dialogue_tags = []

	var catalog := CharacterCatalog.new()
	catalog.characters = [a, b]

	var hub_scene: PackedScene = load("res://ui/hub.tscn") as PackedScene
	var hub: Hub2DHub = hub_scene.instantiate() as Hub2DHub
	hub.character_catalog = catalog
	add_child(hub)
	await get_tree().process_frame

	assert_int(hub._characters_by_id.size()).is_equal(2)
	assert_bool(hub._characters_by_id.has("CHAR_A")).is_true()
	assert_bool(hub._characters_by_id.has("CHAR_B")).is_true()

	var container: Container = hub._characters_container
	assert_object(container).is_not_null()
	assert_int(container.get_child_count()).is_equal(2)

	hub.queue_free()


func test_interacting_with_shop_role_character_triggers_shop_panel_activation() -> void:
	var shop_data := CharacterData.new()
	shop_data.character_id = "TEST_SHOP_CHAR"
	shop_data.display_name = "Shop Tester"
	shop_data.role = Types.HubRole.SHOP
	shop_data.description = "TODO: description"
	shop_data.portrait_id = ""
	shop_data.icon_id = ""
	shop_data.hub_position_2d = Vector2.ZERO
	shop_data.hub_marker_name_3d = ""
	shop_data.default_dialogue_tags = ["hub", "shop"]

	var catalog := CharacterCatalog.new()
	catalog.characters = [shop_data]

	var hub_scene: PackedScene = load("res://ui/hub.tscn") as PackedScene
	var hub: Hub2DHub = hub_scene.instantiate() as Hub2DHub
	hub.character_catalog = catalog
	add_child(hub)
	await get_tree().process_frame

	var bms_stub := BetweenMissionScreenStub.new()
	hub.set_between_mission_screen(bms_stub)

	var ui_stub := UiManagerStub.new()
	hub._set_ui_manager(ui_stub)

	_register_dialogue_entries([
		_make_dialogue_entry(
			"TEST_SHOP_ENTRY_01",
			"TEST_SHOP_CHAR",
			"Shop dialogue line",
			10,
			false,
			""
		)
	])

	var char_node: HubCharacterBase2D = hub._characters_by_id.get("TEST_SHOP_CHAR", null) as HubCharacterBase2D
	assert_object(char_node).is_not_null()

	var ev := _mouse_left_click_event()
	char_node._gui_input(ev)
	await get_tree().process_frame

	assert_bool(bms_stub.shop_opened).is_true()
	assert_int(ui_stub.show_dialogue_calls).is_equal(1)
	assert_str(ui_stub.last_speaker_name).is_equal("Shop Tester")
	assert_str(ui_stub.last_entry_id).is_equal("TEST_SHOP_ENTRY_01")

	hub.queue_free()
	if is_instance_valid(bms_stub):
		bms_stub.free()
	if is_instance_valid(ui_stub):
		ui_stub.free()
	await get_tree().process_frame


func test_dialogue_panel_displays_text_from_dialogue_entry() -> void:
	var scene: PackedScene = load("res://ui/dialogue_panel.tscn") as PackedScene
	var panel: DialoguePanel = scene.instantiate() as DialoguePanel
	add_child(panel)

	var entry := DialogueEntry.new()
	entry.entry_id = "TEST_PANEL_ENTRY_01"
	entry.character_id = "TEST_PANEL_CHAR"
	entry.text = "Panel text"
	entry.priority = 10
	entry.once_only = false
	entry.chain_next_id = ""
	entry.conditions = []

	panel.show_entry("Speaker Name", entry)
	await get_tree().process_frame

	var speaker_label: Label = panel.get_node_or_null("SpeakerLabel") as Label
	var text_label: Label = panel.get_node_or_null("TextLabel") as Label
	assert_object(speaker_label).is_not_null()
	assert_object(text_label).is_not_null()

	assert_str(speaker_label.text).is_equal("Speaker Name")
	assert_str(text_label.text).is_equal("Panel text")
	assert_bool(panel.visible).is_true()

	panel.queue_free()


func test_dialogue_panel_click_advances_chain_and_signals_finished() -> void:
	var char_id: String = "TEST_CHAIN_CHAR"

	var part1 := _make_dialogue_entry(
		"TEST_CHAIN_ENTRY_01",
		char_id,
		"Part 1",
		10,
		false,
		"TEST_CHAIN_ENTRY_02"
	)
	var part2 := _make_dialogue_entry(
		"TEST_CHAIN_ENTRY_02",
		char_id,
		"Part 2",
		10,
		false,
		""
	)

	_register_dialogue_entries([part1, part2])

	var scene: PackedScene = load("res://ui/dialogue_panel.tscn") as PackedScene
	var panel: DialoguePanel = scene.instantiate() as DialoguePanel
	add_child(panel)

	var monitor := monitor_signals(SignalBus, false)

	panel.show_entry("Speaker", part1)
	await get_tree().process_frame

	var ev := _mouse_left_click_event()
	panel._on_gui_input(ev)
	await get_tree().process_frame
	assert_str(panel.current_entry.entry_id).is_equal("TEST_CHAIN_ENTRY_02")
	assert_bool(panel.visible).is_true()

	panel._on_gui_input(ev)
	await assert_signal(monitor).is_emitted(
		"dialogue_line_finished",
		["TEST_CHAIN_ENTRY_02", char_id]
	)

	assert_bool(panel.visible).is_false()
	assert_object(panel.current_entry).is_null()

	panel.queue_free()


var _main_stub: Node = null
var _hub_under_stub: Hub2DHub = null
var _dialogue_panel_under_stub: DialoguePanel = null


func _ensure_main_ui_stub() -> void:
	var existing_main: Node = get_node_or_null("/root/Main")
	if existing_main != null:
		_main_stub = existing_main
		_hub_under_stub = get_node_or_null("/root/Main/UI/Hub") as Hub2DHub
		_dialogue_panel_under_stub = get_node_or_null("/root/Main/UI/UIManager/DialoguePanel") as DialoguePanel
		return

	_main_stub = Node.new()
	_main_stub.name = "Main"
	get_tree().root.add_child(_main_stub)

	var ui := CanvasLayer.new()
	ui.name = "UI"
	_main_stub.add_child(ui)

	var hud: Control = Control.new()
	hud.name = "HUD"
	ui.add_child(hud)

	var build_menu: Control = Control.new()
	build_menu.name = "BuildMenu"
	ui.add_child(build_menu)

	var between_screen: Control = Control.new()
	between_screen.name = "BetweenMissionScreen"
	ui.add_child(between_screen)

	var main_menu: Control = Control.new()
	main_menu.name = "MainMenu"
	ui.add_child(main_menu)

	var briefing: Control = Control.new()
	briefing.name = "MissionBriefing"
	ui.add_child(briefing)

	var end_screen: Control = Control.new()
	end_screen.name = "EndScreen"
	ui.add_child(end_screen)

	_hub_under_stub = (load("res://ui/hub.tscn") as PackedScene).instantiate() as Hub2DHub
	_hub_under_stub.name = "Hub"
	ui.add_child(_hub_under_stub)

	var ui_manager_node: Control = Control.new()
	ui_manager_node.name = "UIManager"
	ui_manager_node.set_script(load("res://ui/ui_manager.gd"))
	ui.add_child(ui_manager_node)

	_dialogue_panel_under_stub = (load("res://ui/dialogue_panel.tscn") as PackedScene).instantiate() as DialoguePanel
	_dialogue_panel_under_stub.name = "DialoguePanel"
	ui_manager_node.add_child(_dialogue_panel_under_stub)

	# Let UIManager finish _ready and wire itself.
	await get_tree().process_frame


func _cleanup_main_ui_stub() -> void:
	if _main_stub == null:
		return
	if is_instance_valid(_main_stub) and get_node_or_null("/root/Main") == _main_stub:
		_main_stub.queue_free()
	await get_tree().process_frame
	_main_stub = null
	_hub_under_stub = null
	_dialogue_panel_under_stub = null


func test_mission_win_between_mission_state_shows_hub() -> void:
	GameManager.game_state = Types.GameState.MAIN_MENU
	await _ensure_main_ui_stub()

	assert_bool(_hub_under_stub.visible).is_false()

	SignalBus.game_state_changed.emit(
		Types.GameState.COMBAT,
		Types.GameState.BETWEEN_MISSIONS
	)
	await get_tree().process_frame

	assert_bool(_hub_under_stub.visible).is_true()

	await _cleanup_main_ui_stub()


func test_next_mission_closes_hub_and_clears_dialogue() -> void:
	GameManager.game_state = Types.GameState.BETWEEN_MISSIONS
	await _ensure_main_ui_stub()
	await get_tree().process_frame

	# Force dialogue visible.
	var entry := DialogueEntry.new()
	entry.entry_id = "TEST_STUB_DLG_01"
	entry.character_id = "TEST_STUB_DLG_CHAR"
	entry.text = "Hello"
	entry.priority = 10
	entry.once_only = false
	entry.chain_next_id = ""
	entry.conditions = []

	_dialogue_panel_under_stub.show_entry("Speaker", entry)
	await get_tree().process_frame

	assert_bool(_hub_under_stub.visible).is_true()
	assert_bool(_dialogue_panel_under_stub.visible).is_true()

	SignalBus.game_state_changed.emit(
		Types.GameState.BETWEEN_MISSIONS,
		Types.GameState.MISSION_BRIEFING
	)
	await get_tree().process_frame

	assert_bool(_hub_under_stub.visible).is_false()
	assert_bool(_dialogue_panel_under_stub.visible).is_false()

	await _cleanup_main_ui_stub()


func test_focus_character_triggers_same_behavior_as_click() -> void:
	var char_id: String = "TEST_FOCUS_CHAR"

	var shop_data := CharacterData.new()
	shop_data.character_id = char_id
	shop_data.display_name = "Focus Tester"
	shop_data.role = Types.HubRole.SHOP
	shop_data.description = "TODO: description"
	shop_data.portrait_id = ""
	shop_data.icon_id = ""
	shop_data.hub_position_2d = Vector2.ZERO
	shop_data.hub_marker_name_3d = ""
	shop_data.default_dialogue_tags = ["hub", "shop"]

	var catalog := CharacterCatalog.new()
	catalog.characters = [shop_data]

	_register_dialogue_entries([
		_make_dialogue_entry(
			"TEST_FOCUS_ENTRY_01",
			char_id,
			"Focus dialogue line",
			10,
			false,
			""
		)
	])

	var hub_scene: PackedScene = load("res://ui/hub.tscn") as PackedScene
	var hub: Hub2DHub = hub_scene.instantiate() as Hub2DHub
	hub.character_catalog = catalog
	add_child(hub)
	await get_tree().process_frame

	var bms_stub := BetweenMissionScreenStub.new()
	hub.set_between_mission_screen(bms_stub)
	var ui_stub := UiManagerStub.new()
	hub._set_ui_manager(ui_stub)

	var char_node: HubCharacterBase2D = hub._characters_by_id.get(char_id, null) as HubCharacterBase2D
	assert_object(char_node).is_not_null()

	# Click path.
	var ev := _mouse_left_click_event()
	char_node._gui_input(ev)
	await get_tree().process_frame

	var click_shop_opened: bool = bms_stub.shop_opened
	var click_speaker: String = ui_stub.last_speaker_name
	var click_entry_id: String = ui_stub.last_entry_id
	var click_call_count: int = ui_stub.show_dialogue_calls

	# Reset and focus path.
	bms_stub.reset()
	ui_stub.reset()

	hub.focus_character(char_id)
	await get_tree().process_frame

	assert_bool(bms_stub.shop_opened).is_equal(click_shop_opened)
	assert_int(ui_stub.show_dialogue_calls).is_equal(click_call_count)
	assert_str(ui_stub.last_speaker_name).is_equal(click_speaker)
	assert_str(ui_stub.last_entry_id).is_equal(click_entry_id)

	hub.queue_free()
	if is_instance_valid(bms_stub):
		bms_stub.free()
	if is_instance_valid(ui_stub):
		ui_stub.free()
	await get_tree().process_frame

