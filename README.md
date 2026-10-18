# Sunny Scout — Green Planet

A small Godot 4.6.3 prototype for Jeremy. Uses the Compatibility renderer and GDScript, with original simple drawn artwork inspired by the approved orange explorer and wide exploration camera. The concept paintings are visual references, not in-game assets.

## Play

Import `project.godot` in Godot 4.6.3 and press **F6** with `main.tscn` open, or **F5** to play the project.

- **WASD / arrow keys:** move
- **E / Space / MINE button:** mine, use workbench, enter or leave mine
- **R:** restart

Collect five copper deposits (two hits each), return to the camp workbench for a stronger pick, then enter the Moss Mine at the northeast and mine a blue crystal. You can continue exploring after completing the mission. The pond blocks movement; decorative trees and rocks currently do not. No enemies, saving, sound, touch movement, or spaceflight yet.

## Browser build

Install the matching Godot 4.6.3 export templates. Export using the **Web** preset, or:

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Open the served page in a desktop browser. Web exports must be served over HTTP(S), rather than opened as a file. The export uses single-threaded WebAssembly and does not need cross-origin isolation headers. Hosting/public sharing is a separate step.

## Verify gameplay

```sh
godot --headless --path . --script tests/smoke.gd
```

The smoke test exercises copper collection, the upgrade purchase, mine entry, crystal completion and returning outdoors.
