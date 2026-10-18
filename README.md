# Sunny Scout — Planet Adventures

A small Godot 4.6.3 prototype for Jeremy. Uses the Compatibility renderer and GDScript, with a painted Green Planet surface and illustrated Sunny Scout inspired by the approved mockups. The wide exploration camera is preserved. Surface art, copper and blue ore deposits, and character are AI-generated original project assets. Copper and blue crystal share illustrated rough stone, with orange-red copper veins or bright blue mineral veins. The Moss Mine has a painted cavern map with timber supports, lanterns, moss, side chambers and an underground pool. `mine_layout.gd` traces its walkable floor and blocks walls, pillars and water. The illustrated duck wanders near the pond and occasionally pecks the ground. Walking uses a four-pose illustrated cycle with alternating arms and legs. The pick is carried on the backpack while walking. Animation advances with distance travelled and returns to a standing pose when stopped or blocked. Front, rear and side walk/idle artwork follows movement direction. Left uses a mirrored side view; stopping retains the last facing. Diagonals use the stronger input axis, with equal diagonals choosing up/down.

Sunny Scout wears a hard hat with a lamp, tan work shirt, teal overalls and brown work boots on Earth/Green Planet, including the Moss Mine. Travel to Frost Canyon automatically switches his walking and mining artwork to the spacesuit; returning restores his miner outfit.

## Play

Import `project.godot` in Godot 4.6.3 and press **F6** with `main.tscn` open, or **F5** to play the project.

- **WASD / arrow keys:** move
- **E / Space / MINE button:** start mining, use workbench or rocket
- **Mine doorways:** walk into an entrance or exit to change areas automatically
- While mining, **E / Space / Cancel button** or movement cancels and resets that attempt.
- **R:** restart

Collect five copper deposits (2 seconds each), return to the camp workbench for a stronger pick, then enter the Moss Mine at the northeast and mine a blue crystal (9 seconds; requires the stronger pick). Press once to start: mining continues automatically until complete or cancelled. Directional pick-swing poses, rock tremors, sparks, dust and a progress bar show the work. The upgrade unlocks crystal mining; copper remains 2 seconds. Durations are set by `COPPER_SECONDS` and `CRYSTAL_SECONDS` in `game.gd`. You can continue exploring after completing the mission. The surface pond blocks movement; surface trees and decorative rocks currently do not. Underground, walls, pillars and water block movement; small decorative props are part of the background. No enemies, saving, sound, touch movement, or spaceflight minigame yet.

## Second planet: Frost Canyon

Walk to the rocket beside the camp and press **E** to open the destination picker. Travel is available immediately for playtesting: choose Green Planet, Frost Canyon or Ember Dunes using the buttons or keys **1 / 2 / 3**. **Esc** or **E** closes the picker without travelling. Movement pauses while choosing a destination. Each trip plays booster ignition, an accelerating upward blastoff, and a slowing booster descent to touchdown on the next planet. Sunny Scout boards during the sequence and steps out after landing; movement and mining resume then. Inventory, pick upgrades and depleted deposits persist across trips during the current play session; **R** resets all three planets. There is no disk save yet.

Frost Canyon has its own snowy canyon map: a southern landing camp, a single bridge to the eastern plateau, an ice-arch side trail, and a winding climb to the Frost Mine. The Frost Mine uses a separate Y-shaped layout with a southern entrance and two northern branches. `frost_layout.gd` controls these two new navigation layouts, including the bridge, canyon and mine walls.

The second mission is to collect **3 frost ore (3 seconds each)** and **1 amethyst (10 seconds)**. Amethyst needs the stronger pick built with 5 copper from Green Planet. Return to Green Planet for copper if needed; workbenches on all three planets accept it. All three worlds share the same walking, mining animations and impact effects.

## Third planet: Ember Dunes

Choose **Ember Dunes** at any rocket to visit the desert. A sandstone mesa divides the sandy surface into two connected routes to the northwest Lava Mine; the landing camp and workbench sit in the southeast. `desert_layout.gd` traces the sandy clearings, mesa, volcanic ledges and stone bridge. Molten lava and rock walls block movement. Stay on the dry galleries and the wide stone bridge to cross the channel.

The mission is **3 gold (3 seconds each)** and **1 fire ruby (10 seconds)**. Fire ruby requires the same stronger pick made with 5 copper from Green Planet. Gold and ruby use matching illustrated stone-and-mineral sprites, random reachable spawn locations and the same discovery fade as earlier materials. Inventory, upgrades, ore locations, mined deposits and exploration persist independently on all three worlds during the play session.

