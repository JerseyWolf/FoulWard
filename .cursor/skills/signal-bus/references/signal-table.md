# Signal Table — Foul Ward SignalBus

**Source of truth:** `autoloads/signal_bus.gd`  
**Count:** 67 `signal` declarations (verified 2026-04-14 against `autoloads/signal_bus.gd`).

This table mirrors the file order and parameter types in code. When in doubt, read `signal_bus.gd` directly.

---

## Combat

| Signal | Parameters |
|---|---|
| `enemy_killed` | `enemy_type: Types.EnemyType, position: Vector3, gold_reward: int` |
| `enemy_reached_tower` | `enemy_type: Types.EnemyType, damage: int` |
| `tower_damaged` | `current_hp: int, max_hp: int` |
| `tower_destroyed` | *(none)* |
| `projectile_fired` | `weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3` |

## Arnulf + allies

| Signal | Parameters |
|---|---|
| `arnulf_state_changed` | `new_state: Types.ArnulfState` |
| `arnulf_incapacitated` | *(none)* |
| `arnulf_recovered` | *(none)* |
| `ally_spawned` | `ally_id: String, building_instance_id: String` |
| `ally_died` | `ally_id: String, building_instance_id: String` |
| `ally_squad_wiped` | `building_instance_id: String` |
| `ally_downed` | `ally_id: String` |
| `ally_recovered` | `ally_id: String` |
| `ally_killed` | `ally_id: String` |
| `ally_state_changed` | `ally_id: String, new_state: String` |

## Bosses

| Signal | Parameters |
|---|---|
| `boss_spawned` | `boss_id: String` |
| `boss_killed` | `boss_id: String` |
| `campaign_boss_attempted` | `day_index: int, success: bool` |

## Waves

| Signal | Parameters |
|---|---|
| `wave_countdown_started` | `wave_number: int, seconds_remaining: float` |
| `wave_started` | `wave_number: int, enemy_count: int` |
| `enemy_spawned` | `enemy_type: Types.EnemyType, position: Vector2` |
| `enemy_enraged` | `enemy_instance_id: String` |
| `wave_cleared` | `wave_number: int` |
| `all_waves_cleared` | *(none)* |

## Economy

| Signal | Parameters |
|---|---|
| `resource_changed` | `resource_type: Types.ResourceType, new_amount: int` |

## Territories / world map

| Signal | Parameters |
|---|---|
| `territory_state_changed` | `territory_id: String` |
| `world_map_updated` | *(none)* |

## Terrain / nav

| Signal | Parameters |
|---|---|
| `enemy_entered_terrain_zone` | `enemy: Node, speed_multiplier: float` |
| `enemy_exited_terrain_zone` | `enemy: Node, speed_multiplier: float` |
| `terrain_prop_destroyed` | `prop: Node, world_position: Vector3` |
| `nav_mesh_rebake_requested` | *(none)* — **MVP:** not emitted; terrain bake is static; buildings use obstacles. |

## Buildings / Florence

| Signal | Parameters |
|---|---|
| `building_placed` | `slot_index: int, building_type: Types.BuildingType` |
| `building_sold` | `slot_index: int, building_type: Types.BuildingType` |
| `building_upgraded` | `slot_index: int, building_type: Types.BuildingType` |
| `building_dealt_damage` | `instance_id: String, damage: float, enemy_id: String` |
| `florence_damaged` | `amount: int, source_enemy_id: String` |
| `building_destroyed` | `slot_index: int` *(POST-MVP stub)* |

## Spells / mana

| Signal | Parameters |
|---|---|
| `spell_cast` | `spell_id: String` |
| `spell_ready` | `spell_id: String` |
| `mana_changed` | `current_mana: int, max_mana: int` |

## Game state / Florence meta

| Signal | Parameters |
|---|---|
| `game_state_changed` | `old_state: Types.GameState, new_state: Types.GameState` |
| `mission_started` | `mission_number: int` |
| `mission_won` | `mission_number: int` |
| `mission_failed` | `mission_number: int` |
| `florence_state_changed` | *(none)* |

## Campaign / day

| Signal | Parameters |
|---|---|
| `campaign_started` | `campaign_id: String` |
| `day_started` | `day_index: int` |
| `day_won` | `day_index: int` |
| `day_failed` | `day_index: int` |
| `campaign_completed` | `campaign_id: String` |

## Dialogue

| Signal | Parameters |
|---|---|
| `dialogue_line_started` | `entry_id: String, character_id: String` |
| `dialogue_line_finished` | `entry_id: String, character_id: String` |

## Build mode

| Signal | Parameters |
|---|---|
| `build_mode_entered` | *(none)* |
| `build_mode_exited` | *(none)* |
| `build_phase_started` | *(none)* |
| `combat_phase_started` | *(none)* |

## Research

| Signal | Parameters |
|---|---|
| `research_unlocked` | `node_id: String` |
| `research_node_unlocked` | `node_id: String` |
| `research_points_changed` | `points: int` |

## Shop

| Signal | Parameters |
|---|---|
| `shop_item_purchased` | `item_id: String` |
| `mana_draught_consumed` | *(none)* |

## Weapons / enchantments

| Signal | Parameters |
|---|---|
| `weapon_upgraded` | `weapon_slot: Types.WeaponSlot, new_level: int` |
| `enchantment_applied` | `weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String` |
| `enchantment_removed` | `weapon_slot: Types.WeaponSlot, slot_type: String` |

## Mercenaries / roster

| Signal | Parameters |
|---|---|
| `mercenary_offer_generated` | `ally_id: String` |
| `mercenary_recruited` | `ally_id: String` |
| `ally_roster_changed` | *(none)* |
