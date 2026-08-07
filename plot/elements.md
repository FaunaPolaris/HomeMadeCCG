# Elements

The nine elements of the world. Kept from the first card-game draft because they
carry the worldbuilding; everything else about that draft was dropped. Sand was
cut from the final list on 2026-08-07 (it stays as a map biome).

Each element has a 12x12 icon in `assets/interface/icons/elements.png`, in this
tile order:

| # | Element |
| --- | --- |
| 0 | Fire |
| 1 | Air |
| 2 | Water |
| 3 | Earth |
| 4 | Thunder |
| 5 | Hunger |
| 6 | Wood |
| 7 | Smoke |
| 8 | Null |

`Water` also appears as a map biome in `script/map/Tile.gd` (as does `Sand`,
which is biome-only now), so the biome and element vocabularies partly overlap.

---

The old `databases/Cards.ods` / `Cards.xlsx` spreadsheets held the abandoned
slot-based ruleset — Coin/Extra Cost, Attack/Cast/Hire, Center with Champions
and Rituals — plus four Isles (Mystical Forest, Oath of the Snake, Meat Golem,
Ardent Spirit) and ten creature Types (Snake, Frog, Golem, Spirit, Bat, Wolf,
Vulture, Fly, Lumi, Fungi). Recoverable with
`git show 1c30d41:databases/Cards.ods` if any of it is ever wanted back.
