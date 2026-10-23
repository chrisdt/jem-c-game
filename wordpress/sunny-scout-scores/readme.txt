=== Sunny Scout Scores ===
Contributors: sunnyscout
Requires at least: 6.0
Requires PHP: 8.1
Stable tag: 1.1.0
License: GPLv2 or later

Shared game scores and private Explore checkpoints using your existing WordPress database.

== Installation ==

1. In WordPress, open Plugins > Add New Plugin > Upload Plugin.
2. Upload sunny-scout-scores.zip, then Install Now and Activate.
3. Click Play Sunny Scout beside the plugin, or open Tools > Sunny Scout Scores.
4. Share the new Play link for database-backed times. It opens
   /index.php?sunny_scout=play and works without permalink changes.

The game files can stay in the WordPress root or in /play/. The plugin detects
the existing index.html and uses its assets in place. It does not include or
upload the large game build. Existing versioned asset paths are supported.

The new Play link is necessary: a directly served old index.html or standalone
PHP file is outside WordPress and cannot be intercepted by an activated plugin.
No game-file edits, directory permission changes, database credentials, rewrite
file edits or separate database setup are needed.

== Scores ==

Activation creates one non-autoloaded record in the site's existing WordPress
options table. It starts a fresh leaderboard; old file-based scores are not
imported. Deactivating or reinstalling the plugin keeps database scores.

The board keeps the 50 fastest nicknames and displays the top 10. Nicknames use
2-16 letters, numbers, spaces, hyphens or underscores. It is a friendly game
leaderboard, not an account system: names are not reserved.

The server starts and stops the official clock. All 14 story quests must be
complete. Menus and travel count. Enemy defeats and recoveries are statistics.
Repeated finishes and posts do not change a recorded finish or duplicate it.

Concurrent updates use atomic database comparisons to preserve other players'
scores. Temporary starts expire after six hours; rate-limit hashes expire after
ten minutes. Full request bodies, nicknames and private tokens are not logged.
The public board never includes the private run records or rate-limit hashes.

Leaderboard times and Explore checkpoints are separate. Existing browser/device
local times remain separate. A run that never registered online cannot be turned into
an official shared time afterward. Start a new speedrun after activation.

== Explore checkpoints (version 1.1) ==

Update the plugin AND game files to add save totems. The plugin alone cannot
add props or Continue buttons to an old compiled game. Upload the new ZIP and
choose Replace current with uploaded; existing scores and checkpoints remain.

Explore for fun shows two save totems per world: one near the starting camp
and one in a distant outdoor district. Walk close on clear ground, away from
nearby enemies, to save. The crystal gives one brief coloured pulse and an
Adventure saved message after a checkpoint is kept. While nearby, a checkpoint
can refresh after 20 seconds. Save > Save and quit keeps another checkpoint
before returning to the guide. Totems and saving are absent from speedruns.

Continue adventure resumes the most recent device checkpoint, checking for
newer online progress when connected. Use recovery code restores an online
checkpoint into another browser/device without a login. Keep that code private:
anyone with it can continue that adventure. Names are not used to find saves.
Starting a new Explore keeps the previous device checkpoint until a new one is
saved. Keep the old recovery code to return to the old adventure online.

Checkpoints include worlds/districts, position, quest flags, materials, tools,
health/poison, Buddy, picked food and wood, depleted/partially mined deposits,
explored fog and defeated enemies. Native plants and idle animals may resume
animations from rest. No account or live speedrun token is saved here.

Each adventure uses an independent non-autoloaded WordPress option, addressed
by a SHA-256 hash of a cryptographically random 128-bit recovery code. The code
is sent only in JSON POST bodies, never query strings or public leaderboards.
Requests and replies are not cached. A save is bounded to 512 KiB. Revision
comparisons reject stale writes from another device; lost-response retries are
idempotent. At most 30 new adventures per address per day can be created;
existing saves do not consume that creation limit. Saves remain when the plugin
is updated, deactivated or uninstalled; removal is an explicit site-owner action.

A device copy is written synchronously before upload. If offline, players can
still save and Continue on that device. Revisit a totem to retry online. A code
can only recover progress on another device after an online copy succeeds.

== Game clients ==

The existing browser build works through the new Play link without replacement.
Updated Godot projects use /index.php?rest_route=/sunny-scout/v1/leaderboard on
the same site. The Play page connects existing browser builds automatically.
The plugin also registers the standard WordPress REST route. The explicit
index.php form supports plain permalinks and a root-hosted game index.html.

== Privacy ==

Only a nickname is needed; do not use a real name. The private database record
contains nicknames, times, enemy/recovery counts, finish timestamps, short-lived
run tokens and hashed addresses for rate limiting. Explore checkpoints also contain the game progress described above; recovery
codes act as private access keys. No external service receives scores or saves. Uninstalling this plugin does not automatically erase its score record.

== Changelog ==

= 1.1.0 =
Private Explore database checkpoints, recovery-code API, no-cache responses,
independent revision checks and Play-page save endpoint configuration.

= 1.0.0 =
Automatic database setup, existing game-file detection, Play link, public score
API, bounded rate limits and concurrent update protection.
