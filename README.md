# Sunny Scout — browser testing build

This branch contains the complete browser build, including all scenery for Earth, Frost Canyon and Ember Dunes. The editable Godot project is on the `main` branch.

## Download

Use **Code → Download ZIP** on this branch, then unzip the download.

## Upload

Upload **everything inside `build/web/`** into your server's `/jem/` folder. Upload the files themselves and keep the three scenery folders together with them:

```text
jem/
  index.html
  index.js
  index.wasm
  index.pck
  scout-backdrop-*.jpg  (loading illustration)
  scout-logo-*.png      (Sunny Scout wordmark)
  ...other exported files...
  earth_chunks/   (6 JPG files)
  frost_chunks/   (6 JPG files)
  ember_chunks/   (6 JPG files)
```

The build contains 30 files in total. Replace the existing browser build as a complete set so the runtime and game data stay together.

Open https://www.digitalthing.com.au/jem/ in a desktop browser or on an iPad in Safari. On iPad, use landscape mode: drag the left pad to walk and tap the larger right-side action button to mine, cancel, upgrade or open the rocket. Tap **Fly here** to choose a world. Touch controls appear automatically. Hard-refresh the page after uploading the complete build. This image should also open directly: https://www.digitalthing.com.au/jem/earth_chunks/pinewood.jpg

The build was exported using Godot 4.6.3 from gameplay source commit `19dc016`. It has been tested in a browser under `/jem/`, including walking into Pinewood Trail and downloading its scenery. Each surface area now contains just two common deposits; each mine contains one common and one rare deposit. There are 16 deposits per planet, about 73% fewer across the game. Explore multiple Earth districts to gather five copper for the drill. Interaction circles are hidden for doors, trails, camp, rocket and ore; location labels, action prompts and mining progress remain visible. Touch input is checked through native input tests and browser touch emulation, including two-finger actions and world selection; a physical iPad Safari playtest is still needed. No Godot installation is required to upload or play it. Progress lasts for the current play session.

World labels now sit on illustrated wooden signs and mine beams, with fitted lettering and direction arrows. Each landing base has one small CAMP sign beside the camp artwork. Rockets are parked at camp and have no separate sign on any of the three worlds. Mine and trail signs retain their previous sizes; exits are marked SURFACE. All 24 maps were rendered in the browser for sign placement review.

Startup now uses an illustrated loading screen with real download progress and a retry button. A matching explorer guide explains keyboard or touch controls, finding five copper, building the drill, uncovering rare minerals and rocket travel. Choose Start exploring (or Enter / Space) to load Earth. Startup, gameplay and touch checks pass. Browser checks cover desktop/tablet startup, next-area streaming, rotation and failed-download recovery.

The loading and welcome artwork now fills the entire viewport on wide, tablet and portrait screens. Both screens use the same illustrated Sunny Scout logo, with Planet Adventures as a smaller, centred subtitle in matching gold lettering and a teal outline. The loader uses its own content-hashed artwork files and never requests the generic index.png splash, so an old cached Godot image cannot replace its background. Upload the two scout artwork files along with the rest of the build.

Earth now has 14 fish across all six ponds and mine pools, with two or three fish in larger ponds and independent swimming and occasional jumps. Six illustrated ducks wander and peck on dry banks beside the outdoor ponds. Willow Marsh, its connecting stream, Old Quarry and the mine pools share the starting pond's subtle water shimmer. Shoreline masks preserve bridges, lily pads and stone islands. Streamed wildlife is freed with its district; hidden home/mine wildlife pauses. Native wildlife and planetary streaming checks pass, and browser review covers every pool and the Willow stream.

Frost Canyon now has illustrated blue crystal Frostlings, and Ember Dunes has warm terracotta Dune Sprites: four per outdoor district and two in each off-world mine. Every Earth mine has two scurrying/sniffing rats and three flapping, hovering bats. Creatures wander and pause on local floor routes, keep clear of water/lava, doors and mineral deposits, and leave player movement unobstructed. Shared animation atlases serve all areas; streamed actors unload with their district. Native checks cover 67 creatures on 19 maps, animation, terrain/ore clearance, hidden pause and cleanup. Browser review covers every creature area and all four pose sets.

Ducks, mountain goats, Frostlings, Dune Sprites, rats and bats now have matching front and rear artwork as well as their side views. They turn with actual movement using Scout's stronger-axis rule, keep their last facing when stopped or blocked, and keep that view while pecking, grazing, sniffing or hovering. Four shared directional atlases use fitted ground anchors, consistent proportions and cached frame textures. Swimming fish already rotate with their heading. Native checks cover all six species at 30/120fps, distinct front/back frames, idle/feeding views and zero/blocked movement, plus the existing pond and all-area wildlife checks. Browser review covers walking and feeding/flapping in all four directions for each species, and the production loading/welcome screens and Earth startup.

Earth now has eight grazing farm animals: two sheep on Pinewood Trail, two cows in Willow Marsh, and three sheep plus one cow on Sunstone Ridge. All have front, rear and side walking/grazing artwork. Their grass routes avoid water, rocks, doors, trees and ore, and unload with their district. Buddy, the golden dog with a teal collar, starts in a random spot in Pinewood Trail, Willow Marsh, Sunstone Ridge or Old Quarry each new game; never Landing Meadow. Approach him to make friends automatically. He follows through Earth's districts and all three mines, catches up, then sits when Scout stops. His tail wags while walking and sitting, and a heart celebrates the first meeting. Buddy waits on Earth during rocket trips and rejoins Scout on return. Friendship lasts for the current game session. Native checks cover the herds across four ore layouts, safe companion routes around ponds/bridge and through all three mines, recruitment, sitting/wagging, menu pause, streamed transitions and rocket return. Existing movement, facing, mining, pond and Earth streaming checks pass. Browser review covers all three pastures, four-direction farm animal/dog animation, seated tail wag and discovery, plus the production loading/welcome screens and Earth startup.

Flower patches now stay on grass with clearance around their bases. Landing Meadow's flowers have been moved off dirt paths and rocks, with five unsuitable patches removed from the rocky bottom edge. Flowers in the streamed Earth districts choose nearby grass instead of a fixed tree offset. Placement checks the existing painting and floor boundaries once when an area loads, and omits a patch if no nearby grass fits. Pond reeds and cattails retain their shoreline positions. Native placement checks and browser review cover all five Earth areas; existing movement, mining, area travel and streaming checks pass.

Buddy now turns toward nearby revealed rats and bats in Earth mines and gives a short friendly double bark, with directional open-mouth poses, a small Woof bubble and an original cartoon bark sound. A 3.2-second cooldown prevents constant barking, and walls block his reaction. Critters scurry or fly away along safe floor routes, then disappear in a fading smoke puff; a blocked critter puffs away in place. Scared critters stay gone from that mine for the current game, including after scenery unloads. A new game resets them. Buddy's randomly chosen hiding spot stays fixed until found, including after revisits and rocket travel, and its selection loads no unvisited scenery. Native checks cover all three mines, escape/smoke cleanup, cooldowns, line of sight, session memory, 100 distinct dog starts across the four later Earth districts, normal following and existing wildlife/gameplay. Browser checks cover barking, running/flying, smoke and disappearance for both species in all three mines; WebAudio output was measured during the barks.
