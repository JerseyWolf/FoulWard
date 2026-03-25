The exact folder path: res://art/icons/enemies/

Files: Texture2D resources (.png imported as Texture2D, or .tres ImageTexture).

Naming:

    icon_enemy_{enemy_token}.png

Loaded by: ArtPlaceholderHelper.get_enemy_icon() — POST-MVP stub methods.

How to produce icons:

    - Python Pillow: generate colored rectangle + label .png, place here.

    - AI image tools: generate .png, resize to consistent size (e.g., 64x64 or 128x128), place here.

    - Godot ViewportTexture: render 3D scene to texture, save as icon (advanced).

POST-MVP: Icon wiring into UI is not implemented yet. Files placed here will be available immediately once the stub methods are completed.
