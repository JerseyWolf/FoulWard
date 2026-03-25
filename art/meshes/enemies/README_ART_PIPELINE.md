The exact folder path: res://art/meshes/enemies/

Files: Godot .tres Mesh resources (BoxMesh, CapsuleMesh, SphereMesh, etc.) or imported .glb files.

Naming: enemy_{enemy_token}.tres or enemy_{enemy_token}.glb where enemy_token is the lowercase snake_case token for Types.EnemyType.

Current tokens and expected filenames:

    ORC_GRUNT → enemy_orc_grunt.tres / .glb

    ORC_BRUTE → enemy_orc_brute.tres / .glb

    GOBLIN_FIREBUG → enemy_goblin_firebug.tres / .glb

    PLAGUE_ZOMBIE → enemy_plague_zombie.tres / .glb

    ORC_ARCHER → enemy_orc_archer.tres / .glb

    BAT_SWARM → enemy_bat_swarm.tres / .glb

Loaded by: ArtPlaceholderHelper.get_enemy_mesh(enemy_type) in res://scripts/art/art_placeholder_helper.gd

Fallback: If a file is missing, the helper uses res://art/meshes/misc/unknown_mesh.tres and logs a warning.

How to add a new enemy type:

    1) Add the new EnemyType value to Types.EnemyType in res://scripts/types.gd.

    2) Add a matching token string in ArtPlaceholderHelper._get_enemy_token().

    3) Place the mesh file here with the correct name.

    4) Create a new EnemyData .tres under res://resources/.

    5) Done — no other code changes needed.

External tools:

    - Blender: export as .glb, place here. Godot auto-imports on project scan.

    - Meshy / Tripo AI: download .glb, rename to convention, place here.

    - Godot EditorScript: create BoxMesh/CapsuleMesh .tres, save here.

    - Python trimesh: generate .glb programmatically, place here.

Generated assets: Place AI/Blender outputs in res://art/generated/meshes/ with the same filename. The helper checks generated/ first before falling back to this folder.
