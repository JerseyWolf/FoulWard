The exact folder path: res://art/materials/factions/

Files: StandardMaterial3D .tres resources.

Naming: faction_{faction_token}_material.tres

Current faction tokens and files:

    orcs → faction_orcs_material.tres (saturated green)

    plague → faction_plague_material.tres (purple/sickly)

    neutral → faction_neutral_material.tres (mid gray)

    allies → faction_allies_material.tres (blue or blue-gold)

Loaded by: ArtPlaceholderHelper.get_faction_material(faction_id: StringName)

Fallback: If unknown faction, returns faction_neutral_material.tres.

ASSUMPTION: Faction tokens are plain StringNames ("orcs", "plague", etc.) until a Types.Faction enum is added. When that enum is added, update ArtPlaceholderHelper._get_faction_token() to map from it.

How to add a new faction:

    1) Create faction_{token}_material.tres here.

    2) Add a match case in ArtPlaceholderHelper._get_faction_token().

    3) Done.

External tools: Create StandardMaterial3D directly in the Godot editor or via EditorScript; save here.
