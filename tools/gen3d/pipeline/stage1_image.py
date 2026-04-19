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

import requests

LORA_STRENGTHS: dict[str, dict[str, float]] = {
    "orc_raiders": {"turnaround": 0.8, "baroque": 0.7, "velvet": 0.6},
    "plague_cult": {"turnaround": 0.8, "baroque": 0.8, "velvet": 0.5},
    "allies": {"turnaround": 0.8, "baroque": 0.5, "velvet": 0.7},
    "buildings": {"turnaround": 0.5, "baroque": 0.6, "velvet": 0.4},
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
    # First positive prompt node (JSON key order: first CLIP encode = positive)
    _nid, first_clip = clip_nodes[0]
    inputs: dict[str, Any] = first_clip.setdefault("inputs", {})
    ct_first: str = str(first_clip.get("class_type", ""))
    if ct_first == "CLIPTextEncodeFlux" or ct_first.endswith("CLIPTextEncodeFlux"):
        # FLUX: long prompt in T5; duplicate into CLIP-L for pipeline simplicity
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
    for i, (_lid, lnode) in enumerate(loras[:3]):
        if i >= len(keys):
            break
        lin: dict[str, Any] = lnode.setdefault("inputs", {})
        s: float = strengths[keys[i]]
        if "strength_model" in lin or "strength_clip" in lin:
            lin["strength_model"] = s
            lin["strength_clip"] = s

    return workflow


def _first_output_image_path(history_entry: dict[str, Any]) -> tuple[str, str] | None:
    """Return (node_id, filename) for first image in history outputs."""
    outputs: dict[str, Any] = history_entry.get("outputs", {})
    for node_id, out in outputs.items():
        if not isinstance(out, dict):
            continue
        images: list[Any] | None = out.get("images")
        if images and isinstance(images, list) and len(images) > 0:
            img0: Any = images[0]
            if isinstance(img0, dict) and "filename" in img0:
                return (str(node_id), str(img0["filename"]))
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
        f"Character design turnaround sheet, front view, right side view, back view, "
        f"isolated on white background.\n{unit_name}.\n{faction_block}\n{style_footer}"
    )
    workflow = build_workflow_with_loras(workflow, full_prompt, faction)

    base: str = f"http://127.0.0.1:{port}"
    r: requests.Response = requests.post(
        f"{base}/prompt",
        json={"prompt": workflow},
        timeout=60,
    )
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
        return str(out_file.resolve())

    raise TimeoutError("ComfyUI did not finish within 1 hour.")
