## tests/test_art_placeholders.gd
## GdUnit4 test suite for ArtPlaceholderHelper scaffolding + scene wiring.

class_name TestArtPlaceholders
extends GdUnitTestSuite

const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

func before_test() -> void:
	ArtPlaceholderHelper.clear_cache()

# ---------------------------------------------------------------------------
# Group 1 — Mesh resolution coverage
# ---------------------------------------------------------------------------

func test_enemy_mesh_resolution_returns_non_null_for_all_enemy_types() -> void:
	for enemy_type: Types.EnemyType in Types.EnemyType.values():
		var mesh: Mesh = ArtPlaceholderHelper.get_enemy_mesh(enemy_type)
		assert_object(mesh).is_not_null()


func test_building_mesh_resolution_returns_non_null_for_all_building_types() -> void:
	for building_type: Types.BuildingType in Types.BuildingType.values():
		var mesh: Mesh = ArtPlaceholderHelper.get_building_mesh(building_type)
		assert_object(mesh).is_not_null()


func test_ally_mesh_resolution_returns_non_null_for_arnulf() -> void:
	var mesh: Mesh = ArtPlaceholderHelper.get_ally_mesh("arnulf")
	assert_object(mesh).is_not_null()


func test_tower_mesh_resolution_returns_non_null() -> void:
	var mesh: Mesh = ArtPlaceholderHelper.get_tower_mesh()
	assert_object(mesh).is_not_null()


func test_unknown_mesh_resolution_returns_non_null() -> void:
	var mesh: Mesh = ArtPlaceholderHelper.get_unknown_mesh()
	assert_object(mesh).is_not_null()

# ---------------------------------------------------------------------------
# Group 2 — Material resolution coverage
# ---------------------------------------------------------------------------

func test_faction_material_resolution_returns_non_null_for_all_core_factions() -> void:
	assert_object(ArtPlaceholderHelper.get_faction_material("orcs")).is_not_null()
	assert_object(ArtPlaceholderHelper.get_faction_material("plague")).is_not_null()
	assert_object(ArtPlaceholderHelper.get_faction_material("neutral")).is_not_null()
	assert_object(ArtPlaceholderHelper.get_faction_material("allies")).is_not_null()


func test_faction_material_resolution_falls_back_to_neutral_for_unknown_faction() -> void:
	assert_object(ArtPlaceholderHelper.get_faction_material("nonexistent_faction")).is_not_null()


func test_enemy_material_resolution_returns_non_null_for_all_enemy_types() -> void:
	for enemy_type: Types.EnemyType in Types.EnemyType.values():
		var mat: Material = ArtPlaceholderHelper.get_enemy_material(enemy_type)
		assert_object(mat).is_not_null()


func test_building_material_resolution_returns_non_null_for_all_building_types() -> void:
	for building_type: Types.BuildingType in Types.BuildingType.values():
		var mat: Material = ArtPlaceholderHelper.get_building_material(building_type)
		assert_object(mat).is_not_null()

# ---------------------------------------------------------------------------
# Group 3 — Fallback behavior
# ---------------------------------------------------------------------------

func test_get_unknown_mesh_returns_non_null_when_called_directly() -> void:
	var mesh: Mesh = ArtPlaceholderHelper.get_unknown_mesh()
	assert_object(mesh).is_not_null()


func test_enemy_mesh_missing_token_falls_back_to_unknown_mesh() -> void:
	# Cast an invalid enum value to trigger the helper's unknown-token fallback.
	var bogus_enemy_type: Types.EnemyType = 999
	var mesh: Mesh = ArtPlaceholderHelper.get_enemy_mesh(bogus_enemy_type)
	var unknown_mesh: Mesh = ArtPlaceholderHelper.get_unknown_mesh()
	assert_object(mesh).is_equal(unknown_mesh)

# ---------------------------------------------------------------------------
# Group 4 — Scene wiring smoke tests
# ---------------------------------------------------------------------------

func _find_first_mesh_instance3d(root: Node) -> MeshInstance3D:
	if root == null:
		return null
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			return n as MeshInstance3D
		for c: Node in n.get_children():
			stack.append(c)
	return null


func _mesh_has_material(mi: MeshInstance3D) -> bool:
	if mi.material_override != null:
		return true
	var mesh: Mesh = mi.mesh
	if mesh == null:
		return false
	for i: int in range(mesh.get_surface_count()):
		if mi.get_active_material(i) != null:
			return true
	return false


func _get_enemy_data_for_type(enemy_type: Types.EnemyType) -> EnemyData:
	match enemy_type:
		Types.EnemyType.ORC_GRUNT:
			return load("res://resources/enemy_data/orc_grunt.tres") as EnemyData
		Types.EnemyType.ORC_BRUTE:
			return load("res://resources/enemy_data/orc_brute.tres") as EnemyData
		Types.EnemyType.GOBLIN_FIREBUG:
			return load("res://resources/enemy_data/goblin_firebug.tres") as EnemyData
		Types.EnemyType.PLAGUE_ZOMBIE:
			return load("res://resources/enemy_data/plague_zombie.tres") as EnemyData
		Types.EnemyType.ORC_ARCHER:
			return load("res://resources/enemy_data/orc_archer.tres") as EnemyData
		Types.EnemyType.BAT_SWARM:
			return load("res://resources/enemy_data/bat_swarm.tres") as EnemyData
		_:
			return null


