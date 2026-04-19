# ComfyUI workflow for Stage 1 (`turnaround_flux.json`)

## One-time layout (after FLUX download)

The Hugging Face snapshot lives at `~/ComfyUI/models/checkpoints/flux1-dev/`. ComfyUI’s **UNETLoader**, **DualCLIPLoader**, and **VAELoader** expect files under `models/unet`, `models/clip` (also `text_encoders`), and `models/vae`.

From the `gen3d` directory run:

```bash
./setup_comfyui_flux_symlinks.sh
```

Restart ComfyUI if it was already running so file lists refresh.

## Shipped workflows

| File | Purpose |
|------|---------|
| `turnaround_flux.json` | **Default:** FLUX + **three `LoraLoader` nodes** (turnaround → baroque → velvet). Requires the `.safetensors` files under `~/ComfyUI/models/loras/` (see below). |
| `turnaround_flux_no_loras.json` | Same stack **without** LoRAs — use if you have not downloaded CivitAI files yet. Set `export FOULWARD_GEN3D_WORKFLOW=turnaround_flux_no_loras.json` before `foulward_gen.py`, or copy this file over `turnaround_flux.json`. |
| `turnaround_flux_with_loras.json` | **Identical graph to the default** `turnaround_flux.json` (kept as a stable alias / for docs that linked the old name). |

Override the workflow file without renaming:

```bash
export FOULWARD_GEN3D_WORKFLOW=turnaround_flux_no_loras.json
```

## Why this file is required

`pipeline/stage1_image.py` POSTs an **API-format** workflow to ComfyUI at `http://127.0.0.1:8188`. The JSON must contain at least:

- One text node whose `class_type` includes **`CLIPTextEncode`** (e.g. **`CLIPTextEncodeFlux`** for FLUX — prompt is injected into `clip_l` and `t5xxl` on the **first** such node; negative uses the second).
- One **`KSampler`** node (`seed` randomized each run).
- Optionally up to three **`LoraLoader`** nodes in order: turnaround → baroque → velvet (strengths from `LORA_STRENGTHS` in `pipeline/stage1_image.py`).

Checkpoint: **FLUX.1 [dev]** (`black-forest-labs/FLUX.1-dev`), not schnell.

## LoRA files (under `~/ComfyUI/models/loras/`)

Filenames are fixed in `turnaround_flux.json` (three `LoraLoader` nodes). **`STYLE_FOOTER` in `foulward_gen.py`** must include each LoRA’s trigger words (see that file).

