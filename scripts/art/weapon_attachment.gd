# weapon_attachment.gd
# Loads a weapon GLB and attaches it to the correct bone of a character skeleton.
class_name WeaponAttachment
extends RefCounted

const WEAPON_BASE_PATH := "res://art/generated/weapons/"


static func attach(character_root: Node3D, weapon_slug: String, bone_name: String) -> Node3D:
	var weapon_path := WEAPON_BASE_PATH + weapon_slug + ".glb"
	if not ResourceLoader.exists(weapon_path):
		push_warning("WeaponAttachment: weapon GLB not found: " + weapon_path)
		return null
	var skeleton := _find_skeleton(character_root)
	if skeleton == null:
		push_warning("WeaponAttachment: no Skeleton3D found under " + character_root.name)
		return null
	var bone_idx := skeleton.find_bone(bone_name)
	if bone_idx == -1:
		push_warning("WeaponAttachment: bone '%s' not found in skeleton" % bone_name)
		return null
	var attach_node := BoneAttachment3D.new()
	attach_node.bone_name = bone_name
	attach_node.name = "WeaponAttach_" + bone_name
	skeleton.add_child(attach_node)
	attach_node.owner = character_root
	var weapon_scene: PackedScene = load(weapon_path)
	if weapon_scene == null:
		push_warning("WeaponAttachment: failed to load: " + weapon_path)
		return null
	var weapon_instance := weapon_scene.instantiate()
	attach_node.add_child(weapon_instance)
	weapon_instance.owner = character_root
	return weapon_instance


static func _find_skeleton(root: Node) -> Skeleton3D:
	if root is Skeleton3D:
		return root as Skeleton3D
	for child in root.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null
