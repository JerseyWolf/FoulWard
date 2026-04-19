# Session 07 — Report 01: Animation Clip Name Table

**Generated:** 2026-04-19 (synced with `scripts/art/rigged_visual_wiring.gd`).

**Note:** `drunk_idle` is formally cut (Arnulf drunkenness system).

## StringName constants in code

```gdscript
const ANIM_IDLE: StringName = &"idle"
const ANIM_WALK: StringName = &"walk"
const ANIM_DEATH: StringName = &"death"
const ANIM_ATTACK: StringName = &"attack"
const ANIM_HIT_REACT: StringName = &"hit_react"
const ANIM_SPAWN: StringName = &"spawn"
const ANIM_RUN: StringName = &"run"
const ANIM_ATTACK_MELEE: StringName = &"attack_melee"
const ANIM_DOWNED: StringName = &"downed"
const ANIM_RECOVERING: StringName = &"recovering"
const ANIM_SHOOT: StringName = &"shoot"
const ANIM_CAST_SPELL: StringName = &"cast_spell"
const ANIM_VICTORY: StringName = &"victory"
const ANIM_DEFEAT: StringName = &"defeat"
const ANIM_ACTIVE: StringName = &"active"
const ANIM_DESTROYED: StringName = &"destroyed"
const ANIM_PHASE_TRANSITION: StringName = &"phase_transition"
```

## Entity categories

| entity_category | required_clips | optional_clips | notes |
|-----------------|----------------|----------------|-------|
| enemies (30 types) | idle, walk, attack, hit_react, death | spawn | Uniform 6+clip set per `enemy_rigged_glb_path()` |
| allies (arnulf + mercs) | idle, run, attack_melee, hit_react, death, downed, recovering | — | `ally_rigged_glb_path(ally_id)` |
| florence / sybil (tower) | idle, shoot, hit_react, cast_spell, victory, defeat | — | Tower: `tower_glb_path()` |
| buildings (36 types) | idle, active, destroyed | — | `building_rigged_glb_path(building_type)` |
| bosses | idle, walk, attack, death | phase_transition | `boss_rigged_glb_path(boss_id)` (+ audit5_territory_mini) |

## Validator alignment

`tools/validate_art_assets.gd` required clips per category should stay aligned with this table (allies may use `walk` where locomotion is validated — see tool source).
