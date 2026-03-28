# FOUL WARD — Project State Summary
**Engine**: Godot 4.4 (GDScript, static typing)
**Project path**: `D:\Projects\Foul Ward\foul_ward_godot\foul-ward`
**GitHub**: https://github.com/JerseyWolf/FoulWard
**Last updated**: 2026-03-22

This file is the fast-load reference for any AI session working on this project.
It tells you what every object is supposed to do, which file implements it, and what the current status is.
Always read this before making any code changes. For full specs, see `docs/ARCHITECTURE.md` and `docs/FoulWard_MVP_Specification.md`.

---

## CRITICAL CODING RULES (non-negotiable)

- **Godot 4.4 GDScript only**. Never use Godot 3 syntax.
- **Static typing everywhere**: `var x: int`, `func foo(a: float) -> bool:`
- **Signals**: `signal_name.connect(callable)` and `signal_name.emit(args)` — never the old string form.
- **All enums live in** `scripts/types.gd` as `class_name Types`. Access as `Types.GameState.COMBAT`, etc.
- **No game logic in UI scripts** (`ui/` folder). UI only reads from signals and calls manager public methods.
- **No game logic in** `scripts/input_manager.gd`. InputManager only translates raw input into public API calls.
- **All resource changes go through EconomyManager** — never modify gold/material directly.
- **All cross-system signals go through SignalBus** — never connect directly between unrelated nodes.
- **`_physics_process`** for all game logic. **`_process`** only for UI (stays responsive at `time_scale = 0.1`).
- **`add_child(node)` BEFORE `node.initialize(data)`** — `@onready` vars are null until the node enters the tree.
- **All game data lives in `.tres` files under `resources/`** — never hardcode stats in GDScript.

---

## GAME LOOP OVERVIEW

```
Main Menu → start_new_game() → COMBAT state → 3-second countdown → Wave 1 spawns
→ enemies march to tower → tower auto-fires / player fires → enemies die → gold awarded
→ wave clears → 30-second countdown → Wave 2 → ... → Wave 10 clears → mission won
→ BETWEEN_MISSIONS → shop / research → NEXT MISSION → repeat × 5 → GAME_WON
```

**Lose condition**: Tower HP reaches 0 → `MISSION_FAILED` → restart from Mission 1.
**Win condition**: Clear Wave 10 of Mission 5 → `GAME_WON`.
**No saving** — single session only.

---

## SCENE TREE (from `scenes/main.tscn`)

```
Main (Node3D)
├── Camera3D          — fixed isometric, orthographic, projection=1, size=40
├── DirectionalLight3D
├── Ground (StaticBody3D, layer 32)
│   ├── GroundMesh
│   ├── GroundCollision
│   └── NavigationRegion3D   ← NO navmesh baked yet; enemies use direct steering fallback
├── Tower             ← scenes/tower/tower.tscn  (layer 1)
├── Arnulf            ← scenes/arnulf/arnulf.tscn (layer 3)
├── HexGrid           ← scenes/hex_grid/hex_grid.tscn
├── SpawnPoints       — 10 Marker3D nodes at radius 40 around origin
├── EnemyContainer    — Node3D; runtime parent for spawned enemies
├── BuildingContainer — Node3D; runtime parent for placed buildings
├── ProjectileContainer — Node3D; runtime parent for projectiles
├── Managers (Node)
│   ├── WaveManager   (scripts/wave_manager.gd)
│   ├── SpellManager  (scripts/spell_manager.gd)
│   ├── ResearchManager (scripts/research_manager.gd)
│   ├── ShopManager   (scripts/shop_manager.gd)
│   └── InputManager  (scripts/input_manager.gd)
└── UI (CanvasLayer)
    ├── UIManager     (ui/ui_manager.gd)
    ├── HUD           (ui/hud.tscn + ui/hud.gd)
    ├── BuildMenu     (ui/build_menu.tscn + ui/build_menu.gd)
    ├── BetweenMissionScreen (ui/between_mission_screen.tscn)
    ├── MainMenu      (ui/main_menu.tscn + ui/main_menu.gd)
    ├── MissionBriefing (inline in main.tscn, visible=false, unused in current flow)
    └── EndScreen     (ui/end_screen.gd)
```

**Physics collision layers** (set in tscn files):
- Layer 1 = Tower
- Layer 2 = Enemies (CharacterBody3D collision_layer = 2)
- Layer 3 = Arnulf
- Layer 5 = Projectiles (Area3D)
- Layer 7 = HexGrid slots (Area3D)
- Layer 32 = Ground

---

## AUTOLOAD SINGLETONS

Registered in `project.godot` in this order. Access by name globally.

### `SignalBus` (`autoloads/signal_bus.gd`)
Pure signal registry — zero logic, zero state.
Every cross-system signal is declared here and emitted/connected through here.