func _get_building_data_for_type(building_type: Types.BuildingType) -> BuildingData:
	match building_type:
		Types.BuildingType.ARROW_TOWER:
			return load("res://resources/building_data/arrow_tower.tres") as BuildingData
		Types.BuildingType.FIRE_BRAZIER:
			return load("res://resources/building_data/fire_brazier.tres") as BuildingData
		Types.BuildingType.MAGIC_OBELISK:
			return load("res://resources/building_data/magic_obelisk.tres") as BuildingData
		Types.BuildingType.POISON_VAT:
			return load("res://resources/building_data/poison_vat.tres") as BuildingData
		Types.BuildingType.BALLISTA:
			return load("res://resources/building_data/ballista.tres") as BuildingData
		Types.BuildingType.ARCHER_BARRACKS:
			return load("res://resources/building_data/archer_barracks.tres") as BuildingData
		Types.BuildingType.ANTI_AIR_BOLT:
			return load("res://resources/building_data/anti_air_bolt.tres") as BuildingData
		Types.BuildingType.SHIELD_GENERATOR:
			return load("res://resources/building_data/shield_generator.tres") as BuildingData
		_:
			return null


func test_enemy_base_scene_wiring_sets_mesh_and_material_for_each_enemy_type() -> void:
	var enemy_scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")

	for enemy_type: Types.EnemyType in Types.EnemyType.values():
		var enemy: EnemyBase = enemy_scene.instantiate() as EnemyBase
		get_tree().root.add_child(enemy)
		await get_tree().process_frame

		var enemy_data: EnemyData = _get_enemy_data_for_type(enemy_type)
		assert_object(enemy_data).is_not_null()

		enemy.initialize(enemy_data)
		await get_tree().process_frame

		var enemy_vis: Node3D = enemy.get_node("EnemyVisual") as Node3D
		assert_object(enemy_vis).is_not_null()
		var enemy_mesh: MeshInstance3D = _find_first_mesh_instance3d(enemy_vis)
		assert_object(enemy_mesh).is_not_null()
		assert_object(enemy_mesh.mesh).is_not_null()
		assert_bool(_mesh_has_material(enemy_mesh)).is_true()

		enemy.queue_free()
		await get_tree().process_frame


func test_building_base_scene_wiring_sets_mesh_for_each_building_type() -> void:
	var building_scene: PackedScene = load("res://scenes/buildings/building_base.tscn")

	for building_type: Types.BuildingType in Types.BuildingType.values():
		var building: BuildingBase = building_scene.instantiate() as BuildingBase
		get_tree().root.add_child(building)
		await get_tree().process_frame

		var building_data: BuildingData = _get_building_data_for_type(building_type)
		assert_object(building_data).is_not_null()

		building.initialize(building_data)
		await get_tree().process_frame

		var building_mesh: MeshInstance3D = building.get_node("BuildingMesh") as MeshInstance3D
		assert_object(building_mesh.mesh).is_not_null()

		building.queue_free()
		await get_tree().process_frame


func test_tower_scene_ready_sets_tower_mesh_non_null() -> void:
	var tower_scene: PackedScene = load("res://scenes/tower/tower.tscn")
	var tower: Tower = tower_scene.instantiate() as Tower
	get_tree().root.add_child(tower)
	await get_tree().process_frame

	var tower_mesh: MeshInstance3D = tower.get_node("TowerMesh") as MeshInstance3D
	assert_object(tower_mesh.mesh).is_not_null()

	tower.queue_free()
	await get_tree().process_frame


func test_arnulf_scene_ready_sets_arnulf_mesh_non_null() -> void:
	var arnulf_scene: PackedScene = load("res://scenes/arnulf/arnulf.tscn")
	var arnulf: Arnulf = arnulf_scene.instantiate() as Arnulf
	get_tree().root.add_child(arnulf)
	await get_tree().process_frame

	var arnulf_vis: Node3D = arnulf.get_node("ArnulfVisual") as Node3D
	assert_object(arnulf_vis).is_not_null()
	var arnulf_mesh: MeshInstance3D = _find_first_mesh_instance3d(arnulf_vis)
	assert_object(arnulf_mesh).is_not_null()
	assert_object(arnulf_mesh.mesh).is_not_null()

	arnulf.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------------
# Group 5 — Cache behavior
# ---------------------------------------------------------------------------

func test_get_enemy_mesh_returns_same_reference_when_called_twice() -> void:
	var mesh1: Mesh = ArtPlaceholderHelper.get_enemy_mesh(Types.EnemyType.ORC_GRUNT)
	var mesh2: Mesh = ArtPlaceholderHelper.get_enemy_mesh(Types.EnemyType.ORC_GRUNT)
	assert_object(mesh1).is_equal(mesh2)


func test_clear_cache_allows_reload_and_returns_non_null_mesh() -> void:
	ArtPlaceholderHelper.clear_cache()
	var mesh1: Mesh = ArtPlaceholderHelper.get_enemy_mesh(Types.EnemyType.ORC_GRUNT)
	assert_object(mesh1).is_not_null()

	ArtPlaceholderHelper.clear_cache()
	var mesh2: Mesh = ArtPlaceholderHelper.get_enemy_mesh(Types.EnemyType.ORC_GRUNT)
	assert_object(mesh2).is_not_null()


func test_generated_orc_grunt_mesh_file_exists_under_art_generated() -> void:
	ArtPlaceholderHelper.clear_cache()
	assert_bool(ResourceLoader.exists("res://art/generated/meshes/enemy_orc_grunt.tres")).is_true()
	var mesh: Mesh = ArtPlaceholderHelper.get_enemy_mesh(Types.EnemyType.ORC_GRUNT)
	assert_object(mesh).is_not_null()

