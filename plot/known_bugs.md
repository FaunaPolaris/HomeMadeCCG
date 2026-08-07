# Known bugs

Things that are wrong or will bite later. Maps are Fauna's to edit, so map
problems get listed here rather than fixed.

Last checked against the maps on 2026-08-06.

## Open

### 1. The player spawns standing on a door

`script/main.gd` starts a new game at `STARTING_CELL = (0, 0)` in `temple`, and
`temple`'s door is on `(0, 0)`. So a new game begins on top of a transition.

It does not fire on spawn — travel only triggers on a step — but walk one cell
off and back and you are sent to `clearing` without meaning to.

Either move the spawn cell or move the door. Both are one-line changes; the spawn
is in code, the door is in the map, so it depends which is meant to move.

### 2. `clearing.tscn` inherits from `temple.tscn`, not from the base

`scenes/maps/clearing.tscn` was created as an inherited scene of
`scenes/maps/temple.tscn` instead of `scenes/map.tscn`. It is a *variant of
temple* rather than a fresh map.

Everything works today, because every layer that matters is overridden. What it
means later:

- Any change to `temple` — a new layer, an extra tile, a moved node — appears in
  `clearing` too unless `clearing` already overrides it.
- `clearing`'s transition node is still named `to_clearing`, inherited from
  temple, even though it leads *to temple*. Renaming it in `clearing` is safe;
  renaming it in `temple` will break `clearing`'s override of it.

To untangle: make a new inherited scene of `scenes/map.tscn`, copy the
`tile_map_data` across, and re-add the transition.

### 3. The pixel font draws some characters wrong

TinyPixels renders `f` as `r` and `l` as `I`, and has no apostrophe or
period — those draw as missing-glyph boxes. Visible on every card:
"follows" comes out "rollows". It looks like the image-font character
mapping in `TinyPixels.png.import` does not match the glyph grid in
`TinyPixels.aseprite`. The starter deck's descriptions dodge punctuation
on purpose until this is fixed. Font is Fauna's asset, so left alone.

### 4. Descenders on the last description line sit on the frame

The font's real line height is 11px at size 8, so the four description
lines exactly fill the 44px text plate, and letters like g or y on the
fourth line touch the plate's bottom edge. Options: give the plate a
couple more pixels in `card_base.aseprite`, cap the label at three
lines, or tighten the font's line height. Which one is an art call.

### 5. E swaps the card lists when they disagree

E toggles each list separately. Once a cardbox click leaves one list
open and the other closed, every E press swaps them instead of lining
them up. If E should mean "all cards out / all cards away", it needs to
look at both lists first — open both if any is closed, close both
otherwise. Small change, but it is a design call, so logged instead of
guessed at.

## Limitations, not bugs

These are known gaps, listed so they are not re-reported as bugs.

- **Entities do not survive a map change.** Anything other than the player is
  freed with the map it was on and comes back as its scene describes it. Only the
  player travels.
- **Renaming a map scene orphans its saved state.** Saves key maps by scene path.
  Rename early or not at all.
- **Reveal edges can show mid-transition terrain.** Tiles are drawn exactly as
  authored, and autotiling assumed neighbours that may not be revealed yet, so a
  coastline tile can appear cut off at the edge of explored ground.
- **No confirmation on the cheat menu's reset.** It wipes the save the instant it
  is clicked, by design.
- **The terrain list deals placeholder cards.** The right panel is meant to show
  the terrain the player stands on, but nothing reads the biome under the player
  yet, so it shows CARD 1–6 until that system exists.
- **Cards are transparent to the world behind them.** The map and the cloud
  background show through the card's inner regions, same as they do through the
  interface skeleton. If a card should fully block what is behind it, the card
  art needs an opaque backing layer.

## Gotchas worth remembering

- **Never hand-write a `uid://` string.** They look valid and parse, but never
  register, so every reference to them silently resolves to nothing. This caused
  a real break: `temple.tscn` shipped with an invented uid, the editor copied it
  into `clearing.tscn`, and `clearing`'s door pointed at a destination that could
  not load. Let the editor assign uids, or generate them with
  `ResourceUID.create_id()`.
- **`MapTransition.destination` accepts both** a `res://` path and a `uid://`
  reference. The editor's file picker writes uids, which is better — they survive
  moving the file.
- **Typed node exports in hand-written `.tscn` need `node_paths`.** Writing
  `list = NodePath("../sibling")` on a node entry does nothing for an
  `@export var list: SomeNode` unless the node header also carries
  `node_paths=PackedStringArray("list")` — without it the export silently stays
  null. The editor writes it automatically; by hand it is easy to miss.
