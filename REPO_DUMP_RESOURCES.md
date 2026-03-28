# REPO_DUMP — Resources (`.tres`, `.res`)

Split from `REPO_DUMP_AFTER_PROMPTS_1_17.md.md`. Sections are unchanged from the original dump format.

---

## `resources/ally_data/ally_melee_generic.tres`

````
[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ally_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "ally_melee_generic"
display_name = "Mercenary (Melee)"
description = "PLACEHOLDER narrative."
ally_class = 0
max_hp = 90
move_speed = 4.5
basic_attack_damage = 12.0
attack_range = 2.0
attack_cooldown = 1.0
preferred_targeting = 0
is_unique = false
scene_path = "res://scenes/allies/ally_base.tscn"
is_starter_ally = false
is_defected_ally = false
debug_color = Color(0.2, 0.45, 0.95, 1)
````

---

## `resources/ally_data/ally_ranged_generic.tres`

````
[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ally_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "ally_ranged_generic"
display_name = "Mercenary (Ranged)"
description = "PLACEHOLDER narrative."
ally_class = 1
max_hp = 70
move_speed = 4.0
basic_attack_damage = 14.0
attack_range = 10.0
attack_cooldown = 1.1
preferred_targeting = 0
is_unique = false
scene_path = "res://scenes/allies/ally_base.tscn"
is_starter_ally = false
is_defected_ally = false
debug_color = Color(0.25, 0.5, 0.9, 1)
````

---

## `resources/ally_data/ally_support_generic.tres`

````
[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ally_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "ally_support_generic"
display_name = "Mercenary (Support)"
description = "PLACEHOLDER narrative."
ally_class = 2
max_hp = 80
move_speed = 3.8
basic_attack_damage = 8.0
attack_range = 8.0
attack_cooldown = 1.2
preferred_targeting = 0
is_unique = false
scene_path = "res://scenes/allies/ally_base.tscn"
is_starter_ally = false
is_defected_ally = false
debug_color = Color(0.55, 0.35, 0.85, 1)
````

---

## `resources/ally_data/anti_air_scout.tres`

````
[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ally_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "anti_air_scout"
display_name = "Anti-Air Scout"
description = "PLACEHOLDER: focuses on flying threats (POST-MVP targeting)."
ally_class = 1
role = 2
damage_type = 0
can_target_flying = true
max_hp = 65
move_speed = 4.5
basic_attack_damage = 11.0
attack_range = 9.0
attack_cooldown = 0.95
patrol_radius = 16.0
recovery_time = 0.0
preferred_targeting = 2
is_unique = false
scene_path = "res://scenes/allies/ally_base.tscn"
is_starter_ally = false
is_defected_ally = false
debug_color = Color(0.3, 0.85, 0.4, 1)
````

---

## `resources/ally_data/arnulf_ally_data.tres`

````
[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ally_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "arnulf"
display_name = "Arnulf"
description = "Tower guardian; always present in the main scene."
ally_class = 0
role = 0
damage_type = 0
can_target_flying = false
max_hp = 200
move_speed = 5.0
basic_attack_damage = 25.0
attack_damage = 25.0
attack_range = 2.0
attack_cooldown = 1.0
patrol_radius = 55.0
recovery_time = 3.0
preferred_targeting = 0
is_unique = true
scene_path = "res://scenes/arnulf/arnulf.tscn"
is_starter_ally = true
is_defected_ally = false
debug_color = Color(0.25, 0.55, 0.95, 1)
````

---

## `resources/ally_data/defected_orc_captain.tres`

````
[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ally_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "defected_orc_captain"
display_name = "Defected Orc Captain"
description = "PLACEHOLDER: former mini-boss turned ally."
ally_class = 0
role = 0
damage_type = 0
can_target_flying = false
max_hp = 140
move_speed = 3.8
basic_attack_damage = 18.0
attack_range = 2.2
attack_cooldown = 1.15
patrol_radius = 12.0
recovery_time = 0.0
preferred_targeting = 0
is_unique = true
scene_path = "res://scenes/allies/ally_base.tscn"
is_starter_ally = false
is_defected_ally = true
debug_color = Color(0.45, 0.35, 0.25, 1)
````

---

## `resources/ally_data/hired_archer.tres`

````
[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/ally_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "hired_archer"
display_name = "Hired Archer"
description = "PLACEHOLDER: catalog mercenary (ranged)."
ally_class = 1
role = 1
damage_type = 0
can_target_flying = false
max_hp = 70
move_speed = 4.0
basic_attack_damage = 14.0
attack_range = 10.0
attack_cooldown = 1.1
patrol_radius = 14.0
recovery_time = 0.0
preferred_targeting = 0
is_unique = false
scene_path = "res://scenes/allies/ally_base.tscn"
is_starter_ally = false
is_defected_ally = false
debug_color = Color(0.85, 0.55, 0.2, 1)
````

---

## `resources/bossdata_final_boss.tres`

````
[gd_resource type="Resource" script_class="BossData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/boss_data.gd" id="1_boss"]
[ext_resource type="PackedScene" path="res://scenes/bosses/boss_base.tscn" id="2_scene"]

[resource]
script = ExtResource("1_boss")
boss_id = "final_boss"
display_name = "Archrot Incarnate"
description = "PLACEHOLDER: Campaign-ending threat for Day 50."
faction_id = "PLAGUE_CULT"
associated_territory_id = ""
threat_icon_id = ""
max_hp = 5000
move_speed = 2.2
damage = 80
attack_range = 2.5
attack_cooldown = 0.85
gold_reward = 2000
is_ranged = false
is_flying = false
phase_count = 3
escort_unit_ids = Array[String](["ORC_BRUTE", "PLAGUE_ZOMBIE", "BAT_SWARM"])
is_mini_boss = false
is_final_boss = true
boss_scene = ExtResource("2_scene")
````

---

## `resources/bossdata_orc_warlord_miniboss.tres`

````
[gd_resource type="Resource" script_class="BossData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/boss_data.gd" id="1_boss"]
[ext_resource type="PackedScene" path="res://scenes/bosses/boss_base.tscn" id="2_scene"]

[resource]
script = ExtResource("1_boss")
boss_id = "orc_warlord"
display_name = "Gorefang Warlord"
description = "PLACEHOLDER: Orc Raiders mini-boss."
faction_id = "ORC_RAIDERS"
max_hp = 400
move_speed = 3.2
damage = 32
attack_range = 2.0
attack_cooldown = 1.0
gold_reward = 110
escort_unit_ids = Array[String](["ORC_GRUNT", "ORC_ARCHER"])
is_mini_boss = true
is_final_boss = false
boss_scene = ExtResource("2_scene")
````

---

## `resources/bossdata_plague_cult_miniboss.tres`

````
[gd_resource type="Resource" script_class="BossData" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/boss_data.gd" id="1_boss"]
[ext_resource type="PackedScene" path="res://scenes/bosses/boss_base.tscn" id="2_scene"]

[resource]
script = ExtResource("1_boss")
boss_id = "plague_cult_miniboss"
display_name = "Herald of Worms"
description = "PLACEHOLDER: Plague Cult mini-boss."
faction_id = "PLAGUE_CULT"
associated_territory_id = ""
threat_icon_id = ""
max_hp = 450
move_speed = 2.8
damage = 35
attack_range = 2.2
attack_cooldown = 1.1
gold_reward = 120
is_ranged = false
is_flying = false
phase_count = 1
escort_unit_ids = Array[String](["ORC_GRUNT", "ORC_BRUTE"])
is_mini_boss = true
is_final_boss = false
boss_scene = ExtResource("2_scene")
````

---

## `resources/building_data/anti_air_bolt.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 6
display_name = "Anti-Air Bolt"
gold_cost = 70
material_cost = 3
upgrade_gold_cost = 100
upgrade_material_cost = 4
damage = 30.0
upgraded_damage = 50.0
fire_rate = 1.2
attack_range = 20.0
upgraded_range = 24.0
damage_type = 0
targets_air = true
targets_ground = false
is_locked = true
unlock_research_id = "unlock_anti_air"
research_damage_boost_id = ""
research_range_boost_id = ""
color = Color(0.2, 0.5, 0.9, 1.0)
````

---

## `resources/building_data/archer_barracks.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 5
display_name = "Archer Barracks"
gold_cost = 90
material_cost = 4
upgrade_gold_cost = 0
upgrade_material_cost = 0
damage = 0.0
upgraded_damage = 0.0
fire_rate = 0.0
attack_range = 0.0
upgraded_range = 0.0
damage_type = 0
targets_air = false
targets_ground = false
is_locked = true
unlock_research_id = "unlock_archer_barracks"
research_damage_boost_id = ""
research_range_boost_id = ""
color = Color(0.8, 0.7, 0.3, 1.0)
````

---

## `resources/building_data/arrow_tower.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 0
display_name = "Arrow Tower"
gold_cost = 50
material_cost = 2
upgrade_gold_cost = 75
upgrade_material_cost = 3
damage = 20.0
upgraded_damage = 35.0
fire_rate = 1.0
attack_range = 15.0
upgraded_range = 18.0
damage_type = 0
targets_air = false
targets_ground = true
is_locked = false
unlock_research_id = ""
research_damage_boost_id = "arrow_tower_plus_damage"
research_range_boost_id = ""
color = Color(0.7, 0.5, 0.2, 1.0)
````

---

## `resources/building_data/ballista.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 4
display_name = "Ballista"
gold_cost = 100
material_cost = 5
upgrade_gold_cost = 150
upgrade_material_cost = 6
damage = 60.0
upgraded_damage = 100.0
fire_rate = 0.4
attack_range = 25.0
upgraded_range = 30.0
damage_type = 0
targets_air = false
targets_ground = true
is_locked = true
unlock_research_id = "unlock_ballista"
color = Color(0.6, 0.4, 0.1, 1.0)
````

---

## `resources/building_data/fire_brazier.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 1
display_name = "Fire Brazier"
gold_cost = 60
material_cost = 3
upgrade_gold_cost = 90
upgrade_material_cost = 4
damage = 15.0
upgraded_damage = 28.0
fire_rate = 0.8
attack_range = 12.0
upgraded_range = 14.0
damage_type = 1
targets_air = false
targets_ground = true
is_locked = false
unlock_research_id = ""
research_damage_boost_id = ""
research_range_boost_id = "fire_brazier_plus_range"
color = Color(0.9, 0.3, 0.0, 1.0)
dot_enabled = true
dot_total_damage = 11.25
dot_tick_interval = 0.5
dot_duration = 3.0
dot_effect_type = "burn"
dot_source_id = "fire_brazier"
dot_in_addition_to_hit = true
````

---

## `resources/building_data/magic_obelisk.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 2
display_name = "Magic Obelisk"
gold_cost = 80
material_cost = 4
upgrade_gold_cost = 120
upgrade_material_cost = 5
damage = 25.0
upgraded_damage = 45.0
fire_rate = 0.6
attack_range = 18.0
upgraded_range = 22.0
damage_type = 2
targets_air = false
targets_ground = true
is_locked = false
unlock_research_id = ""
color = Color(0.5, 0.0, 0.8, 1.0)
````

---

## `resources/building_data/poison_vat.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 3
display_name = "Poison Vat"
gold_cost = 55
material_cost = 2
upgrade_gold_cost = 80
upgrade_material_cost = 3
damage = 10.0
upgraded_damage = 18.0
fire_rate = 1.5
attack_range = 10.0
upgraded_range = 12.0
damage_type = 3
targets_air = false
targets_ground = true
is_locked = false
unlock_research_id = ""
color = Color(0.2, 0.7, 0.1, 1.0)
dot_enabled = true
dot_total_damage = 7.5
dot_tick_interval = 1.0
dot_duration = 5.0
dot_effect_type = "poison"
dot_source_id = "poison_vat"
dot_in_addition_to_hit = true
````

---

## `resources/building_data/shield_generator.tres`

````
[gd_resource type="Resource" script_class="BuildingData" format=3]

[ext_resource type="Script" path="res://scripts/resources/building_data.gd" id="1_buildingdata"]

[resource]
script = ExtResource("1_buildingdata")
building_type = 7
display_name = "Shield Generator"
gold_cost = 120
material_cost = 6
upgrade_gold_cost = 0
upgrade_material_cost = 0
damage = 0.0
upgraded_damage = 0.0
fire_rate = 0.0
attack_range = 0.0
upgraded_range = 0.0
damage_type = 0
targets_air = false
targets_ground = false
is_locked = true
unlock_research_id = "unlock_shield_generator"
research_damage_boost_id = ""
research_range_boost_id = ""
color = Color(0.0, 0.8, 0.8, 1.0)
````

---

## `resources/campaign_main_50days.tres`

````
; campaign_main_50days.tres — Main 50-day CampaignConfig.
; # PLACEHOLDER / # TUNING / # ASSUMPTION: days 6–50 reuse mission_index 5 for MVP testing.

[gd_resource type="Resource" script_class="CampaignConfig" load_steps=53 format=3]

[ext_resource type="Script" path="res://scripts/resources/campaign_config.gd" id="1_cc"]
[ext_resource type="Script" path="res://scripts/resources/day_config.gd" id="2_dc"]

[sub_resource type="Resource" id="Day_1"]
script = ExtResource("2_dc")
day_index = 1
mission_index = 1
display_name = "Day 1"
description = "Linear campaign day 1. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_2"]
script = ExtResource("2_dc")
day_index = 2
mission_index = 2
display_name = "Day 2"
description = "Linear campaign day 2. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_3"]
script = ExtResource("2_dc")
day_index = 3
mission_index = 3
display_name = "Day 3"
description = "Linear campaign day 3. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_4"]
script = ExtResource("2_dc")
day_index = 4
mission_index = 4
display_name = "Day 4"
description = "Linear campaign day 4. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_5"]
script = ExtResource("2_dc")
day_index = 5
mission_index = 5
display_name = "Day 5"
description = "Linear campaign day 5. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_6"]
script = ExtResource("2_dc")
day_index = 6
mission_index = 5
display_name = "Day 6"
description = "Linear campaign day 6. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_7"]
script = ExtResource("2_dc")
day_index = 7
mission_index = 5
display_name = "Day 7"
description = "Linear campaign day 7. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_8"]
script = ExtResource("2_dc")
day_index = 8
mission_index = 5
display_name = "Day 8"
description = "Linear campaign day 8. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_9"]
script = ExtResource("2_dc")
day_index = 9
mission_index = 5
display_name = "Day 9"
description = "Linear campaign day 9. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_10"]
script = ExtResource("2_dc")
day_index = 10
mission_index = 5
display_name = "Day 10"
description = "Linear campaign day 10. # PLACEHOLDER"
territory_id = "heartland_plains"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_11"]
script = ExtResource("2_dc")
day_index = 11
mission_index = 5
display_name = "Day 11"
description = "Linear campaign day 11. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_12"]
script = ExtResource("2_dc")
day_index = 12
mission_index = 5
display_name = "Day 12"
description = "Linear campaign day 12. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_13"]
script = ExtResource("2_dc")
day_index = 13
mission_index = 5
display_name = "Day 13"
description = "Linear campaign day 13. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_14"]
script = ExtResource("2_dc")
day_index = 14
mission_index = 5
display_name = "Day 14"
description = "Linear campaign day 14. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_15"]
script = ExtResource("2_dc")
day_index = 15
mission_index = 5
display_name = "Day 15"
description = "Linear campaign day 15. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_16"]
script = ExtResource("2_dc")
day_index = 16
mission_index = 5
display_name = "Day 16"
description = "Linear campaign day 16. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_17"]
script = ExtResource("2_dc")
day_index = 17
mission_index = 5
display_name = "Day 17"
description = "Linear campaign day 17. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_18"]
script = ExtResource("2_dc")
day_index = 18
mission_index = 5
display_name = "Day 18"
description = "Linear campaign day 18. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_19"]
script = ExtResource("2_dc")
day_index = 19
mission_index = 5
display_name = "Day 19"
description = "Linear campaign day 19. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_20"]
script = ExtResource("2_dc")
day_index = 20
mission_index = 5
display_name = "Day 20"
description = "Linear campaign day 20. # PLACEHOLDER"
territory_id = "blackwood_forest"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_21"]
script = ExtResource("2_dc")
day_index = 21
mission_index = 5
display_name = "Day 21"
description = "Linear campaign day 21. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_22"]
script = ExtResource("2_dc")
day_index = 22
mission_index = 5
display_name = "Day 22"
description = "Linear campaign day 22. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_23"]
script = ExtResource("2_dc")
day_index = 23
mission_index = 5
display_name = "Day 23"
description = "Linear campaign day 23. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_24"]
script = ExtResource("2_dc")
day_index = 24
mission_index = 5
display_name = "Day 24"
description = "Linear campaign day 24. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_25"]
script = ExtResource("2_dc")
day_index = 25
mission_index = 5
display_name = "Day 25"
description = "Linear campaign day 25. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_26"]
script = ExtResource("2_dc")
day_index = 26
mission_index = 5
display_name = "Day 26"
description = "Linear campaign day 26. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_27"]
script = ExtResource("2_dc")
day_index = 27
mission_index = 5
display_name = "Day 27"
description = "Linear campaign day 27. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_28"]
script = ExtResource("2_dc")
day_index = 28
mission_index = 5
display_name = "Day 28"
description = "Linear campaign day 28. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_29"]
script = ExtResource("2_dc")
day_index = 29
mission_index = 5
display_name = "Day 29"
description = "Linear campaign day 29. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_30"]
script = ExtResource("2_dc")
day_index = 30
mission_index = 5
display_name = "Day 30"
description = "Linear campaign day 30. # PLACEHOLDER"
territory_id = "ashen_swamp"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_31"]
script = ExtResource("2_dc")
day_index = 31
mission_index = 5
display_name = "Day 31"
description = "Linear campaign day 31. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_32"]
script = ExtResource("2_dc")
day_index = 32
mission_index = 5
display_name = "Day 32"
description = "Linear campaign day 32. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_33"]
script = ExtResource("2_dc")
day_index = 33
mission_index = 5
display_name = "Day 33"
description = "Linear campaign day 33. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_34"]
script = ExtResource("2_dc")
day_index = 34
mission_index = 5
display_name = "Day 34"
description = "Linear campaign day 34. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_35"]
script = ExtResource("2_dc")
day_index = 35
mission_index = 5
display_name = "Day 35"
description = "Linear campaign day 35. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_36"]
script = ExtResource("2_dc")
day_index = 36
mission_index = 5
display_name = "Day 36"
description = "Linear campaign day 36. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_37"]
script = ExtResource("2_dc")
day_index = 37
mission_index = 5
display_name = "Day 37"
description = "Linear campaign day 37. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_38"]
script = ExtResource("2_dc")
day_index = 38
mission_index = 5
display_name = "Day 38"
description = "Linear campaign day 38. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_39"]
script = ExtResource("2_dc")
day_index = 39
mission_index = 5
display_name = "Day 39"
description = "Linear campaign day 39. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_40"]
script = ExtResource("2_dc")
day_index = 40
mission_index = 5
display_name = "Day 40"
description = "Linear campaign day 40. # PLACEHOLDER"
territory_id = "iron_ridge"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_41"]
script = ExtResource("2_dc")
day_index = 41
mission_index = 5
display_name = "Day 41"
description = "Linear campaign day 41. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_42"]
script = ExtResource("2_dc")
day_index = 42
mission_index = 5
display_name = "Day 42"
description = "Linear campaign day 42. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_43"]
script = ExtResource("2_dc")
day_index = 43
mission_index = 5
display_name = "Day 43"
description = "Linear campaign day 43. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_44"]
script = ExtResource("2_dc")
day_index = 44
mission_index = 5
display_name = "Day 44"
description = "Linear campaign day 44. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_45"]
script = ExtResource("2_dc")
day_index = 45
mission_index = 5
display_name = "Day 45"
description = "Linear campaign day 45. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_46"]
script = ExtResource("2_dc")
day_index = 46
mission_index = 5
display_name = "Day 46"
description = "Linear campaign day 46. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_47"]
script = ExtResource("2_dc")
day_index = 47
mission_index = 5
display_name = "Day 47"
description = "Linear campaign day 47. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_48"]
script = ExtResource("2_dc")
day_index = 48
mission_index = 5
display_name = "Day 48"
description = "Linear campaign day 48. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_49"]
script = ExtResource("2_dc")
day_index = 49
mission_index = 5
display_name = "Day 49"
description = "Linear campaign day 49. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[sub_resource type="Resource" id="Day_50"]
script = ExtResource("2_dc")
day_index = 50
mission_index = 5
display_name = "Day 50"
description = "Linear campaign day 50. # PLACEHOLDER"
territory_id = "outer_city"
faction_id = ""
is_mini_boss_day = false
is_final_boss = false
base_wave_count = 5
; # TUNING
enemy_hp_multiplier = 1.0
enemy_damage_multiplier = 1.0
gold_reward_multiplier = 1.0

