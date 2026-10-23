=== Sunny Scout Scores ===
Contributors: sunnyscout
Requires at least: 6.0
Requires PHP: 8.1
Stable tag: 1.0.0
License: GPLv2 or later

Shared game scores using the WordPress database already configured on your site.

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

This saves completed times, not game progress. Existing browser/device local
times remain separate. A run that never registered online cannot be turned into
an official shared time afterward. Start a new speedrun after activation.

== Game clients ==

The existing browser build works through the new Play link without replacement.
Updated Godot projects use /index.php?rest_route=/sunny-scout/v1/leaderboard on
the same site. The Play page connects existing browser builds automatically.
The plugin also registers the standard WordPress REST route. The explicit
index.php form supports plain permalinks and a root-hosted game index.html.

== Privacy ==

Only a nickname is needed; do not use a real name. The private database record
contains nicknames, times, enemy/recovery counts, finish timestamps, short-lived
run tokens and hashed addresses for rate limiting. No external service receives
scores. Uninstalling this plugin does not automatically erase its score record.

== Changelog ==

= 1.0.0 =
Automatic database setup, existing game-file detection, Play link, public score
API, bounded rate limits and concurrent update protection.
