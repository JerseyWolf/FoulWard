## day_config.gd
## Single-day campaign configuration resource.
## Owned by CampaignConfig; read by CampaignManager and WaveManager.
## POST-MVP: extend with territory/world-map fields.

class_name DayConfig
extends Resource

## 1-based day index inside the campaign.
@export var day_index: int = 1

## Mission index used by MVP systems (1–5). Short campaign: days 1–5 map 1:1 to missions 1–5.
## Days beyond 5 may reuse mission 5 as placeholder content (# ASSUMPTION / # PLACEHOLDER / # TUNING).
@export var mission_index: int = 1

## Human-friendly day name for UI.
@export var display_name: String = ""
## Day description shown in hub/briefing.
@export var description: String = ""

## Active faction for this day. Must match a FactionData.faction_id in the registry.
@export var faction_id: String = "DEFAULT_MIXED"
## POST-MVP: world map / territory UI.
@export var territory_id: String = ""

## Marks this day as eligible for mini-boss schedule queries (WaveManager hook).
@export var is_mini_boss_day: bool = false
## Alias for data-driven mini-boss days (Prompt 10); WaveManager treats this like is_mini_boss_day.
@export var is_mini_boss: bool = false
## TUNING: mark final day boss.
@export var is_final_boss: bool = false
## BossData.boss_id for final boss or repeat boss-attack days.
@export var boss_id: String = ""
## True when this day is a post–Day-50 boss strike on a held territory (Prompt 10).
@export var is_boss_attack_day: bool = false

## TUNING: desired wave count for this day.
@export var base_wave_count: int = 10

## TUNING: per-day multipliers.
@export var enemy_hp_multiplier: float = 1.0
@export var enemy_damage_multiplier: float = 1.0
@export var gold_reward_multiplier: float = 1.0
