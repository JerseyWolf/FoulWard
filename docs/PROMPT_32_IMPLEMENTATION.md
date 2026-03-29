# PROMPT 32 — Modular Building Kit System

**Date:** 2026-03-29

## Summary

Implemented enum-driven modular building kit assembly: `Types.BuildingBaseMesh` / `Types.BuildingTopMesh`, `BuildingData` exports (`base_mesh_id`, `top_mesh_id`, `accent_color`), `ArtPlaceholderHelper.get_building_kit_mesh()`, and `BuildingBase.initialize()` wiring when kit enums differ from the default legacy pair (`STONE_ROUND` + `ROOF_CONE`). Documented kit filenames and Rodin template in `FUTURE_3D_MODELS_PLAN.md` (§4 — Modular Building Kit); renumbered following sections (5–10). Added `tests/unit/test_building_kit.gd`; updated `run_gdunit_quick.sh`, `run_gdunit_unit.sh`, and `run_gdunit_parallel.sh` (include `tests/unit/*.gd`).

## Files touched

- `scripts/types.gd` — `BuildingBaseMesh`, `BuildingTopMesh` enums
- `scripts/resources/building_data.gd` — kit exports + defaults
- `scripts/art/art_placeholder_helper.gd` — `get_building_kit_mesh()` + kit path helpers
- `scenes/buildings/building_base.gd` — kit visual + `BuildingKitAssembly` + `TODO(ART-KIT)`
- `FUTURE_3D_MODELS_PLAN.md` — §4 kit table, Rodin template, attribution; section renumber
- `tests/unit/test_building_kit.gd` — four GdUnit tests
- `tools/run_gdunit_quick.sh`, `tools/run_gdunit_unit.sh`, `tools/run_gdunit_parallel.sh`
- `docs/INDEX_SHORT.md`, `docs/INDEX_FULL.md`

## Notes

- **BuildingBase:** Kit is applied in `initialize()` after placeholder mesh logic, because `BuildingData` is only available there (matches `ArtPlaceholderHelper` usage for combat units).
- **MCP:** Godot MCP not invoked in this session (headless CI path; no editor required for these changes).
- **RAG:** Not verified this session.

## Verification

- `./tools/run_gdunit.sh` — run before completion (see session log for exit code).
