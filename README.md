# Sunny Scout — Green Planet

A small Godot 4.6.3 prototype for Jeremy. Uses the Compatibility renderer and GDScript, with a painted Green Planet surface and illustrated Sunny Scout inspired by the approved mockups. The wide exploration camera is preserved. Surface art, copper and blue ore deposits, and character are AI-generated original project assets. Copper and blue crystal share illustrated rough stone, with orange-red copper veins or bright blue mineral veins. The Moss Mine has a painted cavern map with timber supports, lanterns, moss, side chambers and an underground pool. `mine_layout.gd` traces its walkable floor and blocks walls, pillars and water. Creature art remains provisional. Walking uses a four-pose illustrated cycle with alternating arms and legs. The pick is carried on the backpack while walking. Animation advances with distance travelled and returns to a standing pose when stopped or blocked. Front, rear and side walk/idle artwork follows movement direction. Left uses a mirrored side view; stopping retains the last facing. Diagonals use the stronger input axis, with equal diagonals choosing up/down.

## Play

Import `project.godot` in Godot 4.6.3 and press **F6** with `main.tscn` open, or **F5** to play the project.

- **WASD / arrow keys:** move
- **E / Space / MINE button:** start mining, use workbench, enter or leave mine
- While mining, **E / Space / Cancel button** or movement cancels and resets that attempt.
- **R:** restart

Collect five copper deposits (2 seconds each), return to the camp workbench for a stronger pick, then enter the Moss Mine at the northeast and mine a blue crystal (9 seconds; requires the stronger pick). Press once to start: mining continues automatically until complete or cancelled. Directional pick-swing poses, rock tremors, sparks, dust and a progress bar show the work. The upgrade unlocks crystal mining; copper remains 2 seconds. Durations are set by `COPPER_SECONDS` and `CRYSTAL_SECONDS` in `game.gd`. You can continue exploring after completing the mission. The surface pond blocks movement; surface trees and decorative rocks currently do not. Underground, walls, pillars and water block movement; small decorative props are part of the background. No enemies, saving, sound, touch movement, or spaceflight yet.

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

The smoke test exercises movement and facing, timed copper collection, the upgrade purchase, mine entry, the 9-second crystal objective and returning outdoors. Run `godot --headless --path . --script tests/mining.gd` for interruption, tool restrictions, directional mining poses, frame-rate independence and effect cleanup checks.

The mine navigation check (`godot --headless --path . --script tests/mine_layout.gd`) verifies walls, pool and pillar collisions, all ore and side-chamber routes, and entry/exit interactions.
