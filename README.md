# Sunny Scout — Planet Adventures

A small Godot 4.6.3 prototype for Jeremy. Uses the Compatibility renderer and GDScript, with a painted Earth surface and illustrated Sunny Scout inspired by the approved mockups. The wide exploration camera is preserved. Surface art, copper and blue ore deposits, and character are AI-generated original project assets. Copper and blue crystal share illustrated rough stone, with orange-red copper veins or bright blue mineral veins. The Moss Mine has a painted cavern map with timber supports, lanterns, moss, side chambers and an underground pool. `mine_layout.gd` traces its walkable floor and blocks walls, pillars and water. The illustrated duck wanders near the pond and occasionally pecks the ground. Walking uses a four-pose illustrated cycle with alternating arms and legs. The starter pick is carried on the backpack while walking. Building the hand drill replaces the character artwork in all directions, during walking, idle and mining, on every world. Animation advances with distance travelled and returns to a standing pose when stopped or blocked. Front, rear and side walk/idle artwork follows movement direction. Left uses a mirrored side view; stopping retains the last facing. Diagonals use the stronger input axis, with equal diagonals choosing up/down.

Sunny Scout wears a hard hat with a lamp, tan work shirt, teal overalls and brown work boots on Earth, including the Moss Mine. Travel to Frost Canyon automatically switches his walking and mining artwork to the spacesuit; returning restores his miner outfit. Ember Dunes also uses the spacesuit. The fitted drill persists across all outfit changes.

## Play

Import `project.godot` in Godot 4.6.3 and press **F5 / Run Project** to open the illustrated explorer's guide, then choose **Start exploring**. **Enter / Space** also starts. Running `main.tscn` directly with **F6** skips the welcome screen for development.

The loading and welcome screens share one illustrated logo: **Planet Adventures** is a smaller, centred subtitle beneath **Sunny Scout**, using matching gold lettering and a teal outline.

- **WASD / arrow keys:** move
- **E / Space / MINE button:** start mining, use workbench or rocket
- **Mine doorways:** walk into an entrance or exit to change areas automatically
- **iPad / touch:** drag the pad at bottom left to walk; tap the action at bottom right to mine, cancel, upgrade or open the rocket. Tap a world card's **Fly here** button to travel.
- While mining, **E / Space / Cancel button** or movement cancels and resets that attempt.
- **R:** restart

The browser loading screen and welcome guide share an illustrated scene and a single-line **Sunny Scout** wordmark. Their backgrounds cover the entire viewport while the guide and buttons remain centred and fully visible. Gameplay restores its usual camera aspect. The loading screen shows actual download progress and a retry button if a download fails. `web/loading.html` is the custom Web export shell; the project's boot image and browser icon also use game artwork. The exporter writes separate `scout-backdrop-*.jpg` and `scout-logo-*.png` files with content hashes, so the loader never depends on a cached generic `index.png` engine splash. Upload these two files along with the rest of the Web build. The welcome guide explains walking, mining, the five-copper drill upgrade, exploration and rocket travel. It switches to touch instructions on iPad and other touch devices. Earth loads after **Start exploring**, while the guide stays visible with landing feedback. Progress lasts for the current play session.

Explore Earth’s signed trails to collect five copper deposits (2 seconds each), return to the camp workbench for a hand drill, then enter the Moss Mine at the northeast and mine a blue crystal (9 seconds; requires the hand drill). Press once to start: mining continues automatically until complete or cancelled. Directional pick-swing poses show starter mining; the upgrade fits a teal-and-brass drill gauntlet and switches to a braced, vibrating drill animation with more frequent dust and sparks. Rock tremors and the progress bar remain visible. The upgrade unlocks crystal mining; copper remains 2 seconds. Durations are set by `COPPER_SECONDS` and `CRYSTAL_SECONDS` in `game.gd`. You can continue exploring after completing the mission. The original meadow pond blocks movement; its trees and small decorative rocks currently do not. New districts also block their ponds, stream, cliffs and solid outcrops. Underground, walls, pillars and water block movement; small decorative props are part of the background. No enemies, saving, sound, or spaceflight minigame yet.

## Illustrated HUD and drill upgrade

