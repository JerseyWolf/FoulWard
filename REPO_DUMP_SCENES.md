# REPO_DUMP — Scenes (`.tscn`)

Split from `REPO_DUMP_AFTER_PROMPTS_1_17.md.md`. Sections are unchanged from the original dump format.

---

## `scenes/allies/ally_base.tscn`

````
[gd_scene load_steps=8 format=3 uid="uid://ally_base_scene"]

; AllyBase — generic ally placeholder (layer 3 friendly, mask ground for CharacterBody3D).
; DetectionArea / AttackArea: mask layer 2 (Enemies).

[ext_resource type="Script" path="res://scenes/allies/ally_base.gd" id="1_ally"]
[ext_resource type="Script" path="res://scripts/health_component.gd" id="2_health"]

[sub_resource type="BoxMesh" id="1_mesh"]
size = Vector3(0.9, 1.2, 0.9)

[sub_resource type="StandardMaterial3D" id="mat_ally"]
albedo_color = Color(0.2, 0.45, 0.95, 1)

[sub_resource type="BoxShape3D" id="2_collision"]
size = Vector3(0.9, 1.2, 0.9)

[sub_resource type="SphereShape3D" id="3_detection_shape"]
radius = 40.0

[sub_resource type="SphereShape3D" id="4_attack_shape"]
radius = 2.0

[node name="AllyBase" type="CharacterBody3D"]
collision_layer = 4
collision_mask = 32
script = ExtResource("1_ally")

[node name="AllyMesh" type="MeshInstance3D" parent="."]
mesh = SubResource("1_mesh")
material_override = SubResource("mat_ally")

[node name="AllyCollision" type="CollisionShape3D" parent="."]
shape = SubResource("2_collision")

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("2_health")

[node name="NavigationAgent3D" type="NavigationAgent3D" parent="."]
path_desired_distance = 0.5
target_desired_distance = 0.75
avoidance_enabled = true
radius = 0.5

[node name="DetectionArea" type="Area3D" parent="."]
collision_layer = 0
collision_mask = 2
monitoring = true
monitorable = false

[node name="DetectionShape" type="CollisionShape3D" parent="DetectionArea"]
shape = SubResource("3_detection_shape")

[node name="AttackArea" type="Area3D" parent="."]
collision_layer = 0
collision_mask = 2
monitoring = true
monitorable = false

[node name="AttackShape" type="CollisionShape3D" parent="AttackArea"]
shape = SubResource("4_attack_shape")
````

---

## `scenes/arnulf/arnulf.tscn`

````
[gd_scene load_steps=10 format=3 uid="uid://arnulf_scene"]

; arnulf.tscn — Arnulf AI melee companion scene for FOUL WARD.
; Scene tree matches ARCHITECTURE.md §2.
;
; Collision layers (CONVENTIONS.md §16):
;   Arnulf CharacterBody3D : collision_layer = 4 (Layer 3, bitmask bit 2)
;   DetectionArea           : collision_mask  = 2 (Layer 2 = Enemies)
;   AttackArea              : collision_mask  = 2 (Layer 2 = Enemies)

[ext_resource type="Script" path="res://scenes/arnulf/arnulf.gd" id="1_arnulf"]
[ext_resource type="Script" path="res://scripts/health_component.gd" id="2_health"]
[ext_resource type="Mesh" path="res://art/meshes/allies/ally_arnulf.tres" id="3_arnulf_mesh"]
[ext_resource type="Material" path="res://art/materials/factions/faction_allies_material.tres" id="4_allies_faction_mat"]

[sub_resource type="BoxMesh" id="1_mesh"]
size = Vector3(1.0, 1.5, 1.0)

[sub_resource type="BoxShape3D" id="2_collision"]
size = Vector3(1.0, 1.5, 1.0)

[sub_resource type="SphereShape3D" id="3_detection_shape"]
radius = 55.0

[sub_resource type="SphereShape3D" id="4_attack_shape"]
radius = 3.5

[node name="Arnulf" type="CharacterBody3D"]
script = ExtResource("1_arnulf")
collision_layer = 4
collision_mask = 0

[node name="ArnulfMesh" type="MeshInstance3D" parent="."]
mesh = ExtResource("3_arnulf_mesh")
material_override = ExtResource("4_allies_faction_mat")

[node name="ArnulfCollision" type="CollisionShape3D" parent="."]
shape = SubResource("2_collision")

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("2_health")

[node name="NavigationAgent3D" type="NavigationAgent3D" parent="."]
path_desired_distance = 1.0
target_desired_distance = 1.5
avoidance_enabled = true
radius = 0.5

[node name="DetectionArea" type="Area3D" parent="."]
collision_layer = 0
collision_mask = 2
monitoring = true
monitorable = false

[node name="DetectionShape" type="CollisionShape3D" parent="DetectionArea"]
shape = SubResource("3_detection_shape")

[node name="AttackArea" type="Area3D" parent="."]
collision_layer = 0
collision_mask = 2
monitoring = true
monitorable = false

[node name="AttackShape" type="CollisionShape3D" parent="AttackArea"]
shape = SubResource("4_attack_shape")

[node name="ArnulfLabel" type="Label3D" parent="."]
text = "ARNULF"
position = Vector3(0, 1.5, 0)
pixel_size = 0.01
billboard = 2
````

---

## `scenes/bosses/boss_base.tscn`

````
[gd_scene load_steps=8 format=3 uid="uid://bossbasefoulward01"]

