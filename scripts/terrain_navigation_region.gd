## terrain_navigation_region.gd
## Builds a flat NavigationMesh from sibling GroundMesh at runtime (PlaneMesh source).

extends NavigationRegion3D


func _ready() -> void:
	var parent_n: Node = get_parent()
	if parent_n == null:
		return
	var ground: MeshInstance3D = parent_n.get_node_or_null("GroundMesh") as MeshInstance3D
	if ground == null or ground.mesh == null:
		push_warning("TerrainNavigationRegion: GroundMesh missing or has no mesh.")
		return
	var nm: NavigationMesh = NavigationMesh.new()
	nm.create_from_mesh(ground.mesh)
	navigation_mesh = nm
