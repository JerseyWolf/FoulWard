# GDAI MCP vendor notes

The **canonical** GDAI addon in this repo lives only under:

`addons/gdai-mcp-plugin-godot/`

**Do not** add a second copy under `res://MCPs/.../addons/`. Godot scans all of `res://`; a duplicate loads the GDExtension twice, which breaks registration and can prevent the **HTTP bridge** (`http://localhost:3571`) from working reliably.

To update from a vendor zip: extract it somewhere **outside** `res://` (e.g. `/tmp/gdai-vendor/`), then merge into `addons/gdai-mcp-plugin-godot/`, or use:

`MCPs/sync_gdai_addon_into_project.sh /path/to/extracted/addons/gdai-mcp-plugin-godot`

The **Cursor** Python bridge (`uv run …/gdai_mcp_server.py`) only forwards MCP to Godot; **the HTTP server runs inside the Godot editor** when the project is open and the plugin is enabled.
