# Earth walking and doorway audit

Checked 23 October 2026. Earth only: all five surface districts and all three mines.

The audit passes **32 routes walked in both directions**, **11,127 real player-movement steps**, **15,471 connected floor samples**, **30 trail approaches** and **18 mine approaches**. No sampled floor positions or interior rooms remain disconnected. The separate Landing Meadow markup test adds seven routes walked both ways (2,836 real-control steps), checked on Godot 4.6.3 and 4.7.2.

## Corrections

- **Landing Meadow markup:** red means walkable ground. `landing_layout.gd` traces the revised 23 October 1499 × 1049 annotation in background coordinates, with holes for its unpainted camp, pond, boulders, signs and shrubs. Movement checks Sunny's feet with an eight-unit ground radius and sweeps/slides around boundaries. Player movement, enemy floor checks, story placement and the companion use this navigation; the existing conservative grass/ore placement mask remains separate. The scenery is unchanged and the red overlay is never shown in play. The revised boundary opens the northern clearing and lower edges, removes the former collision islands where decorations are now painted red, and keeps the unpainted camp, pond bank, boulders, shrubs and signs blocked. Trail probes avoid the unpainted east sign and southern shrub. The Moss Mine entry trigger sits on the revised threshold so approaches from the right enter before meeting its rocky bank; the safe return stays outside the trigger.
- **Three mine markups:** `earth_mine_markup.gd` traces the supplied red-ground contours for Moss Mine, Copper Hollow and Crystal Depths in their original 1499 × 1049 background coordinates. The same outlines control player/companion collision, enemy floor checks and deposit placement. Boarded door faces, pillars, rock peninsulas and pools remain excluded. Source paintings are unchanged.
- **Moss Mine:** the two unmarked lower alcoves are now blocked. Routes use the four marked side chambers and the main galleries; random ore and creatures cannot be placed in the removed alcoves. Copper Hollow no longer permits crossing the rock spur between the southwest room and the southern entrance. Crystal Depths follows the dry western pool rim and excludes the central boarded rock peninsula.
- **Mine minerals:** deposits require a clear 85-unit ring around their position so a mineral cannot fill a narrow marked passage and strand Buddy. This affects placement, not the walking boundary or material budget. Regression checks include the previously blocking Crystal Depths corridor, 150 landing layouts, 200 expanded-Earth layouts and Buddy following through all three mines.
- **Four surface markups:** `earth_surface_markup.gd` replaces the broad rectangle and approximate blockers with the supplied red-ground outlines for Pinewood Trail, Willow Marsh, Sunstone Ridge and Old Quarry. Unpainted forest, pond banks, boulders, logs and ruin walls are excluded. Marked bridge/jetty decks override the underlying water; the ruin interior, arch opening and quarry ledge are usable. Original scenery files are unchanged.
- **Arrivals and quests:** the quarry trigger follows the marked western trail; its arrival sits below the sign-side rocks. Bea moves onto adjacent marked ground beside her log when her old anchor is excluded. Wood prefers grass, then falls back to clear marked dirt/stone when no suitable grass exists, retaining all six crafting supplies. Flowers and fruit continue to require grass.
- **All Earth signed trails:** widened the trigger across the painted path. The new ellipses have half-width 135 world units across the path and half-depth 85 along it; the old trigger was a 55-unit circle.
- **All Earth mine entrances/exits:** widened the trigger to an ellipse with half-extents 110 × 100 world units; the old trigger was a 65-unit circle. Swept tests detect diagonal motion and frames that cross the entire opening.
- **Arrivals:** remain outside the return trigger, with the existing cooldown retained. Enlarged triggers do not bypass the locked quarry. Other planets keep their existing trigger behavior.

## Floor coverage

Every floor sample below is linked to the area’s arrival by swept movement that checks the complete player footprint. The 24-unit grid is supplemented by direct swept joins around tight diagonal bends. The result includes 14,987 successful links, with no isolated samples.

| Area | Valid floor samples | Reachable |
| --- | ---: | ---: |
| Landing Meadow | 3,115 | 3,115 |
| Moss Mine | 1,098 | 1,098 |
| Pinewood Trail | 2,334 | 2,334 |
| Copper Hollow | 1,066 | 1,066 |
| Willow Marsh | 2,144 | 2,144 |
| Sunstone Ridge | 2,747 | 2,747 |
| Old Quarry | 1,800 | 1,800 |
| Crystal Depths | 1,167 | 1,167 |

## Routes checked with player movement

| Area | Painted routes walked in both directions |
| --- | --- |
| Landing Meadow | camp to mine; east and southern trails; pond rim |
| Moss Mine | central doorway apron regression; northwest side chamber; north side chamber; northeast side chamber; far east gallery; southeast gallery |
| Pinewood Trail | full east-west trail; campsite and mine approach; mine and south trail; marked northern clearing |
| Copper Hollow | central copper galleries; north copper loop; west and southwest copper approach; east copper gallery |
| Willow Marsh | whole bridge deck; west meadow loop; southern pond banks; marked fishing jetty |
| Sunstone Ridge | north to west trail; southern ridge loop; circular ruins; marked stone arch |
| Old Quarry | quarry rails to mine; quarry eastern and southern loop; marked pond ledge |
| Crystal Depths | crystal central and north galleries; crystal western gallery; crystal northeast gallery; crystal dry lake rim |

These routes use `move_player`, the function used by keyboard and touch movement. Each route is followed in both directions through independent artwork waypoints. The test also verifies the original solid landmarks remain forbidden; the corrections do not open water or rock.

## Entry checks and regressions

All ten directed surface trail links are walked at center and two valid lateral offsets (30 crossings). Trail probes scan for the outermost straight walking approaches on the actual marked floor, plus the midpoint. Each of the three mine entrances and exits is checked at center and two valid offsets (18 crossings). Approaches stay on the painted floor; each starting probe is explicitly checked. Lateral probes on the narrow Moss and Crystal exit aprons follow the marked dirt, rather than starting inside their rocky banks. The tests check that a successful transition reaches the correct map and that standing at arrival does not immediately return after cooldown. The closed quarry rejects all enlarged-trigger approaches.

Related passing checks cover original mine transitions, slow frames and held movement, smooth wall sliding and frame-rate independence, 150 randomized layouts across the three planets, and 200 expanded-Earth layouts with loading/cache bounds and failure/retry behavior.

Run the focused audit:

```sh
godot --headless --path . --script tests/earth_navigation_audit.gd
godot --headless --path . --script tests/landing_markup.gd
godot --headless --path . --script tests/mine_markup.gd
godot --headless --path . --script tests/surface_markup.gd
```

Its machine-readable results are written to ignored `build/earth-navigation-audit.json`. Existing regression scripts are `navigation_paths.gd`, `mine_layout.gd`, `mine_transitions.gd`, `ore_spawns.gd` and `earth_expansion.gd` under `tests/`. The complete campaign test separately earns the quarry clearance and launch requirements. Review scenes and audit output are excluded from browser exports.