Key signals (full list in `autoloads/signal_bus.gd`):
| Signal | Args | Who emits | Who listens |
|---|---|---|---|
| `enemy_killed` | enemy_type, position, gold_reward | EnemyBase | EconomyManager, WaveManager, Arnulf |
| `tower_damaged` | current_hp, max_hp | Tower | HUD |
| `tower_destroyed` | — | Tower | GameManager |
| `wave_countdown_started` | wave_number, seconds | WaveManager | HUD |
| `wave_started` | wave_number, enemy_count | WaveManager | HUD |
| `wave_cleared` | wave_number | WaveManager | WaveManager |
| `all_waves_cleared` | — | WaveManager | GameManager |
| `resource_changed` | resource_type, new_amount | EconomyManager | HUD |
| `game_state_changed` | old_state, new_state | GameManager | UIManager, WaveManager, Arnulf |
| `mission_started` | mission_number | GameManager | (future: HUD) |
| `mission_won` | mission_number | GameManager | (future: BetweenMissionScreen) |
| `mission_failed` | mission_number | GameManager | (future: EndScreen) |
| `build_mode_entered/exited` | — | GameManager | HexGrid, HUD |
| `mana_changed` | current, max | SpellManager | HUD |
| `spell_cast` / `spell_ready` | spell_id | SpellManager | HUD |
| `research_unlocked` | node_id | ResearchManager | HexGrid |
| `shop_item_purchased` | item_id | ShopManager | (display only) |
| `arnulf_state_changed` | new_state | Arnulf | (tests, future HUD) |
| `arnulf_incapacitated` / `arnulf_recovered` | — | Arnulf | (tests) |

### `DamageCalculator` (`autoloads/damage_calculator.gd`)
Stateless pure function. Call: `DamageCalculator.calculate_damage(base, damage_type, armor_type) -> float`

Damage matrix (armor_type → damage_type → multiplier):
```
UNARMORED:  physical 1.0  fire 1.0  magical 1.0  poison 1.0
HEAVY_ARMOR: physical 0.5  fire 1.0  magical 2.0  poison 1.0
UNDEAD:     physical 1.0  fire 2.0  magical 1.0  poison 0.0  ← poison immune
FLYING:     physical 1.0  fire 1.0  magical 1.0  poison 1.0
```

### `EconomyManager` (`autoloads/economy_manager.gd`)
Owns `gold`, `building_material`, `research_material`.

**Starting values**: gold=100, building_material=10, research_material=0
All mutations emit `SignalBus.resource_changed(resource_type, new_amount)`.

Public API:
- `add_gold(amount)`, `spend_gold(amount) -> bool`
- `add_building_material(amount)`, `spend_building_material(amount) -> bool`
- `add_research_material(amount)`, `spend_research_material(amount) -> bool`
- `can_afford(gold_cost, material_cost) -> bool`
- `get_gold/building_material/research_material() -> int`
- `reset_to_defaults()` — called by `GameManager.start_new_game()`

Listens to: `SignalBus.enemy_killed` → calls `add_gold(gold_reward)`

### `GameManager` (`autoloads/game_manager.gd`)
State machine for overall game flow. Owns `current_mission`, `current_wave`, `game_state`.

**States** (`Types.GameState`): MAIN_MENU, MISSION_BRIEFING, COMBAT, BUILD_MODE, WAVE_COUNTDOWN, BETWEEN_MISSIONS, MISSION_WON, MISSION_FAILED, GAME_WON

Public API:
- `start_new_game()` — resets economy, transitions to COMBAT, calls `_begin_mission_wave_sequence()`
- `start_next_mission()` — increments mission, transitions to MISSION_BRIEFING, calls `_begin_mission_wave_sequence()`
- `enter_build_mode()` — sets `Engine.time_scale = 0.1`, transitions to BUILD_MODE
- `exit_build_mode()` — sets `Engine.time_scale = 1.0`, transitions to COMBAT
- `get_game_state() -> Types.GameState`
- `get_current_mission() -> int` (1–5)
- `get_current_wave() -> int` (0–10)

Private helper `_begin_mission_wave_sequence()`:
1. Gets WaveManager via `get_node_or_null("/root/Main/Managers/WaveManager")`
2. Calls `wave_manager.reset_for_new_mission()`
3. Calls `wave_manager.call_deferred("start_wave_sequence")` (deferred so UI settles first)

Listens to: `all_waves_cleared` → awards resources, emits `mission_won`, transitions to BETWEEN_MISSIONS or GAME_WON
Listens to: `tower_destroyed` → transitions to MISSION_FAILED, emits `mission_failed`

Post-mission gold reward: `50 × current_mission` gold + 3 building material + 2 research material.

---

## SCENE SCRIPTS

### `Tower` (`scenes/tower/tower.tscn` + `scenes/tower/tower.gd`)
**Scene path in tree**: `/root/Main/Tower` (StaticBody3D, layer 1)
**Children**: TowerMesh, TowerCollision, HealthComponent (Node), TowerLabel (Label3D)

Exports:
- `@export var starting_hp: int = 500` (set in inspector)
- `@export var crossbow_data: WeaponData` (assigned `crossbow.tres` in main.tscn)
- `@export var rapid_missile_data: WeaponData` (assigned `rapid_missile.tres` in main.tscn)
- `@export var auto_fire_enabled: bool = false` ← **currently `true` in main.tscn for testing**

`_ready()`: sets `_health_component.max_hp = starting_hp`, connects `health_changed` and `health_depleted`.

