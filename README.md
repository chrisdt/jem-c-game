# Sunny Scout — mobile fullscreen and camp totems

Godot 4.6.3 browser export. Source: `417561c8bd25aa32e17647a919702beea0c8ce6f` on `main`.
Build release: `d0e0699dd603de6ec49c`. All 31 browser files verified against the export.

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

## Mobile full screen

Tap the four-corner button near the top of the page to enter or exit full screen.
On iPhones without browser fullscreen support, it shows Safari's Share > Add to
Home Screen steps. Enable Open as Web App if shown, then open the new Sunny Scout
icon. A tap is required; browsers do not allow automatic fullscreen on URL load.
The existing WordPress plugin needs no update.

## Changes

- Added a persistent 44px fullscreen touch control with request-failure feedback,
  Safari API support and Home Screen guidance. Already-installed standalone
  mode hides the extra button. This does not add offline play.

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
Mobile Chromium touch fullscreen entry/exit passed on the guide and during real
continued gameplay. API rejection, simulated iOS/prefixed Safari and standalone
mode passed. A physical iPhone was not available for testing.

Editable Godot project:
https://codeload.github.com/chrisdt/jem-c-game/zip/417561c8bd25aa32e17647a919702beea0c8ce6f
Details: docs/EXPLORE_SAVES.md and docs/MOBILE_PLAY.md on main.
