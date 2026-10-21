# Earth walking and doorway audit

Checked 21 October 2026. Earth only: all five surface districts and all three mines.

The audit passes **30 routes walked in both directions**, **10,704 real player-movement steps**, **18,739 connected floor samples**, **30 trail approaches** and **18 mine approaches**. No sampled floor positions or interior rooms remain disconnected.

## Corrections

- **Moss Mine:** opened the painted dirt apron below the central timber doorway. Its old boundary cut across clear ground. Also corrected the corridor above the right central pillar, where a polygon corner blocked the visible route. The pool, solid pillars and cliff walls remain blocked.
- **Sunstone Ridge:** tightened the back-wall collision around the circular ruins so the clear interior floor is usable.
- **Pinewood Trail:** removed a phantom walkable pocket on the solid cliff backdrop at the upper-right edge. This was outside the playable trails, rather than an inaccessible room.
- **All Earth signed trails:** widened the trigger across the painted path. The new ellipses have half-width 135 world units across the path and half-depth 85 along it; the old trigger was a 55-unit circle.
- **All Earth mine entrances/exits:** widened the trigger to an ellipse with half-extents 110 × 100 world units; the old trigger was a 65-unit circle. Swept tests detect diagonal motion and frames that cross the entire opening.
- **Arrivals:** remain outside the return trigger, with the existing cooldown retained. Enlarged triggers do not bypass the locked quarry. Other planets keep their existing trigger behavior.

## Floor coverage

Every floor sample below is linked to the area’s arrival by swept movement that checks the complete player footprint. The 24-unit grid is supplemented by direct swept joins around tight diagonal bends. The result includes 18,731 successful links, with no isolated samples.

| Area | Valid floor samples | Reachable |
| --- | ---: | ---: |
| Landing Meadow | 3,387 | 3,387 |
| Moss Mine | 965 | 965 |
| Pinewood Trail | 3,221 | 3,221 |
| Copper Hollow | 1,414 | 1,414 |
| Willow Marsh | 2,820 | 2,820 |
| Sunstone Ridge | 3,207 | 3,207 |
| Old Quarry | 2,475 | 2,475 |
| Crystal Depths | 1,250 | 1,250 |

## Routes checked with player movement

| Area | Painted routes walked in both directions |
| --- | --- |
| Landing Meadow | camp to mine; east and southern trails; pond rim |
| Moss Mine | central doorway apron regression; northwest side chamber; north side chamber; northeast side chamber; far east gallery; southeast gallery; south pool rim and gallery; southwest side chamber |
| Pinewood Trail | full east-west trail; campsite and mine approach; mine and south trail |
| Copper Hollow | central copper galleries; north copper loop; west and southwest copper loop; east copper gallery |
| Willow Marsh | whole bridge deck; west meadow loop; southern pond banks |
| Sunstone Ridge | north to west trail; southern ridge loop; circular ruins |
| Old Quarry | quarry rails to mine; quarry eastern and southern loop |
| Crystal Depths | crystal central and north galleries; crystal western gallery; crystal northeast gallery; crystal dry lake rim |

These routes use `move_player`, the function used by keyboard and touch movement. Each route is followed in both directions through independent artwork waypoints. The test also verifies the original solid landmarks remain forbidden; the corrections do not open water or rock.

## Entry checks and regressions

All ten directed surface trail links are walked at center and two valid lateral offsets (30 crossings). Each of the three mine entrances and exits is checked at center and two valid offsets (18 crossings). Approaches stay on the painted floor; probes inside rock are not treated as a reason to open a wall. The tests check that a successful transition reaches the correct map and that standing at arrival does not immediately return after cooldown. The closed quarry rejects all enlarged-trigger approaches.

Related passing checks cover original mine transitions, slow frames and held movement, smooth wall sliding and frame-rate independence, 150 randomized layouts across the three planets, and 200 expanded-Earth layouts with loading/cache bounds and failure/retry behavior.

Run the focused audit:

```sh
godot --headless --path . --script tests/earth_navigation_audit.gd
```

Its machine-readable results are written to ignored `build/earth-navigation-audit.json`. Existing regression scripts are `navigation_paths.gd`, `mine_layout.gd`, `mine_transitions.gd`, `ore_spawns.gd` and `earth_expansion.gd` under `tests/`. The complete campaign test separately earns the quarry clearance and launch requirements. Review scenes and audit output are excluded from browser exports.
