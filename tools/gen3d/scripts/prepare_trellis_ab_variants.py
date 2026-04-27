#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Prepare 5 TRELLIS input-format variants from a cleaned RGBA source (A/B harness).

Writes PNGs next to ``--out-prefix`` (e.g. ``local/gen3d/ab_test/<slug>/inputs/variant`` → ``variant_1.png`` … ``variant_5.png``).
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


def hard_alpha_rgba(img: Image.Image, threshold: int = 128) -> Image.Image:
    arr: np.ndarray = np.array(img.convert("RGBA"), dtype=np.uint8)
    arr[:, :, 3] = np.where(arr[:, :, 3] >= threshold, 255, 0)
    mask: Image.Image = Image.fromarray(arr[:, :, 3], mode="L")
    mask_eroded: Image.Image = mask.filter(ImageFilter.MinFilter(size=3))
    arr[:, :, 3] = np.array(mask_eroded, dtype=np.uint8)
    return Image.fromarray(arr, mode="RGBA")


def rgba_to_rgb_white(img_rgba: Image.Image) -> Image.Image:
    arr: np.ndarray = np.array(img_rgba.convert("RGBA"), dtype=np.uint8)
    rgb: np.ndarray = arr[:, :, :3].astype(np.float32)
    a: np.ndarray = arr[:, :, 3:4].astype(np.float32) / 255.0
    white: np.ndarray = np.full_like(rgb, 255.0)
    out: np.ndarray = rgb * a + white * (1.0 - a)
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), mode="RGB")


def maybe_left_third(img: Image.Image) -> tuple[Image.Image, bool]:
    """If image looks like a 3-panel horizontal sheet, crop left third; else return full."""
    w: int
    h: int
    w, h = img.size
    if w >= int(h * 1.45):
        third: int = w // 3
        return img.crop((0, 0, third, h)), True
    return img, False


def main() -> int:
    ap: argparse.ArgumentParser = argparse.ArgumentParser()
    ap.add_argument("source", type=Path, help="RGBA PNG (cleaned preferred)")
    ap.add_argument(
        "--out-prefix",
        type=Path,
        required=True,
        help="Path prefix for outputs, e.g. .../ab_test/orc_grunt/inputs/variant → variant_1.png … variant_5.png",
    )
    args: argparse.Namespace = ap.parse_args()

    src_p: Path = args.source.expanduser().resolve()
    if not src_p.is_file():
        print(f"Missing source: {src_p}", file=sys.stderr)
        return 1

    base: Image.Image = Image.open(src_p).convert("RGBA")
    cropped_for_v34: Image.Image
    used_crop: bool
    cropped_for_v34, used_crop = maybe_left_third(base)
    note: str = (
        "left-third crop applied (wide sheet detected)"
        if used_crop
        else "single front / narrow sheet — skipped left-third crop for V3/V4"
    )
    print(f"[variants] {note}")

    v1: Image.Image = hard_alpha_rgba(base)
    out1: Path = Path(str(args.out_prefix) + "_1.png")
    v1.save(out1)
    print(f"V1 {out1} {v1.size} {out1.stat().st_size} bytes")

    v2_base: Image.Image = hard_alpha_rgba(base)
    v2_rgb: Image.Image = rgba_to_rgb_white(v2_base).resize((1024, 1024), Image.LANCZOS)
    out2: Path = Path(str(args.out_prefix) + "_2.png")
    v2_rgb.save(out2)
    print(f"V2 {out2} {v2_rgb.size} {out2.stat().st_size} bytes")

    v3_src: Image.Image = hard_alpha_rgba(cropped_for_v34)
    v3: Image.Image = v3_src.resize((768, 768), Image.LANCZOS)
    out3: Path = Path(str(args.out_prefix) + "_3.png")
    v3.save(out3)
    print(f"V3 {out3} {v3.size} {out3.stat().st_size} bytes")

    v4_src: Image.Image = hard_alpha_rgba(cropped_for_v34)
    v4_rgb: Image.Image = rgba_to_rgb_white(v4_src).resize((512, 512), Image.LANCZOS)
    out4: Path = Path(str(args.out_prefix) + "_4.png")
    v4_rgb.save(out4)
    print(f"V4 {out4} {v4_rgb.size} {out4.stat().st_size} bytes")

    v5_base: Image.Image = hard_alpha_rgba(base)
    v5_rgb: Image.Image = rgba_to_rgb_white(v5_base).resize((512, 512), Image.LANCZOS)
    out5: Path = Path(str(args.out_prefix) + "_5.png")
    v5_rgb.save(out5)
    print(f"V5 {out5} {v5_rgb.size} {out5.stat().st_size} bytes")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
