# Context Brief — Session 7: Art Pipeline

## Art Pipeline (§22)

PLACEHOLDER SYSTEM EXISTS; PRODUCTION ART PLANNED

ArtPlaceholderHelper, RiggedVisualWiring, PlaceholderIconGenerator. All combat/hub scenes marked TODO(ART).

- ArtPlaceholderHelper resolves meshes by type enum and string ID. Production GLBs at correct paths auto-override placeholders.
- RiggedVisualWiring maps enemy types and allies to GLB paths under res://art/generated/. It mounts GLB scenes into visual slots and drives idle/walk animations via AnimationPlayer.

## TODO(ART) Markers in Codebase

| File | Line | What It Marks |
|------|------|---------------|
| scenes/allies/ally_base.gd | 206 | Placeholder visual for ally — replace with GLB |
| scenes/arnulf/arnulf.gd | 134 | ArnulfVisual placeholder — replace with production GLB |
| scenes/tower/tower.gd | 82 | Tower/Florence visual — replace with production model |
| scenes/bosses/boss_base.gd | 46 | BossVisual placeholder — replace with boss GLB |
| ui/hub.gd | 35 | Hub character portraits — replace with 2D art |

## Formally Cut Features (§31)

| Feature | Status |
|---------|--------|
| Arnulf drunkenness system | FORMALLY CUT — drunk_idle animation must be removed from requirements |
| Time Stop spell | FORMALLY CUT |
| Hades-style 3D navigable hub | FORMALLY CUT |

## EnemyType Enum (30 values — for animation table)

ORC_GRUNT(0), ORC_BRUTE(1), GOBLIN_FIREBUG(2), PLAGUE_ZOMBIE(3), ORC_ARCHER(4), BAT_SWARM(5), ORC_SKIRMISHER(6), ORC_RATLING(7), GOBLIN_RUNTS(8), HOUND(9), ORC_RAIDER(10), ORC_MARKSMAN(11), WAR_SHAMAN(12), PLAGUE_SHAMAN(13), TOTEM_CARRIER(14), HARPY_SCOUT(15), ORC_SHIELDBEARER(16), ORC_BERSERKER(17), ORC_SABOTEUR(18), HEXBREAKER(19), WYVERN_RIDER(20), BROOD_CARRIER(21), TROLL(22), IRONCLAD_CRUSHER(23), ORC_OGRE(24), WAR_BOAR(25), ORC_SKYTHROWER(26), WARLORDS_GUARD(27), ORCISH_SPIRIT(28), PLAGUE_HERALD(29).

## BuildingType Enum (36 values — for animation table)

ARROW_TOWER(0) through CITADEL_AURA(35). See uploaded types.gd for full list.

## Conventions
- Static typing on ALL parameters, returns, and variable declarations
- No magic numbers — all tuning in .tres resources or named constants
- All cross-system events through SignalBus
