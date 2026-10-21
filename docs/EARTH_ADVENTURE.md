# Earth crafting and combat

Earth now has a complete resource-and-equipment loop across its five surface districts and three mines. Snakes, apple trees, berry bushes and fallen wood belong only to Earth. Other planets retain their existing friendly alien wildlife and mining/travel behaviour.

## Earth story

Follow the seven-character [Earth story](EARTH_STORY.md): Rowan → Bea → Otis → Mara → Iris → Finn → Nova. Their missions connect the existing gathering and combat systems to a visible quarry rockfall, upgraded tools, expedition supplies, spacesuit repairs and final rocket readiness. The journal tracks these seven story missions and optional exploration. Travel unlocks after Nova’s repair chain, with an affordable resource budget.

## Try it

- Start with the pick. Explore the trails for copper and fallen branches/logs. Use **E** or the contextual touch action to gather wood; mining still runs automatically after starting it.
- Return to the camp workbench and choose **Copper sword: 3 copper + 2 wood** or **Hand drill: 5 copper**. Either order works. Earth has thirteen copper deposits and six wood piles, enough to craft both with resources left over.
- The sword starts locked. Crafting it unlocks the second equipment slot and selects it. **1** selects the pick/fitted drill and **2** selects the owned sword. **E / Space** collects nearby revealed wood and quest items with either weapon. A snake guarding a box keeps Space available for combat until defeated. With no ready pickup, **Space** jabs with the sword or mines nearby revealed ore with the pick/drill; away from ore it attacks. Select the mining tool to drill quest objects. **E** and **Space** can pause jobs started by either key. On touch, tap a tool and then **Attack / Jab**, or the contextual action. **E** also talks and opens the workbench/rocket.
- Both crafted items keep their mission ticks after their ingredients are spent. Drill and sword ownership are separate; changing tools never removes an upgrade. The compact Earth header shows copper, blue crystal and wood.
- Press **J** or tap **Open** beside Missions for the Earth expedition journal. Its seven story missions can be recalled after dialogue closes. District/mine exploration, finding Buddy and trying healing fruit are optional objectives.
- On Earth, moving, pressing **E / Space / Pause**, changing tools, taking damage or opening the journal pauses mining. Each deposit retains its own seconds of completed work through district unloading, mine exits and rocket trips. The prompt shows **Resume** and the remaining time. Finishing pays once. A new game resets every deposit.
- Snakes roam every outdoor Earth district: three in Landing Meadow and two in each later district. A sword defeats a snake in three hits; the pick or fitted drill takes nine. Sword artwork appears only during the jab.
- Every Earth mine has two rats and three bats. They warn before a short attack. A rat takes two sword hits and a bat takes one; weaker pick/drill attacks also work. Defeated foes poof away silently.
- After the sword is crafted, some mining attempts stir a nearby creature. The first 0.6 seconds of work gives that deposit one 35% chance. Each area permits at most one successful alert per game. A visible **!** gives 1.25 seconds of warning before the normal chase/attack. Nearby creatures are reused; surfaces never exceed four living snakes, and mine alerts only use existing rats/bats. Camp is safe. Resuming the same deposit or trying a second deposit cannot bypass the area cap.
- Bites/lunges remove half a heart with a recovery window. Camp, trail mouths and mine arrival areas are safe. Losing all hearts moves Scout to the current area's safe arrival, restores health and keeps gathered materials and crafted tools.
- Earth has only two apple trees and two berry bushes in total. Their grass-safe positions vary in each new game and remain fixed on revisits. Landing Meadow has one bush and no fruit trees. Berries heal one heart and apples heal two; full health leaves fruit available. Picked foliage remains. There is no Earth food, wood or snake population on Frost Canyon or Ember Dunes.
- Buddy still scares mine rats and bats into fleeing and smoke. Scared creatures stop attacking. Playback remains silent, including the bark animation.
- **R** asks before resetting. **No / Escape** preserves the current game; **Yes** starts fresh. Closing/reloading also starts fresh; disk saving is not part of this update.

## State and performance

Only the active surface district owns snake nodes, food meshes and wood drawing data. Leaving saves small records for snake health/position, wood collection and food harvesting/discovery; returning restores them. Mine enemies use stable area/slot IDs for partial damage and removal, sharing the existing no-respawn record with Buddy's scared wildlife. Defeat increments once per enemy. No new system downloads an unvisited map; the existing bounded scenery cache and prefetch queue still load backgrounds.

Grass placement uses the loaded Earth painting and floor boundaries. Food, wood and snakes keep clear of ore, portals and mine doors. New wood is outside the opening camera view and fades in with exploration. All enemies check floor/line-of-sight before attacks and movement. Damage and attacks pause during menus, help, loading, flight and reset confirmation. Wildlife remains friendly unless it is an Earth snake or mine rat/bat.

The historical `environment/earth_trial.gd` now owns Earth-wide health, equipment, surface enemy state, mine damage records and capped mining alerts. Deposit dictionaries own retained work. `environment/earth_missions.gd` owns small visit/creature/food records, and `ui/mission_journal.gd` presents them without loading other maps. `environment/wood_supplies.gd` owns the flat illustrated pickups; `ui/camp_workbench.gd` presents the two recipes. The original generated wood PNG is retained as a reusable atlas; `environment/trial_art.gd` selects its branch/log poses and matching inventory bundle without editing the artwork.

## Verification

`tests/earth_missions.gd` verifies normal J/touch journal opening, second-finger movement cleanup, modal combat pause, independent deposit progress after movement/damage/equipping, exact remaining mining time and one reward, mine/district/rocket persistence, seeded surface and mine alerts, warning delay/caps/no repeated summoning, camp protection, Earth-only scope, defeat/scare objectives, all districts/mines and a fresh reset.

`tests/earth_progression.gd` gathers the real resources, checks both exact one-time purchases and lasting mission ticks, explores all Earth districts/mines, remembers snake damage/defeat and verifies all fifteen surface districts for off-world exclusion. `tests/mine_combat.gd` checks both species in every Earth mine, directional sword/pick hits, wall blocking, warned half-heart attacks, recovery, menu/help/craft pause, terrain clearance, smoke, persistent damage/removal and scare cancellation. `tests/healing_gardens.gd` covers Earth's four plants and no off-world plants, safe placement, discovery and exact healing.

`tests/context_mining.gd` exercises the real E/Space dispatcher, exact rewards and mining times, cross-key cancellation, rare-material drill gate, equipment poses, menu blocking and off-world mining. The surrounding attack-pose, mining, HUD/drill, touch, reset, startup, planet travel, wildlife and Buddy checks protect the existing game. Touch verification includes both crafts while another thumb rests on the movement pad. Browser review complements native checks with the rendered workbench/HUD, pickup icons, Earth district and mine combat, off-world exclusion and the production welcome/start/streaming flow.

Per the latest review, this rollout focuses on Earth. Later-world characters/equipment, fishing and cooking remain deferred. Full tree chopping and disk saving remain separate backlog items; Earth’s quarry and launch gates are part of the implemented story. The existing walking trouble spots still need the promised visual locations.
