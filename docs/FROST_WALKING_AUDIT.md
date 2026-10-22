# Frost walking audit

Checked 22 October 2026 against the eight supplied red walking-area annotations.

`frost_markup.gd` owns five surface contours and three mine contours in original
background coordinates. `frost_layout.gd` delegates the home maps to it;
`outer_regions.gd` delegates the remaining Frost districts. Feet use the existing
20-unit offset, eight-unit ground radius, swept collision and boundary sliding.
Player movement, enemy ground checks, Snow Sprite placement, quest-object
placement and ore generation therefore agree on the same floor.

Red frozen pools are usable ice, including the small southwest Frozen Basin
pool and its approach. The marked canyon bridge and Prism Pass stone-circle
interior remain connected. Unmarked chasms, cliffs, rock islands and Deep Prism
water stay excluded. Red annotations are never displayed in the game. Canyon Camp and Prism Pass
now include the matching cleared snow trails described below.

Canyon Camp's west gate and Prism Pass's west gate follow the marked openings
and keep their arrivals clear of the unpainted stones. Frost trails and mines use
the existing swept elliptical doorway checks with wider lateral hit areas. Other
planets retain their previous behavior.

## Coverage

The focused audit passes **33 artwork routes walked in both directions**, **10,320
real player-movement steps**, **30 trail approaches** and **18 mine approaches**.
Every sampled floor point connects to its area's arrival through swept movement;
no isolated samples remain. Explicit positive/negative checks cover the frozen
pools, bridge, heart-crystal landmark, mine pillars, central islands and water.

| Area | Floor samples | Reachable |
| --- | ---: | ---: |
| Canyon Camp | 1250 | 1250 |
| Canyon Camp mine | 731 | 731 |
| Frozen Basin | 2014 | 2014 |
| Frozen Basin mine | 1316 | 1316 |
| Prism Pass | 1830 | 1830 |
| Aurora Shelf | 2000 | 2000 |
| Glacier Crown | 1970 | 1970 |
| Glacier Crown mine | 1020 | 1020 |

The eight maps include Canyon Camp, Frozen Basin, Prism Pass, Aurora Shelf,
Glacier Crown, Frost Mine, Blue Echo Mine and Deep Prism Mine. Each directed
surface connection and both directions of each mine doorway are crossed from
three valid approaches. Arrival checks reject automatic return transitions.
The narrow Prism Pass west approach is sampled at five-unit lateral intervals
so test starts stay on the marked path around its rocks.

## Verification

```sh
godot --headless --path . --script tests/frost_navigation_audit.gd
godot --headless --path . --script tests/frozen_routes.gd
godot --headless --path . --script tests/frozen_story.gd
godot --headless --path . --script tests/outer_expansion.gd
godot --headless --path . --script tests/navigation_paths.gd
godot --headless --path . --script tests/mine_transitions.gd
godot --headless --path . --script tests/ore_spawns.gd
```

`frozen_routes.gd` verifies connected approaches to every Snow Sprite, quest
prop and yeti. `frozen_story.gd` completes all four quests with real gathering,
exact upgrade costs and retained equipment. Expanded-world tests cover 400
randomized ore layouts and actual trail/mine travel with bounded streaming and
failure recovery. Base-world ore tests cover a further 150 layouts.

Machine-readable audit results are written to ignored
`build/frost-navigation-audit.json`. Review scenes, screenshots and test scripts
are excluded from the production Web export.

## Deep Prism access correction

The first audit reached the northeast chamber on a diagonal route but missed the
blocked direct stepped entrance. It also omitted the walkable stone shoreline
along the pool. Both boundaries now include those approaches. Three additional
routes cover the direct stair entrance, the lakeside path and its southern tip,
walking each route in both directions. Those routes failed against the previous
contour and pass with the correction. Negative samples keep the adjacent cliff
face, central island and water blocked. All 12,103 sampled Frost floor points
remain connected to their area arrivals.

The compiled Web review walks from the Deep Prism arrival to each reported
area, returns to the arrival, then visits it again using real player movement.
All three browser routes passed (2,727 movement steps) with no browser errors.
The final production pack also confirms the formerly blocked stair samples
are walkable.

## Cleared signed junctions

Canyon Camp's two isolated outcrops beside the Frozen Basin and Prism Pass signs
are removed from the painting. Footprint trails connect across the cleared snow.
The western contour includes the new trail width and the northeast connection
joins the existing floor. The other outcrops, ice banks and canyon remain blocked.
Prism Pass's Glacier Crown exit has an unobstructed matching footprint trail off
the east edge. Three independent routes check these paths in both directions.

## Connected crossroads before the bridge

The western footprint trail now curves into the same crossing as the north,
south and east/bridge trails. The painting has one continuous four-way junction
instead of a western dead end and a separate northern merge. The west-to-east
audit follows its painted centre through art points (300,470), (345,485) and
(400,490); the existing north/south route crosses the same open ground.
