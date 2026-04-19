# SPDX-License-Identifier: MIT
"""Load `~/.foulward_secrets` into `os.environ` (same convention as `FoulWard/launch.sh`)."""

from __future__ import annotations

import os
from pathlib import Path


def load_foulward_secrets() -> None:
    """Parse `export KEY=value` / `KEY=value` lines from the secrets file.

    Path: ``FOULWARD_SECRETS_FILE`` or ``~/.foulward_secrets``. Skips comments and
    blank lines. Does **not** override keys already set in the environment (exported
    shell vars win).

    After loading, if ``HF_TOKEN`` is set but ``HUGGING_FACE_HUB_TOKEN`` is empty,
    mirrors the token so Hugging Face libraries that read either name both work.
    """
    raw: str | None = os.environ.get("FOULWARD_SECRETS_FILE")
    secrets_path: Path = (Path(raw).expanduser() if raw else Path.home() / ".foulward_secrets").resolve()
    if not secrets_path.is_file():
        return
    try:
        text: str = secrets_path.read_text(encoding="utf-8")
    except OSError:
        return
    for line in text.splitlines():
        stripped: str = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("export "):
            stripped = stripped[7:].lstrip()
        if "=" not in stripped:
            continue
        key: str
        value: str
        key, _, value = stripped.partition("=")
        key = key.strip()
        value = value.strip()
        if value.startswith('"') and value.endswith('"') and len(value) >= 2:
            value = value[1:-1]
        elif value.startswith("'") and value.endswith("'") and len(value) >= 2:
            value = value[1:-1]
        if key == "":
            continue
        existing: str | None = os.environ.get(key)
        if existing is not None and existing != "":
            continue
        os.environ[key] = value

    hf: str | None = os.environ.get("HF_TOKEN")
    if hf is not None and hf.strip() != "":
        hub: str | None = os.environ.get("HUGGING_FACE_HUB_TOKEN")
        if hub is None or hub.strip() == "":
            os.environ["HUGGING_FACE_HUB_TOKEN"] = hf.strip()
