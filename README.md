# Sunny Scout — Sunstone Folk & Sunforge equipment

Complete browser game exported with Godot 4.6.3 from source commit `2b7ee3117838964be77cad67a197914d044d0215`. Editable project: `main`. Build release: `c5fd5a184439436b44f6`.

## Upload

Upload **everything inside `build/web/`** to `/play/` on your website. Replace the full set of **30 files**, preserving `earth_chunks/`, `frost_chunks/` and `ember_chunks/` (six JPGs each) and both hashed loading-art files. Serve over HTTPS. Opening `index.html` as a local file does not run the game.

Intended site: https://playsunnyscout.com/play/. Publishing this branch does not upload to WP Engine.

## Start the desert adventure

Use the camp rocket to fly to **Ember Dunes**, then meet **Sol beside Mesa Camp**. The four Sunstone Folk quests are:

1. **Sol — A Cool Welcome:** find three cooling parts in Dune Sea, Sunken Oasis and Redrock Arches. Return to repair the station; it heals and refills antidote.
2. **Luma — A Cure from the Oasis:** collect glowleaf in Sunken Oasis and Redrock Arches, plus the flask in Lava Mine beneath Mesa Camp. Earn a three-dose antidote canteen.
3. **Brasa — Fire up the Sunforge:** find the core in Sunfire Cavern beneath Dune Sea. Bring an owned Earth sword, **3 gold + 1 fire ruby** for the **Sunfang Sword**, then a hand drill, **4 gold + 1 fire ruby** for the **Magma Drill**. Talk once for each upgrade. Completed recipes disappear.
4. **Orin — The Buried Observatory:** use the Magma Drill to open cooled lava in Obsidian Rise, defeat the guardian scorpion and return the ancient star map to Orin in Redrock Arches.

There are enough real deposits for both upgrades: 13 gold and 3 fire rubies across the five surfaces and three mines. Unique quest objects can be collected early. Frost equipment helps but is optional. The rocket remains usable from the start and no quest blocks planet travel.

Alien scorpions have front/back/side movement, raised-tail/claw warnings and sandy defeat puffs. Dodge during the warning, then jab during recovery. A sting deals **1.5 hearts**, with venom taking another **half heart after 3 seconds**. Claws deal one heart without venom. Venom does not stack; menus, help and travel pause its countdown. Camp shade clears it. After earning the canteen, press **3** or tap its new icon to cure venom; Sol's repaired cooler refills all three doses. Healthy players cannot waste antidote.

Sunfang deals 10 damage (Frostfang 7, reinforced sword 5, copper sword 3). The Magma Drill reduces base mining time by 55%: Earth copper 0.9s / blue crystal 4.05s; off-world common 1.35s / rare 4.5s. Both upgrades work in the Earth miner outfit and spacesuit on every planet. Lower tier rewards cannot downgrade them. The sword stays hidden between jabs.

## Existing adventures and controls

Earth and Frost Canyon keep separate quests, wildlife and exploration. Starter sword (3 copper + 2 wood) and hand drill (5 copper) are only crafted at Earth's workbench; built cards disappear. Frost Canyon's four Snow Sprites still offer beacon, Frostfang, Crystal Drill and expedition quests. Nova's rocket repair quest remains paused.

**WASD / arrows** walks. **E** talks or opens the rocket. **E / Space** gathers ready objects; Space mines with the mining tool selected. Away from ready interactions, **Space** attacks. **1** selects the tool, **2** the owned sword, **3** uses earned antidote. **J / Quests** opens the current world's expandable quest list. **R** asks before resetting. Materials and equipment stay visible across planets. On touch, use the movement pad, action/attack buttons and equipment icons.

No saving or sound is added. Progress lasts while this game remains open. Reload or confirmed reset starts fresh.

## Validation

Fourteen native integration checks cover the complete affordable Sunstone and Snow Sprite quest chains, both Earth story configurations, exact one-time recipes/cancellation, both outfits/all attack directions, imported Earth damage/mining, venom timing/pause/cure/recovery, touch controls, flight, pickups and resets. Route audits cover all desert and frozen quest locations across each world's five surfaces and three mines, retaining the bounded three-map scenery cache.

The production browser build was checked through welcome/startup, Earth and its quest popup. Chromium artwork review covers directional scorpions, venom HUD, Sunforge equipment in both outfits, touch layout and Sunstone Folk. Browser review helpers are excluded from production. The complete 30-file build and archive hashes are verified.
