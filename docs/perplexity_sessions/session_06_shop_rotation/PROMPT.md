# Session 6: Shop Rotation & Economy Tuning

## Goal
Design the shop inventory rotation system (different items available each day) and tune SimBot strategy profile difficulty_target values. The master doc TBD asks: "How many items shown per day?" — this session decides.

## Source excerpts (inside this document)
The following paths are summarized here; **full file contents** appear later in this document under the **`FILES:`** heading (each path is repeated there with its complete text).
- `shop_manager.gd` — ShopManager scene-bound manager; current shop logic
- `shop_item_data.gd` — ShopItemData resource class definition
- `economy_manager.gd` — EconomyManager autoload; lines 1-50 covering constants and currency fields
- `shop_catalog.tres` — Current static shop catalog (4 items)
- `strategy_balanced_default.tres` — SimBot balanced strategy profile
- `strategy_greedy_econ.tres` — SimBot greedy economy profile
- `strategy_heavy_fire.tres` — SimBot heavy fire profile
- `strategyprofile.gd` — StrategyProfile resource class definition

## Context Brief
Later in this document, under the heading **`CONTEXT_BRIEF:`**, you will find the relevant excerpts from the project's master documentation. Read that block fully before proceeding.

## Constraints
- Godot 4.4, GDScript primary, C# for performance-critical paths only
- All signals go through SignalBus (autoloads/signal_bus.gd) — never direct connections between managers
- Enums live in types.gd with integer values — C# mirror in FoulWardTypes.cs must stay aligned
- No class_name on autoloads
- Tests use GdUnit4 framework
- See the **CONTEXT_BRIEF:** section in this document for full conventions

## Task
Produce an implementation spec for: shop inventory rotation and SimBot profile tuning.

The spec must include:
1. Every file to create or modify, with exact path
2. For modified files: exact method signatures to add/change, with parameter types and return types
3. For new files: complete resource schema or class structure
4. New signals to add to signal_bus.gd (if any), with exact signature
5. New enum values to add to types.gd (if any), with integer assignments
6. Test cases to write — file name, test method names, what each asserts
7. Any .tres resource files to create or modify, with field values

DESIGN DECISION: Show 4-6 items per day from a larger pool of 12-15 total items.

REQUIREMENTS:

Part A — Shop Rotation:
1. Design 12-15 ShopItemData entries organized into categories: consumables (instant effects), equipment (persistent buffs for the mission), and vouchers (free building placements).
2. Include the existing 4 items plus: building_material_pack (gain 10 BM), research_boost (gain 3 RM), tower_armor_plate (+50 tower max HP for mission), fire_oil_flask (next 5 projectiles deal bonus fire damage), scout_report (reveal next wave composition), mercenary_discount (reduce next merc cost by 20%), emergency_repair (restore 25% tower HP mid-combat).
3. Design the rotation algorithm: seed with day_index for determinism. Always include at least 1 consumable and 1 equipment. Exclude items the player has already stacked to max (cap 5 per consumable).
4. Add to ShopManager: a get_daily_items(day_index: int) method that returns Array[ShopItemData].
5. Add ShopItemData fields: category (String: "consumable", "equipment", "voucher"), max_stack (int, default 5), rarity_weight (float, default 1.0).
6. Provide the complete .tres specification for each new item.

Part B — SimBot Profile Tuning:
1. Set difficulty_target for each profile: BALANCED_DEFAULT: 0.5, GREEDY_ECON: 0.3, HEAVY_FIRE: 0.7.
2. Provide exact .tres field values for each profile.

Format as a numbered task list as prompts that a Cursor's agent would be able to perform in separate chat sessions first using 'plan' and then 'agent' mode. Please prepare them to fit the newly discussed "caveman" prompting method to save tokens but still be able to perform all the tasks correctly. You also have access to FOUL_WARD_MASTER_DOC, but it shouldn't be necessary for your work. Use it only if you believe you are missing some information that you require. Please ask any and all questions if you are uncertain of something.
