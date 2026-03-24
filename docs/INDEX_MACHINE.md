# Foul Ward Code Index (Machine-Friendly)

## 1) Autoload Matrix

| name | path | script_class | emits_signals(csv) |
|---|---|---|---|
| SignalBus | `res://autoloads/signal_bus.gd` | `-` | `-` |
| CampaignManager | `res://autoloads/campaign_manager.gd` | `-` | `campaign_started,day_started,day_won,day_failed,campaign_completed` |
| DamageCalculator | `res://autoloads/damage_calculator.gd` | `-` | `-` |
| EconomyManager | `res://autoloads/economy_manager.gd` | `-` | `resource_changed` |
| GameManager | `res://autoloads/game_manager.gd` | `-` | `mission_started,build_mode_entered,game_state_changed,build_mode_exited,mission_won,mission_failed` |
| EnchantmentManager | `res://autoloads/enchantment_manager.gd` | `-` | `enchantment_applied,enchantment_removed` |
| AutoTestDriver | `res://autoloads/auto_test_driver.gd` | `-` | `-` |
| GDAIMCPRuntime | `uid://dcne7ryelpxmn` | `-` | `-` |
| MCPScreenshot | `res://addons/godot_mcp/mcp_screenshot_service.gd` | `-` | `-` |
| MCPInputService | `res://addons/godot_mcp/mcp_input_service.gd` | `-` | `-` |
| MCPGameInspector | `res://addons/godot_mcp/mcp_game_inspector_service.gd` | `-` | `-` |

## 2) Script Matrix (first-party only)

