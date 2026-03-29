## tests/unit/test_building_kit.gd
## GdUnit4 unit tests for modular building kit assembly (ArtPlaceholderHelper + BuildingData).

class_name TestBuildingKit
extends GdUnitTestSuite

const ArtPlaceholderHelper: GDScript = preload("res://scripts/art/art_placeholder_helper.gd")

func before_test() -> void:
	ArtPlaceholderHelper.clear_cache()


func test_kit_mesh_returns_node3d() -> void:
	var root: Node3D = ArtPlaceholderHelper.get_building_kit_mesh(
			Types.BuildingBaseMesh.STONE_ROUND,
			Types.BuildingTopMesh.ROOF_CONE,
			Color.RED
	) as Node3D
	assert_object(root).is_not_null()
	assert_bool(root is Node3D).is_true()
	assert_int(root.get_child_count()).is_equal(2)
	root.free()


func test_accent_color_applied() -> void:
	var accent: Color = Color(0.2, 0.5, 0.9, 1.0)
	var root: Node3D = ArtPlaceholderHelper.get_building_kit_mesh(
			Types.BuildingBaseMesh.STONE_SQUARE,
			Types.BuildingTopMesh.GLASS_DOME,
			accent
	) as Node3D
	var top_mi: MeshInstance3D = root.get_child(1) as MeshInstance3D
	assert_object(top_mi).is_not_null()
	var mat: Material = top_mi.get_surface_override_material(0)
	assert_object(mat).is_not_null()
	var sm: StandardMaterial3D = mat as StandardMaterial3D
	assert_object(sm).is_not_null()
	assert_float(sm.albedo_color.r).is_equal_approx(accent.r, 0.01)
	assert_float(sm.albedo_color.g).is_equal_approx(accent.g, 0.01)
	assert_float(sm.albedo_color.b).is_equal_approx(accent.b, 0.01)
	root.free()


func test_fallback_when_no_glb() -> void:
	var root: Node3D = ArtPlaceholderHelper.get_building_kit_mesh(
			Types.BuildingBaseMesh.WOOD_ROUND,
			Types.BuildingTopMesh.BALLISTA_FRAME,
			Color.WHITE
	) as Node3D
	assert_object(root).is_not_null()
	assert_int(root.get_child_count()).is_equal(2)
	var base_mi: MeshInstance3D = root.get_child(0) as MeshInstance3D
	var top_mi: MeshInstance3D = root.get_child(1) as MeshInstance3D
	assert_object(base_mi).is_not_null()
	assert_object(top_mi).is_not_null()
	assert_object(base_mi.mesh).is_not_null()
	assert_object(top_mi.mesh).is_not_null()
	assert_bool(base_mi.mesh is BoxMesh).is_true()
	assert_bool(top_mi.mesh is BoxMesh).is_true()
	root.free()


func test_building_data_fields_exist() -> void:
	var bd: BuildingData = BuildingData.new()
	bd.base_mesh_id = Types.BuildingBaseMesh.STONE_SQUARE
	bd.top_mesh_id = Types.BuildingTopMesh.GLASS_DOME
	bd.accent_color = Color.GREEN
	assert_int(bd.base_mesh_id).is_equal(Types.BuildingBaseMesh.STONE_SQUARE)
	assert_int(bd.top_mesh_id).is_equal(Types.BuildingTopMesh.GLASS_DOME)
	assert_float(bd.accent_color.r).is_equal_approx(Color.GREEN.r, 0.01)
	assert_float(bd.accent_color.g).is_equal_approx(Color.GREEN.g, 0.01)
	assert_float(bd.accent_color.b).is_equal_approx(Color.GREEN.b, 0.01)
