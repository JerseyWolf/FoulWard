# SPDX-License-Identifier: MIT
"""Stage 1: ComfyUI HTTP API — FLUX.1 dev reference sheet with optional LoRA strengths."""

from __future__ import annotations

import json
import os
import random
import shutil
import time
from pathlib import Path
from typing import Any

import numpy as np
import requests
from PIL import Image, ImageFilter

# Per-faction ceilings (validated); build_workflow_with_loras caps workflow JSON to these maxima.
LORA_STRENGTHS: dict[str, dict[str, float]] = {
    "orc_raiders": {"turnaround": 0.4, "baroque": 0.5, "velvet": 0.4},
    "plague_cult": {"turnaround": 0.4, "baroque": 0.5, "velvet": 0.3},
    "allies": {"turnaround": 0.4, "baroque": 0.3, "velvet": 0.4},
    "buildings": {"turnaround": 0.3, "baroque": 0.4, "velvet": 0.2},
}


def _workflow_nodes(workflow: dict[str, Any]) -> dict[str, Any]:
    """Normalize: ComfyUI API JSON is a flat map of node_id -> {class_type, inputs}."""
    return workflow


def _iter_clip_text_encode_nodes(workflow: dict[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    out: list[tuple[str, dict[str, Any]]] = []
    for node_id, node in _workflow_nodes(workflow).items():
        if not isinstance(node, dict):
            continue
        ct: str = str(node.get("class_type", ""))
        if "CLIPTextEncode" in ct or ct == "CLIPTextEncode":
            out.append((node_id, node))
    return out


def _iter_lora_loader_nodes(workflow: dict[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    out: list[tuple[str, dict[str, Any]]] = []
    for node_id, node in _workflow_nodes(workflow).items():
        if not isinstance(node, dict):
            continue
        ct: str = str(node.get("class_type", ""))
        if "LoraLoader" in ct or ct == "LoraLoader":
            out.append((node_id, node))
    # Stable order: numeric sort when possible
    def sort_key(t: tuple[str, dict[str, Any]]) -> tuple[int, str]:
        try:
            return (int(t[0]), t[0])
        except ValueError:
            return (999999, t[0])

    out.sort(key=sort_key)
    return out


def build_workflow_with_loras(
    workflow: dict[str, Any],
    prompt: str,
    faction: str,
) -> dict[str, Any]:
    """Inject prompt text, random seed, and per-faction LoRA strengths."""
    strengths: dict[str, float] = LORA_STRENGTHS.get(faction, LORA_STRENGTHS["orc_raiders"])
    keys: tuple[str, str, str] = ("turnaround", "baroque", "velvet")

    clip_nodes: list[tuple[str, dict[str, Any]]] = _iter_clip_text_encode_nodes(workflow)
    if not clip_nodes:
        raise RuntimeError(
            "ComfyUI workflow has no CLIPTextEncode node. Export API JSON from ComfyUI "
            "and save as workflows/turnaround_flux.json (see workflows/README_COMFYUI.md)."
        )
    # Positive prompt: FLUX turnaround workflow uses node "7" (CLIPTextEncodeFlux).
    n7: Any = workflow.get("7")
    if isinstance(n7, dict) and str(n7.get("class_type", "")) == "CLIPTextEncodeFlux":
        ins7: dict[str, Any] = n7.setdefault("inputs", {})
        ins7["clip_l"] = prompt
        ins7["t5xxl"] = prompt
    else:
        # First positive prompt node (JSON key order: first CLIP encode = positive)
        _nid, first_clip = clip_nodes[0]
        inputs: dict[str, Any] = first_clip.setdefault("inputs", {})
        ct_first: str = str(first_clip.get("class_type", ""))
        if ct_first == "CLIPTextEncodeFlux" or ct_first.endswith("CLIPTextEncodeFlux"):
            inputs["clip_l"] = prompt
            inputs["t5xxl"] = prompt
        else:
            inputs["text"] = prompt

    # Randomize seeds across any node that exposes one (KSampler `seed`,
    # FLUX `RandomNoise` `noise_seed`, etc.).
    new_seed: int = random.randint(0, 2**32 - 1)
    for node in _workflow_nodes(workflow).values():
        if not isinstance(node, dict):
            continue
        nin: dict[str, Any] | None = node.get("inputs")
        if not isinstance(nin, dict):
            continue
        if "seed" in nin and isinstance(nin["seed"], (int, float)):
            nin["seed"] = new_seed
        if "noise_seed" in nin and isinstance(nin["noise_seed"], (int, float)):
            nin["noise_seed"] = new_seed

    loras: list[tuple[str, dict[str, Any]]] = _iter_lora_loader_nodes(workflow)
    # When workflow JSON pins all three LoRAs to 0.0 (NaN / black-PNG isolation), do not
    # apply per-faction strengths — would undo the workaround in turnaround_flux.json.
    all_lora_zero: bool = True
    for _lid, lnode in loras[:3]:
        lin0: dict[str, Any] = lnode.get("inputs", {})
        if not isinstance(lin0, dict):
            all_lora_zero = False
            break
        sm0: float = float(lin0.get("strength_model", -1.0))
        sc0: float = float(lin0.get("strength_clip", -1.0))
        if sm0 != 0.0 or sc0 != 0.0:
            all_lora_zero = False
            break
    if not all_lora_zero:
        for i, (_lid, lnode) in enumerate(loras[:3]):
            if i >= len(keys):
                break
            lin: dict[str, Any] = lnode.setdefault("inputs", {})
            s = strengths[keys[i]]
            if "strength_model" not in lin and "strength_clip" not in lin:
                continue
            cur_m: float = float(lin.get("strength_model", 0.0))
            cur_c: float = float(lin.get("strength_clip", 0.0))
            if cur_m == 0.0 and cur_c == 0.0:
                continue
            # Cap at faction maximum (validated); never exceed LORA_STRENGTHS for this slot.
            lin["strength_model"] = min(cur_m, s)
            lin["strength_clip"] = min(cur_c, s)

    return workflow


def _first_output_image_path(history_entry: dict[str, Any]) -> tuple[str, str] | None:
    """Return (node_id, filename) for ComfyUI history outputs.

    Prefer node 101 (upscaled 2048x2048 ``foulward_turnaround_hires_*``) when present.
    """
    outputs: dict[str, Any] = history_entry.get("outputs", {})
    preferred_id: str = "101"
    if preferred_id in outputs:
        out101: Any = outputs[preferred_id]
        if isinstance(out101, dict):
            images101: list[Any] | None = out101.get("images")
            if images101 and isinstance(images101, list) and len(images101) > 0:
                img0: Any = images101[0]
                if isinstance(img0, dict) and "filename" in img0:
                    return (preferred_id, str(img0["filename"]))
    for node_id, out in outputs.items():
        if not isinstance(out, dict):
            continue
        images: list[Any] | None = out.get("images")
        if images and isinstance(images, list) and len(images) > 0:
            img1: Any = images[0]
            if isinstance(img1, dict) and "filename" in img1:
                return (str(node_id), str(img1["filename"]))
    return None


def generate_reference_sheet(
    unit_name: str,
    faction_block: str,
    style_footer: str,
    out_path: str,
    port: int = 8188,
    faction: str = "orc_raiders",
    comfyui_output_dir: Path | None = None,
) -> str:
    """POST workflow to ComfyUI, poll history, copy PNG to out_path."""
    gen3d_root: Path = Path(__file__).resolve().parent.parent
    workflow_name: str = os.environ.get("FOULWARD_GEN3D_WORKFLOW", "turnaround_flux.json")
    workflow_path: Path = gen3d_root / "workflows" / workflow_name
    if not workflow_path.is_file():
        raise FileNotFoundError(
            f"Missing {workflow_path}. Build a FLUX + LoRA graph in ComfyUI, "
            "then Save (API Format) and replace this file. See workflows/README_COMFYUI.md."
        )

    with workflow_path.open("r", encoding="utf-8") as f:
        workflow: dict[str, Any] = json.load(f)

    full_prompt: str = (
        f"{unit_name}.\n{faction_block}\n{style_footer}"
    )
    workflow = build_workflow_with_loras(workflow, full_prompt, faction)

    base: str = f"http://127.0.0.1:{port}"
    try:
        r: requests.Response = requests.post(
            f"{base}/prompt",
            json={"prompt": workflow},
            timeout=60,
        )
    except requests.exceptions.ConnectionError as exc:
        raise RuntimeError(
            f"Cannot reach ComfyUI at {base} (connection refused or unreachable). "
            "Start ComfyUI on that port before running foulward_gen.py, or set SKIP_STAGE1=1 "
            "if reference PNGs already exist under local/gen3d/staging/."
        ) from exc
    r.raise_for_status()
    data: dict[str, Any] = r.json()
    prompt_id: str | None = data.get("prompt_id")
    if not prompt_id:
        raise RuntimeError(f"ComfyUI /prompt unexpected response: {data}")

    out_file: Path = Path(out_path)
    out_file.parent.mkdir(parents=True, exist_ok=True)

    if comfyui_output_dir is None:
        comfyui_output_dir = Path.home() / "ComfyUI" / "output"

    deadline: float = time.time() + 3600.0
    while time.time() < deadline:
        hr: requests.Response = requests.get(f"{base}/history/{prompt_id}", timeout=30)
        hr.raise_for_status()
        hist: dict[str, Any] = hr.json()
        if prompt_id not in hist:
            time.sleep(2.0)
            continue
        entry: dict[str, Any] = hist[prompt_id]
        found: tuple[str, str] | None = _first_output_image_path(entry)
        if not found:
            time.sleep(2.0)
            continue
        _node_id, filename = found
        src: Path = comfyui_output_dir / filename
        if not src.is_file():
            # Subfolder in output
            for p in comfyui_output_dir.rglob(filename):
                if p.is_file():
                    src = p
                    break
        if not src.is_file():
            raise FileNotFoundError(f"ComfyUI reported output {filename} but file not found under {comfyui_output_dir}")
        shutil.copy2(src, out_file)
        img = Image.open(out_file).convert("RGB")
        arr: np.ndarray = np.array(img)
        black_ratio: float = float((arr < 10).all(axis=2).mean())
        if black_ratio > 0.95:
            raise RuntimeError(
                f"Stage 1 produced a {black_ratio * 100:.0f}% black image. "
                f"Likely NaN from VAEDecode. Check ComfyUI log for 'invalid value encountered in cast'. "
                f"Current workaround: LoRAs are disabled — check workflow node 4/5/6 strengths."
            )
        return str(out_file.resolve())

    raise TimeoutError("ComfyUI did not finish within 1 hour.")


def crop_front_view(sheet_path: str, out_path: str) -> str:
    """
    Crop the front-view panel from a 2-panel front+back reference sheet.
    Takes the LEFT HALF of the image — front view is always on the left.

    Note: Previously took left third (w // 3) for the old 3-panel turnaround sheet.
    Updated for the current 2-panel STYLE_FOOTER (front left, back right).

    Args:
        sheet_path: Path to the full 2-panel sheet PNG.
        out_path:   Where to save the cropped front-view PNG.

    Returns:
        out_path after saving.
    """
    img = Image.open(sheet_path)
    w, h = img.size
    front = img.crop((0, 0, w // 2, h))
    front.save(out_path)
    return out_path


def clean_alpha_for_trellis(image_path: str, out_path: str, threshold: int = 128) -> str:
    """
    Binarise the alpha channel of an RGBA image so every pixel is either
    fully opaque (alpha=255) or fully transparent (alpha=0).
    Semi-transparent fringe pixels from rembg cause TRELLIS to hallucinate
    thin geometry sheets which explode into razor shards after decimation.

    Args:
        image_path: Path to RGBA PNG (rembg output).
        out_path:   Where to save the cleaned RGBA PNG.
        threshold:  Pixels with alpha >= threshold → 255, else → 0. Default 128.

    Returns:
        out_path after saving.
    """
    img: Image.Image = Image.open(image_path).convert("RGBA")
    arr: np.ndarray = np.array(img, dtype=np.uint8)

    # Hard alpha threshold
    arr[:, :, 3] = np.where(arr[:, :, 3] >= threshold, 255, 0)

    # Erode the mask by 1px (3x3 min filter) to reduce fringe artifacts at silhouette edges
    mask: Image.Image = Image.fromarray(arr[:, :, 3], mode="L")
    mask_eroded: Image.Image = mask.filter(ImageFilter.MinFilter(size=3))
    arr[:, :, 3] = np.array(mask_eroded, dtype=np.uint8)

    Image.fromarray(arr).save(out_path)
    return out_path
