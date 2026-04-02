# PROMPT_60 — Session I-D: SignalBus phase signals + nav rebake documentation

**Date:** 2026-03-31

## Task 1 — `build_phase_started` / `combat_phase_started`

### Decision

**Moved both signals to `SignalBus`.**

**Evidence:** `grep` showed `BuildMenu` and `ResearchPanel` connect to `BuildPhaseManager.combat_phase_started`. Those UI nodes are not children of `BuildPhaseManager`; they are cross-system consumers (HUD ↔ phase lifecycle). `build_phase_started` had no subscribers but is part of the same lifecycle API and is now discoverable on `SignalBus` with `combat_phase_started`.

### Code changes

- `autoloads/signal_bus.gd`: declared `build_phase_started()` and `combat_phase_started()` under **BUILD MODE** (after `build_mode_exited`), with brief doc comments.
- `autoloads/build_phase_manager.gd`: removed local `signal` declarations; `set_build_phase_active()` emits via `SignalBus`.
- `ui/build_menu.gd`, `ui/research_panel.gd`: connect to `SignalBus.combat_phase_started` with `is_connected` guards.

### Docs / skills

- `.cursor/skills/signal-bus/SKILL.md`: new section **When local signals are acceptable** (autoload listeners ⇒ use `SignalBus`).
- `.cursor/skills/building-system/SKILL.md`: BuildPhaseManager snippet updated to reference `SignalBus` emits.
- `.cursor/skills/lifecycle-flows/SKILL.md`: flow diagrams note `SignalBus.build_phase_started` / `combat_phase_started` at `set_build_phase_active` transitions.
- `docs/INDEX_FULL.md`, `docs/INDEX_SHORT.md`: BuildPhaseManager line updated.
- `docs/FOUL_WARD_MASTER_DOC.md`: BuildPhaseManager table + signals line updated (phase signals on `SignalBus`).
- `.cursor/skills/signal-bus/references/signal-table.md`: table rows + count **65**.

## Task 2 — `nav_mesh_rebake_requested` never emitted

### Decision

**Document-only (static navmesh + obstacles). No `emit()` added in `hex_grid.gd`.**

**Evidence:**

- `NavMeshManager` already connects `SignalBus.nav_mesh_rebake_requested` → `request_rebake()` in `_ready()`.
- `HexGrid` places buildings and calls `_activate_building_obstacle()`; `BuildingBase` exposes `NavigationObstacle3D` (see `tests/test_building_base.gd`). Ground enemies avoid buildings without rebaking the region mesh.
- Rebaking on every placement would be expensive and is unnecessary for obstacle-based avoidance.

### Code / docs changes

- `scripts/nav_mesh_manager.gd`: comment block above the connect explaining MVP static bake, obstacles, and that gameplay does not emit the signal yet.
- `.cursor/skills/scene-tree-and-physics/SKILL.md`: navigation overview + NavMesh section updated to match reality (optional hook, MVP unused).
- `signal-table.md`: `nav_mesh_rebake_requested` row notes MVP non-emission.

## Verification

- `./tools/run_gdunit_quick.sh`
- `./tools/run_gdunit.sh`