`environment/lava_mine.tscn` adds masked flowing lava highlights and drifting embers. The bridge and dry floor remain still, and particle effects pause while the mine is hidden. The surface and cave each have their own mist colour and exploration memory. Run `godot --headless --path . --script tests/desert_world.gd` for the destination picker, surface routes, bridge and lava collision, 50 ore layouts, mission timing and three-world progress. The existing mine-transition and rocket checks cover the new travel flow too.

## Exploration and random ore

A subtle, translucent mist softly blurs unexplored ground on all three planets and in all three mines. The landscape remains visible through it; discovered ground becomes crisp and clear. Sunny Scout reveals a circle as he walks, and visited areas remain clear for the rest of the current game. Ore stays hidden and cannot be selected or mined until its location is explored. Newly discovered deposits, their shadows and selection rings fade in together over 0.75 seconds; revisiting a discovered deposit does not restart the fade. Adjust `ORE_REVEAL_SECONDS` in `game.gd` to change the duration. Each of the six maps remembers its own discovery; travelling through a doorway or rocket does not reveal a line between arrival and departure points.

Every new game creates new ore locations. Returning to a map keeps its existing layout and depleted deposits. **R** starts a fresh game with new ore and fresh mist. There is no disk persistence. `ore_spawns.gd` selects separated deposits on connected walkable floor, leaves space around doors/camp/rocket, and keeps Green Planet deposits off the pond, painted boulders, cliff and tree canopies. Deposit counts, upgrades and mining times are unchanged.

The mist radius is controlled by `CLEAR_RADIUS` and `REVEAL_RADIUS` in `exploration_fog.gd`. Discovery uses small reusable texture masks, with the mist drawn above the world and below the HUD. The mist shader blurs a screen copy using filtered mipmaps; undiscovered ore is omitted from rendering and interaction. Run `tests/exploration.gd` and `tests/ore_spawns.gd` with the same headless command as the other gameplay checks to verify discovery/travel/reset behaviour and 100 seeded ore layouts.

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

Green Planet uses a clean ground painting and separate reusable tree instances in `environment/green_planet.tscn`. Two broadleaf styles and a pine share `environment/wind_tree.tscn`, with fixed trunks/contact shadows and gently bending canopy meshes. The leaf shader moves neighbouring clusters by slightly different amounts, and each tree has its own wind phase and speed. Tree roots are placed on grass, away from the cliff and rock outcrops. This change does not add tree collisions.

To experiment in Godot, open `environment/green_planet.tscn`, select a tree, and adjust **Tree Style**, **Wind Strength**, **Wind Speed** or **Wind Phase** in the Inspector. Duplicate and move tree instances to reuse the effect. The scene origin marks the roots and controls whether Sunny Scout appears in front of or behind a tree. This layered environment is used on the Green Planet surface; the other maps retain their existing artwork.

White, yellow, pink and blue flowers, green reeds and cattails use `environment/wind_plant.tscn`. Their stems bend while roots remain anchored; reeds sway more than the flowers. The plants and trees share a cached mesh in `environment/wind_mesh.gd`. The ground shader adds faint water refraction and highlights only inside the turquoise pond, preserving the shoreline and lily pads.

`environment/pond.tscn` adds a swimming fish, small wakes, occasional jumps and landing splashes. After an initial 5–9 second wait, jumps have a random 8–18 second wait between landings and takeoffs. Adjust the pond's **Minimum Jump Wait**, **Maximum Jump Wait** and **Jump Height** in the Inspector. `environment/duck.tscn` provides the illustrated duck's wandering, walking poses and occasional ground pecks. Both animals pause while the Green Planet surface is hidden.

Four illustrated mountain goats wander and graze in separate grassy areas of Green Planet. `environment/goat.tscn` shares walking and head-down nibbling frames, with independently timed movement, rests and grazing. Routes stay on grass and avoid the pond, painted boulders, tree roots and mining deposits. Their feet stay anchored as they lower their heads. Adjust **Walk Speed**, **Wander Radius** and **Body Scale** on the goat instances in `environment/green_planet.tscn`. Wildlife pauses when the surface is hidden.

Run `godot --headless --path . --script tests/pond_life.gd` for wildlife movement, goat grazing/routes, random jump spacing, landings, effect cleanup and visibility checks. Run `godot --headless --path . --script tests/mine_transitions.gd` for automatic entry/exit on all three planets, safe arrivals, held movement and slow-frame doorway crossing.

The rocket is a separate reusable illustrated actor in `environment/rocket.gd`; the surface paintings contain empty landing sites. Flight phases and timings live beside `Flight` in `game.gd`. Camera framing stays on each landing site during flight, and a short fade covers the planet change. Run `godot --headless --path . --script tests/rocket_travel.gd` for takeoff/landing motion, input locks, frame rates, session progress and recovery after landing.
