#!/usr/bin/env bash
# Phase 2 / E2E smoke: load main scene headless, run a few seconds of iterations, exit.
# On Linux this should finish with exit code 0. Some Windows + Godot 4.6 setups SIGSEGV
# after similar runs — use editor F5 or GdUnit for authoritative checks there.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT:-}"
if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
	if [[ -x "$REPO/Godot_v4.6.2-stable_mono_linux.x86_64" ]]; then
		GODOT_BIN="$REPO/Godot_v4.6.2-stable_mono_linux.x86_64"
	elif [[ -x "$REPO/Godot_v4.6.1-stable_linux.x86_64" ]]; then
		GODOT_BIN="$REPO/Godot_v4.6.1-stable_linux.x86_64"
	else
		GODOT_BIN="$(command -v godot || true)"
	fi
fi
if [[ -z "$GODOT_BIN" || ! -x "$GODOT_BIN" ]]; then
	echo "smoke_main_scene.sh: set GODOT to your Godot 4.6+ .NET editor binary, or place Godot_v4.6.2-stable_mono_linux.x86_64 (or Godot_v4.6.1-stable_linux.x86_64) in the repo root." >&2
	exit 1
fi
exec "$GODOT_BIN" --headless --path "$REPO" --scene res://scenes/main.tscn --quit-after 120
