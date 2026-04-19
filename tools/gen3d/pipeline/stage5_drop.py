# SPDX-License-Identifier: MIT
"""Stage 5: Copy final GLB into Foul Ward art/generated (flat paths)."""

from __future__ import annotations

import shutil
from pathlib import Path


def drop_to_godot(glb_path: str, unit_slug: str, output_dir: str) -> str:
    """Copy GLB to output_dir/{unit_slug}.glb. Godot creates .import on next editor scan."""
    src: Path = Path(glb_path).resolve()
    out_dir: Path = Path(output_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    dest: Path = out_dir / f"{unit_slug}.glb"
    shutil.copy2(src, dest)
    print(f"[stage5_drop] Dropped to {dest}")
    return str(dest)
