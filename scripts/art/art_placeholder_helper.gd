## =============================================================================
## ArtPlaceholderHelper
## res://scripts/art/art_placeholder_helper.gd
##
## Stateless utility class for resolving placeholder art resources (Mesh,
## Material, Texture2D) based on Types enums and string IDs.
##
## DEVIATION: Icon pipeline is POST-MVP stubbed (helper returns null).
## =============================================================================
class_name ArtPlaceholderHelper
extends RefCounted

# ---------------------------------------------------------------------------
# Private caches — keyed by enum int or StringName
# ---------------------------------------------------------------------------
static var _enemy_mesh_cache: Dictionary = {}
static var _building_mesh_cache: Dictionary = {}
static var _ally_mesh_cache: Dictionary = {}
static var _faction_material_cache: Dictionary = {}
static var _enemy_material_cache: Dictionary = {}
static var _building_material_cache: Dictionary = {}
static var _unknown_mesh_cache: Mesh = null
static var _building_icon_cache: Dictionary = {}
static var _enemy_icon_cache: Dictionary = {}
static var _ally_icon_cache: Dictionary = {}
static var _fallback_icon_texture: Texture2D = null

# ---------------------------------------------------------------------------
# ART ROOT CONSTANTS
# ---------------------------------------------------------------------------
const ART_ROOT_MESHES_ENEMIES: String = "res://art/meshes/enemies/"
const ART_ROOT_MESHES_BUILDINGS: String = "res://art/meshes/buildings/"
const ART_ROOT_MESHES_ALLIES: String = "res://art/meshes/allies/"
const ART_ROOT_MESHES_MISC: String = "res://art/meshes/misc/"
const ART_ROOT_MATERIALS_FACTIONS: String = "res://art/materials/factions/"
const ART_ROOT_MATERIALS_TYPES: String = "res://art/materials/types/"
const ART_ROOT_ICONS_ENEMIES: String = "res://art/icons/enemies/"
const ART_ROOT_ICONS_BUILDINGS: String = "res://art/icons/buildings/"
const ART_ROOT_ICONS_ALLIES: String = "res://art/icons/allies/"

# POST-MVP: Generated asset roots — checked before placeholders
const ART_GEN_MESHES: String = "res://art/generated/meshes/"
const ART_GEN_ICONS: String = "res://art/generated/icons/"
## Modular building kit GLBs (`FUTURE_3D_MODELS_PLAN.md` §4).
const ART_GEN_KIT: String = "res://art/generated/kit/"
## Vertical offset for the top kit slot (base sits at origin).
const KIT_TOP_SLOT_Y: float = 1.0

# ---------------------------------------------------------------------------
# PUBLIC API — MESHES
# ---------------------------------------------------------------------------

static func get_enemy_mesh(enemy_type: Types.EnemyType) -> Mesh:
	if _enemy_mesh_cache.has(enemy_type):
		return _enemy_mesh_cache[enemy_type] as Mesh
	var token: String = _get_enemy_token(enemy_type)
	var mesh: Mesh = _load_mesh_with_generated_fallback(
		ART_GEN_MESHES + "enemy_%s.tres" % token,
		ART_ROOT_MESHES_ENEMIES + "enemy_%s.tres" % token,
		"enemy mesh for %s" % token
	)
	_enemy_mesh_cache[enemy_type] = mesh
	return mesh


static func get_building_mesh(building_type: Types.BuildingType) -> Mesh:
	if _building_mesh_cache.has(building_type):
		return _building_mesh_cache[building_type] as Mesh
	var token: String = _get_building_token(building_type)
	var mesh: Mesh = _load_mesh_with_generated_fallback(
		ART_GEN_MESHES + "building_%s.tres" % token,
		ART_ROOT_MESHES_BUILDINGS + "building_%s.tres" % token,
		"building mesh for %s" % token
	)
	_building_mesh_cache[building_type] = mesh
	return mesh


static func get_ally_mesh(ally_id: StringName) -> Mesh:
	if _ally_mesh_cache.has(ally_id):
		return _ally_mesh_cache[ally_id] as Mesh
	var token: String = _get_ally_token(ally_id)
	var mesh: Mesh = _load_mesh_with_generated_fallback(
		ART_GEN_MESHES + "ally_%s.tres" % token,
		ART_ROOT_MESHES_ALLIES + "ally_%s.tres" % token,
		"ally mesh for %s" % token
	)
	_ally_mesh_cache[ally_id] = mesh
	return mesh


