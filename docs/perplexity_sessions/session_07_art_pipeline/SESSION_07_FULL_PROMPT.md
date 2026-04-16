PROMPT:

# Session 7: 3D Art Pipeline Integration & Wiring

## Goal
Finalize the integration between the 3D art pipeline (reference sheet -> Rodin -> rig -> animate -> Godot import) and the existing ArtPlaceholderHelper / RiggedVisualWiring code. Standardize AnimationPlayer clip names, document the exact GLB drop zones, and resolve conflicts between the pipeline doc and cut features.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `art_placeholder_helper.gd` — Runtime mesh/material resolver; production GLBs auto-override placeholders
- `rigged_visual_wiring.gd` — GLB mount + animation mapping; maps entity types to GLB paths
- `FUTURE_3D_MODELS_PLAN.md` — Production 3D art roadmap (complete file under **FILES:** below)
- `FOUL WARD 3D ART PIPELINE.txt` — Full 5-stage art pipeline strategy document (complete file under **FILES:** below)
- `enemy_base.gd` — EnemyBase script; lines 1-50 covering visual slot setup
- `arnulf.gd` — Arnulf script; lines 130-140 covering ArnulfVisual
- `boss_base.gd` — BossBase script; lines 40-50 covering BossVisual

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: 3D art pipeline integration, animation standardization, and validation tooling.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

CONFLICT: The pipeline doc lists "drunk_idle (swaying variation) — Arnulf only" as a required animation. The Arnulf drunkenness system is FORMALLY CUT. Remove drunk_idle from the animation requirements.

REQUIREMENTS:
1. Produce a definitive animation clip name table for every entity type:
   - Enemies (all 30 types): idle, walk, attack, hit_react, death, spawn (optional)
   - Allies (Arnulf + mercenaries): idle, run, attack_melee, hit_react, death, downed, recovering
   - Florence/Sybil (Tower): idle, shoot, hit_react, cast_spell, victory, defeat
   - Buildings: idle, active, destroyed
   - Bosses: idle, walk, attack, death, phase_transition (optional)

2. Document the exact GLB drop zone paths for each entity category:
   - res://art/generated/enemies/{enemy_type_lowercase}.glb
   - res://art/generated/allies/{ally_id}.glb
   - res://art/generated/bosses/{boss_id}.glb
   - res://art/generated/buildings/{building_type_lowercase}.glb
   - res://art/characters/{character_name}/{character_name}.glb

3. Design a validation script (tools/validate_art_assets.gd) that scans all GLB files under res://art/, checks required animation clips exist, reports missing clips/wrong names/unexpected files.

4. For each TODO(ART) marker, specify what production art replaces:
   - ally_base.gd:206 — GLB from RiggedVisualWiring for ally_id
   - arnulf.gd:134 — res://art/generated/allies/arnulf.glb
   - tower.gd:82 — res://art/characters/florence/florence.glb
   - boss_base.gd:46 — GLB from RiggedVisualWiring for boss_id
   - hub.gd:35 — 2D character portraits from res://art/icons/characters/

5. Update the 3D art pipeline doc: remove drunk_idle from Arnulf's animation list.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.

CONTEXT_BRIEF:

# Context Brief — Session 7: Art Pipeline

## Art Pipeline (§22)

PLACEHOLDER SYSTEM EXISTS; PRODUCTION ART PLANNED

ArtPlaceholderHelper, RiggedVisualWiring, PlaceholderIconGenerator. All combat/hub scenes marked TODO(ART).

- ArtPlaceholderHelper resolves meshes by type enum and string ID. Production GLBs at correct paths auto-override placeholders.
- RiggedVisualWiring maps enemy types and allies to GLB paths under res://art/generated/. It mounts GLB scenes into visual slots and drives idle/walk animations via AnimationPlayer.

## TODO(ART) Markers in Codebase

| File | Line | What It Marks |
|------|------|---------------|
| scenes/allies/ally_base.gd | 206 | Placeholder visual for ally — replace with GLB |
| scenes/arnulf/arnulf.gd | 134 | ArnulfVisual placeholder — replace with production GLB |
| scenes/tower/tower.gd | 82 | Tower/Florence visual — replace with production model |
| scenes/bosses/boss_base.gd | 46 | BossVisual placeholder — replace with boss GLB |
| ui/hub.gd | 35 | Hub character portraits — replace with 2D art |

## Formally Cut Features (§31)

| Feature | Status |
|---------|--------|
| Arnulf drunkenness system | FORMALLY CUT — drunk_idle animation must be removed from requirements |
| Time Stop spell | FORMALLY CUT |
| Hades-style 3D navigable hub | FORMALLY CUT |

## EnemyType Enum (30 values — for animation table)

ORC_GRUNT(0), ORC_BRUTE(1), GOBLIN_FIREBUG(2), PLAGUE_ZOMBIE(3), ORC_ARCHER(4), BAT_SWARM(5), ORC_SKIRMISHER(6), ORC_RATLING(7), GOBLIN_RUNTS(8), HOUND(9), ORC_RAIDER(10), ORC_MARKSMAN(11), WAR_SHAMAN(12), PLAGUE_SHAMAN(13), TOTEM_CARRIER(14), HARPY_SCOUT(15), ORC_SHIELDBEARER(16), ORC_BERSERKER(17), ORC_SABOTEUR(18), HEXBREAKER(19), WYVERN_RIDER(20), BROOD_CARRIER(21), TROLL(22), IRONCLAD_CRUSHER(23), ORC_OGRE(24), WAR_BOAR(25), ORC_SKYTHROWER(26), WARLORDS_GUARD(27), ORCISH_SPIRIT(28), PLAGUE_HERALD(29).

## BuildingType Enum (36 values — for animation table)

ARROW_TOWER(0) through CITADEL_AURA(35). See uploaded types.gd for full list.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus

FILES:

# Files to Upload for Session 7: Art Pipeline

**Errata (single-file bundle):** The standalone file `FILES_TO_UPLOAD.md` is **not** attached for Perplexity. This manifest exists for repo maintainers; for Perplexity, its entire contents (this list and the full text of every path below) are merged into `SESSION_07_FULL_PROMPT.md` in this folder.

Listed repository paths:

1. `scripts/art/art_placeholder_helper.gd` — Runtime mesh/material resolver; full file (~444 lines)
2. `scripts/art/rigged_visual_wiring.gd` — GLB mount + animation mapping; full file (~117 lines)
3. `FUTURE_3D_MODELS_PLAN.md` — Production 3D art roadmap; full file (~321 lines)
4. `docs/FOUL WARD 3D ART PIPELINE.txt` — Full 5-stage art pipeline strategy (~358 lines)
5. `scenes/enemies/enemy_base.gd` — EnemyBase; lines 1-50 covering visual slot setup (~50 lines)
6. `scenes/arnulf/arnulf.gd` — Arnulf; lines 130-140 covering ArnulfVisual (~10 lines)
7. `scenes/bosses/boss_base.gd` — BossBase; lines 40-50 covering BossVisual (~10 lines)

Total estimated token load: ~1,310 lines across 7 files

Note: art_placeholder_helper.gd (444 lines) is the largest file. If Perplexity context is tight, upload lines 1-200 only (mesh resolution logic; the rest is material lookup tables).

scripts/art/art_placeholder_helper.gd:
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


scripts/art/rigged_visual_wiring.gd:
## RiggedVisualWiring
## Paths to Blender batch GLBs (see art/generated/generation_log.json) + helpers to mount scenes.
## Visual-only: no gameplay state; used by EnemyBase, BossBase, Arnulf.

class_name RiggedVisualWiring
extends RefCounted

const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"
const ANIM_DEATH: StringName = &"death"

const LOC_BLEND_SEC: float = 0.12
const LOC_VELOCITY_EPSILON: float = 0.12

const ALLY_ARNULF_GLB: String = "res://art/generated/allies/arnulf.glb"


static func clear_visual_slot(visual_slot: Node3D) -> void:
	if visual_slot == null:
		return
	var kids: Array[Node] = visual_slot.get_children()
	for n: Node in kids:
		n.free()


static func find_animation_player(root: Node) -> AnimationPlayer:
	if root == null:
		return null
	return root.find_child("AnimationPlayer", true, false) as AnimationPlayer


static func enemy_rigged_glb_path(enemy_type: Types.EnemyType) -> String:
	match enemy_type:
		Types.EnemyType.ORC_GRUNT:
			return "res://art/generated/enemies/orc_grunt.glb"
		Types.EnemyType.ORC_BRUTE:
			return "res://art/generated/enemies/orc_brute.glb"
		Types.EnemyType.GOBLIN_FIREBUG:
			return "res://art/generated/enemies/goblin_firebug.glb"
		Types.EnemyType.PLAGUE_ZOMBIE:
			return "res://art/generated/enemies/plague_zombie.glb"
		Types.EnemyType.ORC_ARCHER:
			return "res://art/generated/enemies/orc_archer.glb"
		_:
			return ""


static func boss_rigged_glb_path(boss_id: String) -> String:
	match boss_id:
		"plague_cult_miniboss":
			return "res://art/generated/bosses/plague_cult_miniboss.glb"
		"orc_warlord":
			return "res://art/generated/bosses/orc_warlord.glb"
		"final_boss":
			return "res://art/generated/bosses/final_boss.glb"
		"audit5_territory_mini":
			return "res://art/generated/bosses/audit5_territory_mini.glb"
		_:
			return ""


## Instances GLB PackedScene under slot; returns first AnimationPlayer in subtree, or null.
static func mount_glb_scene(visual_slot: Node3D, glb_path: String) -> AnimationPlayer:
	if visual_slot == null:
		return null
	clear_visual_slot(visual_slot)
	if glb_path.is_empty() or not ResourceLoader.exists(glb_path):
		return null
	var packed: PackedScene = load(glb_path) as PackedScene
	if packed == null:
		return null
	var inst: Node = packed.instantiate()
	visual_slot.add_child(inst)
	return find_animation_player(inst)


## Primitive MeshInstance3D fallback (e.g. bat swarm — no skeleton in batch log).
static func mount_enemy_placeholder_mesh(visual_slot: Node3D, enemy_data: EnemyData) -> void:
	if visual_slot == null or enemy_data == null:
		return
	clear_visual_slot(visual_slot)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "PlaceholderMesh"
	mi.mesh = ArtPlaceholderHelper.get_enemy_mesh(enemy_data.enemy_type)
	mi.material_override = ArtPlaceholderHelper.get_enemy_material(enemy_data.enemy_type)
	visual_slot.add_child(mi)


static func mount_boss_placeholder_mesh(visual_slot: Node3D) -> void:
	if visual_slot == null:
		return
	clear_visual_slot(visual_slot)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "BossPlaceholderMesh"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(1.1, 1.1, 1.1)
	mi.mesh = box
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.15, 0.65)
	mi.material_override = mat
	visual_slot.add_child(mi)


static func update_locomotion_animation(
	animation_player: AnimationPlayer,
	horizontal_speed: float,
	current_anim: StringName
) -> StringName:
	if animation_player == null:
		return current_anim
	var want: StringName = ANIM_WALK if horizontal_speed > LOC_VELOCITY_EPSILON else ANIM_IDLE
	if want == current_anim:
		return current_anim
	if not animation_player.has_animation(want):
		return current_anim
	animation_player.play(want, LOC_BLEND_SEC)
	return want

FUTURE_3D_MODELS_PLAN.md:
# Foul Ward — Future 3D Models & Art Pipeline Plan

## 1. Overview

This document is the **authoritative roadmap** for moving Foul Ward from **Blender-generated Rigify placeholders** and **primitive `.tres` meshes** to **production 3D assets** (and matching **2D hub portraits**). It complements:

- **`ArtPlaceholderHelper`** (`res://scripts/art/art_placeholder_helper.gd`) — runtime resolution of **Mesh** / **Material** from `res://art/meshes/**` with optional override from `res://art/generated/meshes/*.tres` (legacy path). There is **no** `resolve_mesh()` API; use **`get_enemy_mesh()`**, **`get_building_mesh()`**, **`get_ally_mesh()`**, etc., typically from **`initialize()`** on combat units (not `_ready()`), after `EnemyData` / `BuildingData` is available. **GLB files** live under `res://art/generated/{enemies,allies,buildings,bosses,misc}/` and are intended to be **swapped in** as imported `PackedScene` roots when gameplay scenes are refactored to use skeletal animation.
- **`res://art/generated/`** — batch output from `tools/generate_placeholder_glbs_blender.py` (Blender 4.x headless). Regenerate after changing faction shapes or animation keyframes.

**When to revisit:** at the start of any **art milestone** (vertical slice, trailer, or outsourcing); after **faction roster** changes; when **adding a new enemy/building/boss** type (update the Blender batch script + this file’s roster tables).

**Source of truth for placeholder inventory:** `res://art/generated/generation_log.json` (written by the generator; includes `godot_mcp.reload_project` metadata when verified).

---

## 2. Current placeholder status

Generated **2026-03-28** by `tools/generate_placeholder_glbs_blender.py` (Blender **4.0.2**).  
`current_mesh` = on-disk GLB path under `res://art/generated/`.  
**Clip names** in GLBs: `idle` (frames 1–60), `walk` (61–120), `death` (121–150) for animated entries.

