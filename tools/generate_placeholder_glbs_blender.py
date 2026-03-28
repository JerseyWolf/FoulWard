# SPDX-License-Identifier: MIT
# Run from project root:
#   blender --background --python tools/generate_placeholder_glbs_blender.py
#
# Requires: numpy for Blender's glTF exporter (`python3 -m pip install --user numpy --break-system-packages`)
# Outputs: res://art/generated/{enemies,allies,buildings,bosses,misc}/{entity_id}.glb
#          art/generated/generation_log.json

from __future__ import annotations

import addon_utils
import bpy
import json
import math
import os
from mathutils import Euler, Vector

# -----------------------------------------------------------------------------
# Paths (this file lives in tools/)
# -----------------------------------------------------------------------------
_HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.normpath(os.path.join(_HERE, ".."))
GEN_ROOT = os.path.join(PROJECT_ROOT, "art", "generated")
LOG_PATH = os.path.join(GEN_ROOT, "generation_log.json")

# -----------------------------------------------------------------------------
# Palette (linear-ish albedo)
# -----------------------------------------------------------------------------
COL_ORC_BASE = (0.42, 0.38, 0.26)
COL_ORC_ACCENT = (0.32, 0.48, 0.24)
COL_PLAGUE_BASE = (0.16, 0.2, 0.14)
COL_PLAGUE_ACCENT = (0.22, 0.32, 0.2)
COL_ALLY_BASE = (0.55, 0.44, 0.34)
COL_NEUTRAL_BASE = (0.48, 0.46, 0.4)
COL_STONE = (0.44, 0.44, 0.46)


def _ensure_dirs() -> None:
	for sub in ("enemies", "allies", "buildings", "bosses", "misc"):
		os.makedirs(os.path.join(GEN_ROOT, sub), exist_ok=True)


def _reset_scene_data() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()
	for act in list(bpy.data.actions):
		bpy.data.actions.remove(act)
	for mat in list(bpy.data.materials):
		bpy.data.materials.remove(mat)
	for mesh in list(bpy.data.meshes):
		bpy.data.meshes.remove(mesh)


def _enable_rigify() -> None:
	addon_utils.enable("rigify", default_set=True, persistent=True)


def _apply_principled_color(obj: bpy.types.Object, rgb: tuple[float, float, float]) -> None:
	mat = bpy.data.materials.new(name="FW_PlaceholderMat")
	mat.use_nodes = True
	nodes = mat.node_tree.nodes
	bsdf = nodes.get("Principled BSDF")
	if bsdf:
		bsdf.inputs["Base Color"].default_value = (rgb[0], rgb[1], rgb[2], 1.0)
	if obj.data.materials:
		obj.data.materials[0] = mat
	else:
		obj.data.materials.append(mat)


def _remove_widget_meshes() -> None:
	for obj in list(bpy.data.objects):
		if obj.name.startswith("WGT-"):
			bpy.data.objects.remove(obj, do_unlink=True)


def _join_boxes(parts: list[bpy.types.Object], name: str) -> bpy.types.Object:
	bpy.ops.object.select_all(action="DESELECT")
	for p in parts:
		p.select_set(True)
	bpy.context.view_layer.objects.active = parts[0]
	bpy.ops.object.join()
	mesh = bpy.context.active_object
	mesh.name = name
	return mesh


def _cube(loc: Vector, scale: Vector) -> bpy.types.Object:
	bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc)
	o = bpy.context.active_object
	o.scale = scale
	return o


def _cylinder(loc: Vector, radius: float, depth: float) -> bpy.types.Object:
	bpy.ops.mesh.primitive_cylinder_add(radius=radius, depth=depth, location=loc)
	return bpy.context.active_object


def _cone(loc: Vector, radius: float, depth: float) -> bpy.types.Object:
	bpy.ops.mesh.primitive_cone_add(radius1=radius, radius2=0.0, depth=depth, location=loc)
	return bpy.context.active_object


def _plane(loc: Vector, size: tuple[float, float]) -> bpy.types.Object:
	bpy.ops.mesh.primitive_plane_add(size=1.0, location=loc)
	o = bpy.context.active_object
	o.scale = (size[0], size[1], 1.0)
	return o


