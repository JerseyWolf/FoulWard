# PROMPT 65 — Phase 3: ProjectilePhysics.cs

Phase 3 complete: `ProjectilePhysics.cs` created. GDScript projectile `_physics_process` removed. 525 tests pass.

- Added `res://scripts/ProjectilePhysics.cs` — C# `Node` child with `_PhysicsProcess` driving movement, lifetime, hit scan via `Call("_on_hit", parent)`, range via `Call("_on_range_exceeded")`.
- `projectile_base.gd`: preload `CSharpScript`, `velocity` / `max_range` / `traveled_distance` bridge properties, `_on_hit` / `_on_range_exceeded`, `_ready()` adds child `ProjectilePhysics`.
- Tests: `test_projectile_system.gd`, `test_weapon_structural.gd` step physics via `ProjectilePhysics` node.
- `CREDITS.md`, `docs/INDEX_SHORT.md` updated.
