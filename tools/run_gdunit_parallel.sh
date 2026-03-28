#!/usr/bin/env bash
# run_gdunit_parallel.sh — Runs all 58 test files across 8 parallel headless
# Godot processes. Target: < 45 seconds wall-clock.
# Replaces run_gdunit.sh for CI and pre-commit checks once validated.
# Spec: IMPROVEMENTS_TO_BE_DONE.md Appendix E (Prompt 26 audit).

set -uo pipefail

PARALLEL_COUNT=8

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_bin="$repo_root/Godot_v4.6.1-stable_linux.x86_64"
godot_bin="${GODOT_BIN:-$default_bin}"
log_dir="$repo_root/reports/parallel"
summary_file="$repo_root/reports/gdunit_parallel_run.summary.txt"

if [[ ! -x "$godot_bin" ]]; then
	echo "run_gdunit_parallel.sh: Godot binary not executable: $godot_bin" >&2
	echo "Set GODOT_BIN to your Godot executable path." >&2
	exit 1
fi

test_files=()
for f in "$repo_root"/tests/test_*.gd; do
	[[ -f "$f" ]] || continue
	basename_f="$(basename "$f")"
	test_files+=("res://tests/$basename_f")
done

total_files=${#test_files[@]}
if [[ $total_files -eq 0 ]]; then
	echo "run_gdunit_parallel.sh: no test files found in $repo_root/tests/" >&2
	exit 1
fi

echo "run_gdunit_parallel.sh: found $total_files test files, splitting across $PARALLEL_COUNT processes" >&2

rm -rf "$log_dir"
mkdir -p "$log_dir"

declare -a group_files
for (( g=0; g<PARALLEL_COUNT; g++ )); do
	group_files[$g]=""
done

for (( i=0; i<total_files; i++ )); do
	g=$(( i % PARALLEL_COUNT ))
	if [[ -z "${group_files[$g]}" ]]; then
		group_files[$g]="${test_files[$i]}"
	else
		group_files[$g]="${group_files[$g]} ${test_files[$i]}"
	fi
done

pids=()
start_time=$(date +%s)

for (( g=0; g<PARALLEL_COUNT; g++ )); do
	files_str="${group_files[$g]}"
	if [[ -z "$files_str" ]]; then
		continue
	fi

	group_log="$log_dir/group_${g}.log"
	group_report_dir="$log_dir/report_${g}"
	mkdir -p "$group_report_dir"

	gdunit_args=()
	for f in $files_str; do
		gdunit_args+=(-a "$f")
	done

	(
		set +e
		"$godot_bin" \
			--headless \
			--path "$repo_root" \
			-s "$repo_root/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
			--ignoreHeadlessMode \
			"${gdunit_args[@]}" \
			> "$group_log" 2>&1
		ec=$?
		echo "$ec" > "$log_dir/exit_${g}.txt"
		exit 0
	) &
	pids+=($!)
	echo "  Group $g: $(echo "$files_str" | wc -w) files (pid $!)" >&2
done

for pid in "${pids[@]}"; do
	wait "$pid" 2>/dev/null || true
done

end_time=$(date +%s)
elapsed=$((end_time - start_time))

strip_ansi() {
	sed 's/\x1b\[[0-9;]*m//g'
}

any_real_fail=0
total_cases=0
total_failures=0
total_orphans=0
summary_lines=()

summary_lines+=("=== run_gdunit_parallel.sh summary ===")
summary_lines+=("Date: $(date -Iseconds 2>/dev/null || date)")
summary_lines+=("Wall-clock: ${elapsed}s")
summary_lines+=("Processes: $PARALLEL_COUNT")
summary_lines+=("Test files: $total_files")
summary_lines+=("")

for (( g=0; g<PARALLEL_COUNT; g++ )); do
	exit_file="$log_dir/exit_${g}.txt"
	group_log="$log_dir/group_${g}.log"
	exit_code=1
	if [[ -f "$exit_file" ]]; then
		exit_code=$(cat "$exit_file")
	fi

	clean_log=$(cat "$group_log" | strip_ansi)
	cases=$(echo "$clean_log" | grep -oP 'Overall Summary:\s+\K\d+' || echo "0")
	failures=$(echo "$clean_log" | grep -oP '\d+ failures' | tail -1 | grep -oP '^\d+' || echo "0")
	orphans=$(echo "$clean_log" | grep -oP '\d+ orphans' | tail -1 | grep -oP '^\d+' || echo "0")

	total_cases=$((total_cases + cases))
	total_failures=$((total_failures + failures))
	total_orphans=$((total_orphans + orphans))

	files_str="${group_files[$g]:-}"
	file_count=$(echo "$files_str" | wc -w)
	summary_lines+=("Group $g: exit=$exit_code  cases=$cases  failures=$failures  orphans=$orphans  files=$file_count")

	if [[ "$exit_code" -ne 0 && "$exit_code" -ne 101 ]]; then
		if [[ "$exit_code" -eq 100 ]]; then
			if echo "$clean_log" | grep -q "0 failures"; then
				:
			else
				any_real_fail=1
			fi
		else
			any_real_fail=1
		fi
	fi
done

summary_lines+=("")
summary_lines+=("TOTALS: cases=$total_cases  failures=$total_failures  orphans=$total_orphans  wall-clock=${elapsed}s")
if [[ $any_real_fail -eq 0 && $total_failures -eq 0 ]]; then
	summary_lines+=("RESULT: PASS")
else
	summary_lines+=("RESULT: FAIL")
fi

printf '%s\n' "${summary_lines[@]}" | tee "$summary_file"

if [[ $any_real_fail -eq 0 && $total_failures -eq 0 ]]; then
	echo "" >&2
	echo "run_gdunit_parallel.sh: PASS (${elapsed}s, $total_cases cases, $total_failures failures, $total_orphans orphans)" >&2
	exit 0
else
	echo "" >&2
	echo "run_gdunit_parallel.sh: FAIL — check $log_dir/group_*.log for details" >&2
	exit 1
fi