[ext_resource type="Script" path="res://scenes/bosses/boss_base.gd" id="1"]
[ext_resource type="Script" path="res://scripts/health_component.gd" id="3"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_boss"]
radius = 0.55
height = 1.2

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_boss"]
albedo_color = Color(0.55, 0.15, 0.65, 1)

[sub_resource type="BoxMesh" id="BoxMesh_boss"]
size = Vector3(1.1, 1.1, 1.1)

[node name="BossBase" type="CharacterBody3D" groups=["enemies"]]
collision_layer = 2
collision_mask = 45
script = ExtResource("1")

[node name="BossMesh" type="MeshInstance3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)
mesh = SubResource("BoxMesh_boss")
material_override = SubResource("StandardMaterial3D_boss")

[node name="BossCollision" type="CollisionShape3D" parent="."]
shape = SubResource("CapsuleShape3D_boss")

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("3")

[node name="NavigationAgent3D" type="NavigationAgent3D" parent="."]
target_position = Vector3(0, 0, 0)
target_desired_distance = 2.0
path_desired_distance = 0.5
avoidance_enabled = true
radius = 0.55
neighbor_distance = 5.0
time_horizon_agents = 2.0
max_speed = 0.0

[node name="BossLabel" type="Label3D" parent="."]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.75, 0)
text = "Boss"
font_size = 48
````

---

## `scenes/buildings/building_base.tscn`

````
[gd_scene load_steps=8 format=3 uid="uid://building_base"]

[ext_resource type="Script" path="res://scenes/buildings/building_base.gd" id="1_buildingbase"]
[ext_resource type="Script" path="res://scripts/health_component.gd" id="2_healthcomponent"]
[ext_resource type="Mesh" path="res://art/meshes/misc/unknown_mesh.tres" id="3_unknown_mesh"]

[sub_resource type="BoxMesh" id="BoxMesh_building"]
size = Vector3(1.5, 3.0, 1.5)

[sub_resource type="StandardMaterial3D" id="BuildingMat"]
albedo_color = Color(0.5, 0.5, 0.5, 1.0)

[sub_resource type="BoxShape3D" id="BoxShapeBuilding"]
size = Vector3(2.5, 3, 2.5)

[node name="BuildingBase" type="Node3D"]
script = ExtResource("1_buildingbase")

[node name="BuildingMesh" type="MeshInstance3D" parent="."]
position = Vector3(0, 1.5, 0)
mesh = ExtResource("3_unknown_mesh")

[node name="BuildingLabel" type="Label3D" parent="."]
position = Vector3(0, 3.5, 0)
pixel_size = 0.01
text = "Building"
font_size = 48

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("2_healthcomponent")
max_hp = 200

[node name="BuildingCollision" type="StaticBody3D" parent="."]
collision_layer = 8
collision_mask = 2

[node name="CollisionShape3D" type="CollisionShape3D" parent="BuildingCollision"]
shape = SubResource("BoxShapeBuilding")

[node name="NavigationObstacle" type="NavigationObstacle3D" parent="."]
avoidance_enabled = true
affect_navigation_mesh = false
radius = 2.0
````

---

## `scenes/enemies/enemy_base.tscn`

````
[gd_scene load_steps=10 format=3]

[ext_resource type="Script" path="res://scenes/enemies/enemy_base.gd" id="1"]
[ext_resource type="Script" path="res://scripts/health_component.gd" id="3"]
[ext_resource type="Mesh" path="res://art/meshes/enemies/enemy_orc_grunt.tres" id="4_enemy_mesh"]
[ext_resource type="Material" path="res://art/materials/factions/faction_orcs_material.tres" id="5_enemy_mat"]

[sub_resource type="CapsuleShape3D" id="1"]
radius = 0.5
height = 1.0

[sub_resource type="StandardMaterial3D" id="2"]
albedo_color = Color(0.4, 0.8, 0.4, 1.0)

[sub_resource type="BoxMesh" id="4"]
size = Vector3(0.9, 0.9, 0.9)

[node name="EnemyBase" type="CharacterBody3D"]
script = ExtResource("1")
collision_layer = 2
collision_mask = 45

[node name="EnemyMesh" type="MeshInstance3D" parent="."]
mesh = ExtResource("4_enemy_mesh")
material_override = ExtResource("5_enemy_mat")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)

[node name="EnemyCollision" type="CollisionShape3D" parent="."]
shape = SubResource("1")

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("3")

[node name="NavigationAgent3D" type="NavigationAgent3D" parent="."]
target_position = Vector3(0, 0, 0)
target_desired_distance = 1.5
path_desired_distance = 0.5
avoidance_enabled = true
radius = 0.5
neighbor_distance = 5.0
time_horizon_agents = 2.0
max_speed = 0.0

[node name="EnemyLabel" type="Label3D" parent="."]
text = "Enemy"
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)
````

---

## `scenes/hex_grid/hex_grid.tscn`

````
[gd_scene load_steps=6 format=3 uid="uid://hex_grid"]

[ext_resource type="Script" path="res://scenes/hex_grid/hex_grid.gd" id="1_hexgrid"]
[ext_resource type="Mesh" path="res://art/meshes/misc/hex_slot.tres" id="2_hex_slot_mesh"]

[sub_resource type="BoxShape3D" id="BoxShape3D_slot"]
size = Vector3(2.8, 0.1, 2.8)

[sub_resource type="StandardMaterial3D" id="SlotMat"]
albedo_color = Color(0.2, 0.8, 0.2, 0.6)
transparency = 1

[sub_resource type="QuadMesh" id="SlotQuadMesh"]
size = Vector2(2.6, 2.6)
orientation = 1

[node name="HexGrid" type="Node3D"]
script = ExtResource("1_hexgrid")