| entity_id | type | current_mesh | has_rig | animations | placeholder_quality |
|-----------|------|--------------|---------|------------|---------------------|
| orc_grunt | enemies | res://art/generated/enemies/orc_grunt.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| orc_brute | enemies | res://art/generated/enemies/orc_brute.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| goblin_firebug | enemies | res://art/generated/enemies/goblin_firebug.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| plague_zombie | enemies | res://art/generated/enemies/plague_zombie.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| orc_archer | enemies | res://art/generated/enemies/orc_archer.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| bat_swarm | enemies | res://art/generated/enemies/bat_swarm.glb | no (Empty root) | idle, walk, death | empty_parent_animated |
| arnulf | allies | res://art/generated/allies/arnulf.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| arrow_tower | buildings | res://art/generated/buildings/arrow_tower.glb | no | — | static_primitive_composite |
| fire_brazier | buildings | res://art/generated/buildings/fire_brazier.glb | no | — | static_primitive_composite |
| magic_obelisk | buildings | res://art/generated/buildings/magic_obelisk.glb | no | — | static_primitive_composite |
| poison_vat | buildings | res://art/generated/buildings/poison_vat.glb | no | — | static_primitive_composite |
| ballista | buildings | res://art/generated/buildings/ballista.glb | no | — | static_primitive_composite |
| archer_barracks | buildings | res://art/generated/buildings/archer_barracks.glb | no | — | static_primitive_composite |
| anti_air_bolt | buildings | res://art/generated/buildings/anti_air_bolt.glb | no | — | static_primitive_composite |
| shield_generator | buildings | res://art/generated/buildings/shield_generator.glb | no | — | static_primitive_composite |
| plague_cult_miniboss | bosses | res://art/generated/bosses/plague_cult_miniboss.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| orc_warlord | bosses | res://art/generated/bosses/orc_warlord.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| final_boss | bosses | res://art/generated/bosses/final_boss.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| audit5_territory_mini | bosses | res://art/generated/bosses/audit5_territory_mini.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| tower_core | misc | res://art/generated/misc/tower_core.glb | no | — | static_misc |
| hex_slot | misc | res://art/generated/misc/hex_slot.glb | no | — | static_misc |
| projectile_crossbow | misc | res://art/generated/misc/projectile_crossbow.glb | no | — | static_misc |
| projectile_rapid_missile | misc | res://art/generated/misc/projectile_rapid_missile.glb | no | — | static_misc |
| unknown_mesh | misc | res://art/generated/misc/unknown_mesh.glb | no | — | static_misc |

---

## 3. Production asset pipeline (when ready)

Use this sequence whenever a placeholder GLB is replaced.

### a. Hyper3D / Rodin (text-to-3D)

