import bpy
import addon_utils

addon_utils.enable("rigify", default_set=True, persistent=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete()
bpy.ops.object.armature_human_metarig_add()
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.rigify_generate()
rig = bpy.context.active_object
names = [b.name for b in rig.pose.bones]
ctrl = [n for n in names if not n.startswith(("DEF-", "MCH-", "VIS-", "WGT-"))]
print("CONTROL-LIKE", ctrl[:40])
