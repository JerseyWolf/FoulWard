# PROMPT 53 — ARCHITECTURE.md audit (2026-03-31)

## Goal

Align `docs/ARCHITECTURE.md` with the current `project.godot` autoload list, `scenes/main.tscn` / MCP `get_scene_tree`, and `docs/FOUL_WARD_MASTER_DOC.md` §§2–4, 25–26. Factual corrections only (paths, counts, names).

## Sources

- `docs/ARCHITECTURE.md` (before)
- `docs/FOUL_WARD_MASTER_DOC.md` §2, §3, §4, §25, §26
- `project.godot` autoload section
- `scenes/main.tscn`, `scenes/arnulf/arnulf.tscn`
- MCP `get_scene_tree` (Godot MCP Pro — `main.tscn` open in editor)
- MCP `get_editor_errors` — baseline editor errors recorded (pre-existing UI parse issues; not introduced by this doc change)

## Archive

- Previous doc: `docs/archived/ARCHITECTURE_pre_prompt53.md`

## Changes (summary)

1. **§1 Autoloads:** Full table (20 entries): core 17 + `GDAIMCPRuntime` + three `addons/godot_mcp/*` helpers; `NavMeshManager` position #2; `AuraManager` and all other singletons through `EnchantmentManager`.
2. **§2 Scene tree:** `TerrainContainer` instead of obsolete `Ground`; `TerrainContainer`/`WeaponUpgradeManager` in managers; UI: `Hub`, `ResearchPanel`, `DialoguePanel` under `UIManager`; `ArnulfVisual` instead of `ArnulfMesh`; 3-ring hex grid; script `main_root.gd` on `Main`.
3. **Manager path contracts:** Documented `InputManager` at `/root/Main/Managers/InputManager`.
4. **§3.1:** Pointer to §1 for full autoload list; `DamageCalculator` matrix wording (includes TRUE damage).
5. **BuildingBase / EnemyBase:** 36 / 30 types (registry enums).
6. **WaveManager / §4.2 / §5.4 / §6 exports:** WaveComposer + WavePatternData; countdown defaults (3s / 10s); `max_waves` 5; removed obsolete “N×6 types” / “wave 10” / 30s-between-waves wording.
7. **SpellManager / InputManager / spell flow:** `cast_selected_spell`, multi-spell registry.
8. **Spell flow diagram:** Space → `cast_selected_spell` or `cast_spell`.
9. **Nav (§5.3, §9.1):** Terrain scenes under `TerrainContainer` + `NavMeshManager`; removed “Ground only” description.
10. **§5.2:** Three rings; sell path uses `get_sell_refund()`; step numbering fixed.
11. **§5.6:** Matrix description aligned with five damage types and TRUE bypass.
12. **HexGrid [Place]:** Left as high-level (economy still uses `can_afford` / spend patterns in code).

## Verification

- `./tools/run_gdunit_quick.sh` — **exit 100** (2026-03-31). Failures observed in existing suites (e.g. `test_waves_per_mission_constant_is_3` vs `WAVES_PER_MISSION == 5`, SimBot integration); **not caused by documentation edits** (no `.gd` / scene changes in this prompt).
