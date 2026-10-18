# Sunny Scout — Planet Adventures

A small Godot 4.6.3 prototype for Jeremy. Uses the Compatibility renderer and GDScript, with a painted Earth surface and illustrated Sunny Scout inspired by the approved mockups. The wide exploration camera is preserved. Surface art, copper and blue ore deposits, and character are AI-generated original project assets. Copper and blue crystal share illustrated rough stone, with orange-red copper veins or bright blue mineral veins. The Moss Mine has a painted cavern map with timber supports, lanterns, moss, side chambers and an underground pool. `mine_layout.gd` traces its walkable floor and blocks walls, pillars and water. The illustrated duck wanders near the pond and occasionally pecks the ground. Walking uses a four-pose illustrated cycle with alternating arms and legs. The starter pick is carried on the backpack while walking. Building the hand drill replaces the character artwork in all directions, during walking, idle and mining, on every world. Animation advances with distance travelled and returns to a standing pose when stopped or blocked. Front, rear and side walk/idle artwork follows movement direction. Left uses a mirrored side view; stopping retains the last facing. Diagonals use the stronger input axis, with equal diagonals choosing up/down.

Sunny Scout wears a hard hat with a lamp, tan work shirt, teal overalls and brown work boots on Earth, including the Moss Mine. Travel to Frost Canyon automatically switches his walking and mining artwork to the spacesuit; returning restores his miner outfit. Ember Dunes also uses the spacesuit. The fitted drill persists across all outfit changes.

## Play

Import `project.godot` in Godot 4.6.3 and press **F6** with `main.tscn` open, or **F5** to play the project.

- **WASD / arrow keys:** move
- **E / Space / MINE button:** start mining, use workbench or rocket
- **Mine doorways:** walk into an entrance or exit to change areas automatically
- While mining, **E / Space / Cancel button** or movement cancels and resets that attempt.
- **R:** restart

Collect five copper deposits (2 seconds each), return to the camp workbench for a hand drill, then enter the Moss Mine at the northeast and mine a blue crystal (9 seconds; requires the hand drill). Press once to start: mining continues automatically until complete or cancelled. Directional pick-swing poses show starter mining; the upgrade fits a teal-and-brass drill gauntlet and switches to a braced, vibrating drill animation with more frequent dust and sparks. Rock tremors and the progress bar remain visible. The upgrade unlocks crystal mining; copper remains 2 seconds. Durations are set by `COPPER_SECONDS` and `CRYSTAL_SECONDS` in `game.gd`. You can continue exploring after completing the mission. The original meadow pond blocks movement; its trees and small decorative rocks currently do not. New districts also block their ponds, stream, cliffs and solid outcrops. Underground, walls, pillars and water block movement; small decorative props are part of the background. No enemies, saving, sound, touch movement, or spaceflight minigame yet.

## Illustrated HUD and drill upgrade

The compact teal-and-brass HUD follows approved concept A: location and planet badge at top left, this world's two mineral icons and actual inventory counts at top right, and the equipped pick/drill icon. Ore icons reuse the exact deposit textures. Earth blue crystals have a separate collected count. The contextual action button appears only near an interaction; notifications fade after 4.5 seconds. The small **?** button opens the controls. Travel cards use illustrated planet thumbnails, material previews, keyboard focus and current-world status. `ui/world_catalog.gd` keeps world names, icons and materials together; the first world is named **Earth** throughout gameplay and travel.

Build the **hand drill for 5 copper** at any camp workbench. It stays visibly fitted in front, rear and side walking/idle poses and replaces pick swings with continuous directional drilling in both outfits, on all twenty-four maps. Mining durations remain unchanged. `drill_visual.gd` anchors the new poses to the same ground contact line, including after cancellation, mine transitions and rocket travel. The checked-in atlas resources and anchors can be regenerated with `python tools/build_drill_frames.py` (optional authoring dependencies: Pillow, NumPy and SciPy); the tool analyzes source alpha without editing the art. Godot itself needs no Python dependencies.

Run `godot --headless --path . --script tests/hud_drill.gd` to check the compact HUD, mineral counters, purchase cost, all upgraded directions/outfits, ground anchors, session persistence and reset. Fonts are Noto under the SIL Open Font License; see `assets/ui/FONT_LICENSE.txt`.

## Larger Earth: five connected districts

