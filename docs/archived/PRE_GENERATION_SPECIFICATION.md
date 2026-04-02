# FOUL WARD — PRE_GENERATION_SPECIFICATION.md

Reference **specification** for the FOUL WARD project: SignalBus and local signal inventory, assumed scene paths, Godot project configuration (autoloads, physics, input, navigation, GdUnit), and **Section 4** resource class stubs (stubs may lag the repo — treat live scripts under `res://scripts/resources/` as source of truth for fields).

For a short **pre-flight checklist** (what to verify before codegen or big refactors), use **`docs/PRE_GENERATION_VERIFICATION.md`**.

When this document disagrees with **`docs/ARCHITECTURE.md`**, **`docs/CONVENTIONS.md`**, or **`project.godot`**, those wins for the *current* game unless you are intentionally pinning MVP history here.

---

## Section 1 — Signal Integrity Table

### 1.1 Cross-Module Signal Flow

| Signal Name | Emitting Module | Receiving Module(s) | Payload Match | Notes |
|---|---|---|---|---|
| `enemy_killed` | Enemy+Projectile | Foundation (EconomyManager), Arnulf+Wave+Spell (WaveManager, Arnulf) | YES | `enemy_type: Types.EnemyType, position: Vector3, gold_reward: int` |
| `tower_damaged` | Tower+Input+UI+SimBot (Tower) | Tower+Input+UI+SimBot (HUD) | YES | `current_hp: int, max_hp: int` — emitter and receiver are in same module |
| `tower_destroyed` | Tower+Input+UI+SimBot (Tower) | Foundation (GameManager) | YES | No payload |
| `projectile_fired` | Tower+Input+UI+SimBot (Tower) | (none) | YES | `weapon_slot: Types.WeaponSlot, origin: Vector3, target: Vector3` — emitted but no module declares receiving it |
| `arnulf_state_changed` | Arnulf+Wave+Spell (Arnulf) | (none) | YES | `new_state: Types.ArnulfState` — emitted but no module declares receiving it |
| `arnulf_incapacitated` | Arnulf+Wave+Spell (Arnulf) | (none) | YES | No payload — emitted but no module declares receiving it |
| `arnulf_recovered` | Arnulf+Wave+Spell (Arnulf) | (none) | YES | No payload — emitted but no module declares receiving it |
| `wave_countdown_started` | Arnulf+Wave+Spell (WaveManager) | Tower+Input+UI+SimBot (HUD) | YES | `wave_number: int, seconds_remaining: float` |
| `wave_started` | Arnulf+Wave+Spell (WaveManager) | Tower+Input+UI+SimBot (HUD) | YES | `wave_number: int, enemy_count: int` |
| `wave_cleared` | Arnulf+Wave+Spell (WaveManager) | Tower+Input+UI+SimBot (SimBot) | YES | `wave_number: int` |
| `all_waves_cleared` | Arnulf+Wave+Spell (WaveManager) | Foundation (GameManager) | YES | No payload |
| `resource_changed` | Foundation (EconomyManager) | Tower+Input+UI+SimBot (HUD) | YES | `resource_type: Types.ResourceType, new_amount: int` |
| `building_placed` | HexGrid+Buildings+Research+Shop (HexGrid) | Tower+Input+UI+SimBot (HUD, optional) | YES | `slot_index: int, building_type: Types.BuildingType` |
| `building_sold` | HexGrid+Buildings+Research+Shop (HexGrid) | (none) | YES | `slot_index: int, building_type: Types.BuildingType` — emitted but no module declares receiving it |
| `building_upgraded` | HexGrid+Buildings+Research+Shop (HexGrid) | (none) | YES | `slot_index: int, building_type: Types.BuildingType` — emitted but no module declares receiving it |
| `research_unlocked` | HexGrid+Buildings+Research+Shop (ResearchManager) | HexGrid+Buildings+Research+Shop (HexGrid) | YES | `node_id: String` — emitter and receiver are in same module |
| `shop_item_purchased` | HexGrid+Buildings+Research+Shop (ShopManager) | (none) | YES | `item_id: String` — emitted but no module declares receiving it |
| `spell_cast` | Arnulf+Wave+Spell (SpellManager) | Tower+Input+UI+SimBot (HUD) | YES | `spell_id: String` |
| `spell_ready` | Arnulf+Wave+Spell (SpellManager) | Tower+Input+UI+SimBot (HUD) | YES | `spell_id: String` |
| `mana_changed` | Arnulf+Wave+Spell (SpellManager) | Tower+Input+UI+SimBot (HUD) | YES | `current_mana: int, max_mana: int` |
| `game_state_changed` | Foundation (GameManager) | Arnulf+Wave+Spell (WaveManager, Arnulf), Tower+Input+UI+SimBot (UIManager, SimBot) | YES | `old_state: Types.GameState, new_state: Types.GameState` |
| `mission_started` | Foundation (GameManager) | Tower+Input+UI+SimBot (SimBot) | YES | `mission_number: int` |
| `mission_won` | Foundation (GameManager) | Tower+Input+UI+SimBot (SimBot) | YES | `mission_number: int` |
| `mission_failed` | Foundation (GameManager) | Tower+Input+UI+SimBot (SimBot) | YES | `mission_number: int` |
| `build_mode_entered` | Foundation (GameManager) | HexGrid+Buildings+Research+Shop (HexGrid), Tower+Input+UI+SimBot (HUD) | YES | No payload |
| `build_mode_exited` | Foundation (GameManager) | HexGrid+Buildings+Research+Shop (HexGrid), Tower+Input+UI+SimBot (HUD) | YES | No payload |