| path | class_name | extends | public_methods(csv signatures) | exports(csv name:type) | declared_local_signals(csv) | emits_signalbus(csv) | key_dependencies(csv) |
|---|---|---|---|---|---|---|---|
| `res://autoloads/signal_bus.gd` | `-` | `Node` | `-` | `-` | `enemy_killed(enemy_type:Types.EnemyType,position:Vector3,gold_reward:int),enemy_reached_tower(enemy_type:Types.EnemyType,damage:int),tower_damaged(current_hp:int,max_hp:int),tower_destroyed(),projectile_fired(weapon_slot:Types.WeaponSlot,origin:Vector3,target:Vector3),arnulf_state_changed(new_state:Types.ArnulfState),arnulf_incapacitated(),arnulf_recovered(),wave_countdown_started(wave_number:int,seconds_remaining:float),wave_started(wave_number:int,enemy_count:int),wave_cleared(wave_number:int),all_waves_cleared(),resource_changed(resource_type:Types.ResourceType,new_amount:int),territory_state_changed(territory_id:String),world_map_updated(),building_placed(slot_index:int,building_type:Types.BuildingType),building_sold(slot_index:int,building_type:Types.BuildingType),building_upgraded(slot_index:int,building_type:Types.BuildingType),building_destroyed(slot_index:int),spell_cast(spell_id:String),spell_ready(spell_id:String),mana_changed(current_mana:int,max_mana:int),game_state_changed(old_state:Types.GameState,new_state:Types.GameState),mission_started(mission_number:int),mission_won(mission_number:int),mission_failed(mission_number:int),build_mode_entered(),build_mode_exited(),research_unlocked(node_id:String),shop_item_purchased(item_id:String),mana_draught_consumed()` | `-` | `Types` |
| `res://autoloads/damage_calculator.gd` | `-` | `Node` | `calculate_damage(base_damage:float,damage_type:Types.DamageType,armor_type:Types.ArmorType)->float,calculate_dot_tick(dot_total_damage:float,tick_interval:float,duration:float,damage_type:Types.DamageType,armor_type:Types.ArmorType)->float` | `-` | `-` | `-` | `Types` |
| `res://autoloads/economy_manager.gd` | `-` | `Node` | `add_gold(amount:int)->void,spend_gold(amount:int)->bool,add_building_material(amount:int)->void,spend_building_material(amount:int)->bool,add_research_material(amount:int)->void,spend_research_material(amount:int)->bool,can_afford(gold_cost:int,material_cost:int)->bool,get_gold()->int,get_building_material()->int,get_research_material()->int,reset_to_defaults()->void` | `-` | `-` | `resource_changed` | `SignalBus,Types,OS` |
| `res://autoloads/game_manager.gd` | `-` | `Node` | `start_new_game()->void,start_next_mission()->void,start_wave_countdown()->void,enter_build_mode()->void,exit_build_mode()->void,get_game_state()->Types.GameState,get_current_mission()->int,get_current_wave()->int,start_mission_for_day(day_index:int,day_config:DayConfig)->void,reload_territory_map_from_active_campaign()->void,get_current_day_index()->int,get_day_config_for_index(day_index:int)->DayConfig,get_current_day_config()->DayConfig,get_current_day_territory_id()->String,get_territory_data(territory_id:String)->TerritoryData,get_current_day_territory()->TerritoryData,get_all_territories()->Array[TerritoryData],get_current_territory_gold_modifiers()->Dictionary,apply_day_result_to_territory(day_config:DayConfig,was_won:bool)->void` | `territory_map:TerritoryMapData` | `-` | `mission_started,build_mode_entered,game_state_changed,build_mode_exited,mission_won,mission_failed` | `SignalBus,Types,EconomyManager,ResearchManager,ShopManager,WaveManager,CampaignManager,Engine` |
| `res://autoloads/campaign_manager.gd` | `-` | `Node` | `start_new_campaign()->void,start_next_day()->void,get_current_day()->int,get_campaign_length()->int,get_current_day_config()->DayConfig,set_active_campaign_config_for_test(config:CampaignConfig)->void,validate_day_configs(day_configs:Array[DayConfig])->void` | `active_campaign_config:CampaignConfig,faction_registry:Dictionary` | `-` | `campaign_started,day_started,day_won,day_failed,campaign_completed` | `SignalBus,Types,GameManager,FactionData` |
| `res://ui/world_map.gd` | `WorldMap` | `Control` | `_build_territory_buttons()->void,_update_day_and_current_territory()->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager` |
| `res://autoloads/auto_test_driver.gd` | `-` | `Node` | `-` | `-` | `-` | `-` | `SignalBus,Types,GameManager,EconomyManager,Tower,HexGrid,WaveManager` |
| `res://scripts/spell_manager.gd` | `SpellManager` | `Node` | `cast_spell(spell_id:String)->bool,get_current_mana()->int,get_max_mana()->int,get_cooldown_remaining(spell_id:String)->float,is_spell_ready(spell_id:String)->bool,set_mana_to_full()->void,reset_to_defaults()->void` | `max_mana:int,mana_regen_rate:float,spell_registry:Array[SpellData]` | `-` | `mana_changed,spell_ready,spell_cast` | `SignalBus,Types,SpellData,EnemyBase,DamageCalculator` |
| `res://scripts/main_root.gd` | `-` | `Node3D` | `-` | `-` | `-` | `-` | `Window` |
| `res://scripts/sim_bot.gd` | `SimBot` | `Node` | `activate()->void,deactivate()->void,bot_enter_build_mode()->void,bot_exit_build_mode()->void,bot_place_building(slot:int,building_type:Types.BuildingType)->bool,bot_cast_spell(spell_id:String)->bool,bot_fire_crossbow(target:Vector3)->void,bot_advance_wave()->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager,HexGrid,SpellManager,Tower,WaveManager` |
| `res://scripts/input_manager.gd` | `InputManager` | `Node` | `-` | `-` | `-` | `-` | `Types,GameManager,Tower,SpellManager,HexGrid,BuildMenu,EnemyBase,Camera3D,PhysicsDirectSpaceState3D` |
| `res://scripts/research_manager.gd` | `ResearchManager` | `Node` | `unlock_node(node_id:String)->bool,is_unlocked(node_id:String)->bool,get_available_nodes()->Array[ResearchNodeData],reset_to_defaults()->void` | `research_nodes:Array[ResearchNodeData],dev_unlock_all_research:bool,dev_unlock_anti_air_only:bool` | `-` | `research_unlocked` | `SignalBus,EconomyManager,ResearchNodeData` |
| `res://scripts/shop_manager.gd` | `ShopManager` | `Node` | `purchase_item(item_id:String)->bool,get_available_items()->Array[ShopItemData],can_purchase(item_id:String)->bool,consume_mana_draught_pending()->bool,consume_arrow_tower_pending()->bool,apply_mission_start_consumables()->void` | `shop_catalog:Array[ShopItemData]` | `-` | `shop_item_purchased,mana_draught_consumed` | `SignalBus,EconomyManager,HexGrid,Tower,ShopItemData` |
| `res://scripts/wave_manager.gd` | `WaveManager` | `Node` | `start_wave_sequence()->void,force_spawn_wave(wave_number:int)->void,get_living_enemy_count()->int,get_current_wave_number()->int,is_wave_active()->bool,is_counting_down()->bool,get_countdown_remaining()->float,reset_for_new_mission()->void,clear_all_enemies()->void,configure_for_day(day_config:DayConfig)->void,set_faction_data_override(faction_data:FactionData)->void,resolve_current_faction()->void,get_mini_boss_info_for_wave(wave_index:int)->Dictionary` | `wave_countdown_duration:float,first_wave_countdown_seconds:float,max_waves:int,enemy_data_registry:Array[EnemyData],faction_registry:Dictionary` | `-` | `wave_countdown_started,wave_started,wave_cleared,all_waves_cleared` | `SignalBus,GameManager,EnemyData,EnemyBase,FactionData,FactionRosterEntry,PackedScene` |
| `res://scripts/health_component.gd` | `HealthComponent` | `Node` | `take_damage(amount:float)->void,heal(amount:int)->void,reset_to_max()->void,is_alive()->bool,get_current_hp()->int` | `max_hp:int` | `health_changed(current_hp:int,max_hp:int),health_depleted()` | `-` | `Node` |
| `res://scripts/types.gd` | `Types` | `-` | `-` | `-` | `-` | `-` | `-` |
| `res://scripts/resources/building_data.gd` | `BuildingData` | `Resource` | `-` | `building_type:Types.BuildingType,display_name:String,gold_cost:int,material_cost:int,upgrade_gold_cost:int,upgrade_material_cost:int,damage:float,upgraded_damage:float,fire_rate:float,attack_range:float,upgraded_range:float,damage_type:Types.DamageType,targets_air:bool,targets_ground:bool,is_locked:bool,unlock_research_id:String,research_damage_boost_id:String,research_range_boost_id:String,color:Color,target_priority:Types.TargetPriority,dot_enabled:bool,dot_total_damage:float,dot_tick_interval:float,dot_duration:float,dot_effect_type:String,dot_source_id:String,dot_in_addition_to_hit:bool` | `-` | `-` | `Types` |
| `res://scripts/resources/enemy_data.gd` | `EnemyData` | `Resource` | `-` | `enemy_type:Types.EnemyType,display_name:String,max_hp:int,move_speed:float,damage:int,attack_range:float,attack_cooldown:float,armor_type:Types.ArmorType,gold_reward:int,is_ranged:bool,is_flying:bool,color:Color,damage_immunities:Array[Types.DamageType]` | `-` | `-` | `Types` |
| `res://scripts/resources/research_node_data.gd` | `ResearchNodeData` | `Resource` | `-` | `node_id:String,display_name:String,research_cost:int,prerequisite_ids:Array[String],description:String` | `-` | `-` | `-` |
| `res://scripts/resources/shop_item_data.gd` | `ShopItemData` | `Resource` | `-` | `item_id:String,display_name:String,gold_cost:int,material_cost:int,description:String` | `-` | `-` | `-` |
| `res://scripts/resources/spell_data.gd` | `SpellData` | `Resource` | `-` | `spell_id:String,display_name:String,mana_cost:int,cooldown:float,damage:float,radius:float,damage_type:Types.DamageType,hits_flying:bool` | `-` | `-` | `Types` |
| `res://scripts/resources/weapon_data.gd` | `WeaponData` | `Resource` | `-` | `weapon_slot:Types.WeaponSlot,display_name:String,damage:float,projectile_speed:float,reload_time:float,burst_count:int,burst_interval:float,can_target_flying:bool,assist_angle_degrees:float,assist_max_distance:float,base_miss_chance:float,max_miss_angle_degrees:float` | `-` | `-` | `Types` |
| `res://scripts/resources/enchantment_data.gd` | `EnchantmentData` | `Resource` | `-` | `enchantment_id:String,display_name:String,description:String,slot_type:String,has_damage_type_override:bool,damage_type_override:Types.DamageType,has_secondary_damage_type:bool,secondary_damage_type:Types.DamageType,damage_multiplier:float,effect_tags:Array[String],effect_data:Dictionary` | `-` | `-` | `Types` |
| `res://scenes/arnulf/arnulf.gd` | `Arnulf` | `CharacterBody3D` | `get_current_state()->Types.ArnulfState,get_current_hp()->int,get_max_hp()->int,reset_for_new_mission()->void` | `max_hp:int,move_speed:float,attack_damage:float,attack_cooldown:float,patrol_radius:float,recovery_time:float` | `-` | `arnulf_recovered,arnulf_incapacitated,arnulf_state_changed` | `SignalBus,Types,EnemyBase,HealthComponent,NavigationAgent3D` |
| `res://scenes/buildings/building_base.gd` | `BuildingBase` | `Node3D` | `initialize(data:BuildingData)->void,upgrade()->void,get_building_data()->BuildingData,get_effective_damage()->float,get_effective_range()->float` | `-` | `-` | `-` | `Types,BuildingData,EnemyBase,ProjectileBase,ResearchManager,HealthComponent` |
| `res://scenes/enemies/enemy_base.gd` | `EnemyBase` | `CharacterBody3D` | `initialize(enemy_data:EnemyData)->void,take_damage(amount:float,damage_type:Types.DamageType)->void,get_enemy_data()->EnemyData,apply_dot_effect(effect_data:Dictionary)->void` | `-` | `-` | `enemy_killed` | `SignalBus,Types,EnemyData,HealthComponent,Tower,NavigationAgent3D,DamageCalculator` |
| `res://scenes/hex_grid/hex_grid.gd` | `HexGrid` | `Node3D` | `place_building(slot_index:int,building_type:Types.BuildingType)->bool,place_building_shop_free(building_type:Types.BuildingType)->bool,has_any_damaged_building()->bool,repair_first_damaged_building()->bool,sell_building(slot_index:int)->bool,upgrade_building(slot_index:int)->bool,get_slot_data(slot_index:int)->Dictionary,get_all_occupied_slots()->Array[int],get_empty_slots()->Array[int],has_empty_slot()->bool,clear_all_buildings()->void,get_building_data(building_type:Types.BuildingType)->BuildingData,is_building_available(building_type:Types.BuildingType)->bool,get_slot_position(slot_index:int)->Vector3,get_nearest_slot_index(world_pos:Vector3)->int,set_build_slot_highlight(slot_index:int)->void` | `building_data_registry:Array[BuildingData]` | `-` | `building_placed,building_sold,building_upgraded` | `SignalBus,Types,EconomyManager,ResearchManager,BuildingData,BuildingBase` |
| `res://scenes/projectiles/projectile_base.gd` | `ProjectileBase` | `Area3D` | `initialize_from_weapon(weapon_data:WeaponData,origin:Vector3,target_position:Vector3)->void,initialize_from_building(damage:float,damage_type:Types.DamageType,speed:float,origin:Vector3,target_position:Vector3,targets_air_only:bool,dot_enabled:bool,dot_total_damage:float,dot_tick_interval:float,dot_duration:float,dot_effect_type:String,dot_source_id:String,dot_in_addition_to_hit:bool)->void` | `-` | `-` | `-` | `Types,WeaponData,EnemyBase,DamageCalculator` |
| `res://scenes/tower/tower.gd` | `Tower` | `StaticBody3D` | `fire_crossbow(target_position:Vector3)->void,fire_rapid_missile(target_position:Vector3)->void,take_damage(amount:int)->void,repair_to_full()->void,get_current_hp()->int,get_max_hp()->int,is_weapon_ready(weapon_slot:Types.WeaponSlot)->bool,get_crossbow_reload_remaining_seconds()->float,get_crossbow_reload_total_seconds()->float,get_rapid_missile_reload_remaining_seconds()->float,get_rapid_missile_reload_total_seconds()->float,get_rapid_missile_burst_remaining()->int,get_rapid_missile_burst_total()->int` | `starting_hp:int,crossbow_data:WeaponData,rapid_missile_data:WeaponData,auto_fire_enabled:bool` | `-` | `projectile_fired,tower_damaged,tower_destroyed` | `SignalBus,Types,WeaponData,ProjectileBase,HealthComponent,EnemyBase` |
| `res://ui/between_mission_screen.gd` | `BetweenMissionScreen` | `Control` | `-` | `-` | `-` | `-` | `SignalBus,Types,GameManager,ShopManager,ResearchManager,HexGrid` |
| `res://ui/build_menu.gd` | `BuildMenu` | `Control` | `open_for_slot(slot_index:int)->void,open_for_sell_slot(slot_index:int,slot_data:Dictionary)->void` | `-` | `-` | `-` | `SignalBus,Types,HexGrid,EconomyManager,ResearchManager,BuildingBase,BuildingData` |
| `res://ui/end_screen.gd` | `EndScreen` | `Control` | `-` | `-` | `-` | `-` | `SignalBus,Types,GameManager` |
| `res://ui/hud.gd` | `HUD` | `Control` | `update_weapon_display(crossbow_ready:bool,missile_ready:bool)->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager,EconomyManager,Tower` |
| `res://ui/main_menu.gd` | `MainMenu` | `Control` | `-` | `-` | `-` | `-` | `GameManager` |
| `res://ui/mission_briefing.gd` | `-` | `Control` | `-` | `-` | `-` | `-` | `SignalBus,GameManager,Types` |
| `res://ui/ui_manager.gd` | `UIManager` | `Control` | `-` | `-` | `-` | `-` | `SignalBus,Types` |

