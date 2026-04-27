# PROMPT 82 — TRELLIS.2 / DINOv3 `transformers` pin (gen3d Stage 2)

**Date:** 2026-04-19

## What was missing

- `.cursor/skills/gen3d/SKILL.md` had no pinned `transformers` note for Stage 2.
- `trellis2` env had **transformers 5.5.4** (incompatible with TRELLIS.2 DINOv3 `.layer` access).

## What we did

1. **Pinned `transformers==4.56.0`** (full `pip install`, not `--no-deps`) per [microsoft/TRELLIS.2#147](https://github.com/microsoft/TRELLIS.2/issues/147).
2. **Rejected `4.46.3` as sole fix:** that release does not expose `DINOv3ViTModel` (`ImportError`).
3. **Verified** `Trellis2ImageTo3DPipeline.from_pretrained(...).image_cond_model.model` has **`len(model.layer)==24`** on GPU load.
4. **Smoke `pipeline.run` on 64×64 dummy** hit `ValueError` (empty bbox in preprocess) — unrelated to DINOv3; use a normal-sized RGB image for end-to-end smoke tests.
5. **Updated** `SKILL.md` with pins and troubleshooting row.
6. **Did not run** full `foulward_gen.py` — ComfyUI was not listening on **8188** (per user: do not start it unless asked).

## Current versions (trellis2)

- `transformers`: 4.56.0  
- `torch`: 2.6.0+cu124  
- `torchaudio`: 2.6.0+cu124  
- `timm`: 1.0.26  
