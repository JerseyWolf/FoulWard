---
name: spell-and-research-system
description: >-
  Activate when working with spells, mana, research nodes, enchantments, or
  weapon upgrades in Foul Ward. Use when: spell, mana, cooldown, shockwave,
  research, unlock, prerequisite, enchantment, weapon upgrade, SpellManager,
  ResearchManager, EnchantmentManager, WeaponUpgradeManager, mana_regen,
  spell_id, research_cost, enchantment slot, elemental, power slot.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Spell and Research System — Foul Ward

---

## SpellManager (Scene-Bound)

Path: `/root/Main/Managers/SpellManager`

```gdscript
SpellManager.cast_spell(spell_id: String) -> bool
SpellManager.cast_selected_spell() -> bool
SpellManager.get_current_mana() -> int
SpellManager.get_max_mana() -> int             # default 100
SpellManager.get_cooldown_remaining(spell_id: String) -> float
SpellManager.is_spell_ready(spell_id: String) -> bool
SpellManager.set_mana_to_full() -> void
SpellManager.restore_mana(amount: int) -> void  # ≤0 = full restore
SpellManager.reset_to_defaults() -> void
SpellManager.set_mana_for_save_restore(mana: int) -> void
SpellManager.get_selected_spell_index() -> int
SpellManager.set_selected_spell_index(index: int) -> void
SpellManager.cycle_selected_spell(delta: int) -> void  # ±1
SpellManager.get_selected_spell_id() -> String
```

**Mana:** max 100, regen 5.0/sec
**Hotkeys:** Space = cast selected, Tab/Shift+Tab = cycle, 1–4 = select slot

---

## Registered Spells

| .tres File | Display Name | Mana | Cooldown |
|---|---|---|---|
| `shockwave.tres` | Shockwave | 50 | 60s |
| `slow_field.tres` | Slow Field | — | — |
| `arcane_beam.tres` | Arcane Beam | — | — |
| `tower_shield.tres` | Aegis Pulse | — | — |

`slow_field.tres` has `damage = 0.0` — **intentional control spell, do not fix**.
**FORMALLY CUT: Time Stop spell — never implement.**

---

## ResearchManager (Scene-Bound)

Path: `/root/Main/Managers/ResearchManager`

```gdscript
ResearchManager.can_unlock(node_id: String) -> bool
ResearchManager.unlock_node(node_id: String) -> bool
ResearchManager.unlock(node_id: String) -> void       # alias
ResearchManager.is_unlocked(node_id: String) -> bool
ResearchManager.get_available_nodes() -> Array[ResearchNodeData]
ResearchManager.get_research_points() -> int
ResearchManager.add_research_points(amount: int) -> void
ResearchManager.show_research_panel_for(node_id: String) -> void
ResearchManager.reset_to_defaults() -> void
ResearchManager.get_save_data() -> Dictionary         # {unlocked_node_ids: [...]}
ResearchManager.restore_from_save(data: Dictionary) -> void
```

**24 research nodes** in `resources/research_data/`.
Field names: `node_id`, `research_cost` (**NOT** `rp_cost`), `prerequisite_ids`.

---

## EnchantmentManager (Autoload #17)

```gdscript
EnchantmentManager.get_equipped_enchantment_id(weapon_slot: Types.WeaponSlot, slot_type: String) -> String
EnchantmentManager.get_equipped_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> EnchantmentData
EnchantmentManager.get_all_equipped_enchantments_for_weapon(weapon_slot: Types.WeaponSlot) -> Dictionary
EnchantmentManager.try_apply_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String, enchantment_id: String, gold_cost: int) -> bool
EnchantmentManager.remove_enchantment(weapon_slot: Types.WeaponSlot, slot_type: String) -> void  # FREE
EnchantmentManager.get_affinity_level(weapon_slot: Types.WeaponSlot) -> int    # POST-MVP inert
EnchantmentManager.get_affinity_xp(weapon_slot: Types.WeaponSlot) -> float     # POST-MVP inert
EnchantmentManager.gain_affinity_xp(weapon_slot: Types.WeaponSlot, amount: float) -> void  # POST-MVP inert
EnchantmentManager.reset_to_defaults() -> void
EnchantmentManager.get_save_data() -> Dictionary
EnchantmentManager.restore_from_save(data: Dictionary) -> void
```

**Slot types per weapon:** `"elemental"` and `"power"`
**4 enchantments:** `arcane_focus`, `scorching_bolts`, `sharpened_mechanism`, `toxic_payload`
**Remove:** FREE. **Apply:** costs gold.
**Affinity XP:** POST-MVP — all three affinity methods are inert stubs. Do NOT implement.

---

## WeaponUpgradeManager (Scene-Bound)

Path: `/root/Main/Managers/WeaponUpgradeManager`  
File: `scripts/weapon_upgrade_manager.gd` (`class_name WeaponUpgradeManager`)

Per-weapon level tracking (0 = base, max `MAX_LEVEL` = 3), upgrade costs, effective stat accessors. On successful upgrade: `SignalBus.weapon_upgraded.emit(weapon_slot, new_level)`.

**Public API (verified 2026-03-31):**

| Method | Returns |
|---|---|
| `upgrade_weapon(weapon_slot: Types.WeaponSlot) -> bool` | Spends gold/material via EconomyManager; false if max level or unaffordable |
| `get_current_level(weapon_slot: Types.WeaponSlot) -> int` | 0–3 |
| `get_max_level() -> int` | `MAX_LEVEL` (3) |
| `get_effective_damage` / `get_effective_speed` / `get_effective_reload_time` / `get_effective_burst_count` | `float` or `int` per weapon |
| `get_effective_pierce_count` / `get_effective_projectile_count` / `get_effective_spread_angle_degrees` / `get_effective_splash_radius` | Derived from level bonuses |
| `get_next_level_data(weapon_slot) -> WeaponLevelData` | Next tier preview for UI |
| `get_level_data(weapon_slot, level: int) -> WeaponLevelData` | Level 1–3 only |
| `reset_to_defaults() -> void` | Levels to 0 |

`@export`: `crossbow_levels`, `rapid_missile_levels`, `crossbow_base_data`, `rapid_missile_base_data`.