## 3) Resource Class Matrix

| class | path | exported_fields(csv name:type) |
|---|---|---|
| `BuildingData` | `res://scripts/resources/building_data.gd` | `building_type:Types.BuildingType,display_name:String,gold_cost:int,material_cost:int,upgrade_gold_cost:int,upgrade_material_cost:int,damage:float,upgraded_damage:float,fire_rate:float,attack_range:float,upgraded_range:float,damage_type:Types.DamageType,targets_air:bool,targets_ground:bool,is_locked:bool,unlock_research_id:String,research_damage_boost_id:String,research_range_boost_id:String,color:Color,target_priority:Types.TargetPriority,dot_enabled:bool,dot_total_damage:float,dot_tick_interval:float,dot_duration:float,dot_effect_type:String,dot_source_id:String,dot_in_addition_to_hit:bool` |
| `EnemyData` | `res://scripts/resources/enemy_data.gd` | `enemy_type:Types.EnemyType,display_name:String,max_hp:int,move_speed:float,damage:int,attack_range:float,attack_cooldown:float,armor_type:Types.ArmorType,gold_reward:int,is_ranged:bool,is_flying:bool,color:Color,damage_immunities:Array[Types.DamageType]` |
| `ResearchNodeData` | `res://scripts/resources/research_node_data.gd` | `node_id:String,display_name:String,research_cost:int,prerequisite_ids:Array[String],description:String` |
| `ShopItemData` | `res://scripts/resources/shop_item_data.gd` | `item_id:String,display_name:String,gold_cost:int,material_cost:int,description:String` |
| `SpellData` | `res://scripts/resources/spell_data.gd` | `spell_id:String,display_name:String,mana_cost:int,cooldown:float,damage:float,radius:float,damage_type:Types.DamageType,hits_flying:bool` |
| `WeaponData` | `res://scripts/resources/weapon_data.gd` | `weapon_slot:Types.WeaponSlot,display_name:String,damage:float,projectile_speed:float,reload_time:float,burst_count:int,burst_interval:float,can_target_flying:bool,assist_angle_degrees:float,assist_max_distance:float,base_miss_chance:float,max_miss_angle_degrees:float` |
| `TerritoryData` | `res://scripts/resources/territory_data.gd` | `territory_id:String,display_name:String,description:String,default_faction_id:String,icon_id:String,color:Color,terrain_type:int,is_controlled_by_player:bool,is_permanently_lost:bool,threat_level:int,is_under_attack:bool,bonus_flat_gold_end_of_day:int,bonus_percent_gold_end_of_day:float,bonus_flat_gold_per_kill:int,bonus_research_per_day:int,bonus_research_cost_multiplier:float,bonus_enchanting_cost_multiplier:float,bonus_weapon_upgrade_cost_multiplier:float` |
| `TerritoryMapData` | `res://scripts/resources/territory_map_data.gd` | `territories:Array[TerritoryData]` |
| `FactionRosterEntry` | `res://scripts/resources/faction_roster_entry.gd` | `enemy_type:Types.EnemyType,base_weight:float,min_wave_index:int,max_wave_index:int,tier:int` |
| `FactionData` | `res://scripts/resources/faction_data.gd` | `faction_id:String,display_name:String,description:String,roster:Array[FactionRosterEntry],mini_boss_ids:Array[String],mini_boss_wave_hints:Array[int],roster_tier:int,difficulty_offset:float` |
| `DayConfig` | `res://scripts/resources/day_config.gd` | `day_index:int,mission_index:int,display_name:String,description:String,faction_id:String,territory_id:String,is_mini_boss_day:bool,is_final_boss:bool,base_wave_count:int,enemy_hp_multiplier:float,enemy_damage_multiplier:float,gold_reward_multiplier:float` |
| `CampaignConfig` | `res://scripts/resources/campaign_config.gd` | `campaign_id:String,display_name:String,day_configs:Array[DayConfig],territory_map_resource_path:String,is_short_campaign:bool,short_campaign_length:int` |

