---
name: add-new-entity
description: >-
  Activate when adding any new entity type to Foul Ward: new building, new
  enemy type, new spell, new research node, or new signal. Contains complete
  step-by-step templates for all four entity types. Use when: add new, create
  new, new building, new spell, new research, new signal, template, scaffold,
  how to add, new entity.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Add New Entity Templates — Foul Ward

---

## How to Add a New Building (9 steps)

1. Add `BUILDING_NAME` to `Types.BuildingType` enum in `scripts/types.gd` — **append only**, never change existing values
2. Create `resources/building_data/building_name.tres` (`class_name BuildingData`)
3. Set `building_id = "building_name"` (matches .tres filename without extension — no spaces)
4. Populate required fields: `gold_cost`, `material_cost`, `damage`, `damage_type`, `target_priority`, `building_size_class`
5. If aura: set `is_aura = true`, `aura_effect_type` (`damage_pct` or `enemy_speed_pct`), `aura_modifier_value`
6. If summoner: set `is_summoner = true`, `squad_ally_ids: Array[String]`
7. If research-locked: set `is_locked = true`, `unlock_research_id = "node_id_string"`
8. Register .tres in the `BuildMenu` scene's building catalog
9. Write at minimum: `test_building_name_can_be_placed_and_sold()`

**Document update checklist:**
- Move from PLANNED → EXISTS in `docs/FOUL_WARD_MASTER_DOC.md` §8
- Add to enum table in §5
- Add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- Update `.cursor/skills/building-system/references/building-types.md`

---

## How to Add a New Signal (7 steps)

Full detail and the **repo-wide signal-count checklist** live in `.cursor/skills/signal-bus/SKILL.md` — use that file as canonical when in doubt.

1. Declare in `autoloads/signal_bus.gd` — past tense, fully typed payload:
```gdscript
signal your_event_happened(param_one: Type, param_two: Type)
```
2. Emit at the correct point in the emitting script:
```gdscript
SignalBus.your_event_happened.emit(param_one, param_two)
```
3. Connect with `is_connected` guard in any listener:
```gdscript
if not SignalBus.your_event_happened.is_connected(_on_your_event_happened):
    SignalBus.your_event_happened.connect(_on_your_event_happened)
```
4. Add to `.cursor/skills/signal-bus/references/signal-table.md` under the correct category
5. Add to `docs/INDEX_FULL.md` SignalBus registry section
6. **Bump the documented signal total** — follow **Signal count in documentation** in `signal-bus/SKILL.md` (re-count `^signal ` in `signal_bus.gd`, update `AGENTS.md`, master doc, `CONVENTIONS.md`, `ARCHITECTURE.md`, indexes, `signal-table.md` header, Perplexity prompts if they cite a number)
7. Write a test using `monitor_signals` + `assert_signal`

**Never declare a cross-system signal anywhere other than `signal_bus.gd`.**

---

## How to Add a New Spell (5 steps)

1. Create `resources/spell_data/spell_name.tres` (`class_name SpellData`)
2. Set required fields:
```gdscript
spell_id: String = "spell_name"       # snake_case, unique
display_name: String = "Display Name"
mana_cost: int = 50
cooldown: float = 60.0
damage: float = 0.0                   # 0.0 is valid for control spells
damage_type: Types.DamageType
hits_flying: bool = false
radius: float = 10.0
```
3. Register the .tres in `main.tscn` → SpellManager's `spell_registry` array (wired in the scene, not in code)
4. Wire hotkey if needed: hotkeys 1–4 map to spell slots 0–3 (set in InputManager)
5. Write test: `test_spell_name_casts_when_mana_sufficient()`

**NEVER implement Time Stop spell — formally cut.**
`slow_field.tres` has `damage = 0.0` intentionally — do not "fix" it.

**Document update checklist:**
- Move from PLANNED → EXISTS in `docs/FOUL_WARD_MASTER_DOC.md` §7
- Add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`

---

## How to Add a New Research Node (6 steps)

1. Create `resources/research_data/node_id.tres` (`class_name ResearchNodeData`)
2. Set required fields:
```gdscript
node_id: String = "node_id"              # snake_case, unique — field is "node_id" NOT "id"
display_name: String = "Display Name"
research_cost: int = 2                   # field is "research_cost" NOT "rp_cost"
prerequisite_ids: Array[String] = []     # empty = no prerequisites
description: String = ""
```
3. If this node unlocks a building: also set `is_locked = true` and `unlock_research_id = "node_id"` on that `BuildingData`
4. Register .tres in `ResearchManager`'s node catalog (loaded from `res://resources/research_data/`)
5. Add to research tree UI if a panel exists
6. Write test: `test_node_id_unlocks_when_prereqs_met()`

**Document update checklist:**
- Move from PLANNED → EXISTS in `docs/FOUL_WARD_MASTER_DOC.md` §9
- Add to `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`

---

## Universal Document Update Checklist

After adding ANY new entity:
- [ ] Move from PLANNED → EXISTS in the relevant master doc section
- [ ] Add field names to §32 (Field Name Discipline) if any new fields introduced
- [ ] Add new signals to §24 (Signal Bus Reference)
- [ ] Update changelog at top of `docs/FOUL_WARD_MASTER_DOC.md`
- [ ] Update `docs/INDEX_SHORT.md` and `docs/INDEX_FULL.md`
- [ ] Log in `docs/PROMPT_[N]_IMPLEMENTATION.md`
