#!/usr/bin/env bash
# run_gdunit_visible.sh — Same as run_gdunit.sh but WITHOUT --headless.
# Use this when you want to watch tests run in the Godot window.
# Do NOT use in CI or automated sessions.
#
# Override log path: GDUNIT_LOG_FILE=/path/to/custom.log ./tools/run_gdunit_visible.sh
#

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mono_bin="$repo_root/Godot_v4.6.2-stable_mono_linux.x86_64"
std_bin="$repo_root/Godot_v4.6.1-stable_linux.x86_64"
if [[ -x "$mono_bin" ]]; then
	default_bin="$mono_bin"
else
	default_bin="$std_bin"
fi
godot_bin="${GODOT_BIN:-$default_bin}"
log_file="${GDUNIT_LOG_FILE:-$repo_root/reports/gdunit_visible_run.log}"

if [[ ! -x "$godot_bin" ]]; then
	echo "run_gdunit_visible.sh: Godot binary not executable: $godot_bin" >&2
	echo "Set GODOT_BIN to your Godot executable path." >&2
	exit 1
fi

mkdir -p "$(dirname "$log_file")"

set +e
{
	echo "=== run_gdunit_visible.sh (full suite, windowed) $(date -Iseconds 2>/dev/null || date) ==="
	echo "Log file: $log_file"
	echo ""
	"$godot_bin" \
		--path "$repo_root" \
		-s "$repo_root/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
		-a "res://tests"
} 2>&1 | tee "$log_file"
gdunit_exit_code=${PIPESTATUS[0]}
set -e

if [[ $gdunit_exit_code -eq 0 ]]; then
	echo "run_gdunit_visible.sh: full log written to $log_file" >&2
	exit 0
fi

if [[ $gdunit_exit_code -eq 101 ]]; then
	echo "run_gdunit_visible.sh: GdUnit finished with warnings (exit 101); treating as pass. Log: $log_file" >&2
	exit 0
fi

echo "run_gdunit_visible.sh: exit $gdunit_exit_code — see $log_file" >&2
exit "$gdunit_exit_code"
