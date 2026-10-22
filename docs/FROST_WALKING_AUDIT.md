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
water stay excluded. Original scenery files are unchanged; red annotations are
never displayed in the game.

Canyon Camp's west gate and Prism Pass's west gate follow the marked openings
and keep their arrivals clear of the unpainted stones. Frost trails and mines use
the existing swept elliptical doorway checks with wider lateral hit areas. Other
planets retain their previous behavior.

## Coverage

The focused audit passes **27 artwork routes walked in both directions**, **9,580
real player-movement steps**, **30 trail approaches** and **18 mine approaches**.
Every sampled floor point connects to its area's arrival through swept movement;
no isolated samples remain. Explicit positive/negative checks cover the frozen
pools, bridge, heart-crystal landmark, mine pillars, central islands and water.

| Area | Floor samples | Reachable |
| --- | ---: | ---: |
| Canyon Camp | 1222 | 1222 |
| Canyon Camp mine | 731 | 731 |
| Frozen Basin | 2014 | 2014 |
| Frozen Basin mine | 1316 | 1316 |
| Prism Pass | 1830 | 1830 |
| Aurora Shelf | 2000 | 2000 |
| Glacier Crown | 1970 | 1970 |
| Glacier Crown mine | 938 | 938 |

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