### 1.2 Signals Declared in SignalBus But Not Emitted by Any Module

| Signal Name | Declared Payload | Status |
|---|---|---|
| `enemy_reached_tower` | `enemy_type: Types.EnemyType, damage: int` | **ORPHAN** — declared in CONVENTIONS.md §5 but no module emits it. EnemyBase calls `Tower.take_damage()` directly instead. Either remove from SignalBus or refactor EnemyBase to emit it. |
| `building_destroyed` | `slot_index: int` | **ORPHAN** — declared in CONVENTIONS.md §5 but no module emits it. MVP buildings cannot be damaged. Remove from SignalBus or add as post-MVP stub. |

### 1.3 Signals Emitted But Not Received by Any Module

| Signal Name | Emitting Module | Notes |
|---|---|---|
| `projectile_fired` | Tower+Input+UI+SimBot | Available for future VFX/audio hooks. No receiver needed for MVP. |
| `arnulf_state_changed` | Arnulf+Wave+Spell | Available for HUD Arnulf status indicator. No receiver declared but HUD may optionally connect. |
| `arnulf_incapacitated` | Arnulf+Wave+Spell | Same as above. |
| `arnulf_recovered` | Arnulf+Wave+Spell | Same as above. |
| `building_sold` | HexGrid+Buildings+Research+Shop | Available for HUD notification. No receiver declared. |
| `building_upgraded` | HexGrid+Buildings+Research+Shop | Same as above. |
| `shop_item_purchased` | HexGrid+Buildings+Research+Shop | Available for HUD notification. No receiver declared. |

### 1.4 Local Signals (Not on SignalBus — Within Scene Only)

| Signal Name | Declared On | Payload | Consumed By |
|---|---|---|---|
| `health_changed` | HealthComponent | `current_hp: int, max_hp: int` | Owning node (Tower, Arnulf, EnemyBase, BuildingBase) |
| `health_depleted` | HealthComponent | (none) | Owning node |
| `hit_enemy` | ProjectileBase | `enemy: EnemyBase, damage_dealt: float` | (none in MVP — future VFX) |
| `missed` | ProjectileBase | `final_position: Vector3` | (none in MVP — future VFX) |

---

## Section 2 — Node Path Verification

### 2.1 Hardcoded `get_node()` Paths from Module Assumptions

| Path | Assumed By | Exists in ARCHITECTURE.md Scene Tree | Notes |
|---|---|---|---|
| `/root/Main/EnemyContainer` | Arnulf+Wave+Spell (WaveManager) | YES | Node3D at Main > EnemyContainer |
| `/root/Main/SpawnPoints` | Arnulf+Wave+Spell (WaveManager) | YES | Node3D at Main > SpawnPoints, 10 Marker3D children |
| `/root/Main/Tower` | Enemy+Projectile (EnemyBase._attack_tower) | YES | StaticBody3D at Main > Tower |
| `/root/Main/ProjectileContainer` | Enemy+Projectile (EnemyBase), HexGrid+Buildings (BuildingBase), Tower+Input+UI (Tower) | YES | Node3D at Main > ProjectileContainer |
| `/root/Main/BuildingContainer` | HexGrid+Buildings+Research+Shop (HexGrid) | YES | Node3D at Main > BuildingContainer |
| `/root/Main/Managers/ResearchManager` | HexGrid+Buildings+Research+Shop (HexGrid) | YES | Node at Main > Managers > ResearchManager |

