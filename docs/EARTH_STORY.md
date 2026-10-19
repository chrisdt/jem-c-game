# Earth NPC and mission tasks

Build Earth's story one character and mission at a time. For each character, make a character mockup and an in-world dialogue mockup, write the mission, implement it, then playtest that complete interaction before starting the next character. Names and dialogue are working choices.

Rowan's character, scale and position between the crafting hut and CAMP sign have been reviewed. **R05, Rowan in the main game**, is ready for review: press **F5**, choose **Start exploring**, walk toward Rowan and use **E / Talk to Rowan**. Future character placements will be shown as screenshots for approval. Test all gameplay in the main game; separate preview scenes are developer fixtures.

## Story direction

Scout helps Earth's community restore an old mining rocket and prepare for other planets. The rocket is visible and broken at the beginning of the finished story. Nova shares the dream of finding new minerals early; the rocket repair mission is the final Earth mission, after the player has upgraded the drill and sword and obtained a working spacesuit.

Each landmark introduces a person with a practical problem. Helping them teaches gathering, crafting, combat, mining and exploration. NPC dialogue gives the next useful action in small pieces. The quarry opens through a visible world change: clearing its rockfall with a hand drill.

## Character order

| Order | Character and location | Mission | Result | Current task |
| --- | --- | --- | --- | --- |
| 1 | Rowan, camp craftsperson; beside the Landing Meadow workbench | Ready for the Trail: gather 3 copper and 2 wood, then craft the copper sword | Sword owned; introduction to Bea | R05 camp interaction ready in the main game |
| 2 | Bea, woodland ranger; by the fallen tree in Pinewood Trail | Woodland Supplies: deal with a nearby snake and recover a supply cache | Introduces the hand-drill recipe and Otis's quarry problem | Mock up after Rowan's mission is playable |
| 3 | Otis, quarry foreman; on the Pinewood side of the blocked quarry trail | Clear the Way: craft the hand drill for 5 copper and clear the rockfall | Old Quarry becomes accessible | Initial character exploration only |
| 4 | Mara, quarry mechanic; beside the quarry rails and mine cart | Better Tools: use quarry minerals to upgrade both drill and sword | Equipment for hard rock and the ruins encounter | Design after Otis |
| 5 | Iris, field researcher; at Sunstone Ridge's circular ruins | The Old Expedition: explore the ruins and recover an expedition locker | Damaged spacesuit and navigation component | Design after Mara |
| 6 | Finn, expedition outfitter; beside Willow Marsh's stream and bridge | Ready for Space: recover repair supplies and seal the spacesuit | Working spacesuit and recovered fuel regulator | Design after Iris |
| 7 | Nova, rocket engineer; beside the Landing Meadow rocket | Beyond Earth: recover the remaining engine component, fit the spare parts and complete launch checks | Rocket repaired; travel to other planets | Design after Finn |

The mine/cart, ruins, stream/bridge and fallen-tree screenshots supplied in chat are placement references for Mara, Iris, Finn and Bea respectively. Otis stands outside the obstruction so he can explain it before the player gains quarry access.

## Small tasks for every character

1. **Character mockup:** one full-body design with a distinct silhouette, outfit, role and personality. Every human uses Scout's character scale: match visible head-to-foot height and overall head/body proportions. Distinguish people through their design, not by enlarging them.
2. **Placement and dialogue mockup:** show a screenshot at the existing landmark beside Scout at the same camera zoom, with one short speech bubble. Include a side-by-side scale check and get placement approval before building the character's mission. Use the main game for playable reviews.
3. **Mission script:** write the introduction, objective, progress reminder, completion and next destination. Define any item costs and rewards.
4. **Character implementation:** fit the production sprite, foot anchor, idle presentation, discovery and interaction to the current world.
5. **Mission implementation:** add only that character's objective tracking, contextual dialogue and rewards; reuse the shared systems.
6. **Playtest:** run through the complete mission with keyboard and touch, revisit the area, check early item collection and verify the reward is granted once.

The concept images are visual targets, not production sprite atlases or evidence of implemented gameplay. Separate fitted production art is part of each character's implementation task.

## Rowan tasks