1. Sign in at [hyper3d.ai](https://hyper3d.ai) (or your Rodin-capable tool).
2. Use a **faction style brief** (see §6) + **entity description** + **T-pose** + topology hint (`18k quad` for rank-and-file, `50k quad` for named characters / bosses).
3. Iterate on the **free preview**; pay to export the mesh package when silhouette reads well at **combat camera distance**.

### b. Blender — Rigify, bind

1. Import the **T-pose GLB/FBX** into Blender 4.x.
2. Enable **Rigify** add-on → add **Human Meta-Rig**, align to mesh.
3. **Parent mesh to metarig** → **Armature Deform with Automatic Weights**.
4. **Pose → Generate Rig**; verify deformation on `chest`, `upper_arm_fk.*`, `root`.

### c. Mixamo — animation pack

1. Export **T-pose** as FBX from Blender (no animation, Apply Transform as needed).
2. Upload to **Mixamo**; pick **idle**, **walk**, **run** (optional), **attack** variants, **death**.
3. Download **FBX for Unity** (binary, with skin) per clip — consistent skeleton.

### d. Blender — combine clips into one GLB

1. Import all Mixamo FBX files into one `.blend`.
2. Use **NLA Editor** or **Action strips** so each clip is a separate **Action** with a clear name (`idle`, `walk`, `attack_melee`, `death`).
3. Ensure **export_animation_mode=ACTIONS** compatibility (same as `tools/generate_placeholder_glbs_blender.py`).

### e. Export path (overwrite placeholder)

Export **GLB** to the **same path** as the batch tool:

`res://art/generated/<type>/<entity_id>.glb`

**Types:** `enemies`, `allies`, `buildings`, `bosses`, `misc`.

Godot reimports automatically; **ArtPlaceholderHelper** continues to resolve **primitive `.tres`** until scenes are switched to **instanced GLB** — plan a **scene refactor milestone** to load `PackedScene` instead of assigning `Mesh` only.

### f. Validate in Godot

1. **Godot MCP Pro:** `reload_project` after export.
2. Open imported scene: confirm **MeshInstance3D** (+ **Skeleton3D** + **AnimationPlayer** for rigged assets).
3. **GDAI MCP:** `get_godot_errors` after reimport; fix material or bone naming issues.

---

## §4 — Modular Building Kit

### Kit Pieces Required (12 total)
| ID (enum name)   | Filename                  | Used by towers            |
|------------------|---------------------------|---------------------------|
| STONE_ROUND      | stone_base_round.glb      | Arrow, Magic Obelisk, Ballista |
| STONE_SQUARE     | stone_base_square.glb     | Fire Brazier, Poison Vat, Shield Gen |
| WOOD_ROUND       | wood_base_round.glb       | Archer Barracks           |
| RUINS_BASE       | ruins_base.glb            | Ruins-tier towers         |
| ROOF_CONE        | roof_cone.glb             | Arrow Tower, Archer Barracks |
| ROOF_FLAT        | roof_flat.glb             | Shield Generator, Ballista base |
| GLASS_DOME       | glass_dome.glb            | Magic Obelisk             |
| FIRE_BOWL        | fire_bowl.glb             | Fire Brazier              |
| POISON_TANK      | poison_tank.glb           | Poison Vat                |
| BALLISTA_FRAME   | ballista_frame.glb        | Ballista                  |
| EMBRASURE        | embrasure.glb             | Arrow Tower, Archer Barracks |
| ARCH_WINDOW      | arch_window.glb           | All towers (optional detail) |

### Rodin Prompt Template
Use this prefix for all kit pieces to ensure visual consistency:

  "Medieval dark-fantasy stone architecture kit piece, single mesh,
  low-poly game asset, 800–1200 tris, PBR textures 512×512,
  muted desaturated palette, worn stone texture, no color variation
  on albedo, neutral grey base so faction accent_color ShaderMaterial
  override reads correctly. T-pose equivalent: upright, centered
  at origin, fits 1m × 1m × 1m bounding box. [PIECE DESCRIPTION]"

Replace [PIECE DESCRIPTION] per piece, e.g.:
  - stone_base_round: "Circular stone tower base, 1.2m diameter,
    rough-cut stone blocks, slight mossy weathering at base ring."
  - roof_cone: "Pointed conical slate roof cap, 0.8m base diameter,
    1.2m tall, slate tile texture, slight overhang edge."

### Attribution
Structural reference: alpapaydin/Godot-4-Tower-Defense-Template (MIT)
https://github.com/alpapaydin/Godot-4-Tower-Defense-Template

---

## 5. Entity-by-entity production TODO (roster)

**Priority legend:** **HIGH** = primary combat visibility; **MEDIUM** = allies / buildings; **LOW** = hub-only, escorts, or test-only.

Faction briefs are summarized in §6.

### Enemies (`res://resources/enemy_data/*.tres`)

- [ ] **orc_grunt** (enemies, Orc Raiders) — HIGH — Rodin: “Stocky green-brown orc infantry, leather straps, cleaver, **T-pose**, 18k quad, game RTS silhouette”. Anims: idle, walk, attack, death.
- [ ] **orc_brute** (Orc Raiders) — HIGH — “Heavy orc, oversized shoulders, slow menace, **T-pose**, 18k quad”. Anims: idle, walk, attack, death.
- [ ] **goblin_firebug** (neutral/goblin) — HIGH — “Small goblin alchemist, fire jars, hunched, **T-pose**, 18k quad”. Anims: idle, walk, throw, death.
- [ ] **plague_zombie** (Plague Cult) — HIGH — “Gaunt grey-green zombie, torn robes, **T-pose**, 18k quad”. Anims: idle, shamble, attack, death.
- [ ] **orc_archer** (Orc Raiders) — HIGH — “Lean orc archer, quiver, **T-pose**, 18k quad”. Anims: idle, walk, shoot, death.
- [ ] **bat_swarm** (flying) — MEDIUM — “Flattened bat cluster or single bat proxy, **T-pose** or wings spread neutral, 18k quad”. Anims: idle flap, move, death fall.

### Allies (`res://resources/ally_data/*.tres`)

- [ ] **arnulf** (allies) — HIGH — Named companion: “Armored humanoid defender, faction tan/brown, **T-pose**, 50k quad”. Anims: idle, walk, attack, downed/recover (custom), death.
- [ ] **ally_melee_generic** — MEDIUM — “Mercenary melee, modular armor, **T-pose**, 18k quad”. Anims: idle, walk, attack, death.
- [ ] **ally_ranged_generic** — MEDIUM — “Mercenary archer, **T-pose**, 18k quad”. Anims: idle, walk, shoot, death.
- [ ] **ally_support_generic** — MEDIUM — “Support staff silhouette, **T-pose**, 18k quad”. Anims: idle, walk, buff (placeholder), death.
- [ ] **anti_air_scout**, **hired_archer**, **defected_orc_captain** — MEDIUM/LOW — Reuse faction kits where possible; note **defected** narrative tint.

### Buildings (`res://resources/building_data/*.tres`)

Static meshes only (no skeleton). Priority **MEDIUM**.

- [ ] **arrow_tower**, **fire_brazier**, **magic_obelisk**, **poison_vat**, **ballista**, **archer_barracks**, **anti_air_bolt**, **shield_generator** — Rodin prompts: “Grey stone base + **faction accent** trim (see §6), **top-down RTS** readable, modular kit piece, no rig, 18k quad.”

### Bosses (`res://resources/boss_data/*.tres`)

- [ ] **plague_cult_miniboss** — HIGH — “Large plague cult champion, sickly green accents, **T-pose**, 50k quad”. Anims: idle, walk, phase attack, death.
- [ ] **orc_warlord** — HIGH — “Massive orc warlord, banners optional, **T-pose**, 50k quad”. Anims: idle, walk, heavy attack, death.
- [ ] **final_boss** — HIGH — “Archrot-themed end boss, unique silhouette, **T-pose**, 50k quad+”. Anims: idle, walk, multi-phase attacks, death.
- [ ] **audit5_territory_mini** — LOW (test) — Reuse miniboss kit or simple unique mesh.

### Hub characters (`res://resources/character_data/*.tres`)

**2D portraits only** for hub UI — see §7. **Florence** is referenced in dialogue but **no** `character_data` resource yet; add when hub roster expands.

---

## 6. Consistency strategy

**Faction style briefs** (embed in every Rodin / art brief):

| Faction | Visual keywords |
|---------|-----------------|
| **Orc Raiders** | Warm olive and brown leather, heavy silhouettes, asymmetric scrap armor, angular silhouettes. |
| **Plague Cult** | Desaturated grey-green, emaciated proportions, dripping organic accents, hoods and bandages. |
| **Allies / neutral merc** | Earthy tan and brown cloth, medium proportions, readable hero read. |
| **Buildings** | Grey stone base + **one** accent color per faction (orc: rust metal; plague: sickly green trim). |

**Seed locking:** store a **per-faction random seed** or **reference mood board URLs** in `docs/` (not in GDScript stats). Reuse **substance palette** hex codes across Rodin prompts for a given milestone.

**Visual coherence:** batch-generate **concept orthographic turns** (front/side) before full sculpt for heroes and bosses; reuse **weapon modules** across orc units.

---

## 7. Hub character portraits (2D)

Characters: **Florence** (player voice — UI only today), **Arnulf** hub, **merchant**, **researcher** (Sybil), **enchantress**, **mercenary captain**, **flavor NPC**. **Not** 3D combat models.

**TODO:** Commission or generate **512×512 PNG** portraits (consistent border lighting, transparent or dark oval crop).

**Placeholder:** `character_base_2d.tscn` uses **ColorRect** + **NameLabel**; swap **Body** to **TextureRect** when assets exist.

---

## 8. PhysicalBone3D ragdoll plan (Godot-side)

After production GLB import, **per humanoid** enemy and ally:

1. Open imported scene → select **Skeleton3D** → **PhysicalBone3D** wizard (or manual): spine, hips, limbs; **disable** on small enemies if performance requires.
2. Set **joint limits** (cone + twist) matching Rigify limb axes; cap **collision** layers to **ragdoll-only** vs **static** geometry.
3. On **`SignalBus.enemy_killed`** / ally death: call **`physical_bones_start_simulation()`** (or custom `enable_ragdoll()` on the character script) — **not** authored in Blender; **post-import** in Godot only.

**Flying / bat:** optional **simple jointed wing** ragdoll or **skip** ragdoll (instant dissolve VFX).

---

## 9. Animation state machine wiring plan

**Expected clip names** (match exported GLB): `idle`, `walk`, `death`; add `attack_*` when Mixamo/production clips exist.

| Scene / controller | AnimationPlayer owner | Signals / states driving clips |
|----------------------|----------------------|--------------------------------|
| **EnemyBase** (+ subclasses) | Child of GLB root or `EnemyMesh` sibling | **Navigation:** walk when `velocity.length() > epsilon`; else idle. **HealthComponent.health_depleted** → death (one-shot, **no** loop). |
| **BossBase** | Same as enemy | **boss_phase** (future): add `ability_cast` / `phase_transition`. **boss_killed** → death. |
| **Arnulf** | Under `Arnulf` root | **`Types.ArnulfState`:** IDLE/PATROL → idle; CHASE → walk; ATTACK → attack clip; DOWNED/RECOVERING → custom; death on incapacitate if added. |
| **AllyBase** | Generic ally root | Mirror enemy: chase → walk; attack → attack; death on `ally_killed`. |

**Note:** Current MVP assigns **`Mesh`** only; **AnimationTree** or **AnimationPlayer.play()** wiring is **post-placeholder**.

---

## 10. Tools and costs reference

| Stage | Tool | Cost pattern |
|-------|------|----------------|
| Placeholder mesh + Rigify + GLB | **Blender** (open source) | Free |
| glTF export dependency | **Python numpy** for Blender’s bundled Python | Free (`pip install --user numpy --break-system-packages` on PEP 668 distros, or `apt install python3-numpy` when available) |
| Text-to-3D preview | **Hyper3D / Rodin** | Free preview; pay per HD export |
| Rigging assist | **Mixamo** | Free autorig + clips for small teams |
| Retopo / cleanup | **Blender** | Free |
| **Upgrade trigger** | — | Move from placeholder to production when **trailer**, **vertical slice**, or **publisher** milestone requires readable silhouette at target resolution |

---

## §5 — Terrain System

### Architecture

TerrainContainer (Node3D in `main.tscn`) is cleared and repopulated each battle by `CampaignManager._load_terrain()`. Each terrain scene contains:

- GroundMesh + StaticBody3D (walkable ground)
- NavRegion (NavigationRegion3D, registered with NavMeshManager autoload)
- TerrainZones (Area3D with `terrain_zone.gd`, optional — SLOW effect only)
- Props (DestructibleProp / ImmovableProp containers, not yet implemented)

### Terrain Types Status

| Type       | Scene file                | Status    | Notes                     |
|------------|---------------------------|-----------|---------------------------|
| GRASSLAND  | terrain_grassland.tscn    | Done   | Flat 100×100 m ground + nav (covers spawn ring); no zones |
| SWAMP      | terrain_swamp.tscn        | Done   | Same arena; 0.55× speed zone          |
| FOREST     | terrain_forest.tscn       | TODO(TERRAIN) | Dense tree props, 0.75× zone |
| RUINS      | terrain_ruins.tscn        | TODO(TERRAIN) | Destructible pillars       |
| TUNDRA     | terrain_tundra.tscn       | TODO(TERRAIN) | 0.7× speed (snow), ice patches |

### DestructibleProp (Future)

Uses Jummit/godot-destruction-plugin (MIT):
https://github.com/Jummit/godot-destruction-plugin

On health_depleted: call destroy(), emit SignalBus.terrain_prop_destroyed, emit SignalBus.nav_mesh_rebake_requested → NavMeshManager queues rebake.

### Speed Zone Design Guide

- SLOW zones: use TerrainZone Area3D with speed_multiplier < 1.0
- IMPASSABLE zones: use NavigationObstacle3D with affect_navigation_mesh=true, baked into NavRegion before battle. Do NOT use TerrainZone for impassable.
- Overlapping zones: EnemyBase takes the MINIMUM multiplier automatically.

### Attribution

- Navmesh rebake queue pattern: community contributor, godotengine/godot#81181
  https://github.com/godotengine/godot/issues/81181 (public domain snippet)
- Navigation pattern reference: quiver-dev/tower-defense-tutorial (MIT)
  https://github.com/quiver-dev/tower-defense-tutorial
- Destructible props (future): Jummit/godot-destruction-plugin (MIT)
  https://github.com/Jummit/godot-destruction-plugin

---

## Appendix A — Scene art audit (verified 2026-03-29)

**Method:** Full-text grep `res://art/` across all `*.tscn` (seven files with `ext_resource` mesh/material paths); inline-mesh scenes listed separately. **Blender MCP `execute_blender_code` is not in this repo** — placeholders are produced by **`tools/generate_placeholder_glbs_blender.py`** (Blender headless). **Godot MCP Pro** `reload_project` after changes; **`get_editor_errors`** scanned for GLB import failures (none; only existing GDScript warnings such as `SHADOWED_GLOBAL_IDENTIFIER` on `ArtPlaceholderHelper` preload aliases).

| Scene | Art reference | Real file? | ArtPlaceholderHelper / mesh resolution | AnimationPlayer |
|-------|---------------|------------|----------------------------------------|-----------------|
| `scenes/enemies/enemy_base.tscn` | `art/meshes/enemies/enemy_orc_grunt.tres` + faction material | Yes (primitive `.tres`) | **`EnemyBase.initialize()`** → `get_enemy_mesh()` / `get_enemy_material()` (`_ready` only sets label) | Not present; GLB clips not wired |
| `scenes/buildings/building_base.tscn` | `unknown_mesh.tres` | Yes | **`BuildingBase.initialize()`** → `get_building_mesh()` / `get_building_material()` | None |
| `scenes/tower/tower.tscn` | `tower_core.tres` + neutral material | Yes | **`Tower._ready()`** → `get_tower_mesh()` | None (static) |
| `scenes/arnulf/arnulf.tscn` | `ally_arnulf.tres` + allies material | Yes | **`Arnulf._ready()`** → `get_ally_mesh("arnulf")` | Not present |
| `scenes/allies/ally_base.tscn` | Inline `BoxMesh` | N/A | **No** `initialize()` mesh hook for generic mercs yet (`# TODO(ART)` in script) | None |
| `scenes/bosses/boss_base.tscn` | Inline `BoxMesh` | N/A | **`initialize_boss_data()`** → **`EnemyBase.initialize()`** uses placeholder **EnemyData** mesh; **`_configure_visuals()`** tints only — boss GLB swap in `# TODO(ART)` | None |
| `scenes/hex_grid/hex_grid.tscn` | `hex_slot.tres` | Yes | Not via helper | None |
| `scenes/projectiles/projectile_base.tscn` | `projectile_crossbow.tres` | Yes | Not via helper | None |
| `ui/hub.tscn` | Character catalog / 2D scenes | N/A | 2D **ColorRect** portraits via `character_base_2d.tscn` | N/A |

**Gaps:** No `.tscn` references **`res://art/generated/*.glb`** directly; combat uses **`.tres` Mesh** or **inline** primitives. **Generated GLBs** exist on disk (see `generation_log.json`) with **Skeleton3D** where Rigify applied; **runtime** does not yet instance `PackedScene` from GLB. **Hub** has no `TextureRect` portraits yet.

**Godot MCP (2026-03-29):** `reload_project` → `Filesystem rescanned.` No new art import errors in editor error scan.

---

## Appendix B — Regenerating placeholders

```bash
cd /path/to/FoulWard
blender --background --python tools/generate_placeholder_glbs_blender.py
```

Requires **numpy** available to Blender’s Python (see §10).

docs/FOUL WARD 3D ART PIPELINE.txt:
=======================================================
FOUL WARD — 3D ART PIPELINE STRATEGY SUMMARY
=======================================================

OVERVIEW
--------
Goal: Generate production-quality 3D models for all Foul Ward 
characters, enemies, and buildings using AI tools, get them 
rigged, animated, and imported into Godot 4.

The pipeline has 5 stages:
1. Reference Sheet Generation (2D image AI)
2. 3D Model Generation (Rodin / Hyper3D)
3. Rigging & Skinning
4. Animation
5. Godot Import & Wiring

=======================================================
STAGE 1 — REFERENCE SHEET GENERATION
=======================================================

PURPOSE
-------
Before generating any 3D model, create a 2D turnaround 
reference sheet for every unit. This locks your design 
decisions (silhouette, proportions, color palette, armor 
coverage) and feeds Rodin's Image-to-3D mode, which 
produces dramatically better results than text-only 
generation.

TOOLS (in order of preference)
-------------------------------
1. CharacterGen (charactergen.app) — PURPOSE BUILT for 
   game dev turnaround sheets. Generates front/side/back 
   from a single text prompt. Mobile-friendly web UI. 
   Use this first.

2. Midjourney V7 — Best raw artistic quality. Use 
   --cref [image] (Character Reference flag) to lock 
   a design across multiple generations once you have 
   a base image. Good for iteration after CharacterGen 
   gives you a base.

3. FLUX.1 Kontext — Best cross-unit consistency. Feed 
   it reference images and it keeps new units visually 
   coherent with the existing roster. Use when generating 
   unit #10+ to ensure they still feel like the same game.

4. Ideogram 3.0 — Strong combined Character Reference 
   + Style Reference locking. Alternative to Midjourney.

5. This chat (GPT-4o Image) — Fast concept sketching, 
   good for quick first looks before committing to a 
   design direction.

WORKFLOW PER UNIT
-----------------
Step 1: Write text prompt (see prompt templates below)
Step 2: Generate in CharacterGen → get front/side/back sheet
Step 3: If result needs iteration → bring into Midjourney 
        with --cref referencing the CharacterGen output
Step 4: Save final approved sheet as:
        [unitname]_reference_sheet.png
Step 5: Feed this image into Rodin Image-to-3D mode

WHAT A REFERENCE SHEET MUST SHOW
---------------------------------
- Front view (most important)
- Right side view (silhouette thickness, weapon profile)
- Back view (cloaks, quivers, backpack details)
- 1-2 detail callouts (face close-up, key prop)
- Color swatches strip at bottom (3-5 colors labeled: 
  skin, armor, weapon, cloth, accent)
- FLAT white/grey background — no environment, no shadows
- Neutral T-pose or A-pose for all characters with limbs

MASTER STYLE FOOTER
-------------------
Add this VERBATIM to the end of every image generation prompt.
Never change the wording — consistency lives in this block.

  Art style: semi-realistic low-poly game character, 
  slightly exaggerated proportions (large hands, broad 
  shoulders, readable silhouette at small scale), 
  dark humor fantasy tone (Warhammer Fantasy meets 
  Terry Pratchett), warm desaturated earth tones, 
  stylized PBR materials, baked ambient occlusion. 
  White background, character turnaround sheet, 
  front/side/back views, no cast shadows, T-pose.

FACTION COLOR ANCHORS
---------------------
Add one of these lines before the master footer for 
faction-specific color consistency:

  ORC RAIDERS:
  Faction palette: dark green skin, rust iron armor, 
  cracked leather, tribal bone trim, warm earth tones.

  PLAGUE CULT:
  Faction palette: rot brown-grey flesh, tattered burial 
  cloth, sickly yellow-green infection glow, rusted dark iron.

  ALLIES / PLAYER CHARACTERS:
  Faction palette: worn practical armor, warm leather browns, 
  tarnished iron, heroic but scruffy aesthetic.

PRIORITY ORDER (who to do first)
---------------------------------
1. Florence, Arnulf, Sybil (player-facing every session)
2. All mini-bosses + Archrot final boss (key dramatic moments)
3. Orc Warboss, Herald of Worms (named enemies)
4. All basic enemy grunts (6 existing types)
5. Generic mercenaries, buildings (lowest — Rodin handles 
   geometric buildings well from text alone)

=======================================================
STAGE 2 — 3D MODEL GENERATION (RODIN)
=======================================================

TOOL: Hyper3D Rodin (hyper3d.ai)
MODE: Image-to-3D (always — not text-only)
INPUT: The approved reference sheet from Stage 1

RODIN SETTINGS TO USE
---------------------
- Enable T-pose / A-pose toggle for all characters 
  (makes them immediately riggable)
- Generate 4 variants per prompt, pick best
- Target polygon count: 5,000–15,000 tris per character
  (appropriate for isometric game units viewed small)
- Export format: GLB (Godot-native, no conversion needed)
- Request: "no background, isolated model, 
  game-ready topology"

CONSISTENCY TIPS FOR RODIN
--------------------------
- Always feed an image, never use text-only mode for 
  characters
- Add to every Rodin generation note:
  "scale reference: adult human male 1.8m, 
   low-poly game asset, isometric tower defense, 
   GLB export, T-pose"
- Bosses: generate at higher detail budget, they appear 
  once and are worth the credits
- Buildings: geometric enough that text-only works fine;
  describe "cubic hex-tile footprint approximately 3x3m"

WHAT TO DO WHEN RESULT IS "CLOSE BUT NOT RIGHT"
------------------------------------------------
- Silhouette wrong → go back to Stage 1, revise reference
- Too cartoony → add "less stylized, more gritty realism" 
  to the Rodin note
- Too realistic → add "simplified geometry, stylized 
  low-poly, fewer polygons"
- Wrong proportions → add "larger head, shorter legs, 
  broader shoulders" corrections to the image prompt first

=======================================================
STAGE 3 — RIGGING
=======================================================

TOOL OPTIONS (in order of speed)
---------------------------------
1. Mixamo (mixamo.com, FREE) — Upload GLB/FBX, 
   auto-rigs humanoid characters in 2 minutes. 
   Best for: Florence, Arnulf, Sybil, mercenaries, 
   humanoid enemies (Orc Grunt, Plague Zombie, etc.)
   Limitation: humanoids only, no creature rigs.

2. Blender Auto-Rig Pro (paid addon, ~$40) — 
   Best for non-humanoid creatures (Bat Swarm, 
   Thornling, Ratkin, Bog Lurker). More control 
   than Mixamo. Requires desktop Blender session.

3. AccuRIG by Reallusion (free) — Alternative to 
   Mixamo, handles slightly more varied body types.

WORKFLOW
--------
Step 1: Export Rodin model as GLB
Step 2: Open in Blender, check topology and scale
Step 3: Upload to Mixamo (humanoids) or rig manually 
        (creatures) — place rig markers on joints
Step 4: Download rigged FBX from Mixamo
Step 5: Import rigged FBX back into Blender, 
        convert to GLB for Godot

NAMING CONVENTION FOR BONES
----------------------------
Use Godot-compatible bone names from the start:
Hips, Spine, Spine1, Spine2, Neck, Head,
LeftUpperArm, LeftLowerArm, LeftHand,
RightUpperArm, RightLowerArm, RightHand,
LeftUpperLeg, LeftLowerLeg, LeftFoot,
RightUpperLeg, RightLowerLeg, RightFoot

=======================================================
STAGE 4 — ANIMATION
=======================================================

REQUIRED ANIMATIONS PER CHARACTER TYPE
---------------------------------------
ENEMIES (all types):
  - idle (2-4 second loop)
  - walk / run (cycle)
  - attack (0.5-1s, with clear impact frame)
  - hit_react (short flinch)
  - death (1-2s, falls to ground)
  - spawn (optional, rising/appearing)

ALLIES (Arnulf + mercenaries):
  - idle
  - run
  - attack_melee (swing)
  - hit_react
  - death
  - downed (collapses, lying pose)
  - recovering (gets up)
  - drunk_idle (swaying variation) — Arnulf only

FLORENCE / SYBIL (stationary, Tower-based):
  - idle
  - shoot (arm raise + release)
  - hit_react (Tower shakes)
  - cast_spell
  - victory
  - defeat

BUILDINGS:
  - idle (static or very subtle ambient motion)
  - active (firing/working state, looping)
  - destroyed (collapse, one-shot)

TOOL OPTIONS FOR ANIMATION
---------------------------
1. Mixamo animations library (FREE) — 
   Thousands of pre-made humanoid animations, 
   downloadable as FBX. Best for: walk, run, attack, 
   idle, death for all humanoid units. Retarget 
   to your rig in Blender.

2. Cascadeur (free tier available) — 
   AI-assisted keyframe animation. Good for 
   creature animations Mixamo can't provide and 
   for polishing auto-generated results.

3. Blender NLA Editor — 
   Manual keyframe animation for non-humanoids, 
   buildings, and anything Mixamo can't handle. 
   Also used to combine and trim Mixamo clips.

4. AccuMotion / DeepMotion — 
   Video-to-animation tools. Record yourself doing 
   a motion on phone camera → generates animation 
   clip. Fast for unique actions.

RETARGETING MIXAMO ANIMATIONS TO CUSTOM RIGS
--------------------------------------------
In Blender:
1. Import Mixamo FBX animation
2. Import your character GLB (with rig)
3. Use "Bake Action" to retarget pose bone by bone
   or use the free Rokoko Retargeting addon
4. Export as GLB with animations embedded

=======================================================
STAGE 5 — GODOT IMPORT & WIRING
=======================================================

IMPORT SETTINGS (Godot 4)
--------------------------
- Import as: GLB scene
- Skeleton: detect automatically
- Animation: import all clips
- Compression: lossless for characters (they're small)
- LOD: not needed at this scale

FILE STRUCTURE IN PROJECT
--------------------------
res://art/
  characters/
    arnulf/
      arnulf.glb
      arnulf_reference_sheet.png
    florence/
    sybil/
  enemies/
    orc_grunt/
    orc_brute/
    goblin_firebug/
    plague_zombie/
    bat_swarm/
    orc_archer/
  bosses/
    gorefang_warlord/
    herald_of_worms/
    archrot_incarnate/
  buildings/
    arrow_tower/
    fire_brazier/
    magic_obelisk/
    [etc]
  generated/  ← Blender placeholder GLBs (existing system)

WIRING TO EXISTING CODE
-----------------------
The project already has ArtPlaceholderHelper.gd which 
resolves meshes at runtime. When a production GLB is 
placed at the correct path, it automatically takes 
priority over the generated placeholder. No code changes 
needed — just drop files in the right folder.

AnimationPlayer node in each scene plays clips by name.
Existing state machines reference animation names as strings:
  EnemyBase → calls "walk", "attack", "death"
  AllyBase → calls "idle", "run", "attack_melee", "downed"
  Arnulf → calls "idle", "run", "attack_melee", 
           "downed", "recovering", "drunk_idle"

Match your AnimationPlayer clip names EXACTLY to these 
strings when importing. No code changes needed.

=======================================================
5 EXAMPLE IMAGE GENERATION PROMPTS (reference sheets)
=======================================================

--- PROMPT 1: Arnulf ---
Character design turnaround sheet, front view, right side 
view, back view, isolated on white background.
Arnulf: burly middle-aged human warrior, 1.9m tall, 
slightly exaggerated proportions. Disheveled dirty blond 
hair with grey streaks, red-nosed bloated face of a heavy 
drinker, permanent five o'clock shadow. Worn plate armor 
missing left pauldron (replaced by leather strap and 
buckle), chainmail visible at joints, one knee cop 
cracked. Battered iron shovel strapped across back as 
primary weapon. Hip flask tucked into belt at left side, 
visible and prominent. Proud slightly unsteady wide-stance 
combat pose. Color swatches strip at bottom: tarnished 
iron, worn leather brown, dirty blond, flushed skin.
Art style: semi-realistic low-poly game character, 
slightly exaggerated proportions (large hands, broad 
shoulders, readable silhouette at small scale), dark humor 
fantasy tone (Warhammer Fantasy meets Terry Pratchett), 
warm desaturated earth tones, stylized PBR materials, 
baked ambient occlusion. White background, character 
turnaround sheet, front/side/back views, 
no cast shadows, T-pose.

--- PROMPT 2: Orc Grunt ---
Character design turnaround sheet, front view, right side 
view, back view, isolated on white background.
Orc Grunt: stocky green-skinned orc soldier, 1.85m, 
broad shoulders, large fists, hunched aggressive forward 
stance. Crude dented iron helmet with two small cheek 
plates, patchwork leather pauldrons with visible stitching, 
linen wrapping on 

scenes/enemies/enemy_base.gd:
## enemy_base.gd
## Runtime enemy controller: movement, tower attacks, and death handling for FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

# Credit (movement/NavigationAgent3D pattern):
#   Godot Docs — "Using NavigationAgents" (CharacterBody3D template, avoidance notes)
#   https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
#   License: CC BY 3.0
#   Adapted by FOUL WARD team to use EnemyData stats and tower-focused targeting.

class_name EnemyBase
extends CharacterBody3D

## Preload registers `class_name RiggedVisualWiring` before this file resolves identifiers (fresh .godot).
const _RiggedVisualWiringScript: GDScript = preload("res://scripts/art/rigged_visual_wiring.gd")
const ShieldComponentType = preload("res://scripts/components/shield_component.gd")

const FLYING_HEIGHT: float = 5.0
const STUCK_VELOCITY_EPSILON: float = 0.1
const STUCK_TIME_THRESHOLD: float = 1.5
const PROGRESS_EPSILON: float = 0.05
const DIRECT_STEER_MIN_DIST_SQ: float = 0.01

# Assign placeholder art resources via convention-based pipeline.
var _enemy_data: EnemyData = null
## Stable id for auras / signals (set in [method initialize]).
var instance_id: String = ""
## Alias for [member _enemy_data] (read-only for systems that expect [code]enemy.enemy_data[/code]).
var enemy_data: EnemyData:
	get:
		return _enemy_data
## Set by WaveManager when using mission lane/path routing (data-driven waves).
var assigned_lane_id: String = ""
var assigned_path_id: String = ""
## When set, this enemy pathfinds to Arnulf and attacks him (only after `begin_arnulf_retaliation`).
var _arnulf_retaliation_target: Node3D = null
## Visual-only: GLB AnimationPlayer for idle/walk (see RiggedVisualWiring).
var _locomotion_animation_player: AnimationPlayer = null
var _locomotion_clip: StringName = &""
var _attack_timer: float = 0.0
var _is_attacking: bool = false
var _time_since_last_progress: float = 0.0
var _last_distance_to_tower: float = 0.0
var active_status_effects: Array[Dictionary] = []
const MAX_POISON_STACKS: int = 5 # TUNING: max poison stacks per enemy.

var _terrain_multipliers: Array[float] = []
var _active_terrain_speed_multiplier: float = 1.0
var _reported_tower_reach: bool = false

## Prompt 49: runtime stat layer (auras / buffs). Legacy DoT/slow uses [member active_status_effects].
var base_stats: Dictionary = {}
var final_stats: Dictionary = {}
var incoming_auras: Array[Dictionary] = []
var resolved_auras: Dictionary = {}
## Stat-layer modifiers (stack_key / stack_mode); distinct keys from legacy DoT dicts.
var stat_layer_effects: Array[Dictionary] = []

var _shield_component: ShieldComponentType = null

## Prompt 9 — charge (Berserker / War Boar).
var _charge_active: bool = false
var _charge_params: Dictionary = {}
var _dash_done: bool = false
var _dash_timer_remaining: float = 0.0

## Prompt 9 — anti-air priority for ranged (Orc Skythrower).
var _target_priority: String = "ANY" # "ANY" | "FLYING"

## Prompt 9 — passive HP/s (Troll / Plague Herald).
var _regen_per_sec: float = 0.0
## Local move speed override when [member final_stats] is applied (does not mutate [member EnemyData] resource).
var _runtime_move_speed: float = -1.0
var _aura_check_timer: float = 0.0
var _last_tower_aura_speed_mod: float = 0.0
const AURA_CHECK_INTERVAL: float = 0.25

# PUBLIC — required by BuildingBase._find_target() and Arnulf._find_closest_enemy_to_tower().
@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _visual_slot: Node3D = get_node_or_null("EnemyVisual")
@onready var _label: Label3D = get_node_or_null("EnemyLabel")

# ASSUMPTION: These paths match ARCHITECTURE.md section 2.
@onready var _tower: Node = get_node_or_null("/root/Main/Tower")

func _exit_tree() -> void:
	if _enemy_data != null and not instance_id.is_empty():
		for tag: String in _enemy_data.special_tags:
			if tag == "aura_buff" or tag == "aura_heal":
				AuraManager.deregister_enemy_aura(instance_id)


func _ready() -> void:
	# Ensure enemies can be found via group for buildings and spells.
	add_to_group("enemies")
	if not SignalBus.enemy_entered_terrain_zone.is_connected(_on_entered_terrain_zone):
		SignalBus.enemy_entered_terrain_zone.connect(_on_entered_terrain_zone)
	if not SignalBus.enemy_exited_terrain_zone.is_connected(_on_exited_terrain_zone):
		SignalBus.enemy_exited_terrain_zone.connect(_on_exited_terrain_zone)
	if _label != null and _enemy_data != null:
		_label.text = _enemy_data.display_name

# === PUBLIC API =====================================================

## Initializes this enemy instance from its EnemyData resource.
func initialize(enemy_data: EnemyData) -> void:
	if enemy_data == null:
		push_error("EnemyBase.initialize called with null EnemyData")
		return
	instance_id = str(get_instance_id())
	_enemy_data = enemy_data
	_charge_active = false
	_charge_params = {}
	_dash_done = false
	_dash_timer_remaining = 0.0
	_heal_accumulator = 0.0
	_target_priority = "ANY"
	_regen_per_sec = 0.0
	assigned_lane_id = ""
	assigned_path_id = ""
	_arnulf_retaliation_target = null
	_attack_timer = 0.0
	_is_attacking = false
	_last_distance_to_tower = global_position.distance_to(_get_tower_target_flat())
	_time_since_last_progress = 0.0
	print("[Enemy] initialized: %s  hp=%d speed=%.1f flying=%s pos=(%.0f,%.0f,%.0f)" % [
		enemy_data.display_name, enemy_data.max_hp, enemy_data.move_speed, enemy_data.is_flying,
		global_position.x, global_position.y, global_position.z
	])

	health_component.max_hp = _enemy_data.max_hp
	health_component.reset_to_max()
	if not health_component.health_depleted.is_connected(_on_health_depleted):
		health_component.health_depleted.connect(_on_health_depleted)

	_mount_enemy_visual(enemy_data)
	_rebuild_base_stats()
	recompute_all_stats()

	# Ground enemies configure NavigationAgent3D; flying ones ignore it.
	if not _enemy_data.is_flying:
		# Credit (target_desired_distance + path_desired_distance usage):
		#   FOUL WARD SYSTEMS_part3.md §8.6 EnemyBase.move_ground pseudocode.
		navigation_agent.path_desired_distance = 0.5
		navigation_agent.target_desired_distance = _get_effective_attack_range()
		navigation_agent.avoidance_enabled = true
		navigation_agent.radius = 0.5
		# max_speed must be non-zero for NavigationAgent3D avoidance / path heuristics (scene default was 0).
		navigation_agent.max_speed = maxf(
				_get_effective_move_speed() * _active_terrain_speed_multiplier,
				0.25
		)
		navigation_agent.target_position = _get_nav_target_position()

	if _label != null:
		_label.text = _enemy_data.display_name

	_init_special_behaviours()

## Data-driven hit resolution (Prompt 49). [method take_damage] routes here.
func receive_damage(hit: Dictionary) -> Dictionary:
	var raw: float = float(hit.get("raw_damage", 0.0))
	var dtype: Types.DamageType = hit.get("damage_type", Types.DamageType.PHYSICAL) as Types.DamageType
	var is_dot: bool = bool(hit.get("is_dot", false))
	var result: Dictionary = {
		"post_mitigation_damage": 0.0,
		"hp_damage": 0.0,
		"shield_absorbed": 0.0,
	}
	if _enemy_data == null:
		return result
	if dtype in _enemy_data.damage_immunities:
		return result
	var post_flat: float = raw
	if dtype == Types.DamageType.TRUE:
		post_flat = DamageCalculator.calculate_damage(raw, dtype, _enemy_data.armor_type)
	elif dtype == Types.DamageType.PHYSICAL:
		var af: float = _enemy_data.armor_flat
		var mult: float = 1.0
		if af >= 0.0:
			mult = 100.0 / (100.0 + af)
		else:
			mult = 1.0 - af / 100.0
		post_flat = raw * mult
		post_flat = DamageCalculator.calculate_damage(post_flat, dtype, _enemy_data.armor_type)
	else:
		post_flat = DamageCalculator.calculate_damage(raw, dtype, _enemy_data.armor_type)
	var hp_apply: float = post_flat
	var absorbed: float = 0.0
	if _shield_component != null and _shield_component.is_active() and post_flat > 0.0:
		var before_hp: float = post_flat
		hp_apply = _shield_component.absorb(post_flat)
		absorbed = before_hp - hp_apply
	result["post_mitigation_damage"] = post_flat
	result["shield_absorbed"] = absorbed
	result["hp_damage"] = hp_apply
	if hp_apply > 0.0:
		health_component.take_damage(hp_apply)
		_check_charge_enrage()
	return result


## Applies damage of a given type to this enemy.
func take_damage(amount: float, damage_type: Types.DamageType) -> void:
	receive_damage({"raw_damage": amount, "damage_type": damage_type, "is_dot": false})

## Returns the EnemyData backing this enemy instance.
func get_enemy_data() -> EnemyData:
	return _enemy_data


func _rebuild_base_stats() -> void:
	if _enemy_data == null:
		return
	base_stats = {
		"move_speed": float(_enemy_data.move_speed),
		"damage": float(_enemy_data.damage),
		"attack_range": float(_enemy_data.attack_range),
		"status_resist_multiplier": float(_enemy_data.status_resist_multiplier),
	}


func recompute_all_stats() -> void:
	final_stats = base_stats.duplicate()
	_resolve_auras()
	for e: Dictionary in stat_layer_effects:
		var st: String = str(e.get("stat", ""))
		if st.is_empty():
			continue
		_apply_modifier(final_stats, st, str(e.get("modifier_type", "MULTIPLY")), float(e.get("modifier_value", 1.0)))
	var tower_aura_spd: float = AuraManager.get_enemy_speed_modifier(global_position)
	if final_stats.has("move_speed") and _enemy_data != null:
		var ms_base: float = float(final_stats["move_speed"])
		var ms_eff: float = ms_base * (1.0 + tower_aura_spd)
		if _charge_active and _charge_params.has("speed_bonus"):
			ms_eff *= (1.0 + float(_charge_params["speed_bonus"]))
		if _dash_timer_remaining > 0.0 and _charge_params.has("dash_speed"):
			ms_eff = float(_charge_params["dash_speed"])
		ms_eff = maxf(ms_eff, _enemy_data.move_speed * 0.2)
		_runtime_move_speed = ms_eff
	else:
		_runtime_move_speed = -1.0
	_last_tower_aura_speed_mod = tower_aura_spd
	if _enemy_data != null and not _enemy_data.is_flying:
		navigation_agent.target_desired_distance = _get_effective_attack_range()
		navigation_agent.max_speed = maxf(
				_get_effective_move_speed() * _active_terrain_speed_multiplier,
				0.25
		)


func _resolve_auras() -> void:
	resolved_auras.clear()
	for a: Dictionary in incoming_auras:
		var cat: String = str(a.get("aura_category", "default"))
		var cur: Dictionary = resolved_auras.get(cat, {}) as Dictionary
		if cur.is_empty() or _aura_strength(a) > _aura_strength(cur):
			resolved_auras[cat] = a
	for _k: Variant in resolved_auras.keys():
		var aura: Dictionary = resolved_auras[_k] as Dictionary
		var st: String = str(aura.get("aura_stat", ""))
		if st.is_empty():
			continue
		_apply_modifier(final_stats, st, str(aura.get("modifier_type", "MULTIPLY")), float(aura.get("modifier_value", 1.0)))


func _aura_strength(aura: Dictionary) -> float:
	var mt: String = str(aura.get("modifier_type", "MULTIPLY"))
	var mv: float = float(aura.get("modifier_value", 1.0))
	match mt:
		"MULTIPLY":
			return absf(mv - 1.0)
		"ADD", "OVERRIDE":
			return absf(mv)
		_:
			return absf(mv)


func _apply_modifier(stats: Dictionary, stat: String, mod_type: String, value: float) -> void:
	var cur: float = float(stats.get(stat, 0.0))
	match mod_type:
		"MULTIPLY":
			stats[stat] = cur * value
		"ADD":
			stats[stat] = cur + value
		"OVERRIDE":
			stats[stat] = value
		_:
			stats[stat] = cur * value


func add_status_effect(effect: Dictionary) -> void:
	var dur: float = float(effect.get("duration_remaining", 0.0))
	dur *= float(base_stats.get("status_resist_multiplier", 1.0))
	var eff: Dictionary = effect.duplicate()
	eff["duration_remaining"] = dur
	var stack_key: String = str(eff.get("stack_key", ""))
	var mode: String = str(eff.get("stack_mode", "NONE"))
	var idx: int = _find_stat_effect_index(stack_key)
	match mode:
		"NONE":
			if idx >= 0:
				return
			stat_layer_effects.append(eff)
		"REFRESH":
			if idx >= 0:
				var old: Dictionary = stat_layer_effects[idx]
				old["duration_remaining"] = float(eff.get("duration_remaining", 0.0))
				stat_layer_effects[idx] = old
			else:
				stat_layer_effects.append(eff)
		"REPLACE_STRONGEST":
			if idx >= 0:
				var old2: Dictionary = stat_layer_effects[idx]
				if float(eff.get("modifier_value", 0.0)) > float(old2.get("modifier_value", 0.0)):
					stat_layer_effects[idx] = eff
			else:
				stat_layer_effects.append(eff)
		"STACK_DURATION":
			if idx >= 0:
				var old3: Dictionary = stat_layer_effects[idx]
				old3["duration_remaining"] = float(old3.get("duration_remaining", 0.0)) + float(eff.get("duration_remaining", 0.0))
				stat_layer_effects[idx] = old3
			else:
				stat_layer_effects.append(eff)
		_:
			stat_layer_effects.append(eff)
	recompute_all_stats()


func _find_stat_effect_index(stack_key: String) -> int:
	if stack_key.is_empty():
		return -1
	for j: int in range(stat_layer_effects.size()):
		var e2: Dictionary = stat_layer_effects[j]
		if str(e2.get("stack_key", "")) == stack_key:
			return j
	return -1


func _tick_stat_layer_effects(delta: float) -> void:
	if stat_layer_effects.is_empty():
		return
	var i: int = 0
	var changed: bool = false
	while i < stat_layer_effects.size():
		var e: Dictionary = stat_layer_effects[i]
		var rem: float = float(e.get("duration_remaining", 0.0)) - delta
		e["duration_remaining"] = rem
		if rem <= 0.0:
			stat_layer_effects.remove_at(i)
			changed = true
		else:
			stat_layer_effects[i] = e
			i += 1
	if changed:
		recompute_all_stats()


func _get_effective_move_speed() -> float:
	if _runtime_move_speed >= 0.0:
		return _runtime_move_speed
	if _enemy_data == null:
		return 0.0
	return _enemy_data.move_speed


func _get_effective_attack_range() -> float:
	if _enemy_data == null:
		return 0.0
	if not final_stats.is_empty() and final_stats.has("attack_range"):
		return float(final_stats["attack_range"])
	return _enemy_data.attack_range


func _get_effective_damage_int() -> int:
	if _enemy_data == null:
		return 0
	var base_d: float = 0.0
	if not final_stats.is_empty() and final_stats.has("damage"):
		base_d = float(final_stats["damage"])
	else:
		base_d = float(_enemy_data.damage)
	var bonus: float = AuraManager.get_enemy_damage_bonus(
			Vector2(global_position.x, global_position.z)
	)
	return int(round(base_d * (1.0 + bonus)))


func _recompute_move_speed() -> void:
	recompute_all_stats()


func _init_special_behaviours() -> void:
	if _enemy_data == null:
		return
	for tag: String in _enemy_data.special_tags:
		match tag:
			"charge":
				_init_charge()
			"shield":
				_init_shield()
			"aura_buff":
				_init_enemy_aura("aura_buff")
			"aura_heal":
				_init_enemy_aura("aura_heal")
			"on_death_spawn":
				pass
			"ranged_long":
				pass
			"disable_building":
				pass
			"anti_air":
				_init_anti_air()
			"regen":
				_init_regen()
			_:
				push_warning("Unknown special_tag: %s on %s" % [tag, _enemy_data.display_name])


func _init_charge() -> void:
	_charge_params = _enemy_data.special_values.get("charge", {}) as Dictionary


func _init_shield() -> void:
	var params: Dictionary = _enemy_data.special_values.get("shield", {}) as Dictionary
	var sc: ShieldComponentType = ShieldComponentType.new() as ShieldComponentType
	sc.initialise(params)
	_shield_component = sc
	add_child(sc)


func _init_enemy_aura(tag: String) -> void:
	AuraManager.register_enemy_aura(self, tag)


func _init_anti_air() -> void:
	_target_priority = "FLYING"


func _init_regen() -> void:
	var params: Dictionary = _enemy_data.special_values.get("regen", {}) as Dictionary
	_regen_per_sec = float(params.get("hp_per_sec", 0.0))


func _check_charge_enrage() -> void:
	if _enemy_data == null:
		return
	if not health_component.is_alive():
		return
	if _charge_params.is_empty():
		return
	if _charge_active:
		return
	var threshold: float = float(_charge_params.get("enrage_hp_pct", 0.5))
	var max_hp_f: float = float(health_component.max_hp)
	if max_hp_f <= 0.0:
		return
	var ratio: float = float(health_component.current_hp) / max_hp_f
	if ratio <= threshold:
		_charge_active = true
		SignalBus.enemy_enraged.emit(instance_id)
		_trigger_dash()
		_recompute_move_speed()


func _trigger_dash() -> void:
	if not _charge_params.has("dash_speed"):
		return
	if _dash_done:
		return
	_dash_done = true
	_dash_timer_remaining = 1.0
	_recompute_move_speed()


func _handle_on_death_spawn() -> void:
	if _enemy_data == null:
		return
	if not "on_death_spawn" in _enemy_data.special_tags:
		return
	var params: Dictionary = _enemy_data.special_values.get("on_death_spawn", {}) as Dictionary
	var spawn_type_name: String = str(params.get("spawn_type", ""))
	var spawn_count: int = int(params.get("spawn_count", 0))
	if spawn_type_name.is_empty() or spawn_count <= 0:
		return
	var enum_keys: Array = Types.EnemyType.keys()
	if enum_keys.find(spawn_type_name) < 0:
		push_warning("on_death_spawn: unknown type %s" % spawn_type_name)
		return
	var spawn_type: int = int(Types.EnemyType[spawn_type_name])
	var wm: WaveManager = get_node_or_null("/root/Main/Managers/WaveManager") as WaveManager
	if wm == null:
		push_warning("on_death_spawn: WaveManager not found")
		return
	var spawn_data: EnemyData = wm.get_enemy_data_by_type(spawn_type)
	if spawn_data == null:
		push_warning("on_death_spawn: no EnemyData for %s" % spawn_type_name)
		return
	for i: int in range(spawn_count):
		var off: Vector3 = Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
		wm.spawn_enemy_at_position(spawn_data, global_position + off)


func _try_disable_target_building(target: BuildingBase) -> void:
	if _enemy_data == null:
		return
	if not "disable_building" in _enemy_data.special_tags:
		return
	var params: Dictionary = _enemy_data.special_values.get("disable_building", {}) as Dictionary
	var duration: float = float(params.get("disable_duration", 4.0))
	target.set_disabled(true, duration)


func _find_closest_building_in_melee_range() -> BuildingBase:
	var rng: float = _get_effective_attack_range()
	var best: BuildingBase = null
	var best_d: float = INF
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	for n: Node in tree.get_nodes_in_group("buildings"):
		var b: BuildingBase = n as BuildingBase
		if b == null or not is_instance_valid(b):
			continue
		var d: float = global_position.distance_to(b.global_position)
		if d <= rng and d < best_d:
			best_d = d
			best = b
	return best


func _try_saboteur_building_attack(delta: float) -> bool:
	if _enemy_data == null:
		return false
	if not "disable_building" in _enemy_data.special_tags:
		return false
	var b: BuildingBase = _find_closest_building_in_melee_range()
	if b == null:
		return false
	_is_attacking = true
	velocity = Vector3.ZERO
	_attack_timer += delta
	if _attack_timer >= _enemy_data.attack_cooldown:
		_attack_timer = 0.0
		_try_disable_target_building(b)
	return true


func _is_ally_considered_flying(ally: AllyBase) -> bool:
	return ally.global_position.y >= 2.5


func _find_closest_flying_ally_in_range() -> AllyBase:
	var rng: float = _get_effective_attack_range()
	var best: AllyBase = null
	var best_d: float = INF
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	for n: Node in tree.get_nodes_in_group("allies"):
		var a: AllyBase = n as AllyBase
		if a == null or not is_instance_valid(a):
			continue
		if a.health_component == null or not a.health_component.is_alive():
			continue
		if not _is_ally_considered_flying(a):
			continue
		var d: float = global_position.distance_to(a.global_position)
		if d <= rng and d < best_d:
			best_d = d
			best = a
	return best


func _tick_dash_timer(delta: float) -> void:
	if _dash_timer_remaining <= 0.0:
		return
	_dash_timer_remaining -= delta
	if _dash_timer_remaining <= 0.0:
		_dash_timer_remaining = 0.0
		_apply_dash_arrival_damage()
		_recompute_move_speed()


var _heal_accumulator: float = 0.0


func _tick_regen_and_aura_heal(delta: float) -> void:
	if _enemy_data == null:
		return
	if not health_component.is_alive():
		return
	var pos_xz: Vector2 = Vector2(global_position.x, global_position.z)
	var heal: float = AuraManager.get_enemy_heal_per_sec(pos_xz) * delta
	if _regen_per_sec > 0.0:
		heal += _regen_per_sec * delta
	if heal <= 0.0:
		return
	_heal_accumulator += heal
	while _heal_accumulator >= 1.0:
		health_component.heal(1)
		_heal_accumulator -= 1.0


func _apply_dash_arrival_damage() -> void:
	if not _charge_params.has("dash_damage"):
		return
	var dmg: float = float(_charge_params["dash_damage"])
	var r: float = 3.0
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for n: Node in tree.get_nodes_in_group("buildings"):
		var b: BuildingBase = n as BuildingBase
		if b == null or not is_instance_valid(b):
			continue
		if global_position.distance_to(b.global_position) <= r:
			if b.health_component != null:
				b.health_component.take_damage(dmg)
	for n2: Node in tree.get_nodes_in_group("allies"):
		var a: AllyBase = n2 as AllyBase
		if a == null or not is_instance_valid(a):
			continue
		if a.health_component == null or not a.health_component.is_alive():
			continue
		if global_position.distance_to(a.global_position) <= r:
			a.health_component.take_damage(dmg)


## Arnulf calls this when he starts attacking this enemy — enemy will path to Arnulf and fight back.
func begin_arnulf_retaliation(arnulf: Node3D) -> void:
	if arnulf == null or not is_instance_valid(arnulf):
		return
	if _enemy_data != null and _enemy_data.is_flying:
		return
	_arnulf_retaliation_target = arnulf


func clear_arnulf_retaliation() -> void:
	_arnulf_retaliation_target = null


## Visual-only: BossBase reassigns after mounting boss GLB (shared locomotion driver).
func assign_locomotion_animation_player(player: AnimationPlayer) -> void:
	_locomotion_animation_player = player
	_locomotion_clip = &""


func _mount_enemy_visual(enemy_data: EnemyData) -> void:
	_locomotion_animation_player = null
	_locomotion_clip = &""
	if _visual_slot == null:
		return
	var glb_path: String = RiggedVisualWiring.enemy_rigged_glb_path(enemy_data.enemy_type)
	if not glb_path.is_empty() and ResourceLoader.exists(glb_path):
		_locomotion_animation_player = RiggedVisualWiring.mount_glb_scene(_visual_slot, glb_path)
	else:
		RiggedVisualWiring.mount_enemy_placeholder_mesh(_visual_slot, enemy_data)


func _sync_locomotion_animation() -> void:
	if _locomotion_animation_player == null:
		return
	var horiz: float = Vector2(velocity.x, velocity.z).length()
	_locomotion_clip = RiggedVisualWiring.update_locomotion_animation(
		_locomotion_animation_player, horiz, _locomotion_clip
	)

# === PHYSICS LOOP ===================================================

func _physics_process(delta: float) -> void:
	if _enemy_data == null:
		return
	_tick_dash_timer(delta)
	_tick_regen_and_aura_heal(delta)
	_aura_check_timer += delta
	if _aura_check_timer >= AURA_CHECK_INTERVAL:
		_aura_check_timer = 0.0
		var new_mod: float = AuraManager.get_enemy_speed_modifier(global_position)
		if not is_equal_approx(new_mod, _last_tower_aura_speed_mod):
			recompute_all_stats()
	_tick_stat_layer_effects(delta)
	_update_status_effects(delta)
	if _enemy_data.is_flying:
		_physics_process_flying(delta)
	else:
		_physics_process_ground(delta)
	_sync_locomotion_animation()


## Applies or updates a damage-over-time (DoT) effect on this enemy.
## required keys in effect_data:
## - "effect_type": String ("burn", "poison", etc.)
## - "damage_type": Types.DamageType
## - "dot_total_damage": float   # total damage before armor/matrix
## - "tick_interval": float      # seconds between ticks
## - "duration": float           # total duration in seconds
## - "source_id": String         # stable source identifier
## Applies a non-stacking slow: worst (lowest) multiplier wins while any slow is active.
func apply_slow_effect(speed_multiplier: float, duration_seconds: float, source_id: String) -> void:
	if duration_seconds <= 0.0:
		return
	var mult: float = clampf(speed_multiplier, 0.05, 1.0)
	var effect: Dictionary = {
		"effect_type": "slow",
		"remaining_time": duration_seconds,
		"speed_multiplier": mult,
		"source_id": source_id,
	}
	# Replace existing slow from same source, else append (worst multiplier kept in movement).
	var idx: int = -1
	for i: int in range(active_status_effects.size()):
		var e: Dictionary = active_status_effects[i]
		if e.get("effect_type", "") == "slow" and e.get("source_id", "") == source_id:
			idx = i
			break
	if idx >= 0:
		var old: Dictionary = active_status_effects[idx]
		if float(effect["remaining_time"]) > float(old.get("remaining_time", 0.0)):
			active_status_effects[idx] = effect
	else:
		active_status_effects.append(effect)


func apply_dot_effect(effect_data: Dictionary) -> void:
	if not effect_data.has("effect_type"):
		return
	if not effect_data.has("damage_type"):
		return
	if not effect_data.has("dot_total_damage"):
		return
	if not effect_data.has("tick_interval"):
		return
	if not effect_data.has("duration"):
		return
	if not effect_data.has("source_id"):
		return

	var duration: float = float(effect_data["duration"])
	var tick_interval: float = float(effect_data["tick_interval"])
	if duration <= 0.0 or tick_interval <= 0.0:
		return

	var effect_type: String = String(effect_data["effect_type"])
	var source_id: String = String(effect_data["source_id"])

	effect_data["remaining_time"] = duration
	effect_data["time_since_last_tick"] = 0.0

	if effect_type == "burn":
		_apply_burn_effect(effect_data, source_id, duration)
	elif effect_type == "poison":
		_apply_poison_effect(effect_data)
	else:
		active_status_effects.append(effect_data)


func _apply_burn_effect(effect_data: Dictionary, source_id: String, duration: float) -> void:
	# TUNING: burn reapplication refreshes duration; keeps highest dot_total_damage for this source.
	var existing_index: int = -1
	for i: int in range(active_status_effects.size()):
		var e: Dictionary = active_status_effects[i]
		if e.get("effect_type", "") == "burn" and e.get("source_id", "") == source_id:
			existing_index = i
			break

	if existing_index != -1:
		var existing: Dictionary = active_status_effects[existing_index]
		existing["duration"] = duration
		existing["remaining_time"] = duration
		var new_total: float = float(effect_data["dot_total_damage"])
		var old_total: float = float(existing.get("dot_total_damage", 0.0))
		if new_total > old_total:
			existing["dot_total_damage"] = new_total
		existing["time_since_last_tick"] = 0.0
		active_status_effects[existing_index] = existing
	else:
		active_status_effects.append(effect_data)


func _apply_poison_effect(effect_data: Dictionary) -> void:
	active_status_effects.append(effect_data)

	# TUNING: max poison stacks per enemy.
	var poison_indices: Array[int] = []
	for i: int in range(active_status_effects.size()):
		var e: Dictionary = active_status_effects[i]
		if e.get("effect_type", "") == "poison":
			poison_indices.append(i)

	if poison_indices.size() > MAX_POISON_STACKS:
		var to_remove: int = poison_indices[0]
		active_status_effects.remove_at(to_remove)


func _update_status_effects(delta: float) -> void:
	if active_status_effects.is_empty():
		return
	_tick_dot_effects(delta)
	_cleanup_expired_effects()


## Advances timers and fires damage ticks for all active_status_effects.
## Does not remove expired effects — call _cleanup_expired_effects() afterward.
func _tick_dot_effects(delta: float) -> void:
	for i: int in range(active_status_effects.size()):
		var effect: Dictionary = active_status_effects[i]
		if str(effect.get("stack_key", "")) != "":
			continue

		if effect.get("effect_type", "") == "slow":
			effect["remaining_time"] = float(effect.get("remaining_time", 0.0)) - delta
			active_status_effects[i] = effect
			continue

		var previous_remaining_time: float = float(effect.get("remaining_time", 0.0))
		var remaining_time: float = previous_remaining_time - delta
		effect["remaining_time"] = remaining_time

		var tick_interval: float = float(effect.get("tick_interval", 0.0))
		var duration: float = float(effect.get("duration", 0.0))
		var damage_type: Types.DamageType = effect.get("damage_type", Types.DamageType.PHYSICAL)

		var time_since_last_tick: float = float(effect.get("time_since_last_tick", 0.0)) + delta
		effect["time_since_last_tick"] = time_since_last_tick

		if tick_interval > 0.0 and time_since_last_tick >= tick_interval:
			effect["time_since_last_tick"] = time_since_last_tick - tick_interval
			var dot_total_damage: float = float(effect.get("dot_total_damage", 0.0))
			if dot_total_damage > 0.0 and previous_remaining_time > 0.0:
				var per_tick_damage: float = DamageCalculator.calculate_dot_tick(
					dot_total_damage,
					tick_interval,
					duration,
					damage_type,
					_enemy_data.armor_type
				)
				if per_tick_damage > 0.0:
					# Avoid matrix double-application by using base-per-tick through take_damage.
					var tick_count: float = duration / tick_interval
					if tick_count > 0.0:
						var per_tick_base: float = dot_total_damage / tick_count
						receive_damage({
							"raw_damage": per_tick_base,
							"damage_type": damage_type,
							"is_dot": true,
						})

		active_status_effects[i] = effect


## Removes all non-stack_key effects whose remaining_time has reached or fallen below zero.
## Uses a backward pass so remove_at() does not shift unvisited indices.
func _cleanup_expired_effects() -> void:
	var i: int = active_status_effects.size() - 1
	while i >= 0:
		var effect: Dictionary = active_status_effects[i]
		if str(effect.get("stack_key", "")) == "" and float(effect.get("remaining_time", 0.0)) <= 0.0:
			active_status_effects.remove_at(i)
		i -= 1


# === MOVEMENT =======================================================

## World XZ the tower is rooted at (fallback origin if Tower node missing — e.g. headless tests).
func _get_tower_target_flat() -> Vector3:
	if is_instance_valid(_tower):
		var p: Vector3 = _tower.global_position
		return Vector3(p.x, 0.0, p.z)
	return Vector3.ZERO


func _get_nav_target_position() -> Vector3:
	var flat: Vector3 = _get_tower_target_flat()
	return Vector3(flat.x, 0.0, flat.z)


func _get_active_combat_destination_flat() -> Vector3:
	if _arnulf_retaliation_target != null and is_instance_valid(_arnulf_retaliation_target):
		var p: Vector3 = _arnulf_retaliation_target.global_position
		return Vector3(p.x, 0.0, p.z)
	return _get_tower_target_flat()


func _on_entered_terrain_zone(enemy: Node, multiplier: float) -> void:
	if enemy != self:
		return
	_terrain_multipliers.append(multiplier)
	_recalculate_terrain_speed()


func _on_exited_terrain_zone(enemy: Node, multiplier: float) -> void:
	if enemy != self:
		return
	_terrain_multipliers.erase(multiplier)
	_recalculate_terrain_speed()


func _recalculate_terrain_speed() -> void:
	# TODO(TERRAIN): If multiple zone types are needed beyond SLOW, extend
	# _recalculate_terrain_speed to handle Types.TerrainEffect variants.
	if _terrain_multipliers.is_empty():
		_active_terrain_speed_multiplier = 1.0
	else:
		var min_m: float = _terrain_multipliers[0]
		for m: float in _terrain_multipliers:
			min_m = minf(min_m, m)
		_active_terrain_speed_multiplier = min_m
	if _enemy_data != null and not _enemy_data.is_flying:
		navigation_agent.max_speed = maxf(
				_get_effective_move_speed() * _active_terrain_speed_multiplier,
				0.25
		)


## Returns combined slow multiplier from active slow effects (1.0 = no slow).
func get_move_speed_slow_multiplier() -> float:
	var worst: float = 1.0
	for effect: Dictionary in active_status_effects:
		if effect.get("effect_type", "") != "slow":
			continue
		var m: float = float(effect.get("speed_multiplier", 1.0))
		worst = minf(worst, m)
	return worst


func _physics_process_ground(delta: float) -> void:
	if _arnulf_retaliation_target != null and not is_instance_valid(_arnulf_retaliation_target):
		_arnulf_retaliation_target = null
	if _try_saboteur_building_attack(delta):
		_sync_locomotion_animation()
		return
	var dest_flat: Vector3 = _get_active_combat_destination_flat()
	navigation_agent.target_position = dest_flat
	if navigation_agent.is_navigation_finished():
		var distance_to_dest: float = global_position.distance_to(dest_flat)
		if distance_to_dest <= _get_effective_attack_range():
			if _arnulf_retaliation_target != null and is_instance_valid(_arnulf_retaliation_target):
				_update_attack_arnulf(delta)
			else:
				_update_attack_tower(delta)
			_reset_progress_tracking(distance_to_dest)
			return

	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_pos - global_position
	if direction.length_squared() < 0.0001:
		direction = Vector3.ZERO
	else:
		direction = direction.normalized()
	# If the nav map/path is missing or not synced yet, steer directly on XZ so the wave can finish.
	if direction == Vector3.ZERO:
		var to_dest: Vector3 = dest_flat - global_position
		to_dest.y = 0.0
		if to_dest.length_squared() > DIRECT_STEER_MIN_DIST_SQ:
			direction = to_dest.normalized()
	var speed_mult: float = (
			get_move_speed_slow_multiplier()
			* _active_terrain_speed_multiplier
	)
	if direction != Vector3.ZERO:
		velocity = direction * _get_effective_move_speed() * speed_mult
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	_update_progress_tracking(delta)
	_maybe_resolve_stuck()

	var distance_after: float = global_position.distance_to(dest_flat)
	if distance_after <= _get_effective_attack_range():
		if _arnulf_retaliation_target != null and is_instance_valid(_arnulf_retaliation_target):
			_update_attack_arnulf(delta)
		else:
			_update_attack_tower(delta)
		_reset_progress_tracking(distance_after)


func _physics_process_flying(delta: float) -> void:
	var flat: Vector3 = _get_tower_target_flat()
	var target_pos: Vector3 = Vector3(flat.x, FLYING_HEIGHT, flat.z)
	var direction: Vector3 = target_pos - global_position
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	var speed_mult: float = (
			get_move_speed_slow_multiplier()
			* _active_terrain_speed_multiplier
	)
	velocity = direction * _get_effective_move_speed() * speed_mult
	move_and_slide()
	if global_position.distance_to(target_pos) <= _get_effective_attack_range():
		_update_attack_tower(delta)


func _update_progress_tracking(delta: float) -> void:
	var distance_to_dest: float = global_position.distance_to(_get_active_combat_destination_flat())
	if distance_to_dest < _last_distance_to_tower - PROGRESS_EPSILON:
		_time_since_last_progress = 0.0
		_last_distance_to_tower = distance_to_dest
	else:
		_time_since_last_progress += delta


func _reset_progress_tracking(current_distance: float) -> void:
	_last_distance_to_tower = current_distance
	_time_since_last_progress = 0.0


func _maybe_resolve_stuck() -> void:
	if _time_since_last_progress < STUCK_TIME_THRESHOLD:
		return
	var distance_to_dest: float = global_position.distance_to(_get_active_combat_destination_flat())
	if distance_to_dest <= _get_effective_attack_range():
		return
	var speed: float = velocity.length()
	if speed > STUCK_VELOCITY_EPSILON:
		return
	navigation_agent.target_position = _get_active_combat_destination_flat()
	navigation_agent.set_velocity(Vector3.ZERO)
	_time_since_last_progress = 0.0
	_last_distance_to_tower = distance_to_dest

# === ATTACK LOGIC ===================================================

func _update_attack_tower(delta: float) -> void:
	_is_attacking = true
	velocity = Vector3.ZERO
	_attack_timer += delta
	if _attack_timer >= _enemy_data.attack_cooldown:
		_attack_timer = 0.0
		_deal_damage_to_tower()


func _deal_damage_to_tower() -> void:
	if _enemy_data != null and _enemy_data.is_ranged and _target_priority == "FLYING":
		var ally: AllyBase = _find_closest_flying_ally_in_range()
		if ally != null and is_instance_valid(ally):
			if ally.health_component != null and ally.health_component.is_alive():
				ally.health_component.take_damage(float(_get_effective_damage_int()))
				return
	if is_instance_valid(_tower):
		if not _reported_tower_reach and _enemy_data != null:
			_reported_tower_reach = true
			SignalBus.enemy_reached_tower.emit(_enemy_data.enemy_type, _get_effective_damage_int())
		_tower.take_damage(_get_effective_damage_int())


func _update_attack_arnulf(delta: float) -> void:
	_is_attacking = true
	velocity = Vector3.ZERO
	if _arnulf_retaliation_target == null or not is_instance_valid(_arnulf_retaliation_target):
		return
	_attack_timer += delta
	if _attack_timer >= _enemy_data.attack_cooldown:
		_attack_timer = 0.0
		_deal_damage_to_arnulf()


func _deal_damage_to_arnulf() -> void:
	if _arnulf_retaliation_target == null or not is_instance_valid(_arnulf_retaliation_target):
		return
	var arnulf_hc: HealthComponent = _arnulf_retaliation_target.get_node_or_null(
		"HealthComponent"
	) as HealthComponent
	if arnulf_hc == null or not arnulf_hc.is_alive():
		return
	var final_damage: float = DamageCalculator.calculate_damage(
		float(_get_effective_damage_int()),
		Types.DamageType.PHYSICAL,
		Types.ArmorType.UNARMORED
	)
	arnulf_hc.take_damage(final_damage)

# === DEATH HANDLING ================================================

func _on_health_depleted() -> void:
	print("[Enemy] DIED: %s  rewarding %d gold" % [_enemy_data.display_name, _enemy_data.gold_reward])
	SignalBus.enemy_killed.emit(
		_enemy_data.enemy_type,
		global_position,
		_enemy_data.gold_reward
	)
	# EconomyManager already listens to enemy_killed in Phase 1, so we do NOT call
	# EconomyManager.add_gold() directly here to avoid double-award.

	_handle_on_death_spawn()

	remove_from_group("enemies")
	queue_free()

scenes/arnulf/arnulf.gd:
## Arnulf — AI-controlled melee companion with IDLE/PATROL/CHASE/ATTACK/DOWNED/RECOVERING state machine.
# arnulf.gd
# Arnulf is the fully AI-controlled melee companion in FOUL WARD.
# He patrols near the tower, chases the closest enemy to TOWER_CENTER,
# attacks at melee range, and revives himself after being downed.
#
# State machine: IDLE → CHASE → ATTACK → DOWNED → RECOVERING → IDLE
# All cross-system communication via SignalBus (never direct node refs).
#
# Credit: Godot Engine Documentation — CharacterBody3D, NavigationAgent3D
#   https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
#   https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
#   License: CC BY 3.0 | Adapted by: Foul Ward team
#   Adapted: move_and_slide() loop, get_next_path_position() per-frame update,
#            NavigationAgent3D target_position update pattern.
#
# Credit: Godot Engine Documentation — Area3D.get_overlapping_bodies()
#   https://docs.godotengine.org/en/stable/classes/class_area3d.html
#   License: CC BY 3.0 | Adapted by: Foul Ward team
#   Adapted: snapshot-based closest-body search; is_instance_valid guard.
#
# Credit: Foul Ward SYSTEMS_part3.md §7 (Arnulf State Machine spec)
#   Internal project document — Foul Ward team.

class_name Arnulf
extends CharacterBody3D

const _RiggedVisualWiringScript: GDScript = preload("res://scripts/art/rigged_visual_wiring.gd")

# ---------------------------------------------------------------------------
# EXPORTS
# ---------------------------------------------------------------------------

## Maximum hit points. After downed, `HealthComponent.reset_to_max()` restores full HP.
@export var max_hp: int = 200

## Movement speed in units per second.
@export var move_speed: float = 5.0

## Physical damage dealt per attack.
@export var attack_damage: float = 25.0

## Seconds between attacks.
@export var attack_cooldown: float = 1.0

## Max distance from tower for an enemy to be considered for melee chase (enemy position vs tower).
@export var patrol_radius: float = 55.0

## Arnulf will not move farther than this from the tower center while chasing (leash).
@export var max_distance_from_tower: float = 16.0

## Seconds at 0 HP (downed) before standing up with full HP. Visual unchanged; body has no collision.
@export var recovery_time: float = 5.0

# ---------------------------------------------------------------------------
# CONSTANTS
# ---------------------------------------------------------------------------

## Tower center — used for target-selection distance comparisons.
## Arnulf always chases the enemy closest to the TOWER, not closest to himself.
const TOWER_CENTER: Vector3 = Vector3.ZERO

## Where Arnulf stands when idle (adjacent to tower base).
const HOME_POSITION: Vector3 = Vector3(2.0, 0.0, 0.0)

## Same issue as EnemyBase: nav next waypoint can match position → normalized() is zero.
const _MIN_NAV_STEP_SQ: float = 0.0004

## Stable id for generic ally signals (SignalBus.ally_*).
const ALLY_ID_ARNULF: String = "arnulf"

## Stop moving into the target beyond this XZ distance — stand and attack instead of pushing.
const ARNULF_MELEE_STOP_DISTANCE: float = 2.2
## If overlap fails (physics jitter), still enter ATTACK when this close on XZ.
const ARNULF_MELEE_SNAP_ATTACK_DISTANCE: float = 1.35

## Scene default: layer bit 2 (value 4) for CharacterBody3D.
const ARNULF_COLLISION_LAYER_BITS: int = 4

# Assign placeholder art resources via convention-based pipeline.
# ---------------------------------------------------------------------------
# STATE
# ---------------------------------------------------------------------------

var _current_state: Types.ArnulfState = Types.ArnulfState.IDLE
var _chase_target: EnemyBase = null
var _attack_timer: float = 0.0
var _recovery_timer: float = 0.0

# POST-MVP: _kill_counter drives Frenzy mode when it reaches a threshold.
# For MVP: counter increments and resets on mission start; no activation logic.
var _kill_counter: int = 0

# ---------------------------------------------------------------------------
# NODE REFERENCES
# ---------------------------------------------------------------------------

@onready var health_component: HealthComponent = $HealthComponent
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var _arnulf_collision: CollisionShape3D = get_node_or_null("ArnulfCollision") as CollisionShape3D
@onready var _visual_slot: Node3D = get_node_or_null("ArnulfVisual")

var _arnulf_anim_player: AnimationPlayer = null
var _arnulf_locomotion_clip: StringName = &""

# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	print("[Arnulf] _ready: hp=%d move_speed=%.1f patrol_radius=%.0f" % [max_hp, move_speed, patrol_radius])
	health_component.max_hp = max_hp
	health_component.reset_to_max()
	health_component.health_depleted.connect(_on_health_depleted)

	# Credit: Godot Engine Documentation — NavigationAgent3D
	#   https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html
	#   Adapted: path_desired_distance and target_desired_distance tuning values.
	navigation_agent.path_desired_distance = 1.0
	navigation_agent.target_desired_distance = 1.5
	navigation_agent.avoidance_enabled = true

	# ASSUMPTION: DetectionArea.collision_mask = 2 (Enemies layer) set in scene.
	# ASSUMPTION: AttackArea.collision_mask = 2 (Enemies layer) set in scene.
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)

	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.game_state_changed.connect(_on_game_state_changed)

	# TODO(ART): Add attack/death clips; drive from ArnulfState when production assets land.
	if _visual_slot != null:
		_arnulf_anim_player = RiggedVisualWiring.mount_glb_scene(
			_visual_slot, RiggedVisualWiring.ALLY_ARNULF_GLB
		)
		if _arnulf_anim_player == null:
			RiggedVisualWiring.clear_visual_slot(_visual_slot)
			var mi: MeshInstance3D = MeshInstance3D.new()
			mi.mesh = ArtPlaceholderHelper.get_ally_mesh("arnulf")
			mi.material_override = ArtPlaceholderHelper.get_faction_material("allies")
			_visual_slot.add_child(mi)

	_transition_to_state(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# PHYSICS PROCESS — State Dispatch
# ---------------------------------------------------------------------------

# Credit: Foul Ward SYSTEMS_part3.md §7.6 (_physics_process dispatch table)
# Credit: Godot Engine Documentation — Engine.time_scale
#   https://docs.godotengine.org/en/stable/classes/class_engine.html
#   All delta-based timers respect Engine.time_scale automatically.

func _physics_process(delta: float) -> void:
	match _current_state:
		Types.ArnulfState.IDLE:
			_process_idle(delta)
		Types.ArnulfState.CHASE:
			_process_chase(delta)
		Types.ArnulfState.ATTACK:
			_process_attack(delta)
		Types.ArnulfState.DOWNED:
			_process_downed(delta)
		Types.ArnulfState.RECOVERING:
			_process_recovering()
		Types.ArnulfState.PATROL:
			# PATROL is a post-MVP stub — treat as IDLE in MVP.
			_process_idle(delta)

	_sync_arnulf_locomotion_animation()

# ---------------------------------------------------------------------------
# STATE HANDLERS
# ---------------------------------------------------------------------------

func _process_idle(_delta: float) -> void:
	var dist_to_home: float = global_position.distance_to(HOME_POSITION)
	if dist_to_home > 1.0:
		navigation_agent.target_position = HOME_POSITION
		var next_pos: Vector3 = navigation_agent.get_next_path_position()
		var to_next: Vector3 = next_pos - global_position
		if to_next.length_squared() < _MIN_NAV_STEP_SQ:
			to_next = HOME_POSITION - global_position
		var direction: Vector3 = to_next.normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector3.ZERO

	# Poll for enemies already inside the detection zone when returning home.
	var target: EnemyBase = _find_closest_enemy_to_tower()
	if target != null:
		_chase_target = target
		_transition_to_state(Types.ArnulfState.CHASE)


func _process_chase(_delta: float) -> void:
	# Credit: is_instance_valid() guard for freed nodes mid-chase.
	if _chase_target == null or not is_instance_valid(_chase_target):
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target == null:
			_transition_to_state(Types.ArnulfState.IDLE)
			return

	if global_position.distance_to(TOWER_CENTER) > max_distance_from_tower:
		_chase_target = null
		_transition_to_state(Types.ArnulfState.IDLE)
		return

	var target_dist_from_tower: float = \
		_chase_target.global_position.distance_to(TOWER_CENTER)
	if target_dist_from_tower > patrol_radius:
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target == null:
			_transition_to_state(Types.ArnulfState.IDLE)
			return

	var to_target_flat: Vector3 = _chase_target.global_position - global_position
	to_target_flat.y = 0.0
	var dist_xz: float = to_target_flat.length()
	if dist_xz <= ARNULF_MELEE_STOP_DISTANCE:
		velocity = Vector3.ZERO
		move_and_slide()
		if attack_area.overlaps_body(_chase_target) or dist_xz <= ARNULF_MELEE_SNAP_ATTACK_DISTANCE:
			_transition_to_state(Types.ArnulfState.ATTACK)
		return

	# Update NavigationAgent3D EVERY frame — the enemy is moving.
	# Credit: Godot Docs NavigationAgent3D per-frame target_position update pattern.
	navigation_agent.target_position = _chase_target.global_position
	var next_pos: Vector3 = navigation_agent.get_next_path_position()
	var to_next: Vector3 = next_pos - global_position
	if to_next.length_squared() < _MIN_NAV_STEP_SQ:
		to_next = _chase_target.global_position - global_position
	var direction: Vector3 = to_next.normalized()
	velocity = direction * move_speed
	move_and_slide()
	# ATTACK transition is also handled by AttackArea.body_entered signal.


func _process_attack(delta: float) -> void:
	if _chase_target == null or not is_instance_valid(_chase_target):
		_chase_target = _find_closest_enemy_to_tower()
		if _chase_target != null:
			_transition_to_state(Types.ArnulfState.CHASE)
		else:
			_transition_to_state(Types.ArnulfState.IDLE)
		return

	velocity = Vector3.ZERO

	# First attack fires immediately (_attack_timer starts at 0 on ATTACK entry).
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		var final_damage: float = DamageCalculator.calculate_damage(
			attack_damage,
			Types.DamageType.PHYSICAL,
			_chase_target.get_enemy_data().armor_type
		)
		_chase_target.take_damage(final_damage, Types.DamageType.PHYSICAL)


func _process_downed(delta: float) -> void:
	velocity = Vector3.ZERO
	_recovery_timer -= delta
	if _recovery_timer <= 0.0:
		_transition_to_state(Types.ArnulfState.RECOVERING)


func _process_recovering() -> void:
	_restore_arnulf_body_after_downed()
	health_component.reset_to_max()
	_clear_all_enemy_arnulf_aggro()
	SignalBus.arnulf_recovered.emit()
	# DEVIATION: generic ally_recovered for ally framework integration.
	SignalBus.ally_recovered.emit(ALLY_ID_ARNULF)
	_transition_to_state(Types.ArnulfState.IDLE)

# ---------------------------------------------------------------------------
# STATE TRANSITION
# ---------------------------------------------------------------------------

func _transition_to_state(new_state: Types.ArnulfState) -> void:
	print("[Arnulf] state → %s  (target=%s)" % [
		Types.ArnulfState.keys()[new_state],
		_chase_target.get_enemy_data().display_name if is_instance_valid(_chase_target) and _chase_target != null else "none"
	])
	_current_state = new_state

	match new_state:
		Types.ArnulfState.IDLE:
			_chase_target = null
			_attack_timer = 0.0
		Types.ArnulfState.CHASE:
			_attack_timer = 0.0
		Types.ArnulfState.ATTACK:
			_attack_timer = 0.0  # First hit fires immediately.
			if is_instance_valid(_chase_target):
				_chase_target.begin_arnulf_retaliation(self)
		Types.ArnulfState.DOWNED:
			_recovery_timer = recovery_time
			_chase_target = null
			velocity = Vector3.ZERO
			_disable_arnulf_body_for_downed()
			_clear_all_enemy_arnulf_aggro()
			SignalBus.arnulf_incapacitated.emit()
			# DEVIATION: generic ally_downed for ally framework integration.
			SignalBus.ally_downed.emit(ALLY_ID_ARNULF)
		Types.ArnulfState.RECOVERING:
			pass
		Types.ArnulfState.PATROL:
			pass  # Post-MVP stub.

	SignalBus.arnulf_state_changed.emit(new_state)


func _disable_arnulf_body_for_downed() -> void:
	if _arnulf_collision != null:
		_arnulf_collision.disabled = true
	collision_layer = 0


func _restore_arnulf_body_after_downed() -> void:
	if _arnulf_collision != null:
		_arnulf_collision.disabled = false
	collision_layer = ARNULF_COLLISION_LAYER_BITS


func _clear_all_enemy_arnulf_aggro() -> void:
	var st: SceneTree = get_tree()
	if st == null:
		return
	st.call_group("enemies", "clear_arnulf_retaliation")


func _sync_arnulf_locomotion_animation() -> void:
	if _arnulf_anim_player == null:
		return
	var horiz: float = 0.0
	if _current_state != Types.ArnulfState.DOWNED and _current_state != Types.ArnulfState.RECOVERING:
		horiz = Vector2(velocity.x, velocity.z).length()
	_arnulf_locomotion_clip = RiggedVisualWiring.update_locomotion_animation(
		_arnulf_anim_player, horiz, _arnulf_locomotion_clip
	)

# ---------------------------------------------------------------------------
# TARGET SELECTION
# ---------------------------------------------------------------------------

# Credit: Foul Ward SYSTEMS_part3.md §7.6 (_find_closest_enemy_to_tower)
# Credit: Godot Engine Documentation — Area3D.get_overlapping_bodies()
#   Selects the enemy closest to TOWER_CENTER from DetectionArea's overlap pool.
#   Flying enemies are excluded — Arnulf is a ground melee unit.

func _find_closest_enemy_to_tower() -> EnemyBase:
	var best_target: EnemyBase = null
	var best_distance: float = patrol_radius + 1.0

	for body: Node3D in detection_area.get_overlapping_bodies():
		var enemy: EnemyBase = body as EnemyBase
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.health_component.is_alive():
			continue
		if enemy.get_enemy_data().is_flying:
			continue
		if enemy.get_enemy_data().move_speed <= 0.001:
			continue

		var dist_to_tower: float = enemy.global_position.distance_to(TOWER_CENTER)
		if dist_to_tower > patrol_radius:
			continue

		if dist_to_tower < best_distance:
			best_distance = dist_to_tower
			best_target = enemy

	return best_target

# ---------------------------------------------------------------------------
# AREA3D SIGNAL HANDLERS
# ---------------------------------------------------------------------------

func _on_detection_area_body_entered(body: Node3D) -> void:
	if _current_state == Types.ArnulfState.DOWNED:
		return
	if _current_state == Types.ArnulfState.RECOVERING:
		return

	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy.get_enemy_data().is_flying:
		return
	if enemy.get_enemy_data().move_speed <= 0.001:
		return

	if _current_state == Types.ArnulfState.IDLE:
		_chase_target = _find_closest_enemy_to_tower()
		# Same-frame manual tests / physics not stepped: overlap list can be empty even though
		# `body_entered` fired — fall back to the body that triggered this handler.
		if _chase_target == null:
			var dist_to_tower: float = enemy.global_position.distance_to(TOWER_CENTER)
			if dist_to_tower <= patrol_radius:
				_chase_target = enemy
		if _chase_target != null:
			_transition_to_state(Types.ArnulfState.CHASE)


func _on_attack_area_body_entered(body: Node3D) -> void:
	if _current_state != Types.ArnulfState.CHASE:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _chase_target:
		_transition_to_state(Types.ArnulfState.ATTACK)


func _on_attack_area_body_exited(body: Node3D) -> void:
	if _current_state != Types.ArnulfState.ATTACK:
		return
	var enemy: EnemyBase = body as EnemyBase
	if enemy == null:
		return
	if enemy == _chase_target:
		_transition_to_state(Types.ArnulfState.CHASE)

# ---------------------------------------------------------------------------
# HEALTH COMPONENT SIGNAL HANDLER
# ---------------------------------------------------------------------------

func _on_health_depleted() -> void:
	_transition_to_state(Types.ArnulfState.DOWNED)

# ---------------------------------------------------------------------------
# SIGNALBUS HANDLERS
# ---------------------------------------------------------------------------

func _on_enemy_killed(
		_enemy_type: Types.EnemyType,
		_position: Vector3,
		_gold_reward: int
) -> void:
	# POST-MVP: increment drives Frenzy mode. MVP: count only.
	_kill_counter += 1


func _on_game_state_changed(
		_old_state: Types.GameState,
		new_state: Types.GameState
) -> void:
	if new_state == Types.GameState.MISSION_BRIEFING:
		reset_for_new_mission()

# ---------------------------------------------------------------------------
# PUBLIC API
# ---------------------------------------------------------------------------

## Returns Arnulf's current state enum value.
func get_current_state() -> Types.ArnulfState:
	return _current_state

## Returns current HP as reported by HealthComponent.
func get_current_hp() -> int:
	return health_component.get_current_hp()

## Returns maximum HP.
func get_max_hp() -> int:
	return health_component.get_max_hp()

## Resets Arnulf for a new mission: full HP, IDLE state, home position.
func reset_for_new_mission() -> void:
	health_component.max_hp = max_hp
	health_component.reset_to_max()
	_restore_arnulf_body_after_downed()
	_clear_all_enemy_arnulf_aggro()
	_kill_counter = 0
	_chase_target = null
	_attack_timer = 0.0
	_recovery_timer = 0.0
	velocity = Vector3.ZERO
	global_position = HOME_POSITION
	_transition_to_state(Types.ArnulfState.IDLE)
	# DEVIATION: Arnulf also broadcasts generic ally_spawned for ally systems.
	SignalBus.ally_spawned.emit(ALLY_ID_ARNULF, "")
	# POST-MVP: emit SignalBus.ally_killed(ALLY_ID_ARNULF) if a permanent-death path is added.


scenes/bosses/boss_base.gd:
## boss_base.gd
## Boss controller extending EnemyBase — reuses nav, damage, and wave integration.

class_name BossBase
extends EnemyBase

var boss_data: BossData = null
var current_phase_index: int = 0


func initialize_boss_data(data: BossData) -> void:
	if data == null:
		push_error("BossBase.initialize_boss_data: BossData is null")
		return
	boss_data = data
	var placeholder: EnemyData = data.build_placeholder_enemy_data()
	initialize(placeholder)
	_apply_boss_stats()
	_configure_visuals()
	SignalBus.boss_spawned.emit(boss_data.boss_id)


func _apply_boss_stats() -> void:
	if boss_data == null:
		return
	# SOURCE: stat application pattern adapted from resource-driven modular enemies (GameDev with Drew, https://www.youtube.com/watch?v=NXvhYdLqrhA)
	var ed: EnemyData = get_enemy_data()
	if ed == null:
		return
	ed.max_hp = boss_data.max_hp
	ed.move_speed = boss_data.move_speed
	ed.damage = boss_data.damage
	ed.attack_range = boss_data.attack_range
	ed.attack_cooldown = boss_data.attack_cooldown
	ed.armor_type = boss_data.armor_type
	ed.gold_reward = boss_data.gold_reward
	ed.is_ranged = boss_data.is_ranged
	ed.is_flying = boss_data.is_flying
	ed.damage_immunities = boss_data.damage_immunities.duplicate()

	health_component.max_hp = boss_data.max_hp
	health_component.reset_to_max()


func _configure_visuals() -> void:
	# TODO(ART): Production boss — phase / ability clips on same AnimationPlayer as placeholders.
	if boss_data == null:
		return
	var slot: Node3D = get_node_or_null("BossVisual") as Node3D
	if slot == null:
		return
	slot.scale = Vector3.ONE
	var glb_path: String = RiggedVisualWiring.boss_rigged_glb_path(boss_data.boss_id)
	if not glb_path.is_empty() and ResourceLoader.exists(glb_path):
		var ap: AnimationPlayer = RiggedVisualWiring.mount_glb_scene(slot, glb_path)
		slot.scale = Vector3(1.5, 1.5, 1.5)
		assign_locomotion_animation_player(ap)
	else:
		RiggedVisualWiring.mount_boss_placeholder_mesh(slot)
		assign_locomotion_animation_player(null)

	var label: Label3D = get_node_or_null("BossLabel") as Label3D
	if label != null:
		label.text = boss_data.display_name


func _on_health_depleted() -> void:
	if boss_data != null:
		SignalBus.boss_killed.emit(boss_data.boss_id)
	super._on_health_depleted()


func advance_phase() -> void:
	if boss_data == null:
		return
	if boss_data.phase_count <= 1:
		return
	current_phase_index = clampi(current_phase_index + 1, 0, boss_data.phase_count - 1)
	# SOURCE: simple phase index tracking inspired by multi-phase boss tutorials (Ludonauta Hollow Knight-style boss, https://ludonauta.itch.io/platformer-essentials/devlog/1089921/hollow-knight-inspired-boss-fight-in-godot-4)
	# POST-MVP: per-phase stat scaling and SignalBus.boss_phase_changed.