[resource]
script = ExtResource("1_cc")
campaign_id = "main_campaign_50_days"
display_name = "Main Campaign 50 Days"
day_configs = [SubResource("Day_1"),SubResource("Day_2"),SubResource("Day_3"),SubResource("Day_4"),SubResource("Day_5"),SubResource("Day_6"),SubResource("Day_7"),SubResource("Day_8"),SubResource("Day_9"),SubResource("Day_10"),SubResource("Day_11"),SubResource("Day_12"),SubResource("Day_13"),SubResource("Day_14"),SubResource("Day_15"),SubResource("Day_16"),SubResource("Day_17"),SubResource("Day_18"),SubResource("Day_19"),SubResource("Day_20"),SubResource("Day_21"),SubResource("Day_22"),SubResource("Day_23"),SubResource("Day_24"),SubResource("Day_25"),SubResource("Day_26"),SubResource("Day_27"),SubResource("Day_28"),SubResource("Day_29"),SubResource("Day_30"),SubResource("Day_31"),SubResource("Day_32"),SubResource("Day_33"),SubResource("Day_34"),SubResource("Day_35"),SubResource("Day_36"),SubResource("Day_37"),SubResource("Day_38"),SubResource("Day_39"),SubResource("Day_40"),SubResource("Day_41"),SubResource("Day_42"),SubResource("Day_43"),SubResource("Day_44"),SubResource("Day_45"),SubResource("Day_46"),SubResource("Day_47"),SubResource("Day_48"),SubResource("Day_49"),SubResource("Day_50")]
territory_map_resource_path = "res://resources/territories/main_campaign_territories.tres"
is_short_campaign = false
short_campaign_length = 0
````

