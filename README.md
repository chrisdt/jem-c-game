# Sunny Scout — Rocket ready from the start

The complete browser game, exported with Godot 4.6.3 from source commit `69eca113534f5af001c3f4c6ef869caf3e229086`. The editable Godot project is on `main`.

## Upload

Unzip the download and upload **everything inside `build/web/`** to your website's game folder, such as `/play/`. Replace the complete set of **30 files**, preserving `earth_chunks/`, `frost_chunks/` and `ember_chunks/` (six JPGs each), plus the two hashed loading illustration/logo files. Serve over HTTPS. Opening `index.html` directly as a local file will not run the game.

The intended site is https://playsunnyscout.com/play/. Publishing this branch does not upload it to WP Engine.

## Ready to explore

The working camp rocket is available immediately. Approach it and press **E**, or tap the contextual action button on touch, to choose Earth, Frost Canyon or Ember Dunes. Takeoff, landing and return trips work without crafting or completing quests first.

Nova's rocket-repair quest, her appearance and the engine-part pickup are temporarily paused. Their code remains in the source: set `gameplay/rocket_repair_required=true` in `project.godot` and export again to restore the original repair chain and travel restrictions. Immediate travel grants no resources, equipment upgrades or quest completion.

The six other Earth story quests remain available: Rowan, Bea, Otis, Mara, Iris and Finn. The Quests popup counts the six active quests and retains optional exploration. The welcome guide explains immediate rocket travel. Saving is deferred: progress lasts only while the current game is open; reload or confirmed reset starts fresh.

## Play

**WASD / arrows** walks. **E / Space** collects nearby revealed wood and ready quest objects. Space attacks while a snake guards an object; otherwise it attacks with the sword or mines nearby ore with the mining tool. Select the mining tool to drill quest objects; **E** talks and uses the camp workbench/rocket. **1** selects the mining tool; **2** selects the owned sword. **J / Quests** opens the expandable quest list. **R** asks before resetting.

On touch, use the movement pad and contextual action button; the separate Attack/Jab button remains available. The game is silent. Craft the sword for **3 copper + 2 wood** and the hand drill for **5 copper**. Earth characters fade in with contact shadows, wave on approach and puff away when their quests finish. Painted mine closures, wildlife, sparse minerals and exploration mist remain included.

## Checked

Fresh-game keyboard and touch rocket access, both destination planets and return trips, resets, the absence of unearned rewards, six-quest journal counts and hidden repair content pass integration checks. The active six-quest story and retained seven-quest repair story both pass complete gathering/crafting playthroughs. Flight animation, touch controls, character presentation, object routes and mission/mining persistence also pass.