`_physics_process(delta)`:
- Ticks down `_crossbow_reload_remaining` and `_rapid_missile_reload_remaining`
- Handles burst-fire sequence for Rapid Missile (`_burst_remaining`, `_burst_timer`)
- If `auto_fire_enabled`: calls `_auto_fire_at_nearest_enemy()` each frame

Public API:
- `fire_crossbow(target_position: Vector3)` — fires one bolt if not reloading
- `fire_rapid_missile(target_position: Vector3)` — starts burst of `burst_count` shots
- `take_damage(amount: int)` — delegates to HealthComponent
- `repair_to_full()` — resets HealthComponent to max (called by ShopManager)
- `get_current_hp() -> int`, `get_max_hp() -> int`
- `is_weapon_ready(weapon_slot: Types.WeaponSlot) -> bool`

`_auto_fire_at_nearest_enemy()` (test/dev helper): finds nearest living enemy in group `"enemies"` (any type, ground or flying), calls `fire_crossbow(enemy.global_position)`.

On `health_depleted`: emits `SignalBus.tower_destroyed()`.
On `health_changed`: emits `SignalBus.tower_damaged(current_hp, max_hp)`.

**Projectile spawning**: calls `_spawn_projectile(weapon_data, target_pos)` which:
1. Instantiates `scenes/projectiles/projectile_base.tscn`
2. Calls `proj.initialize_from_weapon(weapon_data, global_position, target_pos)`
3. Adds to `ProjectileContainer`, adds to group `"projectiles"`

### `Arnulf` (`scenes/arnulf/arnulf.tscn` + `scenes/arnulf/arnulf.gd`)
**Scene path**: `/root/Main/Arnulf` (CharacterBody3D, layer 3)
**Children**: ArnulfMesh, ArnulfCollision, HealthComponent, NavigationAgent3D, DetectionArea (sphere r=25, mask=2), AttackArea (small sphere, mask=2), ArnulfLabel

Exports: `max_hp=200`, `move_speed=5.0`, `attack_damage=25.0`, `attack_cooldown=1.0`, `patrol_radius=25.0`, `recovery_time=3.0`

**State machine** (match in `_physics_process`):
- `IDLE` — walks to `HOME_POSITION = Vector3(2, 0, 0)`. Polls for enemies in detection area each frame. Transitions to CHASE when enemy found.
- `PATROL` — post-MVP stub, treated as IDLE
- `CHASE` — updates `navigation_agent.target_position = _chase_target.global_position` every frame, moves along path. Transitions to ATTACK when target enters AttackArea.
- `ATTACK` — stays still (`velocity=ZERO`), deals `attack_damage` PHYSICAL damage every `attack_cooldown` seconds using `DamageCalculator`. Transitions to CHASE if target leaves AttackArea or dies.
- `DOWNED` — stays still, counts down `recovery_time` (3 seconds). Transitions to RECOVERING. Emits `arnulf_incapacitated`.
- `RECOVERING` — heals to 50% max HP (`health_component.heal(max_hp / 2)`), emits `arnulf_recovered`, immediately transitions to IDLE.

**Target selection** (`_find_closest_enemy_to_tower()`):
- Iterates `detection_area.get_overlapping_bodies()` for EnemyBase instances
- **Skips flying enemies** — Arnulf is ground-only
- Selects the enemy **closest to `Vector3.ZERO` (tower center)**, not closest to Arnulf

Listens to: `game_state_changed` → if new state is MISSION_BRIEFING, calls `reset_for_new_mission()`
Listens to: `enemy_killed` → increments `_kill_counter` (post-MVP frenzy hook, no effect in MVP)

`reset_for_new_mission()`: restores full HP, resets position to HOME_POSITION, transitions to IDLE.

### `EnemyBase` (`scenes/enemies/enemy_base.tscn` + `scenes/enemies/enemy_base.gd`)
**Spawned at runtime** into `EnemyContainer` by WaveManager.
**Scene**: CharacterBody3D (collision_layer=2, mask=1)
**Children**: EnemyMesh (BoxMesh 0.9×0.9×0.9), EnemyCollision (CapsuleShape3D), HealthComponent, NavigationAgent3D, EnemyLabel (Label3D)

`initialize(enemy_data: EnemyData)` — **must be called AFTER `add_child()`** so `@onready` vars are valid:
- Sets `health_component.max_hp`, calls `reset_to_max()`
- Connects `health_component.health_depleted → _on_health_depleted`
- Sets up NavigationAgent3D params for ground enemies
- Applies `enemy_data.color` to mesh material, sets label text

Group membership: added to `"enemies"` group in `_ready()` (before initialize).

`_physics_process(delta)`:
- If `_enemy_data == null`, returns early
- If `_is_attacking`: calls `_attack_tower_melee(delta)` or `_attack_tower_ranged(delta)`
- Else: calls `_move_flying(delta)` or `_move_ground(delta)`

**`_move_ground(delta)`** logic:
1. If within `attack_range` of `Vector3.ZERO` → set `_is_attacking = true`
2. Check navmesh validity: `nav_map.is_valid() AND map_get_iteration_id > 0`
3. If no valid navmesh → `_move_direct(delta)` (steers straight to tower)
4. If `navigation_agent.is_navigation_finished()` but NOT in range → `_move_direct(delta)` (path missing)
5. Otherwise: follow NavigationAgent3D path normally

