"""One-off Rigify pipeline smoke test — run: blender --background --python tools/blender_rigify_test.py"""
import bpy
import addon_utils

addon_utils.enable("rigify", default_set=True, persistent=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()

bpy.ops.object.armature_human_metarig_add()
metarig = bpy.context.active_object
metarig.location = (0.0, 0.0, 0.0)

parts = []


def add_box(loc, sc) -> None:
	bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
	o = bpy.context.active_object
	o.scale = sc
	parts.append(o)


add_box((0, 0, 0.95), (0.35, 0.22, 0.5))
add_box((0, 0, 1.65), (0.22, 0.2, 0.22))
add_box((0.45, 0, 0.95), (0.12, 0.12, 0.45))
add_box((-0.45, 0, 0.95), (0.12, 0.12, 0.45))
add_box((0.15, 0, 0.25), (0.14, 0.14, 0.45))
add_box((-0.15, 0, 0.25), (0.14, 0.14, 0.45))

bpy.ops.object.select_all(action="DESELECT")
for o in parts:
	o.select_set(True)
bpy.context.view_layer.objects.active = parts[0]
bpy.ops.object.join()
mesh = bpy.context.active_object
mesh.name = "OrcBody"

bpy.ops.object.select_all(action="DESELECT")
mesh.select_set(True)
metarig.select_set(True)
bpy.context.view_layer.objects.active = metarig
bpy.ops.object.parent_set(type="ARMATURE_AUTO")
print("parent auto OK")

bpy.ops.object.select_all(action="DESELECT")
metarig.select_set(True)
bpy.context.view_layer.objects.active = metarig
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.rigify_generate()
print("rigify_generate OK")

rig = bpy.context.active_object
print("active after gen", rig.name)
if rig.pose:
	alln = list(rig.pose.bones.keys())
	ctrl = [n for n in alln if not n.startswith(("DEF-", "MCH-", "VIS-", "ORG-", "WGT-"))]
	print("CONTROL BONES", ctrl)

out = "/tmp/test_orc.glb"
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=False, export_animations=True)
print("exported", out)
