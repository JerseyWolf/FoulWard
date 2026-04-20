# PROMPT 72 — Group 7 Ring Rotation Pre-Battle UI

## Summary

- **HexGrid:** `RING3_COUNT` 24, `RING3_RADIUS` 24.0, `TOTAL_SLOTS` 42; `hex_grid.tscn` adds `HexSlot_24`–`HexSlot_41`. Per-ring `_ring_offsets` + `rotate_ring(ring_index, angle_rad)`; `SignalBus.ring_rotated`; building positions updated on rebuild; `get_ring_offset_radians` for tests.
- **Types / C#:** `RING_ROTATE` = 12 in `types.gd` / `FoulWardTypes.RingRotate`.
- **SignalBus:** `ring_rotated(ring_index, angle_rad)` — **73** signals; docs + `signal-table.md` updated.
- **GameManager:** `enter_ring_rotate` / `exit_ring_rotate`; `exit_passive_select` → `enter_ring_rotate()`.
- **SaveManager:** payload `"version": 2`, `HEX_GRID_SLOT_COUNT`, `is_hex_slot_index_in_save_range`, v1 migration comment in `_apply_save_payload`.
- **UI:** `scenes/ui/ring_rotation_screen.tscn` + `scripts/ui/ring_rotation_screen.gd`; `main.tscn` instance; `UIManager` routes `RING_ROTATE`.
- **SimBot:** `RING_ROTATE` included in mission-active states.
- **Tests:** `tests/test_ring_rotation.gd` (13 methods); `test_hex_grid.gd`, `test_simulation_api.gd`, `test_building_repair.gd` updated for 42 slots.
- **Docs:** AGENTS, INDEX_*, FOUL_WARD_MASTER_DOC, ARCHITECTURE, CONVENTIONS, SUMMARY_VERIFICATION, signal-bus/building-system skills.

## Verification

- `dotnet build FoulWard.csproj`
- `./tools/run_gdunit_quick.sh` / `./tools/run_gdunit.sh`
