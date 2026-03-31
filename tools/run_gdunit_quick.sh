#!/usr/bin/env bash
# Fast subset of GdUnit4 — same engine/headless path as run_gdunit.sh, but only selected suites.
#
# --- Note for Cursor / LLM agents ---
# Use THIS script as the default test command during iterative work. Run `./tools/run_gdunit.sh`
# (full suite) after a large chunk of related changes or before merge.
#
# Logs (stdout from Godot is NOT echoed to the terminal — avoids huge captures):
#   Full:   reports/gdunit_quick_run.log     (override: GDUNIT_LOG_FILE)
#   Summary: reports/gdunit_quick_run.summary.txt — last N lines of the full log for quick
#            tail/rg checks without scrolling (override: GDUNIT_QUICK_SUMMARY_FILE, GDUNIT_QUICK_SUMMARY_LINES)
#
# Why: `./tools/run_gdunit.sh` passes `-a "res://tests"` so GdUnit discovers and runs *every*
# suite. Several suites load `main.tscn`, spin physics/navigation, or use many `await` frames;
# that is valuable for integration coverage but slow for tight edit-test loops.
#
# This script uses multiple `-a res://tests/<suite>.gd` flags so only the allowlist runs.
# Edit QUICK_SUITES below when you learn which files matter for your current work (add suites
# you touch; drop suites you never need locally). CI / pre-merge should still use the full
# `./tools/run_gdunit.sh` unless you intentionally gate on a smaller set.
#
# GdUnit reference: addons/gdUnit4/src/core/runners/GdUnitTestCIRunner.gd (`-a` = add path).

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
default_bin="$repo_root/Godot_v4.6.1-stable_linux.x86_64"
godot_bin="${GODOT_BIN:-$default_bin}"
log_file="${GDUNIT_LOG_FILE:-$repo_root/reports/gdunit_quick_run.log}"
summary_file="${GDUNIT_QUICK_SUMMARY_FILE:-$repo_root/reports/gdunit_quick_run.summary.txt}"
summary_lines="${GDUNIT_QUICK_SUMMARY_LINES:-150}"

if [[ ! -x "$godot_bin" ]]; then
	echo "run_gdunit_quick.sh: Godot binary not executable: $godot_bin" >&2
	echo "Set GODOT_BIN to your Godot executable path." >&2
	exit 1
fi

# Allowlist: prefer autoloads, resources, and managers that do not preload `main.tscn`.
# Omitted by default (heavier): e.g. test_wave_manager, test_hex_grid, test_ally_spawning,
# test_enemy_pathfinding, test_simulation_api, scene-heavy combat tests — run full suite for those.
QUICK_SUITES=(
	"res://tests/test_economy_manager.gd"
	"res://tests/test_damage_calculator.gd"
	"res://tests/test_health_component.gd"
	"res://tests/test_art_placeholders.gd"
	"res://tests/test_ally_data.gd"
	"res://tests/test_ally_combat.gd"
	"res://tests/test_faction_data.gd"
	"res://tests/test_boss_data.gd"
	"res://tests/test_territory_data.gd"
	"res://tests/test_campaign_manager.gd"
	"res://tests/test_endless_mode.gd"
	"res://tests/test_game_manager.gd"
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
	"res://tests/test_simbot_basic_run.gd"
	"res://tests/test_simbot_handlers.gd"
	"res://tests/test_simbot_logging.gd"
	"res://tests/test_simbot_safety.gd"
	"res://tests/test_dialogue_manager.gd"
	"res://tests/test_relationship_manager.gd"
	"res://tests/test_florence.gd"
	"res://tests/test_spell_manager.gd"
	"res://tests/test_weapon_structural.gd"
	"res://tests/test_building_specials.gd"
	"res://tests/test_settings_manager.gd"
	"res://tests/test_save_manager.gd"
	"res://tests/test_relationship_manager_tiers.gd"
	"res://tests/test_save_manager_slots.gd"
	"res://tests/unit/test_building_kit.gd"
	"res://tests/unit/test_terrain.gd"
	"res://tests/unit/test_mission_spawn_routing.gd"
	"res://tests/unit/test_td_resource_helpers.gd"
	"res://tests/unit/test_economy_mission_integration.gd"
	"res://tests/unit/test_aura_healer_runtime.gd"
	"res://tests/unit/test_simbot_balance_integration.gd"
)

gdunit_args=()
for suite in "${QUICK_SUITES[@]}"; do
	gdunit_args+=(-a "$suite")
done

mkdir -p "$(dirname "$log_file")"
mkdir -p "$(dirname "$summary_file")"

set +e
{
	echo "=== run_gdunit_quick.sh $(date -Iseconds 2>/dev/null || date) ==="
	echo "Full log: $log_file"
	echo "Summary file (tail): $summary_file"
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

{
	echo "=== run_gdunit_quick.sh summary (last $summary_lines lines of full log) ==="
	echo "Full log: $log_file"
	echo "GdUnit exit code: $gdunit_exit_code"
	echo "Hint: rg -n 'FAILED|FAIL|ERROR|Parse Error' \"$log_file\""
	echo ""
	tail -n "$summary_lines" "$log_file"
} > "$summary_file"

if [[ $gdunit_exit_code -eq 0 ]]; then
	echo "run_gdunit_quick.sh: full log → $log_file" >&2
	echo "run_gdunit_quick.sh: summary → $summary_file (check tail for Overall Summary / failures)" >&2
	exit 0
fi

if [[ $gdunit_exit_code -eq 101 ]]; then
	echo "run_gdunit_quick.sh: GdUnit finished with warnings (exit 101); treating as pass." >&2
	echo "run_gdunit_quick.sh: full log → $log_file | summary → $summary_file" >&2
	exit 0
fi

# GdUnit may return 100 when the Godot error monitor counts warnings (e.g. expected headless
# push_warning chains) while all assertions pass — if the log shows 0 failures, treat as pass.
if [[ $gdunit_exit_code -eq 100 ]] && grep -q "Overall Summary:.*0 failures" "$log_file" 2>/dev/null; then
	echo "run_gdunit_quick.sh: exit 100 with 0 test failures (see GdUnit 'errors' / warnings in log); treating as pass." >&2
	echo "run_gdunit_quick.sh: full log → $log_file | summary → $summary_file" >&2
	exit 0
fi

echo "run_gdunit_quick.sh: exit $gdunit_exit_code — see $log_file or $summary_file" >&2
exit "$gdunit_exit_code"
