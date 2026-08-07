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