| Task | Small deliverable | Done when | Status |
| --- | --- | --- | --- |
| R01 | Character concept | Rowan reads as a welcoming craftsperson and is distinct from Scout | Reviewed |
| R02 | Camp dialogue concept | Rowan stands beside camp at Scout's scale; a readable bubble points to her; the long instruction banner is absent | Revised and reviewed |
| R03 | Mission and dialogue | The recipe, objective, reminders, completion and next destination are written | Script below |
| R04 | Reusable speech bubble | One speaker, short text pages, keyboard/touch advance, close, screen-edge fitting and priority rules work | Reviewed; shared component |
| R05 | Rowan in camp | A fitted sprite, discovery, greeting and talk interaction work without obstructing the workbench | Implemented; main-game review |
| R06 | Rowan's crafting objective | Gathering and the existing sword craft update the mission; already-crafted swords are recognized | Pending |
| R07 | Reopenable mission log | Rowan's objective can be recalled after dialogue closes; desktop and touch can open/close it | Pending |
| R08 | Rowan playtest | The checks below pass and the implemented desktop/touch views are captured | Pending |

### Rowan character

Rowan is a practical, patient camp craftsperson. Curly black hair, a teal bandana, an ochre shirt and a worn teal apron distinguish her from Scout. A small hammer stays at her belt. She welcomes the player rather than delivering the entire Earth story at once.

Rowan stands on the approved clear ground between the crafting hut and the CAMP sign, at foot position `(590, 454)` in Landing Meadow. Her visible alpha bounds are fitted to Scout's 87.45-world-unit idle height, excluding transparent padding. The closest of Rowan and the workbench gets the interaction in their overlapping approach areas. The R05 actor uses the approved concept's cropped Rowan figure; separate directional/animated production art remains future work.

### Ready for the Trail

**Start:** interact with Rowan. Accepting the mission records it in the mission log. The player keeps access to the existing crafting recipes.

**Objective:** gather 3 copper and 2 fallen wood, then craft the copper sword at the camp workbench. Crafting uses the existing exact recipe and grants the existing sword. Rowan's mission does not charge for the ingredients a second time.

**Completion:** recognize sword ownership, including a sword crafted before speaking to Rowan. Keep the completed objective after materials are spent. Rowan acknowledges the result and introduces Bea. Until Bea is implemented, this remains a conversational lead rather than an active objective with a missing NPC.

**Reward:** the crafted sword is the progression reward. No additional consumable reward is needed for this first mission.

| Conversation state | Short dialogue |
| --- | --- |
| First page, shown in the concept | “Let's get you ready for the trail. Find 3 copper and 2 fallen wood.” |
| Second page | “Bring them to this workbench to craft a sword. It'll help with the snakes along the trails.” |
| Accept action | “I'll gather the materials.” |
| Copper still needed | “Copper is hiding along Earth's trails. Your pick can mine it.” |
| Wood still needed | “Look for fallen branches and logs. You can gather those by hand.” |
| All materials held | “You've got what you need. Craft your sword at the workbench.” |
| Sword already crafted | “That's a fine sword! You're ready for the trail.” |
| Closing lead | “Bea looks after Pinewood Trail. She may have a job for an explorer.” |

Choose one reminder appropriate to the player's current state; do not show every line on each visit. The mission log can show current material counts before crafting, and a lasting completion tick afterwards.

### Bubble behaviour

- NPC speech appears above its speaker; direct control hints and player reactions appear above Scout.
- Use a warm cream bubble, dark teal text and a small pointer, borrowing Buddy's friendly “Woof!” presentation.
- Dialogue uses short pages with an explicit **Next**, **Accept** or **Close** action. Desktop uses E and Escape; touch uses a comfortable button. Spoken text stays until advanced or closed.
- Show only one main conversation or tutorial bubble at a time. NPC greetings do not repeatedly restart while standing nearby.
- Keep the bubble inside the viewport, clear of faces, material counters and touch controls. Close or reposition it safely during area changes and menus.
- Pause attacks and movement during a conversation; closing it must restore input cleanly. Buddy's bark bubble yields to active dialogue.
- Replace the long instructional notice banner using the shared bubble system. Keep mine progress, critical loading feedback and useful action buttons legible.
- Keep mission details in a reopenable log, with a desktop shortcut and a touch button. The proposed mockup uses **J / Missions**.

### Rowan playtest checks

