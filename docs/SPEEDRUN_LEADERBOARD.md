# Three-world speedrun leaderboard

The welcome screen offers **Start speedrun**, **Explore for fun** and **Best
times**. A run begins when Earth's initial setup is ready, after the welcome and
initial world loading and first draw. Speedruns use real elapsed time: menus, travel, background
tabs and later area loading count. Reloading or confirming R starts fresh gameplay. Completed results are kept on the device;
Best times → Last result can reopen the latest finish after restarting.

The finish line is **all 14 story quests**: six on Earth, four on Frost Canyon
and four on Ember Dunes. Earth's four optional challenges do not block finishing;
Nova's temporarily paused rocket repair quest is excluded. Story handoffs can
be completed in any order once their real items and equipment are ready. The rocket remains
available from the start. Defeated enemies and recoveries appear as bonus
statistics, without changing the time ranking. Each defeated enemy counts once;
scaring wildlife does not count as a defeat.

The final story handoff opens **Adventure complete!** and stops the clock once.
Players can post a nickname, view best times, keep exploring, or return to the
welcome screen for a new adventure. Relaxed play also has a completion screen,
but cannot post a ranked time. Results show hundredths; the compact HUD shows
minutes and seconds plus story progress. Opening a leaderboard pauses combat
while the speedrun clock continues.

## WordPress installation (recommended on WP Engine)

Build the small installer with `python tools/package_wordpress_scores.py`.
In WordPress, select **Plugins → Add New Plugin → Upload Plugin**, upload
`build/sunny-scout-scores.zip`, install and activate. Activation creates one
non-autoloaded score record in the existing WordPress options table. There are
no database credentials or schemas to configure, and no game data files to write.
The plugin starts a fresh board; it does not import old file-based scores.

Click **Play Sunny Scout** beside the plugin, or under **Tools → Sunny Scout
Scores**, and share that Play link. It uses `/index.php?sunny_scout=play` so
plain permalinks and a root-hosted game `index.html` both work. The plugin detects
existing exported game files in the WordPress root or `/play/`, preserves any
versioned asset base URL, and runs the full-screen game using those assets.
The plugin ZIP contains only its three small source/readme files, not the game.

The new Play link is required for database-backed scores in existing browser
builds. The page directs their score requests to WordPress REST before they
reach the old physical PHP file. A standalone game HTML/PHP file is served
outside WordPress, so installing a plugin cannot intercept that old URL.
No file rewrites, permission changes, `.htaccess` edits or game re-upload are
performed. Root `index.php` is the existing WordPress entry, not a new file.

Updated native Godot builds use
`https://playsunnyscout.com/index.php?rest_route=/sunny-scout/v1/leaderboard`.
The same REST route works for browser and native clients; GET cache-busting uses
`&` when the URL already has query parameters. New browser builds also honor
the same-origin endpoint supplied by the plugin's Play page.

Database updates use binary compare-and-swap with bounded retries, so concurrent
players do not overwrite each other's starts or scores. The state is read
straight from the database instead of trusting a cached WordPress option.
Deactivation and reactivation retain scores. Uninstall does not delete them.
The existing campaign rules, server timing, rate limits and public/private field
boundaries are retained. This is score storage, not game-progress saving.

## Standalone PHP host (legacy file backend)

Upload **all 31 files** inside `build/web/`, including
**`api/leaderboard.php`**, to `/play/`. The compiled game still works on static
hosting, but shared scores require **PHP 8.1 or newer**. WP Engine supports PHP;
no WordPress plugin, login, SQL table or database connection is used.

The endpoint creates **`/play/api/data/scores.php`** at runtime. This is a
human-readable JSON text document with a short PHP access guard. It contains
best times and temporary run records; it does **not** contain saved game progress.
Read public scores through `/play/api/leaderboard.php`, which returns only the top
10 nicknames/times/statistics. Keep the data file private; back it up via SFTP.

PHP must be able to create/write `/play/api/data/`. The default permissions are
private to its PHP user; do not make the directory world-writable. If your host
requires another persistent location, set the PHP environment variable
`SUNNY_SCOUT_DATA_DIR` to a writable private directory. Exclude
**`/play/api/leaderboard.php`** from any host/page cache if necessary. The endpoint
also sends `Cache-Control: no-store` and reads use a fresh query parameter.

Versioned deployments install the endpoint in stable `/play/api/`, while game
assets remain under `/play/releases/<hash>/`. Neither deployment nor rollback
deletes or replaces `/play/api/data/`. Manual uploads likewise contain code only,
never a blank data file that could overwrite existing scores. Preserve the data
folder when updating the game.

## Posting and fairness

