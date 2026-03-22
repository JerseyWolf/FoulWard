#!/usr/bin/env bash
# Merge addons/gdai-mcp-plugin-godot from a vendor tree (e.g. full zip under MCPs/) into the project.
# MCPs/gdaimcp is a sources-only vendor snapshot; the full plugin zip from gdaimcp.com also adds
# from gdaimcp.com also includes bin/ and gdai_mcp_server.py — extract that zip into MCPs/ first.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-$REPO/MCPs/gdaimcp/addons/gdai-mcp-plugin-godot}"
DST="$REPO/addons/gdai-mcp-plugin-godot"
if [[ ! -d "$SRC" ]]; then
	echo "Source not found: $SRC" >&2
	exit 1
fi
mkdir -p "$DST"
rsync -a "$SRC/" "$DST/" --exclude 'requirements-mcp.txt'
echo "Synced: $SRC -> $DST (requirements-mcp.txt in project left unchanged)"
