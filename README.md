# Sunny Scout — Green Planet

A small Godot 4.6.3 prototype for Jeremy. Uses the Compatibility renderer and GDScript, with a painted Green Planet surface and illustrated Sunny Scout inspired by the approved mockups. The wide exploration camera is preserved. Surface art and character are AI-generated original project assets; ore, creature and underground art remain provisional. Walking uses a small bounce and horizontal facing flip, rather than a full directional animation sheet.

## Play

Import `project.godot` in Godot 4.6.3 and press **F6** with `main.tscn` open, or **F5** to play the project.

- **WASD / arrow keys:** move
- **E / Space / MINE button:** mine, use workbench, enter or leave mine
- **R:** restart

Collect five copper deposits (two hits each), return to the camp workbench for a stronger pick, then enter the Moss Mine at the northeast and mine a blue crystal. You can continue exploring after completing the mission. The painted pond blocks movement; decorative trees and rocks currently do not. No enemies, saving, sound, touch movement, or spaceflight yet.

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
