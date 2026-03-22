## signal_bus.gd
## Central signal registry for all cross-system communication in FOUL WARD.
## Simulation API: all public methods callable without UI nodes present.

extends Node

# === COMBAT ===
signal enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)
## POST-MVP: enemy_reached_tower is not emitted in MVP. EnemyBase calls Tower.take_damage() directly.
signal enemy_reached_tower(enemy_type: Types.EnemyType, damage: int)
signal tower_damaged(current_hp: int, max_hp: int)
signal tower_destroyed()
signal projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)
signal arnulf_state_changed(new_state: Types.ArnulfState)
signal arnulf_incapacitated()
signal arnulf_recovered()

# === WAVES ===
signal wave_countdown_started(wave_number: int, seconds_remaining: float)
signal wave_started(wave_number: int, enemy_count: int)
signal wave_cleared(wave_number: int)
signal all_waves_cleared()

# === ECONOMY ===
signal resource_changed(resource_type: Types.ResourceType, new_amount: int)

# === BUILDINGS ===
signal building_placed(slot_index: int, building_type: Types.BuildingType)
signal building_sold(slot_index: int, building_type: Types.BuildingType)
signal building_upgraded(slot_index: int, building_type: Types.BuildingType)
## POST-MVP: building_destroyed is not emitted in MVP. Buildings cannot take damage in MVP.
signal building_destroyed(slot_index: int)

# === SPELLS ===
signal spell_cast(spell_id: String)
signal spell_ready(spell_id: String)
signal mana_changed(current_mana: int, max_mana: int)

# === GAME STATE ===
signal game_state_changed(old_state: Types.GameState, new_state: Types.GameState)
signal mission_started(mission_number: int)
signal mission_won(mission_number: int)
signal mission_failed(mission_number: int)

# === BUILD MODE ===
signal build_mode_entered()
signal build_mode_exited()

# === RESEARCH ===
signal research_unlocked(node_id: String)

# === SHOP ===
signal shop_item_purchased(item_id: String)
## Emitted by ShopManager when a mana draught has been consumed by GameManager at mission start.
signal mana_draught_consumed()
