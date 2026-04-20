# PROMPT 87 — TRELLIS.2 input format A/B (2026-04-20)

## Source image

- `~/ComfyUI/output/foulward_turnaround_hires_00006_.png` (largest `foulward_turnaround_hires_*.png` by file size).
- Size **2048×2048** RGB (Comfy node 101 hires upscale), three horizontal panels (front / side / back).

## Variants (`/tmp/fw_trellis_input_test/`)

| ID | Description |
|----|-------------|
| v1 | Full sheet, hard-alpha |
| v2 | Full sheet, white RGB |
| v3 | Left third (front), hard-alpha → 768×768 |
| v4 | Front third, white → 512×512 |
| v5 | Full sheet white → 512×512 |

## TRELLIS.2 runs

- Harness: `tools/gen3d/scripts/trellis2_input_ab_variant.py` (pad square, resize to `prep_edge`, RGB, seed **42**).
- v1–v3: default `to_glb` (`texture_size=2048`, `predecimate=100000`).
- v4 first failed CuMesh OOM; succeeded with `FOULWARD_AB_TEXTURE_SIZE=512`, `FOULWARD_TRELLIS_PREDECIMATE=50000` (same for v5, v3b).

## Results (decimated @ 10k faces, non-manifold edge proxy)

| Variant | prep_edge | to_glb texture / predec | dec NM | Raw faces |
|---------|-----------|---------------------------|--------|-----------|
| v1 | 770 | 2048 / 100k | 9791 | 99457 |
| v2 | 770 | 2048 / 100k | 9840 | 98003 |
| v3 | 768 | 2048 / 100k | 9805 | 99426 |
| v3b | 768 | 512 / 50k | **9310** | 49634 |
| v4 | 512 | 512 / 50k | 9472 | 48587 |
| v5 | 512 | 512 / 50k | 9874 | 49669 |

**Winner (geometry proxy, matched lighter `to_glb`):** **v3b** — front panel only, 768 prep edge, hard-alpha lineage (same asset as v3).

## Pipeline changes

- `tools/gen3d/pipeline/stage2_mesh.py`: `TRELLIS_INPUT_SIZE` default **768** via `FOULWARD_TRELLIS_INPUT_EDGE`.
- `tools/gen3d/foulward_gen.py`: documented `TRELLIS_INPUT_SIZE`, `TRELLIS_INPUT_MODE`, `TRELLIS_CROP_TO_FRONT`.
- No change to `crop_front_view` (still left **third** for three-panel sheets).

## Remaining

- Re-run v1/v2 with the same reduced `to_glb` settings if strict apples-to-apples vs v3b is needed (texture / predecimate dominated NM spread).
- Visual pick in Blender still recommended; NM is only a proxy.
