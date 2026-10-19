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

Open https://www.digitalthing.com.au/jem/ in a desktop browser. Refresh the page after uploading. This image should also open directly: https://www.digitalthing.com.au/jem/earth_chunks/pinewood.jpg

The build was exported using Godot 4.6.3 from gameplay source commit `5e8f2b4`. It has been tested in a browser under `/jem/`, including walking into Pinewood Trail and downloading its scenery. Each surface area now contains just two common deposits; each mine contains one common and one rare deposit. There are 16 deposits per planet, about 73% fewer across the game. Explore multiple Earth districts to gather five copper for the drill. No Godot installation is required to upload or play it. Progress lasts for the current play session.