def build_humanoid_mesh(style: str, scale_mul: float) -> bpy.types.Object:
	# Blocky proportions by style
	if style == "orc":
		tx, ty, tz = 0.42, 0.26, 0.52
		hx, hy, hz = 0.24, 0.22, 0.24
		ax, ay, az = 0.14, 0.14, 0.48
		lx, lz = 0.16, 0.48
	elif style == "plague":
		tx, ty, tz = 0.28, 0.18, 0.58
		hx, hy, hz = 0.18, 0.18, 0.26
		ax, ay, az = 0.1, 0.1, 0.52
		lx, lz = 0.12, 0.52
	elif style == "ally":
		tx, ty, tz = 0.36, 0.22, 0.5
		hx, hy, hz = 0.22, 0.2, 0.24
		ax, ay, az = 0.12, 0.12, 0.46
		lx, lz = 0.15, 0.46
	else:  # neutral / default
		tx, ty, tz = 0.35, 0.22, 0.5
		hx, hy, hz = 0.22, 0.2, 0.24
		ax, ay, az = 0.12, 0.12, 0.46
		lx, lz = 0.15, 0.46

	tx *= scale_mul
	ty *= scale_mul
	tz *= scale_mul
	hx *= scale_mul
	hy *= scale_mul
	hz *= scale_mul
	ax *= scale_mul
	ay *= scale_mul
	az *= scale_mul
	lx *= scale_mul
	lz *= scale_mul

	parts: list[bpy.types.Object] = []
	parts.append(_cube(Vector((0.0, 0.0, 0.95 * scale_mul)), Vector((tx, ty, tz))))
	parts.append(_cube(Vector((0.0, 0.0, 1.65 * scale_mul)), Vector((hx, hy, hz))))
	parts.append(_cube(Vector((0.45 * scale_mul, 0.0, 0.95 * scale_mul)), Vector((ax, ay, az))))
	parts.append(_cube(Vector((-0.45 * scale_mul, 0.0, 0.95 * scale_mul)), Vector((ax, ay, az))))
	parts.append(_cube(Vector((0.15 * scale_mul, 0.0, 0.25 * scale_mul)), Vector((lx, lx, lz))))
	parts.append(_cube(Vector((-0.15 * scale_mul, 0.0, 0.25 * scale_mul)), Vector((lx, lx, lz))))
	return _join_boxes(parts, "HumanoidMesh")


def build_bat_mesh() -> bpy.types.Object:
	parts: list[bpy.types.Object] = []
	parts.append(_cube(Vector((0.0, 0.0, 1.2)), Vector((0.55, 0.12, 0.18))))
	wl = _plane(Vector((0.0, 0.0, 1.25)), (1.2, 0.6))
	wl.rotation_euler = Euler((0.0, math.radians(25.0), math.radians(8.0)))
	parts.append(wl)
	wr = _plane(Vector((0.0, 0.0, 1.25)), (1.2, 0.6))
	wr.rotation_euler = Euler((0.0, math.radians(-25.0), math.radians(-8.0)))
	parts.append(wr)
	return _join_boxes(parts, "BatMesh")


def _rigify_humanoid(mesh: bpy.types.Object, mat_rgb: tuple[float, float, float]) -> bpy.types.Object:
	_apply_principled_color(mesh, mat_rgb)
	bpy.ops.object.armature_human_metarig_add()
	metarig = bpy.context.active_object
	bpy.ops.object.select_all(action="DESELECT")
	mesh.select_set(True)
	metarig.select_set(True)
	bpy.context.view_layer.objects.active = metarig
	bpy.ops.object.parent_set(type="ARMATURE_AUTO")
	bpy.ops.object.select_all(action="DESELECT")
	metarig.select_set(True)
	bpy.context.view_layer.objects.active = metarig
	bpy.ops.object.mode_set(mode="POSE")
	bpy.ops.pose.rigify_generate()
	rig = bpy.context.active_object
	bpy.ops.object.mode_set(mode="OBJECT")
	return rig


