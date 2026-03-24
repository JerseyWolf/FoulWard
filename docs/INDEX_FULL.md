# Foul Ward Code Index (Full, first-party only)

Scope: `autoloads/`, `scripts/`, `scenes/`, `ui/` (excluding `addons/`, `MCPs/`, `tests/`).

## Autoload Signal Registry (SignalBus)

Path: `autoloads/signal_bus.gd`

- Combat
  - `enemy_killed(enemy_type: Types.EnemyType, position: Vector3, gold_reward: int)`
  - `enemy_reached_tower(enemy_type: Types.EnemyType, damage: int)` (declared, noted as not emitted in MVP)
  - `tower_damaged(current_hp: int, max_hp: int)`
  - `tower_destroyed()`
  - `projectile_fired(weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3)`
  - `arnulf_state_changed(new_state: Types.ArnulfState)`
  - `arnulf_incapacitated()`
  - `arnulf_recovered()`
- Waves
  - `wave_countdown_started(wave_number: int, seconds_remaining: float)`
  - `wave_started(wave_number: int, enemy_count: int)`
  - `wave_cleared(wave_number: int)`
  - `all_waves_cleared()`
- Economy/Build/Spells/Game
  - `resource_changed(resource_type: Types.ResourceType, new_amount: int)`
  - `building_placed(slot_index: int, building_type: Types.BuildingType)`
  - `building_sold(slot_index: int, building_type: Types.BuildingType)`
  - `building_upgraded(slot_index: int, building_type: Types.BuildingType)`
  - `building_destroyed(slot_index: int)` (declared, noted as not emitted in MVP)
  - `spell_cast(spell_id: String)`
  - `spell_ready(spell_id: String)`
  - `mana_changed(current_mana: int, max_mana: int)`
  - `game_state_changed(old_state: Types.GameState, new_state: Types.GameState)`
  - `mission_started(mission_number: int)`
  - `mission_won(mission_number: int)`
  - `mission_failed(mission_number: int)`
  - `build_mode_entered()`
  - `build_mode_exited()`
  - `research_unlocked(node_id: String)`
  - `shop_item_purchased(item_id: String)`
  - `mana_draught_consumed()`

---

## Resource Class Fields (`scripts/resources/*.gd`)

### `BuildingData` (`scripts/resources/building_data.gd`)
- `building_type: Types.BuildingType` - enum identity for the building.
- `display_name: String` - UI name.
- `gold_cost: int`, `material_cost: int` - placement cost.
- `upgrade_gold_cost: int`, `upgrade_material_cost: int` - upgrade cost.
- `damage: float`, `upgraded_damage: float` - base/upgraded damage.
- `fire_rate: float` - shots per second.
- `attack_range: float`, `upgraded_range: float` - base/upgraded range.
- `damage_type: Types.DamageType` - projectile damage type.
- `targets_air: bool`, `targets_ground: bool` - targeting flags.
- `is_locked: bool`, `unlock_research_id: String` - unlock gate.
- `research_damage_boost_id: String`, `research_range_boost_id: String` - passive boost unlock IDs.
- `color: Color` - mesh tint.
- `target_priority: Types.TargetPriority` - targeting strategy marker (currently closest-target logic in runtime).

### `EnemyData` (`scripts/resources/enemy_data.gd`)
- `enemy_type: Types.EnemyType` - enum identity.
- `display_name: String` - name/label.
- `max_hp: int`, `move_speed: float`.
- `damage: int`, `attack_range: float`, `attack_cooldown: float`.
- `armor_type: Types.ArmorType`.
- `gold_reward: int`.
- `is_ranged: bool`, `is_flying: bool`.
- `color: Color`.
- `damage_immunities: Array[Types.DamageType]`.

### `ResearchNodeData` (`scripts/resources/research_node_data.gd`)
- `node_id: String` - unique key.
- `display_name: String`.
- `research_cost: int`.
- `prerequisite_ids: Array[String]`.
- `description: String`.

### `ShopItemData` (`scripts/resources/shop_item_data.gd`)
- `item_id: String`.
- `display_name: String`.
- `gold_cost: int`.
- `material_cost: int`.
- `description: String`.

