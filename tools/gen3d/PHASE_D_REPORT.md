# Gen3D Phase D — 2-panel pipeline correction + orc grunt clean test

**Date:** 2026-04-21  
**Artifacts:** `art/gen3d_candidates/orc_grunt_d/` (raw / decimated_25k / decimated_12k / source)  
**Batch script:** `tools/gen3d/scripts/phase_d_trellis_batch.py` (loads TRELLIS once, 12 runs)

---

## 1. Phase C cleanup (D1a)

**Processes:** `ps aux | grep -E "blender|foulward|trellis|comfyui"` showed **no** matching processes (nothing to kill).

**GPU:** `nvidia-smi` reported ~3458 MiB used (near idle).

**Tmp files present:**

| Path | Notes |
|------|--------|
| `/tmp/fw_c_decimate_test.py` | Leftover script |
| `/tmp/fw_c_trellis_master.py`, `/tmp/fw_c_trellis_worker.py` | Leftover scripts |
| `/tmp/fw_c_decimate_test/` | Directory with `decimation_ladder.csv` and several decimated `trellis_512_seed42_*` GLBs |

**Action:** No Phase C jobs were running; tmp files were **not** used for Phase D output. Phase B candidates in `art/gen3d_candidates/orc_grunt_b_test/` were not modified.

---

## 2. Code changes (D1b–D1c)

### 2.1 `tools/gen3d/foulward_gen.py`

**`TRELLIS_CROP_TO_FRONT`**

- **Before:** `TRELLIS_CROP_TO_FRONT: bool = False` with comments suggesting full 2-panel sheet to TRELLIS.
- **After:** `TRELLIS_CROP_TO_FRONT: bool = True` with comments stating the left **half** must be cropped before rembg; never feed the full 2-panel sheet to TRELLIS.

Related header comments for `TRELLIS_INPUT_FORMAT` were updated to describe the 2-panel front+back sheet + crop workflow (removed obsolete “left third of 3-view” winner notes).

**`run_pipeline` log branch**

- **Before:** `TRELLIS_CROP_TO_FRONT=0` in the print for full-sheet rembg.
- **After:** `TRELLIS_CROP_TO_FRONT=False` (same behavior, clearer).

**`STYLE_FOOTER`**

- **Confirmed unchanged** from Phase B: two-panel instructions (“Exactly TWO views side by side… LEFT HALF… FRONT… RIGHT HALF… BACK…”).

### 2.2 `tools/gen3d/pipeline/stage1_image.py` — `crop_front_view()`

- **Before:** `front = img.crop((0, 0, w // 3, h))` (left third, 3-panel turnaround).
- **After:** `front = img.crop((0, 0, w // 2, h))` (left half, 2-panel front+back).

Docstring updated accordingly.

### 2.3 Crop sanity check (`/tmp/fw_orc_ref.png`)

- Source: **2048×2048**
- After new crop (`/tmp/fw_d_crop_check.png`): **1024×2048** (single-panel aspect as expected).

---

## 3. Blender decimation (D1d)

```text
/usr/bin/blender --background --python tools/gen3d/pipeline/blender_decimate.py \
  -- art/gen3d_candidates/orc_grunt_b_test/raw/trellis_512_seed42_raw.glb \
  /tmp/fw_d_blender_smoke.glb 25000
```

- **Stdout contained:** `BLENDER_DECIMATE_OK`
- **Output:** `/tmp/fw_d_blender_smoke.glb` non-zero (~2.5 MB)

---

## 4. Source image quality (D2)

**Unit string:**  
`stocky green-skinned orc soldier, crude dented iron helmet, patchwork leather pauldrons, large fists, hunched aggressive stance, crude iron cleaver weapon`

**ComfyUI:** Started with `nohup …/trellis2/bin/python ~/ComfyUI/main.py --listen 0.0.0.0 --port 8188`; `generate_reference_sheet()` ×2 with `random.seed(70001)` / `random.seed(80002)` before each call.