| Filename | Role | Source |
|----------|------|--------|
| `turnaround_sheet.safetensors` | Multi-view turnaround layout | **Flux Kontext Character Turnaround Sheet LoRA** — [CivitAI model 1753109](https://civitai.com/models/1753109/flux-kontext-character-turnaround-sheet-lora) · API: `https://civitai.com/api/download/models/1753109` · **Alternative (no CivitAI):** [Hugging Face `reverusar/kontext-turnaround-lora-v1`](https://huggingface.co/reverusar/kontext-turnaround-lora-v1) — download the `.safetensors` and save as `turnaround_sheet.safetensors`. |
| `baroque_fantasy_realism.safetensors` | Dark fantasy art style | **Baroque Fantasy Realism** — [CivitAI model 1604716](https://civitai.com/models/1604716/baroque-fantasy-realism) · API: `https://civitai.com/api/download/models/1604716` → save as `baroque_fantasy_realism.safetensors`. |
| `velvet_mythic_flux.safetensors` | Third style slot (filename unchanged for workflows) | **Caravaggio Baroque Style** (replaces older “Velvet Mythic” for FLUX.1 dev) — [CivitAI model 2256567](https://civitai.com/models/2256567/caravaggio-baroque-style) · API: `https://civitai.com/api/download/models/2256567` → save as `velvet_mythic_flux.safetensors`. |

### Example downloads (CLI)

```bash
mkdir -p ~/ComfyUI/models/loras
cd ~/ComfyUI/models/loras

# LoRA 1 — CivitAI API (or use Hugging Face for the same turnaround LoRA; rename to turnaround_sheet.safetensors)
wget -O turnaround_sheet.safetensors \
  "https://civitai.com/api/download/models/1753109"

wget -O baroque_fantasy_realism.safetensors \
  "https://civitai.com/api/download/models/1604716"

# LoRA 3 — keep filename velvet_mythic_flux.safetensors so ComfyUI JSON stays valid
wget -O velvet_mythic_flux.safetensors \
  "https://civitai.com/api/download/models/2256567"
```

**Hugging Face (LoRA 1 only, optional):** after `pip install 'huggingface_hub[cli]'` in ComfyUI’s venv:

```bash
hf download reverusar/kontext-turnaround-lora-v1 --local-dir /tmp/kontext-lora
mv /tmp/kontext-lora/*.safetensors ~/ComfyUI/models/loras/turnaround_sheet.safetensors
```

If CivitAI returns login/403, use a free account API token: `?token=YOUR_KEY` on the download URL, or download in the browser.

### Local copies from `~/Downloads`

If files were saved with other names, copy into place (example — adjust to your filenames):

```bash
cp ~/Downloads/kontext-turnaround-sheet-v1.safetensors ~/ComfyUI/models/loras/turnaround_sheet.safetensors
cp ~/Downloads/Baroque_Fantasy_Realism.safetensors ~/ComfyUI/models/loras/baroque_fantasy_realism.safetensors
cp ~/Downloads/caravaggio_flux_v2.safetensors ~/ComfyUI/models/loras/velvet_mythic_flux.safetensors
```

## Custom graphs

1. Build the graph in ComfyUI (FLUX + optional LoRAs → sampler → decode → save image).
2. Use **Save (API Format)** so the file is the flat `node_id → { class_type, inputs }` map.
3. Save as `workflows/turnaround_flux.json` next to `foulward_gen.py`.

If node IDs differ, **no code change is needed** — stage 1 discovers nodes by `class_type`, not by fixed IDs.

## Stage 2 (TRELLIS) — Hugging Face token

`TRELLIS.2-4B` pulls several Hugging Face weights:

| Component | Repo | Notes |
|-----------|------|--------|
| Image encoder (DINOv3) | `facebook/dinov3-vitl16-pretrain-lvd1689m` | Gated — accept the license on the model card. |
| Foreground mask (BiRefNet) | `briaai/RMBG-2.0` in Microsoft’s default `pipeline.json` | Also gated. |

1. Create a token at [Hugging Face settings](https://huggingface.co/settings/tokens).
2. Accept licenses on each model card you use: [TRELLIS.2-4B](https://huggingface.co/microsoft/TRELLIS.2-4B), [DINOv3](https://huggingface.co/facebook/dinov3-vitl16-pretrain-lvd1689m), and (if you keep the default rembg) [RMBG-2.0](https://huggingface.co/briaai/RMBG-2.0).
3. Before `foulward_gen.py`, run: `export HF_TOKEN=hf_...` (or `huggingface-cli login` in the `trellis2` conda env).

`tools/gen3d/pipeline/stage2_mesh.py` forwards `HF_TOKEN` / `HUGGING_FACE_HUB_TOKEN` into `conda run`.

**Without `briaai/RMBG-2.0` access:** leave the default `FOULWARD_TRELLIS_PUBLIC_REMBG=1`. The orchestrator prefetches `pipeline.json` and rewrites the rembg checkpoint to public **`ZhengPeng7/BiRefNet`** (same `BiRefNet` class as in TRELLIS). Set `FOULWARD_TRELLIS_PUBLIC_REMBG=0` only if you have accepted RMBG-2.0 and want that checkpoint.

### Stage 2 bypass (no TRELLIS / no gated HF models)

While waiting for access to dependencies such as `facebook/dinov3-vitl16-pretrain-lvd1689m`, you can skip TRELLIS and feed an existing mesh:

```bash
# Use a GLB you already have (e.g. previous export or hand-made asset)
export FOULWARD_GEN3D_STAGE2_MODE=input_file
export FOULWARD_GEN3D_STAGE2_INPUT_GLB=/home/you/.../model.glb
```

Or generate a **rough box** placeholder (needs `pip install trimesh` in the host Python that runs `foulward_gen.py`):

```bash
export FOULWARD_GEN3D_STAGE2_MODE=placeholder
```

Default is `FOULWARD_GEN3D_STAGE2_MODE=trellis` (full quality). Placeholder / input_file are for exercising stages 3–5 only.
