# Sunny Scout — Earth story browser build

The complete browser game, exported with Godot 4.6.3 from source commit `d6974b19a453b6983592274ab9e70871f9677ec6`. The editable Godot project is on `main`.

## Upload

Download this branch with **Code → Download ZIP** and unzip it. Upload **everything inside `build/web/`** into your website's game folder, such as `/play/`. Replace the entire set of **30 files**, preserving `earth_chunks/`, `frost_chunks/` and `ember_chunks/` (six JPGs in each). Keep the two hashed `scout-backdrop-*.jpg` / `scout-logo-*.png` loading assets. Serve over HTTPS; opening `index.html` directly as a local file will not run the game.

The intended site is https://playsunnyscout.com/play/. Publishing this build branch does not upload it to WP Engine. Manual deployment instructions are in `docs/DEPLOY_WPENGINE.md` on `main`.

## Play Earth's story

Start exploring, then talk to **Rowan** beside camp with **E** or the touch action. **J / Open missions** recalls the seven character missions:

1. Rowan — craft the copper sword (3 copper + 2 fallen wood).
2. Bea — deal with her designated snake, recover the woodland supply box and return it.
3. Otis — build the hand drill (5 copper), drill away the rockfall and open Old Quarry.
4. Mara — bring 4 copper + 2 blue crystals to upgrade both tools together.
5. Iris — explore the circular ruins, defeat the ruins snake and open the expedition locker.
6. Finn — recover the seal kit and bring the damaged suit plus 2 wood to repair the spacesuit.
7. Nova — recover the engine part in Crystal Depths and fit the navigation unit, regulator and engine component to repair the rocket.

Earth has enough materials for every recipe, with supplies left over. Early kills, pickups and crafts count. Closing a conversation preserves items; returns, upgrades and repairs happen only on their explicit final actions. The quarry stays open and the repaired rocket unlocks travel. Other planets retain their existing friendly aliens and mining objectives; no new off-world enemies, fishing or cooking are included.

**WASD / arrows** walks. **1** selects the mining tool; **2** selects the owned sword. **Space** mines nearby ore with the mining tool or attacks; **E** gathers, talks and uses objects. The reinforced sword deals 5 damage instead of 3, and the upgraded drill completes Earth mining 25% sooner. On Earth, movement, damage, changing tools or pausing keeps each deposit's work. Returning resumes the remaining time. Rockfall/locker/engine drilling also pauses and resumes. **R** asks before a new game.

Use landscape on iPad: a thumb pad handles movement; separate action, equipment and attack buttons work with other fingers. The mission journal has Up/Down buttons as well as scrolling. Berries heal one heart, apples two. Buddy can be found outside Landing Meadow and follows you into mines, where he scares rats and bats away. Snakes and food plants remain Earth-only. The game stays silent. Progress lasts while the session is open; reloading starts fresh.

The illustrated loading screen, wooden signs, exploration mist, sparse randomized minerals, water/wildlife animation and bounded scenery streaming are retained. Story actors and quest objects use fitted art and small session records; opening the journal never downloads distant maps. Review scenes/screenshots and test code are excluded from the playable export.

## Checked

Native checks cover the full seven-character chain with real resource gathering and exact recipes, early actions/cancelled handoffs, stable snake identities, quarry collision and transition restrictions, actual upgrade speed/damage, unique suit/rocket parts, launch checks, connected routes, water-safe placement, persistent mining, warned/capped encounters, session reset and touch controls. Randomized wood placement is checked across sixteen fresh layouts. Browser review covers all seven character conversations in desktop/tablet emulation, the production welcome/start flow and mission journal. Physical iPad Safari testing remains useful for device-specific performance.
