# Bea: Woodland Supplies

Proposed next character after Rowan's reviewed R06 mission. This is the B01–B03
design checkpoint: approve Bea's look and landmark placement from screenshots,
then implement and test her interaction and mission in the main game. No new
NPC or quest is activated by this design step. Rowan's mission-log task (R07)
remains pending while the requested rollout moves to the next character.

## Character and placement

Bea is a warm, practical woodland ranger. Auburn hair in a braid, a green soft
ranger hat with a leaf pin, a green jacket, rust scarf, tan trousers and a brown
supply satchel distinguish her from Scout, Rowan and Otis.

Place her on the clear ground **below Pinewood Trail's southeast fallen tree,
beside the small stump**, in the area the user circled in red. Requested world
foot position: `(1632, 1138)`, corresponding to art position `(1224, 853.5)`.
This moves her down and left from the initial position to the right of the log.
Keep both approaches around the log usable; final ore, foliage and encounter
clearance is part of B04.

Fit the character's visible alpha bounds to Scout's **87.45 world-unit** idle
height, excluding transparent padding. Keep Scout visible at the same camera
zoom for the scale check. Her compact head/body
proportions follow Scout's miner artwork. Store the character source and review
captures in [the concept folder](concepts/bea-v1/README.md).

## Mission

**Woodland Supplies:** deal with the snake near Bea's lost supply box, recover
the box and return it to her. This introduces a short combat objective followed
by a persistent world pickup and a return conversation.

- **Before accepting:** require ownership of the copper sword. If Scout has no
  sword, Bea suggests Rowan and the camp workbench. Keep exploration and normal
  crafting available. Already-crafted swords count, including those crafted
  before meeting Rowan.
- **Accept:** use the existing paged character bubble with an explicit
  **Accept mission** action. Closing the conversation does not accept.
- **Encounter:** use Pinewood's existing second snake, with preferred spawn
  `(1347, 880)` in world coordinates. Give it a stable spawn identifier in the
  actor and area-memory records. Do not identify it from its wandering position,
  its mutable home after floor fitting, or the total number of enemies defeated.
  This adds no extra snake to the district.
- **Supply box:** add a small distinct tied wooden box near the encounter,
  provisionally around world `(1440, 1000)`, northwest of Bea and beside the
  fallen-tree clearing. Verify the final spot against the painted ground,
  randomized ore and existing plants before implementation. The box is a unique
  mission item; it is not one of the wood pickups needed for crafting.
- **Recover:** reveal it through the usual fog/discovery rules. A nearby
  **E / Recover supplies** action collects it once after the designated snake
  has been defeated. Its collected state persists across area and planet trips.
  Walking, tools, combat and other nearby interactions retain their priorities.
- **Return:** after the encounter and recovery, talk to Bea and choose
  **Return supplies**. Consume only the unique quest-box flag; mark the mission
  complete once. Closing early keeps the box and the return option.
- **Reward and lead:** Bea explains the existing **5-copper hand drill** recipe
  and Otis's quarry problem. If a drill is already owned, she recognizes it.
  Preserve the workbench's current recipe availability and all equipment.
  No extra copper, wood or crystals are charged or created. Until Otis is
  implemented, the quarry lead is conversational and creates no missing-NPC
  objective or blocked route.

The planned quarry obstruction belongs to Otis's later task. Bea's mission will
not close the quarry, change launch access or introduce later upgrade costs.

## Dialogue draft

| State | Short pages / action |
| --- | --- |
| Greeting | “Could you lend a hand with some lost supplies?” |
| No sword | “There's a snake near my supply box. Rowan at camp can help you prepare a copper sword.” / **Done** |
| Offer, page 1 | “A snake's guarding my supply box beside the fallen tree.” |
| Offer, page 2 | “Deal with the snake, recover the box and bring it back to me.” / **Accept mission** |
| Snake still alive | “The snake near the box is still there. Keep your sword ready and watch its warning before it strikes.” |
| Snake defeated, box not held | “The way is clear. Look for my tied supply box near the fallen tree.” |
| Box held | “You found it! Those supplies will help keep the woodland trail safe.” / **Return supplies** |
| Completion, no drill | “Otis needs help with a rockfall on the quarry trail. A hand drill can break through it. You can build one at camp with 5 copper.” |
| Completion, drill owned | “You've already built a hand drill! Otis will be glad to see it when you help with the quarry rockfall.” |
| Repeat visit | “Thanks for bringing my supplies back. Take care out on the trails!” |

Show one useful reminder for the current state. Keep the speaker bubble and
input handoff used by Rowan. Completing the handoff should not immediately start
another interaction with the same key or touch.

## Early actions and session state

- Defeating the designated snake before accepting counts; never respawn it to
  satisfy the objective. Defeating an unrelated snake does not count.
- Recovering the box early after that encounter is allowed. Accepting later
  recognizes the existing kill and held item, so the player can return it.
- A previously crafted sword or drill is recognized. No recipe or owned item
  is locked, removed or purchased again.
- Before pickup, the box remains in its original spot; after pickup, it cannot
  respawn or grant duplicates. Returning it once keeps lasting completion even
  though the held-item flag is cleared.
- Preserve active/complete status, the designated encounter result, held box
  and closing-dialogue acknowledgement across district, mine and planet trips.
  A confirmed new game resets them, matching the existing session scope.

## Small implementation tasks

| Task | Deliverable | Status |
| --- | --- | --- |
| B01 | Bea character concept at Scout's proportions | Ready for approval |
| B02 | Landmark screenshot and measured same-height comparison | Ready for approval |
| B03 | Mission and dialogue draft, early-action rules and resource budget | Draft above |
| B04 | Bea in the main game: fitted actor, greeting, discovery and Talk | After B01/B02 approval |
| B05 | Designated encounter, persistent supply box, mission state and one-time return | After B04 review |
| B06 | Main-game keyboard/touch playtest and completion screenshots | After B05 |

B04 must route the shared conversation's close/complete event to the NPC that
opened it. The current main-game callback belongs to Rowan; talking to Bea must
never accept, complete or acknowledge Rowan's mission. Choose the nearest valid
NPC/station consistently for the on-screen action and the actual interaction.

## Required checks

Check fresh acceptance/cancellation, the real sword fight and unique box pickup,
return/cancel/retry, unrelated versus designated snake kills, early kill and
pickup, an already-crafted drill, area/mine/planet revisits, one-time turn-in and
confirmed reset. Check that each conversation affects only its own NPC's mission.
Verify fog visibility, safe foot placement, usable trail and
world interaction priorities at several randomized ore layouts. Capture Bea and
Scout together at the same zoom before calling B04 ready.
