#!/usr/bin/env python3
"""Static check: GDAI MCP must not print to stdout (MCP uses stdout for JSON-RPC only)."""
from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
TARGET = ROOT / "addons" / "gdai-mcp-plugin-godot" / "gdai_mcp_server.py"


def main() -> int:
    if not TARGET.is_file():
        print(f"Missing {TARGET}", file=sys.stderr)
        return 2
    text = TARGET.read_text(encoding="utf-8")
    bad: list[tuple[int, str]] = []
    for idx, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if "print(" not in line:
            continue
        if "file=sys.stderr" in line:
            continue
        bad.append((idx, line.rstrip()))
    if bad:
        print("Found print() calls that are not explicitly directed to stderr:", file=sys.stderr)
        for idx, line in bad:
            print(f"  line {idx}: {line}", file=sys.stderr)
        return 1
    print("OK: GDAI MCP server only logs via stderr.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
