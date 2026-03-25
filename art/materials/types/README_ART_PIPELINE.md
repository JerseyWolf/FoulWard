The exact folder path: res://art/materials/types/

Files: StandardMaterial3D .tres per building or enemy type, for type-specific overrides beyond faction colors.

Naming:

    building_{building_token}_material.tres

    enemy_{enemy_token}_material.tres

When used: ArtPlaceholderHelper.get_building_material() / get_enemy_material() will check here first, then fall back to the faction material.

POST-MVP: This folder is empty in the initial scaffolding. Fill in as art direction solidifies. When you add a file here it will automatically be picked up by the helper.

External tools: Godot editor material editor, or scripted StandardMaterial3D .tres creation.
