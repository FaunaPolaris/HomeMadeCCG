class_name DeckDisplay
extends Control

## The row of tiny cards under the deck's panel: one per card in the
## list, so the row reads as a gauge of how full the deckbox is.
##
## The deck is laid out as one circular ring, built by dealing card 0
## to the middle and the rest left, right, left, right until the deck
## is full at MAX_DECK. The ring itself never changes: scrolling the
## big list only rotates it, so whichever card is selected sits in the
## middle slot (the biggest art) with its ring neighbours still beside
## it, shrinking toward the edges.

const SHEET := preload("res://assets/interface/cards/small_card_base.png")

const MAX_DECK := 30

## The three arts in the sheet, big to small.
const ART_SELECTED := Rect2(0, 0, 9, 9)
const ART_NEAR := Rect2(10, 1, 7, 7)
const ART_FAR := Rect2(20, 2, 5, 5)

## Horizontal distance between the small outer slots.
const SLOT_STEP := 6.0

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
	for card in _count:
		var slot := slot_of(card, _selected, _count)
		var art := ART_SELECTED
		if absi(slot) == 1:
			art = ART_NEAR
		elif absi(slot) > 1:
			art = ART_FAR
		draw_texture_rect_region(SHEET, Rect2(_slot_position(slot), art.size), art)


## The signed slot deck card [param index] lands in when [param selected]
## is centered: 0 is the middle, negative is left, positive is right.
static func slot_of(index: int, selected: int, count: int) -> int:
	var place := _ring_place(index, count)
	var delta := posmod(place - _ring_place(selected, count), count)
	if delta <= (count - 1) / 2:
		return delta
	return delta - count


## Where a card sits in the ring, counting left to right: the deal is
## middle, left, right, left, right, so odd cards fan left and even
## cards fan right of card 0.
static func _ring_place(index: int, count: int) -> int:
	var lefts := ceili((count - 1) / 2.0)
	if index == 0:
		return lefts
	if index % 2 == 1:
		return lefts - (index + 1) / 2
	return lefts + index / 2


## Pixel position of a slot, from the card_small_display guide layer:
## a 9px middle at x=92, 7px slots beside it, then 5px slots every 6px.
func _slot_position(slot: int) -> Vector2:
	if slot == 0:
		return Vector2(92, 0)
	if slot == 1:
		return Vector2(102, 1)
	if slot == -1:
		return Vector2(84, 1)
	if slot > 1:
		return Vector2(110 + SLOT_STEP * (slot - 2), 2)
	return Vector2(78 - SLOT_STEP * (-slot - 2), 2)
