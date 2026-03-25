The exact folder path: res://art/meshes/buildings/

Files: .tres Mesh resources or imported .glb files.

Naming: building_{building_token}.tres / .glb

Current tokens and expected filenames:

    ARROW_TOWER → building_arrow_tower.tres / .glb

    FIRE_BRAZIER → building_fire_brazier.tres / .glb

    MAGIC_OBELISK → building_magic_obelisk.tres / .glb

    POISON_VAT → building_poison_vat.tres / .glb

    BALLISTA → building_ballista.tres / .glb

    ARCHER_BARRACKS → building_archer_barracks.tres / .glb

    ANTI_AIR_BOLT → building_anti_air_bolt.tres / .glb

    SHIELD_GENERATOR → building_shield_generator.tres / .glb

Loaded by: ArtPlaceholderHelper.get_building_mesh(building_type)

Fallback: unknown_mesh.tres

How to add a new building type: same 5-step pattern as enemies but using Types.BuildingType and BuildingData.

External tools: same as enemies.

Generated assets: same generated/ priority rule.