### 2.2 Preloaded Scene Paths

| Path | Assumed By | File Listed in CONVENTIONS.md Directory Structure | Notes |
|---|---|---|---|
| `res://scenes/enemies/enemy_base.tscn` | Arnulf+Wave+Spell (WaveManager) | YES | |
| `res://scenes/projectiles/projectile_base.tscn` | Enemy+Projectile, HexGrid+Buildings (BuildingBase), Tower+Input+UI (Tower) | YES | |
| `res://scenes/buildings/building_base.tscn` | HexGrid+Buildings+Research+Shop (HexGrid) | YES | |

### 2.3 Child Node Paths (within instanced scenes, via $NodeName)

| Path | Scene | Exists in ARCHITECTURE.md Scene Tree | Notes |
|---|---|---|---|
| `$HealthComponent` | Tower, Arnulf, EnemyBase, BuildingBase | YES | HealthComponent listed as child of Tower and Arnulf. EnemyBase and BuildingBase must add it to their .tscn. |
| `$NavigationAgent3D` | Arnulf, EnemyBase | YES (Arnulf) / PARTIAL (EnemyBase) | Arnulf scene tree shows NavigationAgent3D. EnemyBase scene tree not detailed — **EnemyBase .tscn must include NavigationAgent3D as a child node.** |
| `$DetectionArea` | Arnulf | YES | Area3D at Arnulf > DetectionArea |
| `$AttackArea` | Arnulf | YES | Area3D at Arnulf > AttackArea |
| `$ArnulfMesh` | Arnulf | YES | MeshInstance3D at Arnulf > ArnulfMesh |
| `$SlotMesh` | HexSlot_XX (Area3D children of HexGrid) | YES | MeshInstance3D listed as child of each HexSlot |
| `$BuildingMesh` | BuildingBase | **NO** | **MISSING from ARCHITECTURE.md scene tree.** BuildingBase.initialize() references `get_node_or_null("BuildingMesh")`. building_base.tscn must include a MeshInstance3D named BuildingMesh. |
| `$TowerMesh` | Tower | YES (as TowerMesh) | Listed in scene tree. Consistency note: Tower uses "TowerMesh", Building uses "BuildingMesh" — naming is consistent with convention. |

### 2.4 Flags

| Issue | Severity | Resolution |
|---|---|---|
| EnemyBase .tscn scene tree not fully specified in ARCHITECTURE.md | MEDIUM | Enemy+Projectile module must create enemy_base.tscn with: root (CharacterBody3D) > EnemyMesh (MeshInstance3D) + EnemyCollision (CollisionShape3D, layer 2) + HealthComponent (Node) + NavigationAgent3D + EnemyLabel (Label3D). |
| BuildingBase .tscn scene tree not fully specified in ARCHITECTURE.md | MEDIUM | HexGrid+Buildings module must create building_base.tscn with: root (Node3D) > BuildingMesh (MeshInstance3D) + HealthComponent (Node). |
| ProjectileBase .tscn scene tree not fully specified in ARCHITECTURE.md | MEDIUM | Enemy+Projectile module must create projectile_base.tscn with: root (Area3D) > ProjectileMesh (MeshInstance3D) + ProjectileCollision (CollisionShape3D, layer 5). |

---

## Section 3 — Godot 4 Project Configuration Checklist

### 3.1 Autoload Registration

Register in `Project > Project Settings > Globals > Autoload` in this EXACT order.
Order matters — later autoloads may depend on earlier ones.

| # | Script Path | Autoload Name | Enabled |
|---|---|---|---|
| 1 | `res://autoloads/signal_bus.gd` | `SignalBus` | Yes |
| 2 | `res://autoloads/damage_calculator.gd` | `DamageCalculator` | Yes |
| 3 | `res://autoloads/economy_manager.gd` | `EconomyManager` | Yes |
| 4 | `res://autoloads/game_manager.gd` | `GameManager` | Yes |

