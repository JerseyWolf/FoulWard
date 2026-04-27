# PROMPT 84 — FOUL_WARD_MASTER_DOC.md full update

**Date:** 2026-04-20  
**Scope:** Audit current codebase state and bring `docs/FOUL_WARD_MASTER_DOC.md` in sync.

## Changes Made

### Changelog
- Added entry for 2026-04-20 (this session) and 2026-04-19 (Prompts 77–83 gen3d work).

### Section 1 (Project Identity)
- Test count: **650 → 665** (parallel runner, 2026-04-19, `PROMPT_76_IMPLEMENTATION.md`).

### Section 3.1 (SignalBus)
- Verification date updated to **2026-04-20**; count still **77**.

### Section 5 (Types.gd)
- `GameState`: Added `RING_ROTATE = 12`.
- Added three new enum tables: **`DifficultyTier`** (NORMAL/VETERAN/NIGHTMARE), **`ChronicleRewardType`** (PERK/COSMETIC/TITLE), **`ChroniclePerkEffectType`** (10 values including STARTING_GOLD through COSMETIC_SKIN).

### Section 6 (Game States)
- **`RING_ROTATE` promoted from PLANNED → EXISTS.** Transition graph updated to include `RING_ROTATE`. Noted `GameManager.enter_ring_rotate()` / `exit_ring_rotate()` and `ring_rotation_screen.tscn`.

### Section 8 (Buildings — Ring Rotation)
- Updated from "PLANNED" to **EXISTS**: 42-slot HexGrid, `rotate_ring()`, `RING_ROTATE` state, `ring_rotation_screen.tscn`, save payload v2, `test_ring_rotation.gd`.

### Section 13 (Campaign — Star Difficulty System)
- **Promoted from "DOES NOT EXIST" → "EXISTS IN CODE (backend; UI pending)."** Documented `DifficultyTierData`, three `.tres` files, `GameManager` methods, `TerritoryData.highest_cleared_tier`, `test_difficulty_tier_system.gd`.

### Section 22 (Art Pipeline)
- **Completely rewritten** to document the gen3d pipeline: 5 stages (ComfyUI/TRELLIS.2/Blender/Mixamo/Godot drop), table of stages, generated GLB assets list (8 enemies + 4 allies), key env vars, TRELLIS.2 `transformers==4.56.0` pin, BiRefNet workaround, skill reference.

### Section 23 (SimBot and Testing)
- Test count updated to **665** (2026-04-19).

### Section 24 (Signal Bus Reference)
- **Territories/World Map:** Added `territory_tier_cleared` and `territory_selected_for_replay`.
- **Build Mode:** Added `build_phase_started` and `combat_phase_started`.
- **New sections added:** Sybil Passive (`sybil_passive_selected`, `sybil_passives_offered`), Ring Rotation (`ring_rotated`), Chronicle (`chronicle_entry_completed`, `chronicle_perk_activated`, `chronicle_progress_updated`).

### Section 32 (Field Name Discipline)
- Renamed "Features That Do Not Exist Yet" → **"Feature Status Tracker"**.
- Updated status for: Chronicle (EXISTS), Ring rotation (EXISTS), Sybil passive (EXISTS backend+screen), Star difficulty (backend EXISTS), Mid-battle dialogue (EXISTS via CombatDialogueBanner), Gen3D pipeline (EXISTS off-repo).

### Section 33 (Open TBD Items)
- Resolved/clarified Sybil passive item.
- Added: Gen3D Stage 3 Mixamo rigging blocked, ComfyUI Stage 1 black images issue.

### Section 34 (Related Documents)
- Added gen3d pipeline files (`../gen3d/foulward_gen.py`, `.cursor/skills/gen3d/SKILL.md`).

## Verification

- No `.gd` / `.cs` files changed — GdUnit not required.
- Signal count: **77** (`grep -c '^signal ' autoloads/signal_bus.gd` = 77).