def _add_rigify_placeholder_actions(rig: bpy.types.Object) -> int:
	if rig.animation_data is None:
		rig.animation_data_create()
	scene = bpy.context.scene
	bpy.context.view_layer.objects.active = rig
	pb = rig.pose.bones
	chest = pb.get("chest")
	root = pb.get("root")
	ua_l = pb.get("upper_arm_fk.L")
	ua_r = pb.get("upper_arm_fk.R")

	def _clear_pose() -> None:
		bpy.ops.object.mode_set(mode="POSE")
		bpy.ops.pose.select_all(action="SELECT")
		bpy.ops.pose.transforms_clear()
		bpy.ops.object.mode_set(mode="OBJECT")

	# --- idle 1-60 ---
	act_idle = bpy.data.actions.new(name="idle")
	rig.animation_data.action = act_idle
	bpy.ops.object.mode_set(mode="POSE")
	if chest:
		chest.rotation_mode = "XYZ"
	for f in range(1, 61):
		scene.frame_set(f)
		if chest:
			t = (f - 1) / 60.0 * 2.0 * math.pi
			chest.rotation_euler.x = 0.06 * math.sin(t)
			chest.keyframe_insert(data_path="rotation_euler", index=0, frame=f)
	act_idle.use_fake_user = True
	rig.animation_data.action = None
	_clear_pose()

	# --- walk 61-120 ---
	act_walk = bpy.data.actions.new(name="walk")
	rig.animation_data.action = act_walk
	bpy.ops.object.mode_set(mode="POSE")
	if root:
		root.rotation_mode = "XYZ"
	if ua_l:
		ua_l.rotation_mode = "XYZ"
	if ua_r:
		ua_r.rotation_mode = "XYZ"
	for f in range(61, 121):
		scene.frame_set(f)
		phase = (f - 61) / 60.0 * 2.0 * math.pi
		if root:
			root.rotation_euler.x = 0.12 * math.sin(phase * 0.5)
			root.keyframe_insert(data_path="rotation_euler", index=0, frame=f)
		if ua_l:
			ua_l.rotation_euler.x = 0.35 * math.sin(phase)
			ua_l.keyframe_insert(data_path="rotation_euler", index=0, frame=f)
		if ua_r:
			ua_r.rotation_euler.x = 0.35 * math.sin(phase + math.pi)
			ua_r.keyframe_insert(data_path="rotation_euler", index=0, frame=f)
	act_walk.use_fake_user = True
	rig.animation_data.action = None
	_clear_pose()

	# --- death 121-150 ---
	act_death = bpy.data.actions.new(name="death")
	rig.animation_data.action = act_death
	bpy.ops.object.mode_set(mode="POSE")
	if root:
		root.rotation_mode = "XYZ"
	for f in range(121, 151):
		scene.frame_set(f)
		if root:
			t = (f - 121) / 29.0
			root.rotation_euler.x = t * 1.45
			root.keyframe_insert(data_path="rotation_euler", index=0, frame=f)
	act_death.use_fake_user = True
	rig.animation_data.action = None
	_clear_pose()

	return 3


def _export_glb(path: str) -> None:
	bpy.ops.export_scene.gltf(
		filepath=path,
		export_format="GLB",
		use_selection=False,
		export_animations=True,
		export_animation_mode="ACTIONS",
		export_anim_single_armature=True,
		export_reset_pose_bones=True,
		export_force_sampling=True,
	)


def export_humanoid_rigify(
	entity_id: str,
	subdir: str,
	style: str,
	scale_mul: float,
	boss_scale: float,
) -> dict:
	_reset_scene_data()
	_enable_rigify()
	mesh = build_humanoid_mesh(style, scale_mul)
	if boss_scale != 1.0:
		mesh.scale = (boss_scale, boss_scale, boss_scale)
		bpy.ops.object.transform_apply(scale=True)

	if style == "orc":
		rgb = COL_ORC_BASE
	elif style == "plague":
		rgb = COL_PLAGUE_BASE
	elif style == "ally":
		rgb = COL_ALLY_BASE
	else:
		rgb = COL_NEUTRAL_BASE

	rig = _rigify_humanoid(mesh, rgb)

	_remove_widget_meshes()
	anim_count = _add_rigify_placeholder_actions(rig)

	out = os.path.join(GEN_ROOT, subdir, f"{entity_id}.glb")
	_export_glb(out)
	return {
		"entity_id": entity_id,
		"type": subdir,
		"export_path": f"res://art/generated/{subdir}/{entity_id}.glb",
		"godot_import_status": "ok_exported",
		"animation_count": anim_count,
		"has_rig": True,
		"placeholder_quality": "rigify_low_poly_v1",
	}