Earth now has **five times the original surface area**: five 2000 × 1400 districts (14 million square world units), with the original camera scale and three distinct mine interiors. Follow a signed trail to change districts automatically with a short fade; entering/exiting a mine also needs no button. These are connected areas, rather than one seamless coordinate plane.

| District | Places to explore | Mine |
| --- | --- | --- |
| Landing Meadow | Original camp, rocket, pond and wildlife; east and south trails | Moss Mine |
| Pinewood Trail | Woodland clearing, abandoned shelter, paths to the quarry and ridge | Copper Hollow |
| Willow Marsh | Two ponds, a winding stream, a broad bridge and waterside loop | — |
| Sunstone Ridge | Rocky uplands, ruined lookout and a looping lower trail | — |
| Old Quarry | Limestone terraces, old railway, water and dry galleries | Crystal Depths |

The meadow's east trail reaches Pinewood; its south trail reaches Willow Marsh. Pinewood connects south to the ridge and east to the quarry. Willow Marsh connects east to the ridge, forming a loop back to camp. The rocket and workbench stay in Landing Meadow. Walk back there to upgrade or travel to another world.

`earth_regions.gd` contains the links, foot-based floor boundaries, safe arrivals, ore zones and separate discovery IDs. The original meadow/Moss Mine remain available immediately. Other districts create their randomized ore **once on first entry**; unloading scenery never resets deposits, collected materials, fitted tools or explored mist. Earth contains 60 deposits when fully explored. Copper remains 2 seconds; blue crystal remains 9 seconds and needs the hand drill. Session progress resets with **R** or closing the game; there is no disk save.

### Loading and performance

`environment/earth_stream.gd` loads nearby scenery ahead of the player within 700 world units of a signed trail or mine entrance. Native Godot uses threaded resource loading. Only one district's extra scenery/foliage is instantiated, and a three-texture LRU cache retains recently used backgrounds; at most two requests run together. Inactive home wildlife pauses. Lightweight ore records and 250 × 175 discovery masks remain independent of that cache. Distant scenery can be evicted without losing progress.

The enabled `addons/earth_streaming` export plugin keeps all eighteen additional district/mine backgrounds out of the initial **Web** PCK, and writes `earth_chunks/`, `frost_chunks/` and `ember_chunks/` folders beside `index.html`. The exporter makes high-quality JPEG copies of these opaque paintings for smaller downloads and faster decoding. The browser downloads those files as the player approaches their area, decodes at most one image per frame and releases stale HTTP requests. Keep all three folders with the exported game when hosting or zipping it. Native builds use the original imported PNG assets automatically. A slow connection holds the short transition fade with a visible destination caption; a failed download returns to a safe spot in the previous district and allows another attempt.

Run `godot --headless --path . --script tests/earth_expansion.gd` for painted trail/bridge/gallery routes, water/rock boundaries, 200 randomized ore layouts, automatic area changes, session progress after cache eviction, loading input locks and failed-load recovery. Browser performance should also be checked on the intended player devices; headless checks establish resource budgets and state correctness rather than a target frame rate.

## Expanded Frost Canyon and Ember Dunes

Both off-world planets now have **five times their original surface area**: five 2000 × 1400 districts and three separate mines each. All three worlds together offer **15 surface districts and 9 mines**, with 24 independent exploration masks. The original landing camps, workbenches, rockets and first mines remain in place.

| Frost Canyon district | Landmark | Mine |
| --- | --- | --- |
| Canyon Camp | Original chasm and wooden bridge; west/east snow trails | Frost Mine |
| Frozen Basin | Wide snow basin, frozen pools and abandoned sled | Blue Echo Mine |
| Prism Pass | Crystal formations, northern loop and ruined observatory | — |
| Aurora Shelf | Two northern approaches, ice arch and frozen lake | — |
| Glacier Crown | Glacial amphitheatre and ancient sundial | Deep Prism Mine |

Canyon Camp's **west** trail reaches Frozen Basin; its **east** trail reaches Prism Pass. Both continue south to separate northern entrances on Aurora Shelf, forming a loop. Prism Pass also leads east to Glacier Crown. Snow paths stay open around the solid crystal/rock islands and frozen pools.

