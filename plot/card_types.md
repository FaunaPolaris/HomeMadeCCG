# Card types

Everything in the game fits on a card, and every card has a type. The
list is open — more types will appear as systems grow — so nothing in
code may assume these are the only ones. Today a card just carries its
type as a free string (`Card.card_type`, `"type"` in decklists and the
save); the systems that make each type mean something come later.

| Type | Role |
| --- | --- |
| hero | A battling card the player uses: life points, stats, skills, equipment. |
| creature | A battling card to defeat, fought by hero cards (heroes can also fight each other). |
| item | Collected and added into a storage card, like the backpack. |
| storage | Holds other cards. The backpack is one. |
| npc | A passive entity that can give the player item and quest cards. |
| merchant | Like an npc but trades; also a source of item and quest cards. |
| quest | Given by npcs and merchants. |
| lore | Discovered and acquired in many ways; mostly information about the world and its systems. |

Planned seams for when types grow teeth:

- **Small card art per type** — `DeckDisplay._art_for()` is where a
  per-type sheet plugs in; the shared `small_card_base.png` is the
  fallback.
- **Unknown keys survive** — a decklist entry keeps every field it was
  written with through `Card.apply_data()`/`to_data()` and into the
  save, so type-specific data (stats, skills, contents...) can ship in
  content before any code reads it.
- The starter deck's element cards are tagged `lore` as a first guess —
  retag them in `resources/decks/starter_deck.json` if they should be
  something else.