- Fresh game: talk to Rowan, accept, gather the real resources, craft and complete the mission.
- Returning before enough resources gives a useful reminder and retains progress.
- Crafting before meeting Rowan still completes the objective without duplicate spending or rewards.
- Crafting the drill first leaves the sword mission achievable and the workbench usable.
- Spending ingredients does not undo completed objectives.
- Dialogue cannot start mining, attacks or a second interaction with the same input press.
- Keyboard, mouse and touch can advance and close dialogue and reopen the mission log.
- Text remains readable near screen edges and during camera movement; other greetings and barks do not obscure it.
- Rowan and Scout have matching visible head-to-foot heights and similar head/body proportions at the same zoom, measured from the fitted sprite bounds rather than source image dimensions or transparent padding. Apply this check to every later human NPC.
- Area changes preserve mission progress during the current session. A confirmed reset starts fresh.

## Later character dependencies

**Bea:** choose the supply-cache placement and a specific nearby encounter. A snake defeated before accepting must be handled without requiring a nonexistent replacement. Introduce the drill recipe without taking away a drill already built.

**Otis:** place the rockfall across the only Pinewood-to-quarry approach. Block both walking and the trail transition while it remains. A starter pick and sword cannot clear it; a crafted hand drill can. Clearing it is a one-time interaction with visible rock/dust feedback, recorded for the current session. A return trip must keep the path open. The quarry must contain no ingredient needed to obtain the first hand drill.

**Mara:** decide the upgrade effects, appearance and costs before coding this mission. Check the whole Earth resource budget, including ingredients spent earlier. Avoid adding unrelated upgrade menus before this step.

**Iris:** define the ruins search and encounter, the upgraded equipment's practical use, and the recovered locker. Add distinct item state for the damaged spacesuit and navigation component.

**Finn:** connect the waterside station to suit preparation, for example testing the repaired seals beside the stream. Define repair supplies and source locations before adding any costs. A damaged suit and a travel-ready suit must have distinct states.

**Nova:** introduce the dream of other worlds early, then activate the final repair mission only after the equipment and suit requirements. Choose a reachable engine-component recovery spot, provisionally Crystal Depths. Fit navigation component, fuel regulator and engine component, then repair the rocket once. Travel must check the repaired rocket, upgraded drill, upgraded sword and ready spacesuit. Release the broken-rocket launch restriction together with the achievable repair chain.

## Resource and state checks

Earth currently provides 13 copper deposits, 3 blue crystals and 6 fallen-wood pickups. The starter sword and hand drill together spend 8 copper and 2 wood. Blocking Old Quarry removes its two surface copper and its mine's common deposit from the early supply; the other four districts and two mines still provide 10 copper, enough for both starter crafts.

Check the remaining 5 copper, 3 crystals and 4 wood against Mara's upgrades, Finn's repairs and Nova's parts before choosing later recipes. Use unique recoverable quest parts where appropriate, and do not consume the same navigation component or other mission item in two recipes. All missions must remain completable regardless of the order in which available ingredients were gathered or starter equipment was crafted.

Use the current session-memory scope for this rollout. Area unloading, mine visits and later planet trips preserve mission/item state; a confirmed new game resets it. Browser save-and-continue remains a separate task.

## Next handoff

Review **R05 in the main game**: F5 → Start exploring. Rowan greets once near camp; walk toward her until **Talk to Rowan** appears, then press E or tap the action. E / Enter / Next advances, and Escape / × closes. Movement, combat, travel and other gameplay keys stop during her conversation; touch gestures are cleared on open and close. Temporary messages now appear above Scout instead of in the old bottom banner. Buddy's bark cannot interrupt dialogue. Recipes remain available at the workbench, and Rowan recognizes an already-crafted sword. No mission acceptance/tracking or rewards are added in this step.

Run `godot --headless --path . --script tests/rowan_camp.gd` for the actual startup-to-camp integration, including keyboard/touch controls, placement/scale, notification priority, crafting access, area scope and session reset. `tests/character_bubble.gd` retains component edge and lifecycle checks.

After this interaction is reviewed, **R06** adds her crafting objective. R07 adds the reopenable mission log, then R08 tests the complete first mission. Make Bea's character and landmark screenshots after Rowan's mission has been reviewed. Keep the remaining characters, quarry obstruction and rocket repair in their own subsequent tasks.
