# Compliance Report H4 — Scene Tree/Physics, Spell/Research, Ally/Mercenary
Date: 2026-03-31

Audit only (no code changes). Skills read in full: `.cursor/skills/scene-tree-and-physics/SKILL.md`, `.cursor/skills/spell-and-research-system/SKILL.md`, `.cursor/skills/ally-and-mercenary-system/SKILL.md`.

**Note:** Prior reports H2/H3 are not present in this repository snapshot. **CHECK D (scene-tree)** and **CHECK B (ally)** for H2/H3 cross-references were satisfied by direct verification in this sweep.

---

## Skill: scene-tree-and-physics

### CHECK A — Contracted manager paths via `get_node` / `get_node_or_null`
**PASS — 0 path violations**

Searched usages of `WaveManager`, `SpellManager`, `ResearchManager`, `ShopManager`, `WeaponUpgradeManager`, `InputManager` combined with `get_node` under `autoloads/`, `scripts/`, `scenes/`, and `ui/` (spell skill scope).

- All production resolutions target `/root/Main/Managers/<ManagerName>` or equivalent relative resolution from `Main/Managers` (e.g. `game_manager.gd` uses `main.get_node_or_null("Managers")` then `get_node_or_null("WaveManager")` — same node as `/root/Main/Managers/WaveManager`).
- `dialogue_manager.gd` uses `managers.get_node_or_null("ResearchManager")` — same contract.
- Test-only wiring (e.g. `tests/test_consumables.gd` attaching a node named `SpellManager` under `Managers`) is intentional scene setup, not a wrong hierarchy.

### CHECK B — `global_position` vs local `.position` for cross-node math
**PASS — 0 flagged issues**

Filtered `.position` in `autoloads/`, `scripts/`, `scenes/` `.gd` files: hits are local offsets on child meshes / kit visuals (`art_placeholder_helper.gd`, `building_base.gd`), not world-space handoffs between unrelated nodes.

### CHECK C — Physics layers in base `.tscn` files
**1 violation found**

| File | Expected (skill table) | Actual | Notes |
|------|------------------------|--------|--------|
| `scenes/enemies/enemy_base.tscn` | Enemies = layer 2 | `collision_layer = 2` | OK |
| `scenes/buildings/building_base.tscn` | Buildings = layer 4 | `BuildingCollision` `collision_layer = 8` (bit 3 = layer 4) | OK |
| `scenes/tower/tower.tscn` | Tower = layer 1 | `collision_layer = 1` | OK |
| `scenes/projectiles/projectile_base.tscn` | Projectiles = layer 5 | `collision_layer = 0`, `collision_mask = 0` | **Mismatch** at scene rest; runtime `projectile_base.gd` `_configure_collision()` sets layer 5 and mask for enemies via `set_collision_layer_value(5, true)` / `set_collision_mask_value(2, true)`. Editor/default instance does not match the contracted layer table until initialized. |

### CHECK D — Flying enemies bypass NavMesh
**PASS — reference H2 N/A (verified here)**

`enemy_base.gd`: ground enemies configure `NavigationAgent3D` and nav-driven movement; `is_flying` uses `_physics_process_flying()` and does not rely on nav pathing for flight. Aligns with the skill.

### CHECK E — NavMesh rebake / `bake_navigation_mesh`
**2 violations (game contract) + 1 tooling note**

1. **`SignalBus.nav_mesh_rebake_requested` is never emitted** in `autoloads/`, `scripts/`, or `scenes/`. `NavMeshManager` connects the signal to `request_rebake()`, but no game code triggers rebakes through the documented SignalBus path (e.g. after terrain/build changes). **Violates the documented “rebake via signal” workflow.**
2. **`NavMeshManager.request_rebake()`** calls `_nav_region.bake_navigation_mesh(true)` **inside NavMeshManager** — allowed by “outside NavMeshManager” wording, but production code never goes through `nav_mesh_rebake_requested` as specified in the skill.
3. **Tooling (non-game):** `addons/godot_mcp/commands/navigation_commands.gd` and duplicate under `../foulward-mcp-servers/godot-mcp-pro/...` call `region.bake_navigation_mesh()` directly — acceptable for editor MCP, but **not** routed through `NavMeshManager` / SignalBus.

`tests/unit/test_terrain.gd` calls `NavMeshManager.request_rebake()` directly — acceptable for unit tests.

---

## Skill: spell-and-research-system

### CHECK A — SpellManager path
**PASS — 0 violations**

All `get_node_or_null` / `@onready` SpellManager lookups in production code use `/root/Main/Managers/SpellManager` (e.g. `game_manager.gd`, `input_manager.gd`, `shop_manager.gd`, `sim_bot.gd`).

### CHECK B — `slow_field.tres` damage
**PASS**

