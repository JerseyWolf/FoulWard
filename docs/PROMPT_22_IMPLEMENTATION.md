# Prompt 22 — Relationship / affinity system (Audit 6 §5.1)

**Date:** 2026-03-28

## Done

- **Resources:** `RelationshipTierConfig`, `CharacterRelationshipData`, `RelationshipEventData` under `res://scripts/resources/`.
- **Data:** `res://resources/relationship_tier_config.tres`; per-character `res://resources/character_relationship/*.tres` (Florence, hub cast IDs, `arnulf`, `WEAPONS_ENGINEER`, `defected_orc_captain` at −20); events `res://resources/relationship_events/on_{mission_won,mission_failed,boss_killed}.tres`.
- **Autoload:** `res://autoloads/relationship_manager.gd` registered **after** `CampaignManager` in `project.godot`. **Note:** no `class_name RelationshipManager` — matches `CampaignManager` pattern; a `class_name` would shadow the autoload singleton (GdUnit tests would see `Nil`; `class_name TestRelationshipManager` also shadowed the autoload).
- **Signals:** connects via lambdas (not `Callable.bind`) so `mission_won(int)` does not mismatch typed slots.
- **DialogueManager:** `DialogueCondition.condition_type == "relationship_tier"` with `character_id`, `required_tier`; warm tiers (Neutral+) use “at least this friendly”; Hostile/Cold use “at most this cold” so Allied does not satisfy Hostile-only lines.
- **Tests:** `res://tests/test_relationship_manager.gd` (`class_name TestRelationshipManagerGdUnit`).
- **SimBot test:** `test_csv_rows_deterministic_for_same_seed` uses a **unique** CSV path per run + `RelationshipManager.reload_from_resources()` to avoid stale `user://` rows from full-suite order.

## GdUnit

- `./tools/run_gdunit.sh`: **506** cases, **0** failures (exit **101** warnings treated as pass per script).
- `./tools/run_gdunit_quick.sh`: allowlist includes `test_relationship_manager.gd`.
