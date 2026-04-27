"""
Blender headless decimation script for Foul Ward gen3d pipeline.

Called as:
  blender --background --python tools/gen3d/pipeline/blender_decimate.py \
          -- input.glb output.glb 10000

Run via subprocess from stage2_mesh.py — do NOT import this file directly.
Requires Blender 3.0+ with bundled Python.
"""
import sys

import bpy


def main() -> None:
    if "--" not in sys.argv:
        print("Usage: blender --background --python blender_decimate.py -- input.glb output.glb target_faces")
        sys.exit(1)

    args = sys.argv[sys.argv.index("--") + 1 :]
    if len(args) < 3:
        print(f"Expected 3 args after --, got: {args}")
        sys.exit(1)

    input_glb = args[0]
    output_glb = args[1]
    target_faces = int(args[2])

    # Clear default Blender scene
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for block in bpy.data.meshes:
        bpy.data.meshes.remove(block)

    # Import GLB
    bpy.ops.import_scene.gltf(filepath=input_glb)
    print(f"[blender_decimate] Imported: {input_glb}")

    for obj in bpy.context.scene.objects:
        if obj.type != "MESH":
            continue
        current_faces = len(obj.data.polygons)
        if current_faces == 0:
            print(f"[blender_decimate] Skipping {obj.name}: 0 faces")
            continue
        ratio = max(0.01, min(1.0, target_faces / current_faces))
        print(
            f"[blender_decimate] {obj.name}: {current_faces} → target {target_faces} (ratio {ratio:.4f})"
        )
        mod = obj.modifiers.new(name="Decimate", type="DECIMATE")
        mod.ratio = ratio
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        bpy.ops.object.modifier_apply(modifier="Decimate")
        after = len(obj.data.polygons)
        print(f"[blender_decimate] {obj.name}: after = {after} faces")

    # Export GLB
    bpy.ops.export_scene.gltf(
        filepath=output_glb,
        export_format="GLB",
        export_texcoords=True,
        export_normals=True,
        export_materials="EXPORT",
        export_animations=True,
    )
    print(f"[blender_decimate] Exported: {output_glb}")
    print("BLENDER_DECIMATE_OK")


main()
