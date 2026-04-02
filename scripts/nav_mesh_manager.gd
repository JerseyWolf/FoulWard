## nav_mesh_manager.gd
## Navmesh rebake queue pattern.
## Credit: community contributor, godotengine/godot#81181
## https://github.com/godotengine/godot/issues/81181
## Autoload-only singleton (no class_name — avoids shadowing the global NavMeshManager autoload in tests).

extends Node

var _nav_region: NavigationRegion3D = null
var _baking: bool = false
var _queue_bake: bool = false


func _ready() -> void:
	# nav_mesh_rebake_requested is wired for future dynamic terrain / geometry changes.
	# MVP: terrain navmesh is baked once at load; buildings use NavigationObstacle3D (see BuildingBase)
	# via HexGrid placement — no runtime rebake. Nothing in gameplay emits this signal yet.
	if not SignalBus.nav_mesh_rebake_requested.is_connected(request_rebake):
		SignalBus.nav_mesh_rebake_requested.connect(request_rebake)


func register_region(region: NavigationRegion3D) -> void:
	if _nav_region != null and is_instance_valid(_nav_region):
		if _nav_region.bake_finished.is_connected(_on_bake_finished):
			_nav_region.bake_finished.disconnect(_on_bake_finished)
	_nav_region = region
	if _nav_region == null:
		return
	if _nav_region.bake_finished.is_connected(_on_bake_finished):
		return
	_nav_region.bake_finished.connect(_on_bake_finished)


func request_rebake() -> void:
	if _nav_region == null:
		push_warning("NavMeshManager.request_rebake: no NavigationRegion3D registered.")
		return
	if _baking:
		_queue_bake = true
	else:
		_queue_bake = false
		_nav_region.bake_navigation_mesh(true)
		_baking = true


func _on_bake_finished() -> void:
	_baking = false
	if _queue_bake:
		request_rebake()
