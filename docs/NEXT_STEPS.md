**Sunny Scout — next steps from Chris and Jeremy’s discussion, 19 October 2026**

The subsequent [Earth NPC and mission task plan](EARTH_STORY.md) breaks the new story into character mockups, mission scripts and one-character implementations. Rowan's **R06 Ready for the Trail** has been reviewed. Bea's look and position are approved, and [B04 adds her greeting and Talk interaction to the main game](BEA_MISSION.md). Test in Pinewood's lower-right fallen-tree clearing before B05 adds the encounter, supply box and mission. Rowan's reopenable log (R07) remains pending. Test gameplay with F5 → Start exploring; use screenshots for placement reviews. The quarry rockfall, later upgrades, spacesuit and final rocket repair follow in their own tasks.

The next playable loop is: explore Earth → collect resources → craft equipment → mine → respond to a snake → resume mining → find fruit to heal. Build and playtest this in small steps before extending combat to the other worlds.

This backlog reviews the complete 6:22 transcript, `Sunny Scout — Planet Adventures - 19 October 2026.srt`, against the project. The recording is supporting evidence, rather than an instruction to implement every idea. Chris and Jeremy subsequently approved the concepts and requested the [first-screen animation trial](FIRST_SCREEN_TRIAL.md), now expanded in the Earth rollout. The attached MP4 could not be inspected because it exceeds the environment’s 32 MiB transfer limit; precise walking-problem locations still need visual review.

**What the discussion establishes**

- Start with Earth. Jeremy wants a bottom equipment bar, a craftable sword, snakes, player health and gentle damage.
- Find sparse, randomly placed apple trees and berry bushes to regain health; initially collecting food restores health immediately.
- Add directional sword/combat animation. Preserve a deposit’s mining progress when leaving to deal with an enemy.
- Try enemies emerging in response to mining, and put multiple objectives, including the drill and sword, inside a brass mission panel.
- Wood gathering/tree chopping and a material recipe for the sword were suggested; the harvesting method and costs are still open.
- Later: chasing yetis on Frost Canyon, tougher opponents on later planets, new weapon/mining upgrades per world, fishing and camp cooking. The third planet’s enemy was not chosen.

**Earth task list, in suggested working order**

The [Earth crafting/combat rollout](EARTH_ADVENTURE.md) now implements the approved HUD, locked/owned equipment, health, sparse Earth-only healing, fallen-wood gathering, both camp recipes, directional attacks and surface/mine combat. The confirmed sword recipe is **3 copper + 2 wood**; the drill remains **5 copper**. Snakes live across all five Earth districts, and rats/bats attack in all three Earth mines and can be defeated or scared away by Buddy. These systems are excluded from the other planets. Completed crafting missions persist after spending their ingredients. Jeremy's complete Earth playtest is the next review checkpoint.

E03–E05, E07–E10 and E12 now have playable implementations; food randomization/balance remains a tuning choice. E06's retained mining progress and E11's mining-triggered spawning remain ideas to test, rather than changes included in this rollout. E01 still needs the visual walking-problem locations. “Requested” means a clear direction from the discussion, while “Idea” marks a tentative mechanic.

The latest review specifies **straight jabs**, **no sound**, **one heart per berry bush** and **two hearts per apple tree**. Those choices supersede the earlier example values below.

| ID | Task | Basis / transcript time | Complete when |
| --- | --- | --- | --- |
| E01 | Review and fix the remaining walking trouble spots | Reported issue, 00:18–00:27 | Identify each location visually, compare the artwork with the walkable floor, and check that the route works with keyboard and touch. Exact locations are not stated in the transcript. |
| E02 | Mock up the expanded HUD | Requested features; mockups suggested at 04:14–04:24 | Show the health display, compact equipment bar and brass mission panel together in desktop and iPad layouts. Retain the illustrated teal-and-brass style and leave room for movement/action controls. Review this before implementing the UI. |
| E03 | Add selectable equipment | Requested, 00:34–01:00 | Select mining equipment or an owned sword using keyboard and touch. Mining equipment becomes the fitted drill after upgrading. Locked equipment is clearly shown, and menus/travel/mining cannot accidentally trigger an attack. |
| E04 | Add player health and recovery rules | Requested, 02:18–02:54; 04:04–04:10 | Health is visible, damage is small and readable, and repeated overlapping hits cannot empty it instantly. Decide what happens at zero health before enabling enemies. |
| E05 | Add healing apple trees and berry bushes | Requested, 02:33–03:29; 03:55–04:04 | A few reusable illustrated food sources appear in random, reachable outdoor spots. They respect fog and grass placement, heal on collection when hurt, and remember harvesting during the current game. Balance food availability against damage. |
| E06 | Keep mining progress after interruption | Idea to test, 04:39–04:55 | Leaving, switching to the sword or taking a hit pauses that deposit’s work. Returning resumes it. Each deposit retains its own progress across area unloading and planet travel within the game; completing it awards the material once. A fresh game resets it. |
| E07 | Introduce a small wood supply | Idea, 05:42–05:53 | Pick a first harvesting method and show wood in the material inventory. Confirm whether to begin with collectable branches/logs or a reusable harvestable tree. Full tree chopping would also need a tool choice, chopping/falling art and rules for the stump. |
| E08 | Extend camp crafting to include a sword | Requested sword; recipe is open, 01:00–01:30; 05:38–05:53 | Camp offers the drill and sword with clear requirements. Crafting spends the correct resources, unlocks equipment once, and visibly updates the character. Resource costs leave enough supplies for both items. |
| E09 | Prototype player sword combat and animation | Requested, 04:25–04:39 | Attack in front, rear and side views, with fitted weapon/hand anchors and clear hit feedback. The sword works alongside the existing drill upgrade. Touch has a comfortable attack button; each swing hits a target at most once. |
| E10 | Build one Earth snake enemy | Requested, 01:38–01:59; 02:08–02:22 | One illustrated snake has readable slithering, turning, warning, attack, hurt and defeat behaviour. It uses the existing walkable floor, does not cross water/rock walls, and takes only a few sword hits in the first prototype. Other Earth animals remain friendly. |
| E11 | Trial mining-triggered encounters | Idea to test, 04:55–05:13 | Some mining attempts cause a warned snake encounter, with a small active-enemy cap and a safe camp. Resuming one deposit cannot repeatedly summon snakes. The player can interrupt, respond or retreat, then return to the retained progress. |
| E12 | Add the Earth mission checklist and update the guide | Requested, 05:27–05:53 | The brass panel tracks “Build the hand drill” and “Build a sword,” with material progress and lasting completion ticks. Spending the ingredients does not undo completion. The guide explains equipping, combat, healing and resumed mining. |
| E13 | Playtest and tune one complete Earth loop | Requested incremental approach, 05:13–05:26 | Jeremy can find materials/food, craft both items, face a snake, heal and resume a deposit. Then extend the proven behaviour across Earth’s five districts and three mines. Verify browser/iPad input, area loading, session state and performance. |

