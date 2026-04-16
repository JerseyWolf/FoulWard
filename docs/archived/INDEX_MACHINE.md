# Foul Ward Code Index (Machine-Friendly)

> **Stale snapshot — partial refresh 2026-04-14.** Prefer `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`, and source files. **DamageCalculator** is `res://autoloads/DamageCalculator.cs` (C#). **`dialogue_line_started` / `dialogue_line_finished`** are declared on **SignalBus**; `DialogueManager` has no local `signal` keywords and emits via `SignalBus`. Hub UI uses **`DialoguePanel`** (`res://ui/dialogue_panel.gd`); `dialogueui.gd` was removed. **`scripts/simbot_logger.gd`** was removed (CSV helpers inlined in SimBot). The long `signal_bus.gd` row below is not exhaustive — use `autoloads/signal_bus.gd` as source of truth.

## 1) Autoload Matrix

| name | path | script_class | emits_signals(csv) |
|---|---|---|---|
| SignalBus | `res://autoloads/signal_bus.gd` | `-` | `-` |
| DamageCalculator | `res://autoloads/DamageCalculator.cs` | `DamageCalculator` | `-` |
| EconomyManager | `res://autoloads/economy_manager.gd` | `-` | `resource_changed` |
| CampaignManager | `res://autoloads/campaign_manager.gd` | `-` | `campaign_started,day_started,day_won,day_failed,campaign_completed` |
| GameManager | `res://autoloads/game_manager.gd` | `-` | `mission_started,build_mode_entered,game_state_changed,build_mode_exited,mission_won,mission_failed` |
| DialogueManager | `res://autoloads/dialogue_manager.gd` | `-` | `-` (dialogue_line_* emitted via SignalBus only) |
| AutoTestDriver | `res://autoloads/auto_test_driver.gd` | `-` | `-` |
| GDAIMCPRuntime | (uid autoload; see `project.godot`) | `-` | `-` |
| EnchantmentManager | `res://autoloads/enchantment_manager.gd` | `-` | `enchantment_applied,enchantment_removed` |
| MCPScreenshot | `res://addons/godot_mcp/mcp_screenshot_service.gd` | `-` | `-` |
| MCPInputService | `res://addons/godot_mcp/mcp_input_service.gd` | `-` | `-` |
| MCPGameInspector | `res://addons/godot_mcp/mcp_game_inspector_service.gd` | `-` | `-` |

## 2) Script Matrix (first-party only)

| path | class_name | extends | public_methods(csv signatures) | exports(csv name:type) | declared_local_signals(csv) | emits_signalbus(csv) | key_dependencies(csv) |
|---|---|---|---|---|---|---|---|
| `res://autoloads/signal_bus.gd` | `-` | `Node` | `-` | `-` | `enemy_killed(enemy_type:Types.EnemyType,position:Vector3,gold_reward:int),enemy_reached_tower(enemy_type:Types.EnemyType,damage:int),tower_damaged(current_hp:int,max_hp:int),tower_destroyed(),projectile_fired(weapon_slot:Types.WeaponSlot,origin:Vector3,target:Vector3),arnulf_state_changed(new_state:Types.ArnulfState),arnulf_incapacitated(),arnulf_recovered(),ally_spawned(ally_id:String),ally_downed(ally_id:String),ally_recovered(ally_id:String),ally_killed(ally_id:String),ally_state_changed(ally_id:String,new_state:String),ally_roster_changed(),boss_spawned(boss_id:String),boss_killed(boss_id:String),campaign_boss_attempted(day_index:int,success:bool),wave_countdown_started(wave_number:int,seconds_remaining:float),wave_started(wave_number:int,enemy_count:int),wave_cleared(wave_number:int),all_waves_cleared(),resource_changed(resource_type:Types.ResourceType,new_amount:int),territory_state_changed(territory_id:String),world_map_updated(),building_placed(slot_index:int,building_type:Types.BuildingType),building_sold(slot_index:int,building_type:Types.BuildingType),building_upgraded(slot_index:int,building_type:Types.BuildingType),building_destroyed(slot_index:int),spell_cast(spell_id:String),spell_ready(spell_id:String),mana_changed(current_mana:int,max_mana:int),game_state_changed(old_state:Types.GameState,new_state:Types.GameState),mission_started(mission_number:int),mission_won(mission_number:int),mission_failed(mission_number:int),build_mode_entered(),build_mode_exited(),campaign_started(campaign_id:String),day_started(day_index:int),day_won(day_index:int),day_failed(day_index:int),campaign_completed(campaign_id:String),research_unlocked(node_id:String),shop_item_purchased(item_id:String),mana_draught_consumed(),mercenary_offer_generated(ally_id:String),mercenary_recruited(ally_id:String),weapon_upgraded(weapon_slot:Types.WeaponSlot,new_level:int),enchantment_applied(weapon_slot:Types.WeaponSlot,slot_type:String,enchantment_id:String),enchantment_removed(weapon_slot:Types.WeaponSlot,slot_type:String)` | `-` | `Types` |
| `res://autoloads/DamageCalculator.cs` | `DamageCalculator` | `Node` | `calculate_damage(base_damage:float,damage_type:int,armor_type:int)->float,calculate_dot_tick(dot_total_damage:float,tick_interval:float,duration:float,damage_type:int,armor_type:int)->float` | `-` | `-` | `-` | `-` |
| `res://autoloads/economy_manager.gd` | `-` | `Node` | `add_gold(amount:int)->void,spend_gold(amount:int)->bool,add_building_material(amount:int)->void,spend_building_material(amount:int)->bool,add_research_material(amount:int)->void,spend_research_material(amount:int)->bool,can_afford(gold_cost:int,material_cost:int)->bool,get_gold()->int,get_building_material()->int,get_research_material()->int,reset_to_defaults()->void` | `-` | `-` | `resource_changed` | `SignalBus,Types,OS` |
| `res://autoloads/game_manager.gd` | `-` | `Node` | `start_new_game()->void,start_next_mission()->void,start_wave_countdown()->void,enter_build_mode()->void,exit_build_mode()->void,get_game_state()->Types.GameState,get_current_mission()->int,get_current_wave()->int,start_mission_for_day(day_index:int,day_config:DayConfig)->void,reload_territory_map_from_active_campaign()->void,get_current_day_index()->int,get_day_config_for_index(day_index:int)->DayConfig,get_current_day_config()->DayConfig,get_current_day_territory_id()->String,get_territory_data(territory_id:String)->TerritoryData,get_current_day_territory()->TerritoryData,get_all_territories()->Array[TerritoryData],get_current_territory_gold_modifiers()->Dictionary,apply_day_result_to_territory(day_config:DayConfig,was_won:bool)->void,prepare_next_campaign_day_if_needed()->void,advance_to_next_day()->void,get_synthetic_boss_day_config()->DayConfig,reset_boss_campaign_state_for_test()->void` | `territory_map:TerritoryMapData` | `-` | `mission_started,build_mode_entered,game_state_changed,build_mode_exited,mission_won,mission_failed,territory_state_changed,world_map_updated,campaign_boss_attempted` | `SignalBus,Types,EconomyManager,ResearchManager,ShopManager,WaveManager,CampaignManager,Engine,BossData` |
| `res://autoloads/dialogue_manager.gd` | `-` | `Node` | `request_entry_for_character(character_id:String,tags:Array[String]=[])->DialogueEntry,get_entry_by_id(entry_id:String)->DialogueEntry,mark_entry_played(entry_id:String)->void,notify_dialogue_finished(entry_id:String,character_id:String)->void,on_campaign_day_started()->void` | `-` | `-` | `dialogue_line_started,dialogue_line_finished` | `SignalBus,Types,GameManager,EconomyManager,ResearchNodeData` |
| `res://autoloads/campaign_manager.gd` | `-` | `Node` | `start_new_campaign()->void,start_next_day()->void,get_current_day()->int,get_campaign_length()->int,get_current_day_config()->DayConfig,set_active_campaign_config_for_test(config:CampaignConfig)->void,validate_day_configs(day_configs:Array[DayConfig])->void,is_ally_owned(ally_id:String)->bool,get_owned_allies()->Array[String],get_active_allies()->Array[String],get_ally_data(ally_id:String)->Resource,add_ally_to_roster(ally_id:String)->void,remove_ally_from_roster(ally_id:String)->void,toggle_ally_active(ally_id:String)->bool,set_active_allies_from_list(ally_ids:Array[String])->void,get_allies_for_mission_start()->Array[String],generate_offers_for_day(day:int)->void,preview_mercenary_offers_for_day(day:int,hypothetical_owned:Array[String])->Array,get_current_offers()->Array,purchase_mercenary_offer(index:int)->bool,notify_mini_boss_defeated(boss_id:String)->void,register_mini_boss(boss_data:Resource)->void,auto_select_best_allies(strategy_profile:Types.StrategyProfile,available_offers:Array,current_roster:Array[String],max_purchases:int,budget_gold:int,budget_material:int,budget_research:int)->Dictionary,has_ally(ally_id:String)->bool,reinitialize_ally_roster_for_test()->void` | `mercenary_catalog:Resource,active_campaign_config:CampaignConfig` | `-` | `campaign_started,day_started,day_won,day_failed,campaign_completed,mercenary_offer_generated,mercenary_recruited,ally_roster_changed` | `SignalBus,Types,GameManager,FactionData,EconomyManager` |
| `res://ui/world_map.gd` | `WorldMap` | `Control` | `_build_territory_buttons()->void,_update_day_and_current_territory()->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager` |
| `res://autoloads/auto_test_driver.gd` | `-` | `Node` | `-` | `-` | `-` | `-` | `SignalBus,Types,GameManager,EconomyManager,Tower,HexGrid,WaveManager` |
| `res://scripts/spell_manager.gd` | `SpellManager` | `Node` | `cast_spell(spell_id:String)->bool,get_current_mana()->int,get_max_mana()->int,get_cooldown_remaining(spell_id:String)->float,is_spell_ready(spell_id:String)->bool,set_mana_to_full()->void,reset_to_defaults()->void` | `max_mana:int,mana_regen_rate:float,spell_registry:Array[SpellData]` | `-` | `mana_changed,spell_ready,spell_cast` | `SignalBus,Types,SpellData,EnemyBase,DamageCalculator` |
| `res://scripts/main_root.gd` | `-` | `Node3D` | `-` | `-` | `-` | `-` | `Window` |
| `res://scripts/sim_bot.gd` | `SimBot` | `Node` | `activate(strategy:Types.StrategyProfile)->void,deactivate()->void,decide_mercenaries()->void,get_log()->Array[String],bot_enter_build_mode()->void,bot_exit_build_mode()->void,bot_place_building(slot:int,building_type:Types.BuildingType)->bool,bot_cast_spell(spell_id:String)->bool,bot_fire_crossbow(target:Vector3)->void,bot_advance_wave()->void,run_single(profile_id:String,run_index:int,seed_value:int)->Dictionary,run_batch(profile_id:String,runs:int,base_seed:int=0,csv_path:String="")->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager,WaveManager,HexGrid,SpellManager,EconomyManager,ResearchManager,Tower,CampaignManager,StrategyProfile` |
| `res://scripts/input_manager.gd` | `InputManager` | `Node` | `-` | `-` | `-` | `-` | `Types,GameManager,Tower,SpellManager,HexGrid,BuildMenu,EnemyBase,Camera3D,PhysicsDirectSpaceState3D` |
| `res://scripts/research_manager.gd` | `ResearchManager` | `Node` | `unlock_node(node_id:String)->bool,is_unlocked(node_id:String)->bool,get_available_nodes()->Array[ResearchNodeData],reset_to_defaults()->void` | `research_nodes:Array[ResearchNodeData],dev_unlock_all_research:bool,dev_unlock_anti_air_only:bool` | `-` | `research_unlocked` | `SignalBus,EconomyManager,ResearchNodeData` |
| `res://scripts/shop_manager.gd` | `ShopManager` | `Node` | `purchase_item(item_id:String)->bool,get_available_items()->Array[ShopItemData],can_purchase(item_id:String)->bool,consume_mana_draught_pending()->bool,consume_arrow_tower_pending()->bool,apply_mission_start_consumables()->void` | `shop_catalog:Array[ShopItemData]` | `-` | `shop_item_purchased,mana_draught_consumed` | `SignalBus,EconomyManager,HexGrid,Tower,ShopItemData` |
| `res://scripts/wave_manager.gd` | `WaveManager` | `Node` | `start_wave_sequence()->void,force_spawn_wave(wave_number:int)->void,get_living_enemy_count()->int,get_current_wave_number()->int,is_wave_active()->bool,is_counting_down()->bool,get_countdown_remaining()->float,reset_for_new_mission()->void,clear_all_enemies()->void,configure_for_day(day_config:DayConfig)->void,set_day_context(day_config:DayConfig,faction_data:FactionData)->void,ensure_boss_registry_loaded()->void,set_faction_data_override(faction_data:FactionData)->void,resolve_current_faction()->void,get_mini_boss_info_for_wave(wave_index:int)->Dictionary` | `wave_countdown_duration:float,first_wave_countdown_seconds:float,max_waves:int,enemy_data_registry:Array[EnemyData],faction_registry:Dictionary` | `-` | `wave_countdown_started,wave_started,wave_cleared,all_waves_cleared` | `SignalBus,GameManager,EnemyData,EnemyBase,FactionData,FactionRosterEntry,BossData,PackedScene` |
| `res://scripts/health_component.gd` | `HealthComponent` | `Node` | `take_damage(amount:float)->void,heal(amount:int)->void,reset_to_max()->void,is_alive()->bool,get_current_hp()->int` | `max_hp:int` | `health_changed(current_hp:int,max_hp:int),health_depleted()` | `-` | `Node` |
| `res://scripts/types.gd` | `Types` | `-` | `-` | `-` | `-` | `-` | `-` |
| `res://scripts/art/art_placeholder_helper.gd` | `ArtPlaceholderHelper` | `RefCounted` | `get_enemy_mesh(enemy_type:Types.EnemyType)->Mesh,get_building_mesh(building_type:Types.BuildingType)->Mesh,get_ally_mesh(ally_id:StringName)->Mesh,get_tower_mesh()->Mesh,get_unknown_mesh()->Mesh,get_faction_material(faction_id:StringName)->Material,get_enemy_material(enemy_type:Types.EnemyType)->Material,get_building_material(building_type:Types.BuildingType)->Material,get_enemy_icon(enemy_type:Types.EnemyType)->Texture2D,get_building_icon(building_type:Types.BuildingType)->Texture2D,get_ally_icon(ally_id:StringName)->Texture2D,clear_cache()->void` | `-` | `-` | `-` | `Types,ResourceLoader` |
| `res://scripts/resources/building_data.gd` | `BuildingData` | `Resource` | `-` | `building_type:Types.BuildingType,display_name:String,gold_cost:int,material_cost:int,upgrade_gold_cost:int,upgrade_material_cost:int,damage:float,upgraded_damage:float,fire_rate:float,attack_range:float,upgraded_range:float,damage_type:Types.DamageType,targets_air:bool,targets_ground:bool,is_locked:bool,unlock_research_id:String,research_damage_boost_id:String,research_range_boost_id:String,color:Color,target_priority:Types.TargetPriority,dot_enabled:bool,dot_total_damage:float,dot_tick_interval:float,dot_duration:float,dot_effect_type:String,dot_source_id:String,dot_in_addition_to_hit:bool` | `-` | `-` | `Types` |
| `res://scripts/resources/enemy_data.gd` | `EnemyData` | `Resource` | `-` | `enemy_type:Types.EnemyType,display_name:String,max_hp:int,move_speed:float,damage:int,attack_range:float,attack_cooldown:float,armor_type:Types.ArmorType,gold_reward:int,is_ranged:bool,is_flying:bool,color:Color,damage_immunities:Array[Types.DamageType]` | `-` | `-` | `Types` |
| `res://scripts/resources/ally_data.gd` | `AllyData` | `Resource` | `-` | `ally_id:String,display_name:String,description:String,ally_class:Types.AllyClass,role:Types.AllyRole,damage_type:Types.DamageType,can_target_flying:bool,max_hp:int,move_speed:float,basic_attack_damage:float,attack_damage:float,attack_range:float,attack_cooldown:float,patrol_radius:float,recovery_time:float,preferred_targeting:Types.TargetPriority,is_unique:bool,scene_path:String,is_starter_ally:bool,is_defected_ally:bool,debug_color:Color,starting_level:int,level_scaling_factor:float,uses_downed_recovering:bool` | `-` | `-` | `Types` |
| `res://scripts/resources/mercenary_offer_data.gd` | `MercenaryOfferData` | `Resource` | `is_available_on_day(day:int)->bool,get_cost_summary()->String` | `ally_id:String,cost_gold:int,cost_building_material:int,cost_research_material:int,min_day:int,max_day:int,is_defection_offer:bool` | `-` | `-` | `Types` |
| `res://scripts/resources/mercenary_catalog.gd` | `MercenaryCatalog` | `Resource` | `filter_offers_for_day(day:int,owned_ally_ids:Array[String])->Array,get_daily_offers(day:int,owned_ally_ids:Array[String])->Array` | `offers:Array,max_offers_per_day:int` | `-` | `-` | `-` |
| `res://scripts/resources/mini_boss_data.gd` | `MiniBossData` | `Resource` | `-` | `boss_id:String,display_name:String,appears_on_day:int,can_defect_to_ally:bool,defected_ally_id:String,defection_cost_gold:int` | `-` | `-` | `-` |
| `res://scripts/resources/boss_data.gd` | `BossData` | `Resource` | `build_placeholder_enemy_data()->EnemyData` | `boss_id:String,display_name:String,description:String,faction_id:String,associated_territory_id:String,threat_icon_id:String,max_hp:int,move_speed:float,damage:int,attack_range:float,attack_cooldown:float,armor_type:Types.ArmorType,gold_reward:int,is_ranged:bool,is_flying:bool,damage_immunities:Array[Types.DamageType],phase_count:int,escort_unit_ids:Array[String],is_mini_boss:bool,is_final_boss:bool,boss_scene:PackedScene` | `-` | `-` | `Types,EnemyData` |
| `res://scripts/resources/research_node_data.gd` | `ResearchNodeData` | `Resource` | `-` | `node_id:String,display_name:String,research_cost:int,prerequisite_ids:Array[String],description:String` | `-` | `-` | `-` |
| `res://scripts/resources/shop_item_data.gd` | `ShopItemData` | `Resource` | `-` | `item_id:String,display_name:String,gold_cost:int,material_cost:int,description:String` | `-` | `-` | `-` |
| `res://scripts/resources/spell_data.gd` | `SpellData` | `Resource` | `-` | `spell_id:String,display_name:String,mana_cost:int,cooldown:float,damage:float,radius:float,damage_type:Types.DamageType,hits_flying:bool` | `-` | `-` | `Types` |
| `res://scripts/resources/weapon_data.gd` | `WeaponData` | `Resource` | `-` | `weapon_slot:Types.WeaponSlot,display_name:String,damage:float,projectile_speed:float,reload_time:float,burst_count:int,burst_interval:float,can_target_flying:bool,assist_angle_degrees:float,assist_max_distance:float,base_miss_chance:float,max_miss_angle_degrees:float` | `-` | `-` | `Types` |
| `res://scripts/resources/enchantment_data.gd` | `EnchantmentData` | `Resource` | `-` | `enchantment_id:String,display_name:String,description:String,slot_type:String,has_damage_type_override:bool,damage_type_override:Types.DamageType,has_secondary_damage_type:bool,secondary_damage_type:Types.DamageType,damage_multiplier:float,effect_tags:Array[String],effect_data:Dictionary` | `-` | `-` | `Types` |
| `res://scenes/arnulf/arnulf.gd` | `Arnulf` | `CharacterBody3D` | `get_current_state()->Types.ArnulfState,get_current_hp()->int,get_max_hp()->int,reset_for_new_mission()->void` | `max_hp:int,move_speed:float,attack_damage:float,attack_cooldown:float,patrol_radius:float,recovery_time:float` | `-` | `arnulf_recovered,arnulf_incapacitated,arnulf_state_changed,ally_spawned,ally_downed,ally_recovered` | `SignalBus,Types,EnemyBase,HealthComponent,NavigationAgent3D` |
| `res://scenes/allies/ally_base.gd` | `AllyBase` | `CharacterBody3D` | `initialize(p_ally_data:AllyData)->void,initialize_ally_data(p_ally_data:Variant)->void,find_target()->EnemyBase,get_current_state()->AllyState,get_current_hp()->int` | `-` | `-` | `ally_spawned,ally_downed,ally_recovered,ally_killed` | `SignalBus,Types,EnemyBase,HealthComponent,NavigationAgent3D,DamageCalculator` |
| `res://scenes/buildings/building_base.gd` | `BuildingBase` | `Node3D` | `initialize(data:BuildingData)->void,upgrade()->void,get_building_data()->BuildingData,get_effective_damage()->float,get_effective_range()->float` | `-` | `-` | `-` | `Types,BuildingData,EnemyBase,ProjectileBase,ResearchManager,HealthComponent` |
| `res://scenes/enemies/enemy_base.gd` | `EnemyBase` | `CharacterBody3D` | `initialize(enemy_data:EnemyData)->void,take_damage(amount:float,damage_type:Types.DamageType)->void,get_enemy_data()->EnemyData,apply_dot_effect(effect_data:Dictionary)->void` | `-` | `-` | `enemy_killed` | `SignalBus,Types,EnemyData,HealthComponent,Tower,NavigationAgent3D,DamageCalculator` |
| `res://scenes/bosses/boss_base.gd` | `BossBase` | `CharacterBody3D` | `initialize_boss_data(data:BossData)->void,advance_phase()->void` | `-` | `-` | `boss_spawned,boss_killed` | `SignalBus,Types,EnemyBase,BossData,HealthComponent,NavigationAgent3D` |
| `res://scenes/hex_grid/hex_grid.gd` | `HexGrid` | `Node3D` | `place_building(slot_index:int,building_type:Types.BuildingType)->bool,place_building_shop_free(building_type:Types.BuildingType)->bool,has_any_damaged_building()->bool,repair_first_damaged_building()->bool,sell_building(slot_index:int)->bool,upgrade_building(slot_index:int)->bool,get_slot_data(slot_index:int)->Dictionary,get_all_occupied_slots()->Array[int],get_empty_slots()->Array[int],has_empty_slot()->bool,clear_all_buildings()->void,get_building_data(building_type:Types.BuildingType)->BuildingData,is_building_available(building_type:Types.BuildingType)->bool,get_slot_position(slot_index:int)->Vector3,get_nearest_slot_index(world_pos:Vector3)->int,set_build_slot_highlight(slot_index:int)->void` | `building_data_registry:Array[BuildingData]` | `-` | `building_placed,building_sold,building_upgraded` | `SignalBus,Types,EconomyManager,ResearchManager,BuildingData,BuildingBase` |
| `res://scenes/projectiles/projectile_base.gd` | `ProjectileBase` | `Area3D` | `initialize_from_weapon(weapon_data:WeaponData,origin:Vector3,target_position:Vector3)->void,initialize_from_building(damage:float,damage_type:Types.DamageType,speed:float,origin:Vector3,target_position:Vector3,targets_air_only:bool,dot_enabled:bool,dot_total_damage:float,dot_tick_interval:float,dot_duration:float,dot_effect_type:String,dot_source_id:String,dot_in_addition_to_hit:bool)->void` | `-` | `-` | `-` | `Types,WeaponData,EnemyBase,DamageCalculator` |
| `res://scenes/tower/tower.gd` | `Tower` | `StaticBody3D` | `fire_crossbow(target_position:Vector3)->void,fire_rapid_missile(target_position:Vector3)->void,take_damage(amount:int)->void,repair_to_full()->void,get_current_hp()->int,get_max_hp()->int,is_weapon_ready(weapon_slot:Types.WeaponSlot)->bool,get_crossbow_reload_remaining_seconds()->float,get_crossbow_reload_total_seconds()->float,get_rapid_missile_reload_remaining_seconds()->float,get_rapid_missile_reload_total_seconds()->float,get_rapid_missile_burst_remaining()->int,get_rapid_missile_burst_total()->int` | `starting_hp:int,crossbow_data:WeaponData,rapid_missile_data:WeaponData,auto_fire_enabled:bool` | `-` | `projectile_fired,tower_damaged,tower_destroyed` | `SignalBus,Types,WeaponData,ProjectileBase,HealthComponent,EnemyBase` |
| `res://ui/between_mission_screen.gd` | `BetweenMissionScreen` | `Control` | `_show_hub_dialogue()->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager,ShopManager,ResearchManager,HexGrid,UIManager` |
| `res://ui/build_menu.gd` | `BuildMenu` | `Control` | `open_for_slot(slot_index:int)->void,open_for_sell_slot(slot_index:int,slot_data:Dictionary)->void` | `-` | `-` | `-` | `SignalBus,Types,HexGrid,EconomyManager,ResearchManager,BuildingBase,BuildingData` |
| `res://ui/end_screen.gd` | `EndScreen` | `Control` | `-` | `-` | `-` | `-` | `SignalBus,Types,GameManager` |
| `res://ui/hud.gd` | `HUD` | `Control` | `update_weapon_display(crossbow_ready:bool,missile_ready:bool)->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager,EconomyManager,Tower` |
| `res://ui/main_menu.gd` | `MainMenu` | `Control` | `-` | `-` | `-` | `-` | `GameManager` |
| `res://ui/mission_briefing.gd` | `-` | `Control` | `-` | `-` | `-` | `-` | `SignalBus,GameManager,Types` |
| `res://ui/ui_manager.gd` | `UIManager` | `Control` | `show_dialogue_for_character(character_id:String)->void,show_dialogue(display_name:String,entry:DialogueEntry)->void,clear_dialogue()->void` | `-` | `-` | `-` | `SignalBus,Types,GameManager,DialogueManager,DialoguePanel` |
| `res://ui/dialogue_panel.gd` | `DialoguePanel` | `Control` | `show_entry(display_name:String,entry:DialogueEntry)->void,clear_dialogue()->void` | `-` | `-` | `-` | `DialogueManager` |

## 3) Resource Class Matrix

| class | path | exported_fields(csv name:type) |
|---|---|---|
| `BuildingData` | `res://scripts/resources/building_data.gd` | `building_type:Types.BuildingType,display_name:String,gold_cost:int,material_cost:int,upgrade_gold_cost:int,upgrade_material_cost:int,damage:float,upgraded_damage:float,fire_rate:float,attack_range:float,upgraded_range:float,damage_type:Types.DamageType,targets_air:bool,targets_ground:bool,is_locked:bool,unlock_research_id:String,research_damage_boost_id:String,research_range_boost_id:String,color:Color,target_priority:Types.TargetPriority,dot_enabled:bool,dot_total_damage:float,dot_tick_interval:float,dot_duration:float,dot_effect_type:String,dot_source_id:String,dot_in_addition_to_hit:bool` |
| `EnemyData` | `res://scripts/resources/enemy_data.gd` | `enemy_type:Types.EnemyType,display_name:String,max_hp:int,move_speed:float,damage:int,attack_range:float,attack_cooldown:float,armor_type:Types.ArmorType,gold_reward:int,is_ranged:bool,is_flying:bool,color:Color,damage_immunities:Array[Types.DamageType]` |
| `ResearchNodeData` | `res://scripts/resources/research_node_data.gd` | `node_id:String,display_name:String,research_cost:int,prerequisite_ids:Array[String],description:String` |
| `DialogueCondition` | `res://scripts/resources/dialogue/dialogue_condition.gd` | `key:String,comparison:String,value:Variant` |
| `DialogueEntry` | `res://scripts/resources/dialogue/dialogue_entry.gd` | `entry_id:String,character_id:String,text:String,priority:int,once_only:bool,chain_next_id:String,conditions:Array[DialogueCondition]` |
| `ShopItemData` | `res://scripts/resources/shop_item_data.gd` | `item_id:String,display_name:String,gold_cost:int,material_cost:int,description:String` |
| `SpellData` | `res://scripts/resources/spell_data.gd` | `spell_id:String,display_name:String,mana_cost:int,cooldown:float,damage:float,radius:float,damage_type:Types.DamageType,hits_flying:bool` |
| `WeaponData` | `res://scripts/resources/weapon_data.gd` | `weapon_slot:Types.WeaponSlot,display_name:String,damage:float,projectile_speed:float,reload_time:float,burst_count:int,burst_interval:float,can_target_flying:bool,assist_angle_degrees:float,assist_max_distance:float,base_miss_chance:float,max_miss_angle_degrees:float` |
| `TerritoryData` | `res://scripts/resources/territory_data.gd` | `territory_id:String,display_name:String,description:String,default_faction_id:String,icon_id:String,color:Color,terrain_type:int,is_controlled_by_player:bool,is_secured:bool,has_boss_threat:bool,is_permanently_lost:bool,threat_level:int,is_under_attack:bool,bonus_flat_gold_end_of_day:int,bonus_percent_gold_end_of_day:float,bonus_flat_gold_per_kill:int,bonus_research_per_day:int,bonus_research_cost_multiplier:float,bonus_enchanting_cost_multiplier:float,bonus_weapon_upgrade_cost_multiplier:float` |
| `TerritoryMapData` | `res://scripts/resources/territory_map_data.gd` | `territories:Array[TerritoryData]` |
| `FactionRosterEntry` | `res://scripts/resources/faction_roster_entry.gd` | `enemy_type:Types.EnemyType,base_weight:float,min_wave_index:int,max_wave_index:int,tier:int` |
| `FactionData` | `res://scripts/resources/faction_data.gd` | `faction_id:String,display_name:String,description:String,roster:Array[FactionRosterEntry],mini_boss_ids:Array[String],mini_boss_wave_hints:Array[int],roster_tier:int,difficulty_offset:float` |
| `BossData` | `res://scripts/resources/boss_data.gd` | `boss_id:String,display_name:String,description:String,faction_id:String,associated_territory_id:String,threat_icon_id:String,max_hp:int,move_speed:float,damage:int,attack_range:float,attack_cooldown:float,armor_type:Types.ArmorType,gold_reward:int,is_ranged:bool,is_flying:bool,damage_immunities:Array[Types.DamageType],phase_count:int,escort_unit_ids:Array[String],is_mini_boss:bool,is_final_boss:bool,boss_scene:PackedScene` |
| `DayConfig` | `res://scripts/resources/day_config.gd` | `day_index:int,mission_index:int,display_name:String,description:String,faction_id:String,territory_id:String,is_mini_boss_day:bool,is_mini_boss:bool,is_final_boss:bool,boss_id:String,is_boss_attack_day:bool,base_wave_count:int,enemy_hp_multiplier:float,enemy_damage_multiplier:float,gold_reward_multiplier:float` |
| `CampaignConfig` | `res://scripts/resources/campaign_config.gd` | `campaign_id:String,display_name:String,day_configs:Array[DayConfig],starting_territory_ids:Array[String],territory_map_resource_path:String,is_short_campaign:bool,short_campaign_length:int` |
| `StrategyProfile` | `res://scripts/resources/strategyprofile.gd` | `profile_id:String,description:String,build_priorities:Array[Dictionary],placement_preferences:Dictionary,spell_usage:Dictionary,upgrade_behavior:Dictionary,difficulty_target:float` |
| `MercenaryOfferData` | `res://scripts/resources/mercenary_offer_data.gd` | `ally_id:String,cost_gold:int,cost_building_material:int,cost_research_material:int,min_day:int,max_day:int,is_defection_offer:bool` |
| `MercenaryCatalog` | `res://scripts/resources/mercenary_catalog.gd` | `offers:Array,max_offers_per_day:int` |
| `MiniBossData` | `res://scripts/resources/mini_boss_data.gd` | `boss_id:String,can_defect_to_ally:bool,defected_ally_id:String,defection_cost_gold:int` |

## 4) Scene Matrix

| scene_path | root_node_name | root_node_type | script_path |
|---|---|---|---|
| `res://scenes/main.tscn` | `Main` | `Node3D` | `res://scripts/main_root.gd` |
| `res://scenes/arnulf/arnulf.tscn` | `Arnulf` | `CharacterBody3D` | `res://scenes/arnulf/arnulf.gd` |
| `res://scenes/buildings/building_base.tscn` | `BuildingBase` | `Node3D` | `res://scenes/buildings/building_base.gd` |
| `res://scenes/enemies/enemy_base.tscn` | `EnemyBase` | `CharacterBody3D` | `res://scenes/enemies/enemy_base.gd` |
| `res://scenes/bosses/boss_base.tscn` | `BossBase` | `CharacterBody3D` | `res://scenes/bosses/boss_base.gd` |
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
| `all_waves_cleared` | `()` | `res://scripts/wave_manager.gd` |
| `ally_roster_changed` | `()` | `res://autoloads/campaign_manager.gd` |
| `arnulf_incapacitated` | `()` | `res://scenes/arnulf/arnulf.gd` |
| `arnulf_recovered` | `()` | `res://scenes/arnulf/arnulf.gd` |
| `arnulf_state_changed` | `(new_state:Types.ArnulfState)` | `res://scenes/arnulf/arnulf.gd` |
| `boss_killed` | `(boss_id:String)` | `res://scenes/bosses/boss_base.gd` |
| `boss_spawned` | `(boss_id:String)` | `res://scenes/bosses/boss_base.gd` |
| `building_destroyed` | `(slot_index:int)` | `-` |
| `building_placed` | `(slot_index:int,building_type:Types.BuildingType)` | `res://scenes/hex_grid/hex_grid.gd` |
| `building_sold` | `(slot_index:int,building_type:Types.BuildingType)` | `res://scenes/hex_grid/hex_grid.gd` |
| `building_upgraded` | `(slot_index:int,building_type:Types.BuildingType)` | `res://scenes/hex_grid/hex_grid.gd` |
| `build_mode_entered` | `()` | `res://autoloads/game_manager.gd` |
| `build_mode_exited` | `()` | `res://autoloads/game_manager.gd` |
| `campaign_boss_attempted` | `(day_index:int,success:bool)` | `res://autoloads/game_manager.gd` |
| `campaign_completed` | `(campaign_id:String)` | `res://autoloads/campaign_manager.gd` |
| `campaign_started` | `(campaign_id:String)` | `res://autoloads/campaign_manager.gd` |
| `day_failed` | `(day_index:int)` | `res://autoloads/campaign_manager.gd` |
| `day_started` | `(day_index:int)` | `res://autoloads/campaign_manager.gd` |
| `day_won` | `(day_index:int)` | `res://autoloads/campaign_manager.gd` |
| `enchantment_applied` | `(weapon_slot:Types.WeaponSlot,slot_type:String,enchantment_id:String)` | `res://autoloads/enchantment_manager.gd` |
| `enchantment_removed` | `(weapon_slot:Types.WeaponSlot,slot_type:String)` | `res://autoloads/enchantment_manager.gd` |
| `enemy_killed` | `(enemy_type:Types.EnemyType,position:Vector3,gold_reward:int)` | `res://scenes/enemies/enemy_base.gd` |
| `enemy_reached_tower` | `(enemy_type:Types.EnemyType,damage:int)` | `-` |
| `game_state_changed` | `(old_state:Types.GameState,new_state:Types.GameState)` | `res://autoloads/game_manager.gd` |
| `mana_changed` | `(current_mana:int,max_mana:int)` | `res://scripts/spell_manager.gd` |
| `mana_draught_consumed` | `()` | `res://scripts/shop_manager.gd` |
| `mercenary_offer_generated` | `(ally_id:String)` | `res://autoloads/campaign_manager.gd` |
| `mercenary_recruited` | `(ally_id:String)` | `res://autoloads/campaign_manager.gd` |
| `mission_failed` | `(mission_number:int)` | `res://autoloads/game_manager.gd` |
| `mission_started` | `(mission_number:int)` | `res://autoloads/game_manager.gd` |
| `mission_won` | `(mission_number:int)` | `res://autoloads/game_manager.gd` |
| `projectile_fired` | `(weapon_slot:Types.WeaponSlot,origin:Vector3,target:Vector3)` | `res://scenes/tower/tower.gd` |
| `research_unlocked` | `(node_id:String)` | `res://scripts/research_manager.gd` |
| `resource_changed` | `(resource_type:Types.ResourceType,new_amount:int)` | `res://autoloads/economy_manager.gd` |
| `shop_item_purchased` | `(item_id:String)` | `res://scripts/shop_manager.gd` |
| `spell_cast` | `(spell_id:String)` | `res://scripts/spell_manager.gd` |
| `spell_ready` | `(spell_id:String)` | `res://scripts/spell_manager.gd` |
| `territory_state_changed` | `(territory_id:String)` | `res://autoloads/game_manager.gd,tests` |
| `tower_damaged` | `(current_hp:int,max_hp:int)` | `res://scenes/tower/tower.gd` |
| `tower_destroyed` | `()` | `res://scenes/tower/tower.gd` |
| `wave_cleared` | `(wave_number:int)` | `res://scripts/wave_manager.gd` |
| `wave_countdown_started` | `(wave_number:int,seconds_remaining:float)` | `res://scripts/wave_manager.gd` |
| `wave_started` | `(wave_number:int,enemy_count:int)` | `res://scripts/wave_manager.gd` |
| `weapon_upgraded` | `(weapon_slot:Types.WeaponSlot,new_level:int)` | `res://scripts/weapon_upgrade_manager.gd` |
| `world_map_updated` | `()` | `res://autoloads/game_manager.gd` |

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

## 2026-03-24 Prompt 10 delta (bosses)

- `docs/PROMPT_10_IMPLEMENTATION.md` — handoff + verification.
- **`BossData`**, **`BossBase`**, `res://resources/bossdata_*.tres`; **SignalBus**: `boss_spawned`, `boss_killed`, `campaign_boss_attempted`.
- **WaveManager**: `boss_registry`, `set_day_context`, `ensure_boss_registry_loaded`.
- **GameManager**: final-boss + synthetic boss-day flow; `prepare_next_campaign_day_if_needed`, `advance_to_next_day`, `get_synthetic_boss_day_config`, `reset_boss_campaign_state_for_test`.
- **DayConfig** / **TerritoryData** / **CampaignConfig** fields per implementation doc.
- Tests: `test_boss_data.gd`, `test_boss_base.gd`, `test_boss_waves.gd`, `test_final_boss_day.gd`; `test_wave_manager.gd` (`test_regular_day_spawns_no_bosses`).

## 2026-03-24 Prompt 10 fixes (GdUnit)

- **`docs/PROMPT_10_FIXES.md`** — full list (`WeaponLevelData` `.tres`, `test_campaign_manager` asserts, WaveManager test harness, **`GameManager._begin_mission_wave_sequence`** graceful skip when **`Main`** / **`WaveManager`** absent).
- **`WaveManager`**: `@onready` **`_enemy_container`** / **`_spawn_points`** = **`get_node_or_null("/root/Main/EnemyContainer")`** and **`.../SpawnPoints`**; spawn paths early-return if null.
- **`GameManager`**: **`_begin_mission_wave_sequence()`** uses **`get_node_or_null`** for **`Main`**, **`Managers`**, **`WaveManager`**; **`push_warning`** and returns if missing (headless GdUnit; not **`push_error`** — GdUnit **`GodotGdErrorMonitor`**). **`mission_won`** → **`_on_mission_won_transition_to_hub`**; **`project.godot`**: **`CampaignManager`** before **`GameManager`**.
- **`test_wave_manager.gd`**, **`test_boss_waves.gd`**: **`SpawnPoints`** in tree before **`Marker3D.global_position`**; assign **`wm._enemy_container`** / **`wm._spawn_points`** after **`add_child(wm)`**.
- **`docs/PROBLEM_REPORT.md`**: GdUnit / **`mission_won`** / engine log snippets and file list.

## 2026-03-25 Prompt 12 delta (mercenaries)

- **`docs/PROMPT_12_IMPLEMENTATION.md`** — mercenary offers, owned/active roster, mini-boss defection, SimBot strategy hooks.
- **SignalBus**: `mercenary_offer_generated`, `mercenary_recruited`, `ally_roster_changed`.
- **Resources**: `MercenaryOfferData`, `MercenaryCatalog`, `MiniBossData`; `res://resources/mercenary_catalog.tres`, `mercenary_offers/`, `miniboss_data/`.
- **CampaignManager**: offer generation/preview/purchase, `notify_mini_boss_defeated`, `auto_select_best_allies`; `@export mercenary_catalog`.
- **BetweenMissionScreen**: Mercenaries tab.
- **SimBot**: `activate(strategy)`, `decide_mercenaries`, `get_log`.
- **Tests**: `test_mercenary_offers.gd`, `test_mercenary_purchase.gd`, `test_campaign_ally_roster.gd`, `test_mini_boss_defection.gd`, `test_simbot_mercenaries.gd` (included in `./tools/run_gdunit_quick.sh`).
- **GameManager**: `_transition_to` no-op when new state equals current state.

## 2026-03-25 Prompt 15 delta (Florence meta-state)

- **`docs/PROMPT_15_IMPLEMENTATION.md`**
- Added `res://scripts/florence_data.gd` (`class_name FlorenceData`)
- Updated `res://scripts/types.gd`:
  - `enum DayAdvanceReason`
  - `Types.get_day_advance_priority(reason)`
- Updated `res://autoloads/signal_bus.gd`:
  - `SignalBus.florence_state_changed()`
- Updated `res://autoloads/game_manager.gd`:
  - `GameManager.current_day`, `GameManager.florence_data`, `advance_day()`, `_apply_pending_day_advance_if_any()`
  - Mission win/fail hooks increment Florence counters and advance meta day
  - `get_florence_data()`
- Updated `res://scripts/research_manager.gd` and `res://scripts/shop_manager.gd` with Florence unlock hooks
- Updated `res://ui/between_mission_screen.tscn` / `res://ui/between_mission_screen.gd`:
  - `FlorenceDebugLabel` + refresh on `florence_state_changed`
- Updated `res://autoloads/dialogue_manager.gd`:
  - Resolver support for `florence.*` and `campaign.*` condition keys
- Added `res://tests/test_florence.gd` and included it in `./tools/run_gdunit_quick.sh` allowlist
- Follow-up parse-safety fixes: removed invalid `Types.DayAdvanceReason(...)` cast in `GameManager.advance_day()` and avoided `: FlorenceData` local type annotations in tests/UI
