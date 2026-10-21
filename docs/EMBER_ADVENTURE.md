# Ember Dunes playtest

Fly to **Ember Dunes** and meet **Sol beside Mesa Camp**. The rocket remains
available from the start; no desert quest restricts travel. Earth and Frost
Canyon retain their separate quest lists.

| Sunstone Folk | Quest | Where to explore / reward |
| --- | --- | --- |
| Sol, Mesa Camp | A Cool Welcome | Find three cooling parts in Dune Sea, Sunken Oasis and Redrock Arches. The repaired camp station restores half a heart every 1.5 seconds and refills antidote. |
| Luma, Sunken Oasis | A Cure from the Oasis | Collect glowleaf from Sunken Oasis and Redrock Arches, and the flask from Mesa Camp's Lava Mine. Earn a three-dose antidote canteen. |
| Brasa, Dune Sea | Fire up the Sunforge | Recover the core in Sunfire Cavern. Bring an owned sword, **3 gold + 1 fire ruby** for Sunfang, and a hand drill, **4 gold + 1 fire ruby** for the Magma Drill. Talk once for each upgrade. |
| Orin, Redrock Arches | The Buried Observatory | Use the Magma Drill to break cooled lava in Obsidian Rise, defeat its guardian scorpion and return the ancient star map. |

All four quests can be accepted and handed in independently when their actual
requirements are met. Orin needs the Magma Drill, but does not wait for Brasa's
sword upgrade. Unique items can be collected early and
are never consumed by cancelling a conversation. Brasa's completed recipe stops
appearing; his quest finishes when both tools are built. The five surfaces and
three mines provide **13 gold and 3 fire rubies**, covering the combined **7 gold
and 2 fire ruby** cost without repeat harvesting. Starter equipment still comes
only from Earth's workbench. Frost upgrades help here but are not required.

## Equipment and combat

Sunfang deals **10 damage** per directional jab (copper 3, reinforced 5,
Frostfang 7). The Magma Drill reduces base mining time by 55%: common deposits
**0.9 seconds** and blue crystal **4.05 seconds** on Earth; off-world common ore takes **1.35 seconds** and rare gems **4.5 seconds**. Both keep their ruby treatment
in Sunny's Earth miner clothes and spacesuit, including walk/mining poses and
front/back/side attacks. The sword remains hidden between jabs. Lower tier
upgrades obtained later cannot replace the stronger Sunforge stats or artwork.

Alien scorpions patrol Dune Sea, Sunken Oasis and Obsidian Rise. Regular
scorpions have 22 health; the observatory guardian has 30. They have front,
back and side poses, distance-driven walk frames, a warning, attack recovery,
contact shadows, exploration fade and a sandy defeat puff. A raised tail warns
for **0.95 seconds** before a sting; claws warn for **0.65 seconds**. Attacks aim
at the position where the warning began: move away, then jab during recovery.

A sting deals **1.5 hearts**, then venom removes **another half heart after
3 seconds**. Claws deal **1 heart** without venom. Venom does not stack or
refresh an active timer. Quest/dialogue/help menus, transitions and flights
pause the timer. A green heart tint and countdown show the condition.

After Luma's quest, press **3** or tap the third hotbar icon to use antidote.
It cures the pending venom tick without changing the selected weapon. A dose
cannot be wasted when healthy. The icon appears only after earning the canteen;
its tooltip shows doses remaining. The repaired Mesa Camp cooler refills all
three doses. Camp shade on any planet clears venom even before that repair.
Defeat returns Sunny safely with collected materials and clears venom.

## Scope and checks

No saving or audio is added. Progress lasts while the current game remains open;
reload or confirmed reset starts fresh. NPCs fade in, wave, have grounded shadows
and puff away after their quests. Scorpions, props and small session records use
the existing area lifecycle; the background loader stays bounded to three maps.

Run `tests/ember_story.gd` with Godot headless for the complete playable quest
chain, actual resource gathering, exact one-time costs/cancellation, all attack
directions in both outfits, imported Earth damage/mining, venom timing and
modal pause, touch antidote, refill/recovery, independent journals, travel and
reset. `tests/ember_routes.gd` checks all quest locations and enemy approaches
across five surfaces and three mines (24,035 connected floor samples).

`tools/build_sunforge_atlas.py` measures alpha silhouettes and foot anchors
without repainting source artwork. It needs Pillow, NumPy and SciPy. Runtime
uses the generated `assets/sunforge/atlas.json`; Web exports include that JSON
and the three compressed illustration sheets. No browser review hooks ship in
the production build.
