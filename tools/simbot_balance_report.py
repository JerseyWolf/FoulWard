#!/usr/bin/env python3
"""Aggregate CombatStatsTracker building_summary.csv files and emit balance report + status CSV.

Reads recursively from a root (default: ./simbot_runs). Mirror Godot user://simbot/runs here for local analysis.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from statistics import median


def load_building_rows(root: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for path in root.rglob("building_summary.csv"):
        with path.open(encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            for row in reader:
                rows.append(dict(row))
    return rows


def aggregate(rows: list[dict[str, str]]) -> dict[str, dict]:
    agg: dict[str, dict] = {}
    for r in rows:
        bid = (r.get("building_id") or "").strip()
        if not bid:
            continue
        if bid not in agg:
            agg[bid] = {
                "building_id": bid,
                "display_name": (r.get("display_name") or "").strip() or bid,
                "role_tags": (r.get("role_tags") or "").strip(),
                "total_damage": 0.0,
                "total_gold": 0.0,
                "total_ally_deaths": 0.0,
                "run_labels": set(),
            }
        a = agg[bid]
        a["total_damage"] += float(r.get("total_damage_dealt") or 0.0)
        gold_key = r.get("cost_gold_paid")
        if gold_key is None or gold_key == "":
            gold_key = r.get("gold_spent") or 0
        a["total_gold"] += float(gold_key or 0.0)
        a["total_ally_deaths"] += float(r.get("ally_deaths") or 0.0)
        rl = (r.get("run_label") or "").strip()
        if rl:
            a["run_labels"].add(rl)
    return agg


def compute_status(agg: dict[str, dict]) -> None:
    dpg_values: list[float] = []
    for a in agg.values():
        tg = float(a["total_gold"])
        if tg >= 200.0:
            dpg = float(a["total_damage"]) / max(tg, 1.0)
            dpg_values.append(dpg)
    if not dpg_values:
        for a in agg.values():
            a["damage_per_gold"] = 0.0
            a["status"] = "UNTESTED"
            a["runs"] = len(a["run_labels"])
            a["ally_deaths_per_run"] = 0.0
        return

    med = float(median(dpg_values))
    for a in agg.values():
        tg = float(a["total_gold"])
        dpg = float(a["total_damage"]) / max(tg, 1.0)
        a["damage_per_gold"] = dpg
        runs = max(len(a["run_labels"]), 1)
        a["runs"] = runs
        a["ally_deaths_per_run"] = float(a["total_ally_deaths"]) / float(runs)
        if tg < 200.0:
            a["status"] = "UNTESTED"
            continue
        if dpg >= med * 1.35:
            a["status"] = "OVERTUNED"
        elif dpg <= med * 0.65:
            a["status"] = "UNDERTUNED"
        else:
            a["status"] = "BASELINE"


def write_markdown(agg: dict[str, dict], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    rows = sorted(agg.values(), key=lambda x: float(x.get("damage_per_gold", 0.0)), reverse=True)
    lines = [
        "# SimBot balance report",
        "",
        "Median `damage_per_gold` uses towers with **total gold ≥ 200** across aggregated runs.",
        "",
        "| Building | role_tags | runs | dmg/gold | ally_deaths/run | status |",
        "|----------|-----------|------|----------|-----------------|--------|",
    ]
    for a in rows:
        name = str(a.get("display_name", a.get("building_id", "")))
        tags = str(a.get("role_tags", ""))
        runs = int(a.get("runs", 0))
        dpg = float(a.get("damage_per_gold", 0.0))
        adr = float(a.get("ally_deaths_per_run", 0.0))
        st = str(a.get("status", "UNTESTED"))
        lines.append(
            f"| {name} | {tags} | {runs} | {dpg:.2f} | {adr:.2f} | {st} |"
        )
    lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def write_status_csv(agg: dict[str, dict], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["building_id", "status"])
        for bid in sorted(agg.keys()):
            w.writerow([bid, str(agg[bid].get("status", "UNTESTED"))])


def main() -> None:
    ap = argparse.ArgumentParser(description="Build SimBot balance report from building_summary CSVs.")
    ap.add_argument(
        "--root",
        type=Path,
        default=Path("simbot_runs"),
        help="Directory tree containing */building_summary.csv (default: ./simbot_runs)",
    )
    ap.add_argument(
        "--out-md",
        type=Path,
        default=Path("tools/output/simbot_balance_report.md"),
        help="Output markdown path",
    )
    ap.add_argument(
        "--out-csv",
        type=Path,
        default=Path("tools/output/simbot_balance_status.csv"),
        help="Output building_id → status CSV",
    )
    args = ap.parse_args()

    root: Path = args.root
    if not root.is_dir():
        root.mkdir(parents=True, exist_ok=True)

    rows = load_building_rows(root)
    agg = aggregate(rows)
    compute_status(agg)
    write_markdown(agg, args.out_md)
    write_status_csv(agg, args.out_csv)
    print(f"Wrote {args.out_md} and {args.out_csv} ({len(agg)} buildings from {len(rows)} rows)")


if __name__ == "__main__":
    main()
