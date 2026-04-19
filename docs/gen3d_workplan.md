# Foul Ward — Gen3D pipeline workplan (machine setup)

**Godot / git repository root:** directory containing `project.godot` (e.g. `FoulWard/` when you clone [FoulWard](https://github.com/JerseyWolf/FoulWard)).  
**Canonical scripts (in-repo):** `tools/gen3d/` — orchestrator `foulward_gen.py` and pipeline stages.  
**This workplan:** `docs/gen3d_workplan.md` (you are here).

This document is the **install-and-verify** checklist. Run shell snippets **from the repository root** unless a path is absolute (`~/`, etc.).

---

## Part 1 — Install tools (Ubuntu, RTX 4090, CUDA 12.4+)

### Step 1 — ComfyUI + FLUX.1 [dev]

```bash
cd ~
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
python3 -m venv .venv
source .venv/bin/activate   # or: . .venv/bin/activate
pip install -r requirements.txt
pip install "huggingface_hub[cli]"
mkdir -p models/checkpoints models/loras
# FLUX.1 [dev] is gated: create a token at https://huggingface.co/settings/tokens,
# accept the license at https://huggingface.co/black-forest-labs/FLUX.1-dev, then:
export HF_TOKEN=hf_...
hf download black-forest-labs/FLUX.1-dev --local-dir models/checkpoints/flux1-dev
```

Wire FLUX paths for ComfyUI loaders (UNET / CLIP / VAE symlinks; **run once** after download):

```bash
cd tools/gen3d && ./setup_comfyui_flux_symlinks.sh
```

Health check (start server, query, stop):

```bash
cd ~/ComfyUI && source .venv/bin/activate
python main.py --listen 127.0.0.1 --port 8188 &
sleep 15 && curl -s http://127.0.0.1:8188/system_stats | head -c 200 && kill %1
```

Use **FLUX.1 [dev]** for best local quality (slower than schnell; fine for background runs).

### Step 1.5 — CivitAI / HF LoRAs

Place three files under `~/ComfyUI/models/loras/` with **exact filenames** (ComfyUI workflow). See `tools/gen3d/workflows/README_COMFYUI.md` for model pages, Hugging Face mirror for the turnaround LoRA, and trigger words in `tools/gen3d/foulward_gen.py` (`STYLE_FOOTER`).

```bash
mkdir -p ~/ComfyUI/models/loras
cd ~/ComfyUI/models/loras

wget -O turnaround_sheet.safetensors \
  "https://civitai.com/api/download/models/1753109"
wget -O baroque_fantasy_realism.safetensors \
  "https://civitai.com/api/download/models/1604716"
# Third slot filename unchanged; content is Caravaggio Baroque Style (not legacy Velvet Mythic)
wget -O velvet_mythic_flux.safetensors \
  "https://civitai.com/api/download/models/2256567"

ls -lh *.safetensors
```

Trigger words are embedded in `STYLE_FOOTER` inside `tools/gen3d/foulward_gen.py`.

### Step 2 — TRELLIS.2 (conda)

```bash
cd ~
git clone -b main https://github.com/microsoft/TRELLIS.2.git --recursive
cd TRELLIS.2
# Official installer (needs CUDA toolkit + nvcc; see README). Alternatively install CUDA into `trellis2` via conda
# and build extensions with PATH including `$CONDA_PREFIX/nvvm/bin` and `CPATH=$CONDA_PREFIX/include`.
. ./setup.sh --new-env --basic --flash-attn --nvdiffrast --nvdiffrec --cumesh --o-voxel --flexgemm
```

`tools/gen3d/pipeline/stage2_mesh.py` runs `conda run -n trellis2` with `PYTHONPATH` pointing at `~/TRELLIS.2`, `CUDA_HOME` at `$CONDA_PREFIX/targets/x86_64-linux`, and `PATH` including `$CONDA_PREFIX/nvvm/bin` (for `cicc`). Override clone path with `FOULWARD_TRELLIS_REPO` and env prefix with `FOULWARD_TRELLIS2_PREFIX` if non-default.

Smoke test:

```bash
export HF_TOKEN=hf_...   # required: gated HF deps (TRELLIS + DINOv3); accept licenses on model pages first
conda run -n trellis2 python -c "from trellis2.pipelines import Trellis2ImageTo3DPipeline; print('TRELLIS2 OK')"
```

(If that fails, set the same env vars as in `stage2_mesh._conda_run_env()` or use `python -c` after `conda activate trellis2` with `export PYTHONPATH=~/TRELLIS.2`.)

### Step 3 — Blender (headless)

```bash
sudo snap install blender --classic
blender --version
```

### Step 4 — Selenium + Chrome (Mixamo automation)

```bash
pip install --user selenium webdriver-manager
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update && sudo apt install -y google-chrome-stable
google-chrome --version
```

### Step 5 — Mixamo bot (optional)

```bash
pip install --user "git+https://github.com/ccalafiore/Mixamo-Bot-that-Automatically-Downloads-Mixamo-Data.git"
```

API varies by package version; `stage3_rig.py` falls back to **unrigged GLB** if import or upload fails.

### Step 6 — Host Python utilities

```bash
pip install --user Pillow requests huggingface_hub trimesh numpy open3d
# Optional: also inside trellis2 env
conda run -n trellis2 pip install Pillow trimesh numpy
```

### Step 7 — Pipeline layout (this repo)

Already created:

- `tools/gen3d/foulward_gen.py`
- `tools/gen3d/pipeline/stage*.py`
- `tools/gen3d/workflows/` — export ComfyUI JSON here (see `README_COMFYUI.md`)
- `tools/gen3d/anim_library/` — Mixamo FBX clips

Install orchestrator deps:

```bash
cd tools/gen3d
pip install --user -r requirements.txt
```

### Step 8 — ComfyUI workflow file

Replace `tools/gen3d/workflows/turnaround_flux.json` (starts as `{}`) with an **API export** from ComfyUI after wiring FLUX dev + three LoRAs. See `tools/gen3d/workflows/README_COMFYUI.md`.

---

## Part 2 — Secrets (never commit)

Recommended: a single file **`~/.foulward_secrets`** (override path with **`FOULWARD_SECRETS_FILE`**) with `export` lines — same as `FoulWard/launch.sh` and **`tools/gen3d/foulward_gen.py`** (via `pipeline/secrets_loader.py`). Example:

```bash
export MIXAMO_EMAIL="your@email.com"
export MIXAMO_PASSWORD="use_a_password_manager"
export HF_TOKEN="hf_..."   # Hugging Face: TRELLIS + gated DINOv3 deps; accept model licenses on HF first
```

Shell scripts under `FoulWard/tools/` that need **`HF_TOKEN`** also source this file when present.

Do **not** paste tokens into repo files, skills, or chat logs.

---

## Part 3 — Run

From the **repository root** (the folder that contains `project.godot` and `tools/gen3d/`):

```bash
# Terminal A — ComfyUI
cd ~/ComfyUI && source .venv/bin/activate
python main.py --listen 127.0.0.1 --port 8188

# Terminal B — pipeline
cd tools/gen3d
export MIXAMO_EMAIL=...
export MIXAMO_PASSWORD=...
python foulward_gen.py "test cube" buildings building
```

**Output:** flat GLB paths under Foul Ward, e.g.  
`/home/jerzy-wolf/workspace/foul-ward/FoulWard/art/generated/buildings/test_cube.glb`

Match `entity_id` + folder to `rigged_visual_wiring.gd` / `FUTURE_3D_MODELS_PLAN.md`.

---

## Part 4 — File reference (canonical copies)

| Path | Role |
|------|------|
| `tools/gen3d/foulward_gen.py` | CLI orchestrator |
| `tools/gen3d/pipeline/stage1_image.py` | ComfyUI client |
| `tools/gen3d/pipeline/stage2_mesh.py` | TRELLIS.2 |
| `tools/gen3d/pipeline/stage3_rig.py` | Blender + Mixamo |
| `tools/gen3d/pipeline/stage4_anim.py` | Blender merge |
| `tools/gen3d/pipeline/stage5_drop.py` | Copy to `art/generated/` |
| `tools/gen3d/workflows/turnaround_flux.json` | ComfyUI API JSON (replace `{}`) |

---

## Part 5 — Costs

All listed tools are **free** for local use; Mixamo requires a **free Adobe account** only. FLUX Pro / closed weights are **not** used here.

---

## Part 6 — Agent skill in repo

Agents load: `FoulWard/.cursor/skills/gen3d/SKILL.md` (points to this workplan and `tools/gen3d/`).
