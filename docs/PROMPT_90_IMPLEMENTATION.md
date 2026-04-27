# PROMPT 90 — Gen3D Phase B (STYLE_FOOTER, Blender decimate, orc grunt TRELLIS test)

**Date:** 2026-04-21

## Summary

- **B2:** Replaced `STYLE_FOOTER` with two-panel front+back instructions; simplified `generate_reference_sheet()` prompt to `{unit}.{faction}.{style_footer}`; extended negative prompt in `turnaround_flux.json` node 8; set `TRELLIS_CROP_TO_FRONT = False`; wired `run_pipeline()` to skip `crop_front_view` when crop is disabled.
- **B3:** Confirmed `TRELLIS_INPUT_SIZE` is `int` from `FOULWARD_TRELLIS_INPUT_EDGE` in `stage2_mesh.py` — no fix.
- **B4:** Added `pipeline/blender_decimate.py` and `_decimate_blender()` in `stage2_mesh.py`; `decimate_glb()` tries Blender first, Open3D unchanged as fallback. Smoke test on `selected.glb` OK.
- **B6–B8:** ComfyUI reference for `orc_grunt` (unit bank description), rembg + alpha clean → `/tmp/fw_orc_test_clean.png`; TRELLIS at 512 and 768 × seeds 42, 256, 512; all succeeded; decimation all Blender; metrics in `/tmp/fw_orc_test/results.csv`; copies under `art/gen3d_candidates/orc_grunt_b_test/`; report `/tmp/fw_orc_test/PHASE_B_REPORT.md`.

## Not done (per scope)

- Stages 3–5, TripoSG, animation library population.
