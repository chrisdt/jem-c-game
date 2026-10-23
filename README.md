# Sunny Scout — Explore save totems

Godot 4.6.3 browser export. Source: `5b2cbfc39100020d30834183871859826eb7c375` on `main`.
Build release: `5a7322d85937cafdc2ed`. All 31 browser files verified against the export.

## Install both updates

1. In WordPress, Plugins > Add New Plugin > Upload Plugin: upload
   `sunny-scout-scores.zip` (version 1.1.0). Choose Replace current with uploaded
   if WordPress prompts. Existing scores and saved adventures are retained.
2. Replace your current exported game files with **everything inside
   `build/web/`**: all 31 files, including the streamed scenery and loading art.
   Keep them in their existing WordPress root or `/play/` location. Do not
   replace WordPress's `index.php`, `wp-config.php` or other WordPress files.
3. Open the plugin's **Play Sunny Scout** link:
   https://playsunnyscout.com/index.php?sunny_scout=play
   Your exact `/play/` host redirect can keep pointing to that link. Asset
   requests beneath `/play/` must remain accessible.

Both the plugin update and game update are needed for save totems. Old game
builds continue to use the existing leaderboard but do not gain the new props.
No database credentials, login setup or score-file permission changes are needed.
Publishing this branch or downloading this ZIP does not install it on your site.

## Explore checkpoints

- Exactly two totems per world: one near the starting camp and one on a distant
  outdoor screen. Earth: Landing Meadow/Sunstone Ridge. Frost: Canyon Camp/
  Glacier Crown. Ember: Mesa Camp/Obsidian Rise.
- Walk close on clear ground, away from nearby hostiles, to keep a checkpoint.
  The crystal gives one brief green, icy blue or amber pulse and an Adventure
  saved caption. Checkpoints can refresh while standing nearby after 20 seconds.
- Save > Save and quit is available near a safe totem. Continue adventure on the
  guide restores the checkpoint. Use recovery code restores an online save on
  another browser/device without a login. Keep that private code to recover it.
- State includes quests, worlds/position, tools, materials, health, Buddy,
  picked foods/wood, depleted and partly mined deposits, enemies and exploration.
- A synchronous device copy is kept before online upload. Offline Continue works
  on that device; another device requires a successful online copy. Newer online
  saves and interrupted uploads are handled without silently overwriting them.
- Totems and checkpoint controls are hidden in speedruns. Continue/recovery
  always start untimed Explore mode. Leaderboard timing and scores stay separate.
- New Explore keeps the previous device checkpoint until a new one is saved.
  Previous online adventures remain available with their own recovery codes.

## Verified

Actual ZIP upload/activation with WordPress 7.1.3 and MariaDB 11.4; six reachable
locations; JSON state/device reload; local and online save/Continue; private
new-device recovery; paused touch Save and quit; interrupted uploads; concurrent
saves/conflicts; malformed state; no-cache/private records; score retention;
Chromium gameplay/save/refresh/Continue; real Godot 14-quest finish/post; startup,
reset and speedrun regression checks. Two unreferenced legacy images are omitted
from the browser pack; all current scenery and game content remain included.

Editable Godot project:
https://codeload.github.com/chrisdt/jem-c-game/zip/5b2cbfc39100020d30834183871859826eb7c375
Details: `docs/EXPLORE_SAVES.md` and `docs/SPEEDRUN_LEADERBOARD.md` on `main`.