[node name="HexSlot_00" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_00"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_00"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_01" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_01"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_01"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_02" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_02"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_02"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_03" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_03"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_03"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_04" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_04"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_04"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_05" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_05"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_05"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_06" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_06"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_06"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_07" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_07"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_07"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_08" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_08"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_08"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_09" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_09"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_09"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_10" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_10"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_10"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_11" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_11"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_11"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_12" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_12"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_12"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_13" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_13"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_13"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_14" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_14"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_14"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_15" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_15"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_15"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_16" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_16"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_16"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_17" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_17"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_17"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_18" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_18"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_18"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_19" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_19"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_19"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_20" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_20"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_20"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_21" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_21"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_21"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_22" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_22"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_22"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")

[node name="HexSlot_23" type="Area3D" parent="."]
collision_layer = 64
collision_mask = 0
[node name="SlotCollision" type="CollisionShape3D" parent="HexSlot_23"]
shape = SubResource("BoxShape3D_slot")
[node name="SlotMesh" type="MeshInstance3D" parent="HexSlot_23"]
visible = false
mesh = ExtResource("2_hex_slot_mesh")
surface_material_override/0 = SubResource("SlotMat")
````

---

## `scenes/hub/character_base_2d.tscn`

````
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scenes/hub/character_base_2d.gd" id="1"]

[node name="HubCharacterBase2D" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Body" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.2, 0.2, 0.2, 0.85) # PLACEHOLDER

[node name="NameLabel" type="Label" parent="."]
anchor_left = 0.05
anchor_top = 0.7
anchor_right = 0.95
anchor_bottom = 0.95
horizontal_alignment = 1
text = "Character"
````

---

## `scenes/main.tscn`

````
[gd_scene format=3 uid="uid://bufihwkk0ml6a"]

[ext_resource type="PackedScene" path="res://scenes/tower/tower.tscn" id="1_tower"]
[ext_resource type="PackedScene" path="res://scenes/arnulf/arnulf.tscn" id="2_arnulf"]
[ext_resource type="Resource" path="res://resources/weapon_data/crossbow.tres" id="2_vxglm"]
[ext_resource type="Resource" path="res://resources/weapon_data/rapid_missile.tres" id="3_2f3dj"]
[ext_resource type="PackedScene" path="res://scenes/hex_grid/hex_grid.tscn" id="3_hexgrid"]
[ext_resource type="Script" uid="uid://dpaj8prktvoa4" path="res://scripts/wave_manager.gd" id="4_wavemanager"]
[ext_resource type="Script" uid="uid://yeain3i4irhk" path="res://scripts/spell_manager.gd" id="5_spellmanager"]
[ext_resource type="Script" uid="uid://ddqrdafsogm80" path="res://scripts/resources/building_data.gd" id="6_c6pm6"]
[ext_resource type="Script" uid="uid://caigeeql81q4a" path="res://scripts/research_manager.gd" id="6_researchmanager"]
[ext_resource type="Resource" path="res://resources/building_data/arrow_tower.tres" id="7_5he1u"]
[ext_resource type="Script" uid="uid://b3qy6xmea1ytu" path="res://scripts/shop_manager.gd" id="7_shopmanager"]
[ext_resource type="Script" uid="uid://dhw5kviljccvx" path="res://scripts/resources/enemy_data.gd" id="7_yq6so"]
[ext_resource type="Resource" path="res://resources/building_data/fire_brazier.tres" id="8_5poiv"]
[ext_resource type="Resource" path="res://resources/enemy_data/orc_grunt.tres" id="8_fv21b"]
[ext_resource type="Script" uid="uid://5n41loe8t7vh" path="res://scripts/input_manager.gd" id="8_inputmanager"]
[ext_resource type="Resource" path="res://resources/building_data/magic_obelisk.tres" id="9_2cjbq"]
[ext_resource type="Resource" path="res://resources/enemy_data/orc_brute.tres" id="9_tel4y"]
[ext_resource type="Script" uid="uid://diu512ianvrru" path="res://ui/ui_manager.gd" id="9_uimanager"]
[ext_resource type="Resource" path="res://resources/building_data/poison_vat.tres" id="10_chjal"]
[ext_resource type="PackedScene" path="res://ui/hud.tscn" id="10_hud"]
[ext_resource type="Resource" path="res://resources/enemy_data/goblin_firebug.tres" id="10_qkpxi"]
[ext_resource type="Resource" path="res://resources/enemy_data/plague_zombie.tres" id="11_5q0nq"]
[ext_resource type="PackedScene" path="res://ui/build_menu.tscn" id="11_buildmenu"]
[ext_resource type="Resource" path="res://resources/building_data/ballista.tres" id="11_cjqg0"]
[ext_resource type="PackedScene" path="res://ui/between_mission_screen.tscn" id="12_bms"]
[ext_resource type="PackedScene" path="res://ui/hub.tscn" id="40_hub"]
[ext_resource type="PackedScene" path="res://ui/dialogue_panel.tscn" id="41_dialogue_panel"]
[ext_resource type="Resource" path="res://resources/enemy_data/orc_archer.tres" id="12_dgi5k"]
[ext_resource type="Resource" path="res://resources/building_data/archer_barracks.tres" id="12_vchkt"]
[ext_resource type="Resource" path="res://resources/enemy_data/bat_swarm.tres" id="13_j8jky"]
[ext_resource type="PackedScene" path="res://ui/main_menu.tscn" id="13_mainmenu"]
[ext_resource type="Resource" path="res://resources/building_data/anti_air_bolt.tres" id="13_txyw0"]
[ext_resource type="Script" uid="uid://du1u75tff1c5l" path="res://ui/end_screen.gd" id="14_endscreen"]
[ext_resource type="Resource" path="res://resources/building_data/shield_generator.tres" id="14_vc5cj"]
[ext_resource type="Script" uid="uid://ct0jcmhqil53d" path="res://scripts/resources/spell_data.gd" id="15_kmb1v"]
[ext_resource type="Resource" path="res://resources/spell_data/shockwave.tres" id="16_fuf3a"]
[ext_resource type="Script" uid="uid://dwrewkv7itq4c" path="res://scripts/resources/research_node_data.gd" id="18_pibwh"]
[ext_resource type="Resource" path="res://resources/research_data/base_structures_tree.tres" id="19_c6pm6"]
[ext_resource type="Resource" path="res://resources/research_data/unlock_anti_air.tres" id="25_raa"]
[ext_resource type="Resource" path="res://resources/research_data/arrow_tower_plus_damage.tres" id="26_atd"]
[ext_resource type="Resource" path="res://resources/research_data/unlock_shield_generator.tres" id="27_usg"]
[ext_resource type="Resource" path="res://resources/research_data/fire_brazier_plus_range.tres" id="28_fbr"]
[ext_resource type="Resource" path="res://resources/research_data/unlock_archer_barracks.tres" id="29_uab"]
[ext_resource type="Script" uid="uid://cymimirt7rukp" path="res://scripts/resources/shop_item_data.gd" id="21_fv21b"]
[ext_resource type="Resource" path="res://resources/shop_data/shop_item_tower_repair.tres" id="22_tel4y"]
[ext_resource type="Resource" path="res://resources/shop_data/shop_item_mana_draught.tres" id="23_qkpxi"]
[ext_resource type="Resource" path="res://resources/shop_data/shop_item_building_repair.tres" id="30_br"]
[ext_resource type="Resource" path="res://resources/shop_data/shop_item_arrow_tower.tres" id="31_at"]
[ext_resource type="Script" path="res://ui/mission_briefing.gd" id="24_missionbrief"]
[ext_resource type="Script" path="res://scripts/main_root.gd" id="32_mainroot"]
[ext_resource type="Script" path="res://scripts/weapon_upgrade_manager.gd" id="33_wum"]
[ext_resource type="Resource" path="res://resources/weapon_level_data/crossbow_level_1.tres" id="34_cb1"]
[ext_resource type="Resource" path="res://resources/weapon_level_data/crossbow_level_2.tres" id="35_cb2"]
[ext_resource type="Resource" path="res://resources/weapon_level_data/crossbow_level_3.tres" id="36_cb3"]
[ext_resource type="Resource" path="res://resources/weapon_level_data/rapid_missile_level_1.tres" id="37_rm1"]
[ext_resource type="Resource" path="res://resources/weapon_level_data/rapid_missile_level_2.tres" id="38_rm2"]
[ext_resource type="Resource" path="res://resources/weapon_level_data/rapid_missile_level_3.tres" id="39_rm3"]

[sub_resource type="PlaneMesh" id="GroundMesh"]
size = Vector2(120, 120)

[sub_resource type="StandardMaterial3D" id="GroundMat"]
albedo_color = Color(0.3, 0.5, 0.2, 1)

[sub_resource type="BoxShape3D" id="GroundShape"]
size = Vector3(120, 0.1, 120)

[node name="Main" type="Node3D" unique_id=278141263]
script = ExtResource("32_mainroot")

[node name="Camera3D" type="Camera3D" parent="." unique_id=1755599474]
transform = Transform3D(0.7071, -0.4082, 0.5774, 0, 0.8165, 0.5774, -0.7071, -0.4082, 0.5774, 20, 20, 20)
projection = 1
size = 40.0

[node name="DirectionalLight3D" type="DirectionalLight3D" parent="." unique_id=2075946280]
transform = Transform3D(1, 0, 0, 0, 0.7071, -0.7071, 0, 0.7071, 0.7071, 0, 0, 0)
shadow_enabled = true

[node name="Ground" type="StaticBody3D" parent="." unique_id=349446950]
collision_layer = 32
collision_mask = 0

[node name="GroundMesh" type="MeshInstance3D" parent="Ground" unique_id=1716342125]
mesh = SubResource("GroundMesh")
surface_material_override/0 = SubResource("GroundMat")

[node name="GroundCollision" type="CollisionShape3D" parent="Ground" unique_id=685200946]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.05, 0)
shape = SubResource("GroundShape")

[node name="NavigationRegion3D" type="NavigationRegion3D" parent="Ground" unique_id=1759993504]

[node name="Tower" parent="." unique_id=1725170270 instance=ExtResource("1_tower")]
crossbow_data = ExtResource("2_vxglm")
rapid_missile_data = ExtResource("3_2f3dj")
auto_fire_enabled = false

[node name="Arnulf" parent="." unique_id=42488866 instance=ExtResource("2_arnulf")]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 3, 0, 0)