### `SpellData` (`scripts/resources/spell_data.gd`)
- `spell_id: String`.
- `display_name: String`.
- `mana_cost: int`.
- `cooldown: float`.
- `damage: float`.
- `radius: float`.
- `damage_type: Types.DamageType`.
- `hits_flying: bool`.

### `WeaponData` (`scripts/resources/weapon_data.gd`)
- `weapon_slot: Types.WeaponSlot`.
- `display_name: String`.
- `damage: float`.
- `projectile_speed: float`.
- `reload_time: float`.
- `burst_count: int`.
- `burst_interval: float`.
- `can_target_flying: bool`.

---

## Per-script Index

## Autoloads

### `autoloads/signal_bus.gd`
- **class_name:** none
- **purpose:** global event bus and signal schema for cross-system communication.
- **public methods:** none.
- **exported vars:** none.
- **signals emitted:** none internally (declares all shared signals).
- **dependencies:** `Types` enums for signal payload typing.

### `autoloads/game_manager.gd`
- **class_name:** none
- **purpose:** top-level game-state controller (missions, transitions, build mode, wave sequence starts).
- **public methods:**
  - `start_new_game() -> void` - reset run state/resources/research, enter combat, emit mission start, apply consumables, start waves.
  - `start_next_mission() -> void` - advance mission number, enter briefing, emit mission start.
  - `start_wave_countdown() -> void` - valid only from briefing; enter combat and start wave flow.
  - `enter_build_mode() -> void` - set slowed time, switch to build mode.
  - `exit_build_mode() -> void` - restore time, return to combat.
  - `get_game_state() -> Types.GameState`
  - `get_current_mission() -> int`
  - `get_current_wave() -> int`
- **exported vars:** none.
- **signals emitted with conditions:**
  - `SignalBus.mission_started(current_mission)` on new game and next mission.
  - `SignalBus.build_mode_entered()` when entering build mode.
  - `SignalBus.build_mode_exited()` when leaving build mode.
  - `SignalBus.game_state_changed(old,new)` on every transition.
  - `SignalBus.mission_won(current_mission)` on `all_waves_cleared`.
  - `SignalBus.mission_failed(current_mission)` on tower destruction.
- **dependencies:** `SignalBus`, `Types`, `EconomyManager`, `ResearchManager`, `WaveManager`, `ShopManager`, `Engine`, scene paths under `/root/Main/...`.

### `autoloads/economy_manager.gd`
- **class_name:** none
- **purpose:** authoritative resource counters (gold/building material/research material) and spending/add APIs.
- **public methods:**
  - `add_gold(amount: int) -> void`
  - `spend_gold(amount: int) -> bool`
  - `add_building_material(amount: int) -> void`
  - `spend_building_material(amount: int) -> bool`
  - `add_research_material(amount: int) -> void`
  - `spend_research_material(amount: int) -> bool`
  - `can_afford(gold_cost: int, material_cost: int) -> bool`
  - `get_gold() -> int`
  - `get_building_material() -> int`
  - `get_research_material() -> int`
  - `reset_to_defaults() -> void`
- **exported vars:** none.
- **signals emitted with conditions:**
  - `SignalBus.resource_changed(...)` after any successful add/spend and on reset (all three resources).
- **dependencies:** `SignalBus`, `Types`, `OS` command-line features, enemy kill signal subscription.

### `autoloads/damage_calculator.gd`
- **class_name:** none
- **purpose:** pure armor-vs-damage-type multiplier lookup.
- **public methods:**
  - `calculate_damage(base_damage: float, damage_type: Types.DamageType, armor_type: Types.ArmorType) -> float` - matrix multiply result.
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `Types` enums and internal `DAMAGE_MATRIX`.

### `autoloads/auto_test_driver.gd`
- **class_name:** none
- **purpose:** optional headless integration test runner activated by `--autotest`.
- **public methods:** none (all orchestration helpers are internal).
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `SignalBus`, `GameManager`, `EconomyManager`, `Tower`, `HexGrid`, `WaveManager`, `Types`, `OS`, `Time`, scene tree paths.

