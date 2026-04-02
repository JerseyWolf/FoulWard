# DIAG-1: Campaign Day Ownership

Date: 2026-03-31

## Finding

**PATTERN B** (soft encapsulation violation on specific paths), with **PATTERN D** nuance (two different “day” concepts in `GameManager`).

**Summary:** The normal mission-win path is **not** `GameManager` bypassing `CampaignManager`’s logic: `CampaignManager` owns the calendar increment inside its own `mission_won` handler. The compliance concern is valid for **narrow paths** where `GameManager` assigns to `CampaignManager.current_day` directly (`advance_to_next_day`, `current_day_index` setter) instead of calling a dedicated `CampaignManager` method.

---

## Evidence

### Direct writes to `CampaignManager.current_day` from `GameManager`

- `advance_to_next_day()` — `CampaignManager.current_day += 1` (see `autoloads/game_manager.gd` around line 306).
- Property `current_day_index` setter — `CampaignManager.current_day = value` (see `autoloads/game_manager.gd` around lines 253–257).

`CampaignManager` exposes `current_day` as a **public** `var` (not a private `_current_day` field), so this is **not** a “private field poke”; it is still **direct mutation of another autoload’s state** without a named API method.

### Mission-win increment ownership

`CampaignManager._on_mission_won` validates the payload and performs `current_day += 1` (and related updates) in `autoloads/campaign_manager.gd` (see lines 646–672). `GameManager._on_all_waves_cleared` **does not** increment `CampaignManager.current_day` before emitting; it emits `SignalBus.mission_won.emit(CampaignManager.get_current_day())` with the **pre-increment** day (argument evaluated before listeners run).

### Separate Florence meta day

`GameManager` also maintains **`GameManager.current_day`** for Florence meta (`advance_day` / `_apply_pending_day_advance_if_any`), documented as independent from the campaign calendar (`autoloads/game_manager.gd` lines 31–32, 205–245). That is intentional split responsibility, not a duplicate increment on `CampaignManager`.

---

## Day-Advance Call Chain (mission win)

1. **Wave completion:** `WaveManager` (or equivalent) leads to `SignalBus.all_waves_cleared`.
2. **GameManager** `GameManager._on_all_waves_cleared()` runs (connected in `GameManager._ready`).
3. Territory rewards, economy, boss flags, Florence `advance_day` + `_apply_pending_day_advance_if_any()` (updates **`GameManager.current_day`** only, not `CampaignManager`).
4. **`SignalBus.mission_won.emit(CampaignManager.get_current_day())`** — payload is the **completed** campaign day index (evaluated before step 5).
5. **Listeners run in Godot `SignalBus` connection order** (order of `connect` calls):
   - **`CampaignManager._on_mission_won(mission_number)`** runs first (connected in `CampaignManager._ready`, autoload #6).
   - **`GameManager._on_mission_won_transition_to_hub(mission_number)`** runs next (connected in `GameManager._ready`, autoload #9; comment at lines 59–60 documents intent).
   - Later autoloads (e.g. `CombatStatsTracker`, `DialogueManager`, …) run after, per their `_ready` connection order.
6. **Inside `CampaignManager._on_mission_won`:** if `_has_active_campaign_run` and `mission_number == current_day`, then `failed_attempts_on_current_day = 0`, `day_won` emitted, then **`current_day += 1`** (non-endless path), `current_day_config` refreshed, `generate_offers_for_day`, or campaign completion / endless branch as coded.
7. **Inside `GameManager._on_mission_won_transition_to_hub`:** hub / `GAME_WON` transition using **`mission_number`** (still the **completed** day from step 4), while `CampaignManager.current_day` is already **next** day after step 6.

---

## Init order and `mission_won` ordering

- **`project.godot`** lists `CampaignManager` before `GameManager` in `[autoload]`, so `CampaignManager._ready` runs before `GameManager._ready`.
- **Listener order** for `mission_won` is therefore **deterministic** as long as no code disconnects/reorders connections: `CampaignManager` connects first, then `GameManager`’s hub transition.

This is **not** enforced by the type system; it **is** enforced in practice by **stable autoload order + `_ready` connect order**. Changing connect order or emitting `mission_won` before `CampaignManager` is connected could break the documented assumption.

---

## Answers to Q1–Q5

| Q | Answer |
|---|--------|
| **Q1** | **YES.** Direct property assignment: `CampaignManager.current_day = value` (`current_day_index` setter) and `CampaignManager.current_day += 1` (`advance_to_next_day`). Exact locations: `autoloads/game_manager.gd` ~252–257 and ~305–307. |
| **Q2** | **YES.** Examples: `CampaignManager.start_new_campaign()`, `CampaignManager.start_next_day()` (via `GameManager.start_next_mission`), `get_current_day()`, `get_campaign_length()`, `get_current_day_config()`, reads of `is_endless_mode`, `campaign_config`, `current_ally_roster`, `set_active_campaign_config_for_test`, `notify_mini_boss_defeated`. |
| **Q3** | **NO** for a single `mission_won` emission in the normal win path: only `CampaignManager._on_mission_won` increments **`CampaignManager.current_day`**. `GameManager` does not also increment `CampaignManager.current_day` in `_on_all_waves_cleared`. (Florence’s `GameManager.current_day` is a separate counter.) |
| **Q4** | **YES** in edge cases: `CampaignManager._on_mission_won` returns early if `not _has_active_campaign_run` or `mission_number != current_day` (e.g. tests or callers emitting the wrong payload). Then **zero** calendar increment occurs for that emission. |
| **Q5** | **YES** for normal gameplay: payload is `CampaignManager.get_current_day()` at emit time, matching `current_day`; tests cover progression (`tests/test_campaign_autoload_and_day_flow.gd`, `tests/test_game_manager.gd`). Hub transition runs **after** `CampaignManager` increments, matching the comment in `GameManager._ready`. |

---

## Recommendation

Treat **mission-win day advancement** as **intentional `CampaignManager` ownership** via `SignalBus.mission_won`; document that **`GameManager`’s hub listener must stay after `CampaignManager`’s** in connection order. For **`advance_to_next_day` / `current_day_index`**, prefer a **small refactor**: add a **`CampaignManager` public method** (e.g. calendar bump for boss-repeat / test) and have `GameManager` call that instead of assigning to `CampaignManager.current_day` directly — **low risk**, improves encapsulation.

---

## Impact on Fix Session I5

**Keep I5 scoped** to the **AllyData / typed access** work unless a session explicitly schedules **day-ownership cleanup**. The finding here is **documentation + optional narrow API wrap**, not a correctness emergency for normal `mission_won` flow.
