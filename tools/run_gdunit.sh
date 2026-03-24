#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_bin="$repo_root/Godot_v4.6.1-stable_linux.x86_64"
godot_bin="${GODOT_BIN:-$default_bin}"

if [[ ! -x "$godot_bin" ]]; then
  echo "run_gdunit.sh: Godot binary not executable: $godot_bin" >&2
  echo "Set GODOT_BIN to your Godot executable path." >&2
  exit 1
fi

exec "$godot_bin" \
  --headless \
  --path "$repo_root" \
  -s "$repo_root/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
  --ignoreHeadlessMode \
  -a "res://tests"
