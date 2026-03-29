# Foul Ward — Future 3D Models & Art Pipeline Plan

## 1. Overview

This document is the **authoritative roadmap** for moving Foul Ward from **Blender-generated Rigify placeholders** and **primitive `.tres` meshes** to **production 3D assets** (and matching **2D hub portraits**). It complements:

- **`ArtPlaceholderHelper`** (`res://scripts/art/art_placeholder_helper.gd`) — runtime resolution of **Mesh** / **Material** from `res://art/meshes/**` with optional override from `res://art/generated/meshes/*.tres` (legacy path). There is **no** `resolve_mesh()` API; use **`get_enemy_mesh()`**, **`get_building_mesh()`**, **`get_ally_mesh()`**, etc., typically from **`initialize()`** on combat units (not `_ready()`), after `EnemyData` / `BuildingData` is available. **GLB files** live under `res://art/generated/{enemies,allies,buildings,bosses,misc}/` and are intended to be **swapped in** as imported `PackedScene` roots when gameplay scenes are refactored to use skeletal animation.
- **`res://art/generated/`** — batch output from `tools/generate_placeholder_glbs_blender.py` (Blender 4.x headless). Regenerate after changing faction shapes or animation keyframes.

**When to revisit:** at the start of any **art milestone** (vertical slice, trailer, or outsourcing); after **faction roster** changes; when **adding a new enemy/building/boss** type (update the Blender batch script + this file’s roster tables).

**Source of truth for placeholder inventory:** `res://art/generated/generation_log.json` (written by the generator; includes `godot_mcp.reload_project` metadata when verified).

---

## 2. Current placeholder status

Generated **2026-03-28** by `tools/generate_placeholder_glbs_blender.py` (Blender **4.0.2**).  
`current_mesh` = on-disk GLB path under `res://art/generated/`.  
**Clip names** in GLBs: `idle` (frames 1–60), `walk` (61–120), `death` (121–150) for animated entries.

| entity_id | type | current_mesh | has_rig | animations | placeholder_quality |
|-----------|------|--------------|---------|------------|---------------------|
| orc_grunt | enemies | res://art/generated/enemies/orc_grunt.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| orc_brute | enemies | res://art/generated/enemies/orc_brute.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| goblin_firebug | enemies | res://art/generated/enemies/goblin_firebug.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| plague_zombie | enemies | res://art/generated/enemies/plague_zombie.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| orc_archer | enemies | res://art/generated/enemies/orc_archer.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| bat_swarm | enemies | res://art/generated/enemies/bat_swarm.glb | no (Empty root) | idle, walk, death | empty_parent_animated |
| arnulf | allies | res://art/generated/allies/arnulf.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| arrow_tower | buildings | res://art/generated/buildings/arrow_tower.glb | no | — | static_primitive_composite |
| fire_brazier | buildings | res://art/generated/buildings/fire_brazier.glb | no | — | static_primitive_composite |
| magic_obelisk | buildings | res://art/generated/buildings/magic_obelisk.glb | no | — | static_primitive_composite |
| poison_vat | buildings | res://art/generated/buildings/poison_vat.glb | no | — | static_primitive_composite |
| ballista | buildings | res://art/generated/buildings/ballista.glb | no | — | static_primitive_composite |
| archer_barracks | buildings | res://art/generated/buildings/archer_barracks.glb | no | — | static_primitive_composite |
| anti_air_bolt | buildings | res://art/generated/buildings/anti_air_bolt.glb | no | — | static_primitive_composite |
| shield_generator | buildings | res://art/generated/buildings/shield_generator.glb | no | — | static_primitive_composite |
| plague_cult_miniboss | bosses | res://art/generated/bosses/plague_cult_miniboss.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| orc_warlord | bosses | res://art/generated/bosses/orc_warlord.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| final_boss | bosses | res://art/generated/bosses/final_boss.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| audit5_territory_mini | bosses | res://art/generated/bosses/audit5_territory_mini.glb | yes | idle, walk, death | rigify_low_poly_v1 |
| tower_core | misc | res://art/generated/misc/tower_core.glb | no | — | static_misc |
| hex_slot | misc | res://art/generated/misc/hex_slot.glb | no | — | static_misc |
| projectile_crossbow | misc | res://art/generated/misc/projectile_crossbow.glb | no | — | static_misc |
| projectile_rapid_missile | misc | res://art/generated/misc/projectile_rapid_missile.glb | no | — | static_misc |
| unknown_mesh | misc | res://art/generated/misc/unknown_mesh.glb | no | — | static_misc |

---

## 3. Production asset pipeline (when ready)

