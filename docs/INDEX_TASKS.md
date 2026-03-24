# Project Index Build Tasks

This file breaks index generation into small, verifiable tasks so updates stay accurate.

## Task 1: Inventory scope and source of truth
- Confirm first-party scope: `autoloads/`, `scripts/`, `scenes/`, `ui/`.
- Exclude `addons/`, `MCPs/`, and `tests/` from per-script API sections.
- Use `project.godot` as source of truth for autoload registrations.

## Task 2: Build compact index (`INDEX_SHORT.md`)
- List autoloads (name -> path).
- List first-party script files.
- List scene files.
- List resource class scripts.
- List resource instances grouped by folder.

## Task 3: Build full index (`INDEX_FULL.md`)
- Add SignalBus registry with payload signatures.
- For each first-party script include:
  - path, class name, purpose,
  - public methods (non-underscore) with signatures and plain-English behavior,
  - exported variables and what they are used for,
  - signals emitted and emission conditions,
  - major dependencies.
- Add resource class field reference for all resource scripts under `scripts/resources/`.

## Task 4: Consistency pass
- Ensure every listed file still exists.
- Ensure method/signature names match current code.
- Ensure all autoload entries in `project.godot` are represented in `INDEX_SHORT.md`.

## Task 5: Ongoing maintenance rule
- Update `INDEX_SHORT.md` and `INDEX_FULL.md` whenever:
  - a new first-party script/scene/resource is added,
  - a public method is added/removed/renamed,
  - an `@export` variable is added/removed/renamed,
  - a SignalBus signal is added/removed/renamed,
  - autoload registration changes.

## Task Update Log (2026-03-24)
- Added `docs/PROMPT_1_IMPLEMENTATION.md` with concrete implementation notes.
- Updated indexes for new BuildMenu sell-mode API and BuildMode input routing changes:
  - `InputManager` now routes hex-slot clicks by occupancy.
  - `BuildMenu` now supports placement mode + sell mode entrypoints.
  - `HexGrid` slot click callback no longer opens menu directly.
- Added HexGrid sell-flow test cases and reflected them in index notes.
