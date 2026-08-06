# Making a new map

Two example maps already exist and work. Copy whichever is closer to what you
want:

- `scenes/maps/temple.tscn` — the original test map. Corridor leaving the top.
- `scenes/maps/temple_north.tscn` — the same shape mirrored. Corridor entering
  from the bottom.

They lead to each other, so between them they show both ends of a doorway.

## How it fits together

`scenes/map.tscn` is the **base**. It holds no map at all — just the three
tilemap layers, positioned correctly, with the `Map` script attached. Every real
map is an **inherited scene** of it, which is why a change to the base (a new
layer, a fixed offset) reaches every map at once.

The three layers, from bottom to top:

| Layer | What it is | Blocks movement? |
| --- | --- | --- |
| `biome` | The ground. **If there is no biome on a cell, that cell is not part of the map** — nothing can stand there, and nothing should be drawn on it. | Yes, by being absent |
| `prop` | Things you interact with by walking onto them. Forageables. | No |
| `building` | Doorways to other maps. Every building is a transition. | No |

Coordinates are **private to each map**. Every map has its own `(0, 0)` and its
own arbitrary extent — `temple` covers y −7…4, `temple_north` covers y −4…7.
Nothing lines up between maps and nothing needs to. A map's origin does not have
to be inside the map at all.

## Steps

**1. Create the scene.**
In the FileSystem dock, right-click `scenes/map.tscn` → **New Inherited Scene**.
Save it into `scenes/maps/` with a descriptive name. Rename the root node to
match the file — it is what shows up in warnings.

**2. Paint the ground.**
Select the `biome` layer, open the TileMap panel, and paint. Use the **Terrains**
tab rather than placing single tiles, so edges join up on their own.

Paint the ground *first*. The loader checks props and buildings against it, and
anything painted where there is no biome gets flagged.

**3. Paint props and buildings.**
`prop` for things to pick up, `building` for doorways. Buildings use
`building_tileset` — currently one piece of art, which is the door.

**4. Wire each doorway.**
For **every** building tile, add a child node of type `MapTransition`
(Add Node → search "MapTransition"). Name it after where it goes, e.g.
`to_temple_north`. Then in the Inspector:

| Field | Meaning |
| --- | --- |
| `cell` | The cell the building tile is on. Must match exactly. |
| `destination` | The map scene to travel to. File picker. |
| `arrival_cell` | The cell in **that** map the player appears on. |

**Point `arrival_cell` just inside the destination, not at the door on the other
side.** Otherwise the player arrives standing on the way back. The examples do
this: `temple`'s door is at `(0, -7)` and sends you to `(0, 6)` in
`temple_north`, which is one cell *past* that map's own door at `(0, 7)`.

**5. Reach it from somewhere.**
A new map is unreachable until an existing map has a doorway pointing at it. If
it is meant to be where the game opens instead, change `STARTING_MAP` in
`script/main.gd`.

## The worked example

```
temple                                  temple_north
  y=-7  door (0,-7) ─────────────────►    arrival (0, 6)
        to_temple_north                   ▲
        arrival_cell (0, 6)               │ one cell inside
                                          y=7  door (0, 7)
  y=-6  arrival (0,-6)  ◄─────────────     to_temple
        one cell inside                    arrival_cell (0,-6)
  ...
  y= 4  bottom edge
```

## What the loader will tell you

Warnings appear in the Output panel when a map loads. All of them mean you drew
something the system cannot honour:

- *"building at (x, y) has no MapTransition"* — a door that goes nowhere. Add the
  node, or erase the tile.
- *"MapTransition 'x' is on (x, y), where no building is drawn"* — the data is
  there but there is nothing to see. Usually a typo in `cell`.
- *"MapTransition 'x' points at '...', which does not exist"* — bad or empty
  `destination`.
- *"'prop' has a tile at (x, y) with no biome under it"* — floating scenery.
  Paint biome under it or erase it.
- *"layer 'x' sits at ..., expected (-16, -16)"* — a layer got nudged. Its tiles
  will be half a cell out of step with entities. Put it back.

## Things worth knowing

**Fog.** A map starts unexplored and reveals in a square around the player. This
is not an overlay — unexplored cells simply are not drawn, so the background
shows through. Nothing to set up per map; it just happens.

**Saving.** A map is identified in the save file by its **scene path**. Renaming
or moving a map scene orphans whatever the player had explored and changed in it.
Rename early or not at all.

State is stored per map, so leaving and coming back preserves what was explored
and any tile the player changed. The save is JSON in `user://save.json`, written
whenever the player changes map.

**Entities do not persist yet.** Anything other than the player that is standing
on a map when the player leaves is destroyed with the map, and comes back as the
scene describes it. Only the player travels.

**Two entities cannot share a cell**, so if you place entities in a map scene,
give them distinct `map_position` values.
