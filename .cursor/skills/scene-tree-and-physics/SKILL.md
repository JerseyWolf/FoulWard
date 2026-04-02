---
name: scene-tree-and-physics
description: >-
  Activate when working with scene tree structure, node paths, physics layers,
  collision masks, input actions, or coordinate system in Foul Ward. Use when:
  scene tree, node path, get_node, physics layer, collision, input action,
  camera, ground, navigation, navmesh, spawn point, container, layer mask,
  keybinding, coordinate system, Y-up, global_position.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Scene Tree and Physics — Foul Ward

---

## Scene Tree Overview

Verified against `scenes/main.tscn` (2026-03-31). Use MCP `get_scene_tree` when the editor is running to confirm runtime tree matches after scene edits.

```
/root
└── Main (main.tscn)
    ├── Camera3D
    ├── DirectionalLight3D
    ├── TerrainContainer (placeholder — terrain scenes loaded at runtime)
    ├── Tower
    ├── Arnulf
    ├── HexGrid
    ├── SpawnPoints
    │   └── SpawnPoint_00 .. SpawnPoint_09
    ├── EnemyContainer
    ├── AllyContainer
    ├── AllySpawnPoints
    │   └── AllySpawnPoint_00 .. AllySpawnPoint_02
    ├── BuildingContainer
    ├── ProjectileContainer
    ├── Managers
    │   ├── WaveManager
    │   ├── SpellManager
    │   ├── ResearchManager
    │   ├── ShopManager
    │   ├── WeaponUpgradeManager
    │   └── InputManager
    └── UI (CanvasLayer)
        ├── UIManager
        ├── Hub
        ├── HUD
        ├── BuildMenu
        ├── ResearchPanel
        ├── BetweenMissionScreen
        ├── MainMenu
        ├── MissionBriefing
        ├── EndScreen
        └── DialoguePanel (parent: UI/UIManager in scene file)
```

**Navigation:** `NavigationRegion3D` lives under terrain prefabs (e.g. `scenes/terrain/terrain_grassland.tscn`, `terrain_swamp.tscn`), not as a direct child of `Main`. `SignalBus.nav_mesh_rebake_requested` is declared and `NavMeshManager` listens — **gameplay does not emit it** in MVP: the navmesh is baked once at load; **buildings** add `NavigationObstacle3D` (see `BuildingBase` / `HexGrid._activate_building_obstacle`) so ground enemies avoid them without rebaking. Emit `nav_mesh_rebake_requested` only if terrain geometry becomes dynamic.

---

## Manager Node Path Contracts

These paths are contracted — they will not change without updating this document and `AGENTS.md` (repo root):

| Manager | Path |
|---|---|
| WaveManager | `/root/Main/Managers/WaveManager` |
| SpellManager | `/root/Main/Managers/SpellManager` |
| ResearchManager | `/root/Main/Managers/ResearchManager` |
| ShopManager | `/root/Main/Managers/ShopManager` |
| WeaponUpgradeManager | `/root/Main/Managers/WeaponUpgradeManager` |
| InputManager | `/root/Main/Managers/InputManager` |

All resolved via `get_node_or_null()` with a null guard. WaveManager absent in headless = silent skip (by design).

---

## Physics Layers

| Layer # | Name | Used By |
|---|---|---|
| 1 | Tower | Tower collision body |
| 2 | Enemies | All EnemyBase collision bodies |
| 3 | Arnulf | Arnulf's collision body |
| 4 | Buildings | All BuildingBase collision bodies |
| 5 | Projectiles | All ProjectileBase collision bodies |
| 6 | Ground | Ground plane / NavigationMesh |
| 7 | HexSlots | Hex slot click detection (Area3D) |

---

## Collision Mask Configuration

| Actor | Collides With (layers) |
|---|---|
| Florence projectiles | Layer 2 (Enemies) only |
| Building projectiles | Layer 2 (Enemies) only |
| Enemies | Layer 1 (Tower) + Layer 3 (Arnulf) + Layer 4 (Buildings) |
| Arnulf | Layer 2 (Enemies) |
| HexSlot Area3D | Layer 7 only (mouse click detection) |

---

## Input Actions

Defined in `project.godot` Input Map:

| Action Name | Default Binding | Purpose |
|---|---|---|
| `fire_primary` | Left Mouse | Florence crossbow |
| `fire_secondary` | Right Mouse | Florence rapid missile |
| `cast_shockwave` | Space | Cast selected spell |
| `toggle_build_mode` | B or Tab | Enter/exit build mode |
| `cancel` | Escape | Exit build mode / close menu |

**Spell inputs:** `project.godot` defines both `cast_selected_spell` and `cast_shockwave` (same default key Space). Spell hotkeys: `spell_slot_1`–`spell_slot_4`, plus `spell_cycle_next` / `spell_cycle_prev`.

---

## Coordinate System

- **Y-up** coordinate system (Godot 4 standard)
- **Ground plane**: Y = 0
- **Tower center**: world origin `Vector3(0, 0, 0)`
- **Flying enemies**: Y offset above ground (e.g. Y = 5.0)
- **All positions**: use `global_position`, never local `position`, for cross-node calculations
- Hex grid positions computed from axial coordinates, stored as `Vector3`

---

## NavMesh

- `NavMeshManager` (Autoload #2) registers `NavigationRegion3D`
- Optional rebake hook: `SignalBus.nav_mesh_rebake_requested.emit()` → `NavMeshManager.request_rebake()` (unused in MVP; reserved for dynamic terrain)
- Ground enemies use `NavigationAgent3D`
- Flying enemies bypass NavMesh entirely (simple steering)