| Sheet | Path | Dimensions | Notes |
|-------|------|------------|--------|
| A | `/tmp/fw_d/orc_sheet_A.png` | 2048×2048 | Two-panel layout (front \| back) |
| B | `/tmp/fw_d/orc_sheet_B.png` | 2048×2048 | Two-panel layout |

**Pipeline per sheet:** `crop_front_view` → `remove_background` → `clean_alpha_for_trellis`

| Output | Dimensions | Alpha > 128 (fraction) |
|--------|------------|-------------------------|
| `orc_A_clean.png` | 1024×2048 | ~0.41 |
| `orc_B_clean.png` | 1024×2048 | ~0.39 |

**Qualitative:** No double-character full-sheet input to TRELLIS; left-half crops are full-height single-view panels suitable for rembg + TRELLIS. (Automated vision QA not run; inspect `source/*.png` in `orc_grunt_d` if needed.)

**ComfyUI shutdown (D2d):** Killed listener on 8188; VRAM dropped below 12 GB immediately (~3.6 GB).

---

## 5. TRELLIS inputs (D3)

Prepared (white composite, pad square, LANCZOS resize):

- `/tmp/fw_d/inputs/A_512.png`, `A_768.png`, `B_512.png`, `B_768.png` — sizes **512²** / **768²** as named.

---

## 6. TRELLIS parameters (all runs)

```text
FOULWARD_TRELLIS_SAMPLER_STEPS=8
FOULWARD_TRELLIS_SPARSE_GUIDANCE=5.0
FOULWARD_TRELLIS_SLAT_GUIDANCE=2.0
FOULWARD_TRELLIS_PREDECIMATE=100000
```

Raw outputs: `/tmp/fw_d/raw/{A|B}_{512|768}_seed{42|256|512}.glb`

---

## 7. TRELLIS results table (12 runs)

Sorted **within each resolution group** by **file size (KB) descending**.

### 768 × 768 input

| source | resolution | seed | face_count | file_size_kb | status |
|--------|------------|------|------------|--------------|--------|
| A | 768 | 512 | 96396 | 5341.2 | ok |
| A | 768 | 256 | 97080 | 5001.7 | ok |
| B | 768 | 42 | 94162 | 4867.5 | ok |
| A | 768 | 42 | 95544 | 4804.5 | ok |
| B | 768 | 512 | 94319 | 4537.2 | ok |
| B | 768 | 256 | 94064 | 4530.6 | ok |

### 512 × 512 input

| source | resolution | seed | face_count | file_size_kb | status |
|--------|------------|------|------------|--------------|--------|
| A | 512 | 512 | 99365 | 5409.5 | ok |
| B | 512 | 256 | 99294 | 4953.7 | ok |
| B | 512 | 42 | 95906 | 4906.5 | ok |
| A | 512 | 42 | 94197 | 4857.5 | ok |
| A | 512 | 256 | 96703 | 4819.4 | ok |
| B | 512 | 512 | 98325 | 4766.6 | ok |

**OOM:** None (single VRAM handoff: ComfyUI off before TRELLIS).

---

## 8. Decimation results (24 meshes)

Blender `blender_decimate.py` on each raw GLB → targets **25 000** and **12 000** faces.

**Non-manifold edge count:** Open3D `TriangleMesh.get_non_manifold_edges(allow_boundary_edges=False)` on geometry from `_load_combined_mesh` (same approach as `scripts/ab_test_batch.py`).