---

## `resources/campaigns/campaign_main_50_days.tres`

````
[gd_resource type="Resource" script_class="CampaignConfig" format=3]
; campaign_main_50_days.tres — 50-day main campaign (Prompt 7).
; # PLACEHOLDER: display_name "Day N", description "Placeholder briefing." on every day until narrative pass.
; # TUNING (per day i = day_index): base_wave_count follows clamp(5 + floor((i-1)/5), 5, 10) — PLACEHOLDER linear ramp.
; # TUNING: enemy_hp_multiplier = 1.0 + (i-1)*0.02 — PLACEHOLDER +2% per day from day 1.
; # TUNING: enemy_damage_multiplier = 1.0 + (i-1)*0.015 — PLACEHOLDER +1.5% per day.
; # TUNING: gold_reward_multiplier = 1.0 + (i-1)*0.01 — PLACEHOLDER +1% per day.
; # TUNING: is_mini_boss_day true on days 10,20,30,40; is_final_boss true on day 50 only.


[ext_resource type="Script" path="res://scripts/resources/campaign_config.gd" id="1_campaignconfig"]
[ext_resource type="Script" path="res://scripts/resources/day_config.gd" id="2_dayconfig"]

[sub_resource type="Resource" id="DayConfig_1"]
script = ExtResource("2_dayconfig")
day_index = 1
display_name = "Day 1"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.0
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.0
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.0
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_2"]
script = ExtResource("2_dayconfig")
day_index = 2
display_name = "Day 2"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.02
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.015
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.01
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_3"]
script = ExtResource("2_dayconfig")
day_index = 3
display_name = "Day 3"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.04
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.03
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.02
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_4"]
script = ExtResource("2_dayconfig")
day_index = 4
display_name = "Day 4"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 5
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.06
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.045
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.03
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_5"]
script = ExtResource("2_dayconfig")
day_index = 5
display_name = "Day 5"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 6
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.08
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.06
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.04
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_6"]
script = ExtResource("2_dayconfig")
day_index = 6
display_name = "Day 6"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 6
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.1
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.075
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.05
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_7"]
script = ExtResource("2_dayconfig")
day_index = 7
display_name = "Day 7"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 6
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.12
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.09
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.06
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_8"]
script = ExtResource("2_dayconfig")
day_index = 8
display_name = "Day 8"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 6
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.14
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.105
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.07
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_9"]
script = ExtResource("2_dayconfig")
day_index = 9
display_name = "Day 9"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 6
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.16
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.12
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.08
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_10"]
script = ExtResource("2_dayconfig")
day_index = 10
display_name = "Day 10"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 7
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.18
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.135
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.09
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_11"]
script = ExtResource("2_dayconfig")
day_index = 11
display_name = "Day 11"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 7
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.2
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.15
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.1
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_12"]
script = ExtResource("2_dayconfig")
day_index = 12
display_name = "Day 12"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 7
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.22
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.165
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.11
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_13"]
script = ExtResource("2_dayconfig")
day_index = 13
display_name = "Day 13"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 7
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.24
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.18
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.12
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_14"]
script = ExtResource("2_dayconfig")
day_index = 14
display_name = "Day 14"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 7
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.26
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.195
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.13
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_15"]
script = ExtResource("2_dayconfig")
day_index = 15
display_name = "Day 15"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 8
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.28
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.21
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.14
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_16"]
script = ExtResource("2_dayconfig")
day_index = 16
display_name = "Day 16"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 8
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.3
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.225
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.15
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_17"]
script = ExtResource("2_dayconfig")
day_index = 17
display_name = "Day 17"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 8
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.32
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.24
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.16
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_18"]
script = ExtResource("2_dayconfig")
day_index = 18
display_name = "Day 18"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 8
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.34
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.255
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.17
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_19"]
script = ExtResource("2_dayconfig")
day_index = 19
display_name = "Day 19"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 8
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.36
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.27
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.18
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_20"]
script = ExtResource("2_dayconfig")
day_index = 20
display_name = "Day 20"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 9
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.38
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.285
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.19
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_21"]
script = ExtResource("2_dayconfig")
day_index = 21
display_name = "Day 21"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 9
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.4
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.3
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.2
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_22"]
script = ExtResource("2_dayconfig")
day_index = 22
display_name = "Day 22"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 9
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.42
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.315
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.21
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_23"]
script = ExtResource("2_dayconfig")
day_index = 23
display_name = "Day 23"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 9
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.44
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.33
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.22
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_24"]
script = ExtResource("2_dayconfig")
day_index = 24
display_name = "Day 24"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 9
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.46
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.345
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.23
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_25"]
script = ExtResource("2_dayconfig")
day_index = 25
display_name = "Day 25"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.48
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.36
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.24
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_26"]
script = ExtResource("2_dayconfig")
day_index = 26
display_name = "Day 26"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.5
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.375
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.25
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_27"]
script = ExtResource("2_dayconfig")
day_index = 27
display_name = "Day 27"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.52
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.39
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.26
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_28"]
script = ExtResource("2_dayconfig")
day_index = 28
display_name = "Day 28"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.54
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.405
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.27
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_29"]
script = ExtResource("2_dayconfig")
day_index = 29
display_name = "Day 29"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.56
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.42
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.28
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_30"]
script = ExtResource("2_dayconfig")
day_index = 30
display_name = "Day 30"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.58
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.435
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.29
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_31"]
script = ExtResource("2_dayconfig")
day_index = 31
display_name = "Day 31"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.6
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.45
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.3
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_32"]
script = ExtResource("2_dayconfig")
day_index = 32
display_name = "Day 32"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.62
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.465
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.31
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_33"]
script = ExtResource("2_dayconfig")
day_index = 33
display_name = "Day 33"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.64
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.48
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.32
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_34"]
script = ExtResource("2_dayconfig")
day_index = 34
display_name = "Day 34"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.66
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.495
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.33
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_35"]
script = ExtResource("2_dayconfig")
day_index = 35
display_name = "Day 35"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.68
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.51
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.34
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_36"]
script = ExtResource("2_dayconfig")
day_index = 36
display_name = "Day 36"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.7
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.525
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.35
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_37"]
script = ExtResource("2_dayconfig")
day_index = 37
display_name = "Day 37"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.72
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.54
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.36
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_38"]
script = ExtResource("2_dayconfig")
day_index = 38
display_name = "Day 38"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.74
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.555
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.37
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_39"]
script = ExtResource("2_dayconfig")
day_index = 39
display_name = "Day 39"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.76
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.57
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.38
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_40"]
script = ExtResource("2_dayconfig")
day_index = 40
display_name = "Day 40"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.78
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.585
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.39
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = true
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_41"]
script = ExtResource("2_dayconfig")
day_index = 41
display_name = "Day 41"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.8
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.6
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.4
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_42"]
script = ExtResource("2_dayconfig")
day_index = 42
display_name = "Day 42"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.82
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.615
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.41
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_43"]
script = ExtResource("2_dayconfig")
day_index = 43
display_name = "Day 43"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.84
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.63
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.42
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_44"]
script = ExtResource("2_dayconfig")
day_index = 44
display_name = "Day 44"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.86
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.645
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.43
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_45"]
script = ExtResource("2_dayconfig")
day_index = 45
display_name = "Day 45"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.88
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.66
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.44
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_46"]
script = ExtResource("2_dayconfig")
day_index = 46
display_name = "Day 46"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.9
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.675
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.45
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_47"]
script = ExtResource("2_dayconfig")
day_index = 47
display_name = "Day 47"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.92
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.69
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.46
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_48"]
script = ExtResource("2_dayconfig")
day_index = 48
display_name = "Day 48"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.94
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.705
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.47
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_49"]
script = ExtResource("2_dayconfig")
day_index = 49
display_name = "Day 49"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.96
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.72
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.48
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = false
; # TUNING: final campaign boss

