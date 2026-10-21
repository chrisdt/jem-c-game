# Sunny Scout backgrounds — walking-area markup

All 24 playable map backgrounds, at their original PNG resolution, from game
source commit `8508ef52a9562f504fac170fee888a4ebf3daaf3`. Five surface areas and three mines for each world.
Files 01–05 in each folder are surfaces; 06–08 are mines. Each PNG is an exact,
unmodified copy of its current game asset. MAP_INDEX.csv lists every location,
image size and source file, so your markup can be matched back to the game.

## Marking the walking areas

- Highlight in **green** all ground where Sunny's feet should be able to stand.
  Include the full usable width of paths, grass clearings, bridges and mine floors.
- Mark **red** where walking should be blocked, especially water, walls, cliff
  edges, pillars, large rocks and gaps that only look like paths.
- Add **arrows** at working mine doors and paths leading to another screen. Cross
  out decorative doors that should remain closed.
- Label conditional areas, such as a path that opens after drilling a rockfall.

Use a translucent highlighter or a separate drawing layer so the artwork stays
visible underneath. Mark where the **feet touch the ground**, rather than trying
to fit Sunny's entire body inside the highlight. Keeping that rule consistent
will help the character move naturally beside rocks and walls.

Please keep the filenames, image sizes and full canvas unchanged. Export marked
copies as PNGs (or keep editable layers as well) and send them back when ready.
You can return one world or a few maps at a time.

These are base backgrounds: fog, HUD, characters, animals, ore, signs added by
code and other separate animated/quest objects are not baked into these files.
Landing Meadow uses the current ground painting; its separate animated trees
and plants are added by the game. Use a note or an in-game screenshot if a
problem concerns one of those separate objects rather than the ground painting.

This is a review-artwork pack, not a playable game build. No movement or live
hosting settings were changed to create it.
