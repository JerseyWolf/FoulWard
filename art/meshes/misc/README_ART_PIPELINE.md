The exact folder path: res://art/meshes/misc/

Files: .tres Mesh resources or .glb for tower, projectiles, hex slots, and the fallback unknown mesh.

Named files expected:

    tower_core.tres — main tower body mesh

    projectile_crossbow.tres — Florence crossbow bolt

    projectile_rapid_missile.tres — rapid missile visual

    hex_slot.tres — build-mode hex slot indicator

    unknown_mesh.tres — generic fallback, MUST always exist

Loaded by:

    - ArtPlaceholderHelper.get_tower_mesh()

    - ArtPlaceholderHelper.get_unknown_mesh()

    - ProjectileBase and HexGrid scripts directly or via helper

Note: unknown_mesh.tres is a hard dependency — the helper will fail gracefully without it but will log an error. Keep it present at all times.

External tools: same.