E01 can progress independently when the walking-problem locations are available. The approved E02 artwork now supports the Earth rollout. Review E13 with Jeremy before tuning the remaining E06 mining-progress and E11 encounter-spawning ideas or extending combat to other planets.

**Suggested starting rules — recommendations, not decisions from the recording**

- **Equipment:** two compact slots at bottom centre: mining tool and sword. Use number keys or tapping to select; keep the iPad movement pad and action button clear. A future fishing rod can add another slot. Keep fruit as immediate healing initially, so it needs no extra food-management screen.
- **Gentle combat:** try five hearts, a half-heart snake bite, a short recovery window after damage, and a snake defeated in two or three hits. Show a clear warning before its first bite. At zero health, return to camp with collected materials retained. These are playtest values to adjust with Jeremy.
- **Healing:** the approved trial now uses one heart per berry bush and two hearts per apple tree. At full health, fruit remains available. Free manual camp resting remains an optional future recommendation; the trial restores health on a safe return after losing all hearts.
- **Sword resources:** the confirmed first recipe is three copper plus two wood. Earth currently provides ten surface copper and three common mine deposits; the existing drill costs five copper. The implemented branches/logs provide six wood pickups, and both recipes together use eight of the thirteen available copper deposits. Full tree chopping remains a later option.
- **First encounter:** teach sword use after it is crafted, then try one snake near one test deposit. Expand to occasional encounters rather than an enemy at every rock. Mining noise can attract a nearby snake or reveal one from a suitable hiding place. Pick the presentation after seeing the animation mockup.
- **Defeat feedback:** a small smoke puff fits the existing wildlife effects. Enemy health can appear only while fighting to keep the screen uncluttered. These are visual suggestions, not requirements from the transcript.
- **Progression:** show separate ownership and equipped-tool state, so carrying a sword does not remove the player’s drill upgrade. Keep completed missions separate from current material counts. Store paused mining on its deposit, using the game’s existing area/session memory.
- **Illustrations and performance:** use separate reusable actors for interactive food trees, bushes, wood and enemies. Give moving actors matching front/back/side views. Keep enemy navigation and animation local to the active area and unload them with it, following the existing scenery/wildlife approach.

The current game remembers progress only while the session remains open. This proposal preserves that scope. Browser save/continue would be a separate, useful future task as the adventure grows; it was not requested in this discussion.

**Later backlog**

| ID | Task | What still needs deciding |
| --- | --- | --- |
| L01 | Frost Canyon yetis | Chasing behaviour, readable attacks, increased enemy health, and the next sword/mining upgrade. Requested at 01:59–02:22 and 05:53–06:19; build after Earth is fun. |
| L02 | Ember Dunes enemies and upgrades | Choose the creature first, then tune its behaviour and equipment requirements. The discussion asks for harder opponents and new upgrades, but names no third-world enemy. |
| L03 | Fishing in the ponds | Fishing rod acquisition, simple catch interaction and fish inventory. Requested at 03:34–03:46 and explicitly deferred in favour of fruit first. |
| L04 | Cooking at camp | Cooking station, recipes and how cooked food improves recovery. Requested at 03:46–03:59 and deferred. Introduce after food and fishing have a purpose in play. |
| L05 | Full tree chopping | If E07 starts with fallen wood, add a chopping tool, reusable tree poses, fall/stump states and a regrowth policy later. This avoids requiring an entire forestry system for the first sword prototype. |
| L06 | World unlock rules | The discussion tentatively links the sword to later-world access at 01:20–01:33. Decide whether travel requires equipment, mission completion or remains freely available; travel is currently open for testing. |
| L07 | Browser save and continue | Additional recommendation: decide what survives closing the browser, then add versioned save data for inventory, equipment, missions, mining progress, discoveries and companion friendship. |

**Current review checkpoint**

Play the complete [Earth adventure](EARTH_ADVENTURE.md): gather resources, craft both tools, fight a surface snake and a mine rat/bat, use fruit, find Buddy and revisit unloaded areas. Tune resource spacing, warning times and damage with Jeremy before adding later-world combat or the remaining mining-progress/spawning ideas.