## 4) Scene Matrix

| scene_path | root_node_name | root_node_type | script_path |
|---|---|---|---|
| `res://scenes/main.tscn` | `Main` | `Node3D` | `res://scripts/main_root.gd` |
| `res://scenes/arnulf/arnulf.tscn` | `Arnulf` | `CharacterBody3D` | `res://scenes/arnulf/arnulf.gd` |
| `res://scenes/buildings/building_base.tscn` | `BuildingBase` | `Node3D` | `res://scenes/buildings/building_base.gd` |
| `res://scenes/enemies/enemy_base.tscn` | `EnemyBase` | `CharacterBody3D` | `res://scenes/enemies/enemy_base.gd` |
| `res://scenes/hex_grid/hex_grid.tscn` | `HexGrid` | `Node3D` | `res://scenes/hex_grid/hex_grid.gd` |
| `res://scenes/projectiles/projectile_base.tscn` | `ProjectileBase` | `Area3D` | `res://scenes/projectiles/projectile_base.gd` |
| `res://scenes/tower/tower.tscn` | `Tower` | `StaticBody3D` | `res://scenes/tower/tower.gd` |
| `res://ui/between_mission_screen.tscn` | `BetweenMissionScreen` | `Control` | `res://ui/between_mission_screen.gd` |
| `res://ui/world_map.tscn` | `WorldMap` | `Control` | `res://ui/world_map.gd` |
| `res://ui/build_menu.tscn` | `BuildMenu` | `Control` | `res://ui/build_menu.gd` |
| `res://ui/hud.tscn` | `HUD` | `Control` | `res://ui/hud.gd` |
| `res://ui/main_menu.tscn` | `MainMenu` | `Control` | `res://ui/main_menu.gd` |
| `res://ui/mission_briefing.tscn` | `MissionBriefing` | `Control` | `res://ui/mission_briefing.gd` |

