# SPDX-License-Identifier: MIT
"""
Foul Ward — per-unit description bank.

`run_pipeline` looks up `UNIT_DESCRIPTIONS[slug]` and injects it into the Stage 1
prompt so the operator only types `python foulward_gen.py "arnulf" allies ally`.

Source: characters.md manifest (kept in sync; edit here when adding new units).
Each value is the full natural-language description — keep multi-line strings.
"""

from __future__ import annotations

UNIT_DESCRIPTIONS: dict[str, str] = {
    # ── Allies ────────────────────────────────────────────────────────────
    "arnulf": (
        "Arnulf Falkenstein IV, burly middle-aged human warrior, 1.9m tall, slightly "
        "exaggerated proportions. Disheveled dirty black hair with grey streaks, slim face, "
        "caught in an angry grimace, moustache and beard in disarray, black eyes burning "
        "with anger. Worn mismatched plate armor with left pauldron missing, replaced by a "
        "leather strap and buckle, chainmail visible at all joints, right knee cop visibly "
        "cracked. Battered iron shovel strapped across back as primary weapon. Hip flask "
        "tucked into belt on left side, prominent and visible. Slightly unsteady wide-stance "
        "combat pose, proud expression despite everything."
    ),
    "florence": (
        "Florence, male human gunner, 1.75m, lean and practical build. Black plague doctor "
        "mask on his head. Wearing a practical long dark coat with many pockets, leather "
        "vambraces, sturdy boots. Primary weapon: a crossbow held at ready. Secondary weapon "
        "holstered at hip. Small potted black rose visible clipped to belt — his defining "
        "personal detail."
    ),
    "sybil": (
        "Sybil the Witch, female human spellcaster, 1.7m, slender and still. Long ginger hair "
        "tied back practically, unsettling calm expression that does not quite land as "
        "threatening — that is the joke. Very slim. Wearing layered grey-brown robes with "
        "geological samples (small rocks, crystals, fossils) hanging from a belt and tucked "
        "into pockets, over it there is a white dirty doctor's coat. Hands glowing faintly "
        "with earthy orange-brown magic. Staff carved from grey stone, not wood. Stationary "
        "casting pose, one hand raised."
    ),
    "mercenary_melee": (
        "Generic human mercenary soldier, 1.8m, stocky practical build. Mismatched chainmail "
        "and leather armor, round wooden shield with a simple painted symbol, short sword at "
        "hip. Closed visor kettle helm, sturdy boots, professional neutral combat-ready stance. "
        "No distinctive personal details — deliberately forgettable, a hired sword."
    ),
    "mercenary_ranged": (
        "Generic human mercenary archer, 1.75m, lean build. Light leather armor and hide "
        "cloak, short recurve bow in hand, quiver of arrows on back, simple leather hood. "
        "Alert slightly crouched stance, scanning forward. No helm, practical clothing only. "
        "Deliberately unremarkable — a hired pair of eyes and a bow."
    ),
    "anti_air_scout": (
        "Nimble human ranger, 1.7m, light quick build. Light leather armor with a mottled "
        "grey-brown hide cloak, short crossbow aimed upward at an angle, quiver on back, one "
        "hand shielding eyes scanning the sky upward. Alert crouched ready stance. Feathered "
        "leather hat, no heavy armor, speed over protection."
    ),
    "defected_orc_captain": (
        "Large orc warrior who has switched sides, 2.0m, powerful and composed. Dark green "
        "skin with old tribal war paint fading and partially scrubbed away. Wearing better-"
        "maintained plate armor than typical orc infantry, one tusk broken off, expression of "
        "grim loyalty replacing battle rage. Heavy iron sword held at rest at side, not "
        "raised. Muscular and still, the posture of a soldier following orders, not a "
        "berserker charging."
    ),
    # ── Orc Raiders ───────────────────────────────────────────────────────
    "orc_grunt": (
        "Orc Grunt infantry soldier, 1.85m, stocky and broad, hunched aggressive forward-"
        "leaning run posture. Crude dented iron helmet with two small cheek plates. Patchwork "
        "leather pauldrons with visible rough stitching. Linen wrapping on forearms. No boots, "
        "bare feet. Small jutting lower jaw tusks, scarred flat nose, deep-set yellow eyes, "
        "permanent scowl. Wide cleaver sword in right hand."
    ),
    "orc_brute": (
        "Orc Brute heavy infantry, 2.1m, twice the width of a grunt, slow and massive. Fully "
        "enclosed salvaged iron plate armor with mismatched riveted panels covering the entire "
        "body. Barrel chest, enormous spiked iron maul resting on right shoulder. Full-face "
        "helmet with narrow horizontal eye slits. Heavy stomping wide-legged stance. Same dark "
        "green skin as grunts visible only at neck joint."
    ),
    "orc_archer": (
        "Orc Archer ranged infantry, 1.75m, lean wiry build, lighter than grunt. Wearing only "
        "a leather vest and vambraces, no heavy armor. Recurve bow made of bone and sinew in "
        "hands. Quiver of crude arrows on back. One eye slightly squinting in aim, small tusks, "
        "pointed ears. Nimble slightly crouched alert stance, weight on back foot ready to "
        "reposition."
    ),
    "goblin_firebug": (
        "Goblin Firebug, 1.1m tall, small and manic. Bright orange-tinted skin, enormous ears, "
        "huge bulging eyes, wide unhinged grin showing all teeth. Scorched leather apron "
        "covering torso, thick padded gloves, four small fire flasks in a leather chest harness "
        "(two per side). Sputtering hand torch in right hand. Spindly limbs, hunched manic "
        "sprint posture, weight forward. Noticeably shorter and smaller than all orc units."
    ),
    "goblin_swarm": (
        "A mass of twenty tiny goblins clustered together as a single unit, 1.0m collective "
        "height. Each goblin is tiny, 0.6m, with green-grey skin, enormous ears, rags for "
        "clothing, wielding sticks, rocks, and broken bottles. The cluster is dense and "
        "chaotic, goblins at different heights clambering over each other, a frantic mob with "
        "too many limbs visible. Treated as one unit with one silhouette."
    ),
    "goblin_saboteur": (
        "Goblin Saboteur stealth unit, 1.0m, wiry and sneaky. Wearing a dark grey-brown cloak "
        "with hood up, face mostly hidden. Carrying a lit torch in one hand and a sack of "
        "materials in the other. Exaggerated tiptoe sneaking pose, looking over shoulder. "
        "Small — clearly designed to slip past notice rather than fight."
    ),
    "orc_berserker": (
        "Orc Berserker, 1.8m, lean and fast unlike the brute. Bare-chested, no armor. Red "
        "tribal war paint in thick stripes across face and torso. Dual short axes, one in each "
        "hand. Wild disheveled dark hair, screaming open-jaw expression. Mid-sprint dynamic "
        "forward lean. Leather kilt only, bone wrist cuffs. The posture of total abandon — "
        "speed and rage over self-preservation."
    ),
    "orc_shaman_boar_rider": (
        "Orc Shaman mounted on a large aggressive war boar, combined unit. The orc is 1.7m "
        "seated, wearing layered bone and hide shaman robes, wooden mask with carved runes, "
        "staff topped with skulls and feathers. The boar is 1.2m at shoulder, stocky and "
        "tusked with iron armor plates strapped to its flanks. The combined silhouette is "
        "wide and low, fast-looking, dangerous."
    ),
    "orc_siege_troll": (
        "Orc Siege Troll, 3.0m, massive grey-green skinned troll beast. Not an orc — a "
        "creature the orcs have chained and pointed at the enemy. Thick warty skin, tiny red "
        "eyes, enormous arms dragging slightly. Carrying a massive boulder in both hands, "
        "mid-wind-up throwing pose. Iron shackle collar with broken chain still attached. Too "
        "dumb to be frightened, too large to be stopped quickly."
    ),
    "orc_wolf_rider": (
        "Orc Wolf Rider cavalry unit. Lean orc 1.6m mounted on a massive dark grey dire wolf, "
        "1.4m at shoulder. The orc wears light leather cavalry armor, short lance in right "
        "hand, round shield on left arm. The wolf has iron spiked collar, scarred muzzle, "
        "powerful haunches in mid-gallop. Fast and low combined silhouette — built for speed "
        "and impact, not sustained fighting."
    ),
    "orc_warboss": (
        "Orc Warboss mini-boss commander, 2.4m, towering authority figure. Ornate mismatched "
        "plate armor with three skull trophies mounted on pauldrons, heavy fur-lined cloak, "
        "full-face war helm with swept-back iron horns. Enormous two-handed war axe with "
        "notched blade held raised in battle command. Heavy gold chain with a captured "
        "medallion around neck. Imposing wide-stance command pose — this is the one the other "
        "orcs follow."
    ),
    "orc_warchief": (
        "Orc Warchief campaign boss, 2.8m, the largest orc in existence. Elaborate ceremonial "
        "plate armor covered in tribal etchings and kill-count tally marks. Six skulls mounted "
        "on a back-banner frame rising behind shoulders. Enormous custom-forged greataxe, "
        "blade the size of a door. Multiple old scars visible on face and neck above the "
        "armor. Mid-monologue pose — one hand raised in dramatic speech, the other holding "
        "the axe. The joke is he talks too long."
    ),
    # ── Plague Cult ───────────────────────────────────────────────────────
    "plague_zombie": (
        "Plague Zombie undead humanoid, 1.7m, bloated and shambling. Rotting brown-grey "
        "desaturated skin with four to five large infection sores on neck and left arm. "
        "Tattered burial rags barely covering torso and legs. Left arm dragging lower than "
        "the right. Head tilted fifteen degrees to the right, slack open jaw, cloudy white "
        "unseeing eyes. Bare feet with exposed toe bones on right foot. Ribcage partially "
        "visible through torn rags on left side."
    ),
    "bat_swarm": (
        "Bat Swarm flying unit, treated as a single entity. Dense cluster of six oversized "
        "bats in tight formation. Each bat has a 40cm wingspan, leathery dark purple-black "
        "wings with ragged torn edges, small glowing red pinpoint eyes, open fanged mouths, "
        "long curved claws. Formation is dense and swirling, bats at different heights and "
        "angles suggesting constant movement. Total unit diameter approximately 1m sphere "
        "shape."
    ),
    "shambling_zombie": (
        "Shambling Zombie, 1.65m, slower and more decayed than the plague zombie. Ancient "
        "dried-out grey flesh over visible bones, burial clothing completely rotted to rags, "
        "arms outstretched in classic zombie pose, mouth open, empty dark eye sockets with "
        "no glow. No infection sores — this one is old death, not new plague. Slow deliberate "
        "trudging posture, feet dragging."
    ),
    "herald_of_worms": (
        "Herald of Worms plague cult priest mini-boss, 1.95m, tall and gaunt. Wearing six "
        "layers of tattered black and brown robes of descending lengths, each frayed "
        "differently. Face entirely hidden by an ornate long plague doctor beak mask with "
        "brass fittings and small dark glass eye lenses. Hands visible below sleeves — "
        "translucent pale skin with dark veins and worm-shaped lumps pressing outward from "
        "beneath. Gnarled wooden staff topped with a diseased green lantern emitting faint "
        "sickly light. Slow imposing slightly hunched standing pose."
    ),
    "archrot_incarnate": (
        "Archrot Incarnate final campaign boss, 3.5m tall, colossal plague entity. Body "
        "formed from six to eight fused plague zombie corpses — faces and limbs half-absorbed "
        "into the torso mass, hands and faces pressing outward from chest. Three arms: one "
        "enormous decayed right arm one and a half times normal size, knuckle dragging; two "
        "smaller skeletal arms on the left. Crown of five broken black iron antlers fused "
        "directly into skull. Ribcage cracked open at center, glowing green bioluminescent "
        "diseased light pouring out. Tattered burial cloth robes trailing 2m behind. Hunched "
        "forward with weight on massive right arm."
    ),
    # ── Buildings ─────────────────────────────────────────────────────────
    "arrow_tower": (
        "Compact medieval stone watchtower, two stories tall, cubic hex-tile footprint 3x3m. "
        "Arrow slits on all four sides of both floors. Wooden platform roof with a mounted "
        "crossbow mechanism on a rotating iron bracket. Ivy creeping up the base stones. "
        "Weathered grey stone throughout, iron bracket reinforcements at all four corners."
    ),
    "fire_brazier": (
        "Short iron pillar 1.5m tall topped with a wide iron bowl filled with roaring magical "
        "fire. Four elaborate chain supports holding the bowl from a central collar. Rune "
        "carvings along the pillar shaft glowing faintly orange. Scorched stone base platform. "
        "Orange and red flame with slight green hex-fire tinting at the core. Hex-tile "
        "footprint 3x3m."
    ),
    "magic_obelisk": (
        "Tall narrow obsidian spire, 3m tall, carved with glowing purple rune lines running "
        "from base to tip in continuous channels. A floating crystal shard orbiting slowly at "
        "the peak, small magical field visible as faint distortion around the top third. "
        "Ancient alien-feeling geometry but contextually medieval. Square footprint 3x3m, "
        "base wider than tip."
    ),
    "poison_vat": (
        "Wide iron cauldron 1.2m diameter mounted on a short stone pedestal, 1.0m total "
        "height. Bubbling green-yellow liquid visible at the rim, overflow stains running "
        "down the cauldron sides and pooling on the stone base. Thick wooden lid partially "
        "open at an angle. A bone stirring rod resting across the rim. Alchemical workshop "
        "aesthetic. Hex-tile footprint 3x3m."
    ),
    "ballista": (
        "Large wooden siege crossbow on a rotating iron mount, 2m tall assembly. Heavy iron "
        "bolt loaded and ready in the channel. Thick twisted rope tension mechanism visible "
        "at both sides. Iron-reinforced dark oak frame, battle-worn with notches. Fortified "
        "stone base platform with iron anchor bolts. Hex-tile footprint 3x3m."
    ),
    "archer_barracks": (
        "Small fortified military building, 2m tall, stone and dark wood construction. Arrow "
        "slits on all walls. Reinforced iron-banded door with a crossed-arrows emblem above "
        "the frame. A wooden target dummy with arrow holes visible beside the building. "
        "Compact military aesthetic, small chimney with faint smoke. Hex-tile footprint 3x3m."
    ),
    "anti_air_bolt_tower": (
        "Tall iron tripod frame 2.5m high supporting an upward-angled repeating bolt launcher "
        "mechanism with three barrels pointing skyward at different elevation angles. Gear and "
        "ratchet rotation mechanism visible at the base of the tripod. Ammunition box bolted "
        "to one leg. Functional industrial look — this is a machine, not architecture. Stone "
        "anchor base. Hex-tile footprint 3x3m."
    ),
    "shield_generator": (
        "Squat stone pedestal 1.0m tall with a large rotating arcane crystal mounted on top, "
        "emitting a visible faint dome of blue-white magical light extending slightly beyond "
        "the building footprint. Copper pipe fittings and coiled wire around the base "
        "connecting to the crystal mount. Subtle magical energy lines etched into the stone "
        "surface. Support device rather than weapon — calm steady glow. Hex-tile footprint "
        "3x3m."
    ),
    # ── Future factions ───────────────────────────────────────────────────
    # See characters.md SECTION 5–9 (skeleton_warrior, ghoul, banshee, ratkin_*,
    # thornling, cultist_zealot, frost_huscarl, etc.). Add entries here as those
    # rosters become priorities. The pipeline accepts unknown slugs by falling
    # back to the bare slug as the prompt — adding a description only improves
    # output quality.
}


def get_unit_description(slug: str) -> str | None:
    """Return the full natural-language description for a slug, or None."""
    return UNIT_DESCRIPTIONS.get(slug)
