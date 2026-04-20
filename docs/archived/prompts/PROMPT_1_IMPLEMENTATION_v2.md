> **Note:** Second session numbered “PROMPT 1” (2026-03-31); distinct from [`PROMPT_1_IMPLEMENTATION.md`](PROMPT_1_IMPLEMENTATION.md) in this folder (2026-03-24 — build menu / input routing).

# PROMPT 1 — Agent Skills verification (read-only)

**Date:** 2026-03-31  
**Scope:** Cross-check `.cursor/skills/**` against the repo; update skills; no tests run.

## Summary

Verified flagged `⚠️ VERIFY` items against sources of truth and corrected skill content where it diverged.

### Autoloads (`godot-conventions/SKILL.md`)

- **`project.godot`** lists **20** `[autoload]` entries, not 17: after `EnchantmentManager`, three addon autoloads are registered (`MCPScreenshot`, `MCPInputService`, `MCPGameInspector` from `addons/godot_mcp/`).
- Documented full ordered table (1–20) and noted 17 core game + tooling/MCP entries.

### Economy (`economy-system/SKILL.md`)

- Confirmed `EconomyManager`: `DEFAULT_GOLD = 1000`, `DEFAULT_BUILDING_MATERIAL = 50`, `DEFAULT_RESEARCH_MATERIAL = 0` in `autoloads/economy_manager.gd`.

### Campaign (`campaign-and-progression/SKILL.md`, `references/game-manager-api.md`)

- Confirmed `GameManager`: `WAVES_PER_MISSION = 5`, `TOTAL_MISSIONS = 5` in `autoloads/game_manager.gd`.

### Enums (`enemy-system/references/enemy-types.md`, `building-system/references/building-types.md`)

- **EnemyType** (30 values), **DamageType** including **TRUE**, and **EnemyBodyType** ordinals match `scripts/types.gd`.
- **BuildingType** (36 values) and **BuildingSizeClass** match `scripts/types.gd`.

### SignalBus (`signal-bus/references/signal-table.md`, `signal-bus/SKILL.md`)

- Rebuilt the signal table from `autoloads/signal_bus.gd`: **63** signals with correct parameter lists. Previous table had wrong names (`boss_defeated`, `territory_captured`, etc.) and outdated payloads (e.g. `enemy_killed` uses `Types.EnemyType`, not `EnemyData`).

### WeaponUpgradeManager (`spell-and-research-system/SKILL.md`)

- Documented public API from `scripts/weapon_upgrade_manager.gd` (`upgrade_weapon`, `get_current_level`, `get_max_level`, `get_effective_*`, `get_next_level_data`, `get_level_data`, `reset_to_defaults`, exports).

### Allies (`ally-and-mercenary-system/SKILL.md`)

- Listed all **12** `ally_id` values from `resources/ally_data/*.tres`; noted starter (`arnulf`) and unique flags from files.

### Scene tree (`scene-tree-and-physics/SKILL.md`)

- Replaced overview with structure from **`scenes/main.tscn`**: added `TerrainContainer`, `AllyContainer`, `AllySpawnPoints`, `BuildingContainer`, `Camera3D`, `ResearchPanel`, `MissionBriefing`, `Hub`, `UIManager`/`DialoguePanel` layout; removed incorrect direct `NavigationRegion3D` under `Main` (nav lives in terrain scenes under `scenes/terrain/`).
- Input: confirmed `cast_shockwave` and `cast_selected_spell` both exist in `project.godot`; noted spell slots and cycle actions.

### Factions & bosses (`enemy-system/SKILL.md`)

- **Faction:** `campaign_main_50days.tres` uses empty `faction_id`; `CampaignManager.validate_day_configs` maps empty to `"DEFAULT_MIXED"`.
- **Boss IDs:** Corrected path to `resources/bossdata_*.tres` and actual `boss_id` values: `final_boss`, `orc_warlord`, `plague_cult_miniboss`, `audit5_territory_mini` (replacing placeholder names like `plague_lord` / `brood_mother`).

### Other

- **`enemy-system/SKILL.md`:** Fixed `enemy_killed` emit signature in the flow section to match `signal_bus.gd`.
- **`building-system/SKILL.md`:** Confirmed 36 building types vs `types.gd`.
- Removed all `⚠️ VERIFY` markers after confirmation; no new VERIFY flags added (no remaining uncertainties requiring a flag).

## Files touched

- `.cursor/skills/godot-conventions/SKILL.md`
- `.cursor/skills/economy-system/SKILL.md`
- `.cursor/skills/campaign-and-progression/SKILL.md`
- `.cursor/skills/campaign-and-progression/references/game-manager-api.md`
- `.cursor/skills/enemy-system/SKILL.md`
- `.cursor/skills/enemy-system/references/enemy-types.md`
- `.cursor/skills/building-system/SKILL.md`
- `.cursor/skills/building-system/references/building-types.md`
- `.cursor/skills/signal-bus/SKILL.md`
- `.cursor/skills/signal-bus/references/signal-table.md`
- `.cursor/skills/spell-and-research-system/SKILL.md`
- `.cursor/skills/ally-and-mercenary-system/SKILL.md`
- `.cursor/skills/scene-tree-and-physics/SKILL.md`
- `docs/archived/prompts/PROMPT_1_IMPLEMENTATION_v2.md` (this file)