static func get_tower_mesh() -> Mesh:
	var path: String = ART_GEN_MESHES + "tower_core.tres"
	if ResourceLoader.exists(path):
		var mesh: Mesh = ResourceLoader.load(path) as Mesh
		if mesh != null:
			return mesh
	return _load_mesh(ART_ROOT_MESHES_MISC + "tower_core.tres", "tower_core")


static func get_unknown_mesh() -> Mesh:
	if _unknown_mesh_cache != null:
		return _unknown_mesh_cache
	_unknown_mesh_cache = _load_mesh(ART_ROOT_MESHES_MISC + "unknown_mesh.tres", "unknown_mesh")
	return _unknown_mesh_cache


## Assembles two kit MeshInstance3D children (base at y=0, top at `KIT_TOP_SLOT_Y`) under a Node3D root.
## Loads `res://art/generated/kit/<piece>.glb` per enum; missing files use BoxMesh placeholders.
static func get_building_kit_mesh(
		base_id: Types.BuildingBaseMesh,
		top_id: Types.BuildingTopMesh,
		accent: Color
	) -> Node3D:
	var root: Node3D = Node3D.new()
	var base_path: String = _get_building_kit_base_glb_path(base_id)
	var top_path: String = _get_building_kit_top_glb_path(top_id)
	var base_mi: MeshInstance3D = _make_kit_mesh_instance_from_glb_or_box(base_path)
	base_mi.position = Vector3.ZERO
	var top_mi: MeshInstance3D = _make_kit_mesh_instance_from_glb_or_box(top_path)
	top_mi.position = Vector3(0.0, KIT_TOP_SLOT_Y, 0.0)
	_apply_accent_to_top_mesh(top_mi, accent)
	root.add_child(base_mi)
	root.add_child(top_mi)
	return root


static func _get_building_kit_base_glb_path(base_id: Types.BuildingBaseMesh) -> String:
	var file_name: String = ""
	match base_id:
		Types.BuildingBaseMesh.STONE_ROUND:
			file_name = "stone_base_round.glb"
		Types.BuildingBaseMesh.STONE_SQUARE:
			file_name = "stone_base_square.glb"
		Types.BuildingBaseMesh.WOOD_ROUND:
			file_name = "wood_base_round.glb"
		Types.BuildingBaseMesh.RUINS_BASE:
			file_name = "ruins_base.glb"
		_:
			file_name = "stone_base_round.glb"
	return ART_GEN_KIT + file_name


static func _get_building_kit_top_glb_path(top_id: Types.BuildingTopMesh) -> String:
	var file_name: String = ""
	match top_id:
		Types.BuildingTopMesh.ROOF_CONE:
			file_name = "roof_cone.glb"
		Types.BuildingTopMesh.ROOF_FLAT:
			file_name = "roof_flat.glb"
		Types.BuildingTopMesh.GLASS_DOME:
			file_name = "glass_dome.glb"
		Types.BuildingTopMesh.FIRE_BOWL:
			file_name = "fire_bowl.glb"
		Types.BuildingTopMesh.POISON_TANK:
			file_name = "poison_tank.glb"
		Types.BuildingTopMesh.BALLISTA_FRAME:
			file_name = "ballista_frame.glb"
		Types.BuildingTopMesh.EMBRASURE:
			file_name = "embrasure.glb"
		_:
			file_name = "roof_cone.glb"
	return ART_GEN_KIT + file_name


