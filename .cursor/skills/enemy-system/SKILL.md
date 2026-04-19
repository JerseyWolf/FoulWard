---
name: enemy-system
description: >-
  Activate when working with enemies in Foul Ward: EnemyBase, EnemyData,
  spawning, damage calculation, pathfinding, bosses, factions, armor types,
  damage types, damage matrix. Use when: enemy, EnemyBase, EnemyData, spawn,
  pathfinding, damage calculator, armor, DamageType, ArmorType, boss, faction,
  mini-boss, flying enemy, ground enemy, undead, wave composition, EnemyType.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Enemy System — Foul Ward

---

## Key Classes

| Class | File | Role |
|---|---|---|
| `EnemyBase` | `scenes/enemies/enemy_base.gd` | Base enemy scene script |
| `EnemyData` | `resources/enemy_data/*.tres` | Resource: all enemy stats |
| `DamageCalculator` | `autoloads/damage_calculator.gd` | Autoload #3: stateless damage matrix |

---

## DamageCalculator API

```gdscript
# Autoload #3 — stateless, pure function
DamageCalculator.calculate_damage(
    base_damage: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float

DamageCalculator.calculate_dot_tick(
    dot_total_damage: float,
    tick_interval: float,
    duration: float,
    damage_type: Types.DamageType,
    armor_type: Types.ArmorType
) -> float
```

---

## Damage Matrix (4×5)

PHYSICAL FIRE MAGICAL POISON TRUE
UNARMORED 1.0 1.0 1.0 1.0 1.0
HEAVY_ARMOR 0.5 1.0 2.0 1.0 1.0
UNDEAD 1.0 2.0 1.0 0.0 1.0
FLYING 1.0 1.0 1.0 1.0 1.0


TRUE damage type bypasses the matrix entirely — always 1.0 multiplier.

---

## EnemyData Fields

```gdscript
@export var enemy_type: Types.EnemyType
@export var display_name: String
@export var max_hp: int              # NOT hp, NOT health
@export var move_speed: float
@export var damage: int
@export var armor_type: Types.ArmorType
@export var gold_reward: int
@export var is_flying: bool
@export var body_type: Types.EnemyBodyType
```

---

## Navigation

- **Ground enemies**: `NavigationAgent3D` + NavMesh baked by `NavMeshManager`
- **Flying enemies**: Simple steering, Y offset (e.g. Y = 5.0), ignore NavMesh
- **Hover enemies**: Body type HOVER — ground movement, elevated collision
- Always check `is_instance_valid(target)` before accessing enemy reference

---

## Faction Structure

3 factions defined in `.tres` resources:

| Faction ID | Composition |
|---|---|
| `DEFAULT_MIXED` | Fallback — used when `DayConfig.faction_id` is empty |
| `ORC_RAIDERS` | Orc-heavy physical damage enemies |
| `PLAGUE_CULT` | Undead + poison enemies |

**Empty `faction_id`:** legacy DayConfigs may use `faction_id = ""`. `CampaignManager.validate_day_configs` resolves empty to `"DEFAULT_MIXED"` when validating. Canonical 50-day asset: `res://resources/campaigns/campaign_main_50_days.tres`.

---

## Boss Structure

Four `BossData` resources under `resources/bossdata_*.tres` (not `boss_data/`):

| boss_id | File | Notes |
|---|---|---|
| `final_boss` | `bossdata_final_boss.tres` | `is_final_boss = true` |
| `orc_warlord` | `bossdata_orc_warlord_miniboss.tres` | Mini-boss |
| `plague_cult_miniboss` | `bossdata_plague_cult_miniboss.tres` | Mini-boss |
| `audit5_territory_mini` | `bossdata_audit5_territory_miniboss.tres` | Test / audit |

*Verified against resource files (2026-03-31).*

---

## Enemy-Reaching-Tower Flow (§27.3)

1. Enemy `HealthComponent` reaches 0 OR enemy reaches tower origin
2. If tower reached: `SignalBus.tower_damaged.emit(current_hp, max_hp)`
3. If hp = 0: `SignalBus.enemy_killed.emit(enemy_type, position, gold_reward)` (`Types.EnemyType`, `Vector3`, `int`)
4. `EnemyBase.queue_free()` — always deferred
5. `is_instance_valid()` guard required on any reference held by other systems

---

## Critical Rules

- Always `is_instance_valid()` before accessing any enemy reference
- Never access `enemy.global_position` without an `is_instance_valid()` guard
- EnemyData files: `max_hp` (not `hp`, not `health`)
- Brood Carrier on-death spawns via `WaveManager.spawn_enemy_at_position()`
- Enemy groups: all active instances in group `"enemies"`

---

## Full Type Tables

Read `references/enemy-types.md` when:
- Looking up the integer value of an EnemyType enum
- Checking which tier an enemy belongs to
- Verifying ArmorType or EnemyBodyType values