**`_move_direct(delta)`**: steers `velocity = (TARGET_POSITION - global_position).normalized() * move_speed`, calls `move_and_slide()`

**`_move_flying(delta)`**: steers toward `Vector3(0, 5, 0)` (flying height), uses `move_and_slide()`. Arrival check uses horizontal XZ distance only.

**Attack**: calls `_tower.take_damage(enemy_data.damage)` every `attack_cooldown` seconds. Both melee and ranged use this in MVP (ranged is instant-hit, not a projectile).

**Death** (`_on_health_depleted()`):
- Emits `SignalBus.enemy_killed(enemy_type, global_position, gold_reward)`
- Calls `remove_from_group("enemies")`
- Calls `queue_free()`

EconomyManager listens to `enemy_killed` to add gold. WaveManager listens to `enemy_killed` to check `_check_wave_cleared()`.

### `BuildingBase` (`scenes/buildings/building_base.tscn` + `scenes/buildings/building_base.gd`)
**Spawned at runtime** into `BuildingContainer` by HexGrid.
**Scene**: Node3D
**Children**: BuildingMesh (BoxMesh 1×1×1), BuildingLabel (Label3D), HealthComponent

`initialize(data: BuildingData)` — called after `add_child()`:
- Sets `_building_data`, applies color to mesh, sets label text

`_physics_process(delta)` → `_combat_process(delta)`:
- Returns early if `fire_rate <= 0` (post-MVP stubs: Archer Barracks, Shield Generator)
- Ticks `_attack_timer`, validates/acquires `_current_target` via `_find_target()`
- Fires via `_fire_at_target()` when timer expires

`_find_target()`: iterates `"enemies"` group, filters by `targets_air/targets_ground`, picks closest within `attack_range`.

`_fire_at_target()`: instantiates `projectile_base.tscn`, calls `proj.initialize_from_building(damage, damage_type, speed, origin, target_pos, targets_air)`, adds to `ProjectileContainer`.
Note: `initialize_from_building` is called before `add_child`; this is safe for collision setup but visuals resolve lazily via `get_node_or_null` in `_configure_visuals`.

`upgrade()`: sets `_is_upgraded = true` (used by HexGrid for range/damage boosts).

### `ProjectileBase` (`scenes/projectiles/projectile_base.tscn` + `scenes/projectiles/projectile_base.gd`)
**Scene**: Area3D (collision_layer=5, mask=2). Collision set to layer 5 / mask 2 in `_configure_collision`.
**Children**: ProjectileMesh (SphereMesh, r=0.15), ProjectileCollision (SphereShape3D, r=0.2)

Two init paths (both safe to call before `add_child`):
- `initialize_from_weapon(weapon_data, origin, target_position)` — Florence's weapons
- `initialize_from_building(damage, damage_type, speed, origin, target_position, targets_air_only)` — buildings

`_physics_process(delta)`:
- Increments `_lifetime`; if >= `MAX_LIFETIME (5s)` → `queue_free()`
- Moves `global_position += _direction * _speed * delta`
- If `_distance_traveled >= _max_travel_distance` or within `ARRIVAL_TOLERANCE (0.5)` → `queue_free()` (miss)

`_on_body_entered(body)`: called when Area3D hits a body on layer 2 (enemy).
- Casts to EnemyBase, checks `is_alive()`
- Calls `_apply_damage_to_enemy(enemy)`:
  - Checks `damage_immunities`, calls `DamageCalculator.calculate_damage()`, calls `enemy.health_component.take_damage()`
- Calls `queue_free()` on hit

`_configure_visuals()`: resolves `_mesh` lazily via `get_node_or_null("ProjectileMesh")` (works before or after `add_child`). Colors: PHYSICAL=brown, FIRE=orange-red, MAGICAL=purple, POISON=green-yellow.

### `HealthComponent` (`scripts/health_component.gd`)
Reusable Node attached to Tower, Arnulf, Buildings, Enemies.

Export: `@export var max_hp: int = 100`
State: `current_hp: int`, `_is_alive: bool = true`

Local signals (NOT on SignalBus):
- `health_changed(current_hp: int, max_hp: int)`
- `health_depleted()` — fires at most once per life

Public API:
- `take_damage(amount: float)` — silent if not alive; emits `health_changed`; if `current_hp == 0` → `_is_alive = false`, emits `health_depleted`
- `heal(amount: int)` — does NOT revive dead entities
- `reset_to_max()` — fully restores HP AND sets `_is_alive = true` (re-arms `health_depleted`)
- `is_alive() -> bool`

---

## MANAGER SCRIPTS (under `/root/Main/Managers/`)

### `WaveManager` (`scripts/wave_manager.gd`)
**Node path**: `/root/Main/Managers/WaveManager`

Exports:
- `wave_countdown_duration: float = 30.0` — countdown for waves 2–10
- `first_wave_countdown_seconds: float = 3.0` — countdown for wave 1 only
- `max_waves: int = 10`
- `enemy_data_registry: Array[EnemyData]` — must have exactly 6 entries in Types.EnemyType order (set in main.tscn) ← **already configured correctly**

