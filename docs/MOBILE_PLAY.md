# Mobile fullscreen

Open the usual Sunny Scout Play URL and tap the four-corner fullscreen button
near the top of the page. It remains available on the loading page, guide and
gameplay. Tap it again to leave fullscreen, or use the browser's own exit control.
Entering fullscreen requires a player tap; browsers do not allow it automatically
when a URL opens. The complete page enters fullscreen so touch controls, menus
and save speech bubbles stay available together.

Supported Android browsers use the standard Fullscreen API. Safari versions
with fullscreen support can use either the standard or prefixed API. A rejected
request shows a short explanation and leaves the game running.

On iPhones without browser fullscreen support, tapping the button opens these
steps: in Safari, choose Share > Add to Home Screen, enable Open as Web App if
shown, then Add. Launch Sunny Scout from that icon to hide browser bars. The
page declares Apple's standalone web-app mode; the extra fullscreen control is
hidden when already launched in standalone mode. This does not add offline play.

This change is part of the exported game HTML. An existing Sunny Scout Scores
1.1.0 plugin needs no update. Replace the full game build through the normal
update process. It does not change save formats or timed runs.

Validation: `python tests/test_web_fullscreen.py` exercises actual touch-triggered
Chromium fullscreen entry/exit, unsupported iOS instructions, rejected requests,
prefixed API handling and standalone visibility. The final game export was also
opened in mobile Chromium emulation, continued into Frost camp and toggled in
and out of fullscreen on the guide and during gameplay. iOS fallback/prefixed
APIs are simulated; a physical iPhone was not available for validation.