## 5) SignalBus Matrix

| signal_name | payload_signature | emitted_by_files(csv) |
|---|---|---|
| `enemy_killed` | `(enemy_type:Types.EnemyType,position:Vector3,gold_reward:int)` | `res://scenes/enemies/enemy_base.gd` |
| `enemy_reached_tower` | `(enemy_type:Types.EnemyType,damage:int)` | `-` |
| `tower_damaged` | `(current_hp:int,max_hp:int)` | `res://scenes/tower/tower.gd` |
| `tower_destroyed` | `()` | `res://scenes/tower/tower.gd` |
| `projectile_fired` | `(weapon_slot:Types.WeaponSlot,origin:Vector3,target:Vector3)` | `res://scenes/tower/tower.gd` |
| `arnulf_state_changed` | `(new_state:Types.ArnulfState)` | `res://scenes/arnulf/arnulf.gd` |

## 2026-03-24 delta

- Build-mode slot routing is centralized in `InputManager` (raycast against layer 7 + occupancy check).
- `BuildMenu` now has placement and sell entrypoints.
- `HexGrid` slot input callback now only updates highlight when in build mode.
- Added sell-flow tests to `res://tests/test_hex_grid.gd`.
- Added Phase 2 firing behavior notes in `docs/PROMPT_2_IMPLEMENTATION.md`.
- `Tower` manual shots now resolve final targets through private assist/miss helper; autofire path bypasses helper effects.
- Added simulation API tests for assist/miss behavior and crossbow default tuning load checks.
- Added deterministic weapon upgrades:
  - new script `res://scripts/weapon_upgrade_manager.gd`
  - new resource class `res://scripts/resources/weapon_level_data.gd`
  - new resource instances `res://resources/weapon_level_data/*.tres`
  - new signal `weapon_upgraded(weapon_slot:Types.WeaponSlot,new_level:int)`
  - `res://scenes/main.tscn` now includes `Managers/WeaponUpgradeManager`
  - `res://ui/between_mission_screen.tscn` now includes `TabContainer/WeaponsTab`
  - tests added in `res://tests/test_weapon_upgrade_manager.gd`
  - tower fallback regression added in `res://tests/test_simulation_api.gd`
