#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""TRELLIS A/B batch + decimation + diagnostics. Writes ``local/gen3d/ab_test/results.csv``."""
from __future__ import annotations

import csv
import importlib
import os
import sys
import time
from pathlib import Path

import numpy as np
import open3d as o3d
from PIL import Image

_SCRIPT_DIR: Path = Path(__file__).resolve().parent
_GEN3D_ROOT: Path = _SCRIPT_DIR.parent
_REPO_ROOT: Path = _GEN3D_ROOT.parent.parent
GEN3D: str = str(_GEN3D_ROOT)
ROOT: Path = _REPO_ROOT / "local" / "gen3d" / "ab_test"
RESULTS_CSV: Path = ROOT / "results.csv"

SEEDS: list[int] = [42, 137, 256, 512, 1024]
VARIANTS: list[int] = [1, 2, 3, 4, 5]


def ensure_stage2_env() -> None:
    os.environ["FOULWARD_TRELLIS_PREDECIMATE"] = "100000"
    os.environ["FOULWARD_TRELLIS_SAMPLER_STEPS"] = "8"
    os.environ["FOULWARD_TRELLIS_SPARSE_GUIDANCE"] = "5.0"
    os.environ["FOULWARD_TRELLIS_SLAT_GUIDANCE"] = "2.0"


def reload_stage2() -> object:
    if "pipeline.stage2_mesh" in sys.modules:
        return importlib.reload(sys.modules["pipeline.stage2_mesh"])
    import pipeline.stage2_mesh as s2

    return s2


def edge_for_image(path: Path) -> int:
    im: Image.Image = Image.open(path)
    w: int
    h: int
    w, h = im.size
    return int(max(w, h))


def diagnose_glb(path: Path) -> tuple[int, int, bool, bool, float]:
    sys.path.insert(0, GEN3D)
    from pipeline.stage2_mesh import _check_glb_has_texture, _load_combined_mesh

    mesh = _load_combined_mesh(str(path))
    faces: int = int(len(mesh.faces))
    wt: bool = bool(mesh.is_watertight)
    tex: bool = _check_glb_has_texture(str(path))

    tm = o3d.geometry.TriangleMesh()
    tm.vertices = o3d.utility.Vector3dVector(np.asarray(mesh.vertices, dtype=np.float64))
    tm.triangles = o3d.utility.Vector3iVector(np.asarray(mesh.faces, dtype=np.int32))
    ne = tm.get_non_manifold_edges(allow_boundary_edges=False)
    nm: int = int(len(np.asarray(ne)))

    kb: float = float(path.stat().st_size) / 1024.0
    return faces, nm, wt, tex, kb


def append_csv(row: dict[str, str | int | float | bool]) -> None:
    RESULTS_CSV.parent.mkdir(parents=True, exist_ok=True)
    file_exists: bool = RESULTS_CSV.is_file()
    fieldnames: list[str] = [
        "slug",
        "variant",
        "seed",
        "face_count",
        "nonmanifold_edges",
        "watertight",
        "has_texture",
        "file_size_kb",
        "status",
    ]
    with RESULTS_CSV.open("a", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames)
        if not file_exists:
            w.writeheader()
        w.writerow(row)


def run_slug(slug: str, base_dir: Path) -> None:
    sys.path.insert(0, GEN3D)
    ensure_stage2_env()

    for vn in VARIANTS:
        vpath: Path = base_dir / "inputs" / f"variant_{vn}.png"
        if not vpath.is_file():
            print(f"[SKIP] missing {vpath}")
            continue
        edge: int = edge_for_image(vpath)
        os.environ["FOULWARD_TRELLIS_INPUT_EDGE"] = str(edge)

        for seed in SEEDS:
            out_dir: Path = base_dir / f"variant_{vn}" / f"seed_{seed}"
            out_dir.mkdir(parents=True, exist_ok=True)
            raw_glb: Path = out_dir / "raw.glb"
            dec_glb: Path = out_dir / "decimated.glb"

            s2 = reload_stage2()
            t0: float = time.time()
            print(f"\n=== {slug} V{vn} seed={seed} edge={edge} ===")
            try:
                s2.image_to_glb(
                    str(vpath),
                    str(raw_glb),
                    model_id="microsoft/TRELLIS.2-4B",
                    tri_budget=12000,
                    seed=seed,
                )
            except Exception as exc:
                print(f"[FAIL] image_to_glb: {exc}")
                append_csv(
                    {
                        "slug": slug,
                        "variant": vn,
                        "seed": seed,
                        "face_count": -1,
                        "nonmanifold_edges": -1,
                        "watertight": False,
                        "has_texture": False,
                        "file_size_kb": 0.0,
                        "status": f"trellis_fail:{exc}",
                    }
                )
                continue

            if not raw_glb.is_file() or raw_glb.stat().st_size == 0:
                print(f"[FAIL] raw missing or empty: {raw_glb}")
                append_csv(
                    {
                        "slug": slug,
                        "variant": vn,
                        "seed": seed,
                        "face_count": -1,
                        "nonmanifold_edges": -1,
                        "watertight": False,
                        "has_texture": False,
                        "file_size_kb": 0.0,
                        "status": "raw_missing",
                    }
                )
                continue

            try:
                s2.decimate_glb(str(raw_glb), str(dec_glb), target_faces=10000)
            except Exception as exc:
                print(f"[FAIL] decimate: {exc}")
                append_csv(
                    {
                        "slug": slug,
                        "variant": vn,
                        "seed": seed,
                        "face_count": -1,
                        "nonmanifold_edges": -1,
                        "watertight": False,
                        "has_texture": False,
                        "file_size_kb": 0.0,
                        "status": f"decimate_fail:{exc}",
                    }
                )
                continue

            if not dec_glb.is_file() or dec_glb.stat().st_size == 0:
                append_csv(
                    {
                        "slug": slug,
                        "variant": vn,
                        "seed": seed,
                        "face_count": -1,
                        "nonmanifold_edges": -1,
                        "watertight": False,
                        "has_texture": False,
                        "file_size_kb": 0.0,
                        "status": "decimated_missing",
                    }
                )
                continue

            fc, nm, wt, tex, kb = diagnose_glb(dec_glb)
            dt: float = time.time() - t0
            print(
                f"[OK] faces={fc} nm={nm} watertight={wt} tex={tex} kb={kb:.1f} ({dt:.1f}s)"
            )
            append_csv(
                {
                    "slug": slug,
                    "variant": vn,
                    "seed": seed,
                    "face_count": fc,
                    "nonmanifold_edges": nm,
                    "watertight": wt,
                    "has_texture": tex,
                    "file_size_kb": round(kb, 2),
                    "status": "ok",
                }
            )


def main() -> int:
    if len(sys.argv) < 2:
        print(
            "Usage: ab_test_batch.py <slug>  "
            "(runs all variants/seeds for local/gen3d/ab_test/<slug>/)"
        )
        return 1
    slug: str = sys.argv[1]
    base: Path = ROOT / slug
    if not base.is_dir():
        print(f"Missing {base}")
        return 1
    run_slug(slug, base)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
