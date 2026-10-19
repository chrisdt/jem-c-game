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

The build was exported using Godot 4.6.3 from gameplay source commit `ed19033`. It has been tested in a browser under `/jem/`, including walking into Pinewood Trail and downloading its scenery. Each surface area now contains just two common deposits; each mine contains one common and one rare deposit. There are 16 deposits per planet, about 73% fewer across the game. Explore multiple Earth districts to gather five copper for the drill. Interaction circles are hidden for doors, trails, camp, rocket and ore; location labels, action prompts and mining progress remain visible. Touch input is checked through native input tests and browser touch emulation, including two-finger actions and world selection; a physical iPad Safari playtest is still needed. No Godot installation is required to upload or play it. Progress lasts for the current play session.

World labels now sit on illustrated wooden signs and mine beams, with fitted lettering and direction arrows. Each landing base has one small CAMP sign beside the camp artwork. Rockets are parked at camp and have no separate sign on any of the three worlds. Mine and trail signs retain their previous sizes; exits are marked SURFACE. All 24 maps were rendered in the browser for sign placement review.

Startup now uses an illustrated loading screen with real download progress and a retry button. A matching explorer guide explains keyboard or touch controls, finding five copper, building the drill, uncovering rare minerals and rocket travel. Choose Start exploring (or Enter / Space) to load Earth. Startup, gameplay and touch checks pass. Browser checks cover desktop/tablet startup, next-area streaming, rotation and failed-download recovery.

The loading and welcome artwork now fills the entire viewport on wide, tablet and portrait screens. Both screens use the same illustrated Sunny Scout logo, with Planet Adventures as a smaller, centred subtitle in matching gold lettering and a teal outline. The loader uses its own content-hashed artwork files and never requests the generic index.png splash, so an old cached Godot image cannot replace its background. Upload the two scout artwork files along with the rest of the build.

Earth now has 14 fish across all six ponds and mine pools, with two or three fish in larger ponds and independent swimming and occasional jumps. Six illustrated ducks wander and peck on dry banks beside the outdoor ponds. Willow Marsh, its connecting stream, Old Quarry and the mine pools share the starting pond's subtle water shimmer. Shoreline masks preserve bridges, lily pads and stone islands. Streamed wildlife is freed with its district; hidden home/mine wildlife pauses. Native wildlife and planetary streaming checks pass, and browser review covers every pool and the Willow stream.

Frost Canyon now has illustrated blue crystal Frostlings, and Ember Dunes has warm terracotta Dune Sprites: four per outdoor district and two in each off-world mine. Every Earth mine has two scurrying/sniffing rats and three flapping, hovering bats. Creatures wander and pause on local floor routes, keep clear of water/lava, doors and mineral deposits, and leave player movement unobstructed. Shared animation atlases serve all areas; streamed actors unload with their district. Native checks cover 67 creatures on 19 maps, animation, terrain/ore clearance, hidden pause and cleanup. Browser review covers every creature area and all four pose sets.

Ducks, mountain goats, Frostlings, Dune Sprites, rats and bats now have matching front and rear artwork as well as their side views. They turn with actual movement using Scout's stronger-axis rule, keep their last facing when stopped or blocked, and keep that view while pecking, grazing, sniffing or hovering. Four shared directional atlases use fitted ground anchors, consistent proportions and cached frame textures. Swimming fish already rotate with their heading. Native checks cover all six species at 30/120fps, distinct front/back frames, idle/feeding views and zero/blocked movement, plus the existing pond and all-area wildlife checks. Browser review covers walking and feeding/flapping in all four directions for each species, and the production loading/welcome screens and Earth startup.