Spawning pattern in `_spawn_wave(wave_number)`:
```
for each EnemyData in enemy_data_registry:
    for i in range(wave_number):
        var enemy = EnemyScene.instantiate()
        _enemy_container.add_child(enemy)   # ← FIRST (so @onready vars work)
        enemy.initialize(enemy_data)        # ← THEN initialize
        enemy.global_position = random_spawn_point + random_offset
```
Wave N spawns N enemies of each of the 6 types = N×6 total enemies.

State: `_current_wave`, `_countdown_remaining`, `_is_counting_down`, `_is_wave_active`, `_is_sequence_running`

Public API:
- `start_wave_sequence()` — begins wave 1 countdown
- `force_spawn_wave(wave_number)` — immediate spawn, no countdown (for bots/tests)
- `reset_for_new_mission()` — resets all state, clears all enemies
- `clear_all_enemies()` — removes all nodes from `"enemies"` group
- `get_living_enemy_count() -> int` — size of `"enemies"` group
- `get_current_wave_number() -> int`, `is_wave_active() -> bool`, `is_counting_down() -> bool`, `get_countdown_remaining() -> float`

Wave cleared logic: on `enemy_killed` → `call_deferred("_check_wave_cleared")` → if group empty: emit `wave_cleared`; if last wave: emit `all_waves_cleared`; else: `_begin_countdown_for_next_wave()`

### `SpellManager` (`scripts/spell_manager.gd`)
**Node path**: `/root/Main/Managers/SpellManager`

Exports: `max_mana: int = 100`, `mana_regen_rate: float = 5.0`, `spell_registry: Array[SpellData]`
In main.tscn: `spell_registry = [shockwave.tres]`

State: `_current_mana_float: float = 0.0`, `_current_mana: int = 0`, `_cooldown_remaining: Dictionary`

`_physics_process(delta)`:
- Regens mana (`_current_mana_float += mana_regen_rate * delta`), emits `mana_changed` on integer change
- Decrements all cooldowns; emits `spell_ready(spell_id)` when cooldown hits 0

Public API:
- `cast_spell(spell_id: String) -> bool` — checks mana and cooldown; applies effect; emits `spell_cast`, `mana_changed`
- `get_current_mana() -> int`, `get_max_mana() -> int`
- `get_cooldown_remaining(spell_id) -> float`, `is_spell_ready(spell_id) -> bool`
- `set_mana_to_full()` — called by ShopManager for Mana Draught item
- `reset_to_defaults()` — mana=0, all cooldowns cleared

**Shockwave effect** (`_apply_shockwave`): iterates `"enemies"` group, skips flying (hits_flying=false), checks `damage_immunities`, calls `DamageCalculator.calculate_damage()`, applies via `enemy.health_component.take_damage()`.
MVP shockwave spell data (from `resources/spell_data/shockwave.tres`): mana_cost=50, cooldown=60s, damage=MAGICAL.

### `ResearchManager` (`scripts/research_manager.gd`)
**Node path**: `/root/Main/Managers/ResearchManager`

In main.tscn: `research_nodes = [base_structures_tree.tres]`

Public API:
- `unlock_node(node_id: String) -> bool` — checks cost + prereqs, spends `research_material`, emits `research_unlocked`
- `is_unlocked(node_id: String) -> bool`
- `get_available_nodes() -> Array[ResearchNodeData]`
- `reset_to_defaults()`

HexGrid listens to `research_unlocked` to refresh which buildings are available. HexGrid also calls `_research_manager.is_unlocked(unlock_research_id)` during `place_building()`.

### `ShopManager` (`scripts/shop_manager.gd`)
**Node path**: `/root/Main/Managers/ShopManager`

In main.tscn: `shop_catalog = [shop_item_tower_repair.tres, shop_item_mana_draught.tres]`

Public API:
- `purchase_item(item_id: String) -> bool` — checks gold, applies effect, emits `shop_item_purchased`
- `get_available_items() -> Array[ShopItemData]`, `can_purchase(item_id) -> bool`

Item effects:
- `"tower_repair"` — calls `Tower.repair_to_full()` (via Tower node reference injected by GameManager._ready)
- `"mana_draught"` — calls `SpellManager.set_mana_to_full()` at next mission start (via `mana_draught_consumed` signal)

### `InputManager` (`scripts/input_manager.gd`)
**Node path**: `/root/Main/Managers/InputManager`
Zero game logic — translates raw Godot input into public method calls.

`_unhandled_input(event)`:
- **Left mouse click** + state=COMBAT → `Tower.fire_crossbow(_get_aim_position())`
- **Right mouse click** + state=COMBAT → `Tower.fire_rapid_missile(_get_aim_position())`
- **`cast_shockwave` action** → `SpellManager.cast_spell("shockwave")`
- **`toggle_build_mode` action** + state=COMBAT/WAVE_COUNTDOWN → `GameManager.enter_build_mode()`
- **`toggle_build_mode`** + state=BUILD_MODE → `GameManager.exit_build_mode()`
- **`cancel` action** + state=BUILD_MODE → `GameManager.exit_build_mode()`

`_get_aim_position() -> Vector3`: raycasts from camera through mouse to `Plane(Vector3.UP, 0)`, returns world XZ intersection.

**Input actions** (must be defined in Godot Project Settings → Input Map):
- `cast_shockwave` (Space or Q)
- `toggle_build_mode` (B or Tab)
- `cancel` (Escape)

