# Bea character and placement review

Character concept and proposed placement for the [Woodland Supplies mission](../../BEA_MISSION.md).
These screenshots are the approval checkpoint before Bea's main-game integration.
No separate playable preview needs to be opened.

![Bea character concept](bea-character.png)

Bea wears a green ranger hat and jacket, rust scarf, tan trousers and a supply
satchel. Her head/body proportions follow Scout's miner artwork. The isolated
concept is source art; its large source-image dimensions do not determine her
in-game size.

The placement captures use the current main-game Pinewood scenery and HUD, with
a proposed Bea sprite and shared character bubble added for the screenshot.
Both characters use the normal camera zoom and an equal 87.45-world-unit visible
height measured from their alpha bounds. Bea stands to the right of the
southeast fallen tree; Scout stands beside her on the same ground line.
Fog is hidden in this screenshot arrangement to show the landmark clearly.

![Proposed placement beside the fallen tree](bea-pinewood-placement.png)

![Proposed speech bubble above Bea](bea-pinewood-dialogue.png)

The [scale check](scale-check.json) records the fitted sprite heights, foot
positions and completed Pinewood transition used for these captures.

The screenshot arrangement is a design mockup, not an implemented quest. The
production startup, game scene and mission behavior are unchanged. The parent
`docs/concepts/.gdignore` excludes the concept art from Godot imports/exports.
