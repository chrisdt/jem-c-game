# Explore checkpoints

Explore mode has exactly two save totems on each world: Landing Meadow and
Sunstone Ridge on Earth; Canyon Camp and Glacier Crown on Frost; Mesa Camp and
Obsidian Rise on Ember. They use the approved moss/emerald, snow/cyan and
basalt/amber designs. Locations fit the authored walkable floor, clear of ore
and people. The normal fog reveals them. They do not add floor or block travel.

Walk within 88 world units with a clear ground approach and no living hostile
within 165 units. A checkpoint is kept on the device before an online upload.
Its crystal gives one smooth 0.8-second pulse in the world's colour, with a
small Adventure saved caption for three seconds. It never flashes repeatedly
within a pulse. While standing near a totem, checkpoints can refresh every 20
seconds; leaving beyond 125 units re-arms a new approach. No online request is
issued every frame. Flight, map transitions, dialogs, help and combat prevent
automatic checkpoints. Save > Save and quit is available near a safe totem.

Totems and the Save button are hidden during speedruns. A timed game cannot
capture or apply an Explore snapshot, start from Continue, or post its restored
progress to the leaderboard. Continue and recovery explicitly start untimed.
Score tokens and server timing never enter an Explore snapshot.

## Install both updates

1. Build/upload the updated Sunny Scout Scores plugin ZIP (version 1.1.0).
   WordPress's Replace current with uploaded preserves the existing database.
2. Replace the exported game files with the new complete browser build (all 31
   files, including streamed scenery and loader art), or deploy through the
   established authorized deployment workflow.
3. Use the plugin Play link, `/index.php?sunny_scout=play`, or the existing exact
   `/play/` host redirect to that link. Game files may remain in their existing
   root or `/play/` location. Do not redirect `/play/*` asset requests.

Unlike the scoreboard adapter for old builds, new props and game state require
an updated game build. Installing this plugin update alone does not add them.
No production upload or WordPress changes are made by packaging the updates.

## Continue and recovery

Continue adventure uses the device's saved Explore checkpoint. It checks for a newer online revision and prefers it, while preserving its
own newer offline work over an older online copy. A network failure falls back
to the device copy. Recoveries are validated by the
game before replacing a previously saved device checkpoint. Invalid or
incompatible snapshots preserve the prior save and return to the guide.

Use recovery code reads an online checkpoint on a different device, with no
login. The private random code has eight groups of four hexadecimal digits;
letters are case-insensitive and hyphens/spaces are optional when entering it.
The Save panel shows/selects it for copying. Anyone with the code can continue
that adventure; a nickname is not used for save ownership. The player must
retain it to recover after clearing browser data. A checkpoint saved only on a
device cannot be recovered elsewhere until upload succeeds.

Starting New Explore or confirming R starts fresh progress with a new save
identity at its first checkpoint. The previous device checkpoint remains until
that new checkpoint is kept. The previous online save remains accessible using
its own recovery code. Starting a speedrun does not replace an Explore save.

## Stored state and failure handling

`ui/adventure_snapshot.gd` explicitly lists resumable fields. It serializes only
bounded primitive JSON, keyed maps and Vector2 values, never Nodes/resources,
GDScript objects or executable `bytes_to_var` data. This preserves integer
region keys, ore positions, depletion and partial mining work, quest flags,
tools, materials, health/poison, Buddy, picked fruit/wood, hostile health and fog
masks. The masks use bounded DEFLATE byte arrays; native idle animations restart.
Restoring uses the normal streamed map loader and does not unlock quest gates.

The device copy uses synchronous browser localStorage (native: atomic file
replacement). WordPress receives bounded JSON POST requests at
`/index.php?rest_route=/sunny-scout/v1/adventure`. The plugin injects the proper
same-origin endpoint into its Play page. Native uses that route on the live
site. Tests can override both endpoint and local storage path.

Each adventure has one non-autoloaded WordPress option named with a SHA-256 hash
of its 128-bit cryptographically random recovery code. It does not share a row
with scores. Recovery codes, snapshots and full request bodies are excluded from
application error logs, public boards and query strings. Origin validation,
JSON content-type enforcement, request/depth/512-KiB limits and expiring limits
on new saves bound public access. Checkpoints have independent optimistic
revision checks. A stale device cannot overwrite newer progress from another
device. Retrying a successful checkpoint after a lost response is idempotent;
the client can rebase a later pending device checkpoint only over its own
recorded uncertain checkpoint IDs. Other conflicts show Continue online save in the Save panel so the player can
explicitly resume the newer online adventure. Plugin updates/activation do not reset stored data.

## Validation

`tests/adventure_saves.gd` checks all six reachable outdoor locations, absence
on other districts, real JSON/device reload/Continue through streamed maps,
all-world state and partial mining, pulse feedback and speedrun isolation.
`tests/wordpress_adventure.gd` runs against disposable WordPress/MariaDB to check
actual approach-triggered saving, new-device recovery, newer-online Continue,
and a real touch Save and quit while paused. `tests/test_wordpress_scores.py`
also checks API privacy, no-cache responses, idempotency, concurrent saves,
stale-write conflicts, score retention, browser localStorage/reload and the
existing full Godot speedrun finish/post flow. It never contacts production.