Place names are painted onto wooden trail signs and mine entrance beams, with fitted lettering and direction arrows. A single small **CAMP** signpost marks each landing base on all three planets, where the rocket is also parked. Mine exits are marked **SURFACE** on their timber frames, or on a sign beside a natural opening. These signs belong to the scenery and remain beneath the exploration mist; keyboard and touch instructions stay in the HUD.

The compact teal-and-brass HUD follows approved concept A: location and planet badge at top left, this world's two mineral icons and actual inventory counts at top right, and the equipped pick/drill icon. Ore icons reuse the exact deposit textures. Earth blue crystals have a separate collected count. The contextual action button appears only near an interaction; notifications fade after 4.5 seconds. Doors, trails, camp, rocket and ore have no visible interaction circles; location labels and contextual prompts guide the player. The small **?** button opens the controls. Travel cards use illustrated planet thumbnails, material previews, keyboard focus and current-world status. `ui/world_catalog.gd` keeps world names, icons and materials together; the first world is named **Earth** throughout gameplay and travel.

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

`earth_regions.gd` contains the links, foot-based floor boundaries, safe arrivals, ore zones and separate discovery IDs. The original meadow/Moss Mine remain available immediately. Other districts create their randomized ore **once on first entry**; unloading scenery never resets deposits, collected materials, fitted tools or explored mist. Earth contains 16 deposits when fully explored: 13 copper and 3 blue crystals. Copper remains 2 seconds; blue crystal remains 9 seconds and needs the hand drill. Session progress resets with **R** or closing the game; there is no disk save.

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

Frost ore/gold still take **3 seconds**; amethyst/fire ruby take **10 seconds** and require the hand drill. Sunny Scout keeps his spacesuit/drill artwork in every off-world district and mine. Expanded areas generate ore on first entry: two common deposits per surface district and two deposits per mine (one common, one rare). Each off-world planet has 16 deposits in total: 13 common minerals and 3 rare minerals. **R** or closing the game resets the session; there is no disk save.

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

A subtle, translucent mist softly blurs unexplored ground on all three planets and in all nine mines. The landscape remains visible through it; discovered ground becomes crisp and clear. Sunny Scout reveals a circle as he walks, and visited areas remain clear for the rest of the current game. Ore stays hidden and cannot be selected or mined until its location is explored. Newly discovered deposits and their shadows fade in together over 0.75 seconds; revisiting a discovered deposit does not restart the fade. Adjust `ORE_REVEAL_SECONDS` in `game.gd` to change the duration. Each of the twenty-four maps remembers its own discovery; travelling through a doorway or rocket does not reveal a line between arrival and departure points.

Every new game creates new ore locations. Returning to a map keeps its existing layout and depleted deposits. **R** starts a fresh game with new ore and fresh mist. There is no disk persistence. `ore_spawns.gd` selects separated deposits on connected walkable floor, leaves space around doors/camp/rocket, and keeps Earth deposits off the pond, painted boulders, cliff and tree canopies. Every surface district has **two common deposits** and every mine has **one common and one rare deposit**, including the original landing areas and mines. This reduces supplies by about 73% across the game, encouraging travel to other districts. Earth’s starting meadow and Moss Mine together provide only three copper; the five-copper drill requires exploring further. All five Earth surfaces provide ten copper that can be mined with the starter pick, so the upgrade remains reachable without any rare material. `ore_density.gd` controls these shared counts. Upgrades and mining times are unchanged.

The mist radius is controlled by `CLEAR_RADIUS` and `REVEAL_RADIUS` in `exploration_fog.gd`. Discovery uses small reusable texture masks, with the mist drawn above the world and below the HUD. The mist shader blurs a screen copy using filtered mipmaps; undiscovered ore is omitted from rendering and interaction. Run `tests/exploration.gd` and `tests/ore_spawns.gd` with the same headless command as the other gameplay checks to verify discovery/travel/reset behaviour and 100 seeded ore layouts.

## Browser build

The same browser build supports iPad touch controls and desktop keyboard/mouse controls. On an iPad, open the hosted HTTPS game URL in Safari and turn the device sideways for the clearest view. Touch hardware is detected automatically, including iPads that request desktop websites. A left thumb pad handles walking; larger contextual action, help and world-selection buttons handle the rest. The guide shows touch instructions and the page can be reloaded to start a new session. The game retains its wide landscape layout when the browser changes size or orientation.

