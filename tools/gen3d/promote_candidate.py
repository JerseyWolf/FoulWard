#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""
Re-select a mesh variant after a batch run and re-run stages 3–5 only.

Usage:
    python3 promote_candidate.py <slug> <variant_number>

Example:
    python3 promote_candidate.py orc_grunt 3

This copies ``art/gen3d_candidates/<slug>/candidate_<N>_decimated.glb`` to
``art/gen3d_candidates/<slug>/selected.glb``, updates the ``meta.json`` sidecar,
and re-invokes ``foulward_gen.py`` with ``SKIP_STAGE1=1 SKIP_STAGE2=1`` so only
stages 3 (rig), 4 (anim), and 5 (drop) are re-run on the newly selected mesh.

Requires:
    - A completed batch run that already generated candidates via Stage 2.
    - ``art/gen3d_candidates/<slug>/meta.json`` must exist (written by run_pipeline).
    - The trellis2 conda environment (for TRELLIS deps used in stages 3–5).
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) < 3:
        print("Usage: python3 promote_candidate.py <slug> <variant_number>")
        print("Example: python3 promote_candidate.py orc_grunt 3")
        sys.exit(1)

    slug: str = sys.argv[1].lower().replace(" ", "_")
    try:
        num: int = int(sys.argv[2])
    except ValueError:
        print(f"ERROR: variant_number must be an integer, got {sys.argv[2]!r}")
        sys.exit(1)

    script_dir: Path = Path(__file__).resolve().parent
    project_root: Path = script_dir.parents[1]
    candidates_dir: Path = project_root / "art" / "gen3d_candidates" / slug

    src: Path = candidates_dir / f"candidate_{num}_decimated.glb"
    if not src.is_file():
        print(f"ERROR: {src} not found")
        print(
            f"  Run the full pipeline first to generate candidates,"
            f" or check the variant number (1–N)."
        )
        sys.exit(1)

    # Promote: copy to selected.glb
    dst: Path = candidates_dir / "selected.glb"
    shutil.copy2(src, dst)
    print(f"Promoted candidate {num} → {dst}")

    # Update meta.json
    meta_path: Path = candidates_dir / "meta.json"
    if not meta_path.is_file():
        print(
            "WARNING: meta.json not found — cannot auto re-run stages 3–5."
            " Run foulward_gen.py manually with SKIP_STAGE1=1 SKIP_STAGE2=1"
            f" SELECTED_GLB={dst}."
        )
        sys.exit(0)

    with open(meta_path, encoding="utf-8") as f:
        meta: dict[str, object] = json.load(f)

    meta["selected"] = num
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2)
    print(f"Updated meta.json: selected={num}")

    unit_name: str = str(meta.get("unit_name", slug))
    faction: str = str(meta.get("faction", "orc_raiders"))
    asset_type: str = str(meta.get("asset_type", "enemy"))

    # Re-run stages 3–5 on the promoted candidate
    env: dict[str, str] = os.environ.copy()
    env["SKIP_STAGE1"] = "1"
    env["SKIP_STAGE2"] = "1"
    env["SELECTED_GLB"] = str(dst)

    # Use the same Python that is currently running (should be trellis2 env)
    python: str = sys.executable
    gen_script: Path = script_dir / "foulward_gen.py"

    print(
        f"\nRe-running stages 3–5 for {slug!r}"
        f" ({unit_name}, {faction}, {asset_type}) ..."
    )
    result: subprocess.CompletedProcess[bytes] = subprocess.run(
        [python, str(gen_script), unit_name, faction, asset_type],
        env=env,
        cwd=str(script_dir),
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
