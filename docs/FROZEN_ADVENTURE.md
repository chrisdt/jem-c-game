# Frost Canyon: Snow Sprites and crystal equipment

Start with F5 → Start exploring, then use the working camp rocket to fly to Frost Canyon. The rocket never requires a frozen quest or upgrade. Earth story progression is independent; Nova's repair quest remains paused. Saving is still deferred: progress survives area/planet trips during the current session, and reload or R → Yes starts fresh.

The compact material header displays all six mineral types and wood on every planet, with the local minerals first. The equipment bar, ownership and selected slot also carry between planets. Slot 1 is the mining tool and slot 2 the owned sword. Upgrades replace their icons rather than adding duplicate equipment. Space uses nearby collectibles or mines with the mining tool; otherwise it attacks. E talks and uses quest objects. Touch provides separate contextual action and Attack/Jab controls.

## Starter recipes and frozen upgrades

The starter sword (3 copper + 2 wood) and hand drill (5 copper) can only be crafted at Earth's workbench. Each recipe card disappears once built; a remaining card is centred. Once both are built, the workbench says all starter equipment is built. Frozen and desert shelters do not open the Earth crafting menu. Nix and Tavi provide the frozen upgrades through their own conversations.

| Snow Sprite | Location | Quest and result |
| --- | --- | --- |
| Pip, aurora scout | Right of Canyon Camp's shelter | Recover the three beacon fragments from Frozen Basin, Prism Pass and Aurora Shelf. Return to restore the trail beacons. |
| Nix, crystal smith | Frozen Basin clearing | Bring the Earth sword, the heart-crystal at the centre of Prism Pass's ruined stone circle, 4 frost ore and 1 amethyst. Forges Frostfang. |
| Tavi, engineer | Prism Pass | Bring the hand drill, Deep Prism Mine's unique power coupling, 5 frost ore and 2 amethysts. Fits the Crystal Drill. |
| Eira, expedition keeper | Aurora Shelf | Find the frozen cache on Glacier Crown's southeast ice pond, defeat its guardian yeti, drill it open and return the expedition keepsake. |

The four quests appear in Frost Canyon's own expandable J / Quests popup. Earth keeps its separate six active story quests and optional objectives. Snow Sprites fade in with exploration, wave on the first close approach, stand on contact shadows, and puff away after completion. There are no alien cats. Frozen characters and objects stay on their own planet.

Items can be found before accepting their quests. Upgrades only spend resources when the final conversation action is confirmed; closing a conversation preserves materials. Completed upgrades cannot charge twice. Both recipes together require **9 frost ore and 3 amethysts**, within the frozen planet's **13 frost ore and 3 amethysts**. The three mines each supply one amethyst, so explore all three. These rare deposits require the Earth hand drill; you can freely fly home to prepare it.

All four quests can be accepted and handed in independently. Nix does not wait
for Pip, and Tavi does not wait for Nix. Real ingredients and equipment still
apply. Nix and Tavi show missing items in their conversations, and the journal
tracks the unique heart-crystal/coupling and starter equipment as well as mineral
totals. Ready recipes show whom to return to.

Pip's collectible fragments are larger, with dark outlines/contact shadows and
subtle gold glints after exploration reveals them. Returning them replaces them
with permanent lantern beacons. E or the touch action inspects a restored light
and explains its purpose. Space stays available for combat nearby.

## Equipment and combat

- **Frostfang Sword:** 7 damage per directional jab, compared with 3 for the copper sword and 5 for Mara's reinforced sword. A hit briefly slows enemies for 1.25 seconds. Sword artwork stays hidden while walking/idle. Both the miner and spacesuit have front, back and mirrored side attack poses with boot anchors.
- **Crystal Drill:** mining progresses at 1.666667 times the normal rate on every planet, approximately 40% shorter duration: common minerals take 1.2 seconds and untouched rare minerals 5.4 seconds. Its silver cutting tip receives a blue crystal treatment in all directions, idle/walking and drilling, while retaining the existing fitted gauntlet animation in both outfits. The equipment icon uses the approved blue crystal/brass design.
- Frozen equipment remains stronger when brought back to Earth, including against snakes, bats and rats. Later Earth upgrades never replace or downgrade it.
- Yeti patrols occupy Frozen Basin, Prism Pass and Glacier Crown. They have 16 health, front/back/side walking art, a clear 0.85-second warning, a locked attack aim, and recovery time after attacking. A hit does **3 half-heart units = 1.5 hearts**. Dodging the marked aim during the warning avoids the strike. Invulnerability prevents repeated contact damage. Defeated yetis disappear in snow puffs and stay defeated through area/planet trips.
- Landing shelters, signed trail entries and NPC conversation approaches are safe. Warm up within the Canyon Camp shelter area to recover half a heart every 1.5 seconds. Defeat restores health at a safe arrival without losing materials or equipment. No sound is added.

The frozen cache is grounded on the southeast ice pond in Glacier Crown, with its guardian stationed beside it on the walkable ice. Eira and the journal describe this landmark. The cache requires a Crystal Drill or Magma Drill, its guardian's defeat and the mining tool slot. Drilling takes two seconds, animates Sunny and shows progress; movement, damage, equipment changes or a popup pause the work. Returning resumes its remaining progress. It never gates an ordinary trail, mine doorway or rocket.

## Assets, performance and checks

`assets/frozen/` contains illustrated Snow Sprite idle/wave poses, equipment/quest objects, the yeti atlas and separate outfit combat art. `tools/build_frozen_atlas.py` measures alpha and boot bounds without repainting or resizing source art; its checked-in JSON is included in Web exports. Imported textures use high-quality lossy compression and mipmaps. The equipment shader changes only the tool region; all skin, fabric, helmets and brass retain their authored colours.

Only the current area's quest objects and yeti are instantiated. Compact session records retain defeated enemies and collected items; the existing bounded scenery loader continues to stream district backgrounds. Native route checks cover all eight frozen areas without loading the whole planet's scenery simultaneously.

Run with `godot --headless --path . --script`:

- `tests/frozen_story.gd`: actual resource gathering and all four quests, cancelled handoffs/exact costs, ownership and journal separation, Earth-only hidden starter cards, both outfits and every attack direction, upgrades across all planets, warned yeti damage, puff cleanup, paused/resumed cache drilling, travel and reset.
- `tests/quest_order.gd`: independent handoffs, Nix before Pip, real landmark pickup, all 24 Frost handoff orders, consuming shared items, recipe races and beacon discovery/inspection.
- `tests/frozen_routes.gd`: reachable Snow Sprites, every quest object and yeti approach across five surfaces and three mines; bounded scenery textures.
- Existing Earth story, mission, combat, pickup, HUD/drill, touch, fresh rocket and flight checks remain regression coverage. Browser review helpers are temporary and excluded from production.
