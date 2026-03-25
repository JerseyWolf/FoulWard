#!/usr/bin/env bash
#
# GdUnit4 — FULL suite (`res://tests/`). Slower; use for milestones / pre-merge / big refactors.
#
# --- Note for Cursor / LLM agents ---
# Prefer `./tools/run_gdunit_quick.sh` during normal iterative work (smaller allowlist, much faster).
# Run THIS script only after finishing a large related chunk of tasks, or when you need full
# regression coverage. After running, read failures from the log file (see below) instead of
# relying on truncated terminal capture — e.g. `tail -n 80 reports/gdunit_full_run.log` or
# `rg -n 'FAIL|ERROR|Parse Error' reports/gdunit_full_run.log`.
#
# Override log path: GDUNIT_LOG_FILE=/path/to/custom.log ./tools/run_gdunit.sh
#

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_bin="$repo_root/Godot_v4.6.1-stable_linux.x86_64"
godot_bin="${GODOT_BIN:-$default_bin}"
log_file="${GDUNIT_LOG_FILE:-$repo_root/reports/gdunit_full_run.log}"

if [[ ! -x "$godot_bin" ]]; then
	echo "run_gdunit.sh: Godot binary not executable: $godot_bin" >&2
	echo "Set GODOT_BIN to your Godot executable path." >&2
	exit 1
fi

mkdir -p "$(dirname "$log_file")"

set +e
{
	echo "=== run_gdunit.sh (full suite) $(date -Iseconds 2>/dev/null || date) ==="
	echo "Log file: $log_file"
	echo ""
	"$godot_bin" \
		--headless \
		--path "$repo_root" \
		-s "$repo_root/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
		--ignoreHeadlessMode \
		-a "res://tests"
} 2>&1 | tee "$log_file"
gdunit_exit_code=${PIPESTATUS[0]}
set -e

# GdUnit returns:
#   0   = success
#   101 = warning (typically orphan nodes)
# Keep all warnings/errors visible in output, but allow warning-only runs to pass.
if [[ $gdunit_exit_code -eq 0 ]]; then
	echo "run_gdunit.sh: full log written to $log_file" >&2
	exit 0
fi

if [[ $gdunit_exit_code -eq 101 ]]; then
	echo "run_gdunit.sh: GdUnit finished with warnings (exit 101); treating as pass. Log: $log_file" >&2
	exit 0
fi

echo "run_gdunit.sh: exit $gdunit_exit_code — see $log_file (try: tail -n 100 \"$log_file\")" >&2
exit "$gdunit_exit_code"