- Added Phase 4 enchantments:
  - new autoload `EnchantmentManager`
  - new resource class `EnchantmentData`
  - new SignalBus signals `enchantment_applied`, `enchantment_removed`
  - new tests `res://tests/test_enchantment_manager.gd`, `res://tests/test_tower_enchantments.gd`
  - `ProjectileBase.initialize_from_weapon(...)` now accepts optional custom damage and damage type
  - `Tower` now composes enchantment stats from `"elemental"` and `"power"` slots
 - Added Phase 5 DoT system:
  - Added `DamageCalculator.calculate_dot_tick(...)`.
  - Added `EnemyBase.apply_dot_effect(effect_data: Dictionary)`.
  - Extended `BuildingData` with DoT export fields.
  - Extended `ProjectileBase.initialize_from_building(...)` with DoT parameters.
  - Added `res://tests/test_enemy_dot_system.gd` and DoT assertions in projectile tests.
- Added Phase 6 solid-building navigation:
  - `res://scenes/buildings/building_base.tscn` now declares `BuildingCollision` + `NavigationObstacle`.
  - `res://scenes/buildings/building_base.gd` now configures collision footprint and avoidance radius via constants.
  - `res://scenes/enemies/enemy_base.gd` now has ground/flying split movement + stuck-prevention helpers.
  - `res://tests/test_enemy_pathfinding.gd` replaced with gameplay-level navigation scenarios.
  - `res://tests/test_building_base.gd` includes node-configuration assertions for Prompt 6.
 - Added Prompt 7 campaign/day layer:
  - New autoload: `CampaignManager` (`res://autoloads/campaign_manager.gd`).
  - New resource classes: `DayConfig`, `CampaignConfig`.
  - New resources under `res://resources/campaigns/` (short 5-day + main 50-day).
  - `SignalBus` includes campaign/day signals:
    - `campaign_started`, `day_started`, `day_won`, `day_failed`, `campaign_completed`.
  - `GameManager` adds `start_mission_for_day(day_index:int, day_config:DayConfig)` and delegates day progression.
  - `WaveManager` adds `configure_for_day(day_config:DayConfig)` and per-day tuning fields.
  - Added tests:
    - `res://tests/test_campaign_manager.gd`
    - Prompt 7 additions in `test_wave_manager.gd`, `test_game_manager.gd`.