---

## scripts/

### `scripts/research_manager.gd`
- **class_name:** `ResearchManager`
- **purpose:** owns unlocked research state; validates prerequisites/costs; unlocks nodes.
- **public methods:**
  - `unlock_node(node_id: String) -> bool` - validate node/prereqs/cost, spend research material, unlock.
  - `is_unlocked(node_id: String) -> bool`
  - `get_available_nodes() -> Array[ResearchNodeData]` - unlocked-filtered, prereq-satisfied nodes.
  - `reset_to_defaults() -> void` - clear unlocks; optional dev unlock modes.
- **exported vars:**
  - `research_nodes: Array[ResearchNodeData]` - full research catalog.
  - `dev_unlock_all_research: bool` - dev shortcut to unlock all.
  - `dev_unlock_anti_air_only: bool` - dev shortcut for anti-air unlock only.
- **signals emitted with conditions:**
  - `SignalBus.research_unlocked(node_id)` on successful unlock.
- **dependencies:** `ResearchNodeData`, `EconomyManager`, `SignalBus`.

### `scripts/shop_manager.gd`
- **class_name:** `ShopManager`
- **purpose:** shop catalog and purchase flow; immediate and mission-start consumable effects.
- **public methods:**
  - `purchase_item(item_id: String) -> bool`
  - `get_available_items() -> Array[ShopItemData]`
  - `can_purchase(item_id: String) -> bool`
  - `consume_mana_draught_pending() -> bool`
  - `consume_arrow_tower_pending() -> bool`
  - `apply_mission_start_consumables() -> void`
- **exported vars:**
  - `shop_catalog: Array[ShopItemData]` - purchasable item definitions.
- **signals emitted with conditions:**
  - `SignalBus.shop_item_purchased(item_id)` after successful purchase.
  - `SignalBus.mana_draught_consumed()` when pending mana draught is applied at mission start.
- **dependencies:** `ShopItemData`, `EconomyManager`, `HexGrid`, `SpellManager`, `Tower`, `SignalBus`, `Types`.

### `scripts/wave_manager.gd`
- **class_name:** `WaveManager`
- **purpose:** mission wave sequence loop: countdowns, spawning, wave-clear/all-clear progression.
- **public methods:**
  - `start_wave_sequence() -> void`
  - `force_spawn_wave(wave_number: int) -> void`
  - `get_living_enemy_count() -> int`
  - `get_current_wave_number() -> int`
  - `is_wave_active() -> bool`
  - `is_counting_down() -> bool`
  - `get_countdown_remaining() -> float`
  - `reset_for_new_mission() -> void`
  - `clear_all_enemies() -> void`
- **exported vars:**
  - `wave_countdown_duration: float` - normal pre-wave countdown.
  - `first_wave_countdown_seconds: float` - first-wave quick countdown.
  - `max_waves: int` - wave cap for current mission.
  - `enemy_data_registry: Array[EnemyData]` - spawn definitions (expected 6 entries).
- **signals emitted with conditions:**
  - `SignalBus.wave_countdown_started(wave,seconds)` when next wave countdown begins.
  - `SignalBus.wave_started(wave,total_spawned)` after spawning a wave.
  - `SignalBus.wave_cleared(current_wave)` when enemy group reaches zero.
  - `SignalBus.all_waves_cleared()` when final wave cleared.
- **dependencies:** `EnemyData`, `EnemyBase` scene preload, `SignalBus`, `Types`, `/root/Main/EnemyContainer`, `/root/Main/SpawnPoints`, `SceneTree` groups.

### `scripts/spell_manager.gd`
- **class_name:** `SpellManager`
- **purpose:** mana pool, cooldown tracking, and spell execution (MVP shockwave).
- **public methods:**
  - `cast_spell(spell_id: String) -> bool`
  - `get_current_mana() -> int`
  - `get_max_mana() -> int`
  - `get_cooldown_remaining(spell_id: String) -> float`
  - `is_spell_ready(spell_id: String) -> bool`
  - `set_mana_to_full() -> void`
  - `reset_to_defaults() -> void`
