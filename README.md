# Sunny Scout — browser testing build

This branch contains the complete playable browser build for Earth, Frost Canyon and Ember Dunes. The editable Godot project is on `main`. Exported with Godot 4.6.3 from source commit `b1f54c9`.

## Download and upload

Use **Code → Download ZIP**, then unzip it. Upload **everything inside `build/web/`** into your server's `/jem/` folder. Replace the complete set of 30 files, keeping all three scenery folders:

```text
jem/
  index.html
  index.js
  index.wasm
  index.pck
  scout-backdrop-*.jpg
  scout-logo-*.png
  ...other exported files...
  earth_chunks/   (6 JPG files)
  frost_chunks/   (6 JPG files)
  ember_chunks/   (6 JPG files)
```

Then open https://www.digitalthing.com.au/jem/ and hard-refresh. No Godot installation is needed to upload or play. Use landscape mode on an iPad. This image should also open directly after upload: https://www.digitalthing.com.au/jem/earth_chunks/pinewood.jpg

## Earth adventure

- Start with a pick and a locked sword. Explore the five Earth districts for copper and six illustrated fallen branches/logs. **E** or the contextual touch action gathers wood.
- Open the **Camp workbench** to craft a **copper sword for 3 copper + 2 wood**, and a **hand drill for 5 copper**, in either order. Crafted equipment and completed mission checks persist after spending ingredients.
- **1** selects the pick/fitted drill; **2** selects the crafted sword. **Space** mines a nearby revealed deposit when the mining tool is selected, and cancels an active attempt. Away from ore it attacks. With the sword selected, Space jabs. **E** can also start/cancel mining, open camp and use the rocket. Touch has separate movement, equipment, contextual action and Attack/Jab controls.
- Eleven small snakes roam Earth's surface districts. Its three mines each have two hostile rats and three hostile bats. All warn before attacking for half a heart. Sword hits deal three damage; pick/drill hits deal one. Snakes have nine health, rats six and bats three. Defeat uses a silent smoke puff. Buddy still interrupts and scares mine foes away.
- Only Earth has snakes, wood, two apple trees and two berry bushes. Landing Meadow has one bush and no fruit tree. Berries heal one heart and apples two; full health preserves fruit. The other planets keep their friendly alien wildlife and existing mining loop.
- Camp, trail mouths and mine arrivals are safe. Losing all hearts restores Scout at a safe arrival while retaining resources and crafted equipment. Collected wood, picked fruit, partially hurt enemies and defeated/scared enemies remain remembered during the session and through area unloading.
- **R** asks before resetting, with No selected by default. Closing/reloading starts fresh; there is no disk saving. The game is silent.

The build retains the illustrated viewport-filling loading screen and welcome guide, fitted wooden signs, exploration mist, sparse random minerals, animated water and wildlife, Buddy's random hiding spot/following/sitting/barking, rocket travel and streamed scenery. It does not download unvisited maps for the new Earth systems; only active-area actors and small session records are retained.

## Validation

Native checks cover real resource gathering and randomized wood availability, exact one-time recipes, lasting missions, directional attacks, walls/terrain, safe arrivals, warned damage/recovery, persistent enemy damage/removal, Buddy's scare interruption, Earth-only food/enemies, mining timing and E/Space cross-cancellation, drill gates, touch crafting, reset, startup and planet travel. Browser review covers the actual rendered workbench purchases and wood pickup, Space mining, Pinewood sword attacks, hostile rat/bat warning/damage/smoke in all three mines, off-world exclusion and two-finger tablet crafting. The final production build passes normal welcome/start, locked sword, camp and Pinewood streaming under `/jem/`, with desktop and tablet emulation and no script/download errors. A physical iPad Safari playtest is still needed.