`resources/spell_data/slow_field.tres`: `damage = 0.0` (intentional control spell).

### CHECK C — Time Stop spell absent
**PASS**

No matches for `time_stop`, `TimeStop`, or `time stop` in `resources/spell_data/`, `scripts/`, or `scenes/`.

### CHECK D — `research_cost` (no `rp_cost`)
**PASS**

No `rp_cost` / `.rp_cost` in `resources/research_data/`, gameplay `scripts/`, or `scenes/`. (Occurrences exist only in docs and skill/metadata files.)

### CHECK E — EnchantmentManager affinity (POST-MVP inert)
**PASS**

`gain_affinity_xp`, `get_affinity_level`, `get_affinity_xp` appear **only** as stub implementations in `autoloads/enchantment_manager.gd`. No call sites treat them as meaningful elsewhere.

### CHECK F — Enchantment save/restore in SaveManager
**PASS — no AP-14 violation**

`autoloads/save_manager.gd`: `_build_save_payload()` includes `"enchantments": EnchantmentManager.get_save_data()`; `_apply_save_payload()` calls `EnchantmentManager.restore_from_save(ench as Dictionary)` when the key is present.

---

## Skill: ally-and-mercenary-system

### CHECK A — Arnulf drunkenness absent
**PASS**

No matches for drunk/drunken/alcohol/`\bale\b` (case-insensitive) in `autoloads/`, `scripts/`, `scenes/`, or `resources/` `.{gd,tres,tscn}`.

### CHECK B — AllyData typed field access (H3 reference)
**1 violation (spot-check; H3 report unavailable)**

- `autoloads/campaign_manager.gd` (`_score_offer`): `ally_data` is typed as `Resource` but scored with `ally_data.get("role")` and `od.get("role")` instead of `AllyData` + `.role`. This bypasses the skill’s “typed field access” rule even though `AllyData` defines `@export var role`.

Elsewhere (e.g. `ally_base.gd`, `ally_manager.gd`) uses `AllyData` typing appropriately.

### CHECK C — Sybil passive stubs only
**PASS**

No matches for `passive_select`, `sybil.*passive`, or `passive.*sybil` in `autoloads/`, `scripts/`, or `scenes/`.

### CHECK D — `spawn_squad` / `despawn_squad` keyed by `placed_instance_id`
**PASS — 0 violations**

- `scenes/buildings/building_base.gd`: `despawn_squad(placed_instance_id)`.
- `scenes/hex_grid/hex_grid.gd`: `despawn_squad(building.placed_instance_id)`.
- `tests/unit/test_summoner_runtime.gd`: sets `building.placed_instance_id = "test_wolf_001"` before spawn/despawn; key matches squad dictionary — correct test usage.

### CHECK E — `max_active_allies_per_day` enforced (2/day)
**PASS**

`CampaignManager.max_active_allies_per_day = 2` and enforcement lives in `campaign_manager.gd` (`set_active_allies_from_list`, roster helpers, save/load paths). UI (`between_mission_screen.gd`) reads the cap from `CampaignManager`; tests temporarily assign other values — expected. **`GameManager._active_allies`** tracks runtime mission allies and is separate from the campaign “active roster for next day” limit — not a duplicate hardcoded cap violation.

### CHECK F — DOWNED→RECOVERING full HP (`reset_to_max`)
**PASS**

- `scenes/arnulf/arnulf.gd` `_process_recovering()`: `health_component.reset_to_max()` before transitioning to IDLE.
- `scenes/allies/ally_base.gd` `_update_recovering()`: `health_component.reset_to_max()`.

---

## Priority Violations

1. **NavMesh rebake signal unused:** `nav_mesh_rebake_requested` is never emitted; terrain/managers register regions but documented SignalBus-driven rebake path is dead in game code.
2. **`projectile_base.tscn` collision layers:** Default `collision_layer` / `collision_mask` are 0; contracted table expects projectiles on layer 5 (runtime fixes after `initialize_*`, not in raw scene).
3. **CampaignManager AllyData access:** `_score_offer` uses `.get("role")` on `Resource` instead of typed `AllyData.role`.
4. **MCP navigation bake:** Direct `bake_navigation_mesh` in Godot MCP addon (editor-only; bypasses project NavMeshManager pattern).
5. _(No fifth item at the same severity; spell subsystem checks were clean.)_

---

## Total Violation Count

| Skill | Violations (strict count) |
|------|---------------------------|
| scene-tree-and-physics | **3** (1 scene layer mismatch; 2 nav rebake contract issues — unused signal + note on MCP bypass) |
| spell-and-research-system | **0** |
| ally-and-mercenary-system | **1** (AllyData `.get("role")`) |
| **Grand total** | **4** |

If MCP/tooling is excluded from the sweep, **grand total = 3**.