- **exported vars:**
  - `max_mana: int`
  - `mana_regen_rate: float`
  - `spell_registry: Array[SpellData]`
- **signals emitted with conditions:**
  - `SignalBus.mana_changed(current,max)` on integer mana changes, cast, full-reset, and defaults reset.
  - `SignalBus.spell_ready(spell_id)` when cooldown reaches zero.
  - `SignalBus.spell_cast(spell_id)` on successful cast.
- **dependencies:** `SpellData`, `SignalBus`, `Types`, `EnemyBase` group `"enemies"`.

### `scripts/health_component.gd`
- **class_name:** `HealthComponent`
- **purpose:** reusable HP state + death event for entities.
- **public methods:**
  - `take_damage(amount: float) -> void`
  - `heal(amount: int) -> void`
  - `reset_to_max() -> void`
  - `is_alive() -> bool`
  - `get_current_hp() -> int`
- **exported vars:**
  - `max_hp: int` - maximum HP.
- **signals emitted with conditions:**
  - `health_changed(current_hp,max_hp)` on damage/heal/reset.
  - `health_depleted()` first time HP reaches zero.
- **dependencies:** none external.

### `scripts/input_manager.gd`
- **class_name:** `InputManager`
- **purpose:** map player input to API calls (tower fire, build mode, spell cast, slot selection).
- **public methods:** none (runtime entry is `_unhandled_input`).
- **exported vars:** none.
- **signals emitted:** none directly.
- **dependencies:** `GameManager`, `Types`, `Tower`, `SpellManager`, `HexGrid`, `BuildMenu`, `Camera3D`, `EnemyBase`, physics ray queries.

### `scripts/main_root.gd`
- **class_name:** none
- **purpose:** apply window content scaling after scene ready.
- **public methods:** none.
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** root `Window` via scene tree.

### `scripts/sim_bot.gd`
- **class_name:** `SimBot`
- **purpose:** API-driven simulation bot stub for non-UI runs.
- **public methods:**
  - `activate() -> void`
  - `deactivate() -> void`
  - `bot_enter_build_mode() -> void`
  - `bot_exit_build_mode() -> void`
  - `bot_place_building(slot: int, building_type: Types.BuildingType) -> bool`
  - `bot_cast_spell(spell_id: String) -> bool`
  - `bot_fire_crossbow(target: Vector3) -> void`
  - `bot_advance_wave() -> void`
- **exported vars:** none.
- **signals emitted:** none directly.
- **dependencies:** `SignalBus`, `GameManager`, `Tower`, `WaveManager`, `SpellManager`, `HexGrid`, `Types`.

### `scripts/types.gd`
- **class_name:** `Types`
- **purpose:** shared enum namespace (`GameState`, `DamageType`, `ArmorType`, `BuildingType`, `ArnulfState`, `ResourceType`, `EnemyType`, `WeaponSlot`, `TargetPriority`).
- **public methods:** none.
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** none.

---

## scenes/

### `scenes/arnulf/arnulf.gd`
- **class_name:** `Arnulf`
- **purpose:** autonomous melee companion AI with state machine, chase/attack/recover loop.
- **public methods:**
  - `get_current_state() -> Types.ArnulfState`
  - `get_current_hp() -> int`
  - `get_max_hp() -> int`
  - `reset_for_new_mission() -> void`
- **exported vars:**
  - `max_hp: int`
  - `move_speed: float`
  - `attack_damage: float`
  - `attack_cooldown: float`
  - `patrol_radius: float`
  - `recovery_time: float`
- **signals emitted with conditions:**
  - `SignalBus.arnulf_incapacitated()` entering `DOWNED`.
  - `SignalBus.arnulf_recovered()` when recovery heal is applied.
  - `SignalBus.arnulf_state_changed(new_state)` on every transition.
- **dependencies:** `HealthComponent`, `NavigationAgent3D`, `Area3D` zones, `EnemyBase`, `DamageCalculator`, `Types`, `SignalBus`, scene tree overlap queries.