| Ember Dunes district | Landmark | Mine |
| --- | --- | --- |
| Mesa Camp | Original mesa and landing camp; west/south sand trails | Lava Mine |
| Dune Sea | Open rippled dunes and stranded mining sled | Sunfire Cavern |
| Sunken Oasis | Pond, palms, old well and waterside loop | — |
| Redrock Arches | Sandstone islands and walkable natural arch | — |
| Obsidian Rise | Basalt formations and volcanic fissures | Magma Vault |

Mesa Camp's **west** trail reaches Dune Sea; its **south** trail reaches Sunken Oasis. Dune Sea continues south to Redrock Arches, which connects east to the oasis. The oasis also leads east to Obsidian Rise. Sunfire Cavern has a broad dry ring around its lava basin; Magma Vault has multiple galleries and a dry western rim beside its lava lake. Lava, solid columns and water block movement. Small masked flow layers and embers animate lava in the current district; Frost districts have a bounded set of drifting snow flecks.

`outer_regions.gd` holds both trail networks, floor outlines traced from the paintings, mineral zones and unique discovery IDs. `game.gd` uses the same transition/state handling and existing `environment/earth_stream.gd` loader for all planets; the historical Earth-named fields/file remain compatible with project tools. A **single** three-background cache and two-request limit apply across all worlds. Changing planets releases the previous planet's streamed scenery. Prefetch never creates ore or reveals a district. Returning after eviction or rocket travel retains depleted deposits, discoveries, materials and the fitted drill during the session. Rockets return to each planet's landing camp.

Frost ore/gold still take **3 seconds**; amethyst/fire ruby take **10 seconds** and require the hand drill. Sunny Scout keeps his spacesuit/drill artwork in every off-world district and mine. Expanded areas generate ore on first entry: eight surface deposits per new district and seven per new mine. Each expanded off-world planet has 58 deposits including its original area/mine. **R** or closing the game resets the session; there is no disk save.

Run `godot --headless --path . --script tests/outer_expansion.gd` for all new painted routes, 400 randomized layouts, 24 unique map IDs, automatic trails/mine doors, real rocket travel, tool requirements, per-world mineral counters, cache eviction, failed-load recovery and preserved progress. The original thirteen checks still cover Earth and the original off-world routes, wildlife, HUD and rocket animations.

## Second planet: Frost Canyon

Walk to the rocket beside the camp and press **E** to open the destination picker. Travel is available immediately for playtesting: choose Earth, Frost Canyon or Ember Dunes using the buttons or keys **1 / 2 / 3**. **Esc** or **E** closes the picker without travelling. Movement pauses while choosing a destination. Each trip plays booster ignition, an accelerating upward blastoff, and a slowing booster descent to touchdown on the next planet. Sunny Scout boards during the sequence and steps out after landing; movement and mining resume then. Inventory, drill upgrades and depleted deposits persist across trips during the current play session; **R** resets all three planets. There is no disk save yet.

Frost Canyon has its own snowy canyon map: a southern landing camp, a single bridge to the eastern plateau, an ice-arch side trail, and a winding climb to the Frost Mine. The Frost Mine uses a separate Y-shaped layout with a southern entrance and two northern branches. `frost_layout.gd` controls these two new navigation layouts, including the bridge, canyon and mine walls.

The second mission is to collect **3 frost ore (3 seconds each)** and **1 amethyst (10 seconds)**. Amethyst needs the hand drill built with 5 copper from Earth. Return to Earth for copper if needed; workbenches on all three planets accept it. All three worlds share the same walking, mining animations and impact effects.

## Third planet: Ember Dunes

Choose **Ember Dunes** at any rocket to visit the desert. A sandstone mesa divides the sandy surface into two connected routes to the northwest Lava Mine; the landing camp and workbench sit in the southeast. `desert_layout.gd` traces the sandy clearings, mesa, volcanic ledges and stone bridge. Molten lava and rock walls block movement. Stay on the dry galleries and the wide stone bridge to cross the channel.

The mission is **3 gold (3 seconds each)** and **1 fire ruby (10 seconds)**. Fire ruby requires the same hand drill made with 5 copper from Earth. Gold and ruby use matching illustrated stone-and-mineral sprites, random reachable spawn locations and the same discovery fade as earlier materials. Inventory, upgrades, ore locations, mined deposits and exploration persist independently on all three worlds and Earth districts during the play session.

