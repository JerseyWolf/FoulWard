# PROMPT_12_IMPLEMENTATION — Mercenary offers, ally roster, mini-boss defection, SimBot

Updated: 2026-03-25.

## Scope (implemented)

### Types (`res://scripts/types.gd`)

- **`AllyRole`** — combat role tags for scoring / SimBot (`MELEE_FRONTLINE`, etc.).
- **`StrategyProfile`** — SimBot strategy (`BALANCED`, `AGGRESSIVE`, …).

### Resources

- **`AllyData`** (`res://scripts/resources/ally_data.gd`) — extended with `role`, `damage_type`, `attack_damage`, `patrol_radius`, `recovery_time`, `scene_path`, `is_starter_ally`, `is_defected_ally`, `debug_color`, etc.
- **`MercenaryOfferData`** — single offer: `ally_id`, costs, day range, `is_defection_offer`, `is_available_on_day`, `get_cost_summary`.
- **`MercenaryCatalog`** — `offers` (untyped `Array` for autoload parse order), `max_offers_per_day`, `filter_offers_for_day`, `get_daily_offers`.
- **`MiniBossData`** — `boss_id`, `can_defect_to_ally`, `defected_ally_id`, defection cost / timing hooks.
- **Data**: `res://resources/mercenary_catalog.tres`, `res://resources/mercenary_offers/*.tres`, `res://resources/miniboss_data/*.tres`, ally `.tres` updates under `res://resources/ally_data/`.

### SignalBus (`res://autoloads/signal_bus.gd`)

- `mercenary_offer_generated(ally_id: String)`
- `mercenary_recruited(ally_id: String)`
- `ally_roster_changed()`

### CampaignManager (`res://autoloads/campaign_manager.gd`)

- Owned vs active roster: `owned_allies`, `active_allies_for_next_day`, `max_active_allies_per_day`.
- `generate_offers_for_day`, `preview_mercenary_offers_for_day`, `get_current_offers`, `purchase_mercenary_offer` (via **EconomyManager**).
- `notify_mini_boss_defeated` / `_inject_defection_offer` for defectable mini-bosses.
- `auto_select_best_allies` / `_pick_best_active` — strategy-weighted selection from `AllyData.role`.
- `@export var mercenary_catalog: Resource` with default load from `res://resources/mercenary_catalog.tres`.
- After **`mission_won`**, day advances only when **`mission_number == current_day`**; tests must sync **`GameManager.current_mission`** when emitting wins (see `test_campaign_manager.gd`, `test_game_manager.gd`).

### GameManager (`res://autoloads/game_manager.gd`)

- **`_transition_to`** no-ops when the target state equals the current state (avoids duplicate `BETWEEN_MISSIONS` transitions and log spam when the same transition is fired twice).
- **`notify_mini_boss_defeated`** routed from boss kill handling (see implementation in repo).

### UI

- **`BetweenMissionScreen`** — **Mercenaries** tab: lists current offers, purchase hooks.

### SimBot (`res://scripts/sim_bot.gd`)

- `activate(strategy: Types.StrategyProfile)` — optional strategy for mercenary decisions.
- `decide_mercenaries()`, `get_log()`, `_on_mercenary_recruited`.

### Tests (GdUnit)

- `test_mercenary_offers.gd`, `test_mercenary_purchase.gd`, `test_campaign_ally_roster.gd`, `test_mini_boss_defection.gd`, `test_simbot_mercenaries.gd`
- Quick allowlist: **`./tools/run_gdunit_quick.sh`** includes the above plus core campaign/game manager suites.

---

## Verification

- [x] `./tools/run_gdunit_quick.sh` — **0 failures** (2026-03-25; 225 cases in allowlist run).
- [x] `./tools/run_gdunit.sh` — **0 failures** (2026-03-25; 398 cases; 12 orphans reported; log in **`reports/gdunit_full_run.log`**).

---

## Related docs

- **`docs/INDEX_SHORT.md`**, **`docs/INDEX_FULL.md`**, **`docs/INDEX_MACHINE.md`**, **`docs/INDEX_TASKS.md`** — Prompt 12 cross-links.
- **`docs/PROMPT_11_IMPLEMENTATION.md`** — ally baseline before mercenary layer.
- **`docs/PROMPT_10_IMPLEMENTATION.md`** — bosses / mini-boss combat baseline.