[node name="HexGrid" parent="." unique_id=1556408131 instance=ExtResource("3_hexgrid")]
building_data_registry = Array[ExtResource("6_c6pm6")]([ExtResource("7_5he1u"), ExtResource("8_5poiv"), ExtResource("9_2cjbq"), ExtResource("10_chjal"), ExtResource("11_cjqg0"), ExtResource("12_vchkt"), ExtResource("13_txyw0"), ExtResource("14_vc5cj")])

[node name="SpawnPoints" type="Node3D" parent="." unique_id=889060022]

[node name="SpawnPoint_00" type="Marker3D" parent="SpawnPoints" unique_id=1061768036]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 40, 0, 0)

[node name="SpawnPoint_01" type="Marker3D" parent="SpawnPoints" unique_id=154523069]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 31, 0, 25)

[node name="SpawnPoint_02" type="Marker3D" parent="SpawnPoints" unique_id=282724448]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 12, 0, 38)

[node name="SpawnPoint_03" type="Marker3D" parent="SpawnPoints" unique_id=939810357]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, 0, 38)

[node name="SpawnPoint_04" type="Marker3D" parent="SpawnPoints" unique_id=911991605]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -31, 0, 25)

[node name="SpawnPoint_05" type="Marker3D" parent="SpawnPoints" unique_id=744283116]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -40, 0, 0)

[node name="SpawnPoint_06" type="Marker3D" parent="SpawnPoints" unique_id=1469967985]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -31, 0, -25)

[node name="SpawnPoint_07" type="Marker3D" parent="SpawnPoints" unique_id=1321225900]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, 0, -38)

[node name="SpawnPoint_08" type="Marker3D" parent="SpawnPoints" unique_id=922159319]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 12, 0, -38)

[node name="SpawnPoint_09" type="Marker3D" parent="SpawnPoints" unique_id=1456399909]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 31, 0, -25)

[node name="EnemyContainer" type="Node3D" parent="." unique_id=1398307004]

[node name="AllyContainer" type="Node3D" parent="."]

[node name="AllySpawnPoints" type="Node3D" parent="."]

[node name="AllySpawnPoint_00" type="Marker3D" parent="AllySpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4, 0, 4)

[node name="AllySpawnPoint_01" type="Marker3D" parent="AllySpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4, 0, 4)

[node name="AllySpawnPoint_02" type="Marker3D" parent="AllySpawnPoints"]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 6)

[node name="BuildingContainer" type="Node3D" parent="." unique_id=1261693534]

[node name="ProjectileContainer" type="Node3D" parent="." unique_id=1596717683]

[node name="Managers" type="Node" parent="." unique_id=2086752460]

[node name="WaveManager" type="Node" parent="Managers" unique_id=1618397993]
script = ExtResource("4_wavemanager")
enemy_data_registry = Array[ExtResource("7_yq6so")]([ExtResource("8_fv21b"), ExtResource("9_tel4y"), ExtResource("10_qkpxi"), ExtResource("11_5q0nq"), ExtResource("12_dgi5k"), ExtResource("13_j8jky")])

[node name="SpellManager" type="Node" parent="Managers" unique_id=1971048015]
script = ExtResource("5_spellmanager")
spell_registry = Array[ExtResource("15_kmb1v")]([ExtResource("16_fuf3a")])

[node name="ResearchManager" type="Node" parent="Managers" unique_id=1112433558]
script = ExtResource("6_researchmanager")
research_nodes = Array[ExtResource("18_pibwh")]([ExtResource("19_c6pm6"), ExtResource("25_raa"), ExtResource("26_atd"), ExtResource("27_usg"), ExtResource("28_fbr"), ExtResource("29_uab")])
dev_unlock_all_research = false
dev_unlock_anti_air_only = true

[node name="ShopManager" type="Node" parent="Managers" unique_id=587576636]
script = ExtResource("7_shopmanager")
shop_catalog = Array[ExtResource("21_fv21b")]([ExtResource("22_tel4y"), ExtResource("23_qkpxi"), ExtResource("30_br"), ExtResource("31_at")])

[node name="WeaponUpgradeManager" type="Node" parent="Managers"]
script = ExtResource("33_wum")
crossbow_levels = [ExtResource("34_cb1"), ExtResource("35_cb2"), ExtResource("36_cb3")]
rapid_missile_levels = [ExtResource("37_rm1"), ExtResource("38_rm2"), ExtResource("39_rm3")]
crossbow_base_data = ExtResource("2_vxglm")
rapid_missile_base_data = ExtResource("3_2f3dj")

[node name="InputManager" type="Node" parent="Managers" unique_id=281699099]
script = ExtResource("8_inputmanager")

[node name="UI" type="CanvasLayer" parent="." unique_id=1086963466]

[node name="UIManager" type="Control" parent="UI" unique_id=1866044408]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
script = ExtResource("9_uimanager")

[node name="Hub" parent="UI" instance=ExtResource("40_hub")]
layout_mode = 3
anchors_preset = 15
grow_horizontal = 2
grow_vertical = 2

[node name="DialoguePanel" parent="UI/UIManager" instance=ExtResource("41_dialogue_panel")]
layout_mode = 3
anchors_preset = 15
grow_horizontal = 2
grow_vertical = 2


[node name="HUD" parent="UI" unique_id=2074136346 instance=ExtResource("10_hud")]
layout_mode = 3
anchors_preset = 15
grow_horizontal = 2
grow_vertical = 2

[node name="BuildMenu" parent="UI" unique_id=526512980 instance=ExtResource("11_buildmenu")]
layout_mode = 3
anchors_preset = 15
grow_horizontal = 2
grow_vertical = 2

[node name="BetweenMissionScreen" parent="UI" unique_id=2754276 instance=ExtResource("12_bms")]
layout_mode = 3
anchors_preset = 15
grow_horizontal = 2
grow_vertical = 2

[node name="MainMenu" parent="UI" unique_id=1918308496 instance=ExtResource("13_mainmenu")]
layout_mode = 3
anchors_preset = 15
grow_horizontal = 2
grow_vertical = 2

[node name="MissionBriefing" type="Control" parent="UI" unique_id=2113838594]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("24_missionbrief")

[node name="Background" type="ColorRect" parent="UI/MissionBriefing" unique_id=2128238404]
layout_mode = 0
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.2, 0.2, 0.2, 0.9)

