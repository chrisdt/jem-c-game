# Sunny Scout — Snow Sprites & Frost Crystal equipment

The complete browser game, exported with Godot 4.6.3 from source commit `7f0f9822cdb328da9d736b4c84bb7b2107fbc9e2`. The editable project is on `main`.

## Upload

Unzip the download and upload **everything inside `build/web/`** to `/play/` on your website. Replace the complete set of **30 files**, preserving `earth_chunks/`, `frost_chunks/` and `ember_chunks/` (six JPGs each), plus both hashed loading-art files. Serve over HTTPS. Opening `index.html` directly as a local file will not run the game.

The intended site is https://playsunnyscout.com/play/. Publishing this branch does not upload to WP Engine.

## Frozen adventure

Fly to **Frost Canyon** using the working camp rocket and meet **Pip beside Canyon Camp's shelter**. Four Snow Sprites offer quests:

1. Pip: find beacon fragments in Frozen Basin, Prism Pass and Aurora Shelf; return to restore the trail lights.
2. Nix in Frozen Basin: bring the Earth sword, 4 frost ore, 1 amethyst and Blue Echo Mine's heart-crystal to forge **Frostfang**.
3. Tavi in Prism Pass: bring the hand drill, 5 frost ore, 2 amethysts and Deep Prism Mine's power coupling to fit the **Crystal Drill**.
4. Eira on Aurora Shelf: open Glacier Crown's frozen expedition cache, defeat its guardian yeti and return the keepsake.

Frostfang deals stronger directional jabs and briefly slows enemies. The Crystal Drill mines approximately 40% faster than the basic drill and opens the frozen cache. Both work with Sunny's spacesuit and Earth miner outfit, and remain upgraded when brought to other planets. The sword stays hidden while idle/walking. Equipment icons update in the existing slots.

The starter sword (3 copper + 2 wood) and hand drill (5 copper) can only be built at **Earth's workbench**. Built recipe cards disappear. Nix and Tavi provide the frozen upgrades through their own conversations; the frozen shelter does not show Earth's recipes.

Yeti encounters in the outer frozen districts warn before striking for **one and a half hearts**. Dodge the warning, then jab during recovery. Defeated yetis vanish in snowy puffs. Warm up beside the Canyon Camp shelter to recover hearts. Snow Sprites fade in with shadows, wave on approach and puff away after completing their quests.

The rocket remains available from the start. Nova's repair quest remains paused. Earth keeps its own quests, wildlife and exploration; Ember Dunes remains peaceful. No saving is added: progress lasts for the current open session, and reload or confirmed reset starts fresh. Playback stays silent.

## Controls

**WASD / arrows** walks. **E** talks, uses objects or opens the rocket. **E / Space** collects nearby ready items; with the mining tool selected, Space mines ore. Away from a ready interaction, **Space** attacks. **1** selects the mining tool; **2** selects the owned sword. **J / Quests** shows the current planet's expandable quest list. **R** asks before resetting. All six minerals and wood remain visible in the compact header on every planet.

On touch, use the movement pad, contextual action button and separate Attack/Jab button. The equipment bar remains available across planets. Tap Fly here to choose a rocket destination.

## Checked

Twelve integration checks cover the complete affordable frozen quest chain, both Earth story configurations, fresh rocket access, mission/mining persistence, combat, exact upgrade costs and cancellation, real upgraded Earth damage/mining, both outfits and all attack directions, dodging the warned 1.5-heart yeti strike, frozen cache progress, touch, flight, pickups and resets. The frozen route audit verifies all four Snow Sprites, quest objects and yeti approaches across five surfaces and three mines (23,640 connected floor samples), with bounded scenery loading.

Fourteen browser review views cover Snow Sprite dialogue/quests, equipment in both outfits, yeti presentation and the completed workbench, alongside a normal production startup/Earth browser check. No browser script or asset errors were reported. Review helpers are excluded from production. Complete build files and ZIP hashes are verified before publication.