### `scenes/buildings/building_base.gd`
- **class_name:** `BuildingBase`
- **purpose:** generic turret building runtime: init, targeting, combat, projectile firing, upgrade state.
- **public methods:**
  - `initialize(data: BuildingData) -> void`
  - `upgrade() -> void`
  - `get_building_data() -> BuildingData`
  - `get_effective_damage() -> float`
  - `get_effective_range() -> float`
  - `is_upgraded` (property getter) -> `bool`
- **exported vars:** none.
- **signals emitted:** none directly.
- **dependencies:** `BuildingData`, `ResearchManager`, `EnemyBase` group iteration, `ProjectileBase` scene preload, `/root/Main/ProjectileContainer`, `Types`.

### `scenes/enemies/enemy_base.gd`
- **class_name:** `EnemyBase`
- **purpose:** enemy movement/attack/death runtime for both ground and flying.
- **public methods:**
  - `initialize(enemy_data: EnemyData) -> void`
  - `take_damage(amount: float, damage_type: Types.DamageType) -> void`
  - `get_enemy_data() -> EnemyData`
- **exported vars:** none.
- **signals emitted with conditions:**
  - `SignalBus.enemy_killed(enemy_type, position, gold_reward)` when health depletes.
- **dependencies:** `EnemyData`, `HealthComponent`, `NavigationAgent3D`, `DamageCalculator`, `SignalBus`, `Tower` (`/root/Main/Tower`), `Types`.

### `scenes/hex_grid/hex_grid.gd`
- **class_name:** `HexGrid`
- **purpose:** slot topology + building placement/sell/upgrade/repair/highlight/build-mode interaction.
- **public methods:**
  - `place_building(slot_index: int, building_type: Types.BuildingType) -> bool`
  - `place_building_shop_free(building_type: Types.BuildingType) -> bool`
  - `has_any_damaged_building() -> bool`
  - `repair_first_damaged_building() -> bool`
  - `sell_building(slot_index: int) -> bool`
  - `upgrade_building(slot_index: int) -> bool`
  - `get_slot_data(slot_index: int) -> Dictionary`
  - `get_all_occupied_slots() -> Array[int]`
  - `get_empty_slots() -> Array[int]`
  - `has_empty_slot() -> bool`
  - `clear_all_buildings() -> void`
  - `get_building_data(building_type: Types.BuildingType) -> BuildingData`
  - `is_building_available(building_type: Types.BuildingType) -> bool`
  - `get_slot_position(slot_index: int) -> Vector3`
  - `get_nearest_slot_index(world_pos: Vector3) -> int`
  - `set_build_slot_highlight(slot_index: int) -> void`
- **exported vars:**
  - `building_data_registry: Array[BuildingData]` - all building archetypes (expected 8).
- **signals emitted with conditions:**
  - `SignalBus.building_placed(slot_index,building_type)` after successful placement.
  - `SignalBus.building_sold(slot_index,building_type)` after successful sale.
  - `SignalBus.building_upgraded(slot_index,building_type)` after successful upgrade.
- **dependencies:** `BuildingData`, `BuildingBase` scene preload, `HealthComponent`, `EconomyManager`, `ResearchManager`, `SignalBus`, `BuildMenu`, `GameManager`, `Types`, `/root/Main/BuildingContainer`.

### `scenes/projectiles/projectile_base.gd`
- **class_name:** `ProjectileBase`
- **purpose:** moving projectile body with collision/overlap fallback and damage application.
- **public methods:**
  - `initialize_from_weapon(weapon_data: WeaponData, origin: Vector3, target_position: Vector3) -> void`
  - `initialize_from_building(damage: float, damage_type: Types.DamageType, speed: float, origin: Vector3, target_position: Vector3, targets_air_only: bool) -> void`
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `WeaponData`, `EnemyBase`, `DamageCalculator`, `Types`, physics overlap/raycast systems.