| `arnulf_incapacitated` | `()` | `res://scenes/arnulf/arnulf.gd` |
| `arnulf_recovered` | `()` | `res://scenes/arnulf/arnulf.gd` |
| `wave_countdown_started` | `(wave_number:int,seconds_remaining:float)` | `res://scripts/wave_manager.gd` |
| `wave_started` | `(wave_number:int,enemy_count:int)` | `res://scripts/wave_manager.gd` |
| `wave_cleared` | `(wave_number:int)` | `res://scripts/wave_manager.gd` |
| `all_waves_cleared` | `()` | `res://scripts/wave_manager.gd` |
| `resource_changed` | `(resource_type:Types.ResourceType,new_amount:int)` | `res://autoloads/economy_manager.gd` |
| `building_placed` | `(slot_index:int,building_type:Types.BuildingType)` | `res://scenes/hex_grid/hex_grid.gd` |
| `building_sold` | `(slot_index:int,building_type:Types.BuildingType)` | `res://scenes/hex_grid/hex_grid.gd` |
| `building_upgraded` | `(slot_index:int,building_type:Types.BuildingType)` | `res://scenes/hex_grid/hex_grid.gd` |
| `building_destroyed` | `(slot_index:int)` | `-` |
| `spell_cast` | `(spell_id:String)` | `res://scripts/spell_manager.gd` |
| `spell_ready` | `(spell_id:String)` | `res://scripts/spell_manager.gd` |
| `mana_changed` | `(current_mana:int,max_mana:int)` | `res://scripts/spell_manager.gd` |
| `game_state_changed` | `(old_state:Types.GameState,new_state:Types.GameState)` | `res://autoloads/game_manager.gd` |
| `mission_started` | `(mission_number:int)` | `res://autoloads/game_manager.gd` |
| `mission_won` | `(mission_number:int)` | `res://autoloads/game_manager.gd` |
| `mission_failed` | `(mission_number:int)` | `res://autoloads/game_manager.gd` |
| `build_mode_entered` | `()` | `res://autoloads/game_manager.gd` |
| `build_mode_exited` | `()` | `res://autoloads/game_manager.gd` |
| `research_unlocked` | `(node_id:String)` | `res://scripts/research_manager.gd` |
| `shop_item_purchased` | `(item_id:String)` | `res://scripts/shop_manager.gd` |
| `mana_draught_consumed` | `()` | `res://scripts/shop_manager.gd` |