`ui/touch_controls.gd` owns one movement finger and clears it on release, cancellation, focus loss, resize, menus or travel. `ui/touch_button.gd` handles other fingers independently and suppresses emulated mouse duplicates, so a tap can mine or choose a world while another finger rests on the pad. `tests/touch_controls.gd` exercises the actual input dispatcher through walking, mining/cancellation, drill purchase, multitouch rocket/world selection and return to desktop layout. Browser touch emulation complements those checks; a physical iPad Safari playtest is still needed for device-specific rendering and performance.

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

The smoke test exercises movement and facing, collecting five copper across three surface districts, the upgrade purchase, returning to the landing camp, mine entry, the 9-second crystal objective and returning outdoors. Run `godot --headless --path . --script tests/mining.gd` for interruption, tool restrictions, directional mining poses, frame-rate independence and effect cleanup checks.

The mine navigation check (`godot --headless --path . --script tests/mine_layout.gd`) verifies walls, pool and pillar collisions, all ore and side-chamber routes, and entry/exit interactions.

Run `godot --headless --path . --script tests/worlds.gd` to check planet travel, persistent session progress, bridge collision, both new route networks and the Frost Canyon mission.

## Floor boundaries and foliage

Navigation follows the visible clearings, chamber outlines and full bridge deck, with collision measured at Sunny Scout’s feet. `floor_motion.gd` sweeps short steps and slides along sloping edges. Run `godot --headless --path . --script tests/navigation_paths.gd` to walk artwork-based routes through the clearings and mine passages and verify hazards remain solid.

Earth uses a clean ground painting and separate reusable tree instances in `environment/green_planet.tscn`. Two broadleaf styles and a pine share `environment/wind_tree.tscn`, with fixed trunks/contact shadows and gently bending canopy meshes. The leaf shader moves neighbouring clusters by slightly different amounts, and each tree has its own wind phase and speed. Tree roots are placed on grass, away from the cliff and rock outcrops. This change does not add tree collisions.

To experiment in Godot, open `environment/green_planet.tscn`, select a tree, and adjust **Tree Style**, **Wind Strength**, **Wind Speed** or **Wind Phase** in the Inspector. Duplicate and move tree instances to reuse the effect. The scene origin marks the roots and controls whether Sunny Scout appears in front of or behind a tree. Landing Meadow uses this layered environment. New Earth districts instantiate the same wind trees and flowers from `earth_regions.gd`; Frost Canyon and Ember Dunes use their own illustrated scenery and lightweight snow/lava ambience.

White, yellow, pink and blue flowers, green reeds and cattails use `environment/wind_plant.tscn`. Their stems bend while roots remain anchored; reeds sway more than the flowers. The plants and trees share a cached mesh in `environment/wind_mesh.gd`. Earth water uses faint refraction and moving highlights, preserving the shorelines, bridges, lily pads and stone islands.

`environment/pond.tscn` supplies reusable swimming fish, small wakes, occasional jumps and landing splashes. Landing Meadow has two fish; Willow Marsh's two ponds have two and three; Old Quarry has three; Moss Mine has one; Crystal Depths has three. Each fish has an independent route and random jump timer. Adjust **Minimum Jump Wait**, **Maximum Jump Wait**, **Jump Height**, **Swim Radius** and **Water Radius** in the Inspector. `environment/duck.tscn` provides the illustrated duck's walking and ground pecks: one duck at the landing pond, three on Willow's banks and two beside the quarry pool. Ducks choose clear routes on dry ground.

`environment/earth_water.gd` traces the other ponds, the Willow stream and both mine pools, installs the same subtle water shimmer, and places their wildlife. Fish use each area's own painting and shoreline mask, keeping them below lily pads and away from stone islands. Only the active streamed district owns its animals and water layers; leaving frees them. The four cached 256 × 180 masks retain no scenery textures. Hidden home and mine wildlife pauses. Pinewood Trail and Sunstone Ridge have no painted ponds and receive no water actors.

Four illustrated mountain goats wander and graze in separate grassy areas of Earth. `environment/goat.tscn` shares walking and head-down nibbling frames, with independently timed movement, rests and grazing. Routes stay on grass and avoid the pond, painted boulders, tree roots and mining deposits. Their feet stay anchored as they lower their heads. Adjust **Walk Speed**, **Wander Radius** and **Body Scale** on the goat instances in `environment/green_planet.tscn`. Wildlife pauses when the surface is hidden.