A server-issued run token starts the official server clock. Small network delays
can make it differ slightly from the local HUD clock. Completing all story
quests records its finish before the player types a nickname. Retrying a finish
or post cannot create a duplicate or change an already recorded server finish. The board keeps
the fastest time per nickname (case-insensitive), retains the top 50, and displays
the top 10. Nicknames use 2–16 simple letters, numbers, spaces, hyphens or
underscores. No real name or account is needed; names are not reserved accounts.

WordPress updates use atomic database comparisons. The standalone backend holds
a file lock and atomically renames a complete replacement document.
Malformed requests, excessive starts, invalid names, expired tokens and incomplete
quest lists are rejected. Private tokens are never included in the public list.
Temporary starts expire after six hours; posted best times persist. Corrupt stored
data causes an error instead of being silently overwritten.

This is a friendly leaderboard, not cheat-proof competitive verification: the
server measures time, while the browser reports quest completion. Rules carry a
campaign version so later changes can use a different board. If connectivity or
storage fails, the adventure and local finish still work; an unverified run cannot
post to the shared board. The completion button shows **Retry and post** after a
failed finish check, and **Post my time** after successful verification. Both
finish checks and posts can be retried. An already recorded server finish keeps
its original time; if the first finish request never reaches the server, the
server clock includes the outage until the first successful finish request.

Every timed finish is also saved automatically. Native builds use
`user://speedrun_scores.json`; browser builds synchronously save to their own
site's local storage so an immediate reload cannot restore an older result.
If browser local storage is unavailable, Godot's user filesystem is used as a
fallback; browser filesystem persistence may be delayed.
**This device times** shows up to 50 recent local results, sorted fastest first;
it is separate from the verified shared leaderboard. With no starting token,
the completion button becomes **Save on this device**, which updates the nickname
without pretending a local result was posted online. Local results stay in this
browser profile or Godot user data, not across devices, and are lost if that data
is cleared. Only the latest completed result retains its private token for
retrying a post after reopening **Best times → Last result**. Starting tokens
still expire after six hours. This saves completed times, not game progress.

## Validation

- `tests/wordpress_score_rules.php`: plugin rules and legacy campaign compatibility,
  server timing, quest validation, frozen/idempotent results and privacy.
- `tests/test_wordpress_scores.py`: disposable real WordPress/MariaDB, actual ZIP
  upload/activation, database API and 16 concurrent starts, browser registration
  with read-only existing root game assets, real Godot finish/post through the
  query-based REST endpoint, root and /play/ detection and versioned bases.
  Requires Docker images `wordpress:php8.3-apache` and `mariadb:11.4`, Godot,
  Playwright and Chromium. It disables email/external WordPress HTTP requests
  in the fixture and never contacts or changes production.

- `tests/speedrun.gd`: modes, welcome leaderboard without loading a world,
  monotonic timing through menus, exactly 14 story quests, optional exclusions,
  actual enemy defeat counting, one completion, offline autosave/local board,
  nickname updates without duplicate records, and fresh reset.
- `tests/leaderboard.php`: storage, tokens, exact quest IDs, server time,
  idempotent finishes/posts, name validation, best-time replacement, concurrent
  writers and protection against overwriting corrupt data.
- `tests/test_leaderboard_http.py`: disposable PHP HTTP server, real Godot client
  registration, failed-finish retry through actual paused-screen touch input,
  submission/rank, saved-result restore, request validation and concurrent PHP
  workers. `SCOUT_TEST_PHP` can select the PHP executable.
- `tests/test_leaderboard_browser.py`: the actual exported Web welcome board,
  registration after the world's first draw, in-game board, Last result and
  mouse saving followed by an immediate reload, using local PHP, Playwright and
  Chromium with disposable score data.
- `tests/test_wpengine_deploy.py`: full deployment integrity, rollback and retained
  scoreboard data, using an isolated filesystem instead of a hosting account.

No test hooks or seed data are included in the production browser build.

## Diagnosing server save failures

If reading scores works but starting a run returns HTTP 503, inspect the PHP
error log for **Sunny Scout scoreboard:**. The endpoint records the operation,
exception class and server error; filesystem write/rename failures include the
underlying PHP error. Browser responses remain generic. Request bodies, run
tokens, nicknames and client addresses are not logged by this diagnostic.
A corrupt stored JSON document is also logged without overwriting it.

WordPress audit events and HTTP access statuses alone do not identify the
exception. Install the updated `server/leaderboard.php` at
`/play/api/leaderboard.php`, reproduce once by starting a speedrun, then read
the new PHP log entry. Preserve `/play/api/data/`; do not delete scores or
change permissions without first identifying the actual error.