**NOTE (repo drift):** This checklist reflects the *original* four-autoload MVP. The live `project.godot` also registers `CampaignManager`, `EnchantmentManager`, `AutoTestDriver`, and plugin-related autoloads. Treat **ARCHITECTURE.md §1** and **`project.godot` `[autoload]`** as authoritative for the current game.

**WARNING**: CONVENTIONS.md §8 autoload table lists the order as SignalBus → GameManager → EconomyManager → DamageCalculator. This contradicts CONVENTIONS.md §19 and ARCHITECTURE.md §1, both of which specify the order in the table above for the core four. The order in this checklist (matching ARCHITECTURE.md §1 and CONVENTIONS.md §19) is authoritative for that subset. CONVENTIONS.md §8 table order is a documentation bug to be corrected.

### 3.2 Physics Layer Assignments

Configure in `Project > Project Settings > General > Layer Names > 3D Physics`.

| Layer # | Name | Used By |
|---|---|---|
| 1 | Tower | Tower StaticBody3D collision_layer |
| 2 | Enemies | All EnemyBase CharacterBody3D collision_layer |
| 3 | Arnulf | Arnulf CharacterBody3D collision_layer |
| 4 | Buildings | All BuildingBase collision bodies (future — not used in MVP combat) |
| 5 | Projectiles | All ProjectileBase Area3D collision_layer |
| 6 | Ground | Ground StaticBody3D collision_layer, NavigationRegion3D host |
| 7 | HexSlots | HexSlot Area3D nodes for click detection |

### 3.3 Collision Mask Configuration Per Entity

| Entity | collision_layer | collision_mask | Notes |
|---|---|---|---|
| Tower (StaticBody3D) | 1 | (none needed) | Static — enemies collide with it via their mask |
| EnemyBase (CharacterBody3D) | 2 | 1 (Tower) + 3 (Arnulf) + 4 (Buildings) | Enemies detect tower and Arnulf for attack range |
| Arnulf (CharacterBody3D) | 3 | 2 (Enemies) + 6 (Ground) | Moves on ground, collides with enemies |
| BuildingBase (if physics body added) | 4 | (none in MVP) | Buildings are static — no physics interaction in MVP |
| Florence Projectile (Area3D) | 5 | 2 (Enemies) | Hits enemies only. Does NOT include flying sublayer — Florence cannot target flying. Flying filtering handled in _on_body_entered code, not mask. |
| Building Projectile (Area3D) | 5 | 2 (Enemies) | Same as Florence. Anti-Air targets flying — filtering in code. |
| Ground (StaticBody3D) | 6 | (none) | Static ground plane |
| HexSlot (Area3D) | 7 | (none — mouse raycast target) | Used for build mode click detection |
| DetectionArea (Arnulf child Area3D) | (none) | 2 (Enemies) | Detects enemies entering patrol radius |
| AttackArea (Arnulf child Area3D) | (none) | 2 (Enemies) | Detects enemies entering melee range |

### 3.4 Input Map Actions

Configure in `Project > Project Settings > Input Map`.

| Action Name | Event Type | Binding |
|---|---|---|
| `fire_primary` | InputEventMouseButton | Left Mouse Button |
| `fire_secondary` | InputEventMouseButton | Right Mouse Button |
| `cast_shockwave` | InputEventKey | Space |
| `toggle_build_mode` | InputEventKey | B |
| `toggle_build_mode` | InputEventKey | Tab (secondary binding) |
| `cancel` | InputEventKey | Escape |

### 3.5 NavigationRegion3D Setup

1. In `main.tscn`, select `Ground > NavigationRegion3D`.
2. Create a new `NavigationMesh` resource on it.
3. Set NavigationMesh properties:
   - `agent_radius` = 0.5
   - `agent_height` = 2.0
   - `cell_size` = 0.25
   - `cell_height` = 0.25
4. The navigation mesh source geometry must include the Ground mesh and the Tower collision shape (so enemies path around the tower).
5. Bake the navigation mesh in the editor (`Bake NavigationMesh` button).
6. The baked mesh should cover the full play area (~80×80 units centered at origin) with a hole carved for the tower collision volume.
7. Do NOT rebake at runtime in MVP. Buildings do not affect navigation.

