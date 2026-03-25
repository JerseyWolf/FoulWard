The exact folder path: res://art/generated/meshes/

Purpose: Drop zone for AI-generated or procedurally generated mesh files that override the manual placeholders.

Files: .glb or .tres Mesh resources, same naming convention as their counterparts in res://art/meshes/.

Priority: ArtPlaceholderHelper checks this folder FIRST before res://art/meshes/. If a generated mesh exists here, it is used automatically.

How to populate:

    - Blender script: run blender --background --python tools/generate_meshes.py — outputs named .glb files here.

    - Meshy / Tripo AI Python script: run python tools/generate_art_api.py — downloads and names .glb files here.

    - trimesh Python script: python tools/generate_meshes_trimesh.py — generates primitive .glb files here.

File placement: just drop the correctly named .glb into this folder and Godot will auto-import it on the next project scan.

No code changes needed when adding generated meshes — the naming convention handles everything.
