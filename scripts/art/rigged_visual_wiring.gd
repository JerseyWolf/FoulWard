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
