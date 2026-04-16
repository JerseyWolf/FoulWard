# Context Brief — Session 10: Settings Graphics

## SettingsManager API (§3.8)

user://settings.cfg — volumes, graphics quality, keybind mirror.

| Signature | Returns | Usage |
|-----------|---------|-------|
| save_settings() -> void | void | Persists to user://settings.cfg |
| load_settings() -> void | void | Loads from config file |
| set_volume(bus_name: String, value: float) -> void | void | Sets "Master", "Music", or "SFX" (0.0-1.0) |
| set_graphics_quality(quality: String) -> void | void | Stores string; no RenderingServer calls (MVP) |
| remap_action(action_name: String, new_event: InputEvent) -> void | void | Replaces first binding and saves |

Current state: set_graphics_quality stores "low", "medium", or "high" as a string in the config file. No actual rendering changes are applied.

## Headless Considerations

The game supports headless execution (SimBot, GdUnit4 tests, AutoTestDriver). Any rendering code must guard against:
- No viewport available (get_viewport() returns null in some headless contexts)
- No WorldEnvironment node present
- RenderingServer calls that crash in headless mode

Pattern: `if not Engine.is_editor_hint() and get_viewport() != null:`

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
- get_node_or_null() for runtime lookups with null guard
- push_warning() not assert() in production