static func _find_first_mesh_instance3d(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			return n as MeshInstance3D
		for c: Node in n.get_children():
			stack.append(c)
	return null


static func _make_kit_mesh_instance_from_glb_or_box(glb_path: String) -> MeshInstance3D:
	var mi: MeshInstance3D = MeshInstance3D.new()
	if ResourceLoader.exists(glb_path):
		var loaded: Resource = ResourceLoader.load(glb_path)
		if loaded is PackedScene:
			var scene_instance: Node = (loaded as PackedScene).instantiate()
			var src_mi: MeshInstance3D = _find_first_mesh_instance3d(scene_instance)
			if src_mi != null and src_mi.mesh != null:
				mi.mesh = src_mi.mesh
			scene_instance.queue_free()
	if mi.mesh == null:
		var box: BoxMesh = BoxMesh.new()
		mi.mesh = box
	return mi


static func _apply_accent_to_top_mesh(mi: MeshInstance3D, accent: Color) -> void:
	if mi.mesh == null:
		return
	var surface_count: int = mi.mesh.get_surface_count()
	if surface_count <= 0:
		return
	var mat: Material = mi.get_active_material(0)
	if mat != null:
		var dup: Material = mat.duplicate() as Material
		if dup is StandardMaterial3D:
			(dup as StandardMaterial3D).albedo_color = accent
			mi.set_surface_override_material(0, dup)
		else:
			# Non-standard materials: still override surface 0 with a solid accent for gameplay readability.
			var sm: StandardMaterial3D = StandardMaterial3D.new()
			sm.albedo_color = accent
			mi.set_surface_override_material(0, sm)
	else:
		var sm_new: StandardMaterial3D = StandardMaterial3D.new()
		sm_new.albedo_color = accent
		mi.set_surface_override_material(0, sm_new)

# ---------------------------------------------------------------------------
# PUBLIC API — MATERIALS
# ---------------------------------------------------------------------------

static func get_faction_material(faction_id: StringName) -> Material:
	if _faction_material_cache.has(faction_id):
		return _faction_material_cache[faction_id] as Material
	var token: String = _get_faction_token(faction_id)
	var path: String = ART_ROOT_MATERIALS_FACTIONS + "faction_%s_material.tres" % token
	var mat: Material = _load_material(path, "faction material for %s" % faction_id)
	_faction_material_cache[faction_id] = mat
	return mat


static func get_enemy_material(enemy_type: Types.EnemyType) -> Material:
	# Returns type-specific material if it exists; falls back to faction material.
	if _enemy_material_cache.has(enemy_type):
		return _enemy_material_cache[enemy_type] as Material
	var token: String = _get_enemy_token(enemy_type)
	var path: String = ART_ROOT_MATERIALS_TYPES + "enemy_%s_material.tres" % token

	var mat: Material = null
	if ResourceLoader.exists(path):
		mat = ResourceLoader.load(path) as Material
	if mat == null:
		mat = get_faction_material(_get_enemy_faction(enemy_type))

	_enemy_material_cache[enemy_type] = mat
	return mat


static func get_building_material(building_type: Types.BuildingType) -> Material:
	# Returns type-specific material if it exists; falls back to neutral faction.
	if _building_material_cache.has(building_type):
		return _building_material_cache[building_type] as Material
	var token: String = _get_building_token(building_type)
	var path: String = ART_ROOT_MATERIALS_TYPES + "building_%s_material.tres" % token

	var mat: Material = null
	if ResourceLoader.exists(path):
		mat = ResourceLoader.load(path) as Material
	if mat == null:
		mat = get_faction_material("neutral")

	_building_material_cache[building_type] = mat
	return mat

# ---------------------------------------------------------------------------
# PUBLIC API — ICONS (PNG under res://art/icons/** or generated/icons)
# ---------------------------------------------------------------------------

static func get_enemy_icon(enemy_type: Types.EnemyType) -> Texture2D:
	if _enemy_icon_cache.has(enemy_type):
		return _enemy_icon_cache[enemy_type] as Texture2D
	var token: String = _get_enemy_token(enemy_type)
	var tex: Texture2D = _load_icon_texture(
		ART_GEN_ICONS + "enemy_%s.png" % token,
		ART_ROOT_ICONS_ENEMIES + "%s.png" % token
	)
	if tex == null:
		tex = _get_fallback_icon_texture()
	_enemy_icon_cache[enemy_type] = tex
	return tex


static func get_building_icon(building_type: Types.BuildingType) -> Texture2D:
	if _building_icon_cache.has(building_type):
		return _building_icon_cache[building_type] as Texture2D
	var token: String = _get_building_token(building_type)
	var tex: Texture2D = _load_icon_texture(
		ART_GEN_ICONS + "building_%s.png" % token,
		ART_ROOT_ICONS_BUILDINGS + "%s.png" % token
	)
	if tex == null:
		tex = _get_fallback_icon_texture()
	_building_icon_cache[building_type] = tex
	return tex


static func get_ally_icon(ally_id: String) -> Texture2D:
	var id_key: StringName = StringName(ally_id)
	if _ally_icon_cache.has(id_key):
		return _ally_icon_cache[id_key] as Texture2D
	var token: String = _get_ally_token(id_key)
	var tex: Texture2D = _load_icon_texture(
		ART_GEN_ICONS + "ally_%s.png" % token,
		ART_ROOT_ICONS_ALLIES + "%s.png" % token
	)
	if tex == null:
		tex = _get_fallback_icon_texture()
	_ally_icon_cache[id_key] = tex
	return tex

# ---------------------------------------------------------------------------
# CACHE MANAGEMENT
# ---------------------------------------------------------------------------

static func clear_cache() -> void:
	_enemy_mesh_cache.clear()
	_building_mesh_cache.clear()
	_ally_mesh_cache.clear()
	_faction_material_cache.clear()
	_enemy_material_cache.clear()
	_building_material_cache.clear()
	_unknown_mesh_cache = null
	_building_icon_cache.clear()
	_enemy_icon_cache.clear()
	_ally_icon_cache.clear()


static func _get_fallback_icon_texture() -> Texture2D:
	if _fallback_icon_texture != null:
		return _fallback_icon_texture
	var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	_fallback_icon_texture = ImageTexture.create_from_image(img)
	return _fallback_icon_texture


static func _load_icon_texture(generated_path: String, placeholder_path: String) -> Texture2D:
	if ResourceLoader.exists(generated_path):
		var t: Texture2D = ResourceLoader.load(generated_path) as Texture2D
		if t != null:
			return t
	if ResourceLoader.exists(placeholder_path):
		var t2: Texture2D = ResourceLoader.load(placeholder_path) as Texture2D
		if t2 != null:
			return t2
	return null

# ---------------------------------------------------------------------------
# PRIVATE — TOKEN MAPPINGS
# ---------------------------------------------------------------------------

static func _get_enemy_token(enemy_type: Types.EnemyType) -> String:
	var i: int = int(enemy_type)
	var keys: Array = Types.EnemyType.keys()
	if i >= 0 and i < keys.size():
		return str(keys[i]).to_lower()
	return "unknown"


static func _get_building_token(building_type: Types.BuildingType) -> String:
	var i: int = int(building_type)
	var keys: Array = Types.BuildingType.keys()
	if i >= 0 and i < keys.size():
		return str(keys[i]).to_lower()
	return "unknown"


static func _get_faction_token(faction_id: StringName) -> String:
	# ASSUMPTION: Faction tokens are plain strings until a Types.Faction enum exists.
	match faction_id:
		"orcs":
			return "orcs"
		"plague":
			return "plague"
		"allies":
			return "allies"
		_:
			return "neutral"


static func _get_ally_token(ally_id: StringName) -> String:
	match ally_id:
		"arnulf":
			return "arnulf"
		_:
			return String(ally_id).to_lower()


static func _get_enemy_faction(enemy_type: Types.EnemyType) -> StringName:
	# ASSUMPTION: Orc* enemies are "orcs"; Plague Zombie is "plague"; others default to "neutral".
	match enemy_type:
		Types.EnemyType.ORC_GRUNT, Types.EnemyType.ORC_BRUTE, Types.EnemyType.ORC_ARCHER:
			return "orcs"
		Types.EnemyType.PLAGUE_ZOMBIE:
			return "plague"
		_:
			return "neutral"

# ---------------------------------------------------------------------------
# PRIVATE — LOADING HELPERS
# ---------------------------------------------------------------------------

static func _load_mesh_with_generated_fallback(
	generated_path: String,
	placeholder_path: String,
	context: String
) -> Mesh:
	# POST-MVP: generated assets in res://art/generated/ take priority.
	if ResourceLoader.exists(generated_path):
		var m: Mesh = ResourceLoader.load(generated_path) as Mesh
		if m != null:
			return m
	return _load_mesh(placeholder_path, context)


static func _load_mesh(path: String, context: String) -> Mesh:
	if ResourceLoader.exists(path):
		var m: Mesh = ResourceLoader.load(path) as Mesh
		if m != null:
			return m

	push_warning(
		"ArtPlaceholderHelper: Missing %s at '%s'. Using unknown_mesh fallback." % [context, path]
	)
	# Avoid infinite recursion: only recurse for non-unknown requests.
	if path.find("unknown_mesh") == -1:
		return get_unknown_mesh()
	return null


static func _load_material(path: String, context: String) -> Material:
	if ResourceLoader.exists(path):
		var m: Material = ResourceLoader.load(path) as Material
		if m != null:
			return m

	push_warning(
		"ArtPlaceholderHelper: Missing %s at '%s'. Using neutral faction fallback." % [context, path]
	)

	var neutral: String = ART_ROOT_MATERIALS_FACTIONS + "faction_neutral_material.tres"
	if path != neutral and ResourceLoader.exists(neutral):
		return ResourceLoader.load(neutral) as Material
	return null