---

## UI SCRIPTS

### `UIManager` (`ui/ui_manager.gd`)
Listens to `game_state_changed`, calls `_apply_state(new_state)`.

Panel routing:
| State | Visible panel |
|---|---|
| MAIN_MENU | MainMenu |
| MISSION_BRIEFING, COMBAT, WAVE_COUNTDOWN | HUD |
| BUILD_MODE | HUD + BuildMenu |
| BETWEEN_MISSIONS | BetweenMissionScreen |
| MISSION_WON, GAME_WON, MISSION_FAILED | EndScreen |

### `HUD` (`ui/hud.gd` + `ui/hud.tscn`)
Uses `_process` (NOT `_physics_process`) to remain responsive at Engine.time_scale = 0.1.
Connects in `_ready()` to: `resource_changed`, `wave_countdown_started`, `wave_started`, `tower_damaged`, `mana_changed`, `spell_cast`, `spell_ready`, `build_mode_entered`, `build_mode_exited`.

Child nodes (see `ui/hud.tscn`):
- `ResourceDisplay/GoldLabel`, `MaterialLabel`, `ResearchLabel`
- `WaveDisplay/WaveLabel`, `CountdownLabel` (hidden when not counting down)
- `TowerHPBar` (ProgressBar, max=500)
- `SpellPanel/ManaBar`, `SpellButton`, `CooldownLabel`
- `WeaponPanel/CrossbowLabel`, `MissileLabel`
- `BuildModeHint` (Label, shown only in BUILD_MODE)

### `BuildMenu` (`ui/build_menu.gd`)
Shown during BUILD_MODE. Displays 8 building options. Clicking calls `HexGrid.place_building(slot_index, building_type)`. Pure UI — no game logic.

---

## HEX GRID (`scenes/hex_grid/hex_grid.tscn` + `scenes/hex_grid/hex_grid.gd`)

24 Area3D slots in 3 concentric rings around Vector3.ZERO:
- Ring 1: 6 slots at radius 6
- Ring 2: 12 slots at radius 12
- Ring 3: 6 slots at radius 18 (offset 30°)

Named `HexSlot_00` through `HexSlot_23` (children of HexGrid node).
Each slot: `collision_layer=7`, `input_ray_pickable=true` (for click detection).
Slot meshes visible only in BUILD_MODE (hidden otherwise).

Export: `building_data_registry: Array[BuildingData]` — must have exactly 8 entries ← **configured correctly in main.tscn**

Public API:
- `place_building(slot_index, building_type) -> bool` — validates, checks research + affordability, spends resources, instantiates BuildingBase, emits `building_placed`
- `sell_building(slot_index) -> bool` — full refund (gold + material + upgrade costs), queue_frees building, emits `building_sold`
- `upgrade_building(slot_index) -> bool` — checks cost, calls `building.upgrade()`, emits `building_upgraded`
- `get_slot_data(slot_index) -> Dictionary` — returns `{index, world_pos, building, is_occupied}`
- `get_all_occupied_slots/get_empty_slots() -> Array[int]`
- `clear_all_buildings()` — called on new game
- `get_building_data(building_type) -> BuildingData`
- `is_building_available(building_type) -> bool`

Listens to: `build_mode_entered/exited` → shows/hides slot meshes. `research_unlocked` → hook for future UI refresh.

---

## RESOURCE DATA FILES

All in `resources/`. These are `.tres` files loaded into `@export` arrays.

### Enemy Data (`resources/enemy_data/` — 6 files, class `EnemyData`)
Fields: `enemy_type, display_name, max_hp, move_speed, damage, attack_range, attack_cooldown, armor_type, gold_reward, is_ranged, is_flying, color, damage_immunities: Array[DamageType]`

| File | Name | HP | Speed | Dmg | Armor | Flying | Immunities |
|---|---|---|---|---|---|---|---|
| orc_grunt.tres | Orc Grunt | 80 | 3.0 | 15 | UNARMORED | no | — |
| orc_brute.tres | Orc Brute | — | — | — | HEAVY_ARMOR | no | — |
| goblin_firebug.tres | Goblin Firebug | — | — | — | UNARMORED | no | [FIRE] |
| plague_zombie.tres | Plague Zombie | — | — | — | UNDEAD | no | [POISON] |
| orc_archer.tres | Orc Archer | — | — | — | UNARMORED | no | — |
| bat_swarm.tres | Bat Swarm | — | — | — | FLYING | yes | — |

### Building Data (`resources/building_data/` — 8 files, class `BuildingData`)
Fields: `building_type, display_name, gold_cost, material_cost, upgrade_gold_cost, upgrade_material_cost, damage, upgraded_damage, fire_rate, attack_range, upgraded_range, damage_type, targets_air, targets_ground, is_locked, unlock_research_id, color`

