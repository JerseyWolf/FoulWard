The exact folder path: res://art/icons/buildings/

Files: Texture2D resources (.png imported as Texture2D, or .tres ImageTexture).

Naming:

    icon_building_{building_token}.png

Loaded by: ArtPlaceholderHelper.get_building_icon() — POST-MVP stub methods.

How to produce icons:

    - Python Pillow: generate colored rectangle + label .png, place here.

    - AI image tools: generate .png, resize to consistent size (e.g., 64x64 or 128x128), place here.

    - Godot ViewportTexture: render 3D scene to texture, save as icon (advanced).

POST-MVP: Icon wiring into UI is not implemented yet. Files placed here will be available immediately once the stub methods are completed.
