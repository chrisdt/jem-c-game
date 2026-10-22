# Ember walking audit

Checked 22 October 2026 against the eight supplied red walking-area annotations:
Mesa Camp, Dune Sea, Sunken Oasis, Redrock Arches, Obsidian Rise, Lava Mine and
Sunfire Cavern and Magma Vault. The supplied Magma Vault annotation follows the
edited background with the former diagonal interior rock barrier removed.

`ember_markup.gd` traces the marked foot-contact contours. `desert_layout.gd`
delegates the home surface/mine to it; `outer_regions.gd` delegates the other four
surfaces, Sunfire Cavern and Magma Vault. Existing swept movement, boundary sliding, the
20-unit foot offset and eight-unit ground radius are retained. Player movement,
Sunstone Folk, scorpions, quest placement and ore use the same floor.

The oasis, mesas, cactus islands and lava stay excluded. The Lava Mine bridge
joins both galleries. Per the user's clarification, the raised rock block above
the left end of that bridge stays solid despite the overlapping red annotation;
the deck remains open beside it. Magma Vault uses the clean edited background and the red annotations never
appear during play. The other seven background paintings are unchanged.

Dune Sea's mine return approaches from the right of the unmarked rock spur,
instead of placing Sunny on its boundary. Dune Sea's east trail and Sunken
Oasis's east trail have their triggers centered on the marked sand. The two mine
exit anchors follow the marked apron. Ember now uses the existing swept elliptical
trail/mine triggers, adding broad lateral hit areas while keeping arrivals outside
the return triggers. Earth and Frost retain their existing trigger behavior.

## Coverage

The audit passes **30 artwork routes in both directions**, **11,756 real-control
steps**, **14,629 connected floor samples**, **30 trail approaches** and **18 mine
approaches**. The dense floor audit covers all eight supplied maps. Tight bends in Magma Vault
are joined through independently authored routes, with every segment proven by
the same swept collision before joining its floor samples. No sampled points
remain isolated. Explicit checks cover the mesa, oasis, cactus islands,
raised rock, bridge and lava. Every trail gate, trail arrival and mine arrival is
checked for valid ground as well as successful travel and no automatic bounce back.

| Area | Floor samples | Reachable |
| --- | ---: | ---: |
| Mesa Camp | 1659 | 1659 |
| Mesa Camp mine | 1021 | 1021 |
| Dune Sea | 2762 | 2762 |
| Dune Sea mine | 1542 | 1542 |
| Sunken Oasis | 2016 | 2016 |
| Redrock Arches | 1828 | 1828 |
| Obsidian Rise | 2461 | 2461 |
| Obsidian Rise mine | 1340 | 1340 |

## Verification

```sh
godot --headless --path . --script tests/ember_navigation_audit.gd
godot --headless --path . --script tests/ember_routes.gd
godot --headless --path . --script tests/ember_story.gd
godot --headless --path . --script tests/desert_world.gd
godot --headless --path . --script tests/outer_expansion.gd
godot --headless --path . --script tests/mine_transitions.gd
godot --headless --path . --script tests/ore_spawns.gd
```

Related passing checks cover all four Sunstone quests with real gathering and
upgrade costs, Sunforge equipment across outfits/worlds, venom/antidotes, quest
and enemy approaches, 50 desert layouts, 400 expanded-world layouts, 150 base-world
layouts, automatic travel, bounded scenery streaming and failure/retry recovery.

Machine-readable results are written to ignored `build/ember-navigation-audit.json`.
Review scenes, tests and screenshots are excluded from the production Web export.
