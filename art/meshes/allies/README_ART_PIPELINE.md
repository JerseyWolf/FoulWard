The exact folder path: res://art/meshes/allies/

Files: .tres Mesh resources or .glb imports.

Naming: ally_{ally_id}.tres / .glb where ally_id is a lowercase string matching the ally's identifier.

Current allies:

    Arnulf → ally_arnulf.tres / .glb

Loaded by: ArtPlaceholderHelper.get_ally_mesh(ally_id: StringName)

Fallback: unknown_mesh.tres

How to add a new ally:

    1) Decide the ally_id string (e.g., "sybil").

    2) Add token handling in ArtPlaceholderHelper._get_ally_token().

    3) Place mesh file here.

    4) Wire the ally scene to call get_ally_mesh(ally_id) in _ready().

    5) Done.

External tools: same as enemies.

Generated assets: res://art/generated/meshes/ally_{ally_id}.tres checked first.