[sub_resource type="Resource" id="DayConfig_50"]
script = ExtResource("2_dayconfig")
day_index = 50
mission_index = 5
faction_id = "PLAGUE_CULT"
boss_id = "final_boss"
display_name = "Day 50"
; # PLACEHOLDER: replace with final day name
description = "Placeholder briefing."
; # PLACEHOLDER: replace with briefing copy
base_wave_count = 10
; # TUNING: wave count ramp — PLACEHOLDER
enemy_hp_multiplier = 1.98
; # TUNING: HP scaling — PLACEHOLDER
enemy_damage_multiplier = 1.735
; # TUNING: damage scaling — PLACEHOLDER
gold_reward_multiplier = 1.49
; # TUNING: reward scaling — PLACEHOLDER
is_mini_boss_day = false
; # TUNING: milestone mini-boss days
is_final_boss = true
; # TUNING: final campaign boss

[resource]
script = ExtResource("1_campaignconfig")
campaign_id = "main_50_day_campaign"
display_name = "The Foul Ward - Main Campaign"
day_configs = [SubResource("DayConfig_1"), SubResource("DayConfig_2"), SubResource("DayConfig_3"), SubResource("DayConfig_4"), SubResource("DayConfig_5"), SubResource("DayConfig_6"), SubResource("DayConfig_7"), SubResource("DayConfig_8"), SubResource("DayConfig_9"), SubResource("DayConfig_10"), SubResource("DayConfig_11"), SubResource("DayConfig_12"), SubResource("DayConfig_13"), SubResource("DayConfig_14"), SubResource("DayConfig_15"), SubResource("DayConfig_16"), SubResource("DayConfig_17"), SubResource("DayConfig_18"), SubResource("DayConfig_19"), SubResource("DayConfig_20"), SubResource("DayConfig_21"), SubResource("DayConfig_22"), SubResource("DayConfig_23"), SubResource("DayConfig_24"), SubResource("DayConfig_25"), SubResource("DayConfig_26"), SubResource("DayConfig_27"), SubResource("DayConfig_28"), SubResource("DayConfig_29"), SubResource("DayConfig_30"), SubResource("DayConfig_31"), SubResource("DayConfig_32"), SubResource("DayConfig_33"), SubResource("DayConfig_34"), SubResource("DayConfig_35"), SubResource("DayConfig_36"), SubResource("DayConfig_37"), SubResource("DayConfig_38"), SubResource("DayConfig_39"), SubResource("DayConfig_40"), SubResource("DayConfig_41"), SubResource("DayConfig_42"), SubResource("DayConfig_43"), SubResource("DayConfig_44"), SubResource("DayConfig_45"), SubResource("DayConfig_46"), SubResource("DayConfig_47"), SubResource("DayConfig_48"), SubResource("DayConfig_49"), SubResource("DayConfig_50")]
is_short_campaign = false
short_campaign_length = 0
````

---

## `resources/campaigns/campaign_short_5_days.tres`

````
; campaign_short_5_days.tres — Short 5-day campaign for FOUL WARD (Prompt 7).
; # PLACEHOLDER: display_name and description copy for each day.
; # TUNING: base_wave_count, enemy_* and gold_reward multipliers per day.

[gd_resource type="Resource" script_class="CampaignConfig" format=3]

[ext_resource type="Script" path="res://scripts/resources/campaign_config.gd" id="1_campaignconfig"]
[ext_resource type="Script" path="res://scripts/resources/day_config.gd" id="2_dayconfig"]

[sub_resource type="Resource" id="DayConfig_day_1"]
script = ExtResource("2_dayconfig")
day_index = 1
mission_index = 1
display_name = "Rotting Fields"
; # PLACEHOLDER: hub / briefing display name
description = "The first wave approaches."
; # PLACEHOLDER: briefing text
base_wave_count = 5
; # TUNING: desired waves this day
enemy_hp_multiplier = 1.0
; # TUNING
enemy_damage_multiplier = 1.0
; # TUNING
gold_reward_multiplier = 1.0
; # TUNING
is_mini_boss_day = false
; # TUNING: milestone days
is_final_boss = false
; # TUNING: final boss flag (none in short MVP)

[sub_resource type="Resource" id="DayConfig_day_2"]
script = ExtResource("2_dayconfig")
day_index = 2
mission_index = 2
display_name = "Blighted Road"
; # PLACEHOLDER
description = "The enemy grows bolder."
; # PLACEHOLDER
base_wave_count = 6
; # TUNING
enemy_hp_multiplier = 1.1
; # TUNING
enemy_damage_multiplier = 1.1
; # TUNING
gold_reward_multiplier = 1.0
; # TUNING
is_mini_boss_day = false
; # TUNING
is_final_boss = false
; # TUNING

[sub_resource type="Resource" id="DayConfig_day_3"]
script = ExtResource("2_dayconfig")
day_index = 3
mission_index = 3
display_name = "Cursed Bridge"
; # PLACEHOLDER
description = "Midway. Losses mount."
; # PLACEHOLDER
base_wave_count = 7
; # TUNING
enemy_hp_multiplier = 1.2
; # TUNING
enemy_damage_multiplier = 1.2
; # TUNING
gold_reward_multiplier = 1.1
; # TUNING
is_mini_boss_day = false
; # TUNING
is_final_boss = false
; # TUNING

[sub_resource type="Resource" id="DayConfig_day_4"]
script = ExtResource("2_dayconfig")
day_index = 4
mission_index = 4
display_name = "Siege at Dawngate"
; # PLACEHOLDER
description = "They send their elite."
; # PLACEHOLDER
base_wave_count = 8
; # TUNING
enemy_hp_multiplier = 1.35
; # TUNING
enemy_damage_multiplier = 1.35
; # TUNING
gold_reward_multiplier = 1.2
; # TUNING
is_mini_boss_day = false
; # TUNING
is_final_boss = false
; # TUNING

[sub_resource type="Resource" id="DayConfig_day_5"]
script = ExtResource("2_dayconfig")
day_index = 5
mission_index = 5
display_name = "Foul Ward - Last Stand"
; # PLACEHOLDER
description = "The final assault."
; # PLACEHOLDER
base_wave_count = 10
; # TUNING
enemy_hp_multiplier = 1.5
; # TUNING
enemy_damage_multiplier = 1.5
; # TUNING
gold_reward_multiplier = 1.3
; # TUNING
is_mini_boss_day = false
; # TUNING: no mini-boss in short campaign MVP
is_final_boss = false
; # TUNING: no boss flag for short MVP (prompt spec)

[resource]
script = ExtResource("1_campaignconfig")
campaign_id = "short_campaign_5_days"
display_name = "The Foul Ward - Short Campaign"
day_configs = [SubResource("DayConfig_day_1"), SubResource("DayConfig_day_2"), SubResource("DayConfig_day_3"), SubResource("DayConfig_day_4"), SubResource("DayConfig_day_5")]
is_short_campaign = true
short_campaign_length = 5
````

---

## `resources/character_catalog.tres`

````
[gd_resource type="Resource" script_class="CharacterCatalog" load_steps=8 format=3]

[ext_resource type="Script" path="res://scripts/resources/character_catalog.gd" id="1"]
[ext_resource type="Resource" path="res://resources/character_data/merchant.tres" id="2"]
[ext_resource type="Resource" path="res://resources/character_data/researcher.tres" id="3"]
[ext_resource type="Resource" path="res://resources/character_data/enchantress.tres" id="4"]
[ext_resource type="Resource" path="res://resources/character_data/mercenary_captain.tres" id="5"]
[ext_resource type="Resource" path="res://resources/character_data/arnulf_hub.tres" id="6"]
[ext_resource type="Resource" path="res://resources/character_data/flavor_npc_01.tres" id="7"]

[resource]
script = ExtResource("1")
characters = [
	ExtResource("2"),
	ExtResource("3"),
	ExtResource("4"),
	ExtResource("5"),
	ExtResource("6"),
	ExtResource("7"),
]
````

---

## `resources/character_data/arnulf_hub.tres`

````
[gd_resource type="Resource" script_class="CharacterData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/character_data.gd" id="1"]

[resource]
script = ExtResource("1")
character_id = "COMPANION_MELEE"
display_name = "Arnulf Hub"
description = "TODO: description"
role = 4
portrait_id = "TODO_PORTRAIT"
icon_id = ""
hub_position_2d = Vector2(480, 0)
hub_marker_name_3d = ""
default_dialogue_tags = ["hub", "ally"]
````

---

## `resources/character_data/enchantress.tres`

````
[gd_resource type="Resource" script_class="CharacterData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/character_data.gd" id="1"]

[resource]
script = ExtResource("1")
character_id = "ENCHANTER"
display_name = "Enchantress"
description = "TODO: description"
role = 2
portrait_id = "TODO_PORTRAIT"
icon_id = ""
hub_position_2d = Vector2(240, 0)
hub_marker_name_3d = ""
default_dialogue_tags = ["hub", "enchant"]
````

---

