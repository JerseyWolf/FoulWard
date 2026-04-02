# PROMPT 4 IMPLEMENTATION

Date: 2026-03-24

Cross-reference: Phase 3 details are in `docs/PROMPT_3_IMPLEMENTATION.md`.

## Implemented

- Added data-driven enchantment resource class:
  - `res://scripts/resources/enchantment_data.gd`

- Added new autoload singleton:
  - `res://autoloads/enchantment_manager.gd`
  - Registered in `project.godot` as `EnchantmentManager`

- Added new SignalBus events in `res://autoloads/signal_bus.gd`:
  - `enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)`
  - `enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)`

- Added enchantment resources:
  - `res://resources/enchantments/scorching_bolts.tres`
  - `res://resources/enchantments/sharpened_mechanism.tres`
  - `res://resources/enchantments/toxic_payload.tres`
  - `res://resources/enchantments/arcane_focus.tres`

- Projectile composition path update:
  - `res://scenes/projectiles/projectile_base.gd`
  - `initialize_from_weapon(...)` now supports optional `custom_damage` and `custom_damage_type`.
  - Default no-override call path remains physical/base for backward compatibility.

- Tower enchantment composition:
  - `res://scenes/tower/tower.gd`
  - Added `_compose_projectile_stats(...)` and `_spawn_weapon_projectile(...)`.
  - `fire_crossbow(...)` and rapid-missile burst shots now spawn projectiles using composed enchantment stats.
  - No-enchantment state preserves prior behavior (`PHYSICAL`, base damage).

- New-game reset integration:
  - `res://autoloads/game_manager.gd`
  - `start_new_game()` now calls `EnchantmentManager.reset_to_defaults()`.

- Between-mission UI integration:
  - `res://ui/between_mission_screen.tscn`: added enchantment controls under `WeaponsTab`.
  - `res://ui/between_mission_screen.gd`: added manager-driven apply/remove handlers and label refresh.
  - UI remains a thin presenter; equip/remove logic is handled by `EnchantmentManager`.

- Added tests:
  - `res://tests/test_enchantment_manager.gd`
  - `res://tests/test_tower_enchantments.gd`
  - Added projectile regression in `res://tests/test_projectile_system.gd`:
    - `test_initialize_from_weapon_without_custom_values_uses_physical`

## Notes

- # POST-MVP: Enchantment affinity is currently tracked as inert manager state (`_affinity_level`, `_affinity_xp`) with no gameplay effects yet.
- # ASSUMPTION: Enchantment resources resolve from `res://resources/enchantments/{enchantment_id}.tres`.
- # SOURCE: Resource composition patterns and stat-modifier layering references are cited inline in new scripts.
