# Sunny Scout — Earth exploration fixes

The complete browser game, exported with Godot 4.6.3 from source commit `eb5bcb3f049241f34d73482933460123a9f794e4`. The editable Godot project is on `main`.

## Upload

Download this branch with **Code → Download ZIP** and unzip it. Upload **everything inside `build/web/`** into your website's game folder, such as `/play/`. Replace the entire set of **30 files**, preserving `earth_chunks/`, `frost_chunks/` and `ember_chunks/` (six JPGs in each). Keep the two hashed `scout-backdrop-*.jpg` / `scout-logo-*.png` loading assets. Serve over HTTPS; opening `index.html` directly as a local file will not run the game.

The intended site is https://playsunnyscout.com/play/. Publishing this build branch does not upload it to WP Engine. Manual deployment instructions are in `docs/DEPLOY_WPENGINE.md` on `main`. Reload the page after replacing the whole build; start a fresh session to see the new quest placements.

## This Earth update

- All seven Earth neighbours use new compact artwork fitted to Sunny's visible height. Rowan and Otis no longer tower over him.
- Completed quest characters disappear in a small smoke puff after their final interaction closes, and stay gone through area changes. Starting a new game restores them.
- Wider automatic trail and mine triggers detect the whole opening, including diagonal and slow-frame crossings, with safe arrivals and no immediate bounce back.
- Corrected Moss Mine's central doorway apron and northern corridor, plus the clear floor inside Sunstone Ridge's ruins. The walking audit covers all five Earth districts and three mines; see `docs/EARTH_WALKING_AUDIT.md` on `main`.
- Boarded up 32 decorative mine doorways. The three usable surface exits stay visibly open.
- Moved Finn's seal kit to clear ground beside the pictured Pinewood Trail campsite tent. Dialogue and quest instructions name the new location.
- One smaller single-log illustration for all fallen wood and its inventory icon. Wood and small gear pickups have low profiles and close ground shadows.
- Moved the quarry rockfall farther right, cropped by the map edge and covering the complete sign. Sunny drills its visible front face from clear ground, with the progress bar unobscured.

Later-world gameplay retains its existing behavior. No new off-world missions or enemies, fishing or cooking are included.

## Play Earth's story

Start exploring, then talk to **Rowan** beside camp with **E** or the touch action. **J / Quests** recalls the seven character missions; select a title to expand its instructions and progress. Completed quests remain in the journal after their characters depart.

1. Rowan — craft the copper sword (3 copper + 2 fallen wood).
2. Bea — deal with her designated snake, recover the woodland supply box and return it.
3. Otis — build the hand drill (5 copper), drill away the rockfall and open Old Quarry.
4. Mara — bring 4 copper + 2 blue crystals to upgrade both tools together.
5. Iris — explore the circular ruins, defeat the ruins snake and open the expedition locker.
6. Finn — recover the seal kit at Pinewood's campsite and bring the damaged suit plus 2 wood to repair the spacesuit.
7. Nova — recover the engine part in Crystal Depths and fit the navigation unit, regulator and engine component to repair the rocket.

Earth has enough materials for every recipe, with supplies left over. Early kills, pickups and crafts count. Closing a conversation preserves items; returns, upgrades and repairs happen only on their explicit final actions. The quarry stays open and the repaired rocket unlocks travel.

**WASD / arrows** walks. **1** selects the mining tool; **2** selects the owned sword. **Space** mines nearby ore with the mining tool or attacks; **E** gathers, talks and uses objects. On Earth, movement, damage, changing tools or pausing keeps each deposit's work. Returning resumes the remaining time. Rockfall/locker/engine drilling also pauses and resumes. **R** asks before a new game.

Use landscape on iPad: a thumb pad handles movement; separate action, equipment and attack buttons work with other fingers. The quest journal has Up/Down buttons as well as scrolling. Berries heal one heart, apples two. Buddy can be found outside Landing Meadow and follows you into mines, where he scares rats and bats away. He also makes living snakes retreat elsewhere in the same district without disappearing or counting as defeated. Snakes and food plants remain Earth-only. The game stays silent. Progress lasts while the session is open; reloading starts fresh.

The illustrated loading screen, wooden signs, exploration mist, sparse randomized minerals, water/wildlife animation and bounded scenery streaming are retained. Review scenes/screenshots and test code are excluded from the playable export.

## Checked

The Earth walking audit passes 30 artwork routes in both directions, 10,704 real player movement steps, 18,739 connected floor samples and 48 doorway/trail approaches. Water, walls, pillars and the locked quarry remain blocked. Native checks cover the complete seven-character campaign, exact recipes, cancelled handoffs, all character departures, pickups, combat, touch controls, randomized mining alerts, exploration and rocket travel. Browser review checks the production welcome/start flow, quest journal and Earth rendering in desktop and tablet emulation, plus close views of all changed art and props. Physical iPad Safari testing is still useful for device-specific performance.