`environment/lava_mine.tscn` adds masked flowing lava highlights and drifting embers. The bridge and dry floor remain still, and particle effects pause while the mine is hidden. The surface and cave each have their own mist colour and exploration memory. Run `godot --headless --path . --script tests/desert_world.gd` for the destination picker, surface routes, bridge and lava collision, 50 ore layouts, mission timing and three-world progress. The existing mine-transition and rocket checks cover the new travel flow too.

## Exploration and random ore

A subtle, translucent mist softly blurs unexplored ground on all three planets and in all nine mines. The landscape remains visible through it; discovered ground becomes crisp and clear. Sunny Scout reveals a circle as he walks, and visited areas remain clear for the rest of the current game. Ore stays hidden and cannot be selected or mined until its location is explored. Newly discovered deposits, their shadows and selection rings fade in together over 0.75 seconds; revisiting a discovered deposit does not restart the fade. Adjust `ORE_REVEAL_SECONDS` in `game.gd` to change the duration. Each of the twenty-four maps remembers its own discovery; travelling through a doorway or rocket does not reveal a line between arrival and departure points.

Every new game creates new ore locations. Returning to a map keeps its existing layout and depleted deposits. **R** starts a fresh game with new ore and fresh mist. There is no disk persistence. `ore_spawns.gd` selects separated deposits on connected walkable floor, leaves space around doors/camp/rocket, and keeps Earth deposits off the pond, painted boulders, cliff and tree canopies. The original maps retain their deposit counts; upgrades and mining times are unchanged.

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

Earth uses a clean ground painting and separate reusable tree instances in `environment/green_planet.tscn`. Two broadleaf styles and a pine share `environment/wind_tree.tscn`, with fixed trunks/contact shadows and gently bending canopy meshes. The leaf shader moves neighbouring clusters by slightly different amounts, and each tree has its own wind phase and speed. Tree roots are placed on grass, away from the cliff and rock outcrops. This change does not add tree collisions.

To experiment in Godot, open `environment/green_planet.tscn`, select a tree, and adjust **Tree Style**, **Wind Strength**, **Wind Speed** or **Wind Phase** in the Inspector. Duplicate and move tree instances to reuse the effect. The scene origin marks the roots and controls whether Sunny Scout appears in front of or behind a tree. Landing Meadow uses this layered environment. New Earth districts instantiate the same wind trees and flowers from `earth_regions.gd`; Frost Canyon and Ember Dunes use their own illustrated scenery and lightweight snow/lava ambience.

White, yellow, pink and blue flowers, green reeds and cattails use `environment/wind_plant.tscn`. Their stems bend while roots remain anchored; reeds sway more than the flowers. The plants and trees share a cached mesh in `environment/wind_mesh.gd`. The ground shader adds faint water refraction and highlights only inside the turquoise pond, preserving the shoreline and lily pads.

`environment/pond.tscn` adds a swimming fish, small wakes, occasional jumps and landing splashes. After an initial 5–9 second wait, jumps have a random 8–18 second wait between landings and takeoffs. Adjust the pond's **Minimum Jump Wait**, **Maximum Jump Wait** and **Jump Height** in the Inspector. `environment/duck.tscn` provides the illustrated duck's wandering, walking poses and occasional ground pecks. Both animals pause while the Earth surface is hidden.

Four illustrated mountain goats wander and graze in separate grassy areas of Earth. `environment/goat.tscn` shares walking and head-down nibbling frames, with independently timed movement, rests and grazing. Routes stay on grass and avoid the pond, painted boulders, tree roots and mining deposits. Their feet stay anchored as they lower their heads. Adjust **Walk Speed**, **Wander Radius** and **Body Scale** on the goat instances in `environment/green_planet.tscn`. Wildlife pauses when the surface is hidden.

Run `godot --headless --path . --script tests/pond_life.gd` for wildlife movement, goat grazing/routes, random jump spacing, landings, effect cleanup and visibility checks. Run `godot --headless --path . --script tests/mine_transitions.gd` for automatic entry/exit on all three planets, safe arrivals, held movement and slow-frame doorway crossing.

The rocket is a separate reusable illustrated actor in `environment/rocket.gd`; the surface paintings contain empty landing sites. Flight phases and timings live beside `Flight` in `game.gd`. Camera framing stays on each landing site during flight, and a short fade covers the planet change. Run `godot --headless --path . --script tests/rocket_travel.gd` for takeoff/landing motion, input locks, frame rates, session progress and recovery after landing.