## `resources/character_data/flavor_npc_01.tres`

````
[gd_resource type="Resource" script_class="CharacterData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/character_data.gd" id="1"]

[resource]
script = ExtResource("1")
character_id = "EXAMPLE_CHARACTER"
display_name = "Flavor NPC 01"
description = "TODO: description"
role = 5
portrait_id = "TODO_PORTRAIT"
icon_id = ""
hub_position_2d = Vector2(600, 0)
hub_marker_name_3d = ""
default_dialogue_tags = ["hub", "flavor"]
````

---

## `resources/character_data/mercenary_captain.tres`

````
[gd_resource type="Resource" script_class="CharacterData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/character_data.gd" id="1"]

[resource]
script = ExtResource("1")
character_id = "MERCENARY_COMMANDER"
display_name = "Mercenary Captain"
description = "TODO: description"
role = 3
portrait_id = "TODO_PORTRAIT"
icon_id = ""
hub_position_2d = Vector2(360, 0)
hub_marker_name_3d = ""
default_dialogue_tags = ["hub", "mercenary"]
````

---

## `resources/character_data/merchant.tres`

````
[gd_resource type="Resource" script_class="CharacterData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/character_data.gd" id="1"]

[resource]
script = ExtResource("1")
character_id = "MERCHANT"
display_name = "Merchant"
description = "TODO: description"
role = 0
portrait_id = "TODO_PORTRAIT"
icon_id = ""
hub_position_2d = Vector2(0, 0)
hub_marker_name_3d = ""
default_dialogue_tags = ["hub", "shop"]
````

---

## `resources/character_data/researcher.tres`

````
[gd_resource type="Resource" script_class="CharacterData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/character_data.gd" id="1"]

[resource]
script = ExtResource("1")
character_id = "SPELL_RESEARCHER"
display_name = "Researcher"
description = "TODO: description"
role = 1
portrait_id = "TODO_PORTRAIT"
icon_id = ""
hub_position_2d = Vector2(120, 0)
hub_marker_name_3d = ""
default_dialogue_tags = ["hub", "research"]
````

---

## `resources/dialogue/campaign_character_template/dialogue_campaign_character_template_generic_01.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "CAMPAIGN_CHARACTER_TEMPLATE_GENERIC_01"
character_id = "CAMPAIGN_CHARACTER_X"
text = "TODO: Template line for a future campaign-specific ally (placeholder)."
priority = 15
once_only = false
chain_next_id = ""
conditions = []
````

---

## `resources/dialogue/companion_melee/dialogue_companion_melee_arnulf_intro_01.tres`