def _add_object_actions(obj: bpy.types.Object) -> int:
	if obj.animation_data is None:
		obj.animation_data_create()
	scene = bpy.context.scene
	bpy.context.view_layer.objects.active = obj

	act_i = bpy.data.actions.new(name="idle")
	obj.animation_data.action = act_i
	for f in range(1, 61):
		scene.frame_set(f)
		t = (f - 1) / 60.0 * 2.0 * math.pi
		obj.location = Vector((0.0, 0.0, 0.04 * math.sin(t)))
		obj.keyframe_insert(data_path="location", frame=f)
	act_i.use_fake_user = True
	obj.animation_data.action = None

	act_w = bpy.data.actions.new(name="walk")
	obj.animation_data.action = act_w
	for f in range(61, 121):
		scene.frame_set(f)
		ph = (f - 61) / 60.0 * 2.0 * math.pi
		obj.rotation_euler = Euler((0.08 * math.sin(ph), 0.0, 0.05 * math.sin(ph * 2.0)))
		obj.keyframe_insert(data_path="rotation_euler", frame=f)
	act_w.use_fake_user = True
	obj.animation_data.action = None

	act_d = bpy.data.actions.new(name="death")
	obj.animation_data.action = act_d
	for f in range(121, 151):
		scene.frame_set(f)
		t = (f - 121) / 29.0
		obj.rotation_euler = Euler((t * 1.4, 0.0, 0.0))
		obj.keyframe_insert(data_path="rotation_euler", frame=f)
	act_d.use_fake_user = True
	obj.animation_data.action = None

	return 3


def export_bat(entity_id: str) -> dict:
	_reset_scene_data()
	bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0.0, 0.0, 0.0))
	root = bpy.context.active_object
	root.name = "BatRoot"
	m = build_bat_mesh()
	_apply_principled_color(m, COL_NEUTRAL_BASE)
	m.parent = root
	m.location = Vector((0.0, 0.0, 0.0))
	anim = _add_object_actions(root)
	out = os.path.join(GEN_ROOT, "enemies", f"{entity_id}.glb")
	_export_glb(out)
	return {
		"entity_id": entity_id,
		"type": "enemies",
		"export_path": f"res://art/generated/enemies/{entity_id}.glb",
		"godot_import_status": "ok_exported",
		"animation_count": anim,
		"has_rig": False,
		"placeholder_quality": "empty_parent_animated",
	}


def export_static_building(entity_id: str, builder) -> dict:
	_reset_scene_data()
	obj = builder()
	_apply_principled_color(obj, COL_STONE)
	out = os.path.join(GEN_ROOT, "buildings", f"{entity_id}.glb")
	_export_glb(out)
	return {
		"entity_id": entity_id,
		"type": "buildings",
		"export_path": f"res://art/generated/buildings/{entity_id}.glb",
		"godot_import_status": "ok_exported",
		"animation_count": 0,
		"has_rig": False,
		"placeholder_quality": "static_primitive_composite",
	}


def _b_arrow_tower() -> bpy.types.Object:
	parts = [
		_cylinder(Vector((0.0, 0.0, 1.5)), 0.45, 2.8),
		_cube(Vector((0.0, 0.0, 3.1)), Vector((0.35, 0.35, 0.35))),
	]
	return _join_boxes(parts, "ArrowTower")


def _b_fire_brazier() -> bpy.types.Object:
	parts = [
		_cylinder(Vector((0.0, 0.0, 0.25)), 0.7, 0.45),
		_cylinder(Vector((0.0, 0.0, 0.75)), 0.35, 0.9),
	]
	return _join_boxes(parts, "FireBrazier")