[node name="MissionLabel" type="Label" parent="UI/MissionBriefing" unique_id=933858123]
layout_mode = 0
anchor_left = 0.3
anchor_top = 0.4
anchor_right = 0.7
anchor_bottom = 0.6
theme_override_font_sizes/font_size = 96
text = "MISSION 1"
horizontal_alignment = 1

[node name="BeginButton" type="Button" parent="UI/MissionBriefing" unique_id=933858124]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -80.0
offset_top = 80.0
offset_right = 80.0
offset_bottom = 120.0
grow_horizontal = 2
grow_vertical = 2
text = "BEGIN"

[node name="EndScreen" type="Control" parent="UI" unique_id=1075513404]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("14_endscreen")

[node name="Background" type="ColorRect" parent="UI/EndScreen" unique_id=618484259]
layout_mode = 0
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 0.85)

[node name="MessageLabel" type="Label" parent="UI/EndScreen" unique_id=163434843]
layout_mode = 0
anchor_left = 0.2
anchor_top = 0.3
anchor_right = 0.8
anchor_bottom = 0.5
theme_override_font_sizes/font_size = 72
horizontal_alignment = 1

[node name="RestartButton" type="Button" parent="UI/EndScreen" unique_id=1168444849]
layout_mode = 0
anchor_left = 0.35
anchor_top = 0.6
anchor_right = 0.65
anchor_bottom = 0.7
text = "Restart"

[node name="QuitButton" type="Button" parent="UI/EndScreen" unique_id=737490085]
layout_mode = 0
anchor_left = 0.35
anchor_top = 0.75
anchor_right = 0.65
anchor_bottom = 0.85
text = "Quit"
````

---

## `scenes/projectiles/projectile_base.tscn`

````
[gd_scene load_steps=6 format=3]

[ext_resource type="Script" path="res://scenes/projectiles/projectile_base.gd" id="1"]
[ext_resource type="Mesh" path="res://art/meshes/misc/projectile_crossbow.tres" id="2_crossbow_projectile_mesh"]

[sub_resource type="SphereShape3D" id="1"]
radius = 0.2

[sub_resource type="StandardMaterial3D" id="2"]
albedo_color = Color(1, 1, 1, 1)

[sub_resource type="SphereMesh" id="3"]
radius = 0.15
height = 0.3

[node name="ProjectileBase" type="Area3D"]
script = ExtResource("1")
collision_layer = 0
collision_mask = 0

[node name="ProjectileMesh" type="MeshInstance3D" parent="."]
mesh = ExtResource("2_crossbow_projectile_mesh")
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)

[node name="ProjectileCollision" type="CollisionShape3D" parent="."]
shape = SubResource("1")
````

---

## `scenes/tower/tower.tscn`

````
[gd_scene load_steps=9 format=3 uid="uid://tower_scene"]

[ext_resource type="Script" path="res://scenes/tower/tower.gd" id="1_tower"]
[ext_resource type="Script" path="res://scripts/health_component.gd" id="2_health"]
[ext_resource type="Resource" path="res://resources/weapon_data/crossbow.tres" id="3_crossbow"]
[ext_resource type="Resource" path="res://resources/weapon_data/rapid_missile.tres" id="4_rapid"]
[ext_resource type="Mesh" path="res://art/meshes/misc/tower_core.tres" id="5_tower_core_mesh"]
[ext_resource type="Material" path="res://art/materials/factions/faction_neutral_material.tres" id="6_neutral_faction_mat"]

[sub_resource type="BoxMesh" id="BoxMesh_tower"]
size = Vector3(2.0, 2.0, 2.0)

[sub_resource type="StandardMaterial3D" id="Mat_tower"]
albedo_color = Color(0.6, 0.4, 0.1, 1.0)

[sub_resource type="BoxShape3D" id="Shape_tower"]
size = Vector3(2.0, 2.0, 2.0)

[node name="Tower" type="StaticBody3D"]
script = ExtResource("1_tower")
collision_layer = 1
collision_mask = 0
starting_hp = 500
crossbow_data = ExtResource("3_crossbow")
rapid_missile_data = ExtResource("4_rapid")

[node name="TowerMesh" type="MeshInstance3D" parent="."]
mesh = ExtResource("5_tower_core_mesh")
material_override = ExtResource("6_neutral_faction_mat")
transform = Transform3D(1,0,0,0,1,0,0,0,1, 0,1.0,0)

[node name="TowerCollision" type="CollisionShape3D" parent="."]
shape = SubResource("Shape_tower")
transform = Transform3D(1,0,0,0,1,0,0,0,1, 0,1.0,0)

[node name="HealthComponent" type="Node" parent="."]
script = ExtResource("2_health")
starting_hp = 500

[node name="TowerLabel" type="Label3D" parent="."]
text = "TOWER"
position = Vector3(0, 2.5, 0)
pixel_size = 0.01
billboard = 2
font_size = 64
````

