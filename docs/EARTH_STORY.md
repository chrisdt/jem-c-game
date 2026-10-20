# Earth's neighbours and mission chain

All seven Earth characters are playable in the main game. Start with **F5 → Start exploring**, talk with **E / the action button**, and use **J / Quests** to recall the story. NPC dialogue pauses movement and combat. Accepting, returning items, upgrading tools and repairing equipment require the final conversation action; closing early preserves your items.

| Character | Where | Mission and result |
| --- | --- | --- |
| Rowan | Beside the Landing Meadow workbench, at the reviewed position | **Ready for the Trail:** gather 3 copper + 2 wood and craft the copper sword. Existing swords count without another charge. |
| Bea | Reviewed fallen-tree clearing in southeast Pinewood Trail | **Woodland Supplies:** defeat her designated snake, recover the tied box and return it. Introduces Otis and the 5-copper hand drill. |
| Otis | Pinewood side of the east quarry trail | **Clear the Way:** craft the hand drill, drill away the visible rockfall and report back. Opens Old Quarry. |
| Mara | Beside Old Quarry's rails and mine cart | **Better Tools:** spend 4 copper + 2 blue crystals to upgrade both tools together: 2 copper + 1 crystal per tool. |
| Iris | Beside Sunstone Ridge's circular ruins | **The Old Expedition:** use the improved tools, defeat the designated ruins snake, drill open the expedition locker and report the discovery. Finds a damaged spacesuit and navigation unit. |
| Finn | Grassy left bank below Willow Marsh's bridge | **Ready for Space:** recover the seal kit from Moss Mine, bring the damaged suit and 2 fallen wood, and repair the suit. Receives a working suit and recovered fuel regulator. |
| Nova | Beside the Landing Meadow rocket, appearing after Finn's suit repair | **Beyond Earth:** recover the engine component in Crystal Depths, fit all three unique rocket parts and complete launch checks. Repairs the rocket and unlocks travel. |

The compact Quests button replaces the old mission overlay. Its popup contains seven required story quests plus optional district/mine exploration, finding Buddy and trying a healing snack. Titles expand to show instructions and live progress; every row shows Complete or Incomplete. Touch supports expansion, swipe scrolling and Up/Down buttons. Completed missions remain complete after spending materials or handing in quest items. Rowan retains her reviewed acceptance and completion behaviour; the journal now implements R07. Bea's reviewed actor and position are retained, with B05/B06's encounter, persistent supply box and return now implemented.

## Budget and upgrades

Earth supplies **13 copper, 3 blue crystals and 6 fallen wood**. The complete story spends **12 copper, 2 blue crystals and 4 wood**:

- Starter sword: 3 copper + 2 wood.
- Starter hand drill: 5 copper.
- Mara's two upgrades: 4 copper + 2 blue crystals total.
- Finn's suit repair: 2 wood plus the unique damaged suit and seal kit.

Bea, Otis, Iris and Nova do not charge additional common materials. Blocking Old Quarry leaves ten copper available on the other side of the gate, enough for both starter crafts. Neither starter recipe needs a quarry ingredient. There are spare resources after finishing, and early gathering or crafting cannot make the story unaffordable.

Mara's reinforced sword deals **5 damage** per directional jab instead of 3; the pick/drill still deals 1. Her crystal drill completes Earth mining **25% sooner**: copper takes 1.5 seconds and blue crystal 6.75 seconds from untouched rock. The HUD names and highlights the upgrades. Existing fitted drill and grounded attack poses remain in use. Other planets retain their existing mineral timing and friendly wildlife.

## World interactions and early actions

Quest objects use fitted illustrated artwork and fade in with exploration. Object placement fits the current district's walkable floor and avoids randomized ore and people. Items are unique session records, separate from the ordinary wood/copper counters.

- Bea's snake is identified by stable spawn ID **1/1**, including after unloading. An unrelated snake or a mining-alert snake cannot satisfy her encounter. Defeating the right snake and recovering the box before accepting is supported. Return consumes the unique box once.
- Iris's ruins snake is stable spawn ID **3/1**. It lives near the ruins. The locker appears centered in the ruins only after both tool upgrades; opening it also needs that encounter's defeat. Reporting an early discovery still works.
- The quarry rockfall blocks walking through the rocks and rejects the quarry trail transition. A pick or sword cannot clear it. The hand drill starts a visible two-second drilling job with a progress bar and dust; moving, taking damage, switching tools, opening the journal or pressing Pause stops the job and retains its work. The locker and engine housing use the same drilling interaction.
- Clearing the rockfall before accepting Otis's task is recognized. It stays cleared through mine visits, area unloading and planet trips.
- The seal kit and engine component may be recovered early. Finn consumes only the damaged suit, seal kit and two wood; he does not consume Iris's navigation unit. The damaged suit and ready suit are distinct states.
- Nova consumes the navigation unit, fuel regulator and engine component once. Launch checks require the repaired rocket, both tool upgrades and the ready suit. The broken rocket is visibly weathered, tilted and has an open service hatch; repairs restore its normal appearance. Travel stays blocked until the achievable repair chain is finished.

No new human character blocks the paths. Each uses Scout's measured **87.45 world-unit** visible height, excluding transparent margins. Rowan and Bea retain their reviewed artwork; Otis uses the original character exploration, and Mara/Iris/Finn/Nova have a separate production atlas with distinct outfits. People currently stand at their landmarks; walking/directional human NPC animation is a separate enhancement. Playback remains silent.

## Session state and checks

NPC acceptance/completion, unique items, the open quarry, upgrades, suit readiness, rocket repair, individual mining progress and defeated/scared creatures survive area and planet trips while the session remains open. **R → Yes** or reloading starts fresh. Browser save/continue, later-world characters, fishing and cooking are deferred.

`tests/earth_story.gd` plays the complete chain using actual ore and wood gathering, existing camp recipes, designated enemy damage, unique pickups and dialogue actions. It checks cancelled handoffs, early kill/pickup recognition, unrelated enemies, exact costs, affordable gate order, real upgraded mining speed and sword damage, resumed world drilling, suit/part consumption, launch restrictions, touch upgrade confirmation, journal completion, travel memory and confirmed reset.

`tests/earth_story_routes.gd` checks connected arrival routes for every NPC and quest object, painted-water exclusion for Finn, seal-kit recovery in Moss Mine, reachable engine recovery, and the scenery cache bound.

`tests/earth_missions.gd` checks journal input and touch cleanup, independent paused deposits, mine/district/rocket persistence, warned/capped mining alerts and optional exploration. Existing Rowan, Bea, character-bubble, combat, food, ore, HUD, reset, flight and touch checks remain relevant. Independent geometry/flight fixtures explicitly supply story access in `tests/support/area_travel.gd`; the complete story test earns the real gate and launch requirements.

Browser review uses the normal production guide and gameplay plus a separate temporary review export for character placement/dialogue. Review helpers and screenshots are excluded from the published game. The production build contains no teleport keys or test scene.

The broken rocket has a dedicated illustrated sprite and bounded animated engine smoke. Repair restores the clean sprite and stops the smoke. All seven neighbours use Scout-sized heads rather than equal total heights. The supply box sits on grass north of Pinewood's fallen log; the enlarged rockfall covers the full trail. Buddy can scare living snakes into a persistent retreat without granting defeat or quest credit. `tests/earth_feedback.gd` checks these changes and the touch quest accordion.
