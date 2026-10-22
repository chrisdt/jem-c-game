# Sunny Scout — Frost paths and off-world mines

Full browser game exported with Godot 4.6.3 from source commit `94e2469b3abb8891013f50baa047a12ced2bf98c`.
Editable project: `main`. Build release: `cd9a628b599663b3f7d5`.

## Upload to WP Engine

Upload **everything inside `build/web/`** to your website's **`/play/`** folder.
Replace all **31 files**, including **`api/leaderboard.php`**, both hashed loading
art files and the six JPGs in each of `earth_chunks/`, `frost_chunks/` and
`ember_chunks/`. Serve over HTTPS at https://playsunnyscout.com/play/.
Opening `index.html` as a local file does not run the browser game.

**Shared scores need PHP 8.1+ and a writable `/play/api/data/` directory.** The PHP
endpoint creates that directory and the protected JSON text file `scores.php`.
No database, WordPress plugin, player login or saved adventure is required.
Preserve the data folder when updating; never replace it with an empty folder.
Exclude `/play/api/leaderboard.php` from hosting/page caching if necessary.
An alternative private writable directory can be set with `SUNNY_SCOUT_DATA_DIR`.
Static-only hosting still runs the adventure but cannot share scores.

Publishing this branch does not upload to WP Engine.

## This update

- Clears the snowy outcrops beside Canyon Camp's Frozen Basin and Prism Pass
  signs, joins the footprint trails and opens the walking connections. The
  Glacier Crown exit from Prism Pass continues through clear snow to the edge.
- Rare minerals now take five seconds before drill bonuses. Earth, Frost and
  Ember deposits retain their own progress after movement, damage, menus and
  leaving an area. Crystal Drill: three seconds; Magma Drill: 2.25 seconds.
- All nine mines have hostile crawling and flying creatures. Frost has Crystal
  Crawlers and Icewings; Ember has Ash Crawlers and Cinderwings, with original
  four-pose animations, warned attacks, safe entrances, solid walls and
  persistent partial damage/defeats. Surface creatures remain friendly.
- Moves the Sunforge core onto the lantern-side crate in Sunfire Cavern, and
  Obsidian Rise's cooled-lava mission rock and guardian into the central sand.
- Food concept art proposes frostberries and emberfruit as wild pickups.
  Prepared meals remain camp-recipe ideas only, with local alien ingredients;
  food is not implemented in this build.
- Checked all nine mines, both off-world stories, 33 Frost walking routes,
  twelve interrupted mining jobs, seeded ore placement, keyboard/touch controls
  and startup. Includes the previous controls guide and world fixes.

## Play and compete

- **Start speedrun:** the clock starts after Earth has loaded and painted.
  Complete **14 story quests**: six on Earth, four in Frost Canyon and four in
  Ember Dunes. Optional Earth challenges are not needed to finish. The rocket
  remains unlocked from the start; Nova's repair quest is paused.
- Menus, travel, background tabs and later loading count. The final story
  handoff stops the clock and opens **Adventure complete!**
- Post a nickname (2–16 letters, numbers, spaces, hyphens or underscores).
  The server freezes the official finish before nickname entry. The board keeps
  one fastest time per nickname and displays the top 10. Enemy defeats and
  recoveries are bonus statistics, without time penalties or ranking points.
- **Best times** opens the shared board from the welcome screen; the HUD timer
  also opens it during a run. Combat pauses while the clock keeps running.
- **Explore for fun** keeps relaxed play and a completion screen without posting
  a ranked time. Keep exploring after finishing or choose **New adventure**.
- Reloading or confirming reset starts fresh. No mid-run progress saving or
  sound is added. Shared best times persist independently of game resets.

## Controls and worlds

**WASD / arrows** walks. **E** talks or opens the rocket. **E / Space** gathers
ready objects; Space mines with the mining tool selected. Away from ready
interactions, **Space** attacks. **1** selects the tool, **2** the owned sword,
**3** uses earned antidote. **J / Quests** opens the current world's quest list.
**R** asks before resetting. On touch, use the movement pad, action/attack buttons
and equipment icons. Landscape is best on iPad.

Start with Earth's neighbours and workbench. Snow Sprites in Frost Canyon offer
the Frostfang Sword and Crystal Drill. Sunstone Folk in Ember Dunes offer the
Sunfang Sword and Magma Drill. Materials, equipment and upgrades work across all
three worlds; finished crafting cards disappear. The existing wildlife,
companions, yetis and venomous scorpions remain part of the adventure.

## Verification

This update passed story/combat/travel/touch checks on all three worlds, both
Earth repair modes, a flood-fill route audit across all eight frozen areas,
Nix-before-Pip with actual landmark pickup/cancel/return/crafting, every one of
the 24 Frost handoff orders, shared quest-item consumption and recipe-race checks.
Browser views verify snow fragment visibility, the central landmark heart,
Nix's ready forge action before Pip and the journal's ready/missing states.
Review helpers are not included in this production build.

Existing infrastructure: Gameplay regression checks cover quests, exact crafting costs, combat, touch,
travel, pickups and reset. Server and HTTP tests cover tokens, server timing,
nickname validation, concurrent file writes, idempotent posting and persistent
scores. Deployment tests preserve runtime data through updates and rollback.
Browser checks cover the production welcome board, first-draw registration and
in-game board, plus completion, nickname posting and refreshed ranked results.
All 31 packaged files are hash-checked against the export. Review helpers and
sample scores are excluded from this build.

Source setup and detailed score rules: `docs/SPEEDRUN_LEADERBOARD.md` on `main`.