---

## `ui/between_mission_screen.tscn`

````
[gd_scene load_steps=3 format=3 uid="uid://betweenmission_scene"]

[ext_resource type="Script" path="res://ui/between_mission_screen.gd" id="1_bms"]
[ext_resource type="PackedScene" uid="uid://worldmap_panel_fw" path="res://ui/world_map.tscn" id="2_wm"]

[node name="BetweenMissionScreen" type="Control"]
script = ExtResource("1_bms")
anchor_right = 1.0
anchor_bottom = 1.0
visible = false

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.1, 0.1, 0.1, 0.95)

[node name="DayProgressLabel" type="Label" parent="."]
offset_left = 120.0
offset_top = 20.0
offset_right = 420.0
offset_bottom = 48.0
text = "Day 1 / 5"

[node name="DayNameLabel" type="Label" parent="."]
offset_left = 120.0
offset_top = 52.0
offset_right = 780.0
offset_bottom = 82.0
text = "Day 1 - Rotting Fields"

[node name="FlorenceDebugLabel" type="Label" parent="."]
offset_left = 120.0
offset_top = 86.0
offset_right = 780.0
offset_bottom = 116.0
text = "Florence debug"

[node name="TabContainer" type="TabContainer" parent="."]
anchor_left = 0.1
anchor_top = 0.1
anchor_right = 0.9
anchor_bottom = 0.85

[node name="MapTab" type="Control" parent="TabContainer"]
metadata/_tab_name = "World Map"

[node name="WorldMap" parent="TabContainer/MapTab" instance=ExtResource("2_wm")]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="ShopTab" type="Control" parent="TabContainer"]

[node name="ShopList" type="VBoxContainer" parent="TabContainer/ShopTab"]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="ResearchTab" type="Control" parent="TabContainer"]

[node name="ResearchList" type="VBoxContainer" parent="TabContainer/ResearchTab"]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="BuildingsTab" type="Control" parent="TabContainer"]

[node name="BuildingsList" type="VBoxContainer" parent="TabContainer/BuildingsTab"]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="MercenariesTab" type="Control" parent="TabContainer"]
metadata/_tab_name = "Mercenaries"

[node name="OffersSection" type="VBoxContainer" parent="TabContainer/MercenariesTab"]
anchor_right = 1.0
anchor_bottom = 0.48

[node name="OffersLabel" type="Label" parent="TabContainer/MercenariesTab/OffersSection"]
text = "Available Mercenaries"

[node name="OffersList" type="VBoxContainer" parent="TabContainer/MercenariesTab/OffersSection"]
anchor_top = 0.12
anchor_right = 1.0
anchor_bottom = 1.0

[node name="RosterSection" type="VBoxContainer" parent="TabContainer/MercenariesTab"]
anchor_top = 0.52
anchor_right = 1.0
anchor_bottom = 1.0

[node name="CapLabel" type="Label" parent="TabContainer/MercenariesTab/RosterSection"]
text = "Active: 0 / 2"

[node name="RosterList" type="VBoxContainer" parent="TabContainer/MercenariesTab/RosterSection"]
anchor_top = 0.14
anchor_right = 1.0
anchor_bottom = 1.0

[node name="WeaponsTab" type="Control" parent="TabContainer"]

[node name="VBoxContainer" type="VBoxContainer" parent="TabContainer/WeaponsTab"]
anchor_right = 1.0
anchor_bottom = 1.0

[node name="CrossbowPanel" type="VBoxContainer" parent="TabContainer/WeaponsTab/VBoxContainer"]

[node name="TitleLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/CrossbowPanel"]
text = "Crossbow"

[node name="LevelLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/CrossbowPanel"]
text = "Level 0 / 3"

[node name="StatsLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/CrossbowPanel"]
text = "DMG: 0  SPD: 0  RLD: 0.0s  BURST: 0"

[node name="PreviewLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/CrossbowPanel"]
text = ""

[node name="CostLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/CrossbowPanel"]
text = ""

[node name="UpgradeButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/CrossbowPanel"]
text = "Upgrade"

[node name="RapidMissilePanel" type="VBoxContainer" parent="TabContainer/WeaponsTab/VBoxContainer"]

[node name="TitleLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/RapidMissilePanel"]
text = "Rapid Missile"

[node name="LevelLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/RapidMissilePanel"]
text = "Level 0 / 3"

[node name="StatsLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/RapidMissilePanel"]
text = "DMG: 0  SPD: 0  RLD: 0.0s  BURST: 0"

[node name="PreviewLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/RapidMissilePanel"]
text = ""

[node name="CostLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/RapidMissilePanel"]
text = ""

[node name="UpgradeButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/RapidMissilePanel"]
text = "Upgrade"

[node name="WeaponsPanel" type="VBoxContainer" parent="TabContainer/WeaponsTab/VBoxContainer"]