def _b_magic_obelisk() -> bpy.types.Object:
	parts = [
		_cube(Vector((0.0, 0.0, 0.2)), Vector((0.8, 0.8, 0.35))),
		_cone(Vector((0.0, 0.0, 2.2)), 0.35, 3.2),
	]
	return _join_boxes(parts, "MagicObelisk")


def _b_poison_vat() -> bpy.types.Object:
	parts = [
		_cylinder(Vector((0.0, 0.0, 0.6)), 0.85, 1.1),
		_cube(Vector((0.0, 0.0, 1.35)), Vector((0.25, 0.25, 0.35))),
	]
	return _join_boxes(parts, "PoisonVat")


def _b_ballista() -> bpy.types.Object:
	parts = [
		_cube(Vector((0.0, 0.0, 0.35)), Vector((1.2, 0.8, 0.45))),
		_cylinder(Vector((0.4, 0.0, 0.85)), 0.12, 1.4),
	]
	return _join_boxes(parts, "Ballista")


def _b_archer_barracks() -> bpy.types.Object:
	parts = [
		_cube(Vector((0.0, 0.0, 0.9)), Vector((1.6, 1.1, 1.6))),
		_cube(Vector((0.0, 0.0, 2.0)), Vector((1.7, 1.2, 0.25))),
	]
	return _join_boxes(parts, "ArcherBarracks")


def _b_anti_air_bolt() -> bpy.types.Object:
	parts = [
		_cylinder(Vector((0.0, 0.0, 2.0)), 0.25, 3.6),
		_cube(Vector((0.35, 0.0, 3.4)), Vector((0.15, 0.8, 0.12))),
		_cube(Vector((-0.35, 0.0, 3.4)), Vector((0.15, 0.8, 0.12))),
		_cube(Vector((0.0, 0.35, 3.4)), Vector((0.8, 0.15, 0.12))),
	]
	return _join_boxes(parts, "AntiAirBolt")


def _b_shield_generator() -> bpy.types.Object:
	base = _cylinder(Vector((0.0, 0.0, 0.2)), 0.9, 0.35)
	bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.85, location=(0.0, 0.0, 1.1))
	dome = bpy.context.active_object
	return _join_boxes([base, dome], "ShieldGen")


def _misc_tower_core() -> bpy.types.Object:
	parts = [
		_cylinder(Vector((0.0, 0.0, 1.0)), 0.55, 1.8),
		_cube(Vector((0.0, 0.0, 2.1)), Vector((0.4, 0.4, 0.35))),
	]
	return _join_boxes(parts, "TowerCore")


def _misc_hex_slot() -> bpy.types.Object:
	bpy.ops.mesh.primitive_cylinder_add(vertices=6, radius=1.0, depth=0.15, location=(0.0, 0.0, 0.0))
	return bpy.context.active_object


def _misc_projectile_crossbow() -> bpy.types.Object:
	parts = [
		_cylinder(Vector((0.0, 0.0, 0.0)), 0.04, 0.55),
		_cube(Vector((0.0, 0.0, 0.0)), Vector((0.08, 0.08, 0.08))),
	]
	return _join_boxes(parts, "ProjCrossbow")


def _misc_projectile_rapid() -> bpy.types.Object:
	parts = [
		_cone(Vector((0.0, 0.0, 0.2)), 0.08, 0.45),
		_cylinder(Vector((0.0, 0.0, -0.1)), 0.05, 0.35),
	]
	return _join_boxes(parts, "ProjRapid")


def _misc_unknown() -> bpy.types.Object:
	return _cube(Vector((0.0, 0.0, 0.5)), Vector((0.5, 0.5, 0.5)))


def export_misc(entity_id: str, builder) -> dict:
	_reset_scene_data()
	obj = builder()
	_apply_principled_color(obj, COL_NEUTRAL_BASE)
	out = os.path.join(GEN_ROOT, "misc", f"{entity_id}.glb")
	_export_glb(out)
	return {
		"entity_id": entity_id,
		"type": "misc",
		"export_path": f"res://art/generated/misc/{entity_id}.glb",
		"godot_import_status": "ok_exported",
		"animation_count": 0,
		"has_rig": False,
		"placeholder_quality": "static_misc",
	}


