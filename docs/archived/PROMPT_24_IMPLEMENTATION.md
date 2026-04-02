# PROMPT 24 — Placeholder icons + SettingsManager + settings UI

## Done

1. **`res://tools/generate_placeholder_icons.gd`** — `PlaceholderIconGenerator`: 64×64 PNGs (SubViewport label + category colors), tokens aligned with `ArtPlaceholderHelper`.
2. **`res://tools/run_generate_placeholder_icons.gd`** — headless runner (non-`--quit-after`; use script `quit()`).
3. **`addons/fw_placeholder_icons/`** — EditorPlugin: **Project → Generate Placeholder Icons** + filesystem scan.
4. **`res://scripts/art/art_placeholder_helper.gd`** — `get_building_icon` / `get_enemy_icon` / `get_ally_icon` with `art/generated/icons/` priority, 16×16 magenta fallback, icon cache + `clear_cache()`.
5. **UI** — `build_menu.gd`, `between_mission_screen.gd` (shop + research), `world_map.gd` (territory buttons + faction primary enemy).
6. **`res://autoloads/settings_manager.gd`** — autoload **before** `GameManager`; `user://settings.cfg`; Music/SFX buses; no `class_name` (avoids autoload name clash).
7. **`res://scenes/ui/settings_screen.tscn`** + **`res://scripts/ui/settings_screen.gd`** — sliders, quality, keybind rows, Back.
8. **`ui/main_menu.gd`** — opens settings overlay; `main_menu.tscn` Settings button enabled.
9. **`tests/test_settings_manager.gd`** — 5 cases; `run_gdunit_quick.sh` allowlist updated.
10. **Repo fixes** — `save_manager.gd`: removed `class_name SaveManager` (autoload clash). `game_manager.gd`: SaveManager wiring.

## Note

Full `./tools/run_gdunit.sh` not run in this session (per request: quick suite only).
