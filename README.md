# Sunny Scout — Planet Adventures

A small Godot 4.6.3 prototype for Jeremy. Uses the Compatibility renderer and GDScript, with a painted Green Planet surface and illustrated Sunny Scout inspired by the approved mockups. The wide exploration camera is preserved. Surface art, copper and blue ore deposits, and character are AI-generated original project assets. Copper and blue crystal share illustrated rough stone, with orange-red copper veins or bright blue mineral veins. The Moss Mine has a painted cavern map with timber supports, lanterns, moss, side chambers and an underground pool. `mine_layout.gd` traces its walkable floor and blocks walls, pillars and water. Creature art remains provisional. Walking uses a four-pose illustrated cycle with alternating arms and legs. The pick is carried on the backpack while walking. Animation advances with distance travelled and returns to a standing pose when stopped or blocked. Front, rear and side walk/idle artwork follows movement direction. Left uses a mirrored side view; stopping retains the last facing. Diagonals use the stronger input axis, with equal diagonals choosing up/down.

## Play

Import `project.godot` in Godot 4.6.3 and press **F6** with `main.tscn` open, or **F5** to play the project.

- **WASD / arrow keys:** move
- **E / Space / MINE button:** start mining, use workbench, enter or leave mine
- While mining, **E / Space / Cancel button** or movement cancels and resets that attempt.
- **R:** restart

Collect five copper deposits (2 seconds each), return to the camp workbench for a stronger pick, then enter the Moss Mine at the northeast and mine a blue crystal (9 seconds; requires the stronger pick). Press once to start: mining continues automatically until complete or cancelled. Directional pick-swing poses, rock tremors, sparks, dust and a progress bar show the work. The upgrade unlocks crystal mining; copper remains 2 seconds. Durations are set by `COPPER_SECONDS` and `CRYSTAL_SECONDS` in `game.gd`. You can continue exploring after completing the mission. The surface pond blocks movement; surface trees and decorative rocks currently do not. Underground, walls, pillars and water block movement; small decorative props are part of the background. No enemies, saving, sound, touch movement, or spaceflight minigame yet.

## Second planet: Frost Canyon

Walk to the rocket beside the Green Planet camp and press **E** to fly to Frost Canyon. Travel is available immediately for playtesting. Press E at the rocket on Frost Canyon to return. Inventory, pick upgrades and depleted deposits persist across trips during the current play session; **R** resets both planets. There is no disk save yet.

Frost Canyon has its own snowy canyon map: a southern landing camp, a single bridge to the eastern plateau, an ice-arch side trail, and a winding climb to the Frost Mine. The Frost Mine uses a separate Y-shaped layout with a southern entrance and two northern branches. `frost_layout.gd` controls these two new navigation layouts, including the bridge, canyon and mine walls.

The second mission is to collect **3 frost ore (3 seconds each)** and **1 amethyst (10 seconds)**. Amethyst needs the stronger pick built with 5 copper from Green Planet. Return to Green Planet for copper if needed; workbenches on either planet accept it. Both worlds share the same walking, mining animations and impact effects.

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

Run `godot --headless --path . --script tests/worlds.gd` to check planet travel, persistent session progress, bridge collision, both new route networks and the Frost Canyon mission.

## Floor boundaries and foliage

Navigation follows the visible clearings, chamber outlines and full bridge deck, with collision measured at Sunny Scout’s feet. `floor_motion.gd` sweeps short steps and slides along sloping edges. Run `godot --headless --path . --script tests/navigation_paths.gd` to walk artwork-based routes through the clearings and mine passages and verify hazards remain solid.

Green Planet now uses a clean ground painting and separate reusable tree instances in `environment/green_planet.tscn`. Two broadleaf styles and a pine share `environment/wind_tree.tscn`, with fixed trunks/contact shadows and gently bending canopy meshes. The leaf shader moves neighbouring clusters by slightly different amounts, and each tree has its own wind phase and speed. Low plants retain a much lighter background breeze. The trees are arranged around the existing paths, camp, pond and mine entrance; this change does not add tree collisions.

To experiment in Godot, open `environment/green_planet.tscn`, select a tree, and adjust **Tree Style**, **Wind Strength**, **Wind Speed** or **Wind Phase** in the Inspector. Duplicate and move tree instances to reuse the effect. The scene origin marks the roots and controls whether Sunny Scout appears in front of or behind a tree. This layered environment is used on the Green Planet surface; the other maps retain their existing artwork.
