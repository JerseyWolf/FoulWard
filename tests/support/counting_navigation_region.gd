## tests/support/counting_navigation_region.gd
## Test double for NavMeshManager: counts bake_navigation_mesh calls (see Godot native override warning).

class_name CountingNavigationRegion
extends NavigationRegion3D

var bake_calls: int = 0


@warning_ignore("native_method_override")
func bake_navigation_mesh(force_bake: bool = false) -> void:
	bake_calls += 1
