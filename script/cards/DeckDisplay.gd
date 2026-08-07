class_name DeckDisplay
extends Control

## The row of tiny cards under the deck's panel: one per card in the
## list, so the row reads as a gauge of how full the deckbox is.
##
## The deck runs left to right in deck order with card 0 in the middle
## and the tail circling around to the left side — seven cards sit as
## 4 5 6 [0] 1 2 3 — with as many cards on either side as symmetry
## allows, full at MAX_DECK. Scrolling the big list moves the FOCUS
## across that fixed order: the selected card wears the big art, its
## ring neighbours (wrapping at the ends) the middle art, the rest the
## small one. The row reflows with a 1px gap between arts, so the wider
## arts always buy their room around the focused card.

const SHEET := preload("res://assets/interface/cards/small_card_base.png")

const MAX_DECK := 30

## The three arts in the sheet, big to small.
const ART_SELECTED := Rect2(0, 0, 9, 9)
const ART_NEAR := Rect2(10, 1, 7, 7)
const ART_FAR := Rect2(20, 2, 5, 5)

## Space between neighbouring arts, and the middle of the guide strip
## the row is centered on.
const ART_GAP := 1.0
const STRIP_CENTER := 96.5

@export var list: CardList

var _count := 0
var _selected := 0


func _ready() -> void:
	if list == null:
		push_warning("DeckDisplay '%s' has no list to watch." % name)
		return
	list.deck_changed.connect(_refresh)
	list.selection_changed.connect(func(_index: int) -> void: _refresh())
	_refresh()


func _refresh() -> void:
	_count = mini(list.card_count(), MAX_DECK)
	_selected = clampi(list.selected_index, 0, maxi(_count - 1, 0))
	queue_redraw()


func _draw() -> void:
	if _count == 0:
		return
	var arts: Array[Rect2] = []
	var total := (_count - 1) * ART_GAP
	var lefts := _count - 1 - (_count - 1) / 2
	for place in _count:
		var card := posmod(place - lefts, _count)
		var art := _art_for(card, ring_distance(card, _selected, _count))
		arts.append(art)
		total += art.size.x
	var x := STRIP_CENTER - total / 2.0
	for art in arts:
		var corner := Vector2(x, (9.0 - art.size.y) / 2.0)
		draw_texture_rect_region(SHEET, Rect2(corner.floor(), art.size), art)
		x += art.size.x + ART_GAP


## The art for one card: today only the distance to the focus matters,
## every card drawing from the shared small_card_base sheet. When small
## cards learn to show their card_type (see plot/card_types.md), this is
## the seam: read list.card_at(card).card_type and pick that type's
## sheet before choosing the size.
func _art_for(_card: int, distance: int) -> Rect2:
	match distance:
		0:
			return ART_SELECTED
		1:
			return ART_NEAR
	return ART_FAR


## How far from the middle of the strip card [param index] sits:
## negative is left. Cards keep deck order reading left to right, with
## card 0 in the middle and the tail wrapped around to the left, sides
## as even as the count allows.
static func strip_offset(index: int, count: int) -> int:
	var rights := (count - 1) / 2
	return index if index <= rights else index - count


## Steps between two cards the short way around the circular deck.
static func ring_distance(a: int, b: int, count: int) -> int:
	var walk := absi(a - b)
	return mini(walk, count - walk)