| File | Name | Cost | Range | DPS | Type | Air | Ground | Locked |
|---|---|---|---|---|---|---|---|---|
| arrow_tower.tres | Arrow Tower | 50g+2m | 15 | 1.0/s | PHYSICAL | no | yes | no |
| fire_brazier.tres | Fire Brazier | — | — | — | FIRE | no | yes | no |
| magic_obelisk.tres | Magic Obelisk | — | — | — | MAGICAL | no | yes | no |
| poison_vat.tres | Poison Vat | — | — | — | POISON | no | yes | no |
| ballista.tres | Ballista | — | — | — | PHYSICAL | no | yes | yes |
| archer_barracks.tres | Archer Barracks | — | — | fire_rate=0 | — | — | — | yes |
| anti_air_bolt.tres | Anti-Air Bolt | — | — | — | PHYSICAL | yes | no | yes |
| shield_generator.tres | Shield Generator | — | — | fire_rate=0 | — | — | — | yes |

Buildings with `fire_rate=0` are post-MVP stubs (Archer Barracks, Shield Generator) — `_combat_process` returns early.

### Weapon Data (`resources/weapon_data/` — 2 files, class `WeaponData`)
- `crossbow.tres` — single shot, slow reload, high damage, `burst_count=1`
- `rapid_missile.tres` — burst fire (`burst_count=10`), `burst_interval`, fast speed, lower damage per shot

### Spell Data (`resources/spell_data/shockwave.tres`, class `SpellData`)
Fields: `spell_id, damage, damage_type, mana_cost, cooldown, hits_flying`
Shockwave: id=`"shockwave"`, damage_type=MAGICAL, mana_cost=50, cooldown=60s, hits_flying=false

### Shop Data (`resources/shop_data/` — class `ShopItemData`)
- `shop_item_tower_repair.tres` — id=`"tower_repair"`, gold_cost=75
- `shop_item_mana_draught.tres` — id=`"mana_draught"`, gold_cost=50
Note: `shop_catalog.tres` also exists with these items as sub-resources. Both approaches are present.

### Research Data (`resources/research_data/base_structures_tree.tres`)
6 research nodes unlocking: Ballista (2), Anti-Air Bolt (2), Arrow Tower +Damage (1), Shield Generator (3), Fire Brazier +Range (1), Archer Barracks (3). All cost `research_material`.

---

## ENUMS (from `scripts/types.gd`, class_name `Types`)

```
Types.GameState:    MAIN_MENU, MISSION_BRIEFING, COMBAT, BUILD_MODE,
                    WAVE_COUNTDOWN, BETWEEN_MISSIONS, MISSION_WON, MISSION_FAILED, GAME_WON
Types.DamageType:   PHYSICAL, FIRE, MAGICAL, POISON
Types.ArmorType:    UNARMORED, HEAVY_ARMOR, UNDEAD, FLYING
Types.BuildingType: ARROW_TOWER, FIRE_BRAZIER, MAGIC_OBELISK, POISON_VAT,
                    BALLISTA, ARCHER_BARRACKS, ANTI_AIR_BOLT, SHIELD_GENERATOR
Types.ArnulfState:  IDLE, PATROL, CHASE, ATTACK, DOWNED, RECOVERING
Types.ResourceType: GOLD, BUILDING_MATERIAL, RESEARCH_MATERIAL
Types.EnemyType:    ORC_GRUNT, ORC_BRUTE, GOBLIN_FIREBUG, PLAGUE_ZOMBIE, ORC_ARCHER, BAT_SWARM
Types.WeaponSlot:   CROSSBOW, RAPID_MISSILE
Types.TargetPriority: CLOSEST, HIGHEST_HP, FLYING_FIRST
```

---

## KNOWN BUGS FIXED (do not re-introduce)

### 1. Enemy immortality + waves never clearing (fixed in `scripts/wave_manager.gd`)
**Root cause**: `enemy.initialize(enemy_data)` was called BEFORE `_enemy_container.add_child(enemy)`. Because `health_component` is `@onready`, it was `null` during `initialize()`, so the `health_depleted` signal was never connected. Enemies could not die; waves never cleared.

**Fix**: `add_child(enemy)` is now called FIRST, then `enemy.initialize(enemy_data)`.

### 2. Ground enemies not moving (fixed in `scenes/enemies/enemy_base.gd`)
**Root cause A**: No navmesh baked in `NavigationRegion3D` (still true — no navmesh). However, `NavigationServer3D.map_get_iteration_id()` may return > 0 even with no geometry, bypassing the fallback. Then `navigation_agent.is_navigation_finished()` returned `true` immediately (no path), and the old code set `_is_attacking = true` from the spawn point 40+ units away. Enemies attacked the tower from spawn without moving.

**Fix**: Arrival check (distance to tower) is now the PRIMARY gate for `_is_attacking`. When `is_navigation_finished()` returns true but enemy is NOT in range, `_move_direct(delta)` is called instead. `_move_direct` steers straight toward `Vector3.ZERO`.

### 3. Enemies invisible (fixed in `scenes/enemies/enemy_base.tscn`)
`EnemyMesh` MeshInstance3D had no `mesh` resource. Added `BoxMesh` (0.9×0.9×0.9).

### 4. Projectiles invisible (fixed in `scenes/projectiles/projectile_base.tscn`)
`ProjectileMesh` MeshInstance3D had no `mesh` resource. Added `SphereMesh` (r=0.15).

### 5. Projectile colors never applied (fixed in `scenes/projectiles/projectile_base.gd`)
`@onready var _mesh` was null when `_configure_visuals()` was called from `initialize_from_*()` (before `add_child`). Changed to a plain `var _mesh = null` resolved lazily inside `_configure_visuals()` via `get_node_or_null("ProjectileMesh")` — works whether called before or after `add_child`.