[node name="Crossbow" type="HBoxContainer" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel"]

[node name="NameLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow"]
text = "Crossbow"

[node name="EnchantmentLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow"]
text = "elemental: None, power: None"

[node name="ApplyElementalButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow"]
text = "Apply Elemental"

[node name="ApplyPowerButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow"]
text = "Apply Power"

[node name="RemoveAllButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow"]
text = "Remove"

[node name="RapidMissile" type="HBoxContainer" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel"]

[node name="NameLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile"]
text = "Rapid Missile"

[node name="EnchantmentLabel" type="Label" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile"]
text = "elemental: None, power: None"

[node name="ApplyElementalButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile"]
text = "Apply Elemental"

[node name="ApplyPowerButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile"]
text = "Apply Power"

[node name="RemoveAllButton" type="Button" parent="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile"]
text = "Remove"

[node name="NextMissionButton" type="Button" parent="."]
anchor_left = 0.35
anchor_top = 0.88
anchor_right = 0.65
anchor_bottom = 0.96
text = "Next Day"

[connection signal="pressed" from="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/ApplyElementalButton" to="." method="on_apply_crossbow_elemental_pressed"]
[connection signal="pressed" from="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/ApplyPowerButton" to="." method="on_apply_crossbow_power_pressed"]
[connection signal="pressed" from="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/Crossbow/RemoveAllButton" to="." method="on_remove_crossbow_enchantments_pressed"]
[connection signal="pressed" from="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/ApplyElementalButton" to="." method="on_apply_rapid_elemental_pressed"]
[connection signal="pressed" from="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/ApplyPowerButton" to="." method="on_apply_rapid_power_pressed"]
[connection signal="pressed" from="TabContainer/WeaponsTab/VBoxContainer/WeaponsPanel/RapidMissile/RemoveAllButton" to="." method="on_remove_rapid_enchantments_pressed"]
````

---

## `ui/build_menu.tscn`

````
[gd_scene load_steps=2 format=3 uid="uid://buildmenu_scene"]

[ext_resource type="Script" path="res://ui/build_menu.gd" id="1_buildmenu"]

[node name="BuildMenu" type="Control"]
script = ExtResource("1_buildmenu")
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
visible = false

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 0.5)
mouse_filter = 2

[node name="Panel" type="PanelContainer" parent="."]
clip_contents = true
anchor_left = 0.0
anchor_top = 0.5
anchor_right = 0.0
anchor_bottom = 0.5
offset_left = 12.0
offset_top = -260.0
offset_right = 572.0
offset_bottom = 260.0
custom_maximum_size = Vector2(560, 520)

[node name="VBox" type="VBoxContainer" parent="Panel"]
size_flags_horizontal = 3

[node name="SlotLabel" type="Label" parent="Panel/VBox"]
text = "Slot 0 — Choose Building:"
horizontal_alignment = 1

[node name="HelpScroll" type="ScrollContainer" parent="Panel/VBox"]
custom_minimum_size = Vector2(520, 88)
size_flags_vertical = 0
size_flags_horizontal = 3

[node name="HelpLabel" type="Label" parent="Panel/VBox/HelpScroll"]
custom_minimum_size = Vector2(500, 0)
text = "Placement: the yellow ring on the ground is the active slot. Click any blue ring to change the slot, then press a building button — it is placed there immediately (no extra click on the map)."
autowrap_mode = 3
horizontal_alignment = 1

[node name="BuildingContainer" type="GridContainer" parent="Panel/VBox"]
columns = 2

[node name="SellPanel" type="VBoxContainer" parent="Panel/VBox"]
visible = false

[node name="BuildingNameLabel" type="Label" parent="Panel/VBox/SellPanel"]
text = ""

[node name="UpgradeStatusLabel" type="Label" parent="Panel/VBox/SellPanel"]
text = ""

[node name="RefundLabel" type="Label" parent="Panel/VBox/SellPanel"]
text = ""

[node name="Buttons" type="HBoxContainer" parent="Panel/VBox/SellPanel"]

[node name="SellButton" type="Button" parent="Panel/VBox/SellPanel/Buttons"]
text = "Sell"

[node name="CancelButton" type="Button" parent="Panel/VBox/SellPanel/Buttons"]
text = "Cancel"

[node name="CloseButton" type="Button" parent="Panel/VBox"]
text = "Close / Exit Build Mode"
````

---

## `ui/dialogue_panel.tscn`

````
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://ui/dialogue_panel.gd" id="1"]

[node name="DialoguePanel" type="Control"]
anchor_right = 1.0
anchor_bottom = 1.0
visible = false
mouse_filter = 1
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
anchor_left = 0.0
anchor_top = 0.6
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.05, 0.05, 0.05, 0.95)

[node name="SpeakerLabel" type="Label" parent="."]
anchor_left = 0.05
anchor_top = 0.62
anchor_right = 0.95
anchor_bottom = 0.70
horizontal_alignment = 0
text = "Speaker"

[node name="TextLabel" type="Label" parent="."]
anchor_left = 0.05
anchor_top = 0.70
anchor_right = 0.95
anchor_bottom = 0.96
autowrap_mode = 2
text = "Dialogue text..."
````

---

## `ui/dialogue_ui.tscn`

````
[gd_scene load_steps=2 format=3 uid="uid://dialogue_ui_placeholder"]

[ext_resource type="Script" path="res://ui/dialogue_ui.gd" id="1_dialogue_ui"]

[node name="DialogueUI" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 0
script = ExtResource("1_dialogue_ui")

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -280.0
offset_top = -180.0
offset_right = 280.0
offset_bottom = -24.0
grow_horizontal = 2
grow_vertical = 0

[node name="VBox" type="VBoxContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
grow_horizontal = 2
grow_vertical = 2

[node name="NameLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "Name"

[node name="TextLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
size_flags_vertical = 3
text = "TODO"
autowrap_mode = 3

[node name="AdvanceButton" type="Button" parent="Panel/VBox"]
layout_mode = 2
text = "Continue"
````

---

## `ui/dialogueui.tscn`

````
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://ui/dialogueui.gd" id="1_dialogue_ui"]

[node name="DialogueUI" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 0
script = ExtResource("1_dialogue_ui")

[node name="Panel" type="Panel" parent="."]
layout_mode = 1
anchors_preset = 7
anchor_left = 0.5
anchor_top = 1.0
anchor_right = 0.5
anchor_bottom = 1.0
offset_left = -280.0
offset_top = -180.0
offset_right = 280.0
offset_bottom = -24.0
grow_horizontal = 2
grow_vertical = 0

[node name="VBox" type="VBoxContainer" parent="Panel"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 12.0
offset_top = 12.0
offset_right = -12.0
offset_bottom = -12.0
grow_horizontal = 2
grow_vertical = 2

[node name="NameLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
text = "Name"

[node name="TextLabel" type="Label" parent="Panel/VBox"]
layout_mode = 2
size_flags_vertical = 3
text = "TODO"
autowrap_mode = 3

[node name="AdvanceButton" type="Button" parent="Panel/VBox"]
layout_mode = 2
text = "Continue"
````

---

## `ui/hub.tscn`

````
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://ui/hub.gd" id="1"]
[ext_resource type="Resource" path="res://resources/character_catalog.tres" id="2"]
[ext_resource type="PackedScene" path="res://scenes/hub/character_base_2d.tscn" id="3"]

[node name="Hub" type="Control"]
anchor_right = 1.0
anchor_bottom = 1.0
visible = false
mouse_filter = 1
script = ExtResource("1")
character_catalog = ExtResource("2")

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.0, 0.0, 0.0, 0.6)

[node name="CharactersContainer" type="HBoxContainer" parent="."]
anchor_left = 0.05
anchor_top = 0.7
anchor_right = 0.95
anchor_bottom = 0.95
alignment = 1
````

---

## `ui/hud.tscn`

````
[gd_scene load_steps=2 format=3 uid="uid://hud_scene"]

[ext_resource type="Script" path="res://ui/hud.gd" id="1_hud"]

[node name="HUD" type="Control"]
mouse_filter = 2
script = ExtResource("1_hud")
anchor_right = 1.0
anchor_bottom = 1.0
visible = false

[node name="ResourceDisplay" type="HBoxContainer" parent="."]
offset_left = 10
offset_top = 10
offset_right = 300
offset_bottom = 40

[node name="GoldLabel" type="Label" parent="ResourceDisplay"]
text = "Gold: 1000"

[node name="MaterialLabel" type="Label" parent="ResourceDisplay"]
text = "Mat: 50"

[node name="ResearchLabel" type="Label" parent="ResourceDisplay"]
text = "Res: 0"

[node name="WaveDisplay" type="VBoxContainer" parent="."]
anchor_left = 0.5
anchor_right = 0.5
offset_left = -150
offset_top = 10
offset_right = 150
offset_bottom = 70

[node name="WaveLabel" type="Label" parent="WaveDisplay"]
text = "Wave 0 / 10"
horizontal_alignment = 1

[node name="CountdownLabel" type="Label" parent="WaveDisplay"]
text = "30"
horizontal_alignment = 1
visible = false

[node name="TowerHPBar" type="ProgressBar" parent="."]
offset_left = 10
offset_top = 50
offset_right = 200
offset_bottom = 75
max_value = 500.0
value = 500.0
show_percentage = false

[node name="SpellPanel" type="HBoxContainer" parent="."]
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = 10
offset_top = -60
offset_right = 320
offset_bottom = -10

[node name="ManaBar" type="ProgressBar" parent="SpellPanel"]
custom_minimum_size = Vector2(150, 30)
max_value = 100.0
value = 0.0
show_percentage = false

[node name="SpellButton" type="Button" parent="SpellPanel"]
text = "Shockwave"
disabled = true

[node name="CooldownLabel" type="Label" parent="SpellPanel"]
text = "Shockwave: READY"

[node name="WeaponPanel" type="VBoxContainer" parent="."]
anchor_left = 1.0
anchor_right = 1.0
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -200
offset_top = -80
offset_right = -10
offset_bottom = -10

[node name="CrossbowLabel" type="Label" parent="WeaponPanel"]
text = "Crossbow: READY"

[node name="CrossbowReloadBar" type="ProgressBar" parent="WeaponPanel"]
custom_minimum_size = Vector2(0, 10)
max_value = 100.0
value = 100.0
show_percentage = false

[node name="MissileLabel" type="Label" parent="WeaponPanel"]
text = "Missile: READY"

[node name="MissileReloadBar" type="ProgressBar" parent="WeaponPanel"]
custom_minimum_size = Vector2(0, 10)
max_value = 100.0
value = 100.0
show_percentage = false

[node name="BuildModeHint" type="Label" parent="."]
anchor_left = 0.5
anchor_right = 0.5
anchor_top = 1.0
anchor_bottom = 1.0
offset_left = -100
offset_top = -40
offset_right = 100
offset_bottom = -10
text = "[B] Build Mode"
horizontal_alignment = 1
visible = false
````

---

## `ui/main_menu.tscn`

````
[gd_scene load_steps=2 format=3 uid="uid://mainmenu_scene"]

[ext_resource type="Script" path="res://ui/main_menu.gd" id="1_mainmenu"]

[node name="MainMenu" type="Control"]
script = ExtResource("1_mainmenu")
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.05, 0.05, 0.1, 1.0)

[node name="TitleLabel" type="Label" parent="."]
anchor_left = 0.25
anchor_right = 0.75
offset_top = 80
offset_bottom = 140
text = "FOUL WARD"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 72

[node name="StartButton" type="Button" parent="."]
anchor_left = 0.35
anchor_top = 0.4
anchor_right = 0.65
anchor_bottom = 0.5
text = "Start Game"

[node name="SettingsButton" type="Button" parent="."]
anchor_left = 0.35
anchor_top = 0.55
anchor_right = 0.65
anchor_bottom = 0.65
text = "Settings (POST-MVP)"
disabled = true

[node name="QuitButton" type="Button" parent="."]
anchor_left = 0.35
anchor_top = 0.7
anchor_right = 0.65
anchor_bottom = 0.8
text = "Quit"
````

---

## `ui/mission_briefing.tscn`

````
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://ui/mission_briefing.gd" id="1"]

[node name="MissionBriefing" type="Control"]
script = ExtResource("1")
anchor_right = 1.0
anchor_bottom = 1.0
visible = false

[node name="MissionLabel" type="Label" parent="."]
anchor_left = 0.5
anchor_right = 0.5
anchor_top = 0.4
anchor_bottom = 0.4
offset_left = -200
offset_right = 200
offset_top = -40
offset_bottom = 40
text = "MISSION 1"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 48

[node name="BeginButton" type="Button" parent="."]
visible = true
anchor_left = 0.5
anchor_right = 0.5
anchor_top = 0.6
anchor_bottom = 0.6
offset_left = -100
offset_right = 100
offset_top = -25
offset_bottom = 25
text = "BEGIN MISSION"
````

---

## `ui/world_map.tscn`

````
[gd_scene load_steps=2 format=3 uid="uid://worldmap_panel_fw"]

[ext_resource type="Script" path="res://ui/world_map.gd" id="1_wm"]

[node name="WorldMap" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_wm")

[node name="MainContainer" type="HBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 12

[node name="TerritoryList" type="VBoxContainer" parent="MainContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="Label" type="Label" parent="MainContainer/TerritoryList"]
layout_mode = 2
text = "Territories"

[node name="TerritoryButtons" type="VBoxContainer" parent="MainContainer/TerritoryList"]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3

[node name="DetailsPanel" type="VBoxContainer" parent="MainContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3

[node name="DayLabel" type="Label" parent="MainContainer/DetailsPanel"]
unique_name_in_owner = true
layout_mode = 2
text = "Day: -"

[node name="TerritoryNameLabel" type="Label" parent="MainContainer/DetailsPanel"]
unique_name_in_owner = true
layout_mode = 2
text = "Territory: -"

[node name="TerritoryDescriptionLabel" type="Label" parent="MainContainer/DetailsPanel"]
unique_name_in_owner = true
layout_mode = 2
text = "Description: -"
autowrap_mode = 3

[node name="TerrainLabel" type="Label" parent="MainContainer/DetailsPanel"]
unique_name_in_owner = true
layout_mode = 2
text = "Terrain: -"

[node name="OwnershipLabel" type="Label" parent="MainContainer/DetailsPanel"]
unique_name_in_owner = true
layout_mode = 2
text = "Ownership: -"

[node name="BonusesLabel" type="Label" parent="MainContainer/DetailsPanel"]
unique_name_in_owner = true
layout_mode = 2
text = "Bonuses: -"
autowrap_mode = 3
````
