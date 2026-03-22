## signal_bus.gd
## Central signal registry for all cross-system communication in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# === COMBAT ===
@warning_ignore("unused_signal")
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
## POST-MVP: enemy_reached_tower is not emitted in MVP. EnemyBase calls Tower.take_damage() directly.
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

# === WAVES ===
@warning_ignore("unused_signal")
signal wave_countdown_started(wave_number: int, seconds_remaining: float)
@warning_ignore("unused_signal")
signal wave_started(wave_number: int, enemy_count: int)
@warning_ignore("unused_signal")
signal wave_cleared(wave_number: int)
@warning_ignore("unused_signal")
signal all_waves_cleared()

# === ECONOMY ===
@warning_ignore("unused_signal")
signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

# === BUILDINGS ===
@warning_ignore("unused_signal")
signal building_placed(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_sold(slot_index: int, building_type: Types.BuildingType)
@warning_ignore("unused_signal")
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
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

# === BUILD MODE ===
@warning_ignore("unused_signal")
signal build_mode_entered()
@warning_ignore("unused_signal")
signal build_mode_exited()

# === RESEARCH ===
@warning_ignore("unused_signal")
signal research_unlocked(node_id: String)

# === SHOP ===
@warning_ignore("unused_signal")
signal shop_item_purchased(item_id: String)
## Emitted by ShopManager when a mana draught has been consumed by GameManager at mission start.
@warning_ignore("unused_signal")
signal mana_draught_consumed()
