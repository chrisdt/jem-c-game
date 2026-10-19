**Landing Meadow animation trial — 19 October 2026**

Chris and Jeremy approved the [HUD and Earth illustration concepts](concepts/earth-hud-v1/README.md), then asked to try the animations on the first Earth screen before progressing through the larger backlog.

The confirmed changes from that review are a smooth slithering snake, a straight directional sword jab in place of a sweeping slash, readable hit feedback, smoke on defeat, no sound, one heart from a berry bush, and two hearts from an apple tree.

**Try it**

- Start a fresh game and stay on **Landing Meadow**. Walk right from camp to find the first snake, or explore the rest of this district for the other two.
- **1:** mining pick or owned hand drill. **2:** trial sword. **Space:** attack in the direction Scout is facing. A sword jabs; a pick or fitted drill uses its mining-tool poses. **E:** use nearby camp, rocket or mining interactions.
- On iPad, drag the pad, tap the tool slots, and tap **Attack** (pick/drill) or **Jab** (sword). Equipment and attack touches have independent finger ownership, so a held movement thumb does not block them.
- The sword is available immediately for this test and only appears during the jab; no weapon floats beside walking or idle Scout. The drill still uses the existing five-copper purchase, and selecting the sword does not remove the earned drill.
- A bite costs half a heart. Each world has only two fruit trees and two berry bushes spread across its districts. Landing Meadow has one berry bush and no fruit trees. Explore the trails to find apples. A revealed berry bush gives one heart, and an apple tree gives two. Full health leaves fruit unpicked. At zero health, Scout returns safely to camp with five hearts and collected materials intact.
- **R** opens a paused **Reset game?** prompt: **Yes** starts a fresh session; **No** or **Escape** continues the current game. Reloading also starts fresh. Defeated snakes and harvested plants stay that way during the current session, including when visiting a mine, another district or another planet.

**What to review with Jeremy**

- Does the smaller snake look consistent and slither smoothly sideways, toward Scout and away from him?
- Is each straight jab easy to aim in all four directions, and is the hit flash/knockback clear?
- Do three sword hits versus nine pick/drill hits per snake feel right? Is the half-heart bite gentle enough, with enough time to react to the warning?
- Are the hearts, mission panel and two equipment slots readable without hiding the world? Does the selected slot stand out?
- Are healing plants easy to recognise, and does harvesting clearly remove fruit while retaining the plant?
- Can Jeremy switch tools and jab comfortably on touch while his other thumb stays on the movement pad?

**Scope**

Snakes, attacks and equipment slots run only on Earth’s first surface map. Sparse healing plants are available across all three planets, and remaining hearts stay visible outside the meadow while Scout is hurt. Leaving it hides and pauses the trial and restores the normal controls, outfit and HUD for the current area. Returning resumes its state. The master audio bus is muted throughout the game; Buddy’s existing visual bark still works silently.

The trial contains three small snakes with bounded local movement. Each world has two apple trees and two berry bushes, with one plant at most per district and none in mines. Earth plants use safe grass; off-world roots check snow/sand floor footprints, rocks, lava, doors and ore. Plants move to nearby clear grass when a randomized ore layout occupies a preferred spot. They are separate reusable actors with fitted atlas regions and subtle wind motion. Snake animation uses six directional phases blended continuously, with a stable head anchor. Sword poses use measured boot anchors, so changing direction or thrust phase does not move Scout’s feet off the ground. Production PNG originals are retained; `tools/build_trial_anchors.py` measures alpha to regenerate anchors without editing the images.

The first sword does not yet need wood or crafting. Mining progress still resets when cancelled, as before. Mining-triggered encounters, full mission/crafting progression, tree chopping, other-world enemies/upgrades, fishing, cooking and disk saving remain separate backlog tasks.

**Validation**

`tests/earth_trial.gd` checks all four sword/pick/drill attack directions, the one-third pick/drill damage, three-sword/nine-tool hit thresholds, hidden idle sword, bounded snake silhouettes, single-hit and cooldown rules, front-only range and floor clearance, snake defeat/smoke cleanup, a real warned bite, half-heart invulnerability and camp safety/recovery, tool ownership, distinct snake views, safe minute-long movement, 30/144fps movement consistency, independent touch fingers, first-screen scope, menu pause and muted playback. `tests/healing_gardens.gd` checks the twelve plants across all fifteen districts, exact healing, full-health/menu protection, discovery fade, grass/floor clearance, bounded active nodes/textures and harvest memory through every mine and rocket trips. Existing smoke, HUD/drill, startup, touch and randomized-ore checks cover the surrounding game.

Browser review uses a temporary isolated fixture for pose, hit, smoke, healing and multitouch inspection. The production build is also checked through its normal welcome/start flow. Desktop Chromium and tablet touch emulation complement the native checks; a physical iPad remains useful for judging finger reach and device performance.
