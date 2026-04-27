# PROMPT 91 — Gen3D Phase D (2-panel crop + orc grunt clean test)

**Date:** 2026-04-21

## Summary

- **D1:** No live Phase C processes (`blender`/`foulward`/`trellis`/`comfyui`); Phase C tmp artifacts under `/tmp/fw_c*` left as-is (scripts + decimation ladder); VRAM idle (~3.5 GiB).
- **Pipeline fix:** `TRELLIS_CROP_TO_FRONT = True`; `crop_front_view()` uses **left half** (`w // 2`) for 2-panel front+back sheets; confirmed crop on `/tmp/fw_orc_ref.png` → **1024×2048**; Blender decimate smoke test **OK**.
- **D2–D7:** Fresh ComfyUI 2048² sheets A/B; crop → rembg → `clean_alpha_for_trellis`; TRELLIS 12× (seeds 42, 256, 512 × 512/768 inputs); Blender decimate 25k/12k; artifacts under `art/gen3d_candidates/orc_grunt_d/`; full data in `tools/gen3d/PHASE_D_REPORT.md`.
- **Added:** `tools/gen3d/scripts/phase_d_trellis_batch.py` (single TRELLIS load, 12 runs).

## Not run

Stages 3–5, TripoSG (per user).
