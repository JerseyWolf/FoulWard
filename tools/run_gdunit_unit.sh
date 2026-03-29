#!/usr/bin/env bash
# run_gdunit_unit.sh — Runs only pure unit tests (35 files, ~65s wall-clock).
# Engine startup overhead dominates; individual tests run in milliseconds.
# Use for focused coverage checks. For fast iteration, use run_gdunit_quick.sh.
# GdUnit4 accepts multiple -a flags in one process (same pattern as run_gdunit_quick.sh).

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_bin="$repo_root/Godot_v4.6.1-stable_linux.x86_64"
godot_bin="${GODOT_BIN:-$default_bin}"
log_file="${GDUNIT_LOG_FILE:-$repo_root/reports/gdunit_unit_run.log}"
summary_file="${GDUNIT_UNIT_SUMMARY_FILE:-$repo_root/reports/gdunit_unit_run.summary.txt}"
summary_lines="${GDUNIT_UNIT_SUMMARY_LINES:-100}"

if [[ ! -x "$godot_bin" ]]; then
	echo "run_gdunit_unit.sh: Godot binary not executable: $godot_bin" >&2
	echo "Set GODOT_BIN to your Godot executable path." >&2
	exit 1
fi

UNIT_SUITES=(
	"res://tests/test_economy_manager.gd"
	"res://tests/test_damage_calculator.gd"
	"res://tests/test_health_component.gd"
	"res://tests/test_art_placeholders.gd"
	"res://tests/test_ally_data.gd"
	"res://tests/test_faction_data.gd"
	"res://tests/test_boss_data.gd"
	"res://tests/test_territory_data.gd"
	"res://tests/test_campaign_manager.gd"
	"res://tests/test_endless_mode.gd"
	"res://tests/test_research_manager.gd"
	"res://tests/test_shop_manager.gd"
	"res://tests/test_consumables.gd"
	"res://tests/test_enchantment_manager.gd"
	"res://tests/test_territory_economy_bonuses.gd"
	"res://tests/test_campaign_territory_mapping.gd"
	"res://tests/test_campaign_territory_updates.gd"
	"res://tests/test_mercenary_offers.gd"
	"res://tests/test_mercenary_purchase.gd"
	"res://tests/test_campaign_ally_roster.gd"
	"res://tests/test_mini_boss_defection.gd"
	"res://tests/test_simbot_mercenaries.gd"
	"res://tests/test_simbot_profiles.gd"
	"res://tests/test_simbot_handlers.gd"
	"res://tests/test_simbot_logging.gd"
	"res://tests/test_simbot_safety.gd"
	"res://tests/test_dialogue_manager.gd"
	"res://tests/test_relationship_manager.gd"
	"res://tests/test_florence.gd"
	"res://tests/test_weapon_structural.gd"
	"res://tests/test_building_specials.gd"
	"res://tests/test_settings_manager.gd"
	"res://tests/test_save_manager.gd"
	"res://tests/test_relationship_manager_tiers.gd"
	"res://tests/test_save_manager_slots.gd"
)

gdunit_args=()
for suite in "${UNIT_SUITES[@]}"; do
	gdunit_args+=(-a "$suite")
done

mkdir -p "$(dirname "$log_file")"
mkdir -p "$(dirname "$summary_file")"

start_time=$(date +%s)

set +e
{
	echo "=== run_gdunit_unit.sh $(date -Iseconds 2>/dev/null || date) ==="
	echo "Full log: $log_file"
	echo ""
	"$godot_bin" \
		--headless \
		--path "$repo_root" \
		-s "$repo_root/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
		--ignoreHeadlessMode \
		"${gdunit_args[@]}"
} > "$log_file" 2>&1
gdunit_exit_code=$?
set -e

end_time=$(date +%s)
elapsed=$((end_time - start_time))

{
	echo "=== run_gdunit_unit.sh summary (last $summary_lines lines of full log) ==="
	echo "Full log: $log_file"
	echo "GdUnit exit code: $gdunit_exit_code"
	echo "Wall-clock: ${elapsed}s"
	echo ""
	tail -n "$summary_lines" "$log_file"
} > "$summary_file"

if [[ $gdunit_exit_code -eq 0 ]]; then
	echo "run_gdunit_unit.sh: PASS (${elapsed}s) — full log → $log_file" >&2
	exit 0
fi

if [[ $gdunit_exit_code -eq 101 ]]; then
	echo "run_gdunit_unit.sh: PASS with warnings (exit 101, ${elapsed}s) — full log → $log_file" >&2
	exit 0
fi

if [[ $gdunit_exit_code -eq 100 ]] && grep -q "Overall Summary:.*0 failures" "$log_file" 2>/dev/null; then
	echo "run_gdunit_unit.sh: PASS (exit 100, 0 test failures, ${elapsed}s) — full log → $log_file" >&2
	exit 0
fi

echo "run_gdunit_unit.sh: FAILED (exit $gdunit_exit_code, ${elapsed}s) — see $log_file or $summary_file" >&2
exit "$gdunit_exit_code"