| File | faces | non_manifold_edges | size_kb |
|------|-------|-------------------|---------|
| A_512_seed256_25k.glb | 25000 | 28798 | 2049 |
| A_512_seed256_12k.glb | 12000 | 15150 | 1534 |
| A_512_seed42_25k.glb | 25000 | 29018 | 2130 |
| A_512_seed42_12k.glb | 12000 | 15224 | 1613 |
| A_512_seed512_25k.glb | 25000 | 30732 | 2232 |
| A_512_seed512_12k.glb | 12000 | 16514 | 1707 |
| A_768_seed256_25k.glb | 25000 | 29000 | 2140 |
| A_768_seed256_12k.glb | 12000 | 15286 | 1625 |
| A_768_seed42_25k.glb | 24999 | 28715 | 2018 |
| A_768_seed42_12k.glb | 11999 | 15115 | 1507 |
| A_768_seed512_25k.glb | 24998 | 30696 | 2147 |
| A_768_seed512_12k.glb | 11998 | 15872 | 1601 |
| B_512_seed256_25k.glb | 25000 | 28934 | 2103 |
| B_512_seed256_12k.glb | 12000 | 15100 | 1581 |
| B_512_seed42_25k.glb | 25000 | 29522 | 2139 |
| B_512_seed42_12k.glb | 12000 | 15552 | 1616 |
| B_512_seed512_25k.glb | 25000 | 28712 | 2006 |
| B_512_seed512_12k.glb | 12000 | 15230 | 1492 |
| B_768_seed256_25k.glb | 25000 | **27378** | 2087 |
| B_768_seed256_12k.glb | 12000 | **14420** | 1586 |
| B_768_seed42_25k.glb | 24999 | 29869 | 2124 |
| B_768_seed42_12k.glb | 12000 | 15870 | 1603 |
| B_768_seed512_25k.glb | 24999 | 27439 | 2107 |
| B_768_seed512_12k.glb | 12000 | 14332 | 1601 |

---

## 9. Recommendation (top 3 to open in Blender first)

Use **decimated_25k** first (game-like density); fall back to **raw** for texture/detail checks.

1. **`B_768_seed256`** — **Lowest** non-manifold edge proxy at 25k (**27378**) among this batch; sheet B + 768 input. Files: `raw/B_768_seed256_raw.glb`, `decimated_25k/B_768_seed256_25k.glb`.
2. **`B_768_seed512`** — Second-best NM proxy at 25k (**27439**); same sheet B, different seed. Files: `raw/B_768_seed512_raw.glb`, `decimated_25k/B_768_seed512_25k.glb`.
3. **`B_512_seed512`** — Best **512** input run on NM proxy at 25k (**28712**). Files: `raw/B_512_seed512_raw.glb`, `decimated_25k/B_512_seed512_25k.glb`.

**512 vs 768 (this run, no double-character bias):** **768**-edge inputs from **sheet B** produced the **lowest** non-manifold counts at 25k faces. **512** runs were competitive but did not beat B_768 on this NM proxy. Raw face counts stayed in a similar band (~94–99k) across resolutions.

---

## 10. Remaining blockers (unchanged)

- **TripoSG** — diso ABI / integration not attempted (per constraints).
- **Mixamo** — automation still depends on env credentials and manual steps documented elsewhere.
- **Animation library** — Stages 4–5 not run this phase.

**New issues noted:** `rembg`/ONNX logged missing CUDA provider (`libcublasLt.so.12`) and fell back to CPU for Stage 1 — acceptable for this test but slower if repeated at scale.

---

## 11. Copy layout (`art/gen3d_candidates/orc_grunt_d/`)

```text
raw/               — 12 files: e.g. A_512_seed42_raw.glb
decimated_25k/     — 12 files: e.g. A_512_seed42_25k.glb
decimated_12k/     — 12 files: e.g. A_512_seed42_12k.glb
source/
  orc_A_sheet.png, orc_B_sheet.png
  orc_A_front.png, orc_B_front.png
  orc_A_clean.png, orc_B_clean.png
```

---

## 12. Constraints checklist

| Constraint | Status |
|------------|--------|
| No Stages 3–5 | OK |
| No TripoSG | OK |
| Phase C processes killed if running | Nothing was running |
| VRAM: ComfyUI down before TRELLIS | OK |
| Do not overwrite `orc_grunt_b_test/` | OK |
| Report in repo (`tools/gen3d/PHASE_D_REPORT.md`) | OK |
