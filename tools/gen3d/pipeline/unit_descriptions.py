# SPDX-License-Identifier: MIT
"""
Foul Ward — per-unit description bank.

`run_pipeline` looks up `UNIT_DESCRIPTIONS[slug]` and injects it into the Stage 1
prompt so the operator only types `python foulward_gen.py "arnulf" allies ally`.

Source: characters.md manifest (kept in sync; edit here when adding new units).
Each value is the full natural-language description — keep multi-line strings.

POSTURE RULES (do not deviate — required for clean TRELLIS mesh reconstruction):
- All bipeds: A-pose, arms down and slightly away from body at 40 degrees,
  both arms fully visible, both hands visible and EMPTY, no held weapons or items.
- Feet shoulder-width apart, toes forward, weight evenly distributed, both feet
  flat on the ground at the same level.
- Mounted units: rider seated upright, both hands resting on thighs, empty.
  Mount standing squarely on all four legs.
- No action poses, no combat poses, no mid-motion descriptions.
- Weapons are generated separately and attached via BoneAttachment3D in Godot.
"""

from __future__ import annotations

UNIT_DESCRIPTIONS: dict[str, str] = {

    # ── Allies ────────────────────────────────────────────────────────────

    "arnulf": (
        "Arnulf Falkenstein IV, burly middle-aged human warrior, 1.9 m tall, slightly "
        "exaggerated proportions, large hands, broad shoulders. Disheveled dirty black hair "
        "with grey streaks, slim face, angry grimace permanently etched into expression, "
        "moustache and beard in disarray, black eyes. Worn mismatched plate armor: left "
        "pauldron missing, replaced by a leather strap and buckle; chainmail visible at all "
        "joints; right knee cop visibly cracked and repaired with wire. Hip flask tucked into "
        "belt on left side, prominent and clearly visible. Empty hands, no weapons held. "
        "A-pose, arms held down and slightly away from body at 40 degrees. Standing straight, "
        "feet shoulder-width apart, toes pointing forward, weight evenly distributed, both "
        "feet flat on ground at the same level. Clear silhouette separation between arms and "
        "torso."
    ),

    "florence": (
        "Florence, male human gunner, 1.75 m tall, lean and practical build. Black plague "
        "doctor mask pushed up on his head like a hat, not covering the face. Wearing a "
        "practical long dark coat with many pockets, leather vambraces, sturdy boots. Small "
        "potted black rose clipped to belt on left side — his defining personal detail. Empty "
        "hands, no weapons held. A-pose, arms held down and slightly away from body at 40 "
        "degrees. Standing straight, feet shoulder-width apart, toes pointing forward, weight "
        "evenly distributed, both feet flat on ground at the same level. Clear silhouette "
        "separation between arms and torso."
    ),

    "sybil": (
        "Sybil the Witch, female human spellcaster, 1.7 m tall, slender and still. Long "
        "ginger hair tied back practically. Unsettling calm expression that does not quite "
        "land as threatening — that is the joke. Very slim build. Wearing layered grey-brown "
        "robes with geological samples (small rocks, crystals, fossils) hanging from a belt "
        "and tucked into pockets; over the robes a white dirty doctor's coat. Hands hang "
        "naturally empty at sides, no staff held. A-pose, arms held down and slightly away "
        "from body at 40 degrees. Standing straight, feet shoulder-width apart, toes pointing "
        "forward, weight evenly distributed, both feet flat on ground at the same level. "
        "Clear silhouette separation between arms and torso."
    ),

    "mercenary_melee": (
        "Generic human mercenary soldier, 1.8 m tall, stocky practical build. Mismatched "
        "chainmail and leather armor. Round wooden shield strapped to back, not held. Short "
        "sword sheathed at hip, not drawn. Closed visor kettle helm, sturdy boots. "
        "Deliberately unremarkable appearance — a hired sword with no personal details. Empty "
        "hands. A-pose, arms held down and slightly away from body at 40 degrees. Standing "
        "straight, feet shoulder-width apart, toes pointing forward, weight evenly "
        "distributed, both feet flat on ground at the same level. Clear silhouette separation "
        "between arms and torso."
    ),

    "mercenary_ranged": (
        "Generic human mercenary archer, 1.75 m tall, lean build. Light leather armor and "
        "hide cloak. Quiver of arrows strapped to back. Simple leather hood, no helm. "
        "Deliberately unremarkable — a hired pair of eyes and nothing more. Empty hands, no "
        "bow held. A-pose, arms held down and slightly away from body at 40 degrees. Standing "
        "straight, feet shoulder-width apart, toes pointing forward, weight evenly "
        "distributed, both feet flat on ground at the same level. Clear silhouette separation "
        "between arms and torso."
    ),

    "anti_air_scout": (
        "Nimble human ranger, 1.7 m tall, light quick build. Light leather armor with a "
        "mottled grey-brown hide cloak. Quiver strapped to back. Feathered leather hat, no "
        "heavy armor — speed over protection. Empty hands, no crossbow held. A-pose, arms "
        "held down and slightly away from body at 40 degrees. Standing straight, feet "
        "shoulder-width apart, toes pointing forward, weight evenly distributed, both feet "
        "flat on ground at the same level. Clear silhouette separation between arms and "
        "torso."
    ),

    "defected_orc_captain": (
        "Large orc warrior who has switched sides, 2.0 m tall, powerful and composed. Dark "
        "green skin with old tribal war paint fading and partially scrubbed away — loyalty "
        "changed, not completed. Better-maintained plate armor than typical orc infantry. One "
        "tusk broken off. Expression of grim composed loyalty replacing battle rage. Empty "
        "hands, no weapons held, arms relaxed at sides. A-pose, arms held down and slightly "
        "away from body at 40 degrees. Standing straight, feet shoulder-width apart, toes "
        "pointing forward, weight evenly distributed, both feet flat on ground at the same "
        "level. Clear silhouette separation between arms and torso."
    ),

    # ── Orc Raiders ───────────────────────────────────────────────────────

    "orc_grunt": (
        "Orc Grunt infantry soldier, 1.85 m tall, stocky and broad. Crude dented iron helmet "
        "with two small cheek plates. Patchwork leather pauldrons with visible rough "
        "stitching. Linen wrapping on forearms. No boots, bare feet. Small jutting lower jaw "
        "tusks, scarred flat nose, deep-set yellow eyes, permanent scowl. Empty hands, no "
        "weapons held. A-pose, arms held down and slightly away from body at 40 degrees. "
        "Standing straight, feet shoulder-width apart, toes pointing forward, weight evenly "
        "distributed, both bare feet flat on ground at the same level. Clear silhouette "
        "separation between arms and torso."
    ),

    "orc_brute": (
        "Orc Brute heavy infantry, 2.1 m tall, twice the width of a grunt, massive and slow. "
        "Fully enclosed salvaged iron plate armor with mismatched riveted panels covering the "
        "entire body. Barrel chest. Full-face helmet with narrow horizontal eye slits. Heavy "
        "wide-legged stance. Dark green skin visible only at the neck joint between helmet "
        "and gorget. Empty hands, no weapons held. A-pose, arms held down and slightly away "
        "from body at 40 degrees. Standing straight, feet shoulder-width apart, toes pointing "
        "forward, weight evenly distributed, both feet flat on ground at the same level. "
        "Clear silhouette separation between arms and torso."
    ),

    "orc_archer": (
        "Orc Archer ranged infantry, 1.75 m tall, lean wiry build, lighter than a grunt. "
        "Leather vest and vambraces only, no heavy armor. Quiver of crude arrows strapped to "
        "back. One eye slightly smaller than the other, small tusks, pointed ears. Empty "
        "hands, no bow held. A-pose, arms held down and slightly away from body at 40 "
        "degrees. Standing straight, feet shoulder-width apart, toes pointing forward, weight "
        "evenly distributed, both feet flat on ground at the same level. Clear silhouette "
        "separation between arms and torso."
    ),

    "goblin_firebug": (
        "Goblin Firebug, 1.1 m tall, small and manic build. Bright orange-tinted green skin, "
        "enormous ears, huge bulging eyes, wide unhinged grin showing all teeth. Scorched "
        "leather apron covering torso, thick padded gloves on both hands. Four small fire "
        "flasks in a leather chest harness, two per side. Spindly limbs. Empty hands, "
        "nothing held. A-pose, arms held down and slightly away from body at 40 degrees. "
        "Standing straight, feet shoulder-width apart, toes pointing forward, weight evenly "
        "distributed, both feet flat on ground at the same level. Noticeably shorter and "
        "smaller than all orc units. Clear silhouette separation between arms and torso."
    ),

    "goblin_swarm": (
        "A mass of twenty tiny goblins clustered together as a single unit, approximately "
        "1.0 m collective height. Each individual goblin is 0.6 m tall with green-grey skin, "
        "enormous ears, rags for clothing. The cluster is dense and chaotic, goblins at "
        "different heights packed tightly together, a frantic mob forming one single "
        "silhouette approximately 1.5 m wide. All limbs visible but entangled. Treated as "
        "one mesh with one cohesive base. White background, front view, right side view, "
        "back view."
    ),

    "goblin_saboteur": (
        "Goblin Saboteur stealth unit, 1.0 m tall, wiry and small. Wearing a dark grey-brown "
        "hooded cloak with hood up, face mostly hidden in shadow. A sack of materials "
        "strapped to back. Small — clearly built to slip past notice rather than fight. Empty "
        "hands, nothing held. A-pose, arms held down and slightly away from body at 40 "
        "degrees. Standing straight, feet shoulder-width apart, toes pointing forward, weight "
        "evenly distributed, both feet flat on ground at the same level. Clear silhouette "
        "separation between arms and torso."
    ),

    "orc_berserker": (
        "Orc Berserker, 1.8 m tall, lean and fast unlike the brute. Bare-chested, no armor. "
        "Red tribal war paint in thick stripes across face and torso. Disheveled dark hair. "
        "Leather kilt only, bone wrist cuffs. Muscular lean build, visible abs and arm "
        "definition. Empty hands, no axes held. A-pose, arms held down and slightly away "
        "from body at 40 degrees. Standing straight, feet shoulder-width apart, toes pointing "
        "forward, weight evenly distributed, both feet flat on ground at the same level. "
        "Clear silhouette separation between arms and torso."
    ),

    "orc_shaman_boar_rider": (
        "Orc Shaman mounted on a large war boar, combined unit. The orc rider is 1.7 m "
        "seated upright, wearing layered bone and hide shaman robes, wooden mask with carved "
        "runes. Both rider hands resting open and empty on thighs. The boar is 1.2 m at "
        "shoulder, stocky and tusked, iron armor plates strapped to its flanks. The boar "
        "standing squarely on all four legs, head level, mouth closed. Combined silhouette "
        "is wide and low. White background, front view, right side view, back view."
    ),

    "orc_siege_troll": (
        "Orc Siege Troll, 3.0 m tall, massive grey-green skinned troll creature. Not an "
        "orc — a creature the orcs have chained. Thick warty skin, tiny red eyes, enormous "
        "arms, hunched but upright posture. Iron shackle collar with broken chain still "
        "attached to neck. Empty hands, both arms hanging at sides. A-pose variant: arms "
        "held down and slightly away from body at 40 degrees, both massive hands open and "
        "empty. Standing straight, feet shoulder-width apart, toes pointing forward, weight "
        "evenly distributed, both feet flat on ground at the same level."
    ),

    "orc_wolf_rider": (
        "Orc Wolf Rider cavalry unit. Lean orc 1.6 m seated upright on a massive dark grey "
        "dire wolf, 1.4 m at shoulder. The orc wears light leather cavalry armor, round "
        "shield strapped to back not held, both hands resting open and empty on thighs. The "
        "dire wolf has an iron spiked collar, scarred muzzle, powerful haunches, standing "
        "squarely on all four legs, head level, mouth closed. Fast low combined silhouette. "
        "White background, front view, right side view, back view."
    ),

    "orc_warboss": (
        "Orc Warboss mini-boss commander, 2.4 m tall, towering authority figure. Ornate "
        "mismatched plate armor with three skull trophies mounted on pauldrons, heavy "
        "fur-lined cloak draped over both shoulders. Full-face war helm with swept-back iron "
        "horns. Heavy gold chain with a captured human medallion around neck. Empty hands, "
        "no weapons held, arms at sides. A-pose, arms held down and slightly away from body "
        "at 40 degrees. Standing straight, feet shoulder-width apart, toes pointing forward, "
        "weight evenly distributed, both feet flat on ground at the same level. Clear "
        "silhouette separation between arms and torso."
    ),

    "orc_warchief": (
        "Orc Warchief campaign boss, 2.8 m tall, the largest orc in existence. Elaborate "
        "ceremonial plate armor covered in tribal etchings and tally marks. Six skulls "
        "mounted on a back-banner frame rising above the shoulders. Multiple old scars "
        "visible on face and neck above the armor line. Empty hands, no weapons held. "
        "A-pose, arms held down and slightly away from body at 40 degrees. Standing "
        "straight, feet shoulder-width apart, toes pointing forward, weight evenly "
        "distributed, both feet flat on ground at the same level. Clear silhouette "
        "separation between arms and torso."
    ),

    # ── Plague Cult ───────────────────────────────────────────────────────

    "plague_zombie": (
        "Plague Zombie undead humanoid, 1.7 m tall, bloated and decayed. Rotting brown-grey "
        "desaturated skin with four to five large infection sores on neck and left arm. "
        "Tattered burial rags barely covering torso and legs. Left arm slightly lower than "
        "right due to bloating asymmetry. Head tilted fifteen degrees to the right, slack "
        "open jaw, cloudy white unseeing eyes. Bare feet with exposed toe bones visible on "
        "right foot. Ribcage partially visible through torn rags on left side. Empty hands. "
        "A-pose, arms held down and slightly away from body at 40 degrees. Standing, feet "
        "shoulder-width apart, both feet flat on ground at the same level."
    ),

    "bat_swarm": (
        "Bat Swarm flying unit, treated as a single entity. Dense cluster of six oversized "
        "bats in tight spherical formation, total diameter approximately 1 m. Each bat has a "
        "40 cm wingspan, leathery dark purple-black wings with ragged torn edges, small "
        "glowing red pinpoint eyes, open fanged mouths, long curved claws. Bats at different "
        "heights and angles within the cluster suggesting constant movement. Formation posed "
        "as a hovering sphere. White background, front view, right side view, back view."
    ),

    "shambling_zombie": (
        "Shambling Zombie, 1.65 m tall, more decayed than the plague zombie. Ancient "
        "dried-out grey flesh over partially visible bones. Burial clothing completely rotted "
        "to rags. Empty dark eye sockets with no glow — old death, not new plague infection. "
        "Empty hands. A-pose, arms held down and slightly away from body at 40 degrees. "
        "Standing, feet shoulder-width apart, both feet flat on ground at the same level. "
        "Slow deliberate posture, slightly bent at knees, but feet still flat and planted."
    ),

    "herald_of_worms": (
        "Herald of Worms plague cult priest mini-boss, 1.95 m tall, gaunt and towering. "
        "Wearing six layers of tattered black and brown robes of descending lengths, each "
        "frayed differently. Face entirely hidden by an ornate long plague doctor beak mask "
        "with brass fittings and small dark glass eye lenses. Hands visible below sleeves: "
        "translucent pale skin, dark veins, worm-shaped lumps pressing outward from beneath "
        "the skin. No staff held, hands empty and hanging at sides. A-pose, arms held down "
        "and slightly away from body at 40 degrees. Standing straight, feet shoulder-width "
        "apart, toes pointing forward, weight evenly distributed, both feet flat on ground "
        "at the same level. Clear silhouette separation between the layered robes."
    ),

    "archrot_incarnate": (
        "Archrot Incarnate final campaign boss, 3.5 m tall, colossal plague entity. Body "
        "formed from six to eight fused plague zombie corpses — faces and limbs half-absorbed "
        "into the torso mass, additional hands and faces pressing outward from the chest "
        "surface. Three distinct arms: one enormous decayed right arm one and a half times "
        "normal size; two smaller skeletal arms on the left side. Crown of five broken black "
        "iron antlers fused directly into the skull. Ribcage cracked open at center with "
        "glowing green bioluminescent diseased light visible inside. Tattered burial cloth "
        "robes trailing behind. All three arms held in A-pose, down and slightly away from "
        "body at 40 degrees, all hands empty. Standing, feet shoulder-width apart, both feet "
        "flat on ground at the same level."
    ),

    # ── Buildings ─────────────────────────────────────────────────────────

    "arrow_tower": (
        "Compact medieval stone watchtower, two stories tall, square hex-tile footprint "
        "approximately 3x3 m. Arrow slits on all four sides of both floors. Wooden platform "
        "roof with an empty mounted crossbow bracket on a rotating iron mount — no bolt "
        "loaded, bracket visible as a mechanical fixture. Ivy creeping up the base stones. "
        "Weathered grey stone throughout, iron bracket reinforcements at all four corners. "
        "Static object, no character, no figures."
    ),

    "fire_brazier": (
        "Short iron pillar 1.5 m tall topped with a wide iron bowl. Four elaborate chain "
        "supports holding the bowl from a central collar. Rune carvings along the pillar "
        "shaft glowing faintly orange. Scorched stone base platform. The bowl is empty and "
        "cold in this reference — show the bowl geometry clearly without fire obscuring it. "
        "Hex-tile footprint 3x3 m. Static object, no character, no figures."
    ),

    "magic_obelisk": (
        "Tall narrow obsidian spire, 3 m tall, carved with glowing purple rune lines running "
        "from base to tip in continuous channels. A floating crystal shard positioned at the "
        "peak. Ancient alien-feeling geometry in a medieval context. Square footprint 3x3 m, "
        "base wider than tip, tapering to a point. Static object, no character, no figures."
    ),

    "poison_vat": (
        "Wide iron cauldron 1.2 m diameter mounted on a short stone pedestal, 1.0 m total "
        "height. Overflow stains running down the cauldron sides and pooling on the stone "
        "base. Thick wooden lid partially open at an angle, resting ajar. A bone stirring "
        "rod resting across the rim. Alchemical workshop aesthetic. Hex-tile footprint 3x3 m. "
        "Static object, no character, no figures."
    ),

    "ballista": (
        "Large wooden siege crossbow on a rotating iron mount, 2 m tall total assembly. "
        "Channel empty, no bolt loaded — show the mechanism clearly. Thick twisted rope "
        "tension mechanism visible at both sides. Iron-reinforced dark oak frame, "
        "battle-worn with notches. Fortified stone base platform with iron anchor bolts. "
        "Hex-tile footprint 3x3 m. Static object, no character, no figures."
    ),

    "archer_barracks": (
        "Small fortified military building, 2 m tall, stone and dark wood construction. "
        "Arrow slits on all walls. Reinforced iron-banded door with a crossed-arrows emblem "
        "carved above the frame. A wooden target dummy with arrow holes beside the building. "
        "Small chimney with no smoke. Compact military aesthetic. Hex-tile footprint 3x3 m. "
        "Static object, no character, no figures."
    ),

    "anti_air_bolt_tower": (
        "Tall iron tripod frame 2.5 m high supporting an upward-angled repeating bolt "
        "launcher mechanism with three barrels pointing skyward at different elevation "
        "angles. Gear and ratchet rotation mechanism at the base of the tripod. Ammunition "
        "box bolted to one leg. Functional industrial look — a machine, not architecture. "
        "Stone anchor base. Hex-tile footprint 3x3 m. Static object, no character, no "
        "figures."
    ),

    "shield_generator": (
        "Squat stone pedestal 1.0 m tall with a large arcane crystal mounted on top. Copper "
        "pipe fittings and coiled wire around the base connecting to the crystal mount. "
        "Subtle magical energy lines etched into the stone surface. Support device rather "
        "than weapon — calm, geometric, no fire or dramatic effects. Hex-tile footprint 3x3 "
        "m. Static object, no character, no figures."
    ),

    # ── Weapons (generated separately, attached via BoneAttachment3D in Godot) ──

    "weapon_iron_shovel": (
        "A single battered iron shovel, 1.5 m total length. Wooden haft with worn leather "
        "grip wrapping near the top. Iron blade showing dents, chips, and repair marks — "
        "clearly used as a weapon not a tool. No character holding it, no hands visible. "
        "Object only, displayed vertically centered on white background, front view and "
        "side view."
    ),

    "weapon_crossbow": (
        "A practical military crossbow, 0.7 m wide when measured across the arms. Dark wood "
        "stock, iron prod arms, hemp string. Loaded bolt channel empty. Iron stirrup at "
        "front. Battle-worn but maintained. No character holding it, no hands visible. "
        "Object only, displayed on white background, front view and side view."
    ),

    "weapon_stone_staff": (
        "A staff carved entirely from a single piece of grey stone, 1.6 m tall. Irregular "
        "natural surface texture with angular carved grip markings near the center. Slightly "
        "tapered at both ends. Heavy-looking despite being a casting implement. No character "
        "holding it. Object only, displayed vertically on white background, front view and "
        "side view."
    ),

    "weapon_iron_cleaver": (
        "A crude wide iron cleaver sword, 0.65 m blade length. Thick spine, wide flat blade "
        "with a single rough edge, visible hammer marks from forging. Simple iron crossguard, "
        "wrapped leather grip. Notches in the blade edge from use. No character holding it. "
        "Object only, displayed on white background, front view and side view."
    ),

    "weapon_iron_maul": (
        "An enormous spiked iron maul, 1.4 m total length. Massive cylindrical iron head "
        "with six blunt iron spikes around the circumference. Thick iron-banded wooden haft. "
        "Extremely heavy-looking. No character holding it. Object only, displayed vertically "
        "on white background, front view and side view."
    ),

    "weapon_skull_staff": (
        "A shaman's staff 1.5 m tall topped with two animal skulls and three hanging bone "
        "fetishes tied with leather cord. Gnarled dark wood haft with carved rune marks. "
        "Feathers and teeth tied near the top. No character holding it. Object only, "
        "displayed vertically on white background, front view and side view."
    ),

    "weapon_bone_recurve_bow": (
        "A recurve bow made from bone and sinew, 1.1 m tall when undrawn. Pale off-white "
        "bone limbs with sinew lashing at joints, hemp bowstring. Crude but functional. No "
        "character holding it. Object only, displayed vertically on white background, front "
        "view and side view."
    ),

    "weapon_dual_axes": (
        "A matched pair of short throwing axes, each 0.45 m long. Iron heads with a single "
        "spike opposite the blade, leather-wrapped wooden hafts. Identical pair shown side "
        "by side. Battle-worn. No character holding them. Object only, displayed on white "
        "background, front view."
    ),
}


def get_unit_description(slug: str) -> str | None:
    """Return the full natural-language description for a slug, or None."""
    return UNIT_DESCRIPTIONS.get(slug)