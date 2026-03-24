# FOUL WARD — PRE_GENERATION_VERIFICATION.md

**Verification** — a short pre-flight list before large refactors, new systems, or AI codegen.

**Specification** (full signal tables, paths, physics, GdUnit setup, resource stubs): **`docs/PRE_GENERATION_SPECIFICATION.md`**.

---

## 1. Autoloads

Open `project.godot` → `[autoload]` and confirm order and names match **`docs/ARCHITECTURE.md` §1**.

The specification’s §3.1 table is the **historical four-autoload core**; the live project also registers `CampaignManager`, `EnchantmentManager`, `AutoTestDriver`, and plugin-related autoloads. See **`PRE_GENERATION_SPECIFICATION.md` §3.1** NOTE.

## 2. Scene tree and paths

Open `res://scenes/main.tscn` and confirm structure matches **`ARCHITECTURE.md` §2** (`Managers`, `EnemyContainer`, `SpawnPoints`, etc.).

Cross-check hardcoded `/root/Main/...` assumptions against **`PRE_GENERATION_SPECIFICATION.md` §2**.

## 3. Signals

All cross-system signals go through **`SignalBus`** only, with payloads per **`CONVENTIONS.md` §5**.

Compare inventory to **`PRE_GENERATION_SPECIFICATION.md` §1** when adding or renaming signals.

## 4. GdUnit

From repo root run **`./tools/run_gdunit.sh`** (or the headless command in **`docs/CURRENT_STATUS.md`**). All tests under `res://tests/` should pass before merging architecture-sensitive changes.

## 5. Data and simulation API

Gameplay values belong in **resources** (`.tres` + Resource scripts), not hardcoded in gameplay logic — **`CONVENTIONS.md`**. Managers stay controllable via **public methods** without UI (`ARCHITECTURE.md` / simulation API).

## Deviations

If the repo diverges from the spec on purpose, mark **`# DEVIATION`** in code and note it in the relevant design or prompt doc.

## Related docs

| Doc | Role |
|-----|------|
| **`docs/PRE_GENERATION_SPECIFICATION.md`** | Full reference tables and stubs |
| **`docs/ARCHITECTURE.md`** | Current scene tree, autoloads, responsibilities |
| **`docs/CONVENTIONS.md`** | Naming, SignalBus law, layers |
| **`docs/CURRENT_STATUS.md`** | Godot/GdUnit CLI notes |
