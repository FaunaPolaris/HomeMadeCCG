# Art the code is waiting on

Everything here is a placeholder or a gap in code that already runs. Grouped by
what unblocks the most. All tiles are **32x32**, `.aseprite` source committed
next to the exported `.png`, same as the existing tilesets.

## Blocking — there is placeholder code standing in for these

- [ ] **Fog tile / tileset** → `assets/map/tiles/fog_tileset.tres`
  `script/map/Fog.gd` currently draws flat `Color(0.03, 0.028, 0.07)` rectangles
  over unseen cells. It works, but the fog edge is a hard 32px square.
  Ideally a **terrain set with edge and corner variants** like `biome_tileset`,
  so the border between seen and unseen autotiles into an organic shape.
  Minimum viable: one solid 32x32 tile. Nice: 13-tile blob set.

- [ ] **Prop tiles** → `assets/map/tiles/prop_tileset.tres`
  The `prop` layer exists and is wired, but has **zero tiles drawn** and is still
  borrowing `biome_tileset`. This is the forageables layer: plants, mushrooms,
  loose items. Needs its own tileset before anything can be placed to collect.

## Next — needed to finish the map as designed

- [ ] **Missing biome terrains.** `script/map/Tile.gd` lists nine biomes; the
      tileset has four. Missing art for: `PRISTINA`, `CAVE`, `GRASH`, `SAND`,
      `WATER`, `DEEP_WATER`.
      Also worth a decision: the tileset has a `deep_foliage` terrain that is
      **not** in the enum. Either add it to the enum or fold it into `BLOOM`.

- [ ] **Building tiles.** `building_tileset.png` has 9 tiles and exactly one is
      placed. Buildings are the map transitions, so they likely want a visual
      cue that they are enterable — a doorway, a lit window, something that
      reads differently from a prop.

- [ ] **Selection / cursor highlight.** `assets/map/tile_border.png` already
      exists and nothing uses it. If it is meant to be the hover highlight, it
      probably wants variants: valid move, blocked, and whatever combat needs
      later.

## Later — no code waiting, but the gap is real

- [ ] **A second entity sprite.** Two entities on one map works and is tested,
      but `player.tscn` is the only entity scene, so any NPC is currently a
      second copy of the eye.

- [ ] **A font.** `TinyPixels.png` was deleted with the card UI; the
      `.aseprite` source is still there. Any on-screen text needs it re-exported.

- [ ] **HUD inside the three panels.** `fullScreen.aseprite` has `base leyout`
      and `mock interface` layers hidden. Whatever the map HUD becomes has to
      live inside the three portrait columns for the mobile port.

## Not needed

Movement is a grid step with no walk cycle, so the player needs no directional
art. The eye's idle, blink and pupil-tracking animations are already complete.