def main() -> None:
	_ensure_dirs()
	log: dict = {
		"blender_version": ".".join(str(x) for x in bpy.app.version[:3]),
		"generator": "tools/generate_placeholder_glbs_blender.py",
		"entries": [],
	}

	jobs: list[tuple[str, callable]] = []

	# Enemies (humanoid)
	jobs.append(("orc_grunt", lambda: export_humanoid_rigify("orc_grunt", "enemies", "orc", 1.0, 1.0)))
	jobs.append(("orc_brute", lambda: export_humanoid_rigify("orc_brute", "enemies", "orc", 1.25, 1.0)))
	jobs.append(("goblin_firebug", lambda: export_humanoid_rigify("goblin_firebug", "enemies", "orc", 0.72, 1.0)))
	jobs.append(("plague_zombie", lambda: export_humanoid_rigify("plague_zombie", "enemies", "plague", 1.0, 1.0)))
	jobs.append(("orc_archer", lambda: export_humanoid_rigify("orc_archer", "enemies", "orc", 0.95, 1.0)))
	jobs.append(("bat_swarm", lambda: export_bat("bat_swarm")))

	# Ally
	jobs.append(("arnulf", lambda: export_humanoid_rigify("arnulf", "allies", "ally", 1.0, 1.0)))

	# Buildings
	jobs.append(("arrow_tower", lambda: export_static_building("arrow_tower", _b_arrow_tower)))
	jobs.append(("fire_brazier", lambda: export_static_building("fire_brazier", _b_fire_brazier)))
	jobs.append(("magic_obelisk", lambda: export_static_building("magic_obelisk", _b_magic_obelisk)))
	jobs.append(("poison_vat", lambda: export_static_building("poison_vat", _b_poison_vat)))
	jobs.append(("ballista", lambda: export_static_building("ballista", _b_ballista)))
	jobs.append(("archer_barracks", lambda: export_static_building("archer_barracks", _b_archer_barracks)))
	jobs.append(("anti_air_bolt", lambda: export_static_building("anti_air_bolt", _b_anti_air_bolt)))
	jobs.append(("shield_generator", lambda: export_static_building("shield_generator", _b_shield_generator)))

	# Bosses (1.5× silhouette)
	jobs.append(("plague_cult_miniboss", lambda: export_humanoid_rigify("plague_cult_miniboss", "bosses", "plague", 1.0, 1.5)))
	jobs.append(("orc_warlord", lambda: export_humanoid_rigify("orc_warlord", "bosses", "orc", 1.0, 1.5)))
	jobs.append(("final_boss", lambda: export_humanoid_rigify("final_boss", "bosses", "plague", 1.0, 1.5)))
	jobs.append(("audit5_territory_mini", lambda: export_humanoid_rigify("audit5_territory_mini", "bosses", "neutral", 1.0, 1.5)))

	# Misc
	jobs.append(("tower_core", lambda: export_misc("tower_core", _misc_tower_core)))
	jobs.append(("hex_slot", lambda: export_misc("hex_slot", _misc_hex_slot)))
	jobs.append(("projectile_crossbow", lambda: export_misc("projectile_crossbow", _misc_projectile_crossbow)))
	jobs.append(("projectile_rapid_missile", lambda: export_misc("projectile_rapid_missile", _misc_projectile_rapid)))
	jobs.append(("unknown_mesh", lambda: export_misc("unknown_mesh", _misc_unknown)))

	for name, fn in jobs:
		try:
			entry = fn()
			log["entries"].append(entry)
			print("OK", name)
		except Exception as e:
			log["entries"].append(
				{
					"entity_id": name,
					"type": "error",
					"export_path": "",
					"godot_import_status": f"error:{e!s}",
					"animation_count": 0,
					"has_rig": False,
					"placeholder_quality": "failed",
				}
			)
			print("FAIL", name, e)

	with open(LOG_PATH, "w", encoding="utf-8") as f:
		json.dump(log, f, indent=2)
	print("Wrote", LOG_PATH)


if __name__ == "__main__":
	main()
