## signal_bus.gd
## Central signal registry for all cross-system communication in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# === COMBAT ===
@warning_ignore("unused_signal")
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
## Emitted once per enemy the first time it deals damage to the central tower (leak / reach metric).
@warning_ignore("unused_signal")
signal enemy_reached_tower(enemy_type: Types.EnemyType, damage: int)
@warning_ignore("unused_signal")
signal tower_damaged(current_hp: int, max_hp: int)
@warning_ignore("unused_signal")
signal tower_destroyed()
@warning_ignore("unused_signal")
signal projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)
@warning_ignore("unused_signal")
signal arnulf_state_changed(new_state: Types.ArnulfState)
@warning_ignore("unused_signal")
signal arnulf_incapacitated()
@warning_ignore("unused_signal")
signal arnulf_recovered()

# === ALLIES ===
## Second arg is empty for roster allies (e.g. Arnulf); set for summoner-tower allies.
@warning_ignore("unused_signal")
signal ally_spawned(ally_id: String, building_instance_id: String)
## Emitted when a summoner ally dies (permanent death, not downed).
@warning_ignore("unused_signal")
signal ally_died(ally_id: String, building_instance_id: String)
## Emitted when the last living ally for a summoner building is removed.
@warning_ignore("unused_signal")
signal ally_squad_wiped(building_instance_id: String)
@warning_ignore("unused_signal")
signal ally_downed(ally_id: String)
@warning_ignore("unused_signal")
signal ally_recovered(ally_id: String)
@warning_ignore("unused_signal")
signal ally_killed(ally_id: String)
# POST-MVP: detailed ally state tracking.
@warning_ignore("unused_signal")
signal ally_state_changed(ally_id: String, new_state: String)

# === BOSSES (Prompt 10) ===
@warning_ignore("unused_signal")
signal boss_spawned(boss_id: String)
@warning_ignore("unused_signal")
signal boss_killed(boss_id: String)
@warning_ignore("unused_signal")
signal campaign_boss_attempted(day_index: int, success: bool)

# === WAVES ===
@warning_ignore("unused_signal")
signal wave_countdown_started(wave_number: int, seconds_remaining: float)
@warning_ignore("unused_signal")
signal wave_started(wave_number: int, enemy_count: int)
## Emitted once per enemy spawned into the mission (Prompt 49 / WaveManager; Prompt 9: type + XZ position).
@warning_ignore("unused_signal")
signal enemy_spawned(enemy_type: Types.EnemyType, position: Vector2)
## Emitted when an enemy with [code]charge[/code] special first crosses its enrage HP threshold.
@warning_ignore("unused_signal")
signal enemy_enraged(enemy_instance_id: String)
@warning_ignore("unused_signal")
signal wave_cleared(wave_number: int)
@warning_ignore("unused_signal")
signal all_waves_cleared()

# === ECONOMY ===
@warning_ignore("unused_signal")
signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

# === TERRITORIES / WORLD MAP ===
@warning_ignore("unused_signal")
signal territory_state_changed(territory_id: String)
@warning_ignore("unused_signal")
signal world_map_updated()

# === TERRAIN (battlefield zones, navmesh) ===
@warning_ignore("unused_signal")
signal enemy_entered_terrain_zone(enemy: Node, speed_multiplier: float)
@warning_ignore("unused_signal")
signal enemy_exited_terrain_zone(enemy: Node, speed_multiplier: float)
@warning_ignore("unused_signal")
signal terrain_prop_destroyed(prop: Node, world_position: Vector3)
@warning_ignore("unused_signal")
signal nav_mesh_rebake_requested()

# === BUILDINGS ===
@warning_ignore("unused_signal")
signal building_placed(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_sold(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
## Building projectile / aura attribution for CombatStatsTracker (placed_instance_id string).
@warning_ignore("unused_signal")
signal building_dealt_damage(instance_id: String, damage: float, enemy_id: String)
## Florence (central tower) took damage — optional alternative to inferring from tower_damaged.
@warning_ignore("unused_signal")
signal florence_damaged(amount: int, source_enemy_id: String)
## POST-MVP: building_destroyed is not emitted in MVP. Buildings cannot take damage in MVP.
@warning_ignore("unused_signal")
signal building_destroyed(slot_index: int)

# === SPELLS ===
@warning_ignore("unused_signal")
signal spell_cast(spell_id: String)
@warning_ignore("unused_signal")
signal spell_ready(spell_id: String)
@warning_ignore("unused_signal")
signal mana_changed(current_mana: int, max_mana: int)

# === GAME STATE ===
@warning_ignore("unused_signal")
signal game_state_changed(old_state: Types.GameState, new_state: Types.GameState)
@warning_ignore("unused_signal")
signal mission_started(mission_number: int)
@warning_ignore("unused_signal")
signal mission_won(mission_number: int)
@warning_ignore("unused_signal")
signal mission_failed(mission_number: int)

# Florence / campaign meta-state.
@warning_ignore("unused_signal")
signal florence_state_changed()

# Campaign / day-level signals.
# mission_* signals remain mission-level; in the current short campaign they
# correspond 1:1 to days (one mission per day). CampaignManager wraps them.
@warning_ignore("unused_signal")
signal campaign_started(campaign_id: String)
@warning_ignore("unused_signal")
signal day_started(day_index: int)
@warning_ignore("unused_signal")
signal day_won(day_index: int)
@warning_ignore("unused_signal")
signal day_failed(day_index: int)
@warning_ignore("unused_signal")
signal campaign_completed(campaign_id: String)

# === BUILD MODE ===
@warning_ignore("unused_signal")
signal build_mode_entered()
@warning_ignore("unused_signal")
signal build_mode_exited()

# === RESEARCH ===
@warning_ignore("unused_signal")
signal research_unlocked(node_id: String)
## Prompt 11: alias event for research UI; mirrors [signal research_unlocked].
@warning_ignore("unused_signal")
signal research_node_unlocked(node_id: String)
## Prompt 11: current research material (RP) for in-mission research panel.
@warning_ignore("unused_signal")
signal research_points_changed(points: int)

# === SHOP ===
@warning_ignore("unused_signal")
signal shop_item_purchased(item_id: String)
## Emitted by ShopManager when a mana draught has been consumed by GameManager at mission start.
@warning_ignore("unused_signal")
signal mana_draught_consumed()

# === WEAPONS ===
@warning_ignore("unused_signal")
signal weapon_upgraded(weapon_slot: Types.WeaponSlot, new_level: int)

# === ENCHANTMENTS ===
@warning_ignore("unused_signal")
signal enchantment_applied(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String)
@warning_ignore("unused_signal")
signal enchantment_removed(weapon_slot: Types.WeaponSlot, slot_type: String)

# === CAMPAIGN / ALLY ROSTER (Prompt 12) ===
@warning_ignore("unused_signal")
signal mercenary_offer_generated(ally_id: String)
@warning_ignore("unused_signal")
signal mercenary_recruited(ally_id: String)
@warning_ignore("unused_signal")
signal ally_roster_changed()
