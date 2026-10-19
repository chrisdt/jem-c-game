# Rowan speech bubble preview

This is the review build for **R04**, the reusable character speech bubble. It uses the real camp as a frozen backdrop and displays Rowan at Scout's measured height. It does not accept a quest, grant a sword or change the normal game startup.

## Run in Godot

Open `previews/rowan_dialogue.tscn` and press **F6**, or run:

```sh
godot --path . res://previews/rowan_dialogue.tscn
```

For a separate Web preview, run `python3 tools/export_rowan_preview.py`. It exports to `build/rowan-dialogue-review/` using a temporary project with the preview as its entry scene. Serve that folder over HTTP; opening its HTML directly as a file cannot run a Godot Web build. The regular project's main scene and normal Web build remain unchanged.

## Review the interaction

1. Read Rowan's first page. Press **E / Enter** or click **Next** to advance. Her dialogue remains until you advance or close it.
2. Press **Escape** or **×** to close. **Talk to Rowan** starts again from page one.
3. Choose **Show a hint**. The shorter bubble disappears after a few seconds.
4. Choose **Next position** to check the four screen corners. Close the current conversation to use the preview controls again. Near the top edge, the bubble moves beside Rowan to leave her face clear.
5. Choose **Touch buttons** for larger buttons without keyboard prefixes. On a touch device this layout is detected automatically. Tap Next and Close; a cancelled or dragged-out touch must not activate either action.
6. Compare Rowan and Scout at the normal camp position. The preview measures each texture's visible alpha bounds and gives them the same rendered height; transparent padding is excluded.

The preview's bottom buttons are review controls, not additions to the main game's HUD. The normal mission panel and long instruction banner remain unchanged until the bubble is integrated with Rowan in the following tasks.

## Component and checks

`ui/character_bubble.gd` supports one active conversation or timed hint, a speaker, text pages, a world-space head offset, and an optional final action label. Dialogue takes priority over hints. Invalid, hidden, removed and offscreen speakers cannot leave an active bubble behind.

The component emits `opened`, `page_changed(index)` and `closed(completed)`. The caller must pause gameplay and clear movement gestures when opening a conversation, resume them on close, and dismiss dialogue when opening another menu or changing areas. Hints do not capture keyboard focus. Rowan's live interaction and Buddy's bark priority will connect to this component in the subsequent camp integration task.

Run the interaction checks with:

```sh
godot --headless --path . --script tests/character_bubble.gd
```

These checks cover keyboard input isolation, paging, cancellation, hint priority, multiple touch fingers, safe placement at the screen edges, speaker lifecycle and matching rendered character heights. The browser review adds desktop mouse/keyboard and tablet touch checks against the exported scene.