---

## CURRENT STATE (as of 2026-03-22)

### Working
- Game starts at MAIN_MENU, transitions to COMBAT on "Start Game"
- Wave 1 starts after 3-second countdown (subsequent waves after 30s)
- All 6 enemy types spawn at the 10 spawn points
- Bat Swarm (flying) moves via `_move_flying()` — working
- Ground enemies move via `_move_direct()` fallback — working after fix
- Enemies attack tower on arrival; tower HP decreases
- Tower auto-fires at nearest enemy (both ground and flying) — enabled in main.tscn for testing
- Enemy death: gold awarded via EconomyManager, removed from group, queue_freed
- Wave clears when all enemies dead; next countdown starts
- HUD updates: wave counter, countdown, tower HP bar, gold/material/research
- EconomyManager tracks gold/materials, updates HUD via resource_changed signal
- SpellManager regens mana; shockwave fires (Space key) and damages all ground enemies
- Arnulf state machine — IDLE, CHASE, ATTACK, DOWNED, RECOVERING — all functional
- Build mode (B key) slows time to 0.1×, shows hex grid slots
- Building placement/sell/upgrade via HexGrid public API
- Auto-built buildings (Arrow Tower etc.) fire projectiles at enemies in range

### Not yet verified / potentially incomplete
- Arnulf's NavigationAgent3D also has no navmesh — IDLE/CHASE states use nav agent which may not pathfind. Apply the same `_move_direct` pattern if Arnulf is also frozen.
- BetweenMissionScreen UI tabs (Shop, Research, Buildings) — UI exists but tab switching and purchase buttons may need wiring
- EndScreen "Restart" button — needs `GameManager.start_new_game()` connection
- Mission progression (mission 2–5) — `start_next_mission()` exists but full flow not verified
- Tower HP does not reset between waves (correct per spec); resets each mission via `Arnulf.reset_for_new_mission()` and tower should also reset — check `GameManager.start_next_mission()`
- `auto_fire_enabled = true` in main.tscn is a test scaffold — should eventually be removed and replaced with player-controlled aiming only

### Known missing / not implemented
- NavigationMesh not baked — enemies use direct vector steering (acceptable for MVP)
- Projectile visuals apply (color/size) if `initialize_from_*` is called before `add_child`; they resolve lazily now but the mesh size scaling may not apply on first shot if the node resolves after the check — test in-editor
- HUD weapon cooldown display is not connected to `projectile_fired` signal; `update_weapon_display()` exists on HUD but nothing calls it yet
- No floating "+gold" text on enemy kill (post-MVP per spec)
- No victory screen content (GameManager transitions to GAME_WON but EndScreen needs to show "YOU SURVIVED")
- Build menu radial layout (8 building buttons) — UI scene exists but button positioning and click-to-build wiring needs verification
- Shop "Tower Repair" and "Mana Draught" effects need Tower node reference injection — `GameManager._ready()` does inject it if `ShopManager.has_method("initialize_tower")`

---

## HOW TO TEST THE FULL COMBAT LOOP

1. Open `scenes/main.tscn` in Godot editor and run.
2. Click "Start Game" on the main menu.
3. After 3 seconds, 6 colored cubes should spawn at the map edges and march toward the center.
4. The tower auto-fires brown spheres (crossbow) at enemies.
5. Watch HUD: gold increases as enemies die, wave counter advances.
6. After all enemies are dead, a 30-second countdown starts for wave 2 (12 enemies).
7. Tower HP bar drops when enemies reach the tower and attack.
8. Press B to enter build mode (time slows to 10%) — hex grid slots appear.
9. Press Space to cast Shockwave (needs 50 mana — wait ~10 seconds to regen).

---

## FILES MODIFIED IN RECENT SESSIONS

| File | Change |
|---|---|
| `scripts/wave_manager.gd` | `add_child` before `initialize` in `_spawn_wave()` |
| `scenes/enemies/enemy_base.gd` | Added `_move_direct()` fallback; restructured `_move_ground()` |
| `scenes/enemies/enemy_base.tscn` | Added BoxMesh (0.9³) to EnemyMesh node |
| `scenes/projectiles/projectile_base.tscn` | Added SphereMesh (r=0.15) to ProjectileMesh node |
| `scenes/projectiles/projectile_base.gd` | `_mesh` no longer `@onready`; resolves lazily in `_configure_visuals` |
| `scenes/tower/tower.gd` | Added `auto_fire_enabled` export + `_auto_fire_at_nearest_enemy()` |
| `scenes/main.tscn` | Set `auto_fire_enabled = true` on Tower node |
| `addons/gdUnit4/src/core/GdUnitFileAccess.gd` | Removed `true` arg from `file.get_as_text()` |
| `ui/ui_manager.gd` | Removed MissionBriefing panel route; MISSION_BRIEFING now shows HUD |
| `autoloads/game_manager.gd` | `start_new_game()` → COMBAT (not BRIEFING); added `_begin_mission_wave_sequence()` |
| `tests/test_game_manager.gd` | Updated assertions to match COMBAT transition |