Use this sequence whenever a placeholder GLB is replaced.

### a. Hyper3D / Rodin (text-to-3D)

1. Sign in at [hyper3d.ai](https://hyper3d.ai) (or your Rodin-capable tool).
2. Use a **faction style brief** (see §6) + **entity description** + **T-pose** + topology hint (`18k quad` for rank-and-file, `50k quad` for named characters / bosses).
3. Iterate on the **free preview**; pay to export the mesh package when silhouette reads well at **combat camera distance**.

### b. Blender — Rigify, bind

1. Import the **T-pose GLB/FBX** into Blender 4.x.
2. Enable **Rigify** add-on → add **Human Meta-Rig**, align to mesh.
3. **Parent mesh to metarig** → **Armature Deform with Automatic Weights**.
4. **Pose → Generate Rig**; verify deformation on `chest`, `upper_arm_fk.*`, `root`.

### c. Mixamo — animation pack

1. Export **T-pose** as FBX from Blender (no animation, Apply Transform as needed).
2. Upload to **Mixamo**; pick **idle**, **walk**, **run** (optional), **attack** variants, **death**.
3. Download **FBX for Unity** (binary, with skin) per clip — consistent skeleton.

### d. Blender — combine clips into one GLB

1. Import all Mixamo FBX files into one `.blend`.
2. Use **NLA Editor** or **Action strips** so each clip is a separate **Action** with a clear name (`idle`, `walk`, `attack_melee`, `death`).
3. Ensure **export_animation_mode=ACTIONS** compatibility (same as `tools/generate_placeholder_glbs_blender.py`).

### e. Export path (overwrite placeholder)

Export **GLB** to the **same path** as the batch tool:

`res://art/generated/<type>/<entity_id>.glb`

**Types:** `enemies`, `allies`, `buildings`, `bosses`, `misc`.

Godot reimports automatically; **ArtPlaceholderHelper** continues to resolve **primitive `.tres`** until scenes are switched to **instanced GLB** — plan a **scene refactor milestone** to load `PackedScene` instead of assigning `Mesh` only.

### f. Validate in Godot

1. **Godot MCP Pro:** `reload_project` after export.
2. Open imported scene: confirm **MeshInstance3D** (+ **Skeleton3D** + **AnimationPlayer** for rigged assets).
3. **GDAI MCP:** `get_godot_errors` after reimport; fix material or bone naming issues.

---

## §4 — Modular Building Kit

### Kit Pieces Required (12 total)
| ID (enum name)   | Filename                  | Used by towers            |
|------------------|---------------------------|---------------------------|
| STONE_ROUND      | stone_base_round.glb      | Arrow, Magic Obelisk, Ballista |
| STONE_SQUARE     | stone_base_square.glb     | Fire Brazier, Poison Vat, Shield Gen |
| WOOD_ROUND       | wood_base_round.glb       | Archer Barracks           |
| RUINS_BASE       | ruins_base.glb            | Ruins-tier towers         |
| ROOF_CONE        | roof_cone.glb             | Arrow Tower, Archer Barracks |
| ROOF_FLAT        | roof_flat.glb             | Shield Generator, Ballista base |
| GLASS_DOME       | glass_dome.glb            | Magic Obelisk             |
| FIRE_BOWL        | fire_bowl.glb             | Fire Brazier              |
| POISON_TANK      | poison_tank.glb           | Poison Vat                |
| BALLISTA_FRAME   | ballista_frame.glb        | Ballista                  |
| EMBRASURE        | embrasure.glb             | Arrow Tower, Archer Barracks |
| ARCH_WINDOW      | arch_window.glb           | All towers (optional detail) |

### Rodin Prompt Template
Use this prefix for all kit pieces to ensure visual consistency:

  "Medieval dark-fantasy stone architecture kit piece, single mesh,
  low-poly game asset, 800–1200 tris, PBR textures 512×512,
  muted desaturated palette, worn stone texture, no color variation
  on albedo, neutral grey base so faction accent_color ShaderMaterial
  override reads correctly. T-pose equivalent: upright, centered
  at origin, fits 1m × 1m × 1m bounding box. [PIECE DESCRIPTION]"

Replace [PIECE DESCRIPTION] per piece, e.g.:
  - stone_base_round: "Circular stone tower base, 1.2m diameter,
    rough-cut stone blocks, slight mossy weathering at base ring."
  - roof_cone: "Pointed conical slate roof cap, 0.8m base diameter,
    1.2m tall, slate tile texture, slight overhang edge."

### Attribution
Structural reference: alpapaydin/Godot-4-Tower-Defense-Template (MIT)
https://github.com/alpapaydin/Godot-4-Tower-Defense-Template

---

## 5. Entity-by-entity production TODO (roster)

**Priority legend:** **HIGH** = primary combat visibility; **MEDIUM** = allies / buildings; **LOW** = hub-only, escorts, or test-only.

Faction briefs are summarized in §6.

### Enemies (`res://resources/enemy_data/*.tres`)

- [ ] **orc_grunt** (enemies, Orc Raiders) — HIGH — Rodin: “Stocky green-brown orc infantry, leather straps, cleaver, **T-pose**, 18k quad, game RTS silhouette”. Anims: idle, walk, attack, death.
- [ ] **orc_brute** (Orc Raiders) — HIGH — “Heavy orc, oversized shoulders, slow menace, **T-pose**, 18k quad”. Anims: idle, walk, attack, death.
- [ ] **goblin_firebug** (neutral/goblin) — HIGH — “Small goblin alchemist, fire jars, hunched, **T-pose**, 18k quad”. Anims: idle, walk, throw, death.
- [ ] **plague_zombie** (Plague Cult) — HIGH — “Gaunt grey-green zombie, torn robes, **T-pose**, 18k quad”. Anims: idle, shamble, attack, death.
- [ ] **orc_archer** (Orc Raiders) — HIGH — “Lean orc archer, quiver, **T-pose**, 18k quad”. Anims: idle, walk, shoot, death.
- [ ] **bat_swarm** (flying) — MEDIUM — “Flattened bat cluster or single bat proxy, **T-pose** or wings spread neutral, 18k quad”. Anims: idle flap, move, death fall.

### Allies (`res://resources/ally_data/*.tres`)

- [ ] **arnulf** (allies) — HIGH — Named companion: “Armored humanoid defender, faction tan/brown, **T-pose**, 50k quad”. Anims: idle, walk, attack, downed/recover (custom), death.
- [ ] **ally_melee_generic** — MEDIUM — “Mercenary melee, modular armor, **T-pose**, 18k quad”. Anims: idle, walk, attack, death.
- [ ] **ally_ranged_generic** — MEDIUM — “Mercenary archer, **T-pose**, 18k quad”. Anims: idle, walk, shoot, death.
- [ ] **ally_support_generic** — MEDIUM — “Support staff silhouette, **T-pose**, 18k quad”. Anims: idle, walk, buff (placeholder), death.
- [ ] **anti_air_scout**, **hired_archer**, **defected_orc_captain** — MEDIUM/LOW — Reuse faction kits where possible; note **defected** narrative tint.

### Buildings (`res://resources/building_data/*.tres`)

Static meshes only (no skeleton). Priority **MEDIUM**.

- [ ] **arrow_tower**, **fire_brazier**, **magic_obelisk**, **poison_vat**, **ballista**, **archer_barracks**, **anti_air_bolt**, **shield_generator** — Rodin prompts: “Grey stone base + **faction accent** trim (see §6), **top-down RTS** readable, modular kit piece, no rig, 18k quad.”

### Bosses (`res://resources/boss_data/*.tres`)

- [ ] **plague_cult_miniboss** — HIGH — “Large plague cult champion, sickly green accents, **T-pose**, 50k quad”. Anims: idle, walk, phase attack, death.
- [ ] **orc_warlord** — HIGH — “Massive orc warlord, banners optional, **T-pose**, 50k quad”. Anims: idle, walk, heavy attack, death.
- [ ] **final_boss** — HIGH — “Archrot-themed end boss, unique silhouette, **T-pose**, 50k quad+”. Anims: idle, walk, multi-phase attacks, death.
- [ ] **audit5_territory_mini** — LOW (test) — Reuse miniboss kit or simple unique mesh.

### Hub characters (`res://resources/character_data/*.tres`)

**2D portraits only** for hub UI — see §7. **Florence** is referenced in dialogue but **no** `character_data` resource yet; add when hub roster expands.

---

## 6. Consistency strategy

**Faction style briefs** (embed in every Rodin / art brief):

| Faction | Visual keywords |
|---------|-----------------|
| **Orc Raiders** | Warm olive and brown leather, heavy silhouettes, asymmetric scrap armor, angular silhouettes. |
| **Plague Cult** | Desaturated grey-green, emaciated proportions, dripping organic accents, hoods and bandages. |
| **Allies / neutral merc** | Earthy tan and brown cloth, medium proportions, readable hero read. |
| **Buildings** | Grey stone base + **one** accent color per faction (orc: rust metal; plague: sickly green trim). |

**Seed locking:** store a **per-faction random seed** or **reference mood board URLs** in `docs/` (not in GDScript stats). Reuse **substance palette** hex codes across Rodin prompts for a given milestone.

**Visual coherence:** batch-generate **concept orthographic turns** (front/side) before full sculpt for heroes and bosses; reuse **weapon modules** across orc units.

---

## 7. Hub character portraits (2D)

Characters: **Florence** (player voice — UI only today), **Arnulf** hub, **merchant**, **researcher** (Sybil), **enchantress**, **mercenary captain**, **flavor NPC**. **Not** 3D combat models.

**TODO:** Commission or generate **512×512 PNG** portraits (consistent border lighting, transparent or dark oval crop).

**Placeholder:** `character_base_2d.tscn` uses **ColorRect** + **NameLabel**; swap **Body** to **TextureRect** when assets exist.

---

## 8. PhysicalBone3D ragdoll plan (Godot-side)

After production GLB import, **per humanoid** enemy and ally:

1. Open imported scene → select **Skeleton3D** → **PhysicalBone3D** wizard (or manual): spine, hips, limbs; **disable** on small enemies if performance requires.
2. Set **joint limits** (cone + twist) matching Rigify limb axes; cap **collision** layers to **ragdoll-only** vs **static** geometry.
3. On **`SignalBus.enemy_killed`** / ally death: call **`physical_bones_start_simulation()`** (or custom `enable_ragdoll()` on the character script) — **not** authored in Blender; **post-import** in Godot only.

**Flying / bat:** optional **simple jointed wing** ragdoll or **skip** ragdoll (instant dissolve VFX).

---

## 9. Animation state machine wiring plan

**Expected clip names** (match exported GLB): `idle`, `walk`, `death`; add `attack_*` when Mixamo/production clips exist.

| Scene / controller | AnimationPlayer owner | Signals / states driving clips |
|----------------------|----------------------|--------------------------------|
| **EnemyBase** (+ subclasses) | Child of GLB root or `EnemyMesh` sibling | **Navigation:** walk when `velocity.length() > epsilon`; else idle. **HealthComponent.health_depleted** → death (one-shot, **no** loop). |
| **BossBase** | Same as enemy | **boss_phase** (future): add `ability_cast` / `phase_transition`. **boss_killed** → death. |
| **Arnulf** | Under `Arnulf` root | **`Types.ArnulfState`:** IDLE/PATROL → idle; CHASE → walk; ATTACK → attack clip; DOWNED/RECOVERING → custom; death on incapacitate if added. |
| **AllyBase** | Generic ally root | Mirror enemy: chase → walk; attack → attack; death on `ally_killed`. |

**Note:** Current MVP assigns **`Mesh`** only; **AnimationTree** or **AnimationPlayer.play()** wiring is **post-placeholder**.

---

## 10. Tools and costs reference

| Stage | Tool | Cost pattern |
|-------|------|----------------|
| Placeholder mesh + Rigify + GLB | **Blender** (open source) | Free |
| glTF export dependency | **Python numpy** for Blender’s bundled Python | Free (`pip install --user numpy --break-system-packages` on PEP 668 distros, or `apt install python3-numpy` when available) |
| Text-to-3D preview | **Hyper3D / Rodin** | Free preview; pay per HD export |
| Rigging assist | **Mixamo** | Free autorig + clips for small teams |
| Retopo / cleanup | **Blender** | Free |
| **Upgrade trigger** | — | Move from placeholder to production when **trailer**, **vertical slice**, or **publisher** milestone requires readable silhouette at target resolution |

---

## §5 — Terrain System

### Architecture

TerrainContainer (Node3D in `main.tscn`) is cleared and repopulated each battle by `CampaignManager._load_terrain()`. Each terrain scene contains:

- GroundMesh + StaticBody3D (walkable ground)
- NavRegion (NavigationRegion3D, registered with NavMeshManager autoload)
- TerrainZones (Area3D with `terrain_zone.gd`, optional — SLOW effect only)
- Props (DestructibleProp / ImmovableProp containers, not yet implemented)

### Terrain Types Status

| Type       | Scene file                | Status    | Notes                     |
|------------|---------------------------|-----------|---------------------------|
| GRASSLAND  | terrain_grassland.tscn    | Done   | Flat, no zones            |
| SWAMP      | terrain_swamp.tscn        | Done   | 0.55× speed zone          |
| FOREST     | terrain_forest.tscn       | TODO(TERRAIN) | Dense tree props, 0.75× zone |
| RUINS      | terrain_ruins.tscn        | TODO(TERRAIN) | Destructible pillars       |
| TUNDRA     | terrain_tundra.tscn       | TODO(TERRAIN) | 0.7× speed (snow), ice patches |

### DestructibleProp (Future)

Uses Jummit/godot-destruction-plugin (MIT):
https://github.com/Jummit/godot-destruction-plugin

On health_depleted: call destroy(), emit SignalBus.terrain_prop_destroyed, emit SignalBus.nav_mesh_rebake_requested → NavMeshManager queues rebake.

### Speed Zone Design Guide

- SLOW zones: use TerrainZone Area3D with speed_multiplier < 1.0
- IMPASSABLE zones: use NavigationObstacle3D with affect_navigation_mesh=true, baked into NavRegion before battle. Do NOT use TerrainZone for impassable.
- Overlapping zones: EnemyBase takes the MINIMUM multiplier automatically.

### Attribution

- Navmesh rebake queue pattern: community contributor, godotengine/godot#81181
  https://github.com/godotengine/godot/issues/81181 (public domain snippet)
- Navigation pattern reference: quiver-dev/tower-defense-tutorial (MIT)
  https://github.com/quiver-dev/tower-defense-tutorial
- Destructible props (future): Jummit/godot-destruction-plugin (MIT)
  https://github.com/Jummit/godot-destruction-plugin

---

## Appendix A — Scene art audit (verified 2026-03-29)

**Method:** Full-text grep `res://art/` across all `*.tscn` (seven files with `ext_resource` mesh/material paths); inline-mesh scenes listed separately. **Blender MCP `execute_blender_code` is not in this repo** — placeholders are produced by **`tools/generate_placeholder_glbs_blender.py`** (Blender headless). **Godot MCP Pro** `reload_project` after changes; **`get_editor_errors`** scanned for GLB import failures (none; only existing GDScript warnings such as `SHADOWED_GLOBAL_IDENTIFIER` on `ArtPlaceholderHelper` preload aliases).

| Scene | Art reference | Real file? | ArtPlaceholderHelper / mesh resolution | AnimationPlayer |
|-------|---------------|------------|----------------------------------------|-----------------|
| `scenes/enemies/enemy_base.tscn` | `art/meshes/enemies/enemy_orc_grunt.tres` + faction material | Yes (primitive `.tres`) | **`EnemyBase.initialize()`** → `get_enemy_mesh()` / `get_enemy_material()` (`_ready` only sets label) | Not present; GLB clips not wired |
| `scenes/buildings/building_base.tscn` | `unknown_mesh.tres` | Yes | **`BuildingBase.initialize()`** → `get_building_mesh()` / `get_building_material()` | None |
| `scenes/tower/tower.tscn` | `tower_core.tres` + neutral material | Yes | **`Tower._ready()`** → `get_tower_mesh()` | None (static) |
| `scenes/arnulf/arnulf.tscn` | `ally_arnulf.tres` + allies material | Yes | **`Arnulf._ready()`** → `get_ally_mesh("arnulf")` | Not present |
| `scenes/allies/ally_base.tscn` | Inline `BoxMesh` | N/A | **No** `initialize()` mesh hook for generic mercs yet (`# TODO(ART)` in script) | None |
| `scenes/bosses/boss_base.tscn` | Inline `BoxMesh` | N/A | **`initialize_boss_data()`** → **`EnemyBase.initialize()`** uses placeholder **EnemyData** mesh; **`_configure_visuals()`** tints only — boss GLB swap in `# TODO(ART)` | None |
| `scenes/hex_grid/hex_grid.tscn` | `hex_slot.tres` | Yes | Not via helper | None |
| `scenes/projectiles/projectile_base.tscn` | `projectile_crossbow.tres` | Yes | Not via helper | None |
| `ui/hub.tscn` | Character catalog / 2D scenes | N/A | 2D **ColorRect** portraits via `character_base_2d.tscn` | N/A |

**Gaps:** No `.tscn` references **`res://art/generated/*.glb`** directly; combat uses **`.tres` Mesh** or **inline** primitives. **Generated GLBs** exist on disk (see `generation_log.json`) with **Skeleton3D** where Rigify applied; **runtime** does not yet instance `PackedScene` from GLB. **Hub** has no `TextureRect` portraits yet.

**Godot MCP (2026-03-29):** `reload_project` → `Filesystem rescanned.` No new art import errors in editor error scan.

---

## Appendix B — Regenerating placeholders

```bash
cd /path/to/FoulWard
blender --background --python tools/generate_placeholder_glbs_blender.py
```

Requires **numpy** available to Blender’s Python (see §10).
