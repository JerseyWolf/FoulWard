#!/usr/bin/env python3
"""Generate EnemyData, AllyData, ResearchNodeData for Prompt 50."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ED = ROOT / "resources/enemy_data"
AD = ROOT / "resources/ally_data"
RD = ROOT / "resources/research_data"
SCRIPT_ED = "res://scripts/resources/enemy_data.gd"
SCRIPT_AD = "res://scripts/resources/ally_data.gd"
SCRIPT_RN = "res://scripts/resources/research_node_data.gd"


def wed(name: str, lines: list[str]) -> None:
    out = [
        '[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]',
        "",
        f'[ext_resource type="Script" path="{SCRIPT_ED}" id="1"]',
        "",
        "[resource]",
        'script = ExtResource("1")',
    ]
    out.extend(lines)
    out.append("")
    (ED / name).write_text("\n".join(out))


def ally(name: str, lines: list[str]) -> None:
    out = [
        '[gd_resource type="Resource" script_class="AllyData" load_steps=2 format=3]',
        "",
        f'[ext_resource type="Script" path="{SCRIPT_AD}" id="1"]',
        "",
        "[resource]",
        'script = ExtResource("1")',
    ]
    out.extend(lines)
    out.append("")
    (AD / name).write_text("\n".join(out))


def rnode(name: str, node_id: str, disp: str, cost: int, prereqs: list[str], desc: str) -> None:
    pre = "[]" if not prereqs else "[" + ", ".join(f'"{p}"' for p in prereqs) + "]"
    out = [
        '[gd_resource type="Resource" script_class="ResearchNodeData" format=3]',
        "",
        f'[ext_resource type="Script" path="{SCRIPT_RN}" id="1_researchnodedata"]',
        "",
        "[resource]",
        'script = ExtResource("1_researchnodedata")',
        f'node_id = "{node_id}"',
        f'display_name = "{disp}"',
        f"research_cost = {cost}",
        f"prerequisite_ids = {pre}",
        f'description = "{desc}"',
        "",
    ]
    (RD / name).write_text("\n".join(out))


# --- New enemies (24) ---
wed(
    "orc_skirmisher.tres",
    [
        'id = "orc_skirmisher"',
        "enemy_type = 6",
        'display_name = "Orc Skirmisher"',
        "max_hp = 40",
        "move_speed = 7.0",
        "damage = 8",
        "attack_cooldown = 1.2",
        "attack_range = 1.5",
        "armor_type = 0",
        "gold_reward = 7",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.7, 0.4, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 1",
        "point_cost = 6",
        'wave_tags = Array[String](["RUSH", "INVASION"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_ratling.tres",
    [
        'id = "orc_ratling"',
        "enemy_type = 7",
        'display_name = "Orc Ratling"',
        "max_hp = 20",
        "move_speed = 5.5",
        "damage = 4",
        "attack_cooldown = 1.5",
        "attack_range = 1.2",
        "armor_type = 0",
        "gold_reward = 2",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.5, 0.3, 0.1, 1.0)",
        "damage_immunities = []",
        "tier = 1",
        "point_cost = 2",
        'wave_tags = Array[String](["RUSH", "INVASION"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "goblin_runts.tres",
    [
        'id = "goblin_runts"',
        "enemy_type = 8",
        'display_name = "Goblin Runts"',
        "max_hp = 25",
        "move_speed = 6.0",
        "damage = 5",
        "attack_cooldown = 1.2",
        "attack_range = 1.2",
        "armor_type = 0",
        "gold_reward = 4",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.6, 0.7, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 1",
        "point_cost = 3",
        'wave_tags = Array[String](["RUSH", "INVASION"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "hound.tres",
    [
        'id = "hound"',
        "enemy_type = 9",
        'display_name = "Hound"',
        "max_hp = 50",
        "move_speed = 9.0",
        "damage = 12",
        "attack_cooldown = 1.0",
        "attack_range = 1.5",
        "armor_type = 0",
        "gold_reward = 10",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.5, 0.3, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 1",
        "point_cost = 10",
        'wave_tags = Array[String](["RUSH"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_raider.tres",
    [
        'id = "orc_raider"',
        "enemy_type = 10",
        'display_name = "Orc Raider"',
        "max_hp = 120",
        "move_speed = 4.5",
        "damage = 18",
        "attack_cooldown = 1.2",
        "attack_range = 1.8",
        "armor_type = 0",
        "gold_reward = 15",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.8, 0.3, 0.1, 1.0)",
        "damage_immunities = []",
        "tier = 2",
        "point_cost = 10",
        'wave_tags = Array[String](["INVASION", "RUSH"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_marksman.tres",
    [
        'id = "orc_marksman"',
        "enemy_type = 11",
        'display_name = "Orc Marksman"',
        "max_hp = 100",
        "move_speed = 3.0",
        "damage = 20",
        "attack_cooldown = 2.0",
        "attack_range = 18.0",
        "armor_type = 0",
        "gold_reward = 16",
        "is_ranged = true",
        "is_flying = false",
        "color = Color(0.7, 0.5, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 2",
        "point_cost = 11",
        'wave_tags = Array[String](["ARTILLERY", "INVASION"])',
        'special_tags = Array[String](["ranged_long"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "war_shaman.tres",
    [
        'id = "war_shaman"',
        "enemy_type = 12",
        'display_name = "War Shaman"',
        "max_hp = 110",
        "move_speed = 3.5",
        "damage = 10",
        "attack_cooldown = 2.0",
        "attack_range = 2.0",
        "armor_type = 0",
        "gold_reward = 18",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.9, 0.2, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 2",
        "point_cost = 12",
        'wave_tags = Array[String](["INVASION", "SUPPORT"])',
        'special_tags = Array[String](["aura_buff"])',
        "special_values = {",
        '&"aura_buff": {',
        '&"radius": 8.0,',
        '&"damage_pct": 0.20',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "plague_shaman.tres",
    [
        'id = "plague_shaman"',
        "enemy_type = 13",
        'display_name = "Plague Shaman"',
        "max_hp = 120",
        "move_speed = 3.0",
        "damage = 8",
        "attack_cooldown = 2.0",
        "attack_range = 2.0",
        "armor_type = 0",
        "gold_reward = 18",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.4, 0.8, 0.3, 1.0)",
        "damage_immunities = []",
        "tier = 2",
        "point_cost = 12",
        'wave_tags = Array[String](["INVASION", "SUPPORT"])',
        'special_tags = Array[String](["aura_heal"])',
        "special_values = {",
        '&"aura_heal": {',
        '&"radius": 8.0,',
        '&"heal_per_sec": 5.0',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "totem_carrier.tres",
    [
        'id = "totem_carrier"',
        "enemy_type = 14",
        'display_name = "Totem Carrier"',
        "max_hp = 130",
        "move_speed = 3.0",
        "damage = 8",
        "attack_cooldown = 2.0",
        "attack_range = 2.0",
        "armor_type = 0",
        "gold_reward = 16",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.6, 0.6, 0.3, 1.0)",
        "damage_immunities = []",
        "tier = 2",
        "point_cost = 10",
        'wave_tags = Array[String](["INVASION", "SUPPORT"])',
        'special_tags = Array[String](["aura_heal"])',
        "special_values = {",
        '&"aura_heal": {',
        '&"radius": 6.0,',
        '&"heal_per_sec": 3.0',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "harpy_scout.tres",
    [
        'id = "harpy_scout"',
        "enemy_type = 15",
        'display_name = "Harpy Scout"',
        "max_hp = 80",
        "move_speed = 7.0",
        "damage = 14",
        "attack_cooldown = 1.5",
        "attack_range = 2.0",
        "armor_type = 3",
        "gold_reward = 16",
        "is_ranged = false",
        "is_flying = true",
        "color = Color(0.7, 0.5, 0.8, 1.0)",
        "damage_immunities = []",
        "tier = 2",
        "point_cost = 12",
        'wave_tags = Array[String](["AIRSTRIKE", "RUSH"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_shieldbearer.tres",
    [
        'id = "orc_shieldbearer"',
        "enemy_type = 16",
        'display_name = "Orc Shieldbearer"',
        "max_hp = 350",
        "move_speed = 2.5",
        "damage = 22",
        "attack_cooldown = 1.5",
        "attack_range = 1.8",
        "armor_type = 1",
        "gold_reward = 30",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.5, 0.5, 0.6, 1.0)",
        "damage_immunities = []",
        "tier = 3",
        "point_cost = 15",
        'wave_tags = Array[String](["HEAVY", "INVASION"])',
        'special_tags = Array[String](["shield"])',
        "special_values = {",
        '&"shield": {',
        '&"shield_hp": 80,',
        '&"shield_armor": &"HEAVY_ARMOR"',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_berserker.tres",
    [
        'id = "orc_berserker"',
        "enemy_type = 17",
        'display_name = "Orc Berserker"',
        "max_hp = 260",
        "move_speed = 3.5",
        "damage = 35",
        "attack_cooldown = 1.0",
        "attack_range = 1.8",
        "armor_type = 0",
        "gold_reward = 32",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.9, 0.1, 0.1, 1.0)",
        "damage_immunities = []",
        "tier = 3",
        "point_cost = 18",
        'wave_tags = Array[String](["RUSH", "INVASION"])',
        'special_tags = Array[String](["charge"])',
        "special_values = {",
        '&"charge": {',
        '&"enrage_hp_pct": 0.5,',
        '&"speed_bonus": 0.50',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_saboteur.tres",
    [
        'id = "orc_saboteur"',
        "enemy_type = 18",
        'display_name = "Orc Saboteur"',
        "max_hp = 180",
        "move_speed = 4.0",
        "damage = 15",
        "attack_cooldown = 2.0",
        "attack_range = 2.5",
        "armor_type = 0",
        "gold_reward = 28",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.4, 0.4, 0.4, 1.0)",
        "damage_immunities = []",
        "tier = 3",
        "point_cost = 16",
        'wave_tags = Array[String](["INVASION"])',
        'special_tags = Array[String](["disable_building"])',
        "special_values = {",
        '&"disable_building": {',
        '&"disable_duration": 4.0',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "hexbreaker.tres",
    [
        'id = "hexbreaker"',
        "enemy_type = 19",
        'display_name = "Hexbreaker"',
        "max_hp = 200",
        "move_speed = 3.5",
        "damage = 18",
        "attack_cooldown = 1.8",
        "attack_range = 2.0",
        "armor_type = 0",
        "gold_reward = 30",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.8, 0.3, 0.8, 1.0)",
        "damage_immunities = []",
        "tier = 3",
        "point_cost = 14",
        'wave_tags = Array[String](["INVASION", "SUPPORT"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "wyvern_rider.tres",
    [
        'id = "wyvern_rider"',
        "enemy_type = 20",
        'display_name = "Wyvern Rider"',
        "max_hp = 220",
        "move_speed = 5.5",
        "damage = 28",
        "attack_cooldown = 2.0",
        "attack_range = 12.0",
        "armor_type = 3",
        "gold_reward = 35",
        "is_ranged = true",
        "is_flying = true",
        "color = Color(0.7, 0.3, 0.1, 1.0)",
        "damage_immunities = []",
        "tier = 3",
        "point_cost = 20",
        'wave_tags = Array[String](["AIRSTRIKE"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "brood_carrier.tres",
    [
        'id = "brood_carrier"',
        "enemy_type = 21",
        'display_name = "Brood Carrier"',
        "max_hp = 300",
        "move_speed = 2.5",
        "damage = 20",
        "attack_cooldown = 1.5",
        "attack_range = 2.0",
        "armor_type = 0",
        "gold_reward = 28",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.6, 0.4, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 3",
        "point_cost = 18",
        'wave_tags = Array[String](["HEAVY", "INVASION"])',
        'special_tags = Array[String](["on_death_spawn"])',
        "special_values = {",
        '&"on_death_spawn": {',
        '&"spawn_type": &"ORC_RATLING",',
        '&"spawn_count": 3',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "troll.tres",
    [
        'id = "troll"',
        "enemy_type = 22",
        'display_name = "Troll"',
        "max_hp = 800",
        "move_speed = 2.0",
        "damage = 55",
        "attack_cooldown = 2.0",
        "attack_range = 2.5",
        "armor_type = 1",
        "gold_reward = 55",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.3, 0.6, 0.3, 1.0)",
        "damage_immunities = []",
        "tier = 4",
        "point_cost = 35",
        'wave_tags = Array[String](["HEAVY"])',
        'special_tags = Array[String](["regen"])',
        "special_values = {",
        '&"regen": {',
        '&"hp_per_sec": 8.0',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "ironclad_crusher.tres",
    [
        'id = "ironclad_crusher"',
        "enemy_type = 23",
        'display_name = "Ironclad Crusher"',
        "max_hp = 700",
        "move_speed = 2.0",
        "damage = 60",
        "attack_cooldown = 2.0",
        "attack_range = 2.5",
        "armor_type = 1",
        "gold_reward = 55",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.6, 0.6, 0.6, 1.0)",
        "damage_immunities = []",
        "tier = 4",
        "point_cost = 38",
        'wave_tags = Array[String](["HEAVY"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_ogre.tres",
    [
        'id = "orc_ogre"',
        "enemy_type = 24",
        'display_name = "Orc Ogre"',
        "max_hp = 900",
        "move_speed = 1.8",
        "damage = 70",
        "attack_cooldown = 2.5",
        "attack_range = 3.0",
        "armor_type = 1",
        "gold_reward = 60",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.5, 0.4, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 4",
        "point_cost = 42",
        'wave_tags = Array[String](["HEAVY"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "war_boar.tres",
    [
        'id = "war_boar"',
        "enemy_type = 25",
        'display_name = "War Boar"',
        "max_hp = 600",
        "move_speed = 4.0",
        "damage = 50",
        "attack_cooldown = 1.5",
        "attack_range = 2.0",
        "armor_type = 1",
        "gold_reward = 50",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.7, 0.4, 0.1, 1.0)",
        "damage_immunities = []",
        "tier = 4",
        "point_cost = 35",
        'wave_tags = Array[String](["HEAVY", "RUSH"])',
        'special_tags = Array[String](["charge"])',
        "special_values = {",
        '&"charge": {',
        '&"dash_speed": 12.0,',
        '&"dash_damage": 40',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orc_skythrower.tres",
    [
        'id = "orc_skythrower"',
        "enemy_type = 26",
        'display_name = "Orc Skythrower"',
        "max_hp = 400",
        "move_speed = 2.5",
        "damage = 35",
        "attack_cooldown = 2.5",
        "attack_range = 20.0",
        "armor_type = 0",
        "gold_reward = 48",
        "is_ranged = true",
        "is_flying = false",
        "color = Color(0.7, 0.5, 0.3, 1.0)",
        "damage_immunities = []",
        "tier = 4",
        "point_cost = 28",
        'wave_tags = Array[String](["ARTILLERY", "AIRSTRIKE"])',
        'special_tags = Array[String](["anti_air"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "warlords_guard.tres",
    [
        'id = "warlords_guard"',
        "enemy_type = 27",
        'display_name = "Warlord\'s Guard"',
        "max_hp = 1200",
        "move_speed = 2.5",
        "damage = 75",
        "attack_cooldown = 1.5",
        "attack_range = 2.5",
        "armor_type = 1",
        "gold_reward = 120",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.6, 0.5, 0.2, 1.0)",
        "damage_immunities = []",
        "tier = 5",
        "point_cost = 50",
        'wave_tags = Array[String](["HEAVY", "INVASION"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "orcish_spirit.tres",
    [
        'id = "orcish_spirit"',
        "enemy_type = 28",
        'display_name = "Orcish Spirit"',
        "max_hp = 800",
        "move_speed = 4.5",
        "damage = 60",
        "attack_cooldown = 1.5",
        "attack_range = 2.0",
        "armor_type = 3",
        "gold_reward = 130",
        "is_ranged = false",
        "is_flying = true",
        "color = Color(0.7, 0.5, 1.0, 1.0)",
        "damage_immunities = [2]",
        "tier = 5",
        "point_cost = 48",
        'wave_tags = Array[String](["AIRSTRIKE", "HEAVY"])',
        'balance_status = "UNTESTED"',
    ],
)

wed(
    "plague_herald.tres",
    [
        'id = "plague_herald"',
        "enemy_type = 29",
        'display_name = "Plague Herald"',
        "max_hp = 1500",
        "move_speed = 2.0",
        "damage = 65",
        "attack_cooldown = 2.0",
        "attack_range = 2.5",
        "armor_type = 1",
        "gold_reward = 150",
        "is_ranged = false",
        "is_flying = false",
        "color = Color(0.4, 0.7, 0.3, 1.0)",
        "damage_immunities = []",
        "tier = 5",
        "point_cost = 50",
        'wave_tags = Array[String](["HEAVY", "SUPPORT"])',
        'special_tags = Array[String](["aura_heal", "regen"])',
        "special_values = {",
        '&"aura_heal": {',
        '&"radius": 10.0,',
        '&"heal_per_sec": 10.0',
        "},",
        '&"regen": {',
        '&"hp_per_sec": 12.0',
        "}",
        "}",
        'balance_status = "UNTESTED"',
    ],
)

# --- Ally stubs ---
ally(
    "wolf_alpha.tres",
    [
        'ally_id = "wolf_alpha"',
        'display_name = "Wolf Alpha"',
        "ally_class = 0",
        "role = 0",
        "damage_type = 0",
        "max_hp = 80",
        "move_speed = 5.0",
        "attack_damage = 12.0",
        "attack_range = 1.8",
        "attack_cooldown = 1.0",
        "patrol_radius = 10.0",
        "is_unique = false",
        "debug_color = Color(0.6, 0.5, 0.3, 1.0)",
    ],
)

ally(
    "wolf_pup.tres",
    [
        'ally_id = "wolf_pup"',
        'display_name = "Wolf Pup"',
        "ally_class = 0",
        "role = 0",
        "damage_type = 0",
        "max_hp = 50",
        "move_speed = 6.0",
        "attack_damage = 7.0",
        "attack_range = 1.5",
        "attack_cooldown = 1.2",
        "patrol_radius = 10.0",
        "is_unique = false",
        "debug_color = Color(0.7, 0.6, 0.4, 1.0)",
    ],
)

ally(
    "bear_alpha.tres",
    [
        'ally_id = "bear_alpha"',
        'display_name = "Bear"',
        "ally_class = 0",
        "role = 0",
        "damage_type = 0",
        "max_hp = 200",
        "move_speed = 3.5",
        "attack_damage = 22.0",
        "attack_range = 2.2",
        "attack_cooldown = 1.5",
        "patrol_radius = 8.0",
        "is_unique = false",
        "debug_color = Color(0.5, 0.3, 0.1, 1.0)",
    ],
)

ally(
    "knight_captain.tres",
    [
        'ally_id = "knight_captain"',
        'display_name = "Knight Captain"',
        "ally_class = 0",
        "role = 0",
        "damage_type = 0",
        "max_hp = 180",
        "move_speed = 3.5",
        "attack_damage = 28.0",
        "attack_range = 2.0",
        "attack_cooldown = 1.0",
        "patrol_radius = 12.0",
        "is_unique = false",
        "debug_color = Color(0.8, 0.7, 0.3, 1.0)",
    ],
)

ally(
    "militia_archer.tres",
    [
        'ally_id = "militia_archer"',
        'display_name = "Militia Archer"',
        "ally_class = 1",
        "role = 1",
        "damage_type = 0",
        "max_hp = 90",
        "move_speed = 4.0",
        "attack_damage = 14.0",
        "attack_range = 14.0",
        "attack_cooldown = 1.5",
        "patrol_radius = 12.0",
        "is_unique = false",
        "is_ranged = true",
        "debug_color = Color(0.7, 0.6, 0.3, 1.0)",
    ],
)

# --- Research nodes (18 new) ---
rnode(
    "unlock_spike_spitter.tres",
    "unlock_spike_spitter",
    "Spike Spitter",
    1,
    [],
    "Unlock: Spike Spitter",
)
rnode("unlock_wolfden.tres", "unlock_wolfden", "Wolf Den", 2, [], "Unlock: Wolf Den")
rnode("unlock_crow_roost.tres", "unlock_crow_roost", "Crow Roost", 1, [], "Unlock: Crow Roost")
rnode("unlock_frost_pinger.tres", "unlock_frost_pinger", "Frost Pinger", 2, [], "Unlock: Frost Pinger")
rnode(
    "unlock_greatbow_turret.tres",
    "unlock_greatbow_turret",
    "Greatbow Turret",
    2,
    ["unlock_spike_spitter"],
    "Unlock: Greatbow Turret",
)
rnode(
    "unlock_bear_den.tres", "unlock_bear_den", "Bear Den", 3, ["unlock_wolfden"], "Unlock: Bear Den"
)
rnode(
    "unlock_warden_shrine.tres",
    "unlock_warden_shrine",
    "Warden Shrine",
    2,
    ["unlock_wolfden"],
    "Unlock: Warden Shrine",
)
rnode(
    "unlock_chain_lightning.tres",
    "unlock_chain_lightning",
    "Chain Lightning",
    3,
    ["unlock_crow_roost"],
    "Unlock: Chain Lightning",
)
rnode(
    "unlock_gust_cannon.tres",
    "unlock_gust_cannon",
    "Gust Cannon",
    2,
    ["unlock_crow_roost"],
    "Unlock: Gust Cannon",
)
rnode(
    "unlock_siege_ballista.tres",
    "unlock_siege_ballista",
    "Siege Ballista",
    3,
    ["unlock_ballista"],
    "Unlock: Siege Ballista",
)
rnode(
    "unlock_molten_caster.tres",
    "unlock_molten_caster",
    "Molten Caster",
    2,
    ["unlock_frost_pinger"],
    "Unlock: Molten Caster",
)
rnode(
    "unlock_arcane_lens.tres",
    "unlock_arcane_lens",
    "Arcane Lens",
    3,
    ["unlock_frost_pinger"],
    "Unlock: Arcane Lens",
)
rnode(
    "unlock_fortress_cannon.tres",
    "unlock_fortress_cannon",
    "Fortress Cannon",
    4,
    ["unlock_siege_ballista"],
    "Unlock: Fortress Cannon",
)
rnode(
    "unlock_dragon_forge.tres",
    "unlock_dragon_forge",
    "Dragon Forge",
    5,
    ["unlock_molten_caster"],
    "Unlock: Dragon Forge",
)
rnode(
    "unlock_void_obelisk.tres",
    "unlock_void_obelisk",
    "Void Obelisk",
    5,
    ["unlock_arcane_lens"],
    "Unlock: Void Obelisk",
)
rnode(
    "unlock_plague_cauldron.tres",
    "unlock_plague_cauldron",
    "Plague Cauldron",
    4,
    ["unlock_arcane_lens"],
    "Unlock: Plague Cauldron",
)
rnode(
    "unlock_barracks_fortress.tres",
    "unlock_barracks_fortress",
    "Barracks Fortress",
    5,
    ["unlock_bear_den"],
    "Unlock: Barracks Fortress",
)
rnode(
    "unlock_citadel_aura.tres",
    "unlock_citadel_aura",
    "Citadel Aura",
    6,
    ["unlock_warden_shrine"],
    "Unlock: Citadel Aura",
)

print("enemies", len(list(ED.glob("*.tres"))))
print("allies", len(list(AD.glob("*.tres"))))
print("research", len(list(RD.glob("*.tres"))))
