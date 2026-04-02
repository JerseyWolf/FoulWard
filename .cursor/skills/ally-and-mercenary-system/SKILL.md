---
name: ally-and-mercenary-system
description: >-
  Activate when working with allies, Arnulf, Sybil, mercenaries, or the ally
  roster in Foul Ward. Use when: ally, mercenary, Arnulf, Sybil, Florence hub
  role, companion, recruit, roster, squad, summoner building ally, defection,
  hire, AllyManager, AllyData, ally_id, is_starter_ally, is_unique, DOWNED,
  RECOVERING, patrol_radius, state machine.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Ally and Mercenary System — Foul Ward

---

## Arnulf (EXISTS IN CODE)

| Field | Value |
|---|---|
| Script | `scenes/arnulf/arnulf.gd` |
| `ally_id` | `"arnulf"` |
| `max_hp` | 200 |
| `basic_attack` | 25.0 |
| `is_unique` | true |
| `is_starter_ally` | true |
| `patrol_radius` | 55.0 |

**State machine** (`Types.ArnulfState`):

| State | Value | Behaviour |
|---|---|---|
| IDLE | 0 | Standing still |
| PATROL | 1 | Wandering within patrol_radius |
| CHASE | 2 | Moving toward target enemy |
| ATTACK | 3 | Attacking target enemy |
| DOWNED | 4 | Incapacitated |
| RECOVERING | 5 | Recovering — `health_component.reset_to_max()` (full HP) |

**Signals** (local on Arnulf node):
`arnulf_state_changed`, `arnulf_incapacitated`, `arnulf_recovered`
(Also on SignalBus — see signal table.)

**Kill counter** exists but frenzy activation is NOT in MVP.
**FORMALLY CUT: Arnulf drunkenness system — never implement.**

---

## Sybil (PARTIAL — spell management exists; passive system PLANNED)

- Role: Spell researcher / spell support
- Spell system managed via SpellManager (see spell-and-research-system skill)
- **Sybil Passive Selection System**: PLANNED, not yet in code — stubs only
- Do not implement passive system until explicitly tasked

---

## AllyManager (Autoload #11)

```gdscript
AllyManager.spawn_squad(building: BuildingBase) -> void
# Spawns leader + followers for a summoner building

AllyManager.despawn_squad(building_instance_id: String) -> void
# Frees all allies for that building — keyed by placed_instance_id
```

---

## AllyData Fields

```gdscript
@export var ally_id: String             # use ally_data.ally_id (NOT .get("ally_id", ""))
@export var display_name: String
@export var max_hp: int
@export var attack_damage: float
@export var is_unique: bool
@export var is_starter_ally: bool
@export var ally_class: Types.AllyClass
```

**AllyData is a Resource** — use typed field access, never `.get(key, default)`.

---

## 12 Ally .tres Files

`ally_id` strings in `resources/ally_data/` (verified 2026-03-31, one file per id):

`ally_melee_generic`, `ally_ranged_generic`, `ally_support_generic`, `anti_air_scout`, `arnulf`, `bear_alpha`, `defected_orc_captain`, `hired_archer`, `knight_captain`, `militia_archer`, `wolf_alpha`, `wolf_pup`

Starter roster: only `arnulf_ally_data.tres` sets `is_starter_ally = true` (others omit the field or set false). Uniqueness: `arnulf` and `defected_orc_captain` are `is_unique = true`.

---

## Mercenary System

```gdscript
# Generate offers for a given day
CampaignManager.generate_offers_for_day(day: int) -> void

# Preview without mutating state
CampaignManager.preview_mercenary_offers_for_day(day: int, hypothetical_owned: Array[String]) -> Array

# Get current offers
CampaignManager.get_current_offers() -> Array

# Purchase offer at index (spends resources, adds ally to roster)
CampaignManager.purchase_mercenary_offer(index: int) -> bool

# Defection offer injection after mini-boss defeat
CampaignManager.notify_mini_boss_defeated(boss_id: String) -> void
```

**Max active allies per day:** 2 (`max_active_allies_per_day`)

---

## DOWNED → RECOVERING

```gdscript
# On DOWNED→RECOVERING transition:
health_component.reset_to_max()  # Full HP recovery — not partial
```