### 3.6 GdUnit4 Installation

1. Install GdUnit4 via Godot Asset Library or download from https://github.com/MikeSchulze/gdUnit4.
2. After installation, enable the plugin: `Project > Project Settings > Plugins > gdUnit4 > Enable`.
3. Verify: `GdUnit4` menu appears in the Godot editor top bar.
4. Test directory: all test files go in `res://tests/`. GdUnit4 auto-discovers files matching `test_*.gd`.
5. Test classes extend `GdUnitTestSuite` and use `class_name Test<ModuleName>`.
6. Run tests via `GdUnit4 > Run Tests` or the GdUnit4 panel.

### 3.7 Non-Default Project Settings

| Setting Path | Value | Reason |
|---|---|---|
| `display/window/size/viewport_width` | 1280 | MVP target resolution |
| `display/window/size/viewport_height` | 720 | MVP target resolution |
| `physics/3d/default_gravity` | 0.0 | No gravity — all movement is script-driven on Y=0 plane. Flying enemies hover at fixed Y. |
| `rendering/renderer/rendering_method` | `forward_plus` | Default for 3D. Confirm not changed. |
| `application/run/main_scene` | `res://scenes/main.tscn` | Entry point |

---

## Section 4 — Resource Class Stubs

### 4.1 EnemyData

```gdscript
class_name EnemyData
extends Resource

@export var enemy_type: Types.EnemyType = Types.EnemyType.ORC_GRUNT
@export var display_name: String = ""
@export var max_hp: int = 100
@export var move_speed: float = 3.0
@export var damage: int = 10
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var armor_type: Types.ArmorType = Types.ArmorType.UNARMORED
@export var gold_reward: int = 10
@export var is_ranged: bool = false
@export var is_flying: bool = false
@export var color: Color = Color.GREEN
@export var damage_immunities: Array[Types.DamageType] = []
```

### 4.2 BuildingData

```gdscript
class_name BuildingData
extends Resource

@export var building_type: Types.BuildingType = Types.BuildingType.ARROW_TOWER
@export var display_name: String = ""
@export var gold_cost: int = 50
@export var material_cost: int = 2
@export var upgrade_gold_cost: int = 75
@export var upgrade_material_cost: int = 3
@export var damage: float = 20.0
@export var upgraded_damage: float = 35.0
@export var fire_rate: float = 1.0
@export var attack_range: float = 15.0
@export var upgraded_range: float = 18.0
@export var damage_type: Types.DamageType = Types.DamageType.PHYSICAL
@export var targets_air: bool = false
@export var targets_ground: bool = true
@export var is_locked: bool = false
@export var unlock_research_id: String = ""
@export var color: Color = Color.GRAY
```

### 4.3 WeaponData

```gdscript
class_name WeaponData
extends Resource

@export var weapon_slot: Types.WeaponSlot = Types.WeaponSlot.CROSSBOW
@export var display_name: String = ""
@export var damage: float = 50.0
@export var projectile_speed: float = 30.0
@export var reload_time: float = 2.5
@export var burst_count: int = 1
@export var burst_interval: float = 0.0
@export var can_target_flying: bool = false
```

### 4.4 SpellData

```gdscript
class_name SpellData
extends Resource

@export var spell_id: String = "shockwave"
@export var display_name: String = "Shockwave"
@export var mana_cost: int = 50
@export var cooldown: float = 60.0
@export var damage: float = 30.0
@export var radius: float = 100.0
@export var damage_type: Types.DamageType = Types.DamageType.MAGICAL
@export var hits_flying: bool = false
```

### 4.5 ResearchNodeData

```gdscript
class_name ResearchNodeData
extends Resource

@export var node_id: String = ""
@export var display_name: String = ""
@export var research_cost: int = 2
@export var prerequisite_ids: Array[String] = []
@export var description: String = ""
```

### 4.6 ShopItemData

```gdscript
class_name ShopItemData
extends Resource

@export var item_id: String = ""
@export var display_name: String = ""
@export var gold_cost: int = 50
@export var material_cost: int = 0
@export var description: String = ""
```
