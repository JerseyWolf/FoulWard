#!/usr/bin/env bash
# Merge a vendor `addons/gdai-mcp-plugin-godot` tree into this project.
# Pass the path to the extracted addon folder (e.g. from a gdaimcp.com zip unpacked outside res://).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $# -lt 1 || ! -d "$1" ]]; then
	echo "Usage: $0 /path/to/gdai-mcp-plugin-godot" >&2
	echo "Example: unzip vendor to /tmp/gdai && $0 /tmp/gdai/addons/gdai-mcp-plugin-godot" >&2
	exit 1
fi
SRC="$(cd "$1" && pwd)"
DST="$REPO/addons/gdai-mcp-plugin-godot"
mkdir -p "$DST"
rsync -a "$SRC/" "$DST/" --exclude 'requirements-mcp.txt'
echo "Synced: $SRC -> $DST (requirements-mcp.txt in project left unchanged)"
