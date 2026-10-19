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

The build was exported using Godot 4.6.3 from gameplay source commit `0a97e4f`. It has been tested in a browser under `/jem/`, including walking into Pinewood Trail and downloading its scenery. Each surface area now contains just two common deposits; each mine contains one common and one rare deposit. There are 16 deposits per planet, about 73% fewer across the game. Explore multiple Earth districts to gather five copper for the drill. Interaction circles are hidden for doors, trails, camp, rocket and ore; location labels, action prompts and mining progress remain visible. Touch input is checked through native input tests and browser touch emulation, including two-finger actions and world selection; a physical iPad Safari playtest is still needed. No Godot installation is required to upload or play it. Progress lasts for the current play session.

World labels now sit on illustrated wooden signs and mine beams, with fitted lettering and direction arrows. Camp, drill workbench and rocket labels use matching signposts; exits are marked SURFACE. All 24 maps were rendered in the browser for sign placement review.

Startup now uses an illustrated loading screen with real download progress and a retry button. A matching explorer guide explains keyboard or touch controls, finding five copper, building the drill, uncovering rare minerals and rocket travel. Choose Start exploring (or Enter / Space) to load Earth. Startup, gameplay and touch checks pass. Browser checks cover desktop/tablet startup, next-area streaming, rotation and failed-download recovery.

The loading and welcome artwork now fills the entire viewport on wide, tablet and portrait screens. Both screens use the same illustrated single-line Sunny Scout wordmark. The loader uses its own content-hashed artwork files and never requests the generic index.png splash, so an old cached Godot image cannot replace its background. Upload the two scout artwork files along with the rest of the build.
