---
name: signal-bus
description: >-
  Activate when working with signals in Foul Ward: emitting, connecting,
  declaring, or verifying signals. Use when: SignalBus, emit, connect,
  signal payload, cross-system communication, add new signal, signal reference,
  signal naming, signal table, is_connected guard, typed signal parameters.
compatibility: Godot 4.4 GDScript. Foul Ward project only.
---

# Signal Bus — Foul Ward

---

## The Rule

SignalBus (`autoloads/signal_bus.gd`) is declarations only.
- NO logic
- NO state (no variables)
- NO methods

All cross-system signals declared here. Local signals (within one scene tree)
may live on the emitting node directly.

---

## When local signals are acceptable

Use **local** `signal` declarations on a node when **only** that node’s own
children (or the same scene subtree) connect — e.g. a panel’s internal
`pressed` / custom UI-only signals.

Do **not** keep lifecycle or phase signals on an autoload as “local” if
**other** scenes (HUD, menus under `/root/Main/UI`) connect to them. Those
listeners are cross-system; declare the signals on `SignalBus` and emit with
`SignalBus.<signal>.emit()` (see `build_phase_started` / `combat_phase_started`).

Cross-system phase **state** is still reflected by `game_state_changed` on
`SignalBus`; phase start/end signals are an additional, explicit hook for UI.

---

## How to Add a New Signal (6 steps)

1. Declare in `autoloads/signal_bus.gd` — past tense, typed payload
2. Emit at the correct point: `SignalBus.your_signal.emit(args)`
3. Connect with guard: `if not SignalBus.x.is_connected(fn): SignalBus.x.connect(fn)`
4. Add to signal table in `docs/INDEX_FULL.md`
5. Update `docs/PROMPT_[N]_IMPLEMENTATION.md`
6. Write a test using `monitor_signals` + `assert_signal`

---

## Signal Naming Convention

- Events (something happened): **past tense** — `enemy_killed`, `wave_cleared`, `building_placed`
- Requests (something is being asked): **present tense** — `build_requested`, `sell_requested`
- NEVER future tense
- Always fully typed payload

---

## The `is_connected` Guard Pattern

Always use when a connect might be called more than once:

```gdscript
if not SignalBus.wave_cleared.is_connected(_on_wave_cleared):
    SignalBus.wave_cleared.connect(_on_wave_cleared)
```

---

## Emit Pattern

```gdscript
# Correct typed emit
SignalBus.enemy_killed.emit(enemy_data, global_position, enemy_data.gold_reward)

# Never emit with wrong types or missing args
```

---

## Signal Testing Pattern

```gdscript
func test_gold_awarded_on_enemy_killed() -> void:
    var monitor := monitor_signals(SignalBus)
    EconomyManager.reset_to_defaults()
    SignalBus.enemy_killed.emit(mock_enemy_data, Vector3.ZERO, 25)
    await assert_signal(monitor).is_emitted("resource_changed")
```

---

## When to Read the Signal Table

Read `references/signal-table.md` when:
- Checking whether a signal already exists before declaring a new one
- Verifying the exact parameter types of a signal you're connecting to
- Looking up which category a signal belongs to
- Auditing signal coverage for a system

---

`references/signal-table.md` is maintained to mirror `autoloads/signal_bus.gd` (65 signals as of 2026-03-31). Prefer the `.gd` file when adding or changing signals.
