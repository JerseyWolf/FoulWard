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
# PUBLIC API — ICONS (POST-MVP stubs)
# ---------------------------------------------------------------------------

static func get_enemy_icon(_enemy_type: Types.EnemyType) -> Texture2D:
	# POST-MVP: implement when icon pipeline is ready.
	push_warning("ArtPlaceholderHelper: get_enemy_icon is POST-MVP and not yet implemented.")
	return null


static func get_building_icon(_building_type: Types.BuildingType) -> Texture2D:
	# POST-MVP: implement when icon pipeline is ready.
	push_warning("ArtPlaceholderHelper: get_building_icon is POST-MVP and not yet implemented.")
	return null


static func get_ally_icon(_ally_id: StringName) -> Texture2D:
	# POST-MVP: implement when icon pipeline is ready.
	push_warning("ArtPlaceholderHelper: get_ally_icon is POST-MVP and not yet implemented.")
	return null

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

# ---------------------------------------------------------------------------
# PRIVATE — TOKEN MAPPINGS
# ---------------------------------------------------------------------------

static func _get_enemy_token(enemy_type: Types.EnemyType) -> String:
	match enemy_type:
		Types.EnemyType.ORC_GRUNT:
			return "orc_grunt"
		Types.EnemyType.ORC_BRUTE:
			return "orc_brute"
		Types.EnemyType.GOBLIN_FIREBUG:
			return "goblin_firebug"
		Types.EnemyType.PLAGUE_ZOMBIE:
			return "plague_zombie"
		Types.EnemyType.ORC_ARCHER:
			return "orc_archer"
		Types.EnemyType.BAT_SWARM:
			return "bat_swarm"
		_:
			return "unknown"


static func _get_building_token(building_type: Types.BuildingType) -> String:
	match building_type:
		Types.BuildingType.ARROW_TOWER:
			return "arrow_tower"
		Types.BuildingType.FIRE_BRAZIER:
			return "fire_brazier"
		Types.BuildingType.MAGIC_OBELISK:
			return "magic_obelisk"
		Types.BuildingType.POISON_VAT:
			return "poison_vat"
		Types.BuildingType.BALLISTA:
			return "ballista"
		Types.BuildingType.ARCHER_BARRACKS:
			return "archer_barracks"
		Types.BuildingType.ANTI_AIR_BOLT:
			return "anti_air_bolt"
		Types.BuildingType.SHIELD_GENERATOR:
			return "shield_generator"
		_:
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

