#!/usr/bin/env python3
"""Merge PROMPT.md, CONTEXT_BRIEF.md, FILES_TO_UPLOAD.md into SESSION_NN_FULL_PROMPT.md per session folder."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def extract_upload_paths(files_to_upload_text: str) -> list[str]:
    paths: list[str] = []
    for line in files_to_upload_text.splitlines():
        if re.match(r"^\d+\.\s", line.strip()):
            match: re.Match[str] | None = re.search(r"`([^`]+)`", line)
            if match is not None:
                paths.append(match.group(1))
    return paths


def read_repo_file(repo_root: Path, rel_path: str) -> str:
    full: Path = repo_root / rel_path
    if not full.is_file():
        return f"[MISSING FILE: {rel_path}]\n"
    raw: bytes = full.read_bytes()
    if b"\x00" in raw[:8192]:
        return (
            f"[BINARY OR NON-TEXT FILE — raw size {len(raw)} bytes; "
            f"not embedded as text: {rel_path}]\n"
        )
    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("utf-8", errors="replace")


def build_session_doc(repo_root: Path, session_dir: Path) -> str:
    prompt_path: Path = session_dir / "PROMPT.md"
    context_path: Path = session_dir / "CONTEXT_BRIEF.md"
    files_list_path: Path = session_dir / "FILES_TO_UPLOAD.md"

    prompt_text: str = prompt_path.read_text(encoding="utf-8")
    context_text: str = context_path.read_text(encoding="utf-8")
    files_list_text: str = files_list_path.read_text(encoding="utf-8")

    rel_paths: list[str] = extract_upload_paths(files_list_text)

    parts: list[str] = [
        "PROMPT:\n\n",
        prompt_text.rstrip(),
        "\n\nCONTEXT_BRIEF:\n\n",
        context_text.rstrip(),
        "\n\nFILES:\n\n",
        files_list_text.rstrip(),
        "\n\n",
    ]

    for rel in rel_paths:
        content: str = read_repo_file(repo_root, rel)
        parts.append(rel)
        parts.append(":\n")
        parts.append(content)
        if not content.endswith("\n"):
            parts.append("\n")
        parts.append("\n")

    return "".join(parts)


def main() -> int:
    repo_root: Path = Path(__file__).resolve().parents[1]
    perplexity_root: Path = repo_root / "docs" / "perplexity_sessions"
    if not perplexity_root.is_dir():
        print(f"Not a directory: {perplexity_root}", file=sys.stderr)
        return 1

    session_dirs: list[Path] = sorted(
        p for p in perplexity_root.iterdir() if p.is_dir() and p.name.startswith("session_")
    )

    for session_dir in session_dirs:
        match: re.Match[str] | None = re.match(r"^session_(\d+)_", session_dir.name)
        if match is None:
            print(f"Skip (unexpected name): {session_dir.name}", file=sys.stderr)
            continue
        session_num: int = int(match.group(1))
        out_name: str = f"SESSION_{session_num:02d}_FULL_PROMPT.md"
        out_path: Path = session_dir / out_name

        doc: str = build_session_doc(repo_root, session_dir)
        out_path.write_text(doc, encoding="utf-8")
        print(f"Wrote {out_path.relative_to(repo_root)}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