````
[gd_resource type="Resource" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]
[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_condition.gd" id="2_cond"]

[sub_resource type="Resource" id="sub1"]
script = ExtResource("2_cond")
key = "current_mission_number"
comparison = ">="
value = 2

[sub_resource type="Resource" id="sub2"]
script = ExtResource("2_cond")
key = "current_gamestate"
comparison = "=="
value = "BETWEEN_MISSIONS"

[resource]
script = ExtResource("1_entry")
entry_id = "COMPANION_MELEE_ARNULF_INTRO_01"
character_id = "COMPANION_MELEE"
text = "TODO: Arnulf greets Florence in the between-mission hub."
priority = 80
once_only = true
chain_next_id = ""
conditions = [SubResource("sub1"), SubResource("sub2")]
````

---

## `resources/dialogue/companion_melee/dialogue_companion_melee_arnulf_research_01.tres`

````
[gd_resource type="Resource" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]
[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_condition.gd" id="2_cond"]

[sub_resource type="Resource" id="sub1"]
script = ExtResource("2_cond")
key = "arnulf_research_unlocked_any"
comparison = "=="
value = true

[resource]
script = ExtResource("1_entry")
entry_id = "COMPANION_MELEE_ARNULF_RESEARCH_01"
character_id = "COMPANION_MELEE"
text = "TODO: Arnulf reacts to new training or research upgrades affecting him."
priority = 85
once_only = false
chain_next_id = ""
conditions = [SubResource("sub1")]
````

---

## `resources/dialogue/companion_melee/dialogue_companion_melee_generic_01.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "COMPANION_MELEE_GENERIC_01"
character_id = "COMPANION_MELEE"
text = "TODO: Arnulf comments generally on combat and readiness."
priority = 20
once_only = false
chain_next_id = ""
conditions = []
````

---

## `resources/dialogue/enchanter/dialogue_enchanter_generic_01.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "ENCHANTER_GENERIC_01"
character_id = "ENCHANTER"
text = "TODO: Enchanter placeholder line about enchantments."
priority = 25
once_only = false
chain_next_id = ""
conditions = []
````

---

## `resources/dialogue/example_character/dialogue_example_character_chain_part_1.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "EXAMPLE_CHARACTER_CHAIN_PART_1"
character_id = "EXAMPLE_CHARACTER"
text = "TODO: Chain start — advance to part 2. # PLACEHOLDER"
priority = 70
once_only = false
chain_next_id = "EXAMPLE_CHARACTER_CHAIN_PART_2"
conditions = []
````

---

## `resources/dialogue/example_character/dialogue_example_character_chain_part_2.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "EXAMPLE_CHARACTER_CHAIN_PART_2"
character_id = "EXAMPLE_CHARACTER"
text = "TODO: Chain end — no further chain_next_id. # PLACEHOLDER"
priority = 70
once_only = false
chain_next_id = ""
conditions = []
````

---

## `resources/dialogue/example_character/dialogue_example_character_conditional_01.tres`

````
[gd_resource type="Resource" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]
[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_condition.gd" id="2_cond"]

[sub_resource type="Resource" id="sub1"]
script = ExtResource("2_cond")
key = "mission_won_count"
comparison = ">="
value = 1

[resource]
script = ExtResource("1_entry")
entry_id = "EXAMPLE_CHARACTER_CONDITIONAL_01"
character_id = "EXAMPLE_CHARACTER"
text = "TODO: Example numeric condition (mission_won_count >= 1). # PLACEHOLDER dev template."
priority = 50
once_only = false
chain_next_id = ""
conditions = [SubResource("sub1")]
````

---

## `resources/dialogue/florence/dialogue_florence_hub_intro_01.tres`

````
[gd_resource type="Resource" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]
[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_condition.gd" id="2_cond"]

[sub_resource type="Resource" id="sub1"]
script = ExtResource("2_cond")
key = "current_gamestate"
comparison = "=="
value = "BETWEEN_MISSIONS"

[resource]
script = ExtResource("1_entry")
entry_id = "FLORENCE_HUB_INTRO_01"
character_id = "FLORENCE"
text = "TODO: Florence reacts to being back at the hub between missions."
priority = 40
once_only = false
chain_next_id = ""
conditions = [SubResource("sub1")]
````

---

## `resources/dialogue/mercenary_commander/dialogue_mercenary_commander_generic_01.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "MERCENARY_COMMANDER_GENERIC_01"
character_id = "MERCENARY_COMMANDER"
text = "TODO: Mercenary commander placeholder line about roster and contracts."
priority = 25
once_only = false
chain_next_id = ""
conditions = []
````

---

## `resources/dialogue/merchant/dialogue_merchant_low_gold_01.tres`

````
[gd_resource type="Resource" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]
[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_condition.gd" id="2_cond"]

[sub_resource type="Resource" id="sub1"]
script = ExtResource("2_cond")
key = "gold_amount"
comparison = "<"
value = 100

[resource]
script = ExtResource("1_entry")
entry_id = "MERCHANT_LOW_GOLD_01"
character_id = "MERCHANT"
text = "TODO: Merchant comments when the player has little gold (placeholder tuning)."
priority = 60
once_only = false
chain_next_id = ""
conditions = [SubResource("sub1")]
````

---

## `resources/dialogue/spell_researcher/dialogue_spell_researcher_sybil_generic_01.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "SPELL_RESEARCHER_SYBIL_GENERIC_01"
character_id = "SPELL_RESEARCHER"
text = "TODO: Sybil makes a generic remark about spell theory and future upgrades."
priority = 20
once_only = false
chain_next_id = ""
conditions = []
````

---

## `resources/dialogue/spell_researcher/dialogue_spell_researcher_sybil_intro_01.tres`

````
[gd_resource type="Resource" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]
[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_condition.gd" id="2_cond"]

[sub_resource type="Resource" id="sub1"]
script = ExtResource("2_cond")
key = "current_mission_number"
comparison = ">="
value = 2

[sub_resource type="Resource" id="sub2"]
script = ExtResource("2_cond")
key = "current_gamestate"
comparison = "=="
value = "BETWEEN_MISSIONS"

[resource]
script = ExtResource("1_entry")
entry_id = "SPELL_RESEARCHER_SYBIL_INTRO_01"
character_id = "SPELL_RESEARCHER"
text = "TODO: Sybil greets Florence in the spell research screen and comments on early research."
priority = 90
once_only = true
chain_next_id = ""
conditions = [SubResource("sub1"), SubResource("sub2")]
````

---

## `resources/dialogue/spell_researcher/dialogue_spell_researcher_sybil_research_unlocked_01.tres`

````
[gd_resource type="Resource" load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]
[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_condition.gd" id="2_cond"]

[sub_resource type="Resource" id="sub1"]
script = ExtResource("2_cond")
key = "sybil_research_unlocked_any"
comparison = "=="
value = true

[resource]
script = ExtResource("1_entry")
entry_id = "SPELL_RESEARCHER_SYBIL_AFTER_UNLOCK_01"
character_id = "SPELL_RESEARCHER"
text = "TODO: Sybil comments on a newly unlocked spell research node."
priority = 80
once_only = false
chain_next_id = ""
conditions = [SubResource("sub1")]
````

---

## `resources/dialogue/weapons_engineer/dialogue_weapons_engineer_weapon_upgrade_hint_01.tres`

````
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/dialogue/dialogue_entry.gd" id="1_entry"]

[resource]
script = ExtResource("1_entry")
entry_id = "WEAPONS_ENGINEER_UPGRADE_HINT_01"
character_id = "WEAPONS_ENGINEER"
text = "TODO: Weapons Engineer hints at future weapon upgrades (placeholder)."
priority = 30
once_only = false
chain_next_id = ""
conditions = []
````

---

## `resources/enchantments/arcane_focus.tres`

````
[gd_resource type="Resource" script_class="EnchantmentData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enchantment_data.gd" id="1"]

[resource]
script = ExtResource("1")
enchantment_id = "arcane_focus"
display_name = "Arcane Focus"
description = "Bolts channel arcane power, excelling against heavy armor."
slot_type = "elemental"
has_damage_type_override = true
damage_type_override = 2
has_secondary_damage_type = false
secondary_damage_type = 0
damage_multiplier = 0.9
effect_tags = Array[String]([])
effect_data = {}
````

---

## `resources/enchantments/scorching_bolts.tres`

````
[gd_resource type="Resource" script_class="EnchantmentData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enchantment_data.gd" id="1"]

[resource]
script = ExtResource("1")
enchantment_id = "scorching_bolts"
display_name = "Scorching Bolts"
description = "Bolts are infused with flame, slightly increasing damage and changing type to fire."
slot_type = "elemental"
has_damage_type_override = true
damage_type_override = 1
has_secondary_damage_type = false
secondary_damage_type = 0
damage_multiplier = 1.2
effect_tags = Array[String]([])
effect_data = {}
````

---

## `resources/enchantments/sharpened_mechanism.tres`

````
[gd_resource type="Resource" script_class="EnchantmentData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enchantment_data.gd" id="1"]

[resource]
script = ExtResource("1")
enchantment_id = "sharpened_mechanism"
display_name = "Sharpened Mechanism"
description = "Improved gearing and sharpened tips increase bolt lethality."
slot_type = "power"
has_damage_type_override = false
damage_type_override = 0
has_secondary_damage_type = false
secondary_damage_type = 0
damage_multiplier = 1.3
effect_tags = Array[String]([])
effect_data = {}
````

---

## `resources/enchantments/toxic_payload.tres`

````
[gd_resource type="Resource" script_class="EnchantmentData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enchantment_data.gd" id="1"]

[resource]
script = ExtResource("1")
enchantment_id = "toxic_payload"
display_name = "Toxic Payload"
description = "Bolts carry a toxic payload, trading impact for lingering harm."
slot_type = "elemental"
has_damage_type_override = true
damage_type_override = 3
has_secondary_damage_type = false
secondary_damage_type = 0
damage_multiplier = 1.1
effect_tags = Array[String](["dot_poison"])
effect_data = {}
````

---

## `resources/enemy_data/bat_swarm.tres`

````
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
enemy_type = 5
display_name = "Bat Swarm"
max_hp = 40
move_speed = 5.0
damage = 8
attack_range = 1.0
attack_cooldown = 0.5
armor_type = 3
gold_reward = 8
is_ranged = false
is_flying = true
color = Color(0.3, 0.0, 0.5, 1.0)
damage_immunities = []
````

---

## `resources/enemy_data/goblin_firebug.tres`

````
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
enemy_type = 2
display_name = "Goblin Firebug"
max_hp = 60
move_speed = 4.0
damage = 20
attack_range = 1.2
attack_cooldown = 0.8
armor_type = 0
gold_reward = 15
is_ranged = false
is_flying = false
color = Color(0.9, 0.4, 0.0, 1.0)
damage_immunities = [1]
````

---

## `resources/enemy_data/orc_archer.tres`

````
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
enemy_type = 4
display_name = "Orc Archer"
max_hp = 70
move_speed = 2.5
damage = 18
attack_range = 10.0
attack_cooldown = 2.0
armor_type = 0
gold_reward = 20
is_ranged = true
is_flying = false
color = Color(0.3, 0.5, 0.0, 1.0)
damage_immunities = []
````

---

## `resources/enemy_data/orc_brute.tres`

````
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
enemy_type = 1
display_name = "Orc Brute"
max_hp = 200
move_speed = 2.0
damage = 30
attack_range = 1.5
attack_cooldown = 1.5
armor_type = 1
gold_reward = 25
is_ranged = false
is_flying = false
color = Color(0.1, 0.4, 0.0, 1.0)
damage_immunities = []
````

---

## `resources/enemy_data/orc_grunt.tres`

````
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
enemy_type = 0
display_name = "Orc Grunt"
max_hp = 80
move_speed = 3.0
damage = 15
attack_range = 1.5
attack_cooldown = 1.2
armor_type = 0
gold_reward = 10
is_ranged = false
is_flying = false
color = Color(0.2, 0.6, 0.1, 1.0)
damage_immunities = []
````

---

## `resources/enemy_data/plague_zombie.tres`

````
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/enemy_data.gd" id="1"]

[resource]
script = ExtResource("1")
enemy_type = 3
display_name = "Plague Zombie"
max_hp = 120
move_speed = 1.5
damage = 12
attack_range = 1.5
attack_cooldown = 2.0
armor_type = 2
gold_reward = 12
is_ranged = false
is_flying = false
color = Color(0.5, 0.7, 0.2, 1.0)
damage_immunities = [3]
````

---

## `resources/faction_data_default_mixed.tres`

````
[gd_resource type="Resource" script_class="FactionData" load_steps=9 format=3]

[ext_resource type="Script" path="res://scripts/resources/faction_data.gd" id="1_faction"]
[ext_resource type="Script" path="res://scripts/resources/faction_roster_entry.gd" id="2_roster"]

[sub_resource type="Resource" id="Roster_0"]
script = ExtResource("2_roster")
enemy_type = 0
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_1"]
script = ExtResource("2_roster")
enemy_type = 1
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_2"]
script = ExtResource("2_roster")
enemy_type = 2
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_3"]
script = ExtResource("2_roster")
enemy_type = 3
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_4"]
script = ExtResource("2_roster")
enemy_type = 4
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_5"]
script = ExtResource("2_roster")
enemy_type = 5
base_weight = 1.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[resource]
script = ExtResource("1_faction")
faction_id = "DEFAULT_MIXED"
display_name = "Default Mixed"
description = "PLACEHOLDER: MVP-style mixed enemy roster."
roster = [SubResource("Roster_0"), SubResource("Roster_1"), SubResource("Roster_2"), SubResource("Roster_3"), SubResource("Roster_4"), SubResource("Roster_5")]
mini_boss_ids = []
mini_boss_wave_hints = []
roster_tier = 1
difficulty_offset = 0.0
````

---

## `resources/faction_data_orc_raiders.tres`

````
[gd_resource type="Resource" script_class="FactionData" load_steps=7 format=3]

[ext_resource type="Script" path="res://scripts/resources/faction_data.gd" id="1_faction"]
[ext_resource type="Script" path="res://scripts/resources/faction_roster_entry.gd" id="2_roster"]

[sub_resource type="Resource" id="Roster_grunt"]
script = ExtResource("2_roster")
enemy_type = 0
base_weight = 4.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_archer"]
script = ExtResource("2_roster")
enemy_type = 4
base_weight = 3.0
min_wave_index = 2
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_brute"]
script = ExtResource("2_roster")
enemy_type = 1
base_weight = 2.0
min_wave_index = 3
max_wave_index = 10
tier = 2

[sub_resource type="Resource" id="Roster_bats"]
script = ExtResource("2_roster")
enemy_type = 5
base_weight = 1.0
min_wave_index = 4
max_wave_index = 10
tier = 2

[resource]
script = ExtResource("1_faction")
faction_id = "ORC_RAIDERS"
display_name = "Orc Raiders"
description = "PLACEHOLDER: Orc warbands and supporting beasts."
roster = [SubResource("Roster_grunt"), SubResource("Roster_archer"), SubResource("Roster_brute"), SubResource("Roster_bats")]
mini_boss_ids = Array[String](["orc_warlord"])
mini_boss_wave_hints = Array[int]([5, 10])
roster_tier = 2
difficulty_offset = 0.0
````

---

## `resources/faction_data_plague_cult.tres`

````
[gd_resource type="Resource" script_class="FactionData" load_steps=6 format=3]

[ext_resource type="Script" path="res://scripts/resources/faction_data.gd" id="1_faction"]
[ext_resource type="Script" path="res://scripts/resources/faction_roster_entry.gd" id="2_roster"]

[sub_resource type="Resource" id="Roster_zombie"]
script = ExtResource("2_roster")
enemy_type = 3
base_weight = 4.0
min_wave_index = 1
max_wave_index = 10
tier = 1

[sub_resource type="Resource" id="Roster_firebug"]
script = ExtResource("2_roster")
enemy_type = 2
base_weight = 3.0
min_wave_index = 2
max_wave_index = 10
tier = 2

[sub_resource type="Resource" id="Roster_bats"]
script = ExtResource("2_roster")
enemy_type = 5
base_weight = 2.0
min_wave_index = 3
max_wave_index = 10
tier = 2

[resource]
script = ExtResource("1_faction")
faction_id = "PLAGUE_CULT"
display_name = "Plague Cult"
description = "PLACEHOLDER: Rotting hordes and fire-obsessed fanatics."
roster = [SubResource("Roster_zombie"), SubResource("Roster_firebug"), SubResource("Roster_bats")]
mini_boss_ids = Array[String](["plague_cult_miniboss"])
mini_boss_wave_hints = Array[int]([4, 9])
roster_tier = 2
difficulty_offset = 0.0
````

---

## `resources/mercenary_catalog.tres`

````
[gd_resource type="Resource" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/resources/mercenary_catalog.gd" id="1_cat"]
[ext_resource type="Resource" path="res://resources/mercenary_offers/offer_hired_archer.tres" id="2_o1"]
[ext_resource type="Resource" path="res://resources/mercenary_offers/offer_anti_air_scout.tres" id="3_o2"]

[resource]
script = ExtResource("1_cat")
offers = [ExtResource("2_o1"), ExtResource("3_o2")]
max_offers_per_day = 3
````

---

## `resources/mercenary_offers/offer_anti_air_scout.tres`

````
[gd_resource type="Resource" script_class="MercenaryOfferData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/mercenary_offer_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "anti_air_scout"
cost_gold = 120
cost_building_material = 0
cost_research_material = 1
min_day = 2
max_day = -1
is_defection_offer = false
````

---

## `resources/mercenary_offers/offer_hired_archer.tres`

````
[gd_resource type="Resource" script_class="MercenaryOfferData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/mercenary_offer_data.gd" id="1"]

[resource]
script = ExtResource("1")
ally_id = "hired_archer"
cost_gold = 80
cost_building_material = 2
cost_research_material = 0
min_day = 1
max_day = -1
is_defection_offer = false
````

---

## `resources/miniboss_data/orc_captain_mini_boss.tres`

````
[gd_resource type="Resource" script_class="MiniBossData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/mini_boss_data.gd" id="1"]

[resource]
script = ExtResource("1")
boss_id = "orc_captain"
display_name = "Orc Captain"
appears_on_day = 5
max_hp = 800
gold_reward = 120
can_defect_to_ally = true
defected_ally_id = "defected_orc_captain"
defection_cost_gold = 0
defection_day_offset = 0
````

---

## `resources/research_data/arrow_tower_plus_damage.tres`

````
[gd_resource type="Resource" script_class="ResearchNodeData" format=3]

[ext_resource type="Script" path="res://scripts/resources/research_node_data.gd" id="1_researchnodedata"]

[resource]
script = ExtResource("1_researchnodedata")
node_id = "arrow_tower_plus_damage"
display_name = "Arrow Tower +Damage"
research_cost = 1
prerequisite_ids = []
description = "Arrow Tower uses upgraded damage tier without building upgrade"
````

---

## `resources/research_data/base_structures_tree.tres`

````
[gd_resource type="Resource" script_class="ResearchNodeData" format=3]

[ext_resource type="Script" path="res://scripts/resources/research_node_data.gd" id="1_researchnodedata"]

[resource]
script = ExtResource("1_researchnodedata")
node_id = "unlock_ballista"
display_name = "Ballista"
research_cost = 2
prerequisite_ids = []
description = "Unlock the Ballista building"
````

---

## `resources/research_data/fire_brazier_plus_range.tres`

````
[gd_resource type="Resource" script_class="ResearchNodeData" format=3]

[ext_resource type="Script" path="res://scripts/resources/research_node_data.gd" id="1_researchnodedata"]

[resource]
script = ExtResource("1_researchnodedata")
node_id = "fire_brazier_plus_range"
display_name = "Fire Brazier +Range"
research_cost = 1
prerequisite_ids = []
description = "Fire Brazier uses upgraded range tier without building upgrade"
````

---

## `resources/research_data/unlock_anti_air.tres`

````
[gd_resource type="Resource" script_class="ResearchNodeData" format=3]

[ext_resource type="Script" path="res://scripts/resources/research_node_data.gd" id="1_researchnodedata"]

[resource]
script = ExtResource("1_researchnodedata")
node_id = "unlock_anti_air"
display_name = "Anti-Air Bolt"
research_cost = 2
prerequisite_ids = []
description = "Unlock the Anti-Air Bolt building"
````

---

## `resources/research_data/unlock_archer_barracks.tres`

````
[gd_resource type="Resource" script_class="ResearchNodeData" format=3]

[ext_resource type="Script" path="res://scripts/resources/research_node_data.gd" id="1_researchnodedata"]

[resource]
script = ExtResource("1_researchnodedata")
node_id = "unlock_archer_barracks"
display_name = "Archer Barracks"
research_cost = 3
prerequisite_ids = []
description = "Unlock the Archer Barracks building"
````

---

## `resources/research_data/unlock_shield_generator.tres`

````
[gd_resource type="Resource" script_class="ResearchNodeData" format=3]

[ext_resource type="Script" path="res://scripts/resources/research_node_data.gd" id="1_researchnodedata"]

[resource]
script = ExtResource("1_researchnodedata")
node_id = "unlock_shield_generator"
display_name = "Shield Generator"
research_cost = 3
prerequisite_ids = []
description = "Unlock the Shield Generator building"
````

---

## `resources/shop_data/shop_catalog.tres`

````
[gd_resource type="Resource" format=3]

[ext_resource type="Script" path="res://scripts/resources/shop_item_data.gd" id="1_shopitemdata"]

[sub_resource type="Resource" id="ShopItem_tower_repair"]
script = ExtResource("1_shopitemdata")
item_id = "tower_repair"
display_name = "Tower Repair Kit"
gold_cost = 50
material_cost = 0
description = "Restore tower to full HP"

[sub_resource type="Resource" id="ShopItem_mana_draught"]
script = ExtResource("1_shopitemdata")
item_id = "mana_draught"
display_name = "Mana Draught"
gold_cost = 20
material_cost = 0
description = "Start next mission at full mana"

[resource]
````

---

## `resources/shop_data/shop_item_arrow_tower.tres`

````
[gd_resource type="Resource" format=3]

[ext_resource type="Script" path="res://scripts/resources/shop_item_data.gd" id="1_shopitemdata"]

[resource]
script = ExtResource("1_shopitemdata")
item_id = "arrow_tower_placed"
display_name = "Arrow Tower (placed)"
gold_cost = 40
material_cost = 2
description = "Auto-place an Arrow Tower on the first empty hex next mission"
````

---

## `resources/shop_data/shop_item_building_repair.tres`

````
[gd_resource type="Resource" format=3]

[ext_resource type="Script" path="res://scripts/resources/shop_item_data.gd" id="1_shopitemdata"]

[resource]
script = ExtResource("1_shopitemdata")
item_id = "building_repair"
display_name = "Building Repair Kit"
gold_cost = 30
material_cost = 0
description = "Restore one building to full HP"
````

---

## `resources/shop_data/shop_item_mana_draught.tres`

````
[gd_resource type="Resource" format=3]

[ext_resource type="Script" path="res://scripts/resources/shop_item_data.gd" id="1_shopitemdata"]

[resource]
script = ExtResource("1_shopitemdata")
item_id = "mana_draught"
display_name = "Mana Draught"
gold_cost = 20
material_cost = 0
description = "Start next mission at full mana"
````

---

## `resources/shop_data/shop_item_tower_repair.tres`

````
[gd_resource type="Resource" format=3]

[ext_resource type="Script" path="res://scripts/resources/shop_item_data.gd" id="1_shopitemdata"]

[resource]
script = ExtResource("1_shopitemdata")
item_id = "tower_repair"
display_name = "Tower Repair Kit"
gold_cost = 50
material_cost = 0
description = "Restore tower to full HP"
````

---

## `resources/spell_data/shockwave.tres`

````
[gd_resource type="Resource" script_class="SpellData" format=3]

; shockwave.tres — Shockwave spell data resource for FOUL WARD.
; Ground-only magical AoE — hits all non-flying enemies on the battlefield.
;
; Credit: Foul Ward SYSTEMS_part3.md §9.2 and CONVENTIONS.md §4.4
;   Internal project document — Foul Ward team.

[ext_resource type="Script" path="res://scripts/resources/spell_data.gd" id="1_spell_data"]

[resource]
script = ExtResource("1_spell_data")
spell_id = "shockwave"
display_name = "Shockwave"
mana_cost = 50
cooldown = 60.0
damage = 30.0
radius = 100.0
; Types.DamageType.MAGICAL = 2
damage_type = 2
hits_flying = false
````

---

## `resources/strategyprofiles/strategy_balanced_default.tres`

````
[gd_resource type="Resource" script_class="StrategyProfile" format=3]

[ext_resource type="Script" path="res://scripts/resources/strategyprofile.gd" id="1_strategyprofile"]

[resource]
script = ExtResource("1_strategyprofile")

profile_id = "BALANCED_DEFAULT"
description = "Balanced profile: mix of all building types, moderate spell usage."

build_priorities = [
	{"building_type": 0, "weight": 1.0, "min_wave": 1, "max_wave": 10},
	{"building_type": 1, "weight": 0.9, "min_wave": 2, "max_wave": 10},
	{"building_type": 2, "weight": 0.9, "min_wave": 3, "max_wave": 10},
	{"building_type": 3, "weight": 0.8, "min_wave": 1, "max_wave": 10},
	{"building_type": 4, "weight": 0.7, "min_wave": 3, "max_wave": 10},
	{"building_type": 5, "weight": 0.6, "min_wave": 2, "max_wave": 10},
	{"building_type": 6, "weight": 0.6, "min_wave": 4, "max_wave": 10},
	{"building_type": 7, "weight": 0.5, "min_wave": 4, "max_wave": 10}
]

placement_preferences = {
	"preferred_slots": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "INNER_FIRST",
}

spell_usage = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 8,
	"min_mana": 50,
	"cooldown_safety_margin": 0.5,
	"evaluation_interval": 1.0,
	"priority_vs_building": 1.0,
}

upgrade_behavior = {
	"prefer_upgrades_until_build_count": 6,
	"upgrade_weight": 1.0,
	"min_gold_reserve": 50,
	"max_upgrade_level": 1,
}

difficulty_target = 0.0
````

---

## `resources/strategyprofiles/strategy_greedy_econ.tres`

````
[gd_resource type="Resource" script_class="StrategyProfile" format=3]

[ext_resource type="Script" path="res://scripts/resources/strategyprofile.gd" id="1_strategyprofile"]

[resource]
script = ExtResource("1_strategyprofile")

profile_id = "GREEDY_ECON"
description = "Greedy econ: prioritize cheap/early towers, fewer upgrades and spells."

build_priorities = [
	{"building_type": 0, "weight": 1.2, "min_wave": 1, "max_wave": 10},
	{"building_type": 3, "weight": 1.0, "min_wave": 2, "max_wave": 10},
	{"building_type": 5, "weight": 0.8, "min_wave": 2, "max_wave": 10},
	{"building_type": 1, "weight": 0.5, "min_wave": 3, "max_wave": 10},
	{"building_type": 2, "weight": 0.4, "min_wave": 4, "max_wave": 10},
	{"building_type": 4, "weight": 0.3, "min_wave": 4, "max_wave": 10},
	{"building_type": 6, "weight": 0.3, "min_wave": 4, "max_wave": 10},
	{"building_type": 7, "weight": 0.3, "min_wave": 4, "max_wave": 10}
]

placement_preferences = {
	"preferred_slots": [0, 1, 2, 3, 4, 5],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "INNER_FIRST",
}

spell_usage = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 10,
	"min_mana": 70,
	"cooldown_safety_margin": 1.0,
	"evaluation_interval": 1.5,
	"priority_vs_building": 0.5,
}

upgrade_behavior = {
	"prefer_upgrades_until_build_count": 10,
	"upgrade_weight": 0.7,
	"min_gold_reserve": 0,
	"max_upgrade_level": 1,
}

difficulty_target = 0.0
````

---

## `resources/strategyprofiles/strategy_heavy_fire.tres`

````
[gd_resource type="Resource" script_class="StrategyProfile" format=3]

[ext_resource type="Script" path="res://scripts/resources/strategyprofile.gd" id="1_strategyprofile"]

[resource]
script = ExtResource("1_strategyprofile")

profile_id = "HEAVY_FIRE"
description = "Heavy fire: prioritize FireBrazier/Ballista/MagicObelisk, aggressive Shockwave."

build_priorities = [
	{"building_type": 0, "weight": 0.7, "min_wave": 1, "max_wave": 10},
	{"building_type": 1, "weight": 1.2, "min_wave": 2, "max_wave": 10},
	{"building_type": 2, "weight": 1.1, "min_wave": 3, "max_wave": 10},
	{"building_type": 4, "weight": 1.0, "min_wave": 3, "max_wave": 10},
	{"building_type": 3, "weight": 0.5, "min_wave": 2, "max_wave": 10},
	{"building_type": 5, "weight": 0.4, "min_wave": 2, "max_wave": 10},
	{"building_type": 6, "weight": 0.7, "min_wave": 4, "max_wave": 10},
	{"building_type": 7, "weight": 0.3, "min_wave": 4, "max_wave": 10}
]

placement_preferences = {
	"preferred_slots": [6, 7, 8, 9, 10, 11, 12, 13],
	"fallback_strategy": "FIRST_EMPTY",
	"ring_hint": "OUTER_FIRST",
}

spell_usage = {
	"enabled": true,
	"spell_id": "shockwave",
	"min_enemies_in_wave": 6,
	"min_mana": 40,
	"cooldown_safety_margin": 0.25,
	"evaluation_interval": 0.75,
	"priority_vs_building": 1.2,
}

upgrade_behavior = {
	"prefer_upgrades_until_build_count": 4,
	"upgrade_weight": 1.3,
	"min_gold_reserve": 50,
	"max_upgrade_level": 1,
}

difficulty_target = 0.0
````

---

## `resources/territories/main_campaign_territories.tres`

````
; main_campaign_territories.tres — TerritoryMapData for main 50-day campaign.
; # PLACEHOLDER / # TUNING: names, bonuses, descriptions.

[gd_resource type="Resource" script_class="TerritoryMapData" load_steps=8 format=3 uid="uid://bwmcterrmap01"]

[ext_resource type="Script" path="res://scripts/resources/territory_map_data.gd" id="1_tmap"]
[ext_resource type="Script" path="res://scripts/resources/territory_data.gd" id="2_terr"]

[sub_resource type="Resource" id="Territory_heartland"]
script = ExtResource("2_terr")
territory_id = "heartland_plains"
display_name = "Heartland Plains"
description = "Central breadbasket region. # PLACEHOLDER # TUNING"
icon_id = "plains_icon"
color = Color(0.75, 0.85, 0.55, 1)
terrain_type = 0
is_controlled_by_player = true
is_permanently_lost = false
threat_level = 0
is_under_attack = false
bonus_flat_gold_end_of_day = 5
bonus_percent_gold_end_of_day = 0.0
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_blackwood"]
script = ExtResource("2_terr")
territory_id = "blackwood_forest"
display_name = "Blackwood Forest"
description = "Dense woods. # PLACEHOLDER # TUNING"
icon_id = "forest_icon"
color = Color(0.2, 0.45, 0.22, 1)
terrain_type = 1
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 1
is_under_attack = false
bonus_flat_gold_end_of_day = 3
bonus_percent_gold_end_of_day = 0.05
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_ashen"]
script = ExtResource("2_terr")
territory_id = "ashen_swamp"
display_name = "Ashen Swamp"
description = "Miasmic wetlands. # PLACEHOLDER # TUNING"
icon_id = "swamp_icon"
color = Color(0.35, 0.4, 0.38, 1)
terrain_type = 2
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 2
is_under_attack = false
bonus_flat_gold_end_of_day = 0
bonus_percent_gold_end_of_day = 0.12
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_iron"]
script = ExtResource("2_terr")
territory_id = "iron_ridge"
display_name = "Iron Ridge"
description = "Highland mines. # PLACEHOLDER # TUNING"
icon_id = "mountain_icon"
color = Color(0.55, 0.5, 0.48, 1)
terrain_type = 3
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 2
is_under_attack = false
bonus_flat_gold_end_of_day = 15
bonus_percent_gold_end_of_day = 0.0
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[sub_resource type="Resource" id="Territory_outer"]
script = ExtResource("2_terr")
territory_id = "outer_city"
display_name = "Outer City"
description = "Walled outskirts. # PLACEHOLDER # TUNING"
icon_id = "city_icon"
color = Color(0.65, 0.62, 0.7, 1)
terrain_type = 4
is_controlled_by_player = false
is_permanently_lost = false
threat_level = 3
is_under_attack = false
bonus_flat_gold_end_of_day = 12
bonus_percent_gold_end_of_day = 0.0
bonus_flat_gold_per_kill = 0
bonus_research_per_day = 0
bonus_research_cost_multiplier = 1.0
bonus_enchanting_cost_multiplier = 1.0
bonus_weapon_upgrade_cost_multiplier = 1.0

[resource]
script = ExtResource("1_tmap")
territories = [SubResource("Territory_heartland"), SubResource("Territory_blackwood"), SubResource("Territory_ashen"), SubResource("Territory_iron"), SubResource("Territory_outer")]
````

---

## `resources/weapon_data/crossbow.tres`

````
[gd_resource type="Resource" script_class="WeaponData" format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_data.gd" id="1_weapondata"]

[resource]
script = ExtResource("1_weapondata")
weapon_slot = 0
display_name = "Crossbow"
damage = 50.0
projectile_speed = 30.0
reload_time = 2.5
burst_count = 1
burst_interval = 0.0
can_target_flying = false
assist_angle_degrees = 7.5
assist_max_distance = 0.0
base_miss_chance = 0.05
max_miss_angle_degrees = 2.0
````

---

## `resources/weapon_data/rapid_missile.tres`

````
[gd_resource type="Resource" script_class="WeaponData" format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_data.gd" id="1_weapondata"]

[resource]
script = ExtResource("1_weapondata")
weapon_slot = 1
display_name = "Rapid Missile"
damage = 8.0
projectile_speed = 40.0
reload_time = 4.0
burst_count = 10
burst_interval = 0.05
can_target_flying = false
assist_angle_degrees = 0.0
assist_max_distance = 0.0
base_miss_chance = 0.0
max_miss_angle_degrees = 0.0
````

---

## `resources/weapon_level_data/crossbow_level_1.tres`

````
[gd_resource type="Resource" script_class="WeaponLevelData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_level_data.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_slot = 0
level = 1
damage_bonus = 10.0
speed_bonus = 5.0
reload_bonus = -0.2
burst_count_bonus = 0
gold_cost = 100
material_cost = 0
````

---

## `resources/weapon_level_data/crossbow_level_2.tres`

````
[gd_resource type="Resource" script_class="WeaponLevelData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_level_data.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_slot = 0
level = 2
damage_bonus = 15.0
speed_bonus = 5.0
reload_bonus = -0.2
burst_count_bonus = 0
gold_cost = 200
material_cost = 0
````

---

## `resources/weapon_level_data/crossbow_level_3.tres`

````
[gd_resource type="Resource" script_class="WeaponLevelData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_level_data.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_slot = 0
level = 3
damage_bonus = 20.0
speed_bonus = 5.0
reload_bonus = -0.2
burst_count_bonus = 0
gold_cost = 350
material_cost = 0
````

---

## `resources/weapon_level_data/rapid_missile_level_1.tres`

````
[gd_resource type="Resource" script_class="WeaponLevelData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_level_data.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_slot = 1
level = 1
damage_bonus = 3.0
speed_bonus = 5.0
reload_bonus = -0.2
burst_count_bonus = 2
gold_cost = 80
material_cost = 0
````

---

## `resources/weapon_level_data/rapid_missile_level_2.tres`

````
[gd_resource type="Resource" script_class="WeaponLevelData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_level_data.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_slot = 1
level = 2
damage_bonus = 4.0
speed_bonus = 5.0
reload_bonus = -0.2
burst_count_bonus = 2
gold_cost = 160
material_cost = 0
````

---

## `resources/weapon_level_data/rapid_missile_level_3.tres`

````
[gd_resource type="Resource" script_class="WeaponLevelData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/resources/weapon_level_data.gd" id="1"]

[resource]
script = ExtResource("1")
weapon_slot = 1
level = 3
damage_bonus = 5.0
speed_bonus = 5.0
reload_bonus = -0.2
burst_count_bonus = 2
gold_cost = 300
material_cost = 0
````
