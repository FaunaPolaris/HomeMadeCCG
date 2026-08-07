class_name DeckDisplay
extends Control

## The row of tiny cards under the deck's panel: one per card in the
## list, so the row reads as a gauge of how full the deckbox is.
##
## The deck is dealt onto a fixed circular ring — card 0 to the middle
## slot, the rest left, right, left, right until the deck is full at
## MAX_DECK — and the cards never leave their slots. Scrolling the big
## list moves the FOCUS instead: the selected card wears the big art
## wherever it sits, its ring neighbours (wrapping around the ends)
## wear the middle art, and everything further wears the small one.

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
		var art := ART_FAR
		match ring_distance(card, _selected, _count):
			0:
				art = ART_SELECTED
			1:
				art = ART_NEAR
		var center := _slot_center(fixed_slot(card))
		var corner := Vector2(center - art.size.x / 2.0, (9.0 - art.size.y) / 2.0)
		draw_texture_rect_region(SHEET, Rect2(corner.floor(), art.size), art)


## The slot deck card [param index] was dealt to, forever: 0 is the
## middle, odd cards fan left (negative), even cards fan right.
static func fixed_slot(index: int) -> int:
	if index == 0:
		return 0
	if index % 2 == 1:
		return -((index + 1) / 2)
	return index / 2


## Steps between two cards along the ring, the short way around. The
## ring wraps: with three cards the outer two are both one step from
## either of the middle ones.
static func ring_distance(a: int, b: int, count: int) -> int:
	var walk := absi(_ring_place(a, count) - _ring_place(b, count))
	return mini(walk, count - walk)


## Where a card sits in the ring, counting left to right, so the wrap
## in [method ring_distance] joins the two outermost cards.
static func _ring_place(index: int, count: int) -> int:
	return fixed_slot(index) + ceili((count - 1) / 2.0)


## Center of a slot, from the card_small_display guide layer: the 9px
## middle centers on x=96, the 7px slots on 87 and 105, then 5px slots
## every 6px outward.
func _slot_center(slot: int) -> float:
	match slot:
		0:
			return 96.5
		1:
			return 105.5
		-1:
			return 87.5
	if slot > 1:
		return 112.5 + SLOT_STEP * (slot - 2)
	return 80.5 - SLOT_STEP * (-slot - 2)
