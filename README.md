# Sunny Scout — camp save totems

Godot 4.6.3 browser export. Source: `16c03b63bd4cb49708b0714d74d28823e3c7299f` on `main`.
Build release: `6f0720c2cd98bcd04e40`. All 31 browser files verified against the export.

## Update the game

If Sunny Scout Scores 1.1.0 is already installed, keep your existing plugin.
Replace your exported game files with **everything inside `build/web/`**,
including all streamed scenery and loading art. Keep the existing file location
in the WordPress root or `/play/`. Leave WordPress's own index.php, wp-config.php
and other WordPress files in place.

Open the plugin Play link:
https://playsunnyscout.com/index.php?sunny_scout=play
Your exact `/play/` redirect can continue pointing to that link. Asset requests
under `/play/` must remain accessible. Packaging this ZIP does not upload it.

For first-time Explore saves setup only, install the included
`sunny-scout-scores.zip` (version 1.1.0) through WordPress Plugins > Upload Plugin.
Existing scores and saved adventures remain compatible.

## Changes

- Exactly one save totem at each world's starting camp. Frost is in the clearing
  in front of camp; Ember is on the sand above/right of the stall, above the CAMP
  sign and left of the rocket. Earth remains in Landing Meadow.
- Native/editor texture loading works from the original PNGs even when generated
  .ctex files are missing. Fresh Godot project import was also verified.
- Stone bases sit directly on small contact shadows.
- A speech bubble shows Saving... until the request completes, then Saved and
  one brief green, icy blue or amber crystal pulse. Offline saves say
  Saved on this device. No repeated flashing.
- Checkpoint data, private recovery codes, local/online Continue, all-world
  progress and partial mining remain supported. Totems stay hidden in speedruns.

## Verified

Three reachable camp placements and clear approaches; no totems on other maps;
local save/reload/Continue; missing texture cache and clean imports; normal NPC
speech-bubble regression; actual WordPress/MariaDB save, recovery and conflicts;
Chromium save/reload/Continue; existing speedrun posting. The final export was
also rendered at the relocated Frost and Ember camps without script errors.

Editable Godot project:
https://codeload.github.com/chrisdt/jem-c-game/zip/16c03b63bd4cb49708b0714d74d28823e3c7299f
Details: docs/EXPLORE_SAVES.md on main.