Run `godot --headless --path . --script tests/pond_life.gd` for the original wildlife, goat grazing/routes, random jump spacing, landings, effect cleanup and visibility checks. `tests/earth_ponds.gd` checks the other five pools, multiple fish, two minutes of bank/island-safe movement, hidden wildlife, mine visibility and streamed actor cleanup. Run `godot --headless --path . --script tests/mine_transitions.gd` for automatic entry/exit on all three planets, safe arrivals, held movement and slow-frame doorway crossing.

The rocket is a separate reusable illustrated actor in `environment/rocket.gd`; the surface paintings contain empty landing sites. Flight phases and timings live beside `Flight` in `game.gd`. Camera framing stays on each landing site during flight, and a short fade covers the planet change. Run `godot --headless --path . --script tests/rocket_travel.gd` for takeoff/landing motion, input locks, frame rates, session progress and recovery after landing.

Frost Canyon's five outdoor districts each have four illustrated blue crystal **Frostlings**, while Ember Dunes has four warm terracotta **Dune Sprites** per district. Each off-world mine has two local aliens. They wander, pause and breathe gently; walking advances their four painted poses with distance. Every Earth mine has two small rats that scurry and sniff, and three bats with continuously flapping wings and gently bobbing flight. These are ambient inhabitants, with no combat, interaction prompts or player collision.

`environment/ambient_life.gd` places each species on short local routes using the existing floor boundaries. It keeps them away from water, lava, rock walls, doors, camp equipment and live mineral deposits. `environment/ambient_creature.gd` shares sprite atlases, fitted pose anchors and frame textures across all areas. Wildlife is created with its active district and freed when that district unloads; hidden creatures pause. The base-area controller also clears and replaces its actors on mine/planet changes without resetting them on HUD updates. Edit the home coordinates in `ambient_life.gd` to place more creatures. Run `godot --headless --path . --script tests/ambient_life.gd` for all 67 creatures across 19 areas, animated poses, roaming/rests, hazard and ore clearance, hidden pause and streamed/base-area cleanup.

Ducks, mountain goats, Frostlings, Dune Sprites, rats and bats use front, rear and side artwork. They face their actual movement using Scout's stronger-axis rule (equal diagonals choose up/down); stopping or a blocked step preserves the last facing. Ducks peck and goats graze in their current view, while bats keep flapping in every direction. `environment/wildlife_facing.gd` shares the turning rule; `environment/wildlife_vertical.gd` caches the front/back atlas frames and fits their ground anchors and proportions to the original side paintings. Swimming fish already rotate along their swimming heading. Run `godot --headless --path . --script tests/wildlife_facing.gd` for all six walking/flying species, front/back artwork, retained feeding/idle views, zero/blocked movement and 30/120fps direction checks.

Earth also has eight grazing farm animals: two sheep on Pinewood Trail, two cows in Willow Marsh, and three sheep plus one cow on Sunstone Ridge. `environment/earth_pastures.gd` places them on small grass routes, clear of ponds, trees, doors and mineral deposits. A small averaged grass mask tolerates painted flowers without trapping the animals; the existing floor boundaries preserve water and rocks. Herds unload with their streamed district. All three new species have front, rear and side artwork in `environment/earth_animal_art.gd`.

Find **Buddy**, the golden dog with a teal collar, in Pinewood Trail's central clearing. Approach him to make friends automatically, using either keyboard or touch movement. He follows through Earth's districts and all three mines, catches up when Scout stops, then sits after a short pause. His tail wags while walking and while sitting; a heart marks the first meeting. He waits on Earth during rocket travel and rejoins Scout on return. Friendship lasts for the current game session and resets with a new game, like the existing exploration and inventory. `environment/dog_companion.gd` owns one persistent companion, uses short checked steps and a lazily built bounded navigation grid for detours, and clears old routes at area changes. He has no player collision or interaction button. Run `godot --headless --path . --script tests/earth_animals.gd` for herd routes/cleanup, four ore layouts per pasture, Buddy's discovery, sitting/wagging, safe bridge and mine following, menu pause, streamed transitions and rocket return.
