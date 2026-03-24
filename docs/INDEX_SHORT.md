# Foul Ward Code Index (Short)

## Autoloads (`project.godot`)
- `SignalBus` -> `res://autoloads/signal_bus.gd`
- `DamageCalculator` -> `res://autoloads/damage_calculator.gd`
- `EconomyManager` -> `res://autoloads/economy_manager.gd`
- `GameManager` -> `res://autoloads/game_manager.gd`
- `AutoTestDriver` -> `res://autoloads/auto_test_driver.gd`

## First-party script files
- `autoloads/auto_test_driver.gd`
- `autoloads/damage_calculator.gd`
- `autoloads/economy_manager.gd`
- `autoloads/game_manager.gd`
- `autoloads/signal_bus.gd`
- `scripts/health_component.gd`
- `scripts/input_manager.gd`
- `scripts/main_root.gd`
- `scripts/research_manager.gd`
- `scripts/shop_manager.gd`
- `scripts/sim_bot.gd`
- `scripts/spell_manager.gd`
- `scripts/types.gd`
- `scripts/wave_manager.gd`
- `scripts/resources/building_data.gd`
- `scripts/resources/enemy_data.gd`
- `scripts/resources/research_node_data.gd`
- `scripts/resources/shop_item_data.gd`
- `scripts/resources/spell_data.gd`
- `scripts/resources/weapon_data.gd`
- `scenes/arnulf/arnulf.gd`
- `scenes/buildings/building_base.gd`
- `scenes/enemies/enemy_base.gd`
- `scenes/hex_grid/hex_grid.gd`
- `scenes/projectiles/projectile_base.gd`
- `scenes/tower/tower.gd`
- `ui/between_mission_screen.gd`
- `ui/build_menu.gd`
- `ui/end_screen.gd`
- `ui/hud.gd`
- `ui/main_menu.gd`
- `ui/mission_briefing.gd`
- `ui/ui_manager.gd`

## Resource script types
- `BuildingData` (`scripts/resources/building_data.gd`)
- `EnemyData` (`scripts/resources/enemy_data.gd`)
- `ResearchNodeData` (`scripts/resources/research_node_data.gd`)
- `ShopItemData` (`scripts/resources/shop_item_data.gd`)
- `SpellData` (`scripts/resources/spell_data.gd`)
- `WeaponData` (`scripts/resources/weapon_data.gd`)

## Resource instances (`resources/`)
- `BuildingData` instances:
  - `resources/building_data/anti_air_bolt.tres`
  - `resources/building_data/archer_barracks.tres`
  - `resources/building_data/arrow_tower.tres`
  - `resources/building_data/ballista.tres`
  - `resources/building_data/fire_brazier.tres`
  - `resources/building_data/magic_obelisk.tres`
  - `resources/building_data/poison_vat.tres`
  - `resources/building_data/shield_generator.tres`
- `EnemyData` instances:
  - `resources/enemy_data/bat_swarm.tres`
  - `resources/enemy_data/goblin_firebug.tres`
  - `resources/enemy_data/orc_archer.tres`
  - `resources/enemy_data/orc_brute.tres`
  - `resources/enemy_data/orc_grunt.tres`
  - `resources/enemy_data/plague_zombie.tres`
- `ResearchNodeData` instances:
  - `resources/research_data/arrow_tower_plus_damage.tres`
  - `resources/research_data/base_structures_tree.tres`
  - `resources/research_data/fire_brazier_plus_range.tres`
  - `resources/research_data/unlock_anti_air.tres`
  - `resources/research_data/unlock_archer_barracks.tres`
  - `resources/research_data/unlock_shield_generator.tres`
- `ShopItemData` instances:
  - `resources/shop_data/shop_item_arrow_tower.tres`
  - `resources/shop_data/shop_item_building_repair.tres`
  - `resources/shop_data/shop_item_mana_draught.tres`
  - `resources/shop_data/shop_item_tower_repair.tres`
  - `resources/shop_data/shop_catalog.tres` (container-style resource with subresources)
- `SpellData` instances:
  - `resources/spell_data/shockwave.tres`
- `WeaponData` instances:
  - `resources/weapon_data/crossbow.tres`
  - `resources/weapon_data/rapid_missile.tres`

## Scene files (first-party)
- `scenes/main.tscn`
- `scenes/arnulf/arnulf.tscn`
- `scenes/buildings/building_base.tscn`
- `scenes/enemies/enemy_base.tscn`
- `scenes/hex_grid/hex_grid.tscn`
- `scenes/projectiles/projectile_base.tscn`
- `scenes/tower/tower.tscn`
- `ui/hud.tscn`
- `ui/build_menu.tscn`
- `ui/between_mission_screen.tscn`
- `ui/main_menu.tscn`
- `ui/mission_briefing.tscn`
- `ui/end_screen` exists as an embedded node in `scenes/main.tscn` (no standalone `.tscn` file)
