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
  ...other exported files...
  earth_chunks/   (6 JPG files)
  frost_chunks/   (6 JPG files)
  ember_chunks/   (6 JPG files)
```

The build contains 28 files in total. Replace the existing browser build as a complete set so the runtime and game data stay together.

Open https://www.digitalthing.com.au/jem/ in a desktop browser or on an iPad in Safari. On iPad, use landscape mode: drag the left pad to walk and tap the larger right-side action button to mine, cancel, upgrade or open the rocket. Tap **Fly here** to choose a world. Touch controls appear automatically. Refresh the page after uploading. This image should also open directly: https://www.digitalthing.com.au/jem/earth_chunks/pinewood.jpg

The build was exported using Godot 4.6.3 from gameplay source commit `29090bb`. It has been tested in a browser under `/jem/`, including walking into Pinewood Trail and downloading its scenery. Each surface area now contains just two common deposits; each mine contains one common and one rare deposit. There are 16 deposits per planet, about 73% fewer across the game. Explore multiple Earth districts to gather five copper for the drill. Interaction circles are hidden for doors, trails, camp, rocket and ore; location labels, action prompts and mining progress remain visible. Touch input is checked through native input tests and browser touch emulation, including two-finger actions and world selection; a physical iPad Safari playtest is still needed. No Godot installation is required to upload or play it. Progress lasts for the current play session.
