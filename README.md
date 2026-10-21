# Sunny Scout — Painted Earth mines

The complete browser game, exported with Godot 4.6.3 from source commit `2df21e567e3bc3d2a21be69fa2bdaa29bfb4b2d2`. The editable Godot project is on `main`.

## Upload

Unzip the download and upload **everything inside `build/web/`** to your website's game folder, such as `/play/`. Replace the complete set of **30 files**, preserving `earth_chunks/`, `frost_chunks/` and `ember_chunks/` (six JPGs each), plus the two hashed loading illustration/logo files. Serve over HTTPS. Opening `index.html` directly as a local file will not run the game.

The intended site is https://playsunnyscout.com/play/. Publishing this branch does not upload it to WP Engine.

## Painted mine backgrounds

- Moss Mine, Copper Hollow and Crystal Depths now have their permanently closed doorways painted directly into the existing background images.
- The 32 timber closures follow their own frames' perspective and lantern lighting. Five natural rail workings in Moss Mine have integrated rubble.
- The old separate boarding renderer is removed; no floating board or rockfall overlays are used for these decorative closures.
- All three usable surface exits remain open. Source image dimensions and every pixel outside the local doorway edit areas are preserved, keeping the established map layout and walking boundaries aligned.
- The initial pack contains Moss Mine; Copper Hollow and Crystal Depths retain their normal on-demand scenery loading. Upload the revised scenery JPGs as well as `index.pck` and `index.html`.

Other worlds and Earth quest props, including Otis's removable quarry rockfall, keep their existing behavior.

## Play

**WASD / arrows** walks. **E / Space** picks up nearby revealed wood and ready quest objects with either weapon. Space stays an attack while a snake guards an object. With no ready pickup, **Space** attacks with the sword or mines nearby ore with the mining tool. Select the mining tool to drill quest objects; **E** talks and uses the camp workbench/rocket. **1** selects the mining tool, **2** selects the owned sword. **J / Quests** opens the expandable quest list. **R** asks before resetting.

On touch, use the movement pad and the contextual action button; the separate Attack/Jab button remains available. The game is silent. Progress lasts for the current session; persistent saves are not part of this update.

## Earth's adventure

Talk to Rowan at camp, craft a sword for **3 copper + 2 wood**, and follow the seven quests through Bea, Otis, Mara, Iris, Finn and Nova. The hand drill costs **5 copper**. Repair the rocket and spacesuit to unlock travel. The Quests popup keeps instructions and completion state. Earth characters fade in with their shadows, give a short greeting wave, then puff away when their quests are complete. Sparse minerals, exploration mist, Buddy, wildlife, healing plants and mining progress remain available.

## Checked

Artwork checks verify all 37 local edits, original image sizes, the unchanged usable exits and exact preservation of all pixels outside the edit areas. The runtime overlay is absent. The Earth audit walks 30 routes both ways, checks all eight areas and 48 doorway/trail approaches. Automatic mine transitions, the complete quest chain and 200 expanded-Earth resource layouts with bounded scenery loading also pass. Eleven full-game browser views cover every mine overview and representative doorway/rubble/waterside close-ups, with no script or asset errors.
