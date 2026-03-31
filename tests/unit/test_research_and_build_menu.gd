# Prompt 11 — research node ↔ building data wiring and ResearchManager unlock helpers.
extends GdUnitTestSuite


func _collect_building_unlock_ids() -> Array[String]:
	var out: Array[String] = []
	var d: DirAccess = DirAccess.open("res://resources/building_data/")
	assert_object(d).is_not_null()
	d.list_dir_begin()
	var fname: String = d.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res: Resource = load("res://resources/building_data/" + fname)
			if res is BuildingData:
				var bd: BuildingData = res as BuildingData
				var uid: String = bd.unlock_research_id.strip_edges()
				if uid != "":
					out.append(uid)
		fname = d.get_next()
	return out


func _collect_research_node_ids() -> Array[String]:
	var out: Array[String] = []
	var d: DirAccess = DirAccess.open("res://resources/research_data/")
	assert_object(d).is_not_null()
	d.list_dir_begin()
	var fname: String = d.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res: Resource = load("res://resources/research_data/" + fname)
			if res is ResearchNodeData:
				var rnd: ResearchNodeData = res as ResearchNodeData
				if rnd.node_id.strip_edges() != "":
					out.append(rnd.node_id)
		fname = d.get_next()
	return out


func test_all_unlockresearch_ids_have_matching_nodes() -> void:
	var ids: Array[String] = _collect_building_unlock_ids()
	var node_ids: Array[String] = _collect_research_node_ids()
	for id: String in ids:
		assert_bool(id in node_ids).is_true()


func test_all_research_nodes_for_towers_have_matching_buildings() -> void:
	var building_ids: Array[String] = []
	var d: DirAccess = DirAccess.open("res://resources/building_data/")
	assert_object(d).is_not_null()
	d.list_dir_begin()
	var fname: String = d.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res: Resource = load("res://resources/building_data/" + fname)
			if res is BuildingData:
				var bd: BuildingData = res as BuildingData
				var uid: String = bd.unlock_research_id.strip_edges()
				if uid != "":
					building_ids.append(uid)
		fname = d.get_next()
	var nd: DirAccess = DirAccess.open("res://resources/research_data/")
	assert_object(nd).is_not_null()
	nd.list_dir_begin()
	fname = nd.get_next()
	while fname != "":
		if fname.ends_with(".tres"):
			var res2: Resource = load("res://resources/research_data/" + fname)
			if res2 is ResearchNodeData:
				var node: ResearchNodeData = res2 as ResearchNodeData
				if node.node_id.begins_with("unlock_"):
					assert_bool(node.node_id in building_ids).is_true()
		fname = nd.get_next()


func test_can_unlock_when_prereqs_and_points_met() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_research_material(20)
	var rm: ResearchManager = ResearchManager.new()
	var spike: ResearchNodeData = load("res://resources/research_data/unlock_spike_spitter.tres") as ResearchNodeData
	rm.research_nodes = [spike]
	add_child(rm)
	assert_bool(rm.can_unlock("unlock_spike_spitter")).is_true()
	rm.queue_free()
	await get_tree().process_frame


func _make_registry_with_spike() -> Array[BuildingData]:
	var registry: Array[BuildingData] = []
	for i: int in range(Types.BuildingType.size()):
		var bt: Types.BuildingType = i as Types.BuildingType
		if bt == Types.BuildingType.SPIKE_SPITTER:
			var loaded: BuildingData = load("res://resources/building_data/spike_spitter.tres") as BuildingData
			registry.append(loaded)
			continue
		var bd: BuildingData = BuildingData.new()
		bd.building_type = bt
		bd.display_name = "Test %d" % i
		bd.gold_cost = 50
		bd.material_cost = 1
		bd.upgrade_gold_cost = 75
		bd.upgrade_material_cost = 3
		bd.damage = 20.0
		bd.upgraded_damage = 35.0
		bd.fire_rate = 1.0
		bd.attack_range = 15.0
		bd.upgraded_range = 18.0
		bd.damage_type = Types.DamageType.PHYSICAL
		bd.targets_air = false
		bd.targets_ground = true
		bd.is_locked = false
		bd.color = Color.GRAY
		registry.append(bd)
	return registry


func test_unlock_sets_building_islocked_false() -> void:
	EconomyManager.reset_to_defaults()
	EconomyManager.add_research_material(20)
	var hg: HexGrid = HexGrid.new()
	hg.building_data_registry = _make_registry_with_spike()
	add_child(hg)
	hg.add_to_group("hex_grid")
	var bd: BuildingData = hg.get_building_data(Types.BuildingType.SPIKE_SPITTER)
	assert_object(bd).is_not_null()
	bd.is_locked = true
	var rm: ResearchManager = ResearchManager.new()
	var spike: ResearchNodeData = load("res://resources/research_data/unlock_spike_spitter.tres") as ResearchNodeData
	rm.research_nodes = [spike]
	add_child(rm)
	var ok: bool = rm.unlock_node("unlock_spike_spitter")
	assert_bool(ok).is_true()
	assert_bool(bd.is_locked).is_false()
	rm.queue_free()
	hg.queue_free()
	await get_tree().process_frame