### `scenes/tower/tower.gd`
- **class_name:** `Tower`
- **purpose:** tower health + Florence weapon handling (crossbow/reload and rapid missile burst).
- **public methods:**
  - `fire_crossbow(target_position: Vector3) -> void`
  - `fire_rapid_missile(target_position: Vector3) -> void`
  - `take_damage(amount: int) -> void`
  - `repair_to_full() -> void`
  - `get_current_hp() -> int`
  - `get_max_hp() -> int`
  - `is_weapon_ready(weapon_slot: Types.WeaponSlot) -> bool`
  - `get_crossbow_reload_remaining_seconds() -> float`
  - `get_crossbow_reload_total_seconds() -> float`
  - `get_rapid_missile_reload_remaining_seconds() -> float`
  - `get_rapid_missile_reload_total_seconds() -> float`
  - `get_rapid_missile_burst_remaining() -> int`
  - `get_rapid_missile_burst_total() -> int`
- **exported vars:**
  - `starting_hp: int`
  - `crossbow_data: WeaponData`
  - `rapid_missile_data: WeaponData`
  - `auto_fire_enabled: bool`
- **signals emitted with conditions:**
  - `SignalBus.projectile_fired(...)` on each successful fire trigger (crossbow or rapid missile burst start).
  - `SignalBus.tower_damaged(current_hp,max_hp)` on health change.
  - `SignalBus.tower_destroyed()` when HP depletes.
- **dependencies:** `HealthComponent`, `WeaponData`, `ProjectileBase` scene preload, `SignalBus`, `EnemyBase` group `"enemies"`, `/root/Main/ProjectileContainer`, `Types`.

---

## ui/

### `ui/ui_manager.gd`
- **class_name:** `UIManager`
- **purpose:** centralized panel visibility routing by `GameState`.
- **public methods:** none (entry via signal handler + internal `_apply_state`).
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `SignalBus.game_state_changed`, `GameManager.get_game_state()`, panel nodes (`HUD`, `BuildMenu`, `BetweenMissionScreen`, `MainMenu`, `MissionBriefing`, `EndScreen`), `Types`.

### `ui/build_menu.gd`
- **class_name:** `BuildMenu`
- **purpose:** build-slot contextual menu; creates placement buttons from `BuildingData`.
- **public methods:**
  - `open_for_slot(slot_index: int) -> void`
- **exported vars:** none.
- **signals emitted:** none directly.
- **dependencies:** `SignalBus` (build mode/resource), `HexGrid`, `EconomyManager`, `GameManager`, `Types`, `BuildingData`.

### `ui/hud.gd`
- **class_name:** `HUD`
- **purpose:** combat/build HUD display for resources, waves, tower HP, mana, cooldown/reload status.
- **public methods:**
  - `update_weapon_display(crossbow_ready: bool, missile_ready: bool) -> void` (legacy hook, mostly superseded by polling).
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `SignalBus` events, `EconomyManager`, `GameManager`, `Tower`, `Types`.

### `ui/main_menu.gd`
- **class_name:** `MainMenu`
- **purpose:** start/settings/quit menu wiring.
- **public methods:** none.
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `GameManager.start_new_game()`, `SceneTree.quit()`.

### `ui/mission_briefing.gd`
- **class_name:** none
- **purpose:** mission title display + begin button to start countdown from briefing.
- **public methods:** none.
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `SignalBus.mission_started`, `GameManager.get_game_state()`, `GameManager.start_wave_countdown()`, `Types`.

### `ui/between_mission_screen.gd`
- **class_name:** `BetweenMissionScreen`
- **purpose:** between-mission tabs for shop/research/buildings and mission advance button.
- **public methods:** none.
- **exported vars:** none.
- **signals emitted:** none directly.
- **dependencies:** `SignalBus.game_state_changed`, `ShopManager`, `ResearchManager`, `HexGrid`, `EconomyManager`, `GameManager`, resource classes (`ShopItemData`, `ResearchNodeData`, `BuildingData`), `BuildingBase`, `Types`.

### `ui/end_screen.gd`
- **class_name:** `EndScreen`
- **purpose:** end-state message view for mission/game win/fail and restart/quit actions.
- **public methods:** none.
- **exported vars:** none.
- **signals emitted:** none.
- **dependencies:** `SignalBus.game_state_changed`, `GameManager` mission getter + restart, `Types`, `SceneTree.quit()`.

---
